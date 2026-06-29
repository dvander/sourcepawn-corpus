#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"
 
public Plugin:myinfo =
{
name = "Glide",
author = "Wazman",
description = "A little glide mode, you don't exactly noclip, you just float around and can't pass through buildings",
version = PLUGIN_VERSION,
url = "http://www.oldtimeservers.com"
};
 
public OnPluginStart()
{
    RegAdminCmd("sm_glide",GlideMe,ADMFLAG_RESERVATION,"Toggles glide on yourself");
}
 
public Action:GlideMe(client, args)
{
    if(client<1||!IsClientInGame(client)||!IsPlayerAlive(client))
    {
            ReplyToCommand(client, "\x04[SM] \x05You need to be alive to use glide");
            return Plugin_Handled;
    }
    if (GetEntityMoveType(client) != MOVETYPE_FLY)
    {
        LogAction(client, client, "Enabled glide");
        SetEntityMoveType(client, MOVETYPE_FLY);
        ReplyToCommand(client, "\x04[SM] \x05Glide Enabled");
    }
    else
    {
        LogAction(client, client, "Disabled glide");
        SetEntityMoveType(client, MOVETYPE_WALK);
        ReplyToCommand(client, "\x04[SM] \x05Glide Disabled");
    }
    return Plugin_Handled;
}