#include <sourcemod>
#include <cstrike>

new Handle:g_DonatorsMenu = INVALID_HANDLE

new Handle:sm_donatorsmenu_join = INVALID_HANDLE;
new Handle:sm_donatorsmenu_announce_player = INVALID_HANDLE;
new Handle:sm_donatorsmenu_announce_admin = INVALID_HANDLE;

#define VERSION "1.1"

public Plugin:myinfo =
{
	name = "Donations Menu",
	author = "niK0",
	description = "Donators list.",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};


 
public OnPluginStart()
{
	// Exec CFG
	AutoExecConfig(true, "donatorsmenu");
	
	// Version cvar
	CreateConVar("sm_donatorsmenu_version", VERSION, "Defines the version of the Rules Menu installed on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Cvars
	sm_donatorsmenu_join = CreateConVar("sm_donatorsmenu_join", "0", "Enables/disables if a player joins the server to show the rules.");
	sm_donatorsmenu_announce_player = CreateConVar("sm_donatorsmenu_announce_player", "0", "Announce if a player is checking the rules with a message in chat.");
	sm_donatorsmenu_announce_admin = CreateConVar("sm_donatorsmenu_announce_admin", "0", "Announce if an admin is using the showrules command with a message in chat.");
	
	// Console command
	RegConsoleCmd("sm_donators", Command_Donators);
	RegAdminCmd("sm_showdonators", Command_ShowDonators, ADMFLAG_KICK, "sm_showdonators <player> to show the donators list");
	
	// Translations init
	LoadTranslations("common.phrases");
	LoadTranslations("donatorsmenu.phrases");
}
 
public OnMapStart()
{
	g_DonatorsMenu = BuildDonatorMenu();
}
 
public OnMapEnd()
{
	if (g_DonatorsMenu != INVALID_HANDLE)
	{
		CloseHandle(g_DonatorsMenu);
		g_DonatorsMenu = INVALID_HANDLE;
	}
}
 
Handle:BuildDonatorMenu()
{
	/* Open the file */
	new Handle:file = OpenFile("addons/sourcemod/configs/donators.ini", "rt");
	if (file == INVALID_HANDLE)
	{
		return INVALID_HANDLE;
	}
 
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Donators);
	new String:donator[255];
	while (!IsEndOfFile(file) && ReadFileLine(file, donator, sizeof(donator)))
	{
		/* Add it to the menu */
		AddMenuItem(menu, donator, donator);
	}
	/* Make sure we close the file! */
	CloseHandle(file);
 
	/* Finally, set the title */
	SetMenuTitle(menu, "Donators List:");
 
	return menu;
}

 public OnClientAuthorized(client,const String:auth[])
{
	if (IsFakeClient(client)) 
	{
	return;
	}
	
	if(GetConVarBool(sm_donatorsmenu_join))
	{
		DisplayMenu(g_DonatorsMenu, client, MENU_TIME_FOREVER);
	}
}

public Menu_Donators(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{

	}
}
 

public Action:Command_Donators(client, args)
{
	if (g_DonatorsMenu == INVALID_HANDLE)
	{
		PrintToConsole(client, "The donators.ini in the sourcemod config directory file was not found!");
		return Plugin_Handled;
	}	
 
	DisplayMenu(g_DonatorsMenu, client, MENU_TIME_FOREVER);
	if(GetConVarBool(sm_donatorsmenu_announce_player))
	{
		PrintToChatAll("\x04[Donators] \x03%t", "Showing Donators", client);
	}
	
 	PrintToChat(client, "\x04[Donators] \x03%t", "Readgood");
	
	return Plugin_Handled;
}

public Action:Command_ShowDonators(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_showdonators <#userid|name>");
		return Plugin_Handled;
	}

	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	new len = BreakString(Arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		
		new donators_self = 0;
		
		for (new i = 0; i < target_count; i++)
		{
			/* Swap everyone else first */
			if (target_list[i] == client)
			{
				donators_self = client;
			}
			else
			{
				DisplayMenu(g_DonatorsMenu, target_list[i], MENU_TIME_FOREVER);
				if(GetConVarBool(sm_donatorsmenu_announce_admin))
				{
					PrintToChatAll("\x04[Donators] \x03%t", "Showdonators", client, target_list[i]);
				}
 				PrintToChat(target_list[i], "\x04[Donators] \x03%t", "Readgood");
				LogAction(client, -1, "\"%L\" used sm_showdonators to player: \"%L\" ", client, target_list[i]);
			}
		}
		
		if (donators_self)
		{
			DisplayMenu(g_DonatorsMenu, client, MENU_TIME_FOREVER);
			if(GetConVarBool(sm_donatorsmenu_announce_admin))
			{
				PrintToChatAll("\x04[Donators] \x03%t", "Showdonators", client);
			}
 			PrintToChat(client, "\x04[Donators] \x03%t", "Readgood");
			LogAction(client, -1, "\"%L\" used sm_showdonators on his self.", client);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}

	return Plugin_Handled;
}

