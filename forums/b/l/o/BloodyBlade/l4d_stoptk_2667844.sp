#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6"

float Damage[MAXPLAYERS + 1];
float Multiplier[MAXPLAYERS + 1];
float Punishment[MAXPLAYERS + 1];

ConVar l4d_stoptk_logpoints;
ConVar l4d_stoptk_logbans;
ConVar l4d_stoptk_bantype;
ConVar l4d_stoptk_bantime;
ConVar l4d_stoptk_showmessages;
ConVar l4d_stoptk_showhints;
ConVar l4d_stoptk_points_vote;
ConVar l4d_stoptk_points_ban;

public Plugin myinfo = 
{
	name = "[L4D] Stop TK",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	CreateConVar("l4d_stoptk_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD);
	l4d_stoptk_logpoints = CreateConVar("l4d_stoptk_logpoints", "logs/stoptk_points.log", "LOG Player bans to file", FCVAR_NOTIFY|FCVAR_SPONLY);
	l4d_stoptk_logbans = CreateConVar("l4d_stoptk_logbans", "logs/stoptk_bans.log", "LOG Player bans to file", FCVAR_NOTIFY|FCVAR_SPONLY);
	l4d_stoptk_bantype = CreateConVar("l4d_stoptk_bantype", "0", "0-no bans; 1-steam; 2-ip", FCVAR_NOTIFY|FCVAR_SPONLY);
	l4d_stoptk_bantime = CreateConVar("l4d_stoptk_bantime", "10080", "10080 = 1 week", FCVAR_NOTIFY|FCVAR_SPONLY);
	l4d_stoptk_showmessages = CreateConVar("l4d_stoptk_showmessages", "1", "", FCVAR_NOTIFY|FCVAR_SPONLY);
	l4d_stoptk_showhints = CreateConVar("l4d_stoptk_showhints", "1", "", FCVAR_NOTIFY|FCVAR_SPONLY);
	l4d_stoptk_points_vote = CreateConVar("l4d_stoptk_points_vote", "600.0", "", FCVAR_NOTIFY|FCVAR_SPONLY);
	l4d_stoptk_points_ban = CreateConVar("l4d_stoptk_points_ban", "2500.0", "", FCVAR_NOTIFY|FCVAR_SPONLY);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("heal_success", Event_MedkitUsed);
	HookEvent("revive_success", Event_ReviveSuccess);
	
	RegConsoleCmd("sm_tkpoints", Command_TKPoints);
}

public Action Command_TKPoints(int client, int args)
{
	if (client > 0 && client < 33)
	{
		float X;
		X = (1 + (Multiplier[client] / 10));
		PrintToChat(client, "\x05You have %d TK points!", RoundToZero(X * Damage[client]));
		PrintToChat(client, "You need %d TK Points to get voted.", RoundToZero(Punishment[client]) + RoundToZero(GetConVarFloat(l4d_stoptk_points_vote)));
		PrintToChat(client, "You need %d TK Points to get banned.", RoundToZero(GetConVarFloat(l4d_stoptk_points_ban)));
	}
}

public void BanClientID(int client)
{
	char ClientSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
	ServerCommand("banid %d %s", GetConVarInt(l4d_stoptk_bantime), ClientSteamID);
	ServerCommand("writeid");
	ServerCommand("kickid %d", GetClientUserId(client));
	char cvar_logfile_bans[128];
	GetConVarString(l4d_stoptk_logbans, cvar_logfile_bans, sizeof(cvar_logfile_bans));
	if (StrEqual(cvar_logfile_bans, "", false) != true)
	{
		char file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), cvar_logfile_bans);	
		LogToFileEx(file, "BANID[%d]: %N - %s", GetConVarInt(l4d_stoptk_bantime), client, ClientSteamID);
	}
}

