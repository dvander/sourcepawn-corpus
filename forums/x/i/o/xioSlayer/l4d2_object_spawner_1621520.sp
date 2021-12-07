#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <strings>
#pragma semicolon 2
#define DEBUG 0

#define ARRAY_SIZE 5000
#define MAX_PATHS 20

#define DESIRED_ADM_FLAGS ADMFLAG_SLAY 	//Edit here the flags to fit your needs!
#define MAX_DESPAWN_RANGE 10			// Despawner must be within this radius of the object's origin to despawn it.

#define MELEE_FIREAXE "fireaxe"
#define MELEE_FRYING_PAN "frying_pan"
#define MELEE_MACHETE "machete"
#define MELEE_BASEBALL_BAT "baseball_bat"
#define MELEE_CROWBAR "crowbar"
#define MELEE_CRICKET_BAT "cricket_bat"
#define MELEE_TONFA "tonfa"
#define MELEE_KATANA "katana"
#define MELEE_GUITAR "electric_guitar"
#define MELEE_KNIFE "knife"

new Handle:AssaultMaxAmmo = INVALID_HANDLE;
new Handle:SMGMaxAmmo = INVALID_HANDLE;
new Handle:ShotgunMaxAmmo = INVALID_HANDLE;
new Handle:AutoShotgunMaxAmmo = INVALID_HANDLE;
new Handle:HRMaxAmmo = INVALID_HANDLE;
new Handle:SniperRifleMaxAmmo = INVALID_HANDLE;
new Handle:GrenadeLauncherMaxAmmo = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;
new g_iCategory[MAXPLAYERS+1] = 0;
new g_iSubCategory[MAXPLAYERS+1] = 0;
new g_iFileCategory[MAXPLAYERS+1] = 0;
new g_iMoveCategory[MAXPLAYERS+1] = 0;
new Float:g_vecLastEntityAngles[MAXPLAYERS+1][3];
new g_iLastObject[MAXPLAYERS+1] = -1;
new g_iLastGrabbedObject[MAXPLAYERS+1] = -1;

new bool:g_bSpawned[ARRAY_SIZE] = false;
new bool:g_bDespawned[500] = false;
new bool:g_bLight[ARRAY_SIZE] = false;
new Float:g_fDespawned[500][3];
new bool:g_bGrabbed[ARRAY_SIZE] = false;
new bool:g_bGrab[MAXPLAYERS+1] = false;
new Float:g_vecEntityAngles[ARRAY_SIZE][3];
new Float:g_vecEntityOrigin[ARRAY_SIZE][3];
new bool:g_bUnsolid[ARRAY_SIZE] = false;
new bool:g_bItem[ARRAY_SIZE] = false;
new g_iAmmo[ARRAY_SIZE] = 0;
new bool:g_bLoaded = false;
new String:g_sPath[128];

new Handle:g_cvarDisplayPropCount = INVALID_HANDLE;
new Handle:g_cvarLogPlugin = INVALID_HANDLE;
new Handle:g_cvarLogActions = INVALID_HANDLE;
new Handle:g_cvarAutoload = INVALID_HANDLE;
new Handle:g_cvarAutoloadType = INVALID_HANDLE;

new Handle:g_hGameMode;
new Handle:g_checkTimer = INVALID_HANDLE;
new Handle:g_spawnTimer = INVALID_HANDLE;

new bool:xioDebug = true;
new propCount = 0;

public Plugin:myinfo = 
{
	name = "[L4D2] Object Spawner",
	author = "honorcode23, xio",
	description = "Spawn props/weapons/items and save them to the map.",
	version = "2.1.1",
	url = "http://forums.alliedmods.net/showthread.php?p=1186503"
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("[L4D2] Object Spawner supports Left 4 dead 2 only!");
	}

	CreateConVar("l4d2_object_spawner_version", "2.1.1", "Version of the Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarDisplayPropCount = CreateConVar("l4d2_object_spawner_show_count", "0", "Print total object count to all (chat) on every object spawn", FCVAR_PLUGIN);
	g_cvarAutoload = CreateConVar("l4d2_object_spawner_autoload", "1", "Enable the plugin to auto load the cache", FCVAR_PLUGIN);
	g_cvarAutoloadType = CreateConVar("l4d2_object_spawner_autoload_different", "0", "Teams in competitive modes play different paths", FCVAR_PLUGIN);
	g_cvarLogActions = CreateConVar("l4d2_object_spawner_log_actions", "1", "Log admin spawns", FCVAR_PLUGIN);
	g_cvarLogPlugin = CreateConVar("l4d2_object_spawner_log_plugin", "1", "Log plugin information (debug)", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_props", CmdPropz, DESIRED_ADM_FLAGS, "Displays total object count and type info (if available) in the chat");
	RegAdminCmd("sm_spawnprop", CmdSpawnProp, DESIRED_ADM_FLAGS, "Spawns a prop with the given information");
	RegAdminCmd("sm_spawnitem", CmdSpawnItem, DESIRED_ADM_FLAGS, "Spawns an item with the item name");
	RegAdminCmd("sm_spawnlight", CmdSpawnLight, DESIRED_ADM_FLAGS, "Spawns a work light ");
	RegAdminCmd("sm_spawnfe", CmdSpawnFireEscape, DESIRED_ADM_FLAGS, "Spawns a fire escape with the specified amount of levels");
	RegAdminCmd("sm_spawntruck", CmdSpawnTruck, DESIRED_ADM_FLAGS, "Spawns a delivery truck with glass pre-attached");
	RegAdminCmd("sm_spawnspawn", CmdSpawnSpawn, DESIRED_ADM_FLAGS, "Spawns a 'spawn' with the given type and count");
	RegAdminCmd("sm_despawn", CmdKillLook, DESIRED_ADM_FLAGS, "Despawns a map object and can be saved to round start");
	RegAdminCmd("sm_despawn_clear", CmdClearKills, DESIRED_ADM_FLAGS, "Delete all despawns in the map (in case you need them removed)");
	
	RegAdminCmd("sm_prop_select", CmdSelectLook, DESIRED_ADM_FLAGS, "Selects the (aimed at) object as the last spawned object (to edit)");
	RegAdminCmd("sm_prop_set", CmdSetLook, DESIRED_ADM_FLAGS, "Sets the (aimed at) phys object's current position to be saved");
	RegAdminCmd("sm_prop_setlast", CmdSetLast, DESIRED_ADM_FLAGS, "Sets the last object's current position to be saved");
	RegAdminCmd("sm_prop_nudge", CmdNudge, DESIRED_ADM_FLAGS, "Nudge the last phys object to enable physics");
	
	RegAdminCmd("sm_prop_move", CmdMove, DESIRED_ADM_FLAGS, "Move an object with the desired movement type");
	RegAdminCmd("sm_prop_rotate", CmdRotate, DESIRED_ADM_FLAGS, "Rotates the last spawned object with the desired angles");
	RegAdminCmd("sm_prop_removelast", CmdRemoveLast, DESIRED_ADM_FLAGS, "Remove last spawned object");
	RegAdminCmd("sm_prop_removelook", CmdRemoveLook, DESIRED_ADM_FLAGS, "Remove the looking object");
	RegAdminCmd("sm_removebyname", cmdRemoveByName, DESIRED_ADM_FLAGS, "Remove all props that have a model that contains this string");
	RegAdminCmd("sm_prop_removeall", CmdRemoveAll, DESIRED_ADM_FLAGS, "Remove all objects");
	RegAdminCmd("sm_prop_setang", CmdSetAngles, DESIRED_ADM_FLAGS, "Sets the last object angles");
	RegAdminCmd("sm_prop_setpos", CmdSetPosition, DESIRED_ADM_FLAGS, "Sets the last object position");
	RegAdminCmd("sm_grabprop", CmdGrab, DESIRED_ADM_FLAGS, "Grabs the last object to move it");
	RegAdminCmd("sm_grablook", CmdGrabLook, DESIRED_ADM_FLAGS, "Grabs the looking object to move it");
	
	//DEV
	RegAdminCmd("sm_savemap", CmdSaveMap, DESIRED_ADM_FLAGS, "Save all the spawned objects");
	RegAdminCmd("sm_osrefresh", CmdOSRefresh, DESIRED_ADM_FLAGS, "Refresh Object Spawner admin menu");
	RegAdminCmd("sm_osload", CmdLoad, DESIRED_ADM_FLAGS, "Load object spawn save file #");
	RegAdminCmd("sm_debugprop", CmdDebugProp, ADMFLAG_ROOT, "DEBUG last spawned object");
	
	
	AutoExecConfig(true, "l4d2_object_spawner");
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	//Events
	HookEvent("survival_round_start", Event_SurvivalRoundStart);
	HookEvent("scavenge_round_start", Event_ScavengeRoundStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	g_hGameMode = FindConVar("mp_gamemode");
	AssaultMaxAmmo = FindConVar("ammo_assaultrifle_max");
	SMGMaxAmmo = FindConVar("ammo_smg_max");
	ShotgunMaxAmmo = FindConVar("ammo_shotgun_max");
	AutoShotgunMaxAmmo = FindConVar("ammo_autoshotgun_max");
	HRMaxAmmo = FindConVar("ammo_huntingrifle_max");
	SniperRifleMaxAmmo = FindConVar("ammo_sniperrifle_max");
	GrenadeLauncherMaxAmmo = FindConVar("ammo_grenadelauncher_max");
	
	//Precache weapon models, thx atomic
	PrecacheWeaponModels();
}

public Action:TimedSpawn(Handle:timer)
{
	LogPlugin("TimedSpawn() called...");
	SpawnObjects();
}

public Action:CheckClient(Handle:timer)
{	
	new client = GetInGameClient();

	if( client != 0 && !g_bLoaded)
	{
		//Purge all object arrays on round start so the prop count or settings do not carry over into the next round.
		propCount = 0;
		for(new i=MaxClients; i < ARRAY_SIZE; i++)
		{
			g_bSpawned[i] = false;
			g_bItem[i] = false;
			g_iAmmo[i] = 0;
			g_vecEntityAngles[i][0] = 0.0;
			g_vecEntityAngles[i][1] = 0.0;
			g_vecEntityAngles[i][2] = 0.0;
			g_vecEntityOrigin[i][0] = 0.0;
			g_vecEntityOrigin[i][1] = 0.0;
			g_vecEntityOrigin[i][2] = 0.0;
		}
		
		for(new i=0; i < (sizeof(g_bLight) - 1); i++)
		{
			g_bLight[i] = false;
		}
		
		for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
		{
			g_bDespawned[i] = false;
		}
		
		g_bLoaded = true;		
		g_spawnTimer = CreateTimer(0.5, TimedSpawn);
		LogPlugin("CheckClient() will call TimedSpawn() in 0.5 seconds...");
		
		return;
	}
	
	//LogSpawn("CheckClient() found no clients... Will try again in 1 second");
	if (!g_bLoaded)		g_checkTimer = CreateTimer(1.0, CheckClient);
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
	LogPlugin("Survival Round Start");
	if(GetConVarBool(g_cvarAutoload) && GetConVarBool(g_cvarAutoloadType))
	{
		GetRandomMapPath(g_sPath, sizeof(g_sPath));
	}

	if(GetConVarBool(g_cvarAutoload) && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}

public Event_ScavengeRoundStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	if(GetConVarBool(g_cvarAutoload) && GetConVarBool(g_cvarAutoloadType))
	{
		GetRandomMapPath(g_sPath, sizeof(g_sPath));
	}

	LogPlugin("Scavenge Round Has Started");
	if(GetConVarBool(g_cvarAutoload) && !g_bLoaded)
	{
		g_bLoaded = true;
		SpawnObjects();
	}
}
public Event_RoundStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	LogPlugin("ROUND START");
	
	if(GetConVarBool(g_cvarAutoload) && GetConVarBool(g_cvarAutoloadType))
	{
		GetRandomMapPath(g_sPath, sizeof(g_sPath));
	}	

	if(GetConVarBool(g_cvarAutoload))
	{
		g_checkTimer = CreateTimer(1.0, CheckClient);
		LogPlugin("CheckClient() will be called in 1 second.");
	}
}

public Event_RoundEnd(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	g_bLoaded = false;
	LogPlugin("ROUND END");
}

public OnMapStart()
{
	LogPlugin("MAP START");
	propCount = 0;
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		g_bSpawned[i] = false;
		g_bItem[i] = false;
		g_iAmmo[i] = 0;
		g_vecEntityAngles[i][0] = 0.0;
		g_vecEntityAngles[i][1] = 0.0;
		g_vecEntityAngles[i][2] = 0.0;
		g_vecEntityOrigin[i][0] = 0.0;
		g_vecEntityOrigin[i][1] = 0.0;
		g_vecEntityOrigin[i][2] = 0.0;
	}
	
	for(new i=0; i < (sizeof(g_bLight) - 1); i++)
	{
		g_bLight[i] = false;
	}
	
	for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
	{
		g_bDespawned[i] = false;
	}
	

	GetRandomMapPath(g_sPath, sizeof(g_sPath));

}

