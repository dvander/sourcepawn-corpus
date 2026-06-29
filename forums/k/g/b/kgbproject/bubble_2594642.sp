#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Tetragromaton(kgbproject)"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
//#include <sdkhooks>
new Handle:g_iBubbleTime;
new Handle:g_iPlayerTimer[MAXPLAYERS+1];
public Plugin myinfo = 
{
	name = "Bubble meditation",
	author = PLUGIN_AUTHOR,
	description = "Prevent player being killed",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_iBubbleTime = CreateConVar("bubble_idletime", "6.0", "Reqired time to apply protection", FCVAR_HIDDEN, true, 0.0);
	AutoExecConfig(true, "bubbleconfig.cfg");
}
public TF2_OnConditionAdded(int client, TFCond:condition)
{
	if(condition == TFCond:7)
	{
		g_iPlayerTimer[client] = CreateTimer(GetConVarFloat(g_iBubbleTime), ApplyBubble, client);
	}
}
public Action ApplyBubble(Handle:timer, any:client)
{
	if(IsPlayerAlive(client))
	{
		TF2_AddCondition(client, TFCond:TFCond_Ubercharged, TFCondDuration_Infinite);
	}
}
public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(condition == TFCond:7)
	{
		TF2_RemoveCondition(client, TFCond:TFCond_Ubercharged);
		if(g_iPlayerTimer[client] != null)
		{
			CloseHandle(g_iPlayerTimer[client]);
			//PrintToChatAll("Found timer before ");
		}
	}
}