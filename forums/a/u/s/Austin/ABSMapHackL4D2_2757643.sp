/* ----------------------------------------------------------------------------
	L4D2MapHack
	Austinbots!

	Spawns items into L4D2 maps and creates Stripper config files for them.

	Requires Metamod:Source, Sourcemod, Stripper
	----------------------------------------------------------------------------
	This plugin lets you add weapons and other items into L4D2 maps.
	The items are added directy to the map and also written to a Stripper
	config file so the next time the map loads the items will be persisted.

	There is one command "add" with the following syntax.
	add item ammo notes

	The only required parameter is the item to add.

	If ammo is left off or set to 0 you will get default ammo for added weapons.
	Notes if entered will be added to the striper config file as a comment.

	Examples:
	Add an ak47 with default ammo where you are standing.
	add ak47

	Add an ak47 with default ammo with a note for the Stripper file.
	You only need quotes around the notes if they contain a space.
	add ak47 0 "ak47 with deafult ammo at first t spawn."

	Add an ak47 with 500 rounds.
	add ak47 500

	----------------------------------------------------------------------------
	Changelog
	----------------------------------------------------------------------------
	2014-05-02 (v1.0)
	        * Initial release.
	----------------------------------------------------------------------------

	Installation instructions
		place the smx file in the plugins folder and you're done.

	Dependencies
		This plugin requires Metamod:Source, Sourcemod, Stripper

		Download them here:
		http://www.sourcemm.net/snapshots
		http://www.sourcemod.net/snapshots.php
		http://www.bailopan.net/stripper/snapshots/1.2/

 	Notes
  	Stripper is used to keep the items you add in the maps permanently.
		Maphack current doens't have the ability to removed items once you add them.
		In order to removed items you added you will have to know how to edit stripper config files.
		Read about Stripper here:
		https://forums.alliedmods.net/showthread.php?t=39439

	Errata
		This works from the console
		add ak47 300 "ak with 300 rounds"

		But the same command from chat doesn't work because of the quotes.
		!add ak47 300 "ak with 300 rounds"

	Plans
		Add in an option to add exploding barrels.
		Add in the ability to easily do a "load out". One command adds in the most common weapons and items.
		Add the ability to remove items by pointing at them to select them.

  Source code best viewed with tab size = 2
---------------------------------------------------------------------------- */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"
public Plugin:myinfo =
{
	name = "L4D2MapHack",
	author = "Austinbots",
	description = "Add Items to L4D2 Maps.",
	version = VERSION,
	url = ""
}

#define s50 50
#define nItems 37
new const String:items[nItems][3][s50] =
{
	// "short name for add command",	"actualy entity name",	"default ammo"

	//---- Health -----------------------------------------
	{"pills",			"weapon_pain_pills",		"0"},
	{"firstaid",	"weapon_first_aid_kit",	"0"},
	{"adrenal",		"weapon_adrenaline",		"0"},
	{"defib",			"weapon_defibrillator",	"0"},

	//---- Grenades --------------------------------------
	{"molotov",		"weapon_molotov",				"0"},
	{"pipe",			"weapon_pipe_bomb",			"0"},
	{"bile",			"weapon_vomitjar",			"0"},

	//---- Items -----------------------------------------
	{"ammo",			"weapon_ammo_spawn",		"0"},
	{"gascan",		"weapon_gascan",				"0"},
	{"fireworks",	"weapon_fireworkcrate",	"0"},
	{"propane",		"weapon_propanetank",		"0"},
	{"oxygen",		"weapon_oxygentank",		"0"},
	{"gnome",			"weapon_gnome",					"0"},
	{"cola",			"weapon_cola_bottles",	"0"},

	//---- Upgrades --------------------------------------
	{"laser",							"upgrade_spawn",									"0"},
	{"explosivebullets",	"weapon_upgradepack_explosive",		"0"},
	{"firebullets",				"weapon_upgradepack_incendiary",	"0"},

	//---- Pistols ---------------------------------------
	{"pistol",		"weapon_pistol",				"120"},
	{"magnum",		"weapon_pistol_magnum",	"120"},

	//---- Sub Machine Guns ------------------------------
	{"smg",				"weapon_smg",						"650"},
	{"smgs",			"weapon_smg_silenced",	"650"},
	{"mp5",				"weapon_smg_mp5",				"650"},

	//---- Shotties --------------------------------------
	{"pump",			"weapon_pumpshotgun",		"56"},
	{"chrome",		"weapon_shotgun_chrome","56"},
	{"spas",			"weapon_shotgun_spas",	"90"},
	{"auto",			"weapon_autoshotgun",		"90"},

	//---- Big Guns --------------------------------------
	{"m60",							"weapon_rifle_m60",					"150"},
	{"grenadelauncher",	"weapon_grenade_launcher",	 "30"},
	{"chainsaw",				"weapon_chainsaw",					  "0"},

	//---- Rifles ----------------------------------------
	{"rifle",			"weapon_rifle",					"360"},
	{"ak47",			"weapon_rifle_ak47",		"360"},
	{"desert",		"weapon_rifle_desert",	"360"},
	{"552",				"weapon_rifle_sg552",		"500"},

	//---- Snipers ---------------------------------------
	{"awp",				"weapon_sniper_awp",			"180"},
	{"scout",			"weapon_sniper_scout",		"180"},
	{"military",	"weapon_sniper_military",	"180"},
	{"hunting",		"weapon_hunting_rifle",		"150"}
};

