#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <sdkhooks>
#include <adt_trie>
#pragma newdecls required

#define VERSION "1.1"

static float distanceList[8] = { 128.0, 256.0, 512.0, 768.0, 1024.0, 1280.0, 1536.0, 1792.0 };
static StringMap distanceMap;

public Plugin myinfo = {
    name = "[TF2] Bonk",
    author = "Walgrim",
    description = "Bonk is back on Sandman (Optimized)",
    version = VERSION,
    url = "http://steamcommunity.com/id/walgrim/"
}

/**
 * Register in our map our keys = values
 * And also initialize the little cvar
 */
public void OnPluginStart() {
    CreateConVar("tf2_bonk_version", VERSION, "Bonk Version", FCVAR_SPONLY | FCVAR_UNLOGGED | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);
    distanceMap = new StringMap();
    char buffer[6];
    for (int index = sizeof(distanceList) - 1; index > 0; index--) {
        FloatToString(distanceList[index], buffer, sizeof(buffer));
        distanceMap.SetValue(buffer, float(index), false);
    }
    FloatToString(distanceList[6], buffer, sizeof(buffer));
    distanceMap.SetValue(buffer, 7.0, false);

    PrintToServer("[Bonk v%s] Plugin has loaded correctly !", VERSION);
}

/**
 * Hook takeDamage
 */
public void OnClientPutInServer(int client) {
    if (!IsThisAClient(client)) {
        return;
    }
    SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}

public Action OnClientTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
    int wepIndex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
    // Not the weapon ? No need to continue
    if (wepIndex != 44) {
        return Plugin_Continue;
    }

    float attackerOrigin[3];
    float victimOrigin[3];
    float distance[3];
    float finalDistance;
    GetClientAbsOrigin(attacker, attackerOrigin);
    GetClientAbsOrigin(victim, victimOrigin);
    MakeVectorFromPoints(attackerOrigin, victimOrigin, distance);
    finalDistance = GetVectorLength(distance);
    // No need to go further if distance is too small
    if (finalDistance < 128.0) {
        return Plugin_Continue;
    }
    // Maybe I should do an array list, I hate this convertion or did I miss something ?
    char buffer[6];
    float closestDistance = getBonkDist(distanceList, finalDistance, sizeof(distanceList));
    FloatToString(closestDistance, buffer, sizeof(buffer));
    if (closestDistance == 1792.0) {
        TF2_StunPlayer(victim, 7.0, 0.0, TF_STUNFLAGS_BIGBONK, attacker);
        return Plugin_Changed;
    }
    float time;
    distanceMap.GetValue(buffer, time);
    //PrintToChatAll("[Debug - Bonk.sp] Dist = %f, time = %f, RealDist = %f", closestDistance, time, finalDistance);
    TF2_StunPlayer(victim, time, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);

    return Plugin_Changed;
}

/**
 * Binary Search (it's really really just for fun, performance gains will not be visible with that small array)
 * The code is better in term of maintenance
 * Complexity is O(log(n))
 */
static float getBonkDist(float[] distList, float distance, int distListSize) {
    int tip_top = RoundToFloor(float(distListSize / 2));
    if (tip_top == 0) {
        return distList[0];
    }

    if (distance >= distList[tip_top]) {
        float[] destList = new float[distListSize - tip_top];
        getSlicedArray(distList, tip_top, distListSize, destList);
        return getBonkDist(destList, distance, distListSize - tip_top);
    } else {
        float[] destList = new float[tip_top];
        getSlicedArray(distList, 0, tip_top, destList);
        return getBonkDist(destList, distance, tip_top);
    }
}

/**
 * Slice our array (n/2)
 * Basically complexity here is O(n) where n = end - begin, but since we use it for binary search it's O(log(n))
 */
static void getSlicedArray(float[] list, int begin, int end, float[] destList) {
    for (int index = 0; index < end - begin; index++) {
        destList[index] = list[begin + index];
    }
}

/**
 * Yo you're really a client or not ?
 */
bool IsThisAClient(int client) {
    return (IsClientInGame(client) && 0 < client <= MaxClients);
}