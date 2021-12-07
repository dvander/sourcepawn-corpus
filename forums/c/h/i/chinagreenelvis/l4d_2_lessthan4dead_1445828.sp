#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.2"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Less Than 4 Dead",
	author = "chinagreenelvis",
	description = "Dynamically change the number of survivors",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1330706"
}

new bool:Enabled = false;
new survivorlimit = 0;
new Handle:TimerPlayerCheck = INVALID_HANDLE;

new Handle:lt4d_minsurvivors = INVALID_HANDLE;
new Handle:lt4d_maxsurvivors = INVALID_HANDLE;
new Handle:lt4d_specials = INVALID_HANDLE;
new Handle:lt4d_specials_boomersenable = INVALID_HANDLE;
new Handle:lt4d_specials_chargersenable = INVALID_HANDLE;
new Handle:lt4d_specials_huntersenable = INVALID_HANDLE;
new Handle:lt4d_specials_jockeysenable = INVALID_HANDLE;
new Handle:lt4d_specials_smokersenable = INVALID_HANDLE;
new Handle:lt4d_specials_spittersenable = INVALID_HANDLE;
new Handle:lt4d_commons = INVALID_HANDLE;
new Handle:lt4d_commons_1player = INVALID_HANDLE;
new Handle:lt4d_commons_2players = INVALID_HANDLE;
new Handle:lt4d_commons_3players = INVALID_HANDLE;
new Handle:lt4d_commons_4players = INVALID_HANDLE;

