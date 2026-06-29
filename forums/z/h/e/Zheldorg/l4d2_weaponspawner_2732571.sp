/*
 * *Simple* plugin which you can spawn any weapon or special zombie where you are looking also you can give weapons to players.
 *
 * ####
 * Commands:
 * 	-	sm_spawnweapon [weapon_name] <amount> or sm_sw [weapon_name] <amount>
 *		(eg. sm_sw chainsaw 2)
 *	-	sm_giveweapon <#userid|name> [weapon_name] or sm_gw <#userid|name> [weapon_name] 
 *		(eg. sm_gw @me chainsaw)
 *		Targeting: http://wiki.alliedmods.net/Admin_Commands_%28SourceMod%29#How_to_Target
 *	-	sm_zspawn [special infeted name] <amount>
 *		(eg. sm_zspawn tank 3)
 *	-	sm_uispawn [uncommon zombie name] <amount>
 *		(eg. sm_uispawn riot 5)
 *	-	sm_spawnmachinegun <type> or sm_smg <type>
 *		(eg. sm_smg 2)
 *	-	sm_removemachinegun or sm_rmg - Remove Machine Gun
 *
 * ####
 * ConVars:
 *	-	sm_spawnweapon_assaultammo 			- How much Ammo for AK74, M4A1, SG552 and Desert Rifle.
 *	-	sm_spawnweapon_smgammo 				- How much Ammo for SMG, Silenced SMG and MP5
 *	-	sm_spawnweapon_shotgunammo 			- How much Ammo for Shotgun and Chrome Shotgun.
 *	-	sm_spawnweapon_autoshotgunammo 		- How much Ammo for Autoshotgun and SPAS.
 *	-	sm_spawnweapon_sniperrifleammo 		- How much Ammo for the Military Sniper Rifle, AWP and Scout.
 *	-	sm_spawnweapon_grenadelauncherammo 	- How much Ammo for the Grenade Launcher.
 *	-	sm_spawnweapon_g_hCvar_AllowAllMeleeWeapons	- Allow or Disallow all melee weapons on all campaigns.
 *
 * ####
 * Weapon List: 
 * adrenaline, autoshotgun, chainsaw, defibrillator, fireworkcrate, 
 * first_aid_kit, gascan, gnome, grenade_launcher, hunting_rifle, 
 * molotov, oxygentank, pain_pills, pipe_bomb, pistol, 
 * pistol_magnum, propanetank, pumpshotgun, rifle, rifle_ak47, 
 * rifle_desert, rifle_sg552, rifle_m60, shotgun_chrome, shotgun_spas, smg, 
 * smg_mp5, smg_silenced, sniper_awp, sniper_military, sniper_scout, 
 * vomitjar, ammo_spawn, upgradepack_explosive, upgradepack_incendiary, 
 * cola_bottles, rifle_m60, upgrade_laser_sight, explosive_barrel, laser_sight
 *
 * ####
 * Melee Weapons List:
 * baseball_bat, cricket_bat, crowbar, electric_guitar, fireaxe, frying_pan, 
 * katana, machete, tonfa, knife, golfclub, pitchfork, shovel
 *
 * #### 
 * Special Infected List: 
 * boomer, hunter, smoker, tank, spitter, jockey, charger, zombie, witch, witch_bride, mob
 *
 * #### 
 * Uncommon Zombie List: 
 * riot, ceda, clown, mud, roadcrew, jimmy, fallen_survivor
 *
 * #### 
 * Minigun Type List: 
 * 1, 2
 *
 * ####
 * Item names for file adminmenu_sorting.txt:
 * "WeaponSpawner", "ws_spawn_weapon", "ws_give_weapon", "ws_special_infected"
 * "ws_uncommon_zombie" ,"ws_minigun_menu"
 *
 * example usage:
 *
 	"WeaponSpawner"
	{
		"item"		"ws_give_weapon"
		"item"		"ws_spawn_weapon"
		"item"		"ws_minigun_menu"
		"item"		"ws_special_infected"
		"item"		"ws_uncommon_zombie"
	}
 *
 * ####
 * Changelog:
 * v1.3c 
 *  o Fixed "Incorrect spawn of special infected in versus and scavenge modes"
 * v1.3b 
 *  o Fixed "sm_zspawn used the wrong set of names"
 * v1.3a
 *  o Add suport the last stand update
 * v1.3
 *  o Now fully translatable
 *  o Added Melee Lists for all def maps
 *  o All console commands check arguments
 *  o Spawn position adjusted for all objects
 *  o Added command and menu item to spawn uncommon infected
 *  o Command "sm_spawnweapon" now works correctly with melee weapons
 *  o Ammo stack is now sticking to the surface, not above or below
 *  o Menu does not switch to the beginning of the section when the item is activated
 *  o Code refactoring witch use SourcePawn Transitional Syntax
 * v1.0a
 *  o Added L4D1 Minigun
 *  o Changed sm_smg to sm_smg #   sm_smg 1 will spawn the l4d2 minigun and sm_smg 2 will spawn the l4d1 minigun
 * v1.0
 *  o Added Laser Sight Box
 *  o Added The Sacrifice and No Mercy Melee Lists
 *  o Added Explosive Barrel
 * v0.9
 *  o Added ability to spawn melee weapons.
 *	o Added Katana and Fireaxe to The Passing melee list
 * v0.8a
 *  o Added "Zombie Mob"
 * v0.8
 *  o Added "Bride Witch"
 * v0.7f
 *  o Removed Electric Guitar from The Passing Melee weapons list
 * v0.7e
 *  o "Golf Club" is now The Passing exclusive
 *  o Fixed precache model typos 
 * v0.7d
 *  o "Golf Club" support
 * v0.7c
 *  o Full "M60" support, excluding ammo cvar
 * v0.7b
 *  o Added "M60(only as spawn)"
 * v0.7a
 *	o Added missing "Full Health"
 *	o Debug informations now are disabled by default
 * v0.7
 *	o Added missing stuff in "give menu" from v0.5-beta
 *	o Fixed Ammo Stack spawning
 *	o Fixed typos in translation file (thx for bearbear)
 *	o Added second argument to sm_spawnweapon and sm_zspawn - amount of spawned items/zombies
 *	o Fixed campaigns detection
 * v0.6
 *	o Added ammo to spawned weapons (yey!)
 *	o Added ammo cvars
 *	o Automatically adding "weapon_" for sm_sw (eg. sm_sw rifle)
 *	o Added multi-language support
 *	o Added cola and knife (knife works only when you play with germans)
 *	o Added command to remove minigun
 *	o Minor Fixes
 * v0.5 - Beta
 *	o Added MagineGun spawning
 *	o Added missing witch and vomitjar
 * 	o Minor fixes
 * v0.4
 *	o Menu now use own category on Admin Menu
 *	o Added menu for "Give Weapons"
 *	o Added menu for "Spawn Special Zombie"
 *	o Added Laser Sights, Explosive Ammo, Incendiary Ammo, Health, Ammo Stack
 *	o Rewrite menu "Spawn Weapon"
 *	o Fix for: http://forums.alliedmods.net/showpost.php?p=998601&postcount=33 (now you can use your nick in binds)
 *	o Rename sm_spawn to sm_zspawn
 *	o Code optimizations
 * v0.3a
 *	o Fix for: http://forums.alliedmods.net/showpost.php?p=997445&postcount=21
 * v0.3
 *	o Added Menu (in admin menu - Server Commands)
 *	o Added sm_spawn
 * v0.2
 *	o Added sm_gw
 * v0.1
 *	o Initial Release
 *
 * Zuko / #hlds.pl @ Qnet #sourcemod @ GameSurge / zuko.steamunpowered.eu / hlds.pl /
 *
 * ####
 * Credits:
 * pheadxdll for [TF2] Pumpkins code
 * antihacker for [L4D] Spawn Minigun code
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required

#define VERSION "1.3c"

// TopMenu Handle
TopMenu hTopMenu;

// ConVar Handle
ConVar g_hCvar_MaxAmmo_Assault;
ConVar g_hCvar_MaxAmmo_SMG;
ConVar g_hCvar_MaxAmmo_Shotgun;
ConVar g_hCvar_MaxAmmo_AutoShotgun;
ConVar g_hCvar_MaxAmmo_HuntingRifle;
ConVar g_hCvar_MaxAmmo_SniperRifle;
ConVar g_hCvar_MaxAmmo_GrenadeLauncher;
ConVar g_hCvar_AllowAllMeleeWeapons;
ConVar g_hCvar_MPGameMode;

// Variables
int g_iCvar_MaxAmmo_Assault;
int g_iCvar_MaxAmmo_SMG;
int g_iCvar_MaxAmmo_Shotgun;
int g_iCvar_MaxAmmo_AutoShotgun;
int g_iCvar_MaxAmmo_HuntingRifle;
int g_iCvar_MaxAmmo_SniperRifle;
int g_iCvar_MaxAmmo_GrenadeLauncher;
int g_iCvar_AllowAllMeleeWeapons;

bool g_bIsMapRunning = false;
bool g_bPvpMode = false;

// Control create model entity zombie
bool g_bCurrentlySpawning = false;
char g_sChangeZombieModelTo[128] = "";

// Menu
enum MenuHistory
{
	NoneMenu = 0,/* Now not used */
	MeleeBasedSpawnMenu = 1,	BulletBasedSpawnMenu = 2,	ShellBasedSpawnMenu = 3,	ExplosiveBasedSpawnMenu = 4,	HealthSpawnMenu = 5,	MiscSpawnMenu = 6,
	MeleeBasedGiveMenu = 7,		BulletBasedGiveMenu = 8,	ShellBasedGiveMenu = 9,		ExplosiveBasedGiveMenu = 10,	HealthGiveMenu = 11,	MiscGiveMenu = 12,
	SpawnMenu = 13,				GiveMenu = 14,				SpecialInfectedMenu = 15,	UncommonZombieMenu = 16,		MinigunMenu = 17
};
MenuHistory Choosed_Menu[MAXPLAYERS+1];
int g_iFirstItemOfMenuPage[MAXPLAYERS+1];
int g_iAmountUncommonZombie[MAXPLAYERS+1] = {1,...};
const int c_iFirstItemMenu = 0;
int g_iMeleeWeaponsList[13]; /* Useds for melee_name & melee_param. Format: [0..12] - stores IDs of strings to melee weapons available on the map, -1 work how "terminal null"*/

