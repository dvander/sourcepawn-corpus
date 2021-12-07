#include <sourcemod>
#include <sdktools>
#include <topmenus>
#include <menus>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

// Skipped 0.7 because abrandnewday already used it
#define PL_VERSION		"0.8"

#define CVAR_VERSION		0
#define CVAR_DISCO			1
#define NUM_CVARS			2

new g_numbers[8] = {0, 40, 80, 120, 160, 200, 240, 255};
new bool:g_disco = false;
new bool:g_lightson = true;
new Handle:g_cvars[NUM_CVARS] = INVALID_HANDLE;
new Handle:g_adminMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Light Colors",
	author = "Jindo",
	description = "Adjust lights in a map.",
	version = PL_VERSION,
	url = "http://www.topaz-games.com/"
}

public OnPluginStart()
{
	LoadTranslations("core.phrases");
	LoadTranslations("lightcolors.phrases");
	
	g_cvars[CVAR_VERSION] = CreateConVar("lights_version", PL_VERSION, "Version of the Light Colours plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvars[CVAR_DISCO] = CreateConVar("lights_disco_enable", "0", "Automatically enable Disco Mode.", FCVAR_PLUGIN);
	
	RegConsoleCmd("lights_color", Command_AllLightsColor);
	RegConsoleCmd("lights_disco", Command_AllLightsDisco);
	RegConsoleCmd("lights_reset", Command_AllLightsReset);
	RegConsoleCmd("lights_switch", Command_AllLightsSwitch);
	RegConsoleCmd("lights_help", Command_LightsHelp);
	
	new Handle:topMenu;
	
	if (LibraryExists("adminmenu") && ((topMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topMenu);
	}
	
	HookConVarChange(g_cvars[CVAR_DISCO], OnDiscoChanged);
}

public Action:Command_AllLightsColor(client, args)
{
	if (!CheckCommandAccess(client, "lightscolor", ADMFLAG_ROOT, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	g_lightson = true;
	g_disco = false;
	new ent = -1;
	decl String:color[64];
	if (args < 1)
	{
		color = "random";
	}
	else
	{
		GetCmdArg(1, color, sizeof(color));
	}
	while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
	{
		if (IsValidEntity(ent) && IsValidEdict(ent))
		{
			decl String:color2[64];
			GetColorFromInt(GetIntFromColor(color), color2, sizeof(color2));
			AcceptEntityInput(ent, "LightOff");
			DispatchKeyValue(ent, "rendercolor", color2);
			CreateTimer(0.25, Timer_TurnLightOn, ent, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	decl String:color3[64];
	GetNameFromColor(GetIntFromColor(color), color3, sizeof(color3));
	ReplyToCommand(client, "[SM] %t", "Lights Changed", color3);
	return Plugin_Handled;
}

public Action:Timer_TurnLightOn(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "LightOn");
	}
	return Plugin_Handled;
}

public Action:Command_AllLightsDisco(client, args)
{
	if (!CheckCommandAccess(client, "lightscolor", ADMFLAG_ROOT, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	if (g_disco)
	{
		g_disco = false;
		ReplyToCommand(client, "[SM] %t", "Disco Off");
		return Plugin_Handled;
	}
	g_lightson = true;
	g_disco = true;
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
	{
		if (IsValidEntity(ent) && IsValidEdict(ent))
		{
			decl String:color[64];
			GetColorFromInt(0, color, sizeof(color));
			AcceptEntityInput(ent, "LightOff");
			DispatchKeyValue(ent, "rendercolor", color);
			CreateTimer(0.25, Timer_TurnLightOnDisco, ent, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	ReplyToCommand(client, "[SM] %t", "Disco On");
	return Plugin_Handled;
}

public Action:Timer_TurnLightOnDisco(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "LightOn");
		new Float:time = GetRandomFloat(0.25, 0.75);
		CreateTimer(time, Timer_ChangeLightDisco, ent, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Timer_ChangeLightDisco(Handle:timer, any:ent)
{
	if (!g_disco)
	{
		if (IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "LightOff");
			DispatchKeyValue(ent, "rendercolor", "255 255 255");
			CreateTimer(0.25, Timer_TurnLightOn, ent, TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Handled;
	}
	if (IsValidEntity(ent))
	{
		decl String:color[64];
		GetColorFromInt(0, color, sizeof(color));
		AcceptEntityInput(ent, "LightOff");
		DispatchKeyValue(ent, "rendercolor", color);
		CreateTimer(0.25, Timer_TurnLightOnDisco, ent, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_AllLightsReset(client, args)
{
	if (!CheckCommandAccess(client, "lightscolor", ADMFLAG_ROOT, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	g_disco = false;
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
	{
		if (IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "LightOff");
			DispatchKeyValue(ent, "rendercolor", "255 255 255");
			CreateTimer(0.25, Timer_TurnLightOn, ent, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	ReplyToCommand(client, "[SM] %t", "Lights Reset");
	return Plugin_Handled;
}

public Action:Command_AllLightsSwitch(client, args)
{
	if (!CheckCommandAccess(client, "lightscolor", ADMFLAG_ROOT, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	g_disco = false;
	new ent = -1;
	if (g_lightson)
	{
		while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
		{
			if (IsValidEntity(ent))
			{
				AcceptEntityInput(ent, "LightOff");
			}
		}
		ReplyToCommand(client, "[SM] %t", "Lights Off");
		g_lightson = false;
		return Plugin_Handled;
	}
	else
	{
		while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
		{
			if (IsValidEntity(ent))
			{
				AcceptEntityInput(ent, "LightOn");
			}
		}
		ReplyToCommand(client, "[SM] %t", "Lights On");
		g_lightson = true;
		return Plugin_Handled;
	}
}

public Action:Command_LightsHelp(client, args)
{
	decl String:version[6];
	GetConVarString(g_cvars[CVAR_VERSION], version, sizeof(version));
	ReplyToCommand(client, "[SM] Light Colors v%s:", version);
	ReplyToCommand(client, " ~ lights_color <c> - %t", "Help lights_color");
	ReplyToCommand(client, " ~ lights_disco - %t", "Help lights_disco");
	ReplyToCommand(client, " ~ lights_reset - %t", "Help lights_reset");
	ReplyToCommand(client, " ~ lights_switch - %t", "Help lights_switch");
	return Plugin_Handled;
}

public Action:Timer_RestartDisco(Handle:timer)
{
	g_disco = true;
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
	{
		if (IsValidEntity(ent))
		{
			CreateTimer(0.25, Timer_TurnLightOnDisco, ent, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Handled;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_adminMenu)
	{
		return;
	}

	g_adminMenu = topmenu;

	new TopMenuObject:serverCommands = FindTopMenuCategory(g_adminMenu, ADMINMENU_SERVERCOMMANDS);
    
	if (serverCommands == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	AddToTopMenu(g_adminMenu, "lights_color", TopMenuObject_Item, AdminMenu_LightsColor, serverCommands, "lights_color", ADMFLAG_ROOT);
	AddToTopMenu(g_adminMenu, "lights_disco", TopMenuObject_Item, AdminMenu_LightsDisco, serverCommands, "lights_disco", ADMFLAG_ROOT);
	AddToTopMenu(g_adminMenu, "lights_reset", TopMenuObject_Item, AdminMenu_LightsReset, serverCommands, "lights_reset", ADMFLAG_ROOT);
	AddToTopMenu(g_adminMenu, "lights_switch", TopMenuObject_Item, AdminMenu_LightsSwitch, serverCommands, "lights_switch", ADMFLAG_ROOT);
}

public AdminMenu_LightsColor(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "%t", "Change All Lights");
		}
		case TopMenuAction_SelectOption:
		{
			DisplayColorsMenu(param);
		}
	}
}

DisplayColorsMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_LightColors);
	
	decl String:title[100];
	decl String:item[64];
	Format(title, sizeof(title), "%N: %t", client, "Change All Lights");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	Format(item, sizeof(item), "%t", "random");
	AddMenuItem(menu, "random", item);
	Format(item, sizeof(item), "%t", "red");
	AddMenuItem(menu, "red", item);
	Format(item, sizeof(item), "%t", "blue");
	AddMenuItem(menu, "blue", item);
	Format(item, sizeof(item), "%t", "green");
	AddMenuItem(menu, "green", item);
	Format(item, sizeof(item), "%t", "yellow");
	AddMenuItem(menu, "yellow", item);
	Format(item, sizeof(item), "%t", "purple");
	AddMenuItem(menu, "purple", item);
	Format(item, sizeof(item), "%t", "magenta");
	AddMenuItem(menu, "magenta", item);
	Format(item, sizeof(item), "%t", "pink");
	AddMenuItem(menu, "pink", item);
	Format(item, sizeof(item), "%t", "cyan");
	AddMenuItem(menu, "cyan", item);
	Format(item, sizeof(item), "%t", "orange");
	AddMenuItem(menu, "orange", item);
	Format(item, sizeof(item), "%t", "brown");
	AddMenuItem(menu, "brown", item);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_LightColors(Handle:menu, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_adminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_adminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		g_lightson = true;
		g_disco = false;
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
		{
			if (IsValidEntity(ent))
			{
				decl String:color2[64];
				GetColorFromInt(GetIntFromColor(info), color2, sizeof(color2));
				AcceptEntityInput(ent, "LightOff");
				DispatchKeyValue(ent, "rendercolor", color2);
				CreateTimer(0.25, Timer_TurnLightOn, ent, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		decl String:color3[64];
		GetNameFromColor(GetIntFromColor(info), color3, sizeof(color3));
		ReplyToCommand(param1, "[SM] %t", "Lights Changed", color3);
	}
}

public AdminMenu_LightsDisco(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "%t", "Enable Disco");
		}
		case TopMenuAction_SelectOption:
		{
			if (g_disco)
			{
				ReplyToCommand(param, "[SM] %t", "Disco Already On");
				return;
			}
			g_lightson = true;
			g_disco = true;
			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
			{
				if (IsValidEntity(ent))
				{
					decl String:color[64];
					GetColorFromInt(0, color, sizeof(color));
					AcceptEntityInput(ent, "LightOff");
					DispatchKeyValue(ent, "rendercolor", color);
					CreateTimer(0.25, Timer_TurnLightOnDisco, ent, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			ReplyToCommand(param, "[SM] %t", "Disco On");
		}
	}
}

public AdminMenu_LightsReset(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "%t", "Reset All Lights");
		}
		case TopMenuAction_SelectOption:
		{
			g_lightson = true;
			g_disco = true;
			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
			{
				if (IsValidEntity(ent))
				{
					AcceptEntityInput(ent, "LightOff");
					DispatchKeyValue(ent, "rendercolor", "255 255 255");
					CreateTimer(0.25, Timer_TurnLightOn, ent, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			ReplyToCommand(param, "[SM] %t", "Lights Reset");
		}
	}
}

public AdminMenu_LightsSwitch(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "%t", "Switch All Lights");
		}
		case TopMenuAction_SelectOption:
		{
			g_disco = false;
			new ent = -1;
			if (g_lightson)
			{
				while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
				{
					if (IsValidEntity(ent))
					{
						AcceptEntityInput(ent, "LightOff");
					}
				}
				ReplyToCommand(param, "[SM] %t", "Lights Off");
				g_lightson = false;
			}
			else
			{
				while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
				{
					if (IsValidEntity(ent))
					{
						AcceptEntityInput(ent, "LightOn");
					}
				}
				ReplyToCommand(param, "[SM] %t", "Lights On");
				g_lightson = true;
			}
		}
	}
}

public OnDiscoChanged(Handle:cvar, String:old_value[], String:new_value[])
{
	if (strcmp(new_value, "1", true) == 0)
	{
		if (g_disco)
		{
			return;
		}
		g_lightson = true;
		g_disco = true;
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
		{
			if (IsValidEntity(ent))
			{
				decl String:color[64];
				GetColorFromInt(0, color, sizeof(color));
				AcceptEntityInput(ent, "LightOff");
				DispatchKeyValue(ent, "rendercolor", color);
				CreateTimer(0.25, Timer_TurnLightOnDisco, ent, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	if (strcmp(new_value, "0", true) == 0)
	{
		g_disco = false;
	}
}

stock GetIntFromColor(const String:color[])
{
	if (strcmp(color, "random") == 0)		return 0;
	if (strcmp(color, "red") == 0)			return 1;
	if (strcmp(color, "blue") == 0)			return 2;
	if (strcmp(color, "green") == 0)		return 3;
	if (strcmp(color, "yellow") == 0)		return 4;
	if (strcmp(color, "orange") == 0)		return 5;
	if (strcmp(color, "pink") == 0)			return 6;
	if (strcmp(color, "magenta") == 0)		return 7;
	if (strcmp(color, "purple") == 0)		return 8;
	if (strcmp(color, "cyan") == 0)			return 9;
	if (strcmp(color, "brown") == 0)		return 10;
	return 0;
}

stock GetNameFromColor(int, String:color[], color_size)
{
	switch (int)
	{
		case 0:			Format(color, color_size, "random");
		case 1:			Format(color, color_size, "red");
		case 2:			Format(color, color_size, "blue");
		case 3:			Format(color, color_size, "green");
		case 4:			Format(color, color_size, "yellow");
		case 5:			Format(color, color_size, "orange");
		case 6:			Format(color, color_size, "pink");
		case 7:			Format(color, color_size, "magenta");
		case 8:			Format(color, color_size, "purple");
		case 9:			Format(color, color_size, "cyan");
		case 10:		Format(color, color_size, "brown");
	}
}

stock GetColorFromInt(int, String:color[], color_size)
{
	switch (int)
	{
		case 0:			Format(color, color_size, "%i %i %i", g_numbers[GetRandomInt(0, 7)], g_numbers[GetRandomInt(0, 7)], g_numbers[GetRandomInt(0, 7)]);
		case 1:			Format(color, color_size, "255 0 0");
		case 2:			Format(color, color_size, "0 0 255");
		case 3:			Format(color, color_size, "0 255 0");
		case 4:			Format(color, color_size, "255 255 0");
		case 5:			Format(color, color_size, "255 175 0");
		case 6:			Format(color, color_size, "255 150 150");
		case 7:			Format(color, color_size, "255 0 255");
		case 8:			Format(color, color_size, "175 0 255");
		case 9:			Format(color, color_size, "0 255 255");
		case 10:		Format(color, color_size, "150 100 0");
	}
}

public OnMapStart()
{
	g_disco = false;
	g_lightson = true;
	if (GetConVarInt(g_cvars[CVAR_DISCO]))
	{
		g_disco = true;
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "point_spotlight")) != -1)
		{
			if (IsValidEntity(ent))
			{
				decl String:color[64];
				GetColorFromInt(0, color, sizeof(color));
				AcceptEntityInput(ent, "LightOff");
				DispatchKeyValue(ent, "rendercolor", color);
				CreateTimer(0.25, Timer_TurnLightOnDisco, ent, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}