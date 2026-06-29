//**********************************************************************************
//* Name: crits_manager
//* Abstract: Provides control for crits calculations
//* Creator: Ghost
//**********************************************************************************
#pragma semicolon 1

//**********************************************************************************
//* Includes
//**********************************************************************************

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.3"

//**********************************************************************************
//* User Defined Types
//**********************************************************************************
// client specific crits mode, takes precedence over serverwide 
//		(normal means serverwide management takes over if active)
enum enuPlayerCritsType
{
	 enuPlayerCritsType_Normal
	,enuPlayerCritsType_FullCrits
	,enuPlayerCritsType_NoCrits
};

// Server wide management options, managed uses custom crit chances
enum enuCritManagementModeType
{
	 enuCritManagementMode_FullCrits
	,enuCritManagementMode_NoCrits
	,enuCritManagementMode_Managed
};

//**********************************************************************************
//* Global Variables
//**********************************************************************************

// individual client crit settings
new enuPlayerCritsType:g_PlayerCrits[MAXPLAYERS+1];

// serverwide crit management settings
new bool:g_blnCritManagementEnabled;
new enuCritManagementModeType:g_enuCritManagementMode;

//Cvars
new Handle:g_cvarCritRatePrimaryWeapon;
new Handle:g_cvarCritRateSecondaryWeapon;
new Handle:g_cvarCritRateMeleeWeapon;

// used in admin menu
new Handle:g_hTopMenu = INVALID_HANDLE;
new g_clnPlayerToGiveCrits;		// *WARNING: potential race condition is multple admins are using this at once, may fix later

//**********************************************************************************
//* Name: my info
//* Abstract: basic information about the plugin
//**********************************************************************************
public Plugin:myinfo =
{
	name = "Crits Manager",
	author = "Ghost/Dessix (same thing)",
	description = "Provides control for crits calculations",
	version = PLUGIN_VERSION,
	url = "www.3rdoct.org or https://forums.alliedmods.net/forumdisplay.php?f=52"
};

