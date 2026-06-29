#include <sourcemod> 

public Plugin:myinfo = { 
    name = "[L4D] & [L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis", 
    description = "Prevents mission loss until all human players have died.", 
    version = "1.4.2", 
    url = "http://www.chinagreenelvis.com" 
}; 

new L4D2Version=false;

new bool:MissionWillBeLost = false;
new bool:CanTriggerDeathCheck[MAXPLAYERS+1];

public OnPluginStart()
{  
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	
	CreateConVar("l4d_2_deathcheck_enable", "1", "1: Enable plugin, 2: Disable plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("l4d_2_deathcheck_bots", "1", "1: Mission will be lost if there are still survivor bots/idle players but no living non-idle humans, 2: Bots and idle players are treated as human non-idle players", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_2_deathcheck");
	
	GameCheck();
	
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

GameCheck()
{
	decl String:GameFolder[16];
	GetGameFolderName(GameFolder, sizeof(GameFolder));
	if (StrEqual(GameFolder, "left4dead2", false))
	{
		L4D2Version=true;
	}	
	else
	{ 
		L4D2Version=false;
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
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	CreateTimer(10.0, Timer_SetConVarDeathCheck);
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
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	DeadCheck();
} 

public Event_PlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	DeadCheck();
}

public Event_LungePounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	DeadCheck();
}

public Event_ToungeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	DeadCheck();
}

public Event_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	DeadCheck();
}

public Event_ChargerPummelStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	DeadCheck();
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	if (MissionWillBeLost == true && CanTriggerDeathCheck[client] == true)
	{ 
		ResetConVar(FindConVar("director_no_death_check"), true, true); 
	} 
	else
	{ 
		DeadCheck();
	}
} 

DeadCheck()
{
	new AliveGuys = 0; 
	for(new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) 
		{ 
			if (GetConVarInt(FindConVar("l4d_2_deathcheck_bots")) >= 1)
			{
				if (!IsFakeClient(i))
				{
					if (IsPlayerAlive(i)) 
					{     
						AliveGuys++;
					}
					CanTriggerDeathCheck[i] = true;
				}
				else
				{
					CanTriggerDeathCheck[i] = false;
				}
			}
			else 
			{
				if (IsPlayerAlive(i))
				{     
					AliveGuys++;
				}
				CanTriggerDeathCheck[i] = true;
			}
		}
	}
	if (AliveGuys == 1)
	{ 
		MissionWillBeLost = true;
	}
	else 
	{ 
		MissionWillBeLost = false;
	} 
}

public Action:Timer_SetConVarDeathCheck(Handle:timer, any:client)
{
	SetConVarInt(FindConVar("director_no_death_check"), 0);
}