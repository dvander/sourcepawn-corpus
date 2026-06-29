/************************************************************************
*************************************************************************
Simple Spectate
Description:
 		Spectate a player and follow them through death.
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: simple-spectate.sp 12 2009-09-27 05:24:04Z antithasys $
$Author: antithasys $
$Revision: 12 $
$Date: 2009-09-27 00:24:04 -0500 (Sun, 27 Sep 2009) $
$LastChangedBy: antithasys $
$LastChangedDate: 2009-09-27 00:24:04 -0500 (Sun, 27 Sep 2009) $
$URL: https://svn.simple-plugins.com/svn/simpleplugins/trunk/addons/sourcemod/scripting/simple-spectate.sp $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

/*	Changelog:
	1.2.2	-	Problem: 	sourcmod_fatal.log - SM] MEMORY LEAK DETECTED IN PLUGIN (file "simple-spectate.smx")
				Solution: 	Recompliled with with latest SM 1.5.2 gives 2 undefined symbol errors dhAddClientHook and DMG_FALL.
								Recompliled w/ SM 1.5.2 and most recent (but old) dukehacks.inc compiles but plugin has load error "[SM] Unable to load plugin "simple-spectate.smx": Native "dhAddClientHook" was not found"
								dhAddClientHook - eliminated the condition for this to load completely as deprecated dukehacks will never be installed anyway
								DMG_FALL - include sdkhooks for this dependancy on this constant instead of dukehacks
*/

#include <simple-plugins>
#include <sdkhooks>						//v1.2.2
#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#tryinclude <dukehacks>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.2.2"

#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 		5
#define SPECMODE_FREELOOK	 		6
#define SPECMODE_CSS_FIRSTPERSON 	3
#define SPECMODE_CSS_3RDPERSON 	4
#define SPECMODE_CSS_FREELOOK	 	5

enum e_CvarHandles
{
	Handle:hHudMode,
	Handle:hMenuType,
	Handle:hRestrictHud,
	Handle:hBan,
	Handle:hBanPerm,
	Handle:hBeacon,
	Handle:hBlind,
	Handle:hCheater,
	Handle:hDrug,
	Handle:hFreeze,
	Handle:hFreezeBomb,
	Handle:hKick,
	Handle:hSlap,
	Handle:hSlay,
	Handle:hTimeBomb
};

enum e_CvarSettings
{
	bool:bHudMode,
	bool:bMenuType,
	bool:bRestrictHud,
	bool:bBan,
	bool:bBanPerm,
	bool:bBeacon,
	bool:bBlind,
	bool:bCheater,
	bool:bDrug,
	bool:bFreeze,
	bool:bFreezebomb,
	bool:bKick,
	bool:bSlap,
	bool:bSlay,
	bool:bTimeBomb
};

enum e_PluginSettings
{
	bool:bUseSteamBans,
	bool:bUseSourceBans,
	bool:bUseMySQLBans,
	bool:bCanHUD,
	bool:bUseDukehacks
};

enum e_Menus
{
	Handle:hSelectPlayer,
	Handle:hBanTime,
	Handle:hReason
};

enum e_Punishments
{
	Punish_None,
	Punish_Ban,
	Punish_Beacon,
	Punish_Blind,
	Punish_Cheater,
	Punish_Drug,
	Punish_Freeze,
	Punish_FreezeBomb,
	Punish_Kick,
	Punish_Slap,
	Punish_Slay,
	Punish_TimeBomb
};

enum e_PlayerData
{
	bool:bIsDisplayingHud,
	bool:bIsFlaggedCheater,
	Handle:hHudTimer,
	Handle:hTargetTimer,
	iTargetIndex,
	e_Punishments:TargetPunishment,
	iBanTime
};

new Handle:sm_spectate_adminflag = INVALID_HANDLE;
new Handle:g_hAdminMenu = INVALID_HANDLE;
new Handle:g_hHud = INVALID_HANDLE;
new Handle:g_aPluginCvar[e_CvarHandles];
new g_aPluginCvarSettings[e_CvarSettings];
new g_aPluginSettings[e_PluginSettings];
new g_aMenus[e_Menus];
new g_aPlayers[MAXPLAYERS + 1][e_PlayerData];
new String:g_sAdminFlags[16];
new String:g_sPunishments[e_Punishments][15] = { "None", "Ban", "Beacon", "Blind", "Cheater", "Drug", "Freeze", "FreezeBomb", "Kick", "Slap", "Slay", "TimeBomb" };

public Plugin:myinfo =
{
	name = "Simple Spectate",
	author = "Simple Plugins",
	description = "Spectate a player and follow them through death.",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
};

