#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


// We must wait longer because of cases where the game doesn't 
// do the compare at the same time as us.
#define SAFETY_BUFFER_TIME 1.0

new Float:g_flDefaultLossTime;
new bool:g_bInScavengeRound;
new bool:g_bInSecondHalf;

// GetRoundTime(&minutes, &seconds, team)
#define GetRoundTime(%0,%1,%2) %1 = GameRules_GetRoundDuration(%2);	%0 = RoundToFloor(%1)/60; %1 -= 60 * %0

#define boolalpha(%0) (%0 ? "true" : "false")

public Plugin:myinfo = 
{
	name = "Scavenge Quick End",
	author = "ProdigySim",
	description = "Checks various tiebreaker win conditions mid-round and ends the round as necessary.",
	version = "1.2",
	url = "http://bitbucket.org/ProdigySim/misc-sourcemod-plugins/"
}

public OnPluginStart()
{
	HookEvent("gascan_pour_completed", EventHook:OnCanPoured, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", EventHook:RoundStart);
	HookEvent("round_end", EventHook:RoundEnd, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_time", TimeCmd);
}

public Action:TimeCmd(client,args)
{
	if(!g_bInScavengeRound) return Plugin_Handled;
	
	if(g_bInSecondHalf)
	{
		new Float:lastRoundTime;
		new lastRoundMinutes;
		GetRoundTime(lastRoundMinutes,lastRoundTime,3);
		
		PrintToChat(client, "Last Round: %d in %d:%05.2f", GameRules_GetScavengeTeamScore(3), lastRoundMinutes, lastRoundTime);
	}
	
	new Float:thisRoundTime;
	new thisRoundMinutes;
	GetRoundTime(thisRoundMinutes,thisRoundTime,2);
	PrintToChat(client, "This Round: %d in %d:%05.2f", GameRules_GetScavengeTeamScore(2), thisRoundMinutes, thisRoundTime);
	
	return Plugin_Handled;
}

public OnGameFrame()
{
	if(g_flDefaultLossTime != 0.0 && GetGameTime() > g_flDefaultLossTime)
	{
		EndRoundEarlyOnTime();
		g_flDefaultLossTime=0.0;
	}
}

public RoundEnd()
{
	if(g_bInScavengeRound) PrintRoundEndTimeData(g_bInSecondHalf);
	
	g_flDefaultLossTime=0.0;	
	g_bInScavengeRound=false;
	g_bInSecondHalf=false;
}

public RoundStart(Handle:event)
{
	g_bInSecondHalf = !GetEventBool(event, "firsthalf");
	g_bInScavengeRound=true;
	g_flDefaultLossTime = 0.0;
	if(g_bInScavengeRound && g_bInSecondHalf)
	{
		new lastRoundScore = GameRules_GetScavengeTeamScore(3);
		if(lastRoundScore == 0 || lastRoundScore == GameRules_GetProp("m_nScavengeItemsGoal"))
		{
			g_flDefaultLossTime = GameRules_GetPropFloat("m_flRoundStartTime") + GameRules_GetRoundDuration(3) + SAFETY_BUFFER_TIME;
		}
	}
}

public OnCanPoured()
{
	if(g_bInScavengeRound && g_bInSecondHalf)
	{
		new remaining = GameRules_GetProp("m_nScavengeItemsRemaining");
		if(remaining > 0)
		{
			new scoreA = GameRules_GetScavengeTeamScore(2);
			new scoreB = GameRules_GetScavengeTeamScore(3);
			if(scoreA == scoreB && GameRules_GetRoundDuration(2) < GameRules_GetRoundDuration(3))
			{
				EndRoundEarlyOnTime();
			}
		}
	}
}

PrintRoundEndTimeData(bool:secondHalf)
{
	decl Float:time;
	decl minutes;
	if(secondHalf)
	{
		GetRoundTime(minutes,time,3);
		PrintToChatAll("Last Round: %d in %d:%05.2f", GameRules_GetScavengeTeamScore(3), minutes, time);
	}

	GetRoundTime(minutes,time,2);
	PrintToChatAll("This Round: %d in %d:%05.2f.", GameRules_GetScavengeTeamScore(2), minutes, time);
}

EndRoundEarlyOnTime()
{
	new oldFlags = GetCommandFlags("scenario_end");
	// FCVAR_LAUNCHER is actually FCVAR_DEVONLY`
	SetCommandFlags("scenario_end", oldFlags & ~(FCVAR_CHEAT|FCVAR_LAUNCHER));
	ServerCommand("scenario_end");
	ServerExecute();
	SetCommandFlags("scenario_end", oldFlags);
	PrintToChatAll("Round Ended Early: Win condition decided on time.");
}

stock Float:GameRules_GetRoundDuration(team)
{
	new Float:flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");
	if(team == 2 && flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
	{
		// Survivor team still playing round.
		return GetGameTime()-flRoundStartTime;
	}
	team = L4D2_TeamNumberToTeamIndex(team);
	if(team == -1) return -1.0;
	
	return GameRules_GetPropFloat("m_flRoundDuration", team);
}

stock GameRules_GetScavengeTeamScore(team, round=-1)
{
	team = L4D2_TeamNumberToTeamIndex(team);
	if(team == -1) return -1;
	
	if(round <= 0 || round > 5)
	{
		round = GameRules_GetProp("m_nRoundNumber");
	}
	--round;
	return GameRules_GetProp("m_iScavengeTeamScore", _, (2*round)+team);
}

// convert "2" or "3" to "0" or "1" for global static indices
stock L4D2_TeamNumberToTeamIndex(team)
{
	// must be team 2 or 3 for this stupid function
	if(team != 2 && team != 3) return -1;

	// Tooth table:
	// Team | Flipped | Correct index
	// 2	   0		 0
	// 2	   1		 1
	// 3	   0		 1
	// 3	   1		 0
	// index = (team & 1) ^ flipped
	// index = team-2 XOR flipped, or team%2 XOR flipped, or this...	
	new bool:flipped = bool:GameRules_GetProp("m_bAreTeamsFlipped", 1);
	if(flipped) ++team;
	return team % 2;
}