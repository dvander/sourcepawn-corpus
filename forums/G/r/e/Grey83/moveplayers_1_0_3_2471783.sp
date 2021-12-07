#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdktools_functions>

static const char TAG[] = "\x04[SM]";
static const char sTeamName[][] = {
"",
"spectators",
"terrorists",
"counter-terrorists"
};
static const int CMD_FLAG = ADMFLAG_SLAY;

int limitteams;
bool teambalance;

public Plugin myinfo = {
	name		= "Move players",
	author		= "SniperHero (rewrited by Grey83)",
	description	= "Move players to specific team.",
	version		= "1.0.3",
	url			= "https://forums.alliedmods.net/showthread.php?t=290675"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_movet", Cmd_move2t, CMD_FLAG, "Move a player to the terrorist team.");
	RegAdminCmd("sm_movect", Cmd_move2ct, CMD_FLAG, "Move a player to the counter-terrorist team.");
	RegAdminCmd("sm_movespec", Cmd_move2spec, CMD_FLAG, "Move a player to the spectators team.");

	RegConsoleCmd("sm_joint", Cmd_join2t, "You are going to terrorist team.");
	RegConsoleCmd("sm_joinct", Cmd_join2ct, "You are going to counter-terrorist team.");
	RegConsoleCmd("sm_joinspec", Cmd_join2ct, "You are going to spectators team.");
}

public void OnConfigsExecuted()
{
	ConVar CVar;
	if((CVar = FindConVar("mp_limitteams")) != null)
	{
		HookConVarChange(CVar, LimitTeams_Changed);
		limitteams = CVar.IntValue;
	}
	if((CVar = FindConVar("mp_teambalance")) != null)
	{
		HookConVarChange(CVar, TeamBalance_Changed);
		teambalance = CVar.BoolValue;
	}
}

public void LimitTeams_Changed(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	limitteams = CVar.IntValue;
}

public void TeamBalance_Changed(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	teambalance = CVar.BoolValue;
}

public Action Cmd_move2t(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%s \x01Usage: sm_t <target>", TAG);
		return Plugin_Handled;
	}

	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	Move2Team(client, FindTarget(client, arg1, true), CS_TEAM_T);
	return Plugin_Handled;
}

public Action Cmd_move2ct(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%s \x01Usage: sm_ct <target>", TAG);
		return Plugin_Handled;
	}

	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	Move2Team(client, FindTarget(client, arg1, true), CS_TEAM_CT);
	return Plugin_Handled;
}

public Action Cmd_move2spec(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "%s \x01Usage: sm_spec <target>", TAG);
		return Plugin_Handled;
	}

	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	Move2Team(client, FindTarget(client, arg1, true), CS_TEAM_SPECTATOR);
	return Plugin_Handled;
}

public Action Cmd_join2t(int client, int args)
{
	Move2Team(client, client, CS_TEAM_T);
	return Plugin_Handled;
}

public Action Cmd_join2ct(int client, int args)
{
	Move2Team(client, client, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action Cmd_join2spec(int client, int args)
{
	Move2Team(client, client, CS_TEAM_SPECTATOR);
	return Plugin_Handled;
}

void Move2Team(int client, int target, int team)
{
	if(!(0 < target < MaxClients && IsClientInGame(target)))
	{
		ReplyToCommand(client, "%s Wrong target!", TAG);
		return;
	}

	if(!isTeamSlotsAvailable(team))
	{
		ReplyToCommand(client, "%s \x01No slots available in the \x03%s \x01team.", TAG);
		return;
	}

	static bool join;
	join = (client == target);

	if(GetClientTeam(target) == team)
	{
		if(join) ReplyToCommand(client, "%s \x01You are already at \x03%s \x01team!", TAG, sTeamName[team]);
		else ReplyToCommand(client, "%s \x02%N \x01it's already at \x03%s \x01team!", TAG, target, sTeamName[team]);
	}
	else
	{
		if(join) ReplyToCommand(client, "%s \x01You have entred the \x03%s \x01team!", TAG, sTeamName[team]);
		else ShowActivity2(client, TAG, "\x01moved player \x02%N \x01to the \x03%s \x01team.", target, sTeamName[team]);
		ChangeClientTeam(target, team);
	}
}

bool isTeamSlotsAvailable(int team)
{
	if(!teambalance || !limitteams || team < 2) return true;
	if(team > 3) return false;

	return ((GetTeamClientCount(team > 2 ? 2 : 3) - GetTeamClientCount(team) + limitteams) > 1);
}