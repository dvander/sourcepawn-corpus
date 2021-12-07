#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

Handle g_hPreviouslyConnected;
bool g_bPreviouslyConnected[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "Force Reconnect New Players",
	author = "Cruze",
    description = "Force new player to reconnect to make sure they see particles.",
    version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnPluginStart()
{
	g_hPreviouslyConnected = RegClientCookie("Force Reconnect New Players", "FRNP Settings", CookieAccess_Private);
	for(int i = 1; i <= MaxClients; i++)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        
        OnClientCookiesCached(i);
    }
}

public void OnClientCookiesCached(int client) 
{
	char sValue[8];
	GetClientCookie(client, g_hPreviouslyConnected, sValue, sizeof(sValue));
	
	g_bPreviouslyConnected[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public void OnClientPostAdminCheck(int client)
{
	OnClientCookiesCached(client);
	CreateTimer(5.0, CheckPlayer, client);
}

public Action CheckPlayer(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		if(!g_bPreviouslyConnected[client])
		{
			PrintToChat(client, "[SM] You will be reconnected to server as it's your first connect.");
			CreateTimer(3.0, Reconnect, client);
			g_bPreviouslyConnected[client] = true;
			SetClientCookie(client, g_hPreviouslyConnected, "1");
		}
		/*
		else
		{
			PrintToChat(client, "[SM] Not first connect.");
		}
		*/
	}
}

public Action Reconnect(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		ClientCommand(client, "retry");
	}
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	if(IsClientReplay(client)) return false;
	if(IsClientSourceTV(client)) return false;
	return IsClientInGame(client);
}