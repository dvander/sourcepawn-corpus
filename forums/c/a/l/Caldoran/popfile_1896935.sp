#include <sourcemod>

public Plugin:myinfo =
{
	name = "MvM Popfile Menu",
	author = "Caldoran",
	description = "Easy-to-use popfile selecter for MvM",
	version = "0.5",
	url = "http://www.sourcemod.net"
};

// new Handle:g_Cvar_PopfileMatch = INVALID_HANDLE;
new Handle:g_PopfileMenu = INVALID_HANDLE

public OnPluginStart()
{
	RegAdminCmd("sm_popfile", Command_ChangePopfile, ADMFLAG_CHANGEMAP, "sm_popfile - Displays menu for admins to select popfile in MvM");
	//g_Cvar_PopfileMatch = CreateConVar("sm_popfile_match", "1", "Determines whether to match the returned popfiles to the current map", _, true, 0, true, 1);
	AutoExecConfig(true, "plugin_popfile");
}

public OnMapStart()
{
	g_PopfileMenu = BuildPopfileMenu();
}
 
public OnMapEnd()
{
	if (g_PopfileMenu != INVALID_HANDLE)
	{
		CloseHandle(g_PopfileMenu);
		g_PopfileMenu = INVALID_HANDLE;
	}
}

Handle:BuildPopfileMenu()
{
	/* Open the file */
	new Handle:file = OpenFile("popfiles.txt", "r");
	if (file == INVALID_HANDLE)
	{
		return INVALID_HANDLE;
	}
 
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_ChangePopfile);
	new String:popfilename[255];
	while (!IsEndOfFile(file) && ReadFileLine(file, popfilename, sizeof(popfilename)))
	{
		if (popfilename[0] == ';' || !IsCharAlpha(popfilename[0]))
		{
			continue;
		}
		/* Cut off the name at any whitespace */
		new len = strlen(popfilename);
		for (new i=0; i<len; i++)
		{
			if (IsCharSpace(popfilename[i]))
			{
				popfilename[i] = '\0';
				break;
			}
		}
		/* Add it to the menu */
		AddMenuItem(menu, popfilename, popfilename);
	}
	/* Make sure we close the file! */
	CloseHandle(file);
 
	/* Finally, set the title */
	SetMenuTitle(menu, "Please select a pop file:");
 
	return menu;
}
 
public Menu_ChangePopfile(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
 
		/* Tell the client */
		PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
 
		/* Change the popfile */
		ServerCommand("tf_mvm_popfile %s", info);
	}
}
 
public Action:Command_ChangePopfile(client, args)
{
	if (g_PopfileMenu == INVALID_HANDLE)
	{
		PrintToConsole(client, "The popfiles.txt file was not found!");
		return Plugin_Handled;
	}	
 
	DisplayMenu(g_PopfileMenu, client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}