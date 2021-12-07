#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hTopMenu = INVALID_HANDLE;

new bool:HasUnlimitedHE[MAXPLAYERS+1] 		= false;
new bool:HasUnlimitedFlash[MAXPLAYERS+1]	= false; 
new bool:HasUnlimitedSmoke[MAXPLAYERS+1]	= false;


public Plugin:myinfo =
{
	name = "Unlmited Grenades",
	author = "Fredd",
	description = "lets you give players unlmited grenades",
	version = "2.0",
	url = "http://www.sourcemod.net/"
};
public OnPluginStart()
{
	CreateConVar("un_version", "2.0", "Unlimited Grenades Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("hegrenade_detonate", 	GrenadeDetonate);
	HookEvent("flashbang_detonate", 	GrenadeDetonate);
	HookEvent("smokegrenade_detonate", 	GrenadeDetonate);
	
	RegAdminCmd("sm_unnades", Command_UnlimitedGrenades, ADMFLAG_KICK, "Give client unlmited grenades");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
		return;
	
	hTopMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT) 
	{
		AddToTopMenu(hTopMenu,
		"Enable Unlmited HE",
		TopMenuObject_Item,
		AdminMenu_EnableHE,
		player_commands,
		"",
		ADMFLAG_KICK);
		
		AddToTopMenu(hTopMenu,
		"Disable Unlmited HE",
		TopMenuObject_Item,
		AdminMenu_DisableHE,
		player_commands,
		"",
		ADMFLAG_KICK);
		
		AddToTopMenu(hTopMenu,
		"Enable Unlmited Flash",
		TopMenuObject_Item,
		AdminMenu_EnableFlash,
		player_commands,
		"",
		ADMFLAG_KICK);
		
		AddToTopMenu(hTopMenu,
		"Disable Unlmited Flash",
		TopMenuObject_Item,
		AdminMenu_DisableFlash,
		player_commands,
		"",
		ADMFLAG_KICK);
		
		AddToTopMenu(hTopMenu,
		"Enable Unlmited Smoke",
		TopMenuObject_Item,
		AdminMenu_EnableSmoke,
		player_commands,
		"",
		ADMFLAG_KICK);
		
		AddToTopMenu(hTopMenu,
		"Disable Unlmited Smoke",
		TopMenuObject_Item,
		AdminMenu_DisableSmoke,
		player_commands,
		"",
		ADMFLAG_KICK);
	}
}
public AdminMenu_EnableHE(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Unlmited HE (ON)", param);
	
	else if (action == TopMenuAction_SelectOption)
		DisplayEnableHEMenu(param);
	
}
public AdminMenu_DisableHE(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Unlmited HE (OFF)", param);
	
	else if (action == TopMenuAction_SelectOption)
		DisplayDisableHEMenu(param);
	
}
public AdminMenu_EnableFlash(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Unlmited Flash (ON)", param);
	
	else if (action == TopMenuAction_SelectOption)
		DisplayEnableFlashMenu(param);
	
}
public AdminMenu_DisableFlash(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Unlmited Flash (OFF)", param);
	
	else if (action == TopMenuAction_SelectOption)
		DisplayDisableFlashMenu(param);
	
}
public AdminMenu_EnableSmoke(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Unlmited Smoke (ON)", param);
	
	else if (action == TopMenuAction_SelectOption)
		DisplayEnableSmokehMenu(param);
	
}
public AdminMenu_DisableSmoke(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Unlmited Smoke (OFF)", param);
	
	else if (action == TopMenuAction_SelectOption)
		DisplayDisableSmokeMenu(param);
	
}
DisplayEnableHEMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_EnableHE);
	
	SetMenuTitle(menu, "Unlmited HE (ON)");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
DisplayDisableHEMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DisableHE);
	
	SetMenuTitle(menu, "Unlmited HE (OFF)");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayEnableFlashMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_EnableFlash);
	
	SetMenuTitle(menu, "Unlmited Flash (ON)");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayDisableFlashMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DisableFlash);
	
	SetMenuTitle(menu, "Unlmited Flash (OFF)");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayEnableSmokehMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_EnableSmoke);
	
	SetMenuTitle(menu, "Unlmited Smoke (ON)");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayDisableSmokeMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DisableSmoke);
	
	SetMenuTitle(menu, "Unlmited Smoke (OFF)");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_EnableHE(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		else
		{
			GiveNades(param1, target, "he", 1);
		}
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayEnableFlashMenu(param1);
		}
	}
}
public MenuHandler_DisableHE(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		else
		{
			GiveNades(param1, target, "he", 0);
		}
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayDisableHEMenu(param1);
		}
	}
}
public MenuHandler_EnableFlash(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		else
		{
			GiveNades(param1, target, "flash", 1);
		}
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayEnableFlashMenu(param1);
		}
	}
}
public MenuHandler_DisableFlash(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		else
		{
			GiveNades(param1, target, "flash", 0);
		}
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayDisableFlashMenu(param1);
		}
	}
}
public MenuHandler_EnableSmoke(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		else
		{
			GiveNades(param1, target, "smoke", 1);
		}
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayEnableSmokehMenu(param1);
		}
	}
}
public MenuHandler_DisableSmoke(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		else
		{
			GiveNades(param1, target, "smoke", 0);
		}
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayDisableSmokeMenu(param1);
		}
	}
}
public Action:GrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(StrEqual(name, "hegrenade_detonate"))
	{
		if(HasUnlimitedHE[client] == true)
			GivePlayerItem(client, "weapon_hegrenade");
		
		return Plugin_Handled;
	} else if(StrEqual(name, "flashbang_detonate"))
	{
		if(HasUnlimitedFlash[client] == true)
			GivePlayerItem(client, "weapon_flashbang");
		
		return Plugin_Handled;
	} else if(StrEqual(name, "smokegrenade_detonate"))
	{
		if(HasUnlimitedSmoke[client] == true)
			GivePlayerItem(client, "weapon_smokegrenade");
		
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:Command_UnlimitedGrenades(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unades <#userid|name> <grenade> [0/1]");
		return Plugin_Handled;
	}
	
	decl String:User[65], String:Grenade[21], String:OnOff[2];
	
	GetCmdArg(1, User, sizeof(User));
	GetCmdArg(2, Grenade, sizeof(Grenade));
	GetCmdArg(3, OnOff, sizeof(OnOff));
	
	if(!StrEqual(Grenade, "he") && !StrEqual(Grenade, "flash") && !StrEqual(Grenade, "smoke")) 
	{
		ReplyToCommand(client, "[SM] %t", "Invalid Grenade type please use 'he','flash' or 'smoke'");
		
		return Plugin_Handled;
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(User, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		GiveNades(client, target_list[i], Grenade, StringToInt(OnOff));
	}
	return Plugin_Handled;
}
GiveNades(client, target, String:Grenade[], toggle)
{
	new String:TargetName[MAX_NAME_LENGTH+1];
	GetClientName(target, TargetName, sizeof(TargetName));
	
	switch (toggle)
	{
		case 0:
		{
			if(StrEqual(Grenade, "he"))
			{
				if(HasUnlimitedHE[target] == true)
				{
					HasUnlimitedHE[target] = false;
					
					PrintToChat(target, "\x04[SM] \x01Your Unlmited HE Grenades have been disabled");
					ReplyToCommand(client,"[SM] %s unlimited HE grenade have been disabled", TargetName);
					
				} else if(HasUnlimitedHE[target] == false)
				{
					ReplyToCommand(client, "[SM] %s already doesnt have unlimited HE Grenades", TargetName);
				}
			}
			if(StrEqual(Grenade, "flash"))
			{
				if(HasUnlimitedFlash[target] == true)
				{
					HasUnlimitedFlash[target] = false;
					PrintToChat(target, "\x04[SM] \x01Your Unlmited Flash Grenades have been disabled");
					ReplyToCommand(client,"[SM] %s unlimited Flash grenade have been disabled", TargetName);
					
				} else if(HasUnlimitedFlash[target] == false)
				{
					ReplyToCommand(client, "[SM]%s already doesnt have unlimited Flash Grenades", TargetName);
				}
			}
			if(StrEqual(Grenade, "smoke"))
			{
				if(HasUnlimitedSmoke[target] == true)
				{
					HasUnlimitedSmoke[target] = false;
					PrintToChat(target, "\x04[SM] \x01Your Unlmited Smoke Grenades have been disabled");
					ReplyToCommand(client,"[SM] %s unlimited Smoke grenade have been disabled", TargetName);
					
				} else if(HasUnlimitedSmoke[target] == false)
				{
					ReplyToCommand(client, "[SM] %s already doesnt have unlimited Smoke Grenades", TargetName);
				}
			}
			
		}
		case 1:
		{
			if(StrEqual(Grenade, "he"))
			{
				if(HasUnlimitedHE[target] == false)
				{
					HasUnlimitedHE[target] = true;
					PrintToChat(target, "\x04[SM] \x01Your have been giving \x04Unlmited HE Grenades");
					ReplyToCommand(client,"[SM] %s Has been giving unlimited HE grenade", TargetName);
					GivePlayerItem(client, "weapon_hegrenade");
					
				} else if(HasUnlimitedHE[target] == true)
				{
					ReplyToCommand(client, "[SM] %s already has unlimited HE Grenades", TargetName);
				}
			}
			if(StrEqual(Grenade, "flash"))
			{
				if(HasUnlimitedFlash[target] == false)
				{
					HasUnlimitedFlash[target] = true;
					PrintToChat(target, "\x04[SM] \x01Your have been giving \x04Unlmited Flash Grenades");
					ReplyToCommand(client,"[SM] %s Has been giving unlimited Flash grenade", TargetName);
					GivePlayerItem(client, "weapon_flashbang");
					
				} else if(HasUnlimitedFlash[target] == true)
				{
					ReplyToCommand(client, "[SM] %s already has unlimited Flash Grenades", TargetName);
				}
			}
			if(StrEqual(Grenade, "smoke"))
			{
				if(HasUnlimitedSmoke[target] == false)
				{
					HasUnlimitedSmoke[target] = true;
					PrintToChat(target, "\x04[SM] \x01Your have been giving \x04Unlmited Smoke Grenades");
					ReplyToCommand(client,"[SM] %s Has been giving unlimited Smoke grenade", TargetName);
					GivePlayerItem(client, "weapon_smokegrenade");
					
				} else if(HasUnlimitedSmoke[target] == true)
				{
					ReplyToCommand(client, "[SM] %s already has unlimited Smoke Grenades", TargetName);
				}
			}
		}
	}
	return;
}
