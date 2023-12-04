#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

float		g_roundStartedTime;
ConVar	abs_l4d2_StartingHealth;
ConVar	abs_l4d2_StartingHealthTimePeriod;

// ------------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------------
public OnPluginStart()
{
	abs_l4d2_StartingHealth						= CreateConVar("abs_l4d2_StartingHealth", "130", "Sets starting health at map start and in safe rooms.");
	abs_l4d2_StartingHealthTimePeriod	= CreateConVar("abs_l4d2_StartingHealthTimePeriod", "180", "Sets the time after map start that starting health would be applied.");
	
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("round_start", Event_RoundStart);

	PrintToServer("ABS_L4D2_HealthSet - Loaded.");
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
  g_roundStartedTime = GetEngineTime();
}

//---------------------------------------------------------------------------
//	PlayerSpawnEvent()
//---------------------------------------------------------------------------
public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new clientID = GetClientOfUserId(GetEventInt(event,"userid"));
	if(IsClientInGame(clientID) && IsPlayerAlive(clientID) && GetClientTeam(clientID) == 2)
		CreateTimer(1.0, Timer_PlayerSpawn, clientID);
}

// ------------------------------------------------------------------------------
// Timer_PlayerSpawn()
// ------------------------------------------------------------------------------
public Action:Timer_PlayerSpawn(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		// Do not do the health boost after StartingHealthTimePeriod has expired
		if ((GetEngineTime() - g_roundStartedTime) < abs_l4d2_StartingHealthTimePeriod.IntValue)
		{
			// reset incap count,
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);

			// turn off isGoingToDie mode
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);

			// turn off IsOnThirdStrike - this resets B+W
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);

			// (try) to turn off the heart beat sound
			ClientCommand(client, "music_dynamic_stop_playing Player.Heartbeat");

			// reset their temp health.
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);

			// set their permanent health,
			SetEntProp(client, Prop_Send, "m_iHealth", abs_l4d2_StartingHealth.IntValue);
		}
	}
}
