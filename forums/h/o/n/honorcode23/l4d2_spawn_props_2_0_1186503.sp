#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#pragma semicolon 2
#define DEBUG 0

#define GETVERSION "2.0.6"
#define ARRAY_SIZE 5000
#define MAX_PATHS 20

#define DESIRED_ADM_FLAGS ADMFLAG_UNBAN //Edit here the flags to fit your needs!

new Handle:hAdminMenu = INVALID_HANDLE;
new g_iCategory[MAXPLAYERS+1] = 0;
new g_iSubCategory[MAXPLAYERS+1] = 0;
new g_iFileCategory[MAXPLAYERS+1] = 0;
new g_iMoveCategory[MAXPLAYERS+1] = 0;
new Float:g_vecLastEntityAngles[MAXPLAYERS+1][3];
new g_iLastObject[MAXPLAYERS+1] = -1;
new g_iLastGrabbedObject[MAXPLAYERS+1] = -1;

new bool:g_bSpawned[ARRAY_SIZE] = false;
new bool:g_bGrabbed[ARRAY_SIZE] = false;
new bool:g_bGrab[MAXPLAYERS+1] = false;
new Float:g_vecEntityAngles[ARRAY_SIZE][3];
new bool:g_bUnsolid[ARRAY_SIZE] = false;
new bool:g_bLoaded = false;
new String:g_sPath[128];

new Handle:g_cvarPhysics = INVALID_HANDLE;
new Handle:g_cvarDynamic = INVALID_HANDLE;
new Handle:g_cvarStatic = INVALID_HANDLE;
new Handle:g_cvarVehicles = INVALID_HANDLE;
new Handle:g_cvarFoliage = INVALID_HANDLE;
new Handle:g_cvarInterior = INVALID_HANDLE;
new Handle:g_cvarExterior = INVALID_HANDLE;
new Handle:g_cvarDecorative = INVALID_HANDLE;
new Handle:g_cvarMisc = INVALID_HANDLE;
new Handle:g_cvarLog = INVALID_HANDLE;
new Handle:g_cvarAutoload = INVALID_HANDLE;
new Handle:g_cvarAutoloadType = INVALID_HANDLE;

//Dynamic Routing
enum RouteType
{
	RouteType_Easy = 0,
	RouteType_Medium = 1,
	RouteType_Hard = 2,
};

