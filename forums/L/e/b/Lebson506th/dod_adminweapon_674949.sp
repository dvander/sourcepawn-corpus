/*
*	DoD:S Admin Weapons
*	By Lebson506th
*
*	Description
*	-----------
*
*	This plugin was inspired by a plugin I saw for DoD:S a long time ago.
*	Don't remeber what it was called or who it was by, and I couldn't find it. So I made this one.
*
*	This plugin allows admins with the "t" (ADMFLAG_CUSTOM6) flag to get
*	any weapon in the game. Automatically gives full ammo for the weapon
*	selected including rifle grenades for the Garand and K98.
*
*	This plugin also allows admins to give any weapon to any player, or
*	let any player decide which weapon they want. It also allows admin to
*	remove 1 or all of any player's weapons.
*
*	The only limitation right now is that the user can only get 1 of each
*	thrown grenade at a time. However, because it is possible to get the
*	grenades of the other team as well, you can get a total of 2 of each. 
*	(IE, US and German frag grenade = 2 frag grenades total)
*
*	Usage
*	-----
*	
*	sm_weapon - Brings up the menu that allows admin to get any weapon.
*	sm_weapon "Name" - Brings up the menu on the named client's side that allows them to choose the weapon they want.
*	sm_giveweapon "Name" - Brings up the menu that allows admin to choose which weapon to give a player.
*	sm_removeweapons "Name" - Removes all weapons from a given player.
*	sm_removeweapon "Name" <slot# (0-3)> - Removes a weapon from the given slot from a given player. 
*
*	Change Log
*	----------
*
*	5/2/2011 - v0.4
*	- Fixed translations potentially acting weirdly.
*
*	11/1/2008 - v0.3
*	- Added translations.
*	- Added commands to admin menu by default.
*	- Fixed a bug when removing weapons that could cause server crashes after a while.
*
*	8/24/2008 - v0.2
*	- Added sm_removeweapons "Name" that strips a player of all of their weapons.
*	- Added sm_giveweapon "Name"  that lets an admin choose what weapon to give to a player.
*	- Added sm_weapon "Name" that opens the weapon menu on the given player so they can choose.
*	- Added sm_removeweapon "Name" <slot# (0-3)> that removes the weapon in the given slot of the given player.
*
*	8/24/2008 - v0.1
*	- Initial release
*/

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1

#define PLUGIN_VERSION "0.4"
#define WEAPONNUM 25

new	Handle:hAdminMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "DoD:S Admin Weapons",
	author = "Lebson506th",
	description = "Allows admins with the t flag to get and give any weapon they want.",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net/"
};

#define WEAPON 0
#define WEAPONNAME 1
#define GIVEWEAPON 2
#define REMOVEWEAPON 3
#define REMOVEWEAPONS 4

new Handle:g_CvarEnabled;

new PlayerAction[MAXPLAYERS + 1] = {-1, ...};
new PlayerTarget[MAXPLAYERS + 1] = {-1, ...};

new String:WeaponName[WEAPONNUM][] = {
	"",
	"weapon_spade", "weapon_amerknife",
	"weapon_c96", "weapon_p38", "weapon_colt",
	"weapon_bar", "weapon_thompson", "weapon_m1carbine", "weapon_mp40", "weapon_mp44",
	"weapon_bazooka", "weapon_pschreck", "weapon_garand", "weapon_k98", "weapon_k98_scoped",
	"weapon_spring", "weapon_mg42", "weapon_30cal",
	"weapon_frag_ger", "weapon_frag_us",
	"weapon_smoke_ger", "weapon_smoke_us",
	"weapon_riflegren_us", "weapon_riflegren_ger"
};

new WeaponAmmo[WEAPONNUM] = {
	0,
	0, 0,
	20, 8, 7,
	20, 30, 15, 30, 30,
	1, 1, 8, 5, 5,
	5, 250, 150,
	1, 1,
	1, 1,
	1, 1
};

new WeaponClips[WEAPONNUM] = {
	0,
	0, 0,
	2, 2, 2,
	12, 6, 4, 7, 8,
	4, 4, 9, 12, 12,
	10, 1, 2,
	0, 0,
	0, 0,
	1, 1
};

