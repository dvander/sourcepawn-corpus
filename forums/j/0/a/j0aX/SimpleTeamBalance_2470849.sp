#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>
#include <adt_array>

public Plugin myinfo =
{
	name = "Simple Team Balance",
	author = "j0aX",
	description = "A simple Team Balance Plugin.",
	version = "1.0",
	url = "Server: 94.250.213.184"
};

/*CONSTANT VARS*/
new const TEAM_LESS = 0;
new const TEAM_MORE = 1;
new const DIFF_COUNT = 2;
new const String:PLUGIN_TAG[22] = " \x1\x0C[TeamBalance] ";

/*VARIABLES*/
ConVar sm_tb_enabled = null;
ConVar sm_tb_player_count = null;
ConVar sm_tb_msg = null;
new bool:g_cmd_tb_enabled = true;
new bool:g_cmd_tc_enabled = true;
/*g_team_diff[TEAM] = team with diff, g_team_diff[DIFF_COUNT] = difference between teams*/
new g_team_diff[3] = {0,0,0};

public void OnPluginStart() {
	/*Setup ConVars*/
	sm_tb_enabled = CreateConVar("sm_tb_enabled", "1","Decides whether Team Balance Plugin is enabled or not.",FCVAR_NONE,true, 0.0, true, 1.0);
	sm_tb_player_count = CreateConVar("sm_tb_player_count","0", "How much players needed before Team Balance will start.",FCVAR_NONE, true, 0.0, true, 65.0);
	sm_tb_msg = CreateConVar("sm_tb_msg", "1", "Enable messages for balance team and moves due to balance",FCVAR_NONE,true, 0.0, true, 1.0);
	AutoExecConfig(true,"simpleteambalance");
	HookConVarChange(sm_tb_enabled, OnConVarChange);
	/*Setup Commands*/
	RegAdminCmd("sm_teambalance", Command_toggleTeamBalance, ADMFLAG_SLAY);
	RegAdminCmd("sm_teamchange", Command_toggleTeamChange, ADMFLAG_SLAY);
	/*Hook Events | Commands*/
	if(sm_tb_enabled.IntValue) {
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	}
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action Command_toggleTeamBalance(int client, int args) {
	g_cmd_tb_enabled = !g_cmd_tb_enabled;
	if(g_cmd_tb_enabled) {
		PrintToChat(client,"%s\x04Team Balance enabled!",PLUGIN_TAG);
	} else {
		PrintToChat(client, "%s\x07Team Balance disabled!", PLUGIN_TAG);
	}
	return Plugin_Handled;
}

public Action Command_toggleTeamChange(int client, int args) {
	g_cmd_tc_enabled = !g_cmd_tc_enabled;
	if(g_cmd_tc_enabled) {
		PrintToChat(client, "%s\x07You've disabled the manual Team Change!", PLUGIN_TAG);
	} else {
		PrintToChat(client, "%s\x04You've enabled the manual Team Change!", PLUGIN_TAG);
	}
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue)) {
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	} else {
		UnhookEvent("round_end", Event_RoundEnd);
	}
}

