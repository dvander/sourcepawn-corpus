/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * "Too Late To Ban" by Shenton
 *
 * English is not my language, sorry if I spell it wrong
 *
 * Developed on l4d, I don't know if it work with other mods/games (it should)
 *
 * This plugin store players names and steamids that disconnected recently,
 * allowing you to ban them with a menu even if they are disconnected.
 * Usefull for those little <insert insult here> that jump from a cliff and disconnect immediately
 *
 * Developed on SourceMod 1.2.1
 */

/*
 * Changelog
 *
 * Version 1.0.0
 * - initial release
 */

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define TLTB_VERSION "1.0.0a"
#define DEBUG 0
#define PLAYER_NAME_SIZE 33
#define PLAYER_NETID_SIZE 32
#define BAN_STRING_SIZE 255
#define MAX_STORED_PLAYERS 20
#define DISCONNECT_REASON_SIZE 64
#define NETID_TO_COMPARE "STEAM_"
#define FILE_PATH_SIZE 128
#define KEY_STRING_SIZE 32
#define BAN_TIME_SIZE 16
#define BAN_REASON_SIZE 32
#define ARG_SIZE 16

public Plugin:myinfo =
{
	name = "Too Late To Ban",
	author = "Shenton",
	description = "Store players that disconnected recently, allowing you to ban them with a menu.",
	version = TLTB_VERSION,
	url = "http://www.a51.eu/"
};

/*
 * ##################################################
 * Globals
 * ##################################################
 */

/* Handle for the players names */
new Handle:hTltbNamesArray = INVALID_HANDLE;

/* Handle for the players steamids */
new Handle:hTltbNetidsArray = INVALID_HANDLE;

/* Set to true when adding a player
 * Set to false when the player is added
 */
new tltbIsPushing = false;

/* Will contain the ban informations */
new String:tltbBanString[BAN_STRING_SIZE];

/* Will contain the player name we are banning, used for menu title */
new String:pNameMenu[PLAYER_NAME_SIZE];

/* Menu handles */
new Handle:hTltbMenu = INVALID_HANDLE;
new Handle:hTltbMenuTime = INVALID_HANDLE;
new Handle:hTltbMenuReason = INVALID_HANDLE;

/* AdminMenu handle/object */
new Handle:hTltbAdminMenu = INVALID_HANDLE;
new TopMenuObject:oTltbPlayerCommands = INVALID_TOPMENUOBJECT;

/* Convars handles */
new Handle:hTltbCheckReason = INVALID_HANDLE;
new Handle:hTltbMaxStore = INVALID_HANDLE;
new Handle:hTltbPlayersOrder = INVALID_HANDLE;
new Handle:hTltbUseBanReason = INVALID_HANDLE;
new Handle:hTltbUseAdminMenu = INVALID_HANDLE;

/* Convars values */
new bool:tltbCheckReason;
new tltbMaxStore;
new bool:tltbPlayersOrder;
new bool:tltbUseBanReason;
new bool:tltbUseAdminMenu;

/* Ban options KeyValues handle */
new Handle:hKvOptions = INVALID_HANDLE;

/* Ban options file path variable */
new String:tltbFileOptions[FILE_PATH_SIZE];

#if DEBUG
/* Contain the debug message to display to admins */
new String:tltbDebugMessage[255];
#endif

/*
 * ##################################################
 * Called Natives
 * ##################################################
 */

