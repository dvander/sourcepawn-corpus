#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.1"

new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[TF2] Spawn flag",
	author = "Michalpl",
	description = "Spawn a flag where you're looking.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

public OnPluginStart()
{
	RegAdminCmd("sm_flag", Command_Spawn, ADMFLAG_RCON);
}

public OnMapStart()
{
	PrecacheModel("models/props_td/atom_bomb.mdl"); 
}

// FUNCTIONS
public Action:Command_Spawn(client, args)
{
    if(!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return Plugin_Handled;
    }
    if(GetEntityCount() >= GetMaxEntities()-32)
    {
        PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore flags. Change maps.");
        return Plugin_Handled;
    }
    new entity = CreateEntityByName("item_teamflag");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);
        g_pos[2] -= 10.0;
        TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
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
