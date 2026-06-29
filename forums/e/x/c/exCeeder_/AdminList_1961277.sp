#include <sourcemod>

#pragma semicolon 1


public Plugin:myinfo = 
{
	name = "Admin List",
	author = "eXceeder",
	description = "AdminList of all and of online Admins",
	version = "1.0",
	url = "www.sourcemod.net"
}


public OnPluginStart()
{
	RegConsoleCmd("sm_admins", Command_AdminList);
}


public Action:Command_AdminList(client, args)
{
	Admins(client);
	
	return Plugin_Handled;
}


Admins(client)
{
	new Handle:menu = CreateMenu(AdminMenuHandler);
	
	SetMenuTitle(menu, "Admins");
	
	AddMenuItem(menu, "list", "Admin List");
	AddMenuItem(menu, "online", "Admins on the Server ?");
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 60);
}


public AdminMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		param2++;
		
		switch(param2)
		{
			case 1:
			{
				AdminList(client);
			}
			
			case 2:
			{
				OnlineAdmins(client);
			}
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


AdminList(client)
{
	new String:sPath[192];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/AdminList.txt");
	
	new Handle:hFile = OpenFile(sPath, "r");
	
	if(hFile == INVALID_HANDLE)
		return;
	
	new String:ReadLine[64];
	
	new Handle:adminlist = CreateMenu(AdminListHandler);
	
	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, ReadLine, sizeof(ReadLine)))
	{
		AddMenuItem(adminlist, "admin", ReadLine);
	}
	
	SetMenuTitle(adminlist, "Admin List");
	
	SetMenuExitBackButton(adminlist, true);
	
	DisplayMenu(adminlist, client, 60);	
}


public AdminListHandler(Handle:adminlist, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		AdminList(client);
	}
	
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Admins(client);
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(adminlist);
	}
}


OnlineAdmins(client)
{
	new Handle:online = CreateMenu(OnlineAdminHandler);
	
	SetMenuTitle(online, "Admins on the Server ?");
	
	new bool:g_b_onserver = false;
	
	for(new i; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			new AdminId:ID = GetUserAdmin(i);
			
			if(ID != INVALID_ADMIN_ID)
			{
				decl String:AdminName[MAX_NAME_LENGTH];
				GetClientName(i, AdminName, sizeof(AdminName));
				
				AddMenuItem(online, "name", AdminName);
				
				if(!g_b_onserver)
					g_b_onserver = true;
			}
		}
	}
	
	if(!g_b_onserver)
		AddMenuItem(online, "", "No admins on the server");
	
	SetMenuExitBackButton(online, true);
	
	DisplayMenu(online, client, 60);
}


public OnlineAdminHandler(Handle:online, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		OnlineAdmins(client);
	}
	
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Admins(client);
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(online);
	}
}


// --------------------------------- STOCKS --------------------------------- //


stock bool:IsClientValid(i)
{
	if(i > 0 && i <= MaxClients && IsClientInGame(i))
	{
		return true;
	}
	
	return false;
}