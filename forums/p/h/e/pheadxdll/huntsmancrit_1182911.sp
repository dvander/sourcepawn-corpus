#include <sourcemod>
#include <tf2>

new Handle:g_hChance;

public OnPluginStart()
{
	g_hChance = CreateConVar("huntsman_crit", "0.1");
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(GetConVarFloat(g_hChance) > GetRandomFloat() && strcmp(weaponname, "tf_weapon_compound_bow") == 0)
	{
		result = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
