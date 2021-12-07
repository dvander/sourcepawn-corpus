#pragma semicolon 1

#define PLUGIN_AUTHOR "RNR"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Say Time",
	author = PLUGIN_AUTHOR,
	description = "Say timespent on server",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

Handle cv_advertise;

float intial[MAXPLAYERS]; //Stores the time when the player joins

public void OnPluginStart()
{
	cv_advertise = CreateConVar("sm_advertise", "1", "Enable or Disable(1/0) advertise at start of each round", FCVAR_PLUGIN | FCVAR_NOTIFY);
	RegConsoleCmd("sm_time", SayTime);
	
	HookEvent("player_disconnect", PlayerDisconnect);
	if (GetConVarBool(cv_advertise))
	{
		HookEvent("round_start", RoundStart);
	}
	
	int i;
	for (i = 1; i < MAXPLAYERS; i++)
	{
		intial[i] = 0.0;
	}
}

public OnClientPutInServer(client)
{
	if(intial[client] == 0.0)
	{
		intial[client] = GetEngineTime();
	}
}

public Action SayTime(int client, int args)
{
		float time;
		char timeStr[50];
		char bit[2][32];
		int h, m, s;
		
		time = GetEngineTime();
		time = FloatSub(time, intial[client]);
		
		FloatToString(time, timeStr, sizeof(timeStr));
		ExplodeString(timeStr, ".", bit, sizeof(bit), sizeof(bit[]));
		
		s = StringToInt(bit[0]);
		h = s / 3600;
		s = s % 3600;
		m = s / 60;
		s = s % 60;
		
		
		ReplyToCommand(client, "\x01You have spent \x04%d H: %d M: %d S\x01 second on the server", h, m, s);
		return Plugin_Handled;
}

public Action RoundStart(Event event, const char[] name, bool dontbroadcast) // Creates a timer every round of 15 seconds
{
	CreateTimer(15.0, Advertise);
}

public Action Advertise(Handle timer) // Prints message after 10 seconds every round
{
	PrintToChatAll("Use /time or !time in chat or sm_time in console to see time spent on the server.");
}

public Action PlayerDisconnect(Event event, const char[] name, bool dontbroadcast)
{
	int clientid;
	int client;
	clientid = GetEventInt(event, "userid");
	client = GetClientOfUserId(clientid);
	intial[client] = 0.0;
}