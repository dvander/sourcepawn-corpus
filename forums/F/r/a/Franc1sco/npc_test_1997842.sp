#include <sourcemod>
#include <sdktools>
#include <npc_generator>

public OnPluginStart()
{
	RegAdminCmd("sm_zombie", Command_Zombie, ADMFLAG_GENERIC);
	RegAdminCmd("sm_gman", Command_Gman, ADMFLAG_GENERIC);
	RegAdminCmd("sm_barney", Command_Barney, ADMFLAG_GENERIC);
	RegAdminCmd("sm_dog", Command_Dog, ADMFLAG_GENERIC);
	RegAdminCmd("sm_antlionguard", Command_Antlionguard, ADMFLAG_GENERIC);
	RegAdminCmd("sm_headcrab", Command_Headcrab, ADMFLAG_GENERIC);
}


public Action:Command_Zombie(client, args)
{
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		NPC_CreateZombie(position);
	else
		PrintHintText(client, "Wrong Position"); 

	return (Plugin_Handled);
}

public Action:Command_Dog(client, args)
{
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		NPC_CreateDog(position);
	else
		PrintHintText(client, "Wrong Position"); 

	return (Plugin_Handled);
}

public Action:Command_Gman(client, args)
{
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		NPC_CreateGman(position);
	else
		PrintHintText(client, "Wrong Position"); 

	return (Plugin_Handled);
}

public Action:Command_Barney(client, args)
{
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		NPC_CreateBarney(position);
	else
		PrintHintText(client, "Wrong Position"); 

	return (Plugin_Handled);
}

public Action:Command_Antlionguard(client, args)
{
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		NPC_CreateAntlionguard(position);
	else
		PrintHintText(client, "Wrong Position"); 

	return (Plugin_Handled);
}

public Action:Command_Headcrab(client, args)
{
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		NPC_CreateHeadcrab(position);
	else
		PrintHintText(client, "Wrong Position"); 

	return (Plugin_Handled);
}

stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return (true);
	}

	CloseHandle(trace);
	return (false);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}