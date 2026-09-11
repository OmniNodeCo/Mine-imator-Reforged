#include "Generated/Scripts.hpp"

#include "Asset/Asset.hpp"
#include "Asset/Sound.hpp"
#include "AppHandler.hpp"
#include "Render/Texture.hpp"

#include <algorithm>
#include <cmath>

extern "C"
{
	#include <libavutil/opt.h>
	#include <libavutil/mathematics.h>
	#include <libavcodec/avcodec.h>
	#include <libavformat/avformat.h>
	#include <libswscale/swscale.h>
}

namespace CppProject
{
	// Video screens in the animation ("TV" rigs): each timeline object that has
	// a video attached gets one of these players. The GML side positions the
	// player at the current animation time every frame (video_display), so the
	// screen shows the right frame while scrubbing, playing and exporting.
	// Audio is played through the existing Sound/SoundInstance system and
	// follows the editor playback state (video_audio_update); exports render
	// frame by frame and are silent, like other editor-only audio.
	struct VideoPlayerState
	{
		StringType filename;

		// Demuxing / decoding
		AVFormatContext* fmt = nullptr;
		AVCodecContext* vctx = nullptr;
		SwsContext* sws = nullptr;
		AVFrame* frame = nullptr;
		AVPacket* packet = nullptr;
		int vstream = -1;
		RealType timeBase = 0.0;
		RealType duration = 0.0;

		// Clock (animation time)
		RealType clock = 0.0;
		BoolType eof = false;

		// Frame pipeline (one frame of lookahead)
		QImage pendingImage;
		RealType pendingPts = -1.0;
		QImage image;
		RealType framePts = -1.0;
		Texture* texture = nullptr;

		// Audio
		Sound* sound = nullptr;
		IntType soundInstance = -1;
		RealType volume = 1.0;
		BoolType audioStarted = false;

		~VideoPlayerState()
		{
			Close();
		}

		void Close()
		{
			StopAudio();
			audioStarted = false;
			if (sound)
			{
				delete sound;
				sound = nullptr;
			}
			if (texture)
			{
				delete texture;
				texture = nullptr;
			}
			if (packet)
				av_packet_free(&packet);
			if (frame)
				av_frame_free(&frame);
			if (sws)
			{
				sws_freeContext(sws);
				sws = nullptr;
			}
			if (vctx)
				avcodec_free_context(&vctx);
			if (fmt)
				avformat_close_input(&fmt);

			pendingImage = QImage();
			image = QImage();
			pendingPts = -1.0;
			framePts = -1.0;
			vstream = -1;
			timeBase = duration = clock = 0.0;
			eof = false;
			filename = "";
		}

		BoolType Open(StringType file)
		{
			Close();

			std::string fn = file.ToStdString();
			if (avformat_open_input(&fmt, fn.c_str(), nullptr, nullptr) != 0)
				return false;

			if (avformat_find_stream_info(fmt, nullptr) < 0)
			{
				Close();
				return false;
			}

			vstream = av_find_best_stream(fmt, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
			if (vstream < 0)
			{
				Close();
				return false;
			}

			const AVCodec* codec = avcodec_find_decoder(fmt->streams[vstream]->codecpar->codec_id);
			if (!codec)
			{
				Close();
				return false;
			}

			vctx = avcodec_alloc_context3(codec);
			if (avcodec_parameters_to_context(vctx, fmt->streams[vstream]->codecpar) < 0)
			{
				Close();
				return false;
			}

			if (avcodec_open2(vctx, codec, nullptr) < 0)
			{
				Close();
				return false;
			}

			timeBase = av_q2d(fmt->streams[vstream]->time_base);
			if (fmt->duration > 0)
				duration = fmt->duration / (RealType)AV_TIME_BASE;
			else if (fmt->streams[vstream]->duration > 0)
				duration = fmt->streams[vstream]->duration * timeBase;

			sws = sws_getContext(vctx->width, vctx->height, vctx->pix_fmt,
				vctx->width, vctx->height, AV_PIX_FMT_RGBA,
				SWS_BILINEAR, nullptr, nullptr, nullptr);

			frame = av_frame_alloc();
			packet = av_packet_alloc();
			filename = file;

			// Decode the file's audio (any container); silent screen if none
			sound = new Sound(file);
			if (!sound->buffer.size())
			{
				delete sound;
				sound = nullptr;
			}
			return true;
		}

		// Reads packets until a video frame is decoded; converts it into
		// 'pendingImage'. Returns false at end of file.
		BoolType DecodeNextFrame()
		{
			while (true)
			{
				int ret = av_read_frame(fmt, packet);
				if (ret < 0)
				{
					// End of file: flush the decoder
					avcodec_send_packet(vctx, nullptr);
				}
				else if (packet->stream_index == vstream)
				{
					ret = avcodec_send_packet(vctx, packet);
					av_packet_unref(packet);
					if (ret < 0)
						continue;
				}
				else
				{
					av_packet_unref(packet);
					continue;
				}

				while (avcodec_receive_frame(vctx, frame) == 0)
				{
					if (frame->width <= 0 || frame->height <= 0)
						continue;

					pendingImage = QImage(frame->width, frame->height, QImage::Format_RGBA8888);
					uint8_t* dstBits[4] = { pendingImage.bits(), nullptr, nullptr, nullptr };
					int dstStride[4] = { pendingImage.bytesPerLine(), 0, 0, 0 };
					sws_scale(sws, frame->data, frame->linesize, 0, frame->height, dstBits, dstStride);
					pendingPts = (frame->pts != AV_NOPTS_VALUE
						? frame->pts * timeBase
						: (pendingPts < 0.0 ? 0.0 : pendingPts + 0.04));
					return true;
				}

				if (ret < 0)
					return false; // EOF and nothing more from the decoder
			}
		}

		// Makes the pending frame the displayed frame
		void ShowPendingFrame()
		{
			image = pendingImage;
			framePts = pendingPts;
			pendingPts = -1.0;
			pendingImage = QImage();

			if (texture)
			{
				delete texture;
				texture = nullptr;
			}
			texture = new Texture(image);
		}

		// Advances to the clock: displays every frame whose time has come
		void Advance()
		{
			while (!eof && (pendingPts < 0.0 || pendingPts <= clock))
			{
				if (pendingPts >= 0.0)
					ShowPendingFrame();
				if (!DecodeNextFrame())
					eof = true;
			}
		}

		// Seek the demuxer to just before the target and flush the decoder
		void SeekTo(RealType sec)
		{
			if (duration > 0.0)
				sec = std::clamp(sec, 0.0, duration);

			eof = false;
			clock = sec;
			audioStarted = false; // Allow the audio to start again from here

			av_seek_frame(fmt, vstream,
				(int64_t)(sec / timeBase), AVSEEK_FLAG_BACKWARD);
			avcodec_flush_buffers(vctx);
			pendingPts = -1.0;
			pendingImage = QImage();

			Advance();
		}

		void StartAudio(RealType offset)
		{
			StopAudio();
			if (!sound || !App->audioSupported)
				return;

			soundInstance = audio_play_sound(sound->id, 0, false);
			if (soundInstance < 0)
				return;

			audio_sound_gain(soundInstance, volume, 0);
			if (offset > 0.0)
				audio_sound_set_track_position(soundInstance, offset);
		}

		void StopAudio()
		{
			if (soundInstance >= 0)
			{
				audio_stop_sound(soundInstance);
				soundInstance = -1;
			}
		}

		BoolType AudioPlaying()
		{
			return (soundInstance >= 0 && FindSoundInstance(soundInstance) != nullptr);
		}
	};