// Spawn and Give Weapons
const int spawngive_submenu_arrsize = 6;
static const char spawngive_submenu_name[6][32] = {"MeleeWeapons", "BulletBased", "ShellBased", "ExplosiveBased", "HealthRelated", "Misc"};

// SPECIAL Infected 
const int special_infected_arrsize = 11;
static const char special_infected_name[11][32] = {"Boomer", "Hunter", "Smoker", "Spitter", "Charger", "Tank", "Jockey", "Witch", "BrideWitch", "OneZombie", "ZombieMob"};
static const char special_infected_param[11][32] = {"boomer", "hunter", "smoker", "spitter", "charger", "tank", "jockey", "witch", "witch_bride", "zombie", "mob"};

// UNCOMMON Zombie
const int uncommon_zombie_arrsize = 8;
static const char uncommon_zombie_name[8][32] = {"Riot", "Ceda", "Clown", "Mud", "Roadcrew", "Jimmy", "Fallen", "SetAmountInfected"};
static const char uncommon_zombie_param[8][32] = {"riot", "ceda", "clown", "mud", "roadcrew", "jimmy", "fallen_survivor", "set_amount"};

// MINIGUN
const int minigun_arrsize = 3;
static const char minigun_name[3][32] = {"SpawnMiniGun", "SpawnMiniGun2", "RemoveMiniGun"};

// MELEE Based
const int melee_arrsize = 13;
static const char melee_name[13][32] =
{ "BaseballBat", "CricketBat", "Crowbar", "ElectricGuitar", "FireAxe",  "FryingPan", "Golfclub", "Katana", "Knife", "Machete", "Tonfa", "Pitchfork", "Shovel"};
static const char melee_param[13][32] =
{ "baseball_bat", "cricket_bat", "crowbar", "electric_guitar", "fireaxe", "frying_pan", "golfclub", "katana", "knife", "machete", "tonfa", "pitchfork", "shovel"};

// BULLET Based
const int bullet_based_arrsize = 14;
static const char bullet_based_name[14][32] =
{ "HuntingRifle", "Pistol", "DesertEagle", "Rifle", "DesertRifle", "SubmachineGun", "SilencedSubmachineGun",
 "MilitarySniper", "AvtomatKalashnikova", "SIGSG550", "SubmachineGunMP5", "RifleM60", "AWP", "ScoutSniper"};
static const char bullet_based_param[14][32] =
{ "hunting_rifle", "pistol", "pistol_magnum", "rifle", "rifle_desert", "smg", "smg_silenced",
 "sniper_military", "rifle_ak47", "rifle_sg552", "smg_mp5", "rifle_m60", "sniper_awp", "sniper_scout"};
 
// SHELL Based
const int shell_based_arrsize = 4;
static const char shell_based_name[4][32] = {"AutoShotgun", "ChromeShotgun", "SpasShotgun", "PumpShotgun"};
static const char shell_based_param[4][32] = {"autoshotgun", "shotgun_chrome", "shotgun_spas", "pumpshotgun"};

// EXPLOSIVE Based
const int exp_based_arrsize = 8;
static const char exp_based_name[8][32] =
{ "GrenadeLauncher", "ExplosiveBarrel", "FireworksCrate", "Gascan", "Molotov", "PropaneTank", "PipeBomb", "OxygenTank"};
static const char exp_based_param[8][32] =
{ "grenade_launcher", "explosive_barrel", "fireworkcrate", "gascan", "molotov", "propanetank", "pipe_bomb", "oxygentank"};

// HEALTH Based
const int heal_based_arrsize = 4;
static const char heal_based_name[4][32] = {"Adrenaline", "Defibrillator", "FirstAidKit", "PainPills"};
static const char heal_based_param[4][32] = {"adrenaline", "defibrillator", "first_aid_kit", "pain_pills"};

// MISC Based
const int misc_based_arrsize = 9;
static const char misc_based_name[9][32] =
{ "AmmoStackCoffee", "AmmoStack", "LaserSightBox", "ExplosiveAmmoPack", "IncendiaryAmmoPack", "VomitJar", "ChainSaw", "Gnome", "Cola"};
static const char misc_based_param[9][32] =
{ "ammo_spawn_coffee", "ammo_spawn", "laser_sight", "upgradepack_explosive", "upgradepack_incendiary", "vomitjar", "chainsaw", "gnome", "cola_bottles"};

// EXPLOSIVE Based (Give Menu)
const int exp_based2_arrsize = 7;
static const char exp_based2_name[7][32] = {"GrenadeLauncher", "FireworksCrate", "Gascan", "Molotov", "PropaneTank", "PipeBomb", "OxygenTank"};
static const char exp_based2_param[7][32] = {"grenade_launcher", "fireworkcrate", "gascan", "molotov", "propanetank", "pipe_bomb", "oxygentank"};

// HEALTH Based (Give Menu)
const int heal_based2_arrsize = 5;
static const char heal_based2_name[5][32] = {"FullHealth", "Adrenaline", "Defibrillator", "FirstAidKit", "PainPills"};
static const char heal_based2_param[5][32] = {"health", "adrenaline", "defibrillator", "first_aid_kit", "pain_pills"};

// MISC Based (Give Menu)
const int misc_based2_arrsize = 10;
static const char misc_based2_name[10][32] =
{ "ChainSaw", "Ammo", "LaserSight", "ExplosiveAmmo", "IncendiaryAmmo", "ExplosiveAmmoPack", "IncendiaryAmmoPack", "VomitJar", "Gnome", "Cola"};
static const char misc_based2_param[10][32] =
{ "chainsaw", "ammo", "laser_sight", "explosive_ammo", "incendiary_ammo", "upgradepack_explosive", "upgradepack_incendiary", "vomitjar", "gnome", "cola_bottles"};

// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo = 
{
	name = "[L4D2] Weapon/Zombie Spawner",
	author = "Zuko & McFlurry, Zheldorg",
	description = "Spawns weapons/zombies where your looking or give weapons to players.",
	version = VERSION,
	url = ""
}