/* Operations on plugin start */
public OnPluginStart()
{
	/* Creation of the 2 players informations dynamics arrays */
	hTltbNamesArray = CreateArray(PLAYER_NAME_SIZE, 0);
	hTltbNetidsArray = CreateArray(PLAYER_NETID_SIZE, 0);

	/* Convars Section */
	hTltbCheckReason = CreateConVar("tltb_check_reason", "0", "Only store a player informations if he disconnected himself, values: <0|1>.", FCVAR_PLUGIN);
	hTltbMaxStore = CreateConVar("tltb_stored_players", "7", "The maximum number of player(s) to store, values: <0 to 20>.", FCVAR_PLUGIN);
	hTltbPlayersOrder = CreateConVar("tltb_players_order", "1", "Display the last disconnected players first in the menu, values: <0|1>.", FCVAR_PLUGIN);
	hTltbUseBanReason = CreateConVar("tltb_use_ban_reason", "1", "Display the ban reasons menu, values: <0|1>.", FCVAR_PLUGIN);
	hTltbUseAdminMenu = CreateConVar("tltb_use_admin_menu", "1", "Add a \"Ban disconnected player\" menu in players commands section of admin menu, values: <0|1>.", FCVAR_PLUGIN);

	/* Execute the config file and create it if it not exists */
	AutoExecConfig(true, "too_late_to_ban");

	/* Main event, called on a player disconnection */
	HookEvent("player_disconnect", TltbPlayerDisconnect);

	/* Main public command */
	RegAdminCmd("sm_tltb", TltbPublicCommand, ADMFLAG_BAN);

	#if DEBUG
	/* Fill arrays informations and generate diconnected players menu */
	RegAdminCmd("sm_tltbtest", TltbTest, ADMFLAG_BAN);
	/* Add the same player */
	RegAdminCmd("sm_tltbtest2", TltbTestTwo, ADMFLAG_BAN);
	#endif

	/* Set ban options file path */
	BuildPath(Path_SM, tltbFileOptions, sizeof(tltbFileOptions), "data/tltb_ban_options.txt");

	/* Check if ban options file exists
	 * Create it if not
	 */
	hKvOptions = CreateKeyValues("TooLateToBan");
	if (!FileToKeyValues(hKvOptions, tltbFileOptions))
	{
		CloseHandle(hKvOptions);
		hKvOptions = INVALID_HANDLE;
		CreateOptionsFile();
	}
	else
	{
		CloseHandle(hKvOptions);
		hKvOptions = INVALID_HANDLE;
	}
}

/* Executed after the config file is loaded */
public OnConfigsExecuted()
{
	/* Set Convars to variables */
	tltbCheckReason = GetConVarBool(hTltbCheckReason);
	tltbMaxStore = GetConVarInt(hTltbMaxStore);
	tltbPlayersOrder = GetConVarBool(hTltbPlayersOrder);
	tltbUseBanReason = GetConVarBool(hTltbUseBanReason);
	tltbUseAdminMenu = GetConVarBool(hTltbUseAdminMenu);

	/* Ensure that the maximum stored players value didn't exceeds the hardcoded one */
	if (tltbMaxStore > MAX_STORED_PLAYERS) { tltbMaxStore = MAX_STORED_PLAYERS; }

	/* Cvar version of the plugin */
	CreateConVar("tltb_version", TLTB_VERSION, "The version of \"Too Late To Ban\".", FCVAR_PLUGIN|FCVAR_NOTIFY);

	/* If we want to use AdminMenu and menu is not integrated */
	if (tltbUseAdminMenu && (hTltbAdminMenu == INVALID_HANDLE))
	{
		/* Check if adminmenu lib exists, set the adminmenu handle and add to AdminMenu */
		if (LibraryExists("adminmenu") && ((hTltbAdminMenu = GetAdminTopMenu()) != INVALID_HANDLE)) { TltbAttachAdminMenu(); }
	}
	/* If we don't want to use AdminMenu and menu is integrated (cvar changed before a changemap) */
	else if (!tltbUseAdminMenu && (hTltbAdminMenu != INVALID_HANDLE))
	{
		/* Remove plugin menu from AdminMenu and reset handle/object */
		RemoveFromTopMenu(hTltbAdminMenu, oTltbPlayerCommands);
		oTltbPlayerCommands = INVALID_TOPMENUOBJECT;
		hTltbAdminMenu = INVALID_HANDLE;
	}
}

/* Called when an optional lib is removed */
public OnLibraryRemoved(const String:name[])
{
	/* If admin menu lib is removed */
	if (StrEqual(name, "adminmenu")) { hTltbAdminMenu = INVALID_HANDLE; }
}

/*
 * ##################################################
 * Local functions
 * ##################################################
 */

