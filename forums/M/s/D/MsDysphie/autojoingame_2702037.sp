#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name        = "Auto-JoinGame",
    author      = "Dysphie",
    description = "Disables the 'Join Game' screen to enter a server.",
    version     = "1.1.0",
    url         = "https://forums.alliedmods.net/showthread.php?p=2702037#post2702037"
};

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
		ClientCommand(client, "joingame");
}