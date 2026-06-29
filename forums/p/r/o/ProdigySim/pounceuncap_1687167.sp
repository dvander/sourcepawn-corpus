#include <sourcemod>

#define PLUGIN_VERSION "2.0"

//globals
new Handle:hMaxPounceDmg;
new Handle:hMinPounceDist
new Handle:hMaxPounceDist;
new Handle:hPounceDmg;

new Float:flUnitsPerDmg;

public Plugin:myinfo = 
{
	name = "PounceUncap",
	author = "n0limit, ProdigySim",
	description = "Makes it easy to properly uncap hunter pounces",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96546"
}

public OnPluginStart()
{
	// Get relevant cvars
	hMaxPounceDmg = FindConVar("z_hunter_max_pounce_bonus_damage");
	hMaxPounceDist = FindConVar("z_pounce_damage_range_max");
	hMinPounceDist = FindConVar("z_pounce_damage_range_min");
	
	Initialize_Scales();
	
	//Create convar to set
	hPounceDmg = CreateConVar("pounceuncap_maxdamage","25","Sets the new maximum hunter pounce damage.",FCVAR_PLUGIN,true,1.0);
	CreateConVar("pounceuncap_version",PLUGIN_VERSION,"Current version of the plugin",FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//Hook changes to the convar
	if(hPounceDmg != INVALID_HANDLE)
		HookConVarChange(hPounceDmg,OnMaxDamageChange);
	
	//Save to config
	AutoExecConfig(true,"pounceuncap");
	
	ChangeDamage(GetConVarInt(hPounceDmg));
}

public OnConfigsExecuted()
{
	ChangeDamage(GetConVarInt(hPounceDmg));
}

public OnMaxDamageChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ChangeDamage(GetConVarInt(hPounceDmg));
}

Initialize_Scales()
{
	decl String:buf[10];
	
	GetConVarDefault(hMaxPounceDmg, buf, sizeof(buf));
	new Float:dmg = StringToFloat(buf);
	
	GetConVarDefault(hMaxPounceDist, buf, sizeof(buf));
	new Float:max_dist = StringToFloat(buf);
	
	GetConVarDefault(hMinPounceDist, buf, sizeof(buf));
	new Float:min_dist = StringToFloat(buf);
	
	flUnitsPerDmg = (max_dist-min_dist)/dmg;
}

ChangeDamage(max_dmg) 
{
	--max_dmg;
	
	new Float:dist = (flUnitsPerDmg * max_dmg) + GetConVarFloat(hMinPounceDist);
	
	SetConVarFloat(hMaxPounceDist,dist);
	
	SetConVarInt(hMaxPounceDmg,max_dmg);
}
