#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.4a"




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

public OnPluginStart()
{
	
	
	// connect to the setting convars
	
	sm_wt_restrict_enable = FindConVar("sm_wt_restrict_enable");
	if (sm_wt_restrict_enable==INVALID_HANDLE) {
		CreateConVar("sm_wt_restrict_enable", "1");
		sm_wt_restrict_enable = FindConVar("sm_wt_restrict_enable");
	}
	
	sm_wt_offset = FindConVar("sm_wt_offset");
	if (sm_wt_offset==INVALID_HANDLE) {
		CreateConVar("sm_wt_offset", "0");
		sm_wt_offset = FindConVar("sm_wt_offset");
	}
	
	sm_restrict_cmd_t = FindConVar("sm_restrict_cmd_t");
	if (sm_restrict_cmd_t==INVALID_HANDLE) {
		CreateConVar("sm_restrict_cmd_t", "");
		sm_restrict_cmd_t = FindConVar("sm_restrict_cmd_t");
	}
	sm_restrict_cmd_ct = FindConVar("sm_restrict_cmd_ct");
	if (sm_restrict_cmd_ct==INVALID_HANDLE) {
		CreateConVar("sm_restrict_cmd_ct", "");
		sm_restrict_cmd_ct = FindConVar("sm_restrict_cmd_ct");
	}
	sm_unrestrict_cmd_t = FindConVar("sm_unrestrict_cmd_t");
	if (sm_unrestrict_cmd_t==INVALID_HANDLE) {
		CreateConVar("sm_unrestrict_cmd_t", "");
		sm_unrestrict_cmd_t = FindConVar("sm_unrestrict_cmd_t");
	}
	sm_unrestrict_cmd_ct = FindConVar("sm_unrestrict_cmd_ct");
	if (sm_unrestrict_cmd_ct==INVALID_HANDLE) {
		CreateConVar("sm_unrestrict_cmd_ct", "");
		sm_unrestrict_cmd_ct = FindConVar("sm_unrestrict_cmd_ct");
	}

	sm_restrict_cmd_unrestrict_all = FindConVar("sm_restrict_cmd_unrestrict_all");
	if (sm_restrict_cmd_unrestrict_all==INVALID_HANDLE) {
		CreateConVar("sm_restrict_cmd_unrestrict_all", "");
		sm_restrict_cmd_unrestrict_all = FindConVar("sm_restrict_cmd_unrestrict_all");
	}
	
	CreateConVar("wt_restrict_version", PLUGIN_VERSION, "Version of [HANSE] WT-Restrict", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);

	
	// hook round start & round end events
	HookEvent("round_end",OnRoundEnd,EventHookMode_Pre);
	HookEvent("round_start",OnRoundStart);
	
	RegConsoleCmd("sm_wtrestrict_status", debugPrint);
}

new bool:restricted_T=false;
new bool:restricted_CT=false;
new score_t=0;
new score_ct=0;

public Action:debugPrint(client, args)
{
	PrintToConsole(client,"[wt_restrict] ct score %d, restriction %d, t score %d, restriction %d", score_ct, restricted_CT, score_t, restricted_T);
	return Plugin_Handled;
}



set_T_restriction(bool:restrict)
{
	new String:cmd[256];
	if (restricted_T!=restrict) 
	{
		restricted_T=restrict;
		
		if (restrict)
		{
			// call sm_restrict_cmd_t
			GetConVarString(sm_restrict_cmd_t, cmd, 256);
			//PrintToServer("[wt_restrict] exec: %s", cmd);
			ServerCommand("%s", cmd);
		} 
		else 
		{
			// call sm_unrestrict_cmd_t
			GetConVarString(sm_unrestrict_cmd_t, cmd, 256);
			//PrintToServer("[wt_restrict] exec: %s", cmd);
			ServerCommand("%s", cmd);
		}
	}
}

set_CT_restriction(bool:restrict)
{
	new String:cmd[256];
	if (restricted_CT!=restrict) 
	{
		restricted_CT=restrict;
		
		if (restrict)
		{
			// call sm_restrict_cmd_ct
			GetConVarString(sm_restrict_cmd_ct, cmd, 256);
			//PrintToServer("[wt_restrict] exec: %s", cmd);
			ServerCommand("%s", cmd);
		} 
		else 
		{
			// call sm_unrestrict_cmd_ct
			GetConVarString(sm_unrestrict_cmd_ct, cmd, 256);
			//PrintToServer("[wt_restrict] exec: %s", cmd);
			ServerCommand("%s", cmd);
		}
	}
}

#define TEAM_T 2
#define TEAM_CT 3

public OnRoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
	// count scores
	new winner = GetEventInt(event, "winner");
	
	if (winner==TEAM_T) score_t++;
	if (winner==TEAM_CT) score_ct++;

	
	// break if plugin is disabled
	if (GetConVarInt(sm_wt_restrict_enable)==0) 
	{
		set_CT_restriction(false);
		set_T_restriction(false);
		return;
	}
	
	
	new offset = GetConVarInt(sm_wt_offset);
	
	// evaluate teams to actiavte restrictions for
	if ((score_t+offset>=score_ct) && (score_ct+offset>=score_t)) {
		set_CT_restriction(false);
		set_T_restriction(false);
	} else if (score_t>score_ct) {
		set_CT_restriction(false);
		set_T_restriction(true);
	} else if (score_t<score_ct) {
		set_CT_restriction(true);
		set_T_restriction(false);
	}
}

public OnRoundStart(Handle: event , const String: name[] , bool: dontBroadcast)
{	
	// announcements
}

public OnMapStart() 
{
	
	score_t=0;
	score_ct=0;
	set_CT_restriction(false);
	set_T_restriction(false);
	
	new String:cmd[256];
	GetConVarString(sm_restrict_cmd_unrestrict_all, cmd, 256);
	ServerCommand("%s", cmd);
}