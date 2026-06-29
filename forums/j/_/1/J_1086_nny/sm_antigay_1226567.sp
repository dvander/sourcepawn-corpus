#include <sourcemod>

#define PLUGIN_NAME "SM AntiGay"
#define PLUGIN_VERSION "1.0"

new Handle:sm_logfile_players;
new Handle:sm_logfile_commands;
new Handle:sm_logfile_bans;
new Handle:sm_block_attack;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_antigay_version", PLUGIN_VERSION, "AntiGay Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_logfile_players = CreateConVar("sm_logfile_players", "", "LOG STEAM_ID + IP + NICKNAME to file", FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_logfile_commands = CreateConVar("sm_logfile_commands", "", "LOG Player commands to file", FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_logfile_bans = CreateConVar("sm_logfile_bans", "", "LOG Player bans to file", FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_block_attack = CreateConVar("sm_block_attack", "", "Block attack", FCVAR_PLUGIN|FCVAR_SPONLY);
}

public OnClientPutInServer(client)
{
	new String:cvar_logfile_players[128];
	GetConVarString(sm_logfile_players, cvar_logfile_players, sizeof(cvar_logfile_players));
	if (StrEqual(cvar_logfile_players, "", false) != true)
	{
		if (!IsFakeClient(client))
		{
			decl String:file[PLATFORM_MAX_PATH], String:steamid[24], String:ClientIP[24];
			BuildPath(Path_SM, file, sizeof(file), cvar_logfile_players);
			GetClientAuthString(client, steamid, sizeof(steamid));
			GetClientIP(client, ClientIP, sizeof(ClientIP), false);      

			LogToFileEx(file, "%N - %s - %s", client, steamid, ClientIP);
		}
	}
}

public BanClientID(client)
{
	decl String:ClientSteamID[32];
	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	ServerCommand("banid 0 %s", ClientSteamID);
	ServerCommand("writeid");
	ServerCommand("kickid %d", GetClientUserId(client));
	new String:cvar_logfile_bans[128];
	GetConVarString(sm_logfile_bans, cvar_logfile_bans, sizeof(cvar_logfile_bans));
	if (StrEqual(cvar_logfile_bans, "", false) != true)
	{
		decl String:file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), cvar_logfile_bans);	
		LogToFileEx(file, "BANID: %N - %s", client, ClientSteamID);
	}
}

public BanClientIP(client)
{
	decl String:ClientIP[24];
	GetClientIP(client, ClientIP, sizeof(ClientIP), true);
	ServerCommand("addip 0 %s", ClientIP);
	ServerCommand("writeip");
	ServerCommand("kickid %d", GetClientUserId(client));	
	new String:cvar_logfile_bans[128];
	GetConVarString(sm_logfile_bans, cvar_logfile_bans, sizeof(cvar_logfile_bans));
	if (StrEqual(cvar_logfile_bans, "", false) != true)
	{
		decl String:file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), cvar_logfile_bans);	
		LogToFileEx(file, "BANIP: %N - %s", client, ClientIP);
	}
}

public Action:OnClientCommand(client, args)
{
	decl String:CommandName[50];
	GetCmdArg(0, CommandName, sizeof(CommandName));
	
	if (GetConVarInt(sm_block_attack) > 0)
	{
		if (StrEqual(CommandName, "developer", false) || StrEqual(CommandName, "fps_modem", false) || StrEqual(CommandName, "fps_max", false))
		{
			switch (GetConVarInt(sm_block_attack))
			{
				case 1: BanClientID(client);
				case 2: BanClientIP(client);
			}
		}
	}

	new String:cvar_logfile_commands[128];
	GetConVarString(sm_logfile_commands, cvar_logfile_commands, sizeof(cvar_logfile_commands));
	if (StrEqual(cvar_logfile_commands, "", false) == true)
	{
		return Plugin_Continue;
	}

	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), cvar_logfile_commands);

	if (args > 0)
	{
		decl String:argstring[255];
		GetCmdArgString(argstring, sizeof(argstring));
		LogToFileEx(file, "%N - %s [%s]", client, CommandName, argstring);
		return Plugin_Continue;
	}

	LogToFileEx(file, "%N - %s", client, CommandName);
	return Plugin_Continue;
}