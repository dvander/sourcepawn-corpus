
/**
 * disconnect.sp - atom0s (c) 2010 [atom0s@live.com]
 * =================================================================
 * 
 * Disconnect message removal.
 * 
 * Removes a users disconnection message.
 * 
 * =================================================================
 * 
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

/**
 * Plugin Version
 */
#define PLUGIN_VERSION "1.1.0"

/**
 * Disconnect Message CVar
 */
new Handle:g_DisconnectMessage;

/**
 * Plugin Information
 */
public Plugin:myinfo = {
	name 		= "Disconnect Message Removal",
	author 		= "atom0s",
	description = "Blocks disconnection messages.",
	version 	= PLUGIN_VERSION,
	url 		= "N/A"
};
 
/**
 * Generic Plugin Events
 */

public OnPluginStart( )
{
	// Create ConVars
	CreateConVar( "disconnectmsg_version", PLUGIN_VERSION, "Disconnect Message Removal Version (by atom0s)", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	g_DisconnectMessage = CreateConVar( "disconnect_message", "", "Disconnection message shown when a user is disconnected." );
	
	// Hook Disconnect Event (Pre-Event Handler)
	HookEvent( "player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre );
}

public Action:PlayerDisconnect_Event( Handle:event, const String:name[], bool:dontBroadcast )
{
	// Disconnection Message
	decl String:message[64];
	GetConVarString( g_DisconnectMessage, message, 64 );
	
	// Overwrite Disconnection Message
	SetEventString( event, "reason", message );
	return Plugin_Continue;
}
