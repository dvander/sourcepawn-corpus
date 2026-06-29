#pragma newdecls required

#pragma semicolon 1
#include <sourcemod>
#include <vip_core>

public Plugin myinfo =
{
	name = "[VIP] Bhop",
	author = "KOROVKA",
	version = "1.0.2"
};

#define VIP_BHOP				"BunnyHop"

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_BHOP, BOOL);
}

public void OnPluginStart() 
{ 
	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
}

public void OnPluginEnd() 
{
	VIP_UnregisterFeature(VIP_BHOP);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) 
{ 	
    if (IsPlayerAlive(client) && VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, VIP_BHOP) && buttons & IN_JUMP && !(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityMoveType(client) & MOVETYPE_LADDER) && GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1) 
		buttons &= ~IN_JUMP;
}  