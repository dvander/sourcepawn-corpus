/* BunnyStopper
* Author: Bullet (c) 31 Jan 2009 ALL RIGHTS RESERVED
* 
* Features:
* 	- compiles and loads
* 	- shows version and author in hlsw
*	- prevents bunnyhopping
* 
* Credits:
*	- <Milo|> Help with LogAction, and Timers, and for other ideas.
*	- theY4Kman For the help with Jumptimer
*	- Tsunami For help with MAXPLAYERS+1
*	- Liam and SAMURAI16 for their helpful comments regarding unnecessary spam, and how to improve the plugin.
* 
* History
* Version 0.0.1
* 	- created compilable plugin
* 	- Added Version
*	- Added Key and Value (view in hlsw)
* 
* Version 0.0.2
* 	- Debugging
* 	- Had loads of ideas, and tried them out, tried to flag the Jump_Event, Hookevent_Pre, etc.
*	- It got too faffy, so I removed loads of unneccesary crud, and rewrote most of it again.
*	- Settled with a change in gravity, instead of trying to rewrite the jump_event.
* 
* Version 1.0.0
* 	- Finished
*	- Sets users gravity to higher value for 0.3 seconds then resets the gravity to normal
*	- Allows normal jumping, and crouch jumping, but stops bunnyhoppers.
*
* Version 1.0.1
*	- Removed spam
*	- No further updates intended.
*
*/

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "bunnystopper",
	author = "Bullet",
	description = "Stops bunnyhoppers",
	version = PLUGIN_VERSION,
};

// When plugin starts
public OnPluginStart()
{
// Show cvars in hlsw
// Hopefully this works.
	CreateConVar("bunnystopper_version", PLUGIN_VERSION, "Shows the version", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	CreateConVar("bunnystopper_author", "Bullet", "Shows Authors details", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	HookEvent("player_jump", Event_Jumper);
	PrintToServer( ".------------------------------------------------------." );
	PrintToServer( "|                   BunnyStopper Loaded                |" );
	PrintToServer( "'------------------------------------------------------'" );
}

// When a Player Jumps
public Action:Event_Jumper(Handle:event, const String:name[], bool:dontBroadcast)
{
// Remind Player that Bunnyhopping isnt allowed, and alter Gravity 
// temporarily to affect Bunnyhopping, but not normal crouch jumps.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntityGravity(client, 1.5);
// Starts the 0.3 second timer.
	CreateTimer( 0.3, Timer_Bunnyhop_Detect, GetClientOfUserId(GetEventInt(event, "userid")), TIMER_REPEAT );
	
}
public Action:Timer_Bunnyhop_Detect(Handle:timer, any:client)
{
// Resets the users gravity. 
	SetEntityGravity(client, 1.0);
	return Plugin_Stop;
}

public OnPluginEnd()
{
// When plugin is unloaded, unhook the jump event, and spawn event.
	UnhookEvent("player_jump", Event_Jumper);
}

