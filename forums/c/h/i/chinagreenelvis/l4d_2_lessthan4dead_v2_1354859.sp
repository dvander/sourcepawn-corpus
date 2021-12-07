#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.1"

public Plugin:myinfo = 
{
	name = "L4D/L4D2 Less Than 4 Dead (v2)",
	author = "chinagreenelvis",
	description = "Play with less than 4 survivors in multiplayer",
	version = PLUGIN_VERSION,
	url = "http://www.chinagreenelvis.com"
}

new bool:GameStarted = false;
new bool:Enabled = false;

new survivorlimit = 0;

new Handle:MinSurvivors = INVALID_HANDLE;
new Handle:MaxSurvivors = INVALID_HANDLE;
new Handle:SpecialsRegulator = INVALID_HANDLE;
new Handle:BoomersEnable = INVALID_HANDLE;
new Handle:ChargersEnable = INVALID_HANDLE;
new Handle:HuntersEnable = INVALID_HANDLE;
new Handle:JockeysEnable = INVALID_HANDLE;
new Handle:SmokersEnable = INVALID_HANDLE;
new Handle:SpittersEnable = INVALID_HANDLE;
new Handle:CommonsRegulator = INVALID_HANDLE;
new Handle:CommonsOnePlayer = INVALID_HANDLE;
new Handle:CommonsTwoPlayers = INVALID_HANDLE;
new Handle:CommonsThreePlayers = INVALID_HANDLE;
new Handle:CommonsFourPlayers = INVALID_HANDLE;

public OnPluginStart() 
{
	MinSurvivors = CreateConVar("l4d_2_lessthan4dead_v2_minsurvivors", "1", "Minimum number of survivors to allow (additional slots are filled by bots)", FCVAR_PLUGIN);
	MaxSurvivors = CreateConVar("l4d_2_lessthan4dead_v2_maxsurvivors", "4", "Maximum number of survivors to allow", FCVAR_PLUGIN);
	
	SpecialsRegulator = CreateConVar("l4d_2_lessthan4dead_v2_specialregulator", "1", "Allow special infected regulation? 1: Enable, 0: Disable", FCVAR_PLUGIN);
	BoomersEnable = CreateConVar("l4d_2_lessthan4dead_v2_boomersenable", "1", "Number of players at which to turn on boomers", FCVAR_PLUGIN);
	ChargersEnable = CreateConVar("l4d_2_lessthan4dead_v2_chargersenable", "4", "Number of players at which to turn on chargers", FCVAR_PLUGIN);
	HuntersEnable = CreateConVar("l4d_2_lessthan4dead_v2_huntersenable", "2", "Number of players at which to turn on hunters", FCVAR_PLUGIN);
	JockeysEnable = CreateConVar("l4d_2_lessthan4dead_v2_jockeysenable", "3", "Number of players at which to turn on jockeys", FCVAR_PLUGIN);
	SmokersEnable = CreateConVar("l4d_2_lessthan4dead_v2_smokersenable", "2", "Number of players at which to turn on smokers", FCVAR_PLUGIN);
	SpittersEnable = CreateConVar("l4d_2_lessthan4dead_v2_spittersenable", "4", "Number of players at which to turn on spitters", FCVAR_PLUGIN);
	
	CommonsRegulator = CreateConVar("l4d_2_lessthan4dead_v2_commonsregulator", "1", "Allow common infected regulation? 1: Enable, 0: Disable", FCVAR_PLUGIN);
	CommonsOnePlayer = CreateConVar("l4d_2_lessthan4dead_v2_commonsoneplayer", "10", "Number of common infected for one player", FCVAR_PLUGIN);
	CommonsTwoPlayers = CreateConVar("l4d_2_lessthan4dead_v2_commonstwoplayers", "20", "Number of common infected for two players", FCVAR_PLUGIN);
	CommonsThreePlayers = CreateConVar("l4d_2_lessthan4dead_v2_commonsthreeplayers", "30", "Number of common infected for three players", FCVAR_PLUGIN);
	CommonsFourPlayers = CreateConVar("l4d_2_lessthan4dead_v2_commonsfourplayers", "40", "Number of common infected for four players", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "l4d_2_lessthan4dead_v2");
	
	SetConVarInt(FindConVar("director_no_survivor_bots"), 1, true, false);
	//SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(MaxSurvivors), true, false);
	
	new flags = GetConVarFlags(FindConVar("survivor_limit")); 
	if (flags & FCVAR_NOTIFY)
	{ 
		SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
	}
	SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(MaxSurvivors), true, false);
	
	survivorlimit = GetConVarInt(FindConVar("survivor_limit"));
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundStart);
	HookEvent("player_activate", Event_PlayerActivate);
	HookEvent("player_team", Event_PlayerTeam);
}

