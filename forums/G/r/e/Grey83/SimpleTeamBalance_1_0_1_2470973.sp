#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdktools_functions>
#include <adt_array>

static const char CHAT_TAG[] = " \x1\x0C[TeamBalance] ";
static const char SERVER_TAG[] = "[TeamBalance] ";

bool bEnabled,
	bMsg,
	bTeamBalance = true,
	bTeamChange = true,
	bHooked;
int iCount,
	iDiff;
char TeamName[4][32];

public Plugin myinfo =
{
	name		= "[CSGO] Simple Team Balance",
	author		= "j0aX (rewrited by Grey83)",
	description	= "A simple Team Balance Plugin.",
	version		= "1.0.1",
//	url			= "Server: 94.250.213.184"
	url			= "https://forums.alliedmods.net/showthread.php?t=290587"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("Plugin supports CS:GO only.");

	ConVar CVar;
	HookConVarChange((CVar = CreateConVar("sm_tb_enabled", "1","Decides whether Team Balance Plugin is enabled or not.",FCVAR_NONE,true, 0.0, true, 1.0)), CVarChange_Enabled);
	bEnabled = CVar.BoolValue;
	HookConVarChange((CVar = CreateConVar("sm_tb_player_count","0", "How much players needed before Team Balance will start.",FCVAR_NONE, true, 0.0, true, 65.0)), CVarChange_Count);
	iCount = CVar.IntValue;
	HookConVarChange((CVar = CreateConVar("sm_tb_msg", "1", "Enable messages for balance team and moves due to balance",FCVAR_NONE,true, 0.0, true, 1.0)), CVarChange_Msg);
	bMsg = CVar.BoolValue;

	AutoExecConfig(true,"simpleteambalance");

	RegAdminCmd("sm_teambalance", Command_toggleTeamBalance, ADMFLAG_SLAY);
	RegAdminCmd("sm_teamchange", Command_toggleTeamChange, ADMFLAG_SLAY);
	AddCommandListener(Command_JoinTeam, "jointeam");

	if(bEnabled) HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

public void CVarChange_Enabled(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	if((bEnabled = CVar.BoolValue) && !bHooked) HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	else if(!bEnabled && bHooked) UnhookEvent("round_end", Event_RoundEnd);
}

public void CVarChange_Count(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iCount = CVar.IntValue;
}

public void CVarChange_Msg(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bMsg= CVar.BoolValue;
}

public void OnMapStart()
{
	char buffer[32];
	GetTeamName(CS_TEAM_T, buffer, 32);
	Format(TeamName[CS_TEAM_T], 32, "\x07%s", buffer);
	GetTeamName(CS_TEAM_CT, TeamName[3], 32);
	Format(TeamName[CS_TEAM_CT], 32, "\x0B%s", buffer);
}

public Action Command_toggleTeamBalance(int client, int args)
{
	if(bEnabled)
	{
		bTeamBalance = !bTeamBalance;

		if(!client) PrintToServer("%sTeam Balance %s!", SERVER_TAG, bTeamBalance ? "enabled" : "disabled");
		else PrintToChat(client, "%s\x07Team Balance %s!", CHAT_TAG, bTeamBalance ? "enabled" : "disabled");
	}
	else
	{
		if(!client) PrintToServer("%sYou do not have access to this command: plugin is disabled!", SERVER_TAG, bTeamChange ? "enabled" : "disabled");
		else PrintToChat(client, "%s\x04You do not have access to this command: plugin is \x07disabled!", CHAT_TAG, bTeamChange ? "enabled" : "disabled");
	}

	return Plugin_Handled;
}

public Action Command_toggleTeamChange(int client, int args)
{
	if(bEnabled)
	{
		bTeamChange = !bTeamChange;

		if(!client) PrintToServer("%sYou've %s the manual Team Change!", SERVER_TAG, bTeamChange ? "enabled" : "disabled");
		else PrintToChat(client, "%s\x04You've %s the manual Team Change!", CHAT_TAG, bTeamChange ? "enabled" : "disabled");
	}
	else
	{
		if(!client) PrintToServer("%sYou do not have access to this command: plugin is disabled!", SERVER_TAG, bTeamChange ? "enabled" : "disabled");
		else PrintToChat(client, "%s\x04You do not have access to this command: plugin is \x07disabled!", CHAT_TAG, bTeamChange ? "enabled" : "disabled");
	}

	return Plugin_Handled;
}

public Action Command_JoinTeam(int client, const char[] command, int argc)
{
	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int team_new = StringToInt(arg);

	if(bEnabled && bTeamBalance && bTeamChange && GetClientTeam(client) != CS_TEAM_SPECTATOR)
	{
		if(IsPlayerAlive(client) && team_new != CS_TEAM_SPECTATOR)
		{
			ForcePlayerSuicide(client);
			CS_SwitchTeam(client, team_new);
		}
		else ChangeClientTeam(client, team_new);

		return Plugin_Handled;
	}
	else return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	bHooked = true;

	if(bEnabled && bTeamBalance && GetClientCount() >= iCount)
	{
		static int target_team;
		target_team = CheckTeamBalance();

		if((target_team = CheckTeamBalance()))
		{
			ArrayList mov_players, dead_players;
			mov_players = new ArrayList(1,0);
			dead_players = new ArrayList(1,0);

			int counter;
			for(int x = 1; x <= MaxClients; x++)
			{
				if(IsClientInGame(x) && GetClientTeam(x) == (target_team == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T))
				{
					counter++;
					if(IsPlayerAlive(x)) mov_players.Push(x);
					else dead_players.Push(x);
				}
			}

			while(iDiff > 1 && dead_players.Length) {
				int rnd = GetRandomInt(0, dead_players.Length - 1);
				CS_SwitchTeam(dead_players.Get(rnd), target_team);
				SwitchNotify(target_team, dead_players.Get(rnd));
				dead_players.Erase(rnd);
				iDiff--;
			}

			while(iDiff > 1) {
				int rnd = GetRandomInt(0, mov_players.Length - 1);
				ForcePlayerSuicide(mov_players.Get(rnd) - 1);
				CS_SwitchTeam(mov_players.Get(rnd), target_team);
				SwitchNotify(target_team, mov_players.Get(rnd));
				mov_players.Erase(rnd);
				iDiff--;
			}
		} else if(bMsg) PrintToChatAll("%s\x04Teams are balanced!",CHAT_TAG);
	}
}

int CheckTeamBalance()
{
	static int t_count, ct_count;
	if(-2 < (t_count = GetTeamClientCount(CS_TEAM_T)) - (ct_count = GetTeamClientCount(CS_TEAM_CT)) < 2) return 0;

	if(t_count > ct_count)
	{
		iDiff = t_count - ct_count;
		return CS_TEAM_CT;
	}
	else
	{
		iDiff = ct_count - t_count;
		return CS_TEAM_T;
	}
}

void SwitchNotify(int newteam, int player)
{
	if(bMsg && IsClientConnected(player)) PrintToChatAll("%s\x01moved \x04%N \x01from %s \x01to %s", CHAT_TAG, player, TeamName[newteam == 2 ? 3 : 2], TeamName[newteam]);
}