//**********************************************************************************
//* Name: On Plugin Start - Event Handler
//* Abstract: Get the admin menu and set it up
//**********************************************************************************
public OnPluginStart()
{
	//Initialize
	InitializePlayerList();
	
	//disable crits management by default, made make into cvar later.
	g_blnCritManagementEnabled = false;
	g_enuCritManagementMode = enuCritManagementMode_Managed;
	
	//CVARs
	CreateConVar("sm_critsmanager_version", PLUGIN_VERSION, "Crits Manager Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarCritRatePrimaryWeapon = CreateConVar("sm_critsmanager_crit_Primary", "2", "Primary Weapon Crit Chance", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	g_cvarCritRateSecondaryWeapon = CreateConVar("sm_critsmanager_crit_Secondary", "3", "Secondary Weapon Crit Chance", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	g_cvarCritRateMeleeWeapon = CreateConVar("sm_critsmanager_crit_Melee", "5", "Melee Weapon Crit Chance", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	
	//make config file
	AutoExecConfig(true, "plugin.crits_manager");
	
	//Admin Menu
	new Handle:topmenu;
	
	//if the top menu exists and we can get it, set up the menu options
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

//**********************************************************************************
//* Name: Initialize Player List
//* Abstract: set all the players to have normal crit frequency
//**********************************************************************************
public InitializePlayerList()
{
	new intPlayerIndex = 0;

	//go through each player spot and set them to normal crit type (they get nothing special)
	for (intPlayerIndex = 1; intPlayerIndex <= MAXPLAYERS; intPlayerIndex += 1)
	{
		g_PlayerCrits[intPlayerIndex] = enuPlayerCritsType_Normal;
	}
	
}

//**********************************************************************************
//* Name: On Admin Menu Ready
//* Abstract: Add the menu options to the admin menu
//**********************************************************************************
public OnAdminMenuReady(Handle:topmenu)
{
	// Block us from being called twice 
	if (topmenu != g_hTopMenu )
	{
		// Save the Handle to the admin menu
		g_hTopMenu  = topmenu;
	
		// Find the "Player Commands" and "Server Commands" category 
		new TopMenuObject:tmoPlayer_Commands = FindTopMenuCategory(g_hTopMenu , ADMINMENU_PLAYERCOMMANDS);
		new TopMenuObject:tmoServer_Commands = FindTopMenuCategory(g_hTopMenu , ADMINMENU_SERVERCOMMANDS);

		// Add the admin menu option to change a players crits settings
		if (tmoPlayer_Commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(g_hTopMenu ,
				"sm_GivePlayerCrits",
				TopMenuObject_Item,
				AdminMenu_GivePlayerCrits,
				tmoPlayer_Commands,
				"sm_GivePlayerCrits",
				ADMFLAG_SLAY);
		}
		
		// Add the admin menu option to manage serverwide crit rates
		if (tmoServer_Commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(g_hTopMenu ,
				"sm_ManageCritRates",
				TopMenuObject_Item,
				AdminMenu_ManageCritRates,
				tmoServer_Commands,
				"sm_ManageCritRates",
				ADMFLAG_SLAY);
		}
		
	}
}

//**********************************************************************************
//* Name: TF2_CalcIsAttackCritical - Event Handler
//* Abstract: determines if the shot being fired should be a crit
//**********************************************************************************
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	// return variable, intialized to Plugin Continue to let the normal crit calculation continue
	new Action:enuActionStatus = Plugin_Continue;

	// individual player crits take precedence over server wide crits
	if( g_PlayerCrits[client] != enuPlayerCritsType_Normal )
    {
		//determine whether the attack should crit based on the clients crit settings
		switch( g_PlayerCrits[client] )
		{
			case enuPlayerCritsType_FullCrits 	: 	result = true;
			case enuPlayerCritsType_NoCrits 	: 	result = false;
		}
		
		//set return to plugin handled to override crit calculation
		enuActionStatus = Plugin_Handled;
	}
	//calculate crits server wide
	else if( g_blnCritManagementEnabled == true )
	{
		//determine whether the attack should crit based on the serverwide crit settings
		switch( g_enuCritManagementMode )
		{
			case enuCritManagementMode_FullCrits	: result = true;
			case enuCritManagementMode_NoCrits 		: result = false;
			case enuCritManagementMode_Managed 		: result = ManageCriticalAttack(client);
		}
		
		//set return to plugin handled to override crit calculation
		enuActionStatus = Plugin_Handled;
	}
	
	return enuActionStatus;
}

//**********************************************************************************
//* Name: ManageCriticalAttack
//* Abstract: use a custom calculation to determine whether an attack is critcal or not
//**********************************************************************************
public bool:ManageCriticalAttack( any:clnTargetClient)
{
	new bool:blnResult = false;
	new intCurrentWeaponSlot;
	
	//get the active weapon slot
	intCurrentWeaponSlot = GetPlayerCurrentWeaponSlot(clnTargetClient);
	
	// calculate the crit boolean
	switch( intCurrentWeaponSlot )
	{
		case 1 : blnResult = CalculateCriticalChance( GetConVarInt(g_cvarCritRatePrimaryWeapon) );
		case 2 : blnResult = CalculateCriticalChance( GetConVarInt(g_cvarCritRateSecondaryWeapon) );
		case 3 : blnResult = CalculateCriticalChance( GetConVarInt(g_cvarCritRateMeleeWeapon) );
	}
	
	return blnResult;
}

//**********************************************************************************
//* Name: GetPlayerCurrentWeaponSlot
//* Abstract: return the players current active weapon slot
//**********************************************************************************
public GetPlayerCurrentWeaponSlot(clnTargetClient)
{
	//FIX: needs to find weapon slot
	new intCurrentWeaponSlot = 1;
	decl String:strWeaponName[32];
	
	//get the name of the clients weapons (will post the list if someone askes for it)
	GetClientWeapon( clnTargetClient, strWeaponName, sizeof(strWeaponName) );
	
	// get the players class, helps to ease the pain of the following hack
	new TFClassType:enuClientClass = TF2_GetPlayerClass(clnTargetClient);
	
	// find the weapon slot based on the players class
	// this does a string comparison onthe name of the weapon against hardcode values
	// painful hack but i prefer it over GetEntData
	switch( enuClientClass )
	{
		case TFClass_Scout 		: intCurrentWeaponSlot = GetScoutWeaponSlot(strWeaponName);
		case TFClass_Soldier 	: intCurrentWeaponSlot = GetSoldierWeaponSlot(strWeaponName);
		case TFClass_Pyro 		: intCurrentWeaponSlot = GetPyroWeaponSlot(strWeaponName);
		case TFClass_DemoMan 	: intCurrentWeaponSlot = GetDemomanWeaponSlot(strWeaponName);
		case TFClass_Heavy 		: intCurrentWeaponSlot = GetHeavyWeaponSlot(strWeaponName);
		case TFClass_Engineer 	: intCurrentWeaponSlot = GetEngineerWeaponSlot(strWeaponName);
		case TFClass_Medic 		: intCurrentWeaponSlot = GetMedicWeaponSlot(strWeaponName);
		case TFClass_Sniper 	: intCurrentWeaponSlot = GetSniperWeaponSlot(strWeaponName);
		case TFClass_Spy 		: intCurrentWeaponSlot = GetSpyWeaponSlot(strWeaponName);
	}

	return intCurrentWeaponSlot;
}

//**********************************************************************************
//* Name: GetScoutWeaponSlot
//* Abstract: return the the scouts weapon slot
//**********************************************************************************
public GetScoutWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_scattergun") == 0)
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_pistol_scout") == 0 ||
				strcmp(strWeaponName, "tf_weapon_lunchbox_drink") == 0 )
		intWeaponSlot = 2;
		
	return intWeaponSlot;
}

