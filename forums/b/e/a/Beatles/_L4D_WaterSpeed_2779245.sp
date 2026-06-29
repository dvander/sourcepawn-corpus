#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define TEAM_SURVIVOR 2

new bool:IsRoundEnd = false;

new Float:vSpeed[MAXPLAYERS + 1];
new bool:Hooked[MAXPLAYERS + 1];

new Handle:l4d_water_speed_enable = INVALID_HANDLE;
new Handle:l4d_water_speed_little = INVALID_HANDLE;
new Handle:l4d_water_speed_half = INVALID_HANDLE;
new Handle:l4d_water_speed_full = INVALID_HANDLE;
new Handle:l4d_water_speed_default = INVALID_HANDLE;

new bool:IsRoundStart;

public Plugin:myinfo =
{
	name = "[L4D] Water Speed",
	author = "Ash The 9th Survivor",
	description = "Survivor water speed to Tutayaq Kaq server",
	version = "1.9",
	url = "N/A"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 1\" game");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	l4d_water_speed_enable = CreateConVar("l4d_water_speed_enable", "1", "0 = Disable plugin, 1 = Enable plugin, 2 = Disable slowdown", FCVAR_NONE);
	l4d_water_speed_little = CreateConVar("l4d_water_speed_little", "0.5", "Speed multiplier if the survivor has a little body part submerged", FCVAR_NONE);
	l4d_water_speed_half = CreateConVar("l4d_water_speed_half", "0.4", "Speed multiplier if the survivor has a half body submerged", FCVAR_NONE);
	l4d_water_speed_full = CreateConVar("l4d_water_speed_full", "0.3", "Speed multiplier if the survivor is full body submerged", FCVAR_NONE);
	
	l4d_water_speed_default = FindConVar("survivor_speed");
	
	AutoExecConfig(true, "[L4D] Water Speed");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsRoundStart) return;
	IsRoundStart = true;
	
	if (GetConVarInt(l4d_water_speed_enable) > 0)
	{
		IsRoundEnd = false;
		ResetAllPlayerState();
		CreateTimer(0.2, CheckingTime, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetPlayerState(client);
}

ResetPlayerState(client)
{
	vSpeed[client] = 1.0;
	Hooked[client] = false;
	UnHook(client);
}

ResetAllPlayerState()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		ResetPlayerState(client);
	}
}

public Action:CheckingTime(Handle:timer)
{
	if (IsRoundEnd == false)
	{
		if (GetConVarInt(l4d_water_speed_enable) == 1)
		{
			for (new client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					new iWaterLevel = GetEntProp(client, Prop_Send, "m_nWaterLevel"); //0: no water, 1: a little, 2: half body, 3: full body under water
					new Float:speed = 1.0;
					if (iWaterLevel == 1)
					{
						Hook(client);
						speed = GetConVarFloat(l4d_water_speed_little);
					}
					else if (iWaterLevel == 2)
					{
						Hook(client);
						speed = GetConVarFloat(l4d_water_speed_half);
					}
					else if (iWaterLevel == 3)
					{
						Hook(client);
						speed = GetConVarFloat(l4d_water_speed_full);
					}
					else
					{
						UnHook(client);
					}
					vSpeed[client] = speed;
				}
			}
		}
		else if (GetConVarInt(l4d_water_speed_enable) == 2)
		{
			new iMaxEnt = GetMaxEntities();
			for (new i = MaxClients + 1; i <= iMaxEnt; i++)
			{
				if (IsValidEntity(i) && IsValidEdict(i))
				{
					decl String:sBuffer[64];
					GetEdictClassname(i, sBuffer, sizeof(sBuffer));
					if (StrEqual(sBuffer, "trigger_playermovement"))
					{
						AcceptEntityInput(i, "Disable"); //Disable|Enable (turn off|on), Kill (delete)
					}
				}
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:PreThinkPostHook(client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client))
	{
		new Float:defSpeed = GetConVarFloat(l4d_water_speed_default);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", defSpeed * vSpeed[client]);
	}
	else
	{
		Hooked[client] = false;
		SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPostHook);
	}
}

Hook(client)
{
	if (!Hooked[client])
	{
		Hooked[client] = true;
		SDKHook(client, SDKHook_PreThinkPost, PreThinkPostHook);
	}
}

UnHook(client)
{
	if (Hooked[client])
	{
		Hooked[client] = false;
		SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPostHook);
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsRoundStart = false;
	IsRoundEnd = true;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR)
		{
			UnHook(client);
		}
	}
}

public void OnMapEnd()
{
	IsRoundStart = false;
}