public void OnPluginStart()
{
	// Load translations
	LoadTranslations("common.phrases");
	LoadTranslations("weaponspawner.phrases");
	
	// ConVars
	CreateConVar("sm_weaponspawner_version", VERSION, "Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hCvar_MaxAmmo_Assault =			CreateConVar("sm_spawnweapon_assaultammo",			"360",	"How much Ammo for AK74, M4A1, SG552, M60 and Desert Rifle.",	0, true, 0.0, true, 360.0);
	g_hCvar_MaxAmmo_SMG =				CreateConVar("sm_spawnweapon_smgammo",				"650",	"How much Ammo for SMG, Silenced SMG and MP5",					0, true, 0.0, true, 650.0);
	g_hCvar_MaxAmmo_Shotgun =			CreateConVar("sm_spawnweapon_shotgunammo",			"56",	"How much Ammo for Shotgun and Chrome Shotgun.",				0, true, 0.0, true, 56.0);
	g_hCvar_MaxAmmo_AutoShotgun =		CreateConVar("sm_spawnweapon_autoshotgunammo",		"90",	"How much Ammo for Autoshotgun and SPAS.",						0, true, 0.0, true, 90.0);
	g_hCvar_MaxAmmo_HuntingRifle =		CreateConVar("sm_spawnweapon_huntingrifleammo",		"150",	"How much Ammo for the Hunting Rifle.",							0, true, 0.0, true, 150.0);
	g_hCvar_MaxAmmo_SniperRifle =		CreateConVar("sm_spawnweapon_sniperrifleammo",		"180",	"How much Ammo for the Military Sniper Rifle, AWP and Scout.",	0, true, 0.0, true, 180.0);
	g_hCvar_MaxAmmo_GrenadeLauncher =	CreateConVar("sm_spawnweapon_grenadelauncherammo",	"30",	"How much Ammo for the Grenade Launcher.",						0, true, 0.0, true, 30.0);
	g_hCvar_AllowAllMeleeWeapons = 		CreateConVar("sm_spawnweapon_allowallmeleeweapons",	"0",	"Allow or Disallow all melee weapons on all campaigns.",		0, true, 0.0, true, 1.0);
	
	g_hCvar_MaxAmmo_Assault.AddChangeHook			(ConVarChanged_MaxAmmo);
	g_hCvar_MaxAmmo_SMG.AddChangeHook				(ConVarChanged_MaxAmmo);
	g_hCvar_MaxAmmo_Shotgun.AddChangeHook			(ConVarChanged_MaxAmmo);
	g_hCvar_MaxAmmo_AutoShotgun.AddChangeHook		(ConVarChanged_MaxAmmo);
	g_hCvar_MaxAmmo_HuntingRifle.AddChangeHook		(ConVarChanged_MaxAmmo);
	g_hCvar_MaxAmmo_SniperRifle.AddChangeHook		(ConVarChanged_MaxAmmo);
	g_hCvar_MaxAmmo_GrenadeLauncher.AddChangeHook	(ConVarChanged_MaxAmmo);
	g_hCvar_AllowAllMeleeWeapons.AddChangeHook		(ConVarChanged_AllowAllMelee);

	// Admin Commands
	RegAdminCmd("sm_spawnweapon",		Command_SpawnWeapon,			ADMFLAG_SLAY, "Spawn weapon where you are looking.");
	RegAdminCmd("sm_sw", 				Command_SpawnWeapon,			ADMFLAG_SLAY, "Spawn weapon where you are looking.");
	RegAdminCmd("sm_giveweapon",		Command_GiveWeapon,				ADMFLAG_SLAY, "Gives weapon to player.");
	RegAdminCmd("sm_gw",				Command_GiveWeapon,				ADMFLAG_SLAY, "Gives weapon to player.");
	RegAdminCmd("sm_zspawn",			Command_SpawnSpecialInfected,	ADMFLAG_SLAY, "Spawns special infected where you are looking.");
	RegAdminCmd("sm_uispawn",			Command_SpawnUncommonZombie,	ADMFLAG_SLAY, "Spawns uncommon zombie where you are looking.");
	RegAdminCmd("sm_spawnmachinegun",	Command_SpawnMinigun,			ADMFLAG_SLAY, "Spawns Machine Gun.");
	RegAdminCmd("sm_smg",				Command_SpawnMinigun,			ADMFLAG_SLAY, "Spawns Machine Gun.");
	RegAdminCmd("sm_removemachinegun",	Command_RemoveMinigun,			ADMFLAG_SLAY, "Remove Machine Gun.");
	RegAdminCmd("sm_rmg",				Command_RemoveMinigun,			ADMFLAG_SLAY, "Remove Machine Gun.");

	// Config File
	AutoExecConfig(true, "l4d2_weaponspawner");

	g_hCvar_MPGameMode = FindConVar("mp_gamemode");
	g_hCvar_MPGameMode.AddChangeHook(ConVarChanged_MPGameMode);

	// Menu Handler
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
	// Read Plugin ConVar
	GetCvars();
	CheckMode();
}

public void OnMapStart()
{
	g_bIsMapRunning = true;
	
	// Precache weapons models
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/props_industrial/barrel_fuel.mdl", true);
	PrecacheModel("models/props_industrial/barrel_fuel_partb.mdl", true);
	PrecacheModel("models/props_industrial/barrel_fuel_parta.mdl", true);
	PrecacheModel("models/w_models/weapons/w_minigun.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	PrecacheModel("models/props_unique/spawn_apartment/coffeeammo.mdl", true);	
	// Precache uncommon infected models
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);

	Define_melee_weapons_list();
}
public void OnMapEnd()
{
	g_bIsMapRunning = false;
}

public void ConVarChanged_MPGameMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CheckMode();
}

public void ConVarChanged_MaxAmmo(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_AllowAllMelee(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCvar_AllowAllMeleeWeapons = g_hCvar_AllowAllMeleeWeapons.IntValue;
	if (g_bIsMapRunning) Define_melee_weapons_list();
}

stock void CheckMode()
{
	char sGameMode[64];
	g_hCvar_MPGameMode.GetString(sGameMode, sizeof(sGameMode));
	if ((strcmp(sGameMode, "versus") == 0) || (strcmp(sGameMode, "scavenge") == 0))
		g_bPvpMode = true;
	else 
		g_bPvpMode = false;
}

stock void GetCvars()
{
	g_iCvar_MaxAmmo_Assault =			g_hCvar_MaxAmmo_Assault.IntValue;
	g_iCvar_MaxAmmo_SMG =				g_hCvar_MaxAmmo_SMG.IntValue;
	g_iCvar_MaxAmmo_Shotgun =			g_hCvar_MaxAmmo_Shotgun.IntValue;
	g_iCvar_MaxAmmo_AutoShotgun =		g_hCvar_MaxAmmo_AutoShotgun.IntValue;
	g_iCvar_MaxAmmo_HuntingRifle =		g_hCvar_MaxAmmo_HuntingRifle.IntValue;
	g_iCvar_MaxAmmo_SniperRifle =		g_hCvar_MaxAmmo_SniperRifle.IntValue;
	g_iCvar_MaxAmmo_GrenadeLauncher =	g_hCvar_MaxAmmo_GrenadeLauncher.IntValue;
	g_iCvar_AllowAllMeleeWeapons =		g_hCvar_AllowAllMeleeWeapons.IntValue;
}

// ====================================================================================================
//					CONSOLE СOMMANDS
// ====================================================================================================
// Spawn Weapon
public Action Command_SpawnWeapon(int client, int args)
{
	int amount;
	char sArg1_weapon[32], sArg2_amount[5];
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "CommandError_01", LANG_SERVER);
		return Plugin_Handled;
	}
	if (args == 2)
	{
		GetCmdArg(1, sArg1_weapon, sizeof(sArg1_weapon));
		GetCmdArg(2, sArg2_amount, sizeof(sArg2_amount));
		amount = StringToInt(sArg2_amount);
	}
	else if (args == 1)
	{
		GetCmdArg(1, sArg1_weapon, sizeof(sArg1_weapon));
		amount = 1;
	}
	else
	{
		ReplyToCommand(client, "%t", "SpawnWeaponUsage", LANG_SERVER);
		return Plugin_Handled;
	}
	int metadata, index;
	bool bCheckArgGun = false;	
	if		((index = CheckName(sArg1_weapon, melee_param,			melee_arrsize)) 		> -1) 	{bCheckArgGun = true; metadata = 100 + index;}
	else if ((index = CheckName(sArg1_weapon, bullet_based_param,	bullet_based_arrsize))	> -1)	{bCheckArgGun = true; metadata = 200 + index;}
	else if ((index = CheckName(sArg1_weapon, shell_based_param,	shell_based_arrsize)) 	> -1)	{bCheckArgGun = true; metadata = 300 + index;}
	else if ((index = CheckName(sArg1_weapon, exp_based_param,		exp_based_arrsize))		> -1)	{bCheckArgGun = true; metadata = 400 + index;}
	else if ((index = CheckName(sArg1_weapon, heal_based_param,		heal_based_arrsize)) 	> -1)	{bCheckArgGun = true; metadata = 500 + index;}
	else if ((index = CheckName(sArg1_weapon, misc_based_param,		misc_based_arrsize)) 	> -1)	{bCheckArgGun = true; metadata = 600 + index;}

	if(bCheckArgGun)
		f_SpawnWeapon(client, sArg1_weapon, amount, metadata);
	else
		ReplyToCommand(client, "%t", "UncorrectWeaponName", LANG_SERVER);
	return Plugin_Handled;
}
// Give Weapon
public Action Command_GiveWeapon(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "%t", "GiveWeaponUsage", LANG_SERVER);
		return Plugin_Handled;
	}

	char sArg1_player[64], sArg2_weapon[32];
	GetCmdArg(1, sArg1_player, sizeof(sArg1_player));
	GetCmdArg(2, sArg2_weapon, sizeof(sArg2_weapon));

	int target_list[MAXPLAYERS], target_count;
	char sStubTargetName[MAX_TARGET_LENGTH]; // NOT FOR REAL USE ( stub var for ProcessTargetString() )
	bool bStub; // NOT FOR REAL USE ( stub var for ProcessTargetString() )

	if ((target_count = ProcessTargetString(sArg1_player, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, sStubTargetName, sizeof(sStubTargetName), bStub)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	int metadata, index;
	bool bCheckArgGun = false;	
	if		((index = CheckName(sArg2_weapon, melee_param,			melee_arrsize))			> -1)	{bCheckArgGun = true; metadata = -1;}
	else if	((index = CheckName(sArg2_weapon, bullet_based_param,	bullet_based_arrsize))	> -1)	{bCheckArgGun = true; metadata = -1;}
	else if ((index = CheckName(sArg2_weapon, shell_based_param,	shell_based_arrsize))	> -1)	{bCheckArgGun = true; metadata = -1;}
	else if ((index = CheckName(sArg2_weapon, exp_based2_param,	 	exp_based2_arrsize))	> -1)	{bCheckArgGun = true; metadata = -1;}
	else if ((index = CheckName(sArg2_weapon, heal_based2_param,	heal_based2_arrsize))	> -1)	{bCheckArgGun = true; metadata = -1;}
	else if ((index = CheckName(sArg2_weapon, misc_based2_param,	misc_based2_arrsize))	> -1)	{bCheckArgGun = true; metadata = 100 + index;} // 102 laser_sight, 103 explosive_ammo, 104 incendiary_ammo

	if(bCheckArgGun)
		f_GiveWeapon(target_count, target_list, sArg2_weapon, metadata);
	else
		ReplyToCommand(client, "%t", "UncorrectWeaponName", LANG_SERVER);
	return Plugin_Handled;
}
// Spawn Special Infected
public Action Command_SpawnSpecialInfected(int client, int args)
{
	int amount;
	char sArg1_zombie[32], sArg2_amount[5];

	if (client == 0)
	{
		ReplyToCommand(client, "%t", "CommandError_01", LANG_SERVER);
		return Plugin_Handled;
	}	
	if (args == 2)
	{
		GetCmdArg(1, sArg1_zombie, sizeof(sArg1_zombie));
		GetCmdArg(2, sArg2_amount, sizeof(sArg2_amount));
		amount = StringToInt(sArg2_amount);
	}
	else if (args == 1)
	{
		GetCmdArg(1, sArg1_zombie, sizeof(sArg1_zombie));
		amount = 1;
	}
	else
	{
		ReplyToCommand(client, "%t", "SpawnSpecialInfectedUsage", LANG_SERVER);
		return Plugin_Handled;
	}
	if(CheckName(sArg1_zombie, special_infected_param, special_infected_arrsize) > -1)
		f_SpawnZombie(client, sArg1_zombie, amount);
	else
		ReplyToCommand(client, "%t", "UncorrectZombieName", LANG_SERVER);
	return Plugin_Handled;		
}
// Spawn Uncommon Zombie
public Action Command_SpawnUncommonZombie(int client, int args)
{
	int amount;
	char sArg1_zombie[32], sArg2_amount[5];
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "CommandError_01", LANG_SERVER);
		return Plugin_Handled;
	}
	if (args == 2)
	{
		GetCmdArg(1, sArg1_zombie, sizeof(sArg1_zombie));
		GetCmdArg(2, sArg2_amount, sizeof(sArg2_amount));
		amount = StringToInt(sArg2_amount);
	}
	else if (args == 1)
	{
		GetCmdArg(1, sArg1_zombie, sizeof(sArg1_zombie));
		amount = 1;
	}
	else
	{
		ReplyToCommand(client, "%t", "SpawnUncommonZombieUsage", LANG_SERVER);
		return Plugin_Handled;
	}
	if(CheckName(sArg1_zombie, uncommon_zombie_param, uncommon_zombie_arrsize) > -1)
		f_SpawnUncommonInfected(client, sArg1_zombie, amount);
	else
		ReplyToCommand(client, "%t", "UncorrectZombieName", LANG_SERVER);
	return Plugin_Handled;
}
// Minigun
public Action Command_SpawnMinigun(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "CommandError_01", LANG_SERVER);
		return Plugin_Handled;	
	}
	if (args == 1)
	{
		char sArg1_type[32];
		GetCmdArg(1, sArg1_type, sizeof(sArg1_type));
		int iType = StringToInt(sArg1_type);
		if (iType == 0) return Plugin_Handled;
		switch(iType) // filter arg, 1) minigun 50cal 2) minigun l4d1
		{
			case 1: f_SpawnMiniGun(client, 1);	
			case 2: f_SpawnMiniGun(client, 2);	
		}	
	}	
	return Plugin_Handled;
}