static const g_ammoOffset[WEAPONNUM] = {
	0,
	0, 0,
	12, 8, 4,
	36, 32, 24, 32, 32,
	48, 48, 16, 20, 20,
	28, 44, 40,
	56, 52,
	72, 68,
	84, 88
};

new Target[MAXPLAYERS + 1] = {0, ...};

public OnPluginStart() {
	LoadTranslations("adminweapon.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_adminweapon_version", PLUGIN_VERSION, "DoD One Weapon Mod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnabled = CreateConVar("sm_weapon_enabled", "1", "Enables(1) and disables(0) the DoD Admin Weapon plugin");

	RegAdminCmd("sm_weapon", AdminWeapon, ADMFLAG_CUSTOM6, "Brings up the menu that allows admin to get any weapon.");
	RegAdminCmd("sm_giveweapon", GiveWeapon, ADMFLAG_CUSTOM6, "Brings up the menu that allows admin to give any weapon to a player.");
	RegAdminCmd("sm_removeweapons", RemoveAll, ADMFLAG_CUSTOM6, "Removes all weapons from a given player.");
	RegAdminCmd("sm_removeweapon", Remove, ADMFLAG_CUSTOM6, "Removes a weapon from the given slot from a given player. sm_removeweapon <name> <slot# (0-3)>");
}

/*
	sm_weapon handler to open a menu on a given client.
	Player "Name" or the client calling if there is no "Name"
*/

public Action:AdminWeapon(client, args) {
	new target;

	if (args == 1) {
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		target = FindTarget(client, arg, false, false);

		if (!target) {
			ReplyToCommand(client, "[DoD Admin Weapons] %T", "Could Not Find Name", client, arg);
			return Plugin_Handled;
		}
	}
	else
		target = client;

	Weapon_Menu(target);
	return Plugin_Handled;
}

/*
	sm_giveweapon handler to open a menu on the admin client to give
	Player "Name" a weapon.
*/

public Action:GiveWeapon(client, args) {
	new target;

	if (args == 1) {
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		target = FindTarget(client, arg, false, false);

		if (!target) {
			ReplyToCommand(client, "[DoD Admin Weapons] %T", "Could Not Find Name", client, arg);
			return Plugin_Handled;
		}
	}
	else {
		ReplyToCommand(client, "[DoD Admin Weapons] %T", "Usage Giveweapons", client);
		return Plugin_Handled;
	}

	Target[client] = target;
	Weapon_Menu(client);
	return Plugin_Handled;
}

/*
	sm_removeweapons handler that removes all weapons of a given client.
*/

public Action:RemoveAll(client, args) {
	new target;

	if (args == 1) {
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		target = FindTarget(client, arg, false, false);

		if (!target) {
			ReplyToCommand(client, "[DoD Admin Weapons] %T", "Could Not Find Name", client, arg);
			return Plugin_Handled;
		}
	}
	else {
		ReplyToCommand(client, "[DoD Admin Weapons] %T", "Usage Removeweapons", client);
		return Plugin_Handled;
	}

	for(new i = 0; i < 4; i++)
		StripWeapon(target, i);

	return Plugin_Handled;
}

/*
	sm_removeweapon that removes a given weapon slot of a given client.
*/

public Action:Remove(client, args) {
	new target;
	new slot;

	if (args == 2) {
		decl String:arg[MAX_NAME_LENGTH];
		decl String:arg2[32];
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(1, arg, sizeof(arg));
		slot = StringToInt(arg2);

		target = FindTarget(client, arg, false, false);

		if (!target) {
			ReplyToCommand(client, "[DoD Admin Weapons] %T", "Could Not Find Name", client, arg);
			return Plugin_Handled;
		}

		if(slot < 0 || slot > 3) {
			ReplyToCommand(client, "[DoD Admin Weapons] %T", "Usage Removeweapon", client);
			return Plugin_Handled;
		}
	}
	else {
		ReplyToCommand(client, "[DoD Admin Weapons] %T", "Usage Removeweapon", client);
		return Plugin_Handled;
	}


	StripWeapon(target, slot);

	return Plugin_Handled;
}

/*
	Admin menu integration
*/

public OnLibraryRemoved(const String:name[]) {
	if( StrEqual( name, "adminmenu" ) ) {
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady( Handle:topmenu ) {
	if( topmenu == hAdminMenu ) {
		return;
	}

	hAdminMenu = topmenu;

	new TopMenuObject:menu_category = AddToTopMenu(
		hAdminMenu,				// Menu
		"dod_aw_commands",		// Name
		TopMenuObject_Category,	// Type
		Handle_Category,		// Callback
		INVALID_TOPMENUOBJECT	// Parent
	);

	if( menu_category == INVALID_TOPMENUOBJECT )
		return;

	AddToTopMenu(
		hAdminMenu,			// Menu
		"sm_weapon",		// Name
		TopMenuObject_Item,	// Type
		Handle_Weapon,		// Callback
		menu_category,		// Parent
		"sm_weapon",		// cmdName
		ADMFLAG_CUSTOM6		// Admin flag
	);

	AddToTopMenu(
		hAdminMenu,			// Menu
		"sm_weaponname",	// Name
		TopMenuObject_Item,	// Type
		Handle_WeaponName,	// Callback
		menu_category,		// Parent
		"sm_weapon",		// cmdName
		ADMFLAG_CUSTOM6		// Admin flag
	);

	AddToTopMenu(
		hAdminMenu,			// Menu
		"sm_giveweapon",	// Name
		TopMenuObject_Item,	// Type
		Handle_GiveWeapon,	// Callback
		menu_category,		// Parent
		"sm_giveweapon",	// cmdName
		ADMFLAG_CUSTOM6		// Admin flag
	);
	

	AddToTopMenu(
		hAdminMenu,				// Menu
		"sm_removeweapon",		// Name
		TopMenuObject_Item,		// Type
		Handle_RemoveWeapon,	// Callback
		menu_category,			// Parent
		"sm_removeweapon",		// cmdName
		ADMFLAG_CUSTOM6			// Admin flag
	);
	
	AddToTopMenu(
		hAdminMenu,				// Menu
		"sm_removeweapons",		// Name
		TopMenuObject_Item,		// Type
		Handle_RemoveWeapons,	// Callback
		menu_category,			// Parent
		"sm_removeweapons",		// cmdName
		ADMFLAG_CUSTOM6			// Admin flag
	);
	
}

public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ) {
	if(action == TopMenuAction_DisplayTitle)
		Format( buffer, maxlength, "%T", "Which Command", param );
	if(action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "DoD:S Admin Weapons", param );
}

public Handle_Weapon( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ) {
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "%T", "Weapon", param );
	else if( action == TopMenuAction_SelectOption)
		ClientCommand(param, "sm_weapon");
}

public Handle_WeaponName( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ) {
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "%T", "Weapon Name", param );
	else if( action == TopMenuAction_SelectOption)
		SelectPlayers( param, WEAPONNAME );
}

