#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define TEAM_SURVIVOR 2

new Handle:l4d_tank_fc_enable = INVALID_HANDLE;
new Handle:l4d_tank_fc_time = INVALID_HANDLE;

new Handle:TimerSpawnControl = INVALID_HANDLE;

new bool:bossSpawn = false;

bool g_bMapStarted;

public Plugin:myinfo =
{
	name = "[L4D] Tank First Chapter",
	author = "Ash The 9th Survivor",
	description = "Spawn tank in first chapter to Tutayaq Kaq server",
	version = "1.4",
	url = "N/A"
};

public OnPluginStart()
{
	l4d_tank_fc_enable = CreateConVar("l4d_tank_fc_enable", "1", "Enable tank in the first chapters.", FCVAR_NONE);
	l4d_tank_fc_time = CreateConVar("l4d_tank_fc_time", "70.0", "Time the first tank on a normal map.", FCVAR_NONE);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("round_end", Event_RoundEnd);
	
	AutoExecConfig(true, "[L4D] Tank First Chapter");
}

public Action:Event_RoundStart(Event:event, String:event_name[], bool:dontBroadcast)
{
	if (g_bMapStarted) return;
	g_bMapStarted = true;
	
	if (GetConVarBool(l4d_tank_fc_enable) && L4D_IsFirstMapInScenario())
	{
		bossSpawn = true;
		TimerSpawnControl = CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TimerLeftSafeRoom(Handle:timer)
{
	decl String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	if(StrEqual(mapname, "l4d_river01_docks") || StrEqual(mapname, "tutorial_standards"))
	{
		return Plugin_Handled;
	}
	else
	{
		if (LeftStartArea()) 
		{
			bossSpawn = false;
			CreateTimer(GetConVarFloat(l4d_tank_fc_time), SpawnTank, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

bool:LeftStartArea()
{
	new maxents = GetMaxEntities();
	for (new i = MaxClients + 1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				if (GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
				{
					return true;
				}
			}
		}
	}
	return false;
}

public Action:SpawnTank(Handle:timer)
{
	if (GetConVarBool(l4d_tank_fc_enable) && L4D_IsFirstMapInScenario() && bossSpawn == false)
	{
		new client = MyGetRandomClient();
		
		if (client > 0)
		{	
			new flags = GetCommandFlags("z_spawn");
			SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "z_spawn tank auto");
			SetCommandFlags("z_spawn", flags);
		}
	}
	return Plugin_Stop;
}

public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(l4d_tank_fc_enable))
	{
		TimerSpawnControl = INVALID_HANDLE;
		if (TimerSpawnControl != INVALID_HANDLE)
		{
			KillTimer(TimerSpawnControl);
			TimerSpawnControl = INVALID_HANDLE;
		}
		bossSpawn = true;
	}
	return Plugin_Handled;
}

MyGetRandomClient()
{
    for (new i = 1; i <= MaxClients; i++) 
	{
        if (IsClientInGame(i) && !IsFakeClient(i))
		{
            return i;
        }
    }
    return 0;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bMapStarted = false;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}