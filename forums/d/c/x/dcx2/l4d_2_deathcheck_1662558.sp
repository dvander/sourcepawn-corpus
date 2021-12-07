#include <sourcemod> 
#include <sdktools>

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

public Plugin:myinfo = { 
    name = "[L4D, L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis (modified by dcx2)", 
    description = "Prevents mission loss until all human players have died.", 
    version = "1.4.8", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

new L4D2Version=false;

new Handle:g_hDeathCheckEnable = INVALID_HANDLE;
new bool:g_bEnabled = false;
new Handle:g_cvarDebug = INVALID_HANDLE;
new bool:g_bDebug = false;
new Handle:g_hDeathCheckBots = INVALID_HANDLE;
new bool:g_bDeathCheckBots = false;
new Handle:g_hDirectorNoDeathCheck = INVALID_HANDLE;
new bool:g_bDirectorNoDeathCheck = false;
new Handle:g_hCvarMPGameMode = INVALID_HANDLE;
new Handle:g_hCvarModes = INVALID_HANDLE;
new Handle:g_hAllowAllBot = INVALID_HANDLE;
new bool:g_bLostFired = false;
new bool:g_bBlockDeathCheckDisable = false;

public OnPluginStart()
{  
	g_hDeathCheckEnable = CreateConVar("deathcheck_enable", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_cvarDebug = CreateConVar("deathcheck_debug", "0", "Enable debugging output", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDeathCheckBots = CreateConVar("deathcheck_bots", "1", "0: Bots and idle players are treated as human non-idle players, 1: Mission will be lost if there are still survivor bots/idle players but no living non-idle humans", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hCvarModes = CreateConVar("deathcheck_modes", "","Enable plugin on these gamemodes, separate by commas (no spaces). (Empty = all).", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDirectorNoDeathCheck = FindConVar("director_no_death_check");
	g_hCvarMPGameMode =	FindConVar("mp_gamemode");
	g_hAllowAllBot = FindConVar("allow_all_bot_survivor_team");

	HookConVarChange(g_hDeathCheckEnable, OnDeathCheckEnableChanged);
	HookConVarChange(g_cvarDebug, OnDeathCheckDebugChanged);
	HookConVarChange(g_hDeathCheckBots, OnDeathCheckBotsChanged);
	HookConVarChange(g_hDirectorNoDeathCheck, OnDirectorNoDeathCheckChanged);
	HookConVarChange(g_hCvarMPGameMode,	CvarChange_Allow);
	HookConVarChange(g_hCvarModes,	CvarChange_Allow);

	AutoExecConfig(true, "l4d_2_deathcheck");
	
	g_bEnabled = GetConVarBool(g_hDeathCheckEnable);
	g_bDebug = GetConVarBool(g_cvarDebug);
	g_bDeathCheckBots = GetConVarBool(g_hDeathCheckBots);
	g_bDirectorNoDeathCheck = GetConVarBool(g_hDirectorNoDeathCheck);
	
	IsAllowed();
	
	if (g_bDebug) HookEvent("mission_lost", Event_MissionLost);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_start_post_nav", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_bot_replace", Event_DeadCheck);
	HookEvent("bot_player_replace", Event_DeadCheck);
	HookEvent("player_team", Event_DeadCheck);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	HookEvent("player_death", Event_DeadCheck, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_DeadCheck); 
	HookEvent("player_ledge_grab", Event_DeadCheck);
	HookEvent("lunge_pounce", Event_DeadCheck);
	HookEvent("tongue_grab", Event_DeadCheck);
	HookEvent("door_close", Event_DoorClose);
	if(L4D2Version)
	{
		HookEvent("jockey_ride", Event_DeadCheck);
		HookEvent("charger_pummel_start", Event_DeadCheck);
	}
}

public OnDeathCheckEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = StringToInt(newVal) == 1;
	if (!g_bEnabled && g_bDirectorNoDeathCheck) SetConVarInt(g_hDirectorNoDeathCheck, 0);
	IsAllowed();
	DeadCheck();
}

public OnDeathCheckDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDebug = StringToInt(newVal) == 1;
	
	// When debugging, it's sometimes useful to know whether MissionLost fired
	if (g_bDebug) HookEvent("mission_lost", Event_MissionLost);
	else UnhookEvent("mission_lost", Event_MissionLost);		
}

public OnDeathCheckBotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDeathCheckBots = StringToInt(newVal) == 1;
	DeadCheck();
}

public OnDirectorNoDeathCheckChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDirectorNoDeathCheck = StringToInt(newVal) == 1;
}

public OnMapStart()
{
	if (g_bDebug)	PrintToChatAll("OnMapStart");
	IsAllowed();
	DeadCheck();
}

public OnClientConnected()
{
	if (g_bDebug)	PrintToChatAll("OnClientConnected");
	DeadCheck();
}

public OnClientPutInServer()
{
	if (g_bDebug)	PrintToChatAll("OnClientPutInServer");
	DeadCheck();
}

public OnClientDisconnect(client)
{
	if (g_bDebug)	PrintToChatAll("OnClientDisconnect");
	DeadCheck();
}