public Handle_GiveWeapon( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ) {
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "%T", "Give Weapon", param );
	else if( action == TopMenuAction_SelectOption)
		SelectPlayers( param, GIVEWEAPON );
}

public Handle_RemoveWeapon( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ) {
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "%T", "Remove Weapon", param );
	else if( action == TopMenuAction_SelectOption)
		SelectPlayers( param, REMOVEWEAPON );
}

public Handle_RemoveWeapons( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ) {
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "%T", "Remove Weapons", param );
	else if( action == TopMenuAction_SelectOption)
		SelectPlayers( param, REMOVEWEAPONS );
}

public SelectPlayers ( client, commandType ) {
	if(client < 0 || !IsClientInGame(client))
		return;

	new Handle:playerSelectMenu = CreateMenu(Command_Handler);

	PlayerAction[client] = commandType;

	SetMenuTitle(playerSelectMenu, "%T", "Select Player", client);
	SetMenuExitButton(playerSelectMenu, true);

	AddTargetsToMenu(playerSelectMenu, client, true, true);
	DisplayMenu(playerSelectMenu, client, MENU_TIME_FOREVER);
}

public Command_Handler( Handle:playerMenu, MenuAction:action, param1, param2 ) {
	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select) {
		decl String:info[32];
		new userid, target;

		GetMenuItem(playerMenu, param2, info, sizeof(info));

		userid = StringToInt(info);
		target = GetClientOfUserId(userid);

		if ( (target <= 0) || !IsClientInGame(target) )
			PrintToChat(param1, "[DoD Admin Weapon] %T", "Could Not Find", param1);
		else {
			new actionType = PlayerAction[param1];
			new String:name[32];
			GetClientName(target, name, 31);

			PlayerAction[param1] = -1;

			switch(actionType) {
				case WEAPONNAME:
					ClientCommand(param1, "sm_weapon \"%s\"", name);
				case GIVEWEAPON:
					ClientCommand(param1, "sm_giveweapon \"%s\"", name);
				case REMOVEWEAPON:
					RemoveWeaponMenu(param1, target);
				case REMOVEWEAPONS:
					ClientCommand(param1, "sm_removeweapons \"%s\"", name);
			}
		}
	}
	else
		CloseHandle(playerMenu);
}

