#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define MAX_AREA_DIST    500

public Plugin:myinfo =  {
    name = "Local-Talk",
    author = "KoSSoLaX",
    description = "LocalTalk based from Voice Proximity Plugin",
    version = "1.2b",
    url = "blabla"
}

new g_bIsConnected[65];

public OnPluginStart() {
    //
    CreateTimer(0.1, Timer_UpdateListeners, _, TIMER_REPEAT);
    //
}
public OnClientDisconnect(client) {
    g_bIsConnected[client] = false;
}
public OnClientPostAdminCheck(client) {
    g_bIsConnected[client] = true;
}
//
//
// Voice Proximity Plugin
//
public Action:Timer_UpdateListeners(Handle:timer) {
    for (new client = 1; client<=GetMaxClients(); client++) {
        if(!IsValidClient(client)) {
            continue;
        }
        
        if( IsPlayerAlive(client) ) {
            check_area(client);
        }
        else {
            check_dead(client);
        }
    }
}

public check_area(client)  {
    
    if( !IsValidClient(client) )
        return;
    
    for (new id = 1; id <= GetMaxClients() ; id++) {
        
        if( !IsValidClient(id) )
            continue;
        if( id == client )
            continue;
        
        if(entity_distance_stock(client, id) <= MAX_AREA_DIST && IsPlayerAlive(id) ) {    
            //In Range
            SetListenOverride(client, id, Listen_Yes);
        }
        else {
            //Out of Range
            SetListenOverride(client, id, Listen_No);
        }
    }
}

public check_dead(client) {
    
    if( !IsValidClient(client) )
        return;
    
    for (new id = 1; id <= GetMaxClients() ; id++) {
        
        if( !IsValidClient(id) )
            continue;
        if( id == client ) 
            continue;
        
        SetListenOverride(client, id, Listen_No);
    }
}

public set_all_listening(client) {
    
    for (new id = 1; id <= GetMaxClients(); id++) {
        
        if( !IsValidClient(client) || !IsValidClient(id) ) 
            continue;
        if( id == client )
            continue;
        
        SetListenOverride(client, id, Listen_Yes);
    }
}

public Float:entity_distance_stock(ent1, ent2) {
    new Float:orig1[3];
    new Float:orig2[3];
 
    GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
    GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

    return GetVectorDistance(orig1, orig2);
}
public bool:IsValidClient(client) {
    if( client <= 0 )
        return false;
    
    if( client > GetMaxClients() )
        return false;
    
    if( !IsValidEdict(client) )
        return false;
    
    if( !IsClientConnected(client) )
        return false;
    
    if( !IsClientInGame(client) )
        return false;
    
    if( !IsClientAuthorized(client) )
        return false;
    
    if( !g_bIsConnected[client] )
        return false;
    
    return true;
} 