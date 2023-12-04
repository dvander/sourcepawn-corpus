#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Tank Spawn",
    author = "marcel",
    description = "Add to game for Survival gamemode spawn tankers",
    version = "1.0",
    url = ""
};

ConVar PluginOn;
ConVar ForceSurvivalMode;
ConVar noSpecialZombies; // zmienna na specjalnych zarazonych
ConVar noZombies; // zmienna na zwyklych zombie
ConVar GameModes; // zmienna okresla jaki to rodzaj gamemoda aktualnie jest ogrywany

public void OnPluginStart()
{
	noZombies = FindConVar("z_common_limit");
	noSpecialZombies = FindConVar("director_no_specials");
	GameModes = FindConVar("mp_gamemode");
	PluginOn = CreateConVar("plugin_on", "1", "Plugin On/Off");
	ForceSurvivalMode = CreateConVar("force_survival_mode", "0", "Force change gamemode on survival?");
	PluginOn.AddChangeHook(ConVarPluginOnChange);
	noZombies.AddChangeHook(ConVarsChanges);
	noSpecialZombies.AddChangeHook(ConVarsChanges);
	GameModes.AddChangeHook(ConVarsChanges);
	ForceSurvivalMode.AddChangeHook(ConVarsChanges);
}

public void OnConfigsExecuted()
{
	IsAlloved();
}

void IsAlloved()
{
	bool bPluginOn = PluginOn.BoolValue;
	if(bPluginOn)
	{
		SetCvars();
	}
	else
	{
		BackupCvars();
	}
}

void ConVarPluginOnChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAlloved();
}

void ConVarsChanges(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetCvars();
}

void SetCvars()
{
	if(noZombies.IntValue != 0)
	{
		noZombies.SetInt(0);
	}

	if(noSpecialZombies.IntValue == 0)
	{
		noSpecialZombies.SetInt(1);
	}

	if(ForceSurvivalMode.BoolValue)
	{
		char namess[32];
		GameModes.GetString(namess, sizeof(namess));
		if(!StrEqual(namess, "survival"))
		{
			GameModes.SetString("survival");
		}
	}
}

void BackupCvars()
{
	ResetConVar(noZombies);
	ResetConVar(noSpecialZombies);
}
