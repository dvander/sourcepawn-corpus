#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "nhnkl159"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Freezing Nade",
	author = PLUGIN_AUTHOR,
	description = "Freezing Nade",
	version = PLUGIN_VERSION,
	url = "-none-"
};

public OnEntityCreated(iEnt, const String:szClassname[])
{
	if(StrEqual(szClassname, "hegrenade_projectile"))
	{
		SDKHook(iEnt, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	FreezePlayer(victim);
	CreateTimer(5.0, UnFreeze_Player, victim);
	return Plugin_Handled;
}

public Action:UnFreeze_Player(Handle:timer, any:victim)
{
    UnFreezePlayer(victim);
}  

public FreezePlayer(client)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
    SetEntityRenderColor(client, 255, 0, 170, 174);
}

public UnFreezePlayer(client)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
    SetEntityRenderColor(client, 255, 255, 255, 255);
}  