/* 
* Plugin requested by nikedu45
* 
* Thanks to berni for SMLib
* 
* 
* 	* Version History
* 			* 1.0	Initial release to nikedu45
* 
*  */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// SMLib - Credits to berni
#include <smlib/clients>
#include <smlib/teams>

#define PLUGIN_VERSION "1.0"

new Handle:h_SpawnTimer[MAXPLAYERS+1];
new Handle:h_SpawnTime;
new Handle:h_Enabled;
new Handle:h_FreezeTime;

new Float:SpawnTimer;
new bool:SpawnAllowed = true;
new bool:Enabled = true;
new Float:FreezeTime;

public Plugin:myinfo = 
{
	name = "NoLateSpawn",
	author = "TnTSCS aka ClarkKent",
	description = "Will not allow players to join a team after X seconds after round start",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=165145"
}

public OnPluginStart()
{
	// Create Plugin ConVars
	CreateConVar("sm_nolatespawn_version", PLUGIN_VERSION, "The version of 'sm_nolatespawn'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	CreateConVar("sm_nolatespawn_version_build",SOURCEMOD_VERSION, "The version of SourceMod that 'sm_nolatespawn' was compiled with.", FCVAR_PLUGIN);
	
	h_Enabled = CreateConVar("sm_nolatespawn_enabled", "1", "1 Enabled or 0 Disabled", _, true, 0.0, true, 1.0);
	h_SpawnTime = CreateConVar("sm_nolatespawn_time", "5.0", "Number of seconds to allow people to spawn after Round_Start", _, true, 5.0, true, 20.0);
		
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn);	
	HookEvent("player_death", OnPlayerDeath);
	
	// Execute the config file
	AutoExecConfig(true, "plugin.NoLateSpawn");
	
	HookConVarChange(h_Enabled, OnConVarChange);
	HookConVarChange(h_SpawnTime, OnConVarChange);
}

public OnConfigsExecuted()
{
	h_FreezeTime = FindConVar("mp_freezetime");
	
	SpawnTimer = GetConVarFloat(h_SpawnTime);
	Enabled = GetConVarBool(h_Enabled);
	SpawnAllowed = true;
	FreezeTime = GetConVarFloat(h_FreezeTime);
}

public OnConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_Enabled)
	{
		cvar = FindConVar("sm_nolatespawn_enabled");
		Enabled = GetConVarBool(cvar);
	}
	else if(cvar == h_SpawnTime)
	{
		cvar = FindConVar("sm_nolatespawn_time");
		SpawnTimer = GetConVarFloat(cvar);
	}
	else if(cvar == h_FreezeTime)
	{
		cvar = FindConVar("sm_nolatespawn_time");
		FreezeTime = GetConVarFloat(cvar);
	}
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if(Enabled && !SpawnAllowed && !IsFakeClient(client))
	{
		h_SpawnTimer[client] = CreateTimer(0.2, Force_Suicide, client);
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new CtCount = Team_GetClientCount(3);
	new TCount = Team_GetClientCount(2);
	
	if(CtCount >= 1 && TCount >= 1)
	{
		CreateTimer(SpawnTimer + FreezeTime, t_AfterRoundStart);
	}
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnAllowed = true;
}

public Action:t_AfterRoundStart(Handle:timer)
{
	SpawnAllowed = false;
}

public Action:Force_Suicide(Handle:timer, any:client)
{
	if(h_SpawnTimer[client] != INVALID_HANDLE)
	{		
		// Make sure client is still in game alive
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			// Notify player they cannot join after X seconds
			PrintToChat(client, "\x01[SM] Sorry, but \x03No Late Spawns\x01 allowed after \x03%i \x01seconds", GetConVarInt(h_SpawnTime));
			
			// Kill player via suicide
			ForcePlayerSuicide(client);
			
			// Reset death and score
			// Using SMLib includes
			new deaths = Client_GetDeaths(client);
			new score = Client_GetScore(client);
			Client_SetDeaths(client, deaths - 1);
			Client_SetScore(client, score + 1);
		}
		h_SpawnTimer[client] = INVALID_HANDLE;
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(!IsFakeClient(client) && h_SpawnTimer[client] != INVALID_HANDLE)
	{
		KillTimer(h_SpawnTimer[client]);
		h_SpawnTimer[client] = INVALID_HANDLE;
	}
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client) && h_SpawnTimer[client] != INVALID_HANDLE)
	{
		KillTimer(h_SpawnTimer[client]);
		h_SpawnTimer[client] = INVALID_HANDLE;
	}
}