/* Create the ban options file, overwrite it even if it already exists */
CreateOptionsFile()
{
	/* Handle of the KeyValues structure */
	hKvOptions = CreateKeyValues("TooLateToBan");

	/* Ban time section */
	KvJumpToKey(hKvOptions, "BanTime", true);

	KvJumpToKey(hKvOptions, "Permanent", true);
	KvSetString(hKvOptions, "time", "0");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "10 Minutes", true);
	KvSetString(hKvOptions, "time", "10");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "30 Minutes", true);
	KvSetString(hKvOptions, "time", "30");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "1 Hour", true);
	KvSetString(hKvOptions, "time", "60");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "1 Day", true);
	KvSetString(hKvOptions, "time", "1440");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "1 Week", true);
	KvSetString(hKvOptions, "time", "10080");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "1 Month", true);
	KvSetString(hKvOptions, "time", "302400");
	KvRewind(hKvOptions);

	/* Ban reason section */
	KvJumpToKey(hKvOptions, "BanReason", true);

	KvJumpToKey(hKvOptions, "Abusive", true);
	KvSetString(hKvOptions, "reason", "Abusive");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "Lamer", true);
	KvSetString(hKvOptions, "reason", "Lamer");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "Team Killing", true);
	KvSetString(hKvOptions, "reason", "Team Killing");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "Exploit", true);
	KvSetString(hKvOptions, "reason", "Exploit");
	KvGoBack(hKvOptions);

	KvJumpToKey(hKvOptions, "Cheat", true);
	KvSetString(hKvOptions, "reason", "Cheat");
	KvRewind(hKvOptions);

	/* Write the KeyValues structure to the ban options file */
	KeyValuesToFile(hKvOptions, tltbFileOptions);

	/* Close KeyValues structure handle */
	CloseHandle(hKvOptions);
	hKvOptions = INVALID_HANDLE;
}

/* Print to client the script usage */
DisplayScriptUsage(client)
{
	ReplyToCommand(client, "[TLTB] Usage: sm_tltb [reset|resetmenu].");
}

/*
 * ##################################################
 * Hooked events
 * ##################################################
 */

/* Main event function, called on player disconnection */
public Action:TltbPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (event != INVALID_HANDLE)
	{
		/* Set variables to informations provided by event "player_disconnect" */
		decl String:pNetid[PLAYER_NETID_SIZE], String:pReason[DISCONNECT_REASON_SIZE], String:pName[PLAYER_NAME_SIZE];
		GetEventString(event, "networkid", pNetid, sizeof(pNetid));
		GetEventString(event, "reason", pReason, sizeof(pReason));
		GetEventString(event, "name", pName, sizeof(pName));

		/* If reason check is asked, we check if the player disconnected himself
		 * If not we simply add a new entry to the arrays
		 */
		if (!tltbCheckReason || (tltbCheckReason && StrEqual(pReason, "Disconnect by user.")))
		{
			/* If one of the needed disconnected player information is missing */
			if (StrEqual(pName, "") || StrEqual(pNetid, ""))
			{
				#if DEBUG
				Format(tltbDebugMessage, sizeof(tltbDebugMessage), "A string was empty <%s> <%s> - TltbPlayerDisconnect()", pName, pNetid);
				TltbPrintToAdmin();
				#endif

				return Plugin_Continue;
			}
			/* If disconnected player netid is invalid */
			else if (strncmp(pNetid, NETID_TO_COMPARE, 6) != 0)
			{
				#if DEBUG
				Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Invalid steamid probably a bot - TltbPlayerDisconnect()");
				TltbPrintToAdmin();
				#endif

				return Plugin_Continue;
			}
			/* If we are not already adding a player, add one and generate diconnected players menu */
			else if (!tltbIsPushing)
			{
				/* If player is not already stored */
				if (FindStringInArray(hTltbNetidsArray, pNetid) == -1)
				{
					/* Tell the script we are adding a player */
					tltbIsPushing = true;

					/* Add player informations to arrays */
					PushArrayString(hTltbNamesArray, pName);
					PushArrayString(hTltbNetidsArray, pNetid);

					/* Remove the first entry of both arrays if the max players stored value is reached
					 *
					 * Yes I should have set the array size to a variable,
					 * but this is just in case an error occur,
					 * it should never loop twice or more.
					 */
					while (GetArraySize(hTltbNamesArray) > tltbMaxStore)
					{
						RemoveFromArray(hTltbNamesArray, 0);
						RemoveFromArray(hTltbNetidsArray, 0);
					}

					/* Generate players menu */
					if (hTltbMenu != INVALID_HANDLE)
					{
						CloseHandle(hTltbMenu);
						hTltbMenu = INVALID_HANDLE;
					}
					hTltbMenu = TltbMenu();

					/* Tell the script we have added the disconnected player */
					tltbIsPushing = false;

					#if DEBUG
					Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Player added %s %s - TltbPlayerDisconnect()", pName, pNetid);
					TltbPrintToAdmin();
					#endif

					return Plugin_Handled;
				}
				else
				{
					#if DEBUG
					Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Player was already stored - TltbPlayerDisconnect()");
					TltbPrintToAdmin();
					#endif

					return Plugin_Continue;
				}
			}
			/* We were already adding a disconnected player */
			else
			{
				#if DEBUG
				Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Was already pushing - TltbPlayerDisconnect()");
				TltbPrintToAdmin();
				#endif

				return Plugin_Continue;
			}
		}
		else
		{
			#if DEBUG
			Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Check reason is asked and player did not disconnected himself - TltbPlayerDisconnect()");
			TltbPrintToAdmin();
			#endif

			return Plugin_Continue;
		}
	}
	else
	{
		#if DEBUG
		Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Invalid event handle - TltbPlayerDisconnect()");
		TltbPrintToAdmin();
		#endif

		return Plugin_Continue;
	}
}

