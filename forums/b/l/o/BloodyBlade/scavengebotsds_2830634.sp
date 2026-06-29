#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION		"2.1"
#define CVAR_FLAGS		FCVAR_NOTIFY
#define CONFIG_DATA		"data/scavengebotsds.cfg"
#define CONFIG_FINALE_DATA		"data/scavengefinalebotsds.cfg"
#define CONFIG_SCAVENGE_DATA		"data/scavengegamebotsds.cfg"

static ConVar hScavengeBotsDS, hScavengeBuddy, hScavengeEscort;
static bool bScavengeBotsDS = false, bScavengeBuddy = false, bScavengeEscort = true, bScavengeInProgress = false, bFinaleScavengeInProgress = false, bScavengeGameInProgress = false, FinaleHasStarted = false, EscapeReady = false;
static int BotAction[MAXPLAYERS + 1] = {0, ...}, BotTarget[MAXPLAYERS + 1] = {0, ...}, BotAIUpdate[MAXPLAYERS + 1] = {0, ...}, BotAbortTick[MAXPLAYERS + 1] = {0, ...};
static int BotUseGasCan[MAXPLAYERS + 1] = {0, ...}, BotBuddy[MAXPLAYERS + 1] = {0, ...}, HumanBuddy[MAXPLAYERS + 1] = {0, ...}, GasNozzle = 0;
static float BotCheckPos[MAXPLAYERS + 1][3], hpMultiplier = 0.0, NozzleOrigin[3], NozzleAngles[3], NozzleOrigin2[3], NozzleAngles2[3], NozzleOrigin3[3], NozzleAngles3[3];

public Plugin myinfo =
{
	name = "[L4D2] ScavengeBotsDS",
	author = "Machine/Xanaguy/ArcticCerebrate",
	description = "Survivor Bots Scavenging now more compatible overall.",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "ScavengeBotsDS only supports Left4Dead2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	hScavengeBotsDS = CreateConVar("scavengebotsds_on", "1", "Enable ScavengeBots? 0=off, 1=on.", CVAR_FLAGS, true, 0.0, true, 1.0);
	bScavengeBotsDS = hScavengeBotsDS.BoolValue;
	
	hScavengeBuddy = CreateConVar("scavengebotsds_buddy", "0", "Enable ScavengeBots Buddy System? 0=off, 1=on.", CVAR_FLAGS, true, 0.0, true, 1.0);
	bScavengeBuddy = hScavengeBuddy.BoolValue;
	
	hScavengeEscort = CreateConVar("scavengebotsds_buddyWithHuman", "1", "Allow Bots to Buddy with Humans? 0=off, 1=on.", CVAR_FLAGS, true, 0.0, true, 1.0);
	bScavengeEscort = hScavengeEscort.BoolValue;
	
	hpMultiplier = FindConVar("sb_temp_health_consider_factor").FloatValue;

	HookEvent("finale_start", Finale_Start);
	HookEvent("gauntlet_finale_start", Finale_Start);
	HookEvent("player_use", Start_Scavenging);
	HookEvent("gascan_pour_completed", Start_Scavenging);
	HookEvent("instructor_server_hint_create", Start_Scavenging);
	HookEvent("finale_vehicle_incoming", Stop_Scavenging);
	HookEvent("finale_vehicle_ready", Stop_Scavenging);
	HookEvent("finale_escape_start", Stop_Scavenging);
	HookEvent("scavenge_round_start", Scavenge_Round_Start);
	HookEvent("round_start", Round_Start);
	HookEvent("weapon_drop", Weapon_Drop);
	HookEvent("scavenge_round_halftime", ResetBools);
	HookEvent("scavenge_round_finished", ResetBools);
	HookEvent("round_end", ResetBools);
	HookEvent("map_transition", ResetBools);
	HookEvent("mission_lost", ResetBools);
	HookEvent("finale_win", ResetBools);
	HookEvent("round_start_pre_entity", ResetBools);

	hScavengeBotsDS.AddChangeHook(ConVarChanged);
	hScavengeBuddy.AddChangeHook(ConVarChanged);
	hScavengeEscort.AddChangeHook(ConVarChanged);

	CreateTimer(0.1, BotUpdate, _, TIMER_REPEAT);

	AutoExecConfig(true, "l4d2_scavengebotsds");
}

public void OnMapStart()
{
	bFinaleScavengeInProgress = false;
	bScavengeInProgress = false;
	bScavengeGameInProgress = false;
	FinaleHasStarted = false;
	EscapeReady = false;
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == hScavengeBotsDS)
	{
		bScavengeBotsDS = hScavengeBotsDS.BoolValue;
		int oldval = StringToInt(oldValue);
		int newval = StringToInt(newValue);
		if (oldval != newval)
		{
			if (newval == 0)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsBot(i))
					{
						L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(i));
					}
				}
			}
			else
			{
				if (FindConVar("sb_unstick").IntValue == 1)
				{
					FindConVar("sb_unstick").SetInt(0);
				}
			}
		}
	}
	if (convar == hScavengeBuddy)
	{
		bScavengeBuddy = hScavengeBuddy.BoolValue;
	}
	if (convar == hScavengeEscort)
	{
		bScavengeEscort = hScavengeEscort.BoolValue;
	}
}

Action ResetBools(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, CallBotsOff, 0);
	return Plugin_Continue;
}

Action Finale_Start(Event event, char[] event_name, bool dontBroadcast)
{
	FinaleHasStarted = true;
	bScavengeGameInProgress = false;
	bScavengeInProgress = false;
	int entity = -1;

	if (!IsInvalidMap())
	{
		while ((entity = FindEntityByClassname(entity, "game_scavenge_progress_display")) != -1)
		{
			bFinaleScavengeInProgress = true;
			LoadFinaleConfig();
		}
		while ((entity = FindEntityByClassname(entity, "point_prop_use_target")) != INVALID_ENT_REFERENCE)
		{
			GasNozzle = entity;
			HookSingleEntityOutput(entity, "OnUseStarted", OnUseStarted);
			HookSingleEntityOutput(entity, "OnUseCancelled", OnUseCancelled);
			HookSingleEntityOutput(entity, "OnUseFinished", OnUseFinished);
		}
	}
	return Plugin_Continue;
}

Action Scavenge_Round_Start(Event event, char[] event_name, bool dontBroadcast)
{
	if (!IsInvalidMap())
	{
		bScavengeGameInProgress = true;
		LoadScavengeConfig();
		int entity = -1;

		while ((entity = FindEntityByClassname(entity, "point_prop_use_target")) != INVALID_ENT_REFERENCE)
		{
			GasNozzle = entity;
			HookSingleEntityOutput(entity, "OnUseStarted", OnUseStarted);
			HookSingleEntityOutput(entity, "OnUseCancelled", OnUseCancelled);
			HookSingleEntityOutput(entity, "OnUseFinished", OnUseFinished);
		}
	}
	return Plugin_Continue;
}

Action Stop_Scavenging(Event event, char[] event_name, bool dontBroadcast)
{
	bScavengeInProgress = false;
	bFinaleScavengeInProgress = false;
	EscapeReady = true;
	CreateTimer(0.2, EscapeTime);
	if (bScavengeBotsDS)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsBot(client))
			{
				L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
			}
		}
	}
	return Plugin_Continue;
}

