//Index
//1: Variables
//2: Init array list
//3: Database (SQLITE) func.
//4: Hook events
//5: Overrided functions
//6: Control points
//7: important functions
//8: Earning points hook functions
//9: Admin menu (ref: all4dead)
//10: Menu setting functions
//11: Handle commands functions
//12: Handle menu selected functions.

/*
										Update LOG
====================================================================================================
v2.7 (23 May 2021)
	- Fixed Shop Commands does not show in the Admin menu sometime.

v2.6 (4 May 2021)
	- Fixed !buy heal command

v2.52 (3 May 2021)
	- Changed MaxClients to MAXPLAYERS 
	- Supported 18+ players' server.
	- Fixed sql update statement for SF.

v2.4 (1 May 2021)
	- Cleared the hard-coded print text.
	- Flxed when player left, SF doesn't not clear.
	- Removed cost limitation
	- Added more shortcut

v2.3 (30 April 2021)
	- Added the checking for Infected Shop (cvar_infected_buy_respawn_on in .cfg)
	- Simplified shortcut variables
	- Changed the Points Transfer menu title

v2.2 (30 April 2021): 
	- Changed MaxClients from 20 to 18 to fix Client index 19 is invalid.
	- Added !buy <item> command (Shortcut item names provided by: Elite Biker)
	- Added disabling option for SF (just set the cost of it to -1)
	- Added disabling specified shop
	- Added transferring message to all players
	- Fixed Infected Shop bug.
	- Added cfg cvar_shop_infected_respawn to decide Where player respawn after buying infected
====================================================================================================
*/

// ====================================================================================================
//					pan0s | 1: Variables
// ====================================================================================================
// 
#define DEFAULT_FLAGS FCVAR_NOTIFY
#define ADMIN_ADD_POINT			0
#define ADMIN_CONFISCATE		1
#define ADMIN_SET_POINT			2
#define ADMIN_ACTION_SIZE		4
#define PLUGIN_VERSION "v2.6"
#define CVAR_FLAGS FCVAR_NOTIFY

#include <sdktools>
#include <sourcemod>
#include <adminmenu>
#include <sdkhooks>
#include <pan0s>
#undef REQUIRE_PLUGIN

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name = "[L4D2] Points and Gift System",
    author = "v2.0+ Updated by pan0s. Original author: Drakcol - Fixed by AXIS_ASAKI",
    description = "An item buying system for Left 4 Dead 2 that is based on (-DR-)GrammerNatzi's Left 4 Dead 1 item buying system. This plug-in allows clients to gain points through various accomplishments and use them to buy items and health/ammo refills. It also allows admins to gift the same things to MaxClients and grant them god mode. Both use menus, no less.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=332186"
}

/*Convar Variables*/
ConVar cvar_points_on;
ConVar cvar_points_versus_on;
ConVar cvar_points_realism_on;
ConVar cvar_points_survival_on;
ConVar cvar_points_team_survival_on;
ConVar cvar_points_team_versus_on;
ConVar cvar_points_coop_on;
ConVar cvar_points_scavenger_on;
ConVar cvar_db_on;
ConVar cvar_round_clear_on;
ConVar cvar_transfer_on;
ConVar cvar_transfer_handling_fee;
ConVar cvar_transfer_notify_all_on;
ConVar cvar_buy_notify_all_on;
ConVar cvar_suicide_cmd_on;
ConVar cvar_sf_on;
ConVar cvar_infected_buy_respawn_on;

ConVar cvar_shop_infected_respawn;
ConVar cvar_iearn_grab, cvar_iearn_pounce;
ConVar cvar_iearn_incapacitate;
ConVar cvar_iearn_vomit;
ConVar cvar_iearn_charge;
ConVar cvar_iearn_charge_collateral;
ConVar cvar_iearn_jockey_ride;
ConVar cvar_iearn_hurt;
ConVar cvar_iearn_survivor;

ConVar cvar_earn_witch_in_one_shot;
ConVar cvar_earn_witch;
ConVar cvar_earn_tank_burn;
ConVar cvar_earn_tank_killed;
ConVar cvar_earn_infected_num;
ConVar cvar_earn_infected;
ConVar cvar_earn_special;
ConVar cvar_earn_heal;
ConVar cvar_earn_revive;
ConVar cvar_earn_revive_ledge_hang;
ConVar cvar_earn_protect;
ConVar cvar_earn_defibrillate;
ConVar cvar_earn_rescued;

/*Item-Related Convars*/
ConVar cvar_tank_limit;
ConVar cvar_witch_limit;

ConVar cvar_invoice_type;

//Laser tag
#define WEAPONTYPE_PISTOL   6
#define WEAPONTYPE_RIFLE    5
#define WEAPONTYPE_SNIPER   4
#define WEAPONTYPE_SMG      3
#define WEAPONTYPE_SHOTGUN  2
#define WEAPONTYPE_MELEE    1
#define WEAPONTYPE_UNKNOWN  0

//Special Functions
#define AUTO_BHOP		0
#define GRAY_AMMO		1
#define GREEN_AMMO		2
#define BLUE_AMMO		3
#define GOLD_AMMO		4
#define RED_AMMO		5
#define SF_SIZE 		6

#define AMMO_SIZE 		5

ConVar cvar_pistols;
ConVar cvar_rifles;
ConVar cvar_snipers;
ConVar cvar_smgs;
ConVar cvar_shotguns;

ConVar cvar_laser_life;
ConVar cvar_laser_width;
ConVar cvar_laser_offset;

/*Some Important Variables*/
bool b_TagWeapon[7];
bool g_bIsShown[MAXPLAYERS + 1];
bool g_bPointsOn;
bool g_bTankOnFire[MAXPLAYERS + 1];
bool g_bClientSF[MAXPLAYERS + 1][2][SF_SIZE]; // The 2nd array, 0 = Trial, 1 = Permanent , // bool to turn on/off client special funcions

float g_LaserOffset;
float g_LaserWidth;
float g_LaserLife;

int g_LaserColor[4];
int g_Sprite;
int g_iGodOn[MAXPLAYERS + 1];
int g_iPoints[MAXPLAYERS + 1];
int g_iKilledInfectedCount[MAXPLAYERS + 1];
int g_iNoOfTanks;
int g_iNoOfWitches;
int g_iHurtCount[MAXPLAYERS + 1];

Menu g_hMenus[MAXPLAYERS + 1];

// SHOP_INDEX
enum 
{
	SHOP_MAIN	 				= 0,
	SHOP_INFECTED 				= 1,
	SHOP_GUNS	 				= 2,
	SHOP_SMGS 					= 3,
	SHOP_RIFLES 				= 4,
	SHOP_SNIPERS 				= 5,
	SHOP_SHOTGUNS 				= 6,
	SHOP_OTHERS 				= 7,
	SHOP_MELEES 				= 8,
	SHOP_THROWABLES 			= 9,
	SHOP_AMMOS 					= 10,
	SHOP_MEDICINES				= 11,
	SHOP_SF						= 12,
	SHOP_SF_TRIAL 				= 13,
	SHOP_SF_PERMANENT 			= 14,
	SHOP_SF_BAG					= 15,
	SHOP_TRANSFER				= 16,
	SHOP_SIZE					= 17,
};

ConVar cvar_shops_on[SHOP_SIZE];

// how to open the above shops by cmd
char g_sShopCmds[SHOP_SIZE][64];

char g_sShopTitles[][] = 
{
	"WELCOME",
	"SHOP_INFECTED",
	"SHOP_GUNS",
	"SHOP_SMGS",
	"SHOP_RIFLES",
	"SHOP_SNIPERS",
	"SHOP_SHOTGUNS",
	"SHOP_OTHERS",
	"SHOP_MELEES",
	"SHOP_THROWABLES",
	"SHOP_AMMOS",
	"SHOP_MEDICINES",
	"SHOP_SF",
	"SHOP_SF_TRIAL",
	"SHOP_SF_PERMANENT",
	"SHOP_SF_BAG",
	"SHOP_TRANSFER",
};

// Shop menu
char g_sShop[][] = {"SHOP_GUNS","SHOP_MELEES","SHOP_THROWABLES","SHOP_AMMOS","SHOP_MEDICINES","SHOP_SF","SHOP_TRANSFER"};
char g_sGunsShop[][] = {"SHOP_SMGS","SHOP_RIFLES","SHOP_SNIPERS","SHOP_SHOTGUNS","SHOP_OTHERS",};
char g_sSFShop[][] = {"SHOP_SF_TRIAL","SHOP_SF_PERMANENT", "SHOP_SF_BAG",};

// Shop items ------------------------------------>
char g_sInfectedItems[][] = 
{                      				// Infected Items ID:
	"kill",            				// 0
	"health",          				// 1
    "boomer",          				// 2
    "hunter",          				// 3
    "smoker",          				// 4
    "spitter",            			// 5
    "charger",            			// 7
    "jockey",            			// 8
    "tank",            				// 9
    "witch",           				// 10
    "mob",             				// 11
    "director_force_panic_event", 	// 12
};

char g_sSmgs[][] = 
{									// SMG ID:
	"smg", 							// 0
	"smg_silenced",					// 1
    "smg_mp5", 						// 2
};

char g_sRifles[][] = 
{									// Rifle ID:
	"rifle", 						// 0
	"rifle_desert",					// 1
	"rifle_ak47", 					// 1
    "rifle_sg552", 					// 2
    "rifle_m60", 					// 3
};			

char g_sSnipers[][] = 
{									// Sniper ID:
	"hunting_rifle", 				// 0
	"sniper_military",				// 1
    "sniper_awp", 					// 2
    "sniper_scout", 				// 3
};

char g_sShotguns[][] = 
{									// shotgun ID:
	"pumpshotgun",					// 0
	"shotgun_chrome",				// 1
    "autoshotgun",	 				// 2
    "shotgun_spas", 				// 3
};

char g_sOthers[][] = 
{									// Other ID:
	"pistol",						// 0
	"pistol_magnum", 				// 1
    "grenade_launcher", 			// 2
};

char g_sThrowables[][] = 
{                       			// Throwable ID:
	"pipe_bomb",        			// 0
	"molotov",          			// 1
    "vomitjar",         			// 2
    "gascan",           			// 3
    "propanetank",      			// 4
    "fireworkcrate",    			// 5
    "oxygentank",       			// 6
};

char g_sAmmos[][] = 
{                            		// Ammo ID:
	"laser_sight",           		// 0
	"ammo",                  		// 1
    "incendiary_ammo",       		// 2
    "explosive_ammo",        		// 3
    "upgradepack_incendiary",		// 4
    "upgradepack_explosive", 		// 5
};

char g_sMedicines[][] = 
{                            		// Medicine ID:
	"first_aid_kit",         		// 0
	"adrenaline",            		// 1
    "pain_pills",            		// 2
    "defibrillator",         		// 3
    "health",                		// 4
};

// Special functoins
char g_sSF[][] = 
{                     				// Function ID:
	"AUTO_BHOP",	  				// 0
	"GRAY_AMMO",	  				// 1
	"GREEN_AMMO",	  				// 2
	"BLUE_AMMO",	  				// 3
	"GOLD_AMMO",	  				// 4
	"RED_AMMO",		  				// 5
};
// <------------------------------------ Shop items 

// 
char g_sAmmoColors[][]=
{
	"GRAY_AMMO",
	"GREEN_AMMO",
	"BLUE_AMMO",
	"GOLD_AMMO",
	"RED_AMMO",
};

// Shortcut variables
char g_sShortcutItemCmds[][][]=
{
    // full form               //shortcut
    {"pistol",                 "gun"},
    {"pistol_magnum",          "eagle"},
    {"pistol_magnum",          "magnum"},
    {"smg_silenced",           "slient"},
    {"smg_silenced",           "silenced"},
    {"smg_mp5",                "mp5"},
    {"rifle_ak47",             "ak"},
    {"rifle_ak47",             "ak47"},
    {"rifle",                  "m16"},
    {"rifle_desert",           "desert"},
    {"rifle_desert",           "scar"},
    {"rifle_sg552",            "sg552"},
    {"rifle_m60",              "m60"},
    {"autoshotgun",            "auto"},
    {"shotgun_spas",           "spas"},
    {"pumpshotgun",            "pump"},
    {"shotgun_chrome",         "chrome"},
    {"hunting_rifle",          "hunt"},
	{"hunting_rifle",          "hunting"},
	{"hunting_rifle",          "hrifle"},
    {"sniper_military",        "mili"},
    {"sniper_military",        "military"},
	{"sniper_military",        "sniper"},
    {"sniper_awp",             "awp"},
    {"sniper_scout",           "scout"},
    {"grenade_launcher",       "grenade"},
    {"grenade_launcher",       "launcher"},
    {"grenade_launcher",       "nuke"},
    {"katana",                 "kat"},
    {"fireaxe",                "fire"},
    {"fireaxe",                "axe"},
    {"machete",                "mac"},
    {"knife",                  "cs"},
    {"chainsaw",               "saw"},
    {"pitchfork",              "fork"},
    {"golfclub",               "golf"},
    {"golfclub",               "club"},
    {"tonfa",                  "police"},
    {"tonfa",                  "nightstick"},
    {"tonfa",                  "stick"},
    {"baseball_bat",           "bat"},
    {"baseball_bat",           "baseball"},
    {"cricket_bat",            "cricket"},
    {"cricket_bat",            "ket"},
    {"frying_pan",             "frying"},
    {"frying_pan",             "pan"},
    {"crowbar",                "crow"},
    {"crowbar",                "bar"},
    {"electric_guitar",        "guitar"},
    {"pipe_bomb",              "pipe"},
    {"pipe_bomb",              "bomb"},
    {"molotov",                "molo"},
    {"molotov",                "moly"},
    {"molotov",                "molly"},
    {"vomitjar",               "jar"},
    {"vomitjar",               "bile"},
    {"upgradepack_incendiary", "packfire"},
    {"upgradepack_explosive",  "packexp"},
    {"laser_sight",            "laser"},
    {"incendiary_ammo",        "fire"},
	{"incendiary_ammo",        "fireammo"},
    {"explosive_ammo",         "expammo"},
	{"explosive_ammo",         "exp"},
    {"first_aid_kit",          "first"},
    {"first_aid_kit",          "aid"},
    {"first_aid_kit",          "kit"},
    {"first_aid_kit",          "healthpack"},
    {"first_aid_kit",          "medkit"},
    {"adrenaline",             "adren"},
    {"pain_pills",             "pill"},
    {"pain_pills",             "pills"},
    {"defibrillator",          "defib"},
    {"health",                 "heal"},
    {"health",                 "full"},
	{"health",                 "fheal"},
    {"gascan",                 "gas"},
    {"propanetank",            "propane"},
    {"fireworkcrate",          "firework"},
    {"oxygentank",             "oxygen"},
};

