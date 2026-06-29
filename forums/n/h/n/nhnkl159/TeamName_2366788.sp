#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "nhnkl159"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <colors>

new Choosed[66];

public Plugin myinfo = 
{
	name = "[CS:GO] ChangeTeamName",
	author = PLUGIN_AUTHOR,
	description = "Admin can change the team name with simple command.",
	version = PLUGIN_VERSION,
	url = "-none-"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_names", Cmd_Names, ADMFLAG_BAN, "Teams Menu");
	AddCommandListener(NameSay, "say");
	AddCommandListener(NameSay, "say_team");
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "0"))
		{
			CPrintToChat(client, "\x05[Names]\x01 Write on the chat the name you want.");
			CPrintToChat(client, "\x05[Names]\x01 Write \x07!stop\x01 to stop the name change.");
			Choosed[client] = 1;
		}
		if (StrEqual(info, "1"))
		{
			CPrintToChat(client, "\x05[Names]\x01 Write on the chat the name you want.");
			CPrintToChat(client, "\x05[Names]\x01 Write \x07!stop\x01 to stop the name change.");
			Choosed[client] = 2;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}


public Action Cmd_Names(client, args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	Menu menu = new Menu(MenuHandler1);
	menu.SetTitle("Choose team :");
	menu.AddItem("0", "Terrorists");
	menu.AddItem("1", "Counter Terrorists");
	menu.ExitButton = true;
	menu.Display(client, 30);
 
	return Plugin_Handled;
	
}

public Action NameSay(int client, const char[] command, int args)
{
  	char text[4096];
  	GetCmdArgString(text, sizeof(text));
 	StripQuotes(text);
	if(Choosed[client] == 1)
	{
		if (StrEqual(text, "!stop")) 
		{
			CPrintToChat(client, "\x05[Names]\x01 You have stop the change name !", text);
			Choosed[client] = 0;
			return Plugin_Handled;
		}
		ServerCommand("mp_teamname_2 %s", text);
		CPrintToChat(client, "\x05[Names]\x01 The new name of the terrorists : \x07%s", text);
		Choosed[client] = 0;
		return Plugin_Handled;
	}
	if(Choosed[client] == 2)
	{
		if (StrEqual(text, "!stop")) 
		{
			CPrintToChat(client, "\x05[Names]\x01 You have stop the change name !", text);
			Choosed[client] = 0;
			return Plugin_Handled;
		}
		ServerCommand("mp_teamname_1 %s", text);
		CPrintToChat(client, "\x05[Names]\x01 The new name of the counter terrorists : \x07%s", text);
		Choosed[client] = 0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}