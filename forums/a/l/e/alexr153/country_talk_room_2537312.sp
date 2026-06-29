#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.3.2"
#define Default 0x01
#define limeGREEN 0x06
#define MAX_COUNTRIES 250

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
ConVar ctr_allow_hear_all;
ConVar ctr_multiple_countries;

bool g_gameCS;

char g_szCountry[MAXPLAYERS + 1][16];
bool g_bAllPlayers[MAXPLAYERS + 1];
bool g_bCountryOnly[MAXPLAYERS + 1];
bool g_bAllPlayersActivated[MAXPLAYERS + 1];

Handle g_hChatTagTimer[MAXPLAYERS + 1];
Handle g_hMuteUpdateTimer[MAXPLAYERS + 1];

char szKvFile[PLATFORM_MAX_PATH];
Handle g_hKV;

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
	ctr_mute_unknown_country = CreateConVar("ctr_mute_unknown_country", "0", "If player country is unknown it will (0) Makes own talk room for unknown countries (1) Mute everyone for client including client", _, true, 0.0, true, 1.0);
	if (g_gameCS)
		ctr_group_tags = CreateConVar("ctr_group_tags", "1", "(1) Sets players tag as country (0) Disables country tag", _, true, 0.0, true, 1.0);
	ctr_chat_message = CreateConVar("ctr_chat_message", "1", "(1) Shows a chat message for what country room you're in. (0) Disables the message", _, true, 0.0, true, 1.0);
	ctr_mute_update = CreateConVar("ctr_mute_update", "1", "(1) Updates mutes with a timer (0) Uses only OnClientPutInServer", _, true, 0.0, true, 1.0);
	ctr_mute_update_time = CreateConVar("ctr_mute_update_time", "60.0", "The time in float for the timer for ctr_mute_update (Seconds)", _, true, 60.0, true, 320.0);
	ctr_allow_hear_all = CreateConVar("ctr_allow_hear_all", "1", "(1) Lets players be able to hear every player or his own country. (0) players can only hear his own countries");
	ctr_multiple_countries = CreateConVar("ctr_multiple_countries", "1", "(1) Makes a .txt so multiple countries can hear each other (0) Disables multiple countries can hear each other");
	
	AutoExecConfig(true, "ctr_config");
	
	RegConsoleCmd("sm_ctr", cmd_ctr, "Allows players to listen to country or listen to all players");
	
	if (g_gameCS)
		HookEvent("player_team", playerTeam);
	
	HookConVarChange(ctr_enabled, onConvarChanged);
	HookConVarChange(ctr_mute_unknown_country, onConvarChanged);
	HookConVarChange(ctr_mute_update, onConvarChanged);
}

public Action cmd_ctr(int client, int args)
{
	buildMenu(client);
	return Plugin_Handled;
}

void buildMenu(int client)
{
	if (GetConVarBool(ctr_allow_hear_all))
	{
		Handle menu = CreateMenu(ctr_menu_callback);
		SetMenuTitle(menu, "Conutry talk room %s", g_szCountry[client]);
		if (g_bAllPlayers[client])
			AddMenuItem(menu, "arg1", "Hear players with this enabled (Active)", ITEMDRAW_DISABLED);
		else
			AddMenuItem(menu, "arg1", "Hear players with this enabled");
		
		if (g_bCountryOnly[client])
			AddMenuItem(menu, "arg2", "Hear only country (Active)", ITEMDRAW_DISABLED);
		else
			AddMenuItem(menu, "arg2", "Hear only country");
		
		if (g_bAllPlayersActivated[client])
			AddMenuItem(menu, "arg3", "Hear every player (Active)", ITEMDRAW_DISABLED);
		else
			AddMenuItem(menu, "arg3", "Hear every player");
		
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, 0);
	} else
	{
		PrintToChat(client, "[%cCTR%c] This server does not have this feature enabled", limeGREEN, Default);
	}
}

public int ctr_menu_callback(Handle menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[60];
			GetMenuItem(menu, param2, item, 60);
			
			if (StrEqual(item, "arg1"))
			{
				g_bAllPlayers[client] = true;
				g_bCountryOnly[client] = false;
				g_bAllPlayersActivated[client] = false;
				unmuteall(client);
			}
			else if (StrEqual(item, "arg2"))
			{
				g_bCountryOnly[client] = true;
				g_bAllPlayers[client] = false;
				g_bAllPlayersActivated[client] = false;
				OnClientPutInServer(client);
			}
			else if (StrEqual(item, "arg3"))
			{
				g_bAllPlayersActivated[client] = true;
				g_bAllPlayers[client] = false;
				g_bCountryOnly[client] = false;
				unmuteAllForClient(client);
			}
			buildMenu(client);
		}
	}
}

