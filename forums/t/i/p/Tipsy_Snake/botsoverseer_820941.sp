/************************************************************
 *															*
 *					Bots Overseer							*
 *						by Tipsy Snake						*
 *															*
 ************************************************************
 *															*
 *	Bots Management Plugin for Counter-Strike: Source		*
 *	I took an idea from dalto's Bot Tools but as that one	*
 *	looks like just an example and don't care about special	*
 *	in-game situations so I decided to write my own script	*
 *															*
 ************************************************************
 
 ////////////////////////////////////////////////////////////
 
	Changelog:
	
	0.95
		* sm_bot_autoslay_mode cvar added to allow autoslay teammates of the killed human if he was last on his team
		* Minor changes in config menu

	0.9
		* Admin menu added

	0.5
		* The plugin now proceed next situations:
			- if human victim was the last alive on his team,
			  then don't autoslay bots
			- whether to slay bots if bomb has been planted
			  and the last human was Terrorist
			  (sm_bot_autoslay_bomb = 0)
			  
	0.1
		* Initial version. Just autoslay functionality
	
	TODO:
	
		* add delay before slaying bots!
		* adding bots using menu
		* add Admin flag for menu

 ////////////////////////////////////////////////////////////
 
*/

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define	PLUGIN_VERSION "0.95"

public Plugin:myinfo =
{
	name = "Bots Overseer",
	author = "Tipsy Snake",
	description = "Bots control plugin for CS:S",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=91700"
};

#define TEAM_SPEC	1
#define TEAM_T		2
#define TEAM_CT		3

new Handle:hAdminMenu = INVALID_HANDLE;

/* Plugin ConVars */
new Handle:g_Cvar_AutoSlay = INVALID_HANDLE;
//new Handle:g_Cvar_AutoSlayDelay = INVALID_HANDLE;
new Handle:g_Cvar_AutoSlayMode = INVALID_HANDLE;
new Handle:g_Cvar_AutoSlayBomb = INVALID_HANDLE;
new Handle:g_Cvar_AutoSlayNotify = INVALID_HANDLE;

new bool:g_BombPlanted = false;

enum BO_Submenu	{
		BO_Submenu_Config			= 0,
		BO_Submenu_Kill				= 1,
		BO_Submenu_Kick				= 2,
		BO_Submenu_Difficulty		= 3
};


