#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.2"

bool g_bLeft4Dead;

float g_fSafeRoomArea[3];

ConVar g_Cvar_NoKitsEnable;
ConVar g_Cvar_NoKitsModes;
ConVar g_Cvar_NoKitsChange;

public Plugin myinfo = 
{
	name = "[L4D2] No Safe Room Medkits",
	author = "Crimson_Fox, Updated by alasfourom",
	description = "Replaces safe room first aid kits with pills.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1032403"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead || Engine_Left4Dead2) g_bLeft4Dead = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar ("L4D_NoSafeRoomMedKits_version", PLUGIN_VERSION, "L4D NoSafeRoomMedKits" ,FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_NoKitsEnable = CreateConVar("l4d_no_saferoom_medkits_enable", "1", "Enable NoSafreRoomMedKits Plugin [1 = Enable, 0 = Disable]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_NoKitsModes 	= CreateConVar("l4d_no_saferoom_medkits_mode", "versus,coop", "Add The Modes You Want To Enable This Plugin In It [Seperated by Comma (,) With No Spaces]", FCVAR_NOTIFY);
	g_Cvar_NoKitsChange = CreateConVar("l4d_no_saferoom_medkits_change", "defibrillator", "You Can Replace Med-Kits With The Name Of Item [pain_pills, adrenaline, defibrillator, etc]", FCVAR_NOTIFY);
	AutoExecConfig(true, "L4D_NoSafeRoomMedKits");
	
	HookEvent("round_end", Event_OnRoundTriggered);
	HookEvent("round_freeze_end", Event_OnRoundTriggered);
}

void Event_OnRoundTriggered(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bLeft4Dead && g_Cvar_NoKitsEnable.BoolValue)
	{
		char GameMode[64];
		char GameInfo[64];
		
		FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
		g_Cvar_NoKitsModes.GetString(GameInfo, sizeof(GameInfo));
		
		if (StrContains(GameInfo, GameMode) != -1)
		{
			FindSurvivorStart();
			ReplaceMedkits();
		}
	}
}

void FindSurvivorStart()
{
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	float fLocation[3];
	
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if ((StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1) && (GetEntProp(i, Prop_Send, "m_bLocked") == 1))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				g_fSafeRoomArea = fLocation;
				return;
			}
		}
	}
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "info_survivor_position", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				g_fSafeRoomArea = fLocation;
				return;
			}
		}
	}
}

void ReplaceMedkits()
{
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	float NearestMedkit[3];
	float fLocation[3];
	
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				
				if ((NearestMedkit[0] + NearestMedkit[1] + NearestMedkit[2]) == 0.0)
				{
					NearestMedkit = fLocation;
					continue;
				}
				if (GetVectorDistance(g_fSafeRoomArea, fLocation, false) < GetVectorDistance(g_fSafeRoomArea, NearestMedkit, false)) NearestMedkit = fLocation;
			}
		}
	}
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fLocation);
				if (GetVectorDistance(NearestMedkit, fLocation, false) < 400)
				{
					char ItemName[64];
					
					g_Cvar_NoKitsChange.GetString(ItemName, sizeof(ItemName));
					Format(ItemName, sizeof(ItemName), "weapon_%s_spawn", ItemName);
					
					int index = CreateEntityByName(ItemName);
					if (index != -1)
					{
						float Angle[3];
						GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
						TeleportEntity(index, fLocation, Angle, NULL_VECTOR);
						DispatchSpawn(index);
					}				
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
}