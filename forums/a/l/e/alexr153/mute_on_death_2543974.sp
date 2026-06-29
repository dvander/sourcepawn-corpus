#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

ConVar vc_enable;
ConVar vc_time;
ConVar vc_chat;

bool playerMuted[MAXPLAYERS + 1];

public Plugin myinfo =  {
	name = "[Voice controller] Mute dead players time", 
	author = "hAlexr", 
	description = "Adds so when player dieswill set a timer to mute him/herself from alive players", 
	version = "1.0.0", 
	url = "www.crypto-gaming.tk"
};

public void OnPluginStart()
{
	LoadTranslations("mute_on_death.phrases");
	
	vc_enable = CreateConVar("vc_enable", "1", "Enables or disables the plugin", _, true, 0.0, true, 1.0);
	vc_time = CreateConVar("vc_time", "10.0", "Time until player is muted", _, true, 0.1, true, 20.0);
	vc_chat = CreateConVar("vc_chat", "1", "Enable or disable chat messages", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "plugin.MuteDeadPlayers");
	
	HookEvent("player_death", playerDeath);
	HookEvent("player_spawn", playerSpawn);
	HookEvent("player_team", playerTeam);
	HookEvent("round_end", roundEnd);
}

public Action playerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(vc_enable))
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(GetConVarFloat(vc_time), muteTimer, client);
}

public Action playerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int clientTeam = GetClientTeam(client);
	checkMutes(client, clientTeam, 0);
}

public Action playerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int clientTeam = GetClientTeam(client);
	checkMutes(client, clientTeam, 1);
}

public void checkMutes(int client, int clientTeam, int mode)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if(mode == 1)
			{
				int iTeam = GetClientTeam(i);
				if (iTeam == clientTeam)
				{
						SetListenOverride(i, client, Listen_Yes);
						SetListenOverride(client, i, Listen_Yes);
				} else {
						SetListenOverride(i, client, Listen_No);
						SetListenOverride(client, i, Listen_No);
				}
			} else if (mode == 0)
			{
				SetListenOverride(i, client, Listen_No);
				SetListenOverride(client, i, Listen_No);
				int iTeam = GetClientTeam(i);
				if (iTeam == clientTeam)
				{
					if(!IsPlayerAlive(client))
					{
						if(!IsPlayerAlive(i))
						{
							SetListenOverride(i, client, Listen_Yes);
							SetListenOverride(client, i, Listen_Yes);
						} 
						if(IsPlayerAlive(i))
						{
							SetListenOverride(i, client, Listen_No);
							SetListenOverride(client, i, Listen_No);
						}
					} else {
						if(IsPlayerAlive(i))
						{
							SetListenOverride(i, client, Listen_Yes);
							SetListenOverride(client, i, Listen_Yes);
						} 
						if(!IsPlayerAlive(i))
						{
							SetListenOverride(i, client, Listen_No);
							SetListenOverride(client, i, Listen_No);
						}
					}
				} else {
					SetListenOverride(i, client, Listen_No);
					SetListenOverride(client, i, Listen_No);
				}
			}
		}
	}
}

public Action muteTimer(Handle timer, int client)
{
	if (!GetConVarBool(vc_enable))
		return;
	
	mutePlayer(client);
}

void mutePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && i != client && !IsPlayerAlive(client))
		{
			int clientTeam = GetClientTeam(client);
			
			if (IsClientConnected(i) && IsClientInGame(i) && i != client && IsPlayerAlive(i))
			{
				int iTeam = GetClientTeam(i);
				
				if (clientTeam == iTeam)
				{
					if(playerMuted[client] == false)
					{
						SetListenOverride(i, client, Listen_No);
						if(GetConVarBool(vc_chat) && !playerMuted[client])
						PrintToChat(client, "[\x06VC\x01] \x07 %t", "deadCantTalk");
						playerMuted[client] = true;
					}
				}
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	playerMuted[client] = false;
}

public Action roundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			int clientTeam = GetClientTeam(i);
			unmuteClients(i, clientTeam);
		}
	}
}

public void unmuteClients(int client, int clientTeam)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			int iTeam = GetClientTeam(i);
			if (iTeam == clientTeam)
			{
				if(playerMuted[client] == true)
				{
					SetListenOverride(i, client, Listen_Yes);
					SetListenOverride(client, i, Listen_Yes);
					if (GetConVarBool(vc_chat) && playerMuted[client])
					PrintToChat(client, "[\x06VC\x01] \x05 %t", "deadCanTalk");
					playerMuted[client] = false;
				}
			}
		}
	}
}
