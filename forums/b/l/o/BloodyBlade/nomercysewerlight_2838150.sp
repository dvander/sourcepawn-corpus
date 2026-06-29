#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define NO_MERCY_SEWERS "c8m3_sewers"
#define WORK_LIGHT_MODEL "models/props_equipment/light_floodlight.mdl"

public Plugin myinfo =
{
	name = "No Mercy Sewer Light Remover",
	author = "AbyssStaresBack",
	description = "Removes the work light from No Mercy 3 that the infected can use to block the tunnel",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=154097"
};

ConVar hPluginOn;
bool bMapStarted = false, bHooked = false;

public void OnPluginStart()
{
	CreateConVar("nomercysewerlight_ver", VERSION, "Version of the No Mercy Sewer Light plugin", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("nomercysewerlight_on", "1", "Plugin On/Off", CVAR_FLAGS);
	AutoExecConfig(true, "nomercysewerlight");
	hPluginOn.AddChangeHook(OnConVarPluginOnChanged);
}

public void OnMapStart()
{
	bMapStarted = true;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChanged(ConVar cvar, char[] OldValue, char[] NewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("round_start", Event_RoundStart);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("round_start", Event_RoundStart);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(bMapStarted)
	{
		char buffer[64];
		GetCurrentMap(buffer, sizeof(buffer));
		if (strcmp(buffer, NO_MERCY_SEWERS) == 0)
		{
			int currentEntity = -1;
			int entityToRemove = -1;
			while ((currentEntity = FindEntityByClassname(currentEntity, "prop_physics")) != -1)
			{
				if (entityToRemove > 0)
				{
					RemoveEdict(entityToRemove);
				}
				entityToRemove = -1;

				GetEntPropString(currentEntity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
				if (strcmp(buffer, WORK_LIGHT_MODEL) == 0)
				{
					entityToRemove = currentEntity;
				}
			}

			if (entityToRemove > 0)
			{
				RemoveEdict(entityToRemove);
			}
		}
	}
}

public void OnMapEnd()
{
	bMapStarted = false;
}
