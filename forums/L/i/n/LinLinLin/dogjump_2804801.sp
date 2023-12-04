#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0.0"
#define DOG_JUMP_VEL -20.0

bool g_player_jumping[MAXPLAYERS + 1];

public Plugin myinfo =    
{
    name = "[L4D2] Dog Jump Like cs1.6",   
	author = "Miuwiki",   
	description = "Make survivor can dog jump",   
	version = PLUGIN_VERSION,   
	url = "https://miuwiki.site"  
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        g_player_jumping[i] = false;
    }
}

public void OnClientPutInServer(int client)
{
    if( IsFakeClient(client) )
        return;
    
    PrintToChat(client, "\x05跳跃中按下蹲键即可狗跳");
    SDKHook(client, SDKHook_PostThink, SDK_PTCallback);
    SDKHook(client, SDKHook_PostThinkPost, SDK_PTPCallback);
}

void SDK_PTCallback(int client)
{
    static int jump[MAXPLAYERS + 1];
    if( !IsValidClient(client) || IsFakeClient(client) )
        return;
    
    int temp = GetEntProp(client, Prop_Send, "m_duckUntilOnGround");
    if( jump[client] == temp )
        return;
    
    jump[client] = temp;
    if( temp == 1 )
        g_player_jumping[client] = true;
    else if( IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity")) )
        g_player_jumping[client] = false;
}
void SDK_PTPCallback(int client)
{
    if( !IsValidClient(client) || IsFakeClient(client) )
        return;
    
    if( !g_player_jumping[client] )
        return;
    
    if( GetClientButtons(client) & IN_DUCK )
    {
        float vel[3];
        vel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
        vel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
        vel[2] = DOG_JUMP_VEL;
        TeleportEntity(client, NULL_VECTOR,NULL_VECTOR,vel);
        g_player_jumping[client] = false;
    }
}


bool IsValidClient(int client)
{
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return false;
    
    return true;
}