#define PLUGIN_VERSION "1.4"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Player Regen Hardcore",
	author = "Alex Dragokas",
	description = "Regenerates player HP based on count of tanks",
	version = PLUGIN_VERSION,
	url = "https://dragokas.com"
};

/*
	ChangeLog
	
	1.0
	 - Initial release

	// required left4dragokas

*/

ConVar g_ConVarEnable;
ConVar g_ConVarRegenInterval;
ConVar g_ConVarRegenHP[9];

int g_bEnabled;
int g_iRegenHP_Surv; // balancer (tanks-count) based
int m_iOffsetHealth;

float g_fRegenInterval;

bool g_bRegen[MAXPLAYERS+1];

public void OnPluginStart()
{
	CreateConVar("l4d_player_regen_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_ConVarEnable 			= CreateConVar("l4d_player_regen_enabled", 			"1", 	"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	g_ConVarRegenHP[0] 		= CreateConVar("l4d_player_regen_hp_0_tanks", 		"2", 	"Number of health to regen when the count of tanks is 0", CVAR_FLAGS);
	g_ConVarRegenHP[1] 		= CreateConVar("l4d_player_regen_hp_1_tanks", 		"3", 	"Number of health to regen when the count of tanks is 1", CVAR_FLAGS);
	g_ConVarRegenHP[2] 		= CreateConVar("l4d_player_regen_hp_2_tanks", 		"4", 	"Number of health to regen when the count of tanks is 2", CVAR_FLAGS);
	g_ConVarRegenHP[3] 		= CreateConVar("l4d_player_regen_hp_3_tanks", 		"5", 	"Number of health to regen when the count of tanks is 3", CVAR_FLAGS);
	g_ConVarRegenHP[4] 		= CreateConVar("l4d_player_regen_hp_4_tanks", 		"7", 	"Number of health to regen when the count of tanks is 4", CVAR_FLAGS);
	g_ConVarRegenHP[5] 		= CreateConVar("l4d_player_regen_hp_5_tanks", 		"10", 	"Number of health to regen when the count of tanks is 5", CVAR_FLAGS);
	g_ConVarRegenHP[6] 		= CreateConVar("l4d_player_regen_hp_6_tanks", 		"10", 	"Number of health to regen when the count of tanks is 6", CVAR_FLAGS);
	g_ConVarRegenHP[7] 		= CreateConVar("l4d_player_regen_hp_7_tanks", 		"12", 	"Number of health to regen when the count of tanks is 7", CVAR_FLAGS);
	g_ConVarRegenHP[8] 		= CreateConVar("l4d_player_regen_hp_8_tanks", 		"15", 	"Number of health to regen when the count of tanks is 8 or more", CVAR_FLAGS);
	g_ConVarRegenInterval 	= CreateConVar("l4d_player_regen_interval", 		"5.0", 	"Interval of each regen", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_player_regen");
	
	HookConVarChange(g_ConVarEnable,				ConVarChanged);
	HookConVarChange(g_ConVarRegenInterval,			ConVarChanged);
	
	m_iOffsetHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");
	
	GetCvars();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_ConVarEnable.BoolValue;
	g_iRegenHP_Surv = g_ConVarRegenHP[0].IntValue;
	g_fRegenInterval = g_ConVarRegenInterval.FloatValue;
	
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if (g_bEnabled) {
		if (!bHooked) {
			HookEvent("player_spawn",		Event_PlayerSpawn);
			HookEvent("player_hurt",		Event_PlayerHurt);
			HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("player_spawn",		Event_PlayerSpawn);
			UnhookEvent("player_hurt",		Event_PlayerHurt);
			UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

public void OnMapStart()
{
	CreateTimer(g_fRegenInterval, Timer_Regen, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Regen(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(g_bRegen[i]) {
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				RegenHP(i);
			}
		}
	}
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	BalanceHP(0);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client != 0 && GetClientTeam(client) == 2) {
		g_bRegen[client] = true;
	}
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client != 0) {
		g_bRegen[client] = true;
	}
	return Plugin_Continue;
}

bool RegenHP(int iClient)
{
	int iHP, iMaxHP;
	iHP = GetEntData(iClient, m_iOffsetHealth);
	
	iMaxHP = GetEntProp(iClient, Prop_Data, "m_iMaxHealth");

	if(iHP < iMaxHP)
	{
		iHP += g_iRegenHP_Surv;
		
		if(iHP < iMaxHP)
		{
			SetEntData(iClient, m_iOffsetHealth, iHP);
			return true;
		}
		SetEntData(iClient, m_iOffsetHealth, iMaxHP);
	}
	
	g_bRegen[iClient] = false;
	return false;
}

public void OnTankCountChanged(int iCount)
{
	BalanceHP(iCount);
}

void BalanceHP(int iTanks)
{
	if( iTanks > 8 )
	{
		iTanks = 8;
	}
	g_iRegenHP_Surv = g_ConVarRegenHP[iTanks].IntValue;
}
