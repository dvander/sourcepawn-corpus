/*
*	Plugin	: [L4D/2] Witchy Spawn Controller
*	Version	: 2.1
*	Game	: Left4Dead & Left4Dead 2
*	Coder	: Sheleu
*	Testers	: Myself and Dosergen (Ja-Forces)
*
*
*	Version 1.0 (05.09.10)
*		- Initial release
*
*	Version 1.1 (08.09.10)
*		- Fixed encountered error 23: Native detected error
*		- Fixed bug with counting alive witches
*		- Added removal of the witch when she far away from the survivors
*
*	Version 1.2 (09.09.10)
*		- Added precache for witch (L4D2)
*
*	Version 1.3 (16.09.10)
*		- Added removal director's witch
*		- Stopped spawn witches after finale start
*
*	Version 1.4 (24.09.10)
*		- Code optimization
*
*	Version 1.5 (17.05.11)
*		- Fixed error "Entity is not valid" (sapphire989's message)
*
*	Version 1.6 (23.01.20)
*		- Converted plugin source to the latest syntax utilizing methodmaps
*		- Added "z_spawn_old" method for L4D2
*
*	Version 1.7 (07.03.20)
*		- Added cvar "l4d_wispaco_enable" to enable or disable plugin
*
*	Version 1.8 (27.05.21)
*		- Added DEBUG log to file
*
*	Version 1.9 (03.08.22)
*		- Fixed SourceMod 1.11 warnings
*		- Fixed counter if director's witch spawns at the beginning of the map
*		- Various changes to clean up the code
*
*	Version 2.0 (01.05.23)
*		- Added support for "Left 4 DHooks Direct" natives
*		- Code optimization
*
*	Version 2.1 (05.11.24)
*		- Added cvar "l4d_wispaco_witch_weight" and "l4d_wispaco_witch_bride_weight"
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "2.1"

#define WITCH_MODEL "models/infected/witch.mdl"
#define BRIDE_MODEL "models/infected/witch_bride.mdl"
#define WITCH_SOUND "music/witch/witchencroacher.wav"
#define BRIDE_SOUND "music/witch/witchencroacher_bride.wav"

float   g_fWitchTimeMin,
        g_fWitchTimeMax,
        g_fWitchDistance;

int     g_iCountWitch,
        g_iCountWitchInRound,
        g_iCountWitchAlive,
        g_iWitchWeight,
        g_iWitchBrideWeight;

bool    g_bPluginEnable,
        g_bLeft4Dead2,
        g_bDirectorWitch,
        g_bFinaleStart,
        g_bDebugLog;

ConVar  g_hCvarEnable,
        g_hCvarCountWitchInRound,
        g_hCvarCountAliveWitch,
        g_hCvarWitchTimeMin,
        g_hCvarWitchTimeMax,
        g_hCvarWitchDistance,
        g_hCvarDirectorWitch,
        g_hCvarWitchWeight,
        g_hCvarWitchBrideWeight,
        g_hCvarFinaleStart,
        g_hCvarLog;
		
bool    g_bRunTimer = false,
        g_bLeftSafeArea = false,
        g_bWitchExec = false,
        g_bHookedEvents = false;

Handle  g_hSpawnTimer;

public Plugin myinfo =
{
	name = "[L4D/2] WiSpaCo",
	author = "Sheleu, Dosergen",
	description = "Witch revival manager by timer.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=137431"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2)
	{
		g_bLeft4Dead2 = true;
		return APLRes_Success;
	}
	else if (test == Engine_Left4Dead)
	{
		g_bLeft4Dead2 = false;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	CreateConVar("l4d_wispaco_version", PLUGIN_VERSION, "WiSpaCo plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_hCvarEnable = CreateConVar("l4d_wispaco_enable", "1", "Enable or disable the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarCountWitchInRound = CreateConVar("l4d_wispaco_limit", "0", "Sets the limit for the number of witches that can spawn in a round.", FCVAR_NOTIFY);
	g_hCvarCountAliveWitch = CreateConVar("l4d_wispaco_limit_alive", "2", "Sets the limit for the number of alive witches at any given time.", FCVAR_NOTIFY);
	g_hCvarWitchTimeMin = CreateConVar("l4d_wispaco_spawn_time_min", "90", "Minimum time for witches to spawn.", FCVAR_NOTIFY);
	g_hCvarWitchTimeMax = CreateConVar("l4d_wispaco_spawn_time_max", "180", "Maximum time for witches to spawn.", FCVAR_NOTIFY);
	g_hCvarWitchDistance = CreateConVar("l4d_wispaco_distance", "1500", "Distance from survivors beyond which the witch will be removed.", FCVAR_NOTIFY);
	g_hCvarDirectorWitch = CreateConVar("l4d_wispaco_director_witch", "0", "Enable or disable director's witch.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	if (g_bLeft4Dead2)
	{
		g_hCvarWitchWeight = CreateConVar("l4d_wispaco_witch_weight", "5", "Weight for a regular witch to spawn.", FCVAR_NOTIFY);
		g_hCvarWitchBrideWeight = CreateConVar("l4d_wispaco_witch_bride_weight", "5", "Weight for a witch bride to spawn.", FCVAR_NOTIFY);
	}
	g_hCvarFinaleStart = CreateConVar("l4d_wispaco_finale_start", "1", "Allow spawning witches after the finale start.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarLog = CreateConVar("l4d_wispaco_log", "0", "Enable or disable debug logging.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d_wispaco");
	
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCountWitchInRound.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCountAliveWitch.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWitchTimeMin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWitchTimeMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWitchDistance.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDirectorWitch.AddChangeHook(ConVarChanged_Cvars);
	if (g_bLeft4Dead2)
	{
		g_hCvarWitchWeight.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarWitchBrideWeight.AddChangeHook(ConVarChanged_Cvars);
	}
	g_hCvarFinaleStart.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLog.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	LogCommand("#DEBUG: On plugin end");
	End_Timer(false);
}

public void OnConfigsExecuted()
{
	LogCommand("#DEBUG: On configs executed");
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bPluginEnable = g_hCvarEnable.BoolValue;
	g_iCountWitchInRound = g_hCvarCountWitchInRound.IntValue;
	g_iCountWitchAlive = g_hCvarCountAliveWitch.IntValue;
	g_fWitchTimeMin = g_hCvarWitchTimeMin.FloatValue;
	g_fWitchTimeMax = g_hCvarWitchTimeMax.FloatValue;
	g_fWitchDistance = g_hCvarWitchDistance.FloatValue;
	g_bDirectorWitch = g_hCvarDirectorWitch.BoolValue;
	if (g_bLeft4Dead2)
	{
		g_iWitchWeight = g_hCvarWitchWeight.IntValue;
		g_iWitchBrideWeight = g_hCvarWitchBrideWeight.IntValue;
	}
	g_bFinaleStart = g_hCvarFinaleStart.BoolValue;
	g_bDebugLog = g_hCvarLog.BoolValue;
}

void IsAllowed()
{	
	GetCvars();
	if (g_bPluginEnable && !g_bHookedEvents)
	{
		HookEvent("witch_spawn", evtWitchSpawn, EventHookMode_PostNoCopy);
		HookEvent("player_left_checkpoint", evtLeftSafeArea, EventHookMode_Post);
		HookEvent("round_start", evtRoundStart, EventHookMode_Post);
		HookEvent("round_end", evtRoundEnd, EventHookMode_Post);
		HookEvent("finale_start", evtFinaleStart, EventHookMode_PostNoCopy);
		g_bHookedEvents = true;
	}
	else if (!g_bPluginEnable && g_bHookedEvents)
	{
		UnhookEvent("witch_spawn", evtWitchSpawn, EventHookMode_PostNoCopy);
		UnhookEvent("player_left_checkpoint", evtLeftSafeArea, EventHookMode_Post);
		UnhookEvent("round_start", evtRoundStart, EventHookMode_Post);
		UnhookEvent("round_end", evtRoundEnd, EventHookMode_Post);
		UnhookEvent("finale_start", evtFinaleStart, EventHookMode_PostNoCopy);
		g_bHookedEvents = false;
	}
}

public void OnMapStart()
{
	LogCommand("#DEBUG: On map start precaching");
	PrecacheModel(WITCH_MODEL, true);
	PrecacheSound(WITCH_SOUND, true);
	if (g_bLeft4Dead2)
	{
		PrecacheModel(BRIDE_MODEL, true);
		PrecacheSound(BRIDE_SOUND, true);
	}
}

public void OnMapEnd()
{
	LogCommand("#DEBUG: On map end");
	End_Timer(false);
}

public void OnClientDisconnect(int client)
{
	if (!g_bRunTimer)
		return;
	if (IsServerEmpty())
	{	
		LogCommand("#DEBUG: All players logged out, timer stopped");
		End_Timer(false);
	}
}

bool IsServerEmpty()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return false;
	}
	return true;
}

void evtWitchSpawn(Event event, const char[] name , bool dontBroadcast)
{
	if (!g_bWitchExec && !g_bDirectorWitch)
	{
		int WitchID = event.GetInt("witchid");
		if (IsValidEntity(WitchID)) 
		{
			RemoveEntity(WitchID);
			LogCommand("#DEBUG: Removing Director's Witch ID = %i; Witch = %d, Max count witch = %d", WitchID, g_iCountWitch, g_iCountWitchInRound);
		}
		else
			LogCommand("#DEBUG: Failed to remove Director's Witch ID = %i because the edict index (witch ID) is invalid.", WitchID);
	}
	else
	{
		g_iCountWitch++;
		LogCommand("#DEBUG: Witch spawned; Witch = %d, Max count witch = %d", g_iCountWitch, g_iCountWitchInRound);
	}
}

void evtLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRunTimer && !g_bLeftSafeArea)
	{	
		if (L4D_HasAnySurvivorLeftSafeArea())
		{
			LogCommand("#DEBUG: Player has left the starting area");
			g_bLeftSafeArea = true;
			First_Start_Timer();
		}	
	}
}

void evtRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LogCommand("#DEBUG: Round started");	
	g_iCountWitch = 0;
	g_bLeftSafeArea = false;
}

void evtRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	LogCommand("#DEBUG: Round ended");
	End_Timer(false);
}

void evtFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bFinaleStart)
	{
		LogCommand("#DEBUG: Spawn ended [FINALE START]");
		End_Timer(false);
	}
}

void First_Start_Timer()
{
	g_bRunTimer = true;
	LogCommand("#DEBUG: First_Start_Timer; Safety zone leaved; RunTimer = %d", g_bRunTimer);
	Start_Timer();
}

void Start_Timer()
{
	float WitchSpawnTime = GetRandomFloatEx(g_fWitchTimeMin, g_fWitchTimeMax);
	LogCommand("#DEBUG: Start_Timer; Witch spawn time = %f", WitchSpawnTime);
	g_hSpawnTimer = CreateTimer(WitchSpawnTime, SpawnAWitch, _);
}

void End_Timer(const bool isClosedHandle)
{
	if (!g_bRunTimer)
		return;
	if (!isClosedHandle)
		delete g_hSpawnTimer;
	g_bRunTimer = false;
	g_bWitchExec = false;
	LogCommand("#DEBUG: End_Timer; Handle closed; RunTimer = %d", g_bRunTimer);
}

Action SpawnAWitch(Handle timer)
{
	if (g_bRunTimer)
	{
		// Check if the maximum number of witches for this round has been reached
		if (g_iCountWitchInRound > 0 && g_iCountWitch >= g_iCountWitchInRound)
		{
			LogCommand("#DEBUG: Witch = %d, Max count witch = %d; End_Timer()", g_iCountWitch, g_iCountWitchInRound);
			End_Timer(true); // Stop the timer since the limit is reached
			return Plugin_Continue;
		}
		// Check if there are already too many witches alive
		if (g_iCountWitchAlive > 0 && g_iCountWitch >= g_iCountWitchAlive && GetCountAliveWitches() >= g_iCountWitchAlive)
		{
			LogCommand("#DEBUG: Too many alive witches, delaying spawn");
			Start_Timer(); // Restart the timer to try again later
			return Plugin_Continue;
		}
		// Get any valid client to spawn the witch for
		int anyclient = GetAnyClient();
		if (anyclient == 0)
		{
			LogCommand("#DEBUG: No valid clients, restarting timer");
			Start_Timer(); // If no valid clients are available, restart the timer and try again later
			return Plugin_Continue;
		}
		// Set a flag indicating a witch is about to be spawned
		g_bWitchExec = true;
		LogCommand("#DEBUG: Attempting to spawn");
		// Spawn the witch for the selected client
		SpawnCommand(anyclient);
		// Reset the flag after the witch is spawned
		g_bWitchExec = false;
		LogCommand("#DEBUG: More witches needed, restarting timer");
		Start_Timer(); // Restart the timer for the next spawn
	}
	return Plugin_Stop; // Stop the function execution if the timer shouldn't run
}

int GetCountAliveWitches()
{
	int iCountAlive = 0;
	int iWitchiNdex = -1;
	while ((iWitchiNdex = FindEntityByClassname2(iWitchiNdex, "witch")) != INVALID_ENT_REFERENCE)
	{
		iCountAlive++;
		LogCommand("#DEBUG: Witch ID = %i (Alive witches = %i)", iWitchiNdex, iCountAlive);
		if (g_fWitchDistance > 0)
		{
			float fWitchPos[3];
			float fPlayerPos[3];
			GetEntPropVector(iWitchiNdex, Prop_Send, "m_vecOrigin", fWitchPos);
			int iClients = 0;
			int iTooFar = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidSurvivor(i) && IsPlayerAlive(i))
				{
					iClients++;
					GetClientAbsOrigin(i, fPlayerPos);
					float distance = GetVectorDistance(fWitchPos, fPlayerPos);
					LogCommand("#DEBUG: Distance to witch = %f; Max distance = %f", distance, g_fWitchDistance);
					if (distance > g_fWitchDistance)
						iTooFar++;
				}
			}
			if (iTooFar == iClients)
			{
				if (IsValidEntity(iWitchiNdex))
					RemoveEntity(iWitchiNdex);
				iCountAlive--;
				LogCommand("#DEBUG: Witch removed for being too far; Alive witches = %d", iCountAlive);
			}
		}
	}
	LogCommand("#DEBUG: Alive witches = %d, Max count alive witches = %d", iCountAlive, g_iCountWitchAlive);
	return iCountAlive;
}

int GetAnyClient()
{
	int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return i;
	}
	return 0;
}

int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while (startEnt < GetMaxEntities() && !IsValidEntity(startEnt))
		startEnt++;
	return FindEntityByClassname(startEnt, classname);
}

void SpawnCommand(int client)
{
	// Check if the client is valid (non-zero)
	if (!client)
		return;
	int iWitchIndex = -1;
	float fSpawnPos[3], fSpawnAng[3];
	// Try to find a random spawn position
	if (!GetSpawnPosition(8, 10, fSpawnPos))
	{
		LogCommand("#DEBUG: Failed to find a valid spawn position");
		return;
	}
	// Set random yaw angle for the witch
	fSpawnAng[1] = GetRandomFloatEx(-179.0, 179.0);
	if (g_bLeft4Dead2)
	{
		// Calculate total weight for witch spawn probability
		int totalWeight = g_iWitchWeight + g_iWitchBrideWeight;
		if (totalWeight <= 0)
		{
			LogCommand("#DEBUG: Total weight for witch spawning is zero or negative");
			return;
		}
		// Generate a random number to select witch type based on weight
		int randomWeight = GetRandomIntEx(1, totalWeight);
		if (randomWeight <= g_iWitchWeight)
		{
			// Spawn a regular witch
			iWitchIndex = L4D2_SpawnWitch(fSpawnPos, fSpawnAng);
			if (!IsValidEntity(iWitchIndex))
			{
				LogCommand("#DEBUG: Failed to spawn a regular witch in L4D2");
				return;
			}
		}
		else
		{
			// Spawn a witch bride
			iWitchIndex = L4D2_SpawnWitchBride(fSpawnPos, fSpawnAng);
			if (!IsValidEntity(iWitchIndex))
			{
				LogCommand("#DEBUG: Failed to spawn a witch bride in L4D2");
				return;
			}
		}
	}
	else // If the game is not L4D2, create a standard witch entity
	{
		iWitchIndex = CreateEntityByName("witch");
		if (IsValidEntity(iWitchIndex))
		{
			// Set the witch's position and angles
			SetAbsOrigin(iWitchIndex, fSpawnPos);
			SetAbsAngles(iWitchIndex, fSpawnAng);
			// Finalize the spawn process
			DispatchSpawn(iWitchIndex);
			// Activate the entity
			ActivateEntity(iWitchIndex);
		}
		else
		{
			LogCommand("#DEBUG: Failed to spawn a witch in L4D");
			return;
		}
	}
}

bool GetSpawnPosition(int zombieClass, int attempts, float spawnpos[3])
{
	if (attempts < 1)
		return false;
	// Try to find a spawn position with less redundant calls
	for (int tryCount = 0; tryCount < attempts; tryCount++)
	{
		// Try to get the spawn position from the highest flow survivor first
		if (IsValidClient(L4D_GetHighestFlowSurvivor()))
		{
			if (L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(), zombieClass, attempts, spawnpos))
				return true;
		}
		// If failed, try each survivor until a valid position is found
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidSurvivor(i))
			{
				if (L4D_GetRandomPZSpawnPosition(i, zombieClass, attempts, spawnpos))
					return true;
			}
		}
	}
	// If no valid position was found after all attempts
	return false;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

int GetRandomIntEx(int min, int max)
{
	return GetURandomInt() % (max - min + 1) + min;
}

float GetRandomFloatEx(float min, float max)
{
	return GetURandomFloat() * (max - min) + min;
}

void LogCommand(const char[] format, any ...)
{
	if (!g_bDebugLog)
		return;
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	char sPath[PLATFORM_MAX_PATH], sTime[32];
	BuildPath(Path_SM, sPath, sizeof(sPath), "logs/wispaco.log");
	File file = OpenFile(sPath, "a+");
	FormatTime(sTime, sizeof(sTime), "L %m/%d/%Y - %H:%M:%S");
	file.WriteLine("%s: %s", sTime, buffer);
	FlushFile(file);
	delete file;
}