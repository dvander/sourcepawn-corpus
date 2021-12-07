#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "cow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "CowFilter",
	author = PLUGIN_AUTHOR,
	description = "filters stuff bro",
	version = PLUGIN_VERSION,
	url = ""
};



new Float:gf_Used[MAXPLAYERS+1];




public OnPluginStart()
{
	RegConsoleCmd("status", DoBlock);
    RegConsoleCmd("ping", DoBlock);
    RegConsoleCmd("+klook", DoBlock);
    RegConsoleCmd("sm_status", Command_Status);
}


public Action DoBlock(int client, int args)
{
	return Plugin_Handled;
}

public void OnClientConnected(client)
{
    gf_Used[client] = -100.0;
}


public Action Command_Status(int client, int args)
{
    if(GetEngineTime() - gf_Used[client] < 1)
    {
        return Plugin_Handled;
    }
    gf_Used[client] = GetEngineTime();
    new String:sBuffer[512];
    Format(sBuffer, sizeof(sBuffer), "# userid name steamid\n");
    new String:sAuth[64];
    new String:sName[64];
    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            GetClientName(i, sName, sizeof(sName));
            if(IsFakeClient(i))
            {
                if(IsClientSourceTV(i))
                {
                    strcopy(sAuth, sizeof(sAuth), "TV");
                }
                else
                {
                    strcopy(sAuth, sizeof(sAuth), "BOT");
                }
            }
            else
            {
                GetClientAuthId(i, AuthId_Steam2, sAuth, sizeof(sAuth));
            }
            Format(sBuffer, sizeof(sBuffer), "%s# %d %s %s\n", sBuffer, GetClientUserId(i), sName, sAuth);
        }
    }
    Format(sBuffer, sizeof(sBuffer), "%s#end", sBuffer);
    PrintToConsole(client, sBuffer);
    return Plugin_Handled;
}