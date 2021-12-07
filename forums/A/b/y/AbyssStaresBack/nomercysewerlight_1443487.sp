#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0"
#define NO_MERCY_SEWERS "c8m3_sewers"
#define WORK_LIGHT_MODEL "models/props_equipment/light_floodlight.mdl"

public Plugin:myinfo =
{
	name = "No Mercy Sewer Light Remover",
	author = "AbyssStaresBack",
	description = "Removes the work light from No Mercy 3 that the infected can use to block the tunnel",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=154097"
};

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	if (strcmp(buffer, NO_MERCY_SEWERS) == 0)
	{
		new currentEntity = -1;
		new entityToRemove = -1;
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

public OnPluginStart()
{
	CreateConVar("nomercysewerlight_ver", VERSION, "Version of the No Mercy Sewer Light plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("round_start", Event_RoundStart);
}
