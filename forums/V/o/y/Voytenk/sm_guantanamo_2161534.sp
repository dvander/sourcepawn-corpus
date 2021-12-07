// CS:GO Jailbreak guantanamo
// Original Compile Date: 03.07.2014
// Description/Features:
// 
// This plugin is designed to automate adding Guantanamo off or on in the CS:GO Jailbreak community. 
// A configurable ratio will specify how many Ts for CT. The ratio is matched every time the round start.
// 
// Usage/Cvar List:
// sm_guanta, [0,1]: Turns the plugin functionality on or off.
// sm_guanta_ratio, [1-10]: Sets the ratio of Ts to CTs for adding Guantanamo ON
// 
// Installation:
// Place the sm_guantanamo.smx file in addons/sourcemod/plugins/
// 
// Future Considerations:
// - Additional command !guanta for status
// 
// Special Thanks:
// - Team E.y.D

#include <sourcemod>
#include <sdktools>

#define terrorist 			2
#define counterTerrorist 	3

public Plugin:myinfo = 
{
	name 		= "SM Guantanamo",
	author 		= "Voytenk E.y.D",
	description = "This plugin automatic adding of Guantanamo off or on.",
	version 	= "1.0.0",
	url 		= "http://forums.alliedmods.net"
}

new Handle:ga_Cvar_guanta;
new Handle:ga_Cvar_guanta_ratio;

public OnPluginStart()
{
	// Hook start round command
	HookEvent("round_start", round_start);
	
	// Create ConVars
	ga_Cvar_guanta = CreateConVar( "sm_guanta", "1", "Enable or disable automatic adding of Guantanamo for jail", FCVAR_PLUGIN );
	ga_Cvar_guanta_ratio = CreateConVar( "sm_guanta_ratio", "2", "The ratio of terrorists to counter-terrorists. (guantanamo on if : 1CT < 2T)", FCVAR_PLUGIN );
	CreateConVar( "sm_guanta_version", "1.0.0", "There is no need to change this value.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );

	// Generate config file
	AutoExecConfig( true, "sm_guantanamo" );
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	// if plugin on
	if (GetConVarInt(ga_Cvar_guanta) == 1)
	{
	
		
		new idx		= 0;
		new countTs 	= 0;
		new countCTs 	= 0;
		new teamRatio = GetConVarInt(ga_Cvar_guanta_ratio);
		
		// count players
		for ( idx = 1; idx <= MaxClients ; idx++ )
		{
		      if ( IsClientInGame( idx ) )
		      {
				 if ( GetClientTeam( idx ) == terrorist )
		         {
		            countTs++;
		         }
				 
				 if ( GetClientTeam( idx ) == counterTerrorist )
		         {
		            countCTs++;
		         }
		      }      
		}
		
		// adding
		if ( countCTs < ( ( countTs ) / teamRatio ) || ! countCTs )
		{
		PrintToChatAll("\x04\x01\x04\x03 GUANTANAMO ON");
		ServerCommand("sm_msay Guantanamo ON");
		}
		else
		{
		PrintToChatAll("\x04\x01\x04\x03 GUANTANAMO OFF");
		ServerCommand("sm_msay Guantanamo OFF ");
		}
	}
}