#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

#define cDefault 0x01
#define cLightGreen 0x03
#define cGreen 0x04
#define cDarkGreen 0x05

#define PLUGIN_VERSION "1.0"

// Uncomment for debugging
#define DEBUG 1

public Plugin:myinfo = 
{
    name = "Friendly Fire Jailbreak",
    author = "Heavy Break Server",
    description = "CT team can use a command to enable or disable friendly fire.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/heavy_break/"
};

// ===========================================================================
// GLOBALS
// ===========================================================================

ConVar g_Cvar_FF;

// ===========================================================================
// LOAD & UNLOAD
// ===========================================================================

public OnPluginStart()
{
    #if defined DEBUG
        LogError("[DEBUG] Plugin started.");
    #endif
    
    HookEvent("round_end", onRoundEnd);
    
    RegConsoleCmd("sm_frfr", Command_frfr, "Enable or disable friendly fire.");
    g_Cvar_FF = FindConVar("mp_friendlyfire");

}

// ===========================================================================
// EVENTS
// ===========================================================================


public Action Command_frfr(int client, int args)
{

	if(GetClientTeam(client) != CS_TEAM_CT)
	{
		ReplyToCommand(client, "Only CT team can use this command.");
		return Plugin_Continue;
	}

	if(GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && g_Cvar_FF.BoolValue == false)
	{
		g_Cvar_FF.BoolValue = true;
		return Plugin_Continue;
		
	} else {
	
		if (GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client)) 
		{
			g_Cvar_FF.BoolValue = false; 
			return Plugin_Continue;
	
		} else {
	
			if (GetClientTeam(client) == CS_TEAM_CT) {
		
				ReplyToCommand(client, "You have to be alive to use this command.");	
				return Plugin_Continue;

			}	
	
		}
		
	}

	return Plugin_Continue;

}


public Action:onRoundEnd(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if (g_Cvar_FF.BoolValue) {
		g_Cvar_FF.BoolValue = false; 
	}
}	


