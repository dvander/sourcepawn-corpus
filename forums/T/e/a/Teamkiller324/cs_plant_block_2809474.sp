#pragma semicolon 1
#pragma newdecls required
#define Version "1.0.1"
#include <sdktools>

public Plugin myinfo =
{
	name = "Prevent bomb plant on round end.",
	author = "fat0nix, Teamkiller324",
	description = "Prevents bomb being planted on round end if CTs are alive.",
	version = Version,
	url = "https://forums.alliedmods.net/showthread.php?t=343763"
}

bool bPreventPlant = false; // Flag to block bomb planting
float bPreventPlantTime = 0.0; // Time when the round ended
float bPreventPlantDelay = 10.0; // Time in seconds to block planting after round end

public void OnMapStart()
{
	bPreventPlant = false;
	bPreventPlantTime = 0.0;
}

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("bomb_plant", Event_BombPlant, EventHookMode_Pre);
}

public Action Event_RoundEnd(Event event, const char[] event_name, bool dontBroadcast)
{
	bPreventPlant = true;
	bPreventPlantTime = GetGameTime();
	CreateTimer(bPreventPlantDelay, Timer_ResetBlockPlanting);
	return Plugin_Continue;
}

Action Event_BombPlant(Event event, const char[] event_name, bool dontBroadcast)
{
	if(!bPreventPlant)
	{
		return Plugin_Continue;
	}
	
	int userid = event.GetInt("userid");
	if(userid < 1)
	{
		return Plugin_Continue;
	}
	
	int CTsAlive;
	if((CTsAlive = GetAliveCTPlayers()) < 1)
	{
		return Plugin_Continue;
	}
	
	if((GetGameTime() - bPreventPlantTime) < bPreventPlantDelay)
	{
		int client;
		if(IsValidClient((client = GetClientOfUserId(userid))))
		{
			PrintToChat(client, "You may not plant the bomb right now, there are %i CTs alive.", CTsAlive);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

Action Timer_ResetBlockPlanting(Handle timer)
{
	bPreventPlant = false;
	return Plugin_Stop;
}

bool IsValidClient(int client)
{
	if(client < 1 || client > MAXPLAYERS)
	{
		return false;
	}
	
	if(!IsClientConnected(client))
	{
		return false;
	}
	
	if(!IsClientInGame(client))
	{
		return false;
	}
	
	if(IsClientSourceTV(client))
	{
		return false;
	}
	
	if(IsClientReplay(client))
	{
		return false;
	}
	
	return true;
}

int GetAliveCTPlayers()
{
	int count;
	int player;
	
	while((player = FindEntityByClassname(player, "player")) != -1)
	{
		if(IsValidClient(player))
		{
			if(GetEntProp(player, Prop_Send, "m_iTeamNum") == 3)
			{
				if(IsPlayerAlive(player))
				{
					count++;
				}
			}
		}
	}
	
	return count;
}