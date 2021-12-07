#include <sourcemod>
#include <cstrike>

new Float:endRoundDelay = 5.0;

public Plugin:myinfo = 
{
    name = "End Round Stopper",
    author = "black_star",
    description = "Prevents the round from ending until one of the team is eliminated (requires mp_ignore_round_win_conditions 1)",
    version = "1.0",
    url = ""
}

public OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeathOrDisconnect);
	HookEvent("player_disconnect", OnPlayerDeathOrDisconnect);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	ServerCommand("mp_ignore_round_win_conditions 1");
}

public OnConfigsExecuted()
{
	endRoundDelay = GetConVarFloat(FindConVar("mp_round_restart_delay"));
	ServerCommand("mp_ignore_round_win_conditions 1");
}

public OnPlayerDeathOrDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(TeamHasPlayers(CS_TEAM_CT) && !TeamHasPlayersAlive(CS_TEAM_CT))
	{
		CS_TerminateRound(endRoundDelay, CSRoundEnd_TerroristWin, false);
	}
	else if(TeamHasPlayers(CS_TEAM_T) && !TeamHasPlayersAlive(CS_TEAM_T))
	{
		CS_TerminateRound(endRoundDelay, CSRoundEnd_CTWin, false);
	}
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
    {
		return Plugin_Continue;
	}
	
	decl String:team[2];
	GetCmdArg(1, team, sizeof(team));
	new targetTeam = StringToInt(team);
	if( (targetTeam == CS_TEAM_CT && !TeamHasPlayers(CS_TEAM_CT)) || (targetTeam == CS_TEAM_T && !TeamHasPlayers(CS_TEAM_T)) )
	{	
		ServerCommand("mp_restartgame 1");
	}
	return Plugin_Continue;
}

public TeamHasPlayers(iTeam)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == iTeam))
		{
			return true;
		}
	}
	return false;
}

stock TeamHasPlayersAlive(iTeam)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == iTeam) && IsPlayerAlive(i))
		{
			return true;
		}
	}
	return false;
}