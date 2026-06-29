#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define ESFP_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D/L4D2] Extra Survivor Finale Positions",
	author = "Psyk0tik (Crasher_3637)",
	description = "Spawns extra survivor positions for finale cutscenes.",
	version = ESFP_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=326643"
};

bool g_bLateLoad;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "The \"Extra Survivor Finale Positions\" only supports Left 4 Dead 1 & 2.");

		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

bool g_bFirstSpawn[MAXPLAYERS + 1];

ConVar g_cvAmount, g_cvMaxIncapCount;

float g_flPosOrigin[MAXPLAYERS + 1][3], g_flSaferoomPosition[MAXPLAYERS + 1][3];

int g_iAmount, g_iSpawned;

public void OnPluginStart()
{
	g_cvAmount = CreateConVar("l4d_esfp_amount", "4", "Number of extra survivor positions to spawn", _, true, 0.0, true, float(MAXPLAYERS + 1));
	CreateConVar("l4d_esfp_version", ESFP_VERSION, "ESFP Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_cvMaxIncapCount = FindConVar("survivor_max_incapacitated_count");

	AutoExecConfig(true, "l4d_esfp");

	HookEvent("bot_player_replace", eEventBotPlayerReplace);
	HookEvent("finale_vehicle_leaving", eEventFinaleVehicleLeaving, EventHookMode_Pre);
	HookEvent("player_bot_replace", eEventPlayerBotReplace);
	HookEvent("player_spawn", eEventPlayerSpawn);

	if (g_bLateLoad)
	{
		int iTrigger = FindEntityByClassname(-1, "trigger_finale");
		iTrigger = (iTrigger == -1) ? FindEntityByClassname(-1, "finale_trigger") : iTrigger;
		if (iTrigger > MaxClients && IsValidEntity(iTrigger))
		{
			HookSingleEntityOutput(iTrigger, "EscapeVehicleLeaving", FinaleHook, true);
		}

		g_bLateLoad = false;
	}
}

public void OnMapStart()
{
	g_iSpawned = 0;

	if (bIsFinaleMap() && g_iAmount > 0)
	{
		vSpawnExtraPositions();
	}
}

public void OnClientPutInServer(int client)
{
	g_bFirstSpawn[client] = false;
}

public void OnClientDisconnect(int client)
{
	g_bFirstSpawn[client] = false;
}

public void OnMapEnd()
{
	g_iAmount = 0;
}

public void OnEntitySpawned(int entity, const char[] classname)
{
	if (entity > MaxClients && IsValidEntity(entity))
	{
		if (StrEqual(classname, "trigger_finale", false) || StrEqual(classname, "finale_trigger", false))
		{
			HookSingleEntityOutput(entity, "EscapeVehicleLeaving", FinaleHook, true);
		}
		else if (StrEqual(classname, "info_survivor_position"))
		{
			char sName[128];
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
			if (StrContains(sName, "survivor_position_extra_") == -1)
			{
				//PrintToServer("An %s entity was found.", classname);
				//LogMessage("An %s entity was found.", classname);

				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_flPosOrigin[g_iAmount]);

				g_iAmount++;
			}
		}
	}
}

public void eEventBotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int iBot = GetClientOfUserId(event.GetInt("bot")), iSurvivor = GetClientOfUserId(event.GetInt("player"));
	if (bIsValidClient(iBot) && bIsSurvivor(iSurvivor))
	{
		g_bFirstSpawn[iSurvivor] = g_bFirstSpawn[iBot];
	}
}

public void eEventFinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	g_iAmount = 0;
	g_iSpawned = 0;
}

public void eEventPlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int iSurvivor = GetClientOfUserId(event.GetInt("player")), iBot = GetClientOfUserId(event.GetInt("bot"));
	if (bIsValidClient(iSurvivor) && bIsSurvivor(iBot))
	{
		g_bFirstSpawn[iBot] = g_bFirstSpawn[iSurvivor];
	}
}

