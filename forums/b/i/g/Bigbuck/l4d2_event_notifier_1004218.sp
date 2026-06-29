// Force strict semicolon mode
#pragma semicolon 1

/**
 * Includes
 *
 */
#include <sourcemod>
#include <sdktools>

/**
 * Global variables
 *
 */
// Determines if clients name was changed or not
new bool: name_changed = false;

/**
 * Plugin information
 *
 */
public Plugin: myinfo =
{
	name = "[L4D2] Event Notifier",
	author = "Cuthbert",
	description = "Announces L4D events.",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.com/"
};

/**
 * Setup plugins first run
 *
 */
public OnPluginStart()
{
	// Create convars
	CreateConVar("sm_l4d2_event_notifier_version", PLUGIN_VERSION, "[L4D2] Event Notifier Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Hook events
	HookEvent("drag_begin", Event_DragBegin);
}

/**
 * Handles when a smoker starts to drag a player
 *
 * @handle: event - The drag_begin event handle
 * @string: name - Name of the event
 * @bool: Handles event broadcasting type
 *
 */
public Event_DragBegin(Handle: event, const String: name[], bool: dontBroadcast)
{
	// Get the event information
	new attacker_id	= GetEventInt(event, "userid");
	new victim_id		= GetEventInt(event, "subject");

	// Get correct client ids
	new victim 	= GetClientOfUserId(victim_id);
	new attacker	= GetClientOfUserId(attacker_id);

	// Now get their names
	decl String: victim_name[64];
	decl String: attacker_name[64];
	GetClientName(victim, victim_name, sizeof(victim_name));
	GetClientName(attacker, attacker_name, sizeof(attacker_name));

	// Here we have two different ways to print
	// This one prints the message to the client
	PrintToChat(attacker, "You have started to drag survivor");
	PrintToChat(victim, "You are being dragged by a Smoker!");
	// This prints the message to everyone
	PrintToChatAll("A Smoker is dragging a survivor!");
	// Sourcemod lets us do cool things like formatting so now we can stick in names
	PrintToChatAll("Smoker %s has started to drag %s", attacker_name, victim_name);
}