// SourceMod 1.7+
#include <sourcemod>
#include <clientprefs>
#include <scp>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

Handle gH_Cookie = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[CS:GO] Chat colors",
	author = "shavit",
	description = "Provides a menu with the option to change your chat color.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/member.php?u=163134"
}

public void OnPluginStart()
{
	gH_Cookie = RegClientCookie("sm_chatcolors_cookie", "Contains the used chat color", CookieAccess_Protected);

	CreateConVar("sm_csgochatcolors_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	RegAdminCmd("sm_colors", Command_Colors, ADMFLAG_GENERIC, "Pops up the colors menu");
}

public Action Command_Colors(int client, int args)
{
	Handle hMenu = CreateMenu(MenuHandler_Colors, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "Select a chat color:");

	AddMenuItem(hMenu, "none", "Default");
	AddMenuItem(hMenu, "\x02", "Strong Red");
	AddMenuItem(hMenu, "\x03", "Team Color");
	AddMenuItem(hMenu, "\x04", "Green");
	AddMenuItem(hMenu, "\x05", "Turquoise");
	AddMenuItem(hMenu, "\x06", "Yellow-Green");
	AddMenuItem(hMenu, "\x07", "Light Red");
	AddMenuItem(hMenu, "\x08", "Gray");
	AddMenuItem(hMenu, "\x09", "Light Yellow");
	AddMenuItem(hMenu, "\x0A", "Light Blue");
	AddMenuItem(hMenu, "\x0C", "Purple");
	AddMenuItem(hMenu, "\x0E", "Pink");
	AddMenuItem(hMenu, "\x10", "Orange");

	SetMenuExitButton(hMenu, true);

	DisplayMenu(hMenu, client, 20);

	return Plugin_Handled;
}

public int MenuHandler_Colors(Handle hMenu, MenuAction maAction, int client, int choice)
{
	if(maAction == MenuAction_Select)
	{
		char sChoice[8];
		GetMenuItem(hMenu, choice, sChoice, 8);

		SetClientCookie(client, gH_Cookie, sChoice);

		if(StrEqual(sChoice, "none"))
		{
			FormatEx(sChoice, 8, "\x01");
		}

		if(StrEqual(sChoice, "\x03"))
		{
			PrintToChat(client, " \x04[Chat Colors]\x01 Your chat color will match your team color.");
		}

		else
		{
			PrintToChat(client, " \x04[Chat Colors]\x01 You have selected %sthis color\x01.", sChoice);
		}
	}

	else if(maAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
}

public Action OnChatMessage(int &client, Handle hRecipients, char[] sName, char[] sMessage)
{
	if(CheckCommandAccess(client, "sm_colors", ADMFLAG_GENERIC))
	{
		char sCookie[8];
		GetClientCookie(client, gH_Cookie, sCookie, 8);

		if(StrEqual(sCookie, "") || StrEqual(sCookie, "none"))
		{
			return Plugin_Continue;
		}

		Format(sMessage, MAXLENGTH_MESSAGE, "%s%s", sCookie, sMessage);

		return Plugin_Changed;
	}

	return Plugin_Continue;
}