//------------------------------------------------------------------
//	OnPluginStart()
//------------------------------------------------------------------
public OnPluginStart()
{
	decl String:game[s50];
	GetGameDescription(game, sizeof(game));
	if (!StrEqual(game, "Left 4 Dead 2", false))
		SetFailState("This plugin only runs on L4D2");

	RegAdminCmd("add", Command_Add, ADMFLAG_GENERIC, "Spawn weapon where you are standing. Type 'add help' for more intormation.");

	// Precache CSS weapons and initialize them.
	PrecacheModels();
	CreateTimer(1.0, InitCSSWeapons);

	PrintToServer("L4D2 - MapHack Loaded - Version: %s - Game = %s.", VERSION, game);
}

//------------------------------------------------------------------
// Add(client, args)
//
// Spawn the item directly into the map and
// write the item to a stripper config file so the
// next time the map is loadded the item will always be there
//------------------------------------------------------------------
public Action:Command_Add(client, args)
{
	new String:itemToCreate[s50];
	new String:customAmmo[s50];
	new String:notes[128];
	new String:ammo[s50];
	new String:weapon[s50];

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
	if (GetEntity(client, itemToCreate, weapon, ammo) == 1)
		return Plugin_Handled;

	// If custom ammo was entered with the add command use it instead of the default
	// but also, if ammo returns from GetItem() ammo == 0 then this is an item that
	// doesn't have ammo. Ignore any ammo value they may have entered for it in this case.
	if(
		!StrEqual(customAmmo, "", false)  &&
		!StrEqual(customAmmo, "0", false) &&
		!StrEqual(ammo, "0", false)
		)
	{
		ammo = customAmmo;
	}

	if(CreateItem(client, weapon, ammo) == 0)
		WriteItemToStripperFile(client, weapon, ammo, notes);
	else
		PrintToChat(client, "Could not create item: %s", weapon);

	return Plugin_Handled;
}

//------------------------------------------------------------------
//	CreateItem(client, String:weapon[s50], String:ammo[s50], String:notes[128])
//
//	Spawns an itm into the map
//------------------------------------------------------------------
CreateItem(client, String:weapon[s50], String:ammo[s50])
{
	new String:tmp[128];
	new ret = 1;

	// spawn the item into the map right now
	new inewEntity = CreateEntityByName(weapon);

	if(IsValidEntity(inewEntity))
	{
		new Float:g_Origin[3];
		new Float:g_Angle[3];

		GetClientAbsOrigin(client, g_Origin);
		GetClientAbsAngles(client, g_Angle);

		if (StrEqual(weapon, "upgrade_spawn", false))
		{
			DispatchKeyValue(inewEntity,	"count", "1");
			DispatchKeyValue(inewEntity,	"laser_sight", "1");
			DispatchKeyValue(inewEntity,	"classname", "upgrade_spawn");
		}

		//if (!StrEqual(ammo, "0", false))
			//DispatchKeyValue(inewEntity, "ammo", ammo);

		Format(tmp, sizeof(tmp),			"%1.1f %1.1f %1.1f", g_Origin[0], g_Origin[1], g_Origin[2]);
		DispatchKeyValue(inewEntity,	"origin", tmp);

		Format(tmp, sizeof(tmp),			"%1.1f %1.1f %1.1f", g_Angle[0], g_Angle[1], g_Angle[2]);
		DispatchKeyValue(inewEntity,	"angles", tmp);

		DispatchSpawn(inewEntity);

		// if the item has ammo set the primary ammo
		if (!StrEqual(ammo, "0", false))
			SetEntProp(inewEntity, Prop_Send, "m_iExtraPrimaryAmmo", StringToInt(ammo), 4);

		//Teleport spawned item to where we are standing and facing
		TeleportEntity(inewEntity, g_Origin, NULL_VECTOR, NULL_VECTOR);

		ret = 0;
	}
	else
	{
		ret = 1;
	}
	return ret;
}

