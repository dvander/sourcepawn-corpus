#include <ReviveMarkers>

#define PLUGIN_NAME "ReviveMarkers Forward Sample"
#define PLUGIN_VERSION "1.1"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "An example to show the usage of the Forwards and natives of the ReviveMarkers Plugin."
#define PLUGIN_URL "NULL"

new bool:ReviveMarkersLoaded = false;

public Plugin:myinfo = {
	name 			= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

public OnAllPluginsLoaded() {
	ReviveMarkersLoaded = LibraryExists("revivemarkers");
}
 
public OnLibraryRemoved(const String:name[]) {
	if (StrEqual(name, "revivemarkers")) {
		ReviveMarkersLoaded = false;
	}
}
 
public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "revivemarkers")) {
		ReviveMarkersLoaded = true;
	}
}

/**
 * This function gets called right before a Marker is spawned,
 * every Property, except the position, is already assigned.
 * You can use this function to modify the properties of the
 * Marker before it gets spawned, or block the spawning entirely.
 * 
 * @param client: The client index the Marker is going to be assigned to
 * @param marker: The marker entity reference you can use to edit the Marker
 * @return Plugin_Continue, Plugin_Handled or Plugin_Stop, depending on if you want to block the spawning or not
 */
public Action:OnReviveMarkerSpawn(client, marker) {
	if (!ReviveMarkersLoaded) { return Plugin_Continue; }
	// Modifying the Render Color before the Marker spawns
	SetEntityRenderColor(marker, 0,0,0);
	// If you want the marker to persist after a player respawned,
	// you MUST add this line in OnReviveMarkerSpawn
	SetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_nForcedSkin")+4, -1);
	// Continue as normal, letting ReviveMarker spawn the Marker
	
	// IMPORTANT: IF YOU WANT TO PREVENT THE MARKER FROM SPAWNING, USE PLUGIN_STOP
	
	return Plugin_Continue;
}

/**
 * Once the Decay Timer ticks (only applicable if revivemarkers_decay_time >= 0.1)
 * this function gets run. Usually despawns the Marker if not blocked, you can also
 * modify the marker properties.
 * 
 * @param client: The client index the Marker is assigned to
 * @param marker: The marker entity reference (already spawned) to edit
 * @return Plugin_Continue, Plugin_Handled or Plugin_Stop, depending on if you want to block the decaying or not
 */
public Action:OnReviveMarkerDecay(client, marker) {
	if (!ReviveMarkersLoaded) { return Plugin_Continue; }
	// Setting to a different Render Color after Timer ticked
	SetEntityRenderColor(marker, 0,0,255);
	// Block the Decay Timer from despawning the Revive Marker
	return Plugin_Handled;
}

/**
 * This runs directly before the marker is despawned.
 * 
 * @param client: The client index the Marker is assigned to
 * @param marker: The marker entity reference (already spawned) to edit
 * @return Plugin_Continue, Plugin_Handled or Plugin_Stop, depending on if you want to block the decaying or not
 */
public Action:OnReviveMarkerDespawn(client, marker) {
	if (!ReviveMarkersLoaded) { return Plugin_Continue; }
	// Set Render Color when Marker is about to be despawned
	SetEntityRenderColor(marker, 0,255,0);
	// Block the Marker from being despawned
	return Plugin_Handled;
}