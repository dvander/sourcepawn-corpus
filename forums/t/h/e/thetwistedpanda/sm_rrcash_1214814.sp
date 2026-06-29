#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new Handle:p_Enabled = INVALID_HANDLE;
new Handle:p_Amount = INVALID_HANDLE;
new Handle:p_Loss = INVALID_HANDLE;
new Handle:p_Time = INVALID_HANDLE;

enum RallyCash
{
	totalCash = 0,
	totalReward = 0,
	Handle:rewardTimer = INVALID_HANDLE
}

new p_Players[MAXPLAYERS + 1][RallyCash];

public Plugin:myinfo = 
{
	name = "Rally Racing Cash",
	author = "Twisted|Panda",
	description = "Manages cash for Rally Racing. Players receive x amount of cash per race and it decreases over time.",
	version = PLUGIN_VERSION,
	url = "http://alliedmods.net/"
};

public OnPluginStart() 
{ 
	CreateConVar("sm_rrcash_version", PLUGIN_VERSION, "Rally Racing Cash Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	p_Enabled = CreateConVar("sm_rrcash", "1", "Enables or disables any feature of this plugin.");
	p_Amount = CreateConVar("sm_rrcash_cash", "180", "The amount of cash players will receive per each race.");
	p_Loss = CreateConVar("sm_rrcash_loss", "1", "The amount of cash players lose per sm_rrcash_time.");
	p_Time = CreateConVar("sm_rrcash_time", "1.0", "The delay, in seconds, between each deduction of sm_rrcash_loss. 0 to disable.");
	AutoExecConfig(true, "sm_rrcash");

	HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);
	RegConsoleCmd("kill", Command_Kill);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(p_Players[i][rewardTimer] != INVALID_HANDLE)
			{
				KillTimer(p_Players[i][rewardTimer]);
				p_Players[i][rewardTimer] = INVALID_HANDLE;
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(GetConVarInt(p_Enabled))
	{
		p_Players[client][totalCash] = 0;
		p_Players[client][totalReward] = 0;
		p_Players[client][rewardTimer] = INVALID_HANDLE;
	}
}

public OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(p_Enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return;

		new newTeam = GetEventInt(event, "team");
		//If the player is moved to the racing team, start their timer.
		if(newTeam == 3)
		{
			p_Players[client][totalReward] = GetConVarInt(p_Amount);
			p_Players[client][rewardTimer] = CreateTimer(GetConVarFloat(p_Time), decreaseReward, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		new oldTeam = GetEventInt(event, "oldteam");
		//Once the player is moved back to the racing team, give the player his/her reward.
		if(newTeam == 2 && oldTeam == 3)
		{
			new original = p_Players[client][totalCash];
			new reward = p_Players[client][totalReward];
			if(reward < 0)
				reward = 0;

			SetEntProp(client, Prop_Send, "m_iAccount", (reward + original));
		}
	}
}

public Action:decreaseReward(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	else
	{
		new clientTeam = GetClientTeam(client);
		if(clientTeam == 2)
			return Plugin_Stop;
		else
		{
			p_Players[client][totalReward] -= GetConVarInt(p_Loss);
			return Plugin_Continue;
		}
	}
}

public Action:Command_Kill(client, args)
{
	if(GetConVarInt(p_Enabled))
	{
		p_Players[client][totalReward] = 0;
		if(p_Players[client][rewardTimer] != INVALID_HANDLE)
		{
			KillTimer(p_Players[client][rewardTimer]);
			p_Players[client][rewardTimer] = INVALID_HANDLE;
		}
	}

	return Plugin_Continue;
}