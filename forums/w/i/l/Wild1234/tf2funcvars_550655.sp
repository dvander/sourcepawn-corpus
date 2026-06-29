public Plugin:myinfo = 
{
	name = "Fun Cvars",
	author = "Wild1234",
	description = "Alter Cvars for fun goofy games.",
	version = "1.0.0",
	url = "http://www.sourcemod.net/"
};

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:g_Cvar_Gravity = INVALID_HANDLE;
new Handle:g_Cvar_AllTalk = INVALID_HANDLE;
new Handle:g_Cvar_FF = INVALID_HANDLE;
new Handle:g_Cvar_RSTime = INVALID_HANDLE;
new Handle:hTopMenu = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_Cvar_Gravity = FindConVar("sv_gravity");
	g_Cvar_AllTalk = FindConVar("sv_alltalk");
	g_Cvar_FF = FindConVar("mp_friendlyfire");
	g_Cvar_RSTime = FindConVar("mp_respawnwavetime");

	RegAdminCmd("sm_svgrav", Command_SetGrav, ADMFLAG_CUSTOM1, "sm_svgrav <gravity> Sets gravity to given value. Default: 800");
	RegAdminCmd("sm_svff", Command_SetFF, ADMFLAG_CUSTOM1, "sm_svff <1/0> Turns friendly fire on or off. Default: 0");
	RegAdminCmd("sm_svalltalk", Command_SetAllTalk, ADMFLAG_CUSTOM1, "sm_svalltalk <1/0> Turns Alltalk on or off. Default: 0");
	RegAdminCmd("sm_mprst", Command_SetRSTime, ADMFLAG_CUSTOM1, "sm_mprst <time> Respawn delay time. Default: 10");

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public Action:Command_SetGrav(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_svgrav <gravity>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	SetConVarInt(g_Cvar_Gravity, StringToInt(arg));
	PrintToChatAll("[SM] Gravity set to: %s", arg);					
	LogMessage("Chat: %L Set Gravity to: %s", client, arg);

	return Plugin_Handled;
}

public Action:Command_SetFF(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_svff <1/0>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	new argi = StringToInt(arg);

	if (argi != 0 && argi != 1)
	{
		PrintToChat(client, "[SM] Invalid Value. Please use 1 or 0");
		return Plugin_Handled;
	}

	SetConVarInt(g_Cvar_FF, argi);
	PrintToChatAll("[SM] Friendly Fire set to: %s", arg);					
	LogMessage("Chat: %L Set Friendly Fire to: %s", client, arg);

	return Plugin_Handled;
}

public Action:Command_SetAllTalk(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_svalltalk <1/0>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	new argi = StringToInt(arg);

	if (argi != 0 && argi != 1)
	{
		PrintToChat(client, "[SM] Invalid Value. Please use 1 or 0");
		return Plugin_Handled;
	}

	SetConVarInt(g_Cvar_AllTalk, argi);
	PrintToChatAll("[SM] AllTalk set to: %s", arg);					
	LogMessage("Chat: %L Set AllTalk to: %s", client, arg);

	return Plugin_Handled;
}

public Action:Command_SetRSTime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mprst <time>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	SetConVarInt(g_Cvar_RSTime, StringToInt(arg));
	PrintToChatAll("[SM] Respawn Time set to: %s", arg);					
	LogMessage("Chat: %L Set Respawn Time to: %s", client, arg);

	return Plugin_Handled;
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}

	/* Save the Handle */
	hTopMenu = topmenu;

	new TopMenuObject:fun_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	AddToTopMenu(hTopMenu, 
		"sm_svgrav",
		TopMenuObject_Item,
		AdminMenu_Grav,
		fun_commands,
		"sm_svgrav",
		ADMFLAG_CUSTOM1);

	AddToTopMenu(hTopMenu, 
		"sm_svff",
		TopMenuObject_Item,
		AdminMenu_FF,
		fun_commands,
		"sm_svff",
		ADMFLAG_CUSTOM1);

	AddToTopMenu(hTopMenu, 
		"sm_svalltalk",
		TopMenuObject_Item,
		AdminMenu_AllTalk,
		fun_commands,
		"sm_svalltalk",
		ADMFLAG_CUSTOM1);

	AddToTopMenu(hTopMenu, 
		"sm_mprst",
		TopMenuObject_Item,
		AdminMenu_RSTime,
		fun_commands,
		"sm_mprst",
		ADMFLAG_CUSTOM1);
}

