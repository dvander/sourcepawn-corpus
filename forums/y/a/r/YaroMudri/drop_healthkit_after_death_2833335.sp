#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define HEALTHKIT_MODEL "models/items/medkit_small.mdl"
#define HEALTHKIT_CLASSNAME "item_healthkit_small"

public Plugin myinfo = {
    name = "Drop Healthkit After Death",
    author = "Your Name",
    description = "Drops a small health kit when a player dies. The health kit is removed after 30 seconds if not picked up.",
    version = "1.0"
};

public void OnPluginStart() {
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsValidClient(client)) {
        float deathPos[3];
        GetClientAbsOrigin(client, deathPos);

        int healthKit = CreateHealthKit(deathPos);
        if (healthKit != -1) {
            CreateTimer(30.0, Timer_RemoveHealthKit, EntIndexToEntRef(healthKit), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

int CreateHealthKit(float pos[3]) {
    int healthKit = CreateEntityByName(HEALTHKIT_CLASSNAME);
    if (healthKit != -1) {
        DispatchKeyValue(healthKit, "model", HEALTHKIT_MODEL);
        DispatchSpawn(healthKit);
        TeleportEntity(healthKit, pos, NULL_VECTOR, NULL_VECTOR);
        return healthKit;
    }
    return -1;
}

public Action Timer_RemoveHealthKit(Handle timer, int healthKitRef) {
    int healthKit = EntRefToEntIndex(healthKitRef);
    if (healthKit != -1 && IsValidEntity(healthKit)) {
        AcceptEntityInput(healthKit, "Kill");
    }
    return Plugin_Stop;
}

bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}