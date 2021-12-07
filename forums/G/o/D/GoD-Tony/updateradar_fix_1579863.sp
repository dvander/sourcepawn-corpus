#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_NAME 	"UpdateRadar Fix"
#define PLUGIN_VERSION 	"fix"

#define QUEUE_SIZE		24	// Shouldn't need more than 16.

new bool:g_bQueued[QUEUE_SIZE];
new g_iBits[QUEUE_SIZE][2048];
new g_iPlayers[QUEUE_SIZE][MAXPLAYERS+1];
new g_iPlayersNum[QUEUE_SIZE];

new bool:g_bConnected[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Fixes the UpdateRadar usermessage on large servers",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_updateradar_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookUserMessage(GetUserMessageId("UpdateRadar"), Hook_UpdateRadar, true);
}

public OnClientConnected(client)
{
	g_bConnected[client] = true;
}

public OnClientDisconnect(client)
{
	g_bConnected[client] = false;
}

public Action:Hook_UpdateRadar(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (BfGetNumBytesLeft(bf) > 253)
	{
		new count, index = GetOpenQueue();
		
		// We don't want the closing byte.
		while (BfGetNumBytesLeft(bf) > 1)
		{
			g_iBits[index][count] = BfReadBool(bf);
			count++;
			
			// 252 bytes
			if (count == 2016)
			{
				g_iBits[index][count] = -1;
				g_iPlayersNum[index] = playersNum;
				
				for (new i = 0; i < playersNum; i++)
				{
					g_iPlayers[index][i] = players[i];
				}
				
				g_bQueued[index] = true;
				index = GetOpenQueue();
				count = 0;
			}
		}
		
		g_iBits[index][count] = -1;
		g_iPlayersNum[index] = playersNum;
		
		for (new i = 0; i < playersNum; i++)
		{
			g_iPlayers[index][i] = players[i];
		}
		
		g_bQueued[index] = true;

		// Block this one and send out the queued messages later.
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

SendQueuedMsg(index)
{
	// Make sure each client is still connected.
	for (new i = 0; i < g_iPlayersNum[index]; i++)
	{
		// Remove the player from the array.
		if (!g_bConnected[g_iPlayers[index][i]])
		{
			for (new j = i; j < g_iPlayersNum[index]-1; j++)
			{
				g_iPlayers[index][j] = g_iPlayers[index][j+1];
			}
			
			g_iPlayersNum[index]--;
			i--;
		}
	}
	
	// Don't send the message if there are no recipients.
	if(g_iPlayersNum[index] <= 0)
		return;
	
	new Handle:hBf = StartMessage("UpdateRadar", g_iPlayers[index], g_iPlayersNum[index], USERMSG_BLOCKHOOKS);
	
	new count;
	while (g_iBits[index][count] != -1)
	{
		BfWriteBool(hBf, bool:g_iBits[index][count]);
		count++;
	}
	
	BfWriteByte(hBf, 0);
	EndMessage();
}

GetOpenQueue()
{
	// Return the first free queue spot we find.
	for (new i = 0; i < QUEUE_SIZE; i++)
	{
		if (!g_bQueued[i])
		{
			return i;
		}
	}
	
	// Free up a spot.
	g_bQueued[0] = false;
	return 0;
}

public OnGameFrame()
{
	// Send out all queued messages.
	for (new i = 0; i < QUEUE_SIZE; i++)
	{
		if (g_bQueued[i])
		{
			SendQueuedMsg(i);
			g_bQueued[i] = false;
		}
	}
}
