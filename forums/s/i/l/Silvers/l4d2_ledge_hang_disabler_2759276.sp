#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

ConVar hGrabLedgeSpecial, hGrabLedgeStagger;

public Plugin myinfo =
{
	name = "[L4D2] Ledge Hang Disabler",
	author = "MasterMind420", 
	description = "Disable ledge hanging while being grabbed or staggered",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	hGrabLedgeSpecial = CreateConVar("l4d_ledge_special", "0", "[1 = Enable][0 = Disable] Enable/Disable grabbing ledges while ridden or smoked");
	hGrabLedgeStagger = CreateConVar("l4d_ledge_stagger", "0", "[1 = Enable][0 = Disable] Enable/Disable grabbing ledges while staggered");

	AutoExecConfig(true, "l4d2_ledge_hang_disabler");
}

public Action L4D_OnLedgeGrabbed(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if ((GetConVarInt(hGrabLedgeStagger) == 0 && GetEntPropFloat(client, Prop_Send, "m_staggerTimer") > 0) ||
			GetConVarInt(hGrabLedgeSpecial) == 0 && (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0))
		{
			return Plugin_Handled;
		}
	}
	

	return Plugin_Continue;
}