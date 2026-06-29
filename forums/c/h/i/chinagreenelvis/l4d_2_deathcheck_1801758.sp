#include <sourcemod> 
#include <sdktools>

public Plugin:myinfo = { 
    name = "[L4D, L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis", 
    description = "Prevents mission loss until all players have died.", 
    version = "1.5.0", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

new bool:MissionWillBeLost = false;

new Handle:deathcheck_plugin_enable = INVALID_HANDLE;
new Handle:deathcheck_bots_survive = INVALID_HANDLE;

public OnPluginStart()
{  
	deathcheck_plugin_enable = CreateConVar("deathcheck_plugin_enable", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	deathcheck_bots_survive = CreateConVar("deathcheck_bots_survive", "1", "0: Mission will be lost if all human players have died, 1: Bots will continue playing after all human players are dead and can rescue them", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_2_deathcheck");
	
	if (GetConVarInt(deathcheck_bots_survive) == 1)
	{
		SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
	}
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_start_post_nav", Event_RoundStartPostNav, EventHookMode_Post);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_entered_start_area", Event_PlayerEnteredStartArea, EventHookMode_Post);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	DeathCheck();
}

public OnClientConnected ()
{
	DeathCheck();
}

public OnClientPutInServer ()
{
	DeathCheck();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeathCheck();
}

public Event_RoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
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

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeathCheck();
} 

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeathCheck();
} 

public Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeathCheck();
} 

public Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeathCheck();
} 

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeathCheck();
} 

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = (GetClientOfUserId(GetEventInt(event, "userid")));
	if (client)
	{
		if (IsValidPlayer(client))
		{
			if (MissionWillBeLost == true)
			{
				new oldFlags = GetCommandFlags("scenario_end");
				SetCommandFlags("scenario_end", oldFlags & ~(FCVAR_CHEAT|FCVAR_LAUNCHER));
				ServerCommand("scenario_end");
				ServerExecute();
				SetCommandFlags("scenario_end", oldFlags);
			}
			else
			{
				DeathCheck();
			}
		}
	}
}

DeathCheck()
{
	if (GetConVarInt(deathcheck_plugin_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
		if (GetConVarInt(deathcheck_bots_survive) == 1)
		{
			SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
		}
		else
		{
			ResetConVar(FindConVar("allow_all_bot_survivor_team"));
		}
		new survivors = 0;
		for (new i = 1; i <= MaxClients; i++) 
		{
            if (IsValidSurvivor(i))
			{
				survivors ++;
			}
        }
		//PrintToChatAll("%i survivors remaining.", survivors);
		if (survivors > 1)
		{
			MissionWillBeLost = false;
		}
		if (survivors == 1)
		{
			//PrintToChatAll("The mission will be lost on the next death!");
			MissionWillBeLost = true;
		}
	}
	else
	{
		ResetConVar(FindConVar("director_no_death_check"));
	}
}

stock bool:IsValidPlayer(client)
{
	if (!client) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetConVarInt(deathcheck_bots_survive) == 0)
	{
		if (IsFakeClient(client)) return false;
	}
	if (GetClientTeam(client) != 2) return false;
	return true;
}

stock bool:IsValidSurvivor(client)
{
	if (!client) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetConVarInt(deathcheck_bots_survive) == 0)
	{
		if (IsFakeClient(client)) return false;
	}
	if (!IsPlayerAlive(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}