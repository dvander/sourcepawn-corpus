/*
	ABSMapHack
	Austinbots!

	Spawns items into CS:GO maps and creates Stripper config files for them.
	
	Best viewed with tab size = 2	

	Requires Metamod:Source, Sourcemod, SDKHooks, Stripper
	
	--------------------------------------------------------------
	This plugin lets you add weapons and spawn points into CS:GO maps.
	The items are added directy to the map and also written to a Stripper 
	config file so the next time the map loads the items will be persisted.

	There is one command "add" with the following syntax.
	The only required parameter is the item to add.
	add item ammo notes

	If ammo is left off or set to 0 you will get default ammo for added weapons.
	notes if entered will be added to the striper config file as a comment.

	Examples:
	Add an ak47 with default ammo where you are standing.
	add ak47

	Add an ak47 with default ammo with a note for the Stripper file.
	(You only need quotes around the notes if they contain a space).
	add ak47 0 "ak47 with deafult ammo at first t spawn."

	Add an ak47 with 500 rounds.
	add ak47 500

	--------------------------------------------------------------
	List of all items you can add.

	---- Grenades ------------------------------------------------
	smoke, flash, he, molo, inc, decoy

	---- Pistols -------------------------------------------------
	glock, p250, fiveseven, deagle, elite, p2000, tec9, taser

	---- Shotguns ------------------------------------------------
	sawedoff, nova, xm1014, mag7

	---- Sub Machine Guns ----------------------------------------
	mp9, mac10, mp7, ump45, p90, bizon

	---- Machine Guns --------------------------------------------
	m249, negev

	---- Rifles --------------------------------------------------
	famas, galilar, m4a1, ak47, aug, sg556

	---- Sniper Rifles -------------------------------------------
	ssg08, g3sg1, scar20, awp

	---- Ammo ----------------------------------------------------
	338mag, 357sig, 45acp, 50ae, 556mm, 57mm, 762mm, 9mm, buckshot

	---- Spawn Points --------------------------------------------
	ct, t

--------------------------------------------------------------
Changelog
--------------------------------------------------------------
2012-08-30 (v1.0)
        * Initial release.
				
2012-09-03 (v1.1)
				* Fixed a problem where you could specify custom ammo on items that do not take ammo
				* added #pragma semicolon 1 and fixed a few places where they were missing

-------------------------------------------------------------
				
Installation instructions
        place the SMX in the plugins folder and you're done"

Dependencies
	This plugin requires Metamod:Source, Sourcemod, SDKHooks, Stripper
	You need the latest version of everything to run on CSGO.
	
	Download them here:
	http://www.sourcemm.net/snapshots
	http://www.sourcemod.net/snapshots.php
	http://users.alliedmods.net/~psychonic/builds/sdkhooks/2.2/
	http://www.bailopan.net/stripper/snapshots/1.2/

	This was only tested on a Windows dedicated server running the latest of 
	everything from the above links.
	
Errata	 
	This works from the console
	add ak47 300 "ak with 300 rounds"
	
	But the same command from chat doesn't work because of the quotes.
	!add ak47 300 "ak with 300 rounds"
		
Plans
	Add in an option to add exploding barrels.
	Add the ability to remove items by pointing at them to select them.
	
***************************************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new String:weapon[80];
new String:itemToCreate[40]; 	
new String:ammo[50];
	
#define VERSION "1.1"

public Plugin:myinfo =
{
	name = "MapHack",
	author = "Austinbots",
	description = "Add Items to CS GO Maps.",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{
	decl String:game[100];
	GetGameDescription(game, sizeof(game));
	if (!StrEqual(game, "Counter-Strike: Global Offensive", false))
		SetFailState("This plugin only runs on Counter-Strike: Global Offensive.");

	RegAdminCmd("add", Command_Add, ADMFLAG_GENERIC, "Spawn weapon where you are standing.");

	PrintToServer("MapHack Loaded - Version: %s - Type \"add help\" for more information.", VERSION);
}

//---------------------------------------------------------------------------
// Add(client, args)
//
// Spawn the item directly into the map now and
// write the item to a stripper config file so the 
// next time the map is loadded the item will always be there
//---------------------------------------------------------------------------
public Action:Command_Add(client, args)
{
	new String:notes[128]; 
	new Float:g_SpawnOrigins[3];
	new Float:g_SpawnAngles[3];	
	new String:customAmmo[50];
	
	if (client == 0)
	{
		PrintToServer("This plugin only runs on a client connected to a server.");
		return Plugin_Handled;
	}
	
	// The add command takes 1 to 3 parms
	if (args < 1 || args > 3)
	{
		PrintToChat(client, "Try: add help");
		return Plugin_Handled;
	}

	if(args >= 1) GetCmdArg(1, itemToCreate,	sizeof(itemToCreate));
	if(args >= 2) GetCmdArg(2, customAmmo,		sizeof(customAmmo));
	if(args >= 3) GetCmdArg(3, notes,					sizeof(notes));
	
	if (StrEqual(itemToCreate, "help", false))
	{
		ShowHelp(client);
		return Plugin_Handled;
	}

	// Get the real entity name and default ammo
	if (GetItem(client) == 1)
		return Plugin_Handled;

	// If custom ammo was entered with the add command use it instead of the default
	// but also, if ammo returns from GetItem() == 0 then this is an item that doesn't 
	// have ammo. Ignore any ammo value they may have entered for it in this case.
	if(
		!StrEqual(customAmmo, "", false)  && 
		!StrEqual(customAmmo, "0", false) &&
		!StrEqual(ammo, "0", false)   
		)
	{
		ammo = customAmmo;
	}
	
	// spawn the item into the map right now
	new inewEntity = CreateEntityByName(weapon);
	if(IsValidEntity(inewEntity))
	{		
		//PrintToChat(client, "You spawned: %s", itemToCreate)
		if (!StrEqual(ammo, "0", false))
			DispatchKeyValue(inewEntity, "ammo", ammo);
		DispatchSpawn(inewEntity); 
			
		//Teleport spawned item to where we are standing and facing
		GetClientAbsOrigin(client, g_SpawnOrigins);
		GetClientAbsAngles(client, g_SpawnAngles);
		TeleportEntity(inewEntity, g_SpawnOrigins, NULL_VECTOR, NULL_VECTOR); 

		// write this item to the stripper file
		new String:map[64];
		GetCurrentMap(map, sizeof(map));
		
		new String:path[255];
		Format(path, sizeof(path), "addons/stripper/maps/%s.cfg", map);
		
		new Handle:file = OpenFile(path, "a");
		if (file == INVALID_HANDLE)
		{
			LogError("Could not open Stripper config file \"%s\" for writing.", path);
			return Plugin_Handled;
		}	
		
		// if they entered notes as the 3rd parameter 
		// write them out as a comment in the stripper file
		if(!StrEqual(notes, "", false))
			WriteFileLine(file, ";%s", notes);

		WriteFileLine(file, "add:");
		WriteFileLine(file, "{");
		
		WriteFileLine(file, "\"origin\" \"%1.1f %1.1f %1.1f\"", 
		g_SpawnOrigins[0],
		g_SpawnOrigins[1],
		g_SpawnOrigins[2]);
		
		WriteFileLine(file, "\"angles\" \"%1.1f %1.1f %1.1f\"",
		g_SpawnAngles[0],
		g_SpawnAngles[1],
		g_SpawnAngles[2]);
				
		if(!StrEqual(ammo, "", false) && !StrEqual(ammo, "0", false))
			WriteFileLine(file, "\"ammo\" \"%s\"", ammo);
		
		WriteFileLine(file, "\"classname\" \"%s\"", weapon);
			
		WriteFileLine(file, "}");

		CloseHandle(file);
		PrintToChat(client, "Item saved to Stripper file: %s", weapon);
	}
	else
	{
		PrintToChat(client, "Item not recognized: %s", weapon);
	}
	return Plugin_Handled;
}

//---------------------------------------------------------------------------
//	ShowHelp(client)
//---------------------------------------------------------------------------
ShowHelp(client)
{
	PrintToChat(client, "Open your console to see a list of items that can be added.");

	PrintToConsole(client, "--------------------------------------------------------------");
	PrintToConsole(client, "This plugs in adds items to CSGO maps using Stripper.\n");
	
	PrintToConsole(client, "There is one command \"add\" with the following syntax:");
	PrintToConsole(client, "The only required parameter is the item to add.");
	PrintToConsole(client, "add item ammo notes\n");

	PrintToConsole(client, "If ammo is left off or set to 0 you will get default ammo for added weapons.");
	PrintToConsole(client, "notes if entered will be added to the striper config file as a comment.\n");
	
	PrintToConsole(client, "Examples:");
	PrintToConsole(client, "Add an ak47 with default ammo where you are standing.");
	PrintToConsole(client, "add ak47\n");

	PrintToConsole(client, "Add an ak47 with default ammo with a note for the Stripper file.");
	PrintToConsole(client, "(You only need quotes around the notes if they contain a space).");
	PrintToConsole(client, "add ak47 0 \"\ak47 with deafult ammo at first t spawn.\"\n");
	
	PrintToConsole(client, "Add an ak47 with 500 rounds.");
	PrintToConsole(client, "add ak47 500\n");
	
	PrintToConsole(client, "--------------------------------------------------------------");
	PrintToConsole(client, "List of all items you can add.\n");
	
	PrintToConsole(client, "---- Grenades ------------------------------------------------");
	PrintToConsole(client, "smoke, flash, he, molo, inc, decoy\n");

	PrintToConsole(client, "---- Pistols -------------------------------------------------");
	PrintToConsole(client, "glock, p250, fiveseven, deagle, elite, p2000, tec9, taser\n");

	PrintToConsole(client, "---- Shotguns ------------------------------------------------");
	PrintToConsole(client, "sawedoff, nova, xm1014, mag7\n");

	PrintToConsole(client, "---- Sub Machine Guns ----------------------------------------");	
	PrintToConsole(client, "mp9, mac10, mp7, ump45, p90, bizon\n");
	
	PrintToConsole(client, "---- Machine Guns --------------------------------------------");
	PrintToConsole(client, "m249, negev\n");
	
	PrintToConsole(client, "---- Rifles --------------------------------------------------");
	PrintToConsole(client, "famas, galilar, m4a1, ak47, aug, sg556\n");
	
	PrintToConsole(client, "---- Sniper Rifles -------------------------------------------");
	PrintToConsole(client, "ssg08, g3sg1, scar20, awp\n");
	
	PrintToConsole(client, "---- Ammo ----------------------------------------------------");
	PrintToConsole(client, "338mag, 357sig, 45acp, 50ae, 556mm, 57mm, 762mm, 9mm, buckshot\n");

	PrintToConsole(client, "---- Spawn Points --------------------------------------------");
	PrintToConsole(client, "ct, t\n");
}

//---------------------------------------------------------------------------
//	GetItem(client)
//
//	Return the actual entity names from the shortened easy to remember names. 
//	Sets per weapon default ammo
//---------------------------------------------------------------------------
GetItem(client)
{
	//---- Grenades ------------------------------------------------
	if (strcmp(itemToCreate, "smoke") == 0)
	{
		weapon = "weapon_smokegrenade";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "flash") == 0)
	{
		weapon = "weapon_flashbang";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "he") == 0)
	{
		weapon = "weapon_hegrenade";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "molo") == 0)
	{
		weapon = "weapon_molotov";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "inc") == 0)
	{
		weapon = "weapon_incgrenade";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "decoy") == 0)
	{
		weapon = "weapon_decoy";
		ammo = "0";
	}
	
	// --- Pistols -------------------------------------------------
	else if (strcmp(itemToCreate, "glock") == 0)
	{
		weapon = "weapon_glock";
		ammo = "120";
	}
	else if (strcmp(itemToCreate, "p250") == 0)
	{
		weapon = "weapon_p250";
		ammo = "52";
	}	
	else if (strcmp(itemToCreate, "fiveseven") == 0)
	{
		weapon = "weapon_fiveseven";
		ammo = "100";
	}
	else if (strcmp(itemToCreate, "deagle") == 0)
	{
		weapon = "weapon_deagle";
		ammo = "35";
	}
	else if (strcmp(itemToCreate, "elite") == 0)
	{
		weapon = "weapon_elite";
		ammo = "120";
	}
	else if (strcmp(itemToCreate, "p2000") == 0)
	{
		weapon = "weapon_hkp2000";
		ammo = "52";
	}
	else if (strcmp(itemToCreate, "tec9") == 0)
	{
		weapon = "weapon_tec9";
		ammo = "120";
	}
	else if (strcmp(itemToCreate, "taser") == 0)
	{
		weapon = "weapon_taser";
		ammo = "1";
	}

	// ---- Shotguns ------------------------------------------------
	else if (strcmp(itemToCreate, "sawedoff") == 0)
	{
		weapon = "weapon_sawedoff";
		ammo = "32";
	}	
	else if (strcmp(itemToCreate, "nova") == 0)
	{
		weapon = "weapon_nova";
		ammo = "32";
	}
	else if (strcmp(itemToCreate, "xm1014") == 0)
	{
		weapon = "weapon_xm1014";
		ammo = "32";
	}
	else if (strcmp(itemToCreate, "mag7") == 0)
	{
		weapon = "weapon_mag7";
		ammo = "32";
	}	

	// ---- Sub Machine Guns ----------------------------------------
	else if (strcmp(itemToCreate, "mp9") == 0)
	{
		weapon = "weapon_mp9";
		ammo = "120";
	}
	else if (strcmp(itemToCreate, "mac10") == 0)
	{
		weapon = "weapon_mac10";
		ammo = "100";
	}
	else if (strcmp(itemToCreate, "mp7") == 0)
	{
		weapon = "weapon_mp7";
		ammo = "120";
	}
	else if (strcmp(itemToCreate, "ump45") == 0)
	{
		weapon = "weapon_ump45";
		ammo = "100";
	}
	else if (strcmp(itemToCreate, "p90") == 0)
	{
		weapon = "weapon_p90";
		ammo = "100";
	}	
	else if (strcmp(itemToCreate, "bizon") == 0)
	{
		weapon = "weapon_bizon";
		ammo = "120";
	}

	// ---- Machine Guns --------------------------------------------
	else if (strcmp(itemToCreate, "m249") == 0)
	{
		weapon = "weapon_m249";
		ammo = "200";
	}	
	else if (strcmp(itemToCreate, "negev") == 0)
	{
		weapon = "weapon_negev";
		ammo = "200";
	}

	// ---- Rifles --------------------------------------------------
	else if (strcmp(itemToCreate, "famas") == 0)
	{
		weapon = "weapon_famas";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "galilar") == 0)
	{
		weapon = "weapon_galilar";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "m4a1") == 0)
	{
		weapon = "weapon_m4a1";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "ak47") == 0)
	{
		weapon = "weapon_ak47";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "aug") == 0)
	{
		weapon = "weapon_aug";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "sg556") == 0)
	{
		weapon = "weapon_sg556";
		ammo = "90";
	}

	// ---- Sniper Rifles -------------------------------------------
	else if (strcmp(itemToCreate, "ssg08") == 0)
	{
		weapon = "weapon_ssg08";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "g3sg1") == 0)
	{
		weapon = "weapon_g3sg1";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "scar20") == 0)
	{
		weapon = "weapon_scar20";
		ammo = "90";
	}
	else if (strcmp(itemToCreate, "awp") == 0)
	{
		weapon = "weapon_awp";
		ammo = "30";
	}

	// ---- Ammo ----------------------------------------------------
	else if (strcmp(itemToCreate, "338mag") == 0)
	{
		weapon = "ammo_338mag";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "357sig") == 0)
	{
		weapon = "ammo_357sig";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "45acp") == 0)
	{
		weapon = "ammo_45acp";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "50ae") == 0)
	{
		weapon = "ammo_50ae";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "556mm") == 0)
	{
		weapon = "ammo_556mm";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "556mm_box") == 0)
	{
		weapon = "ammo_556mm_box";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "57mm") == 0)
	{
		weapon = "ammo_57mm";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "762mm") == 0)
	{
		weapon = "ammo_762mm";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "9mm") == 0)
	{
		weapon = "ammo_9mm";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "buckshot") == 0)
	{
		weapon = "ammo_buckshot";
		ammo = "0";
	}
	
	// ---- Spawn Points --------------------------------------------
	else if (strcmp(itemToCreate, "ct") == 0)
	{
		weapon = "info_player_counterterrorist";
		ammo = "0";
	}
	else if (strcmp(itemToCreate, "t") == 0)
	{
		weapon = "info_player_deathmatch";
		ammo = "0";
	}
	
	else
	{
		PrintToChat(client, "Item not recognized: %s", itemToCreate);
		return 1;	
	}
	return 0;
}

