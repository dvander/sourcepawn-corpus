#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#define PLUGIN_VERSION "1.50"

/* ChangeLog
1.00	Initial Creation
1.10	Better Hooks
1.20	Fixed Round Restard Issue, Stopped Counting Carriers when the Carrier Dies
1.30	Fixed Offest Issue, Fixed Hooks on Reload
1.40	Added Set Carrier
1.50	Added Admin Menu
*/

public Plugin:myinfo = {
	name = "Carrier Mod",
	author = "Will2Tango",
	description = "Change the number of Carriers.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

new Handle:MaxCarriers = INVALID_HANDLE;
new maxCarriers = 1;
new bool:isHooked = false;
new CarrierOffset = -1;

new Handle:hTopMenu = INVALID_HANDLE;

public OnPluginStart()
{
	new Handle:conf = LoadGameConfigFile("zps_carrier");
	CarrierOffset = GameConfGetOffset(conf, "IsCarrier");
	CloseHandle(conf);
	if 	(CarrierOffset == -1) {LogToGame("[CarrierMod] Offset Not Found: %i", CarrierOffset);}
	
	CreateConVar("zps_carriermod_version", PLUGIN_VERSION, "Carrier Mod Plugin Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_carrier", Command_Carrier, ADMFLAG_ROOT, "Set Player as Carrier <target>");	
	MaxCarriers = CreateConVar("sm_maxcarriers", "1", "Max Number of Carriers. (default & disabled = 1, 0 = reservation)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	HookConVarChange(MaxCarriers, GetMaxCarriers);
	
	maxCarriers = GetConVarInt(MaxCarriers);
	if (maxCarriers != 1 && isHooked == false)
	{
		HookEvent("player_spawn",PlayerSpawn);
		HookEvent("player_death", PlayerDeath);
		HookEvent("game_round_restart", NewRound, EventHookMode_PostNoCopy);
		isHooked = true;
	}
	
	new Handle:topmenu;	//For Late Loading
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {OnAdminMenuReady(topmenu);}
}

public Action:Command_Carrier(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_carrier <target>");
		return Plugin_Handled;
	}
	new String:targetId[64];//, String:arg2[64];
	GetCmdArg(1, targetId, sizeof(targetId));
//	GetCmdArg(2, arg2, sizeof(arg2));
	new target = FindTarget(client,targetId);
//	new bool:toggle = false;
//	if (StrEqual(arg2, "1")) {toggle = true;}

	ToggleCarrier(client, target);//, toggle);
	
	return Plugin_Handled;
}

ToggleCarrier(client, target)//, bool:set)
{
	if (GetCarrier(target))
	{
		SetCarrier(target, false);
//		if (GetClientTeam(target) == ZOMBIE)
//		{
//			GivePlayerWeapon(client, target, "weapon_arms", true, true, false);
//			SDKCall(ChangeToZombie, target);
//		}
		LogAction(client, target, "\"%L\" Removed \"%L\" as a Carrier.", client, target);
	}
	else
	{
		SetCarrier(target, true);
//		if (GetClientTeam(target) == ZOMBIE)
//		{
//			GivePlayerWeapon(client, target, "weapon_carrierarms", true, true, false);
//			SDKCall(ChangeToZombie, target);
//		}
		LogAction(client, target, "\"%L\" Made \"%L\" a Carrier.", client, target);
	}
}

GetCarrier(target)
{
	if(GetEntData(target, CarrierOffset))
	{
		return true;
	}
	else
	{
		return false;
	}
}

SetCarrier(target, bool:toggle)
{
	SetEntData(target, CarrierOffset, toggle);
	if (GetClientTeam(target) == 3)
	{
		new String:clientModel[50]; GetClientModel(target, clientModel, sizeof(clientModel));
		new String:carrierModel[50]; carrierModel = "models/zombies/zombie0/zombie0.mdl";
		if (!StrEqual(clientModel, carrierModel, false))
		{
			if(!IsModelPrecached(carrierModel)) {PrecacheModel(carrierModel);}
			SetEntityModel(target, carrierModel);
		}
	}
}

public GetMaxCarriers(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	if (strcmp(oldValue, newValue) != 0)
	{
		maxCarriers = GetConVarInt(MaxCarriers);
		if (maxCarriers == 1 && isHooked == true)
		{
			UnhookEvent("player_spawn",PlayerSpawn);
			UnhookEvent("player_death", PlayerDeath);
			UnhookEvent("game_round_restart", NewRound);
			isHooked = false;
		}
		else if (maxCarriers != 1 && isHooked == false)
		{
			HookEvent("player_spawn",PlayerSpawn);
			HookEvent("player_death", PlayerDeath);
			HookEvent("game_round_restart", NewRound, EventHookMode_PostNoCopy);
			isHooked = true;
		}
	}
}

public NewRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MaxClients; i++)
	if(IsClientInGame(i) && GetEntData(i, CarrierOffset))
	{
		SetCarrier(i, false);
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CheckCarriers(client, 2);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!GetEntData(client, CarrierOffset)) {CheckCarriers(client, 3);}
}

