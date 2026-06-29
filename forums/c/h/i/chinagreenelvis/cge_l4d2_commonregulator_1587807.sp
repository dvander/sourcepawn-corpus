#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.1"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Common Infected Regulator",
	author = "chinagreenelvis",
	description = "Decrease or increase infected numbers based on number of living survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

new bool:Enabled = false;
new survivors = 0;

new Handle:commonregulator = INVALID_HANDLE;
new Handle:commonregulator_commons = INVALID_HANDLE;
new Handle:commonregulator_commons_background = INVALID_HANDLE;
new Handle:commonregulator_megamob = INVALID_HANDLE;
new Handle:commonregulator_mobmin = INVALID_HANDLE;
new Handle:commonregulator_mobmax = INVALID_HANDLE;

public OnPluginStart() 
{
	commonregulator = CreateConVar("commonregulator", "1", "Allow common infected regulation? 1: Yes, 0: No", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	commonregulator_commons = CreateConVar("commonregulator_commons", "30", "Common infected limit for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	commonregulator_commons_background = CreateConVar("commonregulator_commons_background", "20", "Background number of common infected for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	commonregulator_megamob = CreateConVar("commonregulator_megamob", "50", "Mega-mob size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY)
	commonregulator_mobmin = CreateConVar("commonregulator_mobmin", "10", "Minimum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	commonregulator_mobmax = CreateConVar("commonregulator_mobmax", "30", "Maximum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "cge_l4d2_commonregulator");

	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("mission_lost", Event_MissionLost);
	
	Enabled = false;
}

public OnMapEnd()
{
	if (Enabled == true)
	{
		Enabled = false;
	}
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(commonregulator) == 1 && Enabled == false)
		{
			Enabled = true;
			CreateTimer(3.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(commonregulator) == 1 && Enabled == false)
		{
			Enabled = true;
			CreateTimer(3.0, Timer_DifficultySet);
		}
		if (GetConVarInt(commonregulator) == 1 && Enabled == true)
		{
			CreateTimer(3.0, Timer_DifficultyCheck);
		}
	}
}

public Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultySet);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultyCheck);
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultyCheck);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultyCheck);
}

public Action:Timer_DifficultySet(Handle:timer)
{
	if (GetConVarInt(commonregulator) == 1)
	{
		//PrintToServer("DifficultySet");
		survivors = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(i)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					survivors++;
				}
			}
		}
		//PrintToServer("Survivors %i", survivors);
		if (survivors)
		{
			SetDifficulty();
			CreateTimer(5.0, Timer_Enable);
		}
		else
		{
			CreateTimer(3.0, Timer_DifficultySet);
		}
	}
}

public Action:Timer_Enable(Handle:timer)
{
	if (Enabled == false)
	{
		Enabled = true;
	}
}

public Action:Timer_DifficultyCheck(Handle:timer)
{
	if (GetConVarInt(commonregulator) == 1 && Enabled == true)
	{
		//PrintToServer("DifficultyCheck");
		new alivesurvivors = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(i)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2) 
				{
					if (IsPlayerAlive(i))
					{
						alivesurvivors++;
					}
				}
			}
		}
		//PrintToServer("Alive survivors %i", alivesurvivors);
		if (alivesurvivors)
		{
			survivors = alivesurvivors;
			SetDifficulty();
		}
		else
		{
			CreateTimer(3.0, Timer_DifficultySet);
		}
	}
}

SetDifficulty()
{
	//PrintToServer("Setting commons for %i players.", survivors);
	
	new commonlimit = survivors * RoundToCeil(float((GetConVarInt(commonregulator_commons)) / 4));
	new backgroundlimit = survivors * RoundToCeil(float((GetConVarInt(commonregulator_commons_background)) / 4));
	new megamobsize = survivors * RoundToCeil(float((GetConVarInt(commonregulator_megamob)) / 4));
	new mobminnotify = survivors * RoundToCeil(float((GetConVarInt(commonregulator_mobmin)) / 4));
	new mobminsize = survivors * RoundToCeil(float((GetConVarInt(commonregulator_mobmin)) / 4));
	new mobmaxsize = survivors * RoundToCeil(float((GetConVarInt(commonregulator_mobmax)) / 4));
	
	SetConVarInt(FindConVar("z_common_limit"), commonlimit);
	SetConVarInt(FindConVar("z_background_limit"), backgroundlimit);
	SetConVarInt(FindConVar("z_mega_mob_size"), megamobsize);
	SetConVarInt(FindConVar("z_mob_min_notify_count"), mobminnotify);
	SetConVarInt(FindConVar("z_mob_spawn_min_size"), mobminsize);
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), mobmaxsize);
}