ArrayList g_listSellable[SHOP_SIZE];
ArrayList g_listItems[SHOP_SIZE];
int g_iBuyItem[MAXPLAYERS + 1][2];
char g_sBuyConfirmOptions[][] = {"BUY_YES","BUY_NO"};
char g_sSuicideOptions[][] = {"SUICIDE_YES","SUICIDE_NO"};
char g_sYesNo[][] = {"YES","NO"};
int g_iAdminPointList[] = { 1, 2, 5, 10, 20, 50, 99, 100, 500, 999, };
int g_iTransferPointList[] = { 1, 2, 5, 10, 20, 50, 99 };

// Price Convars:
ConVar cvar_costs[SHOP_SIZE][30];

// Handle hAutoSaveDelayTime;

// admin menu
TopMenu g_hTopMenu;
TopMenu g_hTopMenuCheck;
TopMenuObject g_hAdminAdd;
TopMenuObject g_hAdminConfiscate;
TopMenuObject g_hAdminSet;

int g_iAdminAction[MAXPLAYERS + 1]; // 1st arr: 0=add 1=reduce 2=set
int g_iAdminPoints[MAXPLAYERS + 1]; // Value for giving point

int g_iTransferPoints[MAXPLAYERS + 1]; // Value for giving point
int g_iTransferTarget[MAXPLAYERS + 1]; // Value for giving point
ArrayList g_listIHuman;
ArrayList g_listSHumanSteamId;

// Timer for fix protecting reward bug.
Handle g_hTimerReward[MAXPLAYERS + 1];
// ====================================================================================================


