#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

float SurvivorStart[3];
bool MapStart;

public Plugin myinfo = 
{
	name = "[L4D2] No Safe Room Medkits",
	author = "Crimson_Fox",
	description = "Replaces safe room first aid kits with pills in versus games.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1032403"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_nsrm_version", PLUGIN_VERSION, "No Safe Room Medkits Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	//Look up what game we're running,
	char game[64];
	GetGameFolderName(game, sizeof(game));
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
}

public void OnMapStart()
{
	MapStart = true;
}

//On every round,
public Action Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	if(MapStart)
	{
		//if we're running a versus game,
		char GameMode[32];
		GetConVarString(FindConVar("mp_gamemode"), GameMode, 32);
		if (StrContains(GameMode, "coop", false) != -1 || StrContains(GameMode, "versus", false) != -1)
		{
			//find where the survivors start so we know which medkits to replace,
			FindSurvivorStart();
			//and replace the medkits with pills.
			ReplaceMedkits();
		}
	}
}

public void FindSurvivorStart()
{
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	float Location[3];
	//Search entities for either a locked saferoom door,
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if ((StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1) && (GetEntProp(i, Prop_Send, "m_bLocked")==1))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				SurvivorStart = Location;
				return;
			}
		}
	}
	//or a survivor start point.
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "info_survivor_position", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				SurvivorStart = Location;
				return;
			}
		}
	}
}

public void ReplaceMedkits()
{
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	float NearestMedkit[3], Location[3];
	//Look for the nearest medkit from where the survivors start,
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				//If NearestMedkit is zero, then this must be the first medkit we found.
				if ((NearestMedkit[0] + NearestMedkit[1] + NearestMedkit[2]) == 0.0)
				{
					NearestMedkit = Location;
					continue;
				}
				//If this medkit is closer than the last medkit, record its location.
				if (GetVectorDistance(SurvivorStart, Location, false) < GetVectorDistance(SurvivorStart, NearestMedkit, false))
					NearestMedkit = Location;
			}
		}
	}
	//then replace the medkits near it with pain pills.
	for (int i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				if (GetVectorDistance(NearestMedkit, Location, false) < 400)
				{
					int index = CreateEntityByName("weapon_pain_pills_spawn");
					if (index != -1)
					{
						float Angle[3];
						GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
						TeleportEntity(index, Location, Angle, NULL_VECTOR);
						DispatchSpawn(index);
					}			
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
}

public void OnMapEnd()
{
	MapStart = false;
}
