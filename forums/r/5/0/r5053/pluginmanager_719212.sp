//Includes:
#include <sourcemod>
#include <topmenus>

/* Make the admin menu plugin optional */
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo = 
{
	name = "Plugin Manager",
	author = "R-Hehl",
	description = "Plugin Manager",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};





public OnPluginStart()
{
	CreateConVar("sm_pluginmanager_version", PLUGIN_VERSION, "Plugin Manager Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
 
public Menu_ULPluginsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))
		ServerCommand("sm plugins unload %s",info)
		new String:newpath[128]
		new String:oldpath[128]
		Format(oldpath, sizeof(oldpath), "addons/sourcemod/plugins/%s.smx",info);
		Format(newpath, sizeof(newpath), "addons/sourcemod/plugins/disabled/%s.smx",info);
		RenameFile(newpath,oldpath)
	}

	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
 
public Action:Menu_ULPlugins(client)
{
	new Handle:pluginsdir = OpenDirectory("addons/sourcemod/plugins");
	new String:name[64];
	new FileType:type;
	new namelen;
	new Handle:menu = CreateMenu(Menu_ULPluginsHandler)
	SetMenuTitle(menu, "Unload Plugin:")
	
	while(ReadDirEntry(pluginsdir,name,sizeof(name),type)){
    if(type == FileType_File){
		namelen = strlen(name) - 4;
		if(StrContains(name,".smx",false) == namelen){
			strcopy(name,namelen + 1,name);
			/* Add it to the menu */
			AddMenuItem(menu, name, name)
      }
    }
  }
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	CloseHandle(pluginsdir)
	return Plugin_Handled
}
public Action:Menu_LPlugins(client)
{
	new Handle:pluginsdir = OpenDirectory("addons/sourcemod/plugins/disabled");
	new String:name[64];
	new FileType:type;
	new namelen;
	new Handle:menu = CreateMenu(Menu_LPluginsHandler)
	SetMenuTitle(menu, "Load Plugin:")
	
	while(ReadDirEntry(pluginsdir,name,sizeof(name),type)){
    if(type == FileType_File){
		namelen = strlen(name) - 4;
		if(StrContains(name,".smx",false) == namelen){
			strcopy(name,namelen + 1,name);
			/* Add it to the menu */
			AddMenuItem(menu, name, name)
      }
    }
  }
	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	CloseHandle(pluginsdir)
	return Plugin_Handled
}
public Menu_LPluginsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))
		new String:newpath[128]
		new String:oldpath[128]
		Format(oldpath, sizeof(oldpath), "addons/sourcemod/plugins/disabled/%s.smx",info);
		Format(newpath, sizeof(newpath), "addons/sourcemod/plugins/%s.smx",info);
		RenameFile(newpath,oldpath)
		ServerCommand("sm plugins load %s",info)
	}

	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public Menu_RLPluginsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))
		ServerCommand("sm plugins reload %s",info)
	}

	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
public Action:Menu_RLPlugins(client)
{
	new Handle:pluginsdir = OpenDirectory("addons/sourcemod/plugins");
	new String:name[64];
	new FileType:type;
	new namelen;
	new Handle:menu = CreateMenu(Menu_RLPluginsHandler)
	SetMenuTitle(menu, "Reload Plugin:")
	
	while(ReadDirEntry(pluginsdir,name,sizeof(name),type)){
    if(type == FileType_File){
		namelen = strlen(name) - 4;
		if(StrContains(name,".smx",false) == namelen){
			strcopy(name,namelen + 1,name);
			/* Add it to the menu */
			AddMenuItem(menu, name, name)
      }
    }
  }
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	CloseHandle(pluginsdir)
	return Plugin_Handled
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* If the category is third party, it will have its own unique name. */
	new TopMenuObject:server_commands = FindTopMenuCategory(topmenu, ADMINMENU_SERVERCOMMANDS); 
	if (server_commands == INVALID_TOPMENUOBJECT)
	{
		/* Error! */
		LogError("server_commands == INVALID_TOPMENUOBJECT")
		return;
	}
 
	AddToTopMenu(topmenu, 
		"Plugins",
		TopMenuObject_Item,
		AdminMenu_Plugins,
		server_commands,
		"sm_adminplugins",
		ADMFLAG_CONFIG);
}
 
public AdminMenu_Plugins(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Plugins");
	}
	else if (action == TopMenuAction_SelectOption)
	{
	Menu_Plugins(param)
	}
}
public Action:Menu_Plugins(client)
{
	new Handle:menu = CreateMenu(Menu_PluginsHandler)
	SetMenuTitle(menu, "Plugins:")
	AddMenuItem(menu, "Load", "Load")
	AddMenuItem(menu, "Unload", "Unload")
	AddMenuItem(menu, "Reload", "Reload")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}
public Menu_PluginsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
	switch(param2)
	{
	case 0:
    Menu_LPlugins(param1)
	case 1:
    Menu_ULPlugins(param1)
	case 2:
    Menu_RLPlugins(param1)
	}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2)
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