Action Round_Start(Event event, char[] event_name, bool dontBroadcast)
{
	ResetVariables();
	for (int i = 1; i <= MaxClients; i++)
	{
		ResetClientArrays(i);
	}
	return Plugin_Continue;
}

Action Start_Scavenging(Event event, char[] event_name, bool dontBroadcast)
{
	CreateTimer(0.1, ScavengeDoubleCheckStart);
	return Plugin_Continue;
}

Action Weapon_Drop(Event event, const char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int entity = event.GetInt("propid");
	if (bScavengeInProgress)
	{
		if (entity > 0 && IsValidEntity(entity))
		{
			char classname[24];
			GetEdictClassname(entity, classname, sizeof(classname));
			if (StrEqual(classname, "weapon_gascan", false))
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				int glowcolor = RGB_TO_INT(255, 150, 0);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowcolor);
				if (IsBot(client))
				{
					if (BotTarget[client] == entity)
					{
						BotTarget[client] = -1;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if(client > 0)
	{
		ResetClientArrays(client);
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
}

public void OnClientDisconnect(int client)
{
	if(client > 0)
	{
		ResetClientArrays(client);
	}
}

stock void ResetVariables()
{
	bScavengeInProgress = false;
	bFinaleScavengeInProgress = false;
	bScavengeGameInProgress = false;
	FinaleHasStarted = false;
	EscapeReady = false;
}

stock void ResetClientArrays(int client)
{
	BotAction[client] = -1;
	BotTarget[client] = -1;
	BotAIUpdate[client] = -1;
	BotUseGasCan[client] = -1;
	BotAbortTick[client] = -1;
	for (int i = 0; i <= 2; i++)
	{
		BotCheckPos[client][i] = 0.0;
	}
	BotBuddy[client] = -1;
	HumanBuddy[client] = -1;
}

stock void LoadConfig()
{
	char Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Path, sizeof(Path), "%s", CONFIG_DATA);
	if (!FileExists(Path))
	{
		PrintToServer("ScavengeBotsDS Error: Cannot read the config %s", Path);
		bScavengeInProgress = false;
		return;
	}
	KeyValues cFile = new KeyValues("maps");
	if (!FileToKeyValues(cFile, Path))
	{
		PrintToServer("ScavengeBotsDS Error: Failed to get maps from %s", Path);
		bScavengeInProgress = false;
		delete cFile;
		return;
	}
	char Map[PLATFORM_MAX_PATH];
	GetCurrentMap(Map, sizeof(Map));
	if (!cFile.JumpToKey(Map))
	{
		PrintToServer("ScavengeBotsDS Error: Failed to get map from %s", Path);
		bScavengeInProgress = false;
		delete cFile;
		return;
	}
	if (FinaleHasStarted)
	{
		bScavengeInProgress = false;
		delete cFile;
		return;
	}
	cFile.GetVector("origin", NozzleOrigin2);
	cFile.GetVector("angles", NozzleAngles2);
	delete cFile;
}

stock void LoadFinaleConfig()
{	
	char Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Path, sizeof(Path), "%s", CONFIG_FINALE_DATA);
	if (!FileExists(Path))
	{
		PrintToServer("ScavengeBotsDS Error: Cannot read the config %s", Path);
		bFinaleScavengeInProgress = false;
		return;
	}
	KeyValues FinaleFile = new KeyValues("finalemaps");
	if (!FileToKeyValues(FinaleFile, Path))
	{
		PrintToServer("ScavengeBotsDS Error: Failed to get maps from %s", Path);
		bFinaleScavengeInProgress = false;
		delete FinaleFile;
		return;
	}
	char Map[PLATFORM_MAX_PATH];
	GetCurrentMap(Map, sizeof(Map));
	if (!FinaleFile.JumpToKey(Map))
	{
		PrintToServer("ScavengeBotsDS Error: Failed to get map from %s", Path);
		bFinaleScavengeInProgress = false;
		delete FinaleFile;
		return;
	}
	FinaleFile.GetVector("origin", NozzleOrigin);
	FinaleFile.GetVector("angles", NozzleAngles);
	delete FinaleFile;
}

stock void LoadScavengeConfig()
{	
	char Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Path, sizeof(Path), "%s", CONFIG_SCAVENGE_DATA);
	if (!FileExists(Path))
	{
		PrintToServer("ScavengeBotsDS Error: Cannot read the config %s", Path);
		bScavengeGameInProgress = false;
		return;
	}
	KeyValues ScavengeFile = new KeyValues("scavengemaps");
	if (!FileToKeyValues(ScavengeFile, Path))
	{
		PrintToServer("ScavengeBotsDS Error: Failed to get maps from %s", Path);
		bScavengeGameInProgress = false;
		delete ScavengeFile;
		return;
	}
	char Map[PLATFORM_MAX_PATH];
	GetCurrentMap(Map, sizeof(Map));
	if (!ScavengeFile.JumpToKey(Map))
	{
		PrintToServer("ScavengeBotsDS Error: Failed to get map from %s", Path);
		bScavengeGameInProgress = false;
		delete ScavengeFile;
		return;
	}
	ScavengeFile.GetVector("origin", NozzleOrigin3);
	ScavengeFile.GetVector("angles", NozzleAngles3);
	delete ScavengeFile;
}

Action BotUpdate(Handle timer)
{
	if (IsServerProcessing() && bScavengeBotsDS)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			updateBotBuddy(i);
			if (IsBot(i))
			{
				BotAI(i);
			}
		}
	}
	return Plugin_Continue;
}

Action CallBotsOff(Handle Timer)
{
	bFinaleScavengeInProgress = false;
	bScavengeInProgress = false;
	bScavengeGameInProgress = false;
	FinaleHasStarted = false;
	EscapeReady = false;
	return Plugin_Stop;
}

Action ScavengeUpdate(Handle Timer)
{	
	int objective = -1;
	while ((objective = FindEntityByClassname(objective, "game_scavenge_progress_display")) != -1)
	{
		if (GetEntProp(objective, Prop_Send, "m_bActive", 1) && !FinaleHasStarted && !bFinaleScavengeInProgress && !bScavengeGameInProgress && !EscapeReady && !IsInvalidMap())
		{
			bScavengeInProgress = true;
		}
		else
		{
			bScavengeInProgress = false;
		}
	}
	return Plugin_Stop;
}

Action ScavengeDoubleCheckStart(Handle Timer)
{
	int objective2 = -1;
	while ((objective2 = FindEntityByClassname(objective2, "game_scavenge_progress_display")) != -1)
	{
		if ((GetEntProp(objective2, Prop_Send, "m_bActive", 1)) && !IsScavenge() && !FinaleHasStarted && !bFinaleScavengeInProgress && !bScavengeGameInProgress && !EscapeReady && !IsInvalidMap())
		{
			bScavengeInProgress = true;
			LoadConfig();
		}
		else 
		{
			CreateTimer(0.1, ScavengeUpdate);
		}
	}
	while ((objective2 = FindEntityByClassname(objective2, "point_prop_use_target")) != INVALID_ENT_REFERENCE)
	{
		GasNozzle = objective2;
		HookSingleEntityOutput(objective2, "OnUseStarted", OnUseStarted);
		HookSingleEntityOutput(objective2, "OnUseCancelled", OnUseCancelled);
		HookSingleEntityOutput(objective2, "OnUseFinished", OnUseFinished);
	}
	return Plugin_Stop;
}

