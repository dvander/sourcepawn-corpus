#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

#define TEST_DEBUG 0
#define TEST_DEBUG_LOG 0

public Plugin:myinfo = 
{
	name = "L4D Repelling Saferoom Door",
	author = "AtomicStryker",
	description = " Creates a repulsive force around a Saferoom exit door to prevent early round starts ",
	version = PLUGIN_VERSION,
	url = ""
}


const Float:DOOR_FORCE_DISTANCE = 100.0;

new checkpointDoorEnt = -1;
new pushEnt = -1;
new bool:isPusherActive = false;
new bool:roundHandled = false;
new Float:vecPusher[3];

public OnPluginStart()
{
	HookEvent("player_entered_checkpoint", Event_RoundStart);
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("round_end", Event_RoundEnd);
}

TurnOffPush()
{
	if (pushEnt && IsValidEntity(pushEnt))
	{
		AcceptEntityInput(pushEnt, "Kill");
		pushEnt = -1;
	}
	
	checkpointDoorEnt = -1;
	isPusherActive = false;
}

stock Create_Point_Push(ent, const String:radius[] = "200.0", const String:innerRadius[] = "200.0", const String:magnitude[] = "1000.0", Float:zOffset = 30.0)
{
	new point_push = CreateEntityByName("point_push");
	
	if (IsValidEdict(point_push))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += zOffset;
		
		DispatchKeyValue(point_push, "targetname", "l4dpusher");
		
		///VALUES
		DispatchKeyValue(point_push, "enabled", "1");
		DispatchKeyValue(point_push, "magnitude", magnitude);
		DispatchKeyValue(point_push, "radius", radius);
		DispatchKeyValue(point_push, "inner_radius", innerRadius);
		DispatchKeyValue(point_push, "spawnflags", "8");
		
		DispatchSpawn(point_push);
		
		ActivateEntity(point_push);
		AcceptEntityInput(point_push, "TurnOn");
		
		ActivateEntity(point_push);
		AcceptEntityInput(point_push, "Enable");
		
		TeleportEntity(point_push, pos, NULL_VECTOR, NULL_VECTOR);
	}
	
	return point_push;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	AddForceFieldToSaferoomDoor();
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundHandled = false;
	TurnOffPush();
}

public Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new ent = GetEventInt(event, "targetid");
	if (ent == checkpointDoorEnt)
	{
		TurnOffPush();
		DebugPrintToAll("Door used, ForceField turned off");
	}
}

AddForceFieldToSaferoomDoor()
{
	if (isPusherActive || roundHandled) return;
	
	new survivor = FindSurvivor();
	if (survivor == -1) return;

	new checkPointDoorEntityIds[10] = -1;

	new ent, count;
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
	{
		checkPointDoorEntityIds[count] = ent;
		count++;
	}
	
	decl Float:survivorvec[3];
	GetClientAbsOrigin(survivor, survivorvec);
	
	decl Float:doorvec[3];
	new Float:mindist = 9999.0;
	decl Float:checkdist;
	count = 0;
	while (checkPointDoorEntityIds[count] != -1 && IsValidEntity(checkPointDoorEntityIds[count]))
	{
		GetEntPropVector(checkPointDoorEntityIds[count], Prop_Data, "m_vecAbsOrigin", doorvec);
		checkdist = GetVectorDistance(survivorvec, doorvec);
		
		if (checkdist < mindist)
		{
			ent = checkPointDoorEntityIds[count];
			mindist = checkdist;
		}
		count++;
		if (count == 10) break;
	}
	
	GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", doorvec);
	
	checkpointDoorEnt = ent;
	vecPusher = doorvec;
	isPusherActive = true;
	pushEnt = Create_Point_Push(ent, "120.0", "120.0");
	roundHandled = true;
	DebugPrintToAll("AddForceFieldToSaferoomDoor completed, ForceField active");
}

FindSurvivor()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
			return i;	
	}
	
	return -1;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[REPELDOOR] %s", buffer);
	PrintToConsole(0, "[REPELDOOR] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}