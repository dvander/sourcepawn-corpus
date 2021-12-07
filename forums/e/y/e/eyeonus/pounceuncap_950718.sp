include <sourcemod>

#define PLUGIN_VERSION "1.2"

//globals
new Handle:hMaxPounceDmg;
new Handle:hMinPounceDist
new Handle:hMaxPounceDist;
new Handle:hPounceDmg;

public Plugin:myinfo = 
{
	name = "PounceUncap",
	author = "n0limit",
	description = "Makes it easy to properly uncap hunter pounces",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96546#i"
}

public OnPluginStart()
{
	// Get relevant cvars
	hMaxPounceDmg = FindConVar("z_hunter_max_pounce_bonus_damage");
	hMaxPounceDist = FindConVar("z_pounce_damage_range_max");
	hMinPounceDist = FindConVar("z_pounce_damage_range_min");
	//Create convar to set
	hPounceDmg = CreateConVar("pounceuncap_maxdamage","25","Sets the new maximum hunter pounce damage.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,2.0);
	CreateConVar("pounceuncap_version",PLUGIN_VERSION,"Current version of the plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	//Hook changes to the convar
	if(hPounceDmg != INVALID_HANDLE)
		HookConVarChange(hPounceDmg,OnMaxDamageChange);

	/*eyeonus - Run uncap code on change to "z_hunter_max_pounce_bonus_damage" cvar */
	if(hMaxPounceDmg != INVALID_HANDLE)
		HookConVarChange(hMaxPounceDmg,OnMaxDamageChange);
	ChangeDamage();

	//Save to config
	AutoExecConfig(true,"pounceuncap");
}
public OnMaxDamageChange(Handle:cvar, const String:oldVal[], const String:newVal[]) { ChangeDamage(); }

ChangeDamage() /* Removed parameters due to newVal conflict with the two hooks. */
{
	new dmg = GetConVarInt(hPounceDmg) /* Assigned directly to hPounceDmg, instead of indirectly through newVal. */
	new dist;

	//1 pounce damage per 28 in game units
	dist = 28 * dmg + GetConVarInt(hMinPounceDist);
	SetConVarInt(hMaxPounceDist,dist);
	//Always set minus 1, game adds 1 when dist >= range_max
	SetConVarInt(hMaxPounceDmg,--dmg);
}