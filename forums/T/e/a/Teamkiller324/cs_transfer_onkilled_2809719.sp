#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
#include <cstrike>

public Plugin myinfo =
{
	name = "Transfer player onto terrorist team on frag.",
	author = "Teamkiller324, shebzftw(requester)",
	description = "When fragged, tranfers the player onto terrorist team.",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=343800"
}

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
}

void OnPlayerDeath(Event event, const char[] event_name, bool dontBroadcast)
{
	int attacker = event.GetInt("attacker"); // the fragger.
	int userid = event.GetInt("userid"); // the fragged player.
	if(attacker < 1
	|| userid < 1
	|| attacker == userid)
	{
		return;
	}
	
	// check if valid frag event.
	int fragger;
	if(!IsValidClient((fragger = GetClientOfUserId(attacker))))
	{
		return;
	}
	
	int client;
	if(IsValidClient((client = GetClientOfUserId(userid))))
	{
		// check if the frag event was a teamkill.
		int team;
		if((team = GetClientTeam(client)) != GetClientTeam(fragger))
		{
			if(team == CS_TEAM_CT)
			{
				CreateTimer(0.151257512585125, Timer_Transfer, userid); // delayed, to ensure avoiding rare client crash related to source spaghetti.
			}
		}
	}
}

Action Timer_Transfer(Handle timer, int userid)
{
	int client;
	if(IsValidClient((client = GetClientOfUserId(userid))))
	{
		ChangeClientTeam(client, CS_TEAM_T);
		CS_RespawnPlayer(client);
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if(client < 1 || client > MAXPLAYERS)
	{
		return false;
	}
	
	if(!IsClientConnected(client))
	{
		return false;
	}
	
	if(!IsClientInGame(client))
	{
		return false;
	}
	
	if(IsClientSourceTV(client))
	{
		return false;
	}
	
	if(IsClientReplay(client))
	{
		return false;
	}
	
	return true;
}