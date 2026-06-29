#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <adminmenu>

new Handle:g_hReloadList = INVALID_HANDLE;
new Handle:hTopMenu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "TOG Reload Admin Menu",
	author = "That One Guy",
	description = "Reloads admin menu and all plugins listed within a cfg file",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("tram_version", PLUGIN_VERSION, "TOG Reload Admin Menu: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_reloadmenu", Command_Reload, "Reloads admin menu");
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

Run_Command()
{
	ServerCommand("sm plugins reload adminmenu.smx");
	
	for(new i = 0; i < GetArraySize(g_hReloadList); i++)
	{
		decl String:sBuffer[75];
		GetArrayString(g_hReloadList, i, sBuffer, sizeof(sBuffer));
		ServerCommand("sm plugins reload %s.smx", sBuffer);
	}
	
	ServerCommand("sm plugins reload togreloadadminmenu.smx");
}

public OnMapStart()
{
	LoadReloadList();
}

public Action:Command_Reload(client, args)
{
	if(client == 0)
	{
		Run_Command();
		return Plugin_Handled;
	}
	
	if(HasFlags("b", client))
	{
		Run_Command();
		ReplyToCommand(client, "[TOGs ADMIN MENU RELOAD] Admin Menu has been reloaded!");
	}
	else
	{
		ReplyToCommand(client, "[TOGs ADMIN MENU RELOAD] You do not have access to this command!");
	}
	return Plugin_Handled;
}

public LoadReloadList()
{
	g_hReloadList = CreateArray(64);
	
	decl String:sFile[256];
	BuildPath(Path_SM, sFile, 255, "configs/togreloadadminmenu_reloadlist.cfg");
	new Handle:hFile = OpenFile(sFile, "r");
	if (hFile != INVALID_HANDLE)
	{
		decl String:sBuffer[256];
		
		new i = 0;		//indexing the array
		while(ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
		{
			TrimString(sBuffer);		//remove spaces and tabs at both ends of string
			if((StrContains(sBuffer, "//") == -1) && (!StrEqual(sBuffer, "")))		//filter out comments and blank lines
			{
				ResizeArray(g_hReloadList, i+1);
				SetArrayString(g_hReloadList, i, sBuffer);
				i++;	//only increments if a valid string is found
			}
		}
	}
	else
	{
		LogError("File does not exist: \"%s\"", sFile);
	}
}

bool:HasFlags(String:sFlag[], client)
{
	if(!IsValidClient(client))
	{
		return false;
	}
	
	new AdminId:id = GetUserAdmin(client);
	
	if (id != INVALID_ADMIN_ID)
	{
		new count, found, flags = ReadFlagString(sFlag);
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				count++;

				if (GetAdminFlag(id, AdminFlag:i))
				{
					found++;
				}
			}
		}

		if (count == found)
		{
			return true;
		}
	}

	return false;
}

public bool:IsValidClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
	{
		return false;
	}
	return true;
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

	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "sm_reloadmenu", TopMenuObject_Item, AdminMenu_Command, server_commands, "sm_reloadmenu", ADMFLAG_BAN);	
	}
}

public AdminMenu_Command(Handle:topmenu,  TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)		//command via admin menu
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reload Admin Menu");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Run_Command();
		CloseHandle(topmenu);
	}
}