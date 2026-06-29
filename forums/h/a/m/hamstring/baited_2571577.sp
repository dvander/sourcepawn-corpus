#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hamstring"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <lastrequest>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "DG: Baited",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_baited", Command_Baited, ADMFLAG_GENERIC);
}

public Action Command_Baited(int client, int args)
{
		if (args < 1)
		{
			PrintToConsole(client, "Usage: sm_baited <name>");
			return Plugin_Handled;
		}

		char name[32];
		int target = -1;
		GetCmdArg(1, name, sizeof(name));
		
		for (int i = 1; i <= MaxClients; i++)
		{
				if (!IsClientConnected(i))
				{
					continue;
				}
				char other[32];
				GetClientName(i, other, sizeof(other));
				if (StrEqual(name, other))
				{
					target = i;
				}
		}
		
		if (target == -1)
		{
			PrintToConsole(client, "Could not find any player with that name: \"%s\"", name);
			return Plugin_Handled;
		}
		ServerCommand("disarm %d", GetClientUserId(target));
		ServerCommand("give %d", GetClientUserId(target));
		if (IsClientRebel(GetClientUserId(target)))
		{
			if (true) 
			{
				ChangeRebelStatus(GetClientUserId(target), false);
			}
		}
		PrintToChatAll("%N has been baited. Their gun has been removed and their rebel status has also been removed.", target);
		return Plugin_Handled;
}
