#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.5"

#define MAX_ANNOTATION_COUNT 50
#define MAX_ANNOTATION_LENGTH 256
#define ANNOTATION_REFRESH_RATE 0.1
#define ANNOTATION_OFFSET 8750

new String:g_AnnotationText[MAX_ANNOTATION_COUNT][MAX_ANNOTATION_LENGTH];
new Float:g_AnnotationPosition[MAX_ANNOTATION_COUNT][3];
new bool:g_AnnotationCanBeSeenByClient[MAX_ANNOTATION_COUNT][MAXPLAYERS+1];
new bool:g_AnnotationEnabled[MAX_ANNOTATION_COUNT];

new Float:g_pos[3];
new g_MinimumDistanceApart;
new g_ViewDistance;


new Handle:g_hCVarMinDist;
new Handle:g_hCVarViewDist;

public Plugin:myinfo = 
{
	name = "[TF2] Annotate",
	author = "Geit",
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
	
	g_hCVarMinDist = CreateConVar("sm_annotate_min_dist", "64", "Sets the minimum distance that an annotation must be from another annotation", _, true, 16.0, true, 128.0);
	g_hCVarViewDist = CreateConVar("sm_annotate_view_dist", "1024", "Sets the maximum distance at which annotations will be sent to players", _, true, 50.0);
	
	g_MinimumDistanceApart = RoundFloat(Pow(GetConVarFloat(g_hCVarMinDist), 2.0));
	g_ViewDistance = RoundFloat(Pow(GetConVarFloat(g_hCVarViewDist), 2.0));
	
	HookConVarChange(g_hCVarMinDist, CB_MinDistChanged);
	HookConVarChange(g_hCVarViewDist, CB_ViewDistChanged);
}

public OnMapStart()
{
	CreateTimer( ANNOTATION_REFRESH_RATE, Timer_RefreshAnnotations, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(g_AnnotationEnabled[i]) 
			Timer_ExpireAnnotation(INVALID_HANDLE, i);
	}
}

public OnPluginEnd()
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(g_AnnotationEnabled[i]) 
			Timer_ExpireAnnotation(INVALID_HANDLE, i);
	}
}

public CB_MinDistChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	g_MinimumDistanceApart = RoundFloat(Pow(StringToFloat(newVal), 2.0));
}

public CB_ViewDistChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	g_ViewDistance = RoundFloat(Pow(StringToFloat(newVal), 2.0));
}

// Commands
public Action:Command_Annotate(client, args)
{
	if (GetCmdArgs() < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_annotate <time> <message>");
		return Plugin_Handled;
	}
	
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
	
	new annotation_id = GetFreeAnnotationID();
	if(annotation_id == -1)
	{
		PrintToChat(client, "[SM] No free annotations!");
		return Plugin_Handled;
	}
	
	decl String:strTime[4], String:ArgString[MAX_ANNOTATION_LENGTH];
	
	GetCmdArg(1, strTime, sizeof(strTime));
	new Float:time = StringToFloat(strTime);
	
	GetCmdArgString(ArgString, sizeof(ArgString));
	new pos = FindCharInString(ArgString, ' ');
	
	strcopy(g_AnnotationText[annotation_id], sizeof(g_AnnotationText[]), ArgString[pos+1]);
	g_AnnotationEnabled[annotation_id] = true;
	g_AnnotationPosition[annotation_id] = g_pos;
	
	if(time > 0.0)
		CreateTimer(time, Timer_ExpireAnnotation, annotation_id, TIMER_FLAG_NO_MAPCHANGE);
	
	PrintToChat(client, "[SM] Annotation created.");
	return Plugin_Handled;
}

public Action:Command_DeleteAnnotation(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find end point.");
		return Plugin_Handled;
	}
	
	for(new i; i < MAX_ANNOTATION_COUNT; i++)
	{
		if (g_AnnotationEnabled[i] && GetVectorDistance(g_pos, g_AnnotationPosition[i], true) < 4096)
		{
			PrintToChat(client, "[SM] Annotation Deleted");
			Timer_ExpireAnnotation(INVALID_HANDLE, i);
			return Plugin_Handled;
		}
	}
	PrintToChat(client, "[SM] No annotations found near where you are looking!");
	return Plugin_Handled;
}

//FUNCTIONS
bool:NearExistingAnnotation(Float:position[3])
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(!g_AnnotationEnabled[i]) continue;
		
		if (GetVectorDistance(position, g_AnnotationPosition[i], true) < g_MinimumDistanceApart)
			return true;
	}
	return false;
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

public bool:CanPlayerSee(client, annotation_id)
{
	decl Float:EyePos[3];
	GetClientEyePosition(client, EyePos); 
	
	if(GetVectorDistance(EyePos, g_AnnotationPosition[annotation_id], true) > g_ViewDistance) return false;

	TR_TraceRayFilter(EyePos, g_AnnotationPosition[annotation_id], MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE))
	{
		return false;
	}
	return true;
}

public ShowAnnotationToPlayer(client, annotation_id)
{
	new Handle:event = CreateEvent("show_annotation");
	if (event == INVALID_HANDLE) return;
	
	SetEventFloat(event, "worldPosX", g_AnnotationPosition[annotation_id][0]);
	SetEventFloat(event, "worldPosY", g_AnnotationPosition[annotation_id][1]);
	SetEventFloat(event, "worldPosZ", g_AnnotationPosition[annotation_id][2]);
	SetEventFloat(event, "lifetime", 99999.0);
	SetEventInt(event, "id", annotation_id*MAXPLAYERS + client + ANNOTATION_OFFSET);
	SetEventString(event, "text", g_AnnotationText[annotation_id]);
	SetEventString(event, "play_sound", "vo/null.wav");
	SetEventInt(event, "visibilityBitfield", (1 << client));
	FireEvent(event);
	
}

public GetFreeAnnotationID()
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(g_AnnotationEnabled[i]) continue;
		return i;
	}
	return -1;
}

public HideAnnotationFromPlayer(client, annotation_id)
{
	new Handle:event = CreateEvent("hide_annotation");
	if (event == INVALID_HANDLE) return;
	
	SetEventInt(event, "id", annotation_id*MAXPLAYERS + client + ANNOTATION_OFFSET);
	FireEvent(event);
}

//TIMERS
public Action:Timer_RefreshAnnotations(Handle:timer, any:entity)
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(!g_AnnotationEnabled[i]) continue;
		for(new client = 1; client < MaxClients; client++)
		{
			if(IsClientInGame(client) && !IsFakeClient(client))
			{		
				new bool:canClientSeeAnnotation = CanPlayerSee(client, i);
				if(!canClientSeeAnnotation && g_AnnotationCanBeSeenByClient[i][client])
				{
					// The player can no longer see the annotation
					HideAnnotationFromPlayer(client, i);
					g_AnnotationCanBeSeenByClient[i][client] = false;
				}
				else if (canClientSeeAnnotation && !g_AnnotationCanBeSeenByClient[i][client])
				{
					ShowAnnotationToPlayer(client, i);
					g_AnnotationCanBeSeenByClient[i][client] = true;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_ExpireAnnotation(Handle:timer, any:annotation_id)
{
	g_AnnotationEnabled[annotation_id] = false;
	
	for(new client = 1; client < MaxClients; client++)
	{
		if(g_AnnotationCanBeSeenByClient[annotation_id][client])
		{
			HideAnnotationFromPlayer(client, annotation_id);
			g_AnnotationCanBeSeenByClient[annotation_id][client] = false;
		}
	}	
	return Plugin_Handled;
}