Action EscapeTime(Handle Timer)
{
	bFinaleScavengeInProgress = false;
	bScavengeInProgress = false;
	EscapeReady = true;
	return Plugin_Stop;
}

// Finds the nearest carryable gas can to an entity. If "pairedCanDist" is specified, this function will only consider a pair of gas cans within the range specified by "pairedCanDist".
int findNearestGas(int client, int maxDist, int pairedCanDist = -1)
{
	float Origin[3], TOrigin[3], distance = 0.0, storeddist = 0.0;
	int storedent = -1, entity = -1;
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
	while ((entity = FindEntityByClassname(entity, "weapon_gascan")) != INVALID_ENT_REFERENCE)
	{
		if (entity != client && IsValidGasCan(entity) && !IsGasCanOwned(entity))
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
			distance = GetVectorDistance(Origin, TOrigin);
			if (storeddist == 0.0 || storeddist > distance)
			{
				if (distance <= maxDist || maxDist == -1)
				{
					// If not looking for pairs, remember the closest gas can so far. If looking for pairs, only remember if a counterpart gas can exists.
					if (pairedCanDist < 0 || (pairedCanDist >= 0 && findNearestGas(entity, pairedCanDist) > -1))
					{
						storedent = entity;
						storeddist = distance;
					}
				}
			}
		}
	}
	return storedent;
}

// Should use assignBotsGas() unless you need to override standard gas assignment logic.
// Set up Bot assignments to find and collect a gas can near an "origin" entity. "pairedCanDist" specifies max distance of a pair of cans.
int assignNearestGas(int client, int origin, int maxDist, int pairedCanDist = -1)
{
	int gas = -1;
	gas = findNearestGas(origin, maxDist, pairedCanDist);
	if (gas > -1)
	{
		BotTarget[client] = gas;
		BotAction[client] = 1;
		BotAIUpdate[client] = 10;
		BotUseGasCan[client] = -1;
		BotAbortTick[client] = 50;
	}
	return gas;
}

// Assigns Bots to find gas. Assignments will adjust automatically if buddy system is active or not.
int assignBotGas(int client, int origin, int maxDist)
{
	if (!IsBot(client))
	{
		return -1;
	}
	
	int gas = -1, b = BotBuddy[client];

	if (!bScavengeBuddy)
	{
		return assignNearestGas(client, origin, maxDist);
	}
	
	// If Buddy system is active and neither have assignments, try to find pair of cans.
	if (IsBot(b) && !isBuddyBusy(client) && !isBuddyBusy(b))
	{
		gas = assignNearestGas(client, origin, maxDist, 400);
		if (gas > -1)
		{
			assignNearestGas(b, gas, 400);
			return gas;
		}
		else
		{
			gas = assignNearestGas(client, origin, maxDist);
			if (gas > -1)
			{
				assignNearestGas(b, gas, maxDist);
			}
			return gas;
		}
	}
	else
	{
		// If there is no buddy or buddy already has an assigment, find a single gas can.
		return assignNearestGas(client, origin, maxDist);
	}
}

// Maintain Bot Buddy Pairings
void updateBotBuddy(int client)
{
	if (bScavengeBuddy && isScavengeActive())
	{
		// If this bot is alive, just double check we have a buddy assigned.
		if (IsBot(client))
		{
			int isBW = GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
			// If no buddy is assigned, find a new buddy
			if (BotBuddy[client] == -1 && isBW == 0)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (i != client && IsBot(i) && BotBuddy[i] == -1 && GetEntProp(i, Prop_Send, "m_bIsOnThirdStrike") == 0)
					{
						BotBuddy[client] = i;
						BotBuddy[i] = client;
						break;
					}
				}
			}
			else
			{
				// If a buddy is already assigned, check if bot is healthy enough and they are also buddies with us. If not, break the pairing.
				int i = BotBuddy[client];
				if (!IsBot(i) || GetEntProp(i, Prop_Send, "m_bIsOnThirdStrike") == 1)
				{
					BotBuddy[client] = -1;
					if (IsBot(i))
					{
						BotBuddy[i] = -1;
					}
				}
				else
				{
					if (BotBuddy[i] != client)
					{
						BotBuddy[client] = -1;
					}
				}
				if (client == i)
				{
					BotBuddy[client] = -1;
				}
			}
		}
		if (isTeammate(client))
		{
			updateHumanBuddy(client);
		}
	}
}

void updateHumanBuddy(int client)
{
	if (!bScavengeEscort || !bScavengeBuddy)
	{
		return;
	}
	
	// Humans only need to check if their bot buddy is still assigned to them.
	if (IsHumanSurvivor(client) && HumanBuddy[client] >= 0)
	{
		if (!IsBot(HumanBuddy[client]) || HumanBuddy[HumanBuddy[client]] != client)
		{
			HumanBuddy[client] = -1;
		}
		return;
	}
	
	// If this is not a bot, no further code logic is needed.
	if (!IsBot(client))
	{
		return;
	}
	
	int buddy = HumanBuddy[client];
	
	// If Bot has found a CPU buddy, detach from human buddy.
	if (BotBuddy[client] != -1)
	{
		if (buddy != -1)
		{
			HumanBuddy[client] = -1;
			HumanBuddy[buddy] = -1;
		}
		return;
	}
	
	// If human buddy isn't human anymore, detach from this monster.
	if (buddy > -1 && !IsHumanSurvivor(buddy))
	{
		HumanBuddy[client] = -1;
		if (buddy > -1)
		{
			HumanBuddy[buddy] = -1;
		}
		buddy = -1;
	}
	
	// If Bot has no human buddy, assign nearest one.
	if (buddy == -1)
	{
		int dist = -1;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsHumanSurvivor(i))
			{
				int dist2 = getPlayerDistance(client, i);
				if (dist2 < dist || dist == -1)
				{
					buddy = i;
					dist = dist2;
				}
			}
		}
		if (buddy > -1)
		{
			HumanBuddy[client] = buddy;
			HumanBuddy[buddy] = client;
		}
		return;
	}
	
	// If Bot already has a human buddy, re-assign if another human bumps into us.
	if (buddy != -1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsHumanSurvivor(i) && getPlayerDistance(client, i) < 100)
			{
				if (buddy != i)
				{
					HumanBuddy[client] = i;
					HumanBuddy[buddy] = -1;
					HumanBuddy[i] = client;
				}
				return;
			}
		}
	}
}

