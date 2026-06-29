#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGINVERSION	"1.0"

//Plugin Information:
public Plugin myinfo = 
{
	name = "HideNSeek Helper", 
	author = "The Doggy", 
	description = "God mode + No Backstab", 
	version = PLUGINVERSION,
	url = "coldcommunity.com"
};

ConVar g_hCV_GodModeEnabled;
ConVar g_hCV_GodModeTime;
ConVar g_hCV_BackstabDisabled;

bool g_bGodMode[MAXPLAYERS + 1];

public void OnPluginStart()
{
	g_hCV_GodModeEnabled = CreateConVar("dg_god_enabled", "1", "Sets whether god mode when damaged is enabled/disabled, 1=enabled, 0=disabled.");
	g_hCV_GodModeTime = CreateConVar("dg_godmode_time", "5.0", "The amount of time that players will get god mode for when damaged.");
	g_hCV_BackstabDisabled = CreateConVar("dg_backstab_disabled", "1", "Sets whether backstabing is enabled/disabled, 1=disabled, 0=enabled.");
	AutoExecConfig(true, "hidenseek_helper");

	// Hooking OnTakeDamage Event
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientPutInServer(int Client)
{
	if(IsValidClient(Client))
		SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int Client)
{
	if(IsValidClient(Client))
		SDKUnhook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iWeapon, float fDamageForce[3], float fDamagePosition[3])
{
	if(IsValidClient(iVictim) && IsValidClient(iAttacker) && iVictim != iAttacker)
	{
		// Blocking Backstabs and Godmode
		if((g_hCV_BackstabDisabled.BoolValue && iDamageType == 4100 && fDamage == 180.00) || g_bGodMode[iVictim])
		{
			fDamage = 0.0;
			return Plugin_Changed;
		}

		// Setting Godmode
		int iHP = GetClientHealth(iVictim);
		if(iHP - fDamage > 0.0 && g_hCV_GodModeEnabled.BoolValue && !g_bGodMode[iVictim])
		{
			g_bGodMode[iVictim] = true;
			CreateTimer(g_hCV_GodModeTime.FloatValue, Timer_GodMode, iVictim);
		}
	}
	return Plugin_Continue;
}

public Action Timer_GodMode(Handle hTimer, int Client)
{
	if(IsValidClient(Client))
		g_bGodMode[Client] = false;
	return Plugin_Stop;
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}