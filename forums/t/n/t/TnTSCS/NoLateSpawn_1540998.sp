#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib/clients>

#define PLUGIN_VERSION "1.0"

new Handle:h_MpRestartGame;

new bool:SpawnAllowed = true;

public Plugin:myinfo = 
{
	name = "No Late Spawn",
	author = "TnTSCS aka ClarkKent",
	description = "Will not allow players to spawn after round_start",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=165145"
}

public OnPluginStart()
{
	CreateConVar("sm_nolatespawn_version", PLUGIN_VERSION, "The version of 'sm_nolatespawn'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	LoadTranslations("NoLateSpawn.phrases");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	
	h_MpRestartGame = FindConVar("mp_restartgame");	
	HookConVarChange(h_MpRestartGame, OnConVarChange);
}

public OnConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_MpRestartGame)
		SpawnAllowed = true;
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(!SpawnAllowed && IsClientInGame(client) && !IsFakeClient(client))
		KillAndReset(client);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnAllowed = false;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnAllowed = true;
}

KillAndReset(client)
{
	ForcePlayerSuicide(client);
	
	new deaths = Client_GetDeaths(client);
	new score = Client_GetScore(client);
	
	Client_SetDeaths(client, deaths - 1);
	Client_SetScore(client, score + 1);
	
	PrintToChat(client,"\x04%t", "NoLateSpawn");
}