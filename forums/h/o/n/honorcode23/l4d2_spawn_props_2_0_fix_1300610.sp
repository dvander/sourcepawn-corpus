#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#pragma semicolon 2

#define GETVERSION "2.0.0a"
new Handle:hAdminMenu = INVALID_HANDLE;
new g_iCategory[MAXPLAYERS+1] = 0;
new g_iSubCategory[MAXPLAYERS+1] = 0;
new g_iFileCategory[MAXPLAYERS+1] = 0;

new Handle:g_cvarPhysics = INVALID_HANDLE;
new Handle:g_cvarDynamic = INVALID_HANDLE;
new Handle:g_cvarStatic = INVALID_HANDLE;
new Handle:g_cvarVehicles = INVALID_HANDLE;
new Handle:g_cvarFoliage = INVALID_HANDLE;
new Handle:g_cvarInterior = INVALID_HANDLE;
new Handle:g_cvarExterior = INVALID_HANDLE;
new Handle:g_cvarDecorative = INVALID_HANDLE;
new Handle:g_cvarMisc = INVALID_HANDLE;

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
	RegAdminCmd("sm_spawnprop", CmdSpawnProp, ADMFLAG_SLAY, "Spawns an object with the given information");
	
	AutoExecConfig(true, "l4d2_spawn_props_2_0");
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	else
	{
		LogError("Unable to fin the adminmenu Library. The category wont appear on the menu");
	}
}

public OnMapStart()
{
	ServerCommand("sm plugins unload l4d2_spawn_props");
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
	GetCmdArg(1, arg2, sizeof(arg2));
	GetCmdArg(1, arg3, sizeof(arg3));
	decl String:model[256];
	strcopy(model, sizeof(model), arg1);
	if(!IsModelPrecached(model))
	{
		if(PrecacheModel(model) <= 0)
		{
			PrintToChat(client, "There was a problem spawning the selected model [ERROR: Invalid Model]");
			return Plugin_Handled;
		}
	}
	if(StrEqual(arg2, "static"))
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
				PrintToChat(client, "Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(StrEqual(arg3, "origin"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	else if(StrEqual(arg2, "dynamic"))
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
				PrintToChat(client, "Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(StrEqual(arg3, "origin"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	else if(StrEqual(arg2, "physics"))
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
				PrintToChat(client, "Vector out of world geometry. Spawning on current position instead");
			}
		}
		else if(StrEqual(arg3, "origin"))
		{
			GetClientEyePosition(client, VecOrigin);
			GetClientEyeAngles(client, VecAngles);
		}
		else
		{
			PrintToChat(client, "Invalid spawn method specified. Use: [cursor | origin]");
			return Plugin_Handled;
		}
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		PrintToChat(client, "Invalid render mode. Use: [static | dynamic | physics]");
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
	//new TopMenuObject:menu_category_part = AddToTopMenu(hAdminMenu, "sm_spawn_props_cat", TopMenuObject_Category, Category_Handler, INVALID_TOPMENUOBJECT);
	if(g_cvarPhysics)
	{
		AddToTopMenu(hAdminMenu, "sm_physicscursor", TopMenuObject_Item, AdminMenu_PhysicsCursor, menu_category_prop, "sm_physicscursor", ADMFLAG_SLAY); //On Cursor Position Phy
		AddToTopMenu(hAdminMenu, "sm_physicsposition", TopMenuObject_Item, AdminMenu_PhysicsPosition, menu_category_prop, "sm_physicsposition", ADMFLAG_SLAY); //On Position Phy
	}
	
	if(g_cvarDynamic)
	{
		AddToTopMenu(hAdminMenu, "sm_dynamiccursor", TopMenuObject_Item, AdminMenu_DynamicCursor, menu_category_prop, "sm_dynamiccursor", ADMFLAG_SLAY); //On Cursor Position Dyn
		AddToTopMenu(hAdminMenu, "sm_dynamicposition", TopMenuObject_Item, AdminMenu_DynamicPosition, menu_category_prop, "sm_dynamicposition", ADMFLAG_SLAY); //On Position Dyn
	}
	
	if(g_cvarStatic)
	{
		AddToTopMenu(hAdminMenu, "sm_staticcursor", TopMenuObject_Item, AdminMenu_StaticCursor, menu_category_prop, "sm_staticcursor", ADMFLAG_SLAY); //On Position Sta
		AddToTopMenu(hAdminMenu, "sm_staticposition", TopMenuObject_Item, AdminMenu_StaticPosition, menu_category_prop, "sm_staticposition", ADMFLAG_SLAY); //On Position Sta
	}
	
	AddToTopMenu(hAdminMenu, "sm_deleteprop", TopMenuObject_Item, AdminMenu_DeleteProp, menu_category_prop, "sm_deleteprop", ADMFLAG_SLAY); //Delete prop
	AddToTopMenu(hAdminMenu, "sm_deleteallprops", TopMenuObject_Item, AdminMenu_DeleteAllProps, menu_category_prop, "sm_deleteallprops", ADMFLAG_SLAY); //DeleteAllProps
}

