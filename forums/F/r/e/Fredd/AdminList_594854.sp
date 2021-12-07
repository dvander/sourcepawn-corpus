#include <sourcemod>

#pragma semicolon 1

new Handle:AdminListEnabled = INVALID_HANDLE;
new Handle:AdminListMode = INVALID_HANDLE;
new Handle:AdminListMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Admin List",
	author = "Fredd",
	description = "prints admins to clients",
	version = "1.2",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("adminlist_version", "1.2", "Admin List Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AdminListEnabled		= CreateConVar("adminlist_on", "1", "turns on and off admin list, 1=on ,0=off");
	AdminListMode			= CreateConVar("adminlist_mode", "1", "mode that changes how the list appears..");
	
	RegConsoleCmd("say", SayHook);
	RegConsoleCmd("say_team", SayHook);
}
public Action:SayHook(client, args)
{
	if(GetConVarInt(AdminListEnabled) == 1)
	{   
		new String:text[192];
		GetCmdArgString(text, sizeof(text));
		
		new startidx = 0;
		if (text[0] == '"')
		{
			startidx = 1;
			
			new len = strlen(text);
			if (text[len-1] == '"')
			{
				text[len-1] = '\0';
			}
		}
		
		if(StrEqual(text[startidx], "!admins") || StrEqual(text[startidx], "/admins"))
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
					PrintToChatAll("\x04Admins online are: %s", buffer);
				}
				case 2:
				{
					decl String:AdminName[MAX_NAME_LENGTH];
					AdminListMenu = CreateMenu(MenuListHandler);
					SetMenuTitle(AdminListMenu, "Admins Online:");
									
					for(new i = 1; i <= GetMaxClients(); i++)
					{
						if(IsClientInGame(i))
						{
							new AdminId:AdminID = GetUserAdmin(i);
							if(AdminID != INVALID_ADMIN_ID)
							{
								GetClientName(i, AdminName, sizeof(AdminName));
								AddMenuItem(AdminListMenu, AdminName, AdminName);
							}
						} 
					}
					SetMenuExitButton(AdminListMenu, true);
					DisplayMenu(AdminListMenu, client, 15);
				}
			}
		}
	}
	return Plugin_Continue;
}public MenuListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}