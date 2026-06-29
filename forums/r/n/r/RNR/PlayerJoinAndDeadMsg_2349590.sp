#pragma semicolon 1

#include <sourcemod>
#include <geoip>

public Plugin myinfo = 
{
	name = "Death and join message",
	author = "RNR",
	description = "Prints death and join message",
	version = "1.2",
	url = "www.sourcemod.net"
};

Handle g_cvDeathMsgEnabled;
Handle g_cvJoinMsgEnabled;
Handle g_cvDeathMsg;
Handle g_cvShowCountry;
Handle g_cvLanOnOrOff;


public void OnPluginStart() {
	HookEvent("player_death", Player_Death_Event);
	g_cvDeathMsgEnabled = CreateConVar("sm_deathmessage", "1", "Determines if the death message should be printed or not.", FCVAR_PLUGIN | FCVAR_NOTIFY);
	g_cvJoinMsgEnabled = CreateConVar("sm_joinmessage", "1", "Determines if the join message should be printed or not.", FCVAR_PLUGIN | FCVAR_NOTIFY);
	g_cvDeathMsg = CreateConVar("sm_dmsg", "Long Live The Queen", "The Message that is printed on screen after \"<player> is dead.", FCVAR_PLUGIN | FCVAR_NOTIFY);
	g_cvShowCountry = CreateConVar("sm_showcountry", "1", "Determines if (country code/country name) has to be shown or not. sm_joinmessage needs to be 1 for this to work.", FCVAR_PLUGIN | FCVAR_NOTIFY);
	g_cvLanOnOrOff = CreateConVar("sm_lanonoroff", "1", "Determines if LAN has to be printed or not if lan client has connected", FCVAR_PLUGIN | FCVAR_NOTIFY);
	AutoExecConfig(true);
}

public Action Player_Death_Event(Handle event, const char[] name, bool dontbroadcast)
{
	if (!GetConVarBool(g_cvDeathMsgEnabled)) 
		return Plugin_Handled;
	
	int client;
	int clientid;
	char nick[32];
	char msg[120];
	clientid = GetEventInt(event, "userid");
	client = GetClientOfUserId(clientid);
	GetConVarString(g_cvDeathMsg, msg, 120);
	GetClientName(client, nick, sizeof(nick));
	if (!IsFakeClient(client)) 
	{
		PrintCenterTextAll("%s is dead. %s", nick, msg);
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	if (!GetConVarBool(g_cvJoinMsgEnabled)) 
		return;
	
	char name[32];
	char ip[26];
	char ipcode[3];
	
	GetClientName(client, name, sizeof(name));
	GetClientIP(client, ip, sizeof(ip));
	
	if(!IsFakeClient(client))
	{
		if (GetConVarBool(g_cvShowCountry)) 
		{
			GeoipCode2(ip, ipcode );
			if (strcmp(ipcode, "") == 0) 
			{
					if (GetConVarBool(g_cvLanOnOrOff)) 
					{
						PrintToChatAll("\x06(LAN)\x01%s\x04 has joined. Sit tight.", name);
					}
					else 
					{
						PrintToChatAll("\x01%s\x04 has joined. Sit tight.", name);	
					}
			}
			else 
			{
				PrintToChatAll("\x03(%s)\x01%s\x04 has joined. Sit tight.", ipcode, name);
			}
		}
		else 
		{
			PrintToChatAll("\x01%s\x04 has joined. Sit tight.", name);	
		}
	}
}
