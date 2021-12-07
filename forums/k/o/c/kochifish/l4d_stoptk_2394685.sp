#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.8.1"
#define MSG_STOP_TK_BAN "Team Killer Punishment"
#define CHAT_TAG				"\x05[\x01TK\x05]\x01 "


new Float:Damage[MAXPLAYERS + 1];
new Float:Multiplier[MAXPLAYERS + 1];
new Float:Punishment[MAXPLAYERS + 1];
new g_fTkVote;
new g_fTkBan;

new Handle:l4d_stoptk_enabled;
new Handle:l4d_stoptk_logpoints;
new Handle:l4d_stoptk_logbans;
new Handle:l4d_stoptk_bantype;
new Handle:l4d_stoptk_bantime;
new Handle:l4d_stoptk_showmessages;
new Handle:l4d_stoptk_showhints;
new Handle:l4d_stoptk_points_vote;
new Handle:l4d_stoptk_points_ban;
new Handle:l4d_stoptk_points_shot;
new Handle:l4d_stoptk_admin_power;
new Handle:l4d_stoptk_difficult;
public Plugin:myinfo = 
{
	name = "[L4D] Stop TK",
	author = "Jonny, Translated Kazantip|HHx, and Fixed & Modified Electr0..",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	l4d_stoptk_difficult = FindConVar("z_difficulty");
	
	LoadTranslations("stoptk.phrases");

	CreateConVar("l4d_stoptk_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	l4d_stoptk_enabled = CreateConVar("l4d_stoptk_enabled", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_logpoints = CreateConVar("l4d_stoptk_logpoints", "logs/stoptk_points.log", "LOG Player bans to file", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_logbans = CreateConVar("l4d_stoptk_logbans", "logs/stoptk_bans.log", "LOG Player bans to file", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_bantype = CreateConVar("l4d_stoptk_bantype", "1", "0-no bans; 1-steam; 2-ip", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_bantime = CreateConVar("l4d_stoptk_bantime", "60", "10080 = 1 week", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_showmessages = CreateConVar("l4d_stoptk_showmessages", "0", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_showhints = CreateConVar("l4d_stoptk_showhints", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_points_vote = CreateConVar("l4d_stoptk_points_vote", "75.0", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_points_ban = CreateConVar("l4d_stoptk_points_ban", "120.0", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_points_shot = CreateConVar("l4d_stoptk_points_shot", "", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	l4d_stoptk_admin_power= CreateConVar("l4d_stoptk_protect_admins", "1", "0: Not ignore, 1: Ignore admins but show TK msg, 2: Ingore admins", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 3.0);
	
	HookConVarChange(l4d_stoptk_difficult, OnCVarChange);
	HookConVarChange(l4d_stoptk_points_vote, OnCVarChange);
	HookConVarChange(l4d_stoptk_points_ban, OnCVarChange);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("heal_success", Event_MedkitUsed);
	HookEvent("revive_success", Event_ReviveSuccess);
	
	RegConsoleCmd("sm_tkpoints", Command_TKPoints);
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	TK_OnCvarChange();
}

public OnConfigsExecuted()
{
	TK_OnCvarChange();
}

TK_OnCvarChange()
{
	decl String:buffer[2];
	GetConVarString(l4d_stoptk_difficult, buffer, sizeof(buffer));
	
	new Float:fMultiplier 	= 1.0;
	
	if (StrEqual(buffer, "E")) fMultiplier = 0.5;
	else if (StrEqual(buffer, "N")) fMultiplier = 0.5;
	else if (StrEqual(buffer, "H")) fMultiplier = 0.5;
	else if (StrEqual(buffer, "I")) fMultiplier = 0.5;
	
	g_fTkVote = RoundToZero(GetConVarFloat(l4d_stoptk_points_vote) * fMultiplier);
	g_fTkBan = RoundToZero(GetConVarFloat(l4d_stoptk_points_ban) * fMultiplier);

	LogMessage("- Difficulty of the current game \"%s\", Voteban %d, Ban %d, (Multiplier x%f)",  buffer, g_fTkVote, g_fTkBan, fMultiplier);
}

public bool:IsIncapacitated(client)
{
    //FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated")
    new isIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
    
    if (isIncap)
	{
		return true;
	}
    
    return false;
}

public Action:Command_TKPoints(client, args)
{
	if (client > 0 && client < 33)
	{
		new Float:X;
		X = (1 + (Multiplier[client] / 10));
		PrintToChat(client, "%s %t", CHAT_TAG, "HaveTKpoints", RoundToZero(X * Damage[client]));
		PrintToChat(client, "%s %t", CHAT_TAG, "NeedTKvoted", g_fTkVote);
		PrintToChat(client, "%s %t", CHAT_TAG, "NeedTKbanned", g_fTkBan);
	}
}

public BanClientID(client)
{
	decl String:ClientSteamID[32];
	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	ServerCommand("banid %d %s", GetConVarInt(l4d_stoptk_bantime), ClientSteamID);
	ServerCommand("sm_ban \"%N\" %d \"%s\"", client, GetConVarInt(l4d_stoptk_bantime), MSG_STOP_TK_BAN);
	ServerCommand("writeid");
	ServerCommand("kickid %d", GetClientUserId(client));
	new String:cvar_logfile_bans[128];
	GetConVarString(l4d_stoptk_logbans, cvar_logfile_bans, sizeof(cvar_logfile_bans));
	if (StrEqual(cvar_logfile_bans, "", false) != true)
	{
		decl String:file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), cvar_logfile_bans);	
		LogToFileEx(file, "BANID[%d]: %N - %s", GetConVarInt(l4d_stoptk_bantime), client, ClientSteamID);
	}
}

