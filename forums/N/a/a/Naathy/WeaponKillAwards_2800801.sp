#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ArrayList gArray_LoadWeapons;

public Plugin myinfo = 
{
	name = "Kill Award",
	author = "Nathy",
	description = "Control money awarded by kill for each weapon",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/nathyzinhaa"
};

public void OnPluginStart() 
{ 
	HookEvent("player_death", PlayerDeath, EventHookMode_Post); 
	RegAdminCmd("sm_reload_money_cfg", Command_Reloadcfg, ADMFLAG_ROOT);
	
	LoadWeapons();
}

public Action Command_Reloadcfg(int client, int args)
{
	LoadWeapons();
	
	PrintToChat(client, "\x01 Kill Award CFG reloaded \x04Successfully\x01!");
	return Plugin_Handled;
}

void LoadWeapons()
{
	gArray_LoadWeapons = new ArrayList(38);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/WeaponAward.cfg");
	
	File hFile = OpenFile(sPath, "r");
	
	char sAward[32];
	
	if (hFile != INVALID_HANDLE)
	{
		while (hFile.ReadLine(sAward, sizeof(sAward)))
		gArray_LoadWeapons.PushString(sAward);
		
		delete hFile;
	}
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast) 
{
	char weapon[80];
	
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker")); 
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsClientValid(attacker) || victim == attacker)
	return;
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	char sBuffer[2][200];
	char weaponcfg[200];
	char data[220];
	
	for (int i = 0; i < gArray_LoadWeapons.Length; i++)
	{
		gArray_LoadWeapons.GetString(i, data, sizeof(data));
		ExplodeString(data, "=", sBuffer, 2, 200);
		
		int sAward = StringToInt(sBuffer[1]);
		Format(weaponcfg, sizeof(weaponcfg), "weapon_%s", weapon);
		
		if(StrContains(sBuffer[0], weaponcfg, false) != -1)
		{
			int clientMoney = GetEntProp(attacker, Prop_Send, "m_iAccount");
			clientMoney += sAward;
	
			ConVar maxMoneyCVar = FindConVar("mp_maxmoney");
			int maxMoney = GetConVarInt(maxMoneyCVar);
	
			if (clientMoney > maxMoney)
			clientMoney = maxMoney;
	
			SetEntProp(attacker, Prop_Send, "m_iAccount", clientMoney);
			return;
		}
	}
}

stock bool IsClientValid(int client = -1, bool bAlive = false) 
{
	return MaxClients >= client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)) ? true : false;
}