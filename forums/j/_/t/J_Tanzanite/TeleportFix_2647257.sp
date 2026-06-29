#include <sourcemod>
#include <clients>
#include <entity>
#include <events>
#include <halflife>
#include <vector>
#include <sdktools_trace>
#include <sdktools_functions>


public Plugin:myinfo = {
	name = "Teleport exploit fix",
	author = "TheLazyCWriter",
	description = "Fixes an exploit that allows teleport placements outside maps.",
	version = "1.2.0",
	url = ""
};


public OnPluginStart()
{
	HookEvent("player_builtobject", Event_BuildingMade, EventHookMode_Post);
}

public Action Event_BuildingMade(Event event, const char[] name, bool dontBroadcast)
{
	float ClientPos[3], EntityPos[3], pos1[3], pos2[3], ang[3];
	int ent, client;

	ent = GetEventInt(event, "index", -1);
	client = GetEventInt(event, "userid", -1);

	if (ent == -1 || client == -1)
		return;

	client = GetClientOfUserId(client);
	GetClientAbsOrigin(client, ClientPos);
	GetClientMaxs(client, ang);
	ClientPos[2] += ang[2]; // Top of the bounding box, seems more accurate than using eye position.
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", EntityPos);

	GetClientEyeAngles(client, ang);
	Point_Rotate_2D(ClientPos, ang[1] + 90.0, 0.1, pos1);
	Point_Rotate_2D(ClientPos, ang[1] - 90.0, 0.1, pos2);

	TR_TraceRayFilter(pos1, EntityPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter);
	if (TR_GetFraction() != 1.0)
	{
		RemoveBuilding(client, ent);
		return;
	}

	TR_TraceRayFilter(pos2, EntityPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter);
	if (TR_GetFraction() != 1.0)
		RemoveBuilding(client, ent);

	return;
}

RemoveBuilding(int client, int entity)
{
	PrintCenterText(client, "Can't place the building from where you're standing.");
	RemoveEntity(entity);
}

bool TraceFilter(int entity, int mask)
{
	return false;
}

Point_Rotate_2D(const float origin[3], const float yaw, const float distance, float writeto[3])
{
	float vec[3], ang[3];

	ScaleVector(ang, 0.0);
	ang[1] = yaw;
	GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vec, distance);
	AddVectors(vec, origin, writeto);
}