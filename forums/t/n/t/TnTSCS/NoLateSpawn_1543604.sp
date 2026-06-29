#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new Handle:h_MpRestartGame;

new bool:SpawnAllowed = true;
new bool:PlayerAllowedSpawn[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
	name = "No Late Spawn",
	author = "TnTSCS aka ClarkKent",
	description = "Will not allow new players to spawn after round_start",
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
		ResetSpawnAllowed();
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetClientTeam(client) == 0)
		return;
	
	if(!SpawnAllowed && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(PlayerAllowedSpawn[client])
		{
			return;
		}
		
		KillAndReset(client);
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnAllowed = false;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			PlayerAllowedSpawn[i] = true;
		}
	}
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetSpawnAllowed();
}

public OnClientDisconnect(client)
{
	PlayerAllowedSpawn[client] = false;
}

KillAndReset(client)
{
	PlayerAllowedSpawn[client] = false;
	
	ForcePlayerSuicide(client);
	
	new deaths = GetEntProp(client, Prop_Data, "m_iDeaths");
	new score = GetClientFrags(client);
	
	SetEntProp(client, Prop_Data, "m_iDeaths", deaths - 1);
	SetEntProp(client, Prop_Data, "m_iFrags", score + 1);
	
	PrintToChat(client,"\x04%t", "NoLateSpawn");
}

ResetSpawnAllowed()
{
	SpawnAllowed = true;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		PlayerAllowedSpawn[i] = false;
	}
}