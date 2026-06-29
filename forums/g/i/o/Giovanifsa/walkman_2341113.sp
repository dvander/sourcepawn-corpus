#include <sourcemod>
#include <sdktools>

//*******************************************************
//*						DEFINES							*
//*******************************************************
#define PLUGIN_VERSION "1.0.3"

//*******************************************************
//*						VARS							*
//*******************************************************
static String:KVPath[PLATFORM_MAX_PATH]; //Don't touch
new String:musicCache[MAXPLAYERS+1][512];
new String:killmusicCache[MAXPLAYERS+1][512];
new Float:musicDuration[MAXPLAYERS+1];
new bool:musicsActive[MAXPLAYERS+1];

new Handle:musicRepeater[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "[ANY] WalkMan",
	author = "Nescau",
	description = "Plays a sound for you and players near you, and a custom sound when you kill enemies.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/nescaufsa/"
};

public OnPluginStart()
{
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "configs/soundfiles.txt");
	RegAdminCmd("sm_walkman", OPEN_SOUNDMENU, ADMFLAG_GENERIC, "Opens the WalkMan menu.");
	RegAdminCmd("sm_walkmanrefresh", REFRESH, ADMFLAG_ROOT, "Refresh the WalkMan sounds.");
	HookEvent("player_death", PLAYER_DIED, EventHookMode_Pre);
}

public OnMapStart()
{
	PrecacheKeyValues();
}

public Action:REFRESH(client, args)
{
	PrecacheKeyValues();
	ReplyToCommand(client, "[WalkMan] Sounds refreshed.");
}

//*********************************************************
//*PRECACHES THE SOUND IF IT DOESN'T HAVE ERRORS ON THE KV*
//*********************************************************

public PrecacheKeyValues()
{
	new Handle:DB = CreateKeyValues("WalkMan");
	FileToKeyValues(DB, KVPath);
	
	new String:titleBuffer[512];
	new String:fileBuffer[512];
	new String:durationBuffer[512];
	new String:killBuffer[512];
	new String:killBufferTitle[512];
	
	new String:DTKill[512];
	new String:DTfile[512];
	new String:sectionBuffer[512];
	
	
	if(KvGotoFirstSubKey(DB))
	{
		KvGetSectionName(DB, sectionBuffer, 512);
		KvGetString(DB, "title", titleBuffer, 512, "EMPTY");
		KvGetString(DB, "soundfile", fileBuffer, 512, "EMPTY");
		KvGetString(DB, "duration", durationBuffer, 512, "EMPTY");
		KvGetString(DB, "killtitle", killBufferTitle, 512, "EMPTY");
		KvGetString(DB, "killplay", killBuffer, 512, "EMPTY");
		
		if (!StrEqual(titleBuffer, "EMPTY") && !StrEqual(fileBuffer, "EMPTY") && !StrEqual(durationBuffer, "EMPTY"))
		{
			if (!StrEqual(killBufferTitle, "EMPTY") && !StrEqual(killBuffer, "EMPTY"))
			{
				Format(DTKill, 512, "sound/%s", killBuffer);
				if (FileExists(DTKill, true))
				{
					AddFileToDownloadsTable(DTKill);
					PrecacheSound(killBuffer);
				} else {
					PrintToServer("[WalkMan] Errors found in music %s: File %s doesn't exists.", sectionBuffer, DTKill);
				}
			}
			Format(DTfile, 512, "sound/%s", fileBuffer);
			if (FileExists(DTfile, true))
			{
				AddFileToDownloadsTable(DTfile);
				PrecacheSound(fileBuffer);
			} else {
				PrintToServer("[WalkMan] Errors found in music %s: File %s doesn't exists.", sectionBuffer, DTfile);
			}
		}		
		
		while (KvGotoNextKey(DB))
		{
			KvSavePosition(DB);
			KvGetSectionName(DB, sectionBuffer, 512);
			KvGetString(DB, "title", titleBuffer, 512, "EMPTY");
			KvGetString(DB, "soundfile", fileBuffer, 512, "EMPTY");
			KvGetString(DB, "duration", durationBuffer, 512, "EMPTY");
			KvGetString(DB, "killtitle", killBufferTitle, 512, "EMPTY");
			KvGetString(DB, "killplay", killBuffer, 512, "EMPTY");
			
			if (!StrEqual(titleBuffer, "EMPTY") && !StrEqual(fileBuffer, "EMPTY") && !StrEqual(durationBuffer, "EMPTY"))
			{
				if (!StrEqual(killBufferTitle, "EMPTY") && !StrEqual(killBuffer, "EMPTY"))
				{
					Format(DTKill, 512, "sound/%s", killBuffer);
					if (FileExists(DTKill, true))
					{
						AddFileToDownloadsTable(DTKill);
						PrecacheSound(killBuffer);
					} else {
						PrintToServer("[WalkMan] Errors found in music %s: File %s doesn't exists.", sectionBuffer, DTKill);
					}
				}
				Format(DTfile, 512, "sound/%s", fileBuffer);
				if (FileExists(DTfile, true))
				{
					AddFileToDownloadsTable(DTfile);
					PrecacheSound(fileBuffer);
				} else {
					PrintToServer("[WalkMan] Errors found in music %s: File %s doesn't exists.", sectionBuffer, DTfile);
				}
			}		
		}
	}
	
	KvRewind(DB);
	KeyValuesToFile(DB, KVPath);
	CloseHandle(DB);	
}