public void OnPluginStart()
{
    // Load multiple language txt file
	LoadTranslations("l4d2_shop.phrases");
	LoadTranslations("l4d2_weapons.phrases");

// ====================================================================================================
//					pan0s | 2: Init variables
// ====================================================================================================

	for(int i=0; i<SHOP_SIZE; i++)
	{
		g_listItems[i] = new ArrayList(ByteCountToCells(32));
		g_listSellable[i] = new ArrayList();

		// 	init shop cmds
		char cmd[64] = "sm_shop"; //SHOP_MAIN, ref to SHOP_INDEX
		Format(g_sShopCmds[i], sizeof(cmd), "%s %d", cmd, i + 1);
	}
	g_listIHuman = new ArrayList();
	g_listSHumanSteamId = new ArrayList(ByteCountToCells(32));
	////// Add items to shop. The ID should be equal to cvar_costs[shop][id], else the cost will be incorrect. /////
	 // Infected items
	for(int i=0; i<sizeof(g_sInfectedItems); i++) g_listItems[SHOP_INFECTED].PushString(g_sInfectedItems[i]);

	// SMGs
	for(int i=0; i<sizeof(g_sSmgs); i++) g_listItems[SHOP_SMGS].PushString(g_sSmgs[i]);

	// Rifle
	for(int i=0; i<sizeof(g_sRifles); i++) g_listItems[SHOP_RIFLES].PushString(g_sRifles[i]);

	// Snipers
	for(int i=0; i<sizeof(g_sSnipers); i++) g_listItems[SHOP_SNIPERS].PushString(g_sSnipers[i]);

	// Shotguns
	for(int i=0; i<sizeof(g_sShotguns); i++) g_listItems[SHOP_SHOTGUNS].PushString(g_sShotguns[i]);

	// Other guns
	for(int i=0; i<sizeof(g_sOthers); i++) g_listItems[SHOP_OTHERS].PushString(g_sOthers[i]);

	// melee weapons
	for(int i=0; i<sizeof(g_sMelees); i++) g_listItems[SHOP_MELEES].PushString(g_sMelees[i]);

	// Throwables
	for(int i=0; i<sizeof(g_sThrowables); i++) g_listItems[SHOP_THROWABLES].PushString(g_sThrowables[i]);

	// Ammos
	for(int i=0; i<sizeof(g_sAmmos); i++) g_listItems[SHOP_AMMOS].PushString(g_sAmmos[i]);

	// Medicines
	for(int i=0; i<sizeof(g_sMedicines); i++) g_listItems[SHOP_MEDICINES].PushString(g_sMedicines[i]);

	// Special functions
	for(int i=0; i<sizeof(g_sSF); i++) g_listItems[SHOP_SF].PushString(g_sSF[i]);
	// ===============================================================================================	

	/*Commands*/
	RegAdminCmd("sm_refill", HandleCmdRefill, ADMFLAG_KICK);
	RegAdminCmd("sm_heal", HandleCmdHeal, ADMFLAG_KICK);
	RegAdminCmd("sm_fakegod",HandleCmdFakeGod, ADMFLAG_KICK);
	RegAdminCmd("sm_test", HandleCmdTest, ADMFLAG_KICK);
	RegConsoleCmd("sm_point", HandleCmdShowPoints);
	RegConsoleCmd("sm_points", HandleCmdShowPoints);
	RegConsoleCmd("sm_repeatbuy",HandleCmdRepeatBuy);
	RegConsoleCmd("sm_itempointshelp", HandleCmdPointsHelp);
	RegConsoleCmd("sm_shop", HandleCmdOpenShop);
	RegConsoleCmd("sm_market", HandleCmdOpenShop);
	RegConsoleCmd("sm_buy", HandleCmdOpenShop);
	RegConsoleCmd("sm_item", HandleCmdOpenShop);
	RegConsoleCmd("sm_items", HandleCmdOpenShop);
	RegConsoleCmd("sm_usepoint", HandleCmdOpenShop);
	RegConsoleCmd("sm_usepoints", HandleCmdOpenShop);
	RegConsoleCmd("sm_buy_confirm", HandleCmdBuyConfirm);
	RegConsoleCmd("sm_kill", HandleCmdSuicide);
	RegConsoleCmd("sm_suicide", HandleCmdSuicide);

	//this signals that the plugin is on on this server
	CreateConVar("points_gift_on", PLUGIN_VERSION, "Points_Gift_On", 320, true, 0.0, true, 1.0);
	/* Values for Convars*/
	cvar_db_on 								= CreateConVar("db_on","1","Will server save points? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_round_clear_on 					= CreateConVar("cvar_round_clear_on","0","Will clear points every round? 0=OFF, 1=On (works with db_on=0 only)",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_transfer_on 						= CreateConVar("cvar_transfer_on","1","Allow player to transfer points? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_transfer_notify_all_on 			= CreateConVar("cvar_transfer_notify_all_on","1","Will notify all players who did transferring? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_buy_notify_all_on 					= CreateConVar("cvar_buy_notify_all_on","1","Will notify all players when a player buy an item? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_suicide_cmd_on 					= CreateConVar("cvar_suicide_cmd_on","1","Can survivor suicide by !kill? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_sf_on 								= CreateConVar("cvar_sf_on","1","Enable Soecial functions? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_infected_buy_respawn_on 			= CreateConVar("cvar_infected_buy_respawn_on","1","Only dead infected can buy respawn? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_points_on 							= CreateConVar("cvar_points_on","1","Point system on or off? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_points_versus_on 					= CreateConVar("cvar_points_versus_on","1","Points spending on or off in versus mode? 0=OFF, 1=On",CVAR_FLAGS,true, 0.0, true, 1.0);
	cvar_points_realism_on 					= CreateConVar("cvar_points_realism_on","1","Points spending on or off in realism mode? 0=OFF, 1=On",CVAR_FLAGS,true, 0.0, true, 1.0);
	cvar_points_coop_on 					= CreateConVar("cvar_points_coop_on","1","Points spending on or off in coop mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_points_scavenger_on 				= CreateConVar("cvar_points_scavenger_on","1","Points spending on or off in scavenger mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_points_survival_on 				= CreateConVar("cvar_points_survival_on","1","Points spending on or off in survival mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_points_team_survival_on 			= CreateConVar("cvar_points_survival_on","1","Points spending on or off in team survival mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_points_team_versus_on 				= CreateConVar("cvar_points_team_versus_on","1","Points spending on or off in team versus mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	// Enable / disable the shop
	cvar_shops_on[SHOP_MAIN]				= CreateConVar("cvar_shop_main_on","1","Open the main shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_INFECTED]			= CreateConVar("cvar_shop_infected_item_on","1","Open the infected item shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_GUNS]				= CreateConVar("cvar_shop_guns_on","1","Open the guns shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SMGS]				= CreateConVar("cvar_shop_smgs_on","1","Open the smgs shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_RIFLES]				= CreateConVar("cvar_shop_riflese_on","1","Open the rifles shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SNIPERS]				= CreateConVar("cvar_shop_snipers_on","1","Open the snupers shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SHOTGUNS]			= CreateConVar("cvar_shop_shotguns_on","1","Open the shotgunsc shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_OTHERS]				= CreateConVar("cvar_shop_others_on","1","Open the others shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_MELEES]				= CreateConVar("cvar_shop_melees_on","1","Open the melees shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_THROWABLES]			= CreateConVar("cvar_shop_throwables_on","1","Open the throwables shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_AMMOS]				= CreateConVar("cvar_shop_ammoss_on","1","Open the ammos shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_MEDICINES]			= CreateConVar("cvar_shop_medicines_on","1","Open the ammos shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF]					= CreateConVar("cvar_shop_sf_on","1","Open the ammos shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF_TRIAL]			= CreateConVar("cvar_shop_sf_trial_on","1","Open the trial shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF_PERMANENT]		= CreateConVar("cvar_shop_sf_permanet_on","1","Open the permanet shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF_BAG]				= CreateConVar("cvar_shop_sf_bag_on","1","Open the bag?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_TRANSFER]			= CreateConVar("cvar_shop_sf_transfer_on","1","Open the tansfer shop?c 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);

	cvar_transfer_handling_fee 				= CreateConVar("cvar_transfer_handling_fee","20","Percentage of handling fee for each transferring point.",CVAR_FLAGS, true, 0.0, true, 99.0);

	cvar_shop_infected_respawn				= CreateConVar("cvar_shop_infected_respawn","0","Where do player respawn after buying infected? 0=Near Survivors, 1=Current location",CVAR_FLAGS, true, 0.0, true, 1.0);

	/* earn points convars */
	cvar_iearn_grab 						= CreateConVar("cvar_iearn_grab","1","How many points you get [as a smoker] when you pull a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_pounce 						= CreateConVar("cvar_iearn_pounce","1","How many points you get [as a hunter] when you pounce a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_vomit 						= CreateConVar("cvar_iearn_vomit","1","How many points you get [as a boomer] when you vomit/explode on a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_charge 						= CreateConVar("cvar_iearn_charge","1","How many points you get [as a charger] after impact on survivor, for 1 pummel damage. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_charge_collateral			= CreateConVar("cvar_iearn_charge_collateral","1","How many points you get [as a charger] when hitting nearby survivors. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_jockey_ride 					= CreateConVar("cvar_iearn_jockey_ride","1","How many points you get when jumping on a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_hurt 						= CreateConVar("cvar_iearn_hurt","2","How many points infected get for hurting survivors a number of times. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_incapacitate 				= CreateConVar("cvar_iearn_incapacitate","5","How many points you get for incapacitating a survivor 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_survivor 					= CreateConVar("cvar_iearn_survivor","10","How many points you get for killing a survivor 0=Disabled",CVAR_FLAGS, true, 0.0);

	cvar_earn_witch							= CreateConVar("cvar_earn_witch","10","How many points you get for killing a witch. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_witch_in_one_shot 			= CreateConVar("cvar_earn_witch_in_one_shot","10","How many extra points you get for killing a witch in one shot. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_tank_burn 					= CreateConVar("cvar_earn_tank_burn","3","How many points you get for burning a tank. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_tank_killed 					= CreateConVar("cvar_earn_tank_killed","2","How many additional points you get for killing a tank. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_infected 						= CreateConVar("cvar_earn_infected","1","How many points for killing a certain number of infected. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_infected_num 					= CreateConVar("cvar_earn_infected_num","10","How many killed infected does it take to earn points? Headshot and minigun kills can be used to rank up extra kills. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_special						= CreateConVar("cvar_earn_special","1","How many points for killing a special infected. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_heal 							= CreateConVar("cvar_earn_heal","5","How many points for healing someone. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_defibrillate					= CreateConVar("cvar_earn_defibrillate","5","How many points rewarded to player who used defibrillator 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_protect 						= CreateConVar("cvar_earn_protect","1","How many points for protecting someone. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_rescued		 				= CreateConVar("cvar_earn_rescued","2","How many points rewarded to player who rescued the dead client. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_revive 						= CreateConVar("cvar_earn_revive","2","How many points for reviving someone. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_revive_ledge_hang 			= CreateConVar("cvar_earn_revive_ledge_hang","1","How many points for reviving someone who is in ledge hang/ 0=Disabled",CVAR_FLAGS,true,0.0);

	// ** If cost is less than 0, the item will be disabled (dont show on the Menu and no one can buy it.) **
	
	/*Rifle cost Convars*/
	cvar_costs[SHOP_RIFLES][0] 				= CreateConVar("cvar_cost_rifles_m16","30","How many points a rifle costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_RIFLES][1] 				= CreateConVar("cvar_cost_rifles_desert","30","How many points a desert rifle costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_RIFLES][2] 				= CreateConVar("cvar_cost_rifles_ak47","30","How many points an AK47 costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_RIFLES][3]				= CreateConVar("cvar_cost_rifles_sg552","30","How many points a SG552 rifle costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_RIFLES][4] 				= CreateConVar("cvar_cost_rifles_m60","160","How many points a m60 costs. -1=Disabled",CVAR_FLAGS);

	/*Sniper cost Convars*/ 
	cvar_costs[SHOP_SNIPERS][0] 			= CreateConVar("cvar_cost_snipers_hunting_rifle","25","How many points a hunting rifle costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SNIPERS][1]				= CreateConVar("cvar_cost_snipers_military","25","How many points a military sniper rifle costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SNIPERS][2] 			= CreateConVar("cvar_cost_snipers_awp","25","How many points an AWP sniper rifle costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SNIPERS][3] 			= CreateConVar("cvar_cost_snipers_scout","20","How many points a scout sniper rifle costs. -1=Disabled",CVAR_FLAGS);

	/*Shotgun cost Convars*/
	cvar_costs[SHOP_SHOTGUNS][0] 			= CreateConVar("cvar_cost_shotguns","13","How many points a shotgun costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SHOTGUNS][1] 			= CreateConVar("cvar_cost_schrome_shotgun","13","How many points a chrome shotgun costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SHOTGUNS][2]			= CreateConVar("cvar_cost_auto_shotgun","30","How many points an auto-shotgun costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SHOTGUNS][3] 			= CreateConVar("cvar_cost_spas_shotgun","30","How many points a Spas Shotgun costs. -1=Disabled",CVAR_FLAGS);

	/*SMG cost Convars*/ 
	cvar_costs[SHOP_SMGS][0] 				= CreateConVar("cvar_cost_smg","13","How many points a smg costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SMGS][1] 				= CreateConVar("cvar_cost_silencedsmg","13","How many points a Silenced SMG costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_SMGS][2] 				= CreateConVar("cvar_cost_mp5","13","How many points a MP5 SMG costs. -1=Disabled",CVAR_FLAGS);

	/*Other cost Convars*/
	cvar_costs[SHOP_OTHERS][0] 				= CreateConVar("cvar_cost_pistol","5","How many points an extra pistol costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_OTHERS][1]				= CreateConVar("cvar_cost_magnum","13","How many points a Magnum costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_OTHERS][2] 				= CreateConVar("cvar_cost_grenade","38","How many points a grenade launcher costs. -1=Disabled",CVAR_FLAGS);

	/*Melee cost Convars*/
	cvar_costs[SHOP_MELEES][0]    			= CreateConVar("cvar_cost_katana","9","How many points a katana costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][1]   			= CreateConVar("cvar_cost_fireaxe","9","How many points a fireaxe costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][2]     			= CreateConVar("cvar_cost_machete","9","How many points a machete costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][3]     			= CreateConVar("cvar_cost_flamethrower","-1","How many points a flamethrower costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][4]   			= CreateConVar("cvar_cost_knife","5","How many points a knife costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][5] 				= CreateConVar("cvar_cost_chainsaw","16","How many points the chainsaw costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][6] 				= CreateConVar("cvar_cost_pitchfork","9","How many points the pitchfork costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][7] 				= CreateConVar("cvar_cost_shovel","9","How many points the shovel costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][8] 				= CreateConVar("cvar_cost_golfclub","9","How many points the golfclub costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][9] 				= CreateConVar("cvar_cost_electric_guitar","9","How many points the electric_guitar costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][10] 			= CreateConVar("cvar_cost_tonfar","9","How many points the tonfa costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][11] 			= CreateConVar("cvar_cost_baseball_bat","9","How many points a baseball_bat bat costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][12] 			= CreateConVar("cvar_cost_cricket_bat","9","How many points a cricket_bat costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][13]   			= CreateConVar("cvar_cost_frying_pan","9","How many points a frying_pan costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MELEES][14] 			= CreateConVar("cvar_cost_crowbar","9","How many points a crowbar bat costs. -1=Disabled",CVAR_FLAGS);

	/*Throwable cost Convars*/
	cvar_costs[SHOP_THROWABLES][0] 			= CreateConVar("cvar_cost_pipebomb","28","How many points a pipe-bomb costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_THROWABLES][1]			= CreateConVar("cvar_cost_molotov","23","How many points a molotov costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_THROWABLES][2]			= CreateConVar("cvar_cost_vomitjar","28","How many points a vomitjar costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_THROWABLES][3]			= CreateConVar("cvar_cost_gascan","18","How many points the gascan costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_THROWABLES][4] 			= CreateConVar("cvar_cost_propane","18","How many points a propane tank costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_THROWABLES][5] 			= CreateConVar("cvar_cost_firework","18","How many points a fireworks crate costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_THROWABLES][6] 			= CreateConVar("cvar_cost_oxygen","18","How many points an oxygen tank costs. -1=Disabled",CVAR_FLAGS);


	/*Ammo cost Convars*/
	cvar_costs[SHOP_AMMOS][0] 				= CreateConVar("cvar_cost_laser","10","How many points a laser sight costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_AMMOS][1] 				= CreateConVar("cvar_cost_refill","12","How many points an ammo refill costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_AMMOS][2] 				= CreateConVar("cvar_cost_special_burn","12","How many points does incendiary ammo cost?",CVAR_FLAGS);
	cvar_costs[SHOP_AMMOS][3] 				= CreateConVar("cvar_cost_explosive","12","How many points the explosive bullets upgade costs. -1=Disabled",CVAR_FLAGS);  
	cvar_costs[SHOP_AMMOS][4] 				= CreateConVar("cvar_cost_special_burn_super","18","How many points does a pack of incendiary ammo cost?",CVAR_FLAGS);
	cvar_costs[SHOP_AMMOS][5] 				= CreateConVar("cvar_cost_explosivepack","18","How many points a pack of explosive bullets upgade costs. -1=Disabled",CVAR_FLAGS);  

	/*Heal cost Convars*/
	cvar_costs[SHOP_MEDICINES][0] 			= CreateConVar("cvar_cost_medkit","88","How many points a medkit costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MEDICINES][1]			= CreateConVar("cvar_cost_adrenaline","43","How many points a adrenaline costs. -1=Disabled",CVAR_FLAGS); 
	cvar_costs[SHOP_MEDICINES][2] 			= CreateConVar("cvar_cost_painpills","43","How many points a pills costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MEDICINES][3] 			= CreateConVar("cvar_cost_defib","50","How many points a defib costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_MEDICINES][4] 			= CreateConVar("cvar_cost_heal","99","How many points a heal costs. -1=Disabled",CVAR_FLAGS);

	// Special shop (for all teams)
	cvar_costs[SHOP_SF_TRIAL][0] 	    	= CreateConVar("cvar_cost_trial_bhop","30","How many points for trial auto bhop.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_TRIAL][1] 	    	= CreateConVar("cvar_cost_trial_gray_ammo","20","How many points for the trial gray ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_TRIAL][2]     		= CreateConVar("cvar_cost_trial_green_ammo","20","How many points the trial green ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_TRIAL][3]      		= CreateConVar("cvar_cost_trial_blue_ammo","20","How many points the trial blue ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_TRIAL][4]      		= CreateConVar("cvar_cost_trial_gold_ammo","20","How many points the trial gold ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_TRIAL][5]     		= CreateConVar("cvar_cost_trial_red_ammo","20","How many points the trial red ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_PERMANENT][0]		= CreateConVar("cvar_cost_permanent_bhop","1000","How many points permanent auto bhop.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_PERMANENT][1]		= CreateConVar("cvar_cost_permanent_gray_ammo","1000","How many points the permanent gray ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_PERMANENT][2]		= CreateConVar("cvar_cost_permanent_green_ammo","3000","How many points the permanent green ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_PERMANENT][3]		= CreateConVar("cvar_cost_permanent_blue_ammo","4000","How many points the permanent blue ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_PERMANENT][4]		= CreateConVar("cvar_cost_permanent_gold_ammo","6000","How many points the permanent gold ammo.",CVAR_FLAGS);
	cvar_costs[SHOP_SF_PERMANENT][5]		= CreateConVar("cvar_cost_permanent_red_ammo","9999","How many points the permanent red ammo.",CVAR_FLAGS);

	/*Infected Price Convars*/
	cvar_costs[SHOP_INFECTED][0]			= CreateConVar("cvar_cost_infected_suicide","4","How many points it takes to end it all.",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][1]  			= CreateConVar("cvar_cost_infected_heal","10","How many points a heal costs (for infected).",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][2]			= CreateConVar("cvar_cost_infected_boomer","10","How many points a boomer costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][3]			= CreateConVar("cvar_cost_infected_hunter","5","How many points a hunter costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][4] 			= CreateConVar("cvar_cost_infected_smoker","7","How many points a smoker costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][5]			= CreateConVar("cvar_cost_infected_spitter","7","How many points a spitter costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][6]			= CreateConVar("cvar_cost_infected_charger","7","How many points a charger costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][7]			= CreateConVar("cvar_cost_infected_jockey","7","How many points a jockey costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][8]  			= CreateConVar("cvar_cost_infected_tank","50","How many points a tank costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][9]			= CreateConVar("cvar_cost_infected_witch","30","How many points a witch costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][10]  			= CreateConVar("cvar_cost_infected_mob","18","How many points a mini-event/mob costs. -1=Disabled",CVAR_FLAGS);
	cvar_costs[SHOP_INFECTED][11]			= CreateConVar("cvar_cost_infected_mob_mega","23","How many points a mega mob costs. -1=Disabled",CVAR_FLAGS);
	
	/*Item-Related Convars*/
	cvar_tank_limit 						= CreateConVar("points_limit_tanks","1","How many tanks can be spawned in a round.",CVAR_FLAGS, true, 0.0, true, 60.0);
	cvar_witch_limit 						= CreateConVar("points_limit_witches","2","How many witches can be spawned in a round.",CVAR_FLAGS, true, 0.0, true, 60.0);

	// /*Laser Tag Convars */
	
	cvar_pistols 							= CreateConVar("l4d_lasertag_pistols", "1", "LaserTagging for Pistols. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_rifles 							= CreateConVar("l4d_lasertag_rifles", "1", "LaserTagging for Rifles. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_snipers 							= CreateConVar("l4d_lasertag_snipers", "1", "LaserTagging for Sniper Rifles. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_smgs 								= CreateConVar("l4d_lasertag_smgs", "1", "LaserTagging for SMGs. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_shotguns 							= CreateConVar("l4d_lasertag_shotguns", "1", "LaserTagging for Shotguns. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
		
	cvar_laser_life 						= CreateConVar("l4d_lasertag_life", "0.8", "Seconds Laser will remain", DEFAULT_FLAGS, true, 0.1);
	cvar_laser_width 						= CreateConVar("l4d_lasertag_width", "1.0", "Width of Laser", DEFAULT_FLAGS, true, 1.0);
	cvar_laser_offset 						= CreateConVar("l4d_lasertag_offset", "36", "Lasertag Offset", DEFAULT_FLAGS);

	//
	cvar_invoice_type 						= CreateConVar("points_inovice_type", "1", "Inovice display type. 0=simple, 1=detail", DEFAULT_FLAGS, true, 0.0, true, 1.0);

	//3: Event Hooks	
	/*Event Hooks*/
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
	HookEvent("heal_success", HealPoints);
	HookEvent("revive_success", RevivePoints);
	HookEvent("award_earned", AwardPoints);
	HookEvent("infected_death", KillPoints);
	HookEvent("witch_killed", WitchPoints);
	HookEvent("zombie_ignited", TankBurnPoints);
	HookEvent("tank_killed", TankKill);
	HookEvent("player_hurt",HurtPoints);
	HookEvent("player_incapacitated",IncapacitatePoints);
	HookEvent("tongue_grab",GrabPoints);
	HookEvent("lunge_pounce",PouncePoints);
	HookEvent("player_now_it",VomitPoints);
	HookEvent("charger_pummel_start",Charge_Pummel_Points); //charger does the hammer like pumping action to the victim.
	HookEvent("charger_impact",Charge_Collateral_Damage_Points); //charger hits survivor(s) who he did NOT carry, thus, collateral damage :).
	HookEvent("jockey_ride",Jockey_Ride_Points); //Jockey gets extra points
	HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	HookEvent("survivor_rescued", Event_Rescued);
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("bullet_impact", Event_BulletImpact);
	
	// ConVars that change whether the plugin is enabled
	HookConVarChange(cvar_pistols, CheckWeapons);
	HookConVarChange(cvar_rifles, CheckWeapons);
	HookConVarChange(cvar_snipers, CheckWeapons);
	HookConVarChange(cvar_smgs, CheckWeapons);
	HookConVarChange(cvar_shotguns, CheckWeapons);
	
	HookConVarChange(cvar_laser_life, UselessHooker);
	HookConVarChange(cvar_laser_width, UselessHooker);
	HookConVarChange(cvar_laser_offset, UselessHooker);

	HookEvent("player_team", PlayerJoinTeam);

	//HookEvent("tank_spawn",TankCheck);

	/* Config Creation*/
	AutoExecConfig(true,"l4d2_shop");

	// Create Table for storaging data
	CreateDBTable();

	if (LibraryExists("adminmenu") && ((g_hTopMenuCheck = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(g_hTopMenuCheck);
}

// ====================================================================================================
//					pan0s | 3: Database (SQLITE) func.
// ====================================================================================================
// 
Database ConnectDB()
{
	if(!GetConVarBool(cvar_db_on)) return null;

	char error[255];
	Database db = SQL_Connect("clientprefs", true, error, sizeof(error));
	
	if (db == null)
	{
	    LogError("[ERROR]: Could not connect: \"%s\"", error);
		return null;
	}
	else
	{
		return db;
	}
}

void CreateDBTable()
{
	Database db = ConnectDB();
	if (db != null)
	{
		DBResultSet query = SQL_Query(db, "CREATE TABLE IF NOT EXISTS Shop(steamId TEXT, points INTEGER, PRIMARY KEY (steamId))");
		char isSucceed[255];
		isSucceed = query.RowCount>0? "Success." : "Already existesd.";
		if(query.RowCount>0)
		{
			LogMessage("[CREATE]: Create Shop table: \"%s\"", isSucceed);
		}
		PrintToServer("[Shop] Create Shop table: %s", isSucceed);

		// query = SQL_Query(db, "DROP TABLE IF EXISTS SpecialFunctions");
		query = SQL_Query(db, "CREATE TABLE IF NOT EXISTS SpecialFunctions(steamId TEXT, functionNo TEXT, isEnabled INTEGER, PRIMARY KEY (steamId, functionNo))");
		isSucceed = query.RowCount>0? "Created." : "Already existesd.";
		if(query.RowCount>0)
		{
			LogMessage("[CREATE]: Create SpecialFunctions table: \"%s\"", isSucceed);
		}
		PrintToServer("[Shop] Create SpecialFunctions table: %s", isSucceed);
	}
	delete db;
}

int GetFunctionIndex(const char[] functionNo)
{
	for(int i=0; i<sizeof(g_sSF); i++)
		if(StrEqual(functionNo, g_sSF[i])) 
			return i;
	return -1;
}

int LoadPoints(int client)
{
	Database db = ConnectDB();
	if (db != null)
	{
		char steamId[32];
		int db_points = 0;
		char error[255];

		Handle hSelectStmt = INVALID_HANDLE;

		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		///////////////////////// Load special functions
		if ((hSelectStmt = SQL_PrepareQuery(db, "SELECT functionNo, isEnabled FROM SpecialFunctions WHERE steamId = ?", error, sizeof(error))) == INVALID_HANDLE)
		{
			LogError("[ERROR]: SELECT SQL_PrepareQuery: \"%s\"", error);
		}

		// Disabled all special function first
		for(int i =0; i< SF_SIZE; i++)
		{
			g_bClientSF[client][0][i] = false;
			g_bClientSF[client][1][i] = false;
		}
		SQL_BindParamString(hSelectStmt, 0, steamId, false);
		if (SQL_Execute(hSelectStmt))
		{
			while(SQL_FetchRow(hSelectStmt))
			{
				char functionNo[32];
				SQL_FetchString(hSelectStmt, 0, functionNo, sizeof(functionNo));
				int index = GetFunctionIndex(functionNo);
				bool isEnabled = SQL_FetchInt(hSelectStmt, 1) == 1;
				g_bClientSF[client][0][index] = isEnabled;
				g_bClientSF[client][1][index] = true;
			}
		}
		///////////////////////////////////////////////////

		////////////////////////////////// Load points
		if ((hSelectStmt = SQL_PrepareQuery(db, "SELECT steamId,points FROM Shop WHERE steamId = ?", error, sizeof(error))) == INVALID_HANDLE)
		{
			LogError("[ERROR]: SELECT SQL_PrepareQuery: \"%s\"", error);
			return db_points;
		}
		SQL_BindParamString(hSelectStmt, 0, steamId, false);

		// Find the client in the database
		if (SQL_Execute(hSelectStmt))
		{
			char playerName[64];
			GetClientName(client, playerName, sizeof(playerName));
			if(SQL_FetchRow(hSelectStmt))
			{
				SQL_FetchString(hSelectStmt, 0, steamId, sizeof(steamId));
				db_points = SQL_FetchInt(hSelectStmt, 1);
				LogAction(client, -1, "[LOAD]: \"%L\" loaded the record successfully! Points: \"%d\"", client, db_points);
			}
			else //INSERT
			{
				// if the user is not existed in the database, insert new one.
				Handle hInsertStmt = INVALID_HANDLE;
				if ((hInsertStmt = SQL_PrepareQuery(db, "INSERT INTO Shop(steamId, points) VALUES(?,?)", error, sizeof(error))) == INVALID_HANDLE)
				{
					LogError("[ERROR]: INSERT SQL_PrepareQuery: \"%s\"", error);
				}
				else
				{
					SQL_BindParamString(hInsertStmt, 0, steamId, false);
					SQL_BindParamInt(hInsertStmt, 1, 0, false); // Default point is 0
					if (!SQL_Execute(hInsertStmt))
					{
						LogError("[ERROR]: INSERT error Error: \"%s\"", error);
					}
					int rs = SQL_GetAffectedRows(hInsertStmt);
					if(rs>0)
					{
						LogAction(client, -1, "[INSERT]: \"%L\" is a new user!!", client);
					}else
					{
						LogError("[ERROR]: \"%L\" made insert error \"%s\"", client, error);
					}
				}
	  		    delete hInsertStmt;
			}

		}
	    delete hSelectStmt;
		return db_points;
	}
	delete db;
	return 0;

}

int SaveToDB(int client)
{
	//(points)\[(.*)\](.*[\+|\-]=.*)
	//(.*)(points)\[(.*)\](.*-=)(.*);
	//$1g_iPoints[$3]$4$5;\n$1CPrintToChat(client,"%t%t", "SYSTEM", "SUCCEED_TO_BUY",$5, g_iPoints[client]);
	// database connection
	int rs = 0;
	if(client && IsValidClient(client) && !IsFakeClient(client))
	{
		char error[255];
		Database db = ConnectDB();
		if (db != null)
		{
			// database statment
			Handle hUpdateStmt = INVALID_HANDLE;
			char steamId[32];
			GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
			if ((hUpdateStmt = SQL_PrepareQuery(db, "UPDATE Shop SET points = ? WHERE steamId = ?", error, sizeof(error))) == INVALID_HANDLE)
			{
				LogError("[ERROR]: UPDATE SQL_PrepareQuery: \"%s\"", error);
			}
			else
			{
				SQL_BindParamInt(hUpdateStmt, 0, g_iPoints[client], false);
				SQL_BindParamString(hUpdateStmt, 1, steamId, false);

				if (!SQL_Execute(hUpdateStmt))
				{
					LogError("[ERROR]: Update Shop SQL_Execute: \"%s\"", error);
				}else
				{
					char playerName[64];
					GetClientName(client, playerName, sizeof(playerName));
					rs = SQL_GetAffectedRows(hUpdateStmt);
					if(rs>0)
					{
						LogAction(client, -1,"[UPDATE]: \"%L\" saved. Points: \"%d\"", client, g_iPoints[client], rs);
					}
				}
			}
			delete hUpdateStmt;
		}
		delete db;
	}
	return rs;
}

void SF_InsertToDB(int client, int idx, int isEnabled)
{
	// database connection
	char error[255];
	Database db = ConnectDB();
	
	if (db != null)
	{
		Handle hInsertStmt = INVALID_HANDLE;
		char steamId[32];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		if ((hInsertStmt = SQL_PrepareQuery(db, "INSERT INTO SpecialFunctions(steamId, functionNo, isEnabled) VALUES(?,?,?)", error, sizeof(error))) == INVALID_HANDLE)
		{
			LogError("[ERROR]: INSERT SpecialFunctions SQL_PrepareQuery: \"%s\"", error);
		}
		else
		{
			SQL_BindParamString(hInsertStmt, 0, steamId, false);
			SQL_BindParamString(hInsertStmt, 1, g_sSF[idx], false);
			SQL_BindParamInt(hInsertStmt, 2, isEnabled, false);

			if (!SQL_Execute(hInsertStmt))
			{
				LogError("[ERROR]: INSERT SpecialFunctions SQL_Execute: \"%s\"", error);
			}
			else
			{
				char item[32];
				char name[32];
				g_listItems[SHOP_SF].GetString(idx, item, sizeof(item));
				AddTimeTag(client, SHOP_SF_PERMANENT, item, name);
				//LogAction(client, -1, "[SF]: \"%L\" have purchased a permanent item \"%s\" (functionNo:\"%s\").", client, name, g_sSF[idx]);
			}
		}
	  	delete hInsertStmt;
	}
	delete db;
}

void SF_UpdateToDB(int client, int idx, int isEnabled, const char[] query, int querySize)
{
	// database connection
	char error[255];
	Database db = ConnectDB();
	
	if (db != null)
	{
		Handle hUpdateStmt = INVALID_HANDLE;
		char steamId[32];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		if ((hUpdateStmt = SQL_PrepareQuery(db, querySize > 0? query:"UPDATE SpecialFunctions SET isEnabled = ? WHERE steamId = ? AND functionNo = ?", error, sizeof(error))) == INVALID_HANDLE)
		{
			LogError("[ERROR]: UPDATE SpecialFunctions SQL_PrepareQuery: \"%s\"", error);
		}
		else
		{
			if(querySize <= 0)
			{
				SQL_BindParamInt(hUpdateStmt, 0, isEnabled, false);
				SQL_BindParamString(hUpdateStmt, 1, steamId, false);
				SQL_BindParamString(hUpdateStmt, 2, g_sSF[idx], false);
			}
			if (!SQL_Execute(hUpdateStmt))
			{
				LogError("[ERROR]: UPDATE SpecialFunctions SQL_Execute: \"%s\"", error);
			}
			else
			{
				char item[32];
				if(idx>=0) g_listItems[SHOP_SF].GetString(idx, item, sizeof(item));
				LogAction(client, -1, "[SF_ON/OFF]: \"%L\" %s the permanent item \"%T\" (functionNo:\"%s\"). Affected rows: \"%d\"", client, isEnabled?"enabled":"disabled", idx>=0?item:"ALL_AMMO_COLORS", client, idx>=0? g_sSF[idx]: "-", SQL_GetAffectedRows(hUpdateStmt));
			}
		}
	  	delete hUpdateStmt;
	}
	delete db;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | 4: Hook events
// ====================================================================================================
// Reset trial special Functions
public void ResetTrialSF()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		// Reset points
		if(!GetConVarBool(cvar_db_on) && GetConVarBool(cvar_round_clear_on)) g_iPoints[i] = 0;
		// Reset special Functions
		for(int j = 0; i< SF_SIZE; i++)
		{
			if(!g_bClientSF[i][1][j]) // if client bought the function, dont reset.
				g_bClientSF[i][0][j] = false;
		}
	} 
}

public Action RoundStart(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;
	ResetTrialSF();
	return Plugin_Handled;
}

public Action RoundEnd(Handle event, char[] event_name, bool dontBroadcast)
{
	ResetTrialSF();
	SaveAll();
} 

public Action PlayerJoinTeam(Handle event, char[] event_name, bool dontBroadcast)
{
	int player_id = GetEventInt(event, "userid", 0);
	int player = GetClientOfUserId(player_id);
    int disconnect = GetEventBool(event, "disconnect");

	ResetPoints(player, disconnect);
	if (!IsFakeClient(player))
	{
		CreateTimer(1.0, ShowLoad, player, 0);
	}
}
// Handle Timer
public Action ShowLoad(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if(!g_bIsShown[client])
		{
			ShowLoadedMsg(client);
			g_bIsShown[client] = true;
		}
	}
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | 5: Overrided functions
// ====================================================================================================
public void OnMapStart()
{
	Handle gamemodevar = FindConVar("mp_gamemode");
	char gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	PrintToServer("[Shop] cvar_points_on:%d | GameMode: %s", GetConVarInt(cvar_points_on), gamemode);
	g_bPointsOn = GetConVarBool(cvar_points_on);
	if(g_bPointsOn)
	{
		bool bOffSurvival 		= StrEqual(gamemode,"survival", true) && !GetConVarBool(cvar_points_survival_on);
		bool bOffCoop			= StrEqual(gamemode,"coop", true) && !GetConVarBool(cvar_points_coop_on);
		bool bOffScavenge 		= StrEqual(gamemode,"scavenge", true) && !GetConVarBool(cvar_points_scavenger_on);
		bool bOffRealism		= StrEqual(gamemode,"realism", true) && !GetConVarBool(cvar_points_realism_on);
		bool bOffVersus 		= StrEqual(gamemode,"versus", true) && !GetConVarBool(cvar_points_versus_on);
		bool bOffTeamscavenge	= StrEqual(gamemode,"teamscavenge", true) && !GetConVarBool(cvar_points_team_survival_on);
		bool bOffTteamversus 	= StrEqual(gamemode,"teamversus", true) && !GetConVarBool(cvar_points_team_versus_on);
		if(bOffSurvival ||
			bOffCoop ||
			bOffScavenge ||
			bOffRealism ||
			bOffVersus ||
			bOffTeamscavenge ||
			bOffTteamversus)
		{
			g_bPointsOn = false;
		}
	}

	// Laser tag
	g_Sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public void OnClientPostAdminCheck(int client)
{
    // reset the points after connect
    if(IsValidClient(client) && !IsFakeClient(client))    
    {
		g_iPoints[client] = LoadPoints(client);
    }
}

public void OnClientDisconnect(int client)
{
	g_bIsShown[client] = false;
	if(IsValidClient(client)) g_iKilledInfectedCount[client] = 0;
	SaveToDB(client);
	ResetClient(client);
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | 6: Control points
// ====================================================================================================
bool AddPoints(int client, int points, bool willSave)
{
	if(IsValidClient(client) && !IsFakeClient(client) && points > 0)
	{
		g_iPoints[client] += points;
		if(willSave) SaveToDB(client);
		return true;
	}
	return false;

}

bool ReducePoints(int client, int points, bool willSave)
{
	if(IsValidClient(client) && !IsFakeClient(client) && points >= 0)
	{
		g_iPoints[client] -= points;
		if(willSave) SaveToDB(client);
		return true;
	}
	return false;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | 7: important functions
// ====================================================================================================
// Save all clients' points to db.
public void SaveAll()
{
	int rs = 0;
	for(int i = 1; i <= MaxClients; i++) rs += SaveToDB(i);
	if(rs>0) PrintToServer("[Shop] Auto Update Successfully! Affected rows: %d", rs);
}
// Show loaded points messages
public void ShowLoadedMsg(int client)
{
	if(!GetConVarBool(cvar_db_on)) return;
    char steamId[32];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	CPrintToChat(client,"%T%T", "SYSTEM", client, "SUCCEED_TO_LOAD", client, steamId, g_iPoints[client]);
}

public void ResetClient(int client)
{
	// Reset client points
	if(client && !IsFakeClient(client))    
    {
		// Reset points
		g_iPoints[client] = 0;

		// Reset special Functions
		for(int i = 0; i< SF_SIZE; i++)
		{
			g_bClientSF[client][0][i] = false;
			g_bClientSF[client][1][i] = false;
		}
    }
}
public void ResetPoints(int client, int isDiscocnnected)
{
	if(GetConVarBool(cvar_db_on)) return;
    
	if(isDiscocnnected) 
	{
		g_iPoints[client] = 0;   // Reset points after disconnect
		g_iKilledInfectedCount[client] = 0;
	}
}

public void PrintBuyState(const int client, const int price, const char[] item)
{
	char name[32];
	AddTimeTag(client, g_iBuyItem[client][0], item, name);
	if(GetConVarBool(cvar_buy_notify_all_on))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			char name2[32];
			AddTimeTag(i, g_iBuyItem[client][0], item, name2);
			if(IsValidClient(i) && i != client)
				CPrintToChat(i, "%T%T", "SYSTEM", i, "NOTIFY_ALL", i, client, name2, price);
		}
	}
	if(GetConVarInt(cvar_invoice_type) ==1)
	{
		CPrintToChat(client,"============%T%T============", "SYSTEM", client, "INVOICE", client);
		DataPack hPack = CreateDataPack();
		CreateTimer(0.1, HandleDelayRow1, client);
		CreateTimer(0.3, HandleDelayRow2, hPack);
		hPack.WriteCell(client);
		hPack.WriteString(name);
		hPack.WriteCell(price);
		char steamId[32];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		LogAction(client, -1, "[Buy]: \"%L\" bought \"%s\" (price: \"%d\"), remaining points: \"%d\"", client, name, price, g_iPoints[client]);
	}
	else
		CPrintToChat(client,"%T%T", "SYSTEM", client, "SUCCEED_TO_BUY", client, name, price, g_iPoints[client]);
}

// Ask the client to pay the item, return true if success.
public bool Checkout(const int client, const int price, const char[] item, bool bPrint)
{
	char name[32];
	AddTimeTag(client, g_iBuyItem[client][0], item, name);
	if (g_iPoints[client] >= price) 
	{
		if(ReducePoints(client, price, false))
		{
			if(bPrint)PrintBuyState(client, price, item);
			return true;
		}
		else
			return false;
	}
	CPrintToChat(client,"%T%T %T", "SYSTEM", client, "FAILED_TO_BUY", client, name, "NOT_ENOUGH_POINTS", client, price, g_iPoints[client]);
	return false;
}

// Invoic messages
public Action HandleDelayRow1(Handle timer, int client)
{
	CPrintToChat(client,"%T", "INVOICE_BUYER_INFO", client, client, g_iPoints[client]);
}

public Action HandleDelayRow2(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int client = hPack.ReadCell();
	char item[64];
	hPack.ReadString(item, sizeof(item));
	int price = hPack.ReadCell();
	CPrintToChat(client,"%T{ORANGE}%s{DEFAULT}, %T", "INVOICE_BUY_ITEM", client, item, "INVOICE_PRICE", client, price);
	CreateTimer(0.2, HandleDelayRow3, client);
}

public Action HandleDelayRow3(Handle timer, int client)
{
	CPrintToChat(client,"%T", "INVOICE_THANKS", client);
	CreateTimer(0.2, HandleDelayRow4, client);
}

public Action HandleDelayRow4(Handle timer, int client)
{
	CPrintToChat(client,"%T", "INVOICE_END", client);
}

/////////////////////////////////////////////////////////////////////
// pan0s | Buy functions
bool BuyItem(int client, const char[] item, int price, int team = TEAM_SURVIVOR)
{
	if(IsSurvivorDeadEx(client, item)) return false;
	
	if(team == TEAM_INFECTED && GetConVarBool(cvar_infected_buy_respawn_on) && IsPlayerAlive(client) && !(StrEqual(item, "kill") || StrEqual(item, "health") || StrEqual(item, "mob") || StrEqual(item, "director_force_panic_event")))
	{
		CPrintToChat(client, "%T%T", "SYSTEM", client, "YOU_ARE_ALIVE", client);
		return false;
	}

	if (Checkout(client, price, item, true)) 
	{
		if(team == TEAM_INFECTED) 
		{
			char spawnCmd[12];
			if(GetConVarBool(cvar_shop_infected_respawn)) Format(spawnCmd, sizeof(spawnCmd), "z_spawn");
			else Format(spawnCmd, sizeof(spawnCmd), "z_spawn_old");

			if(StrEqual(item, "kill")) KillClient(client);
			else if (StrEqual(item, "health")) CheatCommand(client, "give", item); 
			else if (StrEqual(item, "mob")) CheatCommand(client, spawnCmd, item); 
			else if (StrEqual(item, "director_force_panic_event")) CheatCommand(client, "director_force_panic_event");
			else
			{
				char args[32];
				Format(args, sizeof(args), "%s auto", item);
				CheatCommand(client, spawnCmd, args);
			}
		}
		else CheatCommand(client, "give", item); 
		return true;
	}
	return false;
}

bool BuyMelee(int client, const char[] melee, int price)
{
	if(IsSurvivorDeadEx(client, melee)) return false;

	// BuyItem(client, melee, price);
	bool isSucceed = false;
	if (Checkout(client, price, melee, false)) 
	{
		CheatCommand(client, "give", melee); 
	    int WeaponEnt = GetPlayerWeaponSlot(client, 1);
	    if (WeaponEnt != -1)
	    {
			char weaponName[32];
			GetClientWeapon(client, weaponName, 32);
			if(StrEqual(weaponName, "weapon_chainsaw")) isSucceed = true;
			else if(StrEqual(weaponName, "weapon_melee"))
			{
	    		if (StrContains(weaponName, melee, false) == -1) 
	    		{
				   	char playerWeaponName[32];
	    		   	GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", playerWeaponName, sizeof(playerWeaponName));
					PrintToServer("[SHOP]=======%s, %s",playerWeaponName, melee);
					if(StrEqual(playerWeaponName, melee)) 
					{
						isSucceed = true;
					}
	    		}
			}
	    }
		if(!isSucceed) 
		{
			g_iPoints[client] += price;
			char name[32];
			AddTimeTag(client, g_iBuyItem[client][0], melee, name);
			CPrintToChat(client,"%T%T%T", "SYSTEM", client, "FAILED_TO_BUY", client, name, "REFUNDED", client, price);
		}else
		{
			PrintBuyState(client, price, melee);
		}
	}
	return isSucceed;
}

bool UpgradeWeapon(int client, const char[] component, int price)
{
	if(IsSurvivorDeadEx(client, component)) return false;

	int priWeapon = GetPlayerWeaponSlot(client, 0);
	if (priWeapon == -1)
	{
		char name[32];
		AddTimeTag(client, g_iBuyItem[client][0], component, name);
		CPrintToChat(client,"%T%T %T", "SYSTEM", client, "NO_PRIMARY_WEAPON", client, "FAILED_TO_BUY", client, name);
		return false;
	}

	if(StrEqual(component, "ammo")) return BuyItem(client, component, price);

	if(Checkout(client, price, component, true)) 
	{
		CheatCommand(client, "upgrade_add", component);
		return true;
	}
	return false;
}

void BuySF(int client, int idx, int price, bool isPermanent)
{
	char item[32];
	g_listItems[SHOP_SF].GetString(idx, item, sizeof(item));

	if((g_bClientSF[client][0][idx] && !isPermanent )|| (g_bClientSF[client][1][idx] && isPermanent))
	{
		char name[32];
		AddTimeTag(client, g_iBuyItem[client][0], item, name);
		CPrintToChat(client,"%T%T", "SYSTEM", client, "IS_IN_YOUR_BAG", client, name);
		return;
	}

	if (Checkout(client, price, item, true))
	{
 		ActivateSF(client, idx, isPermanent);
		if(isPermanent) SF_InsertToDB(client, idx, true); // Update SpecialFunctions
	}
}
////////////////////////////////////////////////////////////////////

// Tell the agent what item you want to buy and which shop, it will help you buy it.
void CallAgent(int client, int id = -1, int shopId = -1)
{
	if(id == -1) id = g_iBuyItem[client][1];
	if(shopId == -1) shopId = g_iBuyItem[client][0];
 	int cost = GetConVarInt(cvar_costs[shopId][id]);
	char item [32];
	g_listItems[shopId==SHOP_SF_TRIAL || shopId==SHOP_SF_PERMANENT? SHOP_SF : shopId].GetString(id, item, sizeof(item));

	if(!GetConVarBool(cvar_shops_on[shopId]) || (IsInfected(client) && shopId != SHOP_INFECTED))
	{
		CPrintToChat(client, "%T%T%T", "SYSTEM", client, g_sShopTitles[shopId], client, "DISABLED", client);
		return;
	}

	if(cost < 0) 
	{
		char name[32];
		g_listItems[shopId].GetString(id, item, sizeof(item));
		AddTimeTag(client, shopId, item, name);
		CPrintToChat(client, "%T%T", "SYSTEM", client, "INVALID_ITEM", client, name);
		return;
	}

	if(shopId == SHOP_INFECTED)
	{
		if(id == 9) //tank
		{
			if (g_iNoOfTanks + 1 < GetConVarInt(cvar_tank_limit) + 1)
			{
				g_iNoOfTanks++;
			}
			else
			{
				CPrintToChat(client,"%T%T", "SYSTEM", client, "UP_TO_LIMIT", client, item);
				return;
			}
		}
		else if(id == 10) // witch
		{
			if (g_iNoOfWitches + 1 < GetConVarInt(cvar_witch_limit) + 1)
			{
				g_iNoOfWitches++;
			}
			else
			{
				CPrintToChat(client,"%T%T", "SYSTEM", client, "UP_TO_LIMIT", client, item);
				return;
			}
		}
		BuyItem(client, item, cost, TEAM_INFECTED);
	}
	else if(shopId == SHOP_MELEES) BuyMelee(client, item, cost);
	else if(shopId == SHOP_AMMOS)
	{
		switch(id)
		{
			case 4, 5: // Ammo upgrade packs
			{
				BuyItem(client, item, cost);
			}
			default :
			{
				UpgradeWeapon(client, item, cost);
			}

		}
	}
	else if(shopId == SHOP_MEDICINES && id == 4)
	{
		if(BuyItem(client, item, cost))
		{
			//Remove buffer hp
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		}
	}
	else if(shopId == SHOP_SF_TRIAL)
	{
		BuySF(client, id, cost, false);
	}
	else if(shopId == SHOP_SF_PERMANENT)
	{
		BuySF(client, id, cost, true);
	}
	else
	{
		BuyItem(client, item, cost);
	}
}

// Format item name to translated text.
public void AddTimeTag(int client, int shopId, const char[] item, char[] buffer)
{
	if(shopId == SHOP_SF_TRIAL)
		Format(buffer, 32, "%T%T",  item, client, "ONE_ROUND", client);
	else if(shopId == SHOP_SF_PERMANENT)
		Format(buffer, 32, "%T%T", item, client, "PERMANENT", client);
	else 
		Format(buffer, 32, "%T", item, client);
}

// pan0s | Activce Special function
public void ActivateSF(int client, int idx, bool isPermanent)
{
	if(IsAmmoColors(idx)) TurnOffAllAmmoColors(client);
	g_bClientSF[client][0][idx] = true;
	if(isPermanent) g_bClientSF[client][1][idx] = true;
}

// pan0s | Check functions
bool IsSurvivorDeadEx(int client, const char[] item)
{
	if(IsSurvivorDead(client))
	{
		char name[32];
		AddTimeTag(client, g_iBuyItem[client][0], item, name);
		CPrintToChat(client,"%T%T%T", "SYSTEM", client, "YOU_ARE_DEAD", client, "FAILED_TO_BUY", client, name);
		return true;
	}
	return false;
}

// pan0s | Handle !kill command function
public void KillClient(int client)
{
	if(IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
		CPrintToChatAll("%t", "SUICIDE", client);
	}else CPrintToChat(client, "%T", "YOU_ARE_DEAD", client);

}

//  pan0s | check the fucnctionNo is one of ammo color
public bool IsAmmoColors(int idx)
{
	for(int j=0; j < sizeof(g_sAmmoColors); j++)
		if(StrEqual(g_sAmmoColors[j], g_sSF[idx])) return true;
	return false;
}

// pan0s | close other ammo color before turning on an ammo color.
public void TurnOffAllAmmoColors(int client)
{
	if(GetEanbledAmmoColorIndex(client) != -1)
	{
		char ammo[255];
		for(int j=0; j < sizeof(g_sAmmoColors); j++)
		{
			// char s[255];
			// Format(s, sizeof(s), "Bag: %d", g_sAmmoColors[j]);
			int idx = GetFunctionIndex(g_sAmmoColors[j]);
			g_bClientSF[client][0][idx] = false;
			if(j == sizeof(g_sAmmoColors) -1)
			{
				Format(ammo, sizeof(ammo), "%sfunctionNo = '%s'",ammo, g_sAmmoColors[j]);
			}
			else
			{
				Format(ammo, sizeof(ammo), "%sfunctionNo = '%s' OR ",ammo, g_sAmmoColors[j]);
			}
		}
		char steamId[32];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		char query[255];
		Format(query, sizeof(query), "UPDATE SpecialFunctions SET isEnabled = 0 WHERE steamId = '%s' AND (%s)", steamId,ammo);
		// PrintToServer("[Shop] %s", query);
		SF_UpdateToDB(client, -1, 0, query, 1);
	}
}

public void SetWish(int client, int shopId, int item)
{
	g_iBuyItem[client][0] = shopId;
	g_iBuyItem[client][1] = g_listSellable[shopId].Get(item);
}

int GetHandlingFee(int client)
{
	float fhandling = GetConVarFloat(cvar_transfer_handling_fee) / 100.0 * g_iTransferPoints[client];
	int handling = RoundFloat(fhandling);
	return handling>0? handling: 1; // at least charge 1
}
// ====================================================================================================



// ====================================================================================================
//					pan0s | 8: Earning points hook functions
// ====================================================================================================
// ---------For special infected or survivor team--------------
//Kill special infected / survivors
public Action Event_PlayerDeath(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsSurvivor(attacker) && IsInfected(client))
	{
		int points = GetConVarInt(cvar_earn_special);
		if(AddPoints(attacker, points, false))
			CPrintToChat(attacker, "%T%T%T%T", "SYSTEM", attacker, "KILLED_SPECIAL_INFECTED", attacker, "REWARD_POINTS", attacker, points, "ADVERTISEMENT", attacker);
	}
	else if(IsInfected(attacker) && IsSurvivor(client))
	{
		int points = GetConVarInt(cvar_iearn_survivor);
		if(AddPoints(attacker, points, false))
			CPrintToChat(attacker, "%T%T%T%T", "SYSTEM", attacker, "KILLED_SURVIVOR", attacker, "REWARD_POINTS", attacker, points, "ADVERTISEMENT", attacker);
	}

	return Plugin_Handled;
}

// ---------For special infected team--------------
// Make survivor Incapacitated

public void PrintEarningMsg(int client, const char[] reason, int points)
{
	CPrintToChat(client, "%T%T%T%T", "SYSTEM", client, reason, client, "REWARD_POINTS", client, points, "ADVERTISEMENT", client);
}

public Action IncapacitatePoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsInfected(attacker) && IsSurvivor(client))
	{
		int points = GetConVarInt(cvar_iearn_incapacitate);
		if(AddPoints(attacker, points, false))
			PrintEarningMsg(attacker, "INCAPACITATE_SURVIVOR", points);
	}
	return Plugin_Handled;
}
// smoke grabs survivor
public Action GrabPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsInfected(attacker) && IsSurvivor(victim))
	{
		int points = GetConVarInt(cvar_iearn_grab);
		if(AddPoints(attacker, points, false))
			PrintEarningMsg(attacker, "PULLED_SURVIVOR", points);
	}
	return Plugin_Handled;	
}
// Charge pounces survivor
public Action PouncePoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsInfected(attacker) && IsSurvivor(victim))
	{
		int points = GetConVarInt(cvar_iearn_pounce);
		if(AddPoints(attacker, points, false))
			PrintEarningMsg(attacker, "POUNCED_SURVIVOR", points);
	}
	return Plugin_Handled;
}
// Boomers
public Action VomitPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsInfected(attacker))
	{
		int points = GetConVarInt(cvar_iearn_vomit);
		if(AddPoints(attacker, points, false))
			PrintEarningMsg(attacker, "TAGGED_SURVIVOR", points);
	}
	return Plugin_Handled;
}

public Action Charge_Pummel_Points(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

    int attacker = GetClientOfUserId(GetEventInt(event, "userid")); // charger
    int client = GetClientOfUserId(GetEventInt(event, "victim"));
    if (IsInfected(attacker) && IsSurvivor(client))
    {
		int points = GetConVarInt(cvar_iearn_charge);
		if(AddPoints(attacker, points, false))
			PrintEarningMsg(attacker, "CHARGED_SURVIVOR", points);
    }
	return Plugin_Handled;
}

public Action Charge_Collateral_Damage_Points(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

    int attacker = GetClientOfUserId(GetEventInt(event, "userid")); // charger
    int client = GetClientOfUserId(GetEventInt(event, "victim"));
    if (IsInfected(attacker) && IsSurvivor(client))
    {
		int points = GetConVarInt(cvar_iearn_charge_collateral);
		if(AddPoints(attacker, points, false))
			PrintEarningMsg(attacker, "COLLATERAL_DAMAGE", points);
    }
	return Plugin_Handled;
}

public Action Jockey_Ride_Points(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

    int attacker = GetClientOfUserId(GetEventInt(event, "userid")); // Jockey
    int client = GetClientOfUserId(GetEventInt(event, "victim"));
    if (IsInfected(attacker) && IsSurvivor(client))
    {
		int points = GetConVarInt(cvar_iearn_jockey_ride);
		if(AddPoints(attacker, points, false))
			PrintEarningMsg(attacker, "RODE_SURVIVOR", points);
    }
	return Plugin_Handled;
}

public Action HurtPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsInfected(attacker) && IsSurvivor(client))
	{
  		g_iHurtCount[attacker] += 1;
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == 4)  //is it a spitter?
		{
			if(g_iHurtCount[attacker] >= 8)
			{
				int points = GetConVarInt(cvar_iearn_hurt);
				if(AddPoints(attacker, points, false))
					PrintEarningMsg(attacker, "BATH_DAMAGE", points);
				g_iHurtCount[attacker] -= 8;
			}
		}  
		else  // Any SI but Spitter
		{
			if(g_iHurtCount[attacker] >= 3)
			{
				int points = GetConVarInt(cvar_iearn_hurt);
				if(AddPoints(attacker, points, false))
					PrintEarningMsg(attacker, "MULTIPLE_DAMAGE", points);
				g_iHurtCount[attacker] -= 3;
			}
		}   
	}
	return Plugin_Handled;
}

// ---------For survivor team--------------
public Action TankKill(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsSurvivor(attacker))
	{
		int points = GetConVarInt(cvar_earn_tank_killed);
		if( points > 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && !IsFakeClient(i))
				{
					AddPoints(i, points, false);
					CPrintToChat(i, "%T%T%T%T", "SYSTEM", i, "KILLED_TANK", i,"REWARD_POINTS", i, points, "ADVERTISEMENT", i);
				}
				g_bTankOnFire[i] = false;
			}
		}
	}
	return Plugin_Handled;
}

public Action WitchPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int instakill = GetEventBool(event, "oneshot");
	if(IsSurvivor(client))
	{
		int points = GetConVarInt(cvar_earn_witch);
		if(AddPoints(client, points, false))
				PrintEarningMsg(client, "KILLED_WITCH", points);
		if (instakill)
		{
			points = GetConVarInt(cvar_earn_witch_in_one_shot);
			if(AddPoints(client, points, false))
				PrintEarningMsg(client, "KILLED_WITCH_ONE_SHOT", points);
		}
	}
	return Plugin_Handled;
}

public Action TankBurnPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client))
	{
		char victim[64];
		GetEventString(event, "victimname", victim, sizeof(victim));
		if (StrEqual(victim, "Tank", false))
		{
			if(!g_bTankOnFire[client])
			{
				int points = GetConVarInt(cvar_earn_tank_burn);
				if(AddPoints(client, points, false))
					PrintEarningMsg(client, "BURNED_TANK", points);
				g_bTankOnFire[client] = true;
			}
		}
	}
	return Plugin_Handled;
}

public Action HealPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));
	if (IsSurvivor(client) && client != target)
	{
		int points = GetConVarInt(cvar_earn_heal);
		if(AddPoints(client, points, false))
			PrintEarningMsg(client, "HEALED_TEAMMATE", points);
	}
	return Plugin_Handled;
}

public Action KillPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	// int headshot = GetEventBool(event, "headshot");
	// int minigun = GetEventBool(event, "minigun");
	if (IsSurvivor(client))
	{
		g_iKilledInfectedCount[client] += 1;
		if (g_iKilledInfectedCount[client] >= GetConVarInt(cvar_earn_infected_num))
		{
			int points = GetConVarInt(cvar_earn_infected);
			if(AddPoints(client, points, false))
				CPrintToChat(client, "%T%T%T%T","SYSTEM", client, "KILLED_INFECTED", client, GetConVarInt(cvar_earn_infected_num), "REWARD_POINTS", client, GetConVarInt(cvar_earn_infected), "ADVERTISEMENT", client);
			g_iKilledInfectedCount[client] -= GetConVarInt(cvar_earn_infected_num);
		}
	}
	return Plugin_Handled;
}

public Action RevivePoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));
	bool isLedgeHang = GetEventBool(event, "ledge_hang");

	if (IsSurvivor(client) && client != target)
	{
		if(isLedgeHang)
		{
			int points = GetConVarInt(cvar_earn_revive_ledge_hang);
			if(AddPoints(client, points, false))
				PrintEarningMsg(client, "REVIVED_TEAMMATE_LEDGE", points);
		}
		else
		{
			int points = GetConVarInt(cvar_earn_revive);
			if(AddPoints(client, points, false))
				PrintEarningMsg(client, "REVIVED_TEAMMATE", points);
		}
	}
	return Plugin_Handled;
}
public Action AwardPoints(Handle event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int award = GetEventInt(event, "award");
	if (IsSurvivor(client))
	{
		if(award == 67) //Protect someone
		{
			if(g_hTimerReward[client] == INVALID_HANDLE) g_hTimerReward[client] = CreateTimer(0.3, HandleReward, client);
		}
	}
	return Plugin_Handled;
}

public Action HandleReward(Handle timer, int client)
{
	int points = GetConVarInt(cvar_earn_protect);
	if(AddPoints(client, points, false))
		PrintEarningMsg(client, "PROTECTED_TEAMMATE", points);
	g_hTimerReward[client] = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action Event_DefibrillatorUsed(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	// int target = GetClientOfUserId(GetEventInt(event, "subject"));

	int points = GetConVarInt(cvar_earn_defibrillate);
	if(AddPoints(client, points, false))
		PrintEarningMsg(client, "DEFIBRILLATE_TEAMMATE", points);
	return Plugin_Handled;
}

public Action Event_Rescued(Event event, char[] event_name, bool dontBroadcast)
{
	int rescuer = GetClientOfUserId(GetEventInt(event, "rescuer"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!g_bPointsOn || rescuer == victim) return Plugin_Handled;

	int points = GetConVarInt(cvar_earn_rescued);
	if(AddPoints(rescuer, points, false))
		PrintEarningMsg(rescuer, "RESCUED", points);
	return Plugin_Handled;
}
// ====================================================================================================



// ====================================================================================================
//					pan0s | 9: Admin menu (ref: all4dead)
// ====================================================================================================
public void MenuCategoryHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength) 
{
	if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "%T:", "MENU_ADMIN_OPTION", client);
	else if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "MENU_ADMIN_OPTION", client);
}

