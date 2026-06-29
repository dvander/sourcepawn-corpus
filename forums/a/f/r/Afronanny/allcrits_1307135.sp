#include <sourcemod>
#include <tf2>

new Handle:g_hCvarEnabled;
new bool:g_bEnabled;
public Plugin:myinfo = 
{
	name = "AllCrits",
	author = "Afronanny",
	description = "Make every shot a crit",
	version = "1.0",
	url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("tf_allcrits", "0");
	HookConVarChange(g_hCvarEnabled, ConVarChanged_Enabled);
}

public ConVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = !!StringToInt(newValue);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (g_bEnabled)
	{
		result = true;
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

