#include <sdktools> 

#pragma newdecls required 

char g_szDefaultModel[][] =  
{ 
    "models/player/custom_player/legacy/tm_anarchist.mdl", 
    "models/player/custom_player/legacy/tm_pirate.mdl", 
    "models/player/custom_player/legacy/ctm_gign.mdl", 
    "models/player/custom_player/legacy/ctm_fbi.mdl" 
}; 

public void OnPluginStart() 
{ 
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post); 
} 

public void OnConfigsExecuted()  
{ 
    PrecacheDefaultModel(); 
} 

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{ 
    int userid = GetEventInt(event, "userid"); 
    int client = GetClientOfUserId(userid); 

    // Set Default 
    SetDefaultSkin(client, GetClientTeam(client)); 
     
    // Set Custom 
   // SetEntPropString(client, Prop_Send, "m_szArmsModel", "Your Custom Arms"); 
  //  CreateTimer(0.1, Timer_ModelDelay, userid); 

    // Fix Spawn without any weapon. 
    //int decoy = GivePlayerItem(client, "weapon_decoy"); 
    //if(decoy != -1) CreateTimer(0.1, Timer_DecoyDelay, EntIndexToEntRef(decoy)); 
} 

/*public Action Timer_DecoyDelay(Handle timer, int iRef) 
{ 
    int decoy = decoy = EntRefToEntIndex(decoy) 
     
    if(!IsValidEdict(decoy)) 
        return Plugin_Stop; 

    int owner = GetEntPropEnt(decoy, Prop_Send, "m_hOwnerEntity"); 
     
    if(IsClientInGame(owner) && IsPlayerAlive(owner)) 
        RemovePlayerItem(owner, decoy); 
     
    AcceptEntityInput(decoy, "Kill"); 

    return Plugin_Stop; 
}*/

public Action Timer_ModelDelay(Handle timer, int userid) 
{ 
    int client = GetClientOfUserId(userid); 
    int team
    char m_szMoedl[128]; 
    GetEntPropString(client, Prop_Data, "m_ModelName", m_szMoedl, 128); 
     
    if(!IsClientInGame(client) || !IsPlayerAlive(client)) 
        return Plugin_Stop; 
     
    if(team == 2) 
    { 
       
        SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/t_arms.mdl"); 
    } 
    else if(team == 3) 
    { 
      
        SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl"); 
    } 

    return Plugin_Stop; 
} 

void SetDefaultSkin(int client, int team) 
{ 
    char m_szMoedl[128]; 
    GetEntPropString(client, Prop_Data, "m_ModelName", m_szMoedl, 128); 

    if(team == 2) 
    { 
        SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/t_arms.mdl"); 
    } 
    else if(team == 3) 
    { 

        SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl"); 
    } 
} 

void PrecacheDefaultModel() 
{ 
    for(int x = 0; x < sizeof(g_szDefaultModel); ++x) 
        PrecacheModel(g_szDefaultModel[x]); 

    PrecacheModel("models/weapons/t_arms.mdl"); 
    PrecacheModel("models/weapons/ct_arms.mdl");
}  