public OnMapEnd()
{
	g_bLoaded = false;
	g_checkTimer = INVALID_HANDLE;
	g_spawnTimer = INVALID_HANDLE;
	LogPlugin("MAP END");
}

public Action:CmdOSRefresh(client, args)
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

public Action:CmdSpawnProp(client, args)
{
	if(GetConVarBool(g_cvarDisplayPropCount))
	{
		PrintToChatAll("\x03Spawned objects: %i", propCount);
	}
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
		new prop;
		
		//If the object needs to be prop_dynamic to function properly then set appropriate values
		if(StrContains(model, "fire_escape_wide_upper.mdl", false) != -1 || StrContains(model, "fire_escape_upper.mdl", false) != -1) 
		{
			prop = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(prop, "disableshadows", "1");
			DispatchKeyValue(prop, "fademaxdist", "1524");
			DispatchKeyValue(prop, "fademindist", "1093");
		}
		else
		{
			prop = CreateEntityByName("prop_dynamic_override");
		}
		
		
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
		propCount += 1;
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
		propCount += 1;
	}
	else if(StrContains(arg2, "physics") >= 0)
	{
		decl Float:VecOrigin[3], Float:VecAngles[3];
		new prop = CreateEntityByName("prop_physics_override");		
		
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
		
		DispatchSpawn(prop);
		
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
		g_vecEntityOrigin[prop] = VecOrigin;
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a physics object with model <%s>", name, model);
		propCount += 1;
	}
	else
	{
		PrintToChat(client, "[SM] Invalid render mode. Use: [static | dynamic | physics]");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CmdSpawnLight(client, args)
{
	if(GetConVarBool(g_cvarDisplayPropCount))
	{
		PrintToChatAll("\x03Spawned objects: %i", propCount);
	}
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_spawnlight [0 | 1]   1 means the light is physics enabled and breakable.");
		return Plugin_Handled;
	}
	decl String:arg1[8], intArg, String:kvString[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	intArg = StringToInt(arg1);

	decl String:model[256];
	strcopy(model, sizeof(model), "models/props_equipment/light_floodlight.mdl");
	if(!IsModelPrecached(model))
	{
		if(PrecacheModel(model) <= 0)
		{
			PrintToChat(client, "[SM] There was a problem spawning the selected model [ERROR: Invalid Model]");
			return Plugin_Handled;
		}
	}

	decl Float:VecOrigin[3], Float:VecAngles[3];
	
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(INVALID_HANDLE))
	{
		TR_GetEndPosition(VecOrigin);
	}
	else
	{
		PrintToChat(client, "[SM] Vector out of world geometry.");
		return Plugin_Handled;
	}
	
	if(intArg == 0)
	{
		new prop = CreateEntityByName("prop_dynamic_override");
		Format(kvString, sizeof(kvString), "l4d2_spawn_props_worklight%i", prop);
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "skin", "1");
		SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_vecEntityAngles[prop] = VecAngles;
		g_vecEntityOrigin[prop] = VecOrigin;
		
		g_bLight[prop] = true;		//set the work light into the array so it can be saved
		
		//VecOrigin[0] += -6.0;	//SET NEW POSITION and ANGLES FOR LIGHT ENTITY
		//VecOrigin[1] += -11.0;	//using the offsets found from stripper dump
		VecOrigin[2] += 80.0;

		VecAngles[0] += 10.0;
		//VecAngles[1] += -7.3;
		VecAngles[2] += -93.7;

		new light = CreateEntityByName("point_spotlight");
		DispatchKeyValue(light, "rendercolor", "250 210 170");
		DispatchKeyValue(light, "rendermode", "9");
		DispatchKeyValue(light, "spotlightwidth", "80");
		DispatchKeyValue(light, "spotlightlength", "260");
		DispatchKeyValue(light, "renderamt", "180");
		DispatchKeyValue(light, "spawnflags", "1");
		

		DispatchKeyValueVector(light, "angles", VecAngles);
		DispatchKeyValueFloat(light, "pitch", VecAngles[0]);
		Format(kvString, sizeof(kvString), "l4d2_spawn_props_light%i", prop);
		DispatchKeyValue(light, "targetname", kvString);
		
		DispatchSpawn(light);				//DISPATCH SPAWN LIGHT ENTITY
		AcceptEntityInput(light, "TurnOn");

		TeleportEntity(light, VecOrigin, NULL_VECTOR, NULL_VECTOR);		//teleport the light entity to the worklight model using the offsets

		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a static light object with model <%s>", name, model);
		
		propCount += 1;
	}
	else if(intArg == 1)
	{
		new prop = CreateEntityByName("prop_physics_override");
		Format(kvString, sizeof(kvString), "l4d2_spawn_props_worklight%i", prop);
		DispatchKeyValue(prop, "model", model);
		DispatchKeyValue(prop, "skin", "1");
		DispatchKeyValue(prop, "targetname", kvString);
		
		
		
		Format(kvString, sizeof(kvString), "OnHealthChanged l4d2_spawn_props_light%i,LightOff,,0,-1", prop);
		SetVariantString(kvString);
		AcceptEntityInput(prop, "AddOutput");
		Format(kvString, sizeof(kvString), "OnHealthChanged l4d2_spawn_props_worklight%i,Skin,0,0,-1", prop);
		SetVariantString(kvString);
		AcceptEntityInput(prop, "AddOutput");

		
		VecAngles[0] = 0.0;
		VecAngles[2] = 0.0;
		VecOrigin[2] += 3.0;		//Raise the work lamp so that it doesn't clip through the ground when spawned.
		
		g_vecLastEntityAngles[client][0] = VecAngles[0];
		g_vecLastEntityAngles[client][1] = VecAngles[1];
		g_vecLastEntityAngles[client][2] = VecAngles[2];
		g_iLastObject[client] = prop;
		DispatchKeyValueVector(prop, "angles", VecAngles);
		DispatchSpawn(prop);
		TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_vecEntityAngles[prop] = VecAngles;
		g_vecEntityOrigin[prop] = VecOrigin;
		
		g_bLight[prop] = true;		//set the work light into the array so it can be saved
		
		//VecOrigin[0] += -6.0;	//SET NEW POSITION and ANGLES FOR LIGHT ENTITY
		//VecOrigin[1] += -11.0;	//using the offsets found from stripper dump
		VecOrigin[2] += 80.0;

		VecAngles[0] += 10.0;
		//VecAngles[1] += -7.3;
		VecAngles[2] += -93.7;

		new light = CreateEntityByName("point_spotlight");
		DispatchKeyValue(light, "rendercolor", "250 210 170");
		DispatchKeyValue(light, "rendermode", "9");
		DispatchKeyValue(light, "spotlightwidth", "80");
		DispatchKeyValue(light, "spotlightlength", "260");
		DispatchKeyValue(light, "renderamt", "180");
		DispatchKeyValue(light, "spawnflags", "1");
		

		DispatchKeyValueVector(light, "angles", VecAngles);
		DispatchKeyValueFloat(light, "pitch", VecAngles[0]);
		Format(kvString, sizeof(kvString), "l4d2_spawn_props_light%i", prop);
		DispatchKeyValue(light, "targetname", kvString);
		
		DispatchSpawn(light);				//DISPATCH SPAWN LIGHT ENTITY
		AcceptEntityInput(light, "TurnOn");

		TeleportEntity(light, VecOrigin, NULL_VECTOR, NULL_VECTOR);		//teleport the light entity to the worklight model using the offsets

		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogSpawn("%s spawned a static light object with model <%s>", name, model);
		
		propCount += 1;
	}
	
	return Plugin_Handled;
}

