#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "xoxo^^"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define PROTECTION_TIME 10
#define PREFIX " \x04[SM]\x01"

int g_timeLeft[MAXPLAYERS + 1] =  { PROTECTION_TIME };
Handle g_currentTimer[MAXPLAYERS + 1];


public Plugin myinfo = 
{
	name = "Spawn protection", 
	author = PLUGIN_AUTHOR, 
	description = "Spawn protection for X seconds", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public OnClientDisconnect(int client)
{
	if (g_currentTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_currentTimer[client]);
		g_currentTimer[client] = INVALID_HANDLE;
	}
}

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_currentTimer[client] != INVALID_HANDLE)
		KillTimer(g_currentTimer[client]);
	
	g_currentTimer[client] = CreateTimer(1.0, Timer_SpawnProtection, client, TIMER_REPEAT);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	SetEntityRenderColor(client, 255, 0, 0, 255);
	PrintToChat(client, "%s \x07Spawn protection\x01 is now \x04ON\x01!", PREFIX);
	g_timeLeft[client] = PROTECTION_TIME;
	return Plugin_Continue;
}

public Action Timer_SpawnProtection(Handle timer, int client)
{
	SetHudTextParams(0.4, 0.2, 1.1, 0, 0, 204, 1, 0);
	g_timeLeft[client]--;
	if (g_timeLeft[client] <= 0)
	{
		ShowHudText(client, 1, "Spawn protection is now off!");
		PrintToChat(client, "%s \x07Spawn protection\x01 is now \x02OFF\x01!", PREFIX);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		KillTimer(g_currentTimer[client]);
		g_currentTimer[client] = INVALID_HANDLE;
		return;
	}
	ShowHudText(client, 1, "You have %d seconds left for your\n\t\t\tSpawn protection!", g_timeLeft[client]);
} 