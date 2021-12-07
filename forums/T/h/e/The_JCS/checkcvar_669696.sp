// Includes
#include <sourcemod>

// Plugin version
#define PLUGIN_VERSION  "0.2"

public Plugin:myinfo = 
{
	name = "Check CVar",
	author = "TheJCS",
	description = "Checks if the CVar is on. If it's, turn it off.",
	version = "0.2",
	url = "http://kongbr.com.br"
}

/****** Configs Start ******/	
new Float:timerLoop = 90.0; // Time to each loop
new String:nameCVar[32] = "sm_hreserved_slots_enable"; // ConVar name
new bool:valueCVar = false; // ConVar "wanted" value
/****** Configs End ******/	

// ConVars
new Handle:cvarEnabled;
new Handle:cvarCVar; // Cool name Ya!

public OnPluginStart()
{
	// ConVars
	CreateConVar("sm_checkcvar", PLUGIN_VERSION, "Check Cvar plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnabled = CreateConVar("sm_checkcvar_enabled", "1", "Toggles the Check CVar plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCVar = FindConVar(nameCVar);
	
	// Hooker
	HookConVarChange(cvarCVar, ConVarChange_CVar);	
}

public ConVarChange_CVar(Handle:convar, const String:oldValue[], const String:newValue[]){
	if((StringToInt(newValue) == 1 ? true : false) != valueCVar)
		CreateTimer(timerLoop, Timer_CheckCVar);
}

public Action:Timer_CheckCVar(Handle:timer, any:client) {
	if (!GetConVarBool(cvarEnabled))
		return;
	if(GetConVarBool(cvarCVar) != valueCVar)
		SetConVarBool(cvarCVar, valueCVar);
}