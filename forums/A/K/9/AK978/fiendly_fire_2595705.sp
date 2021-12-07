#pragma semicolon 1

#define DEBUG
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "[l4d2]no friendly fire",
	author = "AK978",
	version = "1.2"
}

public OnPluginStart()
{
	SetConVarInt(FindConVar("survivor_burn_factor_easy"), 0);
	SetConVarInt(FindConVar("survivor_burn_factor_Normal"), 0);
	SetConVarInt(FindConVar("survivor_burn_factor_hard"), 0);
	SetConVarInt(FindConVar("survivor_burn_factor_expert"), 0);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
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

bool:IsSurvivor(client) 
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

bool:IsInfected(client) 
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

stock bool:IsCommonInfected(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
}

bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}