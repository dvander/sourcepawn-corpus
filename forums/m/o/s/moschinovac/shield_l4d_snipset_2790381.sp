#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1


Handle l4d_shield_damage_from_ci;
Handle l4d_shield_damage_from_si;
Handle l4d_shield_damage_from_tankwitch;


public void OnPluginStart()
{
	
	l4d_shield_damage_from_ci = CreateConVar("l4d_shield_damage_from_ci", "0.0", "ci damage to survivor with shield[0.0, 100.0]" );
  	l4d_shield_damage_from_si = CreateConVar("l4d_shield_damage_from_si", "10.0", "si damage to survivor with shield[0.0, 100.0]" );
  	l4d_shield_damage_from_tankwitch = CreateConVar("l4d_shield_damage_from_tankwitch", "20.0", "tank or witch damage to survivor with shield[0.0, 100.0]" );


	AutoExecConfig(true, "shield_l4d_snipset");
	
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, PlayerOnTakeDamage);
	}
}

HoldShieldWeapon(client)
{
	int ent=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(ent>0)
	{
		decl String:item[64];
		GetEdictClassname(ent,  item, sizeof(item));
		if(StrEqual(item, "weapon_melee"))
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
			if(StrContains(item, "shield")>0)
			{
				return ent;
			}
		}
	}
	return 0;
}


public Action PlayerOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(victim<=0)return Plugin_Continue;
	
	if(GetClientTeam(victim) != 2) return Plugin_Continue;
	
	if(!HoldShieldWeapon(victim)) return Plugin_Continue;
	
	float damageFactor=100.0;
	
	if(attacker>0 && attacker<=MaxClients)
	{
		if(GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8)
		{
			damageFactor=GetConVarFloat(l4d_shield_damage_from_tankwitch);
		}
		else 
			damageFactor=GetConVarFloat(l4d_shield_damage_from_si);
	}
	else
	{
		char name[64];
		GetEdictClassname(attacker, name, 64);
		if(StrEqual(name, "infected"))
		{
			damageFactor=GetConVarFloat(l4d_shield_damage_from_ci);
		}
		else if(StrEqual(name, "tank_rock"))
		{
			damageFactor=GetConVarFloat(l4d_shield_damage_from_tankwitch);
		}
		else 
			return Plugin_Continue;
	}

	

	damageFactor=damageFactor*0.01;


	damage=damage*damageFactor;

	return Plugin_Changed;
}


bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) 
		return false;
	
	if (!IsClientConnected(client)) 
		return false;
	
	if (!IsClientInGame(client)) 
		return false;
	
	return true;
}