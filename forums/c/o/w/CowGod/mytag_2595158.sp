#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "codingcow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "mytag",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

char myTag[MAXPLAYERS + 1][8];

public void OnPluginStart()
{
	RegConsoleCmd("sm_mytag", setTag);
}

public Action setTag(int client, int args)
{
	char tag[8];
	GetCmdArg(1, tag, sizeof(tag));
	
	if(strlen(tag) <= 8)
	{
		myTag[client] = tag;
		
		CS_SetClientClanTag(client, myTag[client]);
	}
	else
	{
		PrintToChat(client, "[\x02MyTag\x01] Tags can only contain up to 8 characters.");
	}
	
	return Plugin_Handled;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(strlen(myTag[i]) > 0)
		{
			CS_SetClientClanTag(i, myTag[i]);
		}
	}
}