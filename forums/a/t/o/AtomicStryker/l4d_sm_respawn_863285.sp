#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define L4D_TEAM_UNASSIGNED 0
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3

public Plugin:myinfo =
{
	name = "L4D SM Respawn",
	author = "AtomicStryker",
	description = "Let's you respawn Players by console",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=96249"
}

new Handle:hCheats = INVALID_HANDLE;
new Float:g_pos[3];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("l4d_sm_respawn_version", "1.0", "L4D SM Respawn Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_BAN, "sm_respawn <player1> [player2] ... [playerN] - respawn all listed players");
	
	hCheats = FindConVar("sv_cheats");
	SetConVarFlags(hCheats, (GetConVarFlags(hCheats) & ~FCVAR_NOTIFY));
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <player1> [player2] ... [playerN] - respawn all listed players");
		return Plugin_Handled;
	}
	
	new player_id;

	new String:player[64];
	
	for(new i = 0; i < args; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		player_id = FindTarget(client, player);
		
		if(GetClientTeam(player_id) == L4D_TEAM_SURVIVOR) {

			SetConVarInt(hCheats, 1);
			FakeClientCommand(player_id,"respawn");
			SetConVarInt(hCheats, 0);
			
				if( !SetTeleportEndPoint(client))
				{
					return Plugin_Handled;
				}
				PerformTeleport(client,player_id,g_pos);
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
		PrintToChat(client, "[SM] %s", "Could not teleport player");
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

PerformTeleport(client, target, Float:pos[3])
{
	decl Float:partpos[3];
	
	GetClientEyePosition(target, partpos);
	partpos[2]-=20.0;	
	
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
	pos[2]+=40.0;
	
	LogAction(client,target, "\"%L\" teleported \"%L\" after respawn" , client, target);

}