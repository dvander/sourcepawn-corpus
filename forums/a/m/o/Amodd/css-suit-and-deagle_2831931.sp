#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Suit & Deagle",
    author = "JaZz, modified by Amodd",
    description = "This plugin gives all players on spawn an assault suit (kevlar + helmet) and a Desert Eagle. This is especially useful for fy and aim maps.",
    version = "1.1.0.0",
    url = "http://www.andreas-glaser.com"
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client <= 0 || !IsClientInGame(client)) {
        return Plugin_Continue;
    }

    // Give Assault Suit (Kevlar and Helmet)
    GivePlayerItem(client, "item_assaultsuit", 0);

    // Check if player has a pistol in slot 1
    int weaponEntity = GetPlayerWeaponSlot(client, 1);
    if (weaponEntity != -1) {
        char classname[64];
        GetEdictClassname(weaponEntity, classname, sizeof(classname));
        if (!StrEqual(classname, "weapon_deagle")) {
            // Remove the current pistol if it's not a Desert Eagle
            RemovePlayerItem(client, weaponEntity);
            AcceptEntityInput(weaponEntity, "Kill");

            // Give Desert Eagle
            GivePlayerItem(client, "weapon_deagle", 0);
        }
    } else {
        // No pistol in slot 1, give Desert Eagle
        GivePlayerItem(client, "weapon_deagle", 0);
    }

    return Plugin_Continue;
}
