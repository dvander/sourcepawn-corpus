#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "stephen473"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define MESSAGETIME 10

char g_sMessageList[][] =  { 
	"Message: 1",
	"Message: 2",
	"Message: 3"
};

ArrayList g_aMessages;

public Plugin myinfo = 
{
	name = "Print Message",
	author = PLUGIN_AUTHOR,
	description = "Prints messages from list one by one every x minute",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/kHardy"
};

public void OnPluginStart()
{
	g_aMessages = new ArrayList();
	
	PushMessagesToArray();
}

public void OnMapStart()
{
	CreateTimer(60.0 * MESSAGETIME, Timer_Message, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void PushMessagesToArray()
{
	g_aMessages.Clear();
	
	for (int i = 0; i <= sizeof(g_sMessageList); i++) { 
		g_aMessages.PushString(g_sMessageList[i]);
	}
}

public Action Timer_Message(Handle timer)
{
	if (g_aMessages.Length == 0) { 
		PushMessagesToArray();
	}

	else { 
		char buffer[128];
		g_aMessages.GetString(0, buffer, sizeof(buffer));	
		g_aMessages.Erase(0);
		
		PrintToChatAll(buffer);
	}
		
}