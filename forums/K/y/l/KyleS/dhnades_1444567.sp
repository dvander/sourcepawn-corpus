#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#define PLUGIN_VERSION "1.0.0.0"

//cvars
new Handle:cvar_damage;
new Handle:cvar_radius;

public Plugin:myinfo =
{
	name = "SuperNades",
	author = "L. Duke",
	description = "increase power of grenades",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};
 
public OnPluginStart()
{
	// register cvars
	CreateConVar("sm_supernades_version", PLUGIN_VERSION, "SuperNades version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_damage = CreateConVar("sm_supernades_damage", "2.0", "damage multiplier", FCVAR_SPONLY);
	cvar_radius = CreateConVar("sm_supernades_radius", "2.0", "radius multiplier", FCVAR_SPONLY);

}
 
// entity listener
public OnEntityCreated(edict, const String:classname[])
{
	// change grenade properties
	if (StrEqual(classname, "hegrenade_projectile"))
	{
		IgniteEntity(edict, 5.0);
		SetEntPropFloat(edict, Prop_Data, "m_flDamage", (GetEntPropFloat(edict, Prop_Data, "m_flDamage") * GetConVarFloat(cvar_damage)));
		SetEntPropFloat(edict, Prop_Data, "m_DmgRadius", (GetEntPropFloat(edict, Prop_Data, "m_DmgRadius") * GetConVarFloat(cvar_radius)));
	}
	return;
}
