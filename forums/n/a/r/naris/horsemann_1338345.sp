#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PL_VERSION "1.1"

#define ADMFLAG_HORSEMANN	ADMFLAG_CUSTOM3	

new Float:g_pos[3];

new Handle:hAdminMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[TF2] Horseless Headless Horsemann",
	author = "Geit",
	description = "Spawn Horseless Headless Horsemann where you're looking.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_horsemann_version", PL_VERSION, "Horsemann Spaner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_horsemann", Command_Spawn, ADMFLAG_HORSEMANN);

	if (LibraryExists("adminmenu"))
	{
		new Handle:topmenu = GetAdminTopMenu();
		if (topmenu != INVALID_HANDLE)
			OnAdminMenuReady(topmenu);
	}
}

// FUNCTIONS

public Action:Command_Spawn(client, args)
{
	
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Stop;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore horsemenn. Change maps.");
		return Plugin_Stop;
	}
	
	new entity = CreateEntityByName("headless_hatman");
	
	if(IsValidEntity(entity))
	{		
		DispatchSpawn(entity);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		return Plugin_Handled;
	}
	return Plugin_Stop;
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

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu != hAdminMenu)
	{
		hAdminMenu = topmenu;

		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		if (server_commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(hAdminMenu,
					"sm_horsemann",
					TopMenuObject_Item,
					AdminMenu_horsemann, 
					server_commands,
					"sm_horsemann",
					ADMFLAG_HORSEMANN);
		}
	}
}

public AdminMenu_horsemann( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Call forth the mighty Horsemann");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		Command_Spawn(param, 0);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Native
	CreateNative("SpawnHorsemann",Native_SpawnHorseMann);
	RegPluginLibrary("horsemann");
	return APLRes_Success;
}

public Native_SpawnHorseMann(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	return _:Command_Spawn(client, 0);
}
