/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Rock The Vote Plugin
 * Creates a map vote when the required number of players have requested one.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <mapchooser>
#include <nextmap>
#include <mapvote> // $ added

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Rock The Vote - mapvote admin",
	author = "AlliedModders LLC",
	description = "Provides RTV Map Voting",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_Cvar_Needed = INVALID_HANDLE;
new Handle:g_Cvar_MinPlayers = INVALID_HANDLE;
new Handle:g_Cvar_InitialDelay = INVALID_HANDLE;
new Handle:g_Cvar_Interval = INVALID_HANDLE;
new Handle:g_Cvar_ChangeTime = INVALID_HANDLE;
new Handle:g_Cvar_RTVPostVoteAction = INVALID_HANDLE;

new bool:g_CanRTV = false;		// True if RTV loaded maps and is active.
new bool:g_RTVAllowed = false;	// True if RTV is available to players. Used to delay rtv votes.
new g_Voters = 0;				// Total voters connected. Doesn't include fake clients.
new g_Votes = 0;				// Total number of "say rtv" votes
new g_VotesNeeded = 0;			// Necessary votes before map vote begins. (voters * percent_needed)
new g_AdminCount = 0;
new g_CurrentVotes = 0;
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};

new bool:g_InChange = false;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("rockthevote.phrases");
	
	g_Cvar_Needed = CreateConVar("sm_rtv_needed", "0.60", "Percentage of players needed to rockthevote (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtv_minplayers", "0", "Number of players required before RTV will be enabled.", 0, true, 0.0, true, float(MAXPLAYERS));
	g_Cvar_InitialDelay = CreateConVar("sm_rtv_initialdelay", "30.0", "Time (in seconds) before first RTV can be held", 0, true, 0.00);
	g_Cvar_Interval = CreateConVar("sm_rtv_interval", "240.0", "Time (in seconds) after a failed RTV before another can be held", 0, true, 0.00);
	g_Cvar_ChangeTime = CreateConVar("sm_rtv_changetime", "0", "When to change the map after a succesful RTV: 0 - Instant, 1 - RoundEnd, 2 - MapEnd", _, true, 0.0, true, 2.0);
	g_Cvar_RTVPostVoteAction = CreateConVar("sm_rtv_postvoteaction", "0", "What to do with RTV's after a mapvote has completed. 0 - Allow, success = instant change, 1 - Deny", _, true, 0.0, true, 1.0);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("sm_rtv", Command_RTV);
	
	AutoExecConfig(true, "rtv");
}

public OnMapStart()
{
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_AdminCount = 0;
	g_CurrentVotes = 0;
	g_InChange = false;
	
	/* Handle late load */
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientPostAdminCheck(i);	
		}	
	}
}

public OnMapEnd()
{
	g_CanRTV = false;	
	g_RTVAllowed = false;
}

public OnConfigsExecuted()
{	
	g_CanRTV = true;
	g_RTVAllowed = false;
	CreateTimer(GetConVarFloat(g_Cvar_InitialDelay), Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client))
		return;
	
	new flags = GetUserFlagBits(client);
	
	g_Voters++;
	
	//LogMessage("[SM] Client connected, Total Admins %i", g_AdminCount);
	
	//if (GetUserFlagBits(client) & ADMFLAG_RESERVATION)
	if (flags & ADMFLAG_ROOT || flags & ADMFLAG_GENERIC || flags & ADMFLAG_RESERVATION)
	{
		if (!g_AdminCount)
		{
			g_CurrentVotes = g_Votes;
			g_Votes = 0;
		}
		g_AdminCount++;
		g_VotesNeeded = RoundToFloor(float(g_AdminCount) * GetConVarFloat(g_Cvar_Needed));
		//PrintToChatAll("[SM] Admin connected, Total Admins %i", g_AdminCount);
		//LogMessage("[SM] Admin connected, Total Admins %i", g_AdminCount);
	}
	
	if (!g_AdminCount)
	{
		g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
		//PrintToChatAll("[SM] Non-admin connected, Total Admins %i", g_AdminCount);
		//LogMessage("[SM] Non-admin connected, Total Admins %i", g_AdminCount);
	}
	
	g_Voted[client] = false;
	
	return;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client] && !g_AdminCount)
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	new flags = GetUserFlagBits(client);
	
	if (flags & ADMFLAG_ROOT || flags & ADMFLAG_GENERIC || flags & ADMFLAG_RESERVATION)
	{
		g_AdminCount--;
		if (g_Voted[client])
		{
			g_Votes--;
		}
		g_VotesNeeded = RoundToFloor(float(g_AdminCount) * GetConVarFloat(g_Cvar_Needed));
		if (!g_AdminCount)
		{
			g_Votes = g_CurrentVotes;
		}
	}
	else if (g_AdminCount)
	{
		g_CurrentVotes--;
	}
	
	if (!g_AdminCount)
	{
		g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
	}
	
	if (!g_CanRTV)
	{
		return;	
	}
	
	if (g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded && 
		g_RTVAllowed ) 
	{
		if (GetConVarInt(g_Cvar_RTVPostVoteAction) == 1 && HasEndOfMapVoteFinished())
		{
			return;
		}
		
		StartRTV();
	}	
}