//**********************************************************************************
//* Name: GetSoldierWeaponSlot
//* Abstract: return the the Soldiers weapon slot
//**********************************************************************************
public GetSoldierWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_rocketlauncher") == 0)
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_shotgun_soldier") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}

//**********************************************************************************
//* Name: GetPyroWeaponSlot
//* Abstract: return the the Pyros weapon slot
//**********************************************************************************
public GetPyroWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_flamethrower") == 0)
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_shotgun_pyro") == 0 ||
				strcmp(strWeaponName, "tf_weapon_flaregun") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}
//**********************************************************************************
//* Name: GetDemomanWeaponSlot
//* Abstract: return the the Demomans weapon slot
//**********************************************************************************
public GetDemomanWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_grenadelauncher") == 0)
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_pipebomblauncher") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}

//**********************************************************************************
//* Name: GetHeavyWeaponSlot
//* Abstract: return the the Heavys weapon slot
//**********************************************************************************
public GetHeavyWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_minigun") == 0)
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_lunchbox") == 0 ||
				strcmp(strWeaponName, "tf_weapon_shotgun_hwg") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}

//**********************************************************************************
//* Name: GetEngineerWeaponSlot
//* Abstract: return the the Engineers weapon slot
//**********************************************************************************
public GetEngineerWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_shotgun_primary") == 0)
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_pistol") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}

//**********************************************************************************
//* Name: GetMedicWeaponSlot
//* Abstract: return the the Medics weapon slot
//**********************************************************************************
public GetMedicWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_syringegun_medic") == 0)
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_medigun") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}

//**********************************************************************************
//* Name: GetSniperWeaponSlot
//* Abstract: return the the Snipers weapon slot
//**********************************************************************************
public GetSniperWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_compound_bow") == 0 ||
				strcmp(strWeaponName, "tf_weapon_sniperrifle") == 0 )
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_jar") == 0 ||
				strcmp(strWeaponName, "tf_weapon_smg") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}

//**********************************************************************************
//* Name: GetSpyWeaponSlot
//* Abstract: return the the Spys weapon slot
//**********************************************************************************
public GetSpyWeaponSlot( String:strWeaponName[] )
{
	// if a name is not matched, assume its a melee weapon
	new intWeaponSlot = 3;
	
	//if the weapon name is this, its a primary weapon
	if( strcmp(strWeaponName, "tf_weapon_revolver") == 0 )
		intWeaponSlot = 1;
	//if the weapon name is this, its a seondary weapon
	else if( strcmp(strWeaponName, "tf_weapon_builder") == 0 )
		intWeaponSlot = 2;

	return intWeaponSlot;
}

//**********************************************************************************
//* Name: CalculateCriticalChance
//* Abstract: calculate the whether the attack should be critical or not
//**********************************************************************************
public bool:CalculateCriticalChance( intCritChance )
{
	new intRandomNumber;
	new bool:blnResult = false;
	
	//get a random number
	intRandomNumber = GetRandomInt( 1, 100 );
	
	// determine if this attack should be critcal or not
	if( intRandomNumber <= intCritChance )
	{
		blnResult = true;
	}
	
	return blnResult;
}

