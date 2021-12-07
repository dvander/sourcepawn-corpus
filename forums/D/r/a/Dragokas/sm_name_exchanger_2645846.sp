#define PLUGIN_VERSION		"1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D] Name Exchanger",
	author = "Dragokas",
	description = "Funny plugin to exchange names between players",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

float g_fConnectionTimeMin = 5.0;
float g_fConnectionTimeMax = 30.0;
float g_fConnectionTime;

bool g_bInQueueCheckConnection;
bool g_bBlockRaname = true;
bool g_bLate;
bool g_bIncludeBots = false;
bool g_bDisableMsg;

ConVar 	g_hCvarEnable;

char g_sOrigName[MAXPLAYERS+1][MAX_NAME_LENGTH];
char g_sNewName[MAXPLAYERS+1][MAX_NAME_LENGTH];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar(						"sm_name_exchange_version",		PLUGIN_VERSION,		"Plugin version", FCVAR_DONTRECORD );
	g_hCvarEnable = CreateConVar(		"sm_name_exchange_enable",		"1",				"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	
	AutoExecConfig(true,			"sm_name_exchange");
	
	HookConVarChange(g_hCvarEnable,			ConVarChanged);
	
	InitHook();
	
	if (g_bLate)
		g_bBlockRaname = false;
}

/*
public void OnAllPluginsLoaded()
{
	HookEvent("player_changename", OnNameChanged, EventHookMode_Pre);
}

public Action OnNameChanged(Handle event, char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);
	return Plugin_Changed;
}

*/

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	InitHook();
}

void InitHook()
{
	static bool bHooked;

	if (g_hCvarEnable.BoolValue) {
		if (!bHooked) {
			HookEvent("player_spawn", 			Event_PlayerSpawn);
			HookEvent("round_start",			Event_RoundStart, 	EventHookMode_PostNoCopy);
			HookEvent("round_end", 				Event_RoundEnd,		EventHookMode_Pre);
			HookEvent("finale_win", 			Event_RoundEnd, 	EventHookMode_PostNoCopy);
			HookEvent("mission_lost", 			Event_RoundEnd, 	EventHookMode_PostNoCopy);
			HookEvent("map_transition", 		Event_RoundEnd, 	EventHookMode_PostNoCopy);
			HookEvent("player_disconnect", 		Event_PlayerDisconnect, EventHookMode_Pre);
			HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("player_spawn", 		Event_PlayerSpawn);
			UnhookEvent("round_start",			Event_RoundStart, 	EventHookMode_PostNoCopy);
			UnhookEvent("round_end", 			Event_RoundEnd,		EventHookMode_Pre);
			UnhookEvent("finale_win", 			Event_RoundEnd, 	EventHookMode_PostNoCopy);
			UnhookEvent("mission_lost", 		Event_RoundEnd, 	EventHookMode_PostNoCopy);
			UnhookEvent("map_transition", 		Event_RoundEnd, 	EventHookMode_PostNoCopy);
			UnhookEvent("player_disconnect", 	Event_PlayerDisconnect, EventHookMode_Pre);
			UnhookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, false);
			RestoreNames();
			bHooked = false;
		}
	}
}

public void Event_PlayerDisconnect(Event event, const char[] sEvName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_sNewName[client][0] = '\0';
	g_sOrigName[client][0] = '\0';
}

public void Event_RoundEnd(Event event, const char[] sEvName, bool bDontBroadcast)
{
	OnMapEnd();
	RestoreNames();
	
	for (int i = 1; i <= MaxClients; i++)
		g_sNewName[i][0] = '\0';
}

public void OnMapEnd()
{
	g_bInQueueCheckConnection = false;
	g_bBlockRaname = true;
}

public void Event_RoundStart(Event event, const char[] sEvName, bool bDontBroadcast)
{
	g_bBlockRaname = true;
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
	//PrintToChatAll("OnAllClientsPostAdminCheck");
	g_bInQueueCheckConnection = false;
	ShuffleNames();
	g_bBlockRaname = false;
}

