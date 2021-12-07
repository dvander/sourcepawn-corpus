#include <sourcemod>

public Plugin:myinfo = {
    name = "Nikooo777",
    author = "Nikooo777",
    description = "bot_quota 0 enforcer",
    version = "1.0"
}

public OnClientPutInServer(client){
    if(!IsFakeClient(client))
        return;
    new String:name[32]
    if(!GetClientName(client, name, 31))
        return;
    ServerCommand("bot_kick %s", name);
} 