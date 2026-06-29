#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Balance Changes to Blue Team",
    author = "Cyriv",
    description = "A plugin that changes the stats of the blue team classes",
    version = "1.0",
    url = ""
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
        switch (class) {
            case 1: // scout
                SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.15); // 15% faster
                break;
            case 2: // sniper
                SetEntProp(client, Prop_Send, "m_iMaxHealth", 300); // 300 health
                SetEntProp(client, Prop_Send, "m_iHealth", 300);
                GivePlayerItem(client, "tf_weapon_jar"); // jarate
                SetEntPropFloat(client, Prop_Send, "m_flDamageScale", 0.75); // 25% damage cost
                break;
            case 3: // soldier
                SetEntPropFloat(client, Prop_Send, "m_flDamageScale", 1.15); // 15% damage buff
                SetEntPropFloat(client, Prop_Send, "m_flJumpHeight", 1.1); // 10% jump height
                break;
            case 4: // demoman
                break;
            case 5: // medic
                SetEntPropFloat(client, Prop_Send, "m_flHealRate", 1.05); // 5% overheal
                SetEntPropFloat(client, Prop_Send, "m_flDamageScale", 1.1); // 10% damage buff
                break;
            case 6: // heavy
                SetEntProp(client, Prop_Send, "m_iMaxHealth", 600); // 600 health
                SetEntProp(client, Prop_Send, "m_iHealth", 600);
                SetEntPropFloat(client, Prop_Send, "m_flDamageScale", 1.35); // 35% damage buff
                break;
            case 7: // pyro
                SetEntPropFloat(client, Prop_Send, "m_flDamageScale", 0.4); // 60% damage nerf
                break;
            case 8: // spy
                SetEntProp(client, Prop_Send, "m_iMaxHealth", 100); // 100 health
                SetEntProp(client, Prop_Send, "m_iHealth", 100);
                SetEntPropFloat(client, Prop_Send, "m_flDamageScale", 1.1); // 10% damage buff
                break;
            case 9: // engineer
                SetEntProp(client, Prop_Send, "m_iMaxHealth", 120); // 120 health
                SetEntProp(client, Prop_Send, "m_iHealth", 120);
                SetEntPropFloat(client, Prop_Send, "m_flDamageScale", 0.65); // 35% damage nerf
                DisableEngineerBuildings(client);
                break;
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