//**********************************************************************************
//* Name: OnClientDisconnect- Event Handler
//* Abstract: set crit settings to normal on discconnect
//**********************************************************************************
public OnClientDisconnect(client)
{
	// reset the crits type when the client discconects, prevents someone else 
	// from joining and getting th e same slot (and potentially a non-normal crit type)
	g_PlayerCrits[client] = enuPlayerCritsType_Normal;
}

//**********************************************************************************
//* Give Player Crits Menus
//**********************************************************************************


//**********************************************************************************
//* Name: Admin Menu _ Give Player Crits - Event Handler
//* Abstract: Handles the event for the crits player command
//**********************************************************************************
public AdminMenu_GivePlayerCrits(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	//If the admin menu wants to know what to display for this menu item
	if (action == TopMenuAction_DisplayOption)
	{
		//Write "Change Player's Team" to the buffer to be displayed
		Format(buffer, maxlength, "Give Player Crits", param);
	}
	//If the menu option is selected by the user, display the change teams menu
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayGivePlayerCritsMenu(param);
	}
}

//**********************************************************************************
//* Name: Display Give Player Crits Menu
//* Abstract: create the give player crits menu and display it
//**********************************************************************************
public DisplayGivePlayerCritsMenu(client)
{
	// Create the new menu and give it an event handler function name
	new Handle:menu = CreateMenu(MenuHandler_GivePlayerCrits);
	
	// make a title
	decl String:title[100];
	Format(title, sizeof(title), "Give Player Crits:");
	
	// Set the title on the menu
	SetMenuTitle(menu, title);
	
	//Set the menu exit buttons to true
	SetMenuExitBackButton(menu, true);
	
	//Add the full list of players to the menu
	AddTargetsToMenu(menu, client, true, false);
	
	//display the menu.
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//**********************************************************************************
//* Name:  Menu Handler _ Give Player Crits - Event Handler
//* Abstract: Handles the event for selecting an option in Give Player Crits menu
//**********************************************************************************
public MenuHandler_GivePlayerCrits(Handle:menu, MenuAction:action, param1, param2)
{
	// If the user wants to close the menu, close it
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	//If the user wants to go back to the menu menu, send them back to the main menu
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu  != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu , param1, TopMenuPosition_LastCategory);
		}
	}
	//If the user selected a player, save that player and open a new menu
	else if (action == MenuAction_Select)
	{
		decl String:strInfo[32];
		new intUserID, clnTargetPlayer;
		
		// Get the user id of the client
		GetMenuItem(menu, param2, strInfo, sizeof(strInfo));
		intUserID = StringToInt(strInfo);
		
		//Get the client of the user ID
		clnTargetPlayer = GetClientOfUserId(intUserID);
		
		// If the player is no longer in this game, we can't do anything
		if (clnTargetPlayer == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		// If the player can not be targeted
		else if (CanUserTarget(param1, clnTargetPlayer) == false)
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		// Display the Player Crit Options Menu
		else
		{	
			DisplayPlayerCritOptionsMenu(param1, clnTargetPlayer);
		}
	}
}