void updateBotMove(int client, float TOrigin[3])
{
	float Origin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);

	if (IsPlayerHeld(client) || IsPlayerIncap(client))
	{
		BotAction[client] = 0;	
	}
	if (BotAbortTick[client] > 0)
	{
		float distance = GetVectorDistance(Origin, BotCheckPos[client]);
		if (distance < 15.0)
		{
			BotAbortTick[client] -= 1;
			if (BotAbortTick[client] == 0)
			{
				BotAction[client] = 6;
				BotAbortTick[client] = 60;
				BotAIUpdate[client] = 50;
				L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
				
				return;
			}
		}
		else
		{
			GetClientAbsOrigin(client, BotCheckPos[client]);
			BotAbortTick[client] = 60;
		}
	}

	if (BotAIUpdate[client] > 0)
	{
		BotAIUpdate[client] -= 1;
	}
	if (BotAIUpdate[client] <= 0)
	{
		L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", TOrigin[0], TOrigin[1], TOrigin[2], GetClientUserId(client));
		BotAIUpdate[client] = 10;
	}
}

void moveToEntity(int client, int item)
{
	float target[3];
	GetEntPropVector(item, Prop_Send, "m_vecOrigin", target);
	updateBotMove(client, target);
}

// Check if Buddy Bot is going towards gas can but does not yet have it.
bool isBuddyGettingGas(int b)
{
	return IsBot(b) && BotTarget[b] > -1 && (BotAction[b] >= 0 && !IsHoldingGasCan(b));
}

// Check if Buddy Bot is at any stage of gas can retrieval.
bool isBuddyBusy(int b)
{
	return IsBot(b) && BotAction[b] >= 0 && BotTarget[b] > -1;
}

void verifyGasTarget(int client)
{
	int gas = BotTarget[client];
	if (!IsHoldingGasCan(client) && IsGasCanOwned(gas))
	{
		BotTarget[client] = -1;
	}
}

// Buddy Bot AI. Executes Buddy AI Logic and returns true if so. This function is not responsible for checking validity of buddies. Use updateBotBuddy() to maintain correct buddy pairings.
bool updateBuddyMove(int client)
{
	if (!bScavengeBuddy || !IsBot(client))
	{
		return false;
	}

	// Verify gas can assignment is valid.
	verifyGasTarget(client);
	
	int buddy = BotBuddy[client], leader = -1, escort = -1;
	
	// If Bot does not have a CPU Buddy, try to buddy with human.
	if (buddy == -1 || !IsBot(buddy))
	{
		// If human buddies are allowed, function will transfer AI control to human-buddy logic.
		if (bScavengeEscort)
		{
			return updateEscortMove(client);
		}
		else
		{
			return false;
		}
	}
	
	// Figure out which bot is leader.
	if (client < buddy)
	{
		leader = client;
		escort = buddy;
	}
	else
	{
		leader = buddy;
		escort = client;
	}
	
	// If bot fetching gas is separated from buddy, try to regroup.
	if (isBuddyGettingGas(client) && getPlayerDistance(client, buddy) > 300)
	{
		// Leader has priority path-finding.
		if (client != leader || getPlayerDistance(client, buddy) > 600)
		{
			moveToEntity(client, buddy);
			return true;
		}
	}
	
	// If this bot has no assignment, we will follow the buddy if they do have one.
	if (!isBuddyBusy(client) && isBuddyBusy(buddy))
	{
		// Try to find a neighboring gas can to buddy's target or search for nearby one during return trip.
		int gas = -1;
		if (isBuddyGettingGas(buddy))
		{
			gas = assignBotGas(client, BotTarget[buddy], 600);
		}
		else if (isBuddyBusy(buddy))
		{
			gas = assignBotGas(client, buddy, 600);
		}
		if (gas > -1)
		{
			// Since Leader has priority, make sure leader goes for the farthest gas can first.
			if (getEntityDistance(GasNozzle, BotTarget[leader]) < getEntityDistance(GasNozzle, BotTarget[escort]))
			{
				gas = BotTarget[leader];
				BotTarget[leader] = BotTarget[escort];
				BotTarget[escort] = gas;
			}
		}
		
		
		if (isBuddyGettingGas(buddy))
		{
			moveToEntity(client, BotTarget[buddy]);
		}
		else
		{
			moveToEntity(client, buddy);
		}
		return true;
	}
	
	// If both bots are going to gas cans, the escort will follow leader.
	if (client == escort && isBuddyGettingGas(leader) && isBuddyGettingGas(escort))
	{
		moveToEntity(client, BotTarget[leader]);
		return true;
	}
	
	// If only one bot has gas can, follow buddy only if they are going to gas can.
	if (IsHoldingGasCan(client) && isBuddyGettingGas(buddy))
	{
		moveToEntity(client, BotTarget[buddy]);
		return true;
	}
	
	// If both bots have gas cans, carry gas back while trying to stay together.
	if (IsHoldingGasCan(client) && IsHoldingGasCan(buddy) && getEntityDistance(client, buddy) > 300)
	{
		// Leader has priority if bots end up taking two different paths back home.
		if (client != leader || getEntityDistance(client, buddy) > 600)
		{
			moveToEntity(client, buddy);
			return true;
		}
	}

	return false;
}

// Buddy AI Logic for human-cpu pairings. Returns true if instructions are given to bots.
bool updateEscortMove(int client)
{
	int buddy = HumanBuddy[client];
	if (!bScavengeEscort || !IsHumanSurvivor(buddy) || IsBot(BotBuddy[client]))
	{
		return false;
	}
	
	// If bot has gas can and is near nozzle, let standard gas can logic control.
	if (IsHoldingGasCan(client) && getEntityDistance(client, GasNozzle) < 500)
	{
		return false;
	}
	
	// If assigned gas can is far away, unassign it.
	if (!IsHoldingGasCan(client) && getEntityDistance(client, BotTarget[client]) > 750)
	{
		BotTarget[client] = -1;
	}
	
	// If Human is far away, regroup with human.
	if (getPlayerDistance(client, buddy) > 400)
	{
		moveToEntity(client, buddy);
		return true;
	}
	
	// If no gas can assignment, follow human. If human finds a new gas can, assign it to bot.
	if (!IsHoldingGasCan(client) && BotTarget[client] == -1)
	{
		moveToEntity(client, buddy);
		assignNearestGas(client, buddy, 100);
		return true;
	}
	
	return false;
	
}

int getBuddy(int client)
{
	if (bScavengeBuddy)
	{
		int b = -1;
		b = BotBuddy[client];
		if (IsBot(b))
		{
			return b;
		}
		else
		{
			if (bScavengeEscort)
			{
				b = HumanBuddy[client];
				if (isTeammate(b))
				{
					return b;
				}
				else
				{
					return -1;
				}
			}
		}
	}
	return -1;
}

stock bool isBuddyNeeded(int client)
{
	if (bScavengeBuddy)
	{
		int b = getBuddy(client);
		if (isTeammate(b) && (IsPlayerIncap(b) || IsPlayerHeld(b)))
		{
			return true;
		}
	}
	return false;
}

/*bool shouldEscortFight(int client)
{
	return IsAssistNeeded() || isBuddyNeeded(client) || isCommonNearby(client, 50) || isBuddyNeeded(client) || shouldCover(client) || (isInfectedSighted(client) && isTankActive()) || getPlayerDistance(client, BotBuddy[client]) < 50;
}*/

