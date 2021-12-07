/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* SurvivorUpgrades - A modification for the game Left4Dead */
/* Copyright 2009 Evil Boomer Santa Claus */

/*
*
* Email: evilboomer@gmail.com
*
* Version 1.0
* 		- Initial release.
* Version 1.1
* 		- Merge with L4DMMO
*		- Add !laser to chat for take Laser Upgrade, OLD Command, NOW is !laseron
*		- Block Exploit where normal user can use a Console for take Upgrade
* Version 1.2
* 		- added support for Windows Server for addUpgrade, removeUpgrade, GiveRandomUpgrade
* Version 1.2.1
*		- change !laser to !laseron to chat for activate Laser Upgrade
*		- add !laseroff to chat for deactivate Laser Upgrade
*/

/* Define constants */
#define PLUGIN_VERSION    "1.2.1"
#define PLUGIN_NAME       "Evil Boomer Survivors Upgrades"
#define PLUGIN_TAG  	  	"[ASU] "
#define MAX_PLAYERS				18		

#define NSKILLS 16
#define NUPGRADES 31

/* Include necessary files */
#include <sourcemod>
#include <sdktools>
/* Make the admin menu optional */
#undef REQUIRE_PLUGIN
#include <adminmenu>

/* Create ConVar Handles */
new Handle:SetSkill = INVALID_HANDLE;
new Handle:GetSkillName = INVALID_HANDLE;
new Handle:AddUpgrade = INVALID_HANDLE;
new Handle:GiveRandomUpgrade = INVALID_HANDLE;
new Handle:RemoveUpgrade = INVALID_HANDLE;
new Handle:RemoveAllUpgrades = INVALID_HANDLE;
new Handle:GetUpgradeName = INVALID_HANDLE;

/* Create handle for the admin menu */
new Handle:AdminMenu = INVALID_HANDLE;
new TopMenuObject:su1 = INVALID_TOPMENUOBJECT;
new TopMenuObject:su2 = INVALID_TOPMENUOBJECT;
new TopMenuObject:su3 = INVALID_TOPMENUOBJECT;


/* Metadata for the mod */
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "Evil Boomer Santa Claus",
	description = "Enables admins to have control for Survivor Upgrades",
	version = PLUGIN_VERSION,
	url = "http://evilboomer.clanservers.com/news.php"
};

/* Create and set all the necessary for ASU and register all our commands */ 

public OnPluginStart() {

	new Handle:hConfig = LoadGameConfigFile("L4D_Asu");
	if(hConfig == INVALID_HANDLE) {
		SetFailState("[ASU] Could not load L4D_Asu gamedata.");
	} else
	
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "SetSkill")) {
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	SetSkill = EndPrepSDKCall();
	}

	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "GetSkillName")) {
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	GetSkillName = EndPrepSDKCall();
	}
	
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "AddUpgrade")) {
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	AddUpgrade = EndPrepSDKCall();
	}
	
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "GiveRandomUpgrade")) {
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	GiveRandomUpgrade = EndPrepSDKCall();
		}
		
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "RemoveUpgrade")) {
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	RemoveUpgrade = EndPrepSDKCall();
	}
	
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "RemoveAllUpgrades")) {
	RemoveAllUpgrades = EndPrepSDKCall();
	}
	
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "GetUpgradeName")) {
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	GetUpgradeName = EndPrepSDKCall();
	}
					
	/* Create all the necessary ConVars and execute auto-configuation */
	/* We add cheat flags to our ConVars to stop other admins with lesser flags altering our plugin */
	CreateConVar("asu_version", PLUGIN_VERSION, "The version of ASU plugin.", FCVAR_PLUGIN);
	/* We make sure that only admins that are permitted to cheat are allow to run these commands */
	/* Register all the director commands */

	RegAdminCmd("setskill", setSkill, ADMFLAG_GENERIC);
	RegAdminCmd("skillname", skillName, ADMFLAG_GENERIC);
	RegAdminCmd("addupgrade", addUpgrade, ADMFLAG_GENERIC);
	RegAdminCmd("giverandomupgrade", giveRandomUpgrade, ADMFLAG_GENERIC);
	RegAdminCmd("removeupgrade", removeUpgrade, ADMFLAG_GENERIC);
	RegAdminCmd("removeallupgrades", removeAllUpgrades, ADMFLAG_GENERIC);
	RegAdminCmd("upgradename", upgradeName, ADMFLAG_GENERIC);

	RegAdminCmd("dumpskills", dumpSkills, ADMFLAG_GENERIC);
	RegAdminCmd("dumpupgrades", dumpUpgrades, ADMFLAG_GENERIC);
	
	RegAdminCmd("asu_spawn_upgrade1", Command_upgrade1, ADMFLAG_GENERIC);
	RegAdminCmd("asu_spawn_upgrade2", Command_upgrade2, ADMFLAG_GENERIC);
	RegAdminCmd("asu_spawn_upgrade3", Command_upgrade3, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_laseron", Lasermeon);
	RegConsoleCmd("sm_laseroff", Lasermeoff);
	
	/* If the Admin menu has been loaded start adding stuff to it */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
		
	LogAction(0, -1, "%s %s has been loaded.", PLUGIN_NAME, PLUGIN_VERSION)
}

