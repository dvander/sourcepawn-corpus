// sourcemod script to randomize RED team's skin (RED or BLU skins)

#include <sourcemod>
#include <sdktools>
#include <tf2>

public Plugin:myinfo = 
{
    name = "RED Team Skin Randomizer",
    author = "Cyriv",
    description = "Randomizes RED team's skins between RED and BLU textures.",
    version = "1.0",
};

public OnPluginStart()
{
    // Hook player spawn event to apply the skin randomization
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get client who spawned
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // Ensure the client is valid and on the RED team
    if (IsValidClient(client) && TF2_GetClientTeam(client) == TFTeam_Red)
    {
        // Randomly select between RED and BLU skin (skin index 0 or 1 for most models)
        int skinIndex = GetRandomInt(0, 1);  // 0 = RED, 1 = BLU

        // Set the skin for the client
    }
}