public Action Command_RemoveMinigun(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "%t", "CommandError_01", LANG_SERVER);
		return Plugin_Handled;	
	}
	f_RemoveMiniGun(client);
	return Plugin_Handled;
}
/* >>> end of CONSOLE СOMMANDS */

// ====================================================================================================
//					MENU CODE
// ====================================================================================================
// Main Menu
public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);	// problem witch TopMenu type in arg, used Handle
	if (topmenu == hTopMenu) return; // Block us from being called twice

	hTopMenu = topmenu;

	TopMenuObject weapon_spawner = hTopMenu.AddCategory("WeaponSpawner", HandlerTopMenu_WeaponSpawner);
	if (weapon_spawner != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("ws_spawn_weapon",			HandlerItemTopMenu_WeaponSpawner, weapon_spawner, "sm_sw_menu", ADMFLAG_SLAY);
		hTopMenu.AddItem("ws_give_weapon",			HandlerItemTopMenu_WeaponSpawner, weapon_spawner, "sm_gw_menu", ADMFLAG_SLAY);
		hTopMenu.AddItem("ws_special_infected",		HandlerItemTopMenu_WeaponSpawner, weapon_spawner, "sm_ssi_menu", ADMFLAG_SLAY);
		hTopMenu.AddItem("ws_uncommon_zombie",		HandlerItemTopMenu_WeaponSpawner, weapon_spawner, "sm_sui_menu", ADMFLAG_SLAY);
		hTopMenu.AddItem("ws_minigun_menu",			HandlerItemTopMenu_WeaponSpawner, weapon_spawner, "sm_smg_menu", ADMFLAG_SLAY);
	}
}

public void HandlerTopMenu_WeaponSpawner(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "WeaponSpawnerTitle", LANG_SERVER);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "WeaponSpawner", LANG_SERVER);
	}
}	
// Main Menu Items
public void HandlerItemTopMenu_WeaponSpawner(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	char ItemName[32];  // The [5] character in the item name is used to identify the item.
	topmenu.GetObjName(object_id, ItemName, sizeof(ItemName));
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			switch(ItemName[5])
			{
				case 'a': Format(buffer, maxlength, "%T", "SpawnWeapon",			LANG_SERVER);
				case 'v': Format(buffer, maxlength, "%T", "GiveWeapon",				LANG_SERVER);
				case 'e': Format(buffer, maxlength, "%T", "SpawnSpecialInfected",	LANG_SERVER);
				case 'c': Format(buffer, maxlength, "%T", "SpawnUncommonZombie",	LANG_SERVER);
				case 'n': Format(buffer, maxlength, "%T", "MinigunMenu",			LANG_SERVER);
			}
		}
		case TopMenuAction_SelectOption:
		{
			switch(ItemName[5])
			{
				case 'a': DisplayMenu_WeaponSpawnerSubMenu(param, c_iFirstItemMenu, spawngive_submenu_name, spawngive_submenu_name,	"SpawnWeaponMenuTitle",		 SpawnMenu, 			spawngive_submenu_arrsize);
				case 'v': DisplayMenu_WeaponSpawnerSubMenu(param, c_iFirstItemMenu, spawngive_submenu_name,	spawngive_submenu_name,	"GiveWeaponMenuTitle",		 GiveMenu,			 	spawngive_submenu_arrsize);
				case 'e': DisplayMenu_WeaponSpawnerSubMenu(param, c_iFirstItemMenu, special_infected_name,	special_infected_param,	"SpawnSpecialInfectedTitle", SpecialInfectedMenu,	special_infected_arrsize);
				case 'c': DisplayMenu_WeaponSpawnerSubMenu(param, c_iFirstItemMenu, uncommon_zombie_name,	uncommon_zombie_param,	"SpawnUncommonZombieTitle",	 UncommonZombieMenu, 	uncommon_zombie_arrsize);
				case 'n': DisplayMenu_WeaponSpawnerSubMenu(param, c_iFirstItemMenu, minigun_name,			minigun_name,			"MinigunMenuTitle",			 MinigunMenu, 			minigun_arrsize);
			}
		}
	}
}

// Build and dislay submenu WeaponSpawner 
void DisplayMenu_WeaponSpawnerSubMenu(int client, int firstItemOfPage, const char[][] item_name,const char[][] item_param, char[] title, MenuHistory menu_name, const int items_array_size)
{
	char nameBuffer[32];
	Menu menu = new Menu(HandlerMenu_WeaponSpawnerSubMenu);
	for (int i = 0; i < items_array_size; i++)
	{
		Format(nameBuffer, sizeof(nameBuffer),"%T", item_name[i], LANG_SERVER);
		menu.AddItem(item_param[i], nameBuffer);	
	}
	Format(nameBuffer, sizeof(nameBuffer),"%T", title, LANG_SERVER);
	menu.SetTitle(nameBuffer);
	menu.ExitBackButton = true;
	Choosed_Menu[client] = menu_name; // save a name open menu
	menu.DisplayAt(client, firstItemOfPage, MENU_TIME_FOREVER);
}

