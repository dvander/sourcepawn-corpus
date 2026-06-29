#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar
	speckillerEnabled, specKillerDeadRinger;

public Plugin myinfo =
{
	name = "Spectator Killer Follow",
	author = "lovetaste / weyouthey",
	description = "Switches to the killer of whoever you are spectating, similar to STV casting ( i dont know if stv actually does that LOL ).",
	version = PLUGIN_VERSION,
	url = "https://lovetaste.neocities.org/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	speckillerEnabled = CreateConVar("speckiller_enabled", "1", "Enables the spectatorkiller plugin.", _, true, 0.0, true, 1.0);
	specKillerDeadRinger = CreateConVar("speckiller_deadringer", "1", "Toggles whether or not feign death events trigger a spectator switch.", _, true, 0.0, true, 1.0);
}

public void OnMapStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	int deathflags = GetEventInt(event, "death_flags");
	if(IsValidClient(victim) && IsValidClient(killer) && speckillerEnabled.IntValue == 1)
	{
		for(int i = 1; i < MaxClients; i++)
		{
			if(!IsValidClient(i) || i == victim || i == killer)
				continue;
			if(!IsClientObserver(i))
				continue;
			if(GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") != victim)
				continue;
			if(deathflags & TF_DEATHFLAG_DEADRINGER)
			{
				if(specKillerDeadRinger.IntValue == 0)
					break;
			}
			
			SetEntPropEnt(i, Prop_Send, "m_hObserverTarget", killer);
		}
	}
}

stock bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || client < 0) 
		return false; 
	return true; 
}