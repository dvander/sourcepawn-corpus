#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.0"

float g_flRTDTimer[MAXPLAYERS + 1];

ConVar g_cvRTDEnable;

public Plugin myinfo = 
{
	name = "Bot RTD Support",
	author = "Marqueritte",
	description = "Bots will now use the rtd plugin.",
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
 	g_cvRTDEnable = CreateConVar("tf_bot_rtd_support", "0", "1 = Enable RTD Bot Support, 0 = Disable RTD Bot Support", _, true, 0.0, true, 1.0);
}

public Action OnPlayerRunCmd(int client)
{
	if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		if (g_cvRTDEnable.IntValue > 0)
		{	
			// For Unfinished RTD Support.
			if(g_flRTDTimer[client] < GetGameTime()) // Bots types !rtd and calls for medic afterwards.
			{
				FakeClientCommandThrottled(client, "say !rtd");
				FakeClientCommandThrottled(client, "voicemenu 0 0");
				g_flRTDTimer[client] = GetGameTime() + GetRandomFloat(70.0, 95.0);
			}
		}
		
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}