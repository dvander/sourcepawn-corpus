#pragma semicolon 1
#include <sourcemod>
#include <sdktools> 

#define PLUGIN_VERSION "1.2.0.0RevA"
#define BOUNDINGBOX_INFLATION_OFFSET 3

public Plugin:myinfo =
{
	name = "Player-Teleport by Dr. HyperKiLLeR",
	author = "Dr. HyperKiLLeR / dcx2",
	description = "Go to a player or teleport a player to your crosshair",
	version = PLUGIN_VERSION,
	url = ""
};
 
//Plugin-Start
public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY, "Go to a player");
	RegAdminCmd("sm_bringtocursor", Command_Bring, ADMFLAG_SLAY, "Teleport a player to your cursor");

	CreateConVar("goto_version", PLUGIN_VERSION, "Dr. HyperKiLLeRs Player Teleport",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:Command_Goto(client,args)
{
	if(!client)
	{
		PrintToServer("[SM] Unable to execute this command from the server console!");
		return Plugin_Handled;
	}
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_goto <#userid|name of teleport destination> [<#userid|name to teleport (default self>]");
		return Plugin_Handled;
	}
	decl String:arg[256];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl dest_list[MAXPLAYERS], teleport_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, arg, sizeof(arg));
	if ((target_count = ProcessTargetString(
			arg,
			client,
			dest_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		// If we try to goto a client whose name does not exist, fail silently
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (target_count > 1)
	{
		ReplyToCommand(client, "Cannot teleport to multiple different people!");
		return Plugin_Handled;
	}
	
	// assume we are targeting self
	target_count = 1;
	teleport_list[0] = client;
	
	// check for other people to teleport
	if (args > 1)
	{
		GetCmdArg(2, arg, sizeof(arg));
		if ((target_count = ProcessTargetString(
				arg,
				client,
				teleport_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	decl Float:VecOrigin[3];
	GetClientAbsOrigin(dest_list[0], VecOrigin);
	
	VecOrigin[2] += BOUNDINGBOX_INFLATION_OFFSET;	// move up a bit to prevent getting stuck in ground somehow
	
	//Teleport
	for (new i=0; i < target_count; i++)
	{
		TeleportEntity(teleport_list[i], VecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Handled;
}

public Action:Command_Bring(client,args)
{
	if(!client)
	{
		PrintToServer("[SM] Unable to execute this command from the server console!");
		return Plugin_Handled;
	}
	decl String:arg[256];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl teleport_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	// no argument assumes self
	target_count = 1;
	teleport_list[0] = client;
	
	if (args > 0)
	{
		GetCmdArg(1, arg, sizeof(arg));
		if ((target_count = ProcessTargetString(
				arg,
				client,
				teleport_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	decl Float:VecOrigin[3];
	// Look for a collision point from this client from their eyes in the direction they are looking
	if (!GetCollisionPoint(client, VecOrigin, true))
	{
		// If we fail using the eye position, we're probably hitting a roof so use abs origin instead
		GetCollisionPoint(client, VecOrigin, false);
	}
	
	//Teleport
	for (new i=0; i < target_count; i++)
	{
		TeleportEntity(teleport_list[i], VecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
		
	return Plugin_Handled;
}

// Traces forward from a client's eye or foot position until the ray hits MASK_SHOT
// Then checks for the possibility to get stuck.  If teleportee would get stuck,
// walk the ray backwards little by little until they won't get stuck anymore
// If we get too close to the client's position, or we take 100 steps, fail with client pos
stock bool:GetCollisionPoint(client, Float:pos[3], bool:eyes=true)
{
	decl Float:vOrigin[3], Float:vAngles[3], Float:vBackwards[3];
	new bool:failed = false;
	new loopLimit = 100;	// only check 100 times, as a precaution against runaway loops

	if (eyes)
	{
		GetClientEyePosition(client, vOrigin);
	}
	else
	{
		// if eyes is false, fall back to the AbsOrigin ( = feet)
		GetClientAbsOrigin(client, vOrigin);
	}
	
	GetClientEyeAngles(client, vAngles);
	GetAngleVectors(vAngles, vBackwards, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vBackwards, vBackwards);
	ScaleVector(vBackwards, 10.0);	// TODO: percentage of distance from endpoint to eyes instead of fixed distance?
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		
	if (TR_DidHit(trace))
	{	
		TR_GetEndPosition(pos, trace);
		//PrintToChat(client, "endpos %f %f %f", pos[0], pos[1], pos[2]);
		
		while (IsPlayerStuck(pos, client) && !failed)	// iteratively check if they would become stuck
		{
			SubtractVectors(pos, vBackwards, pos);		// if they would, subtract backwards from the position
			//PrintToChat(client, "endpos %f %f %f", pos[0], pos[1], pos[2]);
			if (GetVectorDistance(pos, vOrigin) < 10 || loopLimit-- < 1)
			{
				
				failed = true;	// If we get all the way back to the origin without colliding, we have failed
				//PrintToChat(client, "failed to find endpos");
				pos = vOrigin;	// Use the client position as a fallback
			}
		}
	}
	
	CloseHandle(trace);
	return !failed;		// If we have not failed, return true to let the caller know pos has teleport coordinates
}

// Checks to see if a player would collide with MASK_SOLID (i.e. they would be stuck)
// Inflates player mins/maxs a little bit for better protection against sticking
// Thanks to andersso for the basis of this function
stock bool:IsPlayerStuck(Float:pos[3], client)
{
	new Float:mins[3];
	new Float:maxs[3];

	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	
	// inflate the sizes just a little bit
	for (new i=0; i<sizeof(mins); i++)
	{
		mins[i] -= BOUNDINGBOX_INFLATION_OFFSET;
		maxs[i] += BOUNDINGBOX_INFLATION_OFFSET;
	}

	TR_TraceHullFilter(pos, pos, mins, maxs, MASK_SOLID, TraceEntityFilterPlayer, client);

	return TR_DidHit();
}  

// filter out players, since we can't get stuck on them
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity <= 0 || entity > MaxClients;
} 
