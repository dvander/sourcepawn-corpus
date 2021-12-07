#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION 	"1.0"

static bool bL4D2;

ConVar hCvar_Enabled;

public Plugin myinfo =
{
	name 		= "[L4D1 And L4D2] Faster Health",
	author 		= "Ernecio (Satanael)",
	description = "Increase healing values, pills, adrenaline, etc.",
	version 	= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/profiles/76561198404709570/"
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if ( engine != Engine_Left4Dead && engine != Engine_Left4Dead2 )
	{
		strcopy( error, err_max, "The Plugin \"Faster Health\" only runs in the \"Left 4 Dead 1/2\" Games!." );
		return APLRes_SilentFailure; 
	}
	
	bL4D2 = ( engine == Engine_Left4Dead2 );
	return APLRes_Success;
}

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
	CreateConVar(				 "l4d_faster_health_version",  PLUGIN_VERSION, 	"Faster Health Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	hCvar_Enabled = CreateConVar("l4d_faster_health_enabled", 		"1", 		"Enables/Disables The plugin. 0 = Plugin OFF, 1 = Plugin ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	
	AutoExecConfig( true, "l4d_faster_health" );
}

/**
 * Event callback (server_cvar)
 * Handler when server settings have been run.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_ServerCvar( Event hEvent, const char[] sName, bool bDontBroadcast ) 
{
	if ( !hCvar_Enabled.BoolValue ) return;
	
	LoadSettings();
}

void LoadSettings()
{
	FindConVar("first_aid_kit_use_duration").IntValue = 2; 	// L4D1/2
	FindConVar("survivor_revive_duration").IntValue = 2; 	// L4D1/2
	FindConVar("first_aid_heal_percent").FloatValue = 1.0; 	// L4D1/2
	FindConVar("pain_pills_health_value").IntValue = 100; 	// L4D1/2
	FindConVar("survivor_revive_health").IntValue = 100; 	// L4D1/2
	
	if ( bL4D2 ) FindConVar("adrenaline_duration").IntValue = 60; 		// L4D2
	if ( bL4D2 ) FindConVar("adrenaline_health_buffer").IntValue = 95; 	// L4D2
	
	if ( IsDedicatedServer() ) PrintToServer( "Cvars loaded successfully" );
}	