	// Video players, one per screen object. GML allocates slots (0-7).
	static VideoPlayerState videoPlayers[8];

	static VideoPlayerState& VideoSlot(IntType slot)
	{
		return videoPlayers[std::clamp<IntType>(slot, 0, 7)];
	}

	// ---- GML interface ----

	IntType video_open(StringType file, IntType slot)
	{
		VideoPlayerState& player = VideoSlot(slot);
		if (!player.Open(file))
			return 0;

		// Show the first frame
		player.Advance();
		return 1;
	}

	void video_close(IntType slot)
	{
		VideoSlot(slot).Close();
	}

	void video_display(RealType timeSec, IntType slot)
	{
		VideoPlayerState& player = VideoSlot(slot);
		if (player.vstream < 0)
			return;

		if (player.duration > 0.0)
			timeSec = std::clamp(timeSec, 0.0, player.duration);

		// Seeking to a new point in the animation (scrubbing, export jumps);
		// small forward steps just advance the decode pipeline
		if (timeSec < player.clock - 0.001 || timeSec > player.clock + 0.3)
			player.SeekTo(timeSec);
		else
			player.clock = timeSec;

		player.Advance();
	}

	void video_audio_update(IntType playing, IntType slot)
	{
		VideoPlayerState& player = VideoSlot(slot);
		if (!player.sound || !App->audioSupported)
			return;

		// Exports and paused timelines are silent
		if (!playing)
		{
			if (player.AudioPlaying())
				audio_pause_sound(player.soundInstance);
			return;
		}

		if (player.AudioPlaying())
		{
			audio_resume_sound(player.soundInstance);

			// Follow seeks (scrubbing while playing)
			RealType audioPos = audio_sound_get_track_position(player.soundInstance);
			if (std::fabs(audioPos - player.clock) > 0.3)
				audio_sound_set_track_position(player.soundInstance, player.clock);
		}
		else if (!player.audioStarted)
		{
			// Start once; if the video's audio ended it stays silent until a seek
			player.StartAudio(player.clock);
			player.audioStarted = true;
		}
	}

	RealType video_duration(IntType slot)
	{
		return VideoSlot(slot).duration;
	}

	IntType video_texture(IntType slot)
	{
		VideoPlayerState& player = VideoSlot(slot);
		if (player.texture)
			return player.texture->GetId();
		return -1;
	}

	IntType video_width(IntType slot)
	{
		VideoPlayerState& player = VideoSlot(slot);
		if (player.vctx)
			return player.vctx->width;
		return 0;
	}

	IntType video_height(IntType slot)
	{
		VideoPlayerState& player = VideoSlot(slot);
		if (player.vctx)
			return player.vctx->height;
		return 0;
	}

	IntType video_has_audio(IntType slot)
	{
		return (VideoSlot(slot).sound ? 1 : 0);
	}

	void video_volume(RealType vol, IntType slot)
	{
		VideoPlayerState& player = VideoSlot(slot);
		player.volume = std::clamp(vol, 0.0, 1.0);
		if (player.AudioPlaying())
			audio_sound_gain(player.soundInstance, player.volume, 0);
	}

	RealType video_volume_get(IntType slot)
	{
		return VideoSlot(slot).volume;
	}
}
