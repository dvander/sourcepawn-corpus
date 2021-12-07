#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

// Change this flag to you need
#define DONATOR_FLAG ADMFLAG_CUSTOM1

new g_iJoinTime[MAXPLAYERS+2] = {0,...};
new g_iClientCount = 0;
new g_iClientsWithFlag = 0;

new Handle:g_hCVFirstAmount;

public Plugin:myinfo = 
{
	name = "First Connect Donators",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Gives the first x players a flag",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_firstjoin_version", PLUGIN_VERSION, "First Connect Donators", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVFirstAmount = CreateConVar("sm_firstjoin_amount", "4", "The first x players get the custom flag", FCVAR_PLUGIN, true, 0.0);
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
	{
		if(CheckCommandAccess(client, "z", ADMFLAG_ROOT))
		{
			//return 0;
		}
		else
		{
			g_iJoinTime[client] = GetTime();
			g_iClientCount++;
			CheckCustomFlags();
		}
	}
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		if(CheckCommandAccess(client, "z", ADMFLAG_ROOT))
		{
			//return 0;
		}
		else
		{
			g_iJoinTime[client] = 0;
			g_iClientCount--;
			g_iClientsWithFlag--;
			CheckCustomFlags();
		}
	}
}

CheckCustomFlags()
{
	new iFirstAmount = GetConVarInt(g_hCVFirstAmount);
	
	new AdminFlag:iDonatorFlag;
	BitToFlag(DONATOR_FLAG, iDonatorFlag);
	
	// Give all players the custom flag
	// if there less or equal players ingame, that should get the flag
	if(g_iClientCount <= iFirstAmount)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && (GetUserFlagBits(i) & DONATOR_FLAG) == 0)
			{
				AddUserFlags(i, iDonatorFlag);
				g_iClientsWithFlag++;
				PrintToChat(i, "You're one of the first %d players on this server. You've been given donator status.", iFirstAmount);
			}
		}
	}
	// If there are less than x players with the flag, but more players on the server
	// give the flag later on
	else if(g_iClientsWithFlag < iFirstAmount && g_iClientCount > g_iClientsWithFlag)
	{
		new iAddedGuy;
		while(g_iClientsWithFlag < iFirstAmount)
		{
			iAddedGuy = GetFirstJoinedWithoutFlag();
			// Failsafe?
			if(iAddedGuy == -1)
				break;
			
			AddUserFlags(iAddedGuy, iDonatorFlag);
			g_iClientsWithFlag++;
			PrintToChat(iAddedGuy, "One of the first joined left. You're the one who joined next, so you've been given donator status.");
		}
	}
}

GetFirstJoinedWithoutFlag()
{
	new iFirstJoin = 0, iFirstGuy = -1;
		
	// Get first joined guy, without the flag
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) 
		&& (GetUserFlagBits(i) & DONATOR_FLAG) == 0
		&& (iFirstJoin == 0 
		|| g_iJoinTime[i] < iFirstJoin))
		{
			iFirstJoin = g_iJoinTime[i];
			iFirstGuy = i;
		}
	}
	return iFirstGuy;
}