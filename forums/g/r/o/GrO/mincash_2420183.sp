#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_DESCRIPTION "MinCash will set minimum value of money on player spawn"
#define PLUGIN_VERSION "v.1.0"

public Plugin myinfo =
{
	name = "Minimum Cash",
	author = "Nerus",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

Handle mp_startmoney = INVALID_HANDLE;
Handle sm_mincash_enabled = INVALID_HANDLE;
Handle sm_mincash_cash = INVALID_HANDLE;

int G_IACCOUNT = -1;
bool ENABLED = true;
int MONEY = 800;

/**
* Event on plugin start
*
*/
public void OnPluginStart()
{
	G_IACCOUNT = FindSendPropOffs("CCSPlayer", "m_iAccount");

	SetCvarsOnStart();
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
}

/**
* Set all ConVars
*
*/
stock void SetCvarsOnStart() 
{
	/*
	* Get ConVars
	*/
	mp_startmoney = FindConVar("mp_startmoney");

	/*
	 * Load/"Save default" config
	*/
	AutoExecConfig(true, "minimumcash");

	/*
	 * Register ConVars
	*/
	CreateConVar("sm_mincash_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	sm_mincash_enabled = CreateConVar("sm_mincash_enabled", "1", "Enable or disable mincash plugin: 0 - disabled, 1 - enabled");
	
	sm_mincash_cash = CreateConVar("sm_mincash_cash", "1000", "Minimum player cash on spawn, if 0 value will be same like mp_startmoney");

	/*
	 * Set values from ConVars
	*/
	ENABLED = GetConVarBool(sm_mincash_enabled);
	SetMoneyValue();

	/*
	* Add event ConVars handlers
	*/
	HookConVarChange(sm_mincash_enabled, OnChangeConVarMinimumCashEnabled);
	HookConVarChange(sm_mincash_cash, OnChangeConVarMinimumCash);
}

/**
* Event on ConVar sm_mincash_enabled changed
*
* @param ConVar 	sm_mincash_enabled
* @param oldValue	old sm_mincash_enabled value before change
* @param newValue	new sm_mincash_enabled value after change
*/
public void OnChangeConVarMinimumCashEnabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ENABLED = GetConVarBool(sm_mincash_enabled);
}

/**
* Event on ConVar sm_mincash_cash changed
*
* @param ConVar 	sm_mincash_cash
* @param oldValue	old sm_mincash_cash value before change
* @param newValue	new sm_mincash_cash value after change
*/
public void OnChangeConVarMinimumCash(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetMoneyValue();
}

/**
* Set minimum cash
*
*/
public void SetMoneyValue() 
{
	int mincash = GetConVarInt(sm_mincash_cash);
	if(mincash == 0) MONEY = GetConVarInt(mp_startmoney);
	else MONEY = mincash;
}

/**
* Event on player spawn
*
*/
public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (ENABLED)
	{
		int userId = GetEventInt(event, "userid");
		int client = GetClientOfUserId(userId);

		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			int client_current_money = GetEntData(client, G_IACCOUNT);
			if (CheckPlayerMoney(client, client_current_money)) CreateTimer(0.001, SetPlayerMoney, client);
		}
	}
	return Plugin_Continue;
}

/**
* Checking player money
*
* @param client 	An client entity index
* @param oldValue	Current player money value
* @return			Retrun true if player money is below minimum, otherwise true
*/
public bool CheckPlayerMoney(int client, int money)
{
	if (money < MONEY) return true;
	return false;
}

/**
* Timer to set player money
*
* @param timer 	Timer handler
* @param data	Client entity index
*/
public Action SetPlayerMoney(Handle timer, any data)
{
	if (IsClientInGame(data) && IsPlayerAlive(data)) SetEntData(data, G_IACCOUNT, MONEY, 4, true);
	return Plugin_Continue;
}
