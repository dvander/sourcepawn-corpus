/*
adminsounds.sp

Description:
	Allows admins to play sounds from a menu

Versions:
	1.0
		* Initial Release
		
	1.0.1
		* Increased the max number of sounds to 50
		* Added error checking on the number of sounds

	1.0.2 // Changed by o_O.Uberman.O_o upon request of|HS|Jesus
		* Added a chat "!stop" command to allow players to stop sounds started by this plug-in

	1.0.3 // Changed by |HS|Jesus
		* Added output of which sound is playing  

	1.1
		* Made the config file load automatically
		* Added sm_adminsounds_delay cvar to control the minimum delay between 2 sounds

	1.1.1 // Changed by cadavor
		* Added Log messages
		* Disable menu after launch sound
		* Added Cvar to enable or disable display and stop command
		
	1.1.2 // Changed by cadavor
		* Added to admin menu
		* Added translations
		
	1.1.3 // Changed by cadavor
		* Added how many sounds has been loaded in log
		* Added error in log when filename is too long to prevent crash of the plugin

	1.1.4a // Changed by cadavor (not released)
		* Added an option to stop all sound (require clientpref plugin) with say command !stopall
		* Added cvar to control the volume of sounds
		
	1.1.4b // Changed by cadavor (not released)
		* Correction of displayed message
		
	1.2.0 // Changed by cadavor
		* Change config file to use KeyValue function (see soundslist.cfg for more details)
		* Added command "sm_adminsounds_list" to display in console all sounds and categories with parameters
		* Added Cvar to choose the show time of menu
		* Reset next sound delay on map start

	1.2.1 // Changed by cadavor
		* Added stop option for each categories and sounds
		* Added Cvar to choose if menu will be shown again after each sound
		* Added Cvar to choose admin flag for delay immunity
		* Fix StopAll option to check if ClientPref plugin is running
		* Fix Cvar tag to don't record the version in config file

	1.2.1d // Changed by cadavor
		* Fix stop option
		* Added Back button to all menus
		* Added stop action in menu
		* Fix check ClientPref plugin which sometimes made too early
		* Change precache option to enable precache before level startup
		
	1.2.1e // Changed by cadavor
		* Added cvar to choose admin level for stop option
		* Fix say command if only one stop option was enabled
		* Fix menu display again
		
	1.2.1f // Changed by cadavor
		* Fix admin level for stop option
		* Added message for reenable sounds to client who "stopall" on each sound launched
		
	1.2.1g // Changed by cadavor
		* Fix sound selection when categories have same name (allow sound with same name in different category)
		* Added public message when admin stop a sound
		
	1.2.1h // Changed by cadavor
		* Fix GetMenuIem errors
		
	1.2.2 // Changed by cadavor
		* Release version
		
Commands :
	Admin Commands:
		sm_adminsounds_menu 	Display a menu of all admin sounds to play
		sm_adminsounds_stop		Stop the playing sound for everyone
		sm_adminsounds_list		Display a list of categories of sounds
	
	User Commands:
		!stop	 			When used in chat will per-user stop any sound currently playing by this plug-in
		!stopall			When used in chat will per-user enable/disable hearing of any sound

*/


#include <sourcemod>
#include <sdktools>
#include <clientprefs>

/* Make the admin menu plugin optional */
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2.2"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Admin Sounds",
	author = "cadav0r, dalto, o_O.Uberman.O_o, |HS|Jesus",
	description = "Allows admins to play sounds from a menu",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

/* Keep track of the top menu */
new Handle:AS_TopMenu = INVALID_HANDLE;

/* KV file */
new Handle:listfile = INVALID_HANDLE;
new String:soundlistfile[PLATFORM_MAX_PATH+1] = "";

/* Menu */
new Handle:cat_menu = INVALID_HANDLE;
new Handle:sound_menu = INVALID_HANDLE;

new Handle:g_CvarDelay = INVALID_HANDLE;
new Handle:g_CvarDisplay = INVALID_HANDLE;
new Handle:g_CvarAdminStop = INVALID_HANDLE;
new Handle:g_CvarStop = INVALID_HANDLE;
new Handle:g_CvarStopAll = INVALID_HANDLE;
new Handle:g_CvarVolume = INVALID_HANDLE;
new Handle:g_CvarMenuReprint = INVALID_HANDLE;
new Handle:g_CvarMenuTime = INVALID_HANDLE;
new Handle:g_CvarTimeImmunity = INVALID_HANDLE;
new Handle:g_StopCookie = INVALID_HANDLE;
new StopAll[MAXPLAYERS+1];
new g_numSounds = 0;
new g_timeNextPlay = 0;
new SndPlaying[MAXPLAYERS+1];
new String:SndPlayingName[MAXPLAYERS+1][PLATFORM_MAX_PATH+1];