//------------------------------------------------------------------
//	WriteItemToStripperFile(client, String:weapon[s50], String:ammo[s50], String:notes[128])
//
//	Writes an item to the strriper file for the curremtly loaded map
//------------------------------------------------------------------
WriteItemToStripperFile(client, String:weapon[s50], String:ammo[s50], String:notes[128])
{
	// write this item to the stripper file
	new String:map[64];
	GetCurrentMap(map, sizeof(map));

	new String:path[255];
	Format(path, sizeof(path), "addons/stripper/maps/%s.cfg", map);

	new Handle:file = OpenFile(path, "a");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open Stripper config file \"%s\" for writing.", path);
		return 1;
	}

	// if they entered notes as the 3rd parameter
	// write them out as a comment in the stripper file
	if(!StrEqual(notes, "", false))
		WriteFileLine(file, ";%s", notes);

	WriteFileLine(file, "add:");
	WriteFileLine(file, "{");

	new Float:g_Origin[3];
	new Float:g_Angle[3];

	GetClientAbsOrigin(client, g_Origin);
	GetClientAbsAngles(client, g_Angle);

	WriteFileLine(file, "\"origin\" \"%1.1f %1.1f %1.1f\"",
	g_Origin[0],
	g_Origin[1],
	g_Origin[2]);

	WriteFileLine(file, "\"angles\" \"%1.1f %1.1f %1.1f\"",
	g_Angle[0],
	g_Angle[1],
	g_Angle[2]);

	if(!StrEqual(ammo, "0", false))
	WriteFileLine(file, "\"ammo\" \"%d\"", ammo);

	WriteFileLine(file, "\"classname\" \"%s\"", weapon);

	// spawnflags 2 overrides the director to force this entity to exist
	if(StrEqual(weapon, "upgrade_spawn", false))
	{
		WriteFileLine(file, "\"laser_sight\" \"1\"");
		WriteFileLine(file, "\"spawnflags\" \"2\"");
	}

	// spawnflags 2 overrides the director to force this entity to exist
	if(StrEqual(weapon, "weapon_ammo_spawn", false))
	{
		WriteFileLine(file, "\"spawnflags\" \"2\"");
	}

	WriteFileLine(file, "\"count\" \"1\"");
	WriteFileLine(file, "}");
	CloseHandle(file);
	PrintToChat(client, "Item saved to Stripper file: %s", weapon);

	return 0;
}

//------------------------------------------------------------------
//	GetEntity(client, String:itemToCreate[s50], String:weapon, String:ammo)
//
//	Return the actual entity name from the shortened add command name.
//	Sets per weapon default ammo
//------------------------------------------------------------------
GetEntity(client, String:itemToCreate[s50], String:weapon[s50], String:ammo[s50])
{
	new ret = 1;
	new idx = -1;

	for (new i = 0; i < nItems; i++)
  	if(StrEqual(itemToCreate, items[i][0],false))
  		idx = i;

	if(idx != -1)
	{
		//PrintToChat(client, "Found = %s %s %s", items[idx][0], items[idx][1], items[idx][2]);
		weapon = items[idx][1];
		ammo = items[idx][2];
		ret = 0;
  }
 	else
	{
		PrintToChat(client, "Item not recognized: %s Try add help for a list of items.", itemToCreate);
		ret = 1;
	}
	return ret;
}

