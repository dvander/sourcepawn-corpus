#include <sourcemod>

#define PLUGIN_VERSION "1.1"

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
	url = "http://forums.alliedmods.net/showthread.php?t=96546"
}

public OnPluginStart()
{
	// Get relevant cvars
	hMaxPounceDmg = FindConVar("z_hunter_max_pounce_bonus_damage");
	hMaxPounceDist = FindConVar("z_pounce_damage_range_max");
	hMinPounceDist = FindConVar("z_pounce_damage_range_min");
	
	//Create convar to sets
	hPounceDmg = CreateConVar("pounceuncap_maxdamage","25","Sets the new maximum hunter pounce damage.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	CreateConVar("pounceuncap_version",PLUGIN_VERSION,"Current version of the plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	//Save to config
	AutoExecConfig(true,"pounceuncap");
	
	//Hook changes to the convar
	if(hPounceDmg != INVALID_HANDLE)
		HookConVarChange(hPounceDmg,OnMaxDamageChange);

/*Code to execute the damage max code at plugin start:*/
	new String:newVal[10]
	GetConVarString(hPounceDmg, newVal, 10)
	ChangeDamage(hPounceDmg, newVal)
}

public OnMaxDamageChange(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	ChangeDamage(cvar, newVal) /*This code has been moved to a separate function.*/
}

ChangeDamage(Handle:cvar, const String:newVal[]) { /*Seperated the following code to enable being executed at startup.*/
	new dmg = StringToInt(newVal,10);
	new dist;
	
	if(dmg < 2)
		SetConVarInt(cvar,25);
	else
/*I don't know why you check if dmg < 2, maybe because lower values cause errors in the equation? Regardless, I would remove this and instead do the following:

	hPounceDmg = CreateConVar("pounceuncap_maxdamage","25","Sets the new maximum hunter pounce damage.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,2.0);


By adding the last two parameters (which are 'hasMin=true' and 'min=2.0'), the pounceuncap_maxdamage cvar CANNOT be set to a value less than 2.0, so you won't need to have the above check. If someone tries to set it lower, it will automagically be set to 2.0. This has the benefit of saving both file size and processing time.

(Additionally, I suggest setting the minimum to 25.0, not 2.0, as I dislike the idea of being able to set the max damage to LESS than standard.)
*/
	{ 
		//1 pounce damage per 28 in game units
		dist = 28 * dmg + GetConVarInt(hMinPounceDist);
		SetConVarInt(hMaxPounceDist,dist);
		//Always set minus 1, game adds 1 when dist >= range_max
		SetConVarInt(hMaxPounceDmg,--dmg);
	}
}
