#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>

ConVar g_GMActive;

public Plugin myinfo =
{
	name = "Teamchange on Death",
	author = "dominikrni",
	description = "changes a players team after they die in csgo",
	version = "1.1",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	g_GMActive = CreateConVar("dtm_enabled", "1", "Sets whether Elimination is active");

	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_poststart", AfterRoundEnd);
	HookEvent("round_start", BeforeRoundStart);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarInt(g_GMActive) > 0){
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(id) == CS_TEAM_CT){
			CS_SwitchTeam(id, CS_TEAM_T);
		}
		else if (GetClientTeam(id) == CS_TEAM_T){
			CS_SwitchTeam(id, CS_TEAM_CT);
		}
		else{
			return Plugin_Continue;
		}
		
		new tslots = GetTeamClientCount(2);
		new ctslots = GetTeamClientCount(3);
		if (tslots == 0){
			CS_TerminateRound(10.0, CSRoundEnd_CTWin);
			new score = CS_GetTeamScore(3);
			score = score + 1;
			CS_SetTeamScore(3, score)
			SetTeamScore(3, score)
			return Plugin_Handled
		}
		else if (ctslots == 0){
			CS_TerminateRound(10.0, CSRoundEnd_TerroristWin);
			new score = CS_GetTeamScore(2);
			score = score + 1;
			CS_SetTeamScore(2, score)
			SetTeamScore(2, score)
			return Plugin_Handled
		}
		else{
			return Plugin_Continue
		}
	}
}

public Action:AfterRoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarInt(g_GMActive) > 0){
		ServerCommand("mp_autoteambalance %d", 1);
		return Plugin_Handled
	}
}

public Action:BeforeRoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarInt(g_GMActive) > 0){
		ServerCommand("mp_autoteambalance %d", 0);
		return Plugin_Handled
	}
}