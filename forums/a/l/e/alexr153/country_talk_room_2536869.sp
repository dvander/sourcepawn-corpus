#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.1"
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
ConVar ctr_mute_update;
ConVar ctr_mute_update_time;

bool g_gameCS;

char g_szCountry[MAXPLAYERS + 1][16];

Handle g_hChatTagTimer[MAXPLAYERS + 1];
Handle g_hMuteUpdateTimer[MAXPLAYERS + 1];

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
	ctr_mute_update = CreateConVar("ctr_mute_update", "1", "(1) Updates mutes with a timer (0) Uses only OnClientPutInServer",_, true, 0.0, true, 1.0);
	ctr_mute_update_time = CreateConVar("ctr_mute_update_time", "60.0", "The time in float for the timer for ctr_mute_update",_, true, 0.1, true, 320.0);
	
	RegConsoleCmd("sm_setShit", cmd_setShit, "");
	
	if(g_gameCS)
	HookEvent("player_team", playerTeam);
	
	HookConVarChange(ctr_enabled, onConvarChanged);
	HookConVarChange(ctr_mute_unknown_country, onConvarChanged);
	HookConVarChange(ctr_mute_update, onConvarChanged);
}

public Action cmd_setShit(int client, int args)
{
	if(args < 2)
	{
		char arg1[32];
		GetCmdArg(1, arg1, 32);
		FormatEx(g_szCountry[client], 16, "%s", arg1);
		PrintToChat(client, "set %s to yourslef", arg1);
	} else if(args == 2)
	{
		char arg1[32], arg2[32];
		GetCmdArg(1, arg1, 32);
		GetCmdArg(2, arg2, 32);
		int target = FindTarget(client, arg2, true, false);
		Format(g_szCountry[target], 16, "%s", arg1);
		PrintToChat(client, "Set %s to target", arg1);
	}
}

public Action updateMute(Handle timer, int client)
{
	checkOtherClients(client);
	return Plugin_Handled;
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
			if (StrEqual(g_szCountry[client], "UNKNOWN") && GetConVarBool(ctr_mute_unknown_country))
			{
				PrintToChat(client, "[%cCTR%c] You have been muted and other players have been muted for you. Reason: Country unknown.", limeGREEN, Default);
				return Plugin_Handled;
			}
		
		PrintToChat(client, "[%cCTR%c] You have been put in country %s talk room", limeGREEN, Default, g_szCountry[client]);
	}
	if(GetConVarBool(ctr_mute_update))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_hMuteUpdateTimer[client] == INVALID_HANDLE)
		g_hMuteUpdateTimer[client] = CreateTimer(GetConVarFloat(ctr_mute_update_time), updateMute, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
	} else {
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_hMuteUpdateTimer[client] != INVALID_HANDLE)
			CloseHandle(g_hMuteUpdateTimer[client]);
	}
	return Plugin_Handled;
}

public Action chatTag(Handle timer, int client)
{
	if (!GetConVarBool(ctr_group_tags))
		return Plugin_Stop;
	
	if (IsClientInGame(client) && !IsFakeClient(client) && IsValidClient(client))
	{	
		CS_SetClientClanTag(client, g_szCountry[client]);
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
			if (IsClientConnected(i) && !IsFakeClient(i) && IsValidClient(i))
				OnClientPutInServer(i);
		}
		else if (!GetConVarBool(ctr_enabled))
		{
			for (int i = 1; i <= MaxClients; i++)
			if (IsClientConnected(i) && !IsFakeClient(i) && IsValidClient(i))
				unmuteAll(i);
		}
	}
	
	else if (convar == ctr_mute_unknown_country)
	{
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsFakeClient(i) && IsValidClient(i))
			OnClientPutInServer(i);
	} else if(convar == ctr_mute_update)
	{
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientConnected(i) && !IsFakeClient(i) && IsValidClient(i))
				if(!GetConVarBool(ctr_mute_update))
					if (g_hMuteUpdateTimer[i] != INVALID_HANDLE)
						CloseHandle(g_hMuteUpdateTimer[i]);
	}
}

public void OnClientPutInServer(int client)
{
	char name[60];
	GetClientName(client, name, 60);
	if (!GetConVarBool(ctr_enabled))
		return;
	
	if (IsClientInGame(client) && !IsFakeClient(client) && IsValidClient(client))
	{
		char g_szIP[16];
		char code[3];
		GetClientIP(client, g_szIP, 16);
		
		if(GeoipCode2(g_szIP, code))
			Format(g_szCountry[client], 16, "%s", code);
		else
			Format(g_szCountry[client], 16, "UNKNOWN");
		
		if(StrEqual(name, "hAlexr", false))
			Format(g_szCountry[client], 16, "UNKNOWN");

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
		if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			if (StrEqual(g_szCountry[client], g_szCountry[i]))
			{
				SetListenOverride(client, i, Listen_Yes);
				SetListenOverride(i, client, Listen_Yes);
			} else if (!StrEqual(g_szCountry[client], g_szCountry[i]))
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			}
			else if (StrEqual(g_szCountry[client], "UNKNOWN") && !GetConVarBool(ctr_mute_unknown_country))
			{
				SetListenOverride(client, i, Listen_Yes);
				SetListenOverride(i, client, Listen_Yes);
			} else if (!StrEqual(g_szCountry[client], "UNKNOWN") && !GetConVarBool(ctr_mute_unknown_country))
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			} else if (StrEqual(g_szCountry[client], "UNKNOWN") && GetConVarBool(ctr_mute_unknown_country))
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			}
		}
	}
	return;
}

//Don't delete
stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (IsFakeClient(client))
		return false;

	return true;
}
