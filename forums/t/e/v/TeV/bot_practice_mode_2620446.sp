#include <sourcemod>
#include <sdktools_functions>
#include <cstrike>
#include <timers>
#include <convars>

#pragma semicolon 1
#pragma newdecls required
#define CLAMP(%0,%1,%2) (((%0) > (%2)) ? (%2) : (((%0) < (%1)) ? (%1) : (%0)))

ConVar cvarMaxBots;

ConVar cvarBotQuota;
ConVar cvarBotDifficulty;
ConVar cvarAutoteambalance;
ConVar cvarLimitteams;

Handle hOnTeamsChanged;
bool bBotModeEnabled;
int iBotModeTeam;
int iRoundLossBalance;
int iCachedAutoTeamBalance;
int iCachedLimitTeams;

public Plugin myinfo = 
{
	name = "Bot Practice Mode",
	author = "TeV",
	description = "Lets players interactively train against bots if there are not enough players on both teams.",
	version = "1.0"
};

public void OnPluginStart()
{
	cvarMaxBots = CreateConVar("bot_practice_max_bots", "30", "Sets the maximum number of bots that the bot practice plugin is allowed to spawn.");
	
	cvarBotQuota = FindConVar("bot_quota");
	cvarBotDifficulty = FindConVar("bot_difficulty");
	cvarAutoteambalance = FindConVar("mp_autoteambalance");
	cvarLimitteams = FindConVar("mp_limitteams");
	
	HookEvent("player_team", EventPlayerTeam);
	HookEvent("player_disconnect", EventPlayerDisconnect);
	HookEvent("round_end", EventRoundEnd);
}

public Action EventPlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	CreateOnTeamsChangedTimer();
}

public Action EventPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{
	CreateOnTeamsChangedTimer();
}

public Action EventRoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	int winningTeam = GetEventInt(event, "winner");
	OnRoundEnded(winningTeam);
}

public void CreateOnTeamsChangedTimer()
{
	if (hOnTeamsChanged != null)
	{
		KillTimer(hOnTeamsChanged);
		hOnTeamsChanged = null;
	}
	
	hOnTeamsChanged = CreateTimer(0.1, OnTeamsChanged);
}

public Action OnTeamsChanged(Handle timer)
{
	hOnTeamsChanged = null;
	
	int iClientCountT = GetTeamClientCount(2);
	int iClientCountCT = GetTeamClientCount(3);
	int iBotCountT = 0;
	int iBotCountCT = 0;
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientConnected(i))
			continue;
		
		if (IsFakeClient(i))
		{
			int iClientTeam = GetClientTeam(i);
			if (iClientTeam == CS_TEAM_T)
				iBotCountT++;
			else if (iClientTeam == CS_TEAM_CT)
				iBotCountCT++;
		}
	}
	
	int iRealCountT = iClientCountT - iBotCountT;
	int iRealCountCT = iClientCountCT - iBotCountCT;
	
	if (iRealCountT == 0 && iRealCountCT > 0 || iRealCountT > 0 && iRealCountCT == 0)
	{
		// one team has real players and the other one does not
		if (!bBotModeEnabled)
		{
			// time to enable bot mode
			iBotModeTeam = iRealCountCT ? CS_TEAM_T : CS_TEAM_CT;
			EnableBotMode();
			bBotModeEnabled = true;
			PrintToChatAll("[\x04Bot Practice\x01]\x04 Bot Practice Mode\x01 has been\x04 ENABLED\x01.");
			PrintToServer("[Bot Practice] ENABLED");
		}
		else
		{
			// mode already enabled, perhaps bots are in the wrong team?
			if (iBotModeTeam != CS_TEAM_NONE && iBotModeTeam == CS_TEAM_T && iRealCountT > 0 || iBotModeTeam == CS_TEAM_CT && iRealCountCT > 0)
			{
				iBotModeTeam = iRealCountCT ? CS_TEAM_T : CS_TEAM_CT;
				DisableBotMode();
				EnableBotMode();
				PrintToChatAll("[\x04Bot Practice\x01] Bots have been moved to the other team.");
				PrintToServer("[Bot Practice] SWITCHED TEAMS");
			}
		}
	}
	else
	{
		// both teams have at least 1 real player or both teams have 0 real players
		if (bBotModeEnabled)
		{
			DisableBotMode();
			bBotModeEnabled = false;
			PrintToChatAll("[\x04Bot Practice\x01]\x04 Bot Practice Mode\x01 has been\x04 DISABLED\x01.");
			PrintToServer("[Bot Practice] DISABLED");
		}
	}
	
	if (bBotModeEnabled)
	{
		// might need to reduce bot quota?
		int currentBotQuota = getCurrentBotQuota();
		int maxBotQuota = getMaxBotQuota();
		
		if (currentBotQuota > maxBotQuota)
		{
			// too many bots
			if (currentBotQuota == 1)
			{
				// last bot, mp_limitteams should take care of diverting the player into the bot team
				//PrintToServer("WARNING: Last bot!");
			}
			else
			{
				SetConVarInt(cvarBotQuota, --currentBotQuota, false, false);
			}
		}
	}
}

