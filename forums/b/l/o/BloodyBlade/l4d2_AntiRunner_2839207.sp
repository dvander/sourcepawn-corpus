/*
*	the original
*	https://forums.alliedmods.net/showthread.php?p=1136074
*
*	a modified version v1.0 from (steamcommunity.com/profiles/76561198025355822/)
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define UNLOCK 0
#define LOCK 1
#define CHECKPOINT_DOOR2_MODEL "models/props_doors/checkpoint_door_02.mdl"

char sg_map[40];
bool ig_killTank = false;
int ig_SafetyLock = 0, ig_keyman = 0, ig_door = 0, ig_time = 0;

public void OnPluginStart()
{
	HookEvent("round_start", Event_Round_Start);
}

public void OnMapStart()
{
	if (!IsModelPrecached(CHECKPOINT_DOOR2_MODEL))
	{
		PrecacheModel(CHECKPOINT_DOOR2_MODEL, false);
	}
}

Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	ig_time = 0;
	ig_killTank = false;
	ig_SafetyLock = UNLOCK;
	ig_door = -1;
	CreateTimer(4.0, TimerDoor);
	return Plugin_Continue;
}

Action TimerDoor(Handle timer)
{
	InitDoor();
	return Plugin_Stop;
}

stock int InitDoor()
{
	if (!IsFinalMap())
	{
		int iEnt = -1;
		while((iEnt = FindEntityByClassname(iEnt, "prop_door_rotating_checkpoint")) != -1)
		{
			if (GetEntProp(iEnt, Prop_Data, "m_hasUnlockSequence") == UNLOCK)
			{
				ig_door = iEnt;
				ControlDoor(iEnt, LOCK);
				ig_SafetyLock = LOCK;
				break;
			}
		}
	}
	return 0;
}

stock int ControlDoor(int Entity, int Operation)
{
	if (Operation == LOCK)
	{
		AcceptEntityInput(Entity, "Close");
		AcceptEntityInput(Entity, "Lock");
		AcceptEntityInput(Entity, "ForceClosed");
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
	}
	else if (Operation == UNLOCK)
	{
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
		AcceptEntityInput(Entity, "Unlock");
		AcceptEntityInput(Entity, "ForceClosed");
		AcceptEntityInput(Entity, "Open");
	}
	return 0;
}

stock int SelectKeyman()
{
	ig_time = GetTime();
	int count = 0;
	int idAlive[MAXPLAYERS + 1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidRealSurv(i))
		{
			idAlive[count] = i;
			count++;
		}
	}

	if (count == 0)
	{
		return 0;
	}

	int key = GetRandomInt(0, count - 1);
	ig_keyman = idAlive[key];
	CreateTimer(26.0, Timedtyclient, ig_keyman, TIMER_FLAG_NO_MAPCHANGE);
	return ig_keyman;
}

stock int Keymanlive()
{
	if (!IsValidRealSurv(ig_keyman))
	{
		if (SelectKeyman())
		{
			return 1;
		}
	}
	return 0;
}

Action Timedtyclient(Handle timer, int client)
{
	if ((ig_SafetyLock == UNLOCK) || ig_time == 0)
	{
		return Plugin_Stop;
	}
	else if (ig_time + 130 < GetTime())
	{
		if (!Keymanlive())
		{
			KickClient(ig_keyman, "Задержка команды");
			if ((ig_SafetyLock == UNLOCK) || ig_time == 0)
			{
				return Plugin_Stop;
			}
			else if (Keymanlive())
			{
				PrintHintTextToAll("Keyman (%N).", ig_keyman);
			}
		}
	}
	else
	{
		CreateTimer(27.0, Timedtyclient, ig_keyman, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if ((buttons & IN_USE) && IsValidRealSurv(client) && !IsFinalMap())
	{
		int entity = GetClientAimTarget(client, false);
		if(entity != -1 && entity == ig_door && ig_SafetyLock == LOCK)
		{
			float vPosClient[3], vPosEnt[3];
			GetClientAbsOrigin(client, vPosClient);
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPosEnt);
			if (GetVectorDistance(vPosClient, vPosEnt) <= 70.0)
			{
				if (!ig_killTank)
				{
					if(IsAnyTankAlive())
					{
						PrintHintText(client, "Kill Tank.");
						return Plugin_Continue;
					}
					else
					{
						SelectKeyman();
						ig_killTank = true;
					}
				}

				Keymanlive();
				if(client == ig_keyman)
				{
					ig_time = 0;
					ig_SafetyLock = UNLOCK;
					ControlDoor(entity, UNLOCK);
				}
				else
				{
					PrintHintTextToAll("Keyman (%N).", ig_keyman);
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool IsValidRealSurv(int client) 
{
	return IsValidClient(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool IsValidAliveTank(int client) 
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

stock bool IsAnyTankAlive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidAliveTank(i))
		{
			return true;
		}
	}
	return false;
}

stock bool IsFinalMap()
{
	GetCurrentMap(sg_map, sizeof(sg_map)-1);
	if (StrEqual(sg_map, "c1m4_atrium", false) 
	|| StrEqual(sg_map, "c2m5_concert", false) 
	|| StrEqual(sg_map, "c3m4_plantation", false) 
	|| StrEqual(sg_map, "c4m5_milltown_escape", false) 
	|| StrEqual(sg_map, "c5m5_bridge", false) 
	|| StrEqual(sg_map, "c6m3_port", false) 
	|| StrEqual(sg_map, "c7m3_port", false) 
	|| StrEqual(sg_map, "c8m5_rooftop", false) 
	|| StrEqual(sg_map, "c9m2_lots", false) 
	|| StrEqual(sg_map, "c10m3_ranchhouse", false) 
	|| StrEqual(sg_map, "c10m5_houseboat", false) 
	|| StrEqual(sg_map, "c11m5_runway", false) 
	|| StrEqual(sg_map, "c12m5_cornfield", false) 
	|| StrEqual(sg_map, "c13m4_cutthroatcreek", false) 
	|| StrEqual(sg_map, "c14m2_lighthouse", false)
	)
	{
		return true;
	}
	return false;
}
