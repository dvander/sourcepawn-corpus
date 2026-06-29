#include <sourcemod>
#include <sdktools>

#define VERSION "0.2"

new Float:g_pos[3];
//new Float:g_normal[3];

new g_iBirds[1500];
new g_iCurrent;

public Plugin:myinfo = 
{
	name = "[TF2] BIRD BIRD BIRD BIRD",
	author = "FlaminSarge (thanks to linux_lover for pumpkins!)",
	description = "Spawns birds to where you're looking.",
	version = VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_bird_version", VERSION, "Bird Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_bird", Command_Bird, ADMFLAG_SLAY);
	RegAdminCmd("sm_ibird", Command_IBird, ADMFLAG_SLAY);
	RegAdminCmd("sm_toggle", Command_Toggle, ADMFLAG_SLAY);
	
	HookEvent("teamplay_round_start", Event_RestartRound);
}

public Action:Command_Bird(client, args)
{
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] That's a terrible idea, go in-game and spawn one.");
		return Plugin_Handled;
	}

	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}

	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore birds. Change maps.");
		return Plugin_Handled;
	}

	new iBird = CreateEntityByName("entity_bird");

	if (IsValidEntity(iBird))
	{		
		DispatchSpawn(iBird);
		g_pos[2] -= 10.0;
		decl Float:eyeangle[3];
		GetClientEyeAngles(client, eyeangle);
		eyeangle[0] = 0.0;	//g_normal[0];
		if (eyeangle[1] <= 0) eyeangle[1] = 180 + eyeangle[1];
		else eyeangle[1] = -180 + eyeangle[1];
//		eyeangle[1] *= -1;
		eyeangle[2] = 0.0;	//g_normal[2];
		TeleportEntity(iBird, g_pos, eyeangle, NULL_VECTOR);
	}

	return Plugin_Handled;
}

public Action:Command_IBird(client, args)
{
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] That's a terrible idea, go in-game and spawn one.");
		return Plugin_Handled;
	}
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities()-32 || g_iCurrent >= sizeof(g_iBirds))
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore birds. Change maps.");
		return Plugin_Handled;
	}
	
	new iBird = CreateEntityByName("entity_bird");
	
	if(IsValidEntity(iBird))
	{		
		DispatchSpawn(iBird);
		g_pos[2] -= 10.0;
		decl Float:eyeangle[3];
		GetClientAbsAngles(client, eyeangle);
		eyeangle[0] = 0.0;
//		eyeangle[1] *= -1;
		eyeangle[2] = 0.0;
		TeleportEntity(iBird, g_pos, eyeangle, NULL_VECTOR);
		SetEntProp(iBird, Prop_Data, "m_takedamage", 0, 1);
		
		g_iBirds[g_iCurrent++] = iBird;
	}
	
	return Plugin_Handled;
}

public Action:Command_Toggle(client, args)
{
	new String:strClassname[50];
	
	for(new i=0; i<g_iCurrent; i++)
	{
		GetEdictClassname(g_iBirds[i], strClassname, sizeof(strClassname));
		if(IsValidEntity(g_iBirds[i]))
		{
			GetEdictClassname(g_iBirds[i], strClassname, sizeof(strClassname));
			if(strcmp(strClassname, "entity_bird") == 0)
			{
				SetEntProp(g_iBirds[i], Prop_Data, "m_takedamage", 2, 1);
			}
		}
		
		g_iBirds[i] = 0;
	}
	
	g_iCurrent = 0;
	
	return Plugin_Handled;
}

public Action:Event_RestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0; i<sizeof(g_iBirds); i++)
	{
		g_iBirds[i] = 0;
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
//		decl Float:fNormal[3];
//		TR_GetPlaneNormal(trace, g_normal);
//		GetVectorAngles(g_normal, g_normal);
		
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}