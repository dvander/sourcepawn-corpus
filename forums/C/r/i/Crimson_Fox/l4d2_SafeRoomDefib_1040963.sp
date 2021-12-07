#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Float:SurvivorStart[3]

public Plugin:myinfo = 
{
	name = "[L4D2] Safe Room Defib",
	author = "Crimson_Fox",
	description = "Replaces a medkit in the safe room with a defib in versus.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("l4d2_srdefib_version", PLUGIN_VERSION,"Safe Room Defib Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post)
	//Look up what game we're running,
	decl String:game[64]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
}

//On every round,
public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	//if we're running a versus game,
	new String:GameMode[32]
	GetConVarString(FindConVar("mp_gamemode"), GameMode, 32)
	if (StrContains(GameMode, "versus", false) != -1)
	{
		//find where the survivors start so we know which medkit to replace,
		FindSurvivorStart()
		//and replace the medkit with a defib.
		ReplaceMedkit()
	}
}

public FindSurvivorStart()
{
	new EntityCount = GetEntityCount()
	new String:EdictClassName[128]
	new Float:Location[3]
	//Search entities for either a locked saferoom door,
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if ((StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1) && (GetEntProp(i, Prop_Send, "m_bLocked")==1))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				SurvivorStart = Location
				return
			}
		}
	}
	//or a survivor start point.
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrContains(EdictClassName, "info_survivor_position", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				SurvivorStart = Location
				return
			}
		}
	}
}

public ReplaceMedkit()
{
	new EntityCount = GetEntityCount()
	new String:EdictClassName[128]
	new Float:NearestMedkit[3]
	new Float:Location[3]
	new i_NearestMedkit
	//Look for the nearest medkit from where the survivors start,
	for (new i = 0; i <= EntityCount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				//If NearestMedkit is zero, then this must be the first medkit we found.
				if ((NearestMedkit[0] + NearestMedkit[1] + NearestMedkit[2]) == 0.0)
				{
					NearestMedkit = Location
					i_NearestMedkit = i
					continue
				}
				//If this medkit is closer than the last medkit, record its index.
				if (GetVectorDistance(SurvivorStart, Location, false) < GetVectorDistance(SurvivorStart, NearestMedkit, false)) i_NearestMedkit = i
			}
		}
	}
	//then replace it with a defib.
	new index = CreateEntityByName("weapon_defibrillator_spawn")
	new Float:Angle[3]
	GetEntPropVector(i_NearestMedkit, Prop_Send, "m_angRotation", Angle)
	TeleportEntity(index, Location, Angle, NULL_VECTOR)
	DispatchSpawn(index)
	AcceptEntityInput(i_NearestMedkit, "Kill")
}