public RemoveWeaponMenu(client, target) {
	new Handle:slotMenu = CreateMenu(RemoveWeaponHandler);
	new String:first[32], String:second[32], String:third[32], String:fourth[32];

	PlayerTarget[client] = target;

	SetMenuTitle(slotMenu, "%T", "Select Slot", client);
	SetMenuExitBackButton(slotMenu, true);

	Format(first, 31, "%T", "First", client);
	Format(second, 31, "%T", "Second", client);
	Format(third, 31, "%T", "Third", client);
	Format(fourth, 31, "%T", "Fourth", client);

	AddMenuItem(slotMenu, "first", first);
	AddMenuItem(slotMenu, "second", second);
	AddMenuItem(slotMenu, "third", third);
	AddMenuItem(slotMenu, "fourth", fourth);

	DisplayMenu(slotMenu, client, MENU_TIME_FOREVER);
}

public RemoveWeaponHandler( Handle:slotMenu, MenuAction:action, param1, param2 ) {
	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select) {
		decl String:info[32];
		new target;

		GetMenuItem(slotMenu, param2, info, sizeof(info));
		target = PlayerTarget[param1];
		PlayerTarget[param1] = -1;

		if ( (target <= 0) || !IsClientInGame(target) )
			PrintToChat(param1, "[DoD Admin Weapon] %T", "Could Not Find", param1);
		else {
			new String:name[32];
			GetClientName(target, name, 31);

			if( strcmp(info, "first") == 0 )
				ClientCommand(param1, "sm_removeweapon \"%s\" %i", name, 0);
			else if( strcmp(info, "second") == 0 )
				ClientCommand(param1, "sm_removeweapon \"%s\" %i", name, 1);
			else if( strcmp(info, "third") == 0 )
				ClientCommand(param1, "sm_removeweapon \"%s\" %i", name, 2);
			else if( strcmp(info, "fourth") == 0 )
				ClientCommand(param1, "sm_removeweapon \"%s\" %i", name, 3);
		}
	}
	else
		CloseHandle(slotMenu);
}

/*
	Weapon selection menu creation
*/