stock void BotAI(int client)
{
	if (IsBot(client) && bScavengeInProgress || IsBot(client) && bFinaleScavengeInProgress || IsBot(client) && bScavengeGameInProgress)
	{
		//PrintToChatAll("client %N, action %i, target %i", client, BotAction[client], BotTarget[client]);

		if (BotAction[client] == -1)
		{
			int entity = -1;
			while ((entity = FindEntityByClassname(entity, "weapon_gascan")) != INVALID_ENT_REFERENCE)
			{
				if (IsValidGasCan(entity) && !IsGasCanOwned(entity))
				{
					BotTarget[client] = -1;
					BotAction[client] = 0;
					BotAIUpdate[client] = -1;
					BotUseGasCan[client] = -1;
					BotAbortTick[client] = -1;
					for (int i = 0; i <= 2; i++)
					{
						BotCheckPos[client][i] = 0.0;
					}
				}
			}
		}
		else if (BotAction[client] == 0)
		{
			if (!IsPlayerHeld(client) && !IsPlayerIncap(client))
			{
				// Buddy System instructions have priority and will interrupt non-buddy logic flow.
				if (bScavengeBuddy)
				{
					if (updateBuddyMove(client))
					{
						BotAction[client] = 1;
						return;
					}
				}
				
				if (BotTarget[client] > 0)
				{
					int entity = BotTarget[client];
					if (IsGasCan(entity))
					{
						float TOrigin[3];
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
						L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", TOrigin[0], TOrigin[1], TOrigin[2], GetClientUserId(client));
						BotAction[client] = 1;
						BotAIUpdate[client] = 10;
						BotUseGasCan[client] = -1;
						BotAbortTick[client] = 50;
						GetClientAbsOrigin(client, BotCheckPos[client]);
					}
					else
					{
						BotTarget[client] = -1;
					}
				}
				else
				{
					// Try to find gas next to us.
					if (assignBotGas(client, client, 500) > -1)
					{
						return;
					}
					
					// Find gas can near where other survivors are headed if none nearby.
					for (int i = 1; i <= MaxClients; i++)
					{
						if (i != client && BotTarget[i] > -1 && IsBot(i) && !IsPlayerIncap(i) && !IsPlayerHeld(i) && isBuddyGettingGas(i))
						{
							if (assignBotGas(client, BotTarget[i], -1) > -1)
							{
								return;
							}
						}
					}
					
					// If no one has any ideas for locations to search, search the entire map for a gas can.
					if (assignBotGas(client, client, -1) > -1)
					{
						return;
					}
					else
					{
						BotAction[client] = -1;
						L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
						return;
					}
				}
			}
		}
		else if (BotAction[client] == 1)
		{
			float Origin[3], TOrigin[3];
			
			// Buddy system logic interrupts non-buddy logic
			if (bScavengeBuddy)
			{
				if (updateBuddyMove(client))
				{
					return;
				}
			}
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			int entity = BotTarget[client];
			if (IsGasCan(entity) && !IsGasCanOwned(entity))
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
			}
			else
			{
				BotTarget[client] = -1;
				BotAction[client] = 0;
			}
			if (IsPlayerHeld(client) || IsPlayerIncap(client))
			{
				BotAction[client] = 0;	
			}
			if (BotAbortTick[client] > 0)
			{
				float distance = GetVectorDistance(Origin, BotCheckPos[client]);
				if (distance < 15.0)
				{
					BotAbortTick[client] -= 1;
					if (BotAbortTick[client] == 0)
					{
						// BotTarget[client] = -1;
						BotAction[client] = 6;
						BotAbortTick[client] = 60;
						BotAIUpdate[client] = 50;
						L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
					}
				}
				else
				{
					GetClientAbsOrigin(client, BotCheckPos[client]);
					BotAbortTick[client] = 60;
				}
			}
			if (BotAIUpdate[client] > 0)
			{
				BotAIUpdate[client] -= 1;
				if (BotAIUpdate[client] == 0)
				{
					if (entity > 0 && IsValidEntity(entity))
					{
						L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", TOrigin[0], TOrigin[1], TOrigin[2], GetClientUserId(client));
						BotAIUpdate[client] = 10;
					}
				}
			}
			float distance = GetVectorDistance(Origin, TOrigin);
			if (distance < 50.0)
			{
				PickupGasCan(client, entity);
			}
			else
			{
				float ZOrigin[3];
				ZOrigin[0] = Origin[0];
				ZOrigin[1] = Origin[1];
				ZOrigin[2] = Origin[2] + 40.0;
				distance = GetVectorDistance(ZOrigin, TOrigin);
				if (distance < 50.0)
				{
					PickupGasCan(client, entity);
				}
				else
				{
					ZOrigin[2] = Origin[2] - 40.0;
					distance = GetVectorDistance(ZOrigin, TOrigin);
					if (distance < 50.0)
					{
						PickupGasCan(client, entity);
					}
				}
			}
		}
		else if (BotAction[client] == 2)
		{
			if (!IsPlayerHeld(client) && !IsPlayerIncap(client) && IsGasCan(IsHoldingGasCan(client)) && !bScavengeInProgress && bFinaleScavengeInProgress && !bScavengeGameInProgress)
			{
				L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", NozzleOrigin[0], NozzleOrigin[1], NozzleOrigin[2], GetClientUserId(client));
				BotAction[client] = 3;
				BotAIUpdate[client] = 10;
				BotAbortTick[client] = 50;
				GetClientAbsOrigin(client, BotCheckPos[client]);
			}
			else if (!IsPlayerHeld(client) && !IsPlayerIncap(client) && IsGasCan(IsHoldingGasCan(client)) && bScavengeInProgress && !bFinaleScavengeInProgress && !bScavengeGameInProgress)
			{
				L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", NozzleOrigin2[0], NozzleOrigin2[1], NozzleOrigin2[2], GetClientUserId(client));
				BotAction[client] = 3;
				BotAIUpdate[client] = 10;
				BotAbortTick[client] = 50;
				GetClientAbsOrigin(client, BotCheckPos[client]);
			}
			else if (!IsPlayerHeld(client) && !IsPlayerIncap(client) && IsGasCan(IsHoldingGasCan(client)) && !bScavengeInProgress && !bFinaleScavengeInProgress && bScavengeGameInProgress)
			{
				L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", NozzleOrigin3[0], NozzleOrigin3[1], NozzleOrigin3[2], GetClientUserId(client));
				BotAction[client] = 3;
				BotAIUpdate[client] = 10;
				BotAbortTick[client] = 50;
				GetClientAbsOrigin(client, BotCheckPos[client]);
			}
			else
			{
				BotAction[client] = 0;
			}
		}
		else if (BotAction[client] == 3)
		{
			// Buddy system logic interrupts non-buddy logic
			if (bScavengeBuddy)
			{
				if (updateBuddyMove(client))
				{
					return;
				}
			}
		
			if (IsPlayerHeld(client) || IsPlayerIncap(client) || IsHoldingGasCan(client) == 0)
			{
				BotAction[client] = 0;	
			}
			if (BotAbortTick[client] > 0)
			{
				float Origin[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
				float distance = GetVectorDistance(Origin, BotCheckPos[client]);
				if (distance < 15.0)
				{
					BotAbortTick[client] -= 1;
					if (BotAbortTick[client] == 0)
					{
						// BotTarget[client] = -1;
						BotAction[client] = 6;
						BotAbortTick[client] = 60;
						BotAIUpdate[client] = 50;
						L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
					}
				}
				else
				{
					GetClientAbsOrigin(client, BotCheckPos[client]);
					BotAbortTick[client] = 60;
				}
			}
			if (BotAIUpdate[client] > 0 && !bScavengeInProgress && bFinaleScavengeInProgress && !bScavengeGameInProgress)
			{
				BotAIUpdate[client] -= 1;
				if (BotAIUpdate[client] == 0)
				{
					L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", NozzleOrigin[0], NozzleOrigin[1], NozzleOrigin[2], GetClientUserId(client));
					BotAIUpdate[client] = 10;
				}
			}
			if (BotAIUpdate[client] > 0 && bScavengeInProgress && !bFinaleScavengeInProgress && !bScavengeGameInProgress)
			{
				BotAIUpdate[client] -= 1;
				if (BotAIUpdate[client] == 0)
				{
					L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", NozzleOrigin2[0], NozzleOrigin2[1], NozzleOrigin2[2], GetClientUserId(client));
					BotAIUpdate[client] = 10;
				}
			}
			if (BotAIUpdate[client] > 0 && !bScavengeInProgress && !bFinaleScavengeInProgress && bScavengeGameInProgress)
			{
				BotAIUpdate[client] -= 1;
				if (BotAIUpdate[client] == 0)
				{
					L4D2_RunScript("CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", NozzleOrigin3[0], NozzleOrigin3[1], NozzleOrigin3[2], GetClientUserId(client));
					BotAIUpdate[client] = 10;
				}
			}
			float Origin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			float distance = GetVectorDistance(Origin, NozzleOrigin);
			if (distance < 50.0)
			{
				if (BotUseGasCan[client] == -1)
				{
					BotUseGasCan[client] = 1;
				}
			}
			float Origin2[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin2);
			float distance2 = GetVectorDistance(Origin2, NozzleOrigin2);
			if (distance2 < 50.0)
			{
				if (BotUseGasCan[client] == -1)
				{
					BotUseGasCan[client] = 1;
				}
			}
			float Origin3[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin3);
			float distance3 = GetVectorDistance(Origin3, NozzleOrigin3);
			if (distance3 < 50.0)
			{
				if (BotUseGasCan[client] == -1)
				{
					BotUseGasCan[client] = 1;
				}
			}
		}
		else if (BotAction[client] == 4)
		{
			if (!IsAssistNeeded())
			{
				if (IsGasCan(BotTarget[client]) && getEntityDistance(client, BotTarget[client]) > 750)
				{
					BotTarget[client] = -1;
				}
				BotAction[client] = 0;
			}
		}
		else if (BotAction[client] == 5)
		{
			if (!IsPlayerHeld(client) && !IsPlayerIncap(client) && !shouldBotFight(client))
			{
				if (GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 0)
				{
					BotAction[client] = 0;
				}
			}
			
			// If bot needs to heal, abandon the gas can to a healthier bot or simply get back to it later.
			if ((!bScavengeBuddy && shouldHeal(client)) || GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 1)
			{
				BotTarget[client] = -1;
			}
		}
		else if (BotAction[client] == 6)
		{
			if (BotAIUpdate[client] > 0)
			{
				BotAIUpdate[client] -= 1;
				if (BotAIUpdate[client] == 0)
				{
					BotAction[client] = 0;
				}
			}
		}
	}
}

