#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Trum | Trum#7913"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = {
    name = "[CSGO] Admin Talk",
    author = "Trum | Trum#7913",
    description = "Custom chat message for admins",
    url = "http://discord.me/trum",
};

public void OnPluginStart()
{
    RegAdminCmd("sm_at", Command_AdminMessage, ADMFLAG_SLAY, "The admin talk command");
}

public Action Command_AdminMessage(int client, int args)
{
    if(args < 1)
    {
        PrintToConsole(client, "Usage: sm_at <message>");
        return Plugin_Handled;
    }
	
    char Message[32];
    
    GetCmdArgString(Message, sizeof(Message));
    PrintToChatAll (" \x07[ADMIN]: \x09%s", Message);
    
    return Plugin_Handled;
}
