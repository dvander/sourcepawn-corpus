#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5"

#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3

int realInfCount, botInfCount, botInfQueue, iMode, iIBCBoomerLimit, iIBCSmokerLimit, iIBCHunterLimit,
	maxInfPlayers, readyBots, infSpawnTimer[MAXPLAYERS+1], playerCount, iIBCSpawnTimeMax,
	iIBCSpawnTimeMin, iIBCSpawnTimeInitial, iIBCTankLimit;

bool bRoundLive, bRoundDone, bGoTime, bBoomerAllowed, bSmokerAllowed, bHunterAllowed,
	bDirectorSpawned, bInfBreak, bLifeState[MAXPLAYERS+1], bFirstSpawn, bGhost[MAXPLAYERS+1],
	bBotGhost[MAXPLAYERS+1], bDVarsChanged, bJoined[MAXPLAYERS+1], bSpawnTimeAdjust,
	bInfBotTeam, bDisableOnTanks;

ConVar cvarIBCBoomerLimit, cvarIBCSmokerLimit, cvarIBCHunterLimit, cvarIBCLimitMax,
	cvarIBCSpawnTimeMax, cvarIBCSpawnTimeMin, cvarIBCDirectorSpawned, cvarIBCMode,
	cvarIBCTeam, cvarIBCIdleKick, cvarIBCSpawnTimeInitial, cvarIBCSpawnTimeGhost,
	cvarIBCDisableOnTanks, cvarIBCTankLimit, cvarIBCSpawnTimeAdjust;

Handle idleKickTimer[MAXPLAYERS+1] = null;

