#pragma semicolon 1

#include <sourcemod>
#include <smlib>
#include <zombiereloaded>
#undef REQUIRE_PLUGIN

Handle Location_Origins;
Handle Location_Angles;
float Origin[3];
float Angle[3];
 
public Plugin myinfo =
{
	name = "[ZR] Mother Zombie Teleport Fix",
	author = "SHUFEN from POSSESSION.tokyo",
	description = "Fix teleports of mother zombies for back to spawn",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	Location_Origins = CreateArray(64);
	Location_Angles = CreateArray(64);
}

public void OnMapStart()
{
	char sClassName[32];
	int iRealMaxEntities = GetMaxEntities() * 2;
	
	for (int x = 0; x < iRealMaxEntities; x++)
	{
		if (!IsValidEntity(x))
			continue;
		
		GetEntityClassname(x, sClassName, sizeof(sClassName));
		
		if (StrEqual(sClassName, "info_player_counterterrorist", false) || StrEqual(sClassName, "info_player_terrorist", false))
		{
			PrintToServer("Find Spawn Point [Index: %i]", x);
			GetEntPropVector(x, Prop_Send, "m_vecOrigin", Origin);
			PrintToServer("Origin(%i): %f %f %f", x, Origin[0], Origin[1], Origin[2]);
			GetEntPropVector(x, Prop_Send, "m_angRotation", Angle);
			PrintToServer("Angle(%i): %f %f %f", x, Angle[0], Angle[1], Angle[2]);
			PushArrayArray(Location_Origins, Origin, sizeof(Origin));
			PushArrayArray(Location_Angles, Angle, sizeof(Angle));
		}
	}
}

public OnMapEnd()
{
	ClearArray(Location_Origins);
	ClearArray(Location_Angles);
}

public ZR_OnClientInfected(int client, int attacker, bool motherinfect, bool respawnOverride, bool respawn)
{
	if (motherinfect)
	{
		TeleportPlayer(client);
	}
}


TeleportPlayer(int client)
{
	int iSize = GetArraySize(Location_Origins) - 1;
	int iLocation = GetRandomInt(0, iSize);
	
	GetArrayArray(Location_Origins, iLocation, Origin, sizeof(Origin));
	GetArrayArray(Location_Angles, iLocation, Angle, sizeof(Angle));
	
	TeleportEntity(client, Origin, Angle, NULL_VECTOR);
}