/// Register our menus with SourceMod
// Added for admin menu
public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == g_hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	g_hTopMenu = topmenu;
	g_hTopMenu.AddCategory("Shop Commands", MenuCategoryHandler, "sm_admin_point", ADMFLAG_KICK, "Admin points function");
	TopMenuObject shopAdminMmenu = g_hTopMenu.FindCategory("Shop Commands");
	if (shopAdminMmenu == INVALID_TOPMENUOBJECT)
	{
		LogError("[ERROR]: Init admin menu error.");
		return;
	}
	g_hAdminAdd = g_hTopMenu.AddItem("reward", InitiateMenuAdmin, shopAdminMmenu);
	g_hAdminConfiscate = g_hTopMenu.AddItem("confiscate ", InitiateMenuAdmin, shopAdminMmenu);
	g_hAdminSet = g_hTopMenu.AddItem("set", InitiateMenuAdmin, shopAdminMmenu);
}

public void InitiateMenuAdmin(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption) 
	{
		if(object_id == g_hAdminAdd)
			Format(buffer, maxlength, "%T", "MENU_ADD_POINTS", client);
		else if(object_id == g_hAdminConfiscate)
			Format(buffer, maxlength, "%T", "MENU_REDUCE_POINTS", client);
		else if(object_id == g_hAdminSet)
			Format(buffer, maxlength, "%T", "MENU_SET_POINTS", client);
	} 
	else if (action == TopMenuAction_SelectOption) 
	{
		if(object_id == g_hAdminAdd)
			g_iAdminAction[client] = ADMIN_ADD_POINT;
		else if(object_id == g_hAdminConfiscate)
			g_iAdminAction[client] = ADMIN_CONFISCATE;
		else if(object_id == g_hAdminSet)
			g_iAdminAction[client] = ADMIN_SET_POINT;
		MenuPointValuesList(client, false);
	}
}