/*
 * ##################################################
 * Public commands functions
 * ##################################################
 */

/* Main public command function */
public Action:TltbPublicCommand(client,args)
{
	/* If no argument we display the menu */
	if (args == 0)
	{
		/* If command is used in server console */
		if (client == 0)
		{
			ReplyToCommand(client, "[TLTB] Command is in-game only.");

			return Plugin_Continue;
		}
		/* Display the disconnected players menu */
		else
		{
			/* If there is no entry in informations arrays */
			if (GetArraySize(hTltbNamesArray) == 0) { ReplyToCommand(client, "[TLTB] No player stored."); }
			/* Try to display the menu */
			else
			{
				/* If menu handle is invalid */
				if (hTltbMenu == INVALID_HANDLE) { ReplyToCommand(client, "[TLTB] An error occured while generating disconnected players menu."); }
				/* Try to display the menu */
				else
				{
					/* If we are adding a player */
					if (tltbIsPushing) { ReplyToCommand(client, "[TLTB] Adding a player, please retry the command."); }
					/* Display the menu */
					else { DisplayMenu(hTltbMenu, client, MENU_TIME_FOREVER); }
				}
			}

			return Plugin_Handled;
		}
	}
	/* If an argument is specified */
	else if (args == 1)
	{
		/* Set argument to a variable */
		decl String:arg[ARG_SIZE];
		GetCmdArgString(arg, sizeof(arg));

		/* Client want to reset disconnected players arrays */
		if (StrEqual(arg, "reset"))
		{
			ClearArray(hTltbNamesArray);
			ClearArray(hTltbNetidsArray);

			ReplyToCommand(client, "[TLTB] Stored disconnected players reset");

			return Plugin_Handled;
		}
		/* Client want to reset ban options file */
		else if (StrEqual(arg, "resetmenu"))
		{
			CreateOptionsFile();

			ReplyToCommand(client, "[TLTB] Menu options file reset");

			return Plugin_Handled;
		}
		else
		{
			DisplayScriptUsage(client);

			return Plugin_Continue;
		}
	}
	else
	{
		DisplayScriptUsage(client);

		return Plugin_Continue;
	}
}

/*
 * ##################################################
 * Menu
 * ##################################################
 */

/* Player selection menu, generated on player disconnection */
Handle:TltbMenu()
{
	/* Menu handle */
	new Handle:menu = CreateMenu(TltbMenuHandler);

	/* If handle is valid */
	if (menu != INVALID_HANDLE)
	{
		/* Disconnected player informations variables */
		decl String:pNetid[PLAYER_NETID_SIZE], String:pName[PLAYER_NAME_SIZE];

		/* The number of player(s) stored */
		new arraySize = GetArraySize(hTltbNamesArray);

		/* If displaying last disconnected players first is wanted */
		if (tltbPlayersOrder)
		{
			/* Decrement the arrays size value to fit array indexes */
			arraySize--;

			/* Loop - Add players informations to the menu */
			for (new i=arraySize;i>=0;i--)
			{
				/* Retrieve player informations */
				GetArrayString(hTltbNamesArray, i, pName, sizeof(pName));
				GetArrayString(hTltbNetidsArray, i, pNetid, sizeof(pNetid));

				/* Add one menu entry */
				AddMenuItem(menu, pNetid, pName);
			}
		}
		/* If displaying last disconnected players first is not wanted */
		else
		{
			/* Loop - Add players informations to the menu */
			for (new i=0;i<arraySize;i++)
			{
				/* Retrieve player informations */
				GetArrayString(hTltbNamesArray, i, pName, sizeof(pName));
				GetArrayString(hTltbNetidsArray, i, pNetid, sizeof(pNetid));

				/* Add one menu entry */
				AddMenuItem(menu, pNetid, pName);
			}
		}

		/* Menu title */
		SetMenuTitle(menu, "Ban a disconnected player:");
	}
	#if DEBUG
	else
	{
		Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Error with menu handle - TltbMenu()");
		TltbPrintToAdmin();
	}
	#endif

	return menu;
}

