/*
	SM Weapon Cleanup bY TechKnow
	
	
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"




public Plugin:myinfo = 
{
	name = "SM Weapon Cleanup",
	author = "TechKnow",
	description = "Removes loose weapons droped",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};



new Handle:Cvar_Removeweapons;
new g_WeaponParent;

public OnPluginStart()
{
	CreateConVar("sm_Weaponcleanup_version", PLUGIN_VERSION, "WeaponCleanup version",     FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Cvar_Removeweapons = CreateConVar("Removeweapons_on", "1", "1 Removeweapons on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

        RegAdminCmd("sm_cleanup", Command_Manual, ADMFLAG_SLAY);

	HookEventEx("player_death", Cleanup, EventHookMode_Post);

	HookEventEx("round_start", Cleanup, EventHookMode_Post);
}

public Action:Cleanup(Handle:event,const String:name[],bool:dontBroadcast)
{
        // By Kigen (c) 2008 - Please give me credit. :)
        if (!GetConVarBool(Cvar_Removeweapons))
	{
		return Plugin_Continue;
	}
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}	
	return Plugin_Continue;
}

public Action:Command_Manual(client, args)
{
        // By Kigen (c) 2008 - Please give me credit. :)
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}	
	return Plugin_Continue;
}