///Creates the director commands menu when it is selected from the top menu and displays it to the client.
public Action MenuPointValuesList(int client, any args) 
{
	Menu menu = CreateMenu(MenuPointValuesListHandler);
	SetMenuTitle(menu, "%T","MENU_TITLE_POINTS_LIST", client);
	for(int i = 0; i < sizeof(g_iAdminPointList); i++)
	{
		char option [64];
		char optionName [10];
		Format(option, sizeof(option), "%d",  g_iAdminPointList[i]);
		Format(optionName, sizeof(optionName),"option%d", i);
		AddMenuItem(menu, optionName, option);
	}
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

// Handles callbacks from a client using the director commands menu.
public int MenuPointValuesListHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if (action == MenuAction_Select) 
	{
		g_iAdminPoints[client] = g_iAdminPointList[itemNum];
		MenuPlayerList(client, false);
	}
	else if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (itemNum == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hTopMenu, client, TopMenuPosition_LastCategory);
	}
}

/// Creates the director commands menu when it is selected from the top menu and displays it to the client.
public Action MenuPlayerList(int client, any args) 
{
	Menu menu = CreateMenu(MenuPlayerListHandler);
	char title[64];
	switch(g_iAdminAction[client])
	{
		case ADMIN_ADD_POINT:
		{
			Format(title,sizeof(title),"%T","MENU_TITLE_ADD_LIST", client, g_iAdminPoints[client]);
		}
		case ADMIN_CONFISCATE:
		{
			Format(title,sizeof(title),"%T","MENU_TITLE_CONFISCATE_LIST", client, g_iAdminPoints[client]);
		}
		case ADMIN_SET_POINT:
		{
			Format(title,sizeof(title),"%T","MENU_TITLE_SET_LIST", client, g_iAdminPoints[client]);
		}
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	GetPlayerList(client, menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

/// Handles callbacks from a client using the director commands menu.
public int MenuPlayerListHandler(Handle menu, MenuAction action, int client, int itempos) 
{
	if (action == MenuAction_Select) 
	{
		// Log
		int selectedClient = g_listIHuman.Get(itempos);
		char selectedSteamId[32]; 
		g_listSHumanSteamId.GetString(itempos, selectedSteamId, 32);
		char steamId[32];
		GetClientAuthId(selectedClient, AuthId_Steam2, steamId, 32);

		if(!StrEqual(selectedSteamId, steamId))
		{
			LogError("[ERROR] Admin Function failed. The steam id of %N doesn't match. (%s != %s)", selectedClient, selectedSteamId, steamId);
			CPrintToChat(client, "[Shop] Failed to do that for {BLUE}%N{DEFAULT}. \nReason: steamId doesn't match. (%s != %s)", selectedClient, selectedSteamId, steamId);
			MenuPlayerList(client, false);
			return 0;
		}

		char sAction[16];

		switch(g_iAdminAction[client])
		{
			case ADMIN_ADD_POINT:
			{
				AddPoints(selectedClient, g_iAdminPoints[client], false);
				CPrintToChat(selectedClient,"%T%T (%T{GREEN}%d{DEFAULT})", "SYSTEM", client, "ADMIN_ADD_POINT", client, g_iAdminPoints[client], "CURRENT_POINTS", client, g_iPoints[selectedClient]);
				CPrintToChat(client, "[Shop] Success to reward {GREEN}%d{DEFAULT} points to {BLUE}%N {DEFAULT}(%T{GREEN}%d{DEFAULT}) ",g_iAdminPoints[client], selectedClient, "CURRENT_POINTS", client, g_iPoints[selectedClient]);
				Format(sAction, sizeof(sAction), "rewarded");

			}
			case ADMIN_CONFISCATE:
			{
				ReducePoints(selectedClient, g_iAdminPoints[client], false);
				CPrintToChat(selectedClient,"%T%T (%T{GREEN}%d{DEFAULT})", "SYSTEM", client, "ADMIN_CONFISCATE_POINT", client, g_iAdminPoints[client], "CURRENT_POINTS", client, g_iPoints[selectedClient]);
				CPrintToChat(client, "[Shop] Success to confiscate {GREEN}%d{DEFAULT} points to {BLUE}%N {DEFAULT}(%T{GREEN}%d{DEFAULT}) ",g_iAdminPoints[client], selectedClient, "CURRENT_POINTS", client, g_iPoints[selectedClient]);
				Format(sAction, sizeof(sAction), "reduced");
			}
			case ADMIN_SET_POINT:
			{
				g_iPoints[selectedClient] = g_iAdminPoints[client];
				CPrintToChat(selectedClient,"%T%T (%T{GREEN}%d{DEFAULT})", "SYSTEM", client, "ADMIN_SET_POINT", client, g_iAdminPoints[client], "CURRENT_POINTS", client, g_iPoints[selectedClient]);
				CPrintToChat(client, "[Shop] Success to set {GREEN}%d{DEFAULT} points to {BLUE}%N {DEFAULT}(%T{GREEN}%d{DEFAULT}) ",g_iAdminPoints[client], selectedClient, "CURRENT_POINTS", client, g_iPoints[selectedClient]);
				Format(sAction, sizeof(sAction), "set");
			}
		}
		// Log the admin action.
		LogAction(client, selectedClient, "[Admin]: \"%L\" %s \"%d\" points for \"%L\" (current: \"%d\")", client, sAction, g_iAdminPoints[client], selectedClient, g_iPoints[selectedClient]);

		MenuPlayerList(client, false);
	}
	else if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (itempos == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hTopMenu, client, TopMenuPosition_LastCategory);
	}
	return 0;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | 10: Menu setting functions
// ====================================================================================================
void SetMenuContent(int client, Menu menu, char[][] names, int size, bool isExitable = false)
{
	for(int i = 0; i < size; i++)
	{
		char option [64];
		char optionName [10];
		Format(option, sizeof(option), "%T", names[i], client);
		Format(optionName, sizeof(optionName),"option%d", i);
		AddMenuItem(menu, optionName, option);
	}
	if(isExitable) SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void GetPlayerList(int client, Menu menu, bool isAdminMenu)
{
	g_listIHuman.Clear();
	g_listSHumanSteamId.Clear();
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			// to ensure the player is accuracy (if player disccounted, it may wrong.)
			char steamId[32];
			GetClientAuthId(i, AuthId_Steam2, steamId, 32);
			g_listIHuman.Push(i);
			g_listSHumanSteamId.PushString(steamId);

			char clientName[100];
			char optionName[16];
			if(isAdminMenu)
				Format(clientName, sizeof(clientName),"%N (%T%d)", i, "CURRENT_POINTS", client, g_iPoints[i]);
			else
				Format(clientName, sizeof(clientName),"%N", i);
			Format(optionName, sizeof(optionName),"%d", i);

			AddMenuItem(menu, optionName, clientName);
		}
	}
}

void SetShopContent(int client, int shopId)
{
	g_hMenus[client].SetTitle("%T\n%T%d", g_sShopTitles[shopId], client, "CURRENT_POINTS", client, g_iPoints[client]);

	switch (shopId)
	{
		case SHOP_MAIN:
		{
			SetMenuContent(client, g_hMenus[client], g_sShop, sizeof(g_sShop));
		}
		case SHOP_GUNS:
			SetMenuContent(client, g_hMenus[client], g_sGunsShop, sizeof(g_sGunsShop), true);
		case SHOP_SF:
			SetMenuContent(client, g_hMenus[client], g_sSFShop, sizeof(g_sSFShop), true);
		case SHOP_SF_BAG:
		{
			int owned = 0;
			for(int i=0; i< SF_SIZE; i++)
			{
				if(g_bClientSF[client][1][i])
				{
					owned++;
					char isEnabled[15];
					char item[32];
					char option[64];
					char optionName[10];
					if(g_bClientSF[client][0][i]) isEnabled = "ENABLED"; 
					else isEnabled = "DISABLED"; 
					g_listItems[SHOP_SF].GetString(i, item, sizeof(item));
					Format(option, sizeof(option), "%T%T:%T", item, client, "PERMANENT", client, isEnabled, client);
					Format(optionName, sizeof(optionName),"option%d", i);
					g_hMenus[client].AddItem(optionName, option);
					g_hMenus[client].ExitBackButton= true;
					g_hMenus[client].ExitButton = true;
				}
			}
			if(owned < 1)
			{
				CPrintToChat(client,"%T%T", "SYSTEM", client, "NO_PERMANENT_ITEM", client);
				return;
			}
		}
		case SHOP_TRANSFER:
		{
			g_hMenus[client].SetTitle("%T%d\n%T", "CURRENT_POINTS", client, g_iPoints[client], "MENU_TITLE_POINTS_LIST", client );
			for(int i = 0; i < sizeof(g_iTransferPointList); i++)
			{
				char option [64];
				char optionName [10];
				Format(option, sizeof(option), "%d",  g_iTransferPointList[i]);
				Format(optionName, sizeof(optionName),"option%d", i);
				g_hMenus[client].AddItem(optionName, option);
				g_hMenus[client].ExitBackButton= true;
				g_hMenus[client].ExitButton = true;
			}
		}
		default:
		{
			int index = shopId;
			if(shopId == SHOP_SF_TRIAL || shopId == SHOP_SF_PERMANENT) index = SHOP_SF;
			g_listSellable[index].Clear();
			for(int i = 0; i< g_listItems[index].Length; i++)
			{
				if(GetConVarInt(cvar_costs[shopId][i]) >= 0)
				{
					char option[64];
					char optionName[10];
					char item[32];
					char name[32];
					g_listItems[index].GetString(i, item, 32);
					AddTimeTag(client, shopId, item, name);

					Format(option, sizeof(option),"%s", name);
					Format(optionName, sizeof(optionName),"option%d", i);
					g_hMenus[client].AddItem(optionName, option);
					g_listSellable[shopId].Push(i);
				}
			}
			g_hMenus[client].ExitBackButton= true;
			g_hMenus[client].ExitButton = true;
		}
	}
	g_hMenus[client].Display(client, MENU_TIME_FOREVER);

}
// ====================================================================================================


// ====================================================================================================
//					pan0s | 11: Handle commands functions
// ====================================================================================================

public bool ConvertShortcutToFull(const char[] cmd, char[] buffer)
{
	for(int i =0; i< sizeof(g_sShortcutItemCmds); i++)
		if(StrEqual(g_sShortcutItemCmds[i][1], cmd))
		{
			Format(buffer, 32, "%s", g_sShortcutItemCmds[i][0]);
			return true;
		}
	return false;
}

public bool GetBuyItemInfoByCmd(const char[] cmd, int[] buffer, bool isInfeected)
{ 
	if(isInfeected)
	{
		for(int i =0; i<sizeof(g_sInfectedItems); i++)
			if(StrEqual(g_sInfectedItems[i], cmd, false))
			{
				buffer[0] = SHOP_INFECTED; // shop id
				buffer[1] = i; // item id
				return true;
			} 
	}
	else
	{
		for(int i =0; i<sizeof(g_sSmgs); i++)
			if(StrEqual(g_sSmgs[i], cmd, false))
			{
				buffer[0] = SHOP_SMGS; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sRifles); i++)
			if(StrEqual(g_sRifles[i], cmd, false))
			{
				buffer[0] = SHOP_RIFLES; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sSnipers); i++)
			if(StrEqual(g_sSnipers[i], cmd, false))
			{
				buffer[0] = SHOP_SNIPERS; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sShotguns); i++)
			if(StrEqual(g_sShotguns[i], cmd, false))
			{
				buffer[0] = SHOP_SHOTGUNS; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sOthers); i++)
			if(StrEqual(g_sOthers[i], cmd, false))
			{
				buffer[0] = SHOP_OTHERS; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sMelees); i++)
			if(StrEqual(g_sMelees[i], cmd, false))
			{
				buffer[0] = SHOP_MELEES; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sThrowables); i++)
			if(StrEqual(g_sThrowables[i], cmd, false))
			{
				buffer[0] = SHOP_THROWABLES; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sAmmos); i++)
			if(StrEqual(g_sAmmos[i], cmd, false))
			{
				buffer[0] = SHOP_AMMOS; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sMedicines); i++)
			if(StrEqual(g_sMedicines[i], cmd, false))
			{
				buffer[0] = SHOP_MEDICINES; // shop id
				buffer[1] = i; // item id
				return true;
			} 

		for(int i =0; i<sizeof(g_sMedicines); i++)
			if(StrEqual(g_sMedicines[i], cmd, false))
			{
				buffer[0] = SHOP_MEDICINES; // shop id
				buffer[1] = i; // item id
				return true;
			} 
	}
	return false;
}

