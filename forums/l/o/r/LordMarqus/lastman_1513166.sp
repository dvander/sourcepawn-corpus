#include <sourcemod>
#include <sdktools>
#include <colors>
#include <clientprefs>

#define PLUGIN_VERSION 		"1.0.2"
#define CSS_TEAM_T			2
#define CSS_TEAM_CT			3

new Handle:g_hCvarSoundPath 		= INVALID_HANDLE;
new Handle:g_hCvarEnabled			= INVALID_HANDLE;
new Handle:g_hCvarDefaultChat		= INVALID_HANDLE;
new Handle:g_hCvarDefaultSound		= INVALID_HANDLE;
new Handle:g_hCvarSoundVolume		= INVALID_HANDLE;
new Handle:g_hCvarPublicChat		= INVALID_HANDLE;
new Handle:g_hCvarVersion			= INVALID_HANDLE;

new Handle:g_hPrefsCookie 			= INVALID_HANDLE;

new g_iLastManIndex 				= -1;
new g_iOpponentsNum 				= 0;
new g_iOpponentsLeft 				= 0;

new bool:g_bEventsHooked 				= false;
new bool:g_bSoundPrefs[MAXPLAYERS + 1] 	= {true, ...};
new bool:g_bChatPrefs[MAXPLAYERS + 1] 	= {true, ...};

new String:g_sSoundNamePath[PLATFORM_MAX_PATH];

public Plugin:myinfo = 
{
	name = "LastManStanding",
	author = "LordMarqus",
	description = "Last Man Standing announcer plugin",
	version = PLUGIN_VERSION,
	url = "http://bloodlords.eu"
};

public OnPluginStart()
{
	g_hCvarVersion = CreateConVar("lastman_version", PLUGIN_VERSION, "LastManStanding plugin version", FCVAR_NOTIFY);
	g_hCvarSoundPath = CreateConVar("lastman_sound", "lastman.wav", "Patch to a sound file in a cstrike/sound folder");
	g_hCvarDefaultChat = CreateConVar("lastman_default_chat", "1", "Set 1 to show chat notifications about enemies left for a new players", _, true, 0.0, true, 1.0);
	g_hCvarDefaultSound = CreateConVar("lastman_default_sound", "1", "Set 1 to play a sound for a new players", _, true, 0.0, true, 1.0);
	g_hCvarSoundVolume = CreateConVar("lastman_sound_volume", "1.0", "Last man sound volume level (set 1.0 for sound's original)", _, true, 0.1, true, 1.0);
	g_hCvarPublicChat = CreateConVar("lastman_public_chat", "1", "Set 1 to show public chat notifications", _, true, 0.0, true, 1.0);
	g_hCvarEnabled = CreateConVar("lastman_enabled", "1", "Enable/disable plugin", _, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, ConVarChange_Enabled);
	HookEvents();
	
	RegConsoleCmd("lastman", LastManPrefsCommand, "Opens LastManStanding player settings (also available in !settings menu)");
	
	g_hPrefsCookie = RegClientCookie("LastManSettings", "LastManStanding plugin settings", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, "Last Man Standing");
	
	LoadTranslations("lastman.phrases");
	AutoExecConfig(true, "lastman");
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:enabled = GetConVarBool(convar);
	HookEvents(enabled);
}

HookEvents(bool:enabled = true)
{
	if(enabled)
	{
		if(!g_bEventsHooked)
		{
			HookEvent("player_death", EventPlayerDeath);
			HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
			HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
			g_bEventsHooked = true;
		}
	}
	else
	{
		if(g_bEventsHooked)
		{
			UnhookEvent("player_death", EventPlayerDeath);
			UnhookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
			UnhookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
			g_bEventsHooked = false;
		}
	}
}