public OnPluginStart() 
{
	lt4d_minsurvivors = CreateConVar("lt4d_minsurvivors", "1", "Minimum number of survivors to allow (additional slots are filled by bots)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_maxsurvivors = CreateConVar("lt4d_maxsurvivors", "4", "Maximum number of survivors to allow", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_specials = CreateConVar("lt4d_specials", "1", "Allow special infected regulation? 1: Enable, 0: Disable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_boomersenable = CreateConVar("lt4d_specials_boomersenable", "1", "Number of players at which to turn on boomers", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_chargersenable = CreateConVar("lt4d_specials_chargersenable", "4", "Number of players at which to turn on chargers", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_huntersenable = CreateConVar("lt4d_specials_huntersenable", "2", "Number of players at which to turn on hunters", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_jockeysenable = CreateConVar("lt4d_specials_jockeysenable", "3", "Number of players at which to turn on jockeys", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_smokersenable = CreateConVar("lt4d_specials_smokersenable", "2", "Number of players at which to turn on smokers", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_spittersenable = CreateConVar("lt4d_specials_spittersenable", "4", "Number of players at which to turn on spitters", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons = CreateConVar("lt4d_commons", "1", "Allow common infected regulation? 1: Enable, 0: Disable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_1player = CreateConVar("lt4d_commons_1player", "15", "Number of common infected for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_2players = CreateConVar("lt4d_commons_2players", "20", "Number of common infected for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_3players = CreateConVar("lt4d_commons_3players", "25", "Number of common infected for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_4players = CreateConVar("lt4d_commons_4players", "30", "Number of common infected for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_2_lessthan4dead");
	
	SetConVarInt(FindConVar("director_no_survivor_bots"), 1, true, false);
	//SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(lt4d_maxsurvivors), true, false);
	
	new flags = GetConVarFlags(FindConVar("survivor_limit")); 
	if (flags & FCVAR_NOTIFY)
	{ 
		SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
	}
	SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(lt4d_maxsurvivors), true, false);
	survivorlimit = GetConVarInt(FindConVar("survivor_limit"));
	
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	Enabled = false;
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			//PrintToChatAll("Player first spawn.");
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			//PrintToChatAll("Player spawn.");
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

public OnClientConnected(client)
{
	if (!IsFakeClient(client))
	{
		PlayerCheck();
	}
}

public OnClientDisconnect(client)
{
	if (!IsFakeClient(client))
	{
		PlayerCheck();
	}
}

PlayerCheck()
{
	if (Enabled == true)
	{
		if (TimerPlayerCheck == INVALID_HANDLE)
		{
			TimerPlayerCheck = CreateTimer(3.0, Timer_PlayerCheck);
		}
	}
}

public Action:Timer_PlayerCheck(Handle:timer)
{
	//PrintToChatAll("Performing PlayerCheck");
	new maxsurvivors = GetConVarInt(lt4d_maxsurvivors);
	new minsurvivors = GetConVarInt(lt4d_minsurvivors);
	if (minsurvivors > maxsurvivors)
	{
		minsurvivors = maxsurvivors;
	}
	//SetConVarInt(FindConVar("sv_visiblemaxplayers"), maxsurvivors, true, false);
	new players = 0;
	new bots = 0;
	new survivorplayers = 0;
	new idlesurvivors = 0;
	new alivesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i)) 
		{
			players++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
		{
			bots++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			survivorplayers++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") > 0)
		{
			idlesurvivors++;
		}
		if (IsClientConnected(i) && !IsPlayerAlive(i) && GetClientTeam(i) == 2) 
		{
			alivesurvivors++;
		}
	}
	new actualsurvivorplayers = survivorplayers + idlesurvivors;
	new waitingplayers = players - actualsurvivorplayers;
	new shouldbots = minsurvivors - actualsurvivorplayers;
	//PrintToChatAll("Actual players %i", players);
	//PrintToChatAll("Actual survivor players %i", actualsurvivorplayers);
	//PrintToChatAll("Survivor bots %i", bots);
	//PrintToChatAll("Idle survivors %i", idlesurvivors);
	if (shouldbots <= 0)
	{
		shouldbots = waitingplayers;
	}
	survivorlimit = actualsurvivorplayers + shouldbots;
	if (survivorlimit > 0)
	{
		SetConVarInt(FindConVar("survivor_limit"), survivorlimit, true, false);
		if (shouldbots > bots)
		{
			new addbots = shouldbots - bots;
			for (new i = 1; i <= addbots; i++)
			{
				ServerCommand("sb_add");
			}
		}
		if (shouldbots < bots)
		{
			new subtractbots = bots - shouldbots;
			for (new i = 1; i <= subtractbots; i++)
			{
				CreateTimer(3.0, Timer_KickBot);
			}
		}
		if (GetConVarInt(lt4d_specials) > 0)
		{
			new boomersenable = GetConVarInt(lt4d_specials_boomersenable);
			new chargersenable = GetConVarInt(lt4d_specials_chargersenable);
			new huntersenable = GetConVarInt(lt4d_specials_huntersenable);
			new jockeysenable = GetConVarInt(lt4d_specials_jockeysenable);
			new smokersenable = GetConVarInt(lt4d_specials_smokersenable);
			new spittersenable = GetConVarInt(lt4d_specials_spittersenable);
			if (alivesurvivors >= boomersenable)
			{
				SetConVarInt(FindConVar("z_boomer_limit"), 1);
			}
			if (alivesurvivors < boomersenable)
			{
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
			}
			if (alivesurvivors >= chargersenable)
			{
				SetConVarInt(FindConVar("z_charger_limit"), 1);
			}
			if (alivesurvivors < chargersenable)
			{
				SetConVarInt(FindConVar("z_charger_limit"), 0);
			}
			if (alivesurvivors >= huntersenable)
			{
				SetConVarInt(FindConVar("z_hunter_limit"), 1);
			}
			if (alivesurvivors < huntersenable)
			{
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
			}
			if (alivesurvivors >= jockeysenable)
			{
				SetConVarInt(FindConVar("z_jockey_limit"), 1);
			}
			if (alivesurvivors < jockeysenable)
			{
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
			}
			if (alivesurvivors >= smokersenable)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 1);
			}
			if (alivesurvivors < smokersenable)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
			}
			if (alivesurvivors >= spittersenable)
			{
				SetConVarInt(FindConVar("z_spitter_limit"), 1);
			}
			if (alivesurvivors < spittersenable)
			{
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
			}
		}
		if (GetConVarInt(lt4d_commons) > 0)
		{
			if (alivesurvivors == 1)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_1player));
			}
			if (alivesurvivors == 2)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_2players));
			}
			if (alivesurvivors == 3)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_3players));
			}
			if (alivesurvivors >= 4)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_4players));
			}
		}
	}
	if (survivorlimit == 0)
	{
		SetConVarInt(FindConVar("survivor_limit"), maxsurvivors, true, false);
		if (Enabled == true)
		{
			Enabled = false;
		}
	}
	if (TimerPlayerCheck != INVALID_HANDLE)
	{
		TimerPlayerCheck = INVALID_HANDLE;
	}
}

public Action:Timer_KickBot(Handle:timer)
{	
	//PrintToChatAll("A bot should be about to be kicked.")
	new bool:ABotHasBeenKicked = false;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (ABotHasBeenKicked == false)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) 
			{ 
				//PrintToChatAll("A bot is very likely about to be kicked.")
				if (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
				{
					//PrintToChatAll("A bot is definitely about to be kicked.")
					if (IsPlayerAlive(i))
					{
						ForcePlayerSuicide(i);
					}
					KickClient(i);
					ABotHasBeenKicked = true;
				}
			}
		}
	}
}