stock void PickupGasCan(int client, int entity)
{
	if (IsBot(client) && entity > 0 && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Use", client);
		BotAction[client] = 2;
	}
}

stock bool IsAssistNeeded()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i))
		{
			if (IsPlayerIncap(i) || IsPlayerHeld(i))
			{
				if (bScavengeBuddy && !isTankActive())
				{
					int b = getBuddy(i);
					if (isTeammate(b) && (BotBuddy[b] == i || HumanBuddy[b] == i) && !IsPlayerIncap(b) && !IsPlayerHeld(b) && getPlayerDistance(i, b) < 800)
					{
						return false;
					}
				}
				return true;
			}
		}
	}
	return false;
}

stock bool isGhost(int i)
{
	return view_as<bool>(GetEntProp(i, Prop_Send, "m_isGhost"));
}

stock bool isInfected(int i)
{
	return i > 0 && i <= MaxClients && IsClientInGame(i) && GetClientTeam(i) == 3 && !isGhost(i);
}

// Calculate the angles from client to target
stock void computeAimAngles(int client, int target, float angles[3], int type = 1)
{
	float target_pos[3], self_pos[3], lookat[3];
	GetClientEyePosition(client, self_pos);
	switch (type)
	{
		case 1:
		{ // Eye (Default)
			GetClientEyePosition(target, target_pos);
		}
		case 2:
		{ // Body
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", target_pos);
		}
		case 3:
		{ // Chest
			GetClientAbsOrigin(target, target_pos);
			target_pos[2] += 45.0;
		}
	}
	MakeVectorFromPoints(self_pos, target_pos, lookat);
	GetVectorAngles(lookat, angles);
}

bool traceFilter(int entity, int mask, any self)
{
	return entity != self;
}

// Determine if the head of the target can be seen from the client
stock bool isVisibleTo(int client, int target)
{
	bool ret = false;
	float aim_angles[3], self_pos[3];

	GetClientEyePosition(client, self_pos);
	computeAimAngles(client, target, aim_angles);
	
	Handle trace = TR_TraceRayFilterEx(self_pos, aim_angles, MASK_VISIBLE, RayType_Infinite, traceFilter, client);
	if (TR_DidHit(trace))
	{
		int hit = TR_GetEntityIndex(trace);
		if (hit == target)
		{
			ret = true;
		}
	}
	CloseHandle(trace);
	return ret;
}

/* Determine if the head of the entity can be seen from the client */
stock bool isVisibleToEntity(int target, int client)
{
	bool ret = false;
	float aim_angles[3], self_pos[3], target_pos[3], lookat[3];

	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", target_pos);
	GetClientEyePosition(client, self_pos);
	
	MakeVectorFromPoints(target_pos, self_pos, lookat);
	GetVectorAngles(lookat, aim_angles);
	
	Handle trace = TR_TraceRayFilterEx(target_pos, aim_angles, MASK_VISIBLE, RayType_Infinite, traceFilter, target);
	if (TR_DidHit(trace))
	{
		int hit = TR_GetEntityIndex(trace);
		if (hit == client)
		{
			ret = true;
		}
	}
	CloseHandle(trace);
	return ret;
}

int getPlayerDistance(int x, int y)
{
	float xPos[3], yPos[3];
	GetClientAbsOrigin(x, xPos);
	GetClientAbsOrigin(y, yPos);
	return RoundToNearest(GetVectorDistance(xPos, yPos, false));
}

