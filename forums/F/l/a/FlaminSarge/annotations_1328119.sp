#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.31"

new Float:g_pos[3];
new g_AnnotationCount;
new g_AnnotationCurrent=5;
new String:g_AnnotationText[2048][256];
new bool:g_AnnotationEnabled[2048] = false;
new Float:g_AnnotationPosition[2048][3];


public Plugin:myinfo = 
{
	name = "[TF2] Annotate",
	author = "Geit (modified by FlaminSarge)",
	description = "Spawn annotations where you're looking.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_annotate_version", PL_VERSION, "Annotate Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_annotate", Command_Annotate, ADMFLAG_CHAT);
	RegAdminCmd("sm_deleteannotation", Command_DeleteAnnotation, ADMFLAG_CHAT);
	CreateConVar("sm_annotate_distance", "64", "Distance Between Annotations", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_annotate_delimiter", ",, ", "Delimiter for Separating Time From Message", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public OnMapStart()
{
	CreateTimer(0.8, Timer_RespawnAnnotations, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	g_AnnotationCount=0;
	g_AnnotationCurrent=5;
}

// FUNCTIONS

public Action:Command_Annotate(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(NearExistingAnnotation(g_pos))
	{
		PrintToChat(client, "[SM] There is already an annotation here!");
		return Plugin_Handled;
	}
	
	decl String:args1[256];
	decl String:annotations[2][256];
	decl String:delimiter1[16];
	new Float:timefloat;
	GetConVarString(FindConVar("sm_annotate_delimiter"), delimiter1, sizeof(delimiter1));
	GetCmdArgString(args1, sizeof(args1));
	ExplodeString(args1, delimiter1, annotations, 2, 256);
	timefloat = StringToFloat(annotations[0]);
	CreateTimer(timefloat, Timer_DisableAnnotation, g_AnnotationCount);
	
	g_AnnotationEnabled[g_AnnotationCount] = true;
	strcopy(g_AnnotationText[g_AnnotationCount], 256, annotations[1]);
	g_AnnotationPosition[g_AnnotationCount] = g_pos;
	SpawnAnnotation(g_AnnotationCount);
	g_AnnotationCount++;
	return Plugin_Handled;
}

public Action:Command_DeleteAnnotation(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find end point.");
		return Plugin_Handled;
	}
	
	for(new i; i < g_AnnotationCount; i++)
	{
		if (GetVectorDistance(g_pos, g_AnnotationPosition[i]) < 64)
		{
			g_AnnotationEnabled[i] = false;
			PrintToChat(client, "[SM] Annotation Deleted");
			return Plugin_Handled;
		}
	}
	PrintToChat(client, "[SM] No annotations found near where you are looking!");
	return Plugin_Handled;
}

//FUNCTIONS

NearExistingAnnotation(Float:position[3])
{
	for(new i; i < g_AnnotationCount; i++)
	{
		if (GetVectorDistance(position, g_AnnotationPosition[i]) < GetConVarInt(FindConVar("sm_annotate_distance")))
		{
			return true;
		}
	}
	return false;
}

public SpawnAnnotation(id)
{	
	new Handle:event = CreateEvent("show_annotation");
	if (event != INVALID_HANDLE)
	{
		new bitstring = BuildBitString(g_AnnotationPosition[id]);
		if (bitstring > 1)
		{
			SetEventFloat(event, "worldPosX", g_AnnotationPosition[id][0]);
			SetEventFloat(event, "worldPosY", g_AnnotationPosition[id][1]);
			SetEventFloat(event, "worldPosZ", g_AnnotationPosition[id][2]);
			SetEventFloat(event, "lifetime", 10.0);
			SetEventInt(event, "id", id);
			SetEventString(event, "text", g_AnnotationText[id]);
			SetEventInt(event, "visibilityBitfield", bitstring);
			FireEvent(event);
		}
	}
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

public CanPlayerSee(client, Float:position[3])
{
	decl Float:EyePos[3];
	GetClientEyePosition(client, EyePos); 

	TR_TraceRayFilter(EyePos, position, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE))
	{
		return false;
	}
	return true;
}

public BuildBitString(Float:position[3])
{
	new bitstring=1;
	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			new Float:EyePos[3];
			GetClientEyePosition(client, EyePos);
			if (GetVectorDistance(position, EyePos) < 1024)
			{
				if(CanPlayerSee(client, position))
				{
					bitstring |= RoundFloat(Pow(2.0, float(client)));
				}
			}
		}
	}
	return bitstring;
}

//TIMERS

public Action:Timer_DisableAnnotation(Handle:timer, any:annotation)
{
	g_AnnotationEnabled[annotation]=false;
	return Plugin_Continue;
}
public Action:Timer_RespawnAnnotations(Handle:timer, any:entity)
{
	if ( g_AnnotationCount > 0)
	{
		for(new i=g_AnnotationCurrent-5; i < g_AnnotationCurrent; i++)
		{
			if (g_AnnotationEnabled[i] == true)
			{
				SpawnAnnotation(i);
			}
		}
	}
	if (g_AnnotationCurrent > g_AnnotationCount)
	{
		g_AnnotationCurrent=5;
	}
	g_AnnotationCurrent+=5;
	return Plugin_Continue;
}