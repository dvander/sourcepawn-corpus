#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <menus>

#define _DEBUG		0	// Set to 1 to have debug spew

#define PLUGIN_VERSION	"0.0.2.0"

new String:sound_file[PLATFORM_MAX_PATH];
new String:PlayerSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];

new Handle:g_cookie;
new Handle:g_cookie2;
new Handle:g_SoundMenu = INVALID_HANDLE;
new Handle:ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:ClientTimer2[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new bool:Enabled = true;

new Float:DelaySoundTime;

public Plugin:myinfo = 
{
	name = "Custom Join Sound",
	author = "TnTSCS aKa ClarkKent",
	description = "Play join sound based on player joining",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	new Handle:hRandom; // KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_cjs_version", PLUGIN_VERSION, 
	"The version of 'Custom Join Sound'", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_cjs_enabled", "1", 
	"Plugin Enabled?.", FCVAR_NONE, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_cjs_time", "5", 
	"Number of seconds to delay the join sound from starting after the player joins.", FCVAR_NONE, true, 0.0, true, 30.0)), OnTimeDelayChanged);
	DelaySoundTime = GetConVarFloat(hRandom);
	
	CloseHandle(hRandom);
	
	BuildPath(Path_SM, sound_file, PLATFORM_MAX_PATH, "configs/join_sounds.ini");
	
	g_cookie = RegClientCookie("join-sound-played", "Join Sound Already Played", CookieAccess_Protected);
	g_cookie2 = RegClientCookie("join-sound-name", "Name of Join Sound", CookieAccess_Protected);
	
	SetCookieMenuItem(Menu_Status, 0, "Display Join Sound");
	
	HookEvent("player_disconnect", Event_Disconnect);
	
	RegConsoleCmd("sm_joinsound", Command_ChangeJoinSound);
}

public OnMapStart()
{
	g_SoundMenu = BuildSoundMenu();
}

public OnMapEnd()
{
	if (g_SoundMenu != INVALID_HANDLE)
	{
		CancelMenu(g_SoundMenu);
		CloseHandle(g_SoundMenu);
		g_SoundMenu = INVALID_HANDLE;
	}
}

public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "Display Selected Join Sound");
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		CreateMenuStatus(client);
	}
}

CreateMenuStatus(client)
{
	new Handle:menu = CreateMenu(Menu_StatusDisplay);
	decl String:text[64];
	decl String:cookie[35];
	
	Format(text, sizeof(text), "Selected Join Sound");
	SetMenuTitle(menu, text);

	GetClientCookie(client, g_cookie2, cookie, sizeof(cookie));
	
	ReplaceString(cookie, sizeof(cookie), "joinsound/", "", false);
	
	AddMenuItem(menu, "sound", cookie, ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, true);
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 15);
}

public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	
	switch (action)
	{
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					ShowCookieMenu(client);
				}
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

Handle:BuildSoundMenu()
{
	/* Open the sound file */
	new Handle:file = OpenFile(sound_file, "r");
	
	if (file == INVALID_HANDLE)
	{
		SetFailState("Unable to open file %s", sound_file);
		return INVALID_HANDLE;
	}
	
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_SelectSound);
	
	decl String:soundname[PLATFORM_MAX_PATH];
	soundname[0] = '\0';
	
	decl String:soundname2[PLATFORM_MAX_PATH];
	soundname2[0] = '\0';
	
	new count = 0;
	
	while (!IsEndOfFile(file) && ReadFileLine(file, soundname, sizeof(soundname)))
	{
		if (soundname[0] == ';' || !IsCharAlpha(soundname[0]))
		{
			continue;
		}
		
		TrimString(soundname);
		
		Format(soundname2, sizeof(soundname2), "sound/joinsound/%s", soundname);
   		
		/* Check if the sound file is valid */
		if (FileExists(soundname2))
		{
			/* Add it to the menu */
			AddMenuItem(menu, soundname, soundname);
			
			Format(soundname, sizeof(soundname), "joinsound/%s", soundname);
			
			#if _DEBUG
				LogMessage("Adding %s to downloads table", soundname2);
			#endif
			AddFileToDownloadsTable(soundname2);
			
			#if _DEBUG
				LogMessage("Precaching %s", soundname);
			#endif
			PrecacheSound(soundname, true);
			
			count++;
		}
		else
		{
			LogError("Unable to open sound file %s", soundname2);
			continue;
		}
	}
	/* Make sure we close the file! */
	CloseHandle(file);
 
	/* Finally, set the title */
	SetMenuTitle(menu, "Please select a join sound:");
	
	LogMessage("Finished loading [%i] sound file(s)", count);
 
	return menu;
}

