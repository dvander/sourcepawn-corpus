#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "AddExtraSpawns",
	author = "backwards",
	description = "Adds Extra Spawns If Needed.",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

Float:TspawnPos[3] = {0.0, 0.0, 0.0};
Float:CTspawnPos[3] = {0.0, 0.0, 0.0};

Float:TAngleVector[3] = {0.0, 0.0, 0.0};
Float:CTAngleVector[3] = {0.0, 0.0, 0.0};

new TSpawnPosCount, CTSpawnPosCount = 0;

public OnPluginStart()
{
	CreateTimer(1.0, DelayedStartup);
}

public OnMapStart()
{
	CreateTimer(1.0, DelayedStartup);
}

public Action:DelayedStartup(Handle:timer)
{
	TSpawnPosCount = 0;
	CTSpawnPosCount = 0;
	
	int iEntity = -1;
	
	while((iEntity = FindEntityByClassname(iEntity, "info_player_terrorist")) != -1)
	{
		TSpawnPosCount++;
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", TspawnPos);
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", TAngleVector);
	}
	
	while((iEntity = FindEntityByClassname(iEntity, "info_player_counterterrorist")) != -1)
	{
		CTSpawnPosCount++;
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", CTspawnPos);
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", CTAngleVector);
	}
	
	new bool:useTSpawnsForCtSpawns = false;
	new bool:useCtSpawnsForTSpawns = false;
	
	if(TSpawnPosCount == 0)
		useCtSpawnsForTSpawns = true;
	
	if(CTSpawnPosCount == 0)
		useTSpawnsForCtSpawns = true;
	
	if(TSpawnPosCount + CTSpawnPosCount >= 64 && CTSpawnPosCount > 15 && TSpawnPosCount > 15)
		return Plugin_Stop;
	
	if(TSpawnPosCount + CTSpawnPosCount == 0)
	{
		LogError("There are no ct or t spawn zones on this map, impossible to mimic.");
		return Plugin_Stop;
	}
	
	PrintToServer("Total Spawns Before Creating New Ones = %i", CTSpawnPosCount + TSpawnPosCount);
	
	new bool:Switch = false;
	
	while(TSpawnPosCount + CTSpawnPosCount < 64)
	{
		if(Switch)
		{
			if(useTSpawnsForCtSpawns)
			{
				new iEnt = CreateEntityByName("info_player_counterterrorist");
				if (DispatchSpawn(iEnt))
					TeleportEntity(iEnt, TspawnPos, TAngleVector, NULL_VECTOR);
			}
			else
			{
				new iEnt = CreateEntityByName("info_player_counterterrorist");
				if (DispatchSpawn(iEnt))
					TeleportEntity(iEnt, CTspawnPos, CTAngleVector, NULL_VECTOR);
			}
			CTSpawnPosCount++;
		}
		else
		{
			if(useCtSpawnsForTSpawns)
			{
				new iEnt = CreateEntityByName("info_player_terrorist");
				if (DispatchSpawn(iEnt))
					TeleportEntity(iEnt, CTspawnPos, CTAngleVector, NULL_VECTOR);
			}
			else
			{
				new iEnt = CreateEntityByName("info_player_terrorist");
				if (DispatchSpawn(iEnt))
					TeleportEntity(iEnt, TspawnPos, TAngleVector, NULL_VECTOR);
			}
			TSpawnPosCount++;
		}
		Switch = !Switch;
	}
	
	while(TSpawnPosCount > CTSpawnPosCount)
	{
		if(useTSpawnsForCtSpawns)
		{
			new iEnt = CreateEntityByName("info_player_counterterrorist");
			if (DispatchSpawn(iEnt))
				TeleportEntity(iEnt, TspawnPos, TAngleVector, NULL_VECTOR);
		}
		else
		{
			new iEnt = CreateEntityByName("info_player_counterterrorist");
			if (DispatchSpawn(iEnt))
				TeleportEntity(iEnt, CTspawnPos, CTAngleVector, NULL_VECTOR);
		}
		CTSpawnPosCount++;
	}
	
	while(CTSpawnPosCount > TSpawnPosCount)
	{
		if(useCtSpawnsForTSpawns)
		{
			new iEnt = CreateEntityByName("info_player_terrorist");
			if (DispatchSpawn(iEnt))
				TeleportEntity(iEnt, CTspawnPos, CTAngleVector, NULL_VECTOR);
		}
		else
		{
			new iEnt = CreateEntityByName("info_player_terrorist");
			if (DispatchSpawn(iEnt))
				TeleportEntity(iEnt, TspawnPos, TAngleVector, NULL_VECTOR);
		}
		TSpawnPosCount++;
	}
	
	PrintToServer("Total Spawns After Creating New Ones = %i", CTSpawnPosCount + TSpawnPosCount);
	
	return Plugin_Stop;
}