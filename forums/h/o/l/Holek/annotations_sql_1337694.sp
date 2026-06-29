#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.4"

new Handle:g_Database;
new Handle:g_DisplayLength;
new Float:g_pos[3];
new g_AnnotationCount;
new g_AnnotationCurrent=5;
new String:g_AnnotationText[2048][256];
new bool:g_AnnotationEnabled[2048] = false;
new Float:g_AnnotationPosition[2048][3];

new Handle:g_MinDist;
new Handle:g_ViewDist;

public Plugin:myinfo = 
{
	name = "Annotations SQL",
	author = "Geit",
	description = "Allows permanent annotations to be made - Requires MYSQL",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_annotate_version", PL_VERSION, "Annotation Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_annotate_perm", Command_Annotate, ADMFLAG_KICK);
	RegAdminCmd("sm_deleteannotation_perm", Command_DeleteAnnotation, ADMFLAG_KICK);
	g_DisplayLength = CreateConVar("sm_annotate_length", "30.0", "Sets the amount of time that permanent annotations appear after round start");
	g_MinDist = CreateConVar("sm_annotate_min_dist", "64", "Sets the minimum distance that an annotation must be from another annotation");
	g_ViewDist = CreateConVar("sm_annotate_view_dist", "1024", "Sets the maximum distance at which annotations will be sent to players");
	
	HookEvent("teamplay_round_start", Event_RestartRound);
	
	Database_Init();
}

public OnMapStart()
{
	CreateTimer(0.8, Timer_RespawnAnnotations, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	g_AnnotationCount=0;
	g_AnnotationCurrent=5;
}

//EVENTS
public Action:Event_RestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(DatabaseIntact())
	{
		decl String:query[392], String:map[64], String:mapbuffer[256];
		GetCurrentMap(map, sizeof(map));
		g_AnnotationCount=0;
		g_AnnotationCurrent=5;
		SQL_EscapeString(g_Database, map, mapbuffer, sizeof(mapbuffer));
		
		Format(query, sizeof(query), "SELECT `position_x`, `position_y`, `position_z`, `text` FROM `annotations` WHERE `file`='%s' AND `deleted`=0", mapbuffer);
		SQL_TQuery(g_Database, CB_FetchAnnotations, query);
	}
	return Plugin_Continue;	
}

