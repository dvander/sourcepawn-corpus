#include <sourcemod>

#define PLUGIN_VERSION "1.2.0"

public Plugin:myinfo = 
{
	name = "Anti-Reconnect",
	author = "exvel",
	description = "Blocking people for time from reconnecting",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new bool:kicked_by_plugin[65];

//CVars' handles
new Handle:db = INVALID_HANDLE;
new Handle:cvar_ar_time = INVALID_HANDLE;
new Handle:cvar_ar_admin_immunity = INVALID_HANDLE;
new Handle:cvar_ar_disconnect_by_user_only = INVALID_HANDLE;
new Handle:cvar_lan = INVALID_HANDLE;

//Cvars' varibles
new bool:isLAN = false;
new ar_time = 30;
new ar_disconnect_by_user_only = true;
new ar_admin_immunity = false;


public OnPluginStart()
{
	db = CreateKeyValues("antireconnect");
	
	CreateConVar("sm_anti_reconnect_version", PLUGIN_VERSION, "Anti-Reconnect Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_ar_time = CreateConVar("sm_anti_reconnect_time", "30", "Time in seconds players must to wait before connect to the server again after disconnecting, 0 = disabled", FCVAR_PLUGIN, true, 0.0);
	cvar_ar_disconnect_by_user_only = CreateConVar("sm_anti_reconnect_disconnect_by_user_only", "1", "\n0 = always block players from reconnecting\n1 = block player from reconnecting only if a client \"disconnected by user\"", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ar_admin_immunity = CreateConVar("sm_anti_reconnect_admin_immunity", "0", "0 = disabled, 1 = protect admins from Anti-Reconnect functionality", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_lan = FindConVar("sv_lan");
	
	HookConVarChange(cvar_ar_time, OnCVarChange);
	HookConVarChange(cvar_ar_disconnect_by_user_only, OnCVarChange);
	HookConVarChange(cvar_ar_admin_immunity, OnCVarChange);
	HookConVarChange(cvar_lan, OnCVarChange);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	
	AutoExecConfig(true, "plugin.antireconnect");
	LoadTranslations("antireconnect.phrases");
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:reason[128];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (kicked_by_plugin[client])
	{
		return;
	}
	
	GetEventString(event, "reason", reason, 128);

	if (StrEqual(reason, "Disconnect by user.") || !ar_disconnect_by_user_only)
	{
		if (isLAN || ar_time == 0 || IsFakeClient(client))
		{
			return;
		}
		
		if (GetUserFlagBits(client) && ar_admin_immunity)
		{
			return;
		}
		
		decl String:steamId[30];
		GetClientIP(client, steamId, sizeof(steamId));
		
		KvSetNum(db, steamId, GetTime());
	}
}

public OnClientPostAdminCheck(client)
{
	kicked_by_plugin[client] = false;
	
	if (isLAN || ar_time == 0 || IsFakeClient(client) || !IsClientConnected(client))
	{
		return;
	}
	
	decl String:steamId[30];	
	GetClientIP(client, steamId, sizeof(steamId));	
	
	new disconnect_time = KvGetNum(db, steamId, -1);
	
	if (disconnect_time == -1)
	{
		return;
	}
	
	new wait_time = disconnect_time + ar_time - GetTime();
	
	if (wait_time <= 0)
	{
		KvDeleteKey(db, steamId);
	}
	else
	{
		kicked_by_plugin[client] = true;
		KickClient(client, "%t", "You are not allowed to reconnect for X seconds", wait_time);
		LogAction(-1, client,"Kicked \"%L\". Player is not allowed to reconnect for %d seconds.", client, wait_time);
	}
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}


public OnConfigsExecuted()
{
	GetCVars();
}

public OnMapStart()
{
	CloseHandle(db);
	db = CreateKeyValues("antireconnect");
}

public GetCVars()
{
	isLAN = false;
	ar_time = GetConVarInt(cvar_ar_time);
	ar_disconnect_by_user_only = GetConVarBool(cvar_ar_disconnect_by_user_only);
	ar_admin_immunity = GetConVarBool(cvar_ar_admin_immunity);
}
