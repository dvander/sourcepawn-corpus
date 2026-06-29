#include <sourcemod>
#include <sdktools>

#define VERSION "0.2"

new Float:g_pos[3];

new g_iPumpkins[1500];
new g_iCurrent;

public Plugin:myinfo = 
{
	name = "[TF2] Pumpkin",
	author = "linux_lover",
	description = "Spawns pumpkins to where your looking.",
	version = VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_pumpkin_version", VERSION, "Pumpkin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_pumpkin", Command_Pumpkin, ADMFLAG_SLAY);
	RegAdminCmd("sm_ipumpkin", Command_IPumpkin, ADMFLAG_SLAY);
	RegAdminCmd("sm_toggle", Command_Toggle, ADMFLAG_SLAY);
	
	HookEvent("teamplay_round_start", Event_RestartRound);
}

public Action:Command_Pumpkin(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return Plugin_Handled;
	}
	
	new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	
	if(IsValidEntity(iPumpkin))
	{		
		DispatchSpawn(iPumpkin);
		g_pos[2] -= 10.0;
		TeleportEntity(iPumpkin, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Handled;
}

public Action:Command_IPumpkin(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities()-32 || g_iCurrent >= sizeof(g_iPumpkins))
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return Plugin_Handled;
	}
	
	new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	
	if(IsValidEntity(iPumpkin))
	{		
		DispatchSpawn(iPumpkin);
		g_pos[2] -= 10.0;
		TeleportEntity(iPumpkin, g_pos, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(iPumpkin, Prop_Data, "m_takedamage", 0, 1);
		
		g_iPumpkins[g_iCurrent++] = iPumpkin;
	}
	
	return Plugin_Handled;
}

public Action:Command_Toggle(client, args)
{
	new String:strClassname[50];
	
	for(new i=0; i<g_iCurrent; i++)
	{
		GetEdictClassname(g_iPumpkins[i], strClassname, sizeof(strClassname));
		if(IsValidEntity(g_iPumpkins[i]))
		{
			GetEdictClassname(g_iPumpkins[i], strClassname, sizeof(strClassname));
			if(strcmp(strClassname, "tf_pumpkin_bomb") == 0)
			{
				SetEntProp(g_iPumpkins[i], Prop_Data, "m_takedamage", 2, 1);
			}
		}
		
		g_iPumpkins[i] = 0;
	}
	
	g_iCurrent = 0;
	
	return Plugin_Handled;
}

public Action:Event_RestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0; i<sizeof(g_iPumpkins); i++)
	{
		g_iPumpkins[i] = 0;
	}
	
	g_iCurrent = 0;
	
	return Plugin_Continue;
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