/**
Sourcemod callbacks
*/
public OnPluginStart()
{
	
	/**
	Get game type and load the team numbers
	*/
	g_CurrentMod = GetCurrentMod();
	LoadCurrentTeams();
	
	/**
	Hook the game events
	*/
	LogAction(0, -1, "[SSPEC] Hooking events for [%s].", g_sGameName[g_CurrentMod]);
	HookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Pre);
	
	/**
	Need to create all of our console variables.
	*/
	CreateConVar("sm_spectate_version", PLUGIN_VERSION, "Sourcemod Spectate", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_aPluginCvar[hHudMode] = CreateConVar("sm_spectate_hudmode", "1", "Hud Mode: 0 = Hud Text | 1 = Panel/Menu (NOTE: The panel/menu will override other menus until canceled)");
	g_aPluginCvar[hMenuType] = CreateConVar("sm_spectate_menutype", "0", "Menu Mode: 0 = Panel | 1 = Menu");
	g_aPluginCvar[hRestrictHud] = CreateConVar("sm_spectate_restricthud", "0", "Restrict the hud to the admin flag provided");
	g_aPluginCvar[hBan] = CreateConVar("sm_spectate_ban", "1", "Enable/Disable ban option");
	g_aPluginCvar[hBanPerm] = CreateConVar("sm_spectate_banperm", "1", "Enable/Disable permanent ban option");
	g_aPluginCvar[hBeacon] = CreateConVar("sm_spectate_beacon", "1", "Enable/Disable beacon option");
	g_aPluginCvar[hBlind] = CreateConVar("sm_spectate_blind", "1", "Enable/Disable blind option");
	g_aPluginCvar[hCheater] = CreateConVar("sm_spectate_cheater", "1", "Enable/Disable cheater option");
	g_aPluginCvar[hDrug] = CreateConVar("sm_spectate_drug", "1", "Enable/Disable drug option");
	g_aPluginCvar[hFreeze] = CreateConVar("sm_spectate_freeze", "1", "Enable/Disable freeze option");
	g_aPluginCvar[hFreezeBomb] = CreateConVar("sm_spectate_freezebomb", "1", "Enable/Disable freezebomb option");
	g_aPluginCvar[hKick] = CreateConVar("sm_spectate_kick", "1", "Enable/Disable kick option");
	g_aPluginCvar[hSlap] = CreateConVar("sm_spectate_slap", "1", "Enable/Disable slap option");
	g_aPluginCvar[hSlay] = CreateConVar("sm_spectate_slay", "1", "Enable/Disable slay option");
	g_aPluginCvar[hTimeBomb] = CreateConVar("sm_spectate_timebomb", "1", "Enable/Disable timebomb option");
	
	sm_spectate_adminflag = CreateConVar("sm_spectate_adminflag", "d", "Admin Flag to use for admin hud");
	
	/**
	Hook console variables
	*/
	new e_CvarHandles:iCvar;
	for ( ; _:iCvar < sizeof(g_aPluginCvar); iCvar++)
	{
		HookConVarChange(g_aPluginCvar[iCvar], ConVarSettingsChanged);
	}
	
	/**
	Need to register the commands we are going to create and use.
	*/
	RegConsoleCmd("sm_spectate", Command_Spectate, "Spectate a player");
	RegConsoleCmd("sm_spec", Command_Spectate, "Spectate a player");
	RegConsoleCmd("sm_observe", Command_Spectate, "Spectate a player");
	RegConsoleCmd("sm_stopspec", Command_StopSpectate, "Stop Spectating a player");
	RegConsoleCmd("sm_endobserve", Command_StopSpectate, "Stop Spectating a player");
	RegConsoleCmd("sm_specinfo", Command_ToggleHud, "Toggles the hud display if in spectator");
	
	/**
	Now we have to deal with the admin menu.  If the admin library is loaded call the function to add our items.
	*/
	new Handle:gTopMenu;
	if (LibraryExists("adminmenu") && ((gTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(gTopMenu);
	}
	
	/**
	Deal with the hud
	Thanks to Spray Trace plugin (http://forums.alliedmods.net/showthread.php?p=665448)
	*/
	new String:sHudGames[32];
	GetGameFolderName(sHudGames, sizeof(sHudGames));
	g_aPluginSettings[bCanHUD] = StrEqual(sHudGames,"tf",false) 
	|| StrEqual(sHudGames,"hl2mp",false) 
	|| StrEqual(sHudGames,"sourceforts",false) 
	|| StrEqual(sHudGames,"obsidian",false) 
	|| StrEqual(sHudGames,"left4dead",false) 
	|| StrEqual(sHudGames,"l4d",false);
	
	if (g_aPluginSettings[bCanHUD])
	{
		g_hHud = CreateHudSynchronizer();
	}
	
	/**
	Load translations
	*/
	LoadTranslations ("common.phrases");
	LoadTranslations ("simplespectate.phrases");
	
	/**
	Create the config file
	*/
	AutoExecConfig(true);
}

public OnConfigsExecuted()
{
	new e_CvarHandles:iCvar;
	for ( ; _:iCvar < sizeof(g_aPluginCvarSettings); iCvar++)
	{
		g_aPluginCvarSettings[iCvar] = GetConVarBool(g_aPluginCvar[iCvar]);
	}
	
	/*
	Build the global menus
	*/
	g_aMenus[hSelectPlayer] = BuildSelectPlayerMenu();
	g_aMenus[hBanTime] = BuildBanTimeMenu();
	g_aMenus[hReason] = BuildReasonMenu();
	
	GetConVarString(sm_spectate_adminflag, g_sAdminFlags, sizeof(g_sAdminFlags));
}

public OnAllPluginsLoaded()
{

	/*
	Check for steambans
	*/
	if (FindConVar("sbsrc_version") != INVALID_HANDLE)
	{
		g_aPluginSettings[bUseSteamBans] = true;
	}
	else
	{
		g_aPluginSettings[bUseSteamBans] = false;
	}
	
	/*
	Check for sourcebans
	*/
	if (FindConVar("sb_version") != INVALID_HANDLE)
	{
		g_aPluginSettings[bUseSourceBans] = true;
	}
	else
	{
		g_aPluginSettings[bUseSourceBans] = false;
	}
	
	/*
	Check for mysql bans
	*/
	if (FindConVar("mysql_bans_version") != INVALID_HANDLE)
	{
		g_aPluginSettings[bUseMySQLBans] = true;
	}
	else
	{
		g_aPluginSettings[bUseMySQLBans] = false;
	}
	
	/*
	Deal with some known plugin conflicts
	*/
	new Handle:hObserveClient = FindConVar("observe_version");
	if (hObserveClient != INVALID_HANDLE)
	{
		new String:sNewFile[PLATFORM_MAX_PATH + 1], String:sOldFile[PLATFORM_MAX_PATH + 1];
		BuildPath(Path_SM, sNewFile, sizeof(sNewFile), "plugins/disabled/observe.smx");
		BuildPath(Path_SM, sOldFile, sizeof(sOldFile), "plugins/observe.smx");
	
		/**
		Check if plugins/observe.smx exists, and if not, ignore
		*/
		if(!FileExists(sOldFile))
		{
			return;
		}
	
		/** 
		Check if plugins/disabled/observe.smx already exists, and if so, delete it
		*/
		if(FileExists(sNewFile))
		{
			DeleteFile(sNewFile);
		}
	
		/**
		Unload plugins/observe.smx and move it to plugins/disabled/observe.smx
		*/
		LogAction(0, -1, "Detected the plugin ObserveClient");
		LogAction(0, -1, "ObserveClient plugin conflicts with Simple Spectate");
		LogAction(0, -1, "Unloading plugin and disabling ObserveClient plugin");
		ServerCommand("sm plugins unload observe");
		RenameFile(sNewFile, sOldFile);
	}
	
	/*
	Check for dukehacks
	*/
	new String:sExtError[256];
	new iExtStatus = GetExtensionFileStatus("dukehacks.ext", sExtError, sizeof(sExtError));
	if (iExtStatus == -2)
	{
		LogAction(0, -1, "[SSPEC] Dukehacks extension was not found.");
		LogAction(0, -1, "[SSPEC] Plugin continued to load, but that feature will not be used.");
		g_aPluginSettings[bUseDukehacks] = false;
	}
	else if (iExtStatus == -1 || iExtStatus == 0)
	{
		LogAction(0, -1, "[SSPEC] Dukehacks extension is loaded with errors.");
		LogAction(0, -1, "[SSPEC] Status reported was [%s].", sExtError);
		LogAction(0, -1, "[SSPEC] Plugin continued to load, but that feature will not be used.");
		g_aPluginSettings[bUseDukehacks] = false;
	}
	/* BOT - Since the extension will never load lets just get rid of the test all together to get rid of the problem with dhAddClientHook
	else if (iExtStatus == 1)
	{
		LogAction(0, -1, "[SSPEC] Dukehacks extension is loaded and will be used.");
		g_aPluginSettings[bUseDukehacks] = true;
		dhAddClientHook(CHK_TakeDamage, Hacks_TakeDamageHook);
	}
	*/
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
	
		/**
		Looks like the admin menu was removed.  Set the global.
		*/
		g_hAdminMenu = INVALID_HANDLE;
	}
	else if (StrEqual(name, "simpleplugins"))
	{
		//something
	}
}

public OnClientDisconnect(client)
{

	/**
	Cleanup the clients variables.
	*/
	ResetClient(client);
	
	/**
	Run a loop and see if we are supposed to spectate this person (is a target)
	*/
	for(new i = 1; i <= MaxClients; i++) 
	{
		if (g_aPlayers[i][iTargetIndex] == client) 
		{
			
			/**
			Cleanup the clients variables.
			*/
			StopFollowingPlayer(i);
			g_aPlayers[i][TargetPunishment] = Punish_None;
			g_aPlayers[i][iBanTime] = 0;
		}
	}
}

/**
Thirdparty callbacks
*/
public SM_OnPlayerMoved(Handle:plugin, client, team)
{

	/**
	Make sure we called the move function
	*/
	if (plugin != GetMyHandle())
	{
		return;
	}
	
	//Nothing
}

public Action:Hacks_TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype)
{
	
	/**
	Check for a valid client
	*/
	if (client > 0 && client <= MaxClients)
	{
		
		/**
		Check if the client taking damage is flagged as a cheater
		*/
		if (g_aPlayers[client][bIsFlaggedCheater])
		{
	
			/**
			Check for fall damage and increase it
			*/
			if (damagetype & DMG_FALL)
			{
				multiplier *= 1000.0;
				return Plugin_Changed;
			}
		}
	}
	
	/**
	Check for a valid attacker
	*/
	if (attacker > 0 && attacker <= MaxClients)
	{
	
		/**
		Check if the attacker causing the damage is flagged as a cheater
		*/
		if (g_aPlayers[attacker][bIsFlaggedCheater])
		{
		
			/**
			Make sure they are not hurting themselves
			*/
			if (client != attacker) 
			{
		
				/**
				Stop the damage
				*/
				multiplier *= 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

/**
Events
*/
public Action:HookPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{

	/**
	Get the client and team
	*/
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetEventInt(event, "team");
	
	/**
	Make sure it's a valid client
	*/
	if (iClient == 0)
	{
		return Plugin_Continue;
	}
	
	/**
	If it's a move to spectator start displaying the hud
	*/
	else if (iTeam == g_aCurrentTeams[Spectator])
	{
		StartDisplayingHud(iClient);
		return Plugin_Continue;
	}
	
	/**
	Otherwise cleanup the client
	*/
	else
	{
		StopDisplayingHud(iClient);
		StopFollowingPlayer(iClient);
	}
	
	/**
	We are done, bug out.
	*/
	return Plugin_Continue;
}

/**
Commands
*/
public Action:Command_Spectate(client, args)
{

	/**
	See if we already have a target (for toggling of command)
	*/
	if (g_aPlayers[client][iTargetIndex])
	{
		
		/**
		We do, toggle it off
		*/
		StopFollowingPlayer(client);
		
		/**
		We are done, bug out.
		*/
		return Plugin_Handled;
	}
	
	/**
	We don't... must want to enable it
	See if we have some command arguments.
	*/
	new iCmdArgs = GetCmdArgs();
	if (iCmdArgs == 0) 
	{
		
		/**
		We don't have any.  Display the player menu.
		*/
		if (g_aPlayers[client][bIsDisplayingHud])
		{
			StopDisplayingHud(client);
		}
		
		DisplayMenu(BuildPlayerListMenu(), client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	
	/**
	We have an argument.
	Try to find the target.
	*/
	new String:sPlayer[128];
	GetCmdArg(1, sPlayer, sizeof(sPlayer));
	new iTarget = FindTarget(client, sPlayer, true, true);
	if (iTarget == -1 || !IsClientInGame(iTarget))
	{
	
		/**
		We couldn't find the target.  Display the player menu.
		*/
		if (g_aPlayers[client][bIsDisplayingHud])
		{
			StopDisplayingHud(client);
		}
		
		DisplayMenu(BuildPlayerListMenu(), client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	
	/**
	We found the target.
	Call the stock function to spectate the target.
	*/
	StartFollowingPlayer(client, iTarget);
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Command_StopSpectate(client, args)
{

	/**
	Cleanup the clients variables.
	*/
	StopFollowingPlayer(client);
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Command_ToggleHud(client, args)
{

	/**
	Toggle the hud
	*/
	if (g_aPlayers[client][bIsDisplayingHud])
	{
		StopDisplayingHud(client);
	}
	else
	{
		StartDisplayingHud(client);
	}
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

/**
Timers
*/
public Action:Timer_ResetTarget(Handle:timer, any:client)
{

	new iTargetID = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	if (iTargetID != g_aPlayers[client][iTargetIndex] && IsPlayerAlive(g_aPlayers[client][iTargetIndex]))
	{
	
		/**
		Run the command to spectate the target from the clients prospectative.
		*/
		FakeClientCommandEx(client, "spec_player \"%N\"", g_aPlayers[client][iTargetIndex]);
	}

	/**
	We are done, bug out.
	*/
	return Plugin_Continue;
}

public Action:Timer_UpdateHud(Handle:timer, any:client)
{
	
	/**
	Make sure the client is still in game and a spectator
	*/
	if (!IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) != g_aCurrentTeams[Spectator] || !g_aPlayers[client][bIsDisplayingHud])
	{
		
		/**
		We are done, bug out
		*/
		g_aPlayers[client][hHudTimer] = INVALID_HANDLE;
		g_aPlayers[client][bIsDisplayingHud] = false;
		return Plugin_Stop;
	}
	/**
	Get the target
	*/
	new iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	/**
	Check to make sure the target is valid
	*/
	if (iTarget <= 0 || iTarget > MaxClients)
	{
		return Plugin_Continue;
	}
	
	/**
	Get the spectator mode
	*/
	new iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	
	/**
	This is a double check to make sure we are in spec
	If we are on a regular team, specmod would = none or zero
	*/
	if (iSpecMode == SPECMODE_NONE)
	{
		
		/**
		We are done, bug out
		*/
		g_aPlayers[client][hHudTimer] = INVALID_HANDLE;
		g_aPlayers[client][bIsDisplayingHud] = false;
		return Plugin_Stop;
	}
	
	/**
	Check the spectator mode
	CSS has different index's so we have to check game type first
	*/
	if (g_CurrentMod == GameType_CSS)
	{
		switch (iSpecMode)
		{
			case SPECMODE_CSS_FIRSTPERSON:
			{
				//Do Nothing
			}
			case SPECMODE_CSS_3RDPERSON:
			{
				//Do Nothing
			}
			case SPECMODE_CSS_FREELOOK:
			{
				return Plugin_Continue;
			}
		}
	}
	else
	{
		switch (iSpecMode)
		{
			case SPECMODE_FIRSTPERSON:
			{
				//Do Nothing
			}
			case SPECMODE_3RDPERSON:
			{
				//Do Nothing
			}
			case SPECMODE_FREELOOK:
			{
				return Plugin_Continue;
			}
		}
	}
	
	
	/**
	Display with the hud
	*/
	if (g_aPluginSettings[bCanHUD] && !g_aPluginCvarSettings[bHudMode])
	{
		new String:sSteamID[64];
		GetClientAuthString(iTarget, sSteamID, sizeof(sSteamID));
		SetHudTextParams(0.04, 0.6, 0.5, 255, 50, 50, 255);
		ShowSyncHudText(client, g_hHud, "%N [%s]", iTarget, sSteamID);
	}
	else if (g_aPluginCvarSettings[bHudMode])
	{
		if (g_aPluginCvarSettings[bMenuType])
		{
			DisplayMenu(BuildPlayerHudMenu(client, iTarget), client, 1);
		}
		else
		{
			new Handle:hPanel = BuildPlayerHudPanel(client, iTarget);
			SendPanelToClient(hPanel, client, Panel_PlayerHud, 1);
			CloseHandle(hPanel);
		}
	}

	/**
	We are done, keep going!
	*/
	return Plugin_Continue;
}

/**
Admin Menu Callbacks
*/
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hAdminMenu)
	{
		return;
	}
	g_hAdminMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
 	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	AddToTopMenu(g_hAdminMenu, 
		"sm_spectate",
		TopMenuObject_Item,
		AdminMenu_SpecPlayer,
		player_commands,
		"sm_spectate",
		ADMFLAG_GENERIC);
}
 
public AdminMenu_SpecPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		
		if (g_aPlayers[param][bIsDisplayingHud])
		{
			StopDisplayingHud(param);
		}
		/**
		See if we already have a target
		*/
		if (g_aPlayers[param][iTargetIndex])
		{
			Format(buffer, maxlength, "Spectate(Disable)");
		}
		else
		{
			Format(buffer, maxlength, "Spectate(Select Player)");
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		
		/**
		See if we already have a target
		*/
		if (g_aPlayers[param][iTargetIndex])
		{
		
			/**
			We do, toggle it off
			*/
			StopFollowingPlayer(param);
		
			/**
			We are done, bug out.
			*/
			return;
		}
		else
		{
			DisplayMenu(BuildPlayerListMenu(), param, MENU_TIME_FOREVER);
		}
	}
}

/**
Select Player Menu Callbacks
*/
public Menu_PlayerList(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		/**
		Get the selected player
		*/
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		new iTarget = GetClientOfUserId(StringToInt(sSelection));
		
		/**
		Start following the player
		*/
		StartFollowingPlayer(param1, iTarget);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_GENERIC)
		{
			
			/**
			Display the last admin menu
			*/
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
		else if (param2 == MenuCancel_Exit && GetClientTeam(param1) == g_aCurrentTeams[Spectator])
		{
			/**
			They canceled the current menu, start the hud back up
			*/
			StartDisplayingHud(param1);
		}
	} 
	else if (action == MenuAction_End)
	{
		
		/**
		Not a global menu, close it
		*/
		CloseHandle(menu);
	}
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		
		/**
		Get the selected player
		*/
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (strcmp(sSelection, "Current", false) == 0)
		{
			/**
			Get the current target
			*/
			new iTarget = GetEntPropEnt(param1, Prop_Send, "m_hObserverTarget");
			
			/**
			Check to make sure the target is valid
			*/
			if (iTarget <= 0 || iTarget > MaxClients)
			{
				PrintToChat(param1, "\x03[SM-SPEC]\x01 %t", "Invalid Target");
				DisplayMenu(BuildPlayerListMenu(), param1, MENU_TIME_FOREVER);
			}
			
			/**
			Start following the player
			*/
			StartFollowingPlayer(param1, iTarget);
		}
		else
		{
			
			/**
			They want to select a player, show the player list
			*/
			DisplayMenu(BuildPlayerListMenu(), param1, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			
			/**
			They canceled the current menu, start the hud back up
			*/
			StartDisplayingHud(param1);
		}
	} 
	else if (action == MenuAction_End)
	{
		/**
		Its a global menu, leave it alive
		*/
	}
}

/**
Punishment Menu Callbacks
*/
public Menu_Punishments(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		
		/**
		Get the menu selection
		*/
		new String:sSelection[15];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		
		/**
		Search for the correct index
		*/
		new e_Punishments:Index = Punish_None;
		for ( ; _:Index <= sizeof(g_sPunishments); Index++)
		{
			if (StrEqual(sSelection, g_sPunishments[Index]))
			{
				break;
			}
		}
		
		/**
		Display the next menu
		*/
		if (Index == Punish_Ban)
		{
			
			/**
			Set the punishment index and display ban time menu
			*/
			g_aPlayers[param1][TargetPunishment] = Index;
			DisplayMenu(g_aMenus[hBanTime], param1, MENU_TIME_FOREVER);
		}
		else if (Index == Punish_Cheater)
		{
			
			/**
			Ask for confirmation before we set punishment index
			*/
			new Handle:hPanel = BuildAdminCheaterPanel();
			SendPanelToClient(hPanel, param1, Panel_AdminCheater, MENU_TIME_FOREVER);
			CloseHandle(hPanel);
		}
		else
		{
			
			/**
			Set the punishment index and display reason menu
			*/
			g_aPlayers[param1][TargetPunishment] = Index;
			DisplayMenu(g_aMenus[hReason], param1, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel) 
	{

		/**
		They canceled the current menu, start the hud back up
		*/
		StartDisplayingHud(param1);
	} 
	else if (action == MenuAction_End)
	{
		
		/**
		Not a global menu, close it
		*/
		CloseHandle(menu);
	}
}

public Menu_BanTime(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
	
		/**
		Get the menu selection
		*/
		new String:sSelection[15];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		
		/**
		Set the ban time global
		*/
		g_aPlayers[param1][iBanTime] = StringToInt(sSelection);
		
		/**
		Display the reason menu
		*/
		DisplayMenu(g_aMenus[hReason], param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			
			/**
			They canceled the current menu, start the hud back up
			*/
			StartDisplayingHud(param1);
		}
	} 
	else if (action == MenuAction_End)
	{
		/**
		Its a global menu, leave it alive
		*/
	}
}

public Menu_Reason(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		
		/**
		Get the menu selection
		*/
		new String:sSelection[15];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		
		/**
		Perform the punishment
		*/
		PerformPunishment(param1, g_aPlayers[param1][iTargetIndex], g_aPlayers[param1][TargetPunishment], sSelection, g_aPlayers[param1][iBanTime]);
		
		/**
		Reactivate the hud if still in spectator
		*/
		if (GetClientTeam(param1) == g_aCurrentTeams[Spectator])
		{
			StartDisplayingHud(param1);
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			
			/**
			They canceled the current menu, start the hud back up
			*/
			StartDisplayingHud(param1);
		}
	} 
	else if (action == MenuAction_End)
	{
		/**
		Its a global menu, leave it alive
		*/
	}
}

public Panel_AdminCheater(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			
			/**
			Set the punishment index and display reason menu
			*/
			g_aPlayers[param1][TargetPunishment] = Punish_Cheater;
			DisplayMenu(g_aMenus[hReason], param1, MENU_TIME_FOREVER);
		}
		else
		{
			
			/**
			Reactivate the hud if still in spectator
			*/
			if (GetClientTeam(param1) == g_aCurrentTeams[Spectator])
			{
				StartDisplayingHud(param1);
			}
		}
	}
}

public Panel_PublicCheater(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			//Waiting for SB 2.0 and sb_submission to be published
		}
		else
		{
		
			/**
			Reactivate the hud if still in spectator
			*/
			if (GetClientTeam(param1) == g_aCurrentTeams[Spectator])
			{
				StartDisplayingHud(param1);
			}
		}
	}
}

/**
Hud Menu/Panel Callbacks
*/
public Menu_PlayerHud(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "stop", false))
		{
			StopFollowingPlayer(param1);
		}
		else if (StrEqual(sSelection, "start", false))
		{
			StopDisplayingHud(param1);
			DisplayMenu(g_aMenus[hSelectPlayer], param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(sSelection, "removecheater", false))
		{
			g_aPlayers[g_aPlayers[param1][iTargetIndex]][bIsFlaggedCheater] = false;
		}
		else if (StrEqual(sSelection, "punish", false))
		{
			if (g_aPlayers[param1][iTargetIndex])
			{
				StopDisplayingHud(param1);
				DisplayMenu(BuildPunishmentMenu(param1), param1, MENU_TIME_FOREVER);
			}
			else
			{
				StopDisplayingHud(param1);
				PrintToChat(param1, "\x03[SM-SPEC]\x01 %t", "Must Have Target");
				DisplayMenu(g_aMenus[hSelectPlayer], param1, MENU_TIME_FOREVER);
			}
		}
		else if (StrEqual(sSelection, "reportcheater", false))
		{
			if (g_aPlayers[param1][iTargetIndex])
			{
				StopDisplayingHud(param1);
				new Handle:hPanel = BuildPublicCheaterPanel();
				SendPanelToClient(hPanel, param1, Panel_PublicCheater, MENU_TIME_FOREVER);
				CloseHandle(hPanel);
			}
			else
			{
				StopDisplayingHud(param1);
				PrintToChat(param1, "\x03[SM-SPEC]\x01 %t", "Must Have Target");
				DisplayMenu(g_aMenus[hSelectPlayer], param1, MENU_TIME_FOREVER);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Interrupted)
		{
			if (GetClientMenu(param1) == MenuSource_External)
			{
				StopDisplayingHud(param1);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Panel_PlayerHud(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				if (g_aPlayers[param1][iTargetIndex])
				{
					StopFollowingPlayer(param1);
				}
				else
				{
					StopDisplayingHud(param1);
					DisplayMenu(BuildSelectPlayerMenu(), param1, MENU_TIME_FOREVER);
				}
			}
			case 2:
			{
				if (!g_aPlayers[param1][iTargetIndex])
				{
					StopDisplayingHud(param1);
					PrintToChat(param1, "\x03[SM-SPEC]\x01 %t", "Must Have Target");
					DisplayMenu(g_aMenus[hSelectPlayer], param1, MENU_TIME_FOREVER);
					return;
				}
				
				if ((GetUserFlagBits(param1) & ADMFLAG_GENERIC) || (GetUserFlagBits(param1) & ADMFLAG_ROOT))
				{
					if (g_aPlayers[g_aPlayers[param1][iTargetIndex]][bIsFlaggedCheater] && (GetUserFlagBits(param1) & ADMFLAG_ROOT))
					{
						//Remove cheater flag
						g_aPlayers[g_aPlayers[param1][iTargetIndex]][bIsFlaggedCheater] = false;
					}
					else
					{
						//Punish menu
						StopDisplayingHud(param1);
						DisplayMenu(BuildPunishmentMenu(param1), param1, MENU_TIME_FOREVER);
					}
				}
				else
				{
					//Report Cheater
					new Handle:hPanel = BuildPublicCheaterPanel();
					SendPanelToClient(hPanel, param1, Panel_PublicCheater, MENU_TIME_FOREVER);
					CloseHandle(hPanel);
				}
			}
			case 3:
			{
				StopDisplayingHud(param1);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Interrupted)
		{
			if (GetClientMenu(param1) == MenuSource_External)
			{
				StopDisplayingHud(param1);
			}
		}
	}
}


/**
Stock functions
*/
stock StartFollowingPlayer(client, target)
{
	
	/**
	If we have an open timer, close it.
	*/
	if (g_aPlayers[client][hTargetTimer] != INVALID_HANDLE)
	{
		CloseHandle(g_aPlayers[client][hTargetTimer]);
		g_aPlayers[client][hTargetTimer] = INVALID_HANDLE;
	}

	/**
	Make sure the target is on a non spectator team, and the client != target
	*/
	if (client == target)
	{
		PrintToChat(client, "\x03[SM-SPEC]\x01 %t", "Yourself");
		return;
	}
	new iTargetTeam = GetClientTeam(target);
	if (iTargetTeam == g_aCurrentTeams[Spectator] || iTargetTeam == g_aCurrentTeams[Unknown])
	{
		PrintToChat(client, "\x03[SM-SPEC]\x01 %t", "Spectator");
		return;
	}
	
	/**
	Check to see if client is already a spectator
	*/
	if (GetClientTeam(client) != g_aCurrentTeams[Spectator]) 
	{

		/**
		Client is not a spectator, lets move them to spec.
		*/
		SM_MovePlayer(client, g_aCurrentTeams[Spectator]);
	}
	
	/**
	If we are using steambans call sb_status
	*/
	if (g_aPluginSettings[bUseSteamBans])
	{
		FakeClientCommandEx(client, "sb_status");
	}
	
	
	/**
	Set the global and start to spectate the target.
	Making sure it's long enough to deal with moving the client to spec if we had to.
	*/
	new String:sTargetName[MAX_NAME_LENGTH + 1];
	GetClientName(target, sTargetName, sizeof(sTargetName));
	g_aPlayers[client][iTargetIndex] = target;
	PrintToChat(client, "\x03[SM-SPEC]\x01 %t", "Spectating", sTargetName);
	g_aPlayers[client][hTargetTimer] = CreateTimer(0.5, Timer_ResetTarget, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (!g_aPlayers[client][bIsDisplayingHud] && GetClientTeam(client) == g_aCurrentTeams[Spectator])
	{
		StartDisplayingHud(client);
	}
}

stock StopFollowingPlayer(client)
{

	/**
	If we have an open timer, close it.
	*/
	if (g_aPlayers[client][hTargetTimer] != INVALID_HANDLE)
	{
		CloseHandle(g_aPlayers[client][hTargetTimer]);
	}

	/**
	Tell the client we can't spec his target anymore... if they are in game.
	*/
	if (IsClientInGame(client) && g_aPlayers[client][iTargetIndex] != 0)
	{
		new String:sTargetName[MAX_NAME_LENGTH + 1];
		GetClientName(g_aPlayers[client][iTargetIndex], sTargetName, sizeof(sTargetName));
		if (!IsClientConnected(g_aPlayers[client][iTargetIndex]) || !IsClientInGame(g_aPlayers[client][iTargetIndex]))
		{
			PrintToChat(client, "\x03[SM-SPEC]\x01 %t", "Target Left");
		}
		else
		{
			PrintToChat(client, "\x03[SM-SPEC]\x01 %t", "Stopped spectating", sTargetName);
		}
	}
	
	/**
	Null the globals.
	*/
	g_aPlayers[client][iTargetIndex] = 0;
	g_aPlayers[client][hTargetTimer] = INVALID_HANDLE;
}

stock StartDisplayingHud(client)
{
	if (g_aPluginCvarSettings[bRestrictHud] && !SM_IsValidAdmin(client, g_sAdminFlags))
	{		
		return;
	}
	else
	{
		/**
		Double check the hud timer
		We should not have one, but if we do, lets cancel it for the current callback
		*/
		StopDisplayingHud(client);
		
		/**
		Now we can safely display the hud and make sure the current stored handle is the current timer
		*/
		g_aPlayers[client][bIsDisplayingHud] = true;
		g_aPlayers[client][hHudTimer] = CreateTimer(0.5, Timer_UpdateHud, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock StopDisplayingHud(client)
{
	if (g_aPlayers[client][hHudTimer] != INVALID_HANDLE)
	{
		CloseHandle(g_aPlayers[client][hHudTimer]);
	}
	g_aPlayers[client][hHudTimer] = INVALID_HANDLE;
	g_aPlayers[client][bIsDisplayingHud] = false;
}

stock ResetClient(client)
{
	StopFollowingPlayer(client);
	StopDisplayingHud(client);
	
	g_aPlayers[client][bIsFlaggedCheater] = false;
	g_aPlayers[client][TargetPunishment] = Punish_None;
	g_aPlayers[client][iBanTime] = -1;
}

stock PerformPunishment(client, target, e_Punishments:punishment, const String:reason[], time = 300)
{
	new	String:sTargetName[MAX_NAME_LENGTH + 1],
		String:sTargetID[64];
		
	/**
	The target could have left the game by the time we get here
	Check for a valid target
	*/
	if (!IsClientConnected(target) || !IsClientInGame(target))
	{
		PrintToChat(client, "\x03[SM-SPEC]\x01 %t", "Target Left");
		return;
	}
	
	GetClientName(target, sTargetName, sizeof(sTargetName));
	GetClientAuthString(target, sTargetID, sizeof(sTargetID));
	
	switch (punishment)
	{
		case Punish_Kick:
		{
			KickClient(g_aPlayers[client][iTargetIndex], "%s", reason);
		}
		case Punish_Ban:
		{
			if (g_aPluginSettings[bUseSourceBans])
			{
				ClientCommand(client, "sm_ban #%d %d \"%s\"", GetClientUserId(target), time, reason);
			}
			else if (g_aPluginSettings[bUseMySQLBans])
			{
				ClientCommand(client, "mysql_ban #%d %d \"%s\"", GetClientUserId(target), time, reason);
			}
			else
			{
				BanClient(target, time, BANFLAG_AUTHID, reason, reason);
			}
		}
		case Punish_Cheater:
		{
			g_aPlayers[target][bIsFlaggedCheater] = true;
		}
		case Punish_Beacon:
		{
			ClientCommand(client, "sm_beacon \"%s\"", sTargetName);
		}
		case Punish_Blind:
		{
			ClientCommand(client, "sm_blind \"%s\"", sTargetName);
		}
		case Punish_Drug:
		{
			ClientCommand(client, "sm_drug \"%s\"", sTargetName);
		}
		case Punish_Freeze:
		{
			ClientCommand(client, "sm_freeze \"%s\"", sTargetName);
		}
		case Punish_FreezeBomb:
		{
			ClientCommand(client, "sm_freezebomb \"%s\"", sTargetName);
		}
		case Punish_Slap:
		{
			ClientCommand(client, "sm_slap \"%s\" 10", sTargetName);
		}
		case Punish_Slay:
		{
			ClientCommand(client, "sm_slay \"%s\"", sTargetName);
		}
		case Punish_TimeBomb:
		{
			ClientCommand(client, "sm_timebomb \"%s\"", sTargetName);
		}
	}
	
	if (punishment == Punish_Cheater)
	{
		LogAction(client, target, "[SM SPEC] %N marked %N(%s) with a %s flag for %s", client, target, sTargetID, g_sPunishments[punishment], reason);
	}
	else
	{
		ShowActivity(client, "%t", "Punished", sTargetName, g_sPunishments[punishment], reason);
		LogAction(client, target, "[SM SPEC] %N punished %N(%s) with a %s for %s", client, target, sTargetID, g_sPunishments[punishment], reason);
	}
	
	/**
	Null the globals.
	*/
	g_aPlayers[client][TargetPunishment] = Punish_None;
	g_aPlayers[client][iBanTime] = -1;
}

/**
Build the menu of player names
*/
stock Handle:BuildPlayerListMenu()
{
	new Handle:hMenu = CreateMenu(Menu_PlayerList);
	AddTargetsToMenu(hMenu, 0, true, false);
	SetMenuTitle(hMenu, "Select A Player:");
	SetMenuExitBackButton(hMenu, true);
	return hMenu;
}

/**
Build the select player menu (current or list of players)
*/
stock Handle:BuildSelectPlayerMenu()
{
	new Handle:hMenu = CreateMenu(Menu_SelectPlayer);
	SetMenuTitle(hMenu, "Select A Player:");
	AddMenuItem(hMenu, "Current", "Current Target");
	AddMenuItem(hMenu, "List", "Player List");
	SetMenuExitBackButton(hMenu, true);
	return hMenu;
}

/**
Build the punishmenu menu
*/
stock Handle:BuildPunishmentMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_Punishments);
	SetMenuTitle(hMenu, "Select A Punishment:");
	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
		
	if (g_aPluginCvarSettings[bKick] && ((GetUserFlagBits(iClient) & ADMFLAG_GENERIC) || (GetUserFlagBits(iClient) & ADMFLAG_ROOT)))
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Kick], "Kick");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Kick], "Kick", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bBan] && ((GetUserFlagBits(iClient) & ADMFLAG_GENERIC) || (GetUserFlagBits(iClient) & ADMFLAG_ROOT)))
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Ban], "Ban");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Ban], "Ban", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginSettings[bUseDukehacks] && g_aPluginCvarSettings[bCheater] && (GetUserFlagBits(iClient) & ADMFLAG_ROOT))
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Cheater], "Flag As Cheater");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Cheater], "Flag As Cheater", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bBeacon])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Beacon], "Beacon");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Beacon], "Beacon", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bBlind])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Blind], "Blind");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Blind], "Blind", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bDrug])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Drug], "Drug");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Drug], "Drug", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bFreeze])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Freeze], "Freeze");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Freeze], "Freeze", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bFreezebomb])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_FreezeBomb], "Freeze Bomb");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_FreezeBomb], "Freeze Bomb", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bSlap])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Slap], "Slap");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Slap], "Slap", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bSlay])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Slay], "Slay");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_Slay], "Slay", ITEMDRAW_DISABLED);
	}
	
	if (g_aPluginCvarSettings[bTimeBomb])
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_TimeBomb], "Time Bomb");
	}
	else
	{
		AddMenuItem(hMenu, g_sPunishments[Punish_TimeBomb], "Time Bomb", ITEMDRAW_DISABLED);
	}
	
	return hMenu;
}