public Action HandleCmdOpenShop(int client, int args) 
{
	if(!g_bPointsOn) return Plugin_Handled;

	if(IsInfected(client)) 
	{
		delete g_hMenus[client];
		g_hMenus[client] = CreateMenu(HandleMenuInfected);
		SetShopContent(client, SHOP_INFECTED);
	}
	else if(IsSurvivor(client)) 
	{
		char cmd[32];
		GetCmdArgString(cmd, sizeof(cmd));
		int shopId = args == 0? 1: StringToInt(cmd);

		if(shopId != 0)
		{
			shopId -= 1;

			// check case.
			bool check = true;
			switch(shopId)
			{
				case SHOP_SF, SHOP_SF_TRIAL, SHOP_SF_PERMANENT, SHOP_SF_BAG:
					if(!GetConVarBool(cvar_db_on)) check=false;
				case SHOP_TRANSFER:
					if(!GetConVarBool(cvar_transfer_on)) check=false;
			}
			if(!check)
			{
				CPrintToChat(client, "%T%T%T", "SYSTEM", client, g_sShopTitles[shopId], client, "DISABLED", client);
				return Plugin_Handled;
			}

			delete g_hMenus[client];
			g_hMenus[client] = CreateMenu(HandleMenuInfected);

			switch(shopId)
			{
				case SHOP_MAIN:
					g_hMenus[client] = CreateMenu(HandleMenuBuy);
				case SHOP_GUNS:
					g_hMenus[client] = CreateMenu(HandleMenuGuns);
				case SHOP_SMGS:
					g_hMenus[client] = CreateMenu(HandleMenuSmgs);
				case SHOP_RIFLES:
					g_hMenus[client] = CreateMenu(HandleMenuRifles);
				case SHOP_SNIPERS:
					g_hMenus[client] = CreateMenu(HandleMenuSnipers);
				case SHOP_SHOTGUNS:
					g_hMenus[client] = CreateMenu(HandleMenuShotguns);
				case SHOP_OTHERS:
					g_hMenus[client] = CreateMenu(HandleMenuOthers);
				case SHOP_MELEES:
					g_hMenus[client] = CreateMenu(HandleMenuMelees);
				case SHOP_THROWABLES:
					g_hMenus[client] = CreateMenu(HandleMenuThrowables);
				case SHOP_AMMOS:
					g_hMenus[client] = CreateMenu(HandleMenuAmmos);
				case SHOP_MEDICINES:
					g_hMenus[client] = CreateMenu(HandleMenuMedicines);
				case SHOP_SF:
					g_hMenus[client] = CreateMenu(HandleMenuSF);
				case SHOP_SF_TRIAL:
					g_hMenus[client] = CreateMenu(HandleMenuSFTrial);
				case SHOP_SF_PERMANENT:
					g_hMenus[client] = CreateMenu(HandleMenuSFPermanent);
				case SHOP_SF_BAG:
					g_hMenus[client] = CreateMenu(HandleMenuBag);
				case SHOP_TRANSFER:
					g_hMenus[client] = CreateMenu(HandleMenuTransfer);
				default:
				{
					CPrintToChat(client, "%T shop does not exist.", "SYSTEM", client);
					return Plugin_Handled;
				}
			}
			SetShopContent(client, shopId);
		}
		else
		{
			// TODO: buy item by sm_buy <item>
			bool isValid = false;
			int buyInfo[2];
			char shortcut[32];
			if(ConvertShortcutToFull(cmd, shortcut)) isValid = GetBuyItemInfoByCmd(shortcut, buyInfo, IsInfected(client));
			else isValid = GetBuyItemInfoByCmd(cmd, buyInfo, IsInfected(client));
			
			if(isValid) 
			{
				for(int i=0; i<sizeof(buyInfo); i++) g_iBuyItem[client][i] = buyInfo[i];
				CallAgent(client);
			}
			else CPrintToChat(client, "%T%T", "SYSTEM", client, "INVALID_ITEM", client, cmd);
		}
	}
	else
	{
		CPrintToChat(client, "%T%T", "SYSTEM", client, "ONLY_USED_BY", client);
	}
	return Plugin_Handled;
}

