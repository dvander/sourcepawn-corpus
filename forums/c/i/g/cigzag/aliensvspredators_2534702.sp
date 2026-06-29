#pragma semicolon 1

#define PLUGIN_AUTHOR	"TheDarkSid3r"
#define PLUGIN_VERSION	"1.14-Beta"

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

ConVar g_hEnabled;
ConVar g_hAlienTeam;
ConVar g_hMeleeOnly;
ConVar g_hMedieval;

bool g_bMeleeOnly;
bool g_bEnabled;

public Plugin myinfo =
{
	name = "Aliens Vs Predators",
	author = PLUGIN_AUTHOR,
	description = "Aliens Vs Predators",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only currently works in Team Fortress 2!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LogMessage("---Initializing Aliens Vs Predators(v%s)---", PLUGIN_VERSION);

	LogMessage("---Initializing ConVars(Aliens Vs Predators)---");

	g_hEnabled = CreateConVar("avp_enabled", "1", "1 - Enable Aliens Vs Predators while 0 disables!", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hAlienTeam = CreateConVar("avp_alien_team", "1", "Team for Aliens,1 is Red and 0 is Blue", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hMeleeOnly = CreateConVar("avp_meleeonly", "1", "Melee Only.1 is true and 0 is false", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hMedieval = FindConVar("tf_medieval");

	HookConVarChange(g_hEnabled, ConVarAVP_Enable);

	LogMessage("---Initializing Events(Aliens Vs Predators)---");

	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("player_spawn", RoundStart);

	LogMessage("---Initializing Natives(Aliens Vs Predators)---");

	LogMessage("---Initialization Complete(Aliens Vs Predators)---");
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bEnabled = GetConVarBool(g_hEnabled);

	if (g_bEnabled)
	{
		for (int i = 1; i < MAXPLAYERS; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}

			TFTeam team = TF2_GetClientTeam(i);

			if (GetConVarBool(g_hAlienTeam))
			{
				if (team == TFTeam_Red)
				{
					SetAlienClass(i);
				}
				else
				{
					SetPredatorClass(i);
				}
			}
			else
			{
				if (team == TFTeam_Blue)
				{
					SetAlienClass(i);
				}
				else
				{
					SetPredatorClass(i);
				}
			}
		}

		SetMeleeMode();
	}
}

void SetMeleeMode()
{
	g_bMeleeOnly = GetConVarBool(g_hMeleeOnly);
	SetConVarBool(g_hMedieval, g_bMeleeOnly, false, false);
}

void SetPredatorClass(int client)
{
	TF2_SetPlayerClass(client, TFClass_Spy, false, TF2_GetPlayerClass(client) != TFClass_Spy);
}

void SetAlienClass(int client)
{
	TF2_SetPlayerClass(client, TFClass_Scout, false, TF2_GetPlayerClass(client) != TFClass_Scout);
}

public void ConVarAVP_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	LogMessage("---%s Aliens Vs Predators(v%s)---", g_bEnabled ? "Enabled" : "Disabled", PLUGIN_VERSION);
}