/* Handler of the player selection menu */
public TltbMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If a menu entry has been selected */
	if (action == MenuAction_Select)
	{
		/* Selected player informations variables */
		decl String:pNetid[PLAYER_NETID_SIZE], String:pName[PLAYER_NAME_SIZE];

		/* Used for GetMenuItem 5th arg */
		new dummy;

		/* Retrieve the selected player informations */
		GetMenuItem(menu, param2, pNetid, sizeof(pNetid), dummy, pName, sizeof(pName));

		/* Add the player netid to the ban string */
		Format(tltbBanString, sizeof(tltbBanString), "%s", pNetid);

		/* Set the selected player name to a global variable, used for menu title */
		Format(pNameMenu, sizeof(pNameMenu), "%s", pName);

		/* Generate the time selection menu */
		hTltbMenuTime = TltbMenuTime();

		/* If menu handle is valid display it*/
		if (hTltbMenuTime != INVALID_HANDLE) { DisplayMenu(hTltbMenuTime, param1, MENU_TIME_FOREVER); }
		/* If menu handle is invalid display an error message to the client */
		else
		{
			ReplyToCommand(param1, "[TLTB] Error generating ban time menu, check your ban options file in <sm_dir>/data/tltb_ban_options.txt or use !tltb resetmenu.");

			#if DEBUG
			Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Error with menu handle - TltbMenuHandler()");
			TltbPrintToAdmin();
			#endif
		}
	}
}

/* Time selection menu, generetad on player selection */
Handle:TltbMenuTime()
{
	/* Menu handle */
	new Handle:menu = CreateMenu(TltbMenuTimeHandler);

	/* If handle is valid */
	if (menu != INVALID_HANDLE)
	{
		/* Will contain menu values */
		decl String:sectionName[KEY_STRING_SIZE], String:keyValue[BAN_TIME_SIZE];

		/* Used to check if we added at least one menu entry */
		new entryCheck = 0;

		/* Set the ban options file handle */
		hKvOptions = CreateKeyValues("TooLateToBan");
		if (!FileToKeyValues(hKvOptions, tltbFileOptions)) { return INVALID_HANDLE; }
		if (!KvJumpToKey(hKvOptions, "BanTime", false)) { return INVALID_HANDLE; }
		if (!KvGotoFirstSubKey(hKvOptions)) { return INVALID_HANDLE; }

		/* Add menu entries */
		do
		{
			KvGetSectionName(hKvOptions, sectionName, sizeof(sectionName));
			KvGetString(hKvOptions, "time", keyValue, sizeof(keyValue));

			/* Check if key is not empty and add menu entry */
			if (strlen(keyValue) > 0)
			{
				AddMenuItem(menu, keyValue, sectionName);
				entryCheck++;
			}
		} while (KvGotoNextKey(hKvOptions));

		/* If we got no entry return invalid handle */
		if (entryCheck == 0) { return INVALID_HANDLE; }

		/* Menu title */
		SetMenuTitle(menu, "Ban %s for (time):", pNameMenu);
	}
	#if DEBUG
	else
	{
		Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Error with menu handle - TltbMenuTime()");
		TltbPrintToAdmin();
	}
	#endif

	return menu;
}

/* Handler of the time selection menu
 * Ban the player if reason menu is not wanted
 */
public TltbMenuTimeHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an entry is selected or menu is closed, reset the menu */
	if (action == MenuAction_End)
	{
		CloseHandle(hTltbMenuTime);
		hTltbMenuTime = INVALID_HANDLE;
	}
	/* If a menu entry has been selected */
	else if (action == MenuAction_Select)
	{
		/* Selected ban time variable */
		decl String:banTime[BAN_TIME_SIZE];

		/* Retrieve the ban time */
		GetMenuItem(menu, param2, banTime, sizeof(banTime));

		/* Add the ban time to the ban string */
		Format(tltbBanString, sizeof(tltbBanString), "%s %s", banTime, tltbBanString);

		/* If ban reason menu is wanted */
		if (tltbUseBanReason)
		{
			/* Generate the reason selection menu */
			hTltbMenuReason = TltbMenuReason();

			/* If menu handle is valid display it*/
			if (hTltbMenuReason != INVALID_HANDLE) { DisplayMenu(hTltbMenuReason, param1, MENU_TIME_FOREVER); }
			/* If menu handle is invalid display an error message to the client */
			else
			{
				ReplyToCommand(param1, "[TLTB] Error generating ban reason menu, check your ban options file in <sm_dir>/data/tltb_ban_options.txt or use !tltb resetmenu.");
			}
		}
		/* If ban reason menu is not wanted */
		else
		{
			/* Ban the disconnected player */
			FakeClientCommand(param1, "sm_addban %s", tltbBanString);

			#if DEBUG
			Format(tltbDebugMessage, sizeof(tltbDebugMessage), "%s", tltbBanString);
			TltbPrintToAdmin();
			#endif
		}
	}
}

/* Reason selection menu, generetad on time selection */
Handle:TltbMenuReason()
{
	/* Menu handle */
	new Handle:menu = CreateMenu(TltbMenuReasonHandler);

	/* If handle is valid */
	if (menu != INVALID_HANDLE)
	{
		/* Will contain menu values */
		decl String:sectionName[KEY_STRING_SIZE], String:keyValue[BAN_TIME_SIZE];

		/* Used to check if we added at least one menu entry */
		new entryCheck = 0;

		/* Set the ban options file handle */
		hKvOptions = CreateKeyValues("TooLateToBan");
		if (!FileToKeyValues(hKvOptions, tltbFileOptions)) { return INVALID_HANDLE; }
		if (!KvJumpToKey(hKvOptions, "BanReason", false)) { return INVALID_HANDLE; }
		if (!KvGotoFirstSubKey(hKvOptions)) { return INVALID_HANDLE; }

		/* Add menu entries */
		do
		{
			/* Retrieve values */
			KvGetSectionName(hKvOptions, sectionName, sizeof(sectionName));
			KvGetString(hKvOptions, "reason", keyValue, sizeof(keyValue));

			/* Check if key is not empty and add menu entry */
			if (strlen(keyValue) > 0)
			{
				AddMenuItem(menu, keyValue, sectionName);
				entryCheck++;
			}
		} while (KvGotoNextKey(hKvOptions));

		/* If we got no entry return invalid handle */
		if (entryCheck == 0) { return INVALID_HANDLE; }

		/* Menu title */
		SetMenuTitle(menu, "Ban %s for (reason):", pNameMenu);
	}
	#if DEBUG
	else
	{
		Format(tltbDebugMessage, sizeof(tltbDebugMessage), "Error with menu handle - TltbMenuReason()");
		TltbPrintToAdmin();
	}
	#endif

	return menu;
}

/* Handler of the reason selection menu
 * Ban the disconnected player
 */
public TltbMenuReasonHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an entry is selected or menu is closed, reset the menu */
	if (action == MenuAction_End)
	{
		CloseHandle(hTltbMenuReason);
		hTltbMenuReason = INVALID_HANDLE;
	}
	/* If a menu entry has been selected */
	else if (action == MenuAction_Select)
	{
		/* Selected ban reason variable */
		decl String:banReason[BAN_REASON_SIZE];

		/* Retrieve the ban reason */
		GetMenuItem(menu, param2, banReason, sizeof(banReason));

		/* If not empty add the ban reason to the ban string */
		if (strlen(banReason) > 0) { Format(tltbBanString, sizeof(tltbBanString), "%s %s", tltbBanString, banReason); }

		/* Ban the disconnected player */
		FakeClientCommand(param1, "sm_addban %s", tltbBanString);

		#if DEBUG
		Format(tltbDebugMessage, sizeof(tltbDebugMessage), "%s", tltbBanString);
		TltbPrintToAdmin();
		#endif
	}
}

