#pragma semicolon 1
#pragma newdecls required

#include <cstrike>

static const char TAG[] = "\x04[SM]";

public Plugin myinfo = {
	name		= "Move players",
	author		= "SniperHero",
	description	= "Move players to specific team.",
	version		= "1.0.1",
	url			= "https://forums.alliedmods.net/showthread.php?t=290675"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_joint", Command_joint, "You are going to terrorist team.");
	RegConsoleCmd("sm_joinct", Command_joinct, "You are going to counter-terrorist team.");
	RegConsoleCmd("sm_joinspec", Command_joinct, "You are going to counter-terrorist team.");
	RegAdminCmd("sm_spec", Command_spec, ADMFLAG_SLAY, "Move a player to the spectators team.");
	RegAdminCmd("sm_t", Command_t, ADMFLAG_SLAY, "Move a player to the terrorist team.");
	RegAdminCmd("sm_ct", Command_ct, ADMFLAG_SLAY, "Move a player to the counter-terrorist team.");
}

public Action Command_t(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%s \x01Usage: sm_t <target>", TAG);
		return Plugin_Handled;
	}

	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true); //Find the target(no bots, immunity check)

	if(GetClientTeam(target) == CS_TEAM_T)
	{
		ReplyToCommand(client, "%s %N it's already at terrorist team!", TAG, target);
	}
	else
	{
		ShowActivity2(client, TAG, "\x01moved player \x02%N \x01to the \x03terrorist \x01team.", target);
		ChangeClientTeam(target, CS_TEAM_T);
	}
	return Plugin_Handled;
}

public Action Command_ct(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%s \x01Usage: sm_ct <target>", TAG);
		return Plugin_Handled;
	}

	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, false); //Find the target(no bots, no immunity check)

	if(GetClientTeam(target) == CS_TEAM_CT)
	{
		ReplyToCommand(client, "%s %N it's already at counter-terrorist team !", TAG, target);
	}
	else
	{
		ShowActivity2(client, TAG, "\x01moved player \x02%N \x01to the \x03counter-terrorist \x01team.", target);
		ChangeClientTeam(target, CS_TEAM_CT);
	}
	return Plugin_Handled;
}

public Action Command_spec(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "%s \x01Usage: sm_spec <target>", TAG);
		return Plugin_Handled;
	}

	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, false); //Find the target(no bots, no immunity check)
	if(GetClientTeam(target) == CS_TEAM_SPECTATOR)
	{
		ReplyToCommand(client, "%s %N it's already at spectators team !", TAG, target);
	}
	else
	{
		ShowActivity2(client, TAG, "\x01moved player \x02%N \x01to the \x03spectators \x01team.", target);
		ChangeClientTeam(target, CS_TEAM_SPECTATOR);
	}
	return Plugin_Handled;
}

public Action Command_joint(int client, int args)
{
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		ReplyToCommand(client, "%s \x01You are already at terrorist team !", TAG);
	}
	else
	{
		ReplyToCommand(client, "%s \x01You have entred the terrorist team !", TAG);
		ChangeClientTeam(client, CS_TEAM_T);
	}
	return Plugin_Handled;
}

public Action Command_joinct(int client, int args)
{
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		ReplyToCommand(client, "%s \x01You are already at terrorist team !", TAG);
	}
	else
	{
		ReplyToCommand(client, "%s \x01You have entred the counter-terrorist team !", TAG);
		ChangeClientTeam(client, CS_TEAM_CT);
	}
	return Plugin_Handled;
}

public Action Command_joinspec(int client, int args)
{
	if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		ReplyToCommand(client, "%s \x01You are already at spectators team !", TAG);
	}
	else
	{
		ReplyToCommand(client, "%s \x01You have entred the spectators team !", TAG);
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	}
	return Plugin_Handled;
}