public Action:CmdSpawnItem(client, args)
{
	if(GetConVarBool(g_cvarDisplayPropCount))
	{
		PrintToChatAll("\x03Spawned objects: %i", propCount);
	}
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_spawnitem <item> <optional:  Ammo>\n \x03Ammo affects reserve ammo, omit it to have a full weapon.");
		return Plugin_Handled;
	}
	
	new bool:isMelee = false;
	decl String:arg1[128], String:arg2[32], meleeName[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	
	////////////////MELEE SUPPORT///////////////////////////
	
	if (StrEqual(arg1, MELEE_FIREAXE, false)
			|| StrEqual(arg1, MELEE_MACHETE, false)
			|| StrEqual(arg1, MELEE_BASEBALL_BAT, false)
			|| StrEqual(arg1, MELEE_CROWBAR, false) 
			|| StrEqual(arg1, MELEE_CRICKET_BAT, false) 
			|| StrEqual(arg1, MELEE_TONFA, false) 
			|| StrEqual(arg1, MELEE_KATANA, false) 
			|| StrEqual(arg1, MELEE_GUITAR, false) 
			|| StrEqual(arg1, MELEE_KNIFE, false) 
			|| StrEqual(arg1, MELEE_FRYING_PAN, false))
	{
		isMelee = true;
		strcopy(String:meleeName, sizeof(meleeName), arg1);
		strcopy(arg1, sizeof(arg1), "melee");
	}
	
	///////////////////////////////////////////////////////
	
	decl String:item[128];
	Format(item, sizeof(item), "weapon_%s", arg1);
	decl Float:VecOrigin[3], Float:VecAngles[3];
	
	new iWeapon = CreateEntityByName(item);
	
	if(!IsValidEntity(iWeapon))
	{
		PrintToChat(client, "Invalid entity...");
		return Plugin_Handled;
	}
	
	if(isMelee)
	{
		DispatchKeyValue(iWeapon, "melee_script_name", String:meleeName);
	}
	
	DispatchKeyValue(iWeapon, "targetname", "l4d2_spawn_props_prop");
	
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

	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	g_vecLastEntityAngles[client][0] = VecAngles[0];
	g_vecLastEntityAngles[client][1] = VecAngles[1];
	g_vecLastEntityAngles[client][2] = VecAngles[2];
	g_iLastObject[client] = iWeapon;
	DispatchKeyValueVector(iWeapon, "angles", VecAngles);
	
	//IF AMMO IS SPECIFIED
	if(args > 1)
	{ 
		GetCmdArg(2, arg2, sizeof(arg2));
		g_iAmmo[iWeapon] = StringToInt(arg2);
		if (g_iAmmo[iWeapon] < 0 || g_iAmmo[iWeapon] > 1000) g_iAmmo[iWeapon] = -1;  // Resets the ammo if its out of range.
	}
	//IF AMMO IS UNSPECIFIED
	else
	{
		g_iAmmo[iWeapon] = -1;
	}
	
	DispatchSpawn(iWeapon);	//SPAWN WEAPON 
	
	VecOrigin[2] += 5;	// Raise the spawned item slightly.
	
	TeleportEntity(iWeapon, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	g_bSpawned[iWeapon] = true;
	g_bItem[iWeapon] = true;
	
	g_vecEntityAngles[iWeapon] = VecAngles;
	g_vecEntityOrigin[iWeapon] = VecOrigin;

	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogSpawn("%s spawned <%s>  with %i ammo", name, item, g_iAmmo[iWeapon]);
	propCount += 1;

	return Plugin_Handled;
}

public Action:CmdSpawnSpawn(client, args)
{
	if(GetConVarBool(g_cvarDisplayPropCount))
	{
		PrintToChatAll("\x03Spawned objects: %i", propCount);
	}
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_spawnspawn <item> <optional:  Count>\n\x03Count indicates how many there will be (defaults to 1).");
		return Plugin_Handled;
	}
	
	new bool:isMelee = false;
	decl String:arg1[128], String:arg2[32], String:meleeName[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	////////////////MELEE SUPPORT///////////////////////////
	
	if (StrEqual(arg1, MELEE_FIREAXE, false)
			|| StrEqual(arg1, MELEE_MACHETE, false)
			|| StrEqual(arg1, MELEE_BASEBALL_BAT, false)
			|| StrEqual(arg1, MELEE_CROWBAR, false) 
			|| StrEqual(arg1, MELEE_CRICKET_BAT, false) 
			|| StrEqual(arg1, MELEE_TONFA, false) 
			|| StrEqual(arg1, MELEE_KATANA, false) 
			|| StrEqual(arg1, MELEE_GUITAR, false) 
			|| StrEqual(arg1, MELEE_KNIFE, false) 
			|| StrEqual(arg1, MELEE_FRYING_PAN, false))
	{
		isMelee = true;
		strcopy(String:meleeName, sizeof(meleeName), arg1);
		strcopy(arg1, sizeof(arg1), "melee");
	}
	
	///////////////////////////////////////////////////////
	
	decl String:item[128];
	Format(item, sizeof(item), "weapon_%s_spawn", arg1);
	decl Float:VecOrigin[3], Float:VecAngles[3];
	
	new iWeapon = CreateEntityByName(item);
	
	if(!IsValidEntity(iWeapon))
	{
		PrintToChat(client, "Invalid entity...");
		return Plugin_Handled;
	}
	
	//CHECK TO SEE IF MELEE< THEN ADD APPROPRIATE SCRIPT NAME
	if(isMelee)
	{
		DispatchKeyValue(iWeapon, "melee_weapon", String:meleeName);
	}
	
	DispatchKeyValue(iWeapon, "targetname", "l4d2_spawn_props_prop");
	
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

	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	g_vecLastEntityAngles[client][0] = VecAngles[0];
	g_vecLastEntityAngles[client][1] = VecAngles[1];
	g_vecLastEntityAngles[client][2] = VecAngles[2];
	g_iLastObject[client] = iWeapon;
	DispatchKeyValueVector(iWeapon, "angles", VecAngles);

	SetEntProp(iWeapon, Prop_Send, "m_nSolidType", 0);
	
	DispatchKeyValue(iWeapon, "spawnflags", "2");
	DispatchKeyValue(iWeapon, "skin", "0");
	DispatchKeyValue(iWeapon, "disableshadows", "1");
	
	if(args > 1)	//IF WEAPON COUNT IS SPECIFIED, set it.   If not, set it to 1
	{ 
		GetCmdArg(2, arg2, sizeof(arg2));
		DispatchKeyValue(iWeapon, "count", arg2);  
	}
	else
	{
		DispatchKeyValue(iWeapon, "count", "1"); 
	}

	DispatchSpawn(iWeapon);	//SPAWN WEAPON 
	
	VecOrigin[2] += 5;	// Raise the spawned item slightly.
	
	TeleportEntity(iWeapon, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityMoveType(iWeapon, MOVETYPE_PUSH);
	
	g_bSpawned[iWeapon] = true;
	g_bItem[iWeapon] = true;
	
	g_vecEntityAngles[iWeapon] = VecAngles;
	g_vecEntityOrigin[iWeapon] = VecOrigin;

	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	
	if(args > 1)	LogSpawn("%s spawned <%s>  with %s count", name, item, arg2);
	else			LogSpawn("%s spawned <%s>  with 1 count", name, item);
	propCount += 1;

	return Plugin_Handled;
}


public Action:CmdSpawnFireEscape(client, args)
{
	if(GetConVarBool(g_cvarDisplayPropCount))
	{
		PrintToChatAll("\x03Spawned objects: %i", propCount);
	}
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_spawnfe <# of levels> <optional: [0|1] >  0:regular(default) 1:wide");
		return Plugin_Handled;
	}
	decl String:arg1[12], String:arg2[6];
	decl String:model0[] = "models/props_urban/fire_escape_upper.mdl";
	decl String:model1[] = "models/props_urban/fire_escape_wide_upper.mdl";
	decl Float:VecOrigin[3], Float:VecAngles[3], rAngle, String:feName[128], String:model[256];
	new option, levels;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	levels = StringToInt(arg1);
	if(args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		option = StringToInt(arg2);
	}
	
	if(option)	strcopy(model, sizeof(model), model1);
	else		strcopy(model, sizeof(model), model0);

	if(!IsModelPrecached(model))
	{
		if(PrecacheModel(model) <= 0)
		{
			PrintToChat(client, "[SM] There was a problem spawning the selected model [ERROR: Invalid Model]");
			return Plugin_Handled;
		}
	}

	new prop = CreateEntityByName("prop_dynamic");
	Format(feName, sizeof(feName), "l4d2_spawn_props_fe%i", prop);
	DispatchKeyValue(prop, "targetname", feName);
	DispatchKeyValue(prop, "disableshadows", "1");
	DispatchKeyValue(prop, "fademaxdist", "1524");
	DispatchKeyValue(prop, "fademindist", "1093");
	DispatchKeyValue(prop, "model", model);
	SetEntProp(prop, Prop_Send, "m_nSolidType", 6);

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
		GetClientEyePosition(client, VecOrigin);
		GetClientEyeAngles(client, VecAngles);
	}
	
	VecAngles[1] = float(RoundFloat(VecAngles[1]));
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	VecAngles[1] -= 90;		//rotate fire escape
	
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
	LogSpawn("%s spawned a fire escape with model <%s>", name, model);
	propCount += 1;

	
	if(levels < 2)
	{
		return Plugin_Handled;
	}
	
	new prop2;
	
	for(new i=1; i < levels; i++)
	{
	prop2 = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(prop2, "targetname", "l4d2_spawn_props_fe");
	DispatchKeyValue(prop2, "disableshadows", "1");
	DispatchKeyValue(prop2, "fademaxdist", "1524");
	DispatchKeyValue(prop2, "fademindist", "1093");
	DispatchKeyValue(prop2, "model", model);
	SetEntProp(prop2, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValueVector(prop2, "angles", VecAngles);
	DispatchSpawn(prop2);
		
	VecOrigin[2] += 128;		//Raise the next fire escape levels
	TeleportEntity(prop2, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	g_bSpawned[prop2] = true;
	g_vecEntityAngles[prop2] = VecAngles;
	
	//parent to base fire escape
	SetVariantString(feName);
	AcceptEntityInput(prop2, "SetParent", prop2, prop2, 0);  

	propCount += 1;
	}
	
	return Plugin_Handled;
}

public Action:CmdSpawnTruck(client, args)
{
	if(GetConVarBool(g_cvarDisplayPropCount))
	{
		PrintToChatAll("\x03Spawned objects: %i", propCount);
	}
	
	//PRECACHE GLASS AND TRUCK
	decl String:model[256], String:tName[256];
	strcopy(model, sizeof(model), "models/props/de_nuke/truck_nuke_glass.mdl");
	if(!IsModelPrecached(model))
	{
		if(PrecacheModel(model) <= 0)
		{
			PrintToChat(client, "[SM] There was a problem spawning the selected model [ERROR: Invalid Model]");
			return Plugin_Handled;
		}
	}
	strcopy(model, sizeof(model), "models/props/de_nuke/truck_nuke.mdl");
	if(!IsModelPrecached(model))
	{
		if(PrecacheModel(model) <= 0)
		{
			PrintToChat(client, "[SM] There was a problem spawning the selected model [ERROR: Invalid Model]");
			return Plugin_Handled;
		}
	}
	//SPAWN THE TRUCk
	decl Float:VecOrigin[3], Float:VecAngles[3];
	new prop;
	prop = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(prop, "model", model);
	SetEntProp(prop, Prop_Send, "m_nSolidType", 6);

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
		GetClientEyePosition(client, VecOrigin);
		GetClientEyeAngles(client, VecAngles);
	}
	Format(tName, sizeof(tName), "l4d2_spawn_props_truck_%f%f%f", VecOrigin[0], VecOrigin[1], VecOrigin[1]);
	DispatchKeyValue(prop, "targetname", tName);

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
	
	//Now spawn the glass
	strcopy(model, sizeof(model), "models/props/de_nuke/truck_nuke_glass.mdl");
	prop = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(prop, "model", model);
	DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
	SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
	DispatchKeyValueVector(prop, "angles", VecAngles);
	DispatchSpawn(prop);
	TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	g_bSpawned[prop] = true;
	g_vecEntityAngles[prop] = VecAngles;
	//parent to truck
	SetVariantString(tName);
	AcceptEntityInput(prop, "SetParent", prop, prop, 0);  
	
	LogSpawn("%N spawned a delivery truck", client);

	propCount += 2;

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
		Format(buffer, maxlength, "Object Spawner");
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
	
	AddMenuItem(menu, "sm_spawnpc", "Spawn Physics On Cursor");
	AddMenuItem(menu, "sm_spawnpo", "Spawn Physics On Origin");

	AddMenuItem(menu, "sm_spawndc", "Spawn Non-solid On Cursor");
	AddMenuItem(menu, "sm_spawndo", "Spawn Non-solid On Origin");

	AddMenuItem(menu, "sm_spawnsc", "Spawn Solid On Cursor");
	AddMenuItem(menu, "sm_spawnso", "Spawn Solid On Origin");

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
		SavePluginProps(param);
	}
}
/* 
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
} */

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

	AddMenuItem(menu, "vehicles", "Vehicles");
	
	AddMenuItem(menu, "foliage", "Foliage");
	
	AddMenuItem(menu, "interior", "Interior");
	
	AddMenuItem(menu, "exterior", "Exterior");
	
	AddMenuItem(menu, "decorative", "Decorative");
	
	AddMenuItem(menu, "misc", "Misc");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

stock BuildPhysicsPositionMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PhysicsPosition);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);

	AddMenuItem(menu, "vehicles", "Vehicles");
	
	AddMenuItem(menu, "foliage", "Foliage");
	
	AddMenuItem(menu, "interior", "Interior");
	
	AddMenuItem(menu, "exterior", "Exterior");
	
	AddMenuItem(menu, "decorative", "Decorative");
	
	AddMenuItem(menu, "misc", "Misc");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

stock BuildDynamicCursorMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DynamicCursor);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);

	AddMenuItem(menu, "vehicles", "Vehicles");
	
	AddMenuItem(menu, "foliage", "Foliage");
	
	AddMenuItem(menu, "interior", "Interior");
	
	AddMenuItem(menu, "exterior", "Exterior");
	
	AddMenuItem(menu, "decorative", "Decorative");
	
	AddMenuItem(menu, "misc", "Misc");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

stock BuildDynamicPositionMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DynamicPosition);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);

	AddMenuItem(menu, "vehicles", "Vehicles");
	
	AddMenuItem(menu, "foliage", "Foliage");
	
	AddMenuItem(menu, "interior", "Interior");
	
	AddMenuItem(menu, "exterior", "Exterior");
	
	AddMenuItem(menu, "decorative", "Decorative");
	
	AddMenuItem(menu, "misc", "Misc");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}
stock BuildStaticCursorMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_StaticCursor);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);

	AddMenuItem(menu, "vehicles", "Vehicles");
	
	AddMenuItem(menu, "foliage", "Foliage");
	
	AddMenuItem(menu, "interior", "Interior");
	
	AddMenuItem(menu, "exterior", "Exterior");
	
	AddMenuItem(menu, "decorative", "Decorative");
	
	AddMenuItem(menu, "misc", "Misc");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}
