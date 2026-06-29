#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hTopMenu = INVALID_HANDLE;
new Handle:Cvar_sidewinder_enabled = INVALID_HANDLE;
new Handle:Cvar_sentryrocket_critchance = INVALID_HANDLE;
new Handle:Cvar_sidewinder_remember = INVALID_HANDLE;

new String:g_sCrocket[5][3] = {"100", "75", "50", "25", "0"};

public Plugin:myinfo =
{
	name = "SideWinder Menu",
	author = "Wazz",
	description = "Simple SideWinder Menu Integration",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{	
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	Cvar_sidewinder_enabled = FindConVar("sm_sidewinder_enabled");
	Cvar_sentryrocket_critchance = FindConVar("sm_sentryrocket_critchance");
	Cvar_sidewinder_remember = CreateConVar("sm_sidewinder_remember", "0", "Whether the server reset sentry rockets to vanilla on map change");

}

public OnMapStart()
{
	if (GetConVarBool(Cvar_sidewinder_remember))
	{
 		SetConVarBool(Cvar_sidewinder_enabled, false);
		SetConVarString(Cvar_sentryrocket_critchance, "0");	
	}
}
 
public OnLibraryRemoved(const String:name[])
{
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = INVALID_HANDLE;
	}
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
 
 	hTopMenu = topmenu;
 	
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
 
	if (server_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
 
	AddToTopMenu(hTopMenu, 
		"sm_sidewinder_enabled",
		TopMenuObject_Item,
		AdminMenu_sidewinder_enabled,
		server_commands,
		"sm_sidewinder_enabled",
		ADMFLAG_RCON);
		
	AddToTopMenu(hTopMenu, 
		"sm_sentryrocket_critchance",
		TopMenuObject_Item,
		AdminMenu_sidewinder_critchance,
		server_commands,
		"sm_sentryrocket_critchance",
		ADMFLAG_RCON);
}
 
public AdminMenu_sidewinder_enabled(Handle:topmenu, 
					TopMenuAction:action,
					TopMenuObject:object_id,
					client,
					String:buffer[],
					maxlength)
{	
	if (action == TopMenuAction_DisplayOption)
	{
		if(GetConVarBool(Cvar_sidewinder_enabled))
		{
			Format(buffer, maxlength, "SideWinder: Disable Homing Rockets");
		}
		else
		{
			Format(buffer, maxlength, "SideWinder: Enable Homing Rockets");
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DoSideWinding(client)
		RedisplayAdminMenu(topmenu, client);	
	}
}
 
 
bool:DoSideWinding(client)
 {
	decl String:playerName[65];
	GetClientName(client,playerName,sizeof(playerName));
		
 	if( GetConVarBool(Cvar_sidewinder_enabled) )
 	{
 		SetConVarBool(Cvar_sidewinder_enabled, false);
		ShowActivity2(client, "[SM] ", "Disabled SideWinding Rockets");	
 		LogMessage( "\"%L\" disabled SideWinding Rockets", client );
 		return false;
 	}
 	else
 	{
 		SetConVarBool(Cvar_sidewinder_enabled, true);	
		ShowActivity2(client, "[SM] ", "Enabled SideWinding Rockets");
 		LogMessage( "\"%L\" enabled SideWinding Rockets", client );
 		return true;
 	}
}

public AdminMenu_sidewinder_critchance(Handle:topmenu, 
					TopMenuAction:action,
					TopMenuObject:object_id,
					client,
					String:buffer[],
					maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "SideWinder: Set Crit Chance");
	}
	else if (action == TopMenuAction_SelectOption)
	{

		DisplayCritRocketMenu(client);
	}
}

DisplayCritRocketMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_CritRocket);
	
	decl String:title[100];
	Format(title, sizeof(title), "%s:", "Sentry Rocket Crit Chance (%%)");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	for (new c = 0; c < sizeof(g_sCrocket); c++) 
	{
		AddMenuItem(menu, g_sCrocket[c], g_sCrocket[c]);		
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_CritRocket(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:playerName[65];
		GetClientName(client,playerName,sizeof(playerName));
		
		new String:crit[6];

		GetMenuItem(menu, param2, crit, sizeof(crit));
		
		SetConVarString(Cvar_sentryrocket_critchance, crit);	

		ShowActivity2(client, "[SM] ", "Changing Sentry Rocket Crit Chance to %s%%", crit);
 		LogMessage( "\"%L\" Changing Sentry Rocket Crit Chance to %s%%", client, crit );	

		DisplayCritRocketMenu(client);
	}
}