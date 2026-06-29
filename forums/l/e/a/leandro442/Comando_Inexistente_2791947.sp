#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	AddCommandListener(escrita, "say");
	AddCommandListener(escrita, "say_team");
	AddCommandListener(block, "status");
	AddCommandListener(block, "ping");
	AddCommandListener(block, "stats");
}

public Action escrita(int client, const char[] command, int args)
{
	if (IsValidClient(client))
	{
		char string[600], comando[600];
		GetCmdArgString(string, sizeof(string)); StripQuotes(string);
		strcopy(comando, sizeof(comando), string);
		
		int n = FindCharInString(string, '/');
		if (n != -1)
		{
			if (n == 0 || n == 1)
			{
				SplitString(string, " ", string, sizeof(string));
				ReplaceString(string, sizeof(string), "/", "sm_");
				if (CommandExists(string))
				{
					return Plugin_Continue;
				}
				else
				{
					CPrintToChat(client, "\x01[\x08 COMMAND \x01] The \x0F%s\x01 dont exist!", comando);
					return Plugin_Handled;
				}
			}
		}
		else
		{
			n = FindCharInString(string, '!');
			if (n != -1)
			{			
				if (n == 0 || n == 1)
				{
					SplitString(string, " ", string, sizeof(string));
					ReplaceString(string, sizeof(string), "!", "sm_");
					if (CommandExists(string))
					{
						return Plugin_Continue;
					}
					else
					{
						CPrintToChat(client, "\x01[\x08 COMMAND \x01] The \x0F%s\x01 dont exist!", comando);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action block(int client, const char[] command, int args)
{
	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool alive = false)
{
	if (0 < client && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) == false && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
} 