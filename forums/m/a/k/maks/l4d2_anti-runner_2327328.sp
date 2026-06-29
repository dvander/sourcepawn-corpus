/*
*	the original
*	https://forums.alliedmods.net/showthread.php?p=1136074
*
*	a modified version v1.0 from (steamcommunity.com/profiles/76561198025355822/)
*/

#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif

#include <sourcemod>
#include <sdktools>
#define UNLOCK 0
#define LOCK 1

char sg_map[40];
int ig_killTank;
int ig_SafetyLock;
int ig_keyman;
int ig_door;
int ig_time;

public OnPluginStart()
{
	HookEvent("round_start", Event_Round_Start);
	HookEvent("player_use", Event_Player_Use);
}

public OnMapStart()
{
	if (!IsModelPrecached("models/props_doors/checkpoint_door_02.mdl"))
	{
		PrecacheModel("models/props_doors/checkpoint_door_02.mdl", false);
	}
}

public ControlDoor(int Entity, int Operation)
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

public InitDoor()
{
	sg_map[0] = '\0';
	GetCurrentMap(sg_map, sizeof(sg_map)-1);

	if (StrEqual(sg_map, "c1m4_atrium", false) || StrEqual(sg_map, "c2m5_concert", false) || StrEqual(sg_map, "c3m4_plantation", false) || StrEqual(sg_map, "c4m5_milltown_escape", false) || StrEqual(sg_map, "c5m5_bridge", false) || StrEqual(sg_map, "c6m3_port", false) || StrEqual(sg_map, "c7m3_port", false) || StrEqual(sg_map, "c8m5_rooftop", false) || StrEqual(sg_map, "c9m2_lots", false) || StrEqual(sg_map, "c10m3_ranchhouse", false) || StrEqual(sg_map, "c10m4_mainstreet", false) || StrEqual(sg_map, "c10m5_houseboat", false) || StrEqual(sg_map, "c11m5_runway", false) || StrEqual(sg_map, "c12m5_cornfield", false) || StrEqual(sg_map, "c13m4_cutthroatcreek", false))
	{
		return 0;
	}

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
	return 0;
}

public Action:TimerDoor(Handle:timer)
{
	InitDoor();
	return Plugin_Stop;
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	ig_time = 0;
	ig_killTank = 0;
	ig_SafetyLock = UNLOCK;
	ig_door = -1;
	CreateTimer(4.0, TimerDoor);
	return Plugin_Continue;
}

public TyCheckpoint()
{
	ServerCommand("exec l4d2_antirunner/prop_door_rotating_checkpoint.cfg");
	return 0;
}

public SelectKeyman()
{
	ig_time = GetTime();
	int count = 0;
	int idAlive[MAXPLAYERS + 1];
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 2)
			{
				idAlive[count] = i;
				count++;
			}
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

public Keymanlive()
{
	if (!IsValidEntity(ig_keyman) || !IsClientInGame(ig_keyman) || GetClientTeam(ig_keyman) != 2 || !IsPlayerAlive(ig_keyman) || IsFakeClient(ig_keyman))
	{
		if (SelectKeyman())
		{
			return 1;
		}
	}
	return 0;
}

public Action:TimerKey(Handle:timer)
{
	if ((ig_SafetyLock == UNLOCK) || ig_time == 0)
	{
		
	}
	else if (Keymanlive())
	{
		PrintHintTextToAll("Keyman (%N).", ig_keyman);
	}
	return Plugin_Stop;
}

void TyClientKick()
{
	KickClient(ig_keyman, "Задержка команды");
	CreateTimer(3.0, TimerKey, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timedtyclient(Handle:timer, any:client)
{
	if ((ig_SafetyLock == UNLOCK) || ig_time == 0)
	{
		return Plugin_Stop;
	}
	else if (ig_time + 130 < GetTime())
	{
		if (!Keymanlive())
		{
			TyClientKick();
		}
	}
	else
	{
		CreateTimer(27.0, Timedtyclient, ig_keyman, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}

public Action:Event_Player_Use(Handle:event, const String:name[], bool:dontBroadcast)
{
	int Entity = GetEventInt(event, "targetid");
	if ((ig_SafetyLock == LOCK) && (Entity == ig_door) && IsValidEntity(Entity))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (ig_killTank == 0)
		{
			for (new i = 1; i <= GetMaxClients(); i++)
			{
				if (IsClientInGame(i))
				{
					if (GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
					{
						PrintHintText(client, "Kill Tank.");
						return Plugin_Continue;
					}
				}
			}

			TyCheckpoint();
			SelectKeyman();
			ig_killTank = 1;
		}

		AcceptEntityInput(Entity, "Lock");
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);

		Keymanlive();
		if (client == ig_keyman)
		{
			ig_time = 0;
			ig_SafetyLock = UNLOCK;
			ControlDoor(Entity, UNLOCK);
		}
		else
		{
			PrintHintTextToAll("Keyman (%N).", ig_keyman);
		}
	}
	return Plugin_Continue;
}