stock BuildStaticPositionMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_StaticPosition);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);

	AddMenuItem(menu, "vehicles", "Vehicles");
	
	AddMenuItem(menu, "foliage", "Foliage");
	
	AddMenuItem(menu, "interior", "Interior");
	
	AddMenuItem(menu, "exterior", "Exterior");
	
	AddMenuItem(menu, "decorative", "Decorative");
	
	AddMenuItem(menu, "misc", "Misc");
	
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
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_object_spawner_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_object_spawner_models.txt file");
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
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_object_spawner_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_object_spawner_models.txt file");
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
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_object_spawner_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_object_spawner_models.txt file");
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
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_object_spawner_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_object_spawner_models.txt file");
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
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_object_spawner_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_object_spawner_models.txt file");
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
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_object_spawner_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_object_spawner_models.txt file");
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
				g_vecEntityOrigin[prop] = VecOrigin;
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				//xio
				propCount++;
				if(GetConVarBool(g_cvarDisplayPropCount))
				{
					PrintToChatAll("\x03Spawned objects: %i", propCount);
				}
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
				g_vecEntityOrigin[prop] = VecOrigin;
				TeleportEntity(prop, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				decl String:name[256];
				GetClientName(param1, name, sizeof(name));
				//xio
				propCount++;
				if(GetConVarBool(g_cvarDisplayPropCount))
				{
					PrintToChatAll("\x03Spawned objects: %i", propCount);
				}
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
				//xio
				propCount++;
				if(GetConVarBool(g_cvarDisplayPropCount))
				{
					PrintToChatAll("\x03Spawned objects: %i", propCount);
				}
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
				//xio
				propCount++;
				if(GetConVarBool(g_cvarDisplayPropCount))
				{
					PrintToChatAll("\x03Spawned objects: %i", propCount);
				}
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
				//xio
				propCount++;
				if(GetConVarBool(g_cvarDisplayPropCount))
				{
					PrintToChatAll("\x03Spawned objects: %i", propCount);
				}
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
				//xio
				propCount++;
				if(GetConVarBool(g_cvarDisplayPropCount))
				{
					PrintToChatAll("\x03Spawned objects: %i", propCount);
				}
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
						g_vecEntityOrigin[Object][0] = vecOrigin[0];
						g_vecEntityOrigin[Object][1] = vecOrigin[1];
						g_vecEntityOrigin[Object][2] = vecOrigin[2];
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "movedown"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[2]-= 30;
						g_vecEntityOrigin[Object][0] = vecOrigin[0];
						g_vecEntityOrigin[Object][1] = vecOrigin[1];
						g_vecEntityOrigin[Object][2] = vecOrigin[2];
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "moveright"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[1]+= 30;
						g_vecEntityOrigin[Object][0] = vecOrigin[0];
						g_vecEntityOrigin[Object][1] = vecOrigin[1];
						g_vecEntityOrigin[Object][2] = vecOrigin[2];
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "moveleft"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[1]-= 30;
						g_vecEntityOrigin[Object][0] = vecOrigin[0];
						g_vecEntityOrigin[Object][1] = vecOrigin[1];
						g_vecEntityOrigin[Object][2] = vecOrigin[2];
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "moveforward"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[0]+= 30;
						g_vecEntityOrigin[Object][0] = vecOrigin[0];
						g_vecEntityOrigin[Object][1] = vecOrigin[1];
						g_vecEntityOrigin[Object][2] = vecOrigin[2];
						TeleportEntity(Object, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					}
					else if(StrEqual(menucmd, "movebackward"))
					{
						decl Float:vecOrigin[3];
						GetEntPropVector(Object, Prop_Data, "m_vecOrigin", vecOrigin);
						vecOrigin[0]-= 30;
						g_vecEntityOrigin[Object][0] = vecOrigin[0];
						g_vecEntityOrigin[Object][1] = vecOrigin[1];
						g_vecEntityOrigin[Object][2] = vecOrigin[2];
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
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_object_spawner_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_object_spawner_models.txt file");
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
	new String:targetName[256], String: sModel[256];
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
			if((StrEqual(class, "prop_physics")
			|| StrEqual(class, "prop_dynamic")
			|| StrEqual(class, "prop_physics_override")
			|| StrEqual(class, "prop_dynamic_override")
			|| StrContains(class, "weapon_", false) != -1)
			&& (g_bSpawned[Object] || g_bLight[Object]))
			{
				g_bSpawned[Object] = false;
				g_bUnsolid[Object] = false;
				g_bItem[Object] = false;
				g_iAmmo[Object] = 0;
				g_vecEntityAngles[Object][0] = 0.0;
				g_vecEntityAngles[Object][1] = 0.0;
				g_vecEntityAngles[Object][2] = 0.0;
				g_vecEntityOrigin[Object][0] = 0.0;
				g_vecEntityOrigin[Object][1] = 0.0;
				g_vecEntityOrigin[Object][2] = 0.0;
				
				if(g_bLight[Object])	//if light, remove model AND light entity
				{
					Format(targetName, sizeof(targetName), "l4d2_spawn_props_light%i LightOff", Object);
					CheatCommand(_, "ent_fire", targetName);
					g_bLight[Object] = false;
				}
				
				GetEntPropString(Object, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				if( StrContains(sModel, "fire_escape_", false) != -1 || StrContains(sModel, "truck_nuke", false) != -1)	checkParent();
				
				AcceptEntityInput(Object, "KillHierarchy");
				PrintToChat(client, "[SM] Succesfully removed an object");
				propCount += -1;
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
			if((StrEqual(class, "prop_physics")
			|| StrEqual(class, "prop_dynamic")
			|| StrEqual(class, "prop_physics_override")
			|| StrEqual(class, "prop_dynamic_override")
			|| StrContains(class, "weapon_", false) != -1)
			&& (g_bSpawned[Object] || g_bLight[Object]))
			{
				g_bSpawned[Object] = false;
				g_bUnsolid[Object] = false;
				g_bItem[Object] = false;
				g_iAmmo[Object] = 0;
				g_vecEntityAngles[Object][0] = 0.0;
				g_vecEntityAngles[Object][1] = 0.0;
				g_vecEntityAngles[Object][2] = 0.0;
				g_vecEntityOrigin[Object][0] = 0.0;
				g_vecEntityOrigin[Object][1] = 0.0;
				g_vecEntityOrigin[Object][2] = 0.0;
				
				if(g_bLight[Object])	//if light, remove model AND light entity
				{
					Format(targetName, sizeof(targetName), "l4d2_spawn_props_light%i LightOff", Object);
					CheatCommand(_, "ent_fire", targetName);
					g_bLight[Object] = false;
				}
				
				GetEntPropString(Object, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				if( StrContains(sModel, "fire_escape_", false) != -1 || StrContains(sModel, "truck_nuke", false) != -1)	checkParent();
				
				AcceptEntityInput(Object, "KillHierarchy");
				PrintToChat(client, "[SM] Succesfully removed an object");
				propCount += -1;
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


stock SelectLookingEntity(client)
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
			if(g_bSpawned[Object] || g_bLight[Object])
			{
				decl String:class[256];
				GetEdictClassname(Object, class, sizeof(class));
				if(StrEqual(class, "prop_physics")
				|| StrEqual(class, "prop_dynamic")
				|| StrEqual(class, "prop_physics_override")
				|| StrEqual(class, "prop_dynamic_override")
				|| StrContains(class, "weapon_", false) != -1)
				{
				
					GetEntPropVector(Object, Prop_Send, "m_angRotation", VecAngles);
					
					g_iLastObject[client] = Object;
					g_vecLastEntityAngles[client] = VecAngles;
					//g_iLastSpawned[Object] = true;

					PrintToChat(client, "Object selected.");


					g_bGrab[client] = false;
					g_bGrabbed[Object] = false;
					
					return;
				}
			}
			else
			{
				PrintToChat(client, "Object is not valid.");
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
			if(g_bSpawned[Object] || g_bLight[Object])
			{
				decl String:class[256];
				GetEdictClassname(Object, class, sizeof(class));
				if(StrEqual(class, "prop_physics")
				|| StrEqual(class, "prop_dynamic")
				|| StrEqual(class, "prop_physics_override")
				|| StrEqual(class, "prop_dynamic_override")
				|| StrContains(class, "weapon_", false) != -1)
				{
				
					GetEntPropVector(Object, Prop_Send, "m_angRotation", VecAngles);
					
					g_iLastObject[client] = Object;
					g_vecLastEntityAngles[client] = VecAngles;
					//g_iLastSpawned[Object] = true;

					PrintToChat(client, "Object selected.");


					g_bGrab[client] = false;
					g_bGrabbed[Object] = false;
					
					return;
				}
			}
			else
			{
				PrintToChat(client, "Object is not valid.");
				return;
			}
		}
	}
	PrintToChat(client, "[SM] You are not looking to a valid object");
}

stock SetLookingEntity(client)
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
			if(g_bSpawned[Object] || g_bLight[Object])
			{
				decl String:class[256];
				GetEdictClassname(Object, class, sizeof(class));
				if(StrEqual(class, "prop_physics")
				|| StrEqual(class, "prop_dynamic")
				|| StrEqual(class, "prop_physics_override")
				|| StrEqual(class, "prop_dynamic_override")
				|| StrContains(class, "weapon_", false) != -1)
				{
				
					GetEntPropVector(Object, Prop_Send, "m_vecOrigin", VecOrigin);
					GetEntPropVector(Object, Prop_Send, "m_angRotation", VecAngles);
					
					g_iLastObject[client] = Object;		//set to last object as well
					g_vecLastEntityAngles[client] = VecAngles;
					
					g_vecEntityAngles[Object] = VecAngles;
					g_vecEntityOrigin[Object] = VecOrigin;
					
					

					PrintToChat(client, "Object save position updated.");


					g_bGrab[client] = false;
					g_bGrabbed[Object] = false;
					
					return;
				}
			}
			else
			{
				PrintToChat(client, "Object is not valid.");
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
			if(g_bSpawned[Object] || g_bLight[Object])
			{
				decl String:class[256];
				GetEdictClassname(Object, class, sizeof(class));
				if(StrEqual(class, "prop_physics")
				|| StrEqual(class, "prop_dynamic")
				|| StrEqual(class, "prop_physics_override")
				|| StrEqual(class, "prop_dynamic_override")
				|| StrContains(class, "weapon_", false) != -1)
				{
				
					GetEntPropVector(Object, Prop_Send, "m_vecOrigin", VecOrigin);
					GetEntPropVector(Object, Prop_Send, "m_angRotation", VecAngles);
					
					g_iLastObject[client] = Object;		//set to last object as well
					g_vecLastEntityAngles[client] = VecAngles;
					
					g_vecEntityAngles[Object] = VecAngles;
					g_vecEntityOrigin[Object] = VecOrigin;

					PrintToChat(client, "Object save position updated.");


					g_bGrab[client] = false;
					g_bGrabbed[Object] = false;
					
					return;
				}
			}
			else
			{
				PrintToChat(client, "Object is not valid.");
				return;
			}
		}
	}
	PrintToChat(client, "[SM] You are not looking to a valid object");
}

stock SetLastEntity(client)
{
	decl Float:VecOrigin[3], Float:VecAngles[3];
	new Object = g_iLastObject[client];
	if(Object > 0 && IsValidEntity(Object) && IsValidEdict(Object))
	{
		if(g_bSpawned[Object] || g_bLight[Object])
		{		
			GetEntPropVector(Object, Prop_Send, "m_vecOrigin", VecOrigin);
			GetEntPropVector(Object, Prop_Send, "m_angRotation", VecAngles);
			g_vecLastEntityAngles[client] = VecAngles;
			g_vecEntityAngles[Object] = VecAngles;
			g_vecEntityOrigin[Object] = VecOrigin;
			PrintToChat(client, "last Object save position updated.");
			g_bGrab[client] = false;
			g_bGrabbed[Object] = false;
			return;
		}
		else
		{
			PrintToChat(client, "Object is not indexed.");
			return;
		}
	}
	PrintToChat(client, "[SM] Object is not valid anymore. error.");
}

stock KillLookingEntity(client)
{
	decl Float:VecOrigin[3], Float:VecAngles[3], iPlus;
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
			LogSpawn("%N despawned <%s>", client, class);
			if(StrEqual(class, "prop_physics")
			|| StrEqual(class, "prop_dynamic")
			|| StrEqual(class, "prop_physics_override")
			|| StrEqual(class, "prop_dynamic_override")
			|| StrContains(class, "weapon_", false) != -1)
			{
				GetEntPropVector(Object, Prop_Send, "m_vecOrigin", VecOrigin);
				
				for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
				{
					if(!g_bDespawned[i])
					{
						iPlus = i;
						iPlus++;
						g_bDespawned[i] = true;
						g_fDespawned[i] = VecOrigin;
						PrintToChat(client, "Object despawned. %i", iPlus);
						AcceptEntityInput(Object, "Kill");
						i = (sizeof(g_bDespawned) - 1);
					}
				}
				propCount += 1;
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
			LogSpawn("%N despawned <%s>", client, class);
			if(StrEqual(class, "prop_physics")
			|| StrEqual(class, "prop_dynamic")
			|| StrEqual(class, "prop_physics_override")
			|| StrEqual(class, "prop_dynamic_override")
			|| StrContains(class, "weapon_", false) != -1)
			{
			
				GetEntPropVector(Object, Prop_Send, "m_vecOrigin", VecOrigin);
				
				for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
				{
					if(!g_bDespawned[i])
					{
						g_bDespawned[i] = true;
						g_fDespawned[i] = VecOrigin;
						PrintToChat(client, "Object despawned. %i", i);
						AcceptEntityInput(Object, "Kill");
						i = (sizeof(g_bDespawned) - 1);
					}
				}
				propCount += 1;
				return;
			}
		}
	}
	PrintToChat(client, "[SM] You are not looking to a valid object");
}

stock DeleteAllProps()
{
	new targetName[256];
	propCount = 0;
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
			g_bItem[i] = false;
			g_iAmmo[i] = 0;
			g_bUnsolid[i] = false;
			g_vecEntityAngles[i][0] = 0.0;
			g_vecEntityAngles[i][1] = 0.0;
			g_vecEntityAngles[i][2] = 0.0;
			g_vecEntityOrigin[i][0] = 0.0;
			g_vecEntityOrigin[i][1] = 0.0;
			g_vecEntityOrigin[i][2] = 0.0;
			if(IsValidEntity(i))
			{
				AcceptEntityInput(i, "Kill");
			}
		}
		if(g_bLight[i])		//if its a light, kill both the model and the light entity
		{
			Format(targetName, sizeof(targetName), "l4d2_spawn_props_light%i LightOff", i);
			CheatCommand(_, "ent_fire", targetName);

			if(IsValidEntity(i))
			{
				AcceptEntityInput(i, "Kill");
			}
			g_bLight[i] = false;
		}
	}
	//DESPAWNER
	for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
	{
		g_bDespawned[i] = false;
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


stock DeleteLastProp(client)
{
	new Object = g_iLastObject[client];
	new String:sModel[256];
	if(Object > 0 && IsValidEntity(Object))
	{
		decl String:class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(StrEqual(class, "prop_physics")
		|| StrEqual(class, "prop_dynamic")
		|| StrEqual(class, "prop_physics_override")
		|| StrEqual(class, "prop_dynamic_override")
		|| StrContains(class, "weapon_", false) != -1)
		{
			if(g_bLight[Object])	//if light, remove model AND light entity
			{
				new String:targetName[256];
				Format(targetName, sizeof(targetName), "l4d2_spawn_props_light%i LightOff", Object);
				CheatCommand(_, "ent_fire", targetName);		//kill light entity
				g_bLight[Object] = false;
			}
			
			GetEntPropString(Object, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			if( StrContains(sModel, "fire_escape_", false) != -1 || StrContains(sModel, "truck_nuke", false) != -1)	checkParent();
			
			
			AcceptEntityInput(g_iLastObject[client], "KillHierarchy");
			PrintToChat(client, "[SM] Succesfully deleted the last spawned object");
			propCount += -1;
			g_iLastObject[client] = -1;
			g_vecLastEntityAngles[client][0] = 0.0;
			g_vecLastEntityAngles[client][1] = 0.0;
			g_vecLastEntityAngles[client][2] = 0.0;
			g_bSpawned[Object] = false;
			g_bUnsolid[Object] = false;
			g_bItem[Object] = false;
			g_iAmmo[Object] = 0;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_vecEntityOrigin[Object][0] = 0.0;
			g_vecEntityOrigin[Object][1] = 0.0;
			g_vecEntityOrigin[Object][2] = 0.0;
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
			g_bItem[Object] = false;
			g_iAmmo[Object] = 0;
			g_vecEntityAngles[Object][0] = 0.0;
			g_vecEntityAngles[Object][1] = 0.0;
			g_vecEntityAngles[Object][2] = 0.0;
			g_vecEntityOrigin[Object][0] = 0.0;
			g_vecEntityOrigin[Object][1] = 0.0;
			g_vecEntityOrigin[Object][2] = 0.0;
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
	if(!GetConVarBool(g_cvarLogActions))
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

stock LogPlugin(const String:format[], any:...)
{
	if(!GetConVarBool(g_cvarLogPlugin))
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

stock printToRoot(const String:format[], any:...)
{
	new AdminId:adminID = INVALID_ADMIN_ID;
	decl String:buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 2);

	for(new i=1; i < GetMaxClients(); i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			adminID = GetUserAdmin(i);
			if (adminID != INVALID_ADMIN_ID)
			{
				if(GetAdminFlag(adminID, Admin_Root, Access_Effective))
				{
					PrintToChat(i, "\x03[%s]", buffer);
				}
			}
		}
	}
}

public Action:CmdSaveMap(client, args)
{
	SavePluginProps(client);
	return Plugin_Handled;
}

stock SavePluginProps(client)
{
	checkParent();
	PrintToChat(client, "\x04[SM] Saving the content. Please Wait");
	decl String:FileName[256], String:map[256], String:classname[256], String:FileNameS[256], String:FileNameT[256];
	new Handle:file = INVALID_HANDLE;
	GetCurrentMap(map, sizeof(map));
	String_ToLower(map, map, sizeof(map));
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
	
	LogSpawn("%N saved the objects for this map [%s]", client, FileNameT);
	
	CreateInitFile();
	decl Float:vecOrigin[3], Float:vecAngles[3], String:sModel[256], String:sTime[256], String:meleeName[256];
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
			if(g_bItem[i])
			{
				GetEdictClassname(i, classname, sizeof(classname));
				
				//Check to see if its an item
				if(StrContains(classname, "ammo_spawn", false) != -1 || StrContains(classname, "_spawn", false) == -1)
				{					
					vecOrigin[0] = g_vecEntityOrigin[i][0];
					vecOrigin[1] = g_vecEntityOrigin[i][1];
					vecOrigin[2] = g_vecEntityOrigin[i][2];
					
					vecAngles = g_vecEntityAngles[i];
					GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
					
					//If melee...
					if (StrContains(classname, "melee", false) != -1)
					{
						GetEntPropString(i, Prop_Data, "m_strMapSetScriptName", meleeName, sizeof(meleeName));
						strcopy(sModel, sizeof(sModel), meleeName);
					}
					
					iOrigin[0] = RoundFloat(vecOrigin[0]);
					iOrigin[1] = RoundFloat(vecOrigin[1]);
					iOrigin[2] = RoundFloat(vecOrigin[2]);
					
					iAngles[0] = RoundFloat(vecAngles[0]);
					iAngles[1] = RoundFloat(vecAngles[1]);
					iAngles[2] = RoundFloat(vecAngles[2]);
					count++;
					
					WriteFileLine(file, "	\"object_%i\"", count);
					WriteFileLine(file, "	{");
					WriteFileLine(file, "		\"item\" \"1\"");
					WriteFileLine(file, "		\"ammo\" \"%i\"", g_iAmmo[i]);
					WriteFileLine(file, "		\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
					WriteFileLine(file, "		\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
					WriteFileLine(file, "		\"model\"	 \"%s\"", sModel);
					WriteFileLine(file, "		\"classname\"	\"%s\"", classname);
					WriteFileLine(file, "	}");
					WriteFileLine(file, "	");
				}
				else	//If its a spawn instead...
				{
					vecOrigin[0] = g_vecEntityOrigin[i][0];
					vecOrigin[1] = g_vecEntityOrigin[i][1];
					vecOrigin[2] = g_vecEntityOrigin[i][2];
					
					vecAngles = g_vecEntityAngles[i];
					GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
					
					
					//If melee...
					if (StrContains(classname, "melee", false) != -1)
					{
						// new iOffset = FindDataMapOffs(i, "m_iszMeleeWeapon");
						// GetEntDataString(i, iOffset, meleeName, sizeof(meleeName));
						GetEntPropString(i, Prop_Data, "m_iszMeleeWeapon", meleeName, sizeof(meleeName));  
						strcopy(sModel, sizeof(sModel), meleeName);
					}
					
					
					new i_Count = GetEntData(i, FindDataMapOffs(i, "m_itemCount"), 4); 
					
					iOrigin[0] = RoundFloat(vecOrigin[0]);
					iOrigin[1] = RoundFloat(vecOrigin[1]);
					iOrigin[2] = RoundFloat(vecOrigin[2]);
					
					iAngles[0] = RoundFloat(vecAngles[0]);
					iAngles[1] = RoundFloat(vecAngles[1]);
					iAngles[2] = RoundFloat(vecAngles[2]);
					count++;
					
					WriteFileLine(file, "	\"object_%i\"", count);
					WriteFileLine(file, "	{");
					WriteFileLine(file, "		\"item\" \"1\"");
					WriteFileLine(file, "		\"count\" \"%i\"", i_Count);
					WriteFileLine(file, "		\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
					WriteFileLine(file, "		\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
					WriteFileLine(file, "		\"model\"	 \"%s\"", sModel);
					WriteFileLine(file, "		\"classname\"	\"%s\"", classname);
					WriteFileLine(file, "	}");
					WriteFileLine(file, "	");
				}
			}
			else
			{
				GetEdictClassname(i, classname, sizeof(classname));
				if(StrContains(classname, "prop_dynamic") >= 0 || StrContains(classname, "prop_physics") >= 0)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
					vecAngles = g_vecEntityAngles[i];
					GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
					
					if(StrContains(classname, "prop_physics") >= 0)
					{
						vecOrigin[0] = g_vecEntityOrigin[i][0];
						vecOrigin[1] = g_vecEntityOrigin[i][1];
						vecOrigin[2] = g_vecEntityOrigin[i][2];
					}
					
					iOrigin[0] = RoundFloat(vecOrigin[0]);
					iOrigin[1] = RoundFloat(vecOrigin[1]);
					iOrigin[2] = RoundFloat(vecOrigin[2]);
					
					iAngles[0] = RoundFloat(vecAngles[0]);
					iAngles[1] = RoundFloat(vecAngles[1]);
					iAngles[2] = RoundFloat(vecAngles[2]);
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
	}
	
	//Worklights
	for(new i=0; i < (sizeof(g_bLight) - 1); i++)
	{
		if(g_bLight[i])
		{
			if(IsValidEntity(i))
			{
				vecAngles = g_vecEntityAngles[i];
				vecOrigin[0] = g_vecEntityOrigin[i][0];
				vecOrigin[1] = g_vecEntityOrigin[i][1];
				vecOrigin[2] = g_vecEntityOrigin[i][2];
				
				GetEdictClassname(i, classname, sizeof(classname));
				
				iOrigin[0] = RoundFloat(vecOrigin[0]);
				iOrigin[1] = RoundFloat(vecOrigin[1]);
				iOrigin[2] = RoundFloat(vecOrigin[2]);
				
				iAngles[0] = RoundFloat(vecAngles[0]);
				iAngles[1] = RoundFloat(vecAngles[1]);
				iAngles[2] = RoundFloat(vecAngles[2]);

				count++;
				
				WriteFileLine(file, "	\"object_%i\"", count);
				WriteFileLine(file, "	{");
				WriteFileLine(file, "		\"light\"	\"1\"");
				WriteFileLine(file, "		\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
				WriteFileLine(file, "		\"angles\" \"%i %i %i\"", iAngles[0], iAngles[1], iAngles[2]);
				WriteFileLine(file, "		\"classname\"	\"%s\"", classname);
				WriteFileLine(file, "	}");
				WriteFileLine(file, "	");
			}
		}
	}
	
	//Despawns
	for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
	{
		if(g_bDespawned[i])
		{
			vecOrigin[0] = g_fDespawned[i][0];
			vecOrigin[1] = g_fDespawned[i][1];
			vecOrigin[2] = g_fDespawned[i][2];
			
			iOrigin[0] = RoundFloat(vecOrigin[0]);
			iOrigin[1] = RoundFloat(vecOrigin[1]);
			iOrigin[2] = RoundFloat(vecOrigin[2]);

			count++;
			
			WriteFileLine(file, "	\"object_%i\"", count);
			WriteFileLine(file, "	{");
			WriteFileLine(file, "		\"despawn\"	\"1\"");
			WriteFileLine(file, "		\"origin\" \"%i %i %i\"", iOrigin[0], iOrigin[1], iOrigin[2]);
			WriteFileLine(file, "	}");
			WriteFileLine(file, "	");
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
	String_ToLower(map, map, sizeof(map));
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
		decl String:model[256], String:class[64], String:itemName[64], Float:vecOrigin[3], Float:vecAngles[3];

		new solid, item, despawn, lightspawn, i_Count; 		//Types of spawns and spawn count
		new maxammo, iAmmo;		//ammunition reserve variables for weaponry
		KvRewind(keyvalues);
		for(new count=1; count <= max; count++)
		{
			Format(name, sizeof(name), "object_%i", count);
			if(KvJumpToKey(keyvalues, name))
			{
				solid = KvGetNum(keyvalues, "solid");
				item = KvGetNum(keyvalues, "item", 0);	//for backwards compatibility with my old saving convention
				i_Count = KvGetNum(keyvalues, "count", -1);
				despawn = KvGetNum(keyvalues, "despawn", 0);
				iAmmo = KvGetNum(keyvalues, "ammo", -1);
				lightspawn = KvGetNum(keyvalues, "light", 0);
				KvGetVector(keyvalues, "origin", vecOrigin);
				KvGetVector(keyvalues, "angles", vecAngles);
				KvGetString(keyvalues, "model", model, sizeof(model));
				KvGetString(keyvalues, "classname", class, sizeof(class));
				

				new EntCount = GetEntityCount();		// ENTITY COUNT
				new prop = -1;
				
				KvRewind(keyvalues);
				if (despawn)
				{
					//DESPAWNER
					
					for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
					{
						if(!g_bDespawned[i])
						{
							g_bDespawned[i] = true;
							g_fDespawned[i] = vecOrigin;
							i = (sizeof(g_bDespawned) - 1);
						}
					}
					
					//Loop through the entities and despawn those that are near the 'despawners'
					for (new i = 0; i <= EntCount; i++)
					{
						if (IsValidEntity(i))
						{
							GetEdictClassname(i, class, sizeof(class));
							if(StrEqual(class, "prop_physics")
							|| StrEqual(class, "prop_dynamic")
							|| StrEqual(class, "prop_physics_override")
							|| StrEqual(class, "prop_dynamic_override")
							|| StrContains(class, "weapon_", false) != -1)
							{
								new Float:Location[3];
								GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
								if(GetVectorDistance(vecOrigin, Location, false) < MAX_DESPAWN_RANGE)
								{
									AcceptEntityInput(i, "Kill");
									LogPlugin("Killed an entity spawn");
									i = EntCount + 1;
								}
							}
						}
					}
				}
				else if(lightspawn)	
				{
					//Light spawner

					if(!IsModelPrecached("models/props_equipment/light_floodlight.mdl"))
					{
						if(PrecacheModel("models/props_equipment/light_floodlight.mdl") <= 0)
						{
							LogPlugin("The work lamp model failed to cache.  aborting...");
							return;
						}
					}
					
					new Float:lAng[3], Float:lOrigin[3];
					
					if(StrEqual(class, "prop_physics"))
					{
						prop = CreateEntityByName("prop_physics_override");
						LogPlugin("%s%i was detected as physics light", class, prop);
						new String:kvString[256];
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_worklight%i", prop);
						DispatchKeyValue(prop, "model", "models/props_equipment/light_floodlight.mdl");
						DispatchKeyValue(prop, "skin", "1");
						DispatchKeyValue(prop, "targetname", kvString);
						
						Format(kvString, sizeof(kvString), "OnHealthChanged l4d2_spawn_props_light%i,LightOff,,0,-1", prop);
						SetVariantString(kvString);
						AcceptEntityInput(prop, "AddOutput");
						Format(kvString, sizeof(kvString), "OnHealthChanged l4d2_spawn_props_worklight%i,Skin,0,0,-1", prop);
						SetVariantString(kvString);
						AcceptEntityInput(prop, "AddOutput");
						
						DispatchKeyValueVector(prop, "angles", vecAngles);
						DispatchSpawn(prop);
						TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
						
						g_bLight[prop] = true;		//set the work light into the array so it can be saved

						lOrigin[0] = vecOrigin[0];
						lOrigin[1] = vecOrigin[1];
						lOrigin[2] = vecOrigin[2];
						lAng[0] = vecAngles[0];
						lAng[1] = vecAngles[1];
						lAng[2] = vecAngles[2];
						
						lOrigin[2] = vecOrigin[2] + 80.0;
						lAng[0] = vecAngles[0] + 15.0;
						lAng[2] = vecAngles[2] + -93.7;

						new light = CreateEntityByName("point_spotlight");
						DispatchKeyValue(light, "rendercolor", "250 210 170");
						DispatchKeyValue(light, "rendermode", "9");
						DispatchKeyValue(light, "spotlightwidth", "80");
						DispatchKeyValue(light, "spotlightlength", "260");
						DispatchKeyValue(light, "renderamt", "180");
						DispatchKeyValue(light, "spawnflags", "1");
						
						DispatchKeyValueVector(light, "angles", lAng);
						DispatchKeyValueFloat(light, "pitch", lAng[0]);
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_light%i", prop);
						DispatchKeyValue(light, "targetname", kvString);
						
						DispatchSpawn(light);				//DISPATCH SPAWN LIGHT ENTITY
						AcceptEntityInput(light, "TurnOn");

						TeleportEntity(light, lOrigin, NULL_VECTOR, NULL_VECTOR);		//teleport the light entity to the worklight model using the offsets
					}
					else if(StrEqual(class, "prop_dynamic"))
					{
						prop = CreateEntityByName("prop_dynamic_override");
						LogPlugin("%s%i was detected as static light", class, prop);
						new String:kvString[256];
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_worklight%i", prop);
						DispatchKeyValue(prop, "model", "models/props_equipment/light_floodlight.mdl");
						DispatchKeyValue(prop, "skin", "1");
						DispatchKeyValue(prop, "targetname", kvString);
						SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
						
						DispatchKeyValueVector(prop, "angles", vecAngles);
						DispatchSpawn(prop);
						TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
						
						g_bLight[prop] = true;		//set the work light into the array so it can be saved
						
						lOrigin[0] = vecOrigin[0];
						lOrigin[1] = vecOrigin[1];
						lOrigin[2] = vecOrigin[2];
						lAng[0] = vecAngles[0];
						lAng[1] = vecAngles[1];
						lAng[2] = vecAngles[2];
						
						lOrigin[2] = vecOrigin[2] + 80.0;
						lAng[0] = vecAngles[0] + 15.0;
						lAng[2] = vecAngles[2] + -93.7;

						new light = CreateEntityByName("point_spotlight");
						DispatchKeyValue(light, "rendercolor", "250 210 170");
						DispatchKeyValue(light, "rendermode", "9");
						DispatchKeyValue(light, "spotlightwidth", "80");
						DispatchKeyValue(light, "spotlightlength", "260");
						DispatchKeyValue(light, "renderamt", "180");
						DispatchKeyValue(light, "spawnflags", "1");

						DispatchKeyValueVector(light, "angles", lAng);
						DispatchKeyValueFloat(light, "pitch", lAng[0]);
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_light%i", prop);
						DispatchKeyValue(light, "targetname", kvString);
						
						DispatchSpawn(light);				//DISPATCH SPAWN LIGHT ENTITY
						AcceptEntityInput(light, "TurnOn");

						TeleportEntity(light, lOrigin, NULL_VECTOR, NULL_VECTOR);		//teleport the light entity to the worklight model using the offsets
					}
					g_vecEntityAngles[prop] = vecAngles;
					g_vecEntityOrigin[prop] = vecOrigin;
				}
				else if(item)		//if its an item...
				{
					if(i_Count == -1)	//item or spawn?
					{
						//Remove weapon_ from item names for easier compares
						strcopy(itemName, sizeof(itemName), class);
						ReplaceString(itemName, sizeof(itemName), "weapon_", "", false);
						maxammo = 0;	//set max to zero then check to see if different value is appropriate
						if (StrEqual(itemName, "rifle", false) || StrEqual(itemName, "rifle_ak47", false) || StrEqual(itemName, "rifle_desert", false) || StrEqual(itemName, "rifle_sg552", false))
						{
							maxammo = GetConVarInt(AssaultMaxAmmo);
						}
						else if (StrContains(itemName, "smg", false) != -1)
						{
							maxammo = GetConVarInt(SMGMaxAmmo);
						}		
						else if (StrEqual(itemName, "pumpshotgun", false) || StrEqual(itemName, "shotgun_chrome", false))
						{
							maxammo = GetConVarInt(ShotgunMaxAmmo);
						}
						else if (StrEqual(itemName, "autoshotgun", false) || StrEqual(itemName, "shotgun_spas", false))
						{
							maxammo = GetConVarInt(AutoShotgunMaxAmmo);
						}
						else if (StrEqual(itemName, "hunting_rifle", false))
						{
							maxammo = GetConVarInt(HRMaxAmmo);
						}	
						else if (StrContains(itemName, "sniper", false) != -1)
						{
							maxammo = GetConVarInt(SniperRifleMaxAmmo);
						}
						else if (StrEqual(itemName, "grenade_launcher", false))
						{
							maxammo = GetConVarInt(GrenadeLauncherMaxAmmo);
						}
						
						prop = CreateEntityByName(class);

						if (IsValidEntity(prop))
						{	
							g_vecLastEntityAngles[client][0] = vecAngles[0];
							g_vecLastEntityAngles[client][1] = vecAngles[1];
							g_vecLastEntityAngles[client][2] = vecAngles[2];
							DispatchKeyValueVector(prop, "angles", vecAngles);
							
							//If melee...
							if (StrContains(class, "melee", false) != -1)
							{
								DispatchKeyValue(prop, "melee_script_name", model);
							}
							
							DispatchSpawn(prop); //Spawn weapon (entity)
							
							if(maxammo)		//If maxammo is any value other than zero, the item must be a primary weapon
							{
								if (iAmmo == -1)
								{
									SetEntProp(prop, Prop_Send, "m_iExtraPrimaryAmmo", maxammo, 4); //Adds max ammo for weapon  -1 is the value
								}
								else if (iAmmo > 0)		// if the ammo is not 'empty'
								{
									SetEntProp(prop, Prop_Send, "m_iExtraPrimaryAmmo", iAmmo, 4); //Adds ammo amount according to the save file
								}
							}
							
							DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");

							TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);		//Teleport spawned weapon
							g_bSpawned[prop] = true;
							g_bItem[prop] = true;
							g_iAmmo[prop] = iAmmo;
							g_vecEntityAngles[prop] = vecAngles;
							g_vecEntityOrigin[prop] = vecOrigin;
						}
					}
					else	//If its a SPAWN, not an item...
					{
						prop = CreateEntityByName(class);
						if (IsValidEntity(prop))
						{								
							DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
							
							g_vecLastEntityAngles[client][0] = vecAngles[0];
							g_vecLastEntityAngles[client][1] = vecAngles[1];
							g_vecLastEntityAngles[client][2] = vecAngles[2];
							DispatchKeyValueVector(prop, "angles", vecAngles);
							
							if(i_Count > 0)
							{
								new String:sCount[16];
								IntToString(i_Count, sCount, sizeof(sCount));
								DispatchKeyValue(prop, "count", sCount);
							}
							
							//If melee...
							if (StrContains(class, "melee", false) != -1)
							{
								DispatchKeyValue(prop, "melee_weapon", model);
							}
							
							SetEntProp(prop, Prop_Send, "m_nSolidType", 0);
							
							DispatchKeyValue(prop, "spawnflags", "2");
							DispatchKeyValue(prop, "skin", "0");
							DispatchKeyValue(prop, "disableshadows", "1");
							
							DispatchSpawn(prop); //Spawn weapon (entity)
							
							TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);		//Teleport spawned spawn
							
							SetEntityMoveType(prop, MOVETYPE_PUSH);
							
							g_bSpawned[prop] = true;
							g_bItem[prop] = true;
							g_vecEntityAngles[prop] = vecAngles;
							g_vecEntityOrigin[prop] = vecOrigin;
						}
					}
					
					
				}
				else if(StrContains(class, "prop_physics") >= 0)
				{
					prop = CreateEntityByName("prop_physics_override");
					DispatchKeyValue(prop, "model", model);
					DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
					DispatchSpawn(prop);
					g_vecLastEntityAngles[client][0] = vecAngles[0];
					g_vecLastEntityAngles[client][1] = vecAngles[1];
					g_vecLastEntityAngles[client][2] = vecAngles[2];
					DispatchKeyValueVector(prop, "angles", vecAngles);
					DispatchSpawn(prop);
					TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					g_bSpawned[prop] = true;
					g_vecEntityAngles[prop] = vecAngles;
					g_vecEntityOrigin[prop] = vecOrigin;					
				}
				else
				{
					//If the object needs to be prop_dynamic to function properly then set appropriate values
					if(StrContains(model, "fire_escape_wide_upper.mdl", false) != -1 || StrContains(model, "fire_escape_upper.mdl", false) != -1)
					{
						prop = CreateEntityByName("prop_dynamic");
						DispatchKeyValue(prop, "disableshadows", "1");
						DispatchKeyValue(prop, "fademaxdist", "1524");
						DispatchKeyValue(prop, "fademindist", "1093");
					}
					else
					{
						prop = CreateEntityByName("prop_dynamic_override");
					}
					
					SetEntProp(prop, Prop_Send, "m_nSolidType", solid);
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
			
			}
			else
			{
				break;
			}
		}
		propCount += max;
	}

	CloseHandle(keyvalues);
	PrintToChat(client, "\x03[SM] Succesfully loaded the map data");
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

public Action:CmdPropz(client, args)
{
	new pCount, iCount, lCount, dCount, String:classname[128];
	
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i])
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrContains(classname, "physics", false) != -1)
			{
				pCount++;
			}
		}
	}
	
	for(new i=0; i < (sizeof(g_bItem) - 1); i++)
	{
		if(g_bItem[i]) iCount++;
	}
	for(new i=0; i < (sizeof(g_bLight) - 1); i++)
	{
		if(g_bLight[i]) lCount++;
	}
	for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
	{
		if(g_bDespawned[i]) dCount++;
	}

	PrintToChat(client, "\x03Spawned objects:  %i", propCount);
	if(pCount) PrintToChat(client, "\x03%i are physics objects", pCount);
	if(iCount) PrintToChat(client, "\x03%i are items/weapons", iCount);
	if(lCount) PrintToChat(client, "\x03%i are lights", lCount);
	if(dCount) PrintToChat(client, "\x03%i are despawners", dCount);
	
	return Plugin_Handled;
}

public Action:CmdRemoveLook(client, args)
{
	DeleteLookingEntity(client);
	return Plugin_Handled;
}

public Action:CmdSelectLook(client, args)
{
	SelectLookingEntity(client);
	return Plugin_Handled;
}

public Action:CmdSetLook(client, args)
{
	SetLookingEntity(client);
	return Plugin_Handled;
}
public Action:CmdSetLast(client, args)
{
	SetLastEntity(client);
	return Plugin_Handled;
}

public Action:CmdKillLook(client, args)
{
	KillLookingEntity(client);
	return Plugin_Handled;
}

public Action:CmdClearKills(client, args)
{
	for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
	{
		g_bDespawned[i] = false;
	}
	PrintToChat(client, "Object-despawners cleared from map.");
	
	
	propCount = 0;
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			propCount += 1;
		}
	}
	
	return Plugin_Handled;
}

	
public Action:cmdRemoveByName(client,args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removebyname <string-to-match>");
		return Plugin_Handled;
	}
	new count;
	decl String:text[256], String:sModel[256];
	GetCmdArgString(text, sizeof(text));

	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			if(StrContains(sModel, text, false) != -1)
			{
				AcceptEntityInput(i, "KillHierarchy");
				propCount += -1;
				g_bSpawned[i] = false;
				g_bUnsolid[i] = false;
				g_bItem[i] = false;
				g_iAmmo[i] = 0;
				g_vecEntityAngles[i][0] = 0.0;
				g_vecEntityAngles[i][1] = 0.0;
				g_vecEntityAngles[i][2] = 0.0;
				g_vecEntityOrigin[i][0] = 0.0;
				g_vecEntityOrigin[i][1] = 0.0;
				g_vecEntityOrigin[i][2] = 0.0;
				g_bGrab[client] = false;
				g_bGrabbed[i] = false;
				if(i == g_iLastGrabbedObject[client])
				{
					g_iLastGrabbedObject[client] = -1;
				}
				count += 1;
			}
		}
	}
	
	PrintToChat(client, "\x03%i objects removed.", count);

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
				PrintToChatAll("\x03Spawned objects: %i", propCount);
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
	if(!FileExists(KvFileName))
	{
		//LogError("Attempted to load an object file which does not exist (%s)", KvFileName);
		LogPlugin("[ERROR] Attempted to load an object file which does not exist (%s)", KvFileName);
		return;
	}
	LogPlugin("Spawning objects from file %s", KvFileName);
	PrintToServer("[Object Spawner] spawning objects from %s", KvFileName);
	
	keyvalues = CreateKeyValues("Objects_Cache");
	FileToKeyValues(keyvalues, KvFileName);
	KvRewind(keyvalues);
	if(KvJumpToKey(keyvalues, "total_cache"))
	{
		new max = KvGetNum(keyvalues, "total", 0);
		LogPlugin("prop count: %i", max);	
		if(max <= 0)
		{
			LogError("[Object Spawner] No Objects found for the map number cache");
			LogPlugin("[ERROR] No Objects found for the map number cache");
			return;
		}
		decl String:model[256], String:class[64], String:itemName[64], Float:vecOrigin[3], Float:vecAngles[3];


		//PRECACHE ALL PROPS
		new isItem, isDespawn, pCount=0;
		KvRewind(keyvalues);
		for(new count=1; count <= max; count++)
		{
			Format(name, sizeof(name), "object_%i", count);
			if(KvJumpToKey(keyvalues, name))
			{
				isItem = KvGetNum(keyvalues, "item", 0);
				isDespawn = KvGetNum(keyvalues, "despawn", 0);
				KvGetString(keyvalues, "model", model, sizeof(model));	
				
				KvRewind(keyvalues);

				if (!isItem && !isDespawn)
				{
					if(!IsModelPrecached(model))
					{
						PrecacheModel(model);
						//LogSpawn("Object#%i precached. %s", count, model);
						pCount++;
					}
				}
			}
		}
		
		printToRoot("Loading %i objects...", max);
		if(pCount)
		{
			printToRoot("Precached: %i", pCount);
		}
		
 		new solid, item, despawn, lightspawn, i_Count;
		new maxammo, iAmmo;		//ammunition reserve variables for weaponry
		KvRewind(keyvalues);
		for(new count=1; count <= max; count++)
		{
			Format(name, sizeof(name), "object_%i", count);
			if(KvJumpToKey(keyvalues, name))
			{	
				solid = KvGetNum(keyvalues, "solid");
				item = KvGetNum(keyvalues, "item", 0);
				i_Count = KvGetNum(keyvalues, "count", -1);
				iAmmo = KvGetNum(keyvalues, "ammo", -1);
				despawn = KvGetNum(keyvalues, "despawn", 0);
				lightspawn = KvGetNum(keyvalues, "light", 0);
				KvGetVector(keyvalues, "origin", vecOrigin);
				KvGetVector(keyvalues, "angles", vecAngles);
				KvGetString(keyvalues, "model", model, sizeof(model));
				KvGetString(keyvalues, "classname", class, sizeof(class));
				
				new EntCount = GetEntityCount();		// ENTITY COUNT
				new prop = -1;
				
				KvRewind(keyvalues);

 				if (despawn)
				{
					//DESPAWNER
					for(new i=0; i < (sizeof(g_bDespawned) - 1); i++)
					{
						if(!g_bDespawned[i])
						{
							g_bDespawned[i] = true;
							g_fDespawned[i] = vecOrigin;
							break;
						}
					}
					
					for (new i = 0; i <= EntCount; i++)
					{
						if (IsValidEntity(i))
						{
							GetEdictClassname(i, class, sizeof(class));
							if(StrEqual(class, "prop_physics")
							|| StrEqual(class, "prop_dynamic")
							|| StrEqual(class, "prop_physics_override")
							|| StrEqual(class, "prop_dynamic_override")
							|| StrContains(class, "weapon_", false) != -1)
							{
								new Float:Location[3];
								GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
								if(GetVectorDistance(vecOrigin, Location, false) < MAX_DESPAWN_RANGE)
								{
									AcceptEntityInput(i, "Kill");
									LogPlugin("Killed an entity (sm_despawn)");
									i = EntCount + 1;
								}
							}
						}
					}
				} 
 				else if(lightspawn)	
				{
					//Light spawner

					if(!IsModelPrecached("models/props_equipment/light_floodlight.mdl"))
					{
						if(PrecacheModel("models/props_equipment/light_floodlight.mdl") <= 0)
						{
							LogPlugin("The work lamp model failed to cache.  aborting...");
							return;
						}
					}
					
					new Float:lAng[3], Float:lOrigin[3];
					
					if(StrEqual(class, "prop_physics"))			////// DESTRUCTIBLE WORK LAMP
					{
						prop = CreateEntityByName("prop_physics_override");
						new String:kvString[256];
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_worklight%i", prop);
						DispatchKeyValue(prop, "model", "models/props_equipment/light_floodlight.mdl");
						DispatchKeyValue(prop, "skin", "1");
						DispatchKeyValue(prop, "targetname", kvString);
						
						Format(kvString, sizeof(kvString), "OnHealthChanged l4d2_spawn_props_light%i,LightOff,,0,-1", prop);
						SetVariantString(kvString);
						AcceptEntityInput(prop, "AddOutput");
						Format(kvString, sizeof(kvString), "OnHealthChanged l4d2_spawn_props_worklight%i,Skin,0,0,-1", prop);
						SetVariantString(kvString);
						AcceptEntityInput(prop, "AddOutput");
						
						DispatchKeyValueVector(prop, "angles", vecAngles);
						DispatchSpawn(prop);
						TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
						
						g_bLight[prop] = true;		//set the work light into the array so it can be saved
						
						lOrigin[0] = vecOrigin[0];
						lOrigin[1] = vecOrigin[1];
						lOrigin[2] = vecOrigin[2];
						lAng[0] = vecAngles[0];
						lAng[1] = vecAngles[1];
						lAng[2] = vecAngles[2];
						
						lOrigin[2] = vecOrigin[2] + 80.0;
						lAng[0] = vecAngles[0] + 15.0;
						lAng[2] = vecAngles[2] + -93.7;

						new light = CreateEntityByName("point_spotlight");
						DispatchKeyValue(light, "rendercolor", "250 210 170");
						DispatchKeyValue(light, "rendermode", "9");
						DispatchKeyValue(light, "spotlightwidth", "80");
						DispatchKeyValue(light, "spotlightlength", "260");
						DispatchKeyValue(light, "renderamt", "180");
						DispatchKeyValue(light, "spawnflags", "1");
						
						DispatchKeyValueVector(light, "angles", lAng);
						DispatchKeyValueFloat(light, "pitch", lAng[0]);
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_light%i", prop);
						DispatchKeyValue(light, "targetname", kvString);
						
						DispatchSpawn(light);				//DISPATCH SPAWN LIGHT ENTITY
						AcceptEntityInput(light, "TurnOn");

						TeleportEntity(light, lOrigin, NULL_VECTOR, NULL_VECTOR);		//teleport the light entity to the worklight model using the offsets
					}
					else if(StrEqual(class, "prop_dynamic"))					///// INDESTRUCTABLE WORK LAMP
					{
						prop = CreateEntityByName("prop_dynamic_override");
						new String:kvString[256];
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_worklight%i", prop);
						DispatchKeyValue(prop, "model", "models/props_equipment/light_floodlight.mdl");
						DispatchKeyValue(prop, "skin", "1");
						DispatchKeyValue(prop, "targetname", kvString);
						SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
						
						DispatchKeyValueVector(prop, "angles", vecAngles);
						DispatchSpawn(prop);
						TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
						
						g_bLight[prop] = true;		//set the work light into the array so it can be saved
						
						lOrigin[0] = vecOrigin[0];
						lOrigin[1] = vecOrigin[1];
						lOrigin[2] = vecOrigin[2];
						lAng[0] = vecAngles[0];
						lAng[1] = vecAngles[1];
						lAng[2] = vecAngles[2];
						
						lOrigin[2] = vecOrigin[2] + 80.0;
						lAng[0] = vecAngles[0] + 15.0;
						lAng[2] = vecAngles[2] + -93.7;

						new light = CreateEntityByName("point_spotlight");
						DispatchKeyValue(light, "rendercolor", "250 210 170");
						DispatchKeyValue(light, "rendermode", "9");
						DispatchKeyValue(light, "spotlightwidth", "80");
						DispatchKeyValue(light, "spotlightlength", "260");
						DispatchKeyValue(light, "renderamt", "180");
						DispatchKeyValue(light, "spawnflags", "1");

						DispatchKeyValueVector(light, "angles", lAng);
						DispatchKeyValueFloat(light, "pitch", lAng[0]);
						Format(kvString, sizeof(kvString), "l4d2_spawn_props_light%i", prop);
						DispatchKeyValue(light, "targetname", kvString);
						
						DispatchSpawn(light);				//DISPATCH SPAWN LIGHT ENTITY
						AcceptEntityInput(light, "TurnOn");

						TeleportEntity(light, lOrigin, NULL_VECTOR, NULL_VECTOR);		//teleport the light entity to the worklight model using the offsets
					}
					g_vecEntityAngles[prop] = vecAngles;
					g_vecEntityOrigin[prop] = vecOrigin;
				} 
 				else if(item)		//if its an item
				{
					if(i_Count == -1)	//item or spawn?
					{	
						//strip weapon_ from item names for easier compares
						strcopy(itemName, sizeof(itemName), class);
						ReplaceString(itemName, sizeof(itemName), "weapon_", "", false);
						maxammo = 0;	
						
						if (StrEqual(itemName, "rifle", false) || StrEqual(itemName, "rifle_ak47", false) || StrEqual(itemName, "rifle_desert", false) || StrEqual(itemName, "rifle_sg552", false))
						{
							maxammo = GetConVarInt(AssaultMaxAmmo);
						}
						else if (StrContains(itemName, "smg", false) != -1)
						{
							maxammo = GetConVarInt(SMGMaxAmmo);
						}		
						else if (StrEqual(itemName, "pumpshotgun", false) || StrEqual(itemName, "shotgun_chrome", false))
						{
							maxammo = GetConVarInt(ShotgunMaxAmmo);
						}
						else if (StrEqual(itemName, "autoshotgun", false) || StrEqual(itemName, "shotgun_spas", false))
						{
							maxammo = GetConVarInt(AutoShotgunMaxAmmo);
						}
						else if (StrEqual(itemName, "hunting_rifle", false))
						{
							maxammo = GetConVarInt(HRMaxAmmo);
						}	
						else if (StrContains(itemName, "sniper", false) != -1)
						{
							maxammo = GetConVarInt(SniperRifleMaxAmmo);
						}
						else if (StrEqual(itemName, "grenade_launcher", false))
						{
							maxammo = GetConVarInt(GrenadeLauncherMaxAmmo);
						}

						prop = CreateEntityByName(class);
						
						
						
						if(IsValidEntity(prop))
						{							
							DispatchKeyValueVector(prop, "angles", vecAngles);
							
							//If melee...
							if (StrContains(class, "melee", false) != -1)
							{
								DispatchKeyValue(prop, "melee_script_name", model);
							}
							
							
							DispatchSpawn(prop); //Spawn weapon
							
							if(maxammo)		//If maxammo is any value other than zero, the item must be a primary weapon
							{
								if (iAmmo == -1)		//if the ammo is 'full'
								{
									SetEntProp(prop, Prop_Send, "m_iExtraPrimaryAmmo", maxammo, 4); //Adds max ammo for weapon
								}
								else if (iAmmo > 0)		// if the ammo is not 'empty'
								{
									SetEntProp(prop, Prop_Send, "m_iExtraPrimaryAmmo", iAmmo, 4); //Adds ammo amount according to the save file
								}
							}

							TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);		//Teleport spawned weapon
							g_bSpawned[prop] = true;
							g_bItem[prop] = true;
							g_iAmmo[prop] = iAmmo;
							
							DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop"); 
							
							g_vecEntityAngles[prop] = vecAngles;
							g_vecEntityOrigin[prop] = vecOrigin;

						}
					}
					else	//IF ITS A SPAWNED SPAWN  not an 'item'
					{
						prop = CreateEntityByName(class);
						if(IsValidEntity(prop))
						{	
							DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");

							DispatchKeyValueVector(prop, "angles", vecAngles);
							
							//If melee...
							if (StrContains(class, "melee", false) != -1)
							{
								DispatchKeyValue(prop, "melee_weapon", model);
							}

							if(i_Count >= 1)
							{
								new String:sCount[16];
								IntToString(i_Count, sCount, sizeof(sCount));
								DispatchKeyValue(prop, "count", sCount);
							}
							
							SetEntProp(prop, Prop_Send, "m_nSolidType", 0);
							
							DispatchKeyValue(prop, "spawnflags", "2");
							DispatchKeyValue(prop, "skin", "0");
							DispatchKeyValue(prop, "disableshadows", "1");
							
							DispatchSpawn(prop); //Spawn weapon (entity)

							TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);		//Teleport spawned weapon
							
							SetEntityMoveType(prop, MOVETYPE_PUSH);
							
							g_bSpawned[prop] = true;
							g_bItem[prop] = true;
							g_vecEntityAngles[prop] = vecAngles;
							g_vecEntityOrigin[prop] = vecOrigin;

						}
					}
				} 
				else if(StrContains(class, "prop_physics") >= 0)
				{
					prop = CreateEntityByName("prop_physics_override");
					DispatchKeyValue(prop, "model", model);
					DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
					DispatchSpawn(prop);
					DispatchKeyValueVector(prop, "angles", vecAngles);
					DispatchSpawn(prop);
					TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					g_bSpawned[prop] = true;
					g_vecEntityAngles[prop] = vecAngles;
					g_vecEntityOrigin[prop] = vecOrigin;

				}
				else
				{
					//If the object needs to be prop_dynamic to function properly then set appropriate values
					if(StrContains(model, "fire_escape_wide_upper.mdl", false) != -1 || StrContains(model, "fire_escape_upper.mdl", false) != -1)
					{
						prop = CreateEntityByName("prop_dynamic");
						DispatchKeyValue(prop, "disableshadows", "1");
						DispatchKeyValue(prop, "fademaxdist", "1524");
						DispatchKeyValue(prop, "fademindist", "1093");
					}
					else
					{
						prop = CreateEntityByName("prop_dynamic_override");
					}

					SetEntProp(prop, Prop_Send, "m_nSolidType", solid);
					DispatchKeyValue(prop, "model", model);
					DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
					
					DispatchKeyValueVector(prop, "angles", vecAngles);
					DispatchSpawn(prop);
					TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					g_bSpawned[prop] = true;
					g_vecEntityAngles[prop] = vecAngles;	
				}
			
			}
/* 			else
			{
				break;
			} */
		}
		if(xioDebug)
		{
			PrintToServer("Object Spawner appeared to load objects...");
		} 
		propCount += max;
	}
	CloseHandle(keyvalues);
}
stock CreateInitFile()
{
	decl String:FileName[256], String:map[256];
	new Handle:file = INVALID_HANDLE;
	GetCurrentMap(map, sizeof(map));
	String_ToLower(map, map, sizeof(map));
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/maps/plugin_cache/%s_init.txt", map);
	
	if(!FileExists(FileName))
	{
		file = OpenFile(FileName, "a+");
		if(file == INVALID_HANDLE)
		{
			return;
		}
		WriteFileLine(file, "//Init file for map %s", map);
		WriteFileLine(file, "//");
		WriteFileLine(file, "//The format of the file is:");
		WriteFileLine(file, "//");
		WriteFileLine(file, "//	\"coop\" --------> This is the gamemode where the following object list will be loaded");
		WriteFileLine(file, "//	{");
		WriteFileLine(file, "//		\"total\"	\"2\"");
		WriteFileLine(file, "//		\"path1\"	\"%s_1\"", map);
		WriteFileLine(file, "//		\"path2\"	\"%s_2\"", map);
		WriteFileLine(file, "//	}");
		WriteFileLine(file, "//");
		WriteFileLine(file, "//	Total needs to be set to the number of paths");
		WriteFileLine(file, "//	In this example the plugin will choose to load c5m2_park_1.txt or c5m2_park_2.txt");
		WriteFileLine(file, "//");
		
		WriteFileLine(file, "");
		WriteFileLine(file, "\"PathInit\"");
		WriteFileLine(file, "{");
		WriteFileLine(file, "	\"coop\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"realism\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"versus\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"mutation12\"");
		WriteFileLine(file, "	{");
		WriteFileLine(file, "		");
		WriteFileLine(file, "	}");
		WriteFileLine(file, "	");
		WriteFileLine(file, "	\"community6\"");
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
	String_ToLower(sMap, sMap, sizeof(sMap));
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/maps/plugin_cache/%s_init.txt", sMap);
	if(!FileExists(KvFileName))
	{
		LogPlugin("%s does not have an init file.", sMap);
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
			LogPlugin("%s gamemode is not in the init file", GameMode);
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
	
	if (g_bItem[Object])
	{
		vecPosition = g_vecEntityOrigin[Object];
	}
	
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
	
	g_vecEntityOrigin[Object][0] = vecPosition[0];
	g_vecEntityOrigin[Object][1] = vecPosition[1];
	g_vecEntityOrigin[Object][2] = vecPosition[2];
	
	return Plugin_Handled;
}

public Action:CmdNudge(client, args)
{
	if(args > 1)
	{
		PrintToChat(client, "[SM] Usage: sm_prop_nudge <OPTIONAL:force> [EX: !prop_nudge 3]");
		return Plugin_Handled;
	}
	new Object = g_iLastObject[client];
	decl String:arg1[16];
	new Float:fForce;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if(args == 1)	fForce = StringToFloat(arg1);
	else			fForce = 0.1;
	
	decl Float:newVel[3];
	newVel[0] = 0.0;
	newVel[1] = 0.0;
	newVel[2] = fForce;
	TeleportEntity(Object, NULL_VECTOR, NULL_VECTOR, newVel);

	g_bGrab[client] = false;
	g_bGrabbed[Object] = false;
	
	return Plugin_Handled;
}

public Action:CmdCount(client, args)
{
	new Object = g_iLastObject[client];
	new i_Count = GetEntData(Object, FindDataMapOffs(Object, "m_itemCount"), 4);
	g_bGrab[client] = false;
	g_bGrabbed[Object] = false;
	PrintToChat(client, "Count: %i", i_Count);
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
		|| StrEqual(class, "prop_dynamic_override")
		|| StrContains(class, "weapon_", false) != -1)
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
			g_bItem[Object] = false;
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
		|| StrEqual(class, "prop_dynamic_override")
		|| StrContains(class, "weapon_", false) != -1)
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
			g_bItem[Object] = false;
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
	if(!g_bGrab[client] && g_bGrabbed[Object])
	{
		PrintToChat(client, "[SM] Someone is already grabbing the Object");
		return;
	}

	if(Object > 0 && IsValidEntity(Object))
	{
		decl String:class[256];
		GetEdictClassname(Object, class, sizeof(class));
		if(StrEqual(class, "prop_physics")
		|| StrEqual(class, "prop_dynamic")
		|| StrEqual(class, "prop_physics_override")
		|| StrEqual(class, "prop_dynamic_override")
		|| StrContains(class, "weapon_", false) != -1)
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
			g_bItem[Object] = false;
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
		|| StrEqual(class, "prop_dynamic_override")
		|| StrContains(class, "weapon_", false) != -1)
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
			g_bItem[Object] = false;
			g_iAmmo[Object] = 0;
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

stock GetInGameClient()
{
	for( new x = 1; x <= GetClientCount( true ); x++ )
	{
		if( IsClientInGame( x ) && GetClientTeam( x ) == 2 )
		{
			return x;
		}
	}
	return 0;
}

static PrecacheWeaponModels()
{
	//atomicstryker's precache weapon code.
	//Precache weapon models if they're not loaded.
	CheckModelPreCache("models/w_models/weapons/w_rifle_sg552.mdl");
	CheckModelPreCache("models/w_models/weapons/w_smg_mp5.mdl");
	CheckModelPreCache("models/w_models/weapons/w_sniper_awp.mdl");
	CheckModelPreCache("models/w_models/weapons/w_sniper_scout.mdl");
	CheckModelPreCache("models/w_models/weapons/w_eq_bile_flask.mdl");
	CheckModelPreCache("models/w_models/weapons/w_eq_adrenaline.mdl");
	CheckModelPreCache("models/v_models/v_rif_sg552.mdl");
	CheckModelPreCache("models/v_models/v_smg_mp5.mdl");
	CheckModelPreCache("models/v_models/v_snip_awp.mdl");
	CheckModelPreCache("models/v_models/v_snip_scout.mdl");
	CheckModelPreCache("models/v_models/v_bile_flask.mdl");
	CheckModelPreCache("models/w_models/weapons/w_m60.mdl");
	CheckModelPreCache("models/v_models/v_m60.mdl");
	CheckModelPreCache("models/v_models/v_adrenaline.mdl");
	
	CheckModelPreCache("models/weapons/melee/w_bat.mdl");
	CheckModelPreCache("models/weapons/melee/w_chainsaw.mdl");
	CheckModelPreCache("models/weapons/melee/w_cricket_bat.mdl");
	CheckModelPreCache("models/weapons/melee/w_crowbar.mdl");
	CheckModelPreCache("models/weapons/melee/w_electric_guitar.mdl");
	CheckModelPreCache("models/weapons/melee/w_fireaxe.mdl");
	CheckModelPreCache("models/weapons/melee/w_frying_pan.mdl");
	CheckModelPreCache("models/weapons/melee/w_gnome.mdl");
	CheckModelPreCache("models/weapons/melee/w_katana.mdl");
	CheckModelPreCache("models/weapons/melee/w_machete.mdl");
	CheckModelPreCache("models/weapons/melee/w_tonfa.mdl");
	
	CheckModelPreCache("models/weapons/melee/v_bat.mdl");
	CheckModelPreCache("models/weapons/melee/v_chainsaw.mdl");
	CheckModelPreCache("models/weapons/melee/v_cricket_bat.mdl");
	CheckModelPreCache("models/weapons/melee/v_crowbar.mdl");
	CheckModelPreCache("models/weapons/melee/v_electric_guitar.mdl");
	CheckModelPreCache("models/weapons/melee/v_fireaxe.mdl");
	CheckModelPreCache("models/weapons/melee/v_frying_pan.mdl");
	CheckModelPreCache("models/weapons/melee/v_gnome.mdl");
	CheckModelPreCache("models/weapons/melee/v_katana.mdl");
	CheckModelPreCache("models/weapons/melee/v_machete.mdl");
	CheckModelPreCache("models/weapons/melee/v_tonfa.mdl");

}

stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile);
	}
}

stock checkParent()
{
	new String:pName[256], String:sModel[256];
	for(new i=MaxClients; i < ARRAY_SIZE; i++)
	{
		if(g_bSpawned[i] && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_iParent", pName, sizeof(pName));
			GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			if(StrContains(pName, "l4d2_spawn_props_fe", false) != -1 || StrContains(sModel, "truck_nuke_glass.mdl", false) != -1)
			{
				DispatchKeyValue(i, "targetname", "l4d2_spawn_props_prop");
				DispatchKeyValue(i, "parentname", "NULL_PARENT");
				AcceptEntityInput(i, "SetParent");
			}

		}
	}
}