void EnableBotMode()
{
	// cache some cvar values to restore them later after the practice mode has been disabled
	iCachedAutoTeamBalance = GetConVarInt(cvarAutoteambalance);
	iCachedLimitTeams = GetConVarInt(cvarLimitteams);
	
	// set cvars
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_limitteams 30");
	ServerCommand("bot_difficulty 1");
	ServerCommand("bot_join_team %s", iBotModeTeam == CS_TEAM_T ? "T" : "CT");
	
	// start out with just one bot
	ServerCommand("bot_quota_mode normal");
	ServerCommand("bot_quota 1");
	ServerExecute();
	
	iRoundLossBalance = 7;
}

void DisableBotMode()
{
	// remove all bots
	ServerCommand("bot_kick");
	ServerCommand("mp_autoteambalance %d", iCachedAutoTeamBalance);
	ServerCommand("mp_limitteams %d", iCachedLimitTeams);
	ServerCommand("bot_quota_mode normal");
	ServerCommand("bot_join_team any");
	ServerCommand("bot_quota 0");
	
	// restore cvars
	ServerExecute();
}

void OnRoundEnded(int winningTeam)
{
	if (bBotModeEnabled)
	{
		int currentBotQuota = getCurrentBotQuota();
		int maxBotQuota = getMaxBotQuota();
		int nextBotQuota = currentBotQuota;
		
		if (winningTeam == iBotModeTeam)
		{
			// bots are winning, reduce them
			nextBotQuota--;
			iRoundLossBalance++;
		}
		else
		{
			// bots did not win, increase them
			nextBotQuota++;
			iRoundLossBalance--;
		}
		
		nextBotQuota = CLAMP(nextBotQuota, 1, maxBotQuota);
		
		if (nextBotQuota != currentBotQuota)
		{
			SetConVarInt(cvarBotQuota, nextBotQuota, false, false);
		}
		
		char difficultyMessage[128];
		char difficultyDescription[32];
		int currentDifficulty = getCurrentBotDifficulty();
		int nextDifficulty = currentDifficulty;
		switch (iRoundLossBalance)
		{
			case 0, 1, 2:
			{
				nextDifficulty = 3;
				Format(difficultyDescription, sizeof(difficultyDescription), "Expert");
			}
			case 3, 4, 5:
			{
				nextDifficulty = 2;
				Format(difficultyDescription, sizeof(difficultyDescription), "Hard");
			}
			case 6, 7, 8:
			{
				nextDifficulty = 1;
				Format(difficultyDescription, sizeof(difficultyDescription), "Normal");
			}
			case 9, 10, 11:
			{
				nextDifficulty = 0;
				Format(difficultyDescription, sizeof(difficultyDescription), "Easy");
			}
		}
		
		if (nextDifficulty != currentDifficulty)
		{
			ServerCommand("bot_difficulty %d", nextDifficulty);
			ServerExecute();
			
			if (nextDifficulty < currentDifficulty)
				Format(difficultyMessage, sizeof(difficultyMessage), "Reducing difficulty to\x04 %s\x01.", difficultyDescription);
			else
				Format(difficultyMessage, sizeof(difficultyMessage), "Increasing difficulty to\x04 %s\x01.", difficultyDescription);
		}
		
		PrintToChatAll("[\x04Bot Practice\x01] Next wave:\x04 %d enemies\x01. %s", nextBotQuota, difficultyMessage);
	}
}

int getCurrentBotQuota()
{
	return GetConVarInt(cvarBotQuota);
}

int getMaxBotQuota()
{
	int iMaxBots = GetConVarInt(cvarMaxBots);
	int iFreeSpaceForBots = GetMaxHumanPlayers() - getClientCountExcludingTeam(iBotModeTeam) - 2; // leave 2 free spots to allow new players to join
	
	// limit the max number of bots to "server slots - amount of real players - 2"
	return CLAMP(iFreeSpaceForBots, 0, iMaxBots);
}

int getClientCountExcludingTeam(int iTeam)
{
	int iCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetClientTeam(i) != iTeam)
			++iCount;
	}
	
	return iCount;
}

int getCurrentBotDifficulty()
{
	return GetConVarInt(cvarBotDifficulty);
}
