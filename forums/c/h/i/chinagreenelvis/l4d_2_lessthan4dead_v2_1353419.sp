#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.3"

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

public OnPluginStart() 
{
	MinSurvivors = CreateConVar("l4d_2_lessthan4dead_v2_minsurvivors", "1", "Minimum number of survivors to allow", FCVAR_PLUGIN);
	MaxSurvivors = CreateConVar("l4d_2_lessthan4dead_v2_maxsurvivors", "4", "Maximum number of survivors to allow (additional plugins required for more than 4 players)", FCVAR_PLUGIN);
	
	SetConVarInt(FindConVar("director_no_survivor_bots"), 1, true, false);
	SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(MaxSurvivors), true, false);
	
	new flags = GetConVarFlags(FindConVar("survivor_limit")); 
	if (flags & FCVAR_NOTIFY)
	{ 
		SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
	}
	SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(MaxSurvivors), true, false);
	
	survivorlimit = GetConVarInt(FindConVar("survivor_limit"));
	
	HookEvent("player_entered_start_area", Event_PlayerEnteredStartArea);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundStart);
	HookEvent("player_activate", Event_PlayerActivate);
	HookEvent("player_team", Event_PlayerTeam);
}

public Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (!IsFakeClient(client))
	{
		//PrintToChatAll("Player entered start area.");
		if (GameStarted == false)
		{
			GameStarted = true;
			if (Enabled == false)
			{
				//PrintToChatAll("Disabled! Enabling.");
				CreateTimer(40.0, Timer_Enable);
			}
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameStarted == true)
	{
		if (Enabled == false)
		{
			//PrintToChatAll("Disabled! Enabling.");
			CreateTimer(40.0, Timer_Enable);
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
}

public OnClientPutInServer(client)
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
	SetConVarInt(FindConVar("sv_visiblemaxplayers"), maxsurvivors, true, false);
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
