#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

char GameName[64], sBrokeModel[128];
ConVar l4d_mtgb_enable;
int L4D2Version;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Molotov Thrown/Gascan Broken Announcer",
	author = "cravenge and eziosid",
	description = "Makes an announcement when players throw a molotov or break a gascan.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=303599"
}

public void OnPluginStart()
{
	GameCheck();
	GetGameFolderName(GameName, sizeof(GameName));
	if(!StrEqual(GameName, "left4dead2", false))
	if(!StrEqual(GameName, "left4dead", false))
		SetFailState("The Molotov Thrown/Gascan Broken Announcer supports L4D and L4D2 only.");
	l4d_mtgb_enable = CreateConVar("l4d_mtgb_enable", "1", "Enable the plugin?\n(0: OFF)\n(1: ON)");
	CreateConVar("l4d_mtgb_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_SPONLY|FCVAR_DONTRECORD);
	if(L4D2Version)
		HookEvent("molotov_thrown", OnMolotovThrown);
	HookEvent("break_breakable", OnBreakBreakable, EventHookMode_Pre);
	AutoExecConfig(true, "l4d_mtgb");
}

public void OnPluginEnd()
{
	if(L4D2Version)
		UnhookEvent("molotov_thrown", OnMolotovThrown);
	UnhookEvent("break_breakable", OnBreakBreakable, EventHookMode_Pre);
}

public void OnMolotovThrown(Event event, const char[] name, bool dontBroadcast)
{
	int thrower = GetClientOfUserId(event.GetInt("userid"));
	if(!l4d_mtgb_enable.BoolValue || !IsValidClient(thrower))
		return;
	if(L4D2Version)
		if(l4d_mtgb_enable.BoolValue)
			PrintToChatAll("\x04%N\x01 threw a \x05molotov!", thrower);
}

public void OnBreakBreakable(Event event, const char[] name, bool dontBroadcast)
{
	int breaker = GetClientOfUserId(event.GetInt("userid")), broke = event.GetInt("entindex");
	if(!l4d_mtgb_enable.BoolValue || !IsValidClient(breaker) || (broke < 1 || !IsValidEntity(broke) || !IsValidEdict(broke)))
		return;
	GetEntPropString(broke, Prop_Data, "m_ModelName", sBrokeModel, sizeof(sBrokeModel));
	if(l4d_mtgb_enable.BoolValue && StrEqual(sBrokeModel, "models/props_junk/gascan001a.mdl", false))
		PrintToChatAll("\x04%N\x01 broke a \x05gascan\x01!", breaker);
}

void GameCheck()
{
	GetGameFolderName(GameName, sizeof(GameName));
	if(StrEqual(GameName, "left4dead2", false))
		L4D2Version = true;
	else
		L4D2Version = false;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsFakeClient(client));
}