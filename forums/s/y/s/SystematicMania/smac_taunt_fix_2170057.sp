#pragma semicolon 1

#include <tf2>
#include <tf2_stocks>

#define TIME_TO_TICK(%1) (RoundToNearest((%1) / GetTickInterval()))
forward Action:SMAC_OnCheatDetected(client, const String:module[]);

enum TauntStatus {
	State_Inactive = 0,
	State_Active,
	State_Done
};

new TauntStatus:g_TauntStatus[MAXPLAYERS+1];
new g_iDoneTick[MAXPLAYERS+1];

new bool:g_bLateLoad = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "This module will not work for this mod and should be removed.");
		return APLRes_SilentFailure;
	}
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && TF2_IsPlayerInCondition(i, TFCond_Taunting))
			{
				g_TauntStatus[i] = State_Active;
			}
		}
	}
}

public OnClientDisconnect(client)
{
	g_TauntStatus[client] = State_Inactive;
	g_iDoneTick[client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsFakeClient(client))
		return Plugin_Continue;
	
	if (angles[0] > -135.0 && angles[0] < 135.0 && angles[1] > -270.0 && angles[1] < 270.0)
	{
		if (g_TauntStatus[client] == State_Done && GetGameTickCount() > g_iDoneTick[client])
		{
			g_TauntStatus[client] = State_Inactive;
			g_iDoneTick[client] = 0;
		}
		
		return Plugin_Continue;
	}
	
	if (g_TauntStatus[client] == State_Done)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if (condition == TFCond_Taunting)
	{
		g_TauntStatus[client] = State_Active;
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if (condition == TFCond_Taunting)
	{
		g_TauntStatus[client] = State_Done;
		
		if (!IsFakeClient(client))
		{
			g_iDoneTick[client] = GetGameTickCount() + (TIME_TO_TICK(GetClientLatency(client, NetFlow_Outgoing) * 1.5) + 1);
		}
	}
}

public Action:SMAC_OnCheatDetected(client, const String:module[])
{
	return (g_TauntStatus[client] == State_Inactive || !StrEqual(module, "smac_eyetest.smx")) ? Plugin_Continue : Plugin_Handled;
}
