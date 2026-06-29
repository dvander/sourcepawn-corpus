#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define MAX_STEAM_LENGTH 20

#define ROOT_KEY_VALUES "Root"

new Handle:RootData;
new bool:RootDataUsed = false;

new Handle:mp_startmoney = INVALID_HANDLE;
new bool:use_mp_startmoney = true;

new SpawnCount[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Keep Players Frags",
	author = "Jonny",
	description = "Keep Players Frags, Deaths, Money",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	mp_startmoney = FindConVar("mp_startmoney");
	if (mp_startmoney == INVALID_HANDLE) use_mp_startmoney = false;

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	if (RootDataUsed) PrintToServer("RootDataUsed");
	if (RootDataUsed) return;
	RootDataUsed = true;
	RootData = CreateKeyValues(ROOT_KEY_VALUES);
}

public OnMapEnd()
{
	if (!RootDataUsed) return;
	CloseHandle(RootData);
}

public OnPluginEnd()
{
	OnMapEnd();
}

public OnClientPostAdminCheck(client)
{
	SpawnCount[client] = 0;
	if (IsFakeClient(client)) return;
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client)) return;
	new String:SteamID[MAX_STEAM_LENGTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	PrintToServer("[CLIENT DISCONNECT] %N, %s", client, SteamID);
	KvJumpToKey(RootData, ROOT_KEY_VALUES);
	if (!KvJumpToKey(RootData, SteamID, true))
	{
		PrintToServer("if (!KvJumpToKey(RootData, SteamID, true))");
	}
	KvSetNum(RootData, "Deaths", GetClientDeaths(client));
	KvSetNum(RootData, "Frags", GetClientFrags(client));
	if (use_mp_startmoney) KvSetNum(RootData, "Money", GetClientMoney(client));
	KvGoBack(RootData);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SpawnCount[client]++;
	if (SpawnCount[client] != 2) return;
	if (IsFakeClient(client)) return;
	new String:SteamID[MAX_STEAM_LENGTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	KvJumpToKey(RootData, ROOT_KEY_VALUES);
	if (KvJumpToKey(RootData, SteamID, true))
	{
		SetClientFrags(client, KvGetNum(RootData, "Frags", 0));
		SetClientDeaths(client, KvGetNum(RootData, "Deaths", 0));
		if (use_mp_startmoney) SetClientMoney(client, KvGetNum(RootData, "Money", GetConVarInt(mp_startmoney)));
		KvGoBack(RootData);
	}
}

GetClientMoney(client)
{
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

SetClientFrags(client, frags)
{
	SetEntProp(client, Prop_Data, "m_iFrags", frags);
}

SetClientDeaths(client, deaths)
{
	SetEntProp(client, Prop_Data, "m_iDeaths", deaths);
}

SetClientMoney(client, money)
{
	new m_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (m_iAccount) SetEntData(client, m_iAccount, money);
}