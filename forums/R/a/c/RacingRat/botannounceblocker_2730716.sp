#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"
#define PLUGIN_DESCRIPTION "Blocks bot announce messages."

public Plugin:myinfo =
             {
                 name = "Bot announce blocker",
                 author = "RacingRat",
                 description = PLUGIN_DESCRIPTION,
                 version = PLUGIN_VERSION,
                 url = ""
            }

new bool:playerConnectFire = true;
new bool:playerConnectClientFire = true;
new bool:playerDisconnectFire = true;

public OnPluginStart()
{
    HookEvent("player_connect", PlayerConnect, EventHookMode_Pre);
    HookEvent("player_connect_client", PlayerConnectClient, EventHookMode_Pre);
    HookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Pre);
}

public OnPluginEnd()
{
    UnhookEvent("player_connect", PlayerConnect, EventHookMode_Pre);
    UnhookEvent("player_connect_client", PlayerConnectClient, EventHookMode_Pre);
    UnhookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Pre);
}

public Action:PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (playerConnectFire && GetEventInt(event, "bot") == 1)
    {
        decl String:clientName[33], String:networkID[22], String:address[32];
        GetEventString(event, "name", clientName, sizeof(clientName));
        GetEventString(event, "networkid", networkID, sizeof(networkID));
        GetEventString(event, "address", address, sizeof(address));

        new Handle:newEvent = CreateEvent("player_connect", true);
        SetEventString(newEvent, "name", clientName);
        SetEventInt(newEvent, "index", GetEventInt(event, "index"));
        SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
        SetEventString(newEvent, "networkid", networkID);
        SetEventString(newEvent, "address", address);

        playerConnectFire = false;
        FireEvent(newEvent, true);
        playerConnectFire = true;

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:PlayerConnectClient(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (playerConnectClientFire && GetEventInt(event, "bot") == 1)
    {
        decl String:clientName[33], String:networkID[22];
        GetEventString(event, "name", clientName, sizeof(clientName));
        GetEventString(event, "networkid", networkID, sizeof(networkID));

        new Handle:newEvent = CreateEvent("player_connect_client", true);
        SetEventString(newEvent, "name", clientName);
        SetEventInt(newEvent, "index", GetEventInt(event, "index"));
        SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
        SetEventString(newEvent, "networkid", networkID);

        playerConnectClientFire = false:
        FireEvent(newEvent, true);
        playerConnectClientFire = true;

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (playerDisconnectFire && GetEventInt(event, "bot") == 1)
    {
        decl String:clientName[33], String:networkID[22];
        GetEventString(event, "name", clientName, sizeof(clientName));
        GetEventString(event, "networkid", networkID, sizeof(networkID));

        new Handle:newEvent = CreateEvent("player_connect_client", true);
        SetEventString(newEvent, "name", clientName);
        SetEventInt(newEvent, "index", GetEventInt(event, "index"));
        SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
        SetEventString(newEvent, "networkid", networkID);

        playerDisconnectFire = false;
        FireEvent(newEvent, true);
        playerDisconnectFire = true;

        return Plugin_Handled;
    }

    return Plugin_Continue;
}