//**********************************************************************************
//* Name:  Display Change Team Target Menu
//* Abstract: display the menu that has the crits option 
//**********************************************************************************
public DisplayPlayerCritOptionsMenu(client, clnTargetPlayer)
{
	// Create the new menu and give it an event handler function name
	new Handle:menu = CreateMenu(MenuHandler_PlayerCritOptions);
	
	// Make the menu title
	decl String:title[100];
	Format(title, sizeof(title), "Crit Settings for %N", clnTargetPlayer);
	
	// Set the title on the menu
	SetMenuTitle(menu, title);
	
	//Set the menu exit buttons to true
	SetMenuExitBackButton(menu, true);
	
	// Save the Target Client reference so we can give him crits
		//*WARNING: potential race condition if multiple admins are using this at once
	g_clnPlayerToGiveCrits = clnTargetPlayer;
	
	//Add options
	//add the options based on what option is currently active on the client
	switch( g_PlayerCrits[clnTargetPlayer] )
	{
		case enuPlayerCritsType_Normal :
		{
			AddMenuItem(menu, "1", "Normal Crits (Current)");
			AddMenuItem(menu, "2", "Always Crits");
			AddMenuItem(menu, "3", "Never Crits");
		}
		case enuPlayerCritsType_FullCrits :
		{
			AddMenuItem(menu, "1", "Normal Crits");
			AddMenuItem(menu, "2", "Always Crits (Current)");
			AddMenuItem(menu, "3", "Never Crits");
		}
		case enuPlayerCritsType_NoCrits :
		{
			AddMenuItem(menu, "1", "Normal Crits");
			AddMenuItem(menu, "2", "Always Crits");
			AddMenuItem(menu, "3", "Never Crits (Current)");
		}
	}
	
	// Display the menu
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//**********************************************************************************
//* Name:  Menu Handler _ Player Crit Options - Event Handler
//* Abstract: Handles the event for selecting a crits option
//**********************************************************************************
public MenuHandler_PlayerCritOptions(Handle:menu, MenuAction:action, param1, param2)
{
	// If the user wants to close the menu, close it
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	//If the user wants to go back a menu, send him the player list menu (Give Player Crits Menu)
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu  != INVALID_HANDLE)
		{
			DisplayGivePlayerCritsMenu(param1);
		}
	}
	//If the user selected a player, save that player and open a new menu
	else if (action == MenuAction_Select)
	{
		decl String:strOption[32];
		decl String:strTargetPlayersName[64];
		new intOptionID, clnTargetPlayer;
		
		//Get the client of the Target Player
		clnTargetPlayer = g_clnPlayerToGiveCrits;
		
		// Get the Team ID that the user selected
		GetMenuItem(menu, param2, strOption, sizeof(strOption));
		intOptionID = StringToInt(strOption);
		
		// If the player is no longer in this game, we can't do anything
		if (clnTargetPlayer == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		// If the player can not be targeted
		else if (!CanUserTarget(param1, clnTargetPlayer))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		//Change the Target player's team to the Team the user selected
		else
		{
			// Get the name of the Target Player
			GetClientName(clnTargetPlayer, strTargetPlayersName, sizeof(strTargetPlayersName));
			
			//Format a String for the Target Team
			switch( intOptionID )
			{
				case 1:		//Give player normal crits
				{
					g_PlayerCrits[clnTargetPlayer] = enuPlayerCritsType_Normal;
					Format(strOption, sizeof(strOption), "Crit Normally");
				}
				case 2:		//Give player always crits
				{
					g_PlayerCrits[clnTargetPlayer] = enuPlayerCritsType_FullCrits;
					Format(strOption, sizeof(strOption), "Always Crit");
				}
				case 3:		//Give player never crits
				{
					g_PlayerCrits[clnTargetPlayer] = enuPlayerCritsType_NoCrits;
					Format(strOption, sizeof(strOption), "Never Crit");
				}
			}
			
			//Display a notifacation message
			PrintToChatAll("\x01[SM] \x04%s will %s", strTargetPlayersName, strOption);
		}
		
		// Re-draw the menu if they're still valid 
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayGivePlayerCritsMenu(param1);
		}
	}
}

//**********************************************************************************
//* Manage Crit Rates Menu
//**********************************************************************************


//**********************************************************************************
//* Name: Admin Menu _ Manage Crit Rates - Event Handler
//* Abstract: Handles the event for the Manage Crit Rates command
//**********************************************************************************
public AdminMenu_ManageCritRates(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	//If the admin menu wants to know what to display for this menu item
	if (action == TopMenuAction_DisplayOption)
	{
		//Write "Change Player's Team" to the buffer to be displayed
		Format(buffer, maxlength, "Manage Crit Rates", param);
	}
	//If the menu option is selected by the user, display the change teams menu
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayManageCritRatesMenu(param);
	}
}

