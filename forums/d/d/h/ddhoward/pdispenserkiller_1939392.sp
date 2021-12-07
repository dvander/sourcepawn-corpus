#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:sm_phantomdispenser = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Phantom Dispenser Killer",
	author = "Derek D. Howard",
	description = "Kills any leftover dispensers belonging to players who are leaving the server.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1939392#post1939392"
};

public OnPluginStart() {
	//This cvar sets how the buildings should go away. If 0, the plugin is disabled. If 1, they vanish. If 2, they blow up into ammo drops like normal. This also affects the player's normal dispenser.
	sm_phantomdispenser = CreateConVar("sm_phantomdispenser", "1", "(0/1/2) 0 = Disabled, 1 = Dispensers vanish. 2 = Dispensers blow up. Also affects the normally built dispenser.", FCVAR_PLUGIN);
}

public OnClientDisconnect(client) {
	if (GetConVarInt(sm_phantomdispenser) != 0) {
		new dispenser = -1;
		while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
			if ((IsValidEntity(dispenser)) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
				if (GetConVarInt(sm_phantomdispenser) == 1) {
					AcceptEntityInput(dispenser, "Kill");
				} else if (GetConVarInt(sm_phantomdispenser) == 2) {
					SetVariantInt(1000);
					AcceptEntityInput(dispenser, "RemoveHealth");
				}
			}
		}
	}
}