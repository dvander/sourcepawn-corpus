/*
    Copyright 2012, Fabian "Graveeater" Kürten

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define TEAM_A 1
#define TEAM_B 2
#define SCORE_TYPE_ROUND 0
#define SCORE_TYPE_CAMPAIGN 1

#define ASSUME_WINNING_TEAM_STARTS 1
#define ASSUME_LOOSING_TEAM_STARTS 0
#define ASSUME_INFECTED_CANNOT_SCORE 1
#define ASSUME_COUNTER_WORKS 0

#define UNKNOWN_VALUE -1

new Handle:gConf = INVALID_HANDLE;
new Handle:fGetTeamScore = INVALID_HANDLE;
// Handle for configuration variables
// ... next two: Respawn time for players in versus, L4D2 core
new Handle:cvRespawnMin = INVALID_HANDLE;
new Handle:cvRespawnMax = INVALID_HANDLE;

new mapAndRound;


public Plugin:myinfo =
{
	name = "Balance",
	author = "Graveeater",
	description = "Balance difficulty for uneven teams.",
	version = "0.0.0.3",
	url = "http://www.sourcemod.net/"
};

/**
 * Called about once.
 */
public OnPluginStart() {
	// Perform one-time startup tasks ...
	PrepareAllSDKCalls()

	mapAndRound = 0;

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);

	cvRespawnMin = FindConVar("z_ghost_delay_min");
	cvRespawnMax = FindConVar("z_ghost_delay_max");

	CreateTimer(15.0, TimerEvent, _, TIMER_REPEAT)
	ShowActivity2(0, "[SM] ", "OnPluginStart")
}

/**
 * Load functions using SDKTools.
 */
PrepareAllSDKCalls() {
	gConf = LoadGameConfigFile("left4downtown.l4d2");
	if(gConf == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/left4downtown.l4d2.txt");
	}

	// GetTeamScores
	StartPrepSDKCall(SDKCall_GameRules);
	if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "GetTeamScore"))
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		fGetTeamScore = EndPrepSDKCall();

		if(fGetTeamScore == INVALID_HANDLE) {
			ThrowError("[TEST] Function 'GetTeamScore' found, but something went wrong.");
		}
		else
		{
			//DebugPrintToAll("[TEST] Function 'GetTeamScore' initialized.");
		}
	}
	else
	{
		ThrowError("[TEST] Function 'GetTeamScore' not found.");
	}
}

stock GetTeamRoundScore(logical_team)
{
	return SDKCall(fGetTeamScore, logical_team, SCORE_TYPE_ROUND);
}

stock GetTeamCampaignScore(logical_team)
{
	return SDKCall(fGetTeamScore, logical_team, SCORE_TYPE_CAMPAIGN);
}

// ############################################################################
// ############################################################################
// ###     .                                                          .     ###
// ###           .                                              .           ###
// ###                 .                                  .                 ###
// ###                           WHO IS PLAYING?                            ###
// ###                                                                      ###
// ###                                                                      ###
// ###                                                                      ###
// ############################################################################
// ############################################################################

//
//
// @returns:
//    TEAM_A        team A
//    TEAM_B        team B
//    TEAM_UNKNOWN  unknown
//    ERROR_MORE_THAN_ONE_TEAM_PLAYING    error
#define TEAM_UNKNOWN -1
#define ERROR_MORE_THAN_ONE_TEAM_PLAYING -2
stock GetCurrentlyPlayingTeam() {
	new teamARound = GetTeamRoundScore(TEAM_A)
	new teamBRound = GetTeamRoundScore(TEAM_B)

	if (teamARound > 0) {
		if (teamBRound > 0) {
			return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
		} else {
			return TEAM_A;
		}
	} else {
		if (teamBRound > 0) {
			return TEAM_B;
		} else {
			return TEAM_UNKNOWN;
		}
	}
}

