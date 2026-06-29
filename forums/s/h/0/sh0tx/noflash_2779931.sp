#include <sourcemod>
#include <cstrike>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

ConVar plugin_enabled;
ConVar remove_entities;


public Plugin myinfo = {
	name = "[CSS] No Flashbangs",
	author = "sh0tx",
	description = "Removes the ability to buy/equip flashbangs.",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

public void OnPluginStart() {
    plugin_enabled = CreateConVar("sm_noflashbangs_enabled", "1", "Determines whether the plugin is enabled or not.");
    remove_entities = CreateConVar("sm_noflashbangs_remove_entities", "1", "Removes all flashbang entities when they are created, and despawns any flashbang grenades that are thrown.");
    CreateConVar("sm_noflashbangs_version", PLUGIN_VERSION, "Plugin version, do not edit.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action CS_OnBuyCommand(int client, const char[] weapon) {
    if (StrEqual(weapon, "flashbang") && GetConVarBool(plugin_enabled)) {
        PrintToChat(client, "[SM] Flash grenades are disabled on this server.");
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname) {
    if (GetConVarBool(plugin_enabled)) {
        if (GetConVarBool(remove_entities) && StrEqual(classname, "flashbang_projectile") || StrEqual(classname, "weapon_flashbang")) {  // not weapon_flashbang???
            RemoveEntity(entity);
        }
    }
}