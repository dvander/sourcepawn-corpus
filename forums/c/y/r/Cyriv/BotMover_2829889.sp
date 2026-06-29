#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

new Float:g_flagSpawnRadius = 10000.0;
new g_flagEntity = -1;
new Handle:g_hTimer = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Random Flag Spawner",
    author = "Cyriv",
    description = "Spawns an unassigned flag and teleports it randomly within a 10,000 unit radius.",
    version = "1.0"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_spawnflag", Command_SpawnFlag, "Spawns an unassigned flag and teleports it randomly.");

    // Create a repeating timer to teleport the flag periodically
    g_hTimer = CreateTimer(10.0, Timer_RandomTeleportFlag, _, TIMER_REPEAT);
}

public OnPluginEnd()
{
    // Kill the timer if it's still active
    if (g_hTimer != INVALID_HANDLE)
    {
        CloseHandle(g_hTimer);
        g_hTimer = INVALID_HANDLE;
    }
}

public Action:Command_SpawnFlag(client, args)
{
    SpawnFlag();
    return Plugin_Handled;
}

public Action:Timer_RandomTeleportFlag(Handle:timer, any:data)
{
    if (IsValidEntity(g_flagEntity)) {
        TeleportFlagToRandomLocation();
    }
    return Plugin_Continue;
}

public SpawnFlag()
{
    if (IsValidEntity(g_flagEntity)) {
        RemoveEdict(g_flagEntity);
    }
    
    // Spawn the flag entity
    g_flagEntity = CreateEntityByName("item_teamflag");
    if (g_flagEntity == -1) {
        PrintToServer("Failed to create flag entity.");
        return;
    }
    
    // Set the flag's properties to be unassigned and not team-specific
    DispatchKeyValue(g_flagEntity, "TeamNum", "0"); // Neutral flag
    DispatchSpawn(g_flagEntity);
    AcceptEntityInput(g_flagEntity, "Enable");
    TeleportFlagToRandomLocation();
}

public TeleportFlagToRandomLocation()
{
    if (g_flagEntity == -1) return;

    // Generate a random location within the specified radius
    new Float:randomPos[3];
    randomPos[0] = GetRandomFloat(-g_flagSpawnRadius, g_flagSpawnRadius);
    randomPos[1] = GetRandomFloat(-g_flagSpawnRadius, g_flagSpawnRadius);
    randomPos[2] = GetRandomFloat(-g_flagSpawnRadius, g_flagSpawnRadius);

    // Move the flag to the new random location
    TeleportEntity(g_flagEntity, randomPos, NULL_VECTOR, NULL_VECTOR);
    PrintToChatAll("Flag has teleported to a new location!");
}

public GetVectorInRange(Float:vec[3], Float:min, Float:max)
{
    vec[0] = GetRandomFloat(min, max);
    vec[1] = GetRandomFloat(min, max);
    vec[2] = GetRandomFloat(min, max);
}