public int HandlerMenu_WeaponSpawnerSubMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != null)
			{
				hTopMenu.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			if (Choosed_Menu[param1] == SpawnMenu)
			{
				switch(param2)
				{
					case 0:	DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, melee_name,		melee_param,		"MeleeMenuTitle",			MeleeBasedSpawnMenu,		melee_arrsize);
					case 1:	DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, bullet_based_name,	bullet_based_param,	"BulletBasedMenuTitle",		BulletBasedSpawnMenu,		bullet_based_arrsize);
					case 2:	DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, shell_based_name,	shell_based_param,	"ShellBasedMenuTitle",		ShellBasedSpawnMenu,		shell_based_arrsize);
					case 3:	DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, exp_based_name,	exp_based_param,	"ExplosiveBasedMenuTitle",	ExplosiveBasedSpawnMenu,	exp_based_arrsize);
					case 4:	DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, heal_based_name,	heal_based_param,	"HealthMenuTitle",			HealthSpawnMenu,			heal_based_arrsize);
					case 5:	DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, misc_based_name,	misc_based_param,	"MiscMenuTitle",			MiscSpawnMenu,				misc_based_arrsize);
				}
			}		
			else if (Choosed_Menu[param1] == GiveMenu)
			{
				switch(param2)
				{
					case 0: DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, melee_name,		melee_param,		"MeleeMenuTitle",			MeleeBasedGiveMenu,			melee_arrsize);
					case 1: DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, bullet_based_name, bullet_based_param,	"BulletBasedMenuTitle",		BulletBasedGiveMenu,		bullet_based_arrsize);
					case 2: DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, shell_based_name,	shell_based_param,	"ShellBasedMenuTitle",		ShellBasedGiveMenu,			shell_based_arrsize);
					case 3: DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, exp_based2_name,	exp_based2_param,	"ExplosiveBasedMenuTitle",	ExplosiveBasedGiveMenu,		exp_based2_arrsize);
					case 4: DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, heal_based2_name,	heal_based2_param,	"HealthMenuTitle",			HealthGiveMenu,				heal_based2_arrsize);
					case 5: DisplayMenu_SpawnOrGiveWeapons(param1, c_iFirstItemMenu, misc_based2_name,	misc_based2_param,	"MiscMenuTitle",			MiscGiveMenu,				misc_based2_arrsize);
				}
			}
			else if (Choosed_Menu[param1] == SpecialInfectedMenu)
			{
				char zombie_type[32];
				menu.GetItem(param2, zombie_type, sizeof(zombie_type));
				f_SpawnZombie(param1, zombie_type, 1);
				g_iFirstItemOfMenuPage[param1] = (param2 -(param2 % 7)); // number of the first object on the page of the selected object.
				DisplayMenu_WeaponSpawnerSubMenu(param1, g_iFirstItemOfMenuPage[param1], special_infected_name, special_infected_param, "SpawnSpecialInfectedTitle", SpecialInfectedMenu, special_infected_arrsize); //Redisplay menu.
			}
			else if (Choosed_Menu[param1] == UncommonZombieMenu)
			{
				switch (param2)
				{
					case 7:
						DisplayMenu_SetAmountInfected(param1); 
					default:
					{					
						char zombie_type[32];
						menu.GetItem(param2, zombie_type, sizeof(zombie_type));
						f_SpawnUncommonInfected(param1, zombie_type, g_iAmountUncommonZombie[param1]);
						DisplayMenu_WeaponSpawnerSubMenu(param1, c_iFirstItemMenu, uncommon_zombie_name, uncommon_zombie_param, "SpawnUncommonZombieTitle", UncommonZombieMenu, uncommon_zombie_arrsize); //Redisplay menu.
					}
				}
			}
			else if (Choosed_Menu[param1] == MinigunMenu)
			{		
				switch (param2)
				{
					case 0: f_SpawnMiniGun(param1, 1);
					case 1: f_SpawnMiniGun(param1, 2);
					case 2: f_RemoveMiniGun(param1);
				}	
				DisplayMenu_WeaponSpawnerSubMenu(param1, c_iFirstItemMenu, minigun_name, minigun_name, "MinigunMenuTitle", MinigunMenu, minigun_arrsize);
			}
		}
	}
}
// Build and dislay submenu GiveWeapon and SpawnWeapon of item WeaponSpawner Menu
void DisplayMenu_SpawnOrGiveWeapons(int client, int firstItemOfPage, const char[][] item_name,const char[][] item_param, char[] title, MenuHistory menu_name, const int items_array_size)
{
	char nameBuffer[32];
	Menu menu = new Menu(HandlerMenu_SpawnOrGiveWeapons);
	if((menu_name == MeleeBasedSpawnMenu) || (menu_name == MeleeBasedGiveMenu))
	{
		for (int i = 0; i < items_array_size; i++)
		{
			if (g_iMeleeWeaponsList[i] == -1) break;
			Format(nameBuffer, sizeof(nameBuffer),"%T", item_name[g_iMeleeWeaponsList[i]], LANG_SERVER);
			menu.AddItem(item_param[g_iMeleeWeaponsList[i]], nameBuffer);	
		}	
	}
	else
	{
		for (int i = 0; i < items_array_size; i++)
		{
			Format(nameBuffer, sizeof(nameBuffer),"%T", item_name[i], LANG_SERVER);
			menu.AddItem(item_param[i], nameBuffer);	
		}			
	}
	Format(nameBuffer, sizeof(nameBuffer),"%T", title, LANG_SERVER);
	menu.SetTitle(nameBuffer);
	menu.ExitBackButton = true;
	Choosed_Menu[client] = menu_name; // save a name open menu
	menu.DisplayAt(client, firstItemOfPage, MENU_TIME_FOREVER);
}

public int HandlerMenu_SpawnOrGiveWeapons(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
			{
				if(Choosed_Menu[param1] <= MiscSpawnMenu)
					DisplayMenu_WeaponSpawnerSubMenu(param1, c_iFirstItemMenu, spawngive_submenu_name, spawngive_submenu_name, "SpawnWeaponMenuTitle", SpawnMenu, spawngive_submenu_arrsize);
				else
					DisplayMenu_WeaponSpawnerSubMenu(param1, c_iFirstItemMenu, spawngive_submenu_name, spawngive_submenu_name, "GiveWeaponMenuTitle", GiveMenu, spawngive_submenu_arrsize);
			}
		case MenuAction_Select:
		{
			char sWeaponName[32];
			menu.GetItem(param2, sWeaponName, sizeof(sWeaponName));
			if(Choosed_Menu[param1] <= MiscSpawnMenu) // Spawn Weapons
			{
				int iMetadata;
				switch(Choosed_Menu[param1]) // get metadata
				{
					case MeleeBasedSpawnMenu:		iMetadata = 100 + CheckName(sWeaponName, melee_param, melee_arrsize);		
					case BulletBasedSpawnMenu:		iMetadata = 200 + param2;
					case ShellBasedSpawnMenu:		iMetadata = 300 + param2;
					case ExplosiveBasedSpawnMenu:	iMetadata = 400 + param2;
					case HealthSpawnMenu:			iMetadata = 500 + param2;
					case MiscSpawnMenu:				iMetadata = 600 + param2;
				}
				f_SpawnWeapon(param1, sWeaponName, 1, iMetadata);
				g_iFirstItemOfMenuPage[param1] = (param2 - (param2 % 7)); // number of the first object on the page of the selected object.
				RedisplayMenu_SpawnOrGiveWeapons(param1); //Redraw menu after item selected
			}
			else // Give Weapon
			{
				g_iFirstItemOfMenuPage[param1] = (param2 - (param2 % 7)); // number of the first object on the page of the selected object.
				DisplayMenu_PlayerSelect(param1, sWeaponName);
			}
		}
	}
}

void DisplayMenu_PlayerSelect(int client, char[] sWeaponName )
{	
	char nameBuffer[32];
	Menu menu = new Menu(HandlerMenu_PlayerSelect);
	menu.AddItem(sWeaponName, "", ITEMDRAW_IGNORE);  // transfer sWeaponName to menu handler
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS);
	Format(nameBuffer, sizeof(nameBuffer),"%T", "SelectPlayer", LANG_SERVER);
	menu.SetTitle(nameBuffer);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_PlayerSelect(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				RedisplayMenu_SpawnOrGiveWeapons(param1);
			}
		}
		case MenuAction_Select:
		{
			char sTargetUserID[64];
			menu.GetItem(param2, sTargetUserID, sizeof(sTargetUserID));	
			
			int iTargetClient[1];	/*void f_GiveWeapon(int target_count, int[] target_list, char[] weapon_name)*/
			iTargetClient[0] = GetClientOfUserId(StringToInt(sTargetUserID));	
			
			if ((iTargetClient[0]) == 0)
			{
				PrintToChat(param1, "%t", "PlayerSelectError_01", LANG_SERVER);
				RedisplayMenu_SpawnOrGiveWeapons(param1);
			}
			else if (!CanUserTarget(param1, iTargetClient[0]))
			{
				PrintToChat(param1, "%t", "PlayerSelectError_02", LANG_SERVER);
				RedisplayMenu_SpawnOrGiveWeapons(param1);
			}
			char sWeaponName[32];
			menu.GetItem(0, sWeaponName, sizeof(sWeaponName));	
			f_GiveWeapon(1, iTargetClient, sWeaponName, 999);
			RedisplayMenu_SpawnOrGiveWeapons(param1);
		}
	}
}

