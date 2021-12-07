#include <sourcemod> 
#include <sdktools>

public Plugin:myinfo = { 
    name = "[L4D] & [L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis", 
    description = "Prevents mission loss until all human players have died.", 
    version = "1.4.5", 
    url = "http://www.chinagreenelvis.com" 
}; 

new L4D2Version=false;

new bool:MissionWillBeLost[MAXPLAYERS+1];
new bool:CanTriggerCheck[MAXPLAYERS+1];
new bool:CanTriggerCheckFake[MAXPLAYERS+1];

public OnPluginStart()
{  
	CreateConVar("l4d_2_deathcheck_enable", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("l4d_2_deathcheck_bots", "1", "0: Bots and idle players are treated as human non-idle players, 1: Mission will be lost if there are still survivor bots/idle players but no living non-idle humans", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_2_deathcheck");
	
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
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

public OnClientDisconnect ()
{
	DeadCheck();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
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
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
} 

public Event_PlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_LungePounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_ToungeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
	{
		SetConVarInt(FindConVar("director_no_death_check"), 1);
	}
	DeadCheck();
}

public Event_ChargerPummelStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
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
	else if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
	{ 
		DeadCheck();
	}
} 

DeadCheck()
{
	if (GetConVarInt(FindConVar("l4d_2_deathcheck_enable")) == 1)
	{
		new survivors = 0; 
		new fakesurvivors = 0;
		for(new i = 1; i <= MaxClients; i++) 
		{ 
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) 
			{ 
				if (GetConVarInt(FindConVar("l4d_2_deathcheck_bots")) == 1 && !IsFakeClient(i))
				{
					survivors++;
					CanTriggerCheck[i] = true;
					CanTriggerCheckFake[i] = true;
				}
				else if (GetConVarInt(FindConVar("l4d_2_deathcheck_bots")) == 1 && IsFakeClient(i))
				{
					fakesurvivors++;
					CanTriggerCheckFake[i] = true;
				}
				else if (GetConVarInt(FindConVar("l4d_2_deathcheck_bots")) == 0)
				{
					survivors++;
					CanTriggerCheck[i] = true;
					CanTriggerCheckFake[i] = false;
				}
			}
			else
			{
				CanTriggerCheck[i] = false;
				CanTriggerCheckFake[i] = false;
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
		if (survivors == 0 && fakesurvivors > 0)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if (CanTriggerCheckFake[i] == true)
				{
					MissionWillBeLost[i] = true;
					ForcePlayerSuicide(i);
				}
			}
		}
	}
}