#define PLUGIN_VERSION 		"1.1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Melee Weapon Spawner
*	Author	:	SilverShot and modified by Psykotik
*	Descrp	:	Spawns a single melee weapon fixed in position, these can be temporary or saved for auto-spawning.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=223020

========================================================================================
	Change Log:

1.1.1 (18-Aug-2013)
	- Changed the randomise slightly so melee spawn positions are better.

1.1 (09-Aug-2013)
	- Added cvar "l4d2_melee_spawn_randomise" to randomise the spawns based on a chance out of 100.

1.0 (09-Aug-2013)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	http://forums.alliedmods.net/showthread.php?t=109659

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function
	http://forums.alliedmods.net/showthread.php?t=93716

======================================================================================*/

#pragma semicolon 			1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Melee Spawn\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d2_melee_spawn.cfg"
#define MAX_SPAWNS			32
#define	MAX_MELEE			115

static	Handle:g_hCvarMPGameMode, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarAllow, Handle:g_hCvarRandom, Handle:g_hCvarRandomise,
		Handle:g_hMenuList, Handle:g_hMenuAng, Handle:g_hMenuPos, bool:g_bLoaded, bool:g_bCvarAllow, g_iCvarRandom, g_iCvarRandomise,
		g_iPlayerSpawn, g_iRoundStart, g_iSpawnCount, g_iSpawns[MAX_SPAWNS][2], g_iSave[MAXPLAYERS+1];

