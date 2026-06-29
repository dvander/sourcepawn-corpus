#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6"
#define L4D_TEAM_UNASSIGNED 0
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3


public Plugin:myinfo =
{
	name = "L4D SM Respawn",
	author = "AtomicStryker, equip code by BertieB",
	description = "Lets you respawn [equipped] players at cursor",
	version = "1.6",
	url = "http://forums.alliedmods.net/showthread.php?t=96249"
}

new Float:g_pos[3];
new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;


public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("l4d_sm_respawn_version", PLUGIN_VERSION, "L4D SM Respawn Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_BAN, "sm_respawn <player1> [item1] ... [itemN] - respawn all listed players, equip them with specified weapons / items, then teleport them where you aim");
	
	hGameConf = LoadGameConfigFile("l4dsmrespawn");

	if (hGameConf == INVALID_HANDLE)
	{
		SetFailState("[SM] sm_respawn could not load l4dsmrespawn, please check you have the file l4dsmrespawn.txt in your gamdata directory.");
	}

	StartPrepSDKCall(SDKCall_Player);
	
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RoundRespawn"); // set linux offset from gamedata file
	hRoundRespawn = EndPrepSDKCall();
	
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <player> [item1] ... [itemN] - respawn selected player with [item]s. Valid [item]s are those that can be used with the 'give' command, eg autoshotgun, pain_pills");
		return Plugin_Handled;
	}
	
	new player_id;
	
	new String:player[64];
	
	GetCmdArg(1, player, sizeof(player));
	player_id = FindTarget(client, player);

	if(GetClientTeam(player_id) == L4D_TEAM_SURVIVOR)
	{
	
		SDKCall(hRoundRespawn, player_id);
			
		if( !SetTeleportEndPoint(client))
		{
			return Plugin_Handled;
		}
		PerformTeleport(client,player_id,g_pos);
	}

	new String:item[14];
		
	for(new i = 1; i < args; i++)
	{
		
		GetCmdArg(i+1, item, sizeof(item));
		GiveItem(client, player_id, item);
	
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
	
	LogAction(client,target, "\"%L\" teleported \"%L\" after respawning them" , client, target);
}

GiveItem(client, target, String:item[14])
{
	
	new Handle:hItemList = INVALID_HANDLE;
	
	hItemList = CreateArray(13,0);

	// item list to check against, pointless ones like health, ammo removed
	
	PushArrayString(hItemList, "autoshotgun");
	PushArrayString(hItemList, "rifle");
	PushArrayString(hItemList, "hunting_rifle");
	PushArrayString(hItemList, "first_aid_kit");
	PushArrayString(hItemList, "pain_pills");
	PushArrayString(hItemList, "pipe_bomb");
	PushArrayString(hItemList, "molotov");
	PushArrayString(hItemList, "smg");
	PushArrayString(hItemList, "pumpshotgun");
	PushArrayString(hItemList, "oxygentank");
	PushArrayString(hItemList, "propanetank");
	PushArrayString(hItemList, "gascan");
	
	for (new i = 0; i < GetArraySize(hItemList); i++) 
	{
		new String:check[14];
		GetArrayString(hItemList, i, check, sizeof(check));
		if ( strcmp(check, item, false) == 0 )
		{

			new flags = GetCommandFlags("give");
			SetCommandFlags("give", flags & ~FCVAR_CHEAT);
			new String:give[19] = "give "; 
			StrCat(give, 19, item); 
			FakeClientCommand(target, give);
			SetCommandFlags("give", flags|FCVAR_CHEAT);
			return true;

		}
	}

	PrintToChat(client, "[SM] %s", "Invalid item. Valid items are those that can be used with the give commend, eg autoshotgun, pain_pills, etc");
	return false;

}	

