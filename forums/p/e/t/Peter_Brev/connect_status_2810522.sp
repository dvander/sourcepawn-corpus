
/******************************
INCLUDE ALL THE NECESSARY FILES
******************************/

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

/******************************
PLUGIN DEFINES
******************************/

/*Plugin Updater*/
#define UPDATE_URL		   "https://raw.githubusercontent.com/speedvoltage/sourcemod/master/addons/sourcemod/connect_status.upd"

/*Plugin Info*/
#define PLUGIN_NAME		   "HL2MP - Connect Status"
#define PLUGIN_AUTHOR	   "Peter Brev"
#define PLUGIN_VERSION	   "1.0.3"
#define PLUGIN_DESCRIPTION "Formats better looking connecting and disconnect players messages"
#define PLUGIN_URL		   "N/A"

/*Team Colors*/
#define REBELS			   "\x07ff3d42"
#define COMBINE			   "\x079fcaf2"
#define SPEC			   "\x07ff811c"
#define UNASSIGNED		   "\x07f7ff7f"

/******************************
PLUGIN STRINGS
******************************/

char   g_sDisconnectReason[64];

/******************************
PLUGIN CONVARS
******************************/

ConVar g_cEnable;
ConVar g_cTeamplay;

/******************************
PLUGIN INFO
******************************/
public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart()
{
	/*GAME CHECK*/
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_HL2DM)
	{
		SetFailState("[HL2MP] This plugin is intended for Half-Life 2: Deathmatch only.");
	}

	/*UPDATER?*/
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}

	/*HOOKING EVENTS*/
	HookEvent("player_disconnect", playerdisconnect_callback, EventHookMode_Pre);
	HookEvent("player_connect", playerconnect_callback, EventHookMode_Pre);
	HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);

	/*CONVARS*/
	CreateConVar("sm_connect_status_version", PLUGIN_VERSION, "Connect Status Plugin Version");

	g_cEnable	= CreateConVar("sm_connect_status_enable", "1", "Determines if the plugin is enabled", 0, true, 0.0, true, 1.0);
	g_cTeamplay = FindConVar("mp_teamplay");

	/*HOOKING CONVARS*/
	HookConVarChange(g_cTeamplay, OnConVarChanged_Teamplay);

	AutoExecConfig(true, "connect_status");

	if (GetConVarBool(g_cEnable))
		PrintToServer("[HL2MP] Connect Status is enabled.");
	else
		PrintToServer("[HL2MP] Connect Status is disabled.");
}

public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action playerdisconnect_callback(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(g_cEnable))
	{
		SetEventBroadcast(event, true);
		GetEventString(event, "reason", g_sDisconnectReason, sizeof(g_sDisconnectReason));
		return Plugin_Handled;
	}
	else return Plugin_Continue;
}

public Action playerconnect_callback(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(g_cEnable))
	{
		SetEventBroadcast(event, true);
		return Plugin_Handled;
	}
	else return Plugin_Continue;
}

public bool OnClientConnect(int client)
{
	if (GetConVarBool(g_cEnable))
	{
		PrintToChatAll("\x04%N \x01is connecting...", client);
	}
	return true;
}

public void OnClientPutInServer(int client)
{
	if (GetConVarBool(g_cEnable))
	{
		int c_Teamplay;
		c_Teamplay = GetConVarInt(FindConVar("mp_teamplay"));
		if (c_Teamplay == 0)
		{
			PrintToChatAll("\x04%N \x01is connected.", client);
			return;
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (GetConVarBool(g_cEnable))
	{
		if (!IsClientInGame(client))
		{
			PrintToChatAll("%s%N \x01has disconnected [\x04%s\x01]", UNASSIGNED, client, g_sDisconnectReason);
			return;
		}

		int team;
		team = GetClientTeam(client);

		if (!GetClientTeam(client))
		{
			PrintToChatAll("\x04%N \x01has disconnected - [\x04%s\x01]", client, g_sDisconnectReason);
			return;
		}

		if (team == 3)
		{
			PrintToChatAll("%s%N \x01has disconnected - [\x04%s\x01]", REBELS, client, g_sDisconnectReason);
			return;
		}

		else if (team == 2)
		{
			PrintToChatAll("%s%N \x01has disconnected - [\x04%s\x01]", COMBINE, client, g_sDisconnectReason);
			return;
		}

		else if (team == 1)
		{
			PrintToChatAll("%s%N \x01has disconnected [\x04%s\x01]", SPEC, client, g_sDisconnectReason);
			return;
		}

		else if (team == 0)
		{
			PrintToChatAll("%s%N \x01has disconnected [\x04%s\x01]", UNASSIGNED, client, g_sDisconnectReason);
			return;
		}
	}
}

public void OnConVarChanged_Teamplay(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int i; i <= MaxClients; i++)
	{
		if (i == 0)
		{
			int c_Teamplay;
			c_Teamplay = GetConVarInt(FindConVar("mp_teamplay"));
			if (c_Teamplay == 1)
			{
				PrintToServer("Teamplay has been enabled. Reloading map...");
				PrintToChatAll("Teamplay is now enabled.");
			}

			else if (c_Teamplay == 0)
			{
				PrintToServer("Teamplay has been disabled. Reloading map...");
				PrintToChatAll("Teamplay is now disabled.");
			}
		}
	}
	CreateTimer(0.1, TeamplayChanged_Timer);
	return;
}

public Action TeamplayChanged_Timer(Handle Timer, any data)
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	ForceChangeLevel(sMap, "mp_teamplay changed");
	return Plugin_Stop;
}