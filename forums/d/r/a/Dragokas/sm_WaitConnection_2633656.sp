#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "WaitConnection",
	author = "Dragokas",
	description = "Players will be frozen until all of them finish loading",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	ChangeLog:

	1.0 (08-Jan-2018)
	 - Initial release
*/

ConVar 	g_hCvarEnable;
ConVar 	g_hCvarWaitMin;
ConVar 	g_hCvarWaitMax;
ConVar 	g_hCvarLockBots;

bool 	g_bEnabled;
bool	g_bLockBots;

float g_fConnectionTimeMin;
float g_fConnectionTimeMax;
float g_fConnectionTime;

bool g_bInQueueCheckConnection;
bool g_bFreezeRequired;

int g_iTimeLeft[MAXPLAYERS+1]; // virtual timer (just for progressbar)

public void OnPluginStart()
{
	LoadTranslations("wait_connection.phrases");
	
	CreateConVar(						"sm_wait_conn_version",		PLUGIN_VERSION,			"Plugin version", FCVAR_DONTRECORD );
	g_hCvarEnable = CreateConVar(		"sm_wait_conn_enable",			"1",				"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	g_hCvarWaitMin = CreateConVar(		"sm_wait_conn_min",				"5.0",				"Minimum delay before checking connection", CVAR_FLAGS );
	g_hCvarWaitMax = CreateConVar(		"sm_wait_conn_max",				"30.0",				"Maximum delay (timeout) to check for connected players", CVAR_FLAGS );
	g_hCvarLockBots = CreateConVar(		"sm_wait_conn_include_bots",	"1",				"Do we need to freeze bots as well? (1 - Yes / 0 - No)", CVAR_FLAGS );
	
	AutoExecConfig(true,			"sm_wait_connection");
	
	HookEvent("player_team",			Event_PlayerTeam);
	HookEvent("round_start",			Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", 				Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_win", 			Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", 			Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd, EventHookMode_PostNoCopy);
	
	HookConVarChange(g_hCvarEnable,			ConVarChanged);
	HookConVarChange(g_hCvarWaitMin,		ConVarChanged);
	HookConVarChange(g_hCvarWaitMax,		ConVarChanged);
	HookConVarChange(g_hCvarLockBots,		ConVarChanged);
	
	// just in case
	RegAdminCmd		("sm_unfreeze", 	Cmd_Unfreeze,		ADMFLAG_ROOT,	"Manually unfreeze all players (in an emergency).");
	
	GetCvars();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_bLockBots = g_hCvarLockBots.BoolValue;
	g_fConnectionTimeMin = g_hCvarWaitMin.FloatValue;
	g_fConnectionTimeMax = g_hCvarWaitMax.FloatValue;
}

public Action Cmd_Unfreeze(int client, int args)
{
	g_bFreezeRequired = false;
	UnfreezeAll();
	return Plugin_Handled;
}

public void Event_RoundEnd(Event event, const char[] sEvName, bool bDontBroadcast)
{
	OnMapEnd();
}

public void OnMapEnd()
{
	g_bInQueueCheckConnection = false;
	g_bFreezeRequired = true;
}

/*
// Cannot use it because freeze is not applicable to player who not yet joined the team

public void OnClientPutInServer(int client)
{
}
*/
public void Event_PlayerTeam(Event event, const char[] sEvName, bool bDontBroadcast)
{
	if (g_bEnabled && g_bFreezeRequired) {
		int team = event.GetInt("team");
		int UserId = event.GetInt("userid");
		int client = GetClientOfUserId(UserId);
		
		if (client != 0 && team > 1) {
			bool fake = IsFakeClient(client);
			
			if (!fake || (fake && g_bLockBots))
			{
				// freeze incoming player
				// still require a little bit delay
				CreateTimer(0.5, Timer_FreezeDelayed, UserId, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action Timer_FreezeDelayed(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (g_bFreezeRequired && client != 0 && IsClientInGame(client))
	{
		if (!IsFakeClient(client)) {
			CreateTimer(1.0, Timer_ShowProgressBar, UserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			g_iTimeLeft[client] = 10;
		}
		DoFreeze(client, true);
	}
}

public Action Timer_ShowProgressBar(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client != 0 && IsClientInGame(client))
	{
		if (!g_bFreezeRequired) {
			PrintHintText(client, "%t", "go");
			return Plugin_Stop;
		}
		PrintHintText(client, "%t %i", "wait", g_iTimeLeft[client]);
		g_iTimeLeft[client]--;
		if (g_iTimeLeft[client] == 0) g_iTimeLeft[client] = 10;
	}
	else
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] sEvName, bool bDontBroadcast)
{
	if (g_bEnabled)
		BeginCheckConnection();
}

void BeginCheckConnection()
{
	if (!g_bInQueueCheckConnection) {
		g_bInQueueCheckConnection = true;
		CreateTimer(g_fConnectionTimeMin, Timer_CheckConnection, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_CheckConnection(Handle timer)
{
	bool IsPlayerConnecting;
	int i;
	
	for (i = 1; i <= MaxClients; i++)
	{
        if (IsClientConnected(i) && !IsClientInGame(i))
		{
			IsPlayerConnecting = true;
			break;
		}
	}
	
	if (!IsPlayerConnecting) {
		for (i = 1; i <= MaxClients; i++)
		{
	        if (IsClientInGame(i) && GetClientTeam(i) == 0)
			{
				IsPlayerConnecting = true;
				break;
			}
		}
	}
	
	if (IsPlayerConnecting)
	{	
		if (g_fConnectionTime <= g_fConnectionTimeMax)
		{
			g_fConnectionTime += 1.0;
			CreateTimer(1.0, Timer_CheckConnection, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {
			OnAllClientsPostAdminCheck(); // timeout
		}
	}
	else {
		OnAllClientsPostAdminCheck();
	}
}

void OnAllClientsPostAdminCheck()
{
	g_bFreezeRequired = false;
	CreateTimer(0.5, Timer_UnFreezeAll, _, TIMER_FLAG_NO_MAPCHANGE); // to let OnClientPutInServer receive !g_bFreezeRequired flag
}

public Action Timer_UnFreezeAll(Handle timer)
{
	g_bInQueueCheckConnection = false;
	UnfreezeAll();
}

void UnfreezeAll()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i))
			DoFreeze(i, false);
	}
}

void DoFreeze(int client, bool bFreeze)
{
	/*
	if (bFreeze)
		PrintToChatAll("Freezing client: %N", client);
	else
		PrintToChatAll("Unfreezing client: %N", client);
	*/
	
	SetEntityMoveType(client, bFreeze ? MOVETYPE_NONE : MOVETYPE_WALK);
}