public void eEventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iSurvivor = GetClientOfUserId(event.GetInt("userid"));
	if (bIsSurvivor(iSurvivor) && bIsFinaleMap() && L4D_IsInFirstCheckpoint(iSurvivor))
	{
		//PrintToServer("Saved %N's saferoom coordinates: %.2f %.2f %.2f", iSurvivor, g_flSaferoomPosition[iSurvivor][0], g_flSaferoomPosition[iSurvivor][1], g_flSaferoomPosition[iSurvivor][2]);
		//LogMessage("Saved %N's saferoom coordinates: %.2f %.2f %.2f", iSurvivor, g_flSaferoomPosition[iSurvivor][0], g_flSaferoomPosition[iSurvivor][1], g_flSaferoomPosition[iSurvivor][2]);

		GetClientAbsOrigin(iSurvivor, g_flSaferoomPosition[iSurvivor]);
	}
}

public void FinaleHook(const char[] output, int caller, int activator, float delay)
{
	if (caller > MaxClients && IsValidEntity(caller))
	{
		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor))
			{
				//PrintToServer("Gave %N godmode.", iSurvivor);
				//LogMessage("Gave %N godmode.", iSurvivor);

				SetEntProp(iSurvivor, Prop_Send, "m_currentReviveCount", g_cvMaxIncapCount.IntValue);
				SetEntProp(iSurvivor, Prop_Data, "m_takedamage", 0, 1);

				if (FindEntityByClassname(-1, "info_survivor_position") == -1)
				{
					//PrintToServer("Teleported %N back to saferoom: %.2f %.2f %.2f", iSurvivor, g_flSaferoomPosition[iSurvivor][0], g_flSaferoomPosition[iSurvivor][1], g_flSaferoomPosition[iSurvivor][2]);
					//LogMessage("Teleported %N back to saferoom: %.2f %.2f %.2f", iSurvivor, g_flSaferoomPosition[iSurvivor][0], g_flSaferoomPosition[iSurvivor][1], g_flSaferoomPosition[iSurvivor][2]);

					TeleportEntity(iSurvivor, g_flSaferoomPosition[iSurvivor], NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
}

static void vSpawnExtraPositions()
{
	static char sTargetName[32];
	static int iPos;
	for (iPos = 0; iPos < g_iAmount; iPos++)
	{
		if (g_iSpawned >= g_cvAmount.IntValue)
		{
			return;
		}

		static int iPosition;
		iPosition = CreateEntityByName("info_survivor_position");
		if (iPosition > MaxClients && IsValidEntity(iPosition))
		{
			//PrintToServer("%i (%i). %.2f %.2f %.2f", iPos, g_iSpawned, g_flPosOrigin[iPos][0], g_flPosOrigin[iPos][1], g_flPosOrigin[iPos][2]);
			//LogMessage("%i (%i). %.2f %.2f %.2f", iPos, g_iSpawned, g_flPosOrigin[iPos][0], g_flPosOrigin[iPos][1], g_flPosOrigin[iPos][2]);

			g_iSpawned++;

			TeleportEntity(iPosition, g_flPosOrigin[iPos], NULL_VECTOR, NULL_VECTOR);
			FormatEx(sTargetName, sizeof(sTargetName), "survivor_position_extra_%i", g_iSpawned);
			DispatchKeyValue(iPosition, "targetname", sTargetName);
			DispatchSpawn(iPosition);
			ActivateEntity(iPosition);

			//PrintToServer("An info_survivor_position entity was created.");
			//LogMessage("An info_survivor_position entity was created.");
		}
	}

	if (g_iSpawned < g_cvAmount.IntValue)
	{
		vSpawnExtraPositions();
	}
}

static bool bIsFinaleMap()
{
	return (FindEntityByClassname(-1, "info_changelevel") == -1 && FindEntityByClassname(-1, "trigger_changelevel") == -1) || FindEntityByClassname(-1, "trigger_finale") != -1 || FindEntityByClassname(-1, "finale_trigger") != -1;
}

static bool bIsSurvivor(int survivor)
{
	return bIsValidClient(survivor) && GetClientTeam(survivor) == 2 && IsPlayerAlive(survivor);
}

static bool bIsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}