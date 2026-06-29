#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo=
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = ""
}

public void OnPluginStart()
{
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
}

void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	int entity = FindEntityByClassname(MaxClients + 1, "info_survivor_position");
	if(entity == INVALID_ENT_REFERENCE)
		return;

	float vOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

	int iSurvivor;
	static const char sOrder[][] = {"1", "2", "3", "4"};
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
			
		if(++iSurvivor < 4)
			continue;
			
		entity = CreateEntityByName("info_survivor_position");
		DispatchKeyValue(entity, "Order", sOrder[iSurvivor - RoundToFloor(iSurvivor / 4.0) * 4]);
		TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
	}
}