void unmuteall(int client)
{
	if (!GetConVarBool(ctr_enabled))
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && g_bAllPlayers[i])
		{
			SetListenOverride(client, i, Listen_Yes);
			SetListenOverride(i, client, Listen_Yes);
		}
	}
	if (GetConVarBool(ctr_chat_message))
	PrintToChat(client, "[%cCTR%c] You have joined all players talk room.", limeGREEN, Default);
}

void unmuteAllForClient(int client)
{
	if (!GetConVarBool(ctr_enabled))
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			SetListenOverride(client, i, Listen_Yes);
		}
	}
	if (GetConVarBool(ctr_chat_message))
	PrintToChat(client, "[%cCTR%c] You can now hear every player.", limeGREEN, Default);
}

public Action updateMute(Handle timer, int client)
{
	checkOtherClients(client);
	return Plugin_Handled;
}

public Action playerTeam(Handle event, char[] name, bool useless)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_hChatTagTimer[client] == INVALID_HANDLE && IsClientInGame(client))
		if (GetConVarBool(ctr_group_tags) && g_gameCS)
		g_hChatTagTimer[client] = CreateTimer(0.1, chatTag, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
	if (GetConVarBool(ctr_chat_message))
		if (StrEqual(g_szCountry[client], "UNKNOWN") && GetConVarBool(ctr_mute_unknown_country))
	{
		PrintToChat(client, "[%cCTR%c] You have been muted and other players have been muted for you. Reason: Country unknown.", limeGREEN, Default);
		return Plugin_Handled;
	}
	if (GetConVarBool(ctr_chat_message))
	PrintToChat(client, "[%cCTR%c] You have been put in country %s talk room", limeGREEN, Default, g_szCountry[client]);
	if (GetConVarBool(ctr_mute_update))
	{
		if (g_hMuteUpdateTimer[client] == INVALID_HANDLE)
			g_hMuteUpdateTimer[client] = CreateTimer(GetConVarFloat(ctr_mute_update_time), updateMute, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
	} else {
		if (g_hMuteUpdateTimer[client] != INVALID_HANDLE)
			CloseHandle(g_hMuteUpdateTimer[client]);
	}
	return Plugin_Handled;
}

public Action chatTag(Handle timer, int client)
{
	if (!GetConVarBool(ctr_group_tags))
		return Plugin_Stop;
	
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && IsValidClient(client))
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
	} else if (convar == ctr_mute_update)
	{
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsFakeClient(i) && IsValidClient(i))
			if (!GetConVarBool(ctr_mute_update))
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
		
		if (GeoipCode2(g_szIP, code))
			Format(g_szCountry[client], 16, "%s", code);
		else
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
		if(IsClientInGame(client) && IsClientInGame(client) && !IsFakeClient(client) && i != client && !g_bAllPlayers[client])
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && i != client && !g_bAllPlayers[i])
			{
				if (!GetConVarBool(ctr_multiple_countries))
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
				} else {
					BuildPath(Path_SM, szKvFile, sizeof(szKvFile), "configs/ctr_countries.txt");
					
					g_hKV = OpenFile(szKvFile, "r");
					
					if (g_hKV != INVALID_HANDLE)
					{
						multipleCountries(client, i);
						return;
					} else {
						PrintToServer("Couldn't find (configs/ctr_countries.txt)");
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
			}
		}
	}
	return;
}

void multipleCountries(int client, int target)
{
	while (!IsEndOfFile(g_hKV))
	{
		char line[60];
		char countriesHolder[MAX_COUNTRIES][32];
		ReadFileLine(g_hKV, line, 60);
		ExplodeString(line, "||", countriesHolder, sizeof(countriesHolder), sizeof(countriesHolder[]));
		
		if (StrEqual(countriesHolder[0], g_szCountry[client], false))
		{
			if (StrEqual(countriesHolder[0], g_szCountry[target], false))
			{
				SetListenOverride(client, target, Listen_Yes);
				SetListenOverride(target, client, Listen_Yes);
				return;
			} else {
				for (int i = 1; i <= MAX_COUNTRIES; i++)
				{
					if (!StrEqual(countriesHolder[i], "") || !StrEqual(countriesHolder[i], " "))
					{
						if (StrEqual(countriesHolder[i], g_szCountry[target], false))
						{
							SetListenOverride(client, target, Listen_Yes);
							SetListenOverride(target, client, Listen_Yes);
							return;
						} else {
							SetListenOverride(client, target, Listen_No);
							SetListenOverride(target, client, Listen_No);
						}
					} else {
						return;
					}
				}
			}
		}
	}
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
