#include <left4downtown>
#include <sourcemod>
#include <sdktools>

static Handle:g_SurvSetCVar;


public Plugin:myinfo =  
{ 
	name = "Survivor set enforcer", 
	author = "", 
	description = "Forces L4D2 survivor set", 
	version = "1.0",
}

public OnPluginStart() 
{ 
	g_SurvSetCVar = CreateConVar("l4d_force_survivorset", "2", "Forces specified survivor set (0 - no change, 1 - force L4D1, 2 - Force L4D2)", FCVAR_PLUGIN);
} 

public Action:L4D_OnGetSurivorSet(&retVal)
{
	new val = GetConVarInt(g_SurvSetCVar);
	if(val == 1 || val == 2)
	{
		retVal = val;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:L4D_OnFastGetSurvivorSet(&retVal)
{
	new val = GetConVarInt(g_SurvSetCVar);
	if(val == 1 || val == 2)
	{
		retVal = val;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