new Handle:g_precacheTrie = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("adminsounds.phrases");

	CreateConVar("sm_admin_sounds_version", PLUGIN_VERSION, "Admin Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarDelay = CreateConVar("sm_admin_sounds_delay", "60", "Default time in seconds after playing a sound that another one can be played. Default: 60", FCVAR_PLUGIN, true, 0.0);
	g_CvarDisplay = CreateConVar("sm_admin_sounds_display", "1", "Enable the display of message to client when a sound is played. Default: on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_CvarMenuReprint = CreateConVar("sm_admin_sounds_menureprint", "0", "Enable the possibility to reprint the menu after each sound. Default : 0.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_CvarMenuTime = CreateConVar("sm_admin_sounds_menutime", "20", "How long the menu still show. Default : 20.", FCVAR_PLUGIN, true, 5.0, true, 60.0);
	g_CvarAdminStop = CreateConVar("sm_admin_sounds_adminlevelstop", "b", "Admin flag to be allow to stop played sound (see admin_level.cfg). If blank no stop possibility for admin. Default : b.", FCVAR_PLUGIN);
	g_CvarStop = CreateConVar("sm_admin_sounds_stop", "1", "Enable the possibility to stop the playing sound. Default: on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_CvarStopAll = CreateConVar("sm_admin_sounds_stopall", "1", "Enable the possibility to stop all sounds. Default : on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_CvarVolume = CreateConVar("sm_admin_sounds_volume", "1.0", "Default volume of played sounds : 0.0 <= x <= 1.0. Default : 1.0.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_CvarTimeImmunity = CreateConVar("sm_admin_sounds_timeimmunity", "z", "Admin flag for delay time immunity (see admin_level.cfg). Leave blank for no immunity. Default : z.", FCVAR_PLUGIN);
	
	// Execute the config file
	AutoExecConfig(true, "adminsounds");

	RegAdminCmd("sm_adminsounds_menu", AS_CatMenu, ADMFLAG_GENERIC);
	RegAdminCmd("sm_adminsounds_stop", Command_StopPlayedSound, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_adminsounds_list", Command_Sound_List, "List available sounds to console");

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	/* See if the menu pluginis already ready */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		/* If so, manually fire the callback */
		OnAdminMenuReady(topmenu);
	}
}

public OnAllPluginsLoaded()
{
	// Clientprefs 
	// for storing clients sound settings
	if (GetConVarBool(g_CvarStopAll))
	{
		new Handle:Plugin_ClientPref = FindPluginByFile("clientprefs.smx");
		new PluginStatus:Plugin_ClientPref_Status = GetPluginStatus(Plugin_ClientPref);
		if ((Plugin_ClientPref == INVALID_HANDLE) || (Plugin_ClientPref_Status != Plugin_Running))
			LogError("This plugin require clientprefs plugin to allow users to disable all sounds.");
		else
			g_StopCookie = RegClientCookie("adminsounds", "Stop All Admin Sounds", CookieAccess_Protected);
	}
}

public OnMapStart()
{
	// Load sounds list
	Load_Sounds();
	// Reset Timer
	g_timeNextPlay = 0;
}

public OnClientPostAdminCheck(client)
{
	if (g_StopCookie != INVALID_HANDLE)
	{
		// Check Client cookie
		new String:cookie[4];
		if (AreClientCookiesCached(client))
		{
			GetClientCookie(client, g_StopCookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "on"))
			{
				StopAll[client] = 1;
				PrintToChat(client, "\x04[SM] Admin Sounds: \x01%t \x04!stopall\x01 %t", "Stop_Type", "StopAll Reenabled");
				return;
			}
			if (StrEqual(cookie, "off"))
			{
				StopAll[client] = 0;
				return;
			}
		}
		// Set cookie if client connects the first time
		SetClientCookie(client, g_StopCookie, "off");
		StopAll[client] = 0;
	}
	else
	{
		StopAll[client] = 0;
	}
	SndPlaying[client] = 0;
	SndPlayingName[client] = "";
}

// Add to the admin menu
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == AS_TopMenu)
		return;

	AS_TopMenu = topmenu;

	decl String:buffer[255];
	Format(buffer, sizeof(buffer), "%t", "Admin Sounds");
	// Add top categorie
	new TopMenuObject:adminsounds_menu = AddToTopMenu(
		AS_TopMenu,		// Menu
		buffer,
		TopMenuObject_Category,
		CategoryHandler,
		INVALID_TOPMENUOBJECT);
		
	// Add items in the categorie
	if (adminsounds_menu != INVALID_TOPMENUOBJECT)
	{
		Format(buffer, sizeof(buffer), "%t", "Play sound");
		AddToTopMenu(AS_TopMenu,
			buffer,
			TopMenuObject_Item,
			AdminMenu_Play,
			adminsounds_menu,
			buffer,
			ADMFLAG_GENERIC);
		
		new AdminFlag:flag;
		decl String:adminstop[5];
		GetConVarString(g_CvarAdminStop, adminstop, sizeof(adminstop));
		if (FindFlagByChar(adminstop[0], flag))
		{
			Format(buffer, sizeof(buffer), "%t", "Stop sound");
			AddToTopMenu(AS_TopMenu,
				buffer,
				TopMenuObject_Item,
				AdminMenu_Stop,
				adminsounds_menu,
				buffer,
				ADMFLAG_GENERIC);
		}
	}
}

public CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "%t:", "Admin Sounds");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "Admin Sounds");
	}
}

public AdminMenu_Stop(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "Stop sound");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		AS_StopPlayedSound(param, 0);
	}
}

public Action:AS_StopPlayedSound(client, args)
{
	if (!client)
		return Plugin_Handled;

	if (CheckImmunity(client, g_CvarAdminStop))
	{
		if (StopSounds())
		{
			decl String:name[35];
			GetClientName(client, name, sizeof(name));

			PrintToChatAll("%t", "AdminStopSounds", name);
			LogAction(client, -1, "\"%L\" stop played sound", client);
		}
		else
		{
			PrintToChat(client, "%t", "NoSoundPlayed");
		}
	}
	else
	{
		PrintToChat(client, "%t", "AdminCantStop");
	}
	DisplayTopMenu(AS_TopMenu, client, TopMenuPosition_LastCategory);

	return Plugin_Handled;
}

public AdminMenu_Play(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "Play sound");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		AS_CatMenu(param, 0);
	}
}

public Action:AS_CatMenu(client, args)
{
	if (!client)
		return Plugin_Handled;

	cat_menu = CreateMenu(AS_CatMenuHandler);

	/* Translate to our phrase */
	decl String:buffer[255];
	Format(buffer, sizeof(buffer), "%t", "Admin Sounds");	
	SetMenuTitle(cat_menu, buffer);

	// Add items in the categorie
	KvRewind(listfile);
	KvGotoFirstSubKey(listfile);

	decl String:buffer2[PLATFORM_MAX_PATH+1];
	decl String:cat_name[PLATFORM_MAX_PATH+1];
	decl String:code_lang[4];
	new client_lang = GetClientLanguage(client);
	GetLanguageInfo(client_lang, code_lang, sizeof(code_lang));
	do
	{
		KvGetSectionName(listfile, buffer2, sizeof(buffer2));
		cat_name[0] = '\0';
		KvGetString(listfile, code_lang, cat_name, sizeof(cat_name));
		if (cat_name[0] == '\0')
			strcopy(cat_name, sizeof(cat_name), buffer2);
		AddMenuItem(cat_menu, buffer2, cat_name);
	} while (KvGotoNextKey(listfile));

	SetMenuExitBackButton(cat_menu, true);
	DisplayMenu(cat_menu, client, GetConVarInt(g_CvarMenuTime));

	return Plugin_Handled;
}

