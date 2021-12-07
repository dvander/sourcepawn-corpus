#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0"

new Handle:g_Database;
new Handle:g_DisplayLength;
new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "Map Feedback",
	author = "Geit",
	description = "Allows players to give feedback on maps",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}
public OnPluginStart()
{
	CreateConVar("sm_annotate_version", PL_VERSION, "Annotation Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_annotate_perm", Command_Annotate, ADMFLAG_KICK);
	g_DisplayLength = CreateConVar("sm_annotate_length", "60.0", "Sets the amount of time that permanent annotations appear after round start");
	
	HookEvent("teamplay_round_start", Event_RestartRound);
	
	Database_Init();
}
//EVENTS
public Action:Event_RestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(DatabaseIntact() && !IsDedicatedServer())
	{
		decl String:query[392], String:map[64], String:mapbuffer[256];
		GetCurrentMap(map, sizeof(map));
		
		SQL_EscapeString(g_Database, map, mapbuffer, sizeof(mapbuffer));
		
		Format(query, sizeof(query), "SELECT `position_x`, `position_y`, `position_z`, `text`, `creator` FROM `annotations` WHERE `file`='%s' AND `deleted`=0", mapbuffer);
		SQL_TQuery(g_Database, CB_FetchAnnotations, query);
	}
	return Plugin_Continue;
}

//COMMANDS
public Action:Command_Annotate(client, args)
{
	if (GetCmdArgs() < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_annotate <Feedback>");
		return Plugin_Handled;
	}
	
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	
	decl String:message[256], String:author[64];
	
	GetCmdArgString(message, sizeof(message));
	GetClientName(client, author, sizeof(author));
	SpawnAnnotation(g_pos, message, author);
	SubmitAnnoation(g_pos, client, message);
	PrintToChat(client, "[SM] Annotation successful!");
	return Plugin_Handled;
}


//FUNCTIONS

SpawnAnnotation(Float:position[3], String:message[], String:author[])
{
	decl String:message2[256];
	
	Format(message2, sizeof(message2), "%s - %s", message, author);
	
	new Handle:event = CreateEvent("show_annotation");
	if (event != INVALID_HANDLE)
	{
		position[2] -= 10.0;
		SetEventFloat(event, "worldPosX", position[0]);
		SetEventFloat(event, "worldPosY", position[1]);
		SetEventFloat(event, "worldPosZ", position[2]);
		SetEventFloat(event, "lifetime", GetConVarFloat(g_DisplayLength));
		SetEventInt(event, "id", 0);
		SetEventString(event, "text", message);
		SetEventInt(event, "visibilityBitfield", 16777215);
		FireEvent(event);
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

//SQL FUNCTIONS
SubmitAnnoation(Float:position[3], client, String:message[])
{
	if(DatabaseIntact())
	{
		decl String:query[2048], String:name[32], String:namebuffer[96], String:messagebuffer[1024], String:authstring[32], String:map[64], String:mapbuffer[256];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, authstring, sizeof(authstring));
		GetCurrentMap(map, sizeof(map));
		
		SQL_EscapeString(g_Database, name, namebuffer, sizeof(namebuffer));
		SQL_EscapeString(g_Database, message, messagebuffer, sizeof(messagebuffer));
		SQL_EscapeString(g_Database, map, mapbuffer, sizeof(mapbuffer));
		
		Format(query, sizeof(query), "INSERT INTO `annotations` (`creator`, `creator_steam_id`, `text`, `position_x`, `position_y`, `position_z`, `file`) VALUES ('%s', '%s', '%s', %.0f, %.0f, %.0f, '%s')", namebuffer, authstring, messagebuffer, position[0], position[1], position[2], mapbuffer);
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
	if(result != INVALID_HANDLE && SQL_HasResultSet(result) && SQL_GetRowCount(result) >= 1)
	{
		while(SQL_FetchRow(result))
		{	
			decl Float:position[3], String:message[256], String:author[64];
			position[0] = float(SQL_FetchInt(result, 0));
			position[1] = float(SQL_FetchInt(result, 1));
			position[2] = float(SQL_FetchInt(result, 2));
			SQL_FetchString(result, 3, message, sizeof(message));
			SQL_FetchString(result, 4, author, sizeof(author));
			SpawnAnnotation(position, message, author);
		}
	}
}

//STOCK FUNCTIONS

stock Database_Init()
{
	
	decl String:error[255];	
	g_Database = SQL_Connect("annotations", true, error, sizeof(error));
	
	if(g_Database != INVALID_HANDLE)
	{
		SQL_FastQuery(g_Database, "SET NAMES 'UTF8'");
		SQL_FastQuery(g_Database, "CREATE TABLE IF NOT EXISTS `annotations` ( `id` INT(16) UNSIGNED NOT NULL AUTO_INCREMENT, `creator` VARCHAR(64) NULL DEFAULT NULL, `creator_steam_id` VARCHAR(25) NULL DEFAULT NULL, `text` VARCHAR(256) NULL DEFAULT NULL, `file` VARCHAR(64) NULL DEFAULT NULL, `time` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, `deleted` INT(1) NULL DEFAULT '0', `position_x` INT(5) NULL DEFAULT NULL, `position_y` INT(5) NULL DEFAULT NULL, `position_z` INT(5) NULL DEFAULT NULL, PRIMARY KEY (`id`), INDEX `creator_community_id` (`creator_steam_id`)) ENGINE=MyISAM ROW_FORMAT=DEFAULT AUTO_INCREMENT=34;");
		return;
	} 
	else 
	{
		PrintToServer("Connection Failed for annotations: %s", error);
		return;
	}
}