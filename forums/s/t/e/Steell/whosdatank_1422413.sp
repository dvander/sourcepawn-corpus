#pragma semicolon 1
#define PL_VERSION "1.0"

#include <sourcemod>

public Plugin:myinfo = {
    name = "Who's The Tank!?",
    author = "Steell",
    description = "Notifies the server of who is the current tank.",
    version = PL_VERSION,
    url = "http://forums.alliedmods.net/forumdisplay.php?f=60"
}

public OnPluginStart()
{
    HookEventEx("tank_spawn", Event_TankSpawn);
}

public Event_TankSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
    new AdminId:id;
    for (new i = 1; i <= MaxClients; i++)
    {
        id = GetUserAdmin(i);
        if (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Generic))
            PrintToChat(i, "%N has spawned as the tank!", GetClientOfUserId(GetEventInt(event, "userid")));
    }
    //PrintToChatAll("%N has spawned as the tank!", GetClientOfUserId(GetEventInt(event, "userid")));  
}

