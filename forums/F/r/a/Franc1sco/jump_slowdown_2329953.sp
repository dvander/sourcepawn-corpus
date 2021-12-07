#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

new Handle:g_ConVar_Penalty = INVALID_HANDLE;
new Float:g_Penalty = 0.0;

new g_StaminaOffset = -1;
new bool:jump[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Jump Speed Penalty",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	g_StaminaOffset = FindSendPropInfo("CCSPlayer", "m_flStamina");
	if (g_StaminaOffset == -1)
	{	
		SetFailState("\"CCSPlayer::m_flStamina\" could not be found.");
	}
	
	g_ConVar_Penalty = CreateConVar("sm_jump_slowdown", "25.0", "Stamina penalty applied", 0, true, 0.0, true, 100.0);
	g_Penalty = GetConVarFloat(g_ConVar_Penalty);
	HookConVarChange(g_ConVar_Penalty, OnPenaltyChanged);
	
}

public OnPenaltyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_Penalty = StringToFloat(newVal);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		jump[client] = false;
		return Plugin_Continue;
	}
	
	if (!IsClientOnObject(client))
	{
		jump[client] = true;
		return Plugin_Continue;
	}
	if(jump[client])
	{
		jump[client] = false;
		SetEntDataFloat(client, g_StaminaOffset, g_Penalty, true);
		//PrintToChat(client, "saltado");
		return Plugin_Continue;
	}
	
	//SetEntDataFloat(client, g_StaminaOffset, 0.0, true);
	
	return Plugin_Continue;
}

bool:IsClientOnObject(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1 ? true : false;
}
