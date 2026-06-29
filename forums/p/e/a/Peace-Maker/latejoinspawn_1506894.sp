#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVEnable;
new Handle:g_hCVSpawnAfterRoundstart;
new Handle:g_hCVSpawnDelay;

new Handle:g_hPlayersPlayedThisRound;

new Handle:g_hPlayerMessageDelay[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new Handle:g_hPlayerSpawnDelay[MAXPLAYERS+1] = {INVALID_HANDLE,...};

new g_iRoundStartTime = -1;

public Plugin:myinfo = 
{
	name = "Late joiner spawn",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Spawns latejoining players",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_latejoin_version", PLUGIN_VERSION, "Late joiner spawn version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVEnable = CreateConVar("sm_latejoin_enable", "1", "Spawn late joining players?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVSpawnAfterRoundstart = CreateConVar("sm_latejoin_spawnafterroundstart", "180", "How many seconds after roundstart should latejoining players be spawned?", FCVAR_PLUGIN, true, 0.0);
	g_hCVSpawnDelay = CreateConVar("sm_latejoin_spawndelay", "5", "How many seconds after the teamjoin should we spawn the player?", FCVAR_PLUGIN, true, 1.0);
	
	g_hPlayersPlayedThisRound = CreateTrie();
	
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_team", Event_OnPlayerTeam);
	
	AutoExecConfig(true, "plugin.latejoinspawn");
}

public OnClientDisconnect(client)
{
	if(g_hPlayerMessageDelay[client] != INVALID_HANDLE)
	{
		KillTimer(g_hPlayerMessageDelay[client]);
		g_hPlayerMessageDelay[client] = INVALID_HANDLE;
	}
	if(g_hPlayerSpawnDelay[client] != INVALID_HANDLE)
	{
		KillTimer(g_hPlayerSpawnDelay[client]);
		g_hPlayerSpawnDelay[client] = INVALID_HANDLE;
	}
}

public OnMapEnd()
{
	ClearTrie(g_hPlayersPlayedThisRound);
}

public Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRoundStartTime = GetTime();
	// No one played this round already
	ClearTrie(g_hPlayersPlayedThisRound);
	
	// Sometimes players spawn before round_start fires
	decl String:sAuthId[32];
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			GetClientAuthString(i, sAuthId, sizeof(sAuthId));
			SetTrieValue(g_hPlayersPlayedThisRound, sAuthId, 1, false);
		}
	}
}

public Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRoundStartTime = -1;
	// This round is over
	ClearTrie(g_hPlayersPlayedThisRound);
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Don't care for spectators
	if(GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		return;
	
	decl String:sAuthId[32];
	GetClientAuthString(client, sAuthId, sizeof(sAuthId));
	
	// Save, that he already played in this round
	SetTrieValue(g_hPlayersPlayedThisRound, sAuthId, 1, false);
}

public Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_hCVEnable))
		return;
	
	// He disconnected?
	if(GetEventBool(event, "disconnect"))
		return;
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if(!client)
		return;
	
	// Don't spawn him twice if he changes teams fast
	if(g_hPlayerMessageDelay[client] != INVALID_HANDLE)
	{
		KillTimer(g_hPlayerMessageDelay[client]);
		g_hPlayerMessageDelay[client] = INVALID_HANDLE;
	}
	if(g_hPlayerSpawnDelay[client] != INVALID_HANDLE)
	{
		KillTimer(g_hPlayerSpawnDelay[client]);
		g_hPlayerSpawnDelay[client] = INVALID_HANDLE;
	}
	
	// He joined a valid team?
	new team = GetEventInt(event, "team");
	if(team <= CS_TEAM_SPECTATOR)
		return;
	
	// This round didn't start yet
	if(g_iRoundStartTime == -1)
		return;
	
	// The round is running for too long already. Won't spawn you - sorry.
	if(GetTime() - g_iRoundStartTime > GetConVarInt(g_hCVSpawnAfterRoundstart))
		return;
	
	// Did he get spawned by the game already?
	g_hPlayerMessageDelay[client] = CreateTimer(0.5, Timer_CheckAlive, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_CheckAlive(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	g_hPlayerMessageDelay[client] = INVALID_HANDLE;
	
	if(!GetConVarBool(g_hCVEnable))
		return Plugin_Stop;
	
	if(!IsClientInGame(client) || IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		return Plugin_Stop;
	
	decl String:sAuthId[32];
	GetClientAuthString(client, sAuthId, sizeof(sAuthId));
	
	// Did he already spawn this round?
	new iBuffer = 0;
	GetTrieValue(g_hPlayersPlayedThisRound, sAuthId, iBuffer);
	if(iBuffer == 1)
	{
		PrintToChat(client, "\x04[\x05Late Join Spawn\x04] \x01You already spawned this round!");
		return Plugin_Stop;
	}
	
	// Spawn him with a delay
	g_hPlayerSpawnDelay[client] = CreateTimer(GetConVarFloat(g_hCVSpawnDelay), Timer_SpawnPlayer, userid, TIMER_FLAG_NO_MAPCHANGE);
	
	// Inform the player
	PrintToChat(client, "\x04[\x05Late Join Spawn\x04] \x01You're going to be late-spawned in %d seconds!", GetConVarInt(g_hCVSpawnDelay));
	
	return Plugin_Stop;
}

public Action:Timer_SpawnPlayer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	g_hPlayerSpawnDelay[client] = INVALID_HANDLE;
	
	if(!GetConVarBool(g_hCVEnable))
		return Plugin_Stop;
	
	// Make sure he didn't spawn in the meantime and no admin changed his team
	if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		// Save, that he already played in this round
		decl String:sAuthId[32];
		GetClientAuthString(client, sAuthId, sizeof(sAuthId));
		SetTrieValue(g_hPlayersPlayedThisRound, sAuthId, 1, false);
		
		CS_RespawnPlayer(client);
	}
	
	return Plugin_Stop;
}