#pragma semicolon 1
#include <sourcemod>

new Handle:list_mode = INVALID_HANDLE;
new Handle:list_cmd = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[ANY] Adminlist",
	author = "Trinia",
	description = "Simple plugin which displays the current online admins.",
	version = "1.1",
	url = "http://NastyGaming.de"
};

public OnPluginStart()
{
	list_mode = CreateConVar("sm_adminlist_mode", "2", "Adminlist Mode (Default = 2) \nIf set 1 = Chat Adminlist; If set 2 = Menu Adminlist");
	list_cmd = CreateConVar("sm_adminlist_command", "admins", "Adminlist Command \nYou can choose your own Chat-Command for the Admin Onlinelist.");
	AutoExecConfig(true, "plugin.adminlist");
	
	new String:Command[32];
	new String:buffer[32];
	GetConVarString(list_cmd, Command, sizeof(Command));
	Format(buffer, sizeof(buffer), "sm_%s", Command);
	RegConsoleCmd(buffer, command_alist, "Command for Adminlist");
}

public Action:command_alist(i, args)
{
	new Listmode = GetConVarInt(list_mode);
	if (Listmode == 1)
	{
		decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
		new count = 0;

		for(new client = 1; client <= GetMaxClients(); client++)
		{
			if (IsClientInGame(client))
			{
				new AdminId:AdminID = GetUserAdmin(client); 
				if (AdminID != INVALID_ADMIN_ID)
				{
					GetClientName(client, AdminNames[count], sizeof(AdminNames[]));
					count++;
				}
			}
		}

		decl String:buffer[1024];
		ImplodeStrings(AdminNames, count, "\n", buffer, sizeof(buffer));

		PrintToChat(i, "\x03Admins online are:\n %s", buffer);
	}	
	else if (Listmode == 2)
	{
		decl String:AdminName[MAX_NAME_LENGTH];
		new Handle:menu = CreateMenu(adminlist);
		SetMenuTitle(menu, "~ Online Admins ~");
		
		for(new client = 1; client <= GetMaxClients(); client++)
		{
			if (IsClientInGame(client))
			{
				new AdminId:AdminID = GetUserAdmin(client); 
				if (AdminID != INVALID_ADMIN_ID)
				{
					GetClientName(client, AdminName, sizeof(AdminName));
					AddMenuItem(menu, AdminName, AdminName);
				}
			}
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, i, 20);
	}
	return Plugin_Handled;
}

public adminlist(Handle:menu, MenuAction:action, client, param)
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