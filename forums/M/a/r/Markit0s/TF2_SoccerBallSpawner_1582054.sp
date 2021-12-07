#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:cvar_enable;
new Float:g_pos[3];

public Plugin:myinfo =
{
	name = "[TF2] Soccer Balls",
	author = "Markit0s",
	description = "My second third plugin ever",
	version = "1.0.0.4",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
    cvar_enable = CreateConVar("sm_soccerball_skin", "0", "Sets the skin of the ball.");
	RegAdminCmd("sm_soccerball", Command_CreateThatSoccerBall, ADMFLAG_SLAY, "Create the ball");
}

public OnMapStart()
{
    PrecacheModel("models/player/items/scout/soccer_ball.mdl", true);
}

public Action:Command_CreateThatSoccerBall(client, args)
{
    if(!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return Plugin_Handled;
    }
    if(GetEntityCount() >= GetMaxEntities()-32)
    {
        PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkin lords or soccer balls. Change maps.");
        return Plugin_Handled;
    }
	new entity = CreateEntityByName("prop_physics_override");
    if(IsValidEntity(entity))
    {
	    DispatchKeyValue(entity,"model", "models/player/items/scout/soccer_ball.mdl");
		if(GetConVarInt(cvar_enable) == 1) DispatchKeyValue(entity,"skin", "1");
        DispatchSpawn(entity);
		ActivateEntity(entity);
        g_pos[2] -= 10.0;
        TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
    }
    return Plugin_Handled;
}

// Ent Teleport Functions	
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	decl String:Derp[256];
	GetEntityNetClass(entity, Derp, sizeof(Derp));
	PrintToChatAll("durrNetworkable class name: %s (entity %i)", Derp, entity);
	return entity != data;
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