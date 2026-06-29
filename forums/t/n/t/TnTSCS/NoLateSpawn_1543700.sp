#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

new Handle:h_SpawnTime;
new Handle:h_Enabled;
new Handle:h_FreezeTime;
new Handle:h_UseMpFreezeTime;
new Handle:h_Timer[32] = INVALID_HANDLE;
new Handle:h_MpRestartGame;

new Float:SpawnTime;
new bool:SpawnAllowed = true;
new bool:Enabled = true;
new Float:FreezeTime;
new bool:UseFreezeTime = true;
new bool:PlayerAllowedSpawn[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
	name = "No Late Spawn",
	author = "TnTSCS aka ClarkKent",
	description = "Will not allow new players to spawn after X seconds after round_start executes",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart()
{
	CreateConVar("sm_nolatespawn_version", PLUGIN_VERSION, "The version of 'sm_nolatespawn'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	CreateConVar("sm_nolatespawn_version_build",SOURCEMOD_VERSION, "The version of SourceMod that 'sm_nolatespawn' was compiled with.", FCVAR_PLUGIN);
	
	h_Enabled = CreateConVar("sm_nolatespawn_enabled", "1", "1 Enabled or 0 Disabled", _, true, 0.0, true, 1.0);
	h_SpawnTime = CreateConVar("sm_nolatespawn_time", "5.0", "Number of seconds to allow people to spawn after Round_Start", _, true, 0.0, true, 15.0);
	h_UseMpFreezeTime = CreateConVar("sm_nolatespawn_freeze", "1", "1 Include mp_freezetime in nolatespawn_time or 0 to not use it", _, true, 0.0, true, 1.0);
	
	LoadTranslations("NoLateSpawn.phrases");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	
	// Execute the config file
	AutoExecConfig(true, "plugin.NoLateSpawn");
	
	HookConVarChange(h_Enabled, OnConVarChange);
	HookConVarChange(h_SpawnTime, OnConVarChange);
	HookConVarChange(h_UseMpFreezeTime, OnConVarChange);
	
	h_MpRestartGame = FindConVar("mp_restartgame");	
	HookConVarChange(h_MpRestartGame, OnConVarChange);
}

public OnConfigsExecuted()
{
	h_FreezeTime = FindConVar("mp_freezetime");
	
	SpawnTime = GetConVarFloat(h_SpawnTime);
	Enabled = GetConVarBool(h_Enabled);
	FreezeTime = GetConVarFloat(h_FreezeTime);
	UseFreezeTime = GetConVarBool(h_UseMpFreezeTime);	
	h_MpRestartGame = FindConVar("mp_restartgame");
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
		SpawnTime = GetConVarFloat(cvar);
	}
	else if(cvar == h_FreezeTime)
	{
		cvar = FindConVar("mp_freezetime");
		FreezeTime = GetConVarFloat(cvar);
	}
	else if(cvar == h_UseMpFreezeTime)
	{
		cvar = FindConVar("sm_nolatespawn_freeze");
		UseFreezeTime = GetConVarBool(cvar);
	}
	else if(cvar == h_MpRestartGame)
	{
		ResetSpawnAllowed();
	}
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetClientTeam(client) == 0)
		return;
	
	if(Enabled)
	{
		if(!SpawnAllowed && IsClientInGame(client) && !IsFakeClient(client))
			KillAndReset(client);
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(Enabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				PlayerAllowedSpawn[i] = true;
			}
		}
		
		if(UseFreezeTime)
		{
			h_Timer[1] = CreateTimer(SpawnTime + FreezeTime, t_AfterRoundStart);
		}
		else
		{
			h_Timer[1] = CreateTimer(SpawnTime, t_AfterRoundStart);
		}
	}
}

public Action:t_AfterRoundStart(Handle:timer)
{
	SpawnAllowed = false;
	h_Timer[1] = INVALID_HANDLE;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetSpawnAllowed();
}

public OnClientDisconnect(client)
{
	PlayerAllowedSpawn[client] = false;
}

ResetSpawnAllowed()
{
	SpawnAllowed = true;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		PlayerAllowedSpawn[i] = false;
	}
	
	if(h_Timer[1] != INVALID_HANDLE)
	{
		KillTimer(h_Timer[1]);
		h_Timer[1] = INVALID_HANDLE;
	}
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