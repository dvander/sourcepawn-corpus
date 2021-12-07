#include <sourcemod>

public Plugin:myinfo = {
name = "spawn info",
author = "[GR|IPM] ThE_HeLl_DuDe {A|O}",
description = "prints a message to server saying that the players has spawned",
version = "1.0",
url = ""
};


public OnPluginStart()
{
}

public OnClientPutInServer(client)
{
new String:auth[32];
new String:name[32];
GetClientAuthString(client, auth, 32);
GetClientName(client, name, 32);
PrintToServer("Player %s (%s) has spawned!",name,auth);
}