void RedisplayMenu_SpawnOrGiveWeapons(int client)
{
	switch (Choosed_Menu[client])
	{
		case MeleeBasedSpawnMenu:		DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], melee_name,			melee_param,		"MeleeMenuTitle",			MeleeBasedSpawnMenu,		melee_arrsize);
		case BulletBasedSpawnMenu:		DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], bullet_based_name,	bullet_based_param,	"BulletBasedMenuTitle",		BulletBasedSpawnMenu,		bullet_based_arrsize);
		case ShellBasedSpawnMenu:		DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], shell_based_name,	shell_based_param,	"ShellBasedMenuTitle",		ShellBasedSpawnMenu,		shell_based_arrsize);
		case ExplosiveBasedSpawnMenu:	DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], exp_based_name,		exp_based_param,	"ExplosiveBasedMenuTitle",	ExplosiveBasedSpawnMenu,	exp_based_arrsize);
		case HealthSpawnMenu:			DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], heal_based_name,		heal_based_param,	"HealthMenuTitle",			HealthSpawnMenu,			heal_based_arrsize);
		case MiscSpawnMenu:				DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], misc_based_name,		misc_based_param,	"MiscMenuTitle",			MiscSpawnMenu,				misc_based_arrsize);	
		case MeleeBasedGiveMenu:		DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], melee_name,			melee_param,		"MeleeMenuTitle",			MeleeBasedGiveMenu,			melee_arrsize);
		case BulletBasedGiveMenu:		DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], bullet_based_name,	bullet_based_param,	"BulletBasedMenuTitle",		BulletBasedGiveMenu,		bullet_based_arrsize);
		case ShellBasedGiveMenu:		DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], shell_based_name,	shell_based_param,	"ShellBasedMenuTitle",		ShellBasedGiveMenu,			shell_based_arrsize);
		case ExplosiveBasedGiveMenu:	DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], exp_based2_name,		exp_based2_param,	"ExplosiveBasedMenuTitle",	ExplosiveBasedGiveMenu,		exp_based2_arrsize);
		case HealthGiveMenu:			DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], heal_based2_name,	heal_based2_param,	"HealthMenuTitle",			HealthGiveMenu,				heal_based2_arrsize);
		case MiscGiveMenu:				DisplayMenu_SpawnOrGiveWeapons(client, g_iFirstItemOfMenuPage[client], misc_based2_name,	misc_based2_param,	"MiscMenuTitle",			MiscGiveMenu,				misc_based2_arrsize);
	}
}
// Build and dislay submenu UncommonInfected Menu
void DisplayMenu_SetAmountInfected(int client)
{
	Menu menu = new Menu(HandlerMenu_SetAmountInfected);
	if (g_iAmountUncommonZombie[client] == 1)
			{		menu.AddItem("1", "1 [active]");	}
	else	{		menu.AddItem("1", "1");				}
	if (g_iAmountUncommonZombie[client] == 5)
			{		menu.AddItem("5", "5 [active]");	}
	else	{		menu.AddItem("5", "5");				}	
	if (g_iAmountUncommonZombie[client] == 10)
			{		menu.AddItem("10", "10 [active]");	}
	else	{		menu.AddItem("10", "10");			}
	if (g_iAmountUncommonZombie[client] == 15)
			{		menu.AddItem("15", "15 [active]");	}
	else	{		menu.AddItem("15", "15");			}
	if (g_iAmountUncommonZombie[client] == 30)
			{		menu.AddItem("30", "30 [active]");	}
	else	{		menu.AddItem("30", "30");			}		
	if (g_iAmountUncommonZombie[client] == 45)
			{		menu.AddItem("45", "45 [active]");	}
	else	{		menu.AddItem("45", "45");			}
	if (g_iAmountUncommonZombie[client] == 60)	
			{		menu.AddItem("60", "60 [active]");	}
	else	{		menu.AddItem("60", "60");			}

	menu.ExitBackButton = true;
	char nameBuffer[32];
	Format(nameBuffer, sizeof(nameBuffer),"%T", "SetAmountInfectedTitle", LANG_SERVER);
	menu.SetTitle(nameBuffer);	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_SetAmountInfected(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu_WeaponSpawnerSubMenu(param1, c_iFirstItemMenu, uncommon_zombie_name, uncommon_zombie_param, "SpawnUncommonZombieTitle", UncommonZombieMenu, uncommon_zombie_arrsize); //Redisplay UncommonInfected menu.
			}
		}
		case MenuAction_Select:
		{		
			if (IsClientConnected(param1) && IsClientInGame(param1))
			{
				char amount[16];
				menu.GetItem(param2, amount, sizeof(amount));
				g_iAmountUncommonZombie[param1] = StringToInt(amount);
			}
			DisplayMenu_SetAmountInfected(param1);
		}
	}
}
/* >>> end of Weapon Action Menu */
stock void Define_melee_weapons_list()
{
	int iCampaignID;
	ArrayList buffer_id = new ArrayList(13);
	
	if (g_iCvar_AllowAllMeleeWeapons == 0)
	{
		char sMapName[128];
		char sCampaignID[3];
		GetCurrentMap(sMapName, sizeof(sMapName));
		if (sMapName[0] == 'c')
			for (int i = 1; i <= 3; i++)
			{
				switch (sMapName[i])
				{
					case 'm': 										{iCampaignID = StringToInt(sCampaignID); break;}
					case '0','1','2','3','4','5','6','7','8','9':	{if (i<3) sCampaignID[(i-1)] = sMapName[i]; else iCampaignID = 0;}
					default:										{iCampaignID = 0; break;}
				}
			}		
		else iCampaignID = 0;
	}
	else iCampaignID = 0;
	
	switch	(iCampaignID)
	{
		case 0:		buffer_id.PushArray({0,1,2,3,4,5,6,7,8,9,10,11,12}, 13);		// Campaign: Custom or Settings if cvar sm_spawnweapon_allowallmeleeweapons = 1
		case 1:		buffer_id.PushArray({0,1,2,4,6,7,8,-1,-1,-1,-1,-1,-1}, 13);		// Campaign: Dead Center
		case 2:		buffer_id.PushArray({0,2,3,4,7,8,-1,-1,-1,-1,-1,-1,-1}, 13);	// Campaign: Dark Carnival
		case 3:		buffer_id.PushArray({0,1,4,5,8,9,11,12,-1,-1,-1,-1,-1}, 13);	// Campaign: Swamp Fever
		case 4:		buffer_id.PushArray({0,2,4,5,7,8,11,12,-1,-1,-1,-1,-1}, 13);	// Campaign: Hard Rain
		case 5:		buffer_id.PushArray({0,3,5,8,9,10,12,-1,-1,-1,-1,-1,-1}, 13);	// Campaign: The Parish
		case 6:		buffer_id.PushArray({0,2,4,6,7,12,-1,-1,-1,-1,-1,-1,-1}, 13);	// Campaign: The Passing
		case 7:		buffer_id.PushArray({0,1,2,4,6,7,10,12,-1,-1,-1,-1,-1}, 13);	// Campaign: The Sacrifice
		case 8:		buffer_id.PushArray({0,2,4,7,8,10,12,-1,-1,-1,-1,-1,-1}, 13);	// Campaign: No Mercy
		case 9:		buffer_id.PushArray({0,1,2,4,5,6,10,-1,-1,-1,-1,-1,-1}, 13);	// Campaign: Crash Course
		case 10:	buffer_id.PushArray({0,2,4,5,8,9,10,12,-1,-1,-1,-1,-1}, 13);	// Campaign: Death Toll
		case 11:	buffer_id.PushArray({0,1,2,3,6,7,8,10,-1,-1,-1,-1,-1}, 13);		// Campaign: Dead Air
		case 12:	buffer_id.PushArray({0,2,4,5,8,9,10,11,12,-1,-1,-1,-1}, 13);	// Campaign: Blood Harvest
		case 13:	buffer_id.PushArray({0,4,7,8,9,10,12,-1,-1,-1,-1,-1,-1}, 13);	// Campaign: Cold Stream
		case 14:	buffer_id.PushArray({0,2,4,5,8,9,11,12,-1,-1,-1,-1,-1}, 13);	// Campaign: The Last Stand
		default:	buffer_id.PushArray({0,1,2,3,4,5,6,7,8,9,10,11,12}, 13);		// If some eroors
	}
	buffer_id.GetArray(0, g_iMeleeWeaponsList, 13);
	delete buffer_id;
}
/* >>> end of MENU CODE */