//Admin Category Name
public Category_Handler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Select The Object Type");
	}
	else if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Objects");
	}
}

//CATEGORIES HANDLERS
public AdminMenu_PhysicsCursor(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Physics On Cursor");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildPhysicsCursorMenu(param);
	}
}

public AdminMenu_PhysicsPosition(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Physics On Origin");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildPhysicsPositionMenu(param);
	}
}

public AdminMenu_DynamicCursor(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Non-solid Static On Cursor");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildDynamicCursorMenu(param);
	}
}

public AdminMenu_DynamicPosition(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Non-solid Static On Origin");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildDynamicPositionMenu(param);
	}
}

public AdminMenu_StaticCursor(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Solid Static On Cursor");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildStaticCursorMenu(param);
	}
}

public AdminMenu_StaticPosition(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Solid Static On Origin");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		BuildStaticPositionMenu(param);
	}
}

public AdminMenu_DeleteProp(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Delete Object");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		DeleteLookingEntity(param);
		DisplayTopMenu(hAdminMenu, param, TopMenuPosition_LastCategory);
	}
}

public AdminMenu_DeleteAllProps(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Delete All Objects");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		DeleteAllProps();
		if(param > 0 )
		{
			PrintToChat(param, "[SM] Deleted all custom objects");
		}
		DisplayTopMenu(hAdminMenu, param, TopMenuPosition_LastCategory);
	}
}

//BUILDMENUS
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
	SetMenuTitle(menu, "Interior");
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
					PrintToChat(param1, "Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
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
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
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
					PrintToChat(param1, "Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
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
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
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
					PrintToChat(param1, "Vector out of world geometry. Spawning on current position instead");
				}
				VecAngles[0] = 0.0;
				VecAngles[2] = 0.0;
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
			}
			else if(g_iCategory[param1] == 4)
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
				DispatchKeyValueVector(prop, "angles", VecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
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
	GetClientAbsOrigin(client, VecOrigin);
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
				AcceptEntityInput(Object, "Kill");
				PrintToChat(client, "Succesfully removed an object");
				return;
			}
		}
	}
	else
	{
		new Object = GetClientAimTarget(client, false);
		if(Object == -2)
		{
			PrintToChat(client, "This plugin won't work in this game");
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
				AcceptEntityInput(Object, "Kill");
				PrintToChat(client, "Succesfully removed an object");
				return;
			}
		}
	}
	PrintToChat(client, "You are not looking to a valid object");
}

stock DeleteAllProps()
{
	CheatCommand(_, "ent_fire", "l4d2_spawn_props_prop kill");
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
#if 0
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
			AcceptEntityInput(g_iLastObject[client], "Kill"));
			PrintToChat(client, "Succesfully deleted the last spawned object");
			return;
		}
		else
		{
			PrintToChat(client, "The last spawned object index %i is not an object anymore!", Object);
			g_iLastObject[client] = -1;
		}
	}
	else if(Object > 0 && !IsValidEntity(Object))
	{
		PrintToChat(client, "The last object is not valid anymore");
	}
	else if(Object <= 0)
	{
		PrintToChat(client, "You haven't spawn any object yet");
	}
}
#endif