public void OnClientPutInServer(int client)
{
	if (g_hCvarEnable.BoolValue && !g_bBlockRaname && !IsFakeClient(client)) {
		g_sNewName[client][0] = '\0';
		CreateTimer(30.0, Timer_Rename, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_Rename(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client))
	{
		GetClientInfo(client, "name", g_sOrigName[client], sizeof(g_sOrigName[])); // save orig.
		
		ArrayList aId = new ArrayList(ByteCountToCells(4));

		for (int i = 1; i <= MaxClients; i++) {
			// exclude self
			if (i != client && IsClientInGame(i) && GetClientTeam(i) != 3 && !BotCheck(i))
			{
				aId.Push(i);
			}
		}
		
		if (aId.Length > 0) {
			int target = aId.Get(GetRandomInt(0, aId.Length -1));
			ExchangeNames(client, target);
		}
		delete aId;
	}
}

bool BotCheck(int client)
{
	if (g_bIncludeBots)
		return false;
		
	return IsFakeClient(client);
}

void ShuffleNames()
{
	ArrayList aId = new ArrayList(ByteCountToCells(4));

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) != 3 && !BotCheck(i))
		{
			aId.Push(i);
			GetClientInfo(i, "name", g_sOrigName[i], sizeof(g_sOrigName[])); // save orig.
		}
	}
	
	int client, target;
	
	for (int i = 0; i < aId.Length -1; i++) // exclude last id
	{
		client = aId.Get(i);
		target = aId.Get(GetRandomInt(i +1, aId.Length -1)); // +1 to last
		ExchangeNames(client, target);
	}
	
	delete aId;
}

void ExchangeNames(int player1, int player2)
{
	char sName1[MAX_NAME_LENGTH], sName2[MAX_NAME_LENGTH];
	
	GetClientInfo(player1, "name", sName1, sizeof(sName1));
	GetClientInfo(player2, "name", sName2, sizeof(sName2));
	
	RenameClient(player1, "temp"); // walkaround against Name(1) because game is not allow identical names
	RenameClient(player2, sName1);
	RenameClient(player1, sName2);
	
	strcopy(g_sNewName[player1], sizeof(g_sNewName[]), sName2);
	strcopy(g_sNewName[player2], sizeof(g_sNewName[]), sName1);
}

void RestoreNames()
{
	char sOldName[MAX_NAME_LENGTH];
	
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && GetClientTeam(client) != 3 && !BotCheck(client))
		{
			GetClientInfo(client, "name", sOldName, sizeof(sOldName));
			
			if (!StrEqual(sOldName, g_sOrigName[client]) && g_sOrigName[client][0] != '\0' )
			{
				RenameClient(client, g_sOrigName[client]);
				PrintToChatAll("\x04%s \x03===> \x04%s", sOldName, g_sOrigName[client]);
			}
		}
	}
	// bypass name duplicates
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && GetClientTeam(client) != 3 && !BotCheck(client))
		{
			GetClientInfo(client, "name", sOldName, sizeof(sOldName));
			
			if (!StrEqual(sOldName, g_sOrigName[client]) && g_sOrigName[client][0] != '\0' )
			{
				RenameClient(client, g_sOrigName[client]);
			}
		}
	}
}

void EnsureName(int client)
{
	char sOldName[MAX_NAME_LENGTH];
	GetClientInfo(client, "name", sOldName, sizeof(sOldName));
	
	if (!StrEqual(sOldName, g_sNewName[client]) && g_sNewName[client][0] != '\0')
	{
		RenameClient(client, g_sNewName[client]);
	}
}

void RenameClient(int client, char[] sNewName, bool bDisableMsg = true)
{
	if (bDisableMsg)
		g_bDisableMsg = true;
		
	SetClientInfo(client, "name", sNewName);
	
	if (bDisableMsg)
		CreateTimer(1.0, Timer_EnableMsg);
}

public Action Timer_EnableMsg(Handle timer)
{
	g_bDisableMsg = false;
}

public Action Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	if (!g_bBlockRaname) {
		int UserId = event.GetInt("userid");
		if (UserId != 0)
		{
			int client = GetClientOfUserId(UserId);
			if (client != 0)
			{
				EnsureName(client);
			}
		}
	}
}

// deny client try to restore his name
public Action UserMessage_SayText2(UserMsg msg_id, Handle bf, const char[] players, int playersNum, bool reliable, bool init)
{
	char message[256];
	
	BfReadShort(bf); // team color
	BfReadString(bf, message, sizeof(message));
	
	// check for Name_Change, not #TF_Name_Change (compatibility?)
	if (StrContains(message, "Name_Change") != -1)
	{
		BfReadString(bf, message, sizeof(message)); // original
		BfReadString(bf, message, sizeof(message)); // new
		
		if (StrContains(message, "Спартанец", false) == -1 && StrContains(message, "Spartanec", false) == -1)
		{
			CreateTimer(10.0, Timer_NameUpdate, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_bDisableMsg)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_NameUpdate(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) != 3 && !BotCheck(i))
		{
			EnsureName(i);
		}
	}
}
