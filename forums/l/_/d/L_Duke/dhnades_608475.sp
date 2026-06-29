#include <sourcemod>
#include <sdktools>
#include <dukehacks>

#pragma semicolon 1
 
#define PLUGIN_VERSION "1.0.0.0"

//cvars
new Handle:cvar_version;
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
	cvar_version = CreateConVar("sm_supernades_version", PLUGIN_VERSION, "SuperNades version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  cvar_damage = CreateConVar("sm_supernades_damage", "2.0", "damage multiplier", FCVAR_SPONLY);
  cvar_radius = CreateConVar("sm_supernades_radius", "2.0", "radius multiplier", FCVAR_SPONLY);

}
 

// entity listener
public ResultType:dhOnEntityCreated(edict)
{
  // get class name
  new String:classname[64];
  GetEdictClassname(edict, classname, sizeof(classname)); 
  
  // change grenade properties
  if (StrEqual(classname, "hegrenade_projectile"))
  {
    IgniteEntity(edict, 5.0);
    new Float:damage = GetEntPropFloat(edict, Prop_Data, "m_flDamage") * GetConVarFloat(cvar_damage);
    new Float:radius = GetEntPropFloat(edict, Prop_Data, "m_DmgRadius") * GetConVarFloat(cvar_radius);
    SetEntPropFloat(edict, Prop_Data, "m_flDamage", damage);
    SetEntPropFloat(edict, Prop_Data, "m_DmgRadius", radius);
  }
  return;
}
