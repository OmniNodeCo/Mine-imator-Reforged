#include "Generated/Scripts.hpp"

#include "Asset/Asset.hpp"
#include "Asset/Sound.hpp"
#include "AppHandler.hpp"
#include "Render/Texture.hpp"

#include <algorithm>

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
	// In-app video player: decodes a video file with FFmpeg and streams the
	// frames into a texture the GML side draws. Audio is played through the
	// existing Sound/SoundInstance system (a Sound decodes the file's best
	// audio stream); when audio exists it is used as the playback master
	// clock, otherwise playback runs on the frame delta.
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

		// Clock
		RealType clock = 0.0;
		BoolType playing = false;
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

		~VideoPlayerState()
		{
			Close();
		}

		void Close()
		{
			StopAudio();
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
			playing = eof = false;
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

			// Decode the file's audio (any container); silent playback if none
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
			if (!playing)
				audio_pause_sound(soundInstance);
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

	VideoPlayerState videoPlayer;

	// ---- GML interface ----

	void video_seek(RealType sec); // Defined below; used by video_play

	IntType video_open(StringType file)
	{
		if (!videoPlayer.Open(file))
			return 0;

		// Show the first frame
		videoPlayer.Advance();
		return 1;
	}

	void video_close()
	{
		videoPlayer.Close();
	}

	void video_update(RealType deltaSec)
	{
		if (videoPlayer.vstream < 0)
			return;

		if (videoPlayer.playing)
		{
			// Use the audio position as the master clock while the audio
			// instance is alive; otherwise run on the frame delta (covers
			// files without audio and audio that ended before the video)
			if (videoPlayer.AudioPlaying())
				videoPlayer.clock = audio_sound_get_track_position(videoPlayer.soundInstance);
			else
				videoPlayer.clock += deltaSec;

			if (videoPlayer.duration > 0.0 && videoPlayer.clock >= videoPlayer.duration)
			{
				videoPlayer.clock = videoPlayer.duration;
				videoPlayer.playing = false;
				videoPlayer.StopAudio();
			}
		}

		videoPlayer.Advance();
	}

	void video_play(IntType play)
	{
		if (videoPlayer.vstream < 0)
			return;

		BoolType wantPlaying = (play != 0);

		// Restart from the beginning when replaying after the end
		if (wantPlaying && !videoPlayer.playing
			&& videoPlayer.duration > 0.0 && videoPlayer.clock >= videoPlayer.duration - 0.01)
			video_seek(0);

		videoPlayer.playing = wantPlaying;

		if (!videoPlayer.sound)
			return;

		if (wantPlaying)
		{
			if (videoPlayer.AudioPlaying())
				audio_resume_sound(videoPlayer.soundInstance);
			else
				videoPlayer.StartAudio(videoPlayer.clock);
		}
		else if (videoPlayer.AudioPlaying())
			audio_pause_sound(videoPlayer.soundInstance);
	}

	IntType video_playing()
	{
		return (videoPlayer.playing ? 1 : 0);
	}

	void video_seek(RealType sec)
	{
		if (videoPlayer.vstream < 0)
			return;

		if (videoPlayer.duration > 0.0)
			sec = std::clamp(sec, 0.0, videoPlayer.duration);

		videoPlayer.eof = false;
		videoPlayer.clock = sec;

		// Seek the demuxer to just before the target and flush the decoder
		av_seek_frame(videoPlayer.fmt, videoPlayer.vstream,
			(int64_t)(sec / videoPlayer.timeBase), AVSEEK_FLAG_BACKWARD);
		avcodec_flush_buffers(videoPlayer.vctx);
		videoPlayer.pendingPts = -1.0;
		videoPlayer.pendingImage = QImage();

		// Decode up to the seek target
		videoPlayer.Advance();

		// Move the audio with us
		if (videoPlayer.AudioPlaying())
			audio_sound_set_track_position(videoPlayer.soundInstance, sec);
		else if (videoPlayer.sound && videoPlayer.playing)
			videoPlayer.StartAudio(sec);
	}

	RealType video_position()
	{
		return videoPlayer.clock;
	}

	RealType video_duration()
	{
		return videoPlayer.duration;
	}

	IntType video_texture()
	{
		if (videoPlayer.texture)
			return videoPlayer.texture->GetId();
		return -1;
	}

	IntType video_width()
	{
		if (videoPlayer.vctx)
			return videoPlayer.vctx->width;
		return 0;
	}

	IntType video_height()
	{
		if (videoPlayer.vctx)
			return videoPlayer.vctx->height;
		return 0;
	}

	IntType video_has_audio()
	{
		return (videoPlayer.sound ? 1 : 0);
	}

	void video_volume(RealType vol)
	{
		videoPlayer.volume = std::clamp(vol, 0.0, 1.0);
		if (videoPlayer.AudioPlaying())
			audio_sound_gain(videoPlayer.soundInstance, videoPlayer.volume, 0);
	}

	RealType video_volume_get()
	{
		return videoPlayer.volume;
	}
}
