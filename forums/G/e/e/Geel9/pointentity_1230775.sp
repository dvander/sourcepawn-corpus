#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"
new TempEnt[MAXPLAYERS] = -1;
public Plugin:myinfo =
{
    
    name = "Point Entity Control",
    author = "Geel9",
    description = "Allows spawning of point entities with greater fidelity.",
    version = PLUGIN_VERSION,
    url = "google.com"
    
}

new Handle:version = INVALID_HANDLE;
public OnPluginStart()
{
    
    version = CreateConVar("point_entity_version",PLUGIN_VERSION,"Point Entity Control's version.", FCVAR_NOTIFY|FCVAR_PLUGIN);
    RegConsoleCmd("setent",setent);
    RegConsoleCmd("DFloat", DispatchKVFloat);
    RegConsoleCmd("DValue", DispatchKV);
    RegConsoleCmd("DVector", DispatchKVVector);
    RegConsoleCmd("DVectorMe", DispatchKVVectorMe);
    RegConsoleCmd("Dispatch", DoSpawn);
    HookEvent("player_disconnect", RemovePlayer);
    
}

public Action:RemovePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    TempEnt[client] = -1;
    
}

public Action:DoSpawn(client, args){
    
    if(GetUserFlagBits(client) & ADMFLAG_KICK && TempEnt[client] != -1){
        
        DispatchSpawn(TempEnt[client]);
        
    }
    
    
}

public Action:setent(client, args){
    
    new String:entity[64];
    GetCmdArg(1, entity, 64);
    TempEnt[client] = CreateEntityByName(entity);
    
}

public Action:DispatchKVFloat(client, args){
    
    new String:KV[64];
    GetCmdArg(1, KV, 64);
    new String:floatvalue[64];
    GetCmdArg(2, floatvalue, 64);
    new Float:float2 = StringToFloat(floatvalue);
    DispatchKeyValueFloat(TempEnt[client], KV, float2);
    
}

public Action:DispatchKV(client, args){
    
    new String:KV[64];
    GetCmdArg(1, KV, 64);
    new String:value[64];
    GetCmdArg(2, value, 64);
    
}

public Action:DispatchKVVectorMe(client, args){
    
    new Float:playervec[3];
    GetClientAbsOrigin(client, Float:playervec);
    DispatchKeyValueVector(TempEnt[client], "origin", playervec);
    
}

public Action:DispatchKVVector(client, args){
    
    new String:KV[64];
    GetCmdArg(1, KV, 64);
    new String:value1[64];
    GetCmdArg(2, value1, 64);
    new String:value2[64];
    GetCmdArg(3, value2, 64);
    new String:value3[64];
    GetCmdArg(4, value3, 64);
    new Float:float2[3];
    float2[0] = StringToFloat(value1);
    float2[1] = StringToFloat(value2);
    float2[2] = StringToFloat(value3);
    DispatchKeyValueVector(TempEnt[client], KV, float2);
    
}