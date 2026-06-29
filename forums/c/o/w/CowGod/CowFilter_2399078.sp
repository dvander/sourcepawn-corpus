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


float gf_Used[MAXPLAYERS + 1];

bool gb_cooldown[MAXPLAYERS + 1] = false;

public OnPluginStart()
{
	RegConsoleCmd("status", DoBlock);
	RegConsoleCmd("ping", DoBlock);
	RegConsoleCmd("sm_status", Command_Status);
    
	for (new i = 1; i <= MaxClients; i++)
	{
   		gb_cooldown[i] = false;
	}  
}


public Action DoBlock(int client, int args)
{
	if(!gb_cooldown[client])
	{
		gb_cooldown = true;
		CreateTimer(10.0, DoCooldown, client);
	}
	else
	return Plugin_Handled;
}

public Action DoCooldown(Handle timer, int client)
{
	gb_cooldown[client] = false;
	CloseHandle(timer);
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