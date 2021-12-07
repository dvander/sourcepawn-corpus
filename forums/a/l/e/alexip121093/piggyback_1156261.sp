//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#define PLUGIN_VERSION "1.0"
#define PLAYER        "player"

new g_piggy[MAXPLAYERS+1];
new Handle:pb_method;
new Handle:pb_enable;


public Plugin:myinfo = {
    name = "Piggyback",
    author = "Mecha the Slag",
    description = "Allows players to piggyback another player!",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    HookEvent("player_spawn", Player_Spawn);
    HookEvent("player_death", Player_Death);
    pb_method = CreateConVar("pb_method", "2", "Method to handle a piggybacking player. 1 = force view, 2 = disable shooting, 0 = do nothing (inaccurate aim)", FCVAR_PLUGIN);
    pb_enable = CreateConVar("pb_enable", "1", "Enable piggybacking", FCVAR_PLUGIN);
    CreateTimer(120.0, Notification);
}

public Action:Notification(Handle:hTimer) {
    CPrintToChatAll("{green}You can piggyback teammates by right-clicking them with your melee out!{default}"); 
    CreateTimer(120.0, Notification);
	return Plugin_Stop;
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    RemovePiggy(client);
    for (new i = 1; i <= MaxClients; i++) {
        if (g_piggy[i] == client) RemovePiggy(i);
    }
}

public Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    RemovePiggy(client);
    for (new i = 1; i <= MaxClients; i++) {
        if (g_piggy[i] == client) RemovePiggy(i);
    }
}

public OnClientPutInServer(client) {
    if (!(IsFakeClient(client))) SDKHook(client, SDKHook_PreThink, OnPreThink);
    g_piggy[client] = 0;
}

public OnClientDisconnect(client) {
    if (!(IsFakeClient(client))) SDKUnhook(client, SDKHook_PreThink, OnPreThink);
    RemovePiggy(client);
    for (new i = 1; i <= MaxClients; i++) {
        if (g_piggy[i] == client) RemovePiggy(i);
    }
}

public OnPreThink(client) {
    new iButtons = GetClientButtons(client);
    
    if ((iButtons & IN_ATTACK2) && (GetConVarBool(pb_enable))) {
       TraceTarget(client);
    }
    
    if (iButtons & IN_JUMP) {
        RemovePiggy(client);
    }
    
    if (g_piggy[client] > 0) {
        if (GetConVarInt(pb_method) == 1) {
            decl Float:vecClientEyeAng[3];
            GetClientEyeAngles(g_piggy[client], vecClientEyeAng) // Get the angle the player is looking
            TeleportEntity(client, NULL_VECTOR, vecClientEyeAng, NULL_VECTOR);
        }
        if (GetConVarInt(pb_method) == 2) {
            iButtons &= ~IN_ATTACK;
            iButtons &= ~IN_ATTACK2;
            SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
        }
        
    }
}

public Piggy(entity, other) {
    //Classnames of entities
    new String:otherName[64];
    new String:classname[64];

    GetEdictClassname(entity, classname, sizeof(classname));
    GetEdictClassname(other, otherName, sizeof(otherName));
    
    if (strcmp(classname, PLAYER) == 0 && strcmp(otherName, PLAYER) == 0 && entity != other && GetClientTeam(entity) == GetClientTeam(other) && IsPlayerAlive(entity) && IsPlayerAlive(other) && (g_piggy[entity] == 0) && (g_piggy[other] == 0) && (g_piggy[other] != entity) ) {
        decl Float:PlayerVec[3];
        decl Float:PlayerVec2[3];
        decl Float:vecClientEyeAng[3];
        decl Float:vecClientVel[3];
        vecClientVel[0] = 0.0;
        vecClientVel[1] = 0.0;
        vecClientVel[2] = 0.0;
        GetClientAbsOrigin(entity, PlayerVec2);
        GetClientAbsOrigin(other, PlayerVec);
        GetClientEyeAngles(other, vecClientEyeAng) // Get the angle the player is looking
        decl Float:distance;
        distance = GetVectorDistance(PlayerVec2, PlayerVec, true);
        
        if(distance <= 20000.0) {
            
            if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{teamcolor}%N{default} is on your back", entity);
            if (IsPlayerAlive(other)) CPrintToChatEx(entity, other, "You are piggybacking {teamcolor}%N{default}", other);
            
            PlayerVec[2] -= 40;
            TeleportEntity(entity, PlayerVec, vecClientEyeAng, vecClientVel);
            
            new String:tName[32];
            GetEntPropString(other, Prop_Data, "m_iName", tName, sizeof(tName));
            DispatchKeyValue(entity, "parentname", tName);
            
            SetVariantString("!activator");
            AcceptEntityInput(entity, "SetParent", other, other, 0);
            SetVariantString("flag");
            AcceptEntityInput(entity, "SetParentAttachment", other, other, 0);
            
            g_piggy[entity] = other;
        }
    }
}

public RemovePiggy(entity) {
    //Classnames of entities
    new String:classname[64];

    GetEdictClassname(entity, classname, sizeof(classname));
    
    if (strcmp(classname, PLAYER) == 0 && (g_piggy[entity] > 0)) {
    
        new other = g_piggy[entity];
    
        if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{teamcolor}%N{default} jumped off your back", entity);

        AcceptEntityInput(entity, "SetParent", -1, -1, 0);
        SetEntityMoveType(entity, MOVETYPE_WALK);
        
        g_piggy[entity] = 0;
        
        if (IsPlayerAlive(entity)) {
            decl Float:PlayerVec[3];
            decl Float:vecClientEyeAng[3];
            decl Float:vecClientVel[3];
            vecClientVel[0] = 0.0;
            vecClientVel[1] = 0.0;
            vecClientVel[2] = 0.0;
            GetClientAbsOrigin(other, PlayerVec);
            GetClientEyeAngles(other, vecClientEyeAng) // Get the angle the player is looking
            TeleportEntity(entity, PlayerVec, NULL_VECTOR, vecClientVel);
        }
    }
}

public TraceTarget(client) {
    new String:classname[64];
    decl Float:vecClientEyePos[3];
    decl Float:vecClientEyeAng[3];
    GetClientEyePosition(client, vecClientEyePos) // Get the position of the player's eyes
    GetClientEyeAngles(client, vecClientEyeAng) // Get the angle the player is looking

    //Check for colliding entities
    TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client)

    if (TR_DidHit(INVALID_HANDLE)) {
        new TRIndex = TR_GetEntityIndex(INVALID_HANDLE)
        GetEdictClassname(TRIndex, classname, sizeof(classname));
        if (strcmp(classname, PLAYER) == 0) Piggy(client, TRIndex);
    }
}

public bool:TraceRayDontHitSelf(entity, mask, any:data) {
    if(entity == data)  { // Check if the TraceRay hit the itself.
        return false    // Don't let the entity be hit
    }
        return true     // It didn't hit itself
}