public void BanClientIP(int client)
{
	char ClientIP[24];
	GetClientIP(client, ClientIP, sizeof(ClientIP), true);
	ServerCommand("addip %d %s", GetConVarInt(l4d_stoptk_bantime), ClientIP);
	ServerCommand("writeip");
	ServerCommand("kickid %d", GetClientUserId(client));	
	char cvar_logfile_bans[128];
	GetConVarString(l4d_stoptk_logbans, cvar_logfile_bans, sizeof(cvar_logfile_bans));
	if (StrEqual(cvar_logfile_bans, "", false) != true)
	{
		char file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), cvar_logfile_bans);	
		LogToFileEx(file, "BANIP[%d]: %N - %s", GetConVarInt(l4d_stoptk_bantime), client, ClientIP);
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return Plugin_Continue;

	if (GetEventInt(event, "dmg_health") < 1)
		return Plugin_Continue;	
		
	if (client == target)
		return Plugin_Continue;
		
	if (GetClientTeam(client) != 2 || GetClientTeam(target) != 2)
		return Plugin_Continue;

	if (IsFakeClient(client) || IsFakeClient(target))
		return Plugin_Continue;		

//	char ClientSteamID[32];
//	char TargetSteamID[32];

//	GetClientAuthId(client, ClientSteamID, sizeof(ClientSteamID));
//	GetClientAuthId(target, TargetSteamID, sizeof(TargetSteamID));

//	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
//		return Plugin_Continue;

	float X;

	X = (1 + (Multiplier[client] / 10));

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");

	if (GetConVarInt(l4d_stoptk_showmessages) > 0)
	{
		PrintToChat(client, "\x01%N attacked %N", client, target);
		PrintToChat(client, "\x03%d TK points! (%d - voteban; %d - ban)", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + RoundToZero(GetConVarFloat(l4d_stoptk_points_vote)), RoundToZero(GetConVarFloat(l4d_stoptk_points_ban)));
		PrintToChat(target, "\x01%N attacked %N", client, target);
		PrintToChat(target, "\x03%d TK points! (%d - voteban; %d - ban)", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + RoundToZero(GetConVarFloat(l4d_stoptk_points_vote)), RoundToZero(GetConVarFloat(l4d_stoptk_points_ban)));
	}
	
	if (GetConVarInt(l4d_stoptk_showhints) > 0)
	{
		PrintHintText(client, "%d TK Points", RoundToZero(X * Damage[client]));
		PrintHintText(target, "%N attacks you!", client);
	}
	
	CheckPunishmentPoints(client);

	return Plugin_Continue;
}

public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return Plugin_Continue;
	if (client == target)
		return Plugin_Continue;

	if (GetClientTeam(client) != 2 || GetClientTeam(target) != 2)
		return Plugin_Continue;

	if (IsFakeClient(client) || IsFakeClient(target))
		return Plugin_Continue;
	
	float X;

	X = (10 + Multiplier[client]) / 10;

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");
	Multiplier[client]++;

	if (GetConVarInt(l4d_stoptk_showmessages) > 0)
	{
		PrintToChat(client, "\x04%N attacked %N", client, target);
		PrintToChat(client, "\x03%d TK points! (%d - voteban; %d - ban)", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + RoundToZero(GetConVarFloat(l4d_stoptk_points_vote)), RoundToZero(GetConVarFloat(l4d_stoptk_points_ban)));
		PrintToChat(target, "\x04%N attacked %N", client, target);
		PrintToChat(target, "\x03%d TK points! (%d - voteban; %d - ban)", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + RoundToZero(GetConVarFloat(l4d_stoptk_points_vote)), RoundToZero(GetConVarFloat(l4d_stoptk_points_ban)));
	}
	
	if (GetConVarInt(l4d_stoptk_showhints) > 0)
	{
		PrintHintText(client, "%d TK Points", RoundToZero(X * Damage[client]));
		PrintHintText(target, "%N attacks you!", client);
	}
	
	CheckPunishmentPoints(client);

	return Plugin_Continue;
}

