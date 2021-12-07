#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>

public Plugin:myinfo =  {
    name = "Change Team Fix", 
    author = "Friagram", 
    description = "burp", 
    version = "1.0", 
    url = "http://steamcommunity.com/groups/poniponiponi"
};

public OnPluginStart()
{
    HookEvent("player_team", Event_PlayerTeam);
}

public Event_PlayerTeam(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(hEvent, "userid");
    new client = GetClientOfUserId(userid);
    if(client && IsClientInGame(client))
    {        
         FakeClientCommand(client, "kill");
         SDKHooks_TakeDamage(client, client, client, 9999.0);
     
         RequestFrame(frame_respawn, userid);
    }
}

public frame_respawn(any:userid)
{
    new client = GetClientOfUserId(userid);
    if(client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        TF2_RespawnPlayer(client);
    }
}