//**********************************************************************************
//* Name: UnlimitedAmmo
//* Abstract: gives players unlimited ammo with no reloads 
//*		*NOTE: sniper rifle still reloads, Does not work on sandman, You get 6 Sandviches (yum)
//* Creator: Ghost/Dessix
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
//* Constants
//**********************************************************************************

// aintTFClassWeaponsMaxAmmo holds all the max clip and reserve ammo amounts, 
// it is an ugly hack but with no struct's or class's, its the best i could do and still make it (somewhat) readable
//		*Dimension Legend:	[ Player class] [ weapon slot, 0 = primary ] [ is weapon unlock 0 = standard ] [  max clip = 0, max reserve = 1 ]
static const aintTFClassWeaponsMaxAmmo[TFClassType][3][2][2] =
{	
	 { 
		 { { -1, -1 }, 	{ -1, -1 } }	//Unknown,  used to stay in line with TFClassType, first value is unkown
		,{ { -1, -1 }, 	{ -1, -1 } }	
		,{ { -1, -1 }, 	{ -1, -1 } }	
	 }
	,{ 									//*** Scout ***
		 { { 6, 32 }, 	{ 2, 32 } }		//	ScatterGun, 		Force Of Nature
		,{ { 12, 36 }, 	{ -1, 1 } }		//	Pistol	 			Bonk	
		,{ { -1, -1 }, 	{ 2, -1 } }		//	Bat				Sandman
	 }
	,{									//*** Sniper ***
		 { { -1, 25 },	{ -1, 12 } }	//	Rifle				Huntsman
		,{ { 25, 75 },	{ 2, -1 } }		//	SMG				Jarate		
		,{ { -1, -1 },	{ -1, -1 } }	//	Razorback(no ammo)	Kukuri	 bad hack but i don't feel like fixing it (it works)
	 }
	,{									//*** Soldier ***
		 { { 4, 20 }, 	{ -1, 1 } }		//	Rocket Launcher 		N/A		
		,{ { 6, 32 }, 	{ -1, -1 } }	//	Shotgun			N/A		
		,{ { -1, -1 }, 	{ -1, -1 } }	//	Shovel			N/A	
	 }
	,{									//*** Demoman ***
		 { { 4, 16 },	{ -1, -1 } }	//	Grenade Launcher		N/A
		,{ { 8, 24 },	{ -1, -1 } }	//	Sticky Launcher		N/A
		,{ { -1, -1 },	{ -1, -1 } }	//	Bottle			N/A
	 }
	,{									//*** Medic ***
		 { { 40, 150 },	{ 40, 150 } }	//	Syringe Gun		Blutsauger
		,{ { -1, -1 },	{ -1, -1 } }	//	Medigun			Kritzkrieg
		,{ { -1, -1 },	{ -1, -1 } }	//	Bonesaw			Ubersaw
	 }
	,{									//*** Heavy ***
		 { { -1, 200 },	{ -1, 200 } }	//	Minigun			Natasha
		,{ { 6, 32 },	{ -1, 1 } }		//	Shotgun			Sandvich
		,{ { -1, -1 },	{ -1, -1 } }	//	Fists				KGB
	 }
	,{									//*** Pyro ***
		 { { -1, 200 },	{ -1, 200 } }	//	Flamethrower		Backburner
		,{ { 6, 32 },	{ -1, 16 } }	//	Shotgun 			Flaregun
		,{ { -1, -1 },	{ -1, -1 } }	//	Fireaxe			Axtinguisher
	 }
	,{									//*** Spy ***
		 { { 6, 24 },	{ 6, 24 } }		//	Revolver			Ambassador
		,{ { -1, -1 },	{ -1, -1 } }	//	Sapper			N/A
		,{ { -1, -1 },	{ -1, -1 } }	//	Knife				N/A
	 }
	,{									//*** Engineer ***
		 { { 6, 32 },	{ -1, -1 } }	//	Shotgun			N/A
		,{ { 12, 200 },	{ -1, -1 } }	//	Pistol				N/A
		,{ { -1, 200 },	{ -1, -1 } }	//	Wrench			N/A
	}									// 	wrench ammo = metal
};

