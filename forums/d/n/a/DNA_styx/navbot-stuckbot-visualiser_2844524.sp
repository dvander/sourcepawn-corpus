/**
 * Navbot Stuckbot Visualiser v2.08
 * Caches stuck bot locations for the current map on map start, spawns floating sprite markers,
 * and prints locations in simplified console format.
 */

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name = "Navbot Stuckbot Visualiser",
    author = "YourName",
    description = "Caches and displays stuck bot locations for the current map with sprite markers",
    version = "2.08",
    url = ""
};

#define MAX_STUCK_BOTS 256

float g_StuckX[MAX_STUCK_BOTS];
float g_StuckY[MAX_STUCK_BOTS];
float g_StuckZ[MAX_STUCK_BOTS];
int   g_StuckCount = 0;

int g_SpriteEntities[MAX_STUCK_BOTS];

public void OnMapStart()
{
    g_StuckCount = 0;

    PrintToServer("[Navbot Stuckbot Visualiser] Map started, loading stuck bot locations...");

    char map[64];
    GetCurrentMap(map, sizeof(map));

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/navbot-stuckbot-visualiser/locations.txt");

    if (!FileExists(path))
    {
        PrintToServer("[Navbot Stuckbot Visualiser] File not found: %s", path);
        return;
    }

    Handle kv = CreateKeyValues("StuckBots");
    FileToKeyValues(kv, path);

    if (!KvGotoFirstSubKey(kv))
    {
        PrintToServer("[Navbot Stuckbot Visualiser] No stuck bot entries found.");
        CloseHandle(kv);
        return;
    }

    do
    {
        if (g_StuckCount >= MAX_STUCK_BOTS)
        {
            PrintToServer("[Navbot Stuckbot Visualiser] Maximum stuck bot limit reached.");
            break;
        }

        char botMap[64];
        KvGetString(kv, "map", botMap, sizeof(botMap));

        if (StrEqual(botMap, map))
        {
            g_StuckX[g_StuckCount] = KvGetFloat(kv, "x", 0.0);
            g_StuckY[g_StuckCount] = KvGetFloat(kv, "y", 0.0);
            g_StuckZ[g_StuckCount] = KvGetFloat(kv, "z", 0.0);

            g_StuckCount++;
        }
    }
    while (KvGotoNextKey(kv));

    CloseHandle(kv);

    // Print cached data in simplified format
    PrintToServer("[Navbot Stuckbot Visualiser] Stuck bots for map %s:", map);
    for (int i = 0; i < g_StuckCount; i++)
    {
        PrintToServer("  Location %d: %f %f %f", i+1, g_StuckX[i], g_StuckY[i], g_StuckZ[i]);
    }
    PrintToServer("[Navbot Stuckbot Visualiser] Total stuck bots for map %s: %d", map, g_StuckCount);

    // Spawn floating sprite markers
    for (int i = 0; i < g_StuckCount; i++)
    {
        float vec[3];
        vec[0] = g_StuckX[i];
        vec[1] = g_StuckY[i];
        vec[2] = g_StuckZ[i] + 16.0; // slightly above the ground

        g_SpriteEntities[i] = CreateEntityByName("env_sprite");
        if (g_SpriteEntities[i] != -1)
        {
            DispatchKeyValue(g_SpriteEntities[i], "model", "sprites/glow01.vmt");
            DispatchKeyValue(g_SpriteEntities[i], "rendermode", "5"); // glow
            DispatchKeyValue(g_SpriteEntities[i], "rendercolor", "255 0 0"); // red
            DispatchKeyValue(g_SpriteEntities[i], "scale", "0.5");
            TeleportEntity(g_SpriteEntities[i], vec, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(g_SpriteEntities[i]);
            ActivateEntity(g_SpriteEntities[i]);
        }
    }
}

public void OnMapEnd()
{
    // Remove sprite markers
    for (int i = 0; i < g_StuckCount; i++)
    {
        if (g_SpriteEntities[i] != -1)
        {
            AcceptEntityInput(g_SpriteEntities[i], "Kill");
            g_SpriteEntities[i] = -1;
        }
    }
}
