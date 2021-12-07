/** 
* THE BLACKBOX TOOLS
* 
* Blackbox Tools is a Series of administrative tools specifically
* designed for the Orange Box engine. Some of these may include extra
* coding to increase the usability among other games, however they
* are designed with the Orange Box engine as an utmost priority.
*/

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define CAM_ADMINFLAG ADMFLAG_KICK
#define PLUGIN_VERSION "1.0.0"

new Handle:g_hTopMenu = INVALID_HANDLE;
new Handle:CameraTimers[MAXPLAYERS+1];
new ClientCamera[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "BlackBox: Admin Camera Tools",
	author = "Crimson",
	description = "Allows admins to spectate players in Realtime",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

/*=================================================*/

public OnPluginStart()
{
	RegAdminCmd("bb_observeclient", Command_Camera, CAM_ADMINFLAG);
	
	CreateConVar("bb_observeclient_version", PLUGIN_VERSION, "Blackbox Tools: Admin Camera Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new Handle:hTopMenu;
	if(LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(hTopMenu);
	
	HookGameEvents();
}

stock HookGameEvents()
{
	decl String:sGameName[32];
	
	GetGameFolderName(sGameName, sizeof(sGameName));
	
	if(strcmp(sGameName, "cstrike")==0)
		HookEvent("weapon_fire", Event_PlayerShoot);
	else if(strcmp(sGameName, "dod")==0)
		HookEvent("dod_stats_weapon_attack", Event_PlayerShoot);
	else if(strcmp(sGameName, "left4dead")==0)
		HookEvent("weapon_fire", Event_PlayerShoot);
	else if(strcmp(sGameName, "tf")==0)
		return;
	else
	{
		HookEvent("player_shoot", Event_PlayerShoot);
		LogMessage("[BB] Game Directory Not Recognized! Using Default Game Events");
	}
}

/* Cleanup Camera Stuff on Client Disconnect */
public OnClientDisconnect(client)
{
	if(CameraTimers[client] != INVALID_HANDLE)
	{
		KillTimer(CameraTimers[client]);
		CameraTimers[client] = INVALID_HANDLE;
	}
	
	if(ClientCamera[client] != 0)
	{
		ClientCamera[client] = 0;
	}
}

/*=================================================*/

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hTopMenu = INVALID_HANDLE;
	}
}

/*=================================================*/

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == g_hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	g_hTopMenu = topmenu;
	
	new TopMenuObject:blackbox_menu = AddToTopMenu(
	g_hTopMenu,				// Menu
	"bb_commands",			// Name
	TopMenuObject_Category,	// Type
	MenuHandler_Category,	// Callback
	INVALID_TOPMENUOBJECT	// Parent
	);
	
	if( blackbox_menu != INVALID_TOPMENUOBJECT )
	{
		AddToTopMenu(g_hTopMenu,
		"bb_camera",
		TopMenuObject_Item,
		MenuHandler_Camera,
		blackbox_menu,
		"bb_camera",
		CAM_ADMINFLAG);
	}
}

/*=================================================*/

public MenuHandler_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	switch( action )
	{
		case TopMenuAction_DisplayTitle:
		Format( buffer, maxlength, "Blackbox Tools" );
		case TopMenuAction_DisplayOption:
		Format( buffer, maxlength, "Blackbox Tools" );
	}
}

public MenuHandler_Camera( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format( buffer, maxlength, "Spectate Client" );
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplaySpecTargetsMenu(param);
	}
}

DisplaySpecTargetsMenu(client)
{
	new Handle:hMenu = CreateMenu(MenuHandler_CamTarget);
	SetMenuTitle(hMenu, "Spectate Clients:");
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_CamTarget(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if(action == MenuAction_Select)
	{
		decl iTarget, String:sDisplay[32], String:sInfo[32];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
		
		iTarget = GetClientOfUserId(StringToInt(sInfo));
		
		if(iTarget == 0)
		{
			PrintToChat(param1, "\x04[BB] \x01This Player is No Longer Connected.");
		}
		else if(!CanUserTarget(param1, iTarget))
		{
			PrintToChat(param1, "\x04[BB] \x01This Player Cannot be Selected.");
		}
		else
		{
			decl String:sCommand[64];
			Format(sCommand, sizeof(sCommand), "bb_observeclient %d", iTarget);
			ClientCommand(param1, sCommand);
		}
	}
}


/*=================================================*/

public Action:Command_Camera(client, args)
{
	/* If No Target is Specified */
	if (args < 1)
	{
		ReplyToCommand(client, "[BB] Usage: sm_blackbox_watchplayer <#userid>");
		return Plugin_Handled;
	}
	
	/* Create the Camera Entity */
	new entCamera = CreateEntityByName("point_viewcontrol");
	
	decl String:sWatcher[64];
	Format(sWatcher, sizeof(sWatcher), "target%i", client);
	
	decl String:sTarget[64];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	new targetIndex = StringToInt(sTarget);
	Format(sTarget, sizeof(sTarget), "target%i", targetIndex);
	
	/* Sets the clients Targetname to their Index */
	DispatchKeyValue(client, "targetname", sWatcher);
	DispatchKeyValue(targetIndex, "targetname", sTarget);
	
	if(IsValidEntity(entCamera))
	{
		//Name of the Camera Entity
		DispatchKeyValue(entCamera, "targetname", "playercam");
		//Name of the Camera Target
		DispatchKeyValue(entCamera, "target", sTarget);
		//Amount of time to stay active
		DispatchKeyValue(entCamera, "wait", "60");
		
		DispatchSpawn(entCamera);
		
		new Float:blah[3];
		GetClientAbsOrigin(client, blah);
		TeleportEntity(entCamera, blah, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString(sWatcher);
		AcceptEntityInput(entCamera, "Enable", client, entCamera, 0);
		SetVariantString(sTarget);
		AcceptEntityInput(entCamera, "SetParent", entCamera, entCamera, 0);
		SetVariantString("eyes")
		AcceptEntityInput(entCamera, "SetParentAttachment", entCamera, entCamera, 0);
		
		/* Stores the Camera index to the client */
		ClientCamera[client] = entCamera;
		CameraTimers[client] = CreateTimer(60.0, Timer_DestroyCamera, client);
	}
	
	return Plugin_Handled;
}

public Action:Timer_DestroyCamera(Handle:timer, any:client)
{
	if(ClientCamera[client] != 0)
		ClientCamera[client] = 0;

	CameraTimers[client] = INVALID_HANDLE;
}

//[GENERIC SHOOT EVENT] Destroy the Camera Entity when the Observer Fires Weapon
public Event_PlayerShoot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	DestroyCamera(client);
}

//[TF2 SHOOT CODE] Destroy the Camera Entity when the Observer Fires Weapon
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	DestroyCamera(client);
}

stock DestroyCamera(client)
{
	if(ClientCamera[client] != 0)
	{
		decl String:sWatcher[64];
		Format(sWatcher, sizeof(sWatcher), "target%i", client);
		
		/* We Must Disable first before removing, or it completely bugs out */
		SetVariantString(sWatcher);
		AcceptEntityInput(ClientCamera[client], "Disable", client, ClientCamera[client], 0);
		
		RemoveEdict(ClientCamera[client]);
		ClientCamera[client] = 0;
	}
	
	if(CameraTimers[client] != INVALID_HANDLE)
	{
		CameraTimers[client] = INVALID_HANDLE;
	}
}