stock CanDecideWhoIsSurvivor() {
	new teamARound = GetTeamRoundScore(TEAM_A)
	new teamBRound = GetTeamRoundScore(TEAM_B)
	if (teamARound > 0) {
		if (teamBRound > 0) {
			return 0
		} else {
			return 1
		}
	} else {
		if (teamBRound > 0) {
			return 1
		} else {
			return 0
		}
	}
}

stock OtherTeam(team) {
	if(team == TEAM_A) {
		return TEAM_B;
	} else if(team == TEAM_B) {
		return TEAM_A;
	} else {
		return TEAM_UNKNOWN;
	}
}

// ############################################################################
// ############################################################################
// ###     .                                                          .     ###
// ###           .                                              .           ###
// ###                 .                                  .                 ###
// ###                          GET SCORE BY ROLE                           ###
// ###                                                                      ###
// ###                                                                      ###
// ###                                                                      ###
// ############################################################################
// ############################################################################



stock GetSurvivorRoundScore() {
	new teamPlaying = GetCurrentlyPlayingTeam()
	if (teamPlaying == TEAM_UNKNOWN) {
		return UNKNOWN_VALUE;
	}
	if (teamPlaying == ERROR_MORE_THAN_ONE_TEAM_PLAYING) {
		return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
	}
	return GetTeamRoundScore(teamPlaying)
}

stock GetSurvivorCampaignScore() {
	new teamPlaying = GetCurrentlyPlayingTeam()
	if (teamPlaying == TEAM_UNKNOWN) {
		return UNKNOWN_VALUE;
	}
	if (teamPlaying == ERROR_MORE_THAN_ONE_TEAM_PLAYING) {
		return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
	}
	return GetTeamCampaignScore(teamPlaying)
}

stock GetSurvivorTotalScore() {
	new teamPlaying = GetCurrentlyPlayingTeam()
	if (teamPlaying == TEAM_UNKNOWN) {
		return UNKNOWN_VALUE;
	}
	if (teamPlaying == ERROR_MORE_THAN_ONE_TEAM_PLAYING) {
		return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
	}
	return GetTeamRoundScore(teamPlaying) + GetTeamCampaignScore(teamPlaying);
}

stock GetInfectedRoundScore() {
	new teamPlaying = GetCurrentlyPlayingTeam()
	if (teamPlaying == TEAM_UNKNOWN) {
		return UNKNOWN_VALUE;
	}
	if (teamPlaying == ERROR_MORE_THAN_ONE_TEAM_PLAYING) {
		return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
	}
	new otherTeam = OtherTeam(teamPlaying)
	return GetTeamRoundScore(otherTeam)
}

stock GetInfectedCampaignScore() {
	new teamPlaying = GetCurrentlyPlayingTeam()
	if (teamPlaying == TEAM_UNKNOWN) {
		return UNKNOWN_VALUE;
	}
	if (teamPlaying == ERROR_MORE_THAN_ONE_TEAM_PLAYING) {
		return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
	}
	new otherTeam = OtherTeam(teamPlaying)
	return GetTeamCampaignScore(otherTeam)
}

stock GetInfectedTotalScore() {
	new teamPlaying = GetCurrentlyPlayingTeam()
	if (teamPlaying == TEAM_UNKNOWN) {
		return UNKNOWN_VALUE;
	}
	if (teamPlaying == ERROR_MORE_THAN_ONE_TEAM_PLAYING) {
		return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
	}
	new otherTeam = OtherTeam(teamPlaying)
	return GetTeamRoundScore(otherTeam) + GetTeamCampaignScore(otherTeam);
}

// ############################################################################
// ############################################################################
// ###     .                                                          .     ###
// ###           .                                              .           ###
// ###                 .                                  .                 ###
// ###                          GET ROUND AND MAP                           ###
// ###                                                                      ###
// ###                                                                      ###
// ###                                                                      ###
// ############################################################################
// ############################################################################