public Action:Command_RTV(client, args)
{
	if (!g_CanRTV || !client)
	{
		return Plugin_Continue;
	}
	
	AttemptRTV(client);
	
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	if (!g_CanRTV || !client)
	{
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "rtv", false) == 0 || strcmp(text[startidx], "rockthevote", false) == 0)
	{
		AttemptRTV(client);
	}
	
	if (strcmp(text[startidx], "adminrtv", false) == 0)
	{
		ReportAdmins();
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

AttemptRTV(client)
{
	if (!g_RTVAllowed  || (GetConVarInt(g_Cvar_RTVPostVoteAction) == 1 && HasEndOfMapVoteFinished()))
	{
		ReplyToCommand(client, "[SM] %t", "RTV Not Allowed");
		return;
	}
	
	new flags = GetUserFlagBits(client);
	
	if (!(flags & ADMFLAG_ROOT || flags & ADMFLAG_GENERIC || flags & ADMFLAG_RESERVATION) && g_AdminCount)
	{
		ReplyToCommand(client, "[SM] %t", "RTV Not Allowed");
		return;
	}
	
		
	if (!CanMapChooserStartVote())
	{
		ReplyToCommand(client, "[SM] %t", "RTV Started");
		return;
	}
	
	if (GetClientCount(true) < GetConVarInt(g_Cvar_MinPlayers))
	{
		ReplyToCommand(client, "[SM] %t", "Minimal Players Not Met");
		return;			
	}
	
	if (g_Voted[client])
	{
		ReplyToCommand(client, "[SM] %t", "Already Voted");
		return;
	}	
	
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	g_Votes++;
	g_Voted[client] = true;
	
	PrintToChatAll("[SM] %t", "RTV Requested", name, g_Votes, g_VotesNeeded);
	
	if (g_Votes >= g_VotesNeeded)
	{
		StartRTV();
	}	
}

ReportAdmins()
{
	//g_AdminCount++;
	PrintToChatAll("[SM] Total Admins %i", g_AdminCount);
	LogMessage("[SM] Total Admins %i", g_AdminCount);
	return;
}

public Action:Timer_DelayRTV(Handle:timer)
{
	g_RTVAllowed = true;
}

StartRTV()
{
	if (g_InChange)
	{
		return;	
	}
	
	if (EndOfMapVoteEnabled() && HasEndOfMapVoteFinished())
	{
		/* Change right now then */
		new String:map[65];
		if (GetNextMap(map, sizeof(map)))
		{
			PrintToChatAll("[SM] %t", "Changing Maps", map);
			CreateTimer(5.0, Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
			g_InChange = true;
			
			ResetRTV();
			
			g_RTVAllowed = false;
		}
		return;	
	}
	
	if (CanMapChooserStartVote())
	{
		new MapChange:when = MapChange:GetConVarInt(g_Cvar_ChangeTime);
		InitiateMapVote(when); // $ changed
		
		ResetRTV();
		
		g_RTVAllowed = false;
		CreateTimer(GetConVarFloat(g_Cvar_Interval), Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

ResetRTV()
{
	g_Votes = 0;
			
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}

public Action:Timer_ChangeMap(Handle:hTimer)
{
	g_InChange = false;
	
	LogMessage("RTV changing map manually");
	
	new String:map[65];
	if (GetNextMap(map, sizeof(map)))
	{	
		ForceChangeLevel(map, "RTV after mapvote");
	}
	
	return Plugin_Stop;
}