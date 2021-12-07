#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

new Float:delicious[3];
new Handle:sofilling;

public Plugin:myinfo = 
{
	name = "[TF2] Spawn Sandvich",
	author = "Tylerst",
	description = "Spawn a Sandvich at the crosshair",
	version = PLUGIN_VERSION,
	url = "None"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_spawnsandvich_version", PLUGIN_VERSION, "Sandvich Spawner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sofilling = CreateConVar("sm_spawnsandvich_size", "1", "Healthkit size of sandwich 0=small 1=medium 2=large");
	RegAdminCmd("sm_sandvich", Itsjustham, ADMFLAG_SLAY, "Spawn a sandvich at the crosshair");
	RegAdminCmd("sm_sandWich", Itsjustham, ADMFLAG_SLAY, "Spawn a sandWich at the crosshair");
}

public OnMapStart()
{
	PrecacheModel("models/items/medkit_small.mdl");
	PrecacheModel("models/items/medkit_medium.mdl");
	PrecacheModel("models/items/medkit_large.mdl");
}

public Action:Itsjustham(client, args)
{
	new Float:bologna[3], Float:cheese[3], Float:lettuce[3], Float:bread[3], Float:tomato, sandvich;

	GetClientEyePosition(client, bologna);
	GetClientEyeAngles(client, cheese);
	
	new Handle:olive = TR_TraceRayFilterEx(bologna, cheese, MASK_SHOT, RayType_Infinite, TraceEntityFilter);

	if(TR_DidHit(olive))
	{   	 
   	 	TR_GetEndPosition(bread, olive);
		GetVectorDistance(bologna, bread, false);
		tomato = -35.0;
   	 	GetAngleVectors(cheese, lettuce, NULL_VECTOR, NULL_VECTOR);
		delicious[0] = bread[0] + (lettuce[0]*tomato);
		delicious[1] = bread[1] + (lettuce[1]*tomato);
		delicious[2] = bread[2] + (lettuce[2]*tomato);
	}
	else
	{
		ReplyToCommand(client, "[SM] Spawn Failed");
		return Plugin_Handled;
	}
	if(GetConVarInt(sofilling) == 0)
	{
		sandvich = CreateEntityByName("item_healthkit_small");		
	}
	else if(GetConVarInt(sofilling) == 2)
	{
		sandvich = CreateEntityByName("item_healthkit_full");		
	}
	else
	{
		sandvich = CreateEntityByName("item_healthkit_medium");		
	}
	
	if(IsValidEntity(sandvich))
	{		
		DispatchSpawn(sandvich);
          	SetEntProp(sandvich, Prop_Send, "m_iTeamNum", 0, 4);
		TeleportEntity(sandvich, delicious, NULL_VECTOR, NULL_VECTOR);
            	SetEntityModel(sandvich, "models/items/plate.mdl");
	}
	else
	{
		ReplyToCommand(client, "[SM] Spawn Failed");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}


public bool:TraceEntityFilter(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}
