#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.3d"

new Handle:AdminListEnabled=INVALID_HANDLE;
new Handle:AdminListMode=INVALID_HANDLE;
new Handle:AdminListMenu=INVALID_HANDLE;
new Handle:AdminListAdminFlag=INVALID_HANDLE;

new Handle:adminMenu=INVALID_HANDLE;

new bool:hidden[MAXPLAYERS+1]={false, ...};
new bool:permHidden[MAXPLAYERS+1]={false, ...};

public Plugin:myinfo=
{
	name="Admin List",
	author="Fredd",
	description="Prints online admins list to clients",
	version="1.3d",
	url="www.sourcemod.net",
};

public OnPluginStart()
{
	CreateConVar("adminlist_version", PLUGIN_VERSION, "Admin List Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegConsoleCmd("sm_admins", Command_Admins, "Displays online admins.");
	RegAdminCmd("sm_adminon", Command_AdminOn, ADMFLAG_GENERIC, "Shows you on the admin list.");
	RegAdminCmd("sm_adminoff", Command_AdminOff, ADMFLAG_GENERIC, "Hides you from the admin list.");
	RegAdminCmd("sm_adminpermoff", Command_AdminPermOff, ADMFLAG_GENERIC, "Permanently hides you from the admin list.");

	AdminListEnabled=CreateConVar("adminlist_on", "1", "Turns the admin list on and off. 1=on, 0=off");
	AdminListMode=CreateConVar("adminlist_mode", "1", "Changes how the admin list appears. 1=text, 2=panel");
	AdminListAdminFlag=CreateConVar("adminlist_adminflag", "d", "Admin flag to use in order for admins to be listed in the admin list.  Must be in char format!");

	AutoExecConfig(true, "plugin.adminlist");

	new Handle:topmenu=INVALID_HANDLE;
	if(LibraryExists("adminmenu") && ((topmenu=GetAdminTopMenu())!=INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnClientDisconnect(client)
{
	if(!permHidden[client])
	{
		hidden[client]=false;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
	{
		adminMenu=INVALID_HANDLE;
	}
}

public Action:Command_AdminOff(client, args)
{
	if(!IsValidClient(client))
	{
		CReplyToCommand(client, "{Olive}[AdminList]{Default} This command must be used in-game and without RCON.");
		return Plugin_Handled;
	}
	hidden[client]=true;
	CReplyToCommand(client, "{Olive}[AdminList]{Default} You will no longer show up on the admin list.");
	return Plugin_Handled;
}

public Action:Command_AdminPermOff(client, args)
{
	if(!IsValidClient(client))
	{
		CReplyToCommand(client, "{Olive}[AdminList]{Default} This command must be used in-game and without RCON.");
		return Plugin_Handled;
	}
	permHidden[client]=true;
	hidden[client]=true;
	CReplyToCommand(client, "{Olive}[AdminList]{Default} You have been permanently hidden from the admin list!");
	return Plugin_Handled;
}

public Action:Command_AdminOn(client, args)
{
	if(!IsValidClient(client))
	{
		CReplyToCommand(client, "{Olive}[AdminList]{Default} This command must be used in-game and without RCON.");
		return Plugin_Handled;
	}
	hidden[client]=false;
	CReplyToCommand(client, "{Olive}[AdminList]{Default} You will show up on the admin list again.");
	return Plugin_Handled;
}

public Action:Command_Admins(client, args)
{
	if(GetConVarBool(AdminListEnabled))
	{
		switch(GetConVarInt(AdminListMode))
		{
			case 1:  //Appears in chat area
			{
				decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
				new count=0;
				for(new client2=1; client2<=MaxClients; client2++)
				{
					if(IsClientInGame(client2) && !hidden[client2] && IsAdmin(client2))
					{
						GetClientName(client2, AdminNames[count], sizeof(AdminNames[]));
						count++;
					}
				}

				if(count==0)
				{
					CPrintToChatAll("{Olive}There are no admins online!{Default}");
					return Plugin_Handled;
				}
				else
				{
					decl String:buffer[1024];
					ImplodeStrings(AdminNames, count, ", ", buffer, sizeof(buffer));
					CPrintToChatAll("{Olive}Admins online are: %s{Default}", buffer);
					return Plugin_Handled;
				}
			}
			case 2:  //Appears as a panel
			{
				decl String:AdminName[MAX_NAME_LENGTH];
				AdminListMenu=CreateMenu(MenuListHandler);
				SetMenuTitle(AdminListMenu, "Admins Online:");							
				for(new client2=1; client2<=MaxClients; client2++)
				{
					if(IsClientInGame(client2) && !hidden[client2] && IsAdmin(client2))
					{
						GetClientName(client2, AdminName, sizeof(AdminName));
						AddMenuItem(AdminListMenu, AdminName, AdminName);
					} 
				}
				SetMenuExitButton(AdminListMenu, true);
				DisplayMenu(AdminListMenu, client, 15);
			}
		}
	}
	return Plugin_Handled;
}

public MenuListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock bool:IsAdmin(client)
{
	decl String:flags[64];
	GetConVarString(AdminListAdminFlag, flags, sizeof(flags));
	new ibFlags=ReadFlagString(flags);
	if((GetUserFlagBits(client) & ibFlags)==ibFlags)
	{
		return true;
	}

	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}

stock bool:IsValidClient(client, bool:replay=true)
{
	if(client<=0 || client>MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replay && (IsClientSourceTV(client) || IsClientReplay(client)))
	{
		return false;
	}
	return true;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if(topmenu==adminMenu)
	{
		return;
	}
	adminMenu=topmenu;
	new TopMenuObject:playerCommands=FindTopMenuCategory(adminMenu, ADMINMENU_PLAYERCOMMANDS);

	if(playerCommands!=INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(adminMenu, "adminlist", TopMenuObject_Item, AdminMenu_AdminOnOff, playerCommands, _, ADMFLAG_GENERIC);
	}
}

public AdminMenu_AdminOnOff(Handle:topmenu, TopMenuAction:action, TopMenuObject:objectID, client, String:buffer[], maxlength)
{
	if(action==TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "AdminList");
	}
	else if(action==TopMenuAction_SelectOption)
	{
		CreateMenuAdminList(client);
	}
}

public CreateMenuAdminList(client)
{
	new Handle:menu=CreateMenu(MenuHandlerAdminList);
	SetMenuTitle(menu, "Toggle your hidden status for the admin list:");
	AddMenuItem(menu, "adminoff", "Hide");
	AddMenuItem(menu, "adminpermoff", "Permanently Hide");
	AddMenuItem(menu, "adminon", "Show");

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandlerAdminList(Handle:menu, MenuAction:action, client, menuPos)
{
	new String:selection[32];
	GetMenuItem(menu, menuPos, selection, sizeof(selection));
	if(action==MenuAction_Select)
	{
		if(StrEqual(selection, "adminoff"))
		{
			Command_AdminOff(client, 0);
		}
		if(StrEqual(selection, "adminpermoff"))
		{
			Command_AdminPermOff(client, 0);
		}
		else if(StrEqual(selection, "adminon"))
		{
			Command_AdminOn(client, 0);
		}
		else
		{
			CPrintToChat(client, "{Olive}[AdminList]{Default} {Red}ERROR:{Default} Something went horribly wrong with the menu code!");
		}
		CreateMenuAdminList(client);
	}
}