int getEntityDistance(int client, int target)
{
	if (IsValidEntity(client) && IsValidEntity(target))
	{
		float selfPos[3], targetPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", selfPos);
		GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", targetPos);
		return RoundToNearest(GetVectorDistance(selfPos, targetPos, false));
	}
	return -1;
}

int getVisibleInfected(int client, int iDist)
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if (isInfected(x) && IsPlayerAlive(x) && ((getPlayerDistance(client, x) < iDist)))
		{
			if (isVisibleTo(client, x))
			{
				return x;
			}
		}
	}
	return -1;
}

bool isInfectedSighted(int client)
{
	// If Tank is active, we should be extra-cautious.
	int iDist = 750;
	if (isTankActive())
	{
		iDist = 1500;
	}

	int si = getVisibleInfected(client, iDist);
	if (si > -1)
	{
		return true;
	}
	return false;
}

stock bool IsCommonInfected(int iEntity)
{
	if (iEntity && IsValidEntity(iEntity))
	{
		char strClassName[64];
		GetEntityClassname(iEntity, strClassName, sizeof(strClassName));
		if (StrContains(strClassName, "infected", false) > -1)
			return true;
	}
	return false;
}

bool isCommonNearby(int client, int dist)
{
	for (int iEntity = MaxClients+1; iEntity <= 2048; ++iEntity)
	{
		if (IsCommonInfected(iEntity) && GetEntProp(iEntity, Prop_Data, "m_iHealth") > 0 && getEntityDistance(client, iEntity) < dist)
		{
			
			if (isVisibleToEntity(iEntity, client))
			{
				return true;
			}
		}
	}
	return false;
}

bool isTankActive()
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if (isInfected(x) && IsPlayerAlive(x))
		{
			int zombieClass = GetEntProp(x, Prop_Send, "m_zombieClass");
			if (zombieClass == 8)
			{
				return true;
			}
		}
	}
	return false;
}

bool hasHealthItem(int client)
{
	int hasMedkit = false;
	int aidItem = GetPlayerWeaponSlot(client, 3);
	if (IsValidEdict(aidItem))
	{
		char item[128];
		GetEntityClassname(aidItem, item, sizeof(item));
		if (StrContains(item, "weapon_first_aid_kit", false) > -1)
		{
			hasMedkit = true;
		}
	}
	
	int hasTempHP = IsValidEdict(GetPlayerWeaponSlot(client, 4));
	if (hasMedkit || hasTempHP)
	{
		return true;
	}

	return false;
}

bool isLowHP(int client)
{
	int baseHP = GetEntProp(client, Prop_Send, "m_iHealth");
	float tempHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	tempHP = tempHP * hpMultiplier;
	return baseHP + tempHP < 30;
}

bool shouldHeal(int client)
{
	return hasHealthItem(client) && isLowHP(client) && !isTankActive();
}

// Should bots stick together if one of them needs healing?
public bool shouldCover(int client)
{
	if (isTankActive())
	{
		return false;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (isTeammate(i) && !IsPlayerIncap(i) && !IsPlayerHeld(i))
		{
			if ((isLowHP(client) || isLowHP(i)) && isVisibleTo(client, i) && getPlayerDistance(client, i) < 500 && (hasHealthItem(client) || hasHealthItem(i)))
			{
				return true;
			}
		}
	}
	return false;
}

bool isGasCanClose(int client, int gas)
{
	return IsGasCan(gas) && getEntityDistance(client, gas) < 200;
}

bool shouldBotFight(int client)
{	
	// If Bot is not currently engaged we fight only when important enemy appears
	if (BotAction[client] != 4 && BotAction[client] != 5)
	{
		if (IsAssistNeeded() || shouldHeal(client) || isInfectedSighted(client) || shouldCover(client) || isBuddyNeeded(client) || (BotAction[client] != -1 && BotAction[client] != 3 && isCommonNearby(client, 100) && !isGasCanClose(client, BotTarget[client])))
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		// If Bot is already fighting, we do not stop until all threats are cleared.
		if (!isInfectedSighted(client) && !IsAssistNeeded() && !shouldHeal(client) && !isCommonNearby(client, 100) && !shouldCover(client) && !isBuddyNeeded(client))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
}

bool isScavengeActive()
{
	if (!bScavengeInProgress && !bFinaleScavengeInProgress && !bScavengeGameInProgress)
	{
		return false;
	}
	else
	{
		return true;
	}
}

void OnPreThink(int client)
{
	if (bScavengeBotsDS)
	{
		if (IsBot(client))
		{
			// Drop extra gas cans if scavenge ended. Only relevant in singleplayer where required gas cans are fewer than available.
			if (IsBot(client) && IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client) && !isScavengeActive())
			{
				int buttons = GetClientButtons(client);
				SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
				ResetClientArrays(client);
			}
			
			// If no Scavenge is active, stop any further Pre-Think code from executing.
			if (!isScavengeActive)
			{
				return;
			}
			
			// If bot loses track of holding gas can, we fix the assignment.
			int holdGas = IsHoldingGasCan(client);
			if (BotTarget[client] == -1 && holdGas > 0)
			{
				BotTarget[client] = holdGas;
				BotAction[client] = 3;
			}
			
			// If Bot is holding gas can while in danger, drop the gas can.
			if (!IsPlayerHeld(client) && !IsPlayerIncap(client) && (BotAction[client] == 4 || BotAction[client] == 5))
			{
				if (IsGasCan(IsHoldingGasCan(client)))
				{
					int buttons = GetClientButtons(client);
					SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
				}
			}
			
			// Stop collecting cans if any significant danger to team is present
			if (!IsPlayerHeld(client) && !IsPlayerIncap(client) && (BotAction[client] != -1 && BotAction[client] != 4 && BotAction[client] != 5) && shouldBotFight(client))
			{
				// Drop can if special infected on the field and bot is not in SI kill-mode.
				if (IsGasCan(IsHoldingGasCan(client)))
				{
					int buttons = GetClientButtons(client);
					SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
				}
				
				if (IsAssistNeeded())
				{
					BotAction[client] = 4;
				}
				else
				{
					BotAction[client] = 5;
					
				}
				BotAIUpdate[client] = 10;
				L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
			}
			
			// Double check Bot Update timers are active when we need them
			if (BotAction[client] > 0 && BotAIUpdate[client] < 0)
			{
				BotAIUpdate[client] = 0;
			}
		
			if (BotAction[client] == 1)
			{
				if (GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 1 || shouldHeal(client))
				{
					BotAction[client] = 5;
					L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
				}
				int threats = GetEntProp(client, Prop_Send, "m_hasVisibleThreats");
				if (threats > 0)
				{
					
					// Blindly Shoot to kill
					int buttons = GetClientButtons(client);
					SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
				}
				
				// Fix Rare error where bot is searching for gas can while already holding one.
				if (IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client))
				{
					int buttons = GetClientButtons(client);
					SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
					BotAction[client] = 5;
					BotTarget[client] = -1;
					L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
				}
			}
			else if (BotAction[client] == 2)
			{
				if (IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client))
				{
					int threats = GetEntProp(client, Prop_Send, "m_hasVisibleThreats");
					if (threats > 0)
					{
						int buttons = GetClientButtons(client);
						SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK2);
					}
					if (IsAssistNeeded())
					{
						int buttons = GetClientButtons(client);
						SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
						BotAction[client] = 4;
						L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
					}
				}
			}
			else if (BotAction[client] == 3)
			{
				if (BotUseGasCan[client] == 1)
				{
					if (IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client) && !bScavengeInProgress && bFinaleScavengeInProgress && !bScavengeGameInProgress)
					{
						int owner = GetEntPropEnt(GasNozzle, Prop_Send, "m_useActionOwner");
						if (owner <= 0)
						{
							TeleportEntity(client, NozzleOrigin, NozzleAngles, NULL_VECTOR);
							int buttons = GetClientButtons(client);
							SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
						}
						else
						{
							int entity = GetEntPropEnt(owner, Prop_Send, "m_hOwner");
							if (entity == client)
							{
								int buttons = GetClientButtons(client);
								SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
							}
						} 
					}
					else if (IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client) && bScavengeInProgress && !bFinaleScavengeInProgress && !bScavengeGameInProgress)
					{
						int owner = GetEntPropEnt(GasNozzle, Prop_Send, "m_useActionOwner");
						if (owner <= 0)
						{
							TeleportEntity(client, NozzleOrigin2, NozzleAngles2, NULL_VECTOR);
							int buttons = GetClientButtons(client);
							SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
						}
						else
						{
							int entity = GetEntPropEnt(owner, Prop_Send, "m_hOwner");
							if (entity == client)
							{
								int buttons = GetClientButtons(client);
								SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
							}
						} 
					}
					else if (IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client) && !bScavengeInProgress && !bFinaleScavengeInProgress && bScavengeGameInProgress)
					{
						int owner = GetEntPropEnt(GasNozzle, Prop_Send, "m_useActionOwner");
						if (owner <= 0)
						{
							TeleportEntity(client, NozzleOrigin3, NozzleAngles3, NULL_VECTOR);
							int buttons = GetClientButtons(client);
							SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
						}
						else
						{
							int entity = GetEntPropEnt(owner, Prop_Send, "m_hOwner");
							if (entity == client)
							{
								int buttons = GetClientButtons(client);
								SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
							}
						} 
					}
				}
				else
				{
					int threats = GetEntProp(client, Prop_Send, "m_hasVisibleThreats");
					if (threats > 0)
					{
						int buttons = GetClientButtons(client);
						SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK2);
					}
					if (IsAssistNeeded() || GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 1)
					{
						int buttons = GetClientButtons(client);
						SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
						BotAction[client] = 4;
						L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
					}
				}
			}
			else if (BotAction[client] == 6)
			{
				if (IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client))
				{
					int buttons = GetClientButtons(client);
					SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
				}
			}
		}
	}
	else if (IsBot(client) && IsGasCan(IsHoldingGasCan(client)) && !IsPlayerHeld(client) && !IsPlayerIncap(client))
	{
		// Drop cans if mod is disabled
		int buttons = GetClientButtons(client);
		SetEntProp(client, Prop_Data, "m_nButtons", buttons|IN_ATTACK);
		L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
		
		if (BotAction[client] != -1)
		{
			ResetClientArrays(client);
		}
	}
}