public AS_CatMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		AdminSoundsMenu(param1, param2, "");
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
	{
		DisplayTopMenu(AS_TopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:AdminSoundsMenu(client, pos, String:name[])
{
	if (!client)
		return Plugin_Handled;

	decl String:cat_name[PLATFORM_MAX_PATH+1];
	decl String:buffer[PLATFORM_MAX_PATH+1];
	if (strlen(name) > 0)
	{
		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		do
		{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (strcmp(name, buffer, false) == 0)
			{
				cat_name = buffer;
				break;
			}
		} while (KvGotoNextKey(listfile));
	}
	else
	{
		decl String:SelectionInfo[PLATFORM_MAX_PATH+1];
		if ((cat_menu != INVALID_HANDLE) && GetMenuItem(cat_menu, pos, SelectionInfo, sizeof(SelectionInfo)))
		{
			KvRewind(listfile);
			KvGotoFirstSubKey(listfile);
			do
			{
				KvGetSectionName(listfile, buffer, sizeof(buffer));
				if (strcmp(SelectionInfo, buffer, false) == 0)
				{
					cat_name = buffer;
					break;
				}
			} while (KvGotoNextKey(listfile));
		}
	}

	decl String:buffer2[PLATFORM_MAX_PATH+1];
	KvRewind(listfile);
	if (KvJumpToKey(listfile, cat_name))
	{
		sound_menu = CreateMenu(AdminSoundsMenuHandler);
		SetMenuTitle(sound_menu, cat_name);
		KvGotoFirstSubKey(listfile);
		do
		{
			KvGetSectionName(listfile, buffer2, sizeof(buffer2));
			AddMenuItem(sound_menu, buffer2, buffer2);
		} while (KvGotoNextKey(listfile));

		SetMenuExitBackButton(sound_menu, true);
		DisplayMenu(sound_menu, client, GetConVarInt(g_CvarMenuTime));
	}
	else
	{
		LogError("Subkey not found in the config file!");
	}

	return Plugin_Handled;
}

public AdminSoundsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:buffer[PLATFORM_MAX_PATH+1];
		GetMenuTitle(menu, buffer, sizeof(buffer));
		PlaySound(param1, param2, buffer);
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
	{
		AS_CatMenu(param1, 0);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// Loads the soundsList array with the quake sounds
public Action:Load_Sounds()
{
	SetupPreloadTrie();

	// precache sounds, loop through sounds
	BuildPath(Path_SM, soundlistfile, sizeof(soundlistfile), "configs/soundslist.cfg");
	if (!FileExists(soundlistfile))
	{
		SetFailState("soundslist.cfg not parsed...file doesnt exist!");
	}
	else
	{
		if (listfile != INVALID_HANDLE)
		{
			CloseHandle(listfile);
		}
		listfile = CreateKeyValues("Admin Sounds");
		if (FileToKeyValues(listfile, soundlistfile))
		{
			KvRewind(listfile);
			if (KvGotoFirstSubKey(listfile))
			{
				decl String:cat_name[PLATFORM_MAX_PATH+1];
				decl String:name[PLATFORM_MAX_PATH+1];
				decl String:filelocation[PLATFORM_MAX_PATH+1];
				decl String:dl[PLATFORM_MAX_PATH+1];
				new download;
				g_numSounds = 0;
				do
				{
					KvGetSectionName(listfile, cat_name, sizeof(cat_name));
//					LogMessage("Category : %s", cat_name);
					KvGotoFirstSubKey(listfile);
					do
					{
						KvGetSectionName(listfile, name, sizeof(name));
						filelocation[0] = '\0';
						KvGetString(listfile, "file", filelocation, sizeof(filelocation), "");
						if (filelocation[0] != '\0')
						{
							download = KvGetNum(listfile, "download", 1);
							Format(dl, sizeof(dl), "sound/%s", filelocation);
							if (FileExists(dl))
							{
								if (download)
									AddFileToDownloadsTable(dl);
//								LogMessage("Loaded sound %s (file : %s - dl : %d)", name, filelocation, download);
								g_numSounds++;
							}
							else
							{
								LogError("Sound file %s (name : %s) does not exist", filelocation, name);							
							}
						}
					} while(KvGotoNextKey(listfile));
					KvRewind(listfile);
					KvJumpToKey(listfile, cat_name);
				} while (KvGotoNextKey(listfile));
			
				LogMessage("%d sounds loaded", g_numSounds);	
			}
			else
			{
				SetFailState("soundslist.cfg not parsed... No subkeys found!");
			}
		}
		else
		{
			SetFailState("soundslist.cfg not parsed... Failed to convert into KeyValue!");
		}
	}
	return Plugin_Handled;
}

public PlaySound(client, item, String:cat_name[])
{
	if ((GetTime() > g_timeNextPlay) || CheckImmunity(client, g_CvarTimeImmunity))
	{
		decl String:SelectionInfo[PLATFORM_MAX_PATH+1];
		decl String:buffer[PLATFORM_MAX_PATH+1];
		decl String:sound_cat[PLATFORM_MAX_PATH+1];
		decl String:sound_name[PLATFORM_MAX_PATH+1];
		decl String:sound_filelocation[PLATFORM_MAX_PATH+1];
		new cat_delay, sound_delay, cat_display, sound_display, cat_stop, sound_stop;
		new Float:cat_volume, Float:sound_volume;
		if (GetMenuItem(sound_menu, item, SelectionInfo, sizeof(SelectionInfo)))
		{
			KvRewind(listfile);
			if (KvJumpToKey(listfile, cat_name))
			{
				cat_delay = KvGetNum(listfile, "delay", GetConVarInt(g_CvarDelay));
				cat_volume = KvGetFloat(listfile, "volume", GetConVarFloat(g_CvarVolume));
				cat_display = KvGetNum(listfile, "display", GetConVarInt(g_CvarDisplay));
				cat_stop = KvGetNum(listfile, "stop", GetConVarInt(g_CvarStop));
				KvGotoFirstSubKey(listfile);
				do
				{
					KvGetSectionName(listfile, buffer, sizeof(buffer));
					if (strcmp(SelectionInfo, buffer, false) == 0)
					{
						strcopy(sound_cat, sizeof(sound_cat), cat_name);
						sound_name = buffer;
						sound_filelocation[0] = '\0';
						KvGetString(listfile, "file", sound_filelocation, sizeof(sound_filelocation));
						if (sound_filelocation[0] != '\0')
						{
							sound_delay = KvGetNum(listfile, "delay", cat_delay);
							sound_volume = KvGetFloat(listfile, "volume", cat_volume);
							sound_display = KvGetNum(listfile, "display", cat_display);
							sound_stop = KvGetNum(listfile, "stop", cat_stop);
							if (sound_volume > 1.0)
								sound_volume = 1.0; // Max value for the volume
						}
						break;
					}
				} while (KvGotoNextKey(listfile));
			}
			else
			{
				LogError("Subkey not found in the config file!");
			}
		}
		else
		{
			LogError("Item not found!");
		}
			
		if (sound_filelocation[0] != '\0')
		{
			new clientlist[MAXPLAYERS+1];
			new clientcount = 0;
			for(new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && !SndPlaying[i])
				{
					if (!StopAll[i])
					{
						clientlist[clientcount++] = i;
						SndPlaying[i] = 1;
						strcopy(SndPlayingName[i], sizeof(SndPlayingName[]), sound_filelocation);
					}
					else
					{
						PrintToChat(i, "\x04[SM] Admin Sounds: \x01%t \x04!stopall\x01 %t", "Stop_Type", "StopAll Reenabled");
					}
				}
			}
			if (clientcount)
			{
				if (PrepareSound(sound_filelocation))
				{
					EmitSound(clientlist, clientcount, sound_filelocation, .volume=sound_volume);
					if (sound_display)
					{
						PrintToChatAll("\x04[SM] Admin Sounds - \x01%t", "Now playing", sound_name);
//						PrintToChatAll("\x04[SM] Admin Sounds - \x01%t - cat: %s - delay: %d - volume: %f - stop: %d", "Now playing", sound_name, sound_cat, sound_delay, sound_volume, sound_stop); // test
					}
					if (sound_stop)
					{
						decl String:buffer2[255];
						Format(buffer2, sizeof(buffer2), "\x01[SM] %t \x04!stop\x01 %t", "Stop_Type", "Stop_to");
						for(new i = 0; i < clientcount; i++)
						{
							PrintToChat(clientlist[i], buffer2);
						}
					}
					if (g_StopCookie != INVALID_HANDLE)
					{
						decl String:buffer3[255];
						Format(buffer3, sizeof(buffer3), "\x01[SM] %t \x04!stopall\x01 %t", "Stop_Type", "StopAll_to");
						for(new i = 0; i < clientcount; i++)
						{
							PrintToChat(clientlist[i], buffer3);
						}
					}
				}
				else
				{
					LogError("Failed to precache sound %s (file : %s)", sound_name, sound_filelocation);
				}
			}
			
			if (sound_delay > 0)
			{
				g_timeNextPlay = GetTime() + sound_delay;
				CreateTimer(float(sound_delay), Timer_ResetSound);
			}
			
			LogAction(client, -1, "\"%L\" launch the sound %s - \"%s\"", client, sound_cat, sound_name);
			
			// Display again the menu
			if (GetConVarBool(g_CvarMenuReprint))
				AdminSoundsMenu(client, 0, sound_cat);
		}
		else
		{
			LogError("File %s not found", sound_name);
		}
	}
	else
	{
		PrintToChat(client, "\x04[SM] Admin Sounds: \x01%t", "Wait a moment");
	}
}

public Action:Timer_ResetSound(Handle:timer, any:dp) {
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if (SndPlaying[i])
		{
			SndPlaying[i] = 0;
		}
	}
}

public Action:Command_StopPlayedSound(client, args)
{
	if (!client)
		return Plugin_Handled;

	if (CheckImmunity(client, g_CvarAdminStop))
	{
		if (StopSounds())
		{
			decl String:name[35];
			GetClientName(client, name, sizeof(name));

			PrintToChatAll("%t", "AdminStopSounds", name);
			LogAction(client, -1, "\"%L\" Stop Played Sound", client);
		}
		else
		{
			PrintToConsole(client, "%t", "NoSoundPlayed");
		}
	}
	else
	{
		PrintToConsole(client, "%t", "AdminCantStop");
	}
	return Plugin_Handled;
}

public Action:Command_Sound_List(client, args)
{
	List_Sounds(client);
	return Plugin_Handled;
}

stock List_Sounds(client)
{
	KvRewind(listfile);
	KvGotoFirstSubKey(listfile);

	decl String:buffer[PLATFORM_MAX_PATH+1];
	decl String:buffer2[PLATFORM_MAX_PATH+1];
	decl String:tempbuffer[PLATFORM_MAX_PATH+1];
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	new String:code_lang[4];
	new String:cat_name[PLATFORM_MAX_PATH+1];
	new String:cat_langname[PLATFORM_MAX_PATH+1];
	PrintToConsole(client, "[Admin Sounds] Default params : delay=%d - volume=%.2f - stop=%d", GetConVarInt(g_CvarDelay), GetConVarFloat(g_CvarVolume), GetConVarBool(g_CvarStop));
	do
	{
		KvGetSectionName(listfile, cat_name, sizeof(cat_name));
		strcopy(buffer, sizeof(buffer), cat_name);
		for(new i = 0; i < GetLanguageCount(); i++)
		{
			GetLanguageInfo(i, code_lang, sizeof(code_lang));
			cat_langname[0] = '\0';
			KvGetString(listfile, code_lang, cat_langname, sizeof(cat_langname), "");
			if (cat_langname[0] != '\0')
			{
				Format(tempbuffer, sizeof(tempbuffer), " - %s : \"%s\"", code_lang, cat_langname);
				StrCat(cat_name, sizeof(cat_name), tempbuffer);
			}
		}
		new Float:cat_volume = KvGetFloat(listfile, "volume");
		if (cat_volume)
		{
			Format(tempbuffer, sizeof(tempbuffer), " - volume : %.2f", cat_volume);
			StrCat(cat_name, sizeof(cat_name), tempbuffer);
		}
		new cat_delay = KvGetNum(listfile, "delay");
		if (cat_delay)
		{
			Format(tempbuffer, sizeof(tempbuffer), " - delay : %d", cat_delay);
			StrCat(cat_name, sizeof(cat_name), tempbuffer);
		}
		new cat_display = KvGetNum(listfile, "display");
		if (cat_display)
		{
			Format(tempbuffer, sizeof(tempbuffer), " - display : %d", cat_display);
			StrCat(cat_name, sizeof(cat_name), tempbuffer);
		}
		new cat_stop = KvGetNum(listfile, "stop");
		if (cat_stop)
		{
			Format(tempbuffer, sizeof(tempbuffer), " - stop : %d", cat_stop);
			StrCat(cat_name, sizeof(cat_name), tempbuffer);
		}
		PrintToConsole(client, cat_name);
		KvGotoFirstSubKey(listfile);
		do
		{
			KvGetSectionName(listfile, buffer2, sizeof(buffer2));
			filelocation[0] = '\0';
			KvGetString(listfile, "file", filelocation, sizeof(filelocation));
			Format(buffer2, sizeof(buffer2), "- %s (\"%s\"", buffer2, filelocation);
			new Float:volume = KvGetFloat(listfile, "volume");
			if (volume)
			{
				Format(tempbuffer, sizeof(tempbuffer), " - volume : %.2f", volume);
				StrCat(buffer2, sizeof(buffer2), tempbuffer);
			}
			new delay = KvGetNum(listfile, "delay");
			if (delay)
			{
				Format(tempbuffer, sizeof(tempbuffer), " - delay : %d", delay);
				StrCat(buffer2, sizeof(buffer2), tempbuffer);
			}
			new display = KvGetNum(listfile, "display");
			if (display)
			{
				Format(tempbuffer, sizeof(tempbuffer), " - display : %d", display);
				StrCat(buffer2, sizeof(buffer2), tempbuffer);
			}
			new stop = KvGetNum(listfile, "stop");
			if (stop)
			{
				Format(tempbuffer, sizeof(tempbuffer), " - stop : %d", stop);
				StrCat(buffer2, sizeof(buffer2), tempbuffer);
			}
			StrCat(buffer2, sizeof(buffer2), ")");
			PrintToConsole(client, buffer2);
		} while (KvGotoNextKey(listfile));
		KvRewind(listfile);
		KvJumpToKey(listfile, buffer);
	} while (KvGotoNextKey(listfile));
}

public Action:Command_Say(client, args)
{
	if (!client || (!GetConVarBool(g_CvarStop) && (g_StopCookie == INVALID_HANDLE)))
		return Plugin_Continue;

	decl String:speech[128];
	decl String:clientName[64];
	decl String:clientAuth[64];
	GetCmdArgString(speech,sizeof(speech));
	GetClientName(client, clientName, 64);
	GetClientAuthId(client, AuthId_Steam2, clientAuth, sizeof(clientAuth));

	new startidx = 0;
	if (speech[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		new len = strlen(speech);
		if (speech[len-1] == '"')
		{
			speech[len-1] = '\0';
		}
	}

	// Stop current sound
	if (strcmp(speech[startidx], "!stop", false) == 0)
	{
		if (SndPlaying[client])
		{
			StopSound(client, SNDCHAN_AUTO, SndPlayingName[client]);
			SndPlaying[client] = 0;
		}
		else
		{
			PrintToChat(client, "%t", "NoSoundPlayed");		
		}
		return Plugin_Handled;
	}

	// Stop all sounds
	if (strcmp(speech[startidx], "!stopall", false) == 0)
	{
		if (g_StopCookie != INVALID_HANDLE)
		{
			if (!StopAll[client])
			{
				if (SndPlaying[client])
				{
					StopSound(client, SNDCHAN_AUTO, SndPlayingName[client]);
					SndPlaying[client] = 0;
				}
				SetClientCookie(client, g_StopCookie, "on");
				StopAll[client] = 1;
				PrintToChat(client, "\x04[SM] Admin Sounds: \x01%t", "StopAll Enabled");
				LogMessage("%s<%s> disable all sounds", clientName, clientAuth);
			}
			else
			{
				SetClientCookie(client, g_StopCookie, "off");
				StopAll[client] = 0;
				PrintToChat(client, "\x04[SM] Admin Sounds: \x01%t", "StopAll Disabled");
				LogMessage("%s<%s> reenable all sounds", clientName, clientAuth);
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock SetupPreloadTrie()
{
    if (g_precacheTrie == INVALID_HANDLE)
        g_precacheTrie = CreateTrie();
    else
        ClearTrie(g_precacheTrie);
}

stock bool:PrepareSound(const String:sound[], bool:preload=true)
{
	//if (!IsSoundPrecached(sound))
	new bool:value;
	if (!GetTrieValue(g_precacheTrie, sound, value))
	{
		if (PrecacheSound(sound, preload))
		{
			SetTrieValue(g_precacheTrie, sound, true);
			return true;
		}
		else
		{
			return false;
		}
	}
	return true;
}

stock bool:CheckImmunity(client, Handle:cvar_immunity)
{
	if (!client)
		return false;

	new AdminId:adminid = GetUserAdmin(client);
	if (adminid == INVALID_ADMIN_ID)
		return false;

	new AdminFlag:flag;
	decl String:immunity[3];
	GetConVarString(cvar_immunity, immunity, sizeof(immunity));
	if (!FindFlagByChar(immunity[0], flag))
		return false;

	return GetAdminFlag(adminid , flag);
}

stock bool:StopSounds()
{
	new clientcount = 0;
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && SndPlaying[i])
		{
			StopSound(i, SNDCHAN_AUTO, SndPlayingName[i]);
			SndPlaying[i] = 0;
			clientcount++;
		}
	}

	if (clientcount > 0)
		return true;

	return false;
}
