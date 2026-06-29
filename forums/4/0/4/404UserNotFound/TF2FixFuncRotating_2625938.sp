#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "18w48a"
#define SPAWNFLAGS 65

char g_strValidMaps[6][128] = {
	"ctf_2fort",
	"cp_egypt_final",
	"cp_gravelpit",
	"cp_gullywash_final1",
	"cp_steel",
	"pl_frontier_final"
};

public Plugin myinfo = {
	name = "[TF2] Fix func_rotating",
	author = "404UNF",
	description = "Fixes non-functional func_rotating entities in stock TF2 maps",
	version = PLUGIN_VERSION,
	url = "http://www.404UNF.ca"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] strError, int iErrMax)
{
	EngineVersion iEngine = GetEngineVersion();
	if (iEngine != Engine_TF2)
	{
		SetFailState("This plugin only works in Team Fortress 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_ffr_version", PLUGIN_VERSION, "[TF2] Fix func_rotating version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	HookEvent("teamplay_round_start", Event_RoundStart);

	// Late load
	FixFuncRotatingEntities();
}

public void OnMapStart()
{
	FixFuncRotatingEntities();
}

public void Event_RoundStart(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	FixFuncRotatingEntities();
}

void FixFuncRotatingEntities()
{
	char strCurrentMap[128];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));
	if (IsValidMap(strCurrentMap))
	{	
		// Dammit Gullywash, why do you have to be difficult?
		if (strcmp(strCurrentMap, "cp_gullywash_final1") == 0)
		{
			int iEnt = -1;
			while ((iEnt = FindEntityByClassnameEx(iEnt, "func_rotating")) != -1)
			{
				SetEntProp(iEnt, Prop_Data, "m_spawnflags", SPAWNFLAGS);

				// We have to start this entity for some reason.
				AcceptEntityInput(iEnt, "Start");

				// The clouds by default in Gullywash were re too bloody fast.
				// cloud_1 was set to 10.0, which was way too fast.
				// cloud_2 was set to 3.0, which was kind of ok I guess.
				// cloud_3 was set to 5.0, which was slightly too fast.
				// So let's change their speed. And let's do it the fun way.
				char strEntName[64];
				GetEntPropString(iEnt, Prop_Data, "m_iName", strEntName, sizeof(strEntName));
				if (strcmp(strEntName, "cloud_1") == 0)
				{
					SetEntPropFloat(iEnt, Prop_Data, "m_flMaxSpeed", GetRandomFloat(1.0, 2.0));
					SetEntPropFloat(iEnt, Prop_Data, "m_flTargetSpeed", GetRandomFloat(1.0, 2.0));
				}
				else if (strcmp(strEntName, "cloud_2") == 0)
				{
					SetEntPropFloat(iEnt, Prop_Data, "m_flMaxSpeed", GetRandomFloat(2.0, 3.0));
					SetEntPropFloat(iEnt, Prop_Data, "m_flTargetSpeed", GetRandomFloat(2.0, 3.0));
				}
				else if (strcmp(strEntName, "cloud_3") == 0)
				{
					SetEntPropFloat(iEnt, Prop_Data, "m_flMaxSpeed", GetRandomFloat(3.0, 4.0));
					SetEntPropFloat(iEnt, Prop_Data, "m_flTargetSpeed", GetRandomFloat(3.0, 4.0));
				}
			}
		}
		else
		{
			int iEnt = -1;
			while ((iEnt = FindEntityByClassnameEx(iEnt, "func_rotating")) != -1)
			{
				SetEntProp(iEnt, Prop_Data, "m_spawnflags", SPAWNFLAGS);
			}
		}
	}
}

stock int FindEntityByClassnameEx(int iStartEnt, const char[] strClassName)
{
    while (iStartEnt > -1 && !IsValidEntity(iStartEnt))
    {
    	iStartEnt--;
    }
    return FindEntityByClassname(iStartEnt, strClassName);
}

stock bool IsValidMap(const char[] strCurrentMap)
{
	for (int i = 0; i < 6; i++)
	{
		if (strcmp(strCurrentMap, g_strValidMaps[i]) == 0)
		{
			return true;
		}
	}
	return false;
}