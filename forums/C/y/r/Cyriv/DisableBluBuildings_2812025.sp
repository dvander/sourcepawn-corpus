#include <sourcemod>
#include <sdktools>
#include <tf2>


public Plugin myinfo = {
    name = "Disable Blue Engineer Buildings",
    author = "Cyriv,
    description = "A plugin that disables the buildings of the blue team engineers",
    version = "1.0",
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client == 0) return;
    
    int team = GetClientTeam(client);
    if (team == 3) { // blue team
        int class = GetEntProp(client, Prop_Send, "m_iClass");
        if (class == 9) { // engineer class
            DisableEngineerBuildings(client);
        }
    }
}

public void DisableEngineerBuildings(int client) {
    int maxEntities = GetMaxEntities();
    for (int i = 0; i < maxEntities; i++) {
        if (!IsValidEntity(i)) continue;
        
        char classname[64];
        GetEdictClassname(i, classname, sizeof(classname));
        
        if (StrEqual(classname, "obj_sentrygun") || StrEqual(classname, "obj_dispenser") || StrEqual(classname, "obj_teleporter")) {
            int owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
            if (owner == client) {
                SetVariantInt(0); // disable building
                AcceptEntityInput(i, "Enable");
            }
        }
    }
}
