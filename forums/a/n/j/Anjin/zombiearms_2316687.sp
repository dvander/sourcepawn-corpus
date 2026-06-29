#pragma semicolon 1 

#include <sourcemod> 
#include <sdktools> 

new Handle:g_CvarModel; 
new String:g_Model[PLATFORM_MAX_PATH]; 

public OnPluginStart() 
{ 
    g_CvarModel = CreateConVar("sm_zombie_arms", "/models/player/bbs_93x_net/zombie/zm_arms_normal.mdl", "The path to the model for the hands of zombies."); 
    GetConVarString(g_CvarModel, g_Model, sizeof(g_Model)); 

    HookEvent("player_spawn", Player_Spawn); 
} 

public OnMapStart() 
{ 
    AddFileToDownloadsTable(g_Model); 

    if(!StrEqual(g_Model, "")) 
    { 
        PrecacheModel(g_Model, true); 
    } 
} 

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    new client = GetClientOfUserId(GetEventInt(event, "userid")); 

    if((GetClientTeam(client) == 2) && IsClientInGame(client) && !StrEqual(g_Model, "")) SetEntPropString(client, Prop_Send, "m_szArmsModel", g_Model); 
}  