//**********************************************************************************
//* User Defined Types
//**********************************************************************************

// player unlimited ammo type
enum enuPlayerAmmoType
{
	 enuPlayerAmmoType_Normal
	,enuPlayerAmmoType_Unlimited
};

//**********************************************************************************
//* Global Variables
//**********************************************************************************

//ammo timer
new Handle:g_tmrGiveAmmo = INVALID_HANDLE;

//player ammo type
new enuPlayerAmmoType:g_enuPlayerAmmo[MAXPLAYERS+1];

// serverwide unlimited ammo
new bool:g_blnAmmoManagementEnabled;

// used in admin menu
new Handle:g_hTopMenu = INVALID_HANDLE;

//**********************************************************************************
//* Name: my info
//* Abstract: basic information about the plugin
//**********************************************************************************
public Plugin:myinfo =
{
	name = "Unlimited Ammo",
	author = "Ghost/Dessix (same thing)",
	description = "Gives a player unlimited ammo",
	version = PLUGIN_VERSION,
	url = "www.3rdoct.org or https://forums.alliedmods.net/forumdisplay.php?f=52"
};

//**********************************************************************************
//* Name: On Plugin Start - Event Handler
//* Abstract: Get the admin menu and set it up
//**********************************************************************************
public OnPluginStart()
{
	//Initialize player statuses
	InitializePlayerList();
	
	// Create Timer for ammo reload
	CreateReloadTimer();
	
	// set the management mode to false by default (may change later to a CVAR)
	g_blnAmmoManagementEnabled = false;
	
	//Cvars
	CreateConVar("sm_unlimitedammo_version", PLUGIN_VERSION, "Unlimited Ammo Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//make config file (will use later if imake more Cvars)
	//AutoExecConfig(true, "plugin.crits_manager");
	
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
//* Abstract: set all the players to have normal ammo management
//**********************************************************************************
public InitializePlayerList()
{
	new intPlayerIndex = 0;

	//go through each player spot and set them to normal ammo type (they get nothing special)
	for (intPlayerIndex = 1; intPlayerIndex <= MAXPLAYERS; intPlayerIndex += 1)
	{
		g_enuPlayerAmmo[intPlayerIndex] = enuPlayerAmmoType_Normal;
	}
	
}

//**********************************************************************************
//* Name: CreateReloadTimer
//* Abstract: create the timer that gives out ammo
//**********************************************************************************
public CreateReloadTimer()
{
	// make sure the timer handle is clean
	if( g_tmrGiveAmmo != INVALID_HANDLE )
	{
		KillTimer(g_tmrGiveAmmo);
		g_tmrGiveAmmo = INVALID_HANDLE;
	}
	
	//create the timer to give out ammo
	g_tmrGiveAmmo = CreateTimer(0.5, g_tmrGiveAmmo_TimerTick, _, TIMER_REPEAT);
}

//**********************************************************************************
//* Name: OnClientDisconnect- Event Handler
//* Abstract: set ammo management to normal on discconnect 
//**********************************************************************************
public OnClientDisconnect(client)
{
	// reset the ammo type when the client discconects, prevents someone else 
	// from joining and getting th e same slot (and potentially unlimited ammo)
	g_enuPlayerAmmo[client] = enuPlayerAmmoType_Normal;
}

//**********************************************************************************
//* Name: OnPluginEnd - Event Handler
//* Abstract: kill the timer on plugin unload
//**********************************************************************************
public OnPluginEnd()
{
	// kill the timer, garbage collection
	if( g_tmrGiveAmmo != INVALID_HANDLE )
	{
		KillTimer(g_tmrGiveAmmo);
		g_tmrGiveAmmo = INVALID_HANDLE;
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
		//new TopMenuObject:tmoServer_Commands = FindTopMenuCategory(g_hTopMenu , ADMINMENU_SERVERCOMMANDS);

		// Add the admin menu option to give client unlimited ammo
		if (tmoPlayer_Commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(g_hTopMenu ,
				"sm_GivePlayerUnlimitedAmmo",
				TopMenuObject_Item,
				AdminMenu_UnlimitedAmmo,
				tmoPlayer_Commands,
				"sm_GivePlayerUnlimitedAmmo",
				ADMFLAG_SLAY);
		}
		
		/*
		// Add the admin menu option  to enable serverwide unlimited ammo
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
		*/
	}
}


//**********************************************************************************
//* Name: g_tmrGiveAmmo_TimerTick
//* Abstract: timer tick event to give ammo to all the players that it is enabled for
//**********************************************************************************
public Action:g_tmrGiveAmmo_TimerTick(Handle:timer)
{
	new intPlayerIndex = 1;
	
	// if the server wide ammo regeneration is disabled, 
	if ( g_blnAmmoManagementEnabled == false )
	{
		//check the individual clients 
		for( intPlayerIndex = 1; intPlayerIndex <= MAXPLAYERS; intPlayerIndex += 1)
		{
			// if the client is set to have unlimited ammo, give it to them
			if( g_enuPlayerAmmo[intPlayerIndex] == enuPlayerAmmoType_Unlimited )
				GiveFullAmmo(intPlayerIndex);
		}
	}
	else
	{	
		// give unlimited ammo to everyone
		for( intPlayerIndex = 1; intPlayerIndex <= MAXPLAYERS; intPlayerIndex += 1)
		{
			GiveFullAmmo(intPlayerIndex);
		}
	}
	
	return Plugin_Continue;
}

//**********************************************************************************
//* Name: GiveFullAmmo
//* Abstract: gives the player full ammo in the weapons clip and in reserve.
//**********************************************************************************
public GiveFullAmmo( clnTarget )
{
	new TFClassType:enuPlayerClass;
	new bool:blnIsUnlockWeapon = false;	
	new intWeaponIndex = 0;
	new aintClipAndReserveAmmo[2];
	
	//Get the players class
	enuPlayerClass = TF2_GetPlayerClass(clnTarget);
	
	//for all the players weapons
	for (intWeaponIndex = 0; intWeaponIndex <= 2; intWeaponIndex += 1)
	{
		//find if the weapon is an unlockable weapon
		blnIsUnlockWeapon = GetIsWeaponAnUnlock( clnTarget, intWeaponIndex );
		
		//get the maximum clip and reserve ammo for the given weapon
		GetMaxWeaponAmmo( enuPlayerClass, intWeaponIndex, blnIsUnlockWeapon, aintClipAndReserveAmmo );
		
		//give full ammo to client
		SendAmmoToClient( clnTarget, intWeaponIndex, aintClipAndReserveAmmo );
	}
}

//**********************************************************************************
//* Name: GetIsWeaponAnUnlock
//* Abstract: return true if the weapon is an unlock. false otherwise
//		*NOTE Sandvich comes up as not being an unlock, its ignored in the main script as 
//			having multiple sandviches does nothing (it throws them all away)
//**********************************************************************************
public bool:GetIsWeaponAnUnlock(client, intWeaponIndex)
{
	new intWeaponEntityIndex = 0;
	new intEntityLevel = 0;
	new bool:blnResult = false;
	
	//get the clients weapon
	intWeaponEntityIndex = GetPlayerWeaponSlot(client, intWeaponIndex);
		
	//get the weapons entity level
	intEntityLevel = GetEntProp(intWeaponEntityIndex, Prop_Send, "m_iEntityLevel");
		
	// if the level of entity is greater than 1, its an unlockable weapon (at least for now)
	if (intEntityLevel > 1)
		blnResult = true;
		
	return blnResult;
}

//**********************************************************************************
//* Name: GetMaxWeaponAmmo
//* Abstract: get the max ammo for the given weapon properties
//**********************************************************************************
public GetMaxWeaponAmmo( TFClassType:enuPlayerClass, intWeaponIndex, bool:blnIsUnlockWeapon, aintClipAndReserveAmmo[2] )
{
	new intAlternateWeapon = 0;
	
	// if the weapon is an unlock, grab the unlocked weapons values
	if( blnIsUnlockWeapon == true )
		intAlternateWeapon = 1;
	else
		intAlternateWeapon = 0;
	
	//get the max clip size and reserve ammo, position 0 is max clip, position 1 is max reserve
	aintClipAndReserveAmmo[0] = aintTFClassWeaponsMaxAmmo[enuPlayerClass][intWeaponIndex][intAlternateWeapon][0];
	aintClipAndReserveAmmo[1] = aintTFClassWeaponsMaxAmmo[enuPlayerClass][intWeaponIndex][intAlternateWeapon][1];
}

//**********************************************************************************
//* Name: SendAmmoToClient
//* Abstract: give the cleint the given amount of ammo in the given weapon slot
//**********************************************************************************
public SendAmmoToClient(clnTarget, intWeaponIndex, aintClipAndReserveAmmo[] )
{
	new intOffset = 0;
	
	// reload weapons clip if possible
	if ( aintClipAndReserveAmmo[0] != -1)
	{
		//find the absolute offset for the weapons clip ammo in the class CTFWeaponBase
		intOffset = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
			
		//give the players weapon clip max ammo
		SetEntData(GetPlayerWeaponSlot(clnTarget, intWeaponIndex), intOffset, aintClipAndReserveAmmo[0]);
	}
	
	// reload reserve ammo if possible
	if (aintClipAndReserveAmmo[1] != -1)
	{
		//find the absolute offset for the players ammo in the class CTFPlayer offset 4 = primary, 8 = secondary, 12 = melee
		intOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo") + ( ( intWeaponIndex + 1 ) * 4);
			
		//give the client max ammo
		SetEntData(clnTarget, intOffset, aintClipAndReserveAmmo[1]);
	}
}

//**********************************************************************************
//* Name: Admin Menu _ Unlimited Ammo - Event Handler
//* Abstract: Handles the event for the Unlimited Ammo command
//**********************************************************************************
public AdminMenu_UnlimitedAmmo(Handle:topmenu, 
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
		Format(buffer, maxlength, "Unlimited Ammo", param);
	}
	//If the menu option is selected by the user, display the Unlimited Ammo menu
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayUnlimitedAmmoMenu(param);
	}
}

