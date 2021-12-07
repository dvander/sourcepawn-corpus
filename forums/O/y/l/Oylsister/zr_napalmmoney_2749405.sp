#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zr_grenade_effects>

float g_fMaxTime[MAXPLAYERS+1];
int g_iDamage[MAXPLAYERS+1];

bool g_bEnabled;
float g_fInterval;
int g_iCashMode;
int g_iCash;

ConVar g_CvarEnable, g_CvarInterval, g_CvarCashMode, g_CvarCash;

public Plugin myinfo =
{
	name = "Napalm Grenade Burning Cash",
	author = "Oylsister",
	description = "Give a player a money while napalm grenade still burning the zombies",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=332947"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", OnPlayerHurt);

	g_CvarEnable = CreateConVar("zr_napalm_burn_cash_enabled", "1.0", "Enabled This plugin or not", _, true, 0.0, true, 1.0);
	g_CvarInterval = CreateConVar("zr_napalm_burn_cash_interval", "0.2", "Every X second while napalm still burn victim will get cash", _, true, 0.1, false);
	g_CvarCashMode = CreateConVar("zr_napalm_burn_cash_mode", "1.0", "Mode 1 = Cash based on Damage that player have done, Mode 2 = Cash based on ConVar below", _, true, 1.0, true, 2.0);
	g_CvarCash = CreateConVar("zr_napalm_burn_cash_money", "10", "How much cash player will receive per X second while napalm still burn victim", _, true, 1.0, false);
	
	HookConVarChange(g_CvarEnable, OnConVarChange);
	HookConVarChange(g_CvarInterval, OnConVarChange);
	HookConVarChange(g_CvarCashMode, OnConVarChange);
	HookConVarChange(g_CvarCash, OnConVarChange);
	
	AutoExecConfig(true, "zr_napalmmoney");
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_CvarEnable)
	{
		g_bEnabled = !g_bEnabled;
	}
	else if (convar == g_CvarInterval)
	{
		g_fInterval = GetConVarFloat(g_CvarInterval);
	}
	else if (convar == g_CvarCashMode)
	{
		g_iCashMode = GetConVarInt(g_CvarCashMode);
	}
	else
	{
		g_iCash = GetConVarInt(g_CvarCash);
	}
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnabled)
		return;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	char weapon[48]; 
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	int damage = GetEventInt(event, "dmg_health");
	
	if (GetClientTeam(client) != 2 && GetClientTeam(attacker) != 3)
		return;
		
	else if (!StrEqual(weapon, "weapon_hegrenade", false))
		return;
	
	else
	{
		if (g_iCashMode == 1)
			g_iDamage[attacker] = damage;
	}
}

public int ZR_OnClientIgnited(int client, int attacker, float duration)
{
	if(g_bEnabled)
	{
		g_fMaxTime[attacker] = GetEngineTime() + duration;
	
		CreateTimer(g_fInterval, GiveAttackerMoney, attacker, TIMER_REPEAT);
	}
}

public Action GiveAttackerMoney(Handle timer, any client)
{
	int g_iClientCash;
		
	if(GetEngineTime() < g_fMaxTime[client])
	{
		g_iClientCash = GetEntProp(client, Prop_Send, "m_iAccount");
		
		if(g_iCashMode == 1)
		{
			SetEntProp(client, Prop_Send, "m_iAccount", g_iClientCash + g_iDamage[client]);
			return Plugin_Continue;
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iAccount", g_iClientCash + g_iCash);
			return Plugin_Continue;
		}
	}
	
	else
	{
		g_iDamage[client] = 0;
		return Plugin_Stop;
	}
}