public Action Command_JoinTeam(int client, const char[] command, int argc) {
	new old_team = GetClientTeam(client);
	new String:arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	new team_new = StringToInt(arg);
	if(g_cmd_tb_enabled && sm_tb_enabled.IntValue && g_cmd_tc_enabled && old_team != CS_TEAM_SPECTATOR) {
		if(IsPlayerAlive(client) && team_new != CS_TEAM_SPECTATOR && old_team != CS_TEAM_SPECTATOR) {
			ForcePlayerSuicide(client);
			CS_SwitchTeam(client, team_new);
		} else if(!g_cmd_tc_enabled) {
			return Plugin_Handled;
		} else {
			ChangeClientTeam(client, team_new);
		}
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	CheckTeamBalance();
	if(g_team_diff[DIFF_COUNT] > 1 && g_cmd_tb_enabled && GetClientCount() >= sm_tb_player_count.IntValue) {
		new Handle:mov_players = CreateArray(1,0);
		new counter = 0;
		new maplayers = GetMaxClients();
		new Handle:dead_players = CreateArray(1,0);
		for(new x = 1; x <= maplayers; x++) {
			if(IsClientInGame(x) && IsClientConnected(x) && GetClientTeam(x) == g_team_diff[TEAM_MORE]) {
				PushArrayCell(mov_players, x);
				counter++;
			}
			if(IsClientInGame(x) && IsClientConnected(x) && GetClientTeam(x) == g_team_diff[TEAM_MORE] && !IsPlayerAlive(x)) {
				PushArrayCell(dead_players, x);
			}
		}
		if(GetArraySize(dead_players) > 0) {
			while(g_team_diff[DIFF_COUNT] > 1 && GetArraySize(dead_players) > 0) {
				new rnd = GetRandomInt(0, GetArraySize(dead_players)-1);
				CS_SwitchTeam(GetArrayCell(dead_players,rnd), g_team_diff[TEAM_LESS]);
				SwitchNotify(g_team_diff[TEAM_LESS],GetArrayCell(dead_players,rnd));
				RemoveFromArray(dead_players, rnd);
				g_team_diff[DIFF_COUNT] = g_team_diff[DIFF_COUNT] - 1;
			}
		} 
		if(g_team_diff[DIFF_COUNT] > 1) {
			while(g_team_diff[DIFF_COUNT] > 1) {
				new rnd = GetRandomInt(0, GetArraySize(mov_players)-1);
				ForcePlayerSuicide(GetArrayCell(mov_players,rnd)-1);
				CS_SwitchTeam(GetArrayCell(mov_players,rnd), g_team_diff[TEAM_LESS]);
				SwitchNotify(g_team_diff[TEAM_LESS],GetArrayCell(mov_players,rnd));
				RemoveFromArray(mov_players, rnd);
				g_team_diff[DIFF_COUNT] = g_team_diff[DIFF_COUNT] - 1;
			}
		}
		
	} else {
		if(sm_tb_msg.IntValue) {
			PrintToChatAll("%s\x04Teams are balanced!",PLUGIN_TAG);
		}
	}
	return Plugin_Handled;
	
}

public void CheckTeamBalance() {
	new t_count = GetTeamClientCount(CS_TEAM_T);
	new ct_count = GetTeamClientCount(CS_TEAM_CT);
	
	if(t_count > ct_count) {
		g_team_diff[TEAM_LESS] = CS_TEAM_CT;
		g_team_diff[TEAM_MORE] = CS_TEAM_T;
		g_team_diff[DIFF_COUNT] = t_count - ct_count;
	} else if(ct_count > t_count) {
		g_team_diff[TEAM_LESS] = CS_TEAM_T;
		g_team_diff[TEAM_MORE] = CS_TEAM_CT;
		g_team_diff[DIFF_COUNT] = ct_count - t_count;
	}
}

public void SwitchNotify(int team, int player) {
	new newteam = team, oldteam = 0;
	new String:player_name[32];
	new String:team_name_old[16];
	new String:team_name_new[16];
	GetTeamName(newteam, team_name_new, 16);
	GetClientName(player, player_name, 32);
	if(newteam == CS_TEAM_CT) {
		oldteam = CS_TEAM_T;
		GetTeamName(oldteam,team_name_old,16);
		if(sm_tb_msg.IntValue) {
			PrintToChatAll("%s\x01moved \x04%s \x01from \x07%s \x01to \x0B%s", PLUGIN_TAG, player_name, team_name_old, team_name_new);
		}
	} else {
		oldteam = CS_TEAM_CT;
		GetTeamName(oldteam,team_name_old,16);
		if(sm_tb_msg.IntValue) {
			PrintToChatAll("%s\x01moved \x04%s \x01from \x0B%s \x01to \x07%s",PLUGIN_TAG,player_name,team_name_old,team_name_new);
		}
	}
}