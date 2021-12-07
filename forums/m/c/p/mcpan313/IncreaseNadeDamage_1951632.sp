#pragma semicolon 1

#include <sdkhooks>

#define PLUGIN_VERSION "1.0.3"

new Handle:g_Cvar_HePower = INVALID_HANDLE;
new Handle:g_Cvar_HeRadius = INVALID_HANDLE;
public Plugin:myinfo =
{
	name = "Increase Nade Damage",
	author = "AUSTINBOTS! - SavSin",
	description = "Increase He Nade Damge and radius",
	version = PLUGIN_VERSION,
	url = "www.norcalbots.com"
}

public OnPluginStart()
{
	CreateConVar("ind_version", PLUGIN_VERSION, "Version of increased nade damage", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_Cvar_HePower = CreateConVar("sm_hePower", "1.3", "Power of HE nades. <Default: 1.3>");
	g_Cvar_HeRadius = CreateConVar("sm_heRadius", "2.5", "Radius of the nade.  <Default: 2.5>");
}

public OnEntityCreated(iEnt, const String:szClassname[])
{
	if(StrEqual(szClassname, "hegrenade_projectile"))
	{
		SDKHook(iEnt, SDKHook_SpawnPost, OnGrenadeSpawn);
	}
}

public OnGrenadeSpawn(iGrenade)
{
	CreateTimer(0.01, ChangeGrenadeDamage, EntIndexToEntRef(iGrenade), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ChangeGrenadeDamage(Handle:hTimer, any:ref)
{
	new iEnt = EntRefToEntIndex(ref);
	if (IsValidEdict(iEnt))
	{
		new Float:flGrenadePower = GetEntPropFloat(iEnt, Prop_Send, "m_flDamage");
		new Float:flGrenadeRadius = GetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius");

		SetEntPropFloat(iEnt, Prop_Send, "m_flDamage", (flGrenadePower*GetConVarFloat(g_Cvar_HePower)));
		SetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius", (flGrenadeRadius*GetConVarFloat(g_Cvar_HeRadius)));
	}
}
