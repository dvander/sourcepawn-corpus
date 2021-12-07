#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MODEL_PROP "models/items/tf_gift.mdl"

public OnPluginStart()
{
	RegConsoleCmd("sm_spawnprop", Command_SpawnProp, "Spawns a prop at your crosshair location");
}

public Action:Command_SpawnProp(client, args)
{	
	decl Float:Position[3];
	if(!SetTeleportEndPoint(client, Position))
	{
		PrintToChat(client, "Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities() - 32)
	{
		PrintToChat(client, "Entity limit is reached. Can't spawn anymore props. Change maps.");
		return Plugin_Handled;
	}
	
	new Prop = CreateEntityByName("prop_physics_override");
	
	if(IsValidEntity(Prop))
	{		
		SetEntityModel(Prop, MODEL_PROP);
		DispatchKeyValue(Prop, "StartDisabled", "false");
		DispatchSpawn(Prop);
		
		Position[2] += 20.0;
		TeleportEntity(Prop, Position, NULL_VECTOR, NULL_VECTOR);
		
		SetEntityMoveType(Prop, MOVETYPE_NONE);
		DispatchKeyValue(Prop, "ExplodeRadius", "150");
		DispatchKeyValue(Prop, "ExplodeDamage", "375");
		SetEntProp(Prop, Prop_Data, "m_takedamage", 2);
		AcceptEntityInput(Prop, "Enable");
		HookSingleEntityOutput(Prop, "OnBreak", OnPropBreak, true);
		SDKHook(Prop, SDKHook_Touch, OnPropTouch);
		
		PrintToChat(client, "spawed a prop at (%f, %f, %f).", Position[0], Position[1], Position[2]);
	}
	return Plugin_Handled;
}

public OnPropTouch(entity, iClient)
{
	if (iClient <= MaxClients)
	{
		OnPropBreak(NULL_STRING, entity, iClient, 0.0);
	}
}

public OnPropBreak(const String:output[], caller, activator, Float:delay)
{
	if (activator <= MaxClients && strcmp(output, NULL_STRING) != 0)
	{
		//What happens to the destoryer of the prop
	}
	UnhookSingleEntityOutput(caller, "OnBreak", OnPropBreak);
	AcceptEntityInput(caller, "kill");
}

bool:SetTeleportEndPoint(client, Float:Position[3])
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
		Position[0] = vStart[0] + (vBuffer[0]*Distance);
		Position[1] = vStart[1] + (vBuffer[1]*Distance);
		Position[2] = vStart[2] + (vBuffer[2]*Distance);
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