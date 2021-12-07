#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.1.5"

public Plugin myinfo = 
{
	name = "Anti-Reconnect",
	author = "exvel",
	description = "Blocking people for time from reconnecting",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

bool g_bKickedByPlugin[MAXPLAYERS + 1];

Handle g_kvDB;

//CVars' handles
ConVar cvar_ar_time, cvar_ar_admin_immunity, cvar_ar_disconnect_by_user_only, cvar_lan;

//Cvars' varibles
bool isLAN = false;
int ar_time = 30, ar_disconnect_by_user_only = true, ar_admin_immunity = false;

public void OnPluginStart()
{
	g_kvDB = CreateKeyValues("antireconnect");
	
	CreateConVar("sm_anti_reconnect_version", PLUGIN_VERSION, "Anti-Reconnect Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvar_ar_time = CreateConVar("sm_anti_reconnect_time", "180", "Time in seconds players must to wait before connect to the server again after disconnecting, 0 = disabled", FCVAR_NOTIFY, true, 0.0);
	cvar_ar_disconnect_by_user_only = CreateConVar("sm_anti_reconnect_disconnect_by_user_only", "1", "\n0 = always block players from reconnecting\n1 = block player from reconnecting only if a client \"disconnected by user\"", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_ar_admin_immunity = CreateConVar("sm_anti_reconnect_admin_immunity", "1", "0 = disabled, 1 = protect admins from Anti-Reconnect functionality", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_lan = FindConVar("sv_lan");

	cvar_ar_time.AddChangeHook(OnCVarChange);
	cvar_ar_disconnect_by_user_only.AddChangeHook(OnCVarChange);
	cvar_ar_admin_immunity.AddChangeHook(OnCVarChange);
	cvar_lan.AddChangeHook(OnCVarChange);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	
	AutoExecConfig(true, "plugin.antireconnect");
	LoadTranslations("antireconnect.phrases");
}

public void OnMapStart()
{
	delete g_kvDB;
	g_kvDB = CreateKeyValues("antireconnect");
}

public void OnConfigsExecuted()
{
	GetCVars();
}

public void OnCVarChange(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

public void GetCVars()
{
	isLAN = cvar_lan.BoolValue;
	ar_time = cvar_ar_time.IntValue;
	ar_disconnect_by_user_only = cvar_ar_disconnect_by_user_only.BoolValue;
	ar_admin_immunity = cvar_ar_admin_immunity.BoolValue;
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	char reason[128];
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (g_bKickedByPlugin[client] || !client)
		return;

	event.GetString("reason", reason, 128);

	if (StrEqual(reason, "Disconnect by user.") || !ar_disconnect_by_user_only)
	{
		if (isLAN || ar_time == 0 || IsFakeClient(client))
			return;

		if (GetUserFlagBits(client) && ar_admin_immunity)
			return;

		char steamId[30];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		KvSetNum(g_kvDB, steamId, GetTime());
	}
}

public void OnClientPostAdminCheck(int client)
{
	g_bKickedByPlugin[client] = false;

	if (isLAN || ar_time == 0 || IsFakeClient(client) || !IsClientConnected(client))
		return;

	char steamId[30];	
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));	

	int disconnect_time = KvGetNum(g_kvDB, steamId, -1);
	if (disconnect_time == -1)
		return;

	int wait_time = disconnect_time + ar_time - GetTime();
	if (wait_time <= 0)
	{
		KvDeleteKey(g_kvDB, steamId);
	}
	else
	{
		g_bKickedByPlugin[client] = true;
		KickClient(client, "%t", "You are not allowed to reconnect for X seconds", wait_time);
		LogAction(-1, client,"Kicked \"%L\". Player is not allowed to reconnect for %d seconds.", client, wait_time);
	}
}