public OnPluginStart()
{
	LoadTranslations("botsoverseer.phrases");
	
	CreateConVar("sm_bots_overseer_version", PLUGIN_VERSION, "Bots Overseer version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_Cvar_AutoSlay = CreateConVar("sm_bot_autoslay", "1", "Enables or disables autoslaying bots when all human players died.", FCVAR_PLUGIN);
	//g_Cvar_AutoSlayDelay = CreateConVar("sm_bot_autoslay_delay", "5", "Delay in seconds between the last human die and bots autoslay.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	g_Cvar_AutoSlayMode = CreateConVar("sm_bot_autoslay_mode", "0", "\"0\" - normal mode; \"1\" - \"teammates\" mode, if the killed human was the last human on his team, then slay his teammates.", FCVAR_PLUGIN);
	g_Cvar_AutoSlayBomb = CreateConVar("sm_bot_autoslay_bomb", "0", "If set to \"0\" then Bot Overseer will not autoslay bots if bomb has been planted and the last killed human was Terrorist. So CT-bots can successfully defuse bomb and win the round.", FCVAR_PLUGIN);
	g_Cvar_AutoSlayNotify = CreateConVar("sm_bot_autoslay_notify", "1", "Turns on/off displaying Bots Overseer notifications in chat.", FCVAR_PLUGIN);

	RegAdminCmd("sm_bot_slay", CommandBotSlay, ADMFLAG_GENERIC, "Kill all bots");

	// Execute the config file
	AutoExecConfig(true, "botsoverseer");

	// Set hooks
	HookEvent("player_death", EventPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_PostNoCopy);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
	
	// See if the menu plugins already ready
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		// If so, manually fire the callback
		OnAdminMenuReady(topmenu);
	}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If autoslay is disabled then exit function
	if(GetConVarBool(g_Cvar_AutoSlay))
	{
		// Proceed only if victim is human
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!IsFakeClient(victim))
		{
			// If sm_bot_autoslay_bomb = 0 and bomb has been planted and victim was T then don't autoslay
			if (!GetConVarBool(g_Cvar_AutoSlayBomb) && g_BombPlanted && GetClientTeam(victim) == TEAM_T)
			{
				if (GetConVarBool(g_Cvar_AutoSlayNotify))
					PrintToChatAll("\x03[Bots Overseer] %t", "Bots-Defusers");
			}
			else if (GetConVarBool(g_Cvar_AutoSlayMode))
			{
				// "Teammates" Mode
			
				// Check if victim was the last human on its team
				new victim_team = GetClientTeam(victim);
				new bool:isAnyHumanTeammateAlive = false;
				new bool:isLastOnHisTeam = true;
				
				for (new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == victim_team)
					{
						isLastOnHisTeam = false;
						if (!IsFakeClient(i))
						{
							isAnyHumanTeammateAlive = true;
							break;
						}
					}
				}
				
				if (!isAnyHumanTeammateAlive && !isLastOnHisTeam)
				{
					if (victim_team == TEAM_T)
					{
						ServerCommand("bot_kill all t");
					}
					else
					{
						ServerCommand("bot_kill all ct");
					}
					if (GetConVarBool(g_Cvar_AutoSlayNotify))
						PrintToChatAll("\x03[Bots Overseer] %t", "Bots Autoslayed");
				}
			}
			else
			{
				// Normal Mode
			
				new bool:isAnyHumanAlive = false;
				
				for (new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
					{
						isAnyHumanAlive = true;
						break;
					}
				}
				
				if(!isAnyHumanAlive)
				{
					new victim_team = GetClientTeam(victim);
					
					// Check if victim was the last one on its team; if it's true then don't slay bots (because of Round End)
					new bool:isLastOnHisTeam = true;
					
					for (new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == victim_team)
						{
							isLastOnHisTeam = false;
							break;
						}
					}
					
					// If victim wasn't the last on its team then slay bots (also slay if victim was the last T and bomb has been planted)
					if (!isLastOnHisTeam || (GetConVarBool(g_Cvar_AutoSlayBomb) && g_BombPlanted == true && victim_team == TEAM_T))
					{
						CommandBotSlay(0, 0);
						if (GetConVarBool(g_Cvar_AutoSlayNotify))
							PrintToChatAll("\x03[Bots Overseer] %t", "Bots Autoslayed");
					}
				}
			}
		}
	}
}

public Action:CommandBotSlay(client, args)
{
	ServerCommand("bot_kill");

	return Plugin_Handled;
}


public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_BombPlanted = false;
}

public EventBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_BombPlanted = true;
}


/************************************************************
 *						Admin Menu							*
 ************************************************************/
 
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hAdminMenu)
		return;
 
	hAdminMenu = topmenu;
	
	// Category
	new TopMenuObject:botmenu = AddToTopMenu(
			hAdminMenu,				// TopMenu Handle
			"bot_autoslay_menu",	// Object name (MUST be unique)
			TopMenuObject_Category,	// Object type
			CategoryHandler,		// Handler for object
			INVALID_TOPMENUOBJECT	// Parent object ID
									// Command name (for access overrides)
									// Default access flags
									// Arbitrary storage (max 255 bytes)
			);

	if(botmenu == INVALID_TOPMENUOBJECT )
		return;
	
	// Items
	AddToTopMenu(
		hAdminMenu,
		"bot_autoslay_config",
		TopMenuObject_Item,
		BotMenu_Config,
		botmenu);

	AddToTopMenu(
		hAdminMenu,
		"bot_kill",
		TopMenuObject_Item,
		BotMenu_Kill,
		botmenu);

	AddToTopMenu(
		hAdminMenu,
		"bot_kick",
		TopMenuObject_Item,
		BotMenu_Kick,
		botmenu);
	
	AddToTopMenu(
		hAdminMenu,
		"bot_difficulty",
		TopMenuObject_Item,
		BotMenu_Difficulty,
		botmenu);	
}

