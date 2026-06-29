#include <sourcemod> 
#include <sdktools>

public Plugin:myinfo = { 
    name = "[L4D, L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis", 
    description = "Prevents mission loss until all human players have died.", 
    version = "1.4.7", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

new L4D2Version=false;

new bool:MissionWillBeLost[MAXPLAYERS+1];
new bool:CanTriggerCheck[MAXPLAYERS+1];

new Handle:deathcheck_enable = INVALID_HANDLE;
new Handle:deathcheck_bots = INVALID_HANDLE;

public OnPluginStart()
{  
	deathcheck_enable = CreateConVar("deathcheck_enable", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	deathcheck_bots = CreateConVar("deathcheck_bots", "1", "0: Bots and idle players are treated as human non-idle players, 1: Mission will be lost if there are still survivor bots/idle players but no living non-idle humans", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_2_deathcheck");
	
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
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
		
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated); 
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("tongue_grab", Event_ToungeGrab);
	if(L4D2Version)
	{
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("charger_pummel_start", Event_ChargerPummelStart);
	}
}

public OnMapStart()
{
	DeadCheck();
}

public OnClientConnected ()
{
	DeadCheck();
}

public OnClientPutInServer ()
{
	DeadCheck();
}

public OnClientDisconnect (client)
{
	if (MissionWillBeLost[client] == true)
	{ 
		SetConVarInt(FindConVar("director_no_death_check"), 0);
		//ResetConVar(FindConVar("director_no_death_check"), true, true); 
		//PrintToChatAll("The mission was lost!");
	} 
	else if (GetConVarInt(deathcheck_enable) == 1)
	{ 
		DeadCheck();
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 0);
	}
	DeadCheck();
} 

public Event_RoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
}

public Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
} 

public Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
} 

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
} 

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
} 

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
} 

public Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
} 

public Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	DeadCheck();
} 

public Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
} 

public Event_PlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_LungePounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_ToungeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_ChargerPummelStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (MissionWillBeLost[GetClientOfUserId(GetEventInt(event, "userid"))] == true)
	{ 
		SetConVarInt(FindConVar("director_no_death_check"), 0);
		//ResetConVar(FindConVar("director_no_death_check"), true, true); 
		//PrintToChatAll("The mission was lost!");
	} 
	else if (GetConVarInt(deathcheck_enable) == 1)
	{ 
		DeadCheck();
	}
} 

DeadCheck()
{
	if (GetConVarInt(deathcheck_enable) == 1)
	{
		new survivors = 0; 
		for (new i = 1; i <= MaxClients; i++) 
		{ 
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) 
			{ 
				if (GetConVarInt(deathcheck_bots) == 1)
				{
					if (!IsFakeClient(i))
					{
						survivors++;
						CanTriggerCheck[i] = true;
					}
				}
				else
				{
					survivors++;
					CanTriggerCheck[i] = true;
				}
			}
			else
			{
				CanTriggerCheck[i] = false;
				MissionWillBeLost[i] = false;
			}
		}
		//PrintToChatAll("%i survivors remaining.", survivors);
		if (survivors == 1)
		{ 
			for(new i = 1; i <= MaxClients; i++)
			{
				if (CanTriggerCheck[i] == true)
				{
					MissionWillBeLost[i] = true;
				}
			}
		}
		if (survivors > 1)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if (CanTriggerCheck[i] == true)
				{
					MissionWillBeLost[i] = false;
				}
			}
		}
	}
}