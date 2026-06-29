// ammorefill.sp
#include <sourcemod>

public void OnPluginStart() {
    // This function is called when the plugin is loaded
    PrintToServer("Ammo Refill Plugin has been loaded!");
}

public Action OnClientKill(int victim, int killer, int weapon) {
    // This function is called when a player kills another player
    if (killer != 0 && IsValidClient(killer)) {
        // Check if the killer is a valid client
        RefillAmmo(killer);
    }
}

public void RefillAmmo(int client) {
    // Refill the ammo of the currently used weapon for the specified client
    int currentWeapon = GetClientWeapon(client);
    if (currentWeapon != 0) {
        // Check if the client has a valid weapon
        SetWeaponClipAmmo(client, currentWeapon, GetWeaponClipSize(client, currentWeapon));
        PrintToChat(client, "Ammo Refilled!");
    }
}