public BanClientIP(client)
{
	decl String:ClientIP[24];
	GetClientIP(client, ClientIP, sizeof(ClientIP), true);
	ServerCommand("addip %d %s", GetConVarInt(l4d_stoptk_bantime), ClientIP);
	ServerCommand("writeip");
	ServerCommand("kickid %d", GetClientUserId(client));	
	new String:cvar_logfile_bans[128];
	GetConVarString(l4d_stoptk_logbans, cvar_logfile_bans, sizeof(cvar_logfile_bans));
	if (StrEqual(cvar_logfile_bans, "", false) != true)
	{
		decl String:file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), cvar_logfile_bans);	
		LogToFileEx(file, "BANIP[%d]: %N - %s", GetConVarInt(l4d_stoptk_bantime), client, ClientIP);
	}
}
static block[MAXPLAYERS+1];
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(l4d_stoptk_enabled) < 1) return Plugin_Handled;

	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return Plugin_Continue;

	if (GetUserFlagBits(client) && GetConVarInt(l4d_stoptk_admin_power) == 2)
		return Plugin_Continue;
			
	new event_damage = GetEventInt(event, "dmg_health");

	if (event_damage < 1)
		return Plugin_Continue;	
		
	if (client == target)
		return Plugin_Continue;
		
	if (IsIncapacitated(target))
		return Plugin_Continue;
		
	if (GetClientTeam(client) != 2 || GetClientTeam(target) != 2)
		return Plugin_Continue;

	if (IsFakeClient(client) || IsFakeClient(target))
		return Plugin_Continue;		

//	decl String:ClientSteamID[32];
//	decl String:TargetSteamID[32];

//	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
//	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

//	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
//		return Plugin_Continue;

	new Float:X;

	X = (1 + (Multiplier[client] / 10));
	if (event_damage > GetConVarInt(l4d_stoptk_points_shot)) event_damage = GetConVarInt(l4d_stoptk_points_shot);

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");

	if (!block[client]){
	
		new Handle:db;
		CreateDataTimer(3.0, TK_MSG, db);
		WritePackCell(db, client);
		WritePackCell(db, target);
		WritePackFloat(db, X);
		block[client] = true;
	}
	return Plugin_Continue;
}

