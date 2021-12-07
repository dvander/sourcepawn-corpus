#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.6"

public Plugin:myinfo = 
{
	name = "Server status",
	author = "GachL",
	description = "Shows a more advanced view of the 'status' command.",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

public OnPluginStart()
{
	CreateConVar("sm_status_version", PLUGIN_VERSION, "Server status version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_status", Command_Status);
	RegConsoleCmd("sm_status_full", Command_Status_Full);
	RegConsoleCmd("sm_status_player", Command_Status_Player);
}

public Action:Command_Status_Full(client, args)
{
	Command_Status(client, args);
	PrintToConsole(client, "\nUsers:\n=========================================\n");
	new iPlayersOnline = GetClientCount();
	for (new i = 1; i <= iPlayersOnline; i++)
	{
		ClientInfo(client, i);
	}
	return Plugin_Handled;
}

public Action:Command_Status_Player(client, args)
{
	if (args == 0)
	{
		PrintToConsole(client, "Usage: sm_status_player <playername>");
		return Plugin_Handled;
	}
	
	new String:sPlayer[64], String:sTargetName[MAX_TARGET_LENGTH];
	GetCmdArg(1, sPlayer, sizeof(sPlayer));
	
	new bool:bTnMl;
		
	new iTargetList[MAXPLAYERS], iTargetCount;
	if ((iTargetCount = ProcessTargetString(
						sPlayer,
						client,
						iTargetList,
						MAXPLAYERS,
						COMMAND_FILTER_CONNECTED,
						sTargetName,
						sizeof(sTargetName),
						bTnMl)) <= 0)
	{
		PrintToConsole(client, "Player(s) not found.");
		return Plugin_Handled;
	}
	
	for (new i = 0; i < iTargetCount; i++)
	{
		ClientInfo(client, iTargetList[i]);
	}
	
	return Plugin_Handled;
}

public Action:Command_Status(client, args)
{
	// Hostname
	new Handle:cvHostname = FindConVar("hostname");
	new String:sHostname[64];
	GetConVarString(cvHostname, sHostname, sizeof(sHostname));
	
	// Cur. Players
	new iPlayersOnline = GetClientCount();
	new iPlayersConnecting = GetClientCount(false);
	iPlayersConnecting -= iPlayersOnline;
	new iFreeSlots = MaxClients - iPlayersOnline - iPlayersConnecting;
	
	// Cur. Map
	new String:sCurrentMap[64];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	
	// Nextmap
	new Handle:cvNextmap = FindConVar("sm_nextmap");
	new String:sNextmap[64];
	GetConVarString(cvNextmap, sNextmap, sizeof(sNextmap));
	
	// Total players
	new iTotalPlayers = 0;
	for (new i = 1; i <= iPlayersOnline; i++)
	{
		if (IsClientConnected(i))
		{
			new iTPTemp = GetClientUserId(i);
			if (iTPTemp > iTotalPlayers)
			{
				iTotalPlayers = iTPTemp;
			}
		}
	}
	
	// Print server specific values
	PrintToConsole(client, "Hostname:\t%s", sHostname);
	PrintToConsole(client, "Maxplayer:\t%d", MaxClients);
	PrintToConsole(client, "Curplayer:\t%d", iPlayersOnline);
	PrintToConsole(client, "Connecting:\t%d", iPlayersConnecting);
	PrintToConsole(client, "FreeSlots:\t%d", iFreeSlots);
	PrintToConsole(client, "CurrentMap:\t%s", sCurrentMap);
	PrintToConsole(client, "NextMap:\t%s", sNextmap);
	if (iTotalPlayers == 0)
	{
		PrintToConsole(client, "TotalPlrs:\tUnknown");
	}
	else
	{
		PrintToConsole(client, "TotalPlrs:\t%d", iTotalPlayers);
	}
	
	return Plugin_Handled;
}

stock ClientInfo(sender, client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (IsFakeClient(client)) // Sourcemod is a little bit stupid ^__^'
		{
			PrintToConsole(sender, "BOT");
			return;
		}
		new iClientUserId = GetClientUserId(client);
		new String:sClientName[64];
		GetClientName(client, sClientName, sizeof(sClientName));
		new String:sClientSteamId[64]
		GetClientAuthString(client, sClientSteamId, sizeof(sClientSteamId));
		new Float:fOnTime = GetClientTime(client);
		new Float:iAvgLat = GetClientAvgLatency(client, NetFlow_Both);
		new Float:iCurLat = GetClientLatency(client, NetFlow_Both);
		new iClientTeam = GetClientTeam(client);
		new String:sClientIP[64];
		GetClientIP(client, sClientIP, sizeof(sClientIP));
		new String:sClientPort[64], String:linebuf[2][32];
		GetClientIP(client, sClientPort, sizeof(sClientPort), false);
		ExplodeString(sClientPort, ":", linebuf, 2, 32);
		sClientPort = linebuf[1];
		new String:sTeamName[64];
		GetTeamName(iClientTeam, sTeamName, sizeof(sTeamName));
		
		PrintToConsole(sender, "%s\n\tHandle:\t%d\n\tUID:\t%d\n\tSteam:\t%s\n\tOnTime:\t%f seconds\n\tAvgLat:\t%f\n\tCurLat:\t%f\n\tTeam:\t%s\n\tIP:\t%s\n\tPort:\t%s\n",
			sClientName,
			client,
			iClientUserId,
			sClientSteamId,
			RoundToZero(fOnTime),
			RoundToZero(iAvgLat*1000),
			RoundToZero(iCurLat*1000),
			sTeamName,
			sClientIP,
			sClientPort);
	}
	else 
	{
		PrintToConsole(sender, "%s\n\t%s\n", "Unknown", "Not available");
	}
}