#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.9"

public Plugin:myinfo = 
{
    name = "RED+BLU Randomizer",
    author = "LazarusXeo",
    description = "",
    version = PLUGIN_VERSION,
    url = ""
};

public OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("post_inventory_application", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // Only target RED (Team 2)
    if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
    {
        CreateTimer(3.0, Timer_ApplyRandomSkin, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Continue;
}

public Action:Timer_ApplyRandomSkin(Handle:timer, any:userid)
{
    int client = GetClientOfUserId(userid);
    
    if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) 
    {
        return Plugin_Stop;
    }

    // 0 = RED skin, 1 = BLU skin
    int skinChoice = (GetRandomInt(1, 2) == 1) ? 0 : 1;
    
    // If skinChoice is 1 (BLU), we tell items they are on Team 3
    int visualTeam = (skinChoice == 1) ? 3 : 2;


    // We change the skin but keep the player's TeamNum as 2 (RED)
    SetEntProp(client, Prop_Send, "m_nSkin", skinChoice); 
    SetEntProp(client, Prop_Send, "m_nForcedSkin", skinChoice);
    SetEntProp(client, Prop_Send, "m_bForcedSkin", 1);


    for (int i = 0; i < 5; i++)
    {
        int weapon = GetPlayerWeaponSlot(client, i);
        if (weapon > 0 && IsValidEntity(weapon))
        {
            ForceVisualsOnEntity(weapon, skinChoice, visualTeam);
        }
    }


    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "tf_wearable*")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
        {
            ForceVisualsOnEntity(ent, skinChoice, visualTeam);
        }
    }
    
  
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "tf_powerup_bottle")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
        {
            ForceVisualsOnEntity(ent, skinChoice, visualTeam);
        }
    }

    return Plugin_Stop;
}

stock void ForceVisualsOnEntity(int entity, int skin, int team)
{
    if (!IsValidEntity(entity)) return;

 
    SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
    SetEntProp(entity, Prop_Send, "m_nSkin", skin);
    
    if (HasEntProp(entity, Prop_Send, "m_bForcedSkin"))
        SetEntProp(entity, Prop_Send, "m_bForcedSkin", 1);
        
    if (HasEntProp(entity, Prop_Send, "m_nForcedSkin"))
        SetEntProp(entity, Prop_Send, "m_nForcedSkin", skin);
}

stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}