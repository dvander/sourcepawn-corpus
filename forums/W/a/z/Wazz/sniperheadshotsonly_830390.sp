#include <sourcemod>
#include <dukehacks>

#define PLUGIN_VERSION 		"1.0.0.0"

public Plugin:myinfo = 
{
	name = "Sniper Headshots Only",
	author = "Wazz",
	description = "Restricts snipers to headshots only",
	version = PLUGIN_VERSION,
};

public OnPluginStart()
{			
	CreateConVar("sm_sniperhs_version", PLUGIN_VERSION, "Sniper Headshot Only version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	dhAddClientHook(CHK_TakeDamage, TakeDamageHook);
}

public Action:TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype)
{
	if (attacker > 0 && attacker <= MaxClients)
	{
		new String:weapon[64];
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		if (StrEqual(weapon, "tf_weapon_sniperrifle", false))
		{		
			if (!(damagetype & DMG_ACID))
			{
				multiplier *= 0.0;
				return Plugin_Changed;
			} 
		}
	}
	
	return Plugin_Continue;
}