#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define CTH_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D & L4D2] Consistent Tank HP",
	author = "Psyk0tik (Crasher_3637)",
	description = "Set the Tank's HP consistently throughout all difficulties and game modes.",
	version = CTH_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=330134"
};

bool g_bSecondGame;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: g_bSecondGame = false;
		case Engine_Left4Dead2: g_bSecondGame = true;
		default:
		{
			strcopy(error, err_max, "This plugin only supports Left 4 Dead 1 & 2.");

			return APLRes_SilentFailure;
		}
	}

	return APLRes_Success;
}

ConVar g_cvTankHealth;

int g_iTankHealth;

public void OnPluginStart()
{
	g_cvTankHealth = CreateConVar("cth_tank_health", "4000", "The Tank's consistent health.", FCVAR_NOTIFY, true, 1.0, true, 65535.0);
	CreateConVar("cth_version", CTH_VERSION, "\"Consistent Tank HP\" Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_SPONLY);
	AutoExecConfig(true, "l4d_consistent_tank_health");

	g_cvTankHealth.AddChangeHook(vTankHealthCvar);

	HookEvent("tank_spawn", vEventTankSpawn);
}

public void OnConfigsExecuted()
{
	g_iTankHealth = g_cvTankHealth.IntValue;
}

public void vTankHealthCvar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iTankHealth = g_cvTankHealth.IntValue;
}

public void vEventTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iTankId = event.GetInt("userid"), iTank = GetClientOfUserId(iTankId);
	if (bIsTank(iTank))
	{
		RequestFrame(vTankSpawnFrame, iTankId);
	}
}

public void vTankSpawnFrame(int userid)
{
	int iTank = GetClientOfUserId(userid);
	if (bIsTank(iTank))
	{
		SetEntProp(iTank, Prop_Data, "m_iHealth", g_iTankHealth);
		SetEntProp(iTank, Prop_Data, "m_iMaxHealth", g_iTankHealth);
	}
}

stock bool bIsTank(int tank)
{
	int iClass = g_bSecondGame ? 8 : 5;
	return 0 < tank <= MaxClients && IsClientInGame(tank) && IsPlayerAlive(tank) && GetClientTeam(tank) == 3 && GetEntProp(tank, Prop_Send, "m_zombieClass") == iClass;
}