// Whenever the round starts, we should clear director_no_death_check
// otherwise the round may not end when all survivors are dead ("all dead glitch")
// Furthermore, it must stay cleared for some amount of time
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	if (g_bDebug)
	{
		decl String:eventName[32];
		GetEventName(event, eventName, sizeof(eventName));
		PrintToChatAll("%s", eventName);
	}
	
	SetConVarInt(g_hDirectorNoDeathCheck, 0);

	if (!g_bBlockDeathCheckDisable) 
	{
		g_bBlockDeathCheckDisable = true;
		CreateTimer(1.5, BlockDeathCheckEnable, 0);
	}
} 

public Action:BlockDeathCheckEnable(Handle:timer, any:value)
{
	g_bBlockDeathCheckDisable = false;
}

// if the all dead glitch happened and a human Survivor spawns,
// director_no_death_check must be cleared again or no one else can die either
// So we do clear the death check as a precautionary measure
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Must not reset death check unless it's a human survivor, otherwise game might accidentally end
	if (GetClientTeam(client) != 2 || IsFakeClient(client)) return;
	
	Event_RoundStart(event, name, dontBroadcast);
} 

public Event_DeadCheck(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (g_bDebug)
	{
		decl String:eventName[32];
		GetEventName(event, eventName, sizeof(eventName));
		PrintToChatAll("%s", eventName);
	}
	DeadCheck();
}

// Enables death check only when all survivors are dead
DeadCheck()
{
	if (!g_bEnabled)
	{
		return;
	}

	new survivors = 0; 
	for (new i = 1; i <= MaxClients; i++) 
	{ 
		if (IS_SURVIVOR_ALIVE(i) && GetClientHealth(i) > 0 && (!g_bDeathCheckBots || !IsFakeClient(i))) 
		{
			survivors++;
			if (!g_bDebug) break;			// quit after we have at least one valid survivor
		}
	}
	
	if (g_bDebug)	PrintToChatAll("%d survivors", survivors);
	
	// cvar must be 0 for at least 1 second
	// So if the block death check disable flag is set, we can't enable the cvar yet
	if (survivors > 0 && !g_bDirectorNoDeathCheck && !g_bBlockDeathCheckDisable)
	{
		if (g_bDebug)	PrintToChatAll("preventing deathcheck");
		SetConVarInt(g_hDirectorNoDeathCheck, 1);
	}
	else if (survivors == 0 && g_bDirectorNoDeathCheck)
	{
		if (g_bDebug)
		{
			PrintToChatAll("enabling deathcheck");
			g_bLostFired = false;					// listen for whether mission lost has fired
			CreateTimer(1.5, CheckLostFired, 0);
		}
		SetConVarInt(g_hDirectorNoDeathCheck, 0);
	}
}

// When everyone is dead in coop, the Mission Lost event should fire
// If it doesn't, the all dead glitch happened
public Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	g_bLostFired = true;
}

public Action:CheckLostFired(Handle:timer, any:value)
{
	if (!g_bLostFired) PrintToChatAll("mission_lost did not fire");
	g_bLostFired = false;
}

// If the last human survivor slays themselves after closing the door but before it seals
// the game will stay in limbo until a human takes control of a Survivor in the safe room
// To prevent this, we wait until after the door seals (about 1 second, so 2 second timer)
// And then if there are no humans, we momentarily allow an all bot survivor team
public Event_DoorClose(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new checkpoint = GetEventBool(event, "checkpoint");
	if (checkpoint)
	{
		CreateTimer(2.0, DoorCloseDelay, 0);
	}
}

public Action:DoorCloseDelay(Handle:timer, any:value)
{
	new bool:FoundHumanSurvivor = false;
	for (new i=1; i<MaxClients; i++)
	{
		if (IS_SURVIVOR_ALIVE(i) && !IsFakeClient(i)) FoundHumanSurvivor = true;
	}
	
	// Don't bother doing this if the cvar is already false
	if (!FoundHumanSurvivor && !GetConVarBool(g_hAllowAllBot))
	{
		if (g_bDebug) PrintToChatAll("Momentarily activating allow_all_bot_survivor_team");
		SetConVarBool(g_hAllowAllBot, true);
		CreateTimer(1.0, DeactivateAllowBotCVARDelay, 0);
	}
}

public Action:DeactivateAllowBotCVARDelay(Handle:timer, any:value)
{
	SetConVarBool(g_hAllowAllBot, false);
}

// Allowed game modes thanks to SilverShot
public OnConfigsExecuted()
{
	IsAllowed();
}

public CvarChange_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsAllowed();
}

bool:IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == INVALID_HANDLE )
		return false;

	decl String:sGameMode[32], String:sGameModes[64];
	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strlen(sGameModes) == 0 )
		return true;

	GetConVarString(g_hCvarMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	return (StrContains(sGameModes, sGameMode, false) != -1);
}

IsAllowed()
{
	new bool:bAllow = GetConVarBool(g_hDeathCheckEnable);
	new bool:bAllowMode = IsAllowedGameMode();

	if (g_bEnabled == false && bAllow == true && bAllowMode == true)
	{
		g_bEnabled = true;
	}
	else if (g_bEnabled == true && (bAllow == false || bAllowMode == false))
	{
		g_bEnabled = false;
	}
}
// /allowed game modes thanks to SilverShot