#define ODD_ROUND 1
#define EVEN_ROUND 2
stock GetRoundInThisMap() {
	new teamACampaignScore = GetTeamCampaignScore(TEAM_A)
	new teamBCampaignScore = GetTeamCampaignScore(TEAM_B)

	if (teamACampaignScore == 0) {
		if (teamBCampaignScore == 0) {
			// most likely the first round in the first map
			return ODD_ROUND;
		} else {
			// first team got owned?
			return ODD_ROUND;
		}
	} else {
		if (teamBCampaignScore == 0) {
			// second round on first map
			return EVEN_ROUND;
		} else {
			// both teams have score. can't say anything yet
		}
	}

	// step 2
	#if ASSUME_INFECTED_CANNOT_SCORE
		#if ASSUME_WINNING_TEAM_STARTS
			if (CanDecideWhoIsSurvivor()) {
				new survivorCampaignScore = GetSurvivorCampaignScore()
				new infectedCampaignScore = GetInfectedCampaignScore()
				if (survivorCampaignScore > infectedCampaignScore) {
					// odd round
					return ODD_ROUND;
				} else if (survivorCampaignScore < infectedCampaignScore) {
					return EVEN_ROUND;
				}
			}
		#endif
		#if ASSUME_LOOSING_TEAM_STARTS
			if (CanDecideWhoIsSurvivor()) {
				new survivorCampaignScore = GetSurvivorCampaignScore()
				new infectedCampaignScore = GetInfectedCampaignScore()
				if (survivorCampaignScore > infectedCampaignScore) {
					// if the loosers start, then the survivors will never have
					// more score than infected in ODD_ROUND, hence it must be
					// EVEN_ROUND
					return EVEN_ROUND;
				}
				// unfortunately, we cannot say anything about the other direction
			}
		#endif
	#endif

	#if ASSUME_COUNTER_WORKS
		return ((mapAndRound-1) % 2) + 1
	#endif
	return UNKNOWN_VALUE
}

#define FIRST_MAP 1
#define UNKNOWN_VALUE_NOT_FIRST_MAP (100-FIRST_MAP)
stock GetMapNumber() {
	new teamACampaignScore = GetTeamCampaignScore(TEAM_A)
	new teamBCampaignScore = GetTeamCampaignScore(TEAM_B)

	if (teamACampaignScore == 0) {
		if (teamBCampaignScore == 0) {
			// most likely the first round in the first map
			return FIRST_MAP;
		} else {
			// first team got owned?
			return FIRST_MAP;
		}
	} else {
		if (teamBCampaignScore == 0) {
			// second round on first map
			return FIRST_MAP;
		} else {
			// both teams have score. can't say anything
		}
	}

	#if ASSUME_COUNTER_WORKS
		return (mapAndRound+1) / 2;
	#endif
	return UNKNOWN_VALUE;
}

// ############################################################################
// ############################################################################
// ###     .                                                          .     ###
// ###           .                                              .           ###
// ###                 .                                  .                 ###
// ###                        BALANCING CALCULATION                         ###
// ###                                                                      ###
// ###                                                                      ###
// ###                                                                      ###
// ############################################################################
// ############################################################################


stock GetSurvivorScoreDelta() {
	new teamPlaying = GetCurrentlyPlayingTeam();
	if (teamPlaying == TEAM_UNKNOWN) {
		return UNKNOWN_VALUE;
	}
	if (teamPlaying == ERROR_MORE_THAN_ONE_TEAM_PLAYING) {
		return ERROR_MORE_THAN_ONE_TEAM_PLAYING;
	}
	return GetSurvivorTotalScore() - GetInfectedTotalScore()
}

stock GetMaxRoundScore() {
	return L4D_GetVersusMaxCompletionScore() + 100;
}

#define DONT_HANDICAP 0
/**
 * @returns 0 don't handicap
 *          >0 handicap current survivors
 *          <0 handicap current infected
 */
