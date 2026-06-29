#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

public Plugin myinfo = {
    name = "Civilian Pose Plugin",
    author = "dada513",
    description = "Adds a command to add a civilian pose",
    version = "1.0",
    url = "https://github.com/dada513/tf2-civplugin"
}

public void OnPluginStart() {
    PrintToServer("Civilian Pose Plugin loaded!");
    RegConsoleCmd("sm_civ", Command_Civ)
}

public Action Command_Civ(int client, int args) {
    PrintToConsole(client , "You are now a civilian!");
    TF2_RemoveWeaponSlot(client, 3); 
    TF2_RemoveWeaponSlot(client, 2); 
    TF2_RemoveWeaponSlot(client, 1); 
    TF2_RemoveWeaponSlot(client, 0); 
    return Plugin_Handled;
}