public Menu_SelectSound(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[255];
		
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
		
		/* Tell the client */
		PrintToChat(param1, "\x03[SM] You selected join sound: %s", info);
		
		/* Change the users join sound */		
		Format(info, sizeof(info), "joinsound/%s", info);
		
		SetClientCookie(param1, g_cookie2, info);
	}
}

public Action:Command_ChangeJoinSound(client, args)
{
	if (g_SoundMenu == INVALID_HANDLE)
	{
		PrintToConsole(client, "The join_sounds.ini file was not found!");
		return Plugin_Handled;
	}
	
	if (!CheckCommandAccess(client, "allow_custom_join_sound", ADMFLAG_CUSTOM1))
	{
		return Plugin_Handled;
	}
	
	DisplayMenu(g_SoundMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	if (Enabled && !IsFakeClient(client) && CheckCommandAccess(client, "allow_custom_join_sound", ADMFLAG_CUSTOM1))
	{
		#if _DEBUG
			LogMessage("Starting timer to check cookies for %L", client);
		#endif
		
		ClientTimer2[client] = CreateTimer(2.0, Timer_CheckCookies, client, TIMER_REPEAT);
	}
}

bool:GetClientJoinSound(client)
{
	if (!IsClientInGame(client))
	{
		#if _DEBUG
			LogMessage("GetClientJoinSound for %L failed because client is not in game.", client);
		#endif
		
		return false;
	}
	
	GetClientCookie(client, g_cookie2, PlayerSound[client], sizeof(PlayerSound[]));
	
	#if _DEBUG
		LogMessage("Sound file for %L is %s", client, PlayerSound[client]);
	#endif
	
	if (strcmp(PlayerSound[client], ""))
	{
		return true;
	}
	
	return false;
}

public Action:Timer_CheckCookies(Handle:timer, any:client)
{
	if (AreClientCookiesCached(client))
	{
		ClientTimer2[client] = INVALID_HANDLE;
		
		if (!GetClientJoinSound(client))
		{
			#if _DEBUG
				LogMessage("%L does not have a sound configured.", client);
			#endif
			
			return Plugin_Stop;
		}
		
		if (!PlayerJoinSoundPlayed(client))
		{
			if (DelaySoundTime > 0)
			{
				#if _DEBUG
					LogMessage("Starting Timer_PlaySound for %L", client);
				#endif
				
				ClientTimer[client] = CreateTimer(DelaySoundTime, Timer_PlaySound, client, TIMER_REPEAT);
			}
			else
			{
				#if _DEBUG
					LogMessage("About to PlayJoinSound for %L", client);
				#endif
				
				PlayJoinSound(client);
			}
		}
		else
		{
			#if _DEBUG
				LogMessage("%L already had sound played this connect session.", client);
			#endif
		}
		
		return Plugin_Stop;
	}
	
	#if _DEBUG
		LogMessage("%L cookies not cached, yet", client);
	#endif
	
	return Plugin_Continue;
}

public Action:Timer_PlaySound(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		ClientTimer[client] = INVALID_HANDLE;
		
		#if _DEBUG
			LogMessage("About to PlayJoinSound for %L from Timer_PlaySound", client);
		#endif
		
		PlayJoinSound(client);
		
		return Plugin_Stop;
	}
	
	#if _DEBUG
		LogMessage("%L still not in game", client);
	#endif
	
	return Plugin_Continue;
}

public PlayJoinSound(client)
{
	if (!IsClientInGame(client))
	{
		#if _DEBUG
			LogMessage("%L left before sound could be played.", client);
		#endif
		
		return;
	}
	
	#if _DEBUG
		LogMessage("Playing Join Sound for %L and setting sound played cookie to 1", client);
	#endif
	
	EmitSoundToAll(PlayerSound[client], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
	
	SetClientCookie(client, g_cookie, "1");
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		ClearTimer(ClientTimer[client]);
		ClearTimer(ClientTimer2[client]);
		
		PlayerSound[client][0] = '\0';
	}
}

public Action:Event_Disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client <= MaxClients && PlayerJoinSoundPlayed(client))
	{
		#if _DEBUG
			LogMessage("%L is leaving, setting sound played cookie to 0", client);
		#endif
		
		SetClientCookie(client, g_cookie, "0");
	}
}

bool:PlayerJoinSoundPlayed(client)
{
	decl String:cookie[32];
	cookie[0] = '\0';
	
	GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
	
	if (StrEqual(cookie, "1"))
	{
		return true;
	}
	
	return false;
}

public ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Enabled = GetConVarBool(cvar);
}

public OnTimeDelayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DelaySoundTime = GetConVarFloat(cvar);
}