stock GetHandicapSuggestion() {
	new round = GetRoundInThisMap();
	if (round == UNKNOWN_VALUE) return DONT_HANDICAP;
	new survivorTotalScore = GetSurvivorTotalScore();
	if (survivorTotalScore == UNKNOWN_VALUE) return DONT_HANDICAP;
	if (survivorTotalScore == ERROR_MORE_THAN_ONE_TEAM_PLAYING) return DONT_HANDICAP;
	new survivorCampaignScore = GetSurvivorCampaignScore();
	if (survivorCampaignScore == UNKNOWN_VALUE) return DONT_HANDICAP;
	if (survivorCampaignScore == ERROR_MORE_THAN_ONE_TEAM_PLAYING) return DONT_HANDICAP;
	new infectedScore = GetInfectedTotalScore();
	if (infectedScore == UNKNOWN_VALUE) return DONT_HANDICAP;
	if (infectedScore == ERROR_MORE_THAN_ONE_TEAM_PLAYING) return DONT_HANDICAP;

	new maxRoundScore = GetMaxRoundScore();

	if (round == ODD_ROUND)	{
		// first round
		if (survivorTotalScore > infectedScore + maxRoundScore) {
			// playing team is leading more than other team can possibly get
			return 1;
		} else if (survivorCampaignScore + maxRoundScore < infectedScore) {
			// playing team is too much behind, will still be behind after completing round
			return -1;
		}
	} else if (round == EVEN_ROUND) {
		// second round
		if(survivorCampaignScore + maxRoundScore < infectedScore) {
			// playing team is too much behind, will still be behind after completing round
			return -1;
		} else if (survivorTotalScore > infectedScore) {
			// playing team is leading, other team has already played
			return 1;
		}
	}
	return DONT_HANDICAP;
}

// ###########################################################################

stock SetRespawnTime(time) {
	SetConVarInt(cvRespawnMin, time)
	SetConVarInt(cvRespawnMax, time)
}


// ###########################################################################

public OnMapStart() {
	ShowActivity2(0, "[SM] ", "OnMapStart")
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	ShowActivity2(0, "[SM] ", "RoundStart")
	mapAndRound++;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	ShowActivity2(0, "[SM] ", "RoundEnd")
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	// ShowActivity2(0, "[SM] ", "PlayerTeam")
}


public Action:TimerEvent(Handle:timer) {
	new teamACampaignScore = GetTeamCampaignScore(TEAM_A)
	new teamBCampaignScore = GetTeamCampaignScore(TEAM_B)
	new teamARoundScore = GetTeamRoundScore(TEAM_A)
	new teamBRoundScore = GetTeamRoundScore(TEAM_B)
	new map = GetMapNumber()
	new round = GetRoundInThisMap()
	//ShowActivity2(0, "[SM] ", "R:%d %d, C:%d %d, Map:%d Round:%d, mapAndRound=%d", teamARoundScore, teamBRoundScore, teamACampaignScore, teamBCampaignScore, map, round, mapAndRound)

	new teamPlaying = GetCurrentlyPlayingTeam();
	new survivorScore = GetSurvivorTotalScore();
	new infectedScore = GetInfectedTotalScore();
	new maxScore = L4D_GetVersusMaxCompletionScore()
	//ShowActivity2(0, "[SM] ", "Playing:%d, S:%d, I:%d, maxScore=%d", teamPlaying, survivorScore, infectedScore, maxScore)
	new deltaScore = GetSurvivorScoreDelta();
	new handicap = GetHandicapSuggestion();

	new time = 0;
	if (handicap < 0) {
		time = 45;
	} else if (handicap > 0) {
		time = 5;
	} else {
		time = 20;
	}
	SetRespawnTime(time);
	ShowActivity2(0, "[SM] ", "Playing:%d, delta=%d, max=%d, suggestion:%d, time=%d", teamPlaying, deltaScore, maxScore, handicap, time)
	return Plugin_Continue
}