public CategoryHandler(Handle:topmenu, 
					TopMenuAction:action,
					TopMenuObject:object_id,
					param,
					String:buffer[],
					maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Bots Overseer Menu");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Bots Overseer");
	}
}

////////////////////////////////////////////////////////////////////////////////////

public BotMenu_Config(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
						param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Configure");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* client who selected item is in param */
		ShowMenu(param, BO_Submenu_Config);
	}
}

public BotMenu_Kill(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
					param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Kill Bots...");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* client who selected item is in param */
		ShowMenu(param, BO_Submenu_Kill);
	}
}

public BotMenu_Kick(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
					param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Kick Bots...");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* client who selected item is in param */
		ShowMenu(param, BO_Submenu_Kick);
	}
}

public BotMenu_Difficulty(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
					param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Bot Difficulty");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* client who selected item is in param */
		ShowMenu(param, BO_Submenu_Difficulty);
	}
}

////////////////////////////////////////////////////////////////////////////////////

public ShowMenu(client, BO_Submenu:select)
{
	new Handle:menu = INVALID_HANDLE;
	
	switch(select)
	{
		case BO_Submenu_Config:
		{
			menu = CreateMenu(MenuConfigHandler);
			SetMenuTitle(menu, "Configure Autoslaying");
			// #0
			AddMenuItem(menu, "sm_bot_autoslay", GetConVarBool(g_Cvar_AutoSlay) ? "Autoslaying bots is enabled" : "Autoslaying bots is disabled");
			// #1
			AddMenuItem(menu, "sm_bot_autoslay_mode", GetConVarBool(g_Cvar_AutoSlayMode) ? "Autoslaying mode: teammates" : "Autoslaying mode: normal");
			// #2
			AddMenuItem(menu, "sm_bot_autoslay_bomb", GetConVarBool(g_Cvar_AutoSlayBomb) ? "If bomb has been planted: enabled" : "If bomb has been planted: disabled");
			// #3
			AddMenuItem(menu, "sm_bot_autoslay_notify", GetConVarBool(g_Cvar_AutoSlayNotify) ? "Notifying is enabled" : "Notifying is disabled");
		}
		case BO_Submenu_Kill:
		{
			menu = CreateMenu(MenuKillHandler);
			SetMenuTitle(menu, "Kill Bots");
			// #1
			AddMenuItem(menu, "kill_all", "Kill all");
			// #2
			AddMenuItem(menu, "kill_all_t", "Kill all T");
			// #3
			AddMenuItem(menu, "kill_all_ct", "Kill all CT");
			// #4
			AddMenuItem(menu, "kill_t", "Kill one T");
			// #5
			AddMenuItem(menu, "kill_ct", "Kill one CT");
		}
		case BO_Submenu_Kick:
		{
			menu = CreateMenu(MenuKickHandler);
			SetMenuTitle(menu, "Kick Bots");
			// #1
			AddMenuItem(menu, "kick_all", "Kick all");
			// #2
			AddMenuItem(menu, "kick_all_t", "Kick all T");
			// #3
			AddMenuItem(menu, "kick_all_ct", "Kick all CT");
			// #4
			AddMenuItem(menu, "kick_t", "Kick one T");
			// #5
			AddMenuItem(menu, "kick_ct", "Kick one CT");
		}
		case BO_Submenu_Difficulty:
		{
			new String:botDifficulty[4][8] = {
					"Easy",
					"Normal",
					"Hard",
					"Expert"
			};
			new String:currDiff[32] = "Current: ";
			StrCat(currDiff, sizeof(currDiff), botDifficulty[GetConVarInt(FindConVar("bot_difficulty"))]);

			menu = CreateMenu(MenuDifficultyHandler);
			SetMenuTitle(menu, "Select Bot Difficulty:");
			// #1
			AddMenuItem(menu, "bot_diff_easy", botDifficulty[0]);
			// #2
			AddMenuItem(menu, "bot_diff_normal", botDifficulty[1]);
			// #3
			AddMenuItem(menu, "bot_diff_hard", botDifficulty[2]);
			// #4
			AddMenuItem(menu, "bot_diff_expert", botDifficulty[3]);
			// #5
			AddMenuItem(menu, "bot_diff_spacer", "", ITEMDRAW_SPACER);
			// #6
			AddMenuItem(menu, "bot_diff_current", currDiff, ITEMDRAW_DISABLED);
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public MenuConfigHandler(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (item)
			{
				case 0:
					SetConVarBool(g_Cvar_AutoSlay, !GetConVarBool(g_Cvar_AutoSlay));
				case 1:
					SetConVarBool(g_Cvar_AutoSlayMode, !GetConVarBool(g_Cvar_AutoSlayMode));
				case 2:
					SetConVarBool(g_Cvar_AutoSlayBomb, !GetConVarBool(g_Cvar_AutoSlayBomb));
				case 3:
					SetConVarBool(g_Cvar_AutoSlayNotify, !GetConVarBool(g_Cvar_AutoSlayNotify));
			}
			ShowMenu(client, BO_Submenu_Config);
		}
		case MenuAction_Cancel:
		{
			// item gives us the reason why the menu was cancelled
			if(item == MenuCancel_ExitBack)
				RedisplayAdminMenu(hAdminMenu, client);
		}
		case MenuAction_End:
		{
			/* If the menu has ended, destroy it */
			CloseHandle(menu);
		}
	}
}

public MenuKillHandler(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (item)
			{
				case 0:
					ServerCommand("bot_kill");
				case 1:
					ServerCommand("bot_kill all t");
				case 2:
					ServerCommand("bot_kill all ct");
				case 3:
					ServerCommand("bot_kill t");
				case 4:
					ServerCommand("bot_kill ct");
			}
			//ShowMenu(client, BO_Submenu_Config);
		}
		case MenuAction_Cancel:
		{
			// item gives us the reason why the menu was cancelled
			if(item == MenuCancel_ExitBack)
			RedisplayAdminMenu(hAdminMenu, client);
		}
		case MenuAction_End:
		{
			/* If the menu has ended, destroy it */
			CloseHandle(menu);
		}
	}
}

