#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define MESSAGE_PREFIX "[Warmup]"

ConVar gCvarEnabled = null;
ConVar gCvarTime = null;
ConVar gCvarRestartGame = null;

Handle gWarmupTimer = null;
Handle gRespawnTimer = null;

bool gConfigsExecuted;
bool gWarmupRunning;
bool gWarmupCompleted;
int gWarmupRemaining;
int gQueuedRespawnUserId[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Ayrton Warmup",
	author = "Ayrton09",
	description = "Simple warmup for CS:S and CS:GO.",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errMax)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_CSS && engine != Engine_CSGO)
	{
		strcopy(error, errMax, "Ayrton Warmup requires CS:S or CS:GO Source because it uses CS_RespawnPlayer.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("ayrton_warmup_version", PLUGIN_VERSION, "Ayrton Warmup version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gCvarEnabled = CreateConVar("ayrton_warmup_enable", "1", "Enables or disables automatic warmup at map start.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gCvarTime = CreateConVar("ayrton_warmup_time", "40", "Warmup duration in seconds. 0 disables warmup.", _, true, 0.0, true, 3600.0);

	AutoExecConfig(true, "ayrton_warmup");

	gCvarEnabled.AddChangeHook(ConVarChanged_Warmup);
	gCvarTime.AddChangeHook(ConVarChanged_Warmup);

	AddCommandListener(Command_JoinClass, "joinclass");

	HookEventEx("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void OnAllPluginsLoaded()
{
	gCvarRestartGame = FindConVar("mp_restartgame");
}

public void OnMapStart()
{
	gConfigsExecuted = false;
	gWarmupCompleted = false;
	StopWarmup(false);
}

public void OnMapEnd()
{
	gConfigsExecuted = false;
	StopWarmup(false);
}

public void OnConfigsExecuted()
{
	gConfigsExecuted = true;

	if (gCvarRestartGame == null)
	{
		gCvarRestartGame = FindConVar("mp_restartgame");
	}

	TryStartWarmup();
}

public void ConVarChanged_Warmup(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!gConfigsExecuted)
	{
		return;
	}

	if (!gCvarEnabled.BoolValue || gCvarTime.IntValue <= 0)
	{
		StopWarmup(true);
		return;
	}

	if (gWarmupRunning && convar == gCvarTime)
	{
		StartWarmup(gCvarTime.IntValue);
		return;
	}

	TryStartWarmup();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (gWarmupRunning)
	{
		RespawnWarmupPlayers();
		AnnounceTime(gWarmupRemaining);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	QueueWarmupRespawnUserId(event.GetInt("userid"));
}

public Action Command_JoinClass(int client, const char[] command, int argc)
{
	if (!gWarmupRunning || client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}

	int userid = GetClientUserId(client);
	if (userid > 0)
	{
		CreateTimer(0.3, Timer_CheckJoiningClient, userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (client > 0 && client <= MaxClients)
	{
		gQueuedRespawnUserId[client] = 0;
	}
}

public Action Timer_WarmupTick(Handle timer)
{
	if (!gWarmupRunning)
	{
		gWarmupTimer = null;
		return Plugin_Stop;
	}

	gWarmupRemaining--;
	if (gWarmupRemaining <= 0)
	{
		gWarmupTimer = null;
		FinishWarmup();
		return Plugin_Stop;
	}

	AnnounceTime(gWarmupRemaining);
	return Plugin_Continue;
}

void TryStartWarmup()
{
	if (!gConfigsExecuted || gWarmupRunning || gWarmupCompleted)
	{
		return;
	}

	if (!gCvarEnabled.BoolValue)
	{
		return;
	}

	int seconds = gCvarTime.IntValue;
	if (seconds <= 0)
	{
		return;
	}

	StartWarmup(seconds);
}

void StartWarmup(int seconds)
{
	StopWarmup(false);

	gWarmupRunning = true;
	gWarmupRemaining = seconds;

	RespawnWarmupPlayers();
	AnnounceTime(seconds);

	gWarmupTimer = CreateTimer(1.0, Timer_WarmupTick, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopWarmup(bool announce)
{
	bool wasRunning = gWarmupRunning;

	if (gWarmupTimer != null)
	{
		delete gWarmupTimer;
		gWarmupTimer = null;
	}

	ClearRespawnTimer();

	gWarmupRunning = false;
	gWarmupRemaining = 0;
	ClearRespawnQueue();

	if (announce && wasRunning)
	{
		PrintHintTextToAll("%s\nWarmup disabled.", MESSAGE_PREFIX);
	}
}

void FinishWarmup()
{
	gWarmupRunning = false;
	gWarmupCompleted = true;
	gWarmupRemaining = 0;
	ClearRespawnTimer();
	ClearRespawnQueue();

	PrintHintTextToAll("%s\nWarmup finished. Restarting match...", MESSAGE_PREFIX);

	if (gCvarRestartGame != null)
	{
		gCvarRestartGame.IntValue = 1;
		return;
	}

	if (CommandExists("mp_restartgame"))
	{
		ServerCommand("mp_restartgame 1");
		return;
	}

	PrintToServer("[Warmup] mp_restartgame was not found; the match could not be restarted automatically.");
}

public Action Timer_RespawnQueue(Handle timer)
{
	gRespawnTimer = null;

	if (gWarmupRunning)
	{
		ProcessRespawnQueue();
	}

	return Plugin_Stop;
}

public Action Timer_CheckJoiningClient(Handle timer, any userid)
{
	if (!gWarmupRunning)
	{
		return Plugin_Stop;
	}

	int client = GetClientOfUserId(userid);
	if (client > 0)
	{
		RespawnClientIfNeeded(client);
	}

	return Plugin_Stop;
}

void RespawnWarmupPlayers()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		RespawnClientIfNeeded(client);
	}
}

void RespawnClientIfNeeded(int client)
{
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	if (!IsClientInGame(client) || IsPlayerAlive(client))
	{
		return;
	}

	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
	{
		return;
	}

	CS_RespawnPlayer(client);
}

void QueueWarmupRespawnUserId(int userid)
{
	if (!gWarmupRunning || userid <= 0)
	{
		return;
	}

	int client = GetClientOfUserId(userid);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}

	gQueuedRespawnUserId[client] = userid;

	if (gRespawnTimer == null)
	{
		gRespawnTimer = CreateTimer(0.2, Timer_RespawnQueue, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void ProcessRespawnQueue()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		int userid = gQueuedRespawnUserId[client];
		if (userid == 0)
		{
			continue;
		}

		gQueuedRespawnUserId[client] = 0;

		if (GetClientOfUserId(userid) == client)
		{
			RespawnClientIfNeeded(client);
		}
	}
}

void ClearRespawnQueue()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		gQueuedRespawnUserId[client] = 0;
	}
}

void ClearRespawnTimer()
{
	if (gRespawnTimer != null)
	{
		delete gRespawnTimer;
		gRespawnTimer = null;
	}
}

void AnnounceTime(int seconds)
{
	if (seconds <= 0)
	{
		return;
	}

	PrintHintTextToAll("%s\nThe match starts in %d seconds.", MESSAGE_PREFIX, seconds);
}