static String:g_sWeaponNames[MAX_MELEE][] =
{
	"Aether Pickaxe",
	"Aether Sword",
	"Anduril",
	"Arm",
	"Bamboo Stick",
	"Barnacle Gun",
	"Baseball Bat",
	"Battle Axe",
	"Biggoron Sword",
	"Black Electric Guitar",
	"Black Guitar",
	"Boxing Gloves",
	"Brown Broken Bottle",
	"Chains",
	"Chalice",
	"Classroom Chair",
	"Combat Knife",
	"Computer Keyboard",
	"Cricket Bat",
	"Crowbar",
	"Deku Stick",
	"Deployable Ammo Pack",
	"Diamond Hoe",
	"Diamond Shovel",
	"Diamond Sword",
	"Dustpan and Brush",
	"Electric Guitar",
	"Enchanted Sword",
	"Fire Axe",
	"Fishing Rod",
	"Flail",
	"Flail Mace",
	"Foam Finger",
	"Foot",
	"Frying Pan",
	"Fubar",
	"Garbage Set",
	"Golden Axe",
	"Golden Hoe",
	"Golden Pickaxe",
	"Golden Shovel",
	"Golf Club",
	"Green Broken Bottle",
	"Grey Guitar",
	"Guandao",
	"Hatchet",
	"Homewrecker",
	"Hylian Shield",
	"Improved Mace",
	"Improved Makeshift Flamethrower",
	"Iron Axe",
	"Iron Hoe",
	"Iron Pickaxe",
	"Iron Sword",
	"Katana",
	"Kink Map",
	"Kitchen Knife",
	"Lamp",
	"Large Concrete Stick",
	"Leg Bone",
	"Lego Sword",
	"Light Blue Mop",
	"Lightsaber",
	"M72 LAW",
	"Mace",
	"Machete",
	"Magic Wand",
	"Makeshift Flamethrower",
	"Master Sword",
	"Medium Concrete Stick",
	"Mega Hammer",
	"Mirror Shield",
	"Molten Sword",
	"Muffler",
	"Nail Bat",
	"Nail Stick",
	"Nightstick",
	"Nightstick and Riotshield",
	"Orange Guitar",
	"Orcrist",
	"Pain Train",
	"Palm Dagger",
	"Pickaxe",
	"Pink Mop",
	"Pink Mug",
	"Pipe Hammer",
	"Recurve Bow",
	"Riotshield",
	"Rockaxe",
	"Sauce Pot",
	"Shadow Claw",
	"Silver Hoe",
	"Silver Pickaxe",
	"Silver Shovel",
	"Silver Sword",
	"Skull Torch",
	"Skyrim Katana",
	"Slasher Blade",
	"Small Concrete Stick",
	"Sting",
	"Sword and Shield",
	"Syringe Gun",
	"Tire Iron",
	"Trash Can",
	"Vampire Sword",
	"Warrior Set",
	"Water Pipe",
	"Wooden Axe",
	"Wooden Bat",
	"Wooden Chair",
	"Wooden Pickaxe",
	"Wooden Shovel",
	"Wooden Sword",
	"Wrench",
	"Wulinmiji"
};
static String:g_sScripts[MAX_MELEE][] =
{
	"aetherpickaxe",
	"aethersword",
	"helms_anduril",
	"arm",
	"bamboo",
	"barnacle",
	"baseball_bat",
	"daxe",
	"bigoronsword",
	"guitar",
	"electric_guitar2",
	"gloves",
	"bottle",
	"chains",
	"weapon_chalice",
	"chair",
	"combat_knife",
	"computer_keyboard",
	"cricket_bat",
	"crowbar",
	"dekustick",
	"custom_ammo_pack",
	"dhoe",
	"dshovel",
	"dsword",
	"dustpan",
	"electric_guitar",
	"enchsword",
	"fireaxe",
	"fishingrod",
	"bnc",
	"weapon_morgenstern",
	"b_foamfinger",
	"foot",
	"frying_pan",
	"fubar",
	"gman",
	"gaxe",
	"ghoe",
	"gpickaxe",
	"gshovel",
	"golfclub",
	"b_brokenbottle",
	"electric_guitar4",
	"guandao",
	"helms_hatchet",
	"bt_sledge",
	"hylianshield",
	"mace2",
	"thrower",
	"iaxe",
	"ihoe",
	"ipickaxe",
	"isword",
	"katana",
	"doc1",
	"kitchen_knife",
	"lamp",
	"2_handed_concrete",
	"b_legbone",
	"legosword",
	"mop",
	"lightsaber",
	"m72law",
	"mace",
	"machete",
	"wand",
	"flamethrower",
	"mastersword",
	"concrete1",
	"hammer",
	"mirrorshield",
	"weapon_sof",
	"muffler",
	"nailbat",
	"sh2wood",
	"tonfa",
	"tonfa_riot",
	"electric_guitar3",
	"helms_orcrist",
	"bt_nail",
	"lobo",
	"pickaxe",
	"mop2",
	"scup",
	"pipehammer",
	"bow",
	"riotshield",
	"rockaxe",
	"pot",
	"weapon_shadowhand",
	"shoe",
	"spickaxe",
	"sshovel",
	"ssword",
	"btorch",
	"katana2",
	"slasher",
	"concrete2",
	"helms_sting",
	"longsword",
	"syringe_gun",
	"tireiron",
	"trashbin",
	"vampiresword",
	"helms_sword_and_shield",
	"waterpipe",
	"waxe",
	"woodbat",
	"chair2",
	"wpickaxe",
	"wshovel",
	"wsword",
	"wrench",
	"wulinmiji"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D2] Melee Weapon Spawner",
	author = "SilverShot and modified by Psykotik",
	description = "Spawns a single melee weapon fixed in position, these can be temporary or saved for auto-spawning.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=223020"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d2_melee_spawn_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_melee_spawn_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_melee_spawn_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_melee_spawn_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d2_melee_spawn_random",			"-1",			"-1=All, 0=None. Otherwise randomly select this many melee weapons to spawn from the maps config.", CVAR_FLAGS );
	g_hCvarRandomise =	CreateConVar(	"l4d2_melee_spawn_randomise",		"25",			"0=Off. Chance out of 100 to randomise the type of melee weapon regardless of what it's set to.", CVAR_FLAGS );
	CreateConVar(						"l4d2_melee_spawn_version",			PLUGIN_VERSION, "Melee Weapon Spawner plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_melee_spawn");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hCvarMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarRandom,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRandomise,		ConVarChanged_Cvars);

	RegAdminCmd("sm_melee_spawn",			CmdSpawnerTemp,		ADMFLAG_ROOT, 	"Opens a menu of melee weapons to spawn. Spawns a temporary melee weapon at your crosshair.");
	RegAdminCmd("sm_melee_spawn_save",		CmdSpawnerSave,		ADMFLAG_ROOT, 	"Opens a menu of melee weapons to spawn. Spawns a melee weapon at your crosshair and saves to config.");
	RegAdminCmd("sm_melee_spawn_del",		CmdSpawnerDel,		ADMFLAG_ROOT, 	"Removes the melee weapon you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_melee_spawn_clear",		CmdSpawnerClear,	ADMFLAG_ROOT, 	"Removes all melee weapons spawned by this plugin from the current map.");
	RegAdminCmd("sm_melee_spawn_wipe",		CmdSpawnerWipe,		ADMFLAG_ROOT, 	"Removes all melee weapons spawned by this plugin from the current map and deletes them from the config.");
	RegAdminCmd("sm_melee_spawn_glow",		CmdSpawnerGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all melee weapons to see where they are placed.");
	RegAdminCmd("sm_melee_spawn_list",		CmdSpawnerList,		ADMFLAG_ROOT, 	"Display a list melee weapon positions and the total number of.");
	RegAdminCmd("sm_melee_spawn_tele",		CmdSpawnerTele,		ADMFLAG_ROOT, 	"Teleport to a melee weapon (Usage: sm_melee_spawn_tele <index: 1 to MAX_SPAWNS (32)>).");
	RegAdminCmd("sm_melee_spawn_ang",		CmdSpawnerAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the melee weapon angles your crosshair is over.");
	RegAdminCmd("sm_melee_spawn_pos",		CmdSpawnerPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the melee weapon origin your crosshair is over.");



	g_hMenuList = CreateMenu(ListMenuHandler);
	for( new i = 0; i < MAX_MELEE; i++ )
	{
		AddMenuItem(g_hMenuList, "", g_sWeaponNames[i]);
	}
	SetMenuTitle(g_hMenuList, "Spawn Melee");
	SetMenuExitBackButton(g_hMenuList, true);
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	// Taken from MeleeInTheSaferoom
	PrecacheModel( "models/weapons/melee/v_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/v_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/v_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/v_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tonfa.mdl", true );
	PrecacheModel( "models/weapons/melee/v_two_handed_concrete.mdl", true );
	PrecacheModel( "models/weapons/melee/v_aetherpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_aethersword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_arm.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/v_b_brokenbottle.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/v_b_foamfinger.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/v_b_legbone.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_bamboo.mdl", true );
	PrecacheModel( "models/weapons/melee/v_barnacle.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_biggoron.mdl", true );
	PrecacheModel( "models/weapons/melee/v_bnc.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_bottle.mdl", true );
	PrecacheModel( "models/weapons/melee/v_bow.mdl", true );
	PrecacheModel( "models/weapons/melee/v_paintrain.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sledgehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/v_btorch.mdl", true);
	PrecacheModel( "models/byblo/weapons/melee/v_chains.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_chair.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_chair2.mdl", true );
	PrecacheModel( "models/v_models/v_knife_t.mdl", true );
	PrecacheModel( "models/weapons/melee/v_pckeyboard.mdl", true );
	PrecacheModel( "models/weapons/melee/v_concretev1.mdl", true );
	PrecacheModel( "models/weapons/melee/v_concretev2.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ammo_pack.mdl", true );
	PrecacheModel( "models/weapons/melee/v_daxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_dekustick.mdl", true );
	PrecacheModel( "models/weapons/melee/v_dhoe.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_doc1.mdl", true );
	PrecacheModel( "models/weapons/melee/v_dshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_dsword.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_dustpan.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar2.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar3.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar4.mdl", true );
	PrecacheModel( "models/weapons/melee/v_enchsword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_rod.mdl", true );
	PrecacheModel( "models/weapons/melee/v_flamethrower.mdl", true );
	PrecacheModel( "models/weapons/melee/v_foot.mdl", true );
	PrecacheModel( "models/weapons/melee/v_fubar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ghoe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gloves_box.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gman.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_guandao.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitrb.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_megahammer.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_anduril.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_hatchet.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_orcrist.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_sting.mdl", true );
	PrecacheModel( "models/weapons/melee/v_splinkswashere.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_shield.mdl", true );
	PrecacheModel( "models/weapons/melee/v_iaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ihoe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ipickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_isword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_katano.mdl", true );
	PrecacheModel( "models/weapons/melee/v_kitchen.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_lamp.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_lego.mdl", true );
	PrecacheModel( "models/weapons/v_lightsaber.mdl", true );
	PrecacheModel( "models/weapons/melee/v_lobo.mdl", true );
	PrecacheModel( "models/weapons/melee/v_longsword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_m72law.mdl", true );
	PrecacheModel( "models/weapons/melee/v_mace.mdl", true );
	PrecacheModel( "models/weapons/melee/v_mace2.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_msword.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_mirrorshield.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_mop.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_mop2.mdl", true );
	PrecacheModel( "models/weapons/melee/v_muffler.mdl", true );
	PrecacheModel( "models/weapons/melee/v_nailbat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_pickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_pipehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sauced_pot.mdl", true );
	PrecacheModel( "models/weapons/melee/v_riotshield.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_rockaxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_scup.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_sh2wood.mdl", true );
	PrecacheModel( "models/weapons/melee/v_shoe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_slasher.mdl", true );
	PrecacheModel( "models/weapons/melee/v_spickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ssword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_syringe_gun.mdl", true );
	PrecacheModel( "models/weapons/melee/v_thrower.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tireiron.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tonfa_riot.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_trashbin.mdl", true );
	PrecacheModel( "models/weapons/melee/v_vampiresword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wand.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_waterpipe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_waxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_chalice.mdl", true );
	PrecacheModel( "models/weapons/melee/v_morgenstern.mdl", true );
	PrecacheModel( "models/weapons/melee/v_shadowhand.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sof.mdl", true );
	PrecacheModel( "models/weapons/melee/v_btc.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wrench.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wsword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wulinmiji.mdl", true );
	
	PrecacheModel( "models/weapons/melee/w_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/w_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/w_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/w_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tonfa.mdl", true );
	PrecacheModel( "models/weapons/melee/w_two_handed_concrete.mdl", true );
	PrecacheModel( "models/weapons/melee/w_aetherpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_aethersword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_arm.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/w_b_brokenbottle.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/w_b_foamfinger.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/w_b_legbone.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_bamboo.mdl", true );
	PrecacheModel( "models/weapons/melee/w_barnacle.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_biggoron.mdl", true );
	PrecacheModel( "models/weapons/melee/w_bnc.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_bottle.mdl", true );
	PrecacheModel( "models/weapons/melee/w_bow.mdl", true );
	PrecacheModel( "models/weapons/melee/w_paintrain.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sledgehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/w_btorch.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_chains.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_chair.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_chair2.mdl", true );
	PrecacheModel( "models/w_models/weapons/w_knife_t.mdl", true );
	PrecacheModel( "models/weapons/melee/w_pckeyboard.mdl", true );
	PrecacheModel( "models/weapons/melee/w_concretev1.mdl", true );
	PrecacheModel( "models/weapons/melee/w_concretev2.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ammo_pack.mdl", true );
	PrecacheModel( "models/weapons/melee/w_daxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_dekustick.mdl", true );
	PrecacheModel( "models/weapons/melee/w_dhoe.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_doc1.mdl", true );
	PrecacheModel( "models/weapons/melee/w_dshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_dsword.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_dustpan.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar2.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar3.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar4.mdl", true );
	PrecacheModel( "models/weapons/melee/w_enchsword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_rod.mdl", true );
	PrecacheModel( "models/weapons/melee/w_flamethrower.mdl", true );
	PrecacheModel( "models/weapons/melee/w_foot.mdl", true );
	PrecacheModel( "models/weapons/melee/w_fubar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ghoe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gloves_box.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gman.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_guandao.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitrb.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_megahammer.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_anduril.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_hatchet.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_orcrist.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_sting.mdl", true );
	PrecacheModel( "models/weapons/melee/w_splinkswashereaswell.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_shield.mdl", true );
	PrecacheModel( "models/weapons/melee/w_iaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ihoe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ipickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_isword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_katano.mdl", true );
	PrecacheModel( "models/weapons/melee/w_kitchen.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_lamp.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_lego.mdl", true );
	PrecacheModel( "models/weapons/w_lightsaber.mdl", true );
	PrecacheModel( "models/weapons/melee/w_lobo.mdl", true );
	PrecacheModel( "models/weapons/melee/w_longsword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_m72law.mdl", true );
	PrecacheModel( "models/weapons/melee/w_mace.mdl", true );
	PrecacheModel( "models/weapons/melee/w_mace2.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_msword.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_mirrorshield.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_mop.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_mop2.mdl", true );
	PrecacheModel( "models/weapons/melee/w_muffler.mdl", true );
	PrecacheModel( "models/weapons/melee/w_nailbat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_pickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_pipehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sauced_pot.mdl", true );
	PrecacheModel( "models/weapons/melee/w_riotshield.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_rockaxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_scup.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_sh2wood.mdl", true );
	PrecacheModel( "models/weapons/melee/w_shoe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_slasher.mdl", true );
	PrecacheModel( "models/weapons/melee/w_spickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ssword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_syringe_gun.mdl", true );
	PrecacheModel( "models/weapons/melee/w_thrower.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tireiron.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tonfa_riot.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_trashbin.mdl", true );
	PrecacheModel( "models/weapons/melee/w_vampiresword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wand.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_waterpipe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_waxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_chalice.mdl", true );
	PrecacheModel( "models/weapons/melee/w_morgenstern.mdl", true );
	PrecacheModel( "models/weapons/melee/w_shadowhand.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sof.mdl", true );
	PrecacheModel( "models/weapons/melee/w_btc.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wrench.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wsword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wulinmiji.mdl", true );
	
	PrecacheGeneric( "scripts/melee/baseball_bat.txt", true );
	PrecacheGeneric( "scripts/melee/cricket_bat.txt", true );
	PrecacheGeneric( "scripts/melee/crowbar.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar.txt", true );
	PrecacheGeneric( "scripts/melee/fireaxe.txt", true );
	PrecacheGeneric( "scripts/melee/frying_pan.txt", true );
	PrecacheGeneric( "scripts/melee/golfclub.txt", true );
	PrecacheGeneric( "scripts/melee/katana.txt", true );
	PrecacheGeneric( "scripts/melee/machete.txt", true );
	PrecacheGeneric( "scripts/melee/tonfa.txt", true );
	PrecacheGeneric( "scripts/melee/2_handed_concrete.txt", true );
	PrecacheGeneric( "scripts/melee/aetherpickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/aethersword.txt", true );
	PrecacheGeneric( "scripts/melee/arm.txt", true );
	PrecacheGeneric( "scripts/melee/b_brokenbottle.txt", true );
	PrecacheGeneric( "scripts/melee/b_foamfinger.txt", true );
	PrecacheGeneric( "scripts/melee/b_legbone.txt", true );
	PrecacheGeneric( "scripts/melee/bamboo.txt", true );
	PrecacheGeneric( "scripts/melee/barnacle.txt", true );
	PrecacheGeneric( "scripts/melee/bigoronsword.txt", true );
	PrecacheGeneric( "scripts/melee/bnc.txt", true );
	PrecacheGeneric( "scripts/melee/bottle.txt", true );
	PrecacheGeneric( "scripts/melee/bow.txt", true );
	PrecacheGeneric( "scripts/melee/bt_nail.txt", true );
	PrecacheGeneric( "scripts/melee/bt_sledge.txt", true );
	PrecacheGeneric( "scripts/melee/btorch.txt", true );
	PrecacheGeneric( "scripts/melee/chains.txt", true );
	PrecacheGeneric( "scripts/melee/chair.txt", true );
	PrecacheGeneric( "scripts/melee/chair2.txt", true );
	PrecacheGeneric( "scripts/melee/combat_knife.txt", true );
	PrecacheGeneric( "scripts/melee/computer_keyboard.txt", true );
	PrecacheGeneric( "scripts/melee/concrete1.txt", true );
	PrecacheGeneric( "scripts/melee/concrete2.txt", true );
	PrecacheGeneric( "scripts/melee/custom_ammo_pack.txt", true );
	PrecacheGeneric( "scripts/melee/daxe.txt", true );
	PrecacheGeneric( "scripts/melee/dekustick.txt", true );
	PrecacheGeneric( "scripts/melee/dhoe.txt", true );
	PrecacheGeneric( "scripts/melee/doc1.txt", true );
	PrecacheGeneric( "scripts/melee/dshovel.txt", true );
	PrecacheGeneric( "scripts/melee/dsword.txt", true );
	PrecacheGeneric( "scripts/melee/dustpan.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar2.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar3.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar4.txt", true );
	PrecacheGeneric( "scripts/melee/enchsword.txt", true );
	PrecacheGeneric( "scripts/melee/fishingrod.txt", true );
	PrecacheGeneric( "scripts/melee/flamethrower.txt", true );
	PrecacheGeneric( "scripts/melee/foot.txt", true );
	PrecacheGeneric( "scripts/melee/fubar.txt", true );
	PrecacheGeneric( "scripts/melee/gaxe.txt", true );
	PrecacheGeneric( "scripts/melee/ghoe.txt", true );
	PrecacheGeneric( "scripts/melee/gloves.txt", true );
	PrecacheGeneric( "scripts/melee/gman.txt", true );
	PrecacheGeneric( "scripts/melee/gpickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/gshovel.txt", true );
	PrecacheGeneric( "scripts/melee/guandao.txt", true );
	PrecacheGeneric( "scripts/melee/guitar.txt", true );
	PrecacheGeneric( "scripts/melee/hammer.txt", true );
	PrecacheGeneric( "scripts/melee/helms_anduril.txt", true );
	PrecacheGeneric( "scripts/melee/helms_hatchet.txt", true );
	PrecacheGeneric( "scripts/melee/helms_orcrist.txt", true );
	PrecacheGeneric( "scripts/melee/helms_sting.txt", true );
	PrecacheGeneric( "scripts/melee/helms_sword_and_shield.txt", true );
	PrecacheGeneric( "scripts/melee/hylianshield.txt", true );
	PrecacheGeneric( "scripts/melee/iaxe.txt", true );
	PrecacheGeneric( "scripts/melee/ihoe.txt", true );
	PrecacheGeneric( "scripts/melee/ipickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/isword.txt", true );
	PrecacheGeneric( "scripts/melee/katana2.txt", true );
	PrecacheGeneric( "scripts/melee/kitchen_knife.txt", true );
	PrecacheGeneric( "scripts/melee/lamp.txt", true );
	PrecacheGeneric( "scripts/melee/legosword.txt", true );
	PrecacheGeneric( "scripts/melee/lightsaber.txt", true );
	PrecacheGeneric( "scripts/melee/lobo.txt", true );
	PrecacheGeneric( "scripts/melee/longsword.txt", true );
	PrecacheGeneric( "scripts/melee/m72law.txt", true );
	PrecacheGeneric( "scripts/melee/mace.txt", true );
	PrecacheGeneric( "scripts/melee/mace2.txt", true );
	PrecacheGeneric( "scripts/melee/mastersword.txt", true );
	PrecacheGeneric( "scripts/melee/mirrorshield.txt", true );
	PrecacheGeneric( "scripts/melee/mop.txt", true );
	PrecacheGeneric( "scripts/melee/mop2.txt", true );
	PrecacheGeneric( "scripts/melee/muffler.txt", true );
	PrecacheGeneric( "scripts/melee/nailbat.txt", true );
	PrecacheGeneric( "scripts/melee/pickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/pipehammer.txt", true );
	PrecacheGeneric( "scripts/melee/pot.txt", true );
	PrecacheGeneric( "scripts/melee/riotshield.txt", true );
	PrecacheGeneric( "scripts/melee/rockaxe.txt", true );
	PrecacheGeneric( "scripts/melee/scup.txt", true );
	PrecacheGeneric( "scripts/melee/sh2wood.txt", true );
	PrecacheGeneric( "scripts/melee/shoe.txt", true );
	PrecacheGeneric( "scripts/melee/slasher.txt", true );
	PrecacheGeneric( "scripts/melee/spickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/sshovel.txt", true );
	PrecacheGeneric( "scripts/melee/ssword.txt", true );
	PrecacheGeneric( "scripts/melee/syringe_gun.txt", true );
	PrecacheGeneric( "scripts/melee/thrower.txt", true );
	PrecacheGeneric( "scripts/melee/tireiron.txt", true );
	PrecacheGeneric( "scripts/melee/tonfa_riot.txt", true );
	PrecacheGeneric( "scripts/melee/trashbin.txt", true );
	PrecacheGeneric( "scripts/melee/vampiresword.txt", true );
	PrecacheGeneric( "scripts/melee/wand.txt", true );
	PrecacheGeneric( "scripts/melee/waterpipe.txt", true );
	PrecacheGeneric( "scripts/melee/waxe.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_chalice.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_morgenstern.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_shadowhand.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_sof.txt", true );
	PrecacheGeneric( "scripts/melee/woodbat.txt", true );
	PrecacheGeneric( "scripts/melee/wpickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/wrench.txt", true );
	PrecacheGeneric( "scripts/melee/wshovel.txt", true );
	PrecacheGeneric( "scripts/melee/wsword.txt", true );
	PrecacheGeneric( "scripts/melee/wulinmiji.txt", true );
}

public OnMapEnd()
{
	ResetPlugin(false);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	g_iCvarRandom = GetConVarInt(g_hCvarRandom);
	g_iCvarRandomise = GetConVarInt(g_hCvarRandomise);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		LoadSpawns();
		g_bCvarAllow = true;
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == INVALID_HANDLE )
		return false;

	new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		new entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hCvarMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetPlugin(false);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart);
	g_iRoundStart = 1;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart);
	g_iPlayerSpawn = 1;
}

