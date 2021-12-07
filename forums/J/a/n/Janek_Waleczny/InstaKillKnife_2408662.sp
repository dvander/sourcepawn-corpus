#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new bool:gB_Enabled,
	Handle:gH_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "InstaKnifeKill for VIPs",
	author = "Janek",
	description = "VIP's can insta kill with knife",
	version = PLUGIN_VERSION,
	url = "http://cs-serwer.pl"
}

public OnPluginStart()
{
	new Handle:Version = CreateConVar("sm_ikk_version", PLUGIN_VERSION, "InstaKnifeKill version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	SetConVarString(Version, PLUGIN_VERSION, _, true);
	
	gH_Enabled = CreateConVar("sm_ikk_enabled", "1", "InstaKnifeKill is enabled?", FCVAR_PLUGIN, true, _, true, 1.0);
	gB_Enabled = true;
	
	HookEvent("player_death", Player_Death, EventHookMode_Pre);
	
	HookConVarChange(gH_Enabled, OnConVarChanged);
}

public Action:Player_Death(Handle:event, const String:name[], bool:dB)
{
	decl String:Weapon[32];
	
	GetEventString(event, "weapon", Weapon, 32);

	if(!gB_Enabled || StrContains(Weapon, "knife") == -1)
	{
		return Plugin_Continue;
	}
	
	SetEventBool(event, "headshot", true);
	
	return Plugin_Continue;
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	gB_Enabled = StringToInt(newVal)? true:false;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageCallback);
}

public Action:TakeDamageCallback(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new String:Weapon[32];
	
	if(inflictor > 0 && inflictor <= MaxClients)
	{
		new weapon = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");
		GetEdictClassname(weapon, Weapon, 32);
	}
	
	if(!gB_Enabled || StrContains(Weapon, "knife") == -1 || !IsValidClient(attacker) || !IsValidClient(victim))
	{
		return Plugin_Continue;
	}
	
	damage = float(GetClientHealth(victim) + GetClientArmor(victim));
	
	return Plugin_Changed;
}

stock bool:IsValidClient(client, bool:bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		if (IsPlayerGenericAdmin(client))
		{
			return true;
		}
	}
	
	return false;
}

/*
@param client id

return bool
*/
bool:IsPlayerGenericAdmin(client)
{
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_CUSTOM1, false);
}
