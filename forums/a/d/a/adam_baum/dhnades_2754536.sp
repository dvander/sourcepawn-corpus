#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
 
#define PLUGIN_VERSION "1.0.0.0"

//cvars
new Handle:cvar_damage = INVALID_HANDLE;
new Handle:cvar_radius = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "SuperNades",
	author = "L. Duke, based upon AUSTINBOTS! - SavSin",
	description = "increase power of grenades",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_supernades_version", PLUGIN_VERSION, "Increased grenade damage", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvar_damage = CreateConVar("sm_supernades_damage", "1.3", "Damage of HE Grenades. <Default: 1.3>");
	cvar_radius = CreateConVar("sm_supernades_radius", "2.5", "Radius of the Grenade.  <Default: 2.5>");
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
	CreateTimer(0.01, ChangeGrenadeDamage, iGrenade, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ChangeGrenadeDamage(Handle:hTimer, any:iEnt)
{
	new Float:flGrenadePower = GetEntPropFloat(iEnt, Prop_Send, "m_flDamage");
	new Float:flGrenadeRadius = GetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius");
	
	SetEntPropFloat(iEnt, Prop_Send, "m_flDamage", (flGrenadePower*GetConVarFloat(cvar_damage)));
	SetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius", (flGrenadeRadius*GetConVarFloat(cvar_radius)));
	
}