public Action:tmrStart(Handle:timer)
{
	ResetPlugin();
	LoadSpawns();
}



// ====================================================================================================
//					LOAD SPAWNS
// ====================================================================================================
LoadSpawns()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many Melees to display
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few Melees?
	new iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved Melees or create random
	new iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( new i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the Melee origins and spawn
	decl String:sTemp[10], Float:vPos[3], Float:vAng[3];
	new index, iMod;
	for( new i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetVector(hFile, "ang", vAng);
			KvGetVector(hFile, "pos", vPos);
			iMod = KvGetNum(hFile, "mod");

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index, iMod, true);
			KvGoBack(hFile);
		}
	}

	CloseHandle(hFile);
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
CreateSpawn(const Float:vOrigin[3], const Float:vAngles[3], index = 0, model = 0, autospawn = false)
{
	if( g_iSpawnCount >= MAX_SPAWNS )
		return;

	new iSpawnIndex = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == 0 )
		{
			iSpawnIndex = i;
			break;
		}
	}

	if( iSpawnIndex == -1 )
		return;


	new entity_weapon = -1;
	entity_weapon = CreateEntityByName("weapon_melee");
	if( entity_weapon == -1 )
		ThrowError("Failed to create entity 'weapon_melee'.");

	if( autospawn && g_iCvarRandomise && GetRandomInt(0, 100) <= g_iCvarRandomise )
		model = GetRandomInt(0, MAX_MELEE-1);

	DispatchKeyValue(entity_weapon, "solid", "6");
	DispatchKeyValue(entity_weapon, "melee_script_name", g_sScripts[model]);

	DispatchSpawn(entity_weapon);
	if( model == 4 || model == 6 )
	{
		if( model == 4 )
		{
			decl Float:vPos[3];
			vPos = vOrigin;
			vPos[2] += 0.6;
			TeleportEntity(entity_weapon, vPos, vAngles, NULL_VECTOR);
		} else {
			decl Float:vAng[3];
			vAng = vAngles;
			vAng[0] += 180.0;
			vAng[1] += 180.0;
			TeleportEntity(entity_weapon, vOrigin, vAng, NULL_VECTOR);
		}
	} else {
		TeleportEntity(entity_weapon, vOrigin, vAngles, NULL_VECTOR);
	}

	SetEntityMoveType(entity_weapon, MOVETYPE_NONE);

	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(entity_weapon);
	g_iSpawns[iSpawnIndex][1] = index;

	g_iSpawnCount++;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_melee_spawn
