#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.7a"


public Plugin:myinfo =
{
	name = "L4D SM Respawn",
	author = "AtomicStryker & Ivailosp",
	description = "Let's you respawn Players by console",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96249"
}

new Float:g_pos[3];
new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:hBecomeGhost = INVALID_HANDLE;
new Handle:hState_Transition = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	hGameConf = LoadGameConfigFile("l4drespawn");
	
	CreateConVar("l4d_sm_respawn_version", PLUGIN_VERSION, "L4D SM Respawn Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_BAN, "sm_respawn <player1> [player2] ... [playerN] - respawn all listed players and teleport them where you aim");

	

	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hBecomeGhost = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hState_Transition = EndPrepSDKCall();

	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt");
	}
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <player1> [player2] ... [playerN] - respawn all listed players");
		return Plugin_Handled;
	}
	
	decl player_id;
	decl String:player[64];
	
	for(new i = 0; i < args; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		player_id = FindTarget(client, player);
		
		if(GetClientTeam(player_id) == 2)
		{
			
			SDKCall(hRoundRespawn, player_id);
			
			new flags = GetCommandFlags("give");
			SetCommandFlags("give", flags & ~FCVAR_CHEAT);
			FakeClientCommand(player_id, "give first_aid_kit");
			FakeClientCommand(player_id, "give smg");
			SetCommandFlags("give", flags);
			
			if( !SetTeleportEndPoint(client) || client == player_id)
			{
				return Plugin_Handled;
			}
			PerformTeleport(client,player_id,g_pos);
		}
		if(GetClientTeam(player_id) == 3)
		{
			SDKCall(hState_Transition, player_id, 8);
			SDKCall(hBecomeGhost, player_id, 1);
			SDKCall(hState_Transition, player_id, 6);
			SDKCall(hBecomeGhost, player_id, 1);
		}
		
		
	}
	return Plugin_Handled;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
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
		PrintToChat(client, "[SM] %s", "Could not teleport player after respawn");
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

PerformTeleport(client, target, Float:pos[3])
{
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
	pos[2]+=40.0;
	
	LogAction(client,target, "\"%L\" teleported \"%L\" after respawning him" , client, target);
}
	