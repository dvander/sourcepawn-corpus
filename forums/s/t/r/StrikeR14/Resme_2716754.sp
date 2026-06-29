#pragma semicolon 1

#define PLUGIN_AUTHOR "Striker14"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required

bool allowed[MAXPLAYERS + 1];
bool roundRunning;

public Plugin myinfo = 
{
	name = "[TF2] Resme", 
	author = PLUGIN_AUTHOR, 
	description = "Made for darkboy245", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/kenmaskimmeod"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_resme", Cmd_Resme);
	
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_stalemate", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd);
}

public void OnClientPutInServer(int client)
{
	allowed[client] = true;
}

public Action Cmd_Resme(int client, int args)
{
	if (roundRunning)
	{
		if (allowed[client])
		{
			if (IsPlayerAlive(client))
			{
				PrintToChat(client, "[SM] You must be dead in order to use this command.");
				return Plugin_Handled;
			}
			
			if (args < 1)
			{
				PrintToChat(client, "[SM] Usage: sm_resme <1-8>");
				return Plugin_Handled;
			}
			
			char arg1[3];
			GetCmdArg(1, arg1, sizeof(arg1));
			
			int temp = StringToInt(arg1);
			int random = GetRandomInt(1, 8);
			
			
			if (temp < 1 || temp > 8)
			{
				PrintToChat(client, "[SM] Usage: sm_resme <1-8>");
				return Plugin_Handled;
			}
			
			if (temp == random)
			{
				TF2_RespawnPlayer(client);
				PrintToChatAll("[SM] %N has respawned using the resme command!", client);
			}
			else
			{
				PrintToChat(client, "[SM] You were wrong. The rolled number was %d, and you chose %d.", random, temp);
			}
			
			allowed[client] = false;
		}
		else
		{
			PrintToChat(client, "[SM] You have already used this command in this round.");
		}
	}
	else
	{
		PrintToChat(client, "[SM] Please wait for the round to start.");
	}
	
	return Plugin_Handled;
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	roundRunning = true;
	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	for (int g = 1; g <= MaxClients; g++)
	{
		if (IsClientInGame(g))
		{
			allowed[g] = true;
		}
	}
	
	roundRunning = false;
	return Plugin_Continue;
}