void OnUseStarted(const char[] output, int entity, int activator, float delay)
{
	int gascan = GetEntPropEnt(entity, Prop_Send, "m_useActionOwner");
	if (gascan > 0 && IsValidEntity(gascan))
	{
		int client = GetEntPropEnt(gascan, Prop_Send, "m_hOwner");
		if (client > 0 && IsValidEntity(client))
		{
			SetEntProp(entity, Prop_Data, "m_iHammerID", client);
		}
	}
}

void OnUseCancelled(const char[] output, int entity, int activator, float delay)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		int client = GetEntProp(entity, Prop_Data, "m_iHammerID");
		if (IsBot(client))
		{
			BotUseGasCan[client] = -1;
			//PrintToChatAll("client %N cancel", client);
		}
	}
}

void OnUseFinished(const char[] output, int entity, int activator, float delay)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		int client = GetEntProp(entity, Prop_Data, "m_iHammerID");
		if (IsBot(client))
		{
			BotTarget[client] = -1;
			BotAction[client] = 0;
			BotAIUpdate[client] = -1;
			BotUseGasCan[client] = -1;
			//PrintToChatAll("client %N finish", client);
		}
	}
}

stock bool IsPlayerIncap(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}

stock bool IsPlayerHeld(int client)
{
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (jockey > 0 || charger > 0 || hunter > 0 || smoker > 0)
	{
		return true;
	}
	return false;
}

stock bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool IsBot(int client)
{
	if (IsSurvivor(client) && IsFakeClient(client) && IsPlayerAlive(client))
	{
		char classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "SurvivorBot", false))
		{
			return true;
		}
	}
	return false;
}

public bool IsHumanSurvivor(int client)
{
	return IsSurvivor(client) && !IsFakeClient(client) && IsPlayerAlive(client);
}

public bool isTeammate(int client)
{
	return IsSurvivor(client) && IsPlayerAlive(client);
}

stock bool IsGasCan(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_gascan", false))
			return true;
	}
	return false;
}

stock bool IsValidGasCan(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		// Added IsBot() check so that dead bots don't claim gas cans.
		if (IsBot(i) && BotTarget[i] > 0)
		{
			if (BotTarget[i] == entity)
			{
				return false;
			}
		}
	}
	return true;
}

stock bool IsGasCanOwned(int entity)
{
	if (IsGasCan(entity))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
		if (owner > 0)
		{
			return true;
		}
	}
	return false;
}

stock int IsHoldingGasCan(int client)
{
	if (IsBot(client))
	{
		int entity = GetPlayerWeaponSlot(client, 5);
		if (entity > 0 && IsValidEntity(entity))
		{
			char classname[24];
			GetEdictClassname(entity, classname, sizeof(classname));
			if (StrEqual(classname, "weapon_gascan", false))
			{
				return entity;
			}
		}
	}
	return 0;
}

stock int RGB_TO_INT(int red, int green, int blue) 
{
	return (blue * 65536) + (green * 256) + red;
}

stock void ScriptCommand(int client, const char[] command, const char[] arguments, any ...)
{
	char vscript[PLATFORM_MAX_PATH];
	VFormat(vscript, sizeof(vscript), arguments, 4);	
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags ^ FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, vscript);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}

stock bool IsScavenge()
{
	char gamemode[56];
	FindConVar("mp_gamemode").GetString(gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "scavenge", false) > -1)
		return true;
	return false;
}

stock bool IsCoop()
{
	char gamemode[56];
	FindConVar("mp_gamemode").GetString(gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "coop", false) > -1)
		return true;
	return false;
}
stock bool IsInvalidMap()
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if (StrEqual(mapname, "l4d2_pl_badwater", true))
	{
		return true;
	}
	return false;
}

stock void L4D2_RunScript(const char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) 
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
		{
			SetFailState("Could not create 'logic_script'");
		}
		DispatchSpawn(iScriptLogic);
	}

	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);

	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}
