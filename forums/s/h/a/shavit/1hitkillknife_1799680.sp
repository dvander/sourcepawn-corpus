#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.3.0"

new bool:gB_Enabled,
	Handle:gH_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "1 Hit Kill Knife",
	author = "TimeBomb",
	description = "Attack with a knife, BAM YOU'RE DEAD!",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	new Handle:Version = CreateConVar("sm_1hkf_version", PLUGIN_VERSION, "1 Hit Kill Knife version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	SetConVarString(Version, PLUGIN_VERSION, _, true);
	
	gH_Enabled = CreateConVar("sm_1hkf_enabled", "1", "1 Hit Knife Kill is enabled?", FCVAR_PLUGIN, true, _, true, 1.0);
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
		return true;
	}
	
	return false;
}