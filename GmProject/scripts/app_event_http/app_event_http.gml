/// app_event_http()

function app_event_http()
{
	// Check assets
	if (async_load[?"id"] = http_assets && async_load[?"status"] < 1 && (!dev_mode || dev_mode_check_assets))
	{
		http_assets = null
		if (async_load[?"status"] = 0 && async_load[?"http_status"] = http_ok)
		{
			var decodedmap = json_decode(async_load[?"result"]);
			if (ds_map_valid(decodedmap))
			{
				var versionslist = decodedmap[?"versions"];
				if (ds_list_valid(versionslist))
				{
					var newversionmap = versionslist[|ds_list_size(versionslist) - 1];
					
					// New assets available
					if (ds_map_valid(newversionmap) && !file_exists_lib(minecraft_directory + newversionmap[?"version"] + ".zip"))
					{
						// Continue with current or newer formats only
						if (newversionmap[?"format"] >= minecraft_assets_format)
						{
							// Get info about assets
							setting_minecraft_assets_new_version = newversionmap[?"version"]
							setting_minecraft_assets_new_format = newversionmap[?"format"]
							setting_minecraft_assets_new_changes = newversionmap[?"changes"]
							
							if (is_string(newversionmap[?"image"]))
							{
								// Download image
								setting_minecraft_assets_new_image = mc_file_directory + newversionmap[?"image"]
								assets_http_image = http_get_file(link_assets + newversionmap[?"image"], setting_minecraft_assets_new_image)
							}
							else
								setting_minecraft_assets_new_image = ""
							
							// Alert
							toast_new(e_toast.INFO, text_get("alertnewassets", setting_minecraft_assets_new_version))
							toast_last.dismiss_time = no_limit
							
							log("New assets found", setting_minecraft_assets_new_version)
						}
					}
					else
						log("Using the latest assets")
				}
				
				ds_map_destroy(decodedmap)
			}
		}
	}
	
	// Download assets specification
	else if (async_load[?"id"] = http_download_assets_file)
	{
		if (async_load[?"status"] = 1)
			new_assets_download_progress = (async_load[?"sizeDownloaded"] / async_load[?"contentLength"]) * 0.25
		else
		{
			http_download_assets_file = null
			http_download_assets_zip = http_get_file(link_assets + new_assets_version + ".zip", mc_file_directory + new_assets_version + ".zip")
		}
	}
	
	// Download assets archive
	else if (async_load[?"id"] = http_download_assets_zip)
	{
		if (async_load[?"status"] = 1)
			new_assets_download_progress = 0.25 + (async_load[?"sizeDownloaded"] / async_load[?"contentLength"]) * 0.75
		else
		{
			http_download_assets_zip = null
			
			// Set as current assets
			setting_minecraft_assets_version = new_assets_version
			setting_minecraft_assets_new_version = ""
			
			// Move files and cleanup
			file_copy_lib(mc_file_directory + new_assets_version + ".midata", minecraft_directory + new_assets_version + ".midata")
			file_copy_lib(mc_file_directory + new_assets_version + ".zip", minecraft_directory + new_assets_version + ".zip")
			file_delete_lib(mc_file_directory + new_assets_version + ".midata")
			file_delete_lib(mc_file_directory + new_assets_version + ".zip")
			if (new_assets_image != "")
				file_delete_lib(mc_file_directory + new_assets_image)
			
			// Load new assets
			if (!minecraft_assets_load_startup())
			{
				error("errorloadassets")
				game_end()
				return false
			}
		}
	}
	
	// Check news
	else if (async_load[?"id"] = http_alert_news && async_load[?"status"] < 1)
	{
		http_alert_news = null
		if (async_load[?"status"] = 0 && async_load[?"http_status"] = http_ok)
		{
			var decodedmap = json_decode(async_load[?"result"]);
			if (ds_map_valid(decodedmap))
			{
				var newslist = decodedmap[?"default"];
				for (var n = 0; n < ds_list_size(newslist); n++)
				{
					var newsmap, title, text, icon, button, buttonurl, iid;
					newsmap = newslist[|n]
					
					if (ds_map_valid(newsmap))
					{
						title = newsmap[?"title"]
						text = newsmap[?"text"]
						icon = newsmap[?"icon"]
						
						switch (icon)
						{
							case "website":		icon = icons.WORLD;				break
							case "forums":		icon = icons.COMMENT;			break
							case "save":		icon = icons.SAVE;				break
							case "download":	icon = icons.DOWNLOAD;			break
							case "cake":		icon = icons.BIRTHDAY;			break
							case "upgrade":		icon = icons.KEY;				break
							case "render":		icon = (setting_theme.dark ? icons.SPHERE_MATERIAL__DARK : icons.SPHERE_MATERIAL);	break
							default:			icon = null;					break
						}
						
						button = newsmap[?"button"]
						buttonurl = newsmap[?"buttonurl"]
						if (!is_undefined(newsmap[?"saveclose"]))
							iid = newsmap[?"id"]
						else
							iid = null
						
						if (!iid || ds_list_find_index(closed_toast_list, iid) < 0)
						{
							button = string_replace(button, "button", "")
							
							toast_new(e_toast.INFO, text)
							toast_add_action(button, popup_open_url, buttonurl)
							toast_last.dismiss_time = no_limit
							toast_last.iid = iid
						}
					}
				}
				ds_map_destroy(decodedmap)
			}
			else
				log("Failed to decode")
		}
	}
	
	// Download skin
	else if (async_load[?"id"] = http_downloadskin && async_load[?"status"] < 1)
	{
		http_downloadskin = null
		
		// Download skin popup
		if (popup = popup_downloadskin)
		{
			popup_downloadskin.fail_message = text_get("errordownloadskininternet")
			
			if (popup_downloadskin.texture)
			{
				texture_free(popup_downloadskin.texture)
				popup_downloadskin.texture = null
			}
		}
		else // Scenery builder
		{
			mc_builder.block_skull_texture = null
			mc_builder.block_skull_texture_fail = false
		}
		
		if (async_load[?"status"] = 0)
		{
			if (popup = popup_downloadskin)
				popup_downloadskin.fail_message = text_get("errordownloadskinuser", string_remove_newline(popup_downloadskin.username))
			else
				mc_builder.block_skull_texture_fail = true
			
			if (async_load[?"http_status"] = http_ok && file_exists_lib(download_image_file))
			{
				if (popup = popup_downloadskin)
				{
					popup_downloadskin.texture = texture_create(download_image_file)
					popup_downloadskin.fail_message = ""
				}
				else
				{
					mc_builder.block_skull_texture = texture_create(download_image_file)
					mc_builder.block_skull_texture_fail = false
				}
			}
		}
	}
	
	// Content center catalog
	else if (async_load[?"id"] = http_content_index)
	{
		http_content_index = null
		
		var cmenu;
		cmenu = popup_contentcenter.fetch_menu
		
		if (async_load[?"status"] = 0 && async_load[?"http_status"] = http_ok)
		{
			var decodedmap = json_decode(async_load[?"result"]);
			var items;
			items = undefined
			if (ds_map_valid(decodedmap))
			{
				if (ds_list_valid(decodedmap[?"items"]))
					items = decodedmap[?"items"]
				else if (ds_list_valid(decodedmap[?"rigs"]))
					items = decodedmap[?"rigs"]
			}
			
			if (!is_undefined(items))
			{
				popup_contentcenter.lists[cmenu] = items
				popup_contentcenter.loading[cmenu] = false
				popup_contentcenter.fail[cmenu] = ""
				
				// Keep the selection if the item is still in the new list,
				// otherwise select the first entry
				var selvalid, itemcount, itemi, entry;
				selvalid = false
				itemcount = ds_list_size(items)
				if (ds_map_valid(popup_contentcenter.selected))
				{
					for (itemi = 0; itemi < itemcount; itemi++)
					{
						entry = items[|itemi]
						if (ds_map_valid(entry) && entry[?"name"] = popup_contentcenter.selected[?"name"])
						{
							popup_contentcenter.selected = entry
							selvalid = true
							break
						}
					}
				}
				if (!selvalid && itemcount > 0)
					popup_contentcenter.selected = items[|0]
					
				log("Content center: loaded", itemcount, "items")
			}
			else
			{
				popup_contentcenter.loading[cmenu] = false
				popup_contentcenter.fail[cmenu] = text_get("contentoffline")
			}
		}
		else
		{
			popup_contentcenter.loading[cmenu] = false
			popup_contentcenter.fail[cmenu] = text_get("contentoffline")
		}
	}
	
	// Content center download
	else if (async_load[?"id"] = http_content_file)
	{
		if (async_load[?"status"] = 1)
		{
			popup_contentcenter.downloaded_bytes = async_load[?"sizeDownloaded"]
			popup_contentcenter.total_bytes = async_load[?"contentLength"]
		}
		else
		{
			http_content_file = null
			
			var dmenu, dpath, dname, dok;
			dmenu = popup_contentcenter.downloading_menu
			dpath = popup_contentcenter.downloading_path
			dname = popup_contentcenter.downloading_name
			dok = (async_load[?"status"] = 0 && async_load[?"http_status"] = http_ok && file_exists_lib(dpath))
			
			if (dmenu = 0)
			{
				// Rigs: the download must be an actual zip - servers like
				// Google Drive can answer with an HTML page instead
				var valid, sentfile;
				valid = false
				sentfile = false
				
				if (dok)
				{
					sentfile = true
					
					var buffer;
					buffer = buffer_load_lib(dpath)
					if (buffer >= 0)
					{
						if (buffer_get_size(buffer) >= 2)
							valid = (buffer_peek(buffer, 0, buffer_u8) = 80 && buffer_peek(buffer, 1, buffer_u8) = 75)
						buffer_delete(buffer)
					}
				}
					
				if (valid)
				{
					popup_contentcenter.saved_name = dname
					popup_contentcenter.saved_path = dpath
					popup_contentcenter.error_message = ""
					log("Content center: saved", dpath)
					toast_new(e_toast.POSITIVE, text_get("contentdonerig", dname))
				}
				else
				{
					// Remove the invalid file (e.g. the HTML page a server sent
					// instead of the file)
					if (sentfile)
						file_delete_lib(dpath)
							
					popup_contentcenter.error_name = dname
					popup_contentcenter.error_message = (sentfile ? text_get("contentnotzip") : text_get("contentfailed", dname))
					log("Content center: download failed", dpath)
					toast_new(e_toast.NEGATIVE, text_get("contentfailedtoast", dname))
				}
			}
			else if (dmenu = 1)
			{
				// Shader pack: installed into the Shaders folder
				if (dok)
				{
					shader_packs_load(true)
					popup_contentcenter.saved_name = dname
					popup_contentcenter.saved_path = dpath
					toast_new(e_toast.POSITIVE, text_get("contentdoneshader", dname))
				}
				else
				{
					file_delete_lib(dpath)
					toast_new(e_toast.NEGATIVE, text_get("contentfailedtoast", dname))
				}
			}
			else if (dmenu = 2)
			{
					// Addon: installed from the temporary download file
				var addonname;
				addonname = ""
				if (dok)
					addonname = addon_install(dpath)
					
				if (addonname != "")
				{
					popup_contentcenter.saved_name = dname
					popup_contentcenter.saved_path = addons_directory
					toast_new(e_toast.POSITIVE, text_get("contentdoneaddon", addonname))
				}
				else
					toast_new(e_toast.NEGATIVE, text_get("contentfailedtoast", dname))
					
				file_delete_lib(dpath)
			}
			else
			{
				// Particle preset: installed into the Particles folder
				if (dok)
				{
					popup_contentcenter.saved_name = dname
					popup_contentcenter.saved_path = dpath
					toast_new(e_toast.POSITIVE, text_get("contentdoneparticle", dname))
				}
				else
				{
					file_delete_lib(dpath)
					toast_new(e_toast.NEGATIVE, text_get("contentfailedtoast", dname))
				}
			}
				
			popup_contentcenter.downloading = ""
		}
	}
}