public Action HandleCmdTest(int client, int args) 
{
	char weaponName[32];
	GetClientWeapon(client, weaponName, 32);
	PrintToChat(client,"MaxClient:%d, weapons:%s", MaxClients, weaponName);

	if(StrEqual(weaponName, "weapon_melee"))
	{
		char meleeName[32];
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", meleeName, sizeof(meleeName));
		PrintToChat(client,"%s", meleeName);
	}
}

public Action HandleCmdBuyConfirm(int client, int args) 
{
	if(!g_bPointsOn) return Plugin_Handled;
	delete g_hMenus[client];
	g_hMenus[client] = new Menu(HandleMenuBuyConfirm);

	int shopId = g_iBuyItem[client][0];
	int id = g_iBuyItem[client][1];

	int cost = GetConVarInt(cvar_costs[shopId][id]);
	int remaining = g_iPoints[client]-cost;

	char item[32];
	char name[32];
	g_listItems[shopId==SHOP_SF_TRIAL || shopId==SHOP_SF_PERMANENT? SHOP_SF : shopId].GetString(id, item, sizeof(item));
	AddTimeTag(client, g_iBuyItem[client][0], item, name);

	g_hMenus[client].SetTitle("%T", "MENU_BUY_CONFIRM", client, name, cost, g_iPoints[client], remaining);

	for(int i=0; i< sizeof(g_sBuyConfirmOptions); i++)
	{
		char option [64];
		char optionName [10];
		Format(option, sizeof(option), "%T", g_sBuyConfirmOptions[i], client);
		Format(optionName, sizeof(optionName),"option%d", i);
		g_hMenus[client].AddItem(optionName, option);
	}

	g_hMenus[client].ExitButton = true;
	g_hMenus[client].Display(client, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action HandleCmdPointsHelp(int client, int args)
{
	if(!g_bPointsOn) return Plugin_Handled;
	CPrintToChat(client, "%T%T", "SYSTEM", client, "HELP", client);
	return Plugin_Handled;
}

public Action HandleCmdShowPoints(int client, int args)
{
	if(!g_bPointsOn) return Plugin_Handled;
	CPrintToChat(client, "%T%T {GREEN}%d{DEFAULT}.", "SYSTEM", client, "CURRENT_POINTS", client ,g_iPoints[client]);
	CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
	return Plugin_Handled;
}

public Action HandleCmdRefill(int client, int args)
{
	//Give player ammo
	CheatCommand(client, "give", "ammo");
	return Plugin_Handled;
}

public Action HandleCmdHeal(int client, int args)
{
	//Give player health
	CheatCommand(client, "give", "health");
	return Plugin_Handled;
}

public Action HandleCmdFakeGod(int client, int args)
{
	if (g_iGodOn[client] <= 0)
	{
		g_iGodOn[client] = 1;
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	else
	{
		g_iGodOn[client] = 0;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);  
	}
	
	return Plugin_Handled;
}

// Repact buy
public Action HandleCmdRepeatBuy(int client, int args)
{
	HandleCmdBuyConfirm(client, 0);
	return Plugin_Handled;
}

public Action HandleCmdSuicide(int client, int args) 
{
	if(!g_bPointsOn || !GetConVarBool(cvar_suicide_cmd_on)) return Plugin_Handled;

	if(IsInfected(client))
	{
		if(GetConVarInt(cvar_costs[SHOP_INFECTED][0]) < 0)
		{
			CPrintToChat(client,"%T%T", "SYSTEM", client, "NOT_ALLOW_SUICIDE", client);
			return Plugin_Handled;
		}
		HandleCmdBuyConfirm(client, 0);
	}
	else
	{	// Suicide without cost for survivors.
		Menu menu = CreateMenu(HandleMenuSuicide);
		menu.SetTitle("%T", "MENU_SUICIDE" ,client);
		SetMenuContent(client, menu, g_sSuicideOptions, sizeof(g_sSuicideOptions));
	}
	return Plugin_Handled;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | 12: Handle menu selected functions.
// ====================================================================================================
public int HandleMenuBuy(Handle menu, MenuAction action, int client, int itemNum)
{
	Handle gamemodevar = FindConVar("mp_gamemode");
	char gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if ( action == MenuAction_Select ) 
	{
		g_iBuyItem[client][0] = SHOP_MAIN;
		switch (itemNum)
		{
			case 0: //guns
			{
				CheatCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
            case 1: //melee
           	{
				CheatCommand(client, g_sShopCmds[SHOP_MELEES]);
			}
           	case 2: //explosives
            {
				CheatCommand(client, g_sShopCmds[SHOP_THROWABLES]);
            }
			case 3: //ammo
			{
				CheatCommand(client, g_sShopCmds[SHOP_AMMOS]);
			}
            case 4: //health
           	{
				CheatCommand(client, g_sShopCmds[SHOP_MEDICINES]);
			}
            case 5: //health
           	{
				CheatCommand(client, g_sShopCmds[SHOP_SF]);
			}
            case 6: //health
           	{
				CheatCommand(client, g_sShopCmds[SHOP_TRANSFER]);
			}
		}
	}
}

public int HandleMenuInfected(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_INFECTED, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuGuns(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			g_iBuyItem[client][0] = SHOP_GUNS;
        	if(itemNum == 0) CheatCommand(client, g_sShopCmds[SHOP_SMGS]);
			else if(itemNum == 1) CheatCommand(client, g_sShopCmds[SHOP_RIFLES]);
			else if(itemNum == 2) CheatCommand(client, g_sShopCmds[SHOP_SNIPERS]);
			else if(itemNum == 3) CheatCommand(client, g_sShopCmds[SHOP_SHOTGUNS]);
			else if(itemNum == 4) CheatCommand(client, g_sShopCmds[SHOP_OTHERS]);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}

	}
}

public int HandleMenuSmgs(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SMGS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;
}

public int HandleMenuRifles(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_RIFLES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;

}

public int HandleMenuSnipers(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SNIPERS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;
}

public int HandleMenuShotguns(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SHOTGUNS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;
}

public int HandleMenuOthers(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_OTHERS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;    
}

public int HandleMenuMelees(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_MELEES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuThrowables(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_THROWABLES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuAmmos(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_AMMOS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuMedicines(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_MEDICINES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuSFTrial(Handle menu, MenuAction action, int client, int itemNum)
{

	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SF_TRIAL, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_SF]);
			}
		}
	}
}

public int HandleMenuSFPermanent(Handle menu, MenuAction action, int client, int itemNum)
{
    
	switch(action) 
	{
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SF_PERMANENT, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_SF]);
			}
		}
	}
	return 0;
}