public Action:PLAYER_DIED(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!StrEqual(killmusicCache[attacker], ""))
	{
		EmitSoundToClient(victim, killmusicCache[attacker]);
	}
}

public Action:OPEN_SOUNDMENU(client, args)
{
	if (client <= MaxClients)
	{
		new Handle:menu = CreateMenu(soundMenu, MenuAction_Select | MenuAction_End);
		SetMenuTitle(menu, "WalkMan\nTitle | Kill Music");
		if (musicsActive[client])
		{
			AddMenuItem(menu, "m_end", "Stop Musics");
		}
		
		new Handle:DB = CreateKeyValues("WalkMan");
		FileToKeyValues(DB, KVPath);
		
		new String:sectionBuffer[512];
		
		new String:titleBuffer[512];
		new String:fileBuffer[512];
		new String:durationBuffer[512];
		new String:killBuffer[512];
		new String:killBufferTitle[512];
		
		new String:menuItem[128];
		new bool:musicsFound;
		
		new String:sKillSound[512];
		new String:sMusic[512];
		
		if (KvGotoFirstSubKey(DB))
		{
			KvGetSectionName(DB, sectionBuffer, 512);
			KvGetString(DB, "title", titleBuffer, 512, "EMPTY");
			KvGetString(DB, "soundfile", fileBuffer, 512, "EMPTY");
			KvGetString(DB, "duration", durationBuffer, 512, "EMPTY");
			KvGetString(DB, "killtitle", killBufferTitle, 512, "EMPTY");
			KvGetString(DB, "killplay", killBuffer, 512, "EMPTY");
			
			if (!StrEqual(titleBuffer, "EMPTY") && !StrEqual(fileBuffer, "EMPTY") && !StrEqual(durationBuffer, "EMPTY"))
			{
				Format(sMusic, 512, "sound/%s", fileBuffer);
				if (FileExists(sMusic, true))
				{
					musicsFound = true;
					if (!StrEqual(killBufferTitle, "EMPTY") && !StrEqual(killBuffer, "EMPTY"))
					{
						Format(sKillSound, 512, "sound/%s", killBuffer);
						if (FileExists(sKillSound, true))
						{
							Format(menuItem, 128, "%s | %s",titleBuffer, killBufferTitle);
							AddMenuItem(menu, sectionBuffer, menuItem);
						} else {
							Format(menuItem, 128, "%s | Don't have", titleBuffer);
							AddMenuItem(menu, sectionBuffer, menuItem);
						}
					} else {
						Format(menuItem, 128, "%s | Don't have", titleBuffer);
						AddMenuItem(menu, sectionBuffer, menuItem);
					}
				}	
			} else {
				PrintToChat(client, "[WalkMan] Sorry, something is wrong: Server-side error.");
				PrintToServer("[WalkMan]: Errors found in music %s, please check config/soundfiles.txt", sectionBuffer);
			}
			
			while (KvGotoNextKey(DB))
			{
				KvSavePosition(DB);
				KvGetSectionName(DB, sectionBuffer, 512);
				KvGetString(DB, "title", titleBuffer, 512, "EMPTY");
				KvGetString(DB, "soundfile", fileBuffer, 512, "EMPTY");
				KvGetString(DB, "duration", durationBuffer, 512, "EMPTY");
				KvGetString(DB, "killtitle", killBufferTitle, 512, "EMPTY");
				KvGetString(DB, "killplay", killBuffer, 512, "EMPTY");
				
				if (!StrEqual(titleBuffer, "EMPTY") && !StrEqual(fileBuffer, "EMPTY") && !StrEqual(durationBuffer, "EMPTY"))
				{
					Format(sMusic, 512, "sound/%s", fileBuffer);
					if (FileExists(sMusic, true))
					{
						musicsFound = true;
						if (!StrEqual(killBufferTitle, "EMPTY") && !StrEqual(killBuffer, "EMPTY"))
						{
							Format(sKillSound, 512, "sound/%s", killBuffer);
							if (FileExists(sKillSound, true))
							{
								Format(menuItem, 128, "%s | %s",titleBuffer, killBufferTitle);
								AddMenuItem(menu, sectionBuffer, menuItem);
							} else {
								Format(menuItem, 128, "%s | Don't have", titleBuffer);
								AddMenuItem(menu, sectionBuffer, menuItem);
							}
						} else {
							Format(menuItem, 128, "%s | Don't have", titleBuffer);
							AddMenuItem(menu, sectionBuffer, menuItem);
						}
					}	
				} else {
					PrintToChat(client, "[WalkMan] Sorry, something is wrong: Server-side error.");
					PrintToServer("[WalkMan]: Errors found in music %s, please check config/soundfiles.txt", sectionBuffer);
				}
			}
		}
		
		if (!musicsFound)
		{
			AddMenuItem(menu, "m_disabled", "No musics found.", ITEMDRAW_DISABLED);
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		CloseHandle(DB);	


		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} else {
		ReplyToCommand(client, "[SM] This command can only be used in-game.");
	}
}

public soundMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:item[128];
			GetMenuItem(menu, param2, item, sizeof(item));
			if (StrEqual(item, "m_end"))
			{
				EndMusics(client);
			} else {
				ExecMusicOnClient(client, item);
			}
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public ExecMusicOnClient(client, const String:item[])
{
	if (!StrEqual(musicCache[client], ""))
	{
		EndMusics(client);
	}
	
	new Handle:DB = CreateKeyValues("WalkMan");
	FileToKeyValues(DB, KVPath);
	
	new String:fileBuffer[512];
	new String:durationBuffer[512];
	new String:killBuffer[512];
	
	new String:sKillSound[512];
	new String:sMusic[512];
	
	if(KvJumpToKey(DB, item, false))
	{	
		KvGetString(DB, "soundfile", fileBuffer, 512, "EMPTY");
		KvGetString(DB, "duration", durationBuffer, 512, "EMPTY");
		KvGetString(DB, "killplay", killBuffer, 512, "EMPTY");
		
		if (!StrEqual(fileBuffer, "EMPTY") && !StrEqual(durationBuffer, "EMPTY"))
		{
			Format(sMusic, 512, "sound/%s", fileBuffer);
			if (FileExists(sMusic, true))
			{
				if (!StrEqual(killBuffer, "EMPTY"))
				{
					Format(sKillSound, 512, "sound/%s", killBuffer);
					if (FileExists(sKillSound, true))
					{
						strcopy(killmusicCache[client], 512, killBuffer);
					} else {
						strcopy(killmusicCache[client], 512, "");
						PrintToChat(client, "[WalkMan] Sorry! The kill music will not play because the file doesn't exists anymore.");
						PrintToServer("[WalkMan] Error found in music %s: File %s doesn't exists anymore.", item, killBuffer);
					}
				} else {
					strcopy(killmusicCache[client], 512, "");
				}
				strcopy(musicCache[client], 512, fileBuffer);
				musicDuration[client] = float(StringToInt(durationBuffer));
				StartMusic(client, musicCache[client], musicDuration[client]);
			} else {
				PrintToChat(client, "[WalkMan] Sorry! Something is wrong: The file of this music doesn't exists anymore.");
				PrintToServer("[WalkMan] Error found in music %s: File %s doesn't exists anymore.", item, fileBuffer);
			}
		}
		
	} else {
		PrintToChat(client, "[WalkMan] Sorry, something is wrong: Server-side error.");
		PrintToServer("[WalkMan] Error detected: music number %s doesn't exists.", item);
	}
	KvRewind(DB);
	
	KeyValuesToFile(DB, KVPath);
	CloseHandle(DB);	
}

public StartMusic(client, const String:file[], Float:time)
{
	EmitSoundToAll(file, client);
	new Handle:pack;
	musicsActive[client] = true;
	
	musicRepeater[client] = CreateDataTimer(time, REPLAYMUSIC, pack, TIMER_REPEAT);
	
	WritePackCell(pack, client);
	WritePackString(pack, file);
}

public Action:REPLAYMUSIC(Handle:timer, Handle:pack)
{
	new String:file[512];
	ResetPack(pack);
	new client = ReadPackCell(pack);
	ReadPackString(pack, file, 512);
	
	StopSound(client, SNDCHAN_AUTO, file);
	
	EmitSoundToAll(file, client);
}

public EndMusics(client)
{
	if (musicsActive[client])
	{
		KillTimer(musicRepeater[client], true);
		musicsActive[client] = false;
		StopSound(client, SNDCHAN_AUTO, musicCache[client]);
		strcopy(musicCache[client], 512, "");
		
		if (!StrEqual(killmusicCache[client], ""))
		{
			for (new a = 1;a <= MaxClients;a++)
			{
				StopSound(a, SNDCHAN_AUTO, killmusicCache[client]);
			}
			strcopy(killmusicCache[client], 512, "");
		}
		
		musicDuration[client] = 0.0;
	}
	
}

public OnClientDisconnect(client)
{
	EndMusics(client);
}

public OnPluginEnd()
{
	for (new a = 1; a <= MaxClients;a++)
	{
		EndMusics(a);
		if (IsClientInGame(a))
			PrintToChat(a, "[WalkMan] The server is ending this plugin, your music has been stoped.");
	}
}

//KeyValues S2