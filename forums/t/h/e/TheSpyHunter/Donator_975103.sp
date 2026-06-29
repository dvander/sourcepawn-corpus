#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <adminmenu>
	
/* defines */
#define PLUGIN_VERSION "0.1"
//#define DEBUG "1"
#define NULLNAME "$$NULL##"
#define cvDonatorVIP      16000
#define display  "Thank you for donating, Please enjoy your Privileges"

public Plugin:myinfo = 
{
	name = "Donator Cash",
	author = "TSH",
	description = "Give cash to Donator",
	version = PLUGIN_VERSION,
	url = "http://www.ultimatefragforce.co.uk"
}

public OnPluginStart()
{
	HookEvent("round_end", eVIPCash, EventHookMode_PostNoCopy);
}


public Action:Command_UFFS(client)
{
ServerCommand("sm_cash \"%N\" 16000", client);
}

public eVIPCash(Handle:event, const String:name[], bool:dontBroadcast)
{
	new maxClients = GetMaxClients();
	for (new i = 1; i <= maxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i))
		{
			new adminflags = GetUserFlagBits(i);
			if(adminflags != 0 && adminflags & ADMFLAG_CUSTOM2)
			{
				Command_UFFS(i);
				PrintCenterText(i,display);
			}
		}
	}
}