public Action:TK_MSG(Handle:timer, Handle:db)
{
	ResetPack(db);
	new client = ReadPackCell(db);
	new target = ReadPackCell(db);
	new Float:X = ReadPackFloat(db);
	
	if (!IsClientInGame(client) || !IsClientInGame(target)) return;
	
	if (GetConVarInt(l4d_stoptk_showmessages) > 0)
	{
		PrintToChat(client, "%s %t", CHAT_TAG, "Attacked", client, target);
		PrintToChat(client, "%s %t", CHAT_TAG, "TKpoints", RoundToZero(X * Damage[client]), g_fTkVote, g_fTkBan);
		PrintToChat(target, "%s %t", CHAT_TAG, "Attacked", client, target);
		PrintToChat(target, "%s %t", CHAT_TAG, "TKpoints", RoundToZero(X * Damage[client]), g_fTkVote, g_fTkBan);
	}
	else
	{
		PrintToConsole(client, "%N attacked %N", client, target);
		PrintToConsole(client, "%d TK points! (%d - voteban; %d - ban)", RoundToZero(X * Damage[client]), g_fTkVote, g_fTkBan);
		PrintToConsole(target, "%N attacked %N", client, target);
		PrintToConsole(target, "%d TK points! (%d - voteban; %d - ban)", RoundToZero(X * Damage[client]), g_fTkVote, g_fTkBan);
	}
	
	if (GetConVarInt(l4d_stoptk_showhints) > 0)
	{
		PrintHintText(client, "%t", "HintTKpoints", RoundToZero(X * Damage[client]), g_fTkVote, g_fTkBan);
		PrintHintText(target, "%t", "HintAttacks", client);
	}
	block[client] = false;

	CheckPunishmentPoints(client);
}

public Action:Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(l4d_stoptk_enabled) < 1) return Plugin_Handled;
	
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return Plugin_Continue;
	if (client == target)
		return Plugin_Continue;

	if (GetClientTeam(client) != 2 || GetClientTeam(target) != 2)
		return Plugin_Continue;

	if (IsFakeClient(client) || IsFakeClient(target))
		return Plugin_Continue;
	
	new Float:X;

	X = (10 + Multiplier[client]) / 10;

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");
	Multiplier[client]++;

	if (!block[client]){
	
		new Handle:db;
		CreateDataTimer(3.0, TK_MSG, db);
		WritePackCell(db, client);
		WritePackCell(db, target);
		WritePackFloat(db, X);
		block[client] = true;
	}

	CheckPunishmentPoints(client);

	return Plugin_Continue;
}

public Action:Event_MedkitUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(l4d_stoptk_enabled) < 1) return Plugin_Handled;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));

	decl String:ClientSteamID[32];
	decl String:TargetSteamID[32];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

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
	new Float:X;
	X = (10 + Multiplier[client]) / 10;
	if (Multiplier[client] < 0.1)
	{
		Multiplier[client] = 0.1;
	}

	if (GetConVarInt(l4d_stoptk_showmessages) > 0)
	{	
		PrintToChat(client, "%s %t", CHAT_TAG, "TKpointsDown", target, Damage[client], X, RoundToZero(X * Damage[client])); 
	}

	return Plugin_Continue;
}

public Action:Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(l4d_stoptk_enabled) < 1) return Plugin_Handled;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));

	decl String:ClientSteamID[32];
	decl String:TargetSteamID[32];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

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
	new Float:X;
	X = (10 + Multiplier[client]) / 10;
	if (Multiplier[client] < 0.1)
	{
		Multiplier[client] = 0.1;
	}
	
	if (GetConVarInt(l4d_stoptk_showmessages) > 0)
	{	
		PrintToChat(client, "%s %t", CHAT_TAG, "RevivedTKpointsDown", target, Damage[client], X, RoundToZero(X * Damage[client])); 
	}
	
	if (GetConVarInt(l4d_stoptk_showhints) > 0 && (RoundToZero(X * Damage[client]) > 0))
	{
		PrintHintText(client, "%t", "HintTKpoints", RoundToZero(X * Damage[client]), g_fTkVote, g_fTkBan);
	}

	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		Damage[client] = 0.0;
		Multiplier[client] = 1.0;
		Punishment[client] = 0.0;
		block[client] = false;
	}
}

