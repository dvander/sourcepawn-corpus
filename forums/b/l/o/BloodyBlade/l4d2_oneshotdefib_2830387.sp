#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "One-Shot Defib",
	author = "Oshroth(edit. by BloodyBlade)",
	description = "Survivors only get one chance with a defib before its useless.",
	version = PLUGIN_VERSION,
	url = "https://sourcemod.net/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

ConVar hPluginOn, hAttempts, hFallsTime;
int iAttempts, iAttempt[MAXPLAYERS + 1] = {0, ...};
float fFallsTime = 0.0;
bool bHooked = false;
Handle hTimerFalls[MAXPLAYERS + 1] = {null, ...};

public void OnPluginStart()
{
	CreateConVar("sm_osdefib_version", PLUGIN_VERSION, "One-Shot Defib version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("sm_osdefib_on", "1", "Plugin On/Off", CVAR_FLAGS, true, 0.0, true, 1.0);
	hAttempts = CreateConVar("sm_osdefib_attempts_count", "1", "How many attempts to revive the player are allowed?", CVAR_FLAGS, true, 0.0, true, 5.0);
	hFallsTime = CreateConVar("sm_osdefib_falls_time", "0.0", "0.0 = off. 0.0 < How long is the player allowed to revive after his death?", CVAR_FLAGS, true, 0.0, true, 300.0);

	hPluginOn.AddChangeHook(ConVarPluginOnChanged);
	hAttempts.AddChangeHook(ConVarsChanged);
	hFallsTime.AddChangeHook(ConVarsChanged);

	AutoExecConfig(true, "sm_osdefib");
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    iAttempts = hAttempts.IntValue;
    fFallsTime = hFallsTime.FloatValue;
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("round_start", Event_Round);
		HookEvent("round_end", Event_Round);
		HookEvent("mission_lost", Event_Round);
		HookEvent("map_transition", Event_Round);
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("survivor_rescued", Event_SurvivorRescued);
		HookEvent("defibrillator_used_fail", Event_UsedDefib);
		HookEvent("defibrillator_interrupted", Event_UsedDefib);	
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", Event_Round);
		UnhookEvent("round_end", Event_Round);
		UnhookEvent("mission_lost", Event_Round);
		UnhookEvent("map_transition", Event_Round);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("survivor_rescued", Event_SurvivorRescued);
		UnhookEvent("defibrillator_used_fail", Event_UsedDefib);
		UnhookEvent("defibrillator_interrupted", Event_UsedDefib);
	}
}

Action Event_Round(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
    	if(IsClientInGame(i))
    	{
    	    Reset(i);
    	}
	}
	return Plugin_Continue;
}

Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidSurv(client))
	{
	    Reset(client);
	}
	return Plugin_Continue;
}

Action Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if(IsValidSurv(victim))
	{
	    Reset(victim);
	}
	return Plugin_Continue;
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidSurv(client))
	{
	    if(hTimerFalls[client] == null && fFallsTime > 0.0)
	    {
	        hTimerFalls[client] = CreateTimer(fFallsTime, TimerFalls, client, TIMER_FLAG_NO_MAPCHANGE);
	    }
	}
	return Plugin_Continue;
}

Action Event_UsedDefib(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));
	if(IsValidSurv(client) && IsValidSurv(subject))
	{
		iAttempt[subject]++;
		if(iAttempt[subject] >= iAttempts)
		{
			int entity = GetPlayerWeaponSlot(client, 3);
			if(entity > -1)
			{
				char EdictName[128];
				GetEdictClassname(entity, EdictName, sizeof(EdictName));
				if(StrContains(EdictName, "defibrillator", false) != -1)
				{
					RemovePlayerItem(client, entity);
					RemoveEntity(entity);
					PrintHintTextToAll("%N's Defib ran out of power and became useless.", client);
				}
			}
		}	
	}
	return Plugin_Continue;
}

Action TimerFalls(Handle timer, int client)
{
    client = GetClientOfUserId(client);
    if(IsValidSurv(client) && !IsPlayerAlive(client))
    {
        iAttempt[client] = iAttempts;
    }
    return Plugin_Stop;
}

void Reset(int client)
{
    iAttempt[client] = 0;
    if(hTimerFalls[client] != null)
    {
        delete hTimerFalls[client];
    }
}

bool IsValidSurv(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}
