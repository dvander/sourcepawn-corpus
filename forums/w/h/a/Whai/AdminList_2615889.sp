#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new Handle:AdminListEnabled = INVALID_HANDLE;
new Handle:AdminListMode = INVALID_HANDLE;
new Handle:AdminListMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Admin List",
	author = "Fredd - edited by Whai",
	description = "prints admins to clients",
	version = "1.2",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("adminlist_version", "1.2", "Admin List Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AdminListEnabled		= CreateConVar("adminlist_on", "1", "turns on and off admin list 1=on/0=off", 0, true, 0.0, true, 1.0);
	AdminListMode			= CreateConVar("adminlist_mode", "2", "mode that changes how the list appears..", 0, true, 1.0, true, 2.0);
	
	RegAdminCmd("sm_admins", Command_Admins, ADMFLAG_GENERIC, "Admin List");
	RegAdminCmd("sm_adminslist", Command_Admins, ADMFLAG_GENERIC, "Admin List");
	RegAdminCmd("sm_adminlist", Command_Admins, ADMFLAG_GENERIC, "Admin List");
}
public Action:Command_Admins(client, args)
{
	if(GetConVarInt(AdminListEnabled) == 1)
	{   
		switch(GetConVarInt(AdminListMode))
		{
			case 1:
			{
				decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
				new count = 0;
				for(new i = 1 ; i <= GetMaxClients();i++)
				{
					if(IsClientInGame(i))
					{
						new AdminId:AdminID = GetUserAdmin(i);
						if(AdminID != INVALID_ADMIN_ID)
						{
							GetClientName(i, AdminNames[count], sizeof(AdminNames[]));
							count++;
						}
					} 
				}
				decl String:buffer[1024];
				ImplodeStrings(AdminNames, count, ",", buffer, sizeof(buffer));
				PrintToChat(client, "\x04Admins online are: %s", buffer);
			}
			case 2:
			{
				decl String:AdminName[MAX_NAME_LENGTH];
				new String:authid[32];
				AdminListMenu = CreateMenu(MenuListHandler);
				SetMenuTitle(AdminListMenu, "Admins/VIPs Online:");
								
				for(new i = 1; i <= GetMaxClients(); i++)
				{
					if(IsClientInGame(i))
					{
						new AdminId:AdminID = GetUserAdmin(i);
						if(AdminID != INVALID_ADMIN_ID)
						{
							new String:buffer[64];
							GetClientName(i, AdminName, sizeof(AdminName));
							GetClientAuthId(i, AuthId_Steam2, authid, sizeof(authid));
							Format(buffer, sizeof(buffer), "%s : %s", AdminName, authid);
							AddMenuItem(AdminListMenu, AdminName, buffer);
						}
					} 
				}
				SetMenuExitButton(AdminListMenu, true);
				DisplayMenu(AdminListMenu, client, MENU_TIME_FOREVER);
				return Plugin_Handled;
			}
		}
	}
	else
	{
		ReplyToCommand(client, "\x04[SM] Admin list is disabled");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}public MenuListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsClientInGame(i))
			{
				decl String:AdminName[MAX_NAME_LENGTH];
				decl String:authid[32];
				new AdminId:AdminID = GetUserAdmin(i);
				if(AdminID != INVALID_ADMIN_ID)
				{
					decl String:buffer[64];
					GetClientName(i, AdminName, sizeof(AdminName));
					GetClientAuthId(i, AuthId_Steam2, authid, sizeof(authid));
					Format(buffer, sizeof(buffer), "\x04%s : %s", AdminName, authid);
					PrintToChat(param1, buffer);
				}
			} 
		}
	}
}