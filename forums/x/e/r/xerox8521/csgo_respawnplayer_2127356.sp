#include <sourcemod>
#include <cstrike>

#define VERSION "1.0"

new Team[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "[CSGO] Respawn on connect",
	author = "XeroX",
	description = "Allows Players to join the round when it already started",
	version = VERSION,
	url = "http://sammys-zps.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_respawn",CommandRespawn,ADMFLAG_ROOT,"Respawns a player");
	CreateConVar("sm_respawn_version",VERSION,"Version of this Plugin",FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	HookEvent("player_team",EventPlayerChangeTeam);
	LoadTranslations("common.phrases");
}


public OnClientConnected(client)
{
	Team[client] = 0;
}
public OnClientPutInServer(client)
{
	if(!IsPlayerAlive(client))
	{
		if(Team[client] == 0)
		{
			new rnd = GetRandomInt(2,3);
			CS_SwitchTeam(client,rnd);
			CS_RespawnPlayer(client);
		}
		else if(GetClientTeam(client) != Team[client])
		{
			CS_SwitchTeam(client,Team[client]);
			CS_RespawnPlayer(client);
		}
	}
}

public Action:EventPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new team = GetEventInt(event,"team");
	if(team == 2 || team == 3) // Only Respawn if player has chosen a Team to play on
	{
		if(!IsPlayerAlive(client))
		{
			Team[client] = team;
			CS_RespawnPlayer(client);
		}
	}
}

public Action:CommandRespawn(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client,"[SM]: Usage: sm_respawn client teamindex (2 = T | 3 = CT) optional");
		return Plugin_Handled;
	}
	else
	{
		new String:arg1[32];
		GetCmdArg(0,arg1,sizeof(arg1));
		new target = FindTarget(client,arg1,true,false);
		if(target == -1)
		{
			return Plugin_Handled;
		}
		if(IsPlayerAlive(target))
		{
			ReplyToCommand(client,"[SM]: %N is alive",target);
			return Plugin_Handled;
		}
		if(args == 1)
		{
			new rnd = GetRandomInt(2,3);
			CS_SwitchTeam(client,rnd);
			CS_RespawnPlayer(client);
			PrintToChat(client,"[SM]: You have respawned: %N",target);
		}
		else if(args >= 2)
		{
			new String:arg2[32];
			GetCmdArg(1,arg2,sizeof(arg2));
			new teamindex = StringToInt(arg2);
			if(teamindex < 2 || teamindex > 3)
			{
				ReplyToCommand(client,"[SM]: Valid team index: 2 = T | 3 = CT");
				return Plugin_Handled;
			}
			else
			{
				CS_SwitchTeam(target,teamindex);
				CS_RespawnPlayer(target);
				PrintToChat(client,"[SM]: You have respawned: %N on Team: %s",target, (teamindex == 2) ? "Terrorist" : "Counter-Terrorist");
			}
		}
		
	}
	return Plugin_Handled;
}
