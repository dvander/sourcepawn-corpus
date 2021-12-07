#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>

public Plugin:myinfo = {
	name = "Freak Fortress 2: Deathrun Helper Module",
	description = "This is a helper module to change the charset to the deathrun charset when loading a deathrun map",
	author = "SHADoW NiNE TR3S",
};

public OnPluginStart()
{
	LogMessage("===Initializing Freak Fortress 2 Deathrun Helper Module===");
}

public Action:FF2_OnLoadCharacterSet(&CharSetNum, String:CharSetName[] )
{
	new String:s[16];
	GetCurrentMap(s,16);
	if (!StrContains(s,"vsh_dr_") || !StrContains(s,"dr_") || !StrContains(s,"deadrun_") || !StrContains(s,"deathrun_"))
	{
		strcopy(CharSetName,32,"Dead Run");
		LogMessage("Deathrun map detected. Switching to deathrun charset.");
		return Plugin_Changed;
	}
	else
		LogMessage("Current map is not a deathrun map. Charset will not be switched");
	return Plugin_Continue;
}