#pragma semicolon 1

#define PLUGIN_VERSION "1.2.3"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <store>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Store - Arms",
	author = "good_live",
	description = "Buy some arms. lol.",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

ArrayList g_aArms;
ArrayList g_aTeams;

ConVar g_cInstant;
ConVar g_cDefaultT;
ConVar g_cDefaultCT;

public void OnPluginStart()
{
	g_aArms = new ArrayList(PLATFORM_MAX_PATH);
	g_aTeams = new ArrayList();
	
	g_cInstant = CreateConVar("sm_store_arms_instant", "0", "Defines whether the arms shoud be changed instantly or on next spawn.");
	g_cDefaultT = CreateConVar("sm_store_arms_default_t", "", "Path of the default T arms.");
	g_cDefaultCT = CreateConVar("sm_store_arms_default_ct", "", "Path of the default CT arms.");
	AutoExecConfig();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	Store_RegisterHandler("arms", "model", Arms_OnMapStart, Arms_Reset, Arms_Config, Arms_Equip, Arms_Remove, true);
}

public void Arms_OnMapStart()
{
	char sModel[PLATFORM_MAX_PATH];
	for (int i = 0; i < g_aArms.Length; i++){
		g_aArms.GetString(i, sModel, sizeof(sModel));
		PrecacheModel(sModel, true);
	}

	g_cDefaultT.GetString(sModel, sizeof(sModel));
	if (strlen(sModel) != 0)
		PrecacheModel(sModel, true);

	g_cDefaultCT.GetString(sModel, sizeof(sModel));
	if (strlen(sModel) != 0)
		PrecacheModel(sModel, true);
}

public void Arms_Reset()
{
	g_aArms.Clear();
	g_aTeams.Clear();
}

public bool Arms_Config(Handle &kv, int itemid)
{
	char sModel[PLATFORM_MAX_PATH];
	KvGetString(kv, "model", sModel, sizeof(sModel));
	Store_SetDataIndex(itemid, g_aArms.PushString(sModel));
	g_aTeams.Push(KvGetNum(kv, "team", 0));
	return true;
}

public int Arms_Equip(int client, int itemid)
{
	int iIndex = Store_GetDataIndex(itemid);
	int iTeam = g_aTeams.Get(iIndex);
	if(g_cInstant.BoolValue && (!iTeam || iTeam == GetClientTeam(client)))
	{
		char sModel[PLATFORM_MAX_PATH];
		g_aArms.GetString(iIndex, sModel, sizeof(sModel));
		DataPack pack = new DataPack();
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(sModel);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", sModel);
		CreateTimer(0.15, RemovePlayerWeapon, pack);
	}
	return iTeam;
}

public Action RemovePlayerWeapon(Handle timer, DataPack datapack)
{
	char sModel[PLATFORM_MAX_PATH];
	
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	
	datapack.ReadString(sModel, sizeof(sModel));
	
	if(0 < client <= MaxClients && IsClientConnected(client) && IsPlayerAlive(client))
	{
		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
		if (iWeapon != -1)
		{
			RemovePlayerItem(client, iWeapon);
			DataPack pack = new DataPack();
			pack.WriteCell(iWeapon);
			pack.WriteCell(GetClientUserId(client));
			CreateTimer(0.15, GivePlayerWeapon, pack);
		}
	}
	return Plugin_Stop;
}

public Action GivePlayerWeapon(Handle timer, DataPack pack)
{
	pack.Reset();
	int iWeapon = pack.ReadCell();
	int client = GetClientOfUserId(pack.ReadCell());
	if(0 < client <= MAXPLAYERS && IsClientConnected(client) && IsPlayerAlive(client))
	{
		EquipPlayerWeapon(client, iWeapon);
	}
	return Plugin_Stop;
}

public int Arms_Remove(int client, int itemid)
{
	int iIndex = Store_GetDataIndex(itemid);
	int iTeam = g_aTeams.Get(iIndex);
	if(g_cInstant.BoolValue && (!iTeam || iTeam == GetClientTeam(client)))
	{
		char sModel[PLATFORM_MAX_PATH];
		if (!GetClientDefaultArms(client, sModel, sizeof(sModel)))
			return iTeam;
		
		DataPack pack = new DataPack();
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(sModel);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", sModel);
		CreateTimer(0.15, RemovePlayerWeapon, pack);
	}
	return iTeam;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	char sModel[PLATFORM_MAX_PATH];

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int itemid = Store_GetEquippedItem(client, "arms", 0);
	if(itemid < 0)
		itemid = Store_GetEquippedItem(client, "arms", GetClientTeam(client));
	
	if(itemid < 0)
	{
		if (!GetClientDefaultArms(client, sModel, sizeof(sModel)))
			return Plugin_Continue;
	}
	else
	{
		int iIndex = Store_GetDataIndex(itemid);
		if(iIndex < 0 || iIndex >= g_aArms.Length)
			return Plugin_Continue;

		g_aArms.GetString(iIndex, sModel, sizeof(sModel));
	}
	SetEntPropString(client, Prop_Send, "m_szArmsModel", sModel);
	
	return Plugin_Continue;
}

bool GetClientDefaultArms(int client, char[] buffer, int maxlen)
{
	if (!IsClientInGame(client))
		return false;

	int clientTeam = GetClientTeam(client);

	char sTempModel[PLATFORM_MAX_PATH];
	if (clientTeam == CS_TEAM_T)
	{
		g_cDefaultT.GetString(sTempModel, sizeof(sTempModel));
		if (strlen(sTempModel) != 0)
		{
			strcopy(buffer, maxlen, sTempModel);
			return true;
		}
	}
	else if (clientTeam == CS_TEAM_CT)
	{
		g_cDefaultCT.GetString(sTempModel, sizeof(sTempModel));
		if (strlen(sTempModel) != 0)
		{
			strcopy(buffer, maxlen, sTempModel);
			return true;
		}
	}

	return false;
}