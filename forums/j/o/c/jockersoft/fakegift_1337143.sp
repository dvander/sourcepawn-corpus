#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>

#define PL_VERSION "1.0"

#define MDL_GIFT "models/props_halloween/halloween_gift.mdl"

new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[TF2] Fake Halloween Gift",
	author = "Jocker",
	description = "Spawn a fake halloween gift where you're looking.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_fakegift_version", PL_VERSION, "Fake Gift Spaner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegAdminCmd("sm_fakegift", Command_Spawn, ADMFLAG_ROOT);
}

public OnMapStart()
{
	PrecacheModel(MDL_GIFT, true);
}

// FUNCTIONS

public Action:Command_Spawn(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	g_pos[2] -= 10;
	
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore fake gifts. Change maps.");
		return Plugin_Handled;
	}
	
	new ent = CreateEntityByName("prop_physics_override");
	SetEntityModel(ent,MDL_GIFT);
	DispatchKeyValue(ent, "StartDisabled", "false");
	DispatchSpawn(ent);
	TeleportEntity(ent, g_pos, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	DispatchKeyValue(ent, "ExplodeRadius", "100");
	DispatchKeyValue(ent, "ExplodeDamage", "300");
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);
	AcceptEntityInput(ent, "Enable");
	HookSingleEntityOutput(ent, "OnBreak", OnGiftBreak, true);
	SDKHook(ent, SDKHook_Touch, OnGiftTouch);

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

public OnGiftTouch(entity, other)
{
	TF2_StunPlayer(other, 6.0, _, TF_STUNFLAGS_LOSERSTATE);
	
	PrintToChat(other, "Sorry, you found the wrong gift");
	
	OnGiftBreak(NULL_STRING, entity, other, 0.0); 
}

public OnGiftBreak(const String:output[], caller, activator, Float:delay)
{
	UnhookSingleEntityOutput(caller, "OnBreak", OnGiftBreak);
	AcceptEntityInput(caller,"kill");
}