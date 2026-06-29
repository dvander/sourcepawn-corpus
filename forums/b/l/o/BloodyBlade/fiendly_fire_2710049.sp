#pragma semicolon 1
#pragma newdecls required

#define DEBUG
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[l4d2]no friendly fire",
	author = "AK978",
	version = "1.2"
}

public void OnPluginStart()
{
	FindConVar("survivor_burn_factor_easy").SetInt(0);
	FindConVar("survivor_burn_factor_Normal").SetInt(0);
	FindConVar("survivor_burn_factor_hard").SetInt(0);
	FindConVar("survivor_burn_factor_expert").SetInt(0);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (IsSurvivor(victim))
	{
		if (IsInfected(attacker))
		{
		}
		else if (IsCommonInfected(attacker))
		{
		}
		else if (AcceptEntityInput(victim, "break"))
		{
		}
		else if (damagetype & DMG_FALL
		|| damagetype & DMG_SLASH
		|| damagetype & DMG_ENERGYBEAM
		|| damagetype & DMG_VEHICLE
		|| damagetype & DMG_NERVEGAS
		|| damagetype & DMG_ACID
		|| damagetype & DMG_RADIATION
		|| damagetype & DMG_DROWN)
		{
		}
		else if (IsSurvivor(attacker))
		{
			if (damage != 0)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		else
		{
			if (damage != 0)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue; 
}

bool IsSurvivor(int client) 
{
	if (IsValidClient(client)) 
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS) 
		{
			return true;
		}
	}
	return false;
}

bool IsInfected(int client)
{
	if (IsValidClient(client))
	{
		if (GetClientTeam(client) == TEAM_INFECTED) 
		{
			return true;
		}
	}
	return false;
}

stock bool IsCommonInfected(int iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        char strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
}

bool IsValidClient(int client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}