//------------------------------------------------------------------
// PrecacheModels()
//
// Precache models if they're not already loaded.
//------------------------------------------------------------------
PrecacheModels()
{
	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl"))					PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl"))			PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl"))			PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl"))		PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");

	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl"))									PrecacheModel("models/v_models/v_smg_mp5.mdl");
	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl"))								PrecacheModel("models/v_models/v_rif_sg552.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl"))								PrecacheModel("models/v_models/v_snip_awp.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl"))							PrecacheModel("models/v_models/v_snip_scout.mdl");

	if (!IsModelPrecached("models/props/terror/ammo_stack.mdl"))						PrecacheModel("models/props/terror/ammo_stack.mdl");

	if (!IsModelPrecached("models/props_c17/oildrum001_explosive.mdl"))			PrecacheModel("models/props_c17/oildrum001_explosive.mdl");
	if (!IsModelPrecached("models/props_industrial/barrel_fuel_parta.mdl"))	PrecacheModel("models/props_industrial/barrel_fuel_parta.mdl");
	if (!IsModelPrecached("models/props_industrial/barrel_fuel_partb.mdl"))	PrecacheModel("models/props_industrial/barrel_fuel_partb.mdl");
}

//------------------------------------------------------------------
//	InitCSSWeapons(Handle:timer, any:client)
//------------------------------------------------------------------
public Action:InitCSSWeapons(Handle:timer, any:client)
{
	decl String:map[100];

	//Spawn and delete the hidden weapons,
	new index = CreateEntityByName("weapon_rifle_sg552");
	DispatchSpawn(index);
	RemoveEdict(index);

	index = CreateEntityByName("weapon_smg_mp5");
	DispatchSpawn(index);
	RemoveEdict(index);

	index = CreateEntityByName("weapon_sniper_awp");
	DispatchSpawn(index);
	RemoveEdict(index);

	index = CreateEntityByName("weapon_sniper_scout");
	DispatchSpawn(index);
	RemoveEdict(index);

	GetCurrentMap(map, sizeof(map));
	ForceChangeLevel(map, "CSS weapon initialization.");
}

//------------------------------------------------------------------
//	ShowHelp(client)
//------------------------------------------------------------------
ShowHelp(client)
{
	PrintToChat(client, "Open your console to see a list of items that can be added.");

	PrintToConsole(client, "---------------------------------------------------------------------------");
	PrintToConsole(client, "This plugs in adds items to L4D2 maps using Stripper.\n");

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

	PrintToConsole(client, "---------------------------------------------------------------------------");
	PrintToConsole(client, "List of all items you can add.\n");

	PrintToConsole(client, "---- Health ------------------------------------------------");
	PrintToConsole(client, "pills, firstaid, adrenal, defib\n");

	PrintToConsole(client, "---- Grenades ----------------------------------------------");
	PrintToConsole(client, "molotov, pipe, bile\n");

	PrintToConsole(client, "---- Items -------------------------------------------------");
	PrintToConsole(client, "ammo, gascan, fireworks, propane, oxygen, gnome, cola\n");

	PrintToConsole(client, "---- Upgrades ----------------------------------------------");
	PrintToConsole(client, "laser, explosivebullets, firebullets\n");

	PrintToConsole(client, "---- Pistols -----------------------------------------------");
	PrintToConsole(client, "pistol, magnum\n");

	PrintToConsole(client, "---- Sub Machine Guns --------------------------------------");
	PrintToConsole(client, "smg, smgs, mp5\n");

	PrintToConsole(client, "---- Shotties ----------------------------------------------");
	PrintToConsole(client, "pump, chrome, spas, auto\n");

	PrintToConsole(client, "---- Big Guns ----------------------------------------------");
	PrintToConsole(client, "m60, grenadelauncher, chainsaw\n");

	PrintToConsole(client, "---- Rifles ------------------------------------------------");
	PrintToConsole(client, "rifle, ak47, desert, 552\n");

	PrintToConsole(client, "---- Snipers -----------------------------------------------");
	PrintToConsole(client, "awp, scout, military\n");
}

