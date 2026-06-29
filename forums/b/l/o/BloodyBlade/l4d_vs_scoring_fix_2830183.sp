#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "2.2"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Versus Scoring Fix",
	author = "Visor; originally by Jahze, vintik, cravenge, BloodyBlade",
	version = PLUGIN_VERSION,
	description = "Fixes Scores In Versus While Boss Infected Spawn.",
	url = "https://github.com/Attano/Equilibrium"
};

int cTank = 0;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine == Engine_Left4Dead)
	{
		cTank = 5;
	}
	else if(engine == Engine_Left4Dead2)
    {
		cTank = 8;
	}
	else
	{
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

PluginData plugin;

enum struct PluginCvars
{
	ConVar hVersusScoringFixOn;

	void Init()
	{
		CreateConVar("l4d_versus_scoring_fix_version", PLUGIN_VERSION, "[L4D2] Versus Scoring Fix plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.hVersusScoringFixOn = CreateConVar("l4d_versus_scoring_fix_on", "1", "Plugin On/Off", CVAR_FLAGS, true, 0.0, true, 1.0);
		AutoExecConfig(true, "l4d_versus_scoring_fix");
		this.hVersusScoringFixOn.AddChangeHook(OnConVarPluginOnChange);
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bPluginOn;
	bool bHooked;
	bool bPointsFrozen;
	int iDistance;
	int tCount;
	int wCount;

	void Init()
	{
		this.cvars.Init();
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.hVersusScoringFixOn.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("round_start", Events);
			HookEvent("tank_spawn", Events);
			HookEvent("player_death", Events);
			HookEvent("witch_spawn", Events);
			HookEvent("witch_killed", Events);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("round_start", Events);
			UnhookEvent("tank_spawn", Events);
			UnhookEvent("player_death", Events);
			UnhookEvent("witch_spawn", Events);
			UnhookEvent("witch_killed", Events);
			if(this.bPointsFrozen)
			{
				this.bPointsFrozen = false;
				UnFreezePoints();
			}
			this.tCount = 0;
			this.wCount = 0;
		}
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "round_start") == 0)
	{
		plugin.tCount = 0;
		plugin.wCount = 0;
		if (InSecondHalfOfRound())
		{
			UnFreezePoints();
		}
	}
	else if(strcmp(name, "tank_spawn") == 0)
	{
		plugin.tCount++;
		if(!plugin.bPointsFrozen)
		{
			plugin.bPointsFrozen = true;
			FreezePoints();
		}
	}
	else if(strcmp(name, "player_death") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (IsTank(client))
		{
			plugin.tCount--;
			CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(strcmp(name, "witch_spawn") == 0)
	{
		plugin.wCount++;
		if(!plugin.bPointsFrozen)
		{
			plugin.bPointsFrozen = true;
			FreezePoints();
		}
	}
	else if(strcmp(name, "witch_killed") == 0)
	{
		plugin.wCount--;
		if(plugin.bPointsFrozen && plugin.wCount == 0 && plugin.tCount == 0)
		{
			plugin.bPointsFrozen = false;
			UnFreezePoints();
		}
	}
	return Plugin_Continue;
}

Action CheckForTanksDelay(Handle timer) 
{
	if(plugin.bPointsFrozen && plugin.tCount == 0 && plugin.wCount == 0)
	{
		plugin.bPointsFrozen = false;
		UnFreezePoints();
	}
	return Plugin_Stop;
}

void FreezePoints() 
{
	plugin.iDistance = L4D_GetVersusMaxCompletionScore();
	L4D_SetVersusMaxCompletionScore(0);
}

void UnFreezePoints() 
{
	L4D_SetVersusMaxCompletionScore(plugin.iDistance);
}

bool IsTank(int client)
{
	return client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == cTank;
}

int InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}
