#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>

#define PLUGIN_VERSION "1.3.3"

#define PANEL_TEAM "team"

new Handle:g_Timer = INVALID_HANDLE;
new Float:SpawnTime;
new Float:FreezeTime;
new bool:SpawnAllowed = true;
new bool:UseFreezeTime = true;

public Plugin:myinfo = 
{
	name = "No Late Spawn",
	author = "TnTSCS aka ClarkKent",
	description = "Will not allow new players to spawn after n seconds post round_start.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart()
{
	// Create this plugins CVars
	new Handle:hRandom;// KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_nolatespawn_version", PLUGIN_VERSION, 
	"The version of 'sm_nolatespawn'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_nolatespawn_enabled", "1", 
	"1 Enabled or 0 Disabled", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_nolatespawn_time", "5.0", 
	"Number of seconds to allow people to spawn after Round_Start", _, true, 0.0, true, 120.0)), OnTimeChanged);
	SpawnTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_nolatespawn_freeze", "0", 
	"1 Include mp_freezetime in nolatespawn_time or 0 to not use it", _, true, 0.0, true, 1.0)), OnFreezeChanged);
	UseFreezeTime = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = FindConVar("mp_freezetime")), OnFreezeTimeChanged);
	FreezeTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = FindConVar("mp_restartgame")), OnRestartGameChanged);
	
	CloseHandle(hRandom); // KyleS hates handles.
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn);
	
	LoadTranslations("nolatespawn.phrases.txt");
	
	// Execute the config file
	AutoExecConfig(true, "nolatespawn.plugin");
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!SpawnAllowed && IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		DenySpawn(client);
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearTimer(g_Timer);
	
	if (UseFreezeTime)
	{
		g_Timer = CreateTimer(SpawnTime + FreezeTime, t_ResetSpawnAllowed);
	}
	else
	{
		g_Timer = CreateTimer(SpawnTime, t_ResetSpawnAllowed);
	}
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetSpawnAllowed();
}

public DenySpawn(client)
{
	new team = GetClientTeam(client);
	
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	CS_SwitchTeam(client, team);
	
	ShowVGUIPanel(client, PANEL_TEAM);
	
	CPrintToChat(client, "%t", "NoLateSpawn");
}

public Action:t_ResetSpawnAllowed(Handle:timer)
{
	SpawnAllowed = false;
	g_Timer = INVALID_HANDLE;
}

public ResetSpawnAllowed()
{
	ClearTimer(g_Timer);
	
	SpawnAllowed = true;
}

ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}	 
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	switch (StringToInt(newVal))
	{
		case 0:
		{
			UnhookEvent("round_start", OnRoundStart);
			UnhookEvent("round_end", OnRoundEnd);
			UnhookEvent("player_spawn", OnPlayerSpawn);
		}
		
		case 1:
		{
			HookEvent("round_start", OnRoundStart);
			HookEvent("round_end", OnRoundEnd);
			HookEvent("player_spawn", OnPlayerSpawn);
		}
	}
}

public OnTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SpawnTime = GetConVarFloat(cvar);
}

public OnFreezeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseFreezeTime = GetConVarBool(cvar);
}

public OnFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FreezeTime = GetConVarFloat(cvar);
}

public OnRestartGameChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ResetSpawnAllowed();
}