public Action Event_MedkitUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));

	char ClientSteamID[32];
	char TargetSteamID[32];

	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthId(target, AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	if (client == target)
		return Plugin_Continue;

	Damage[client] = Damage[client] - 150;
	if (Damage[client] < 0.0)
	{
		Damage[client] = 0.0;
		Multiplier[client] = Multiplier[client] - 0.15;
	}
	else
	{
		Multiplier[client] = Multiplier[client] - 0.1;
	}

	float X;
	X = (10 + Multiplier[client]) / 10;
	if (Multiplier[client] < 0.1)
	{
		Multiplier[client] = 0.1;
	}

	if (GetConVarInt(l4d_stoptk_showmessages) > 0)
	{	
		PrintToChat(client, "\x05You have cured %N and your TK points has gone down: \x04%f x %f = %d", target, Damage[client], X, RoundToZero(X * Damage[client])); 
//		PrintToChat(client, "\x04You healed somebody and lost some TK points. Now you have: \x05%f x %f = %d TK points!", Damage[client], X, RoundToZero(X * Damage[client]));
	}

	return Plugin_Continue;
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));

	char ClientSteamID[32];
	char TargetSteamID[32];

	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthId(target, AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	Damage[client] = Damage[client] - 50;
	if (Damage[client] < 0.0)
	{
		Damage[client] = 0.0;
		Multiplier[client] = Multiplier[client] - 0.05;
	}
	else
	{
		Multiplier[client] = Multiplier[client] - 0.033333;
	}

	float X;
	X = (10 + Multiplier[client]) / 10;
	if (Multiplier[client] < 0.1)
	{
		Multiplier[client] = 0.1;
	}
	
	if (GetConVarInt(l4d_stoptk_showmessages) > 0)
	{	
		PrintToChat(client, "\x05You have revived %N and your TK points has gone down: \x04%f x %f = %d", target, Damage[client], X, RoundToZero(X * Damage[client])); 
	}
	
	if (GetConVarInt(l4d_stoptk_showhints) > 0 && (RoundToZero(X * Damage[client]) > 0))
	{
		PrintHintText(client, "%d TK Points", RoundToZero(X * Damage[client]));
	}

	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		Damage[client] = 0.0;
		Multiplier[client] = 1.0;
		Punishment[client] = 0.0;
	}
}

public void CheckPunishmentPoints(int client)
{
	float TotalDamage;
	float X;

	X = (10 + Multiplier[client]) / 10;

	TotalDamage = Damage[client] * X;
	
	if (TotalDamage > GetConVarFloat(l4d_stoptk_points_vote))
	{
		if (TotalDamage > GetConVarFloat(l4d_stoptk_points_ban))
		{
			if (Punishment[client] < GetConVarFloat(l4d_stoptk_points_ban) && GetConVarInt(l4d_stoptk_bantype) > 0)
			{
				switch (GetConVarInt(l4d_stoptk_bantype))
				{
					case 1: BanClientID(client);
					case 2: BanClientIP(client);
				}

				char ClientSteamID[32];
				GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
				Punishment[client] = TotalDamage;
				if (GetConVarInt(l4d_stoptk_showmessages) > 0)
				{
					PrintToChatAll("\x04%N (\x05%s\x04) has been banned [\x05%d TK points!\x04]", client, ClientSteamID, RoundToZero(X * Damage[client]));
				
					switch (GetRandomInt(1, 3))
					{
						case 1: PrintToChatAll("\x04%Ciao Bambino!");
						case 2: PrintToChatAll("\x04%Bye! Come again!");
						case 3: PrintToChatAll("\x04%Dirty Bastard!");
					}
				}

				char cvar_logfile_points[128];
				GetConVarString(l4d_stoptk_logpoints, cvar_logfile_points, sizeof(cvar_logfile_points));
				if (StrEqual(cvar_logfile_points, "", false) != true)
				{
					char file[PLATFORM_MAX_PATH];
					BuildPath(Path_SM, file, sizeof(file), cvar_logfile_points);	
					LogToFileEx(file, "%N (%s) has been  banned [%d TK points!]", client, ClientSteamID, RoundToZero(X * Damage[client]));
				}	
			}
		}
		else if ((TotalDamage - Punishment[client]) > GetConVarFloat(l4d_stoptk_points_vote))
		{
			Punishment[client] = TotalDamage;
			if (GetConVarInt(l4d_stoptk_showmessages) > 0)
			{
				PrintToChatAll("\x05Autoban vote : %N (%d TK Points)", client, RoundToZero(Punishment[client])); 
			}
			ServerCommand("sm_voteban #%d", GetClientUserId(client));
			char cvar_logfile_points[128];
			GetConVarString(l4d_stoptk_logpoints, cvar_logfile_points, sizeof(cvar_logfile_points));
			if (StrEqual(cvar_logfile_points, "", false) != true)
			{
				char file[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, file, sizeof(file), cvar_logfile_points);	
				LogToFileEx(file, "VoteBan Started: %N [%d TK points!]", client, RoundToZero(X * Damage[client]));
			}			
		}
	}
}