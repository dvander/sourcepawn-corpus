#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.0"
#define Default 0x01
#define limeGREEN 0x06

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <cstrike>

#pragma newdecls required

EngineVersion g_Game;

ConVar ctr_enabled;
ConVar ctr_mute_unknown_country;
ConVar ctr_group_tags;
ConVar ctr_chat_message;

bool g_gameCS;

char g_szCountry[MAXPLAYERS + 1];
char g_szCountry2[MAXPLAYERS + 1];

Handle g_hChatTagTimer[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Country talk rooms", 
	author = PLUGIN_AUTHOR, 
	description = "Puts people from different countries in their own talk room", 
	version = PLUGIN_VERSION, 
	url = "www.crypto-gaming.tk"
};

public void OnPluginStart()
{
	g_gameCS = true;
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		g_gameCS = false;
	}
	
	ctr_enabled = CreateConVar("ctr_enabled", "1", "Enables the plugin", _, true, 0.0, true, 1.0);
	ctr_mute_unknown_country = CreateConVar("ctr_mute_unknown_country", "0", "If player country is unknown it will (0) Makes own chat room for unknown countries (1) Mute everyone for client including client", _, true, 0.0, true, 1.0);
	if (g_gameCS)
		ctr_group_tags = CreateConVar("ctr_group_tags", "1", "(1) Sets players tag as country (0) Disables country tag", _, true, 0.0, true, 1.0);
	ctr_chat_message = CreateConVar("ctr_chat_message", "1", "(1) Shows a chat message for what country room you're in. (0) Disables the message", _, true, 0.0, true, 1.0);
	
	if(g_gameCS)
	HookEvent("player_team", playerTeam);
	
	HookConVarChange(ctr_enabled, onConvarChanged);
	HookConVarChange(ctr_mute_unknown_country, onConvarChanged);
}

public Action playerTeam(Handle event, char[] name, bool useless)
{
	if (!g_gameCS)
		return Plugin_Handled;
	if (GetConVarBool(ctr_group_tags))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (g_hChatTagTimer[client] == INVALID_HANDLE && IsClientInGame(client))
			g_hChatTagTimer[client] = CreateTimer(0.1, chatTag, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
		if (GetConVarBool(ctr_chat_message))
			if (StrEqual(g_szCountry[client], "UNKNOWN") && !GetConVarBool(ctr_mute_unknown_country))
			PrintToChat(client, "[%cCTR%c] You have been muted and other players have been muted for you. Reason: Country unknown.", limeGREEN, Default);
		
		PrintToChat(client, "[%cCTR%c] You have been put in country %s talk room", limeGREEN, Default, g_szCountry[client]);
		
	}
	return Plugin_Handled;
}

public Action chatTag(Handle timer, int client)
{
	if (!GetConVarBool(ctr_group_tags))
		return Plugin_Stop;
	
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		char g_szIP[16];
		GetClientIP(client, g_szIP, 60);
		if (!StrEqual(g_szCountry[client], "UNKNOWN"))
			GeoipCode2(g_szIP, g_szCountry2[client]);
		else
			Format(g_szCountry2[client], MAXPLAYERS + 1, "UNKNOWN");
			
		CS_SetClientClanTag(client, g_szCountry2[client]);
	}
	return Plugin_Continue;
}


public void onConvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == ctr_enabled)
	{
		if (GetConVarBool(ctr_enabled))
		{
			for (int i = 1; i <= MaxClients; i++)
			if (IsClientConnected(i) && !IsFakeClient(i))
				OnClientPutInServer(i);
		}
		else if (!GetConVarBool(ctr_enabled))
		{
			for (int i = 1; i <= MaxClients; i++)
			if (IsClientConnected(i) && !IsFakeClient(i))
				unmuteAll(i);
		}
	}
	
	if (convar == ctr_mute_unknown_country)
	{
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsFakeClient(i))
			OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	if (!GetConVarBool(ctr_enabled))
		return;
	
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		char g_szIP[16];
		GetClientIP(client, g_szIP, 60);
		GeoipCountry(g_szIP, g_szCountry[client], MAXPLAYERS + 1);
		checkOtherClients(client);
	}
}

void unmuteAll(int client)
{
	if (GetConVarBool(ctr_enabled))
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetListenOverride(client, i, Listen_Yes);
			SetListenOverride(i, client, Listen_Yes);
		}
	}
}

void checkOtherClients(int client)
{
	if (!GetConVarBool(ctr_enabled))
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (StrEqual(g_szCountry[client], "UNKNOWN") && GetConVarBool(ctr_mute_unknown_country))
			{
				SetListenOverride(client, i, Listen_Yes);
				SetListenOverride(i, client, Listen_Yes);
			} else if (!StrEqual(g_szCountry[client], "UNKNOWN") && GetConVarBool(ctr_mute_unknown_country))
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			} else if (StrEqual(g_szCountry[client], "UNKNOWN") && !GetConVarBool(ctr_mute_unknown_country))
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			} else if (StrEqual(g_szCountry[client], g_szCountry[i]))
			{
				SetListenOverride(client, i, Listen_Yes);
				SetListenOverride(i, client, Listen_Yes);
			} else if (!StrEqual(g_szCountry[client], g_szCountry[i]))
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			}
		}
	}
	return;
}
