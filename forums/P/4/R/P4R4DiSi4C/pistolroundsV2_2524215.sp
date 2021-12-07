#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "codingcow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo = 
{
	name = "pistol rounds",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

bool firstRound = false;

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("announce_phase_end", OnHalfTime, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", SpawnEvent);
}

public void OnMapStart()
{
	firstRound = true;
}

public Action SpawnEvent(Handle event,const char[] name,bool dontBroadcast)
{
    int client_id = GetEventInt(event, "userid");
    int client = GetClientOfUserId(client_id);
    
    if(firstRound)
    {
    	if(IsValidClient(client))
		{
			Client_SetArmor(client, 0);
		}
  	}
}

public OnRoundStart(Handle event, char[] name, bool dontBroadcast) 
{
	if(firstRound && GetTeamClientCount(CS_TEAM_CT) > 0 && GetTeamClientCount(CS_TEAM_T) > 0)
	{
		for (new i=1; i<MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				Client_SetArmor(i, 0);
			}
		}
		ServerCommand("mp_buytime 0");
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(firstRound)
	{
		firstRound = false;
		ServerCommand("mp_buytime 90");
	}	
}

public OnHalfTime(Handle event, char[] name, bool dontBroadcast) 
{
	firstRound = true;
}


bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

stock Client_SetArmor(client, value)
{
    SetEntProp(client, Prop_Data, "m_ArmorValue", value);
}