#pragma semicolon 1

#define PLUGIN_NAME				"Team Reminder"
#define PLUGIN_AUTHOR 			"Prophet"
#define PLUGIN_DESCRIPTION		"Remembers a client's last team upon reconnection."
#define PLUGIN_VERSION 			"1.0.0"
#define PLUGIN_URL				"extreme-network.net"

#include <sourcemod>
#include <clientprefs>
#include <sdktools>

#pragma newdecls required

Handle g_hLastTeamCookie;

bool g_bClientSwitched[MAXPLAYERS + 1];
int g_iLastClientTeam[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name 		=	PLUGIN_NAME,
	author 		=	PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version 	=	PLUGIN_VERSION,
	url 		=	PLUGIN_URL
};

public void OnPluginStart()
{	
	g_hLastTeamCookie = RegClientCookie("team_last", "Last player's team cookie.", CookieAccess_Protected);
	
	//HookEvent("player_team", Event_OnPlayerTeam);
	
	AddCommandListener(Event_OnJoinTeam, "jointeam");
}

public void OnClientPutInServer(int client)
{
	g_bClientSwitched[client] = false;
}

public void OnClientDisconnect(int client)
{
	g_iLastClientTeam[client] = GetClientTeam(client);
	
	char sTeam[32];
	IntToString(g_iLastClientTeam[client], sTeam, sizeof(sTeam));
	
	SetClientCookie(client, g_hLastTeamCookie, sTeam);
}

public Action Event_OnJoinTeam(int client, const char[] szCommand, int iArgCount)
{
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int team = StringToInt(arg1);
	
	switch (team)
	{
		case 1:
		{
			return Plugin_Continue;
		}
		
		case 2, 3:
		{
			if (!g_bClientSwitched[client])
			{
				g_bClientSwitched[client] = true;
				
				if (AreClientCookiesCached(client))
				{
					char sCookie[32];
					GetClientCookie(client, g_hLastTeamCookie, sCookie, sizeof(sCookie));
					
					int iLastTeam = StringToInt(sCookie);
					
					if (team != iLastTeam)
					{						
						ChangeClientTeam(client, iLastTeam);
						
						PrintToChat(client, "[SM] You were forced to join your last played team.");
						
						return Plugin_Handled;
					}
				}
			}
			
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

/*public Action Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	PerformTeamSwitch(client);
	
	return Plugin_Handled;
}*/