////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////	This is a re-write of M3Motd plugin made by KaOs (https://forums.alliedmods.net/showthread.php?t=66795).	////
////	Also, I used a method of displaying MOTD in CS:GO discovered by Bacardi										////
////	(https://forums.alliedmods.net/showpost.php?p=1808763&postcount=33). Special thanks to 11530 and ajr1234	////
////	for resolving my doubts (https://forums.alliedmods.net/showthread.php?p=1895616).							////
////	This is my first plugin and I am absolutely not a coder, so there may be bugs. (But I hope there aren't 	////
////	any). Feel free to modify or refine	it... Of course it would be nice, if you didn't forget about credits.	////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////	Configuration:																								////
////		There are two convars plugin depends on:																////
////			- sm_rules_url																						////
////			- sm_contact_url																					////
////		It's currently impossible to display websites directly in the MOTD panel in CS:GO, so those urls link	////
////		to 'routing' (prefix r_) sites with simple JavaScript code. With that workaround you can open new		////
////		window right in the game and display proper (name without prefix) rules website or admin contact site.	////
////																												////
////		To configure, you have to do five steps:																////
////			1. Modify attached r_rules.html and set title and url to your proper rules website in the line 		////
////				var popup=window.open("http://yourdomain.com/rules.html","title","height=720,width=1280");		////
////			2. Do the step above for r_contact.html	too.														////
////			3. Place both r_rules.html and r_contact.html on your public http server (it may be Dropbox, but	////
////				you have to place them in the /Public folder.													////
////			4. Go back to your game server and set sm_rules_url to "http://yourdomain.com/r_rules.html" in 		////
////				your cfg/server.cfg (this is the link to the routing r_rules.html site)							////
////			5. Do the step above for sm_contact_url "http://yourdomain.com/r_contact.html" in your 				////
////				cfg/server.cfg (this is the link to the routing r_contact.html site)							////
////																												////
////	Usage:																										////
////		There are three in-game commands:																		////
////			- !donate - to be used by any player only in a chat window, opens defined donate website.			////
////			- !rules - to be used by any player only in a chat window, opens defined rules website.				////
////			- !sm_rules target (or "sm_rules target" in the console, respectively) - to be used by admins, 		////
////				("c" kick flag is required) shows rules to specified target (which can be name or #id).			////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
#pragma semicolon 1
#define PL_VERSION    "0.2"
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin:myinfo =
{
    name        = "NotifyMOTD",
    author      = "Wilczek, KaOs, Bacardi",
    description = "Admin notifier and MOTD Show for CS:GO",
    version     = PL_VERSION,
    url         = "http://www.g4g.pl"
};

new Handle:RulesURL;
new Handle:ContactURL;
new Handle:hTopMenu;

public OnPluginStart()
{
	RegConsoleCmd("donate", admin);
	RegConsoleCmd("rules", rules);
	RegAdminCmd("sm_rules", Command_ShowRules, ADMFLAG_KICK, "sm_rules <#userid|name>");
	RulesURL = CreateConVar("sm_rules_url","http://yourdomain.com/r_rules.html","Set this to the URL of your routing Rules.");
	ContactURL = CreateConVar("sm_contact_url","http://yourdomain.com/r_contact.html","Set this to the URL of your routing Contact site.");
	LoadTranslations("common.phrases");
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
 
	hTopMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, 
			"sm_rules",
			TopMenuObject_Item,
			AdminMenu_Rules,
			player_commands,
			"sm_rules",
			ADMFLAG_KICK);
	}
}

DisplayRulesMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Rules);
	
	decl String:title[100];
	Format(title, sizeof(title), "Show rules", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AdminMenu_Rules(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Show rules", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayRulesMenu(param);
	}
}

public MenuHandler_Rules(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM]", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM]", "Unable to target");
		}
		else
		{
			new String:name[32];
			GetClientName(target, name, sizeof(name));
			
			PerformMOTD(param1, target);
			ShowActivity2(param1, "[SM] ", "Showed rules", "_s", name);
		}
		
		DisplayRulesMenu(param1);
	}
}

public Action:admin(client, args)
{
	new String:CONURL[128];
	GetConVarString(ContactURL, CONURL, sizeof(CONURL));
	
	ShowMOTDPanel(client, "Contact", CONURL, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

public Action:rules(client, args)
{
	new String:MOTDURL[128];
	GetConVarString(RulesURL, MOTDURL, sizeof(MOTDURL));
	
	ShowMOTDPanel(client, "Rules", MOTDURL, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

public Action:Command_ShowRules(client, args) {
	if (args != 1) {
		return Plugin_Handled;	
	}
	
	new String:Target[64];
	GetCmdArg(1, Target, sizeof(Target));
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetList[MAXPLAYERS], targetCount;
	new bool:tnIsMl;
	
	targetCount = ProcessTargetString(Target, client, targetList, sizeof(targetList), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), tnIsMl);

	if(targetCount == 0)
	{
		ReplyToTargetError(client, targetCount);
	} 
	else
	{
		for (new i=0; i<targetCount; i++)
		{
			PerformMOTD(client, targetList[i]);
		}
	}
	
	return Plugin_Handled;
}

public PerformMOTD(client, target) {
	if (client != target) {
        PrintToChatAll("\x01 \x07[MOTD] %N thinks that %N needs to read the rules!", client, target);
	}
	
	new String:MOTDURL[128];
	GetConVarString(RulesURL, MOTDURL, sizeof(MOTDURL));
	
	ShowMOTDPanel(target, "Rules", MOTDURL, MOTDPANEL_TYPE_URL);
}