public OnMapStart()
{
	if (GameStarted == false)
	{
		GameStarted = true;
		if (Enabled == false)
		{
			//PrintToChatAll("Disabled! Enabling.");
			CreateTimer(20.0, Timer_Enable);
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(SpecialsRegulator) > 0)
	{
		SetConVarInt(FindConVar("z_boomer_limit"), 1);
		SetConVarInt(FindConVar("z_charger_limit"), 1);
		SetConVarInt(FindConVar("z_hunter_limit"), 1);
		SetConVarInt(FindConVar("z_jockey_limit"), 1);
		SetConVarInt(FindConVar("z_smoker_limit"), 1);
		SetConVarInt(FindConVar("z_spitter_limit"), 1);
	}
	if (GameStarted == true)
	{
		if (Enabled == false)
		{
			//PrintToChatAll("Disabled! Enabling.");
			CreateTimer(10.0, Timer_Enable);
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Enabled == true)
	{
		//PrintToChatAll("Disabling!");
		Enabled = false;
	}
	if (GetConVarInt(SpecialsRegulator) > 0)
	{
		SetConVarInt(FindConVar("z_boomer_limit"), 1);
		SetConVarInt(FindConVar("z_charger_limit"), 1);
		SetConVarInt(FindConVar("z_hunter_limit"), 1);
		SetConVarInt(FindConVar("z_jockey_limit"), 1);
		SetConVarInt(FindConVar("z_smoker_limit"), 1);
		SetConVarInt(FindConVar("z_spitter_limit"), 1);
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

public Event_PlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("PlayerActivate");
	PlayerCheck();
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("PlayerTeam");
	PlayerCheck();
}

public Action:Timer_Enable(Handle:timer)
{
	if (Enabled == false)
	{
		//PrintToChatAll("Timer enabled!")
		Enabled = true;
	}
	PlayerCheck();
}

PlayerCheck()
{
	if (Enabled == true)
	{
		CreateTimer(1.0, Timer_PlayerCheck);
	}
}

public Action:Timer_PlayerCheck(Handle:timer)
{
	//PrintToChatAll("Performing PlayerCheck");
	new maxsurvivors = GetConVarInt(MaxSurvivors);
	new minsurvivors = GetConVarInt(MinSurvivors);
	if (minsurvivors > maxsurvivors)
	{
		minsurvivors = maxsurvivors;
	}
	//SetConVarInt(FindConVar("sv_visiblemaxplayers"), maxsurvivors, true, false);
	new players = 0;
	new bots = 0;
	new survivorplayers = 0;
	new idlesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i)) 
		{
			players++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) != 3 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
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
		if (GetConVarInt(SpecialsRegulator) > 0)
		{
			new boomersenable = GetConVarInt(BoomersEnable);
			new chargersenable = GetConVarInt(ChargersEnable);
			new huntersenable = GetConVarInt(HuntersEnable);
			new jockeysenable = GetConVarInt(JockeysEnable);
			new smokersenable = GetConVarInt(SmokersEnable);
			new spittersenable = GetConVarInt(SpittersEnable);
			if (survivorlimit >= boomersenable)
			{
				SetConVarInt(FindConVar("z_boomer_limit"), 1);
			}
			if (survivorlimit < boomersenable)
			{
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
			}
			if (survivorlimit >= chargersenable)
			{
				SetConVarInt(FindConVar("z_charger_limit"), 1);
			}
			if (survivorlimit < chargersenable)
			{
				SetConVarInt(FindConVar("z_charger_limit"), 0);
			}
			if (survivorlimit >= huntersenable)
			{
				SetConVarInt(FindConVar("z_hunter_limit"), 1);
			}
			if (survivorlimit < huntersenable)
			{
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
			}
			if (survivorlimit >= jockeysenable)
			{
				SetConVarInt(FindConVar("z_jockey_limit"), 1);
			}
			if (survivorlimit < jockeysenable)
			{
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
			}
			if (survivorlimit >= smokersenable)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 1);
			}
			if (survivorlimit < smokersenable)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
			}
			if (survivorlimit >= spittersenable)
			{
				SetConVarInt(FindConVar("z_spitter_limit"), 1);
			}
			if (survivorlimit < spittersenable)
			{
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
			}
		}
		if (GetConVarInt(CommonsRegulator) > 0)
		{
			if (survivorlimit == 1)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(CommonsOnePlayer));
			}
			if (survivorlimit == 2)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(CommonsTwoPlayers));
			}
			if (survivorlimit == 3)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(CommonsThreePlayers));
			}
			if (survivorlimit == 4)
			{
				SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(CommonsFourPlayers));
			}
		}
	}
	if (survivorlimit <= 0)
	{
		SetConVarInt(FindConVar("survivor_limit"), maxsurvivors, true, false);
		if (Enabled == true)
		{
			GameStarted = false;
			Enabled = false;
		}
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