/*
 * ##################################################
 * AdminMenu
 * ##################################################
 */

/* Add ban disconnected player menu to the admin menu player commands category */
TltbAttachAdminMenu()
{
	/* Find the category object id of player commands menu */
	new TopMenuObject:oPlayerCommands = FindTopMenuCategory(hTltbAdminMenu, ADMINMENU_PLAYERCOMMANDS);

	/* If object is invalid return */
	if (oPlayerCommands == INVALID_TOPMENUOBJECT) { return; }

	/* Add the category */
	oTltbPlayerCommands = AddToTopMenu(hTltbAdminMenu, "sm_tltb", TopMenuObject_Item, TltbAdminMenuHandler, oPlayerCommands, "sm_tltb", ADMFLAG_BAN);
}

/* AdminMenu handler */
public TltbAdminMenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	/* Category name display */
	if (action == TopMenuAction_DisplayOption) { Format(buffer, maxlength, "Ban disconnected player"); }
	/* Ban disconnected player category is selected display menu */
	else if (action == TopMenuAction_SelectOption)
	{
		/* If there is no entry in informations arrays */
		if (GetArraySize(hTltbNamesArray) == 0) { ReplyToCommand(param, "[TLTB] No player stored."); }
		/* Try to display the menu */
		else
		{
			/* If menu handle is invalid */
			if (hTltbMenu == INVALID_HANDLE) { ReplyToCommand(param, "[TLTB] An error occured while generating disconnected players menu."); }
			/* Try to display the menu */
			else
			{
				/* If we are adding a player */
				if (tltbIsPushing) { ReplyToCommand(param, "[TLTB] Adding a player, please retry."); }
				/* Display the menu */
				else { DisplayMenu(hTltbMenu, param, MENU_TIME_FOREVER); }
			}
		}
	}
}

/*
 * ##################################################
 * Testing/Debug
 * ##################################################
 */

#if DEBUG
/* Return if the player is an admin
 * args:
 * - client => the player id
 */
bool:TltbIsAdmin(client)
{
	if (GetUserAdmin(client) == INVALID_ADMIN_ID) { return false; }
	else { return true; }
}

/* Print the debug message to admins in game */
TltbPrintToAdmin()
{
	for (new i=1;i<=MaxClients;i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			if (TltbIsAdmin(i)) { PrintToChat(i, "[TLTB] %s", tltbDebugMessage); }
		}
	}
}

/* For testing purpose, fill informations arrays with dummy infos and generate players menu */
public Action:TltbTest(client,args)
{
	decl String:pNetid[32], String:pName[32], String:numBuffer[2];

	new letters[] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'};
	new tmp, size, i, ii;

	for (ii=1;ii<=12;ii++)
	{
		size = GetRandomInt(4, 8);
		for (i=1;i<=size;i++)
		{
			tmp = GetRandomInt(0, 25);
			StrCat(pName, sizeof(pName), letters[tmp]);
		}

		size = GetRandomInt(8, 10);
		StrCat(pNetid, sizeof(pNetid), "STEAM_0:");
		for (i=1;i<=size;i++)
		{
			tmp = GetRandomInt(0, 9);
			IntToString(tmp, numBuffer, sizeof(numBuffer));
			StrCat(pNetid, sizeof(pNetid), numBuffer);
		}

		PushArrayString(hTltbNamesArray,pName);
		PushArrayString(hTltbNetidsArray,pNetid);

		strcopy(pNetid, sizeof(pNetid), "");
		strcopy(pName, sizeof(pName), "");
	}

	if (hTltbMenu != INVALID_HANDLE)
	{
		CloseHandle(hTltbMenu);
		hTltbMenu = INVALID_HANDLE;
	}
	hTltbMenu = TltbMenu();
}

/* For testing purpose, fire player_disconnect event with the same player */
public Action:TltbTestTwo(client,args)
{
	new Handle:event = CreateEvent("player_disconnect", false);
	SetEventString(event, "name", "UberPlayerZ");
	SetEventString(event, "networkid", "STEAM_0:0:123456789");
	SetEventString(event, "reason", "Disconnect by user.");
	FireEvent(event);
}
#endif