//**********************************************************************************
//* Name: Display Unlimited Ammo Menu
//* Abstract: create the Unlimited Ammo menu and display it
//**********************************************************************************
public DisplayUnlimitedAmmoMenu(client)
{
	// Create the new menu and give it an event handler function name
	new Handle:menu = CreateMenu(MenuHandler_UnlimitedAmmo);
	
	// make a title
	decl String:title[100];
	Format(title, sizeof(title), "Unlimited Ammo");
	
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
//* Name:  Menu Handler _ Unlimited Ammo - Event Handler
//* Abstract: Handles the event for selecting a player to toggle Unlimited Ammo on
//**********************************************************************************
public MenuHandler_UnlimitedAmmo(Handle:menu, MenuAction:action, param1, param2)
{
	// If the user wants to close the menu, close it
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	//If the user wants to go back a menu, send him the top menu
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu  != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu , param1, TopMenuPosition_LastCategory);
		}
	}
	//If the user selected a player, toggle Unlimited Ammo on that player
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
		else if (!CanUserTarget(param1, clnTargetPlayer))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		// toggle Unlimited Ammo on the player
		else
		{
			// if th eplayer has unlimited ammo, take it away,
			if( g_enuPlayerAmmo[clnTargetPlayer] == enuPlayerAmmoType_Unlimited )
			{
				g_enuPlayerAmmo[clnTargetPlayer] = enuPlayerAmmoType_Normal;
				PrintToChatAll("\x01[SM] \x04%N has lost Unlimited Ammo", clnTargetPlayer);
			}
			//give player unlimited ammo
			else
			{
				g_enuPlayerAmmo[clnTargetPlayer] = enuPlayerAmmoType_Unlimited;
				PrintToChatAll("\x01[SM] \x04%N has Unlimited Ammo", clnTargetPlayer);
			}
		}
		
		// Re-draw the menu if they're still valid 
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayUnlimitedAmmoMenu(param1);
		}
	}
}