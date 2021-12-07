#pragma semicolon 1
#include <sourcemod> 
#include <sdktools>

public Plugin:myinfo =
{ 
    name = "[L4D2] Death Check Fix", 
    author = "chinagreenelvis", 
    description = "Fixes Bug About Death Checks.", 
    version = "1.5.6", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

new Handle:deathcheck = INVALID_HANDLE;
new bool:Enabled = false;

public OnPluginStart()
{  
	deathcheck = CreateConVar("death_check_fix-l4d2_on", "1", "Enable/Disable Plugin", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "death_check_fix-l4d2");
	
	HookConVarChange(deathcheck, ConVarChange_deathcheck);
	
	HookEvent("player_first_spawn", OnFixOngoing);
	HookEvent("player_spawn", OnFixOngoing);
	HookEvent("player_bot_replace", OnFixStart); 
	HookEvent("bot_player_replace", OnFixStart); 
	HookEvent("player_team", OnFixStart);
	HookEvent("player_death", OnFixStart);
	
	Enabled = false;
}

public ConVarChange_deathcheck(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
    {
        if (strcmp(newValue, "1") == 0)
        {
			SetConVarInt(FindConVar("director_no_death_check"), 1);
		}
    }
}

public OnMapEnd()
{
	if (Enabled)
	{
		Enabled = false;
	}
}

public OnClientDisconnect()
{ 
	DeathCheck();
}

public OnClientDisconnect_Post()
{
	DeathCheck();
}

public Action:OnFixOngoing(Handle:event, const String:name[], bool:dontBroadcast)  
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (!Enabled)
		{
			if (GetConVarInt(deathcheck) == 1)
			{
				SetConVarInt(FindConVar("director_no_death_check"), 1);
			}
			Enabled = true;
		}
	}
} 

public Action:OnFixStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	DeathCheck();
}

DeathCheck()
{
	if (Enabled)
	{
		CreateTimer(3.0, Timer_DeathCheck);
	}
}

public Action:Timer_DeathCheck(Handle:timer)
{
	if (GetConVarInt(deathcheck) == 1)
	{
		new survivors = 0;
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsValidSurvivor(i))
			{
				survivors++;
			}
		}
		if (survivors < 1)
		{
			new oldFlags = GetCommandFlags("scenario_end");
			SetCommandFlags("scenario_end", oldFlags & ~(FCVAR_CHEAT|FCVAR_LAUNCHER));
			ServerCommand("scenario_end");
			ServerExecute();
			SetCommandFlags("scenario_end", oldFlags);
		}
	}
}

stock bool:IsValidSurvivor(client)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		return false;
	}
	
	return true;
}

