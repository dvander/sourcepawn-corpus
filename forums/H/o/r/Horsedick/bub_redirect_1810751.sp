#include <sourcemod> 

new Handle:NewIP = INVALID_HANDLE;
new Handle:Timer = INVALID_HANDLE;
new Handle:STime = INVALID_HANDLE;
new Handle:g_hTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };  

public Plugin:myinfo =
{
    name = "New IP Redirect",
    author = "{SG} Bubka3",
    description = "Redirects client to your New IP with a message.",
    version = "1.0",
    url = "http://www.silencedguns.com/"
};

public OnPluginStart()
{
    HookEvent("player_spawn", EventSpawn);
    NewIP = CreateConVar("re_newip", "27.50.70.5:28115", "Set to your new IP.", FCVAR_PLUGIN);
    Timer = CreateConVar("re_time", "120", "Seconds to kick after not leaving.", FCVAR_PLUGIN);
    STime = CreateConVar("re_stime", "120", "Seconds to show connection display box.", FCVAR_PLUGIN);
}


public OnClientPostAdminCheck(client)
{
    if (IsClientInGame(client))
        g_hTimers[client] = CreateTimer(GetConVarFloat(Timer), IdlerKick, client, TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientDisconnect(client)
{
    if(g_hTimers[client] != INVALID_HANDLE)
        if(CloseHandle(g_hTimers[client]))
            g_hTimers[client] = INVALID_HANDLE;
}

public EventSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:buffer[32];
    GetConVarString(NewIP, buffer, sizeof(buffer));
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new Float:time = GetConVarFloat(STime); 
    new String:ip[32]; 
    GetConVarString(NewIP, ip, sizeof(ip));
    DisplayAskConnectBox(client, time, ip);
    PrintToChat(client, "[SM] We have a new server at IP: %s", ip);
    PrintToChat(client, "[SM] Press F3 to connect to the new server.");
    PrintToChat(client, "[SM] If you do not connect, you will be kicked from this server.");
}


public Action:IdlerKick(Handle:timer, any:client)
{
    decl String:buffer[32];
    GetConVarString(NewIP, buffer, sizeof(buffer));

    if (IsClientInGame(client))
        KickClient(client, "Get out! Moved to \"%s\"", buffer);
}