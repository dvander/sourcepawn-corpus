#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.1"

new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[TF2] Skeleton",
	author = "Orion™",
	description = "Spawn Skeleton where you're looking.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_sskeleton_version", PL_VERSION, "Skeleton Spawner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_sskeleton", Command_Spawn, ADMFLAG_RCON, "Spawn a Skeleton on the map - Usage: sm_sskeleton");
	RegAdminCmd("sm_sskel", Command_Spawn, ADMFLAG_RCON, "Spawn a Skeleton on the map - Usage: sm_sskel");
	RegAdminCmd("sm_ss", Command_Spawn, ADMFLAG_RCON, "Spawn a Skeleton on the map - Usage: sm_ss");
	RegAdminCmd("sm_kakaka", Command_Spawn, ADMFLAG_RCON, "Spawn a Skeleton on the map - Usage: sm_kakaka");
	RegAdminCmd("sm_slaythemall", Command_SlaySkeleton, ADMFLAG_RCON, "Slays all Skeletons on the map - Usage: sm_slaythemall");
	RegAdminCmd("sm_sta", Command_SlaySkeleton, ADMFLAG_RCON, "Slays all Skeletons on the map - Usage: sm_sta");
}

public OnMapStart()
{
	PrecacheModel("models/bots/sniper_skeleton/sniper_skeleton.mdl"); 
}

// FUNCTIONS
public Action:Command_Spawn(client, args)
{
    if(!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return Plugin_Handled;
    }
    if(GetEntityCount() >= GetMaxEntities()-64)
    {
        PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore skeletons. Kill them all.");
        return Plugin_Handled;
    }
    new entity = CreateEntityByName("tf_zombie");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);
        g_pos[2] -= 10.0;
        TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
    }
    return Plugin_Handled;
}

public Action:Command_SlaySkeleton(client, args)
{
	if(IsValidClient(client))
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_zombie")) != -1 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Kill");
		}
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

stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}