// ====================================================================================================
//					COMMON CODE AND OTHER
// ====================================================================================================
// Spawn Weapon
public void f_SpawnWeapon(int client, char[] weapon_name, int amount, int iMetadata)
{
	float fEntOrigin[3], fEntAngles[3];
	if(!SetTeleportEndPoint(client, fEntOrigin, fEntAngles))
	{
		PrintToChat(client, "%T", "SpawnError", LANG_SERVER);
		return;
	}
	
	if(iMetadata == 401) // 401 ExplosiveBarrel
	{
		fEntOrigin[2] += 0.4;
		for (int i = 1; i <= amount; i++)
		{
			int iEnt = CreateEntityByName("prop_fuel_barrel");
			DispatchKeyValue(iEnt, "model", "models/props_industrial/barrel_fuel.mdl");
			DispatchKeyValue(iEnt, "BasePiece", "models/props_industrial/barrel_fuel_partb.mdl");
			DispatchKeyValue(iEnt, "FlyingPiece01", "models/props_industrial/barrel_fuel_parta.mdl");
			DispatchKeyValue(iEnt, "DetonateParticles", "weapon_pipebomb");
			DispatchKeyValue(iEnt, "FlyingParticles", "barrel_fly");
			DispatchKeyValue(iEnt, "DetonateSound", "BaseGrenade.Explode");
			TeleportEntity(iEnt, fEntOrigin, fEntAngles, NULL_VECTOR); //Teleport weapon
			DispatchSpawn(iEnt); 
			fEntOrigin[2] += 46.0; // Z-axis correction for stacking appearance
		}
	}	
	else if(iMetadata == 602) // 602 LaserSight
	{
		char sEntOrigin[64];
		int iEnt = CreateEntityByName("upgrade_spawn");
		DispatchKeyValue(iEnt, "count", "1");
		DispatchKeyValue(iEnt, "laser_sight", "1");
		Format(sEntOrigin, sizeof(sEntOrigin), "%1.1f %1.1f %1.1f", fEntOrigin[0], fEntOrigin[1], fEntOrigin[2]);
		DispatchKeyValue(iEnt, "origin", sEntOrigin);
		DispatchKeyValue(iEnt, "classname", "upgrade_spawn");
		DispatchSpawn(iEnt);
	}	
	else if((iMetadata == 600) || (iMetadata == 601)) // 600, 601 AmmoStack
	{
		int iEntAmmostack = CreateEntityByName("weapon_ammo_spawn");
		if (iEntAmmostack != -1)
		{
			if (iMetadata == 601)
				SetEntityModel(iEntAmmostack, "models/props/terror/ammo_stack.mdl");
			else
				SetEntityModel(iEntAmmostack, "models/props_unique/spawn_apartment/coffeeammo.mdl");
		
			float position[3];
			float ang_eye[3];
			float ang_ent[3];
			float normal[3];
			if (!GetClientAimedLocationData(client, position, ang_eye, normal))
			{
				RemoveEdict(iEntAmmostack);
				PrintToChat(client, "%T", "SpawnError", LANG_SERVER);
				return;
			}
			
			GetVectorAngles(normal, ang_ent);
			ang_ent[0] += 90.0;
			float cross[3];
			float vec_eye[3];
			float vec_ent[3];
			GetAngleVectors(ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR);
			GetAngleVectors(ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR);
			GetVectorCrossProduct(vec_eye, normal, cross);
			float yaw = GetAngleBetweenVectors(vec_ent, cross, normal);
			RotateYaw(ang_ent, 90 + yaw);
			DispatchKeyValueVector(iEntAmmostack, "Origin", position);
			DispatchKeyValueVector(iEntAmmostack, "Angles", ang_ent);
			DispatchSpawn(iEntAmmostack);
		}	
	}
	else
	{
		if (iMetadata < 200) // all melee weapon
		{
			float fZstack;
			float fHalfsize;
			switch(iMetadata) // (fEntOrigin[2] += x.y) correction of coordinates along the z-axis in accordance with the size of the object
			{
				case 100: {fEntOrigin[2] += 2.0;	fEntAngles[2] += 90;	fHalfsize = 16.5;	fZstack = 3.2;}	// BaseballBat
				case 101: {fEntOrigin[2] += 2.0;	fEntAngles[2] += 90;	fHalfsize = 7.5;	fZstack = 2.3;}	// CricketBat
				case 102: {fEntOrigin[2] += 2.0;	fEntAngles[2] += 90;	fHalfsize = 12.5;	fZstack = 3.2;}	// Crowbar
				case 103: {fEntOrigin[2] += 2.0;	fEntAngles[2] += 90;	fHalfsize = 0.0;	fZstack = 1.5;}	// ElectricGuitar
				case 104: {fEntOrigin[2] += 1.5;	fEntAngles[2] += 90;	fHalfsize = 8.0;	fZstack = 3.5;}	// FireAxe
				case 105: {fEntOrigin[2] += 1.5;	fEntAngles[2] += 90;	fHalfsize = 7.5;	fZstack = 2.5;}	// FryingPan
				case 106: {fEntOrigin[2] += 3.0;	fEntAngles[2] += 90;	fHalfsize = 12.0;	fZstack = 4.0;}	// Golfclub
				case 107: {fEntOrigin[2] += 2.0;	fEntAngles[2] += 90;	fHalfsize = 10.5;	fZstack = 3.5;}	// Katana
				case 108: {fEntOrigin[2] += 2.0;	fEntAngles[2] += 90;	fHalfsize = 5.0;	fZstack = 2.0;}	// Knife
				case 109: {fEntOrigin[2] += 1.5;	fEntAngles[2] += 90;	fHalfsize = 10.5;	fZstack = 1.0;}	// Machete
				case 110: {fEntOrigin[2] += 2.0;	fEntAngles[2] += 90;	fHalfsize = 8.5;	fZstack = 2.0;}	// Tonfa
				case 111: {fEntOrigin[2] += 3.0;	fEntAngles[2] += 90;	fHalfsize = 7.5;	fZstack = 4.5;}	// Pitchfork
				case 112: {fEntOrigin[2] += 2.5;	fEntAngles[2] += 90;	fHalfsize = 7.5;	fZstack = 3.0;}	// Shovel
			}
			float vAngles[3], vShift[3];
			GetClientEyeAngles(client, vAngles);
			vAngles[0] = 0.0;
			vAngles[2] = 0.0;
			GetAngleVectors(vAngles, NULL_VECTOR, vShift, NULL_VECTOR);
			fEntOrigin[0] += vShift[0] * fHalfsize;
			fEntOrigin[1] += vShift[1] * fHalfsize;
			
			for (int i = 1; i <= amount; i++)
			{			
				int iEntWeapon = CreateEntityByName("weapon_melee");
				if(IsValidEntity(iEntWeapon))
				{
					DispatchKeyValue(iEntWeapon, "melee_script_name", weapon_name);
					TeleportEntity(iEntWeapon, fEntOrigin, fEntAngles, NULL_VECTOR); //Teleport spawned weapon
					DispatchSpawn(iEntWeapon); //Spawn weapon (entity)
					fEntOrigin[2] += fZstack;
				}
			}
		}
		else
		{
			float fZstack;
			int iMaxAmmo = -1;
			switch(iMetadata) // (fEntOrigin[2] += x.y) correction of coordinates along the z-axis in accordance with the size of the object
			{
				case 200: {fEntOrigin[2] += 1.8;	fEntAngles[1] -= 90;	fZstack = 7.0;	iMaxAmmo = g_iCvar_MaxAmmo_HuntingRifle;}		// HuntingRifle
				case 201: {fEntOrigin[2] += 2.4;	fEntAngles[1] -= 90;	fZstack = 7.0;	}												// Pistol
				case 202: {fEntOrigin[2] += 0.5;	fEntAngles[1] -= 90;	fZstack = 7.0;	}												// DesertEagle
				case 203: {fEntOrigin[2] += 4.0;	fEntAngles[1] -= 90;	fZstack = 11.0;	iMaxAmmo = g_iCvar_MaxAmmo_Assault;}			// Rifle
				case 204: {fEntOrigin[2] += 5.4;	fEntAngles[1] -= 90;	fZstack = 13.0;	iMaxAmmo = g_iCvar_MaxAmmo_Assault;}			// DesertRifle
				case 205: {fEntOrigin[2] += 5.9;	fEntAngles[1] -= 90;	fZstack = 10.0;	iMaxAmmo = g_iCvar_MaxAmmo_SMG;}				// SubmachineGun
				case 206: {fEntOrigin[2] += 6.4;	fEntAngles[1] -= 90;	fZstack = 10.0;	iMaxAmmo = g_iCvar_MaxAmmo_SMG;}				// SilencedSubmachineGun
				case 207: {fEntOrigin[2] += 1.4;	fEntAngles[1] -= 90;	fZstack = 11.0;	iMaxAmmo = g_iCvar_MaxAmmo_SniperRifle;}		// MilitarySniper
				case 208: {fEntOrigin[2] += 3.4;	fEntAngles[1] -= 90;	fZstack = 9.0;	iMaxAmmo = g_iCvar_MaxAmmo_Assault;}			// AvtomatKalashnikova
				case 209: {fEntOrigin[2] += 3.8;	fEntAngles[1] -= 90;	fZstack = 6.0;	iMaxAmmo = g_iCvar_MaxAmmo_Assault;}			// SIGSG550
				case 210: {fEntOrigin[2] += 5.4;	fEntAngles[1] -= 90;	fZstack = 12.0;	iMaxAmmo = g_iCvar_MaxAmmo_SMG;}				// SubmachineGunMP5
				case 211: {fEntOrigin[2] += 3.4;	fEntAngles[1] -= 90;	fZstack = 10.0;	}												// RifleM60
				case 212: {fEntOrigin[2] += 3.9;	fEntAngles[1] -= 90;	fZstack = 9.0;	iMaxAmmo = g_iCvar_MaxAmmo_SniperRifle;}		// AWP
				case 213: {fEntOrigin[2] += 2.8;	fEntAngles[1] -= 90;	fZstack = 7.0;	iMaxAmmo = g_iCvar_MaxAmmo_SniperRifle;}		// ScoutSniper
				case 300: {fEntOrigin[2] += 2.2;	fEntAngles[1] -= 90;	fZstack = 8.0;	iMaxAmmo = g_iCvar_MaxAmmo_AutoShotgun;}		// AutoShotgun
				case 301: {fEntOrigin[2] += 2.8;	fEntAngles[1] -= 90;	fZstack = 6.0;	iMaxAmmo = g_iCvar_MaxAmmo_Shotgun;}			// ChromeShotgun
				case 302: {fEntOrigin[2] += 2.2;	fEntAngles[1] -= 90;	fZstack = 8.0;	iMaxAmmo = g_iCvar_MaxAmmo_AutoShotgun;}		// SpasShotgun
				case 303: {fEntOrigin[2] += 2.8;	fEntAngles[1] -= 90;	fZstack = 6.0;	iMaxAmmo = g_iCvar_MaxAmmo_Shotgun;}			// PumpShotgun
				case 400: {fEntOrigin[2] += 1.9;	fEntAngles[1] -= 90;	fZstack = 9.0;	iMaxAmmo = g_iCvar_MaxAmmo_GrenadeLauncher;}	// GrenadeLauncher
				case 402: {fEntOrigin[2] += 2.8;	fEntAngles[1] -= 90;	fZstack = 6.0;	}												// FireworksCrate
				case 403: {fEntOrigin[2] += 10.7;							fZstack = 21.0;	}												// Gascan
				case 404: {fEntOrigin[2] += 5.2;							fZstack = 13.0;	}												// Molotov
				case 405: {fEntOrigin[2] += 11.0;							fZstack = 24.0;	}												// PropaneTank
				case 406: {fEntOrigin[2] += 4.8;							fZstack = 10.0;	}												// PipeBomb
				case 407: {fEntOrigin[2] += 0.2;							fZstack = 32.0;	}												// OxygenTank
				case 500: {fEntOrigin[2] += 0.5;							fZstack = 2.0;	}												// Adrenaline
				case 501: {fEntOrigin[2] += 0.4;							fZstack = 4.0;	}												// Defibrillator
				case 502: {fEntOrigin[2] += 0.3;	fEntAngles[1] += 180;	fZstack = 8.0;	}												// FirstAidKit
				case 503: {fEntOrigin[2] += 0.2;	fEntAngles[1] += 180;	fZstack = 6.0;	}												// PainPills
				case 603: {fEntOrigin[2] += 0.5;							fZstack = 9.0;	}												// ExplosiveAmmoPack
				case 604: {fEntOrigin[2] += 0.5;							fZstack = 9.0;	}												// IncendiaryAmmoPack
				case 605: {fEntOrigin[2] += 5.1;							fZstack = 14.0;	}												// VomitJar
				case 606: {fEntOrigin[2] += 4.3;	fEntAngles[1] += 90;	fZstack = 11.0;	}												// ChainSaw
				case 607: {fEntOrigin[2] += 11.2;	fEntAngles[1] += 180;	fZstack = 34.0;	}												// Gnome
				case 608: {fEntOrigin[2] += 1.2;							fZstack = 14.0;	}												// Cola
			}
			char weapon_name_ext[32];
			Format(weapon_name_ext, sizeof(weapon_name_ext), "weapon_%s", weapon_name);
			
			for (int i = 1; i <= amount; i++)
			{		
				int iEntWeapon = CreateEntityByName(weapon_name_ext);
				if(IsValidEntity(iEntWeapon))
				{		
					TeleportEntity(iEntWeapon, fEntOrigin, fEntAngles, NULL_VECTOR); //Teleport spawned weapon
					DispatchSpawn(iEntWeapon); //Spawn weapon (entity)
					if (iMaxAmmo > -1)
					{
						SetEntProp(iEntWeapon, Prop_Send, "m_iExtraPrimaryAmmo", iMaxAmmo ,4); //Add max ammo for gun
					}
					fEntOrigin[2] += fZstack; // Z-axis correction for stacking appearance
				}
			}
		}
	}
}

