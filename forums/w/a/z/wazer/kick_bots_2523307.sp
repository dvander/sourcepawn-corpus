#include <sourcemod>

public Plugin:myinfo = {
    name = "Bot Crash Prevention",
    author = "Sylwester",
    description = "prevents server from adding too many bots when players switch teams",
    version = "1.0"
}

new Handle:g_Cvar_bot_quota = INVALID_HANDLE;
new g_bot_quota
new g_max_players

public OnConfigsExecuted(){
    g_Cvar_bot_quota = FindConVar("bot_quota");
    g_bot_quota = GetConVarInt(g_Cvar_bot_quota);
    g_max_players = GetMaxClients();
}

public OnClientPutInServer(client){
    if(!IsFakeClient(client))
        return;
        
    if(g_bot_quota < GetConVarInt(g_Cvar_bot_quota))
        SetConVarInt(g_Cvar_bot_quota, g_bot_quota);
    
    new i, count;
    for(i = 1; i<=g_max_players; i++)
        if(IsClientInGame(i) && GetClientTeam(i)>1)
            count++;
            
    if(count<=g_bot_quota)
        return;
    
    new String:name[32]
    if(!GetClientName(client, name, 31))
        return;
    ServerCommand("bot_kick %s", name);
}  


