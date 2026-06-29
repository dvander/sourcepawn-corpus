#include <sourcemod> 
#include <sdktools>

public Plugin:myinfo = { 
    name = "[L4D, L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis", 
    description = "Prevents mission loss until all players have died.", 
    version = "1.5.4", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

new Handle:deathcheck = INVALID_HANDLE;
new Handle:deathcheck_bots = INVALID_HANDLE;

new Handle:director_no_death_check = INVALID_HANDLE;
new Handle:allow_all_bot_survivor_team = INVALID_HANDLE;

new director_no_death_check_default_cvar = 0;
new allow_all_bot_survivor_team_default_cvar = 0;

new bool:Enabled = false;

public OnPluginStart()
{  
	deathcheck = CreateConVar("deathcheck", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	deathcheck_bots = CreateConVar("deathcheck_bots", "1", "0: Mission will be lost if all human players have died, 1: Bots will continue playing after all human players are dead and can rescue them", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	director_no_death_check = FindConVar("director_no_death_check");
	allow_all_bot_survivor_team = FindConVar("allow_all_bot_survivor_team");

	AutoExecConfig(true, "cge_l4d2_deathcheck");
	
	HookConVarChange(deathcheck, ConVarChange_deathcheck);
	HookConVarChange(deathcheck_bots, ConVarChange_deathcheck_bots);
	
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_bot_replace", Event_PlayerBotReplace); 
	HookEvent("bot_player_replace", Event_BotPlayerReplace); 
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
	
	Enabled = false;
}

public OnConfigsExecuted()
{
	director_no_death_check_default_cvar = GetConVarInt(director_no_death_check);
	allow_all_bot_survivor_team_default_cvar = GetConVarInt(allow_all_bot_survivor_team);
}

public ConVarChange_deathcheck(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
    {
        if (strcmp(newValue, "1") == 0)
        {
			//PrintToChatAll("Setting director_no_death_check to 1.");
			SetConVarInt(director_no_death_check, 1);
			if (GetConVarInt(deathcheck_bots) == 1)
			{
				//PrintToChatAll("Setting allow_all_bot_survivor_team to 1.");
				SetConVarInt(allow_all_bot_survivor_team, 1);
			}
			else
			{
				//PrintToChatAll("Resetting allow_all_bot_survivor_team to default value.");
				SetConVarInt(allow_all_bot_survivor_team, allow_all_bot_survivor_team_default_cvar);
			}
		}
        else
		{
			//PrintToChatAll("Resetting director_no_death_check and allow_all_bot_survivor_team to default values.");
			SetConVarInt(director_no_death_check, director_no_death_check_default_cvar);
			SetConVarInt(allow_all_bot_survivor_team, allow_all_bot_survivor_team_default_cvar);
		}
    }
}

public ConVarChange_deathcheck_bots(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(deathcheck) == 1)
	{
		if (strcmp(oldValue, newValue) != 0)
		{
			if (strcmp(newValue, "1") == 0)
			{
				//PrintToChatAll("Setting allow_all_bot_survivor_team to 1.");
				SetConVarInt(allow_all_bot_survivor_team, 1);
			}
			else
			{
				//PrintToChatAll("Resetting allow_all_bot_survivor_team to default value.");
				SetConVarInt(allow_all_bot_survivor_team, allow_all_bot_survivor_team_default_cvar);
			}
		}
	}
}

public OnMapEnd()
{
	if (Enabled == true)
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

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)  
{
	if (Enabled == false)
	{
		if (GetConVarInt(deathcheck) == 1)
		{
			SetConVarInt(director_no_death_check, 1);
			if (GetConVarInt(deathcheck_bots) == 1)
			{
				SetConVarInt(allow_all_bot_survivor_team, 1);
			}
		}
		Enabled = true;
	}
	DeathCheck();
}  

public Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)  
{  
	DeathCheck();
}  

public Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast)  
{  
	DeathCheck();
}  

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)  
{  
	DeathCheck();
}  

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	DeathCheck();
}

DeathCheck()
{
	if (Enabled == true)
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
				survivors ++;
			}
		}
		
		//PrintToChatAll("%i survivors remaining.", survivors);
		
		if (survivors < 1)
		{
			//PrintToChatAll("Everyone is dead. Ending the round.");
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
	if (!client) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetConVarInt(deathcheck_bots) == 0)
	{
		if (IsFakeClient(client)) return false;
	}
	if (!IsPlayerAlive(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}