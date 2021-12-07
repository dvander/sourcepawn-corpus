#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

public Plugin:myinfo = 
{
	name = "L4D2 Difficulty Override",
	author = "ProdigySim",
	description = "Overrides game difficulty",
	version = "1.1",
	url = "https://bitbucket.org/ProdigySim/misc-sourcemod-plugins"
}

new Handle:ghCvarEnabled;

public OnPluginStart()
{
	ghCvarEnabled = CreateConVar("l4d2_force_difficulty", "0", "Enforce z_difficulty in all game modes");
}

public Action:L4D_OnHasConfigurableDifficulty(&retVal)
{
	if(GetConVarBool(ghCvarEnabled))
	{
		retVal = 1;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