/**
Build the punishmenu menu
*/
stock Handle:BuildBanTimeMenu()
{
	new Handle:hMenu = CreateMenu(Menu_BanTime);
	SetMenuTitle(hMenu, "Select Ban Type:");
	
	if (g_aPluginCvarSettings[bBanPerm])
	{
		AddMenuItem(hMenu, "permban", "Permanent");
	}
	else
	{
		AddMenuItem(hMenu, "permban", "Permanent", ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(hMenu, "10", "10 Minutes");
	AddMenuItem(hMenu, "30", "30 Minutes");
	AddMenuItem(hMenu, "60", "1 Hour");
	AddMenuItem(hMenu, "240", "4 Hours");
	AddMenuItem(hMenu, "1440", "1 Day");
	AddMenuItem(hMenu, "10080", "1 Week");
	
	SetMenuExitBackButton(hMenu, true);
	return hMenu;
}

/**
Build the punishmenu menu
*/
stock Handle:BuildReasonMenu()
{
	new Handle:hMenu = CreateMenu(Menu_Reason);
	SetMenuTitle(hMenu, "Select A Reason:");

	AddMenuItem(hMenu, "Abusive", "Abusive");
	AddMenuItem(hMenu, "Racism", "Racism");
	AddMenuItem(hMenu, "General cheating/exploits", "General cheating/exploits");
	AddMenuItem(hMenu, "Wallhack", "Wallhack");
	AddMenuItem(hMenu, "Aimbot", "Aimbot");
	AddMenuItem(hMenu, "Speedhacking", "Speedhacking");
	AddMenuItem(hMenu, "Mic spamming", "Mic spamming");
	AddMenuItem(hMenu, "Admin disrepect", "Admin disrepect");
	AddMenuItem(hMenu, "Camping", "Camping");
	AddMenuItem(hMenu, "Team killing", "Team killing");
	AddMenuItem(hMenu, "Unacceptable Spray", "Unacceptable Spray");
	AddMenuItem(hMenu, "Breaking Server Rules", "Breaking Server Rules");
	AddMenuItem(hMenu, "Other", "Other");
	
	SetMenuExitBackButton(hMenu, true);
	return hMenu;
}

/**
Build the cheater displays
*/
stock Handle:BuildAdminCheaterPanel()
{
	
	/**
	 Create the menu and set the menu options.
	*/
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Simple Spectator:");
	
	DrawPanelText(hPanel, "Are you sure you want to");
	DrawPanelText(hPanel, "flag this player as a cheater?");
	DrawPanelText(hPanel, "They will not be able to damage");
	DrawPanelText(hPanel, "anyone and die on fall damage.");
	DrawPanelItem(hPanel, "Yes");
	DrawPanelItem(hPanel, "No");
	
	return hPanel;
}

stock Handle:BuildPublicCheaterPanel()
{

	/**
	 Create the menu and set the menu options.
	*/
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Simple Spectator:");
	
	DrawPanelText(hPanel, "Are you sure you want to");
	DrawPanelText(hPanel, "submit this player as a cheater?");
	DrawPanelItem(hPanel, "Yes (Not Implemented Yet)", ITEMDRAW_DISABLED);
	DrawPanelItem(hPanel, "No");
	return hPanel;
}

/**
Build the hud displays
*/
stock Handle:BuildPlayerHudMenu(iClient, iTarget)
{
	
	/**
	 Create all the string variables we will need
	*/
	new	String:sTargetName[MAX_NAME_LENGTH + 1],
		String:sTargetID[64],
		String:sTargetIP[16];
		
	new	String:sDisplayName[MAX_NAME_LENGTH + 1],
		String:sDisplayID[64],
		String:sDisplayIP[64],
		String:sDisplayFrags[16],
		String:sDisplayDeaths[16];

	new	iTargetFrags,
		iTargetDeaths;
	
	/**
	 Get the targets information
	*/
	GetClientName(iTarget, sTargetName, sizeof(sTargetName));
	GetClientIP(iTarget, sTargetIP, sizeof(sTargetIP));
	GetClientAuthString(iTarget, sTargetID, sizeof(sTargetID));
	iTargetFrags = GetClientFrags(iTarget);
	iTargetDeaths = GetClientDeaths(iTarget);
	
	/**
	 Format the strings for the menu
	*/
	Format(sDisplayName, sizeof(sDisplayName), "Player: %s", sTargetName);
	Format(sDisplayID, sizeof(sDisplayID), "Steam ID: %s", sTargetID);
	Format(sDisplayIP, sizeof(sDisplayIP), "IP Address: %s", sTargetIP);
	Format(sDisplayFrags, sizeof(sDisplayFrags), "Kills: %i", iTargetFrags);
	Format(sDisplayDeaths, sizeof(sDisplayDeaths), "Deaths: %i", iTargetDeaths);
	
	/**
	 Create the menu and set the menu options.
	*/
	new Handle:hMenu = CreateMenu(Menu_PlayerHud);
	SetMenuExitBackButton(hMenu, false);
	SetMenuTitle(hMenu, "Simple Spectator");
	
	AddMenuItem(hMenu, "name", sDisplayName, ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "steamid", sDisplayID, ITEMDRAW_DISABLED);
	
	if (SM_IsValidAdmin(iClient, g_sAdminFlags))
	{		
		AddMenuItem(hMenu, "ip", sDisplayIP, ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(hMenu, "kills", sDisplayFrags, ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "deaths", sDisplayDeaths, ITEMDRAW_DISABLED);
	
	if (g_aPlayers[iClient][iTargetIndex])
	{
		AddMenuItem(hMenu, "stop", "Stop Following");
	}
	else
	{
		AddMenuItem(hMenu, "start", "Follow Player");
	}
	
	if ((GetUserFlagBits(iClient) & ADMFLAG_GENERIC) || (GetUserFlagBits(iClient) & ADMFLAG_ROOT))
	{
		if (g_aPlayers[iTarget][bIsFlaggedCheater] && (GetUserFlagBits(iClient) & ADMFLAG_ROOT))
		{
			AddMenuItem(hMenu, "removecheater", "Remove Cheater Flag");
		}
		else
		{
			if (CanUserTarget(iClient, iTarget))
			{
				AddMenuItem(hMenu, "punish", "Punish Player");
			}
			else
			{
				AddMenuItem(hMenu, "punish", "Punish Player (Immune)", ITEMDRAW_DISABLED);
			}
		}
	}
	else
	{
		AddMenuItem(hMenu, "reportcheater", "Report Cheater");
	}
	
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	return hMenu;
}

stock Handle:BuildPlayerHudPanel(iClient, iTarget)
{
	
	/**
	 Create all the string variables we will need
	*/
	new	String:sTargetName[MAX_NAME_LENGTH + 1],
		String:sTargetID[64],
		String:sTargetIP[16];
		
	new	String:sDisplayName[MAX_NAME_LENGTH + 1],
		String:sDisplayID[64],
		String:sDisplayIP[64],
		String:sDisplayFrags[16],
		String:sDisplayDeaths[16];

	new	iTargetFrags,
		iTargetDeaths;
	
	/**
	 Get the targets information
	*/
	GetClientName(iTarget, sTargetName, sizeof(sTargetName));
	GetClientIP(iTarget, sTargetIP, sizeof(sTargetIP));
	GetClientAuthString(iTarget, sTargetID, sizeof(sTargetID));
	iTargetFrags = GetClientFrags(iTarget);
	iTargetDeaths = GetClientDeaths(iTarget);
	
	/**
	 Format the strings for the menu
	*/
	Format(sDisplayName, sizeof(sDisplayName), "Player: %s", sTargetName);
	Format(sDisplayID, sizeof(sDisplayID), "Steam ID: %s", sTargetID);
	Format(sDisplayIP, sizeof(sDisplayIP), "IP Address: %s", sTargetIP);
	Format(sDisplayFrags, sizeof(sDisplayFrags), "Kills: %i", iTargetFrags);
	Format(sDisplayDeaths, sizeof(sDisplayDeaths), "Deaths: %i", iTargetDeaths);
	
	/**
	 Create the menu and set the menu options.
	*/
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Simple Spectator");
	
	DrawPanelText(hPanel, "Player Information:");
	DrawPanelText(hPanel, sDisplayName);
	DrawPanelText(hPanel, sDisplayID);
	if (SM_IsValidAdmin(iClient, g_sAdminFlags))
	{		
		DrawPanelText(hPanel, sDisplayIP);
	}
	
	DrawPanelText(hPanel, sDisplayFrags);
	DrawPanelText(hPanel, sDisplayDeaths);
	
	if (g_aPlayers[iClient][iTargetIndex])
	{
		DrawPanelItem(hPanel, "Stop Following");
	}
	else
	{
		DrawPanelItem(hPanel, "Follow Player");
	}
	
	if ((GetUserFlagBits(iClient) & ADMFLAG_GENERIC) || (GetUserFlagBits(iClient) & ADMFLAG_ROOT))
	{
		if (g_aPlayers[iTarget][bIsFlaggedCheater] && (GetUserFlagBits(iClient) & ADMFLAG_ROOT))
		{
			DrawPanelItem(hPanel, "Remove Cheater Flag");
		}
		else
		{
			if (CanUserTarget(iClient, iTarget))
			{
				DrawPanelItem(hPanel, "Punish Player");
			}
			else
			{
				DrawPanelItem(hPanel, "Punish Player (Immune)", ITEMDRAW_DISABLED);
			}
		}
	}
	else
	{
		DrawPanelItem(hPanel, "Report Cheater");
	}
	
	DrawPanelItem(hPanel, "Close Hud Panel");
	return hPanel;
}

/**
Adjust the settings if a convar was changed
*/
public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for (new iCvar = 0 ; _:iCvar < sizeof(g_aPluginCvarSettings); iCvar++)
	{
		if (g_aPluginCvar[_:iCvar] == convar)
		{
			if (StringToInt(newValue) == 1)
			{
				g_aPluginCvarSettings[_:iCvar] = true;
			}
			else
			{
				g_aPluginCvarSettings[_:iCvar] = false;
			}
		}
	}
	
	/*
	ReBuild the global menu that depends on cvars
	*/
	g_aMenus[hBanTime] = BuildBanTimeMenu();
	
	/**
	Run a loop to reset the hud
	*/
	for(new i = 1; i <= MaxClients; i++) 
	{
		StopDisplayingHud(i);
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == g_aCurrentTeams[Spectator])
		{
			StartDisplayingHud(i);
		}
	}
}