public Plugin:myinfo = 
{
	name = "[L4D2] Objects Spawner",
	author = "honorcode23",
	description = "Let admins spawn any kind of objects",
	version = GETVERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1186503"
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("[L4D2] Objects Spawner supports Left 4 dead 2 only!");
	}
	
	CreateConVar("l4d2_spawn_props_version", GETVERSION, "Version of the Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); //Version
	g_cvarPhysics = CreateConVar("l4d2_spawn_props_physics", "1", "Enable the Physics Objects in the menu", FCVAR_PLUGIN);
	g_cvarDynamic = CreateConVar("l4d2_spawn_props_dynamic", "1", "Enable the Dynamic (Non-solid) Objects in the menu", FCVAR_PLUGIN);
	g_cvarStatic = CreateConVar("l4d2_spawn_props_static", "1", "Enable the Static (Solid) Objects in the menu", FCVAR_PLUGIN);
	g_cvarVehicles = CreateConVar("l4d2_spawn_props_category_vehicles", "1", "Enable the Vehicles category", FCVAR_PLUGIN);
	g_cvarFoliage = CreateConVar("l4d2_spawn_props_category_foliage", "1", "Enable the Foliage category", FCVAR_PLUGIN);
	g_cvarInterior = CreateConVar("l4d2_spawn_props_category_interior", "1", "Enable the Interior category", FCVAR_PLUGIN);
	g_cvarExterior = CreateConVar("l4d2_spawn_props_category_exterior", "1", "Enable the Exterior category", FCVAR_PLUGIN);
	g_cvarDecorative = CreateConVar("l4d2_spawn_props_category_decorative", "1", "Enable the Decorative category", FCVAR_PLUGIN);
	g_cvarMisc = CreateConVar("l4d2_spawn_props_category_misc", "1", "Enable the Misc category", FCVAR_PLUGIN);
	g_cvarLog = CreateConVar("l4d2_spawn_props_log_actions", "1", "Log if an admin spawns an object?", FCVAR_PLUGIN);
	g_cvarAutoload = CreateConVar("l4d2_spawn_props_autoload", "0", "Enable the plugin to auto load the cache?", FCVAR_PLUGIN);
	g_cvarAutoloadType = CreateConVar("l4d2_spawn_props_autoload_different", "1", "Should the paths be different for the teams or not?", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_spawnprop", CmdSpawnProp, DESIRED_ADM_FLAGS, "Spawns an object with the given information");
	RegAdminCmd("sm_savemap", CmdSaveMap, DESIRED_ADM_FLAGS, "Save all the spawned object in a stripper file");
	RegAdminCmd("sm_grabprop", CmdGrab, DESIRED_ADM_FLAGS, "Grabs the last object to move it");
	RegAdminCmd("sm_grablook", CmdGrabLook, DESIRED_ADM_FLAGS, "Grabs the looking object to move it");
	
	RegAdminCmd("sm_prop_rotate", CmdRotate, DESIRED_ADM_FLAGS, "Rotates the last spawned object with the desired angles");
	RegAdminCmd("sm_prop_removelast", CmdRemoveLast, DESIRED_ADM_FLAGS, "Remove last spawned object");
	RegAdminCmd("sm_prop_removelook", CmdRemoveLook, DESIRED_ADM_FLAGS, "Remove the looking object");
	RegAdminCmd("sm_prop_removeall", CmdRemoveAll, DESIRED_ADM_FLAGS, "Remove all objects");
	RegAdminCmd("sm_prop_move", CmdMove, DESIRED_ADM_FLAGS, "Move an object with the desired movement type");
	RegAdminCmd("sm_prop_setang", CmdSetAngles, DESIRED_ADM_FLAGS, "Forces an object angles");
	RegAdminCmd("sm_prop_setpos", CmdSetPosition, DESIRED_ADM_FLAGS, "Sets the last object position");
	
	RegAdminCmd("sm_debugprop", CmdDebugProp, ADMFLAG_ROOT, "DEBUG");
	
	
	AutoExecConfig(true, "l4d2_spawn_props_2_0");
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	//DEV
	RegAdminCmd("sm_sprefresh", CmdSPRefresh, DESIRED_ADM_FLAGS, "Refresh admin menu");
	RegAdminCmd("sm_spload", CmdLoad, DESIRED_ADM_FLAGS, "Load map");
	
	//Events
	HookEvent("survival_round_start", Event_SurvivalRoundStart);
	HookEvent("scavenge_round_start", Event_ScavengeRoundStart);
	HookEvent("round_start_post_nav", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public Action:CmdDebugProp(client, args)
{
	decl String:name[256];
	new Object = g_iLastObject[client];
	if(Object > 0 && IsValidEntity(Object))
	{
		GetEntPropString(Object, Prop_Data, "m_iName", name, sizeof(name));
		PrintToChat(client, "prop: %s", name);
	}
	return Plugin_Handled;
}

public Event_SurvivalRoundStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	if(GetConVarBool(g_cvarAutoload) && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}

public Event_ScavengeRoundStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	LogSpawn("Scavenge Round Has Started");
	if(GetConVarBool(g_cvarAutoload) && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}
public Event_RoundStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	if(GetConVarBool(g_cvarAutoload) && GetConVarBool(g_cvarAutoloadType))
	{
		GetRandomMapPath(g_sPath, sizeof(g_sPath));
	}
	LogSpawn("Normal Round Has Started");
	if(GetConVarBool(g_cvarAutoload) && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}

public Event_RoundEnd(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	g_bLoaded = false;
}

public OnMapEnd()
{
	g_bLoaded = false;
}



public Action:CmdSPRefresh(client, args)
{
	new Handle:topmenu = GetAdminTopMenu();
	if(topmenu == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Admin menu is not valid or is unavailable right now");
		return Plugin_Handled;
	}
	hAdminMenu = topmenu;
	new TopMenuObject:menu_category_prop = AddToTopMenu(hAdminMenu, "sm_spawn_props_cat", TopMenuObject_Category, Category_Handler, INVALID_TOPMENUOBJECT);
	
	AddToTopMenu(hAdminMenu, "sm_spdelete", TopMenuObject_Item, AdminMenu_Delete, menu_category_prop, "sm_spdelete", DESIRED_ADM_FLAGS); //Delete
	AddToTopMenu(hAdminMenu, "sm_spedit", TopMenuObject_Item, AdminMenu_Edit, menu_category_prop, "sm_spedit", DESIRED_ADM_FLAGS); //Edit
	AddToTopMenu(hAdminMenu, "sm_spspawn", TopMenuObject_Item, AdminMenu_Spawn, menu_category_prop, "sm_spspawn", DESIRED_ADM_FLAGS); //Spawn
	AddToTopMenu(hAdminMenu, "sm_spsave", TopMenuObject_Item, AdminMenu_Save, menu_category_prop, "sm_spsave", DESIRED_ADM_FLAGS); //Save
	AddToTopMenu(hAdminMenu, "sm_spload", TopMenuObject_Item, AdminMenu_Load, menu_category_prop, "sm_spload", DESIRED_ADM_FLAGS); //Load
	PrintToChat(client, "[SM] Done...");
	return Plugin_Handled;
}

public OnMapStart()
{
	ServerCommand("sm plugins unload l4d2_spawn_props");
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		g_bSpawned[i] = false;
		g_bUnsolid[i] = false;
		g_vecEntityAngles[i][0] = 0.0;
		g_vecEntityAngles[i][1] = 0.0;
		g_vecEntityAngles[i][2] = 0.0;
	}
	if(GetConVarBool(g_cvarAutoload) && !GetConVarBool(g_cvarAutoloadType))
	{
		GetRandomMapPath(g_sPath, sizeof(g_sPath));
	}
}

public Action:CmdSpawnProp(client, args)
{
	if(args < 3)
	{
		PrintToChat(client, "[SM] Usage: sm_spawnprop <model> [static | dynamic | physics] [cursor | origin]");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:arg2[256], String:arg3[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	decl String:model[256];
	strcopy(model, sizeof(model), arg1);
	if(!IsModelPrecached(model))
	{
		if(PrecacheModel(model) <= 0)
		{
			PrintToChat(client, "[SM] There was a problem spawning the selected model [ERROR: Invalid Model]");
			return Plugin_Handled;
		}
	}
	if(StrContains(arg2, "static") >= 0)
	{
		decl Float:VecOrigin[3], Float:VecAngles[3];
		new prop = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
		SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
		if(StrEqual(arg3, "cursor"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			if(TR_DidHit(INVALID_HANDLE))
			{
				TR_GetEndPosition(VecOrigin);
			}
			else
			{
				PrintToChat(client, "[SM] Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(StrEqual(arg3, "origin"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "[SM] Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_bSpawned[prop] = true;
		g_vecEntityAngles[prop] = VecAngles;
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a static object with model <%s>", name, model);
	}
	else if(StrContains(arg2, "dynamic") >= 0)
	{
		decl Float:VecOrigin[3], Float:VecAngles[3];
		new prop = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
		if(StrEqual(arg3, "cursor"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			if(TR_DidHit(INVALID_HANDLE))
			{
				TR_GetEndPosition(VecOrigin);
			}
			else
			{
				PrintToChat(client, "[SM] Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(StrEqual(arg3, "origin"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "[SM] Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_bSpawned[prop] = true;
		g_vecEntityAngles[prop] = VecAngles;
		g_bUnsolid[prop] = true;
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a dynamic object with model <%s>", name, model);
	}
	else if(StrContains(arg2, "physics") >= 0)
	{
		decl Float:VecOrigin[3], Float:VecAngles[3];
		new prop = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
		if(StrEqual(arg3, "cursor"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
			TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
			if(TR_DidHit(INVALID_HANDLE))
			{
				TR_GetEndPosition(VecOrigin);
			}
			else
			{
				PrintToChat(client, "[SM] Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(StrEqual(arg3, "origin"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "[SM] Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_bSpawned[prop] = true;
		g_vecEntityAngles[prop] = VecAngles;
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a physics object with model <%s>", name, model);
	}
	else
	{
		PrintToChat(client, "[SM] Invalid render mode. Use: [static | dynamic | physics]");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//Admin Menu ready
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	hAdminMenu = topmenu;
	new TopMenuObject:menu_category_prop = AddToTopMenu(hAdminMenu, "sm_spawn_props_cat", TopMenuObject_Category, Category_Handler, INVALID_TOPMENUOBJECT);
	
	AddToTopMenu(hAdminMenu, "sm_spdelete", TopMenuObject_Item, AdminMenu_Delete, menu_category_prop, "sm_spdelete", DESIRED_ADM_FLAGS); //Delete
	AddToTopMenu(hAdminMenu, "sm_spedit", TopMenuObject_Item, AdminMenu_Edit, menu_category_prop, "sm_spedit", DESIRED_ADM_FLAGS); //Edit
	AddToTopMenu(hAdminMenu, "sm_spspawn", TopMenuObject_Item, AdminMenu_Spawn, menu_category_prop, "sm_spdelete", DESIRED_ADM_FLAGS); //Spawn
	AddToTopMenu(hAdminMenu, "sm_spsave", TopMenuObject_Item, AdminMenu_Save, menu_category_prop, "sm_spsave", DESIRED_ADM_FLAGS); //Save
	AddToTopMenu(hAdminMenu, "sm_spload", TopMenuObject_Item, AdminMenu_Load, menu_category_prop, "sm_spload", DESIRED_ADM_FLAGS); //Load
}

//Admin Category Name
public Category_Handler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Select a task:");
	}
	else if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Objects");
	}
}
/*
////////////////////////////////////////////////////////////////////////////|
						D E L E T E        M E N U							|
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public AdminMenu_Delete(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Delete Object");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildDeleteMenu(param);
	}
}

stock BuildDeleteMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Delete);
	SetMenuTitle(menu, "Select the delete task");
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "sm_spdeleteall", "Delete All Objects");
	AddMenuItem(menu, "sm_spdeletelook", "Delete Looking Object");
	AddMenuItem(menu, "sm_spdeletelast", "Delete Last Object");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

stock BuildDeleteAllAskMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DA_Ask);
	SetMenuTitle(menu, "Are you sure?");
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "sm_spyes", "Yes");
	AddMenuItem(menu, "sm_spno", "No");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_DA_Ask(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "sm_spyes"))
			{
				DeleteAllProps();
				PrintToChat(param1, "[SM] Successfully deleted all spawned objects");
			}
			else
			{
				PrintToChat(param1, "[SM] Canceled");
			}
			BuildDeleteMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_Delete(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "sm_spdeleteall"))
			{
				BuildDeleteAllAskMenu(param1);
				PrintToChat(param1, "[SM] Are you sure that you want to delete all the spawned objects?");
			}
			else if(StrEqual(menucmd, "sm_spdeletelook"))
			{
				DeleteLookingEntity(param1);
				BuildDeleteMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spdeletelast"))
			{
				DeleteLastProp(param1);
				BuildDeleteMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

/*
////////////////////////////////////////////////////////////////////////////|
						E D I T        M E N U							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public AdminMenu_Edit(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Edit Object");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildEditPropMenu(param);
	}
}

/*
////////////////////////////////////////////////////////////////////////////|
						S P A W N        M E N U							|
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public AdminMenu_Spawn(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Object");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildSpawnMenu(param);
	}
}

stock BuildSpawnMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Spawn);
	SetMenuTitle(menu, "Select the spawn method");
	SetMenuExitBackButton(menu, true);
	if(GetConVarBool(g_cvarPhysics))
	{
		AddMenuItem(menu, "sm_spawnpc", "Spawn Physics On Cursor");
		AddMenuItem(menu, "sm_spawnpo", "Spawn Physics On Origin");
	}
	if(GetConVarBool(g_cvarDynamic))
	{
		AddMenuItem(menu, "sm_spawndc", "Spawn Non-solid On Cursor");
		AddMenuItem(menu, "sm_spawndo", "Spawn Non-solid On Origin");
	}
	if(GetConVarBool(g_cvarStatic))
	{
		AddMenuItem(menu, "sm_spawnsc", "Spawn Solid On Cursor");
		AddMenuItem(menu, "sm_spawnso", "Spawn Solid On Origin");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Spawn(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "sm_spawnpc"))
			{
				BuildPhysicsCursorMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spawnpo"))
			{
				BuildPhysicsPositionMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spawndc"))
			{
				BuildDynamicCursorMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spawndo"))
			{
				BuildDynamicPositionMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spawnsc"))
			{
				BuildStaticCursorMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spawnso"))
			{
				BuildStaticPositionMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

/*
////////////////////////////////////////////////////////////////////////////|
						S A V E       M E N U							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public AdminMenu_Save(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Save Objects");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildSaveMenu(param);
	}
}

stock BuildSaveMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Save);
	SetMenuTitle(menu, "Select The Save Method");
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "sm_spsavestripper", "Save Stripper File");
	AddMenuItem(menu, "sm_spsaverouting", "Save Routing File");
	AddMenuItem(menu, "sm_spsaveplugin", "Save Spawn Objects File");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

stock BuildRoutingMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PathDiff);
	SetMenuTitle(menu, "Select Path Difficulty");
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "sm_speasy", "Easy Path");
	AddMenuItem(menu, "sm_spmedium", "Medium Path");
	AddMenuItem(menu, "sm_sphard", "Hard Path");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_PathDiff(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "sm_speasy"))
			{
				SaveRoutingPath(param1, RouteType_Easy);
			}
			else if(StrEqual(menucmd, "sm_spmedium"))
			{
				SaveRoutingPath(param1, RouteType_Medium);
			}
			else if(StrEqual(menucmd, "sm_sphard"))
			{
				SaveRoutingPath(param1, RouteType_Hard);
			}
			BuildSaveMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_Save(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "sm_spsavestripper"))
			{
				SaveMapStripper(param1);
				BuildSaveMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spsaverouting"))
			{
				BuildRoutingMenu(param1);
			}
			else if(StrEqual(menucmd, "sm_spsaveplugin"))
			{
				SavePluginProps(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

/*
////////////////////////////////////////////////////////////////////////////|
						L O A D       M E N U							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/

public AdminMenu_Load(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Load Objects");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildLoadAskMenu(param);
		PrintToChat(param, "[SM] Are you sure that you want the load the map data cache?");
	}
}

stock BuildLoadAskMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Load_Ask);
	SetMenuTitle(menu, "Are you sure?");
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "sm_spyes", "Yes");
	AddMenuItem(menu, "sm_spno", "No");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

stock BuildLoadPropsMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Load_Props);
	SetMenuTitle(menu, "Choose a map number please");
	SetMenuExitBackButton(menu, true);
	decl String:buffer[16], String:buffer2[16];
	for(new i=1; i <= MAX_PATHS; i++)
	{
		Format(buffer, sizeof(buffer), "map%i", i);
		Format(buffer2, sizeof(buffer2), "Map %i", i);
		AddMenuItem(menu, buffer, buffer2);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Load_Props(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			ReplaceString(menucmd, sizeof(menucmd), "map", "", false);
			new number = StringToInt(menucmd);
			LoadPluginProps(param1, number);
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_Load_Ask(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "sm_spyes"))
			{
				BuildLoadPropsMenu(param1);
			}
			else
			{
				PrintToChat(param1, "[SM] Canceled");
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

/*
////////////////////////////////////////////////////////////////////////////|
						Build Secondary Menus							    |
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|
*/
stock BuildPhysicsCursorMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PhysicsCursor);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);
	if(g_cvarVehicles)
	{
		AddMenuItem(menu, "vehicles", "Vehicles");
	}
	if(g_cvarFoliage)
	{
		AddMenuItem(menu, "foliage", "Foliage");
	}
	if(g_cvarInterior)
	{
		AddMenuItem(menu, "interior", "Interior");
	}
	if(g_cvarExterior)
	{
		AddMenuItem(menu, "exterior", "Exterior");
	}
	if(g_cvarDecorative)
	{
		AddMenuItem(menu, "decorative", "Decorative");
	}
	if(g_cvarMisc)
	{
		AddMenuItem(menu, "misc", "Misc");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

stock BuildPhysicsPositionMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PhysicsPosition);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);
	if(g_cvarVehicles)
	{
		AddMenuItem(menu, "vehicles", "Vehicles");
	}
	if(g_cvarFoliage)
	{
		AddMenuItem(menu, "foliage", "Foliage");
	}
	if(g_cvarInterior)
	{
		AddMenuItem(menu, "interior", "Interior");
	}
	if(g_cvarExterior)
	{
		AddMenuItem(menu, "exterior", "Exterior");
	}
	if(g_cvarDecorative)
	{
		AddMenuItem(menu, "decorative", "Decorative");
	}
	if(g_cvarMisc)
	{
		AddMenuItem(menu, "misc", "Misc");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

stock BuildDynamicCursorMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DynamicCursor);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);
	if(g_cvarVehicles)
	{
		AddMenuItem(menu, "vehicles", "Vehicles");
	}
	if(g_cvarFoliage)
	{
		AddMenuItem(menu, "foliage", "Foliage");
	}
	if(g_cvarInterior)
	{
		AddMenuItem(menu, "interior", "Interior");
	}
	if(g_cvarExterior)
	{
		AddMenuItem(menu, "exterior", "Exterior");
	}
	if(g_cvarDecorative)
	{
		AddMenuItem(menu, "decorative", "Decorative");
	}
	if(g_cvarMisc)
	{
		AddMenuItem(menu, "misc", "Misc");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

stock BuildDynamicPositionMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DynamicPosition);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);
	if(g_cvarVehicles)
	{
		AddMenuItem(menu, "vehicles", "Vehicles");
	}
	if(g_cvarFoliage)
	{
		AddMenuItem(menu, "foliage", "Foliage");
	}
	if(g_cvarInterior)
	{
		AddMenuItem(menu, "interior", "Interior");
	}
	if(g_cvarExterior)
	{
		AddMenuItem(menu, "exterior", "Exterior");
	}
	if(g_cvarDecorative)
	{
		AddMenuItem(menu, "decorative", "Decorative");
	}
	if(g_cvarMisc)
	{
		AddMenuItem(menu, "misc", "Misc");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}
stock BuildStaticCursorMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_StaticCursor);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);
	if(g_cvarVehicles)
	{
		AddMenuItem(menu, "vehicles", "Vehicles");
	}
	if(g_cvarFoliage)
	{
		AddMenuItem(menu, "foliage", "Foliage");
	}
	if(g_cvarInterior)
	{
		AddMenuItem(menu, "interior", "Interior");
	}
	if(g_cvarExterior)
	{
		AddMenuItem(menu, "exterior", "Exterior");
	}
	if(g_cvarDecorative)
	{
		AddMenuItem(menu, "decorative", "Decorative");
	}
	if(g_cvarMisc)
	{
		AddMenuItem(menu, "misc", "Misc");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}
stock BuildStaticPositionMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_StaticPosition);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);
	if(g_cvarVehicles)
	{
		AddMenuItem(menu, "vehicles", "Vehicles");
	}
	if(g_cvarFoliage)
	{
		AddMenuItem(menu, "foliage", "Foliage");
	}
	if(g_cvarInterior)
	{
		AddMenuItem(menu, "interior", "Interior");
	}
	if(g_cvarExterior)
	{
		AddMenuItem(menu, "exterior", "Exterior");
	}
	if(g_cvarDecorative)
	{
		AddMenuItem(menu, "decorative", "Decorative");
	}
	if(g_cvarMisc)
	{
		AddMenuItem(menu, "misc", "Misc");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

stock BuildEditPropMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_EditProp);
	SetMenuTitle(menu, "Select an action:");
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "rotate", "Rotate");
	AddMenuItem(menu, "move", "Move");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_PhysicsCursor(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 1;
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "vehicles"))
			{
				DisplayVehiclesMenu(param1);
			}
			else if(StrEqual(menucmd, "foliage"))
			{
				DisplayFoliageMenu(param1);
			}
			else if(StrEqual(menucmd, "interior"))
			{
				DisplayInteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "exterior"))
			{
				DisplayExteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "decorative"))
			{
				DisplayDecorativeMenu(param1);
			}
			else if(StrEqual(menucmd, "misc"))
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_PhysicsPosition(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 2;
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "vehicles"))
			{
				DisplayVehiclesMenu(param1);
			}
			else if(StrEqual(menucmd, "foliage"))
			{
				DisplayFoliageMenu(param1);
			}
			else if(StrEqual(menucmd, "interior"))
			{
				DisplayInteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "exterior"))
			{
				DisplayExteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "decorative"))
			{
				DisplayDecorativeMenu(param1);
			}
			else if(StrEqual(menucmd, "misc"))
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_DynamicCursor(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 3;
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "vehicles"))
			{
				DisplayVehiclesMenu(param1);
			}
			else if(StrEqual(menucmd, "foliage"))
			{
				DisplayFoliageMenu(param1);
			}
			else if(StrEqual(menucmd, "interior"))
			{
				DisplayInteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "exterior"))
			{
				DisplayExteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "decorative"))
			{
				DisplayDecorativeMenu(param1);
			}
			else if(StrEqual(menucmd, "misc"))
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_DynamicPosition(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 4;
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "vehicles"))
			{
				DisplayVehiclesMenu(param1);
			}
			else if(StrEqual(menucmd, "foliage"))
			{
				DisplayFoliageMenu(param1);
			}
			else if(StrEqual(menucmd, "interior"))
			{
				DisplayInteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "exterior"))
			{
				DisplayExteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "decorative"))
			{
				DisplayDecorativeMenu(param1);
			}
			else if(StrEqual(menucmd, "misc"))
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_StaticCursor(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 5;
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "vehicles"))
			{
				DisplayVehiclesMenu(param1);
			}
			else if(StrEqual(menucmd, "foliage"))
			{
				DisplayFoliageMenu(param1);
			}
			else if(StrEqual(menucmd, "interior"))
			{
				DisplayInteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "exterior"))
			{
				DisplayExteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "decorative"))
			{
				DisplayDecorativeMenu(param1);
			}
			else if(StrEqual(menucmd, "misc"))
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_StaticPosition(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCategory[param1] = 6;
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "vehicles"))
			{
				DisplayVehiclesMenu(param1);
			}
			else if(StrEqual(menucmd, "foliage"))
			{
				DisplayFoliageMenu(param1);
			}
			else if(StrEqual(menucmd, "interior"))
			{
				DisplayInteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "exterior"))
			{
				DisplayExteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "decorative"))
			{
				DisplayDecorativeMenu(param1);
			}
			else if(StrEqual(menucmd, "misc"))
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_EditProp(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "rotate"))
			{
				DisplayRotateMenu(param1);
			}
			else if(StrEqual(menucmd, "move"))
			{
				DisplayMoveMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock DisplayVehiclesMenu(client)
{
	g_iSubCategory[client] =  1;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == 'n')
		{
			buffer[--len] = '0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 1)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Vehicles");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayFoliageMenu(client)
{
	g_iSubCategory[client] =  2;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 2)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Foliage");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayInteriorMenu(client)
{
	g_iSubCategory[client] =  3;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 3)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Interior");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayExteriorMenu(client)
{
	g_iSubCategory[client] =  4;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 4)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Exterior");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayDecorativeMenu(client)
{
	g_iSubCategory[client] =  5;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 5)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Decorative");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayMiscMenu(client)
{
	g_iSubCategory[client] =  6;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 6)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Misc");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayRotateMenu(client)
{
	g_iMoveCategory[client] = 1;
	new Handle:menu = CreateMenu(MenuHandler_PropPosition);
	AddMenuItem(menu, "rotate15x", "Rotate 15º (X axys)");
	AddMenuItem(menu, "rotate45x", "Rotate 45º (X axys)");
	AddMenuItem(menu, "rotate90x", "Rotate 90º (X axys)");
	AddMenuItem(menu, "rotate180x", "Rotate 180º (X axys)");
	AddMenuItem(menu, "rotate15y", "Rotate 15º (Y axys)");
	AddMenuItem(menu, "rotate45y", "Rotate 45º (Y axys)");
	AddMenuItem(menu, "rotate90y", "Rotate 90º (Y axys)");
	AddMenuItem(menu, "rotate180y", "Rotate 180º (Y axys)");
	AddMenuItem(menu, "rotate15z", "Rotate 15º (Z axys)");
	AddMenuItem(menu, "rotate45z", "Rotate 45º (Z axys)");
	AddMenuItem(menu, "rotate90z", "Rotate 90º (Z axys)");
	AddMenuItem(menu, "rotate180z", "Rotate 180º (Z axys)");
	SetMenuTitle(menu, "Rotate");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

stock DisplayMoveMenu(client)
{
	g_iMoveCategory[client] = 2;
	new Handle:menu = CreateMenu(MenuHandler_PropPosition);
	AddMenuItem(menu, "moveup", "Move Up");
	AddMenuItem(menu, "movedown", "Move Down");
	AddMenuItem(menu, "moveright", "Move Right");
	AddMenuItem(menu, "moveleft", "Move Left");
	AddMenuItem(menu, "moveforward", "Move Forward");
	AddMenuItem(menu, "movebackward", "Move Backward");
	SetMenuTitle(menu, "Move");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_DoAction(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:model[256];
			GetMenuItem(menu, param2, model, sizeof(model));
			if(!IsModelPrecached(model))
			{
				PrecacheModel(model);
			}
			if(g_iCategory[param1] == 1)
			{
				decl Float:VecOrigin[3], Float:VecAngles[3];
				new prop = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientEyePosition(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				
				TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
				if(TR_DidHit(INVALID_HANDLE))
				{
					TR_GetEndPosition(VecOrigin);
				}
				else
				{
					PrintToChat(param1, "[SM] Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a physics object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 2)
			{
				decl Float:VecOrigin[3], Float:VecAngles[3];
				new prop = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientAbsOrigin(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a physics object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 3)
			{
				decl Float:VecOrigin[3], Float:VecAngles[3];
				new prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientEyePosition(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				
				TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
				if(TR_DidHit(INVALID_HANDLE))
				{
					TR_GetEndPosition(VecOrigin);
				}
				else
				{
					PrintToChat(param1, "[SM] Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
			
				g_bSpawned[prop] = true;
				g_bUnsolid[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a dynamic object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 4)
			{
				decl Float:VecOrigin[3], Float:VecAngles[3];
				new prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				DispatchSpawn(prop);
				GetClientAbsOrigin(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_bUnsolid[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a dynamic object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 5)
			{
				decl Float:VecOrigin[3], Float:VecAngles[3];
				new prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				GetClientEyePosition(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
				
				TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
				if(TR_DidHit(INVALID_HANDLE))
				{
					TR_GetEndPosition(VecOrigin);
				}
				else
				{
					PrintToChat(param1, "[SM] Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a static object with model <%s>", name, model);
			}
			else if(g_iCategory[param1] == 6)
			{
				decl Float:VecOrigin[3], Float:VecAngles[3];
				new prop = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
				DispatchSpawn(prop);
				GetClientAbsOrigin(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				g_vecLastEntityAngles[param1] = VecAngles;
				g_iLastObject[param1] = prop;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = VecAngles;
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				LogSpawn("%s spawned a static object with model <%s>", name, model);
			}
			switch(g_iSubCategory[param1])
			{
				case 1:
				{
					DisplayVehiclesMenu(param1);
				}
				case 2:
				{
					DisplayFoliageMenu(param1);
				}
				case 3:
				{
					DisplayInteriorMenu(param1);
				}
				case 4:
				{
					DisplayExteriorMenu(param1);
				}
				case 5:
				{
					DisplayDecorativeMenu(param1);
				}
				case 6:
				{
					DisplayMiscMenu(param1);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				switch(g_iCategory[param1])
				{
					case 1:
					{
						BuildPhysicsCursorMenu(param1);
					}
					case 2:
					{
						BuildPhysicsPositionMenu(param1);
					}
					case 3:
					{
						BuildDynamicCursorMenu(param1);
					}
					case 4:
					{
						BuildDynamicPositionMenu(param1);
					}
					case 5:
					{
						BuildStaticCursorMenu(param1);
					}
					case 6:
					{
						BuildStaticPositionMenu(param1);
					}
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public MenuHandler_PropPosition(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			switch(g_iMoveCategory[param1])
			{
				case 1:
				{
					if(g_iLastObject[param1] <= 0 || !IsValidEntity(g_iLastObject[param1]))
					{
						PrintToChat(param1, "[SM] The last object is not valid anymore or you haven't spawned anything yet");
						DisplayRotateMenu(param1);
						return;
					}
					new Object = g_iLastObject[param1];
					if(StrEqual(menucmd, "rotate15x"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[0] += 15;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate45x"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[0] += 45;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate90x"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[0] += 90;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate180x"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[0] += 180;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate15y"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[1] += 15;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate45y"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[1] += 45;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate90y"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[1] += 90;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate180y"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[1] += 180;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate15z"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[2] += 15;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate45z"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[2] += 45;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate90z"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[2] += 90;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					else if(StrEqual(menucmd, "rotate180z"))
					{
						decl Float:vecAngles[3];
						vecAngles[0] = g_vecLastEntityAngles[param1][0];
						vecAngles[1] = g_vecLastEntityAngles[param1][1];
						vecAngles[2] = g_vecLastEntityAngles[param1][2];
						vecAngles[2] += 180;
						g_vecLastEntityAngles[param1] = vecAngles;
						TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
						g_vecEntityAngles[g_iLastObject[param1]] = vecAngles;
					}
					DisplayRotateMenu(param1);
				}
				case 2:
				{
					if(g_iLastObject[param1] <= 0 || !IsValidEntity(g_iLastObject[param1]))
					{
						PrintToChat(param1, "[SM] The last object is not valid anymore or you haven't spawned anything yet");
						DisplayMoveMenu(param1);
						return;
					}
					new Object = g_iLastObject[param1];
					if(StrEqual(menucmd, "moveup"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[2]+= 30;
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "movedown"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[2]-= 30;
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "moveright"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[1]+= 30;
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "moveleft"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[1]-= 30;
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "moveforward"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[0]+= 30;
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "movebackward"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[0]-= 30;
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					DisplayMoveMenu(param1);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				BuildEditPropMenu(param1);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:CmdReadFile(client, args)
{
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		LogMessage("Read: %s", buffer);
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 1)
		{
			break;
		}
		
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		if(IsEndOfFile(file))
		{
			break;
		}
	}
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}

stock DeleteLookingEntity(client)
{
	decl Float:VecOrigin[3], Float:VecAngles[3];
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(INVALID_HANDLE))
	{
		new Object = TR_GetEntityIndex(INVALID_HANDLE);
		if(Object > 0 && IsValidEntity(Object) && IsValidEdict(Object))
		{
			decl String:class[256];
			GetEdictClassname(Object, class, sizeof(class));
			if(StrEqual(class, "prop_physics")
			|| StrEqual(class, "prop_dynamic")
			|| StrEqual(class, "prop_physics_override")
			|| StrEqual(class, "prop_dynamic_override"))
			{
				g_bSpawned[Object] = false;
				g_bUnsolid[Object] = false;
				g_vecEntityAngles[Object][0] = 0.0;
				g_vecEntityAngles[Object][1] = 0.0;
				g_vecEntityAngles[Object][2] = 0.0;
				AcceptEntityInput(Object, "KillHierarchy");
				PrintToChat(client, "[SM] Succesfully removed an object");
				if(Object == g_iLastObject[client])
				{
					g_iLastObject[client] = -1;
					g_vecLastEntityAngles[client][0] = 0.0;
					g_vecLastEntityAngles[client][1] = 0.0;
					g_vecLastEntityAngles[client][2] = 0.0;
					g_bGrab[client] = false;
					g_bGrabbed[Object] = false;
				}
				if(Object == g_iLastGrabbedObject[client])
				{
					g_iLastGrabbedObject[client] = -1;
				}
				return;
			}
		}
	}
	else
	{
		new Object = GetClientAimTarget(client, false);
		if(Object == -2)
		{
			PrintToChat(client, "[SM] This plugin won't work in this game");
			SetFailState("Unhandled Behaviour");
		}
		if(Object > 0 && IsValidEntity(Object))
		{
			decl String:class[256];
			GetEdictClassname(Object, class, sizeof(class));
			if(StrEqual(class, "prop_physics")
			|| StrEqual(class, "prop_dynamic")
			|| StrEqual(class, "prop_physics_override")
			|| StrEqual(class, "prop_dynamic_override"))
			{
				g_bSpawned[Object] = false;
				g_bUnsolid[Object] = false;
				g_vecEntityAngles[Object][0] = 0.0;
				g_vecEntityAngles[Object][1] = 0.0;
				g_vecEntityAngles[Object][2] = 0.0;
				AcceptEntityInput(Object, "KillHierarchy");
				PrintToChat(client, "[SM] Succesfully removed an object");
				if(Object == g_iLastObject[client])
				{
					g_iLastObject[client] = -1;
					g_vecLastEntityAngles[client][0] = 0.0;
					g_vecLastEntityAngles[client][1] = 0.0;
					g_vecLastEntityAngles[client][2] = 0.0;
					if(Object == g_iLastGrabbedObject[client])
					{
						g_iLastGrabbedObject[client] = -1;
					}
				}
				return;
			}
		}
	}
	PrintToChat(client, "[SM] You are not looking to a valid object");
}

stock DeleteAllProps()
{
	CheatCommand(_, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
	for(new i=1; i<=MaxClients; i++)
	{
		g_iLastObject[i] = -1;
		g_vecLastEntityAngles[i][0] = 0.0;
		g_vecLastEntityAngles[i][1] = 0.0;
		g_vecLastEntityAngles[i][2] = 0.0;
		g_bGrab[i] = false;
		g_iLastGrabbedObject[i] = -1;
	}
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i])
		{
			g_bGrabbed[i] = false;
			g_bSpawned[i] = false;
			g_bUnsolid[i] = false;
			g_vecEntityAngles[i][0] = 0.0;
			g_vecEntityAngles[i][1] = 0.0;
			g_vecEntityAngles[i][2] = 0.0;
			if(IsValidEntity(i))
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}

stock CheatCommand(client = 0, String:command[], String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

//Disabled right now
stock DeleteLastProp(client)
{
	new Object = g_iLastObject[client];
	if(Object > 0 && IsValidEntity(Object))
	{
		decl String:class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(StrEqual(class, "prop_physics")
		|| StrEqual(class, "prop_dynamic")
		|| StrEqual(class, "prop_physics_override")
		|| StrEqual(class, "prop_dynamic_override"))
		{
			AcceptEntityInput(g_iLastObject[client], "KillHierarchy");
			PrintToChat(client, "[SM] Succesfully deleted the last spawned object");
			g_iLastObject[client] = -1;
			g_vecLastEntityAngles[client][0] = 0.0;
			g_vecLastEntityAngles[client][1] = 0.0;
			g_vecLastEntityAngles[client][2] = 0.0;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_bGrab[client] = false;
			g_bGrabbed[Object] = false;
			if(Object == g_iLastGrabbedObject[client])
			{
				g_iLastGrabbedObject[client] = -1;
			}
			return;
		}
		else
		{
			PrintToChat(client, "[SM] The last spawned object index %i is not an object anymore!", Object);
			g_iLastObject[client] = -1;
			g_vecLastEntityAngles[client][0] = 0.0;
			g_vecLastEntityAngles[client][1] = 0.0;
			g_vecLastEntityAngles[client][2] = 0.0;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
		}
	}
	else if(Object > 0 && !IsValidEntity(Object))
	{
		PrintToChat(client, "[SM] The last object is not valid anymore");
	}
	else if(Object <= 0)
	{
		PrintToChat(client, "[SM] You haven't spawned anything yet");
	}
}

stock LogSpawn(const String:format[], any:...)
{
	if(!GetConVarBool(g_cvarLog))
	{
		return;
	}
	decl String:buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	new Handle:file;
	decl String:FileName[256], String:sTime[256];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	BuildPath(Path_SM, FileName, sizeof(FileName), "logs/objects_%s.log", sTime);
	file = OpenFile(FileName, "a+");
	FormatTime(sTime, sizeof(sTime), "%b %d |%H:%M:%S| %Y");
	WriteFileLine(file, "%s: %s", sTime, buffer);
	FlushFile(file);
	CloseHandle(file);
}

public Action:CmdSaveMap(client, args)
{
	SaveMapStripper(client);
	return Plugin_Handled;
}

stock SaveMapStripper(client)
{
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> was called by %N", client);
	#endif
	LogSpawn("%N saved the objects for this map on a 'Stripper' file format", client);
	PrintToChat(client, "\x04[SM] Saving the content. Please Wait");
	decl String:FileName[256], String:map[256], String:classname[256];
	new Handle:file = INVALID_HANDLE;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/maps/stripper/%s.cfg", map);
	
	if(FileExists(FileName))
	{
		PrintHintText(client, "The file already exists. The older content won't be deleted.");
	}
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> File stated, proceed");
	#endif
	file = OpenFile(FileName, "a+");
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> File Opened, proceed");
	#endif
	if(file == INVALID_HANDLE)
	{
		#if DEBUG
		LogSpawn("[DEBUG] <SaveMapStripper> File Invalid, proceed");
		#endif
		PrintToChat(client, "[SM] Failed to create or overwrite the map file");
		PrintToChat(client, "\x04[SM] Something was probably missing during installation");
		PrintHintText(client, "[SM] Probably missing sourcemod/data/maps/stripper folder");
		PrintToConsole(client, "[SM] Unable to open, write, or find the file!");
		PrintCenterText(client, "[SM] FAILURE");
		return;
	}
	
	decl Float:vecOrigin[3], Float:vecAngles[3], String:sModel[256], String:sTime[256];
	new iOrigin[3], iAngles[3];
	FormatTime(sTime, sizeof(sTime), "%Y/%m/%d");
	WriteFileLine(file, ";----------FILE MODIFICATION (YY/MM/DD): [%s] ---------------||", sTime);
	WriteFileLine(file, ";----------BY: %N----------------------||", client);
	WriteFileLine(file, "");
	WriteFileLine(file, "add:");
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> Wrote first information line");
	#endif
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		#if DEBUG
		LogSpawn("[DEBUG] <SaveMapStripper> CHECK: %i", i);
		#endif
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			#if DEBUG
			LogSpawn("[DEBUG] <SaveMapStripper> Possible Entity Found: %i <%s>", i, classname);
			#endif
			if(StrContains(classname, "prop_dynamic") >= 0 || StrContains(classname, "prop_physics") >= 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
				vecAngles = g_vecEntityAngles[i];
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				iOrigin[0] = RoundToFloor(vecOrigin[0]);
				iOrigin[1] = RoundToFloor(vecOrigin[1]);
				iOrigin[2] = RoundToFloor(vecOrigin[2]);
				
				iAngles[0] = RoundToFloor(vecAngles[0]);
				iAngles[1] = RoundToFloor(vecAngles[1]);
				iAngles[2] = RoundToFloor(vecAngles[2]);
				WriteFileLine(file, "{");
				if(StrContains(classname, "physics") < 0)
				{
					if(g_bUnsolid[i])
					{
						WriteFileLine(file, "	\"solid\" \"0\"");
					}
					else
					{
						WriteFileLine(file, "	\"solid\" \"6\"");
					}
				}
				WriteFileLine(file, "	\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
				WriteFileLine(file, "	\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
				WriteFileLine(file, "	\"model\"	 \"%s\"", sModel);
				WriteFileLine(file, "	\"classname\"	\"%s\"", classname);
				WriteFileLine(file, "}");
				WriteFileLine(file, "");
				#if DEBUG
				LogSpawn("[DEBUG] <SaveMapStripper> END: %i", i);
				#endif
			}
		}
	}
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> Wrote all entities");
	#endif
	FlushFile(file);
	CloseHandle(file);
	PrintToChat(client, "\x03[SM] Succesfully saved the map data (%s)", FileName);
	#if DEBUG
	LogSpawn("[DEBUG] <SaveMapStripper> END");
	#endif
}

stock SaveRoutingPath(client, RouteType:type)
{
	#if DEBUG
	LogSpawn("[DEBUG] <SaveRoutingPath> was called by %N", client);
	#endif
	LogSpawn("%N saved the objects for this map on a \"Routing\" file format", client);
	PrintToChat(client, "\x04[SM] Saving the content. Please Wait");
	decl String:FileName[256], String:map[256], String:classname[256], String:targetname[256];
	new Handle:file = INVALID_HANDLE;
	new bool:Exists = false;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/maps/routing/%s.cfg", map);
	if(FileExists(FileName))
	{
		PrintHintText(client, "The file already exists. The older content won't be deleted.");
		Exists = true;
	}
	file = OpenFile(FileName, "a+");
	if(file == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Failed to create or overwrite the map file");
		PrintToChat(client, "\x04[SM] Something was probably missing during installation");
		PrintHintText(client, "[SM] Probably missing sourcemod/data/maps/routing folder");
		PrintToConsole(client, "[SM] Unable to open, write, or find the file!");
		PrintCenterText(client, "[SM] FAILURE");
		return;
	}
	decl Float:vecOrigin[3], Float:vecAngles[3], String:sModel[256], String:sTime[256];
	new iOrigin[3], iAngles[3];
	FormatTime(sTime, sizeof(sTime), "%Y/%m/%d");
	WriteFileLine(file, ";----------FILE MODIFICATION (YY/MM/DD): [%s] ---------------||", sTime);
	WriteFileLine(file, ";----------BY: %N----------------------||", client);
	WriteFileLine(file, "");
	switch(type)
	{
		case RouteType_Easy:
		{
			WriteFileLine(file, ";This part was generated for an \"Easy\" routing path.");
			Format(targetname, sizeof(targetname), "easy_route_blocker");
		}
		case RouteType_Medium:
		{
			WriteFileLine(file, ";This part was generated for a \"Medium\" routing path.");
			Format(targetname, sizeof(targetname), "medium_route_blocker");
		}
		case RouteType_Hard:
		{
			WriteFileLine(file, ";This part was generated for a \"Hard\" routing path.");
			Format(targetname, sizeof(targetname), "hard_route_blocker");
		}
	}
	WriteFileLine(file, "");
	WriteFileLine(file, "add:");
	
	if(!Exists)
	{
		//First, wee add the necessary relays
		
		WriteFileLine(file, "; plugin trigger relay");
		WriteFileLine(file, "; will get fired by Plugin ONLY IN VERSUS, so it doesnt break coop");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"origin\" \"0 0 0\"");
		WriteFileLine(file, "	\"spawnflags\" \"1\"");
		WriteFileLine(file, "	\"targetname\" \"relay_routing_init\"");
		WriteFileLine(file, "	\"classname\" \"logic_relay\"");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	; destroy Valve routing entities so they dont interfere");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"OnTrigger\" \"director_queryKill0-1\"");
		WriteFileLine(file, "}");
		WriteFileLine(file, "");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"origin\" \"0 0 0\"");
		WriteFileLine(file, "	\"spawnflags\" \"1\"");
		WriteFileLine(file, "	\"targetname\" \"relay_routing_disabledbydefault\"");
		WriteFileLine(file, "	\"classname\" \"logic_auto\"");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"OnMapSpawn\" \"easy_route_blockerDisable0-1\"");
		WriteFileLine(file, "	\"OnMapSpawn\" \"easy_route_blockerDisableCollision0-1\"");
		WriteFileLine(file, "	\"OnMapSpawn\" \"medium_route_blockerDisable0-1\"");
		WriteFileLine(file, "	\"OnMapSpawn\" \"medium_route_blockerDisableCollision0-1\"");
		WriteFileLine(file, "	\"OnMapSpawn\" \"hard_route_blockerDisable0-1\"");
		WriteFileLine(file, "	\"OnMapSpawn\" \"hard_route_blockerDisableCollision0-1\"");
		WriteFileLine(file, "}");
		WriteFileLine(file, "; config existence checking entity");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"origin\" \"0 0 0\"");
		WriteFileLine(file, "	\"targetname\" \"map_has_routing\"");
		WriteFileLine(file, "	\"noise\" \"0\"");
		WriteFileLine(file, "	\"minAngerRange\" \"1\"");
		WriteFileLine(file, "	\"maxAngerRange\" \"10\"");
		WriteFileLine(file, "	\"classname\" \"logic_director_query\"");
		WriteFileLine(file, "	\"OutAnger\" \"DoHeadBangInValue0-1\"");
		WriteFileLine(file, "}");
		WriteFileLine(file, "");
		WriteFileLine(file, "; easy path");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"origin\" \"0 0 0\"");
		WriteFileLine(file, "	\"targetname\" \"relay_easy_route_spawn\"");
		WriteFileLine(file, "	\"spawnflags\" \"0\"");
		WriteFileLine(file, "	\"classname\" \"logic_relay\"");
		WriteFileLine(file, "	\"OnTrigger\" \"easy_route_blockerEnable0-1\"");
		WriteFileLine(file, "	\"OnTrigger\" \"easy_route_blockerEnableCollision0-1\"");
		WriteFileLine(file, "}");
		WriteFileLine(file, "");
		WriteFileLine(file, "; medium path");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"origin\" \"0 0 0\"");
		WriteFileLine(file, "	\"targetname\" \"relay_medium_route_spawn\"");
		WriteFileLine(file, "	\"spawnflags\" \"0\"");
		WriteFileLine(file, "	\"classname\" \"logic_relay\"");
		WriteFileLine(file, "	\"OnTrigger\" \"medium_route_blockerEnable0-1\"");
		WriteFileLine(file, "	\"OnTrigger\" \"medium_route_blockerEnableCollision0-1\"");
		WriteFileLine(file, "}");
		WriteFileLine(file, "");
		WriteFileLine(file, "; hard path");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"origin\" \"0 0 0\"");
		WriteFileLine(file, "	\"targetname\" \"relay_hard_route_spawn\"");
		WriteFileLine(file, "	\"spawnflags\" \"0\"");
		WriteFileLine(file, "	\"classname\" \"logic_relay\"");
		WriteFileLine(file, "	\"OnTrigger\" \"hard_route_blockerEnable0-1\"");
		WriteFileLine(file, "	\"OnTrigger\" \"hard_route_blockerEnableCollision0-1\"");
		WriteFileLine(file, "}");
		WriteFileLine(file, "");
	}
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrContains(classname, "prop_dynamic") >= 0 || StrContains(classname, "prop_physics") >= 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
				vecAngles = g_vecEntityAngles[i];
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				iOrigin[0] = RoundToFloor(vecOrigin[0]);
				iOrigin[1] = RoundToFloor(vecOrigin[1]);
				iOrigin[2] = RoundToFloor(vecOrigin[2]);
				
				iAngles[0] = RoundToFloor(vecAngles[0]);
				iAngles[1] = RoundToFloor(vecAngles[1]);
				iAngles[2] = RoundToFloor(vecAngles[2]);
				WriteFileLine(file, "{");
				if(StrContains(classname, "physics") < 0)
				{
					if(g_bUnsolid[i])
					{
						WriteFileLine(file, "	\"solid\" \"0\"");
					}
					else
					{
						WriteFileLine(file, "	\"solid\" \"6\"");
					}
				}
				WriteFileLine(file, "	\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
				WriteFileLine(file, "	\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
				WriteFileLine(file, "	\"model\"	 \"%s\"", sModel);
				WriteFileLine(file, "	\"targetname\" \"%s\"", targetname);
				WriteFileLine(file, "	\"classname\"	\"%s\"", classname);
				WriteFileLine(file, "}");
				WriteFileLine(file, "");
			}
		}
	}
	FlushFile(file);
	CloseHandle(file);
	PrintToChat(client, "\x03[SM] Succesfully saved the map data (%s)", FileName);
}

stock SavePluginProps(client)
{
	LogSpawn("%N saved the objects for this map on a \"Plugin Cache\" file format", client);
	PrintToChat(client, "\x04[SM] Saving the content. Please Wait");
	decl String:FileName[256], String:map[256], String:classname[256], String:FileNameS[256], String:FileNameT[256];
	new Handle:file = INVALID_HANDLE;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileNameS, sizeof(FileNameS), "data/maps/plugin_cache/%s", map);
	Format(FileName, sizeof(FileName), "%s_1.txt", FileNameS);
	new map_number = 0;
	if(FileExists(FileName))
	{
		map_number = GetNextMapNumber(FileNameS);
		if(map_number <= 0)
		{
			PrintToChat(client, "\x04[SM] Fatal Error: Too Many path files for this map! (Max: %i)", MAX_PATHS);
			return;
		}
		Format(FileNameT, sizeof(FileNameT), "%s_%i.txt", FileNameS, map_number);
	}
	else
	{
		Format(FileNameT, sizeof(FileNameT), "%s_1.txt", FileNameS);
	}
	file = OpenFile(FileNameT, "a+");
	if(file == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Failed to create or overwrite the map file");
		PrintToChat(client, "\x04[SM] Something was probably missing during installation");
		PrintHintText(client, "[SM] Probably missing sourcemod/data/maps/plugin_cache folder");
		PrintToConsole(client, "[SM] Unable to open, write, or find the file!");
		PrintCenterText(client, "[SM] FAILURE");
		return;
	}
	CreateInitFile();
	decl Float:vecOrigin[3], Float:vecAngles[3], String:sModel[256], String:sTime[256];
	new iOrigin[3], iAngles[3];
	new count = 0;
	FormatTime(sTime, sizeof(sTime), "%Y/%m/%d");
	WriteFileLine(file, "//----------FILE MODIFICATION (YY/MM/DD): [%s] ---------------||", sTime);
	WriteFileLine(file, "//----------BY: %N----------------------||", client);
	WriteFileLine(file, "");
	WriteFileLine(file, "\"Objects_Cache\"");
	WriteFileLine(file, "{");
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrContains(classname, "prop_dynamic") >= 0 || StrContains(classname, "prop_physics") >= 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
				vecAngles = g_vecEntityAngles[i];
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				iOrigin[0] = RoundToFloor(vecOrigin[0]);
				iOrigin[1] = RoundToFloor(vecOrigin[1]);
				iOrigin[2] = RoundToFloor(vecOrigin[2]);
				
				iAngles[0] = RoundToFloor(vecAngles[0]);
				iAngles[1] = RoundToFloor(vecAngles[1]);
				iAngles[2] = RoundToFloor(vecAngles[2]);
				count++;
				
				WriteFileLine(file, "	\"object_%i\"", count);
				WriteFileLine(file, "	{");
				if(StrContains(classname, "physics") < 0)
				{
					if(g_bUnsolid[i])
					{
						WriteFileLine(file, "		\"solid\" \"0\"");
					}
					else
					{
						WriteFileLine(file, "		\"solid\" \"6\"");
					}
				}
				WriteFileLine(file, "		\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
				WriteFileLine(file, "		\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
				WriteFileLine(file, "		\"model\"	 \"%s\"", sModel);
				WriteFileLine(file, "		\"classname\"	\"%s\"", classname);
				WriteFileLine(file, "	}");
				WriteFileLine(file, "	");
			}
		}
	}
	WriteFileLine(file, "	\"total_cache\"");
	WriteFileLine(file, "	{");
	WriteFileLine(file, "		\"total\" \"%i\"", count);
	WriteFileLine(file, "	}");
	WriteFileLine(file, "}");
	
	FlushFile(file);
	CloseHandle(file);
	PrintToChat(client, "\x03[SM] Succesfully saved the map data (%s)", FileNameT);
}

public Action:CmdLoad(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Specify a map number");
	}
	decl String:arg[5];
	GetCmdArgString(arg, sizeof(arg));
	new number = StringToInt(arg);
	LoadPluginProps(client, number);
	return Plugin_Handled;
}

stock LoadPluginProps(client, number)
{
	LogSpawn("%N loaded the objects for this map", client);
	PrintToChat(client, "\x04[SM] Loading content. Please Wait");
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256], String:map[256], String:name[256];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/maps/plugin_cache/%s_%i.txt", map, number);
	if(!FileExists(KvFileName))
	{
		PrintToChat(client, "\x04[SM] The file does not exist");
		PrintHintText(client, "\x04[SM] The file does not exist");
		return;
	}
	keyvalues = CreateKeyValues("Objects_Cache");
	FileToKeyValues(keyvalues, KvFileName);
	KvRewind(keyvalues);
	if(KvJumpToKey(keyvalues, "total_cache"))
	{
		new max = KvGetNum(keyvalues, "total", 0);
		if(max <= 0)
		{
			PrintToChat(client, "\x04[SM] No objects found in the cache");
			return;
		}
		decl String:model[256], String:class[64], Float:vecOrigin[3], Float:vecAngles[3];
		new solid;
		KvRewind(keyvalues);
		for(new count=1; count <= max; count++)
		{
			Format(name, sizeof(name), "object_%i", count);
			if(KvJumpToKey(keyvalues, name))
			{
				solid = KvGetNum(keyvalues, "solid");
				KvGetVector(keyvalues, "origin", vecOrigin);
				KvGetVector(keyvalues, "angles", vecAngles);
				KvGetString(keyvalues, "model", model, sizeof(model));
				KvGetString(keyvalues, "classname", class, sizeof(class));
				new prop = -1;
				KvRewind(keyvalues);
				if(StrContains(class, "prop_physics") >= 0)
				{
					prop = CreateEntityByName("prop_physics_override");
				}
				else
				{
					prop = CreateEntityByName("prop_dynamic_override");
					SetEntProp(prop, Prop_Send, "m_nSolidType", solid);
				}
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				
				g_vecLastEntityAngles[client][0] = vecAngles[0];
				g_vecLastEntityAngles[client][1] = vecAngles[1];
				g_vecLastEntityAngles[client][2] = vecAngles[2];
				DispatchKeyValueVector(prop, "angles", vecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = vecAngles;				
			}
			else
			{
				break;
			}
		}
	}
	CloseHandle(keyvalues);
	PrintToChat(client, "\x03[SM] Succesfully loaded the map data");
	PrintHintText(client, "[SM] If nothing is visible, you probably forgot something during installation");
}

public Action:CmdRotate(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_rotate <axys> <angles> [EX: !prop_rotate x 30]");
		return Plugin_Handled;
	}
	new Object = g_iLastObject[client];
	decl String:arg1[16], String:arg2[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl Float:vecAngles[3];
	vecAngles[0] = g_vecLastEntityAngles[client][0];
	vecAngles[1] = g_vecLastEntityAngles[client][1];
	vecAngles[2] = g_vecLastEntityAngles[client][2];
	new iAngles = StringToInt(arg2);
	if(StrEqual(arg1, "x"))
	{
		vecAngles[0] += iAngles;
	}
	else if(StrEqual(arg1, "y"))
	{
		vecAngles[1] += iAngles;
	}
	else if(StrEqual(arg1, "z"))
	{
		vecAngles[2] += iAngles;
	}
	else
	{
		PrintToChat(client, "[SM] Invalid Axys (x,y,z are allowed)");
	}
	g_vecLastEntityAngles[client] = vecAngles;
	TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
	g_vecEntityAngles[g_iLastObject[client]] = vecAngles;
	return Plugin_Handled;
}

public Action:CmdRemoveLast(client, args)
{
	DeleteLastProp(client);
	return Plugin_Handled;
}

public Action:CmdRemoveLook(client, args)
{
	DeleteLookingEntity(client);
	return Plugin_Handled;
}

public Action:CmdRemoveAll(client, args)
{
	PrintToChat(client, "\x04[SM] Are you sure that you want to delete all objects?");
	BuildDeleteAllCmd(client);
	return Plugin_Handled;
}

stock BuildDeleteAllCmd(client)
{
	new Handle:menu = CreateMenu(MenuHandler_cmd_Ask);
	SetMenuTitle(menu, "Are you sure?");
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "sm_spyes", "Yes");
	AddMenuItem(menu, "sm_spno", "No");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_cmd_Ask(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "sm_spyes"))
			{
				DeleteAllProps();
				PrintToChat(param1, "[SM] Successfully deleted all spawned objects");
			}
			else
			{
				PrintToChat(param1, "[SM] Canceled");
			}
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock GetNextMapNumber(String:FileName[])
{
	decl String:FileNameS[256];
	for(new i=1; i <= MAX_PATHS; i++)
	{
		Format(FileNameS, sizeof(FileNameS), "%s_%i.txt", FileName, i);
		if(FileExists(FileNameS))
		{
			continue;
		}
		else
		{
			return i;
		}
	}
	return -1;
}

stock SpawnObjects()
{
	//if disabled
	if(!GetConVarBool(g_cvarAutoload))
	{
		return;
	}
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256], String:name[256];
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/maps/plugin_cache/%s.txt", g_sPath);
	LogSpawn("Spawning props from file %s", KvFileName);
	if(!FileExists(KvFileName))
	{
		LogError("Attempted to load an object file which does not exist (%s)", KvFileName);
		LogSpawn("[ERROR] Attempted to load an object file which does not exist (%s)", KvFileName);
		return;
	}
	keyvalues = CreateKeyValues("Objects_Cache");
	FileToKeyValues(keyvalues, KvFileName);
	KvRewind(keyvalues);
	if(KvJumpToKey(keyvalues, "total_cache"))
	{
		new max = KvGetNum(keyvalues, "total", 0);
		if(max <= 0)
		{
			LogError("No Objects found for the map number cache");
			LogSpawn("[ERROR] No Objects found for the map number cache");
			return;
		}
		decl String:model[256], String:class[64], Float:vecOrigin[3], Float:vecAngles[3];
		new solid;
		KvRewind(keyvalues);
		for(new count=1; count <= max; count++)
		{
			Format(name, sizeof(name), "object_%i", count);
			if(KvJumpToKey(keyvalues, name))
			{
				solid = KvGetNum(keyvalues, "solid");
				KvGetVector(keyvalues, "origin", vecOrigin);
				KvGetVector(keyvalues, "angles", vecAngles);
				KvGetString(keyvalues, "model", model, sizeof(model));
				KvGetString(keyvalues, "classname", class, sizeof(class));
				new prop = -1;
				KvRewind(keyvalues);
				if(StrContains(class, "prop_physics") >= 0)
				{
					prop = CreateEntityByName("prop_physics_override");
				}
				else
				{
					prop = CreateEntityByName("prop_dynamic_override");
					SetEntProp(prop, Prop_Send, "m_nSolidType", solid);
				}
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				
				DispatchKeyValueVector(prop, "angles", vecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				g_vecEntityAngles[prop] = vecAngles;				
			}
			else
			{
				break;
			}
		}
	}
	CloseHandle(keyvalues);
}
stock CreateInitFile()
{
	decl String:FileName[256], String:map[256];
	new Handle:file = INVALID_HANDLE;
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/maps/plugin_cache/%s_init.txt", map);
	
	if(!FileExists(FileName))
	{
		file = OpenFile(FileName, "a+");
		if(file == INVALID_HANDLE)
		{
			return;
		}
		WriteFileLine(file, "//Init file for map %s", map);
		WriteFileLine(file, "//DO NOT FORGET TO REPLACE \" FOR QUOTES!");
		WriteFileLine(file, "//");
		WriteFileLine(file, "//The format of the file is:");
		WriteFileLine(file, "//");
		WriteFileLine(file, "//	\"coop\" --------> This is the gamemode where the following object list will be loaded");
		WriteFileLine(file, "//	{");
		WriteFileLine(file, "//		\"total\"	\"2\" ---------> This is the total object list availables. Randomly, one will be selected");
		WriteFileLine(file, "//		\"path1\"	\"c5m2_park_1\" -------------> If the plugin chooses the option 1, the file c5m2_park_1.txt will be loaded");
		WriteFileLine(file, "//		\"path2\"	\"c5m2_park_3\" -------------> Same if the option is 2");
		WriteFileLine(file, "//	}");
		WriteFileLine(file, "//");
		WriteFileLine(file, "// If you have any doubts, please check the example_init.txt file or ask on the plugin topic.");
		WriteFileLine(file, "//");
		WriteFileLine(file, "");
		WriteFileLine(file, "\"PathInit\"");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"coop\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"versus\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"survival\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"scavenge\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "}");
		FlushFile(file);
		CloseHandle(file);
	}
}

stock GetRandomMapPath(String:MapName[], maxlen)
{
	decl String:KvFileName[256], String:sMap[128], String:GameMode[128];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/maps/plugin_cache/%s_init.txt", sMap);
	if(!FileExists(KvFileName))
	{
		LogError("Unable to find the init file!");
	}
	else
	{
		new Handle:keyvalues = INVALID_HANDLE;
		keyvalues = CreateKeyValues("PathInit");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		new Handle:cvarGameMode = FindConVar("mp_gamemode");
		GetConVarString(cvarGameMode, GameMode, sizeof(GameMode));
		if(KvJumpToKey(keyvalues, GameMode))
		{
			decl String:sNumber[11];
			new total_paths = KvGetNum(keyvalues, "total");
			new random = GetRandomInt(1, total_paths);
			Format(sNumber, sizeof(sNumber), "path%i", random);
			KvGetString(keyvalues, sNumber, MapName, maxlen);
			CloseHandle(keyvalues);
			return;
		}
		else
		{
			LogError("Unable to find the gamemode");
			Format(MapName, maxlen, "invalid");
			CloseHandle(keyvalues);
			return;
		}
		
	}
	Format(MapName, maxlen, "invalid");
	return;
}

public Action:CmdMove(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_move <axys> <distance> [EX: !prop_move x 30]");
		return Plugin_Handled;
	}
	new Object = g_iLastObject[client];
	decl String:arg1[16], String:arg2[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl Float:vecPosition[3];
	GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecPosition);
	new Float:flPosition = StringToFloat(arg2);
	if(StrEqual(arg1, "x"))
	{
		vecPosition[0] += flPosition;
	}
	else if(StrEqual(arg1, "y"))
	{
		vecPosition[1] += flPosition;
	}
	else if(StrEqual(arg1, "z"))
	{
		vecPosition[2] += flPosition;
	}
	else
	{
		PrintToChat(client, "[SM] Invalid Axys (x,y,z are allowed)");
	}
	g_bGrab[client] = false;
	g_bGrabbed[Object] = false;
	TeleportEntity(Object, vecPosition, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

public Action:CmdSetAngles(client, args)
{
	if(args < 3)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_setang <X Y Z> [EX: !prop_setang 30 0 34");
		return Plugin_Handled;
	}
	new Object = g_iLastObject[client];
	decl String:arg1[16], String:arg2[16], String:arg3[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	decl Float:vecAngles[3];
	
	vecAngles[0] = StringToFloat(arg1);
	vecAngles[1] = StringToFloat(arg2);
	vecAngles[2] = StringToFloat(arg3);
	g_vecLastEntityAngles[client] = vecAngles;
	g_vecEntityAngles[Object] = vecAngles;
	
	g_bGrab[client] = false;
	g_bGrabbed[Object] = false;
	TeleportEntity(Object, NULL_VECTOR, vecAngles, NULL_VECTOR);
	return Plugin_Handled;
}

public Action:CmdSetPosition(client, args)
{
	if(args < 3)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_setpos <X Y Z> [EX: !prop_setpos 505 -34 17");
		return Plugin_Handled;
	}
	new Object = g_iLastObject[client];
	decl String:arg1[16], String:arg2[16], String:arg3[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	decl Float:vecPosition[3];
	
	vecPosition[0] = StringToFloat(arg1);
	vecPosition[1] = StringToFloat(arg2);
	vecPosition[2] = StringToFloat(arg3);
	TeleportEntity(Object, vecPosition, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

public Action:CmdGrab(client, args)
{
	if(!g_bGrab[client])
	{
		GrabObject(client);
	}
	else
	{
		ReleaseObject(client);
	}
	return Plugin_Handled;
}

public Action:CmdGrabLook(client, args)
{
	if(!g_bGrab[client])
	{
		GrabLookingObject(client);
	}
	else
	{
		ReleaseLookingObject(client);
	}
	return Plugin_Handled;
}

stock GrabObject(client)
{
	new Object = g_iLastObject[client];
	if(g_bGrab[client])
	{
		PrintToChat(client, "[SM] You are already grabbing the Object");
		return;
	}
	else if(g_bGrabbed[Object])
	{
		PrintToChat(client, "[SM] The last object is already moving");
		return;
	}
	if(Object > 0 && IsValidEntity(Object))
	{
		decl String:class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(StrEqual(class, "prop_physics")
		|| StrEqual(class, "prop_dynamic")
		|| StrEqual(class, "prop_physics_override")
		|| StrEqual(class, "prop_dynamic_override"))
		{
			g_bGrab[client] = true;
			g_bGrabbed[Object] = true;
			PrintToChat(client, "[SM] You are now grabbing an object");
			
			decl String:sName[64], String:sObjectName[64];
			new userid = GetClientUserId(client);
			Format(sName, sizeof(sName), "%d", userid+25);
			Format(sObjectName, sizeof(sObjectName), "%d", Object+100);
			DispatchKeyValue(Object, "targetname", sObjectName);
			DispatchKeyValue(client, "targetname", sName);
			GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
			DispatchKeyValue(Object, "parentname", sName);
			SetVariantString(sName);
			AcceptEntityInput(Object, "SetParent", Object, Object);
			SetEntityRenderColor(Object, 189, 9 , 13, 100);
			return;
		}
		else
		{
			PrintToChat(client, "[SM] The last spawned object index %i is not an object anymore!", Object);
			g_bGrabbed[Object] = false;
			g_iLastObject[client] = -1;
			g_vecLastEntityAngles[client][0] = 0.0;
			g_vecLastEntityAngles[client][1] = 0.0;
			g_vecLastEntityAngles[client][2] = 0.0;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_bGrab[client] = false;
		}
	}
	else if(Object > 0 && !IsValidEntity(Object))
	{
		PrintToChat(client, "[SM] The last object is not valid anymore");
	}
	else if(Object <= 0)
	{
		PrintToChat(client, "[SM] You haven't spawned anything yet");
	}
}

stock ReleaseObject(client)
{
	new Object = g_iLastObject[client];
	if(Object > 0 && IsValidEntity(Object))
	{
		decl String:class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(StrEqual(class, "prop_physics")
		|| StrEqual(class, "prop_dynamic")
		|| StrEqual(class, "prop_physics_override")
		|| StrEqual(class, "prop_dynamic_override"))
		{
			g_bGrab[client] = false;
			g_bGrabbed[Object] = false;
			PrintToChat(client, "[SM] You are no longer grabbing an object");
			DispatchKeyValue(Object, "targetname", "l4d2_spawn_props_prop");
			DispatchKeyValue(Object, "parentname", "NULL_PARENT");
			SetEntityRenderColor(Object, 255, 255 ,255, 255);
			AcceptEntityInput(Object, "SetParent");
			
			//Set client angles
			decl Float:vecAngles[3];
			GetClientEyeAngles(client, vecAngles);
			g_vecLastEntityAngles[client][0] = vecAngles[0];
			g_vecLastEntityAngles[client][1] = vecAngles[1];
			g_vecLastEntityAngles[client][2] = vecAngles[2];
			g_vecEntityAngles[Object][0] = vecAngles[0];
			g_vecEntityAngles[Object][1] = vecAngles[1];
			g_vecEntityAngles[Object][2] = vecAngles[2];
			return;
		}
		else
		{
			PrintToChat(client, "[SM] The last spawned object index %i is not an object anymore!", Object);
			g_bGrabbed[Object] = false;
			g_iLastObject[client] = -1;
			g_vecLastEntityAngles[client][0] = 0.0;
			g_vecLastEntityAngles[client][1] = 0.0;
			g_vecLastEntityAngles[client][2] = 0.0;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_bGrab[client] = false;
		}
	}
	else if(Object > 0 && !IsValidEntity(Object))
	{
		PrintToChat(client, "[SM] The last object is not valid anymore");
	}
	else if(Object <= 0)
	{
		PrintToChat(client, "[SM] You haven't spawned anything yet");
	}
}

stock GrabLookingObject(client)
{
	new Object = GetLookingObject(client);
	if(Object >= ARRAY_SIZE)
	{
		PrintToChat(client, "[SM] No valid object found");
		return;
	}
	if(g_bGrab[client])
	{
		PrintToChat(client, "[SM] You are already grabbing the Object");
		return;
	}
	if(Object > 0 && IsValidEntity(Object))
	{
		decl String:class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(StrEqual(class, "prop_physics")
		|| StrEqual(class, "prop_dynamic")
		|| StrEqual(class, "prop_physics_override")
		|| StrEqual(class, "prop_dynamic_override"))
		{
			g_bGrab[client] = true;
			g_bGrabbed[Object] = true;
			g_iLastGrabbedObject[client] = Object;
			PrintToChat(client, "[SM] You are now grabbing an object");
			
			decl String:sName[64], String:sObjectName[64];
			new userid = GetClientUserId(client);
			Format(sName, sizeof(sName), "%d", userid+25);
			Format(sObjectName, sizeof(sObjectName), "%d", Object+100);
			DispatchKeyValue(Object, "targetname", sObjectName);
			DispatchKeyValue(client, "targetname", sName);
			GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
			DispatchKeyValue(Object, "parentname", sName);
			SetVariantString(sName);
			AcceptEntityInput(Object, "SetParent", Object, Object);
			SetEntityRenderColor(Object, 189, 9 , 13, 100);
			return;
		}
		else
		{
			PrintToChat(client, "[SM] The last spawned object index %i is not an object", Object);
			g_bGrabbed[Object] = false;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_bGrab[client] = false;
		}
	}
	else if(Object > 0 && !IsValidEntity(Object))
	{
		PrintToChat(client, "[SM] The last object is not valid anymore");
	}
	else if(Object <= 0)
	{
		PrintToChat(client, "[SM] You haven't spawned anything yet");
	}
}

stock ReleaseLookingObject(client)
{
	new Object = g_iLastGrabbedObject[client];
	if(Object > 0 && IsValidEntity(Object))
	{
		decl String:class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(StrEqual(class, "prop_physics")
		|| StrEqual(class, "prop_dynamic")
		|| StrEqual(class, "prop_physics_override")
		|| StrEqual(class, "prop_dynamic_override"))
		{
			g_bGrab[client] = false;
			g_bGrabbed[Object] = false;
			PrintToChat(client, "[SM] You are no longer grabbing an object");
			DispatchKeyValue(Object, "targetname", "l4d2_spawn_props_prop");
			DispatchKeyValue(Object, "parentname", "NULL_PARENT");
			SetEntityRenderColor(Object, 255, 255 ,255, 255);
			AcceptEntityInput(Object, "SetParent");
			
			//Set client angles
			decl Float:vecAngles[3];
			GetClientEyeAngles(client, vecAngles);
			g_vecEntityAngles[Object][0] = vecAngles[0];
			g_vecEntityAngles[Object][1] = vecAngles[1];
			g_vecEntityAngles[Object][2] = vecAngles[2];
			return;
		}
		else
		{
			PrintToChat(client, "[SM] The last spawned object index %i is not an object anymore!", Object);
			g_bGrabbed[Object] = false;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_bGrab[client] = false;
		}
	}
	else if(Object > 0 && !IsValidEntity(Object))
	{
		PrintToChat(client, "[SM] The last object is not valid anymore");
	}
	else if(Object <= 0)
	{
		PrintToChat(client, "[SM] You haven't spawned anything yet");
	}
}

stock GetLookingObject(client)
{
	decl Float:VecOrigin[3], Float:VecAngles[3];
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(INVALID_HANDLE))
	{
		new Object = TR_GetEntityIndex(INVALID_HANDLE);
		if(Object > 0 && IsValidEntity(Object) && IsValidEdict(Object))
		{
			decl String:class[256];
			GetEdictClassname(Object, class, sizeof(class));
			if(StrEqual(class, "prop_physics")
			|| StrEqual(class, "prop_dynamic")
			|| StrEqual(class, "prop_physics_override")
			|| StrEqual(class, "prop_dynamic_override"))
			{
				return Object;
			}
		}
	}
	return -1;
}