//COMMANDS
public Action:Command_Annotate(client, args)
{
	if (GetCmdArgs() < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_annotate <Message>");
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
	
	decl String:message[256];
	GetCmdArgString( message, sizeof(message));
	CreateTimer(GetConVarFloat(g_DisplayLength), Timer_DisableAnnotation, g_AnnotationCount);
	
	g_AnnotationEnabled[g_AnnotationCount] = true;
	strcopy(g_AnnotationText[g_AnnotationCount], 256, message);
	g_AnnotationPosition[g_AnnotationCount] = g_pos;
	SpawnAnnotation(g_AnnotationCount);
	SubmitAnnoation(client, g_AnnotationCount);
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
			decl String:messagebuffer[1024], String:query[2048];
			
			SQL_EscapeString(g_Database, g_AnnotationText[i], messagebuffer, sizeof(messagebuffer));
			
			Format(query, sizeof(query), "UPDATE `annotations` SET `deleted`=1 WHERE `text`='%s'", messagebuffer);
			SQL_TQuery(g_Database, CB_ErrorOnly, query);
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
		if (GetVectorDistance(position, g_AnnotationPosition[i]) < GetConVarInt(g_MinDist))
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
			SetEventFloat(event, "lifetime", 5.0);
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
			if (GetVectorDistance(position, EyePos) < GetConVarInt(g_ViewDist))
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

//SQL FUNCTIONS
SubmitAnnoation(client, id)
{
	if(DatabaseIntact())
	{
		decl String:query[2048], String:name[32], String:namebuffer[96], String:messagebuffer[1024], String:authstring[32], String:map[64], String:mapbuffer[256];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, authstring, sizeof(authstring));
		GetCurrentMap(map, sizeof(map));
		
		SQL_EscapeString(g_Database, name, namebuffer, sizeof(namebuffer));
		SQL_EscapeString(g_Database, g_AnnotationText[id], messagebuffer, sizeof(messagebuffer));
		SQL_EscapeString(g_Database, map, mapbuffer, sizeof(mapbuffer));
		
		Format(query, sizeof(query), "INSERT INTO `annotations` (`creator`, `creator_steam_id`, `text`, `position_x`, `position_y`, `position_z`, `file`) VALUES ('%s', '%s', '%s', %.0f, %.0f, %.0f, '%s')", namebuffer, authstring, messagebuffer, g_AnnotationPosition[id][0], g_AnnotationPosition[id][1], g_AnnotationPosition[id][2], mapbuffer);
		SQL_TQuery(g_Database, CB_ErrorOnly, query);
	}
}

public DatabaseIntact()
{
	if(g_Database != INVALID_HANDLE)
	return true;
	else 
	{
		Database_Init();
		return false;
	}
}

//SQL THREADED CALLBACKS

public CB_ErrorOnly(Handle:owner, Handle:result, const String:error[], any:client)
{
	if(result == INVALID_HANDLE)
	{
		LogError("[SM] MYSQL ERROR (Map Feedback - error: %s)", error);
		PrintToChatAll("MYSQL ERROR (Map Feedback - error: %s)", error);
	}
}

public CB_FetchAnnotations(Handle:owner, Handle:result, const String:error[], any:client) 
{
	if(result == INVALID_HANDLE)
	{
		LogError("[SM] MYSQL ERROR (Map Feedback - error: %s)", error);
		PrintToChatAll("MYSQL ERROR (Map Feedback - error: %s)", error);
	}
	
	if(result != INVALID_HANDLE && SQL_HasResultSet(result) && SQL_GetRowCount(result) >= 1)
	{
		while(SQL_FetchRow(result))
		{	
			g_AnnotationPosition[g_AnnotationCount][0] = float(SQL_FetchInt(result, 0));
			g_AnnotationPosition[g_AnnotationCount][1] = float(SQL_FetchInt(result, 1));
			g_AnnotationPosition[g_AnnotationCount][2] = float(SQL_FetchInt(result, 2));
			SQL_FetchString(result, 3, g_AnnotationText[g_AnnotationCount], 256);
			CreateTimer(GetConVarFloat(g_DisplayLength), Timer_DisableAnnotation, g_AnnotationCount);
			g_AnnotationEnabled[g_AnnotationCount] = true;
			SpawnAnnotation(g_AnnotationCount);
			g_AnnotationCount++;
		}
	}
}

//STOCK FUNCTIONS

stock Database_Init()
{
	
	decl String:error[255];	
	g_Database = SQL_Connect("annotations", true, error, sizeof(error));
	if(g_Database == INVALID_HANDLE)
	{
		g_Database = SQL_Connect("default", true, error, sizeof(error));
	}
	
	if(g_Database != INVALID_HANDLE)
	{
		SQL_FastQuery(g_Database, "SET NAMES 'UTF8'");
		SQL_FastQuery(g_Database, "CREATE TABLE IF NOT EXISTS `annotations` ( `id` INT(16) UNSIGNED NOT NULL AUTO_INCREMENT, `creator` VARCHAR(64) NULL DEFAULT NULL, `creator_steam_id` VARCHAR(25) NULL DEFAULT NULL, `text` VARCHAR(256) NULL DEFAULT NULL, `file` VARCHAR(64) NULL DEFAULT NULL, `time` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, `deleted` INT(1) NULL DEFAULT '0', `position_x` INT(5) NULL DEFAULT NULL, `position_y` INT(5) NULL DEFAULT NULL, `position_z` INT(5) NULL DEFAULT NULL, PRIMARY KEY (`id`), INDEX `creator_community_id` (`creator_steam_id`)) ENGINE=MyISAM;");
		return;
	} 
	else 
	{
		PrintToServer("Connection Failed for annotations: %s", error);
		return;
	}
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
		g_AnnotationCurrent=0;
	}
	g_AnnotationCurrent+=5;
	return Plugin_Continue;
}
