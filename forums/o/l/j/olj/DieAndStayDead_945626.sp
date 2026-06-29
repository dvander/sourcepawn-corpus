#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new String:DeadClientsArray[MAXPLAYERS][1024];
new FinaleStarted = false;

public Plugin:myinfo = 

{
	name = "Die And Stay Dead",
	author = "Olj",
	description = "Survivors stay dead across mapchanges",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("player_death", DeathEvent, EventHookMode_Pre);
	HookEvent("finale_start", FinaleStart);
	HookEvent("round_start", RoundStart);
	HookEvent("mission_lost", FinaleLost);
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
		CreateTimer(27.0, RoundStartTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
public FinaleLost(Handle:event, const String:name[], bool:dontBroadcast)
	{
		if (FinaleStarted)
			{
				FinaleStarted = false;
			}
	}
	
public FinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
		FinaleStarted = true;
		for(new f = 0; f < sizeof(DeadClientsArray); f++)
			{
				DeadClientsArray[f] = "0";			
			}
	}


public DeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!FinaleStarted)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if ((IsValidClient(client))&&(GetClientTeam(client)==2))
				{
					decl String:SteamId[1024]; 
					GetClientAuthString(client, SteamId, sizeof(SteamId));
					DeadClientsArray[client] = SteamId;
				}
		}
}


public Action:RoundStartTimer(Handle:timer)
	{
		for(new i = 1; i < MaxClients; i++) 
			{
				if ((IsValidClient(i))&&(GetClientTeam(i)==2))
					{
						decl String:Auth[1024];
						GetClientAuthString(i, Auth, sizeof(Auth));					
						for(new f = 0; f < sizeof(DeadClientsArray); f++)
							{
								if (StrEqual(Auth, DeadClientsArray[f], false))
									{
										if (IsPlayerAlive(f)) ForcePlayerSuicide(f);
									}
								}
						}
				}
	}


public IsValidClient (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	//if (!IsPlayerAlive(client))
		//return false;
	return true;
}


	
