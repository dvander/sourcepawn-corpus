/*
*	the original
*	https://forums.alliedmods.net/showthread.php?p=1136074
*
*	a modified version v1.0 from (steamcommunity.com/profiles/76561198025355822/)
*/

#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"
#define UNLOCK 0
#define LOCK 1

ConVar hCvar_Enabled;
bool bCvar_Enabled = false, bHooked = false;
char sg_map[40];
int ig_killTank = 0, ig_SafetyLock = 0, ig_keyman = 0, ig_door = 0, ig_time = 0;

public void OnPluginStart()
{
	CreateConVar("l4d2_anti_runner_version", PLUGIN_VERSION, "[L4D2] Anti runner plugin version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hCvar_Enabled = CreateConVar("l4d2_anti_runner_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCvar_Enabled.AddChangeHook(ConVarPluginOnChanged);
	AutoExecConfig(true, "l4d2_anti_runner");
}

public void OnMapStart()
{
	if (!IsModelPrecached("models/props_doors/checkpoint_door_02.mdl"))
	{
		PrecacheModel("models/props_doors/checkpoint_door_02.mdl", false);
	}
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

/****************************************************************************************************/

void ConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void IsAllowed()
{
	if (bCvar_Enabled && !bHooked)
	{
		bHooked = true;
		HookEvent("round_start", Events);
		HookEvent("player_use", Events);
	}
	else if (bCvar_Enabled && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", Events);
		UnhookEvent("player_use", Events);
	}
}

int ControlDoor(int Entity, int Operation)
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

int InitDoor()
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

Action TimerDoor(Handle timer)
{
	InitDoor();
	return Plugin_Stop;
}

Action Events(Event event, const char[] name, bool dontBroadcast)
{
	if (strcmp(name, "round_start") == 0)
	{
		ig_time = 0;
		ig_killTank = 0;
		ig_SafetyLock = UNLOCK;
		ig_door = -1;
		CreateTimer(4.0, TimerDoor);
	}
	else if(strcmp(name, "player_use") == 0)
	{
		int Entity = event.GetInt("targetid");
		if (ig_SafetyLock == LOCK && Entity == ig_door && IsValidEntity(Entity))
		{
			int client = GetClientOfUserId(event.GetInt("userid"));

			if (ig_killTank == 0)
			{
				for (int i = 1; i <= MaxClients; i++)
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
				SetEntProp(ig_keyman, Prop_Send, "m_iGlowType", 0);
				SetEntProp(ig_keyman, Prop_Send, "m_glowColorOverride", 0);
				SetEntityRenderColor(ig_keyman, 255, 255, 255, 255);
			}
			else
			{
				PrintHintTextToAll("Keyman (%N).", ig_keyman);
			}
		}
	}
	return Plugin_Continue;
}

void TyCheckpoint()
{
	ServerCommand("exec l4d2_antirunner/prop_door_rotating_checkpoint.cfg");
}

int SelectKeyman()
{
	ig_time = GetTime();
	int count = 0;
	int idAlive[MAXPLAYERS + 1];
	for (int i = 1; i <= MaxClients; i++)
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
	SetEntityRenderMode(ig_keyman, view_as<RenderMode>(3));
	SetEntityRenderColor(ig_keyman, 0,128,0,255);//Green
	SetEntProp(ig_keyman, Prop_Send, "m_iGlowType", 3);
	SetEntProp(ig_keyman, Prop_Send, "m_glowColorOverride", 52224);
	SetEntProp(ig_keyman, Prop_Send, "m_bFlashing", 0);
	SetEntProp(ig_keyman, Prop_Send, "m_nGlowRange", 0);
	CreateTimer(26.0, Timedtyclient, ig_keyman, TIMER_FLAG_NO_MAPCHANGE);
	return ig_keyman;
}

int Keymanlive()
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

Action TimerKey(Handle timer)
{
	if (ig_SafetyLock != UNLOCK && ig_time != 0 && Keymanlive())
	{
		PrintHintTextToAll("Keyman (%N).", ig_keyman);
	}
	return Plugin_Stop;
}

void TyClientKick()
{
	SetEntProp(ig_keyman, Prop_Send, "m_iGlowType", 0);
	SetEntProp(ig_keyman, Prop_Send, "m_glowColorOverride", 0);
	SetEntityRenderColor(ig_keyman, 255, 255, 255, 255);
	KickClient(ig_keyman, "Задержка команды");
	CreateTimer(3.0, TimerKey, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timedtyclient(Handle timer, any client)
{
	if (ig_SafetyLock == UNLOCK || ig_time == 0)
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