public AdminMenu_Grav(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Gravity");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* Do something! client who selected item is in param */
		DisplayGravityMenu(param);
	}
}

public AdminMenu_FF(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (!GetConVarBool(g_Cvar_FF))
		{
			Format(buffer, maxlength, "Enable FF", param);
		}
		else
		{
			Format(buffer, maxlength, "Disable FF", param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* Do something! client who selected item is in param */
		// turn on or off FF
		SetConVarBool(g_Cvar_FF, !GetConVarBool(g_Cvar_FF));
		PrintToChatAll("[SM] Friendly Fire set to: %s", (GetConVarBool(g_Cvar_FF) ? "1" : "0"));
		LogMessage("Chat: %L Set Friendly Fire to: %s", param, (GetConVarBool(g_Cvar_FF) ? "1" : "0"));
	}
}

public AdminMenu_AllTalk(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (!GetConVarBool(g_Cvar_AllTalk))
		{
			Format(buffer, maxlength, "Enable AllTalk", param);
		}
		else
		{
			Format(buffer, maxlength, "Disable AllTalk", param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* Do something! client who selected item is in param */
		// turn on or off Alltalk
		SetConVarBool(g_Cvar_AllTalk, !GetConVarBool(g_Cvar_AllTalk));
		PrintToChatAll("[SM] AllTalk set to: %s", (GetConVarBool(g_Cvar_AllTalk) ? "1" : "0"));
		LogMessage("Chat: %L Set AllTalk to: %s", param, (GetConVarBool(g_Cvar_AllTalk) ? "1" : "0"));
	}
}

public AdminMenu_RSTime(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Respawn Timer");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* Do something! client who selected item is in param */
		DisplayRSTMenu(param);
	}
}

DisplayGravityMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Grav);
	
	decl String:title[100];
	Format(title, sizeof(title), "Select Gravity", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "200", "Very Low");
	AddMenuItem(menu, "400", "Low");
	AddMenuItem(menu, "800", "Default");
	AddMenuItem(menu, "1600", "High");
	AddMenuItem(menu, "3200", "Extreme");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Grav(Handle:menu, MenuAction:action, param1, param2)
{
	// param1 = client, param2 = grav
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
		decl String:GravLev[32];
		
		GetMenuItem(menu, param2, GravLev, sizeof(GravLev));

		// Set Gravity
		SetConVarInt(g_Cvar_Gravity, StringToInt(GravLev));
		PrintToChatAll("[SM] Gravity set to: %s", GravLev);					
		LogMessage("Chat: %L Set Gravity to: %s", param1, GravLev);
	}
}

DisplayRSTMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_RST);
	
	decl String:title[100];
	Format(title, sizeof(title), "Set Respawn Time", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "0", "Instant");
	AddMenuItem(menu, "2", "Very Fast");
	AddMenuItem(menu, "5", "Fast");
	AddMenuItem(menu, "10", "Normal");
	AddMenuItem(menu, "20", "Long");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_RST(Handle:menu, MenuAction:action, param1, param2)
{
	// param1 = client, param2 = grav
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
		decl String:RSTimer[32];
		
		GetMenuItem(menu, param2, RSTimer, sizeof(RSTimer));

		// Set Respawn Time
		SetConVarInt(g_Cvar_RSTime, StringToInt(RSTimer));
		PrintToChatAll("[SM] Respawn Time set to: %s", RSTimer);					
		LogMessage("Chat: %L Set Respawn Timer to: %s", param1, RSTimer);
	}
}