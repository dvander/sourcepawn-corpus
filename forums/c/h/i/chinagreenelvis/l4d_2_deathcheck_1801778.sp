#include <sourcemod> 
#include <sdktools>

public Plugin:myinfo = { 
    name = "[L4D, L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis", 
    description = "Prevents mission loss until all players have died.", 
    version = "1.5.1", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

new Handle:deathcheck_plugin_enable = INVALID_HANDLE;
new Handle:deathcheck_bots_survive = INVALID_HANDLE;

public OnPluginStart()
{  
	deathcheck_plugin_enable = CreateConVar("deathcheck_plugin_enable", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	deathcheck_bots_survive = CreateConVar("deathcheck_bots_survive", "1", "0: Mission will be lost if all human players have died, 1: Bots will continue playing after all human players are dead and can rescue them", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_2_deathcheck");
	
	if (GetConVarInt(deathcheck_plugin_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
		if (GetConVarInt(deathcheck_bots_survive) == 1)
		{
			SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
		}
	}
	HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	DeathCheck();
}

DeathCheck()
{
	if (GetConVarInt(deathcheck_plugin_enable) == 1)
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
	if (GetConVarInt(deathcheck_bots_survive) == 0)
	{
		if (IsFakeClient(client)) return false;
	}
	if (!IsPlayerAlive(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}