public CheckPunishmentPoints(client)
{
	if (GetUserFlagBits(client) && GetConVarInt(l4d_stoptk_admin_power) == 1)
		return;

	new Float:TotalDamage;
	new Float:X;

	X = (10 + Multiplier[client]) / 10;

	TotalDamage = Damage[client] * X;
	
	if (TotalDamage > g_fTkVote)
	{
		if (TotalDamage > g_fTkBan)
		{
			if (Punishment[client] < g_fTkBan && GetConVarInt(l4d_stoptk_bantype) > 0)
			{
				switch (GetConVarInt(l4d_stoptk_bantype))
				{
					case 1: BanClientID(client);
					case 2: BanClientIP(client);
				}

				decl String:ClientSteamID[32];
				GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
				Punishment[client] = TotalDamage;
				if (GetConVarInt(l4d_stoptk_showmessages) > 0)
				{
					NotifyBannedAll(client, ClientSteamID, X);
				
					switch (GetRandomInt(1, 3))
					{
						case 1: NotifyBannedAll2(1);
						case 2: NotifyBannedAll2(2);
						case 3: NotifyBannedAll2(3);
					}
				}

				new String:cvar_logfile_points[128];
				GetConVarString(l4d_stoptk_logpoints, cvar_logfile_points, sizeof(cvar_logfile_points));
				if (StrEqual(cvar_logfile_points, "", false) != true)
				{
					decl String:file[PLATFORM_MAX_PATH];
					BuildPath(Path_SM, file, sizeof(file), cvar_logfile_points);	
					LogToFileEx(file, "%N (%s) has been  banned [%d TK points!]", client, ClientSteamID, RoundToZero(X * Damage[client]));
				}	
			}
		}
		else if ((TotalDamage - Punishment[client]) > g_fTkVote)
		{
			Punishment[client] = TotalDamage;
			if (GetConVarInt(l4d_stoptk_showmessages) > 0)
			{
				NotifyAutoBanAll(client)
			}
			ServerCommand("sm_voteban #%d", GetClientUserId(client));
			new String:cvar_logfile_points[128];
			GetConVarString(l4d_stoptk_logpoints, cvar_logfile_points, sizeof(cvar_logfile_points));
			if (StrEqual(cvar_logfile_points, "", false) != true)
			{
				decl String:file[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, file, sizeof(file), cvar_logfile_points);	
				LogToFileEx(file, "VoteBan Started: %N [%d TK points!]", client, RoundToZero(X * Damage[client]));
			}			
		}
	}
}

stock NotifyBannedAll2(numb)
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{	
			SetGlobalTransTarget(i);
			if (numb == 1) PrintToChat(i, "%s %t", CHAT_TAG, "CiaoBambino");
			if (numb == 2) PrintToChat(i, "%s %t", CHAT_TAG, "ComeAgain");
			if (numb == 3) PrintToChat(i, "%s %t", CHAT_TAG, "DirtyBastard");
		}
	}
}

stock NotifyBannedAll(client, String:ClientSteamID[], Float:X)
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{	
			SetGlobalTransTarget(i);
			PrintToChat(i, "%s %t", CHAT_TAG, "BeenBanned", client, ClientSteamID, RoundToZero(X * Damage[client]));
		}
	}
}

stock NotifyAutoBanAll(client)
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{	
			SetGlobalTransTarget(i);
			PrintToChat(i, "%s %t", CHAT_TAG, "AutobanVote", client, RoundToZero(Punishment[client])); 
		}
	}
}