public Weapon_Menu(client) {
	if(GetConVarBool(g_CvarEnabled)) {
		new Handle:menu = CreateMenu(Weapon_Menu_handler);
		SetMenuTitle(menu, "%T", "MenuTitle", client);

		AddMenuItem(menu, "spade", "Spade");
		AddMenuItem(menu, "amerknife", "American Knife");
		AddMenuItem(menu, "c96", "C96");
		AddMenuItem(menu, "p38", "P38");
		AddMenuItem(menu, "colt", "Colt");
		AddMenuItem(menu, "bar", "Bar");
		AddMenuItem(menu, "thompson", "Thompson");
		AddMenuItem(menu, "m1carbine", "M1 Carbine");
		AddMenuItem(menu, "mp40", "MP 40");
		AddMenuItem(menu, "mp44", "MP 44");
		AddMenuItem(menu, "bazooka", "Bazooka");
		AddMenuItem(menu, "pschreck", "Panzerschreck");
		AddMenuItem(menu, "garand", "Garand");
		AddMenuItem(menu, "k98", "K98");
		AddMenuItem(menu, "k98_scoped", "Scoped K98");
		AddMenuItem(menu, "spring", "Springfield");
		AddMenuItem(menu, "mg42", "MG42");
		AddMenuItem(menu, "30cal", "30 cal.");
		AddMenuItem(menu, "frag_ger", "German Grenades");
		AddMenuItem(menu, "frag_us", "US Grenades");
		AddMenuItem(menu, "smoke_ger", "German Smoke Grenades");
		AddMenuItem(menu, "smoke_us", "US Smoke Grenades");

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

/*
	Handles giving selected client the selected weapon.
*/

public Weapon_Menu_handler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:info[32];
		new target = Target[param1];
		GetMenuItem(menu, param2, info, sizeof(info));

		if(target == 0)
			target = param1;
		else
			Target[param1] = 0;

		if(strcmp(info,"spade") == 0) {
			GivePlayerItem(target, WeaponName[1]);
		}
		else if(strcmp(info,"amerknife") == 0) {
			GivePlayerItem(target, WeaponName[2]);
		}
		else if(strcmp(info,"c96") == 0) {
			StripWeapon(target, 1);
			GivePlayerItem(target, WeaponName[3]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[3], WeaponAmmo[3] * WeaponClips[3], 4, true);
		}
		else if(strcmp(info,"p38") == 0) {
			StripWeapon(target, 1);
			GivePlayerItem(target, WeaponName[4]);
			SetEntData(target,FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[4], WeaponAmmo[4] * WeaponClips[4], 4, true);
		}
		else if(strcmp(info,"colt") == 0) {
			StripWeapon(target, 1);
			GivePlayerItem(target, WeaponName[5]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[5], WeaponAmmo[5] * WeaponClips[5], 4, true);
		}
		else if(strcmp(info,"bar") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[6]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[6], WeaponAmmo[6] * WeaponClips[6], 4, true);
		}
		else if(strcmp(info,"thompson") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[7]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[7], WeaponAmmo[7] * WeaponClips[7], 4, true);
		}
		else if(strcmp(info,"m1carbine") == 0) {
			StripWeapon(target, 1);
			GivePlayerItem(target, WeaponName[8]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[8], WeaponAmmo[8] * WeaponClips[8], 4, true);
		}
		else if(strcmp(info,"mp40") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[9]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[9], WeaponAmmo[9] * WeaponClips[9], 4, true);
		}
		else if(strcmp(info,"mp44") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[10]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[10], WeaponAmmo[10] * WeaponClips[10], 4, true);
		}
		else if(strcmp(info,"bazooka") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[11]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[11], WeaponAmmo[11] * WeaponClips[11], 4, true);
		}
		else if(strcmp(info,"pschreck") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[12]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[12], WeaponAmmo[12] * WeaponClips[12], 4, true);
		}
		else if(strcmp(info,"garand") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[13]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[13], WeaponAmmo[13] * WeaponClips[13], 4, true);
			GivePlayerItem(target, WeaponName[23]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[23], WeaponAmmo[23] * WeaponClips[23], 4, true);
		}
		else if(strcmp(info,"k98") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[14]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[14], WeaponAmmo[14] * WeaponClips[14], 4, true);
			GivePlayerItem(target, WeaponName[24]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[24], WeaponAmmo[24] * WeaponClips[24], 4, true);
		}
		else if(strcmp(info,"k98_scoped") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[15]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[15], WeaponAmmo[15] * WeaponClips[15], 4, true);
		}
		else if(strcmp(info,"spring") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[16]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[16], WeaponAmmo[16] * WeaponClips[16], 4, true);
		}
		else if(strcmp(info,"mg42") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[17]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[17], WeaponAmmo[17] * WeaponClips[17], 4, true);
		}
		else if(strcmp(info,"30cal") == 0) {
			StripWeapon(target, 0);
			GivePlayerItem(target, WeaponName[18]);
			SetEntData(target, FindSendPropOffs("CDODPlayer", "m_iAmmo") + g_ammoOffset[18], WeaponAmmo[18] * WeaponClips[18], 4, true);
		}
		else if(strcmp(info,"frag_ger") == 0)
			GivePlayerItem(target, WeaponName[19]);
		else if(strcmp(info,"frag_us") == 0)
			GivePlayerItem(target, WeaponName[20]);
		else if(strcmp(info,"smoke_ger") == 0)
			GivePlayerItem(target, WeaponName[21]);
		else if(strcmp(info,"smoke_us") == 0)
			GivePlayerItem(target, WeaponName[22]);
	} 
	if (action == MenuAction_End)
		CloseHandle(menu);
}

/*
	Helper method to strip a given player "client"'s slot "i"
*/

public StripWeapon(client, i) {
	new ent = GetPlayerWeaponSlot(client, i);

	if(ent != -1) {
		RemovePlayerItem(client, ent);
		RemoveEdict(ent);
	}
}