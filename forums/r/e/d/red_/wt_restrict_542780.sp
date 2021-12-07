#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define PLUGIN_VERSION "1.2.5"

#define STREAK_NONE 0
#define STREAK_BOTH 1


public Plugin:myinfo = 
{
	name = "HANSE WT-Restrict",
	author = "red!",
	description = "Provides winning team restrictions",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
};

/* Handles to convars used by plugin */
new Handle:sm_wt_restrict_enable;
new Handle:sm_restrict_cmd_t;
new Handle:sm_restrict_cmd_ct;
new Handle:sm_unrestrict_cmd_t;
new Handle:sm_unrestrict_cmd_ct;
new Handle:sm_restrict_cmd_unrestrict_all;
new Handle:sm_wt_offset;
new Handle:sm_wstreak_len;
new Handle:sm_wstreak_type;

new s_streak[4]={0, 0, 0, 0};

public OnPluginStart()
{
	
	
	// connect to the setting convars
	
	sm_wt_restrict_enable = CreateConVar("sm_wt_restrict_enable", "1");
	sm_wt_offset = CreateConVar("sm_wt_offset", "0");
	sm_wstreak_len = CreateConVar("sm_winstreak_length", "2");
	sm_wstreak_type = CreateConVar("sm_winstreak_mode", "1", "0=unrestrict, 1=restrict for both teams");
	sm_restrict_cmd_t = CreateConVar("sm_restrict_cmd_t", "");
	sm_restrict_cmd_ct = CreateConVar("sm_restrict_cmd_ct", "");
	sm_unrestrict_cmd_t = CreateConVar("sm_unrestrict_cmd_t", "");
	sm_unrestrict_cmd_ct = CreateConVar("sm_unrestrict_cmd_ct", "");
	sm_restrict_cmd_unrestrict_all = CreateConVar("sm_restrict_cmd_unrestrict_all", "");

	CreateConVar("wt_restrict_version", PLUGIN_VERSION, "Version of [HANSE] WT-Restrict", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);

	
	// hook round start & round end events
	HookEvent("round_end",OnRoundEnd,EventHookMode_Pre);
	HookEvent("round_start",OnRoundStart);
	
	RegConsoleCmd("sm_wtrestrict_status", debugPrint);
}

new bool:restricted[4]={false, false, false, false};


public Action:debugPrint(client, args)
{
	PrintToConsole(client,"[wt_restrict] ct score %d, win streak %d, restriction %d, t score %d, win streak %d, restriction %d", GetTeamScore(CS_TEAM_CT), s_streak[CS_TEAM_CT], restricted[CS_TEAM_CT], GetTeamScore(CS_TEAM_T), s_streak[CS_TEAM_T], restricted[CS_TEAM_T]);
	return Plugin_Handled;
}


set_wt_restriction(team, bool:restrict)
{
	new String:cmd[256]="";
	if (restricted[team]!=restrict) 
	{
		restricted[team]=restrict;
		
		if (restrict)
		{
			if (team==CS_TEAM_T) {
				LogMessage("Activating winning team restrictions for team T. (CT: %d, T: %d)", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
				GetConVarString(sm_restrict_cmd_t, cmd, 256);
			} else if (team==CS_TEAM_CT) {
				LogMessage("Activating winning team restrictions for team CT. (CT: %d, T: %d)", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
				GetConVarString(sm_restrict_cmd_ct, cmd, 256);
			} else {
				LogMessage("Invalid team, can not restrict. internal error. (CT: %d, T: %d)", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
			}
		} 
		else 
		{
			if (team==CS_TEAM_T) {
				LogMessage("Removing winning team restrictions for team T. (CT: %d, T: %d)", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
				GetConVarString(sm_unrestrict_cmd_t, cmd, 256);
			} else if (team==CS_TEAM_CT) {
				LogMessage("Removing winning team restrictions for team CT. (CT: %d, T: %d)", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
				GetConVarString(sm_unrestrict_cmd_ct, cmd, 256);
			} else {
				LogMessage("Invalid team, can not unrestrict. internal error. (CT: %d, T: %d)", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T));
			}
		}
	}
	
	if (cmd[0]!=0) {
		//LogMessage("[debug] exec: %s", cmd);
		ServerCommand("%s", cmd);
	}
}

new s_offset;
public OnRoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
	
	// break if plugin is disabled
	if (GetConVarInt(sm_wt_restrict_enable)==0) 
	{
		set_wt_restriction(CS_TEAM_T, false);
		set_wt_restriction(CS_TEAM_CT, false);
		return;
	}
	
	s_offset = GetConVarInt(sm_wt_offset);
	new wstreakType = GetConVarInt(sm_wstreak_type);
	
	// evaluate continous win streak
	new winner = GetEventInt(event, "winner");	
	if (winner==CS_TEAM_T) {
		s_streak[CS_TEAM_T]++; 
		s_streak[CS_TEAM_CT]=0; 
	}
	if (winner==CS_TEAM_CT) { 
		s_streak[CS_TEAM_CT]++; 
		s_streak[CS_TEAM_T]=0; 
	}
	
	// evaluate teams to actiavte restrictions for
	if (isDominatingTeam(CS_TEAM_T)) {
		if (hasWinStreak(CS_TEAM_CT)) {
			LogMessage("[debug] the CT team is loosing by points but has a win streak of %d, mode %d", s_streak[CS_TEAM_CT], wstreakType);
			set_wt_restriction(CS_TEAM_CT, wstreakType==STREAK_BOTH);
			set_wt_restriction(CS_TEAM_T, wstreakType==STREAK_BOTH);
		} else {
			set_wt_restriction(CS_TEAM_CT, false);
			set_wt_restriction(CS_TEAM_T, true);
		}
	} else if (isDominatingTeam(CS_TEAM_CT)) {
		if (hasWinStreak(CS_TEAM_T)) {
			LogMessage("[debug] the T team is loosing by points but has a win streak of %d, mode %d", s_streak[CS_TEAM_T], wstreakType);
			set_wt_restriction(CS_TEAM_CT, wstreakType==STREAK_BOTH);
			set_wt_restriction(CS_TEAM_T, wstreakType==STREAK_BOTH);
		} else {
			set_wt_restriction(CS_TEAM_CT, true);
			set_wt_restriction(CS_TEAM_T, false);
		}
	} else {
		set_wt_restriction(CS_TEAM_CT, false);
		set_wt_restriction(CS_TEAM_T, false);
	}
	

}

bool:isDominatingTeam(team) 
{
	return (GetTeamScore(team) > (s_offset + GetTeamScore((team==CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T)));
}
bool:hasWinStreak(team) 
{
	new min_streak= GetConVarInt(sm_wstreak_len);
	if (min_streak>0) {
		return (s_streak[team]>min_streak);
	} else {
		return false;
	}
}

public OnRoundStart(Handle: event , const String: name[] , bool: dontBroadcast)
{	
	// announcements
}

public OnMapStart() 
{
	s_streak[CS_TEAM_CT]=0; 
	s_streak[CS_TEAM_T]=0; 
	set_wt_restriction(CS_TEAM_CT, false);
	set_wt_restriction(CS_TEAM_T, false);
	
	new String:cmd[256];
	GetConVarString(sm_restrict_cmd_unrestrict_all, cmd, 256);
	ServerCommand("%s", cmd);
}