/* This spawns an infected of your choice either at your crosshair if a4d_automatic_placement is false or automatically */
/* Currently you can only spawn one thing at once. */
public Action:Command_upgrade1(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: asu_spawn_upgrade1 <Health|Laser|LargeClip|Damage|Reload|>"); return Plugin_Handled; }	
		
	new String:type[7]	
	GetCmdArg(1, type, sizeof(type))
	SpawnItem(client, type)
	return Plugin_Handled;
}

public Action:Command_upgrade2(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: asu_spawn_upgrade2 <Body|Goggles|LedgeSave|ReviveSelf|Knife>"); return Plugin_Handled; }	
		
	new String:type[16]	
	GetCmdArg(1, type, sizeof(type))
	SpawnItem(client, type)
	return Plugin_Handled;
}

public Action:Command_upgrade3(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: asu_spawn_upgrade3 <Prevent|Recoil|FastRevive|Ointment|BulbingFlash>"); return Plugin_Handled; }	
		
	new String:type[16]	
	GetCmdArg(1, type, sizeof(type))
	SpawnItem(client, type)
	return Plugin_Handled;
}

SpawnItem(client, String:type[]) {
	new String:command[] = "addupgrade";
	StripAndExecuteClientCommand(client, command, type, "", "")
	
}	

/* Menu Functions */

/* Load our categories and menus */
public OnAdminMenuReady(Handle:TopMenu) {
	/* Block us from being called twice */
	if (TopMenu == AdminMenu) { return; }
	
	AdminMenu = TopMenu;
 
	/* Add a category to the SourceMod menu called "Director Commands" */
	AddToTopMenu(AdminMenu, "ASU Commands", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT)
	/* Get a handle for the catagory we just added so we can add items to it */
	new TopMenuObject:afd_commands = FindTopMenuCategory(AdminMenu, "ASU Commands");
	
	/* Don't attempt to add items to the catagory if for some reason the catagory doesn't exist */
	if (afd_commands == INVALID_TOPMENUOBJECT) { return; }
	
	/* The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically */
	/* Assign the menus to global values so we can easily check what a menu is when it is chosen */
	su1 = AddToTopMenu(AdminMenu, "asu_show_upgrade1", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "asu_show_upgrade1", ADMFLAG_GENERIC);
	su2 = AddToTopMenu(AdminMenu, "asu_show_upgrade2", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "asu_show_upgrade2", ADMFLAG_GENERIC);
	su3 = AddToTopMenu(AdminMenu, "asu_show_upgrade3", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "asu_show_upgrade3", ADMFLAG_GENERIC);
}

/* This handles the top level "ASU" category and how it is displayed on the core admin menu */
public CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "ASU Commands:");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "ASU Commands");
	}
}

/* This deals with what happens someone opens the "ASU" category from the menu */ 
public Menu_TopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	/* When an item is displayed to a player tell the menu to format the item */
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == su1) {
			Format(buffer, maxlength, "Survivor Upgrade 1");
		} else if (object_id == su2) {
			Format(buffer, maxlength, "Survivor Upgrade 2");
		} else if (object_id == su3) {
			Format(buffer, maxlength, "Survivor Upgrade 3");
				} 
	}
	
	/* When an item is selected do the following */
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == su1) {
			Menu_su1(client, false)
		} else if (object_id == su2) {
			Menu_su2(client, false)
		} else if (object_id == su3) {
			Menu_su3(client, false)
		}
	}
}

