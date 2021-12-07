#pragma semicolon 1

#include <sdktools>

new Float:g_pos[3];
// new Float:g_pos_cord[3];
new RemovePortals = false;

new Handle:ZValueHandle;
new ZValue = 0;

new Handle:Z2ValueHandle;
new Z2Value = 0;

public Plugin:myinfo = 
{
	name = "[TF2] Spawn MONOCULUS! Portals",
	author = "Oshizu",
	description = "Allows you spawn MONOCULUS! portals.",
	version = "0.2d",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{

	RegAdminCmd("sm_monoportal_entrance", Command_SpawnPortal, ADMFLAG_GENERIC);
//	RegAdminCmd("sm_portal_entrance_cords", Command_SpawnPortal, ADMFLAG_GENERIC);
	RegAdminCmd("sm_monoportal_exit", Command_SpawnExit, ADMFLAG_GENERIC);
//	RegAdminCmd("sm_portal_cleanup_original", Command_RemoveAll, ADMFLAG_GENERIC);
	RegAdminCmd("sm_monoportal_cleanup", Command_RemoveAll, ADMFLAG_GENERIC);
	
	ZValueHandle = CreateConVar("sm_monoportal_height",	"0", "How high above ground should portal be located?");
	HookConVarChange(ZValueHandle, OnZHeightChange);
	
	Z2ValueHandle = CreateConVar("sm_monoportal_exit_height",	"0", "How high above ground should portal exit be located?");
	HookConVarChange(Z2ValueHandle, OnZ2HeightChange);
	
	AutoExecConfig(true, "plugin.spawn_monoportal");
}

public OnZHeightChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new value = StringToInt(newVal);
	SetConVarInt(cvar, value);
	ZValue = value;
}

public OnZ2HeightChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new value = StringToInt(newVal);
	SetConVarInt(cvar, value);
	Z2Value = value;
}

public OnMapStart()
{
	PrecacheModel("models/props_halloween/bombonomicon.mdl", true);
}

public OnGameFrame()
{
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "info_target"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			if(RemovePortals)
			{
				decl String:targetname[128];
				GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
				if(StrEqual(targetname, "spawn_purgatory", false))
				{
					AcceptEntityInput(entity, "kill");
				}
			}
		}
	}
}

// FUNCTIONS
public Action:Command_RemoveAll(client, args)
{
	PrintToChat(client, "All Portals will be removed in 1.0 secound. Please Wait!");
	RemovePortals = true;
	CreateTimer(1.0, RemoveAllDisable, client);
}

public Action:RemoveAllDisable(Handle:timer, any:client)
{
	PrintToChat(client, "All Portals has been removed!");
	RemovePortals = false;
}

public Action:Command_SpawnExit(client, args)
{
	if(!SetTeleportEndPoint(client))
	{	
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;	
	}
	new target = CreateEntityByName("info_target");	
	if(IsValidEntity(target))
	{
		g_pos[2] -= 10.0;
		g_pos[2] += Z2Value;
		TeleportEntity(target, g_pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(target, "targetname", "spawn_purgatory");
		DispatchSpawn(target);
		PrintToChat(client, "Portal Exit Has Been Spawned!");
	}
	return Plugin_Handled;
}

public Action:Command_SpawnPortal(client, args)
{
	if(!SetTeleportEndPoint(client))
	{	
		PrintToChat(client, "[SM] Could not find spawn point.");	
		return Plugin_Handled;
	}
	new portal = CreateEntityByName("teleport_vortex");	
	if(IsValidEntity(portal))
	{
		SetEntProp(portal, Prop_Send, "m_iState", 1);
		DispatchSpawn(portal);
		g_pos[2] -= 10.0;
		g_pos[2] += ZValue;
		TeleportEntity(portal, g_pos, NULL_VECTOR, NULL_VECTOR);
		PrintToChat(client, "Portal Has been spawned!");
	}
	return Plugin_Handled;
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}