#include <sourcemod>
#include <dukehacks>
#include <tf2>

new Handle:crits = INVALID_HANDLE;
new Handle:chance = INVALID_HANDLE;
new Handle:sniperBodyShots = INVALID_HANDLE;
new Handle:ambassBodyShots = INVALID_HANDLE;

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo = 
{
	name = "SM Crit Chance with sniper rifle control",
	author = "pRED* & Wazz",
	description = "Change critical hit % and control sniper rifle body shots",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	crits = CreateConVar("sm_crits_enabled", "1");
	chance = CreateConVar("sm_crits_chance", "1.00");
	sniperBodyShots = CreateConVar("sm_crits_sniperbodyshots", "0", "Enable (1) or disable (0) critical body shots from the sniper rifle", 0, true, 0.0, true, 1.0);
	ambassBodyShots = CreateConVar("sm_crits_ambassbodyshots", "0", "Enable (1) or disable (0) critical body shots from the ambassador", 0, true, 0.0, true, 1.0);
	
	CreateConVar("sm_crits_version", PLUGIN_VERSION, "Crits Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	dhAddClientHook(CHK_TakeDamage, TakeDamageHook);
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!GetConVarBool(crits))
	{
		return Plugin_Continue;
	}
	
	if (!GetConVarBool(sniperBodyShots))
	{
		if (StrEqual(weaponname, "tf_weapon_sniperrifle", false))
			return Plugin_Continue;
	}
	if (!GetConVarBool(ambassBodyShots))
	{
		if (StrEqual(weaponname, "tf_weapon_revolver", false) && GetEntProp(weapon, Prop_Send, "m_iEntityQuality") == 3)
			return Plugin_Continue;
	}

	if (GetConVarFloat(chance) > GetRandomFloat(0.0, 1.0))
	{
		result = true;
		return Plugin_Handled;	
	}
	
	result = false;
	
	return Plugin_Handled;
}

public Action:TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype)
{
	if ((!GetConVarBool(sniperBodyShots)) && attacker > 0 && attacker <= MaxClients)
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