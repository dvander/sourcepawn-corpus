#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.2"

float g_fSafeRoomArea[3];


public Plugin myinfo = 
{
	name = "[L4D2] No Safe Room Medkits",
	author = "Crimson_Fox, Updated by alasfourom",
	description = "Replaces safe room first aid kits with pills.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1032403"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	CreateTimer(2.0, Timer_StartFiltering, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

Action Timer_StartFiltering (Handle timer)
{
	Search_StartRoomArea();
	Replace_FirstAidKits();
	return Plugin_Handled;
}

void Search_StartRoomArea()
{
	int   EntityCount = GetEntityCount();
	char  EdictClassName[128];
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

void Replace_FirstAidKits()
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
					int index = CreateEntityByName("weapon_defibrillator_spawn");
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