// ====================================================================================================
public ListMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( g_iSave[client] == 0 )
		{
			CmdSpawnerTempMenu(client, index);
		} else {
			CmdSpawnerSaveMenu(client, index);
		}

		DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);
	}
}

public Action:CmdSpawnerTemp(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melees. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	g_iSave[client] = 0;
	DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

CmdSpawnerTempMenu(client, weapon)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Commands may only be used in-game on a dedicated server..");
		return;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melees. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return;
	}

	new Float:vPos[3], Float:vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place Melee, please try again.", CHAT_TAG);
		return;
	}

	CreateSpawn(vPos, vAng, 0, weapon);
	return;
}

// ====================================================================================================
//					sm_melee_spawn_save
// ====================================================================================================
public Action:CmdSpawnerSave(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melees. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	g_iSave[client] = 1;
	DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

CmdSpawnerSaveMenu(client, weapon)
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		new Handle:hCfg = OpenFile(sPath, "w");
		WriteFileLine(hCfg, "");
		CloseHandle(hCfg);
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Melee Spawn config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);
	if( !KvJumpToKey(hFile, sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Melee Spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many Melee Spawns are saved
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melee Spawns. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
		CloseHandle(hFile);
		return;
	}

	// Save count
	iCount++;
	KvSetNum(hFile, "num", iCount);

	decl String:sTemp[10];

	IntToString(iCount, sTemp, sizeof(sTemp));

	if( KvJumpToKey(hFile, sTemp, true) )
	{
		new Float:vPos[3], Float:vAng[3];
		// Set player position as Melee Spawn location
		if( !SetTeleportEndPoint(client, vPos, vAng) )
		{
			PrintToChat(client, "%sCannot place Melee Spawn, please try again.", CHAT_TAG);
			CloseHandle(hFile);
			return;
		}

		// Save angle / origin
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);
		KvSetNum(hFile, "mod", weapon);

		CreateSpawn(vPos, vAng, iCount, weapon);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Melee Spawn.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
}