// Points trasnfer--------------------------------------------------------------------------->
public int HandleMenuTransfer(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			g_iTransferPoints[client] = g_iTransferPointList[itemNum];
			ShowMenuTransferPlayerList(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public Action ShowMenuTransferPlayerList(int client, int args)
{
	Menu menu = CreateMenu(HandleTransferPlayerList);
	char title[64];
	Format(title, sizeof(title), "%T%d\n%T", "CURRENT_POINTS", client, g_iPoints[client], "MENU_TITLE_TRANSFER_POINT", client, g_iTransferPoints[client]);
	SetMenuTitle(menu, title);

	GetPlayerList(client, menu, false);
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int HandleTransferPlayerList(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			g_iTransferTarget[client] = itemNum;
			ShowMenuTransferConfirm(client, itemNum);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_TRANSFER]);
			}
		}
	}
}

public Action ShowMenuTransferConfirm(int client, int args)
{
	delete g_hMenus[client];
	g_hMenus[client] = new Menu(HandleTransferConfirm);
	char title[64];
	int handling = GetHandlingFee(client);
	int selectedClient = g_listIHuman.Get(args);
	int after = g_iPoints[client] - handling - g_iTransferPoints[client];
	Format(title,sizeof(title),"%T%N\n%T%d\n%T%d", "MENU_TITLE_TRANSFER_POINT", client, g_iTransferPoints[client], selectedClient, "HANDLING_FEE", client, handling, "AFTER_TRANSFERRED_BALANCE", client, after);
	g_hMenus[client].SetTitle(title);
	g_hMenus[client].ExitButton = false;
	SetMenuContent(client, g_hMenus[client], g_sYesNo, sizeof(g_sYesNo));
}

public int HandleTransferConfirm(Handle menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select) 
	{
		// Log
		if(itemNum == 0)
		{
			int selectedClient = g_listIHuman.Get(g_iTransferTarget[client]);
			char selectedSteamId[32]; 
			g_listSHumanSteamId.GetString(g_iTransferTarget[client], selectedSteamId, 32);
			char steamId[32];
			GetClientAuthId(selectedClient, AuthId_Steam2, steamId, 32);

			if(!StrEqual(selectedSteamId, steamId))
			{
				CPrintToChat(client, "%T%T", "SYSTEM", client, "USER_MISMATCH", client);
				ShowMenuTransferPlayerList(client, 0);
				return 0;
			}

			int handling = GetHandlingFee(client);
			if(handling + g_iTransferPoints[client] > g_iPoints[client])
			{
				CPrintToChat(client, "%T%T","SYSTEM", client, "FAILED_TO_TRANSFER", client, client, g_iTransferPoints[client], handling, g_iPoints[client]);
				return 0;
			}

			AddPoints(selectedClient, g_iTransferPoints[client], false);
			ReducePoints(client, handling + g_iTransferPoints[client], false);

			if(GetConVarBool(cvar_transfer_notify_all_on))
			{
				for(int i=1; i<=MaxClients; i++)
					if(IsValidClient(i)) CPrintToChat(i, "%T%T", "SYSTEM", i,"TRANSFERRED_ALL", i, client, g_iTransferPoints[client], selectedClient, handling);
			}
			else
			{
				CPrintToChat(client, "%T%T", "SYSTEM", client, "TRANSFERRED_TO", client, selectedClient, g_iTransferPoints[client], handling);
				CPrintToChat(selectedClient, "%T%T(%T{GREEN}%d{DEFAULT})", "SYSTEM", selectedClient, "TRANSFERRED", selectedClient, client, g_iTransferPoints[client], "CURRENT_POINTS", client, g_iPoints[client]);
			}
			LogAction(client, selectedClient, "\"%L\" (Balacne: \"%d\") tansferred \"%d\"+\"%d\" points to \"%L\" (Balacne: \"%d\")", client, g_iPoints[client], g_iTransferPoints[client], handling, selectedClient, g_iPoints[selectedClient]);

		}
		else
		{
			CheatCommand(client, g_sShopCmds[SHOP_TRANSFER]);
		}
	}
	return 0;
}
// <--------------------------------------------------------------------------- Points trasnfer
public int HandleMenuBuyConfirm(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select)
	{
		if(itemNum == 0) CallAgent(client);
		else 
		{
			// return to last visiting shopId.
			int shopId = g_iBuyItem[client][0];
			CheatCommand(client, g_sShopCmds[shopId]);
		}
	}
	return 0;
}

public int HandleMenuSuicide(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select)
	{
		if(itemNum == 0 && IsSurvivor(client)) 
		{
			KillClient(client);
		}
	}else if(action == MenuAction_End) delete menu;
	return 0;
}

// Special functions shop
public int HandleMenuSF(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
      		switch (itemNum)
			{
				case 0: // Trial shop
				{
					CheatCommand(client, g_sShopCmds[SHOP_SF_TRIAL]);
				}
				case 1: // Permanent shop
				{
					CheatCommand(client, g_sShopCmds[SHOP_SF_PERMANENT]);
				}
				case 2: // Bag
				{
					CheatCommand(client, g_sShopCmds[SHOP_SF_BAG]);
				}
			}
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
}

public int HandleMenuBag(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action) 
	{
		case MenuAction_Select:
		{
			int idx = 0;
			for(int i=0; i< SF_SIZE; i++)
			{
				if(g_bClientSF[client][1][i])
				{
					if(idx++ == itemNum)
					{
						bool tempValue = !g_bClientSF[client][0][i];
						int idxs[2];
						idxs[0] = GetFunctionIndex(g_sAmmoColors[0]);
						idxs[1] = GetFunctionIndex(g_sAmmoColors[4]);
						if(tempValue && i>= idxs[0] && i<= idxs[1])
						{
							// turn off all colorful ammo
							TurnOffAllAmmoColors(client);
						}
						g_bClientSF[client][0][i] = tempValue;
						SF_UpdateToDB(client, i, g_bClientSF[client][0][i],"",0);
						// char s[255];
						// Format(s, sizeof(s), "Bag: %d/%d", idx, i);
						CheatCommand(client, g_sShopCmds[SHOP_SF_BAG]);
						return 0;
					}
				}
			}
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_SF]);
			}
		}
	}
	return 0;
}

public int HandleMenuInfectedItems(Handle menu, MenuAction action, int client, int itemNum)
{

	switch(action) 
	{
		case MenuAction_Select:
		{
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel: 
		{
			if(itemNum == MenuCancel_ExitBack) 
			{
				CheatCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | Speical functions (Copy from other plugin)
// ====================================================================================================
// Speical functions

public bool IsSFOn (int client, int idx)
{
	bool isOn = GetConVarInt(cvar_costs[SHOP_SF_TRIAL][idx]) >= 0 && GetConVarInt(cvar_costs[SHOP_SF_PERMANENT][idx]) >= 0;
	return g_bClientSF[client][0][idx] && GetConVarBool(cvar_sf_on) && isOn;
}

// |------------------------------ Auto bhop ------------------------------|
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if ( IsSFOn(client, AUTO_BHOP) && IsPlayerAlive(client))
	{
		if (buttons & IN_JUMP)
		{
			if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
			{
				if (GetEntityMoveType(client) != MOVETYPE_LADDER)
				{
					buttons &= ~IN_JUMP;
				}
			}
		}
	}
	return Plugin_Continue;
}
//
// |------------------------------ Laser tag ------------------------------|
public void UselessHooker(Handle convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	CheckWeapons(INVALID_HANDLE, "", "");
	
	g_LaserLife = GetConVarFloat(cvar_laser_life);
	g_LaserWidth = GetConVarFloat(cvar_laser_width);
	g_LaserOffset = GetConVarFloat(cvar_laser_offset);
}

public void CheckWeapons(Handle convar, const char[] oldValue, const char[] newValue)
{
	b_TagWeapon[WEAPONTYPE_PISTOL] = GetConVarBool(cvar_pistols);
	b_TagWeapon[WEAPONTYPE_RIFLE] = GetConVarBool(cvar_rifles);
	b_TagWeapon[WEAPONTYPE_SNIPER] = GetConVarBool(cvar_snipers);
	b_TagWeapon[WEAPONTYPE_SMG] = GetConVarBool(cvar_smgs);
	b_TagWeapon[WEAPONTYPE_SHOTGUN] = GetConVarBool(cvar_shotguns);
}

public int GetWeaponType(int userid)
{
	// Get current weapon
	char weapon[32];
	GetClientWeapon(userid, weapon, 32);
	
	if(StrEqual(weapon, "weapon_hunting_rifle") || StrContains(weapon, "sniper") >= 0) return WEAPONTYPE_SNIPER;
	if(StrContains(weapon, "weapon_rifle") >= 0) return WEAPONTYPE_RIFLE;
	if(StrContains(weapon, "pistol") >= 0) return WEAPONTYPE_PISTOL;
	if(StrContains(weapon, "smg") >= 0) return WEAPONTYPE_SMG;
	if(StrContains(weapon, "shotgun") >=0) return WEAPONTYPE_SHOTGUN;
	
	return WEAPONTYPE_UNKNOWN;
}

public int GetEanbledAmmoColorIndex(int client)
{

	for(int i=0; i < sizeof(g_sAmmoColors); i++)
	{
		int idx = GetFunctionIndex(g_sAmmoColors[i]);
		if(g_bClientSF[client][0][idx]) return idx;
	}
	return -1;
}

public int GetPurchasedAmmoColorIndex(int client)
{

	for(int i=0; i < sizeof(g_sAmmoColors); i++)
	{
		int idx = GetFunctionIndex(g_sAmmoColors[i]);
		if(g_bClientSF[client][1][idx]) return idx;
	}
	return -1;
}

public Action Event_BulletImpact(Handle event, const char[] name, bool dontBroadcast)
{
	// Get Shooter's Userid
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	int colorIndex = GetEanbledAmmoColorIndex(client);
	if(!g_bPointsOn || colorIndex == -1 || !IsSFOn(client, colorIndex)) return Plugin_Continue;
	
	// Check if is Survivor
 	if(!IsSurvivor(client)) return Plugin_Continue;
	// Check if is Bot and enabled
	// int bot = 0;
	// if(IsFakeClient(client)) { if(!g_Bots) return Plugin_Continue; bot = 1; }
	
	// Check if the weapon is an enabled weapon type to tag
	if(b_TagWeapon[GetWeaponType(client)])
	{
		// Bullet impact location
		float x = GetEventFloat(event, "x");
		float y = GetEventFloat(event, "y");
		float z = GetEventFloat(event, "z");
		
		float startPos[3];
		startPos[0] = x;
		startPos[1] = y;
		startPos[2] = z;
		
		/*float bulletPos[3];
		bulletPos[0] = x;
		bulletPos[1] = y;
		bulletPos[2] = z;*/
		
		float bulletPos[3];
		bulletPos = startPos;
		
		// Current player's EYE position
		float playerPos[3];
		GetClientEyePosition(client, playerPos);
		
		float lineVector[3];
		SubtractVectors(playerPos, startPos, lineVector);
		NormalizeVector(lineVector, lineVector);
		
		// Offset
		ScaleVector(lineVector, g_LaserOffset);
		// Find starting point to draw line from
		SubtractVectors(playerPos, lineVector, startPos);
		
		switch(colorIndex)
		{
			case GRAY_AMMO:
			{
				g_LaserColor[0] = 108;//red
				g_LaserColor[1] = 108;//greem
				g_LaserColor[2] = 108;//blue
				g_LaserColor[3] = 20; // alpha
			}
			case RED_AMMO:
			{
				g_LaserColor[0] = 214;//red
				g_LaserColor[1] = 31;//greem
				g_LaserColor[2] = 31;//blue
				g_LaserColor[3] = 40; // alpha
			}
			case GOLD_AMMO:
			{
				g_LaserColor[0] = 255;//red
				g_LaserColor[1] = 234;//greem
				g_LaserColor[2] = 0;//blue
				g_LaserColor[3] = 40; // alpha
			}
			case BLUE_AMMO:
			{
				g_LaserColor[0] = 0;//red
				g_LaserColor[1] = 168;//greem
				g_LaserColor[2] = 255;//blue
				g_LaserColor[3] = 40; // alpha
			}
			case GREEN_AMMO:
			{
				g_LaserColor[0] = 101;//red
				g_LaserColor[1] = 244;//greem
				g_LaserColor[2] = 68;//blue
				g_LaserColor[3] = 40; // alpha
			}
		}

		// char text[255];
		// Format(text, sizeof(text), "Color: %d / %d", colorIndex, GRAY_AMMO);

		// Draw the line
		TE_SetupBeamPoints(startPos, bulletPos, g_Sprite, 0, 0, 0, g_LaserLife, g_LaserWidth, g_LaserWidth, 1, 0.0, g_LaserColor, 0);
	
		
		TE_SendToAll();
	}
	
 	return Plugin_Continue;
}

// Added by Psyk0tik (Crasher_3637)
void CheatCommand(int client, const char[] command, const char[] arguments = "")
{
	int iCmdFlags = GetCommandFlags(command), iFlagBits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetUserFlagBits(client, iFlagBits);
	SetCommandFlags(command, iCmdFlags|FCVAR_CHEAT);
}