public CheckCarriers(client, checkTeam)
{
	if (maxCarriers > 1)
	{
		if (GetClientTeam(client) == checkTeam)
		{
			new CarrierCount = 0;
			for (new i = 1; i < MaxClients; i++)
			if(IsClientInGame(i) && GetEntData(i, CarrierOffset))
			{
				CarrierCount++;
			}
			if(CarrierCount < maxCarriers)
			{
				SetCarrier(client, true);
			}
		}
	}
	else if (maxCarriers == 0)
	{
		if (GetClientTeam(client) == checkTeam)
		{
			if (CheckCommandAccess(client, "sm_reservation", ADMFLAG_RESERVATION) || CheckCommandAccess(client, "sm_root", ADMFLAG_ROOT))
			{
				SetCarrier(client, true);
			}
		}
	}
}


/*****************************************************************
							 ADMIN MENU
*****************************************************************/
public OnAdminMenuReady(Handle:topmenu)
{
	//Block us from being called twice
	if (topmenu == hTopMenu) {return;}
	hTopMenu = topmenu;
	
	new TopMenuObject:player_commandsII = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDSII);	//here
	if (player_commandsII != INVALID_TOPMENUOBJECT)
	{
		Setup_AdminMenu_Carrier(player_commandsII);	//here
	}
//	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
//
//	if (server_commands != INVALID_TOPMENUOBJECT)
//	{
//		Setup_AdminMenu_FF_Server(server_commands);
//	}
}

/*****************************************************************
					CARRIER ADMIN MENU
*****************************************************************/
Setup_AdminMenu_Carrier(TopMenuObject:parentmenu)	//here
{
	AddToTopMenu(hTopMenu, 
		"sm_carrier", TopMenuObject_Item,	//here
		AdminMenu_Carrier, parentmenu,		//here
		"sm_carrier", ADMFLAG_ROOT);		//here
}

public AdminMenu_Carrier(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)	//here
{
	if (action == TopMenuAction_DisplayOption)
	{
		//Format(buffer, maxlength, "%T", "Carrier Player", client);
		Format(buffer, maxlength, "Carrier Player");				//here
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayCarrierMenu(client);									//here
	}
}

DisplayCarrierMenu(client)											//here
{
	new Handle:menu = CreateMenu(MenuHandler_Carrier);				//here
	
	decl String:title[100];
	//Format(title, sizeof(title), "%T:", "Carrier Player", client);
	Format(title, sizeof(title), "Carrier Player:");				//here
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	//menu			Menu Handle.
	//source_client	Source client, or 0 to ignore immunity.
	//in_game_only	True to only select in-game players.
	//alive_only 	True to only select alive players.

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Carrier(Handle:menu, MenuAction:action, client, param)		//here
{
	if (action == MenuAction_End) {CloseHandle(menu);}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);		//here if 2nd tier
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0) {PrintToChat(client, "[SM] Player no longer available");}
		else if (!CanUserTarget(client, target)) {PrintToChat(client, "[SM] Unable to target");}
		else
		{
			ToggleCarrier(client, target);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(client) && !IsClientInKickQueue(client))
		{
			DisplayCarrierMenu(client);											//here
		}
	}
}