public Plugin myinfo = 
{
	name = "Infected Bots Control",
	author = "djromero (SkyDavid), MI 5",
	description = "Controls Spawns Of Infected Bots.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=893938#post893938"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char sGameName[64];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (!StrEqual(sGameName, "left4dead", false))
	{
		strcopy(error, err_max, "[IBC] Plugin Supports L4D Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	cvarIBCMode = FindConVar("mp_gamemode");
	
	CreateConVar("infected_bots_control_version", PLUGIN_VERSION, "Infected Bots Control Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarIBCBoomerLimit = CreateConVar("infected_bots_control_boomer_limit", "2", "Limit Of Boomers Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCSmokerLimit = CreateConVar("infected_bots_control_smoker_limit", "3", "Limit Of Smokers Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCTankLimit = CreateConVar("infected_bots_control_tank_limit", "0", "Limit Of Tanks Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCHunterLimit = CreateConVar("infected_bots_control_hunter_limit", "3", "Limit Of Hunters Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCLimitMax = CreateConVar("infected_bots_control_limit_max", "8", "Maximum Number Of Specials Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY); 
	cvarIBCSpawnTimeMax = CreateConVar("infected_bots_control_spawn_time_max", "30", "Maximum Spawn Time Of Specials Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCSpawnTimeMin = CreateConVar("infected_bots_control_spawn_time_min", "25", "Minimum Spawn Time Of Specials Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCDirectorSpawned = CreateConVar("infected_bots_control_director_spawn", "0", "Enable/Disable Director-based Spawns", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCTeam = CreateConVar("infected_bots_control_team", "0", "Enable/Disable Infected Bot Team Spawn", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCIdleKick = CreateConVar("infected_bots_control_idle_kick", "120", "Kick Idle Infected Bots After This Amount Of Seconds", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCSpawnTimeInitial = CreateConVar("infected_bots_control_spawn_time_initial", "10", "Initial Spawn Time Of Specals Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCSpawnTimeGhost = CreateConVar("infected_bots_control_ghost_time", "0", "Ghost Time Of Specials Spawned By Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCDisableOnTanks = CreateConVar("infected_bots_control_disable_on_tanks", "0", "Enable/Disable Control On Tank Fights", FCVAR_NOTIFY|FCVAR_SPONLY);
	cvarIBCSpawnTimeAdjust = CreateConVar("infected_bots_control_spawn_time_adjust", "0", "Enable/Disable Adjustments Of Spawn Times", FCVAR_NOTIFY|FCVAR_SPONLY);
	
	iIBCBoomerLimit = cvarIBCBoomerLimit.IntValue;
	iIBCSmokerLimit = cvarIBCSmokerLimit.IntValue;
	iIBCHunterLimit = cvarIBCHunterLimit.IntValue;
	maxInfPlayers = cvarIBCLimitMax.IntValue;
	bDirectorSpawned = cvarIBCDirectorSpawned.BoolValue;
	bSpawnTimeAdjust = cvarIBCSpawnTimeAdjust.BoolValue;
	bInfBotTeam = cvarIBCTeam.BoolValue;
	bDisableOnTanks = cvarIBCDisableOnTanks.BoolValue;
	iIBCSpawnTimeMax = cvarIBCSpawnTimeMax.IntValue;
	iIBCSpawnTimeMin = cvarIBCSpawnTimeMin.IntValue;
	iIBCSpawnTimeInitial = cvarIBCSpawnTimeInitial.IntValue;
	iIBCTankLimit = cvarIBCTankLimit.IntValue;
	
	HookConVarChange(cvarIBCBoomerLimit, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCSmokerLimit, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCHunterLimit, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCLimitMax, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCDirectorSpawned, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCMode, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCSpawnTimeAdjust, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCTeam, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCDisableOnTanks, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCSpawnTimeMax, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCSpawnTimeMin, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCSpawnTimeInitial, OnPluginCVarsAltered);
	HookConVarChange(cvarIBCTankLimit, OnPluginCVarsAltered);
	
	AutoExecConfig(true, "infected_bots_control");
	
	HookConVarChange(FindConVar("z_hunter_limit"), OnDVarsAltered);
	HookConVarChange(FindConVar("z_gas_limit"), OnDVarsAltered);
	HookConVarChange(FindConVar("z_exploding_limit"), OnDVarsAltered);
	HookConVarChange(FindConVar("holdout_max_boomers"), OnDVarsAltered);
	HookConVarChange(FindConVar("holdout_max_smokers"), OnDVarsAltered);
	HookConVarChange(FindConVar("holdout_max_hunters"), OnDVarsAltered);
	HookConVarChange(FindConVar("holdout_max_specials"), OnDVarsAltered);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("create_panic_event", OnSurvivalStart);
	HookEvent("finale_start", OnFinaleStart);
	HookEvent("player_bot_replace", OnPlayerBotReplace);
	
	HookEvent("player_first_spawn", OnPlayerRelatedEvents);
	HookEvent("player_entered_start_area", OnPlayerRelatedEvents);
	HookEvent("player_entered_checkpoint", OnPlayerRelatedEvents);
	HookEvent("player_transitioned", OnPlayerRelatedEvents);
	HookEvent("player_left_start_area", OnPlayerRelatedEvents);
	HookEvent("player_left_checkpoint", OnPlayerRelatedEvents);
}

public void OnPluginCVarsAltered(ConVar cvar, const char[] oV, const char[] nV)
{
	iIBCBoomerLimit = cvarIBCBoomerLimit.IntValue;
	iIBCSmokerLimit = cvarIBCSmokerLimit.IntValue;
	iIBCHunterLimit = cvarIBCHunterLimit.IntValue;
	maxInfPlayers = cvarIBCLimitMax.IntValue;
	bDirectorSpawned = cvarIBCDirectorSpawned.BoolValue;
	bSpawnTimeAdjust = cvarIBCSpawnTimeAdjust.BoolValue;
	bInfBotTeam = cvarIBCTeam.BoolValue;
	bDisableOnTanks = cvarIBCDisableOnTanks.BoolValue;
	iIBCSpawnTimeMax = cvarIBCSpawnTimeMax.IntValue;
	iIBCSpawnTimeMin = cvarIBCSpawnTimeMin.IntValue;
	iIBCSpawnTimeInitial = cvarIBCSpawnTimeInitial.IntValue;
	iIBCTankLimit = cvarIBCTankLimit.IntValue;
	
	CreateTimer(0.1, MaxLimitFix);
	
	GameModeCheck();
	if (!bDirectorSpawned)
	{
		TweakSettings();
		CheckIfBotsNeeded(true, false);
	}
	else
	{
		DirectorStuff();
	}
}

public void OnDVarsAltered(ConVar cvar, const char[] oV, const char[] nV)
{
	bDVarsChanged = true;
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	playerCount += 1;
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	infSpawnTimer[client] = 0;
	
	bLifeState[client] = false;
	bGhost[client] = false;
	bJoined[client] = false;
	
	playerCount -= 1;
	if (playerCount == 0)
	{
		bGoTime = false;
		
		bRoundDone = true;
		bRoundLive = false;
		
		bDVarsChanged = false;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				bGhost[i] = false;
				bJoined[i] = false;
				
				if (idleKickTimer[i] != null)
				{
					idleKickTimer[i] = null;
				}
			}
		}
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (bRoundLive)
	{
		return Plugin_Continue;
	}
	
	bGoTime = false;
	bRoundDone = false;
	bRoundLive = true;
	
	GameModeCheck();
	if (iMode == 0)
	{
		return Plugin_Continue;
	}
	
	int flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
	FindConVar("z_max_player_zombies").SetBounds(ConVarBound_Upper, true, 8.0);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags|FCVAR_NOTIFY);
	
	CreateTimer(0.4, MaxLimitFix);
	
	botInfQueue = 0;
	readyBots = 0;
	
	bInfBreak = false;
	bFirstSpawn = false;
	
	if (!bDirectorSpawned)
	{
		TweakSettings();
	}
	else
	{
		DirectorStuff();
	}
	
	if (iMode != 3)
	{
		CreateTimer(1.0, PlayerLeftStart, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public Action MaxLimitFix(Handle timer)
{
	if (FindConVar("z_max_player_zombies").IntValue == maxInfPlayers)
	{
		return Plugin_Stop;
	}
	
	FindConVar("z_max_player_zombies").SetInt(maxInfPlayers);
	return Plugin_Stop;
}

public Action PlayerLeftStart(Handle timer)
{
	if (!LeftStartArea())
	{
		return Plugin_Continue;
	}
	
	if (!bGoTime)
	{
		bGoTime = true;
		
		bBoomerAllowed = true;
		bSmokerAllowed = true;
		bHunterAllowed = true;
		bFirstSpawn = true;
		
		CheckIfBotsNeeded(false, true);
		
		CreateTimer(3.0, IgnoreInitialSpawns, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}

public Action IgnoreInitialSpawns(Handle timer)
{
	bFirstSpawn = false;
	return Plugin_Stop;
}

public Action OnPlayerRelatedEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (bRoundDone)
	{
		return Plugin_Continue;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client) || bJoined[client])
	{
		return Plugin_Continue;
	}
	
	bGhost[client] = false;
	bJoined[client] = true;
	
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!bRoundDone)
	{
		bRoundDone = true;
		bRoundLive = false;
		bGoTime = false;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				bJoined[i] = false;
				if (idleKickTimer[i] != null)
				{
					idleKickTimer[i] = null;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnSurvivalStart(Event event, const char[] name, bool dontBroadcast)
{
	if (iMode == 3)
	{
		if (!bGoTime)
		{
			bGoTime = true;
			
			bBoomerAllowed = true;
			bSmokerAllowed = true;
			bHunterAllowed = true;
			bFirstSpawn = true;
			
			CheckIfBotsNeeded(false, true);
			
			CreateTimer(3.0, IgnoreInitialSpawns, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	bBotGhost[bot] = true;
	
	return Plugin_Continue;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (IsFakeClient(client))
	{
		if (bDirectorSpawned && iMode != 2)
		{
			switch (GetEntProp(client, Prop_Send, "m_zombieClass"))
			{
				case 1:
				{
					if (!bInfBreak)
					{
						CreateTimer(0.1, KickInfBot, client, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.2, SpawnInfBot_Director, 1, TIMER_FLAG_NO_MAPCHANGE);
					}
					
					if (idleKickTimer[client] != null)
					{
						idleKickTimer[client] = null;
					}
					idleKickTimer[client] = CreateTimer(cvarIBCIdleKick.FloatValue, DisposeOfCowards, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case 2:
				{
					if (!bInfBreak)
					{
						CreateTimer(0.1, KickInfBot, client, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.2, SpawnInfBot_Director, 2, TIMER_FLAG_NO_MAPCHANGE);
					}
					
					if (idleKickTimer[client] != null)
					{
						idleKickTimer[client] = null;
					}
					idleKickTimer[client] = CreateTimer(cvarIBCIdleKick.FloatValue, DisposeOfCowards, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case 3:
				{
					if (!bInfBreak)
					{
						CreateTimer(0.1, KickInfBot, client, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.2, SpawnInfBot_Director, 3, TIMER_FLAG_NO_MAPCHANGE);
					}
					
					if (idleKickTimer[client] != null)
					{
						idleKickTimer[client] = null;
					}
					idleKickTimer[client] = CreateTimer(cvarIBCIdleKick.FloatValue, DisposeOfCowards, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	else
	{
		if (iMode == 2 && GetEntProp(client, Prop_Send, "m_zombieClass") < 4)
		{
			CreateTimer(0.1, PrepareGhostBot, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

public Action KickInfBot(Handle timer, any client)
{
	if (IsClientInGame(client) && IsFakeClient(client) && !IsClientInKickQueue(client))
	{
		KickClient(client);
	}
	
	return Plugin_Stop;
}

public Action SpawnInfBot_Director(Handle timer, any infType)
{
	bool resetGhost[MAXPLAYERS+1], resetLife[MAXPLAYERS+1];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
		{
			if (IsPlayerGhost(i))
			{
				resetGhost[i] = true;
				SetGhostStatus(i, false);
			}
			else if (!PlayerIsAlive(i))
			{
				bGhost[i] = false;
				SetLifeState(i, true);
			}
		}
	}
	
	int anyclient = GetAnyClient();
	bool temp = false;
	
	if (anyclient == -1)
	{
		anyclient = CreateFakeClient("Bot");
		temp = true;
	}
	
	bInfBreak = true;
	
	switch (infType)
	{
		case 1: CheatCommand(anyclient, "z_spawn", "smoker auto");
		case 2: CheatCommand(anyclient, "z_spawn", "boomer auto");
		case 3: CheatCommand(anyclient, "z_spawn", "hunter auto");
		case 4: CheatCommand(anyclient, "z_spawn", "spitter auto");
		case 5: CheatCommand(anyclient, "z_spawn", "jockey auto");
		case 6: CheatCommand(anyclient, "z_spawn", "charger auto");
	}
	
	bInfBreak = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (resetGhost[i])
		{
			SetGhostStatus(i, true);
		}
		
		if (resetLife[i])
		{
			SetLifeState(i, true);
		}
	}
	if (temp)
	{
		CreateTimer(0.1, KickInfBot, anyclient, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public Action DisposeOfCowards(Handle timer, any coward)
{
	if (IsClientInGame(coward) && GetClientTeam(coward) == TEAM_INFECTED  && GetEntProp(coward, Prop_Send, "m_zombieClass") < 4 && PlayerIsAlive(coward) && IsFakeClient(coward))
	{
		int threats = GetEntProp(coward, Prop_Send, "m_hasVisibleThreats");
		if (threats)
		{
			if (idleKickTimer[coward] != null)
			{
				idleKickTimer[coward] = null;
			}
			idleKickTimer[coward] = CreateTimer(cvarIBCIdleKick.FloatValue, DisposeOfCowards, coward);
			
			return Plugin_Stop;
		}
		else
		{
			CreateTimer(0.1, KickInfBot, coward, TIMER_FLAG_NO_MAPCHANGE);
			if (!bDirectorSpawned)
			{
				int SpawnTime = GetURandomIntRange(iIBCSpawnTimeMin, iIBCSpawnTimeMax);
				if (iMode == 2 && bSpawnTimeAdjust && maxInfPlayers != HumansOnInfected())
				{
					SpawnTime = SpawnTime / (maxInfPlayers - HumansOnInfected());
				}
				else if (iMode == 1 && bSpawnTimeAdjust)
				{
					SpawnTime = SpawnTime - TrueNumberOfSurvivors();
				}
				
				CreateTimer(float(SpawnTime), SpawnInfBot, _, TIMER_FLAG_NO_MAPCHANGE);
				botInfQueue += 1;
			}
		}
	}
	
	idleKickTimer[coward] = null;
	return Plugin_Stop;
}

public Action SpawnInfBot(Handle timer)
{
	if (bRoundDone || !bRoundLive || !bGoTime)
	{
		return Plugin_Stop;
	}
	
	int Infected = maxInfPlayers;
	if (bInfBotTeam && !bDirectorSpawned && !bFirstSpawn)
	{
		readyBots += 1;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
			{
				Infected -= 1;
			}
		}
		if (readyBots >= Infected)
		{
			CreateTimer(3.0, ClearReadyBots, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			botInfQueue -= 1;
			return Plugin_Stop;
		}
	}
	
	CountInfected();
	if ((realInfCount + botInfCount) >= maxInfPlayers || (realInfCount + botInfCount + botInfQueue) > maxInfPlayers) 	
	{
		botInfQueue -= 1;
		return Plugin_Stop;
	}
	
	if (bDisableOnTanks)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && GetEntProp(i, Prop_Send, "m_zombieClass") == 5 && IsPlayerAlive(i))
			{
				botInfQueue -= 1;
				return Plugin_Stop;
			}
		}
	}
	
	bool resetGhost[MAXPLAYERS+1], resetLife[MAXPLAYERS+1];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
		{
			if (IsPlayerGhost(i))
			{
				resetGhost[i] = true;
				SetGhostStatus(i, false);
			}
			else if (!PlayerIsAlive(i))
			{
				resetLife[i] = true;
				SetLifeState(i, false);
			}
		}
	}
	
	int anyclient = GetAnyClient();
	bool temp = false;
	
	if (anyclient == -1)
	{
		anyclient = CreateFakeClient("Bot");
		if (anyclient == -1)
		{
			return Plugin_Stop;
		}
		
		temp = true;
	}
	
	int bot_type = BotTypeNeeded();
	switch (bot_type)
	{
		case 1: CheatCommand(anyclient, "z_spawn", "hunter auto");
		case 2: CheatCommand(anyclient, "z_spawn", "smoker auto");
		case 3: CheatCommand(anyclient, "z_spawn", "boomer auto");
		case 4: CheatCommand(anyclient, "z_spawn", "tank auto");
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (resetGhost[i])
		{
			SetGhostStatus(i, true);
		}
		
		if (resetLife[i])
		{
			SetLifeState(i, true);
		}
	}
	if (temp)
	{
		CreateTimer(0.1, KickInfBot, anyclient, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	botInfQueue -= 1;
	CreateTimer(1.0, CheckReinforcements, true, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action ClearReadyBots(Handle timer)
{
	readyBots = 0;
	return Plugin_Stop;
}

public Action CheckReinforcements(Handle timer, any bImmediate)
{
	CheckIfBotsNeeded(bImmediate, false);
	return Plugin_Stop;
}

public Action PrepareGhostBot(Handle timer, any client)
{
	if (IsValidEntity(client))
	{
		if (!bBotGhost[client])
		{
			SetGhostStatus(client, true);
			
			SetEntityMoveType(client, MOVETYPE_NONE);
			CreateTimer(cvarIBCSpawnTimeGhost.FloatValue, RestoreInfBot, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			bBotGhost[client] = false;
		}
	}
	
	return Plugin_Stop;
}

public Action RestoreInfBot(Handle timer, any client)
{
	if (IsValidEntity(client))
	{
		SetGhostStatus(client, false);
		
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	
	return Plugin_Stop;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (bRoundDone || !bGoTime)
	{
		return Plugin_Continue;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (idleKickTimer[client] != null)
	{
		idleKickTimer[client] = null;
	}
	
	if (event.GetBool("victimisbot") && !bDirectorSpawned)
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") < 4)
		{
			int SpawnTime = GetURandomIntRange(iIBCSpawnTimeMin, iIBCSpawnTimeMax);
			if (bSpawnTimeAdjust && maxInfPlayers != HumansOnInfected())
			{
				SpawnTime = SpawnTime / (maxInfPlayers - HumansOnInfected());
			}
			
			CreateTimer(float(SpawnTime), SpawnInfBot, _, TIMER_FLAG_NO_MAPCHANGE);
			botInfQueue += 1;
		}
	}
	
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 5)
	{
		CheckIfBotsNeeded(false, false);
	}
	else if (iMode != 2 && bDirectorSpawned)
	{
		int SpawnTime = GetURandomIntRange(iIBCSpawnTimeMin, iIBCSpawnTimeMax);
		infSpawnTimer[client] = SpawnTime;
	}
	
	if (IsFakeClient(client))
	{
		CreateTimer(0.1, KickInfBot, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("isbot"))
	{
		return Plugin_Continue;
	}
	
	int newteam = event.GetInt("team"), oldteam = event.GetInt("oldteam");
	
	if (!bRoundDone && bGoTime && iMode == 2)
	{
		if (oldteam == 3 || newteam == 3)
		{
			CheckIfBotsNeeded(false, false);
		}
		
		if (newteam == 3)
		{
			CreateTimer(1.0, InfectedBotBooterVersus, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

public Action InfectedBotBooterVersus(Handle timer)
{
	if (iMode != 2)
	{
		return Plugin_Stop;
	}
	
	int total = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && (GetEntProp(i, Prop_Send, "m_zombieClass") < 4 || (GetEntProp(i, Prop_Send, "m_zombieClass") == 5 && !PlayerIsAlive(i))))
		{
			total += 1;
		}
	}
	if (total + botInfQueue > maxInfPlayers)
	{
		int kick = total + botInfQueue - maxInfPlayers; 
		int kicked = 0;
		
		for (int i = 1; i <= MaxClients && kicked < kick; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && (GetEntProp(i, Prop_Send, "m_zombieClass") < 4 || (GetEntProp(i, Prop_Send, "m_zombieClass") == 5 && !PlayerIsAlive(i))) && IsFakeClient(i))
			{
				CreateTimer(0.1, KickInfBot, i, TIMER_FLAG_NO_MAPCHANGE);
				kicked += 1;
			}
		}
	}
	
	return Plugin_Stop;
}

public Action OnFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, CheckReinforcements, true, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public void OnMapEnd()
{
	bRoundLive = false;
	bRoundDone = true;
	bGoTime = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (idleKickTimer[i] != null)
			{
				idleKickTimer[i] = null;
			}
		}
	}
}

void GameModeCheck()
{
	char sGameMode[16];
	cvarIBCMode.GetString(sGameMode, sizeof(sGameMode));
	if (StrEqual(sGameMode, "survival", false))
	{
		iMode = 3;
	}
	else if (StrEqual(sGameMode, "versus", false) || StrEqual(sGameMode, "teamversus", false))
	{
		iMode = 2;
	}
	else if (StrEqual(sGameMode, "coop", false))
	{
		iMode = 1;
	}
	else
	{
		iMode = 0;
	}
}

void TweakSettings()
{
	ResetCvars();
	
	switch (iMode)
	{
		case 1:
		{
			FindConVar("z_gas_limit").SetInt(0);
			FindConVar("z_exploding_limit").SetInt(0);
			FindConVar("z_hunter_limit").SetInt(0);
		}
		case 2:
		{
			FindConVar("z_gas_limit").SetInt(999);
			FindConVar("z_exploding_limit").SetInt(999);
			FindConVar("z_hunter_limit").SetInt(999);
			
			FindConVar("smoker_tongue_delay").SetFloat(0.0);
			FindConVar("boomer_vomit_delay").SetFloat(0.0);
			FindConVar("boomer_exposed_time_tolerance").SetFloat(0.0);
			
			FindConVar("hunter_leap_away_give_up_range").SetInt(0);
			FindConVar("z_hunter_lunge_distance").SetInt(5000);
			FindConVar("z_hunter_lunge_distance").SetInt(1500);
			
			FindConVar("hunter_pounce_loft_rate").SetFloat(0.055);
			FindConVar("z_hunter_lunge_stagger_time").SetFloat(0.0);
		}
		case 3:
		{
			FindConVar("holdout_max_smokers").SetInt(0);
			FindConVar("holdout_max_boomers").SetInt(0);
			FindConVar("holdout_max_hunters").SetInt(0);
			FindConVar("holdout_max_specials").SetInt(maxInfPlayers);
			
			FindConVar("z_gas_limit").SetInt(0);
			FindConVar("z_exploding_limit").SetInt(0);
			FindConVar("z_hunter_limit").SetInt(0);
		}
	}
	
	FindConVar("z_attack_flow_range").SetInt(50000);
	FindConVar("director_spectate_specials").SetInt(1);
	FindConVar("z_spawn_safety_range").SetInt(0);
	FindConVar("z_spawn_flow_limit").SetInt(50000);
	
	bDVarsChanged = false;
}

void CheckIfBotsNeeded(bool bImmediate, bool bInitial)
{
	if (!bDirectorSpawned)
	{
		if (bRoundDone || !bGoTime)
		{
			return;
		}
		
		CountInfected();
		
		int diff = maxInfPlayers - (botInfCount + realInfCount + botInfQueue);
		if (diff > 0)
		{
			for (int i; i < diff; i++)
			{
				if (bImmediate)
				{
					botInfQueue += 1;
					CreateTimer(0.5, SpawnInfBot, _, TIMER_FLAG_NO_MAPCHANGE);
				}
				else if (bInitial)
				{
					botInfQueue += 1;
					CreateTimer(float(iIBCSpawnTimeInitial), SpawnInfBot, _, TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					botInfQueue += 1;
					if (iMode == 2 && bSpawnTimeAdjust && maxInfPlayers != HumansOnInfected())
					{
						CreateTimer(float(iIBCSpawnTimeMax) / (maxInfPlayers - HumansOnInfected()), SpawnInfBot, _, TIMER_FLAG_NO_MAPCHANGE);
					}
					else if (iMode == 1 && bSpawnTimeAdjust)
					{
						CreateTimer(float(iIBCSpawnTimeMax - TrueNumberOfSurvivors()), SpawnInfBot, _, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						CreateTimer(float(iIBCSpawnTimeMax), SpawnInfBot, _, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

void ResetCvars()
{
	switch (iMode)
	{
		case 1:
		{
			FindConVar("director_no_specials").RestoreDefault();
			FindConVar("boomer_vomit_delay").RestoreDefault();
			FindConVar("smoker_tongue_delay").RestoreDefault();
			FindConVar("hunter_leap_away_give_up_range").RestoreDefault();
			FindConVar("boomer_exposed_time_tolerance").RestoreDefault();
			FindConVar("z_hunter_lunge_distance").RestoreDefault();
			FindConVar("hunter_pounce_ready_range").RestoreDefault();
			FindConVar("hunter_pounce_loft_rate").RestoreDefault();
			FindConVar("z_hunter_lunge_stagger_time").RestoreDefault();
			
			FindConVar("holdout_max_smokers").RestoreDefault();
			FindConVar("holdout_max_boomers").RestoreDefault();
			FindConVar("holdout_max_hunters").RestoreDefault();
			FindConVar("holdout_max_specials").RestoreDefault();
		}
		case 2:
		{
			FindConVar("holdout_max_smokers").RestoreDefault();
			FindConVar("holdout_max_boomers").RestoreDefault();
			FindConVar("holdout_max_hunters").RestoreDefault();
			FindConVar("holdout_max_specials").RestoreDefault();
		}
		case 3:
		{
			FindConVar("z_hunter_limit").RestoreDefault();
			FindConVar("z_gas_limit").RestoreDefault();
			FindConVar("z_exploding_limit").RestoreDefault();
			
			FindConVar("director_no_specials").RestoreDefault();
			FindConVar("boomer_vomit_delay").RestoreDefault();
			FindConVar("smoker_tongue_delay").RestoreDefault();
			FindConVar("hunter_leap_away_give_up_range").RestoreDefault();
			FindConVar("boomer_exposed_time_tolerance").RestoreDefault();
			FindConVar("z_hunter_lunge_distance").RestoreDefault();
			FindConVar("hunter_pounce_ready_range").RestoreDefault();
			FindConVar("hunter_pounce_loft_rate").RestoreDefault();
			FindConVar("z_hunter_lunge_stagger_time").RestoreDefault();
		}
	}
}

void DirectorStuff()
{	
	bInfBreak = false;
	
	FindConVar("z_spawn_safety_range").SetInt(0);
	FindConVar("director_spectate_specials").SetInt(1);
	
	if (!bDVarsChanged)
	{
		ResetCvarsDirector();
	}
}

void ResetCvarsDirector()
{
	if (iMode != 2)
	{
		FindConVar("z_hunter_limit").RestoreDefault();
		FindConVar("z_gas_limit").RestoreDefault();
		FindConVar("z_exploding_limit").RestoreDefault();
		
		FindConVar("holdout_max_smokers").RestoreDefault();
		FindConVar("holdout_max_boomers").RestoreDefault();
		FindConVar("holdout_max_hunters").RestoreDefault();
		FindConVar("holdout_max_specials").RestoreDefault();
	}
	else
	{
		FindConVar("z_hunter_limit").RestoreDefault();
		FindConVar("z_gas_limit").RestoreDefault();
		FindConVar("z_exploding_limit").RestoreDefault();
	}
}

bool LeftStartArea()
{
	int ent = -1;
	
	for (int i = 1; i <= GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	if (ent != -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea", 1))
		{
			return true;
		}
	}
	
	return false;
}

int GetAnyClient() 
{
	int chosenClient = -1;
	
	for (int target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target) && !IsFakeClient(target))
		{
			chosenClient = target;
			break;
		}
	}
	
	return chosenClient;
}

int HumansOnInfected()
{
	int humansTotal = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
		{
			humansTotal += 1;
		}
	}
	
	return humansTotal;
}

int TrueNumberOfSurvivors()
{
	int survivorsTotal = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			survivorsTotal += 1;
		}
	}
	
	return survivorsTotal;
}

bool IsPlayerGhost(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isGhost")) ? true : false;
}

bool PlayerIsAlive(int client)
{
	return (!GetEntProp(client, Prop_Send, "m_lifeState")) ? true : false;
}

void SetGhostStatus(int client, bool ghost)
{
	if (ghost)
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 1);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 0);
	}
}

SetLifeState(int client, bool ready)
{
	if (ready)
	{
		SetEntProp(client, Prop_Send,  "m_lifeState", 1);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
	}
}

int BotTypeNeeded()
{
	int boomers = 0, smokers = 0, hunters = 0, tanks = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && PlayerIsAlive(i))
		{
			switch (GetEntProp(i, Prop_Send, "m_zombieClass"))
			{
				case 1: smokers += 1;
				case 2: boomers += 1;	
				case 3: hunters += 1;	
				case 5: tanks += 1;
			}
		}
	}
	
	int random = GetURandomIntRange(1, 4);
	if (random == 2)
	{
		if (smokers < iIBCSmokerLimit && bSmokerAllowed)
		{
			return 2;
		}
	}
	else if (random == 3)
	{
		if (boomers < iIBCBoomerLimit && bBoomerAllowed)
		{
			return 3;
		}
	}
	else if (random == 1)
	{
		if (hunters < iIBCHunterLimit && bHunterAllowed)
		{
			return 1;
		}
	}
	else if (random == 4)
	{
		if (tanks < iIBCTankLimit)
		{
			return 4;
		}
	}
	
	return BotTimePrepare();
}

int BotTimePrepare()
{
	CreateTimer(1.0, KnowNeededBot);
	return 0;
}

public Action KnowNeededBot(Handle timer)
{
	BotTypeNeeded();
	return Plugin_Stop;
}

int GetURandomIntRange(int min, int max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}

void CountInfected()
{
	botInfCount = 0;
	realInfCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if (IsFakeClient(i))
			{
				botInfCount += 1;
			}
			else
			{
				realInfCount += 1;
			}
		}
	}
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