// Entity Position
bool SetTeleportEndPoint(int client, float vEndPosition[3], float vEndAngles[3])
{
	float vEyeOrigin[3];
	float vEyeAngles[3];
	
	GetClientEyePosition(client,vEyeOrigin);
	GetClientEyeAngles(client, vEyeAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vEyeOrigin, vEyeAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(hTrace))
	{
		float vVecBuffer[3];
		TR_GetEndPosition(vEndPosition, hTrace);
		GetAngleVectors(vEyeAngles, vVecBuffer, NULL_VECTOR, NULL_VECTOR);
		vEndPosition[0] += (vVecBuffer[0]*(-25));
		vEndPosition[1] += (vVecBuffer[1]*(-25));
		float vAngBuffer[3];
		NegateVector(vVecBuffer);
		GetVectorAngles(vVecBuffer, vAngBuffer);
		vEndAngles[0] = 0.0;
		vEndAngles[1] = vAngBuffer[1];
		vEndAngles[2] = 0.0;
	}
	else
	{
		delete hTrace;
		return false;
	}
	delete hTrace;
	return true;
}

bool GetClientAimedLocationData(int client, float position[3], float angles[3], float normal[3])
{
	float vEyeOrigin[3];
	float vEyeAngles[3];
	
	GetClientEyePosition(client, vEyeOrigin);
	GetClientEyeAngles(client, vEyeAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vEyeOrigin, vEyeAngles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(hTrace))
	{
		TR_GetEndPosition(position, hTrace);
		TR_GetPlaneNormal(hTrace, normal);	
		angles[0] = vEyeAngles[0];
		angles[1] = vEyeAngles[1];
		angles[2] = vEyeAngles[2];
	}
	else
	{
		delete hTrace;
		return false;
	}
	delete hTrace;
	return true;
}

public bool TraceEntityFilterPlayer(int entity,  int contentsMask)
{
	return ((entity > MaxClients) || (!entity));
}

void RotateYaw(float angles[3], float degree)
{
	float direction[3], normal[3];
	GetAngleVectors(angles, direction, NULL_VECTOR, normal);
	float sin = Sine( degree * 0.01745328 );	 // Pi/180
	float cos = Cosine( degree * 0.01745328 );
	float a = normal[0] * sin;
	float b = normal[1] * sin;
	float c = normal[2] * sin;
	float x = direction[2] * b + direction[0] * cos - direction[1] * c;
	float y = direction[0] * c + direction[1] * cos - direction[2] * a;
	float z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;
	GetVectorAngles(direction, angles);
	float up[3];
	GetVectorVectors(direction, NULL_VECTOR, up);
	float roll = GetAngleBetweenVectors(up, normal, direction);
	angles[2] += roll;
}

float GetAngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3])
{
	float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
	NormalizeVector(direction, direction_n);
	NormalizeVector(vector1, vector1_n);
	NormalizeVector(vector2, vector2_n);
	float degree = ArcCosine(GetVectorDotProduct(vector1_n, vector2_n)) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct(vector1_n, vector2_n, cross);
	if (GetVectorDotProduct(cross, direction_n) < 0.0)
	{
		degree *= -1.0;
	}
	return degree;
}
// Give Weapon
public void f_GiveWeapon(int target_count, int[] target_list, char[] weapon_name, int iMetadata)
{
	for (int i = 0; i < target_count; i++)
	{
		if (IsClientConnected(target_list[i]) && IsClientInGame(target_list[i]))
		{
			if ((iMetadata == 999) && ((strcmp(weapon_name, "laser_sight") == 0) || (strcmp(weapon_name, "explosive_ammo") == 0) || (strcmp(weapon_name, "incendiary_ammo") == 0))) // 999 call from menu handler
			{
				CheatCommand(target_list[i], "upgrade_add", weapon_name, "");
			}
			else if ((iMetadata == 102) || (iMetadata == 103) || (iMetadata == 104)) // 102 laser_sight, 103 explosive_ammo, 104 incendiary_ammo
			{
				CheatCommand(target_list[i], "upgrade_add", weapon_name, "");
			}
			else
			{
				CheatCommand(target_list[i], "give", weapon_name, "");
			}
		}
	}
}
// Spawn Special Infected
public void f_SpawnZombie(int client, char[] zombie_type, int amount)
{
	for (int i = 1; i <= amount; i++)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (!g_bPvpMode)
			{
				int iBot = CreateFakeClient("Infected Bot");
				if (iBot != 0)
				{
					ChangeClientTeam(iBot,3);
					CreateTimer(0.1,kickbot,iBot);
				}
			}
			CheatCommand(client, "z_spawn", zombie_type, "");
		}
	}
}

public Action kickbot(Handle timer, any client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}
}
// Spawn Uncommon Infected
public void f_SpawnUncommonInfected(int client, char[] zombie_type, int amount)
{
	char modelname[64];
	Format(modelname, sizeof(modelname), "models/infected/common_male_%s.mdl", zombie_type);
	g_sChangeZombieModelTo = modelname;
	int FlagsZSpawn = GetCommandFlags("z_spawn");	
	SetCommandFlags("z_spawn", FlagsZSpawn & ~FCVAR_CHEAT);
	for (int i = 0; i < amount; i++)
	{
		g_bCurrentlySpawning = true;
		FakeClientCommand(client, "z_spawn zombie");
	}
	SetCommandFlags("z_spawn", FlagsZSpawn|FCVAR_CHEAT);
	g_sChangeZombieModelTo = "";
}

public void OnEntityCreated(int entity, const char[] classname) //it sdkhooks callback function, here works in tandem with f_SpawnUncommonInfected()
{
	if (g_bCurrentlySpawning)
	{
		if (strcmp(classname, "infected", false) == 0)
		{
			g_bCurrentlySpawning = false;
			SetEntityModel(entity, g_sChangeZombieModelTo);
		}
	}
}
// Spawn Minigun
public void f_SpawnMiniGun(int client, int type)
{
	float vOrigin[3], vAngles[3], vDirection[3];
	int minigun;
	switch(type)
	{
		case 1:
		{
			minigun = CreateEntityByName("prop_minigun");
			if (minigun == -1)
			{
				ReplyToCommand(client, "%t", "MinigunError_01", LANG_SERVER);
				return;		
			}
			DispatchKeyValue(minigun, "model", "models/w_models/weapons/50cal.mdl");
		}	
		case 2:
		{
			minigun = CreateEntityByName("prop_minigun_l4d1");
			if (minigun == -1)
			{
				ReplyToCommand(client, "%t", "MinigunError_01", LANG_SERVER);
				return;	
			}
			DispatchKeyValue(minigun, "model", "models/w_models/weapons/w_minigun.mdl");
		}	
	}		
	DispatchKeyValueFloat (minigun, "MaxPitch", 360.00);
	DispatchKeyValueFloat (minigun, "MinPitch", -360.00);
	DispatchKeyValueFloat (minigun, "MaxYaw", 90.00);
	// Set position
	GetClientAbsOrigin(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	vAngles[0] = 0.0;
	vAngles[2] = 0.0;
	GetAngleVectors(vAngles, vDirection, NULL_VECTOR, NULL_VECTOR);
	vOrigin[0] += vDirection[0] * 32; // 32 - minigun collision box size, we move this size away from the player
	vOrigin[1] += vDirection[1] * 32; 
	DispatchKeyValueVector(minigun, "Angles", vAngles);
	TeleportEntity(minigun, vOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(minigun);
}

public void f_RemoveMiniGun(int client)
{
	char Classname[128];
	int minigun = GetClientAimTarget(client, false);
	if ((minigun == -1) || (!IsValidEntity (minigun)))
	{
		ReplyToCommand (client, "%t","AimTargetError_01");
		return;
	}
	GetEdictClassname(minigun, Classname, sizeof(Classname));
	if((strcmp(Classname, "prop_minigun_l4d1", false) == 0) || (strcmp(Classname, "prop_minigun", false) == 0))
	{
		RemoveEdict(minigun);
	}
	else
	{
		ReplyToCommand(client, "%t", "RemoveMinigunError_01");
	}
}
// other
public int CheckName(char[] check_arg, const char[][] control_arg, int sizeArray) // returns the index of the element in the string array if matched, otherwise -1
{
	for (int i = 0; i < sizeArray; i++)
	{
		if (strcmp(check_arg, control_arg[i], true) == 0)
		{
			return i;
		}
	}
	return -1;
}

public void CheatCommand(int client, char[] command, char[] argument1, char[] argument2)
{
	if (client == 0) return;
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}
/* >>> end of COMMON CODE */