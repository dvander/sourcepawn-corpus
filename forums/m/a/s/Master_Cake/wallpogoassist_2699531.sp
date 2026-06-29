#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new bool:WP_ENABLED[MAXPLAYERS + 1];
new bool:WPFULL_ENABLED[MAXPLAYERS + 1];
new Handle:HudDisplayWP;

#define SEL1 "#select1"
#define SEL2 "#select2"
#define SEL3 "#select3"
#define SEL4 "#select4"
#define SEL5 "#select5"

public Plugin:myinfo =
{
	name = "Wall Pogo Assistant",
	author = "Master Cake",
	description = "This plugin helps jumpers to learn Wall Pogo",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_wp", WP_Command, "Command to enable/disable Wall Pogo Assistant");
	RegConsoleCmd("sm_wpfull", WPFULL_Command, "Command to enable/disable Wall Pogo Assistant");
	RegConsoleCmd("sm_wpmenu", WPMENU_Command, "Command to enable Wall Pogo Assistant Menu");
	HudDisplayWP = CreateHudSynchronizer();
}

public OnClientPutInServer(myClient)
{
	WP_ENABLED[myClient] = false;
	WPFULL_ENABLED[myClient] = false;
}

public Action:WP_Command(myClient, args)
{
    if (args > 0 ) {
   		ReplyToCommand(myClient, "[SM] This command has no arguments!");
   		return Plugin_Continue;
    }
    else {
    	if (!WP_ENABLED[myClient]) {
    		WP_ENABLED[myClient] = true;
    		ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Enabled!");
    	}
    	else {
    		WP_ENABLED[myClient] = false;
    		WPFULL_ENABLED[myClient] = false;
    		ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Disabled!");
    	}
    }

    return Plugin_Handled;
}

public Action:WPFULL_Command(myClient, args)
{
    if (args > 0 ) {
   		ReplyToCommand(myClient, "[SM] This command has no arguments!");
   		return Plugin_Continue;
    }
    else {
    	if (!WP_ENABLED[myClient] || !WPFULL_ENABLED[myClient]) {
    		WP_ENABLED[myClient] = true;
    		WPFULL_ENABLED[myClient] = true;
    		ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Full Enabled!");
    	}
    	else {
    		WPFULL_ENABLED[myClient] = false;
    		ReplyToCommand(myClient, "[SM] Wall Pogo Assistant Full Disabled!");
    	}
    }

    return Plugin_Handled;
}

public Action:OnPlayerRunCmd(myClient, &myButtons, &myImpulse, Float:fVel[3], Float:fAngles[3], &myWeapon)
{
	if(IsPlayerAlive(myClient) && IsValidClient(myClient) && WP_ENABLED[myClient] && myButtons & IN_DUCK)
	{
    	ClearSyncHud(myClient, HudDisplayWP);
    	static float:FL_Angles[3];
    	GetClientEyeAngles(myClient, FL_Angles);
    	if (FL_Angles[0] >= 75.0 && FL_Angles[0] <= 79.9)
    	{
    		SetHudTextParams(0.475, 0.4, 0.1, 0, 0, 255, 0, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplayWP, "▲▲▲");
    		return Plugin_Continue;
    	}
    	if (FL_Angles[0] >= 80.55 && FL_Angles[0] <= 81.0)
    	{
    		SetHudTextParams(0.475, 0.55, 0.1, 0, 255, 0, 0, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplayWP, "▼▼▼");
    		return Plugin_Continue;
    	}

    	if (WPFULL_ENABLED[myClient] && FL_Angles[0] >= 80.0 && FL_Angles[0] <= 80.54)
    	{
    		SetHudTextParams(0.44, 0.483, 0.1, 255, 255, 0, 0, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplayWP, "►►►    ◄◄◄");
    		return Plugin_Continue;
    	}
	}
	return Plugin_Continue;
}

public int MenuHandler(Handle:menu, MenuAction:action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
  		{
    		case 0:
    		{
      			new Handle:submenu = CreateMenu(MenuHandler2);
      			SetMenuTitle(submenu, "<--Wall Pogo Assistant-->\n ");
      			AddMenuItem(submenu, SEL1, "You need to sit down, else you won't be able to see indicators\n ", ITEMDRAW_DISABLED);
      			AddMenuItem(submenu, SEL2, "Then type '!wp' in chat to enable or disable green and blue indicators", ITEMDRAW_DISABLED);
      			AddMenuItem(submenu, SEL3, "Type '!wpfull' to enable all indicators (green, blue and yellow)", ITEMDRAW_DISABLED);
    			SetMenuExitButton(submenu, true);
    			SetMenuOptionFlags(submenu, MENUFLAG_BUTTON_EXIT);
    			DisplayMenu(submenu, param1, MENU_TIME_FOREVER);
      		}

      		case 1:
			{
      			new Handle:submenu = CreateMenu(MenuHandler2);
      			SetMenuTitle(submenu, "<--Wall Pogo Assistant-->\n ");
      			AddMenuItem(submenu, SEL1, "If you see blue indicator above your aim icon you can make pogo up the wall", ITEMDRAW_DISABLED);
      			AddMenuItem(submenu, SEL2, "If you see green indicator under your aim icon you can make pogo down the wall\n ", ITEMDRAW_DISABLED);
      			AddMenuItem(submenu, SEL3, "If you see yellow indicator you can make pogo\nwithout movement on vertical (doesn't always work)", ITEMDRAW_DISABLED);
    			SetMenuExitButton(submenu, true);
    			SetMenuOptionFlags(submenu, MENUFLAG_BUTTON_EXIT);
    			DisplayMenu(submenu, param1, MENU_TIME_FOREVER);
      		}
  		}
  	}

  	if(action == MenuAction_End)
  	{
  		delete menu;
  	}

  	return 0;
}

public int MenuHandler2(Handle:menu, MenuAction:action, int param1, int param2)
{
  	if(action == MenuAction_End)
  	{
  		delete menu;
  	}
  	return 0;
}

public Action:WPMENU_Command(myClient, args)
{
	new Handle:menu = CreateMenu(MenuHandler);
	SetMenuTitle(menu, "<--Wall Pogo Assistant-->");
	AddMenuItem(menu, SEL1, "How to Enable/Disable plugin");
	AddMenuItem(menu, SEL2, "How to use");
	SetMenuExitButton(menu, true);
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, myClient, MENU_TIME_FOREVER);

  	return Plugin_Handled;
}

stock bool:IsValidClient(myClient, bool:bReplay = true)
{
	if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
		return false;
	if(bReplay && (IsClientSourceTV(myClient) || IsClientReplay(myClient)))
		return false;
	return true;
}