public MenuKickHandler(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (item)
			{
				case 0:
					ServerCommand("bot_kick");
				case 1:
					ServerCommand("bot_kick all t");
				case 2:
					ServerCommand("bot_kick all ct");
				case 3:
					ServerCommand("bot_kick t");
				case 4:
					ServerCommand("bot_kick ct");
			}
			//ShowMenu(client, BO_Submenu_Config);
		}
		case MenuAction_Cancel:
		{
			// item gives us the reason why the menu was cancelled
			if(item == MenuCancel_ExitBack)
			RedisplayAdminMenu(hAdminMenu, client);
		}
		case MenuAction_End:
		{
			/* If the menu has ended, destroy it */
			CloseHandle(menu);
		}
	}
}

public MenuDifficultyHandler(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (item)
			{
				case 0:
					ServerCommand("bot_difficulty 0");
				case 1:
					ServerCommand("bot_difficulty 1");
				case 2:
					ServerCommand("bot_difficulty 2");
				case 3:
					ServerCommand("bot_difficulty 3");
			}
			PrintToConsole(client, "Bot difficulty is set to %i", item);
		}
		case MenuAction_Cancel:
		{
			// item gives us the reason why the menu was cancelled
			if(item == MenuCancel_ExitBack)
			RedisplayAdminMenu(hAdminMenu, client);
		}
		case MenuAction_End:
		{
			/* If the menu has ended, destroy it */
			CloseHandle(menu);
		}
	}
}

