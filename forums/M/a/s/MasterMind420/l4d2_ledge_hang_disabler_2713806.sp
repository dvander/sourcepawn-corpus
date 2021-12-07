#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

bool bStaggered[MAXPLAYERS+1];
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

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnThink);
}

public void OnThink(int client)
{
	if (IsValidClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if ((GetConVarInt(hGrabLedgeStagger) == 0 && GetEntPropFloat(client, Prop_Send, "m_staggerTimer") > 0) ||
			GetConVarInt(hGrabLedgeSpecial) == 0 && (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0))
		{
			bStaggered[client] = true;
			AcceptEntityInput(client, "DisableLedgeHang");
		}
		else if (bStaggered[client])
		{
			bStaggered[client] = false;
			AcceptEntityInput(client, "EnableLedgeHang");
		}
	}
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}