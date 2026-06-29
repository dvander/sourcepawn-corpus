#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

ConVar plugin_enabled;

public Plugin myinfo = {
    name = "[CS:S/CS:GO?] Remove hostages",
    author = "sh0tx",
    description = "Removes hostages from the game.",
    version = PLUGIN_VERSION,
    url = "sourcemod.net"
}

public void OnPluginStart() {
    plugin_enabled = CreateConVar("sm_nohostages_enabled", "1", "0/1 - 0 = disabled, 1 = enabled");
    CreateConVar("sm_nohostages_version", PLUGIN_VERSION, "Remove hostages version, do not edit.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public void OnEntityCreated(int entity, const char[] classname) {
    if (plugin_enabled.BoolValue) {
        if (StrEqual(classname, "hostage_entity") && IsValidEntity(entity)) {
            RemoveEntity(entity);
        }
    }
}