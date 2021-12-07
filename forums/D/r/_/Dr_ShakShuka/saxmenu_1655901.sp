#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <adminmenu>
new currentTarget[MAXPLAYERS+1];
//+----------------------------------------------------------------------------------------+
#define PLUGIN_VERSION "1.0.1"
//+----------------------------------------------------------------------------------------+
public Plugin:myinfo = 
{
	name 		= "Saxton Menu",
	author		= "Dr.ShakShuka",
	description = "Admin Menu for the VS Saxton Hale plugin.",
	version 	= PLUGIN_VERSION,
	url 		= "http://xtreme-il.info"
}
//+----------------------------------------------------------------------------------------+
public OnPluginStart()
{
	/*
		ConVars
	*/
	CreateConVar("sm_saxton_menu_version", PLUGIN_VERSION, "Saxton Menu version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	/*
		Regs
	*/
	RegAdminCmd("sm_saxmenu", CommandMenu, ADMFLAG_BAN, "Opens the saxton menu");
	RegAdminCmd("sm_halemenu", CommandMenu, ADMFLAG_BAN, "Opens the saxton menu");
	RegAdminCmd("sm_sax", CommandMenu, ADMFLAG_BAN, "Opens the saxton menu");
	RegAdminCmd("sm_haleadmin", CommandMenu, ADMFLAG_BAN, "Opens the saxton menu");
}
//------------------------------------------------------------------------------------------------
public Action:CommandMenu(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:MainMenu = CreateMenu(MenuHandler_Saxton);

		SetMenuTitle(MainMenu, "Main Menu - Choose Category:");
		
		AddMenuItem(MainMenu, "hale_select", "Saxton Select");
		AddMenuItem(MainMenu, "hale_special", "Saxton Special");
		AddMenuItem(MainMenu, "hale_addpoints", "Saxton Points");
		AddMenuItem(MainMenu, "hale_stop_music", "Stop Boss' Music");
		
		DisplayMenu(MainMenu, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------
public MenuHandler_Saxton(Handle:MainMenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		GetClientName(param1, admName, sizeof(admName));
		switch (param2)
		{
			case 0 :
			{
				MenuChooseHale(param1, -1);
			}
			case 1 :
			{
				MenuChooseSpecial(param1, -1);
			}
			case 2 :
			{
				MenuPreAddPoints(param1, -1);
			}
			case 3 :
			{
				ServerCommand("hale_stop_music");
				PrintToChatAllEx(param1, "\x04Saxton-Menu\x05 |\x03 %s\x01 stopped the\x04 Boss\'\x01 music.", admName);
				CommandMenu(param1, -1);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(MainMenu);
	}
}
//------------------------------------------------------------------------------------------------
/*
	Hale Select System
*/
public Action:MenuChooseHale(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuSelect = CreateMenu(MenuHandler_HaleSelect);
		
		SetMenuTitle(menuSelect, "Choose the next Hale:");
		SetMenuExitBackButton(menuSelect, true);
		
		AddTargetsToMenu(menuSelect, client, true, false);
		
		DisplayMenu(menuSelect, client, MENU_TIME_FOREVER);
	}
}
//------------------------------------------------------------------------------------------------
public MenuHandler_HaleSelect(Handle:menuSelect, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		decl String:pName[64];
		new userid, target;
		
		GetMenuItem(menuSelect, param2, info, sizeof(info));
		userid = StringToInt(info);

		target = GetClientOfUserId(userid);
		
		GetClientName(target, pName, sizeof(pName));
		ServerCommand("hale_select %s", pName);
		MenuChooseHale(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		CommandMenu(param1, -1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuSelect);
	}
}
//------------------------------------------------------------------------------------------------
/*
	Special System
*/
public Action:MenuChooseSpecial(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuSpecial = CreateMenu(MenuHandler_SaxtonSpecial);

		SetMenuTitle(menuSpecial, "Choose Special-Round:");
		SetMenuExitBackButton(menuSpecial, true);
		
		AddMenuItem(menuSpecial, "hale", "Hale");
		AddMenuItem(menuSpecial, "vagineer", "Vagineer");
		AddMenuItem(menuSpecial, "hhh", "HHH - Haloween");
		AddMenuItem(menuSpecial, "christian", "Christian Brutal Sniper");
		
		DisplayMenu(menuSpecial, client, MENU_TIME_FOREVER);
	}
}
//------------------------------------------------------------------------------------------------
public MenuHandler_SaxtonSpecial(Handle:menuSelect, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		GetClientName(param1, admName, sizeof(admName));
		
		decl String:specialClass[32];
		GetMenuItem(menuSelect, param2, specialClass, sizeof(specialClass));
		
		ServerCommand("hale_special %s", specialClass);
		PrintToChatAllEx(param1, "\x04Saxton-Menu\x05 |\x03 %s\x01 sets the next\x04 Special\x01 to:\x05 %s", admName, specialClass);
		MenuChooseSpecial(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		CommandMenu(param1, -1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuSelect);
	}
}
//------------------------------------------------------------------------------------------------
/*
	Points System
*/
public Action:MenuPreAddPoints(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuPreAddPoints = CreateMenu(MenuHandler_PreAddPoints);
		
		SetMenuTitle(menuPreAddPoints, "Choose player to add points:");
		SetMenuExitBackButton(menuPreAddPoints, true);
		
		AddTargetsToMenu(menuPreAddPoints, client, true, false);
		
		DisplayMenu(menuPreAddPoints, client, MENU_TIME_FOREVER);
	}
}
//------------------------------------------------------------------------------------------------
public MenuHandler_PreAddPoints(Handle:menuPreAddPoints, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menuPreAddPoints, param2, info, sizeof(info));
		userid = StringToInt(info);

		target = GetClientOfUserId(userid);
		
		if ( IsClientInGame(target) )
		{
			currentTarget[param1] = target;
			MenuAddPoint(param1, -1);
		}
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		CommandMenu(param1, -1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuPreAddPoints);
	}
}
//------------------------------------------------------------------------------------------------
public Action:MenuAddPoint(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuAddPoints = CreateMenu(MenuHandler_AddPoints);

		SetMenuTitle(menuAddPoints, "Choose amount of Points:");
		SetMenuExitBackButton(menuAddPoints, true);
		
		AddMenuItem(menuAddPoints, "10", "10 Points");
		AddMenuItem(menuAddPoints, "20", "20 Points");
		AddMenuItem(menuAddPoints, "30", "30 Points");
		AddMenuItem(menuAddPoints, "40", "40 Points");
		AddMenuItem(menuAddPoints, "50", "50 Points");
		AddMenuItem(menuAddPoints, "100", "100 Points");
		
		DisplayMenu(menuAddPoints, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------
public MenuHandler_AddPoints(Handle:menuAddPoints, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		decl String:pName[64];
		GetClientName(param1, admName, sizeof(admName));
		GetClientName(currentTarget[param1], pName, sizeof(pName));
		
		decl String:info[32];
		GetMenuItem(menuAddPoints, param2, info, sizeof(info));
		
		ServerCommand("hale_addpoints %s %s", pName, info);
		PrintToChatAllEx(param1, "\x04Saxton-Menu\x05 |\x01 Admin\x04 %s\x01 added\x05 %s Points\x01 to:\x03 %s", admName, info, pName);
		MenuPreAddPoints(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		MenuPreAddPoints(param1, -1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuAddPoints);
	}
}
//------------------------------------------------------------------------------------------------
/*
	Custom
*/
public PrintToChatAllEx(from, const String:format[], any:...)
{
	decl String:message[512];
	VFormat(message, sizeof(message), format, 3);

	new Handle:hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}
//------------------------------------------------------------------------------------------------