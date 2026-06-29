#include <sourcemod>
#include <tf2>

new Handle:crits = INVALID_HANDLE;
new Handle:chance = INVALID_HANDLE;
new Handle:team;

#define PLUGIN_VERSION "0.2"

public Plugin:myinfo = 
{
	name = "Crits Chance 4 Saxton/FF2",
	author = "pRED*",
	description = "Change critical hit % for saxton/ff2",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	crits = CreateConVar("sm_crits_enabled", "1");
	chance = CreateConVar("sm_crits_chance", "0.35");
	team = CreateConVar("sm_crits_team", "2", "Team to allow crits. 2 - RED 3 - BLU 0 - Disable");
	CreateConVar("sm_crits_version", PLUGIN_VERSION, "Crits Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	new iTeamAllowed = GetConVarInt(team);
	if(iTeamAllowed && GetClientTeam(client) != iTeamAllowed)
	{
		return Plugin_Handled;
	}
	if (!GetConVarBool(crits))
	{
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