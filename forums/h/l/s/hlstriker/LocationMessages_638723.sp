/*	=============================================
*	- NAME:
*	  + FF Location Messages
*
*	- DESCRIPTION:
*	  + This plugin will show messages on the location hud to all players with a typing effect.
*	  + You can add any message you want.
* 	
* 	
*	-------------
*	Server cvars:
*	-------------
*	- sv_ffmsgtime <seconds>
*	 + Set the number of seconds between each message.
*	
*	- sv_ffmsgholdtime <seconds>
*	 + Set the number of seconds to hold the message on the screen.
*	
* 	
*	---------------
*	Credits/Thanks:
*	---------------
*	- [Geokill]: Helped test the plugin until it was working.
* 	
* 	
*	----------
*	Changelog:
*	----------
*	Version 1.0 ( 06-13-2008 )
*	-- Initial release.
* 	
*	Version 2.0 ( 03-03-2009 )
*	-- Recoded a lot of the plugin, it now works proper on Linux machines.
*	-- Added a forward for the message locations so other plugins can hook it.
*	-- Fixed bugs throughout the plugin.
* 	
*/

#include <sourcemod>

#define VERSION "2.0"
public Plugin:myinfo = 
{
	name = "FF Location Messages",
	author = "hlstriker",
	description = "Shows messages on the location hud",
	version = VERSION,
	url = "None"
}

#define MAX_PLAYERS 22
new g_iMaxPlayers;

new g_iMessageNum;
new g_iOnTypeNum;
new String:g_szMessages[32][64];
new Handle:g_hMsgTimer = INVALID_HANDLE;

#define OUR_LOC_ID 728
new bool:g_bDisplayMessage;
new g_iPlayerLocColor[MAX_PLAYERS+1];
new String:g_szPlayerLocation[MAX_PLAYERS+1][42];

new Handle:g_hPlayerLocForward; // Used so other plugins can get loc message data
new Handle:g_hMsgTime = INVALID_HANDLE;
new Handle:g_hMsgHoldTime = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sv_locationmessages", VERSION, "Location Messages Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hPlayerLocForward = CreateGlobalForward("OnSetPlayerLocation", ET_Event, Param_Cell, Param_String, Param_Cell);
	HookUserMessage(UserMsg:28, MsgHook:msg_SetPlayerLocation, true);
	g_hMsgTime = CreateConVar("sv_ffmsgtime", "35.0", "Set the number of seconds between each message.", FCVAR_NOTIFY, true, 5.0);
	g_hMsgHoldTime = CreateConVar("sv_ffmsgholdtime", "3.0", "Set the number of seconds to hold the message on the screen.", FCVAR_NOTIFY);
}

public OnMapStart()
{
	g_iMaxPlayers = GetMaxClients();
	
	// Need to reset some variables
	for(new i=0; i<sizeof(g_szPlayerLocation); i++)
		strcopy(g_szPlayerLocation[i], sizeof(g_szPlayerLocation[])-1, "");
}

public OnMapEnd()
{
	if(g_hMsgTimer != INVALID_HANDLE)
	{
		KillTimer(g_hMsgTimer);
		g_hMsgTimer = INVALID_HANDLE;
	}
}

public OnConfigsExecuted()
{
	new String:szBuffer[128], i, Handle:hFile = INVALID_HANDLE;
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer)-1, "configs/ffmessagelist.ini");
	hFile = OpenFile(szBuffer, "r");
	if(hFile != INVALID_HANDLE)
	{
		while(!IsEndOfFile(hFile))
		{
			if(ReadFileLine(hFile, szBuffer, sizeof(szBuffer)))
			{
				if(szBuffer[0] == ';' || strlen(szBuffer) < 5)
					continue;
				
				TrimString(szBuffer);
				strcopy(g_szMessages[i], sizeof(g_szMessages[]), szBuffer);
				i++;
			}
		}
	}
	else
		LogMessage("You do not have ffmessagelist.ini");
	
	if(!StrEqual(g_szMessages[0], ""))
		g_hMsgTimer = CreateTimer(GetConVarFloat(g_hMsgTime), timer_SetPlayerLocation);
}

