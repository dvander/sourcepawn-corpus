/* 
Changelog
	Version 1.0
		*	Initial release
	
	Version 1.1
		* 	Added timer to reset Round End status 
			*	This is to allow players to nade the ViP post round end, so ViP is only protected from C4 blast and that's it
		*	Modified message to user
	
	Version 2.0
		*	Updated code with Bacardi's suggestions and examples (big thanks to Bacardi for simplifying this plugin)

	Version 2.1
		*	Updated with more streamlined code that has less checks and compares - thanks to bacardi - this is now more his plugin than mine :)
		* 	Added translactions file for multi-language support
*/

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "2.1"

#define DMG_BLAST        (1 << 6)    // explosive blast damage

new planted_c4 = -1;

public Plugin:myinfo = 
{
	name = "No Bomb Damage",
	author = "Bacardi & TnTSCS",
	description = "Will protect special players from C4 blast, code fix by Bacardi",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=157955"
}

public OnPluginStart()
{
	CreateConVar("sm_NoBombDamage_buildversion",SOURCEMOD_VERSION, "This version of 'No Bomb Damage' was built on ", FCVAR_PLUGIN);
	CreateConVar("sm_NoBombDamage_version", PLUGIN_VERSION, "Protect From Bomb Damage Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	LoadTranslations("NoBombDamage.phrases");
}

public OnClientPutInServer(client)
{	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "planted_c4"))
	{
		planted_c4 = entity;
	}
}

public OnEntityDestroyed(entity)
{
	if(entity == planted_c4)
	{
		planted_c4 = -1;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(damagetype == DMG_BLAST && planted_c4 != -1 && planted_c4 == inflictor)
	{
		if(CheckCommandAccess(victim, "c4_damage_immunity", ADMFLAG_CUSTOM1))
		{
			PrintToChat(victim,"\x04%t", "Protected");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}