//**********************************************************************************
//* Name:  Display Manage Crit Rates Menu
//* Abstract: display the menu for manage crit rates
//**********************************************************************************
public DisplayManageCritRatesMenu(client)
{
	// Create the new menu and give it an event handler function name
	new Handle:menu = CreateMenu(MenuHandler_ManageCritRates);
	
	// Make the menu title
	decl String:title[100];
	Format(title, sizeof(title), "Manage Crit Rates");
	
	// Set the title on the menu
	SetMenuTitle(menu, title);
	
	//Set the menu exit buttons to true
	SetMenuExitBackButton(menu, true);
	
	//Add options
	// Enable / Disable Option
	if( g_blnCritManagementEnabled == true )
		AddMenuItem(menu, "1", "Disable Crits Management");
	else
		AddMenuItem(menu, "1", "Enable Crits Management");
		
	// add crit settings
	switch( g_enuCritManagementMode )
	{
		case enuCritManagementMode_FullCrits :
		{
			AddMenuItem(menu, "2", "Always Crits (Current)");
			AddMenuItem(menu, "3", "Never Crits");
			AddMenuItem(menu, "4", "Custom Crit Rate");
		}
		case enuCritManagementMode_NoCrits :
		{
			AddMenuItem(menu, "2", "Always Crits");
			AddMenuItem(menu, "3", "Never Crits (Current)");
			AddMenuItem(menu, "4", "Custom Crit Rate");
		}
		case enuCritManagementMode_Managed :
		{
			AddMenuItem(menu, "2", "Always Crits");
			AddMenuItem(menu, "3", "Never Crits");
			AddMenuItem(menu, "4", "Custom Crit Rate (Current)");
		}
	}

	// Display the menu
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//**********************************************************************************
//* Name:  Menu Handler _ Manage Crit Rates- Event Handler
//* Abstract: Handles the event for selecting a target team for the player
//**********************************************************************************
public MenuHandler_ManageCritRates(Handle:menu, MenuAction:action, param1, param2)
{
	// If the user wants to close the menu, close it
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	//If the user wants to go back a menu, send him the player list menu (Change Teams menu)
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu  != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu , param1, TopMenuPosition_LastCategory);
		}
	}
	//If the user selected a player, save that player and open a new menu
	else if (action == MenuAction_Select)
	{
		decl String:strOption[8];
		new intOptionID;
		
		// Get the Option ID that the user selected
		GetMenuItem(menu, param2, strOption, sizeof(strOption));
		intOptionID = StringToInt(strOption);
			
		// Preform an action based on the option selected
		switch( intOptionID )
		{
			case 1 : ToggleCritManagement();									//Toggle Crit Management
			case 2 : SetCritManagementMode( enuCritManagementMode_FullCrits );	//set the crits mode to full crits
			case 3 : SetCritManagementMode( enuCritManagementMode_NoCrits );	//set the crits mode to no crits
			case 4 : SetCritManagementMode( enuCritManagementMode_Managed );	//set the crits mode to no crits
		}
		
		// Re-draw the menu if they're still valid 
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayManageCritRatesMenu(param1);
		}
	}
}

//**********************************************************************************
//* Name:  ToggleCritManagement
//* Abstract:  toggle the crit management and display the relavent notifacation
//**********************************************************************************
public ToggleCritManagement()
{
	if( g_blnCritManagementEnabled == true )
	{
		//Disable Crits amangement
		g_blnCritManagementEnabled = false;
		PrintToChatAll("\x01[SM] \x04Crit Management Disabled");
	}
	else
	{
		//Enable Crits management
		g_blnCritManagementEnabled = true;
		
		//make a message based on the current management mode
		switch( g_enuCritManagementMode )
		{
			case enuCritManagementMode_FullCrits:
				PrintToChatAll("\x01[SM] \x04Crit Management Enabled: Always Crit");
			case enuCritManagementMode_NoCrits 	:
				PrintToChatAll("\x01[SM] \x04Crit Management Enabled: Never Crit");
			case enuCritManagementMode_Managed 	:
				PrintToChatAll("\x01[SM] \x04Crit Management Enabled: Custom Crit Rate");
		}
	}
}

//**********************************************************************************
//* Name:  SetCritManagementMode
//* Abstract:  set the management mode and display a notifacation if the management is enabled
//**********************************************************************************
public SetCritManagementMode( enuCritManagementModeType:enuNewCritMode )
{
	//set the crits mode to no crits
	g_enuCritManagementMode = enuNewCritMode;
	
	// if management is enabled, display a notifacation message
	if( g_blnCritManagementEnabled == true )
	{
		//make a message based on the current management mode
		switch( g_enuCritManagementMode )
		{
			case enuCritManagementMode_FullCrits:
				PrintToChatAll("\x01[SM] \x04Crit Management Mode Changed to Always Crit");
			case enuCritManagementMode_NoCrits 	:
				PrintToChatAll("\x01[SM] \x04Crit Management Mode Changed to Never Crit");
			case enuCritManagementMode_Managed 	:
				PrintToChatAll("\x01[SM] \x04Crit Management Mode Changed to Custom Crit Rate");
		}
	}
}