public Action:LastManPrefsCommand(client, args)
{
	decl String:buffer[8];
	PrefMenu(client, CookieMenuAction_SelectOption, 0, buffer, sizeof(buffer));
	
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	GetConVarString(g_hCvarSoundPath, g_sSoundNamePath, PLATFORM_MAX_PATH);
	
	PrecacheSound(g_sSoundNamePath, true);
	decl String:buffer[PLATFORM_MAX_PATH];
	Format(buffer, sizeof(buffer), "sound/%s", g_sSoundNamePath);
	AddFileToDownloadsTable(buffer);
	
	g_iLastManIndex = -1;
	
	SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iLastManIndex = -1;
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iLastManIndex = -1;
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iLastManIndex != -1)
	{
		new killedClient = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_iLastManIndex == killedClient)
			g_iLastManIndex = -1;
		else
		{
			if(--g_iOpponentsLeft != 1 && g_iLastManIndex && IsClientInGame(g_iLastManIndex))
			{
				if(g_iOpponentsLeft == 0)
				{
					decl String:playerName[MAX_NAME_LENGTH];
					GetClientName(g_iLastManIndex, playerName, MAX_NAME_LENGTH);
					if (GetConVarBool(g_hCvarPublicChat))
						CPrintToChatAllEx(g_iLastManIndex, "%t", "Player won public", playerName, g_iOpponentsNum);
					g_iLastManIndex = -1;
				}
				else
				{
					if (g_bChatPrefs[g_iLastManIndex])
						CPrintToChat(g_iLastManIndex, "%t", "Enemies left", g_iOpponentsLeft);
				}
			}
		}
	}
	else
	{
		new ctNum = 0, ctIndex, tNum = 0, tIndex, team;
		for(new i = 1; i <= MaxClients; ++i)
		{			
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				team = GetClientTeam(i);
				if(team == CSS_TEAM_CT)
				{
					++ctNum;
					ctIndex = i;
				}
				else if(team == CSS_TEAM_T)
				{
					++tNum;
					tIndex = i;
				}
			}
			
			if(ctNum > 1 && tNum > 1)
				return;
		}
		
		if(ctNum != tNum)
		{
			if(ctNum == 1 && tNum > 1)
			{
				g_iLastManIndex = ctIndex;
				g_iOpponentsNum = g_iOpponentsLeft = tNum;
			}
			else if(tNum == 1 && ctNum > 1)
			{
				g_iLastManIndex = tIndex;
				g_iOpponentsNum = g_iOpponentsLeft = ctNum;
			}
			else
				return;
		}
		else
			return;
		
		decl String:playerName[MAX_NAME_LENGTH];
		GetClientName(g_iLastManIndex, playerName, MAX_NAME_LENGTH);
		if (GetConVarBool(g_hCvarPublicChat))
			CPrintToChatAllEx(g_iLastManIndex, "%t", "Public chat", playerName, g_iOpponentsNum);
		if(!IsFakeClient(g_iLastManIndex) && g_bSoundPrefs[g_iLastManIndex])
			EmitSoundToClient(g_iLastManIndex, g_sSoundNamePath, _, _, _, _, GetConVarFloat(g_hCvarSoundVolume));
	}
}

// Format: (chat,sound)
public OnClientCookiesCached(client)
{
	if (!IsClientConnected(client) || IsFakeClient(client))
		return;
	
	decl String:pref[8];
	GetClientCookie(client, g_hPrefsCookie, pref, sizeof(pref));
	
	if (StrEqual(pref, ""))
	{
		g_bChatPrefs[client] = GetConVarBool(g_hCvarDefaultChat);
		g_bSoundPrefs[client] = GetConVarBool(g_hCvarDefaultSound);
	}
	else
	{
		new String:settings[2][4];
		ExplodeString(pref, ",", settings, 2, 4);
		g_bChatPrefs[client] = bool:StringToInt(settings[0]);
		g_bSoundPrefs[client] = bool:StringToInt(settings[1]);
	}
}

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		decl String:menuItem[64];
		new Handle:prefMenu = CreateMenu(PrefMenuHandler);
		
		Format(menuItem, sizeof(menuItem), "%t", "Settings Title");
		SetMenuTitle(prefMenu, menuItem);
		
		Format(menuItem, sizeof(menuItem), "%t%t", "Settings Chat", g_bChatPrefs[client] ? "On" : "Off");
		if (g_bChatPrefs[client])
			AddMenuItem(prefMenu, "0", menuItem);
		else
			AddMenuItem(prefMenu, "1", menuItem);
		
		Format(menuItem, sizeof(menuItem), "%t%t", "Settings Sound", g_bSoundPrefs[client] ? "On" : "Off");
		if (g_bSoundPrefs[client])
			AddMenuItem(prefMenu, "0", menuItem);
		else
			AddMenuItem(prefMenu, "1", menuItem);
		
		SetMenuExitBackButton(prefMenu, true);
		DisplayMenu(prefMenu, client, MENU_TIME_FOREVER);
	}
}

public PrefMenuHandler(Handle:prefMenu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		decl String:pref[8];
		GetMenuItem(prefMenu, item, pref, sizeof(pref));
		
		if (item == 0)
			g_bChatPrefs[client] = bool:StringToInt(pref);
		else if (item == 1)
			g_bSoundPrefs[client] = bool:StringToInt(pref);
		
		Format(pref, sizeof(pref), "%d,%d", g_bChatPrefs[client], g_bSoundPrefs[client]);
		SetClientCookie(client, g_hPrefsCookie, pref);
		
		decl String:buffer[8];
		PrefMenu(client, CookieMenuAction_SelectOption, 0, buffer, sizeof(buffer));
	}
	else if(action == MenuAction_Cancel)
	{
		if(item == MenuCancel_ExitBack)
			ShowCookieMenu(client);
	}
	else if (action == MenuAction_End)
		CloseHandle(prefMenu);
}

	