// ====================================================================================================
//					sm_melee_spawn_del
// ====================================================================================================
public Action:CmdSpawnerDel(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Melee Spawn] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	new cfgindex, index = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	cfgindex = g_iSpawns[index][1];
	if( cfgindex == 0 )
	{
		RemoveSpawn(index);
		return Plugin_Handled;
	}

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][1] > cfgindex )
			g_iSpawns[i][1]--;
	}

	g_iSpawnCount--;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Melee Spawn config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Melee Spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many Melee Spawns
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	new bool:bMove;
	decl String:sTemp[16];

	// Move the other entries down
	for( new i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			if( !bMove )
			{
				bMove = true;
				KvDeleteThis(hFile);
				RemoveSpawn(index);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				KvSetSectionName(hFile, sTemp);
			}
		}

		KvRewind(hFile);
		KvJumpToKey(hFile, sMap);
	}

	if( bMove )
	{
		iCount--;
		KvSetNum(hFile, "num", iCount);

		// Save to file
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Melee Spawn removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Melee Spawn from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_clear
// ====================================================================================================
public Action:CmdSpawnerClear(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Melee Spawns removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_wipe
// ====================================================================================================
public Action:CmdSpawnerWipe(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Melee Spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	KvDeleteThis(hFile);
	ResetPlugin();

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(0/%d) - All Melee Spawns removed from config, add with \x05sm_melee_spawn_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_glow
// ====================================================================================================
public Action:CmdSpawnerGlow(client, args)
{
	static bool:glow;
	glow = !glow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, glow ? "on" : "off");

	VendorGlow(glow);
	return Plugin_Handled;
}

VendorGlow(glow)
{
	new ent;

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		ent = g_iSpawns[i][0];
		if( IsValidEntRef(ent) )
		{
			SetEntProp(ent, Prop_Send, "m_iGlowType", glow ? 3 : 0);
			if( glow )
			{
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 255);
				SetEntProp(ent, Prop_Send, "m_nGlowRange", glow ? 0 : 50);
			}
		}
	}
}

