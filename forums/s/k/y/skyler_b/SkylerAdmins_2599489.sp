#define PLUGIN_AUTHOR "Skyler"
#define PLUGIN_VERSION "0.01"
#define PREFIX " \x0E[\x0CSkylerAdmins\x0E] \x04"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <sdkhooks>
#include <skyler>

Handle h_SkylerAdminStatus;

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_admins", CMD_admins, "");
	h_SkylerAdminStatus = RegClientCookie("admins_status", "status of the admin", CookieAccess_Protected);
}
public Action CMD_admins(int client, args)
{
	if (args > 2)
	{
		PrintToChat(client, "%s Error to many arguments!", PREFIX);
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char status[128];
		GetCmdArg(1, status, sizeof(status));
		if (GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			if (StrEqual(status, "0"))
			{
				PrintToChat(client, "%s You changed your admin visibility to \x02OFF\x04!", PREFIX);
				SetClientCookie(client, h_SkylerAdminStatus, "0");
			}
			else if (StrEqual(status, "1"))
			{
				PrintToChat(client, "%s You changed your admin visibility to \x06ON\x04!", PREFIX);
				SetClientCookie(client, h_SkylerAdminStatus, "1");
			}
			else
			{
				PrintToChat(client, "%s You can only change the status to 1/0 !", PREFIX);
				return Plugin_Handled;
			}
		}
	}
	else if (args == 0)
	{
		Menu admins = CreateMenu(AdminsMenuHandler);
		admins.SetTitle("[SkylerAdmins] Online admins currectly in server! \n");
		for (int i = 1; i <= MaxClients;i++ )
		{
			char status[128];
			GetClientCookie(i, h_SkylerAdminStatus, status, sizeof(status));
			if(IsValidClient(i) && StrEqual(status, "1"))
			{
				char display[512];
				char name[32];
				GetClientName(i, name, sizeof(name));
				Format(display, sizeof(display), ">> %s", name);
				admins.AddItem("", display);
			}
		}
		admins.Pagination = MENU_NO_PAGINATION;
		admins.ExitButton = true;
		admins.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Continue;
}
public int AdminsMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
}