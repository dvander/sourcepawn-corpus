#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

int round;

public Plugin myinfo = 
{
	name = "pistol rounds",
	author = "shanapu",
	description = "",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=297958"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("announce_phase_end", Event_HalfTime);
}

public void OnMapStart()
{
	round = 0;
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool bDontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	GiveEquip(client);
}

public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast) 
{
	if(GetTeamClientCount(CS_TEAM_CT) > 0 && GetTeamClientCount(CS_TEAM_T) > 0)
	{
		round++;
		
		for (int i=1; i<MaxClients; i++)
		{
			GiveEquip(i);
		}
	}
}

void GiveEquip(int client)
{
	if(!IsValidClient(client))
		return;
			
	if(round == 1)
	{
		SetEntProp(client, Prop_Send, "m_iAccount", 800);
		SetEntProp(client, Prop_Data, "m_ArmorValue", 0);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
	}
	else if(round == 2)
	{
		SetEntProp(client, Prop_Send, "m_iAccount", 4000);
		SetEntProp(client, Prop_Data, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iAccount", 16000);
		SetEntProp(client, Prop_Data, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}
}

public void Event_HalfTime(Handle event, char[] name, bool dontBroadcast) 
{
	round = 0;
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}