// ====================================================================================================
//					sm_melee_spawn_list
// ====================================================================================================
public Action:CmdSpawnerList(client, args)
{
	decl Float:vPos[3];
	new count;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( IsValidEntRef(g_iSpawns[i][0]) )
		{
			count++;
			GetEntPropVector(g_iSpawns[i][0], Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}
	PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_tele
// ====================================================================================================
public Action:CmdSpawnerTele(client, args)
{
	if( args == 1 )
	{
		decl String:arg[16];
		GetCmdArg(1, arg, 16);
		new index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_SPAWNS && IsValidEntRef(g_iSpawns[index][0]) )
		{
			decl Float:vPos[3];
			GetEntPropVector(g_iSpawns[index][0], Prop_Data, "m_vecOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_melee_spawn_tele <index 1-%d>.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action:CmdSpawnerAng(client, args)
{
	ShowMenuAng(client);
	return Plugin_Handled;
}

ShowMenuAng(client)
{
	CreateMenus();
	DisplayMenu(g_hMenuAng, client, MENU_TIME_FOREVER);
}

public AngMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}
}

SetAngle(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vAng[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				if( index == 0 ) vAng[0] += 2.0;
				else if( index == 1 ) vAng[1] += 2.0;
				else if( index == 2 ) vAng[2] += 2.0;
				else if( index == 3 ) vAng[0] -= 2.0;
				else if( index == 4 ) vAng[1] -= 2.0;
				else if( index == 5 ) vAng[2] -= 2.0;

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action:CmdSpawnerPos(client, args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

ShowMenuPos(client)
{
	CreateMenus();
	DisplayMenu(g_hMenuPos, client, MENU_TIME_FOREVER);
}

public PosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

SetOrigin(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vPos[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				if( index == 0 ) vPos[0] += 0.5;
				else if( index == 1 ) vPos[1] += 0.5;
				else if( index == 2 ) vPos[2] += 0.5;
				else if( index == 3 ) vPos[0] -= 0.5;
				else if( index == 4 ) vPos[1] -= 0.5;
				else if( index == 5 ) vPos[2] -= 0.5;

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}

SaveData(client)
{
	new entity, index;
	new aim = GetClientAimTarget(client, false);
	if( aim == -1 )
		return;

	aim = EntIndexToEntRef(aim);

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		entity = g_iSpawns[i][0];

		if( entity == aim  )
		{
			index = g_iSpawns[i][1];
			break;
		}
	}

	if( index == 0 )
		return;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Melee Spawn config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Melee Spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	decl Float:vAng[3], Float:vPos[3], String:sTemp[32];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
	if( KvJumpToKey(hFile, sTemp) )
	{
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%sSaved origin and angles to the data config", CHAT_TAG);
	}
}

CreateMenus()
{
	if( g_hMenuAng == INVALID_HANDLE )
	{
		g_hMenuAng = CreateMenu(AngMenuHandler);
		AddMenuItem(g_hMenuAng, "", "X + 2.0");
		AddMenuItem(g_hMenuAng, "", "Y + 2.0");
		AddMenuItem(g_hMenuAng, "", "Z + 2.0");
		AddMenuItem(g_hMenuAng, "", "X - 2.0");
		AddMenuItem(g_hMenuAng, "", "Y - 2.0");
		AddMenuItem(g_hMenuAng, "", "Z - 2.0");
		AddMenuItem(g_hMenuAng, "", "SAVE");
		SetMenuTitle(g_hMenuAng, "Set Angle");
		SetMenuExitButton(g_hMenuAng, true);
	}

	if( g_hMenuPos == INVALID_HANDLE )
	{
		g_hMenuPos = CreateMenu(PosMenuHandler);
		AddMenuItem(g_hMenuPos, "", "X + 0.5");
		AddMenuItem(g_hMenuPos, "", "Y + 0.5");
		AddMenuItem(g_hMenuPos, "", "Z + 0.5");
		AddMenuItem(g_hMenuPos, "", "X - 0.5");
		AddMenuItem(g_hMenuPos, "", "Y - 0.5");
		AddMenuItem(g_hMenuPos, "", "Z - 0.5");
		AddMenuItem(g_hMenuPos, "", "SAVE");
		SetMenuTitle(g_hMenuPos, "Set Position");
		SetMenuExitButton(g_hMenuPos, true);
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

ResetPlugin(bool:all = true)
{
	g_bLoaded = false;
	g_iSpawnCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	if( all )
		for( new i = 0; i < MAX_SPAWNS; i++ )
			RemoveSpawn(i);
}

RemoveSpawn(index)
{
	new entity, client;

	entity = g_iSpawns[index][0];
	g_iSpawns[index][0] = 0;
	g_iSpawns[index][1] = 0;

	if( IsValidEntRef(entity) )
	{
		client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if( client < 0 || client > MaxClients || !IsClientInGame(client) )
		{
			AcceptEntityInput(entity, "kill");
		}
	}
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
Float:GetGroundHeight(Float:vPos[3])
{
	new Float:vAng[3], Handle:trace = TR_TraceRayFilterEx(vPos, Float:{ 90.0, 0.0, 0.0 }, MASK_ALL, RayType_Infinite, _TraceFilter);
	if( TR_DidHit(trace) )
		TR_GetEndPosition(vAng, trace);

	CloseHandle(trace);
	return vAng[2];
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
SetTeleportEndPoint(client, Float:vPos[3], Float:vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if(TR_DidHit(trace))
	{
		decl Float:vNorm[3];
		new Float:degrees = vAng[1];
		TR_GetEndPosition(vPos, trace);
		GetGroundHeight(vPos);
		vPos[2] += 1.0;
		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);
		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] = degrees + 180;
		}
		else
		{
			if( degrees > vAng[1] )
				degrees = vAng[1] - degrees;
			else
				degrees = degrees - vAng[1];
			vAng[0] += 90.0;
			RotateYaw(vAng, degrees + 180);
		}
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);

	vAng[1] += 90.0;
	vAng[2] -= 90.0;
	return true;
}

public bool:_TraceFilter(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}



//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
RotateYaw( Float:angles[3], Float:degree )
{
	decl Float:direction[3], Float:normal[3];
	GetAngleVectors( angles, direction, NULL_VECTOR, normal );

	new Float:sin = Sine( degree * 0.01745328 );	 // Pi/180
	new Float:cos = Cosine( degree * 0.01745328 );
	new Float:a = normal[0] * sin;
	new Float:b = normal[1] * sin;
	new Float:c = normal[2] * sin;
	new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
	new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
	new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles( direction, angles );

	decl Float:up[3];
	GetVectorVectors( direction, NULL_VECTOR, up );

	new Float:roll = GetAngleBetweenVectors( up, normal, direction );
	angles[2] += roll;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
Float:GetAngleBetweenVectors( const Float:vector1[3], const Float:vector2[3], const Float:direction[3] )
{
	decl Float:vector1_n[3], Float:vector2_n[3], Float:direction_n[3], Float:cross[3];
	NormalizeVector( direction, direction_n );
	NormalizeVector( vector1, vector1_n );
	NormalizeVector( vector2, vector2_n );
	new Float:degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct( vector1_n, vector2_n, cross );

	if ( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}