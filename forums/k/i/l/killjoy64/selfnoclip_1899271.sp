#pragma semicolon 1
 
#include <sourcemod>
 
#define PLUGIN_VERSION "1.0.0"
 
public Plugin:myinfo =
{
    name        =    "Self Noclip",
    author        =    "killjoy",
    description    =    "personal noclip for Donators",
    version        =    PLUGIN_VERSION,
    url            =    "http://www.epic-nation.com"
};
 
public OnPluginStart()
{
    RegAdminCmd("sm_noclipme",NoclipMe,ADMFLAG_RESERVATION,"Toggles noclip on yourself");
}
 
public Action:NoclipMe(client, args)
{
    if(client<1||!IsClientInGame(client)||!IsPlayerAlive(client))
    {
            ReplyToCommand(client, "\x04[SM] \x05You need to be alive to use noclip");
            return Plugin_Handled;
    }
    if (GetEntityMoveType(client) != MOVETYPE_NOCLIP)
    {
        LogAction(client, client, "Enabled noclip");
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
        ReplyToCommand(client, "\x04[SM] \x05Noclip Enabled");
    }
    else
    {
        LogAction(client, client, "Disabled noclip");
        SetEntityMoveType(client, MOVETYPE_WALK);
        ReplyToCommand(client, "\x04[SM] \x05Noclip Disabled");
    }
    return Plugin_Handled;
}