// Includes
#include <sourcemod>

// Plugin version
#define PLUGIN_VERSION  "0.1"

public Plugin:myinfo = 
{
	name = "Check CVar",
	author = "TheJCS",
	description = "Checks if the CVar is on. If it's, turn it off.",
	version = "0.1",
	url = "http://kongbr.com.br"
}

/****** Configs Start ******/	
new Float:timerLoop = 1.5; // Time to each loop
new String:nameCVar[32] = "sm_hreserved_slots_enable"; // ConVar name
new bool:valueCVar = true; // ConVar "wanted" value
/****** Configs End ******/	

// ConVars
new Handle:cvarEnabled;
new Handle:cvarCVar; // Cool name Ya!

public OnPluginStart()
{
	// ConVars
	CreateConVar("sm_checkcvar", PLUGIN_VERSION, "Check Cvar plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarEnabled = CreateConVar("sm_checkcvar_enabled", "1", "Toggles the Check CVar plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// If you want, change "sm_hreserved_slots_enable" to other ConVar name
	cvarCVar = FindConVar(nameCVar);
	
	// The Timer - Change 1.5 to the time in seconds of each loop
	CreateTimer(timerLoop, Timer_CheckCVar, INVALID_HANDLE, TIMER_REPEAT);
	
}

public Action:Timer_CheckCVar(Handle:timer, any:client) {
	if (!GetConVarBool(cvarEnabled))
		return;
	if(GetConVarBool(cvarCVar) != valueCVar)
		SetConVarBool(cvarCVar, valueCVar);
}