/* This menu deals with all the commands related to the director */
public Action:Menu_su1(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_su1)
	SetMenuTitle(menu, "Survivor Upgrades 1")
	AddMenuItem(menu, "au1", "Health")
	AddMenuItem(menu, "au2", "Laser Sight")
	AddMenuItem(menu, "au3", "Larger Clip")
	AddMenuItem(menu, "au4", "Hollow-Point")
	AddMenuItem(menu, "au5", "Fast Reload")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_su1(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "16")
			} case 1: {
				SpawnItem(cindex, "17")
			} case 2: {
				SpawnItem(cindex, "20")
			} case 3: {
				SpawnItem(cindex, "21")
			} case 4: {
				SpawnItem(cindex, "29")
			}
		}
		
		Menu_su1(cindex, false)
		
	}
	
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* This menu deals with spawning weapons */
public Action:Menu_su2(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_su2)
	SetMenuTitle(menu, "Survivor Upgrades 2")
	AddMenuItem(menu, "au6", "Body Armor")
	AddMenuItem(menu, "au7", "Goggles")
	AddMenuItem(menu, "au8", "Ledge Save")	
	AddMenuItem(menu, "au9", "Revive Self")
	AddMenuItem(menu, "au10", "Knife")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_su2(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "1")
			} case 1: {
				SpawnItem(cindex, "13")
			} case 2: {
				SpawnItem(cindex, "11")
			} case 3: {
				SpawnItem(cindex, "12")
			} case 4: {
				SpawnItem(cindex, "26")
			} 
		}
		
		Menu_su2(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* This menu deals with spawning items */
public Action:Menu_su3(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_su3)
	SetMenuTitle(menu, "Survivor Upgrades 3")
	AddMenuItem(menu, "au11", "Raincoat")
	AddMenuItem(menu, "au12", "Less Recoil")
	AddMenuItem(menu, "au13", "Fast Revive")
	AddMenuItem(menu, "au14", "Ointment")
	AddMenuItem(menu, "au15", "Blinding Flash")	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_su3(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "8")
			} case 1: {
				SpawnItem(cindex, "19")
			} case 2: {
				SpawnItem(cindex, "27")
			} case 3: {
				SpawnItem(cindex, "28")
			} case 4: {
				SpawnItem(cindex, "30")
			} 
		}
		
		Menu_su3(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* Helper Functions */
/* This function strips the cheat flags from a command, executes it and then restores it to its former glory. */

/* This isn't used yet. It seems that most commands are called from the client and StripAndExecuteClientCommand should be used instead

StripAndExecuteServerCommand(String:command[], String:arg[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	ServerCommand(command);
	SetCommandFlags(command, flags);
}
*/

///* Strip and change a ConVar to the value specified */
//StripAndChangeServerConVarBool(String:command[], bool:value) {
//	new flags = GetCommandFlags(command);
//	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
//	SetConVarBool(FindConVar(command), value, false, false);
//	SetCommandFlags(command, flags);
//}

///* Strip and change a ConVar to the value sppcified */
///* This doesn't do any maths. If you want to add 10 to an existing ConVar you need to work out the value before you call this */
//StripAndChangeServerConVarInt(String:command[], value) {
//	new flags = GetCommandFlags(command);
//	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
//	SetConVarInt(FindConVar(command), value, false, false);
//	SetCommandFlags(command, flags);
//}

/* Does the same as the above but for client commands */
StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3)
	SetCommandFlags(command, flags);
}


//
//
//
//L4DMMO Modify
//
//

public Action:setSkill(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new skill = StringToInt(arg);

	if ((skill < 0) || (skill > NSKILLS)) 
	{
		PrintToChat(client, "Bad skill number");
		return Plugin_Handled;
	}

	SDKCall(SetSkill, client, skill, false);

	return Plugin_Handled;
}

public Action:skillName(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new skill = StringToInt(arg);

	if ((skill < 0) || (skill > NSKILLS)) 
	{
		PrintToChat(client, "Bad skill number");
		return Plugin_Handled;
	}

	decl String:name[64];
	SDKCall(GetSkillName, name, sizeof(name), skill);

	PrintToChat(client, "Skill %d is %s", skill, name);

	return Plugin_Handled;
}

public Action:addUpgrade(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new upgrade = StringToInt(arg);

	if ((upgrade < 0) || (upgrade > NUPGRADES)) 
	{
		PrintToChat(client, "Bad upgrade number");
		return Plugin_Handled;
	}

	SDKCall(AddUpgrade, client, upgrade);

	return Plugin_Handled;
}

public Action:giveRandomUpgrade(client, args)
{
	SDKCall(GiveRandomUpgrade, client);

	return Plugin_Handled;
}

public Action:removeUpgrade(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new upgrade = StringToInt(arg);

	if ((upgrade < 0) || (upgrade > NUPGRADES)) 
	{
		PrintToChat(client, "Bad upgrade number");
		return Plugin_Handled;
	}

	SDKCall(RemoveUpgrade, client, upgrade);

	return Plugin_Handled;
}

public Action:removeAllUpgrades(client, args)
{
	SDKCall(RemoveAllUpgrades, client);

	return Plugin_Handled;
}

public Action:upgradeName(client, args)
{
	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	new upgrade = StringToInt(arg);

	if ((upgrade < 0) || (upgrade > NUPGRADES)) 
	{
		PrintToChat(client, "Bad upgrade number");
		return Plugin_Handled;
	}

	decl String:name[64];
	SDKCall(GetUpgradeName, name, sizeof(name), upgrade);

	PrintToChat(client, "Upgrade %d is %s", upgrade, name);

	return Plugin_Handled;
}

public Action:dumpUpgrades(client, args)
{
	new upgrade;
	decl String:name[64];

	PrintToChat(client, "Upgrades:");
	while (upgrade < NUPGRADES)
	{
		SDKCall(GetUpgradeName, name, sizeof(name), upgrade);

		PrintToChat(client, "  %d: %s", upgrade, name);

		upgrade++;
	}

	return Plugin_Handled;
}

public Action:dumpSkills(client, args)
{
	new skill;
	decl String:name[64];

	PrintToChat(client, "Skills:");
	while (skill < NSKILLS)
	{
		SDKCall(GetSkillName, name, sizeof(name), skill);

		PrintToChat(client, "  %d: %s", skill, name);

		skill++;
	}

	return Plugin_Handled;
}

//Add a sourcemod command so players can easily take and remove Laser Upgrade
	
public Action:Lasermeon(client, args)
{ 
	SDKCall(AddUpgrade, client, 17);
}

public Action:Lasermeoff(client, args)
{ 
	SDKCall(RemoveUpgrade, client, 17);
}