public Action:msg_SetPlayerLocation(UserMsg:msg_id, Handle:hBf, const iPlayers[], iPlayersNum, bool:bReliable, bool:bInit)
{
	if(!iPlayersNum)
		return Plugin_Continue;
	
	// Read location, color, and our argument
	static String:szBuffer[64], iColor, iOne;
	BfReadString(hBf, szBuffer, sizeof(szBuffer)-1);
	iColor = BfReadShort(hBf);
	iOne = BfReadShort(hBf);
	
	// Save players real location to variable
	static iClient;
	iClient = iPlayers[0];
	if(iOne != OUR_LOC_ID && IsClientInGame(iClient))
	{
		g_iPlayerLocColor[iClient] = iColor;
		strcopy(g_szPlayerLocation[iClient], sizeof(g_szPlayerLocation[])-1, szBuffer);
	}
	
	if(iOne != OUR_LOC_ID)
	{
		// Send forward so other plugins can hook it
		new Action:iResult;
		Call_StartForward(g_hPlayerLocForward);
		Call_PushCell(iClient);
		Call_PushString(szBuffer);
		Call_PushCell(iColor);
		Call_Finish(_:iResult);
		
		// Block locations while we are sending a message
		if(g_bDisplayMessage)
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:timer_SetPlayerLocation(Handle:hTimer)
{
	g_bDisplayMessage = true;
	
	new iStrLen = strlen(g_szMessages[g_iMessageNum]);
	new String:szBuffer[iStrLen+1], Handle:hBf;
	
	hBf = StartMessageAll("SetPlayerLocation");
	if(g_szMessages[g_iMessageNum][0] == '!')
	{
		static String:szSplit[2][sizeof(g_szMessages[])-2];
		if(g_szMessages[g_iMessageNum][1] == 'b')
		{
			ExplodeString(g_szMessages[g_iMessageNum], "!b", szSplit, sizeof(szSplit), sizeof(szSplit[]));
			FormatEx(szBuffer, g_iOnTypeNum, "%s", szSplit[1]);
			TrimString(szBuffer);
			BfWriteString(hBf, szBuffer);
			BfWriteShort(hBf, 2);
		}
		else if(g_szMessages[g_iMessageNum][1] == 'r')
		{
			ExplodeString(g_szMessages[g_iMessageNum], "!r", szSplit, sizeof(szSplit), sizeof(szSplit[]));
			FormatEx(szBuffer, g_iOnTypeNum, "%s", szSplit[1]);
			TrimString(szBuffer);
			BfWriteString(hBf, szBuffer);
			BfWriteShort(hBf, 3);
		}
		else if(g_szMessages[g_iMessageNum][1] == 'y')
		{
			ExplodeString(g_szMessages[g_iMessageNum], "!y", szSplit, sizeof(szSplit), sizeof(szSplit[]));
			FormatEx(szBuffer, g_iOnTypeNum, "%s", szSplit[1]);
			TrimString(szBuffer);
			BfWriteString(hBf, szBuffer);
			BfWriteShort(hBf, 4);
		}
		else if(g_szMessages[g_iMessageNum][1] == 'g')
		{
			ExplodeString(g_szMessages[g_iMessageNum], "!g", szSplit, sizeof(szSplit), sizeof(szSplit[]));
			FormatEx(szBuffer, g_iOnTypeNum, "%s", szSplit[1]);
			TrimString(szBuffer);
			BfWriteString(hBf, szBuffer);
			BfWriteShort(hBf, 5);
		}
		else
		{
			FormatEx(szBuffer, g_iOnTypeNum, "%s", g_szMessages[g_iMessageNum]);
			TrimString(szBuffer);
			BfWriteString(hBf, szBuffer);
			BfWriteShort(hBf, 0);
		}
	}
	else
	{
		FormatEx(szBuffer, g_iOnTypeNum, "%s", g_szMessages[g_iMessageNum]);
		TrimString(szBuffer);
		BfWriteString(hBf, szBuffer);
		BfWriteShort(hBf, 0);
	}
	BfWriteShort(hBf, OUR_LOC_ID);
	EndMessage();
	
	if(g_iOnTypeNum <= iStrLen)
	{
		g_iOnTypeNum += 1;
		g_hMsgTimer = CreateTimer(0.12, timer_SetPlayerLocation);
	}
	else
	{
		if(g_szMessages[g_iMessageNum+1][0] != 0)
			g_iMessageNum += 1;
		else
			g_iMessageNum = 0;
		g_iOnTypeNum = 0;
		g_hMsgTimer = CreateTimer(GetConVarFloat(g_hMsgHoldTime), timer_MessageEnd);
	}
	
	return Plugin_Continue;
}

public Action:timer_MessageEnd(Handle:hTimer)
{
	g_bDisplayMessage = false;
	
	// Set each players location back to the maps location
	new Handle:hBf;
	for(new i=1; i<=g_iMaxPlayers; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			hBf = StartMessageOne("SetPlayerLocation", i);
			BfWriteString(hBf, g_szPlayerLocation[i]);
			BfWriteShort(hBf, g_iPlayerLocColor[i]);
			EndMessage();
		}
	}
	
	g_hMsgTimer = CreateTimer(GetConVarFloat(g_hMsgTime), timer_SetPlayerLocation);
}