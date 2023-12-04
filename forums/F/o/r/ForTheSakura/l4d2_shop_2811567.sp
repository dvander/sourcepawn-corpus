/*
										Code Index
====================================================================================================
#1: Variables
#2: Init array list
#3: Database (SQLITE) func.
#4: Hook events
#5: Overrided functions
#6: Control points
#7: important functions
#8: Earning points hook functions
#9: Admin menu (ref: all4dead)
#10: Menu setting functions
#11: Handle commands functions
#12: Menu menu selected functions.
#13: Speical functions (Copy from other plugin)
#14: Native registion
#15: Library functions override
*/

#define PLUGIN_VERSION "v4.5"

/*
										Update LOG
====================================================================================================
v4.5 (20 March 2022)
	- Added a new item Lethal Ammo (in SHOP_AMMO)
	- Added native functions: AddPoints, ReducePoints, SetPoints
	- Will stop update until I have time
	

v4.4 (19 March 2022)
	- Added a new SF China Qing Gong
	- SF on/off will not be save immediately now
	- Added some native functions

v4.3 (18 March 2022)
	- Added airstrike and extinguisher(Thanks VYRNACH_GAMING for adding this)
	- Added more shop on checking.
	- Moved some global variables to shop_cv.inc
	- Simplified adding a new item. Adding cost convar is not necessary now as you will set the price in shop_cv.inc
	- Rename ConVar in .cfg (you may need to delete old l4d2_shop.cfg to get the latest one)
	- Fixed Transfer Point title 

v4.2 (16 March 2022)
	- Fixed memory leak

v4.1 (15 March 2022)
	- Added gnome and cola bottles (Thanks NoroHime)

v4.0 (15 March 2022)
	- Fixed Client index is invalid
	- Supported Native function.

v3.0 (15 March 2022)
	- Fixed round reset bug.
	- Fixed survivors can buy infected shop item by command.
	- Added ConVar to set points after resetting points.

v2.9 (25 Feb 2022)
	- Tank and Witch limit bug, reported by laurauwu.

v2.8 (27 July 2021)
	- Fixed SI id that doesn't match and the number of them do not reset, reported by ryxzxz
	- Fixed the cheat command exploit by Crasher_3637

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
//					pan0s | #1: Variables
// ====================================================================================================
//
#define DEFAULT_FLAGS FCVAR_NOTIFY
#define ADMIN_ADD_POINT			0
#define ADMIN_CONFISCATE		1
#define ADMIN_SET_POINT			2
#define ADMIN_ACTION_SIZE		4
#define CVAR_FLAGS FCVAR_NOTIFY
#define DATABASE 		"clientprefs" //SQLITE

#define IsClientIndex(%1) (1 <= %1 <= MaxClients)
#define IsClient(%1) (IsClientIndex(%1) && IsValidEntity(%1) && IsClientInGame(%1))
#define IsSurvivorHumanAlive(%1) (IsClient(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == 2 && IsPlayerAlive(%1))
#define IsSurvivorHumanDead(%1) (IsClient(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == 2 && !IsPlayerAlive(%1))
#define IsInfectedHumanAlive(%1) (IsClient(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == 3 && IsPlayerAlive(%1))
#define IsInfectedHumanDead(%1) (IsClient(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == 3 && !IsPlayerAlive(%1))

#include <sdktools>
#include <sourcemod>
#include <adminmenu>
#include <sdkhooks>
#include <pan0s>
#include <shop_cv>
#undef REQUIRE_PLUGIN

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "[L4D2] Shop (Points and Gift System)",
    author = "v2.0+ Updated by pan0s. Original author: Drakcol - Fixed by AXIS_ASAKI",
    description = "An item buying system for Left 4 Dead 2 that is based on (-DR-)GrammerNatzi's Left 4 Dead 1 item buying system. This plug-in allows clients to gain points through various accomplishments and use them to buy items and health/ammo refills. It also allows admins to gift the same things to MaxClients and grant them god mode. Both use menus, no less.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=332186"
}

/*Convar Variables*/
ConVar cvar_shop_on;
ConVar cvar_shops_on[SHOP_SIZE];
ConVar cvar_shop_versus_on;
ConVar cvar_shop_realism_on;
ConVar cvar_shop_survival_on;
ConVar cvar_shop_team_survival_on;
ConVar cvar_shop_team_versus_on;
ConVar cvar_shop_coop_on;
ConVar cvar_shop_scavenger_on;
ConVar cvar_db_on;
ConVar cvar_round_clear_on;
ConVar cvar_transfer_handling_fee;
ConVar cvar_transfer_notify_all_on;
ConVar cvar_buy_notify_all_on;
ConVar cvar_suicide_cmd_on;
ConVar cvar_sf_on;
ConVar cvar_infected_buy_respawn_on;
ConVar cvar_reset_points;

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

/*Some Important Variables*/
bool g_bIsShown[MAXPLAYERS + 1];
bool g_bPointsOn;
bool g_bTankOnFire[MAXPLAYERS + 1];
bool g_bClientSF[MAXPLAYERS + 1][2][SF_SIZE]; // The 2nd array, 0 = Trial, 1 = Permanent , // bool to turn on/off client special funcions

int g_iMOSOn[MAXPLAYERS + 1];
int g_iPoints[MAXPLAYERS + 1];
int g_iKilledInfectedCount[MAXPLAYERS + 1];
int g_iNoOfTanks;
int g_iNoOfWitches;
int g_iHurtCount[MAXPLAYERS + 1];

// Native funcion
Handle g_hFowards[2];
// bool g_bIsLate;

ArrayList g_listSellable[SHOP_SIZE];
ArrayList g_listItems[SHOP_SIZE];
int g_iBuyItem[MAXPLAYERS + 1][2];
char g_sBuyConfirmOptions[][] = {"BUY_YES","BUY_NO"};
char g_sSuicideOptions[][] = {"SUICIDE_YES","SUICIDE_NO"};
char g_sYesNo[][] = {"YES","NO"};
int g_iAdminPointList[] = { 10000, 20000, 50000, 100000, 1000000, };
int g_iTransferPointList[] = { 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, };

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


public void CreateCostConVar(int shopId, const char[][][] item, int size)
{
	char shopType[32] = { 0 };
	int dId = 2;
	int pId = 1;
	switch(shopId)
	{
		case SHOP_INFECTED: Format(shopType, sizeof(shopType), "%s", "infected_");
		case SHOP_SF_TRIAL: 
		{
			dId = 3;
			Format(shopType, sizeof(shopType), "%s", "trial_");
			
		}
		case SHOP_SF_PERMANENT: 
		{
			dId = 3;
			pId = 2;
			Format(shopType, sizeof(shopType), "%s", "premanent_");
		}
	}

	for(int i = 0; i<size; i++)
	{
		char cvName[64];
		char description[64];
		Format(cvName, sizeof(cvName), "shop_cost_%s%s", shopType, item[i][0]);
		Format(description, sizeof(description), "How many points %s costs. -1=Disabled", item[i][dId]);
		cvar_costs[shopId][i] = CreateConVar(cvName, item[i][pId], description, CVAR_FLAGS);
	}
}
public void OnPluginStart()
{
    // Load multiple language txt file

// ====================================================================================================
//					pan0s | #2: Init variables
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
	for(int i=0; i<sizeof(g_sInfectedItems); i++) g_listItems[SHOP_INFECTED].PushString(g_sInfectedItems[i][0]);

	// SMGs
	for(int i=0; i<sizeof(g_sSmgs); i++) g_listItems[SHOP_SMGS].PushString(g_sSmgs[i][0]);

	// Rifle
	for(int i=0; i<sizeof(g_sRifles); i++) g_listItems[SHOP_RIFLES].PushString(g_sRifles[i][0]);

	// Snipers
	for(int i=0; i<sizeof(g_sSnipers); i++) g_listItems[SHOP_SNIPERS].PushString(g_sSnipers[i][0]);

	// Shotguns
	for(int i=0; i<sizeof(g_sShotguns); i++) g_listItems[SHOP_SHOTGUNS].PushString(g_sShotguns[i][0]);

	// Other guns
	for(int i=0; i<sizeof(g_sOthers); i++) g_listItems[SHOP_OTHERS].PushString(g_sOthers[i][0]);

	// melee weapons
	for(int i=0; i<sizeof(g_sShopMelees); i++) g_listItems[SHOP_MELEES].PushString(g_sShopMelees[i][0]);

	// Throwables
	for(int i=0; i<sizeof(g_sThrowables); i++) g_listItems[SHOP_THROWABLES].PushString(g_sThrowables[i][0]);

	// Ammos
	for(int i=0; i<sizeof(g_sAmmos); i++) g_listItems[SHOP_AMMOS].PushString(g_sAmmos[i][0]);

	// Medicines
	for(int i=0; i<sizeof(g_sMedicines); i++) g_listItems[SHOP_MEDICINES].PushString(g_sMedicines[i][0]);

	// Special functions
	for(int i=0; i<sizeof(g_sSF); i++) g_listItems[SHOP_SF].PushString(g_sSF[i][0]);

	// Airstrike
	for(int i=0; i<sizeof(g_sAirstrike); i++) g_listItems[SHOP_AIRSTRIKE].PushString(g_sAirstrike[i][0]);
	// ===============================================================================================

	/*Commands*/
	RegAdminCmd("sm_refill", HandleCmdRefill, ADMFLAG_ROOT);
	RegAdminCmd("sm_heal", HandleCmdHeal, ADMFLAG_ROOT);
	RegAdminCmd("sm_mos",HandleCmdManOfSteel, ADMFLAG_ROOT);
	RegAdminCmd("sm_test", HandleCmdTest, ADMFLAG_ROOT);
	RegConsoleCmd("sm_point", HandleCmdShowPoints);
	RegConsoleCmd("sm_points", HandleCmdShowPoints);
	RegConsoleCmd("sm_repeatbuy",HandleCmdRepeatBuy);
	RegConsoleCmd("sm_rb",HandleCmdRepeatBuy);
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
	RegConsoleCmd("sm_gg", HandleCmdSuicide);
	RegConsoleCmd("sm_ggwp", HandleCmdSuicide);
	RegConsoleCmd("sm_imdone", HandleCmdSuicide);
	RegConsoleCmd("sm_gonext", HandleCmdSuicide);

	/////////////////////////////////////////////////////////////////////////////
	//Added airstrike and extinguisher(Thanks VYRNACH_GAMING for adding this)
	RegConsoleCmd("sm_airstrike", HandleCmdAirstrike);
	RegConsoleCmd("sm_air", HandleCmdAirstrike);
	RegConsoleCmd("sm_extinguisher", HandleCmdExtinguisher);
	RegConsoleCmd("sm_ext", HandleCmdExtinguisher);
	RegConsoleCmd("sm_flamethrower", HandleCmdExtinguisher);
	RegConsoleCmd("sm_flamer", HandleCmdExtinguisher);
	RegConsoleCmd("sm_fire", HandleCmdExtinguisher);
	/////////////////////////////////////////////////////////////////////////////

	//this signals that the plugin is on on this server
	CreateConVar("shop_version", PLUGIN_VERSION, "l4d2_shop version.", CVAR_FLAGS);
	/* Values for Convars*/
	cvar_db_on 								= CreateConVar("shop_db_on","1","Will server save points? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_round_clear_on 					= CreateConVar("shop_round_clear_on","0","Will clear points every round? 0=OFF, 1=On (works with db_on=0 only)",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_reset_points		 				= CreateConVar("shop_reset_points","0","How many points players will have after resetting point every round? (works with db_on=0 only)",CVAR_FLAGS);
	cvar_transfer_notify_all_on 			= CreateConVar("shop_transfer_notify_all_on","1","Will notify all players who did transferring? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_buy_notify_all_on 					= CreateConVar("shop_buy_notify_all_on","1","Will notify all players when a player buy an item? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_suicide_cmd_on 					= CreateConVar("shop_suicide_cmd_on","1","Can survivor suicide by !kill? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_sf_on 								= CreateConVar("shop_sf_on","1","Enable Special functions? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_infected_buy_respawn_on 			= CreateConVar("shop_infected_buy_respawn_on","1","Only dead infected can buy respawn? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shop_on 							= CreateConVar("shop_on","1","Shop system is on? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shop_versus_on 					= CreateConVar("shop_versus_on","1","Shop is on for versus mode? 0=OFF, 1=On",CVAR_FLAGS,true, 0.0, true, 1.0);
	cvar_shop_realism_on 					= CreateConVar("shop_realism_on","1","Shop is on for realism mode? 0=OFF, 1=On",CVAR_FLAGS,true, 0.0, true, 1.0);
	cvar_shop_coop_on 						= CreateConVar("shop_coop_on","1","Shop is on for coop mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shop_scavenger_on 					= CreateConVar("shop_scavenger_on","1","Shop is on for scavenger mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shop_survival_on 					= CreateConVar("shop_survival_on","1","Shop is on for survival mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shop_team_survival_on 				= CreateConVar("shop_team_survival_on","1","Shop is on for team survival mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shop_team_versus_on 				= CreateConVar("shop_team_versus_on","1","Shop is on for team versus mode? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	
	// Enable / disable the shop
	cvar_shops_on[SHOP_MAIN]				= CreateConVar("shop_shop_main_on","1","Open the main shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_INFECTED]			= CreateConVar("shop_shop_infected_item_on","1","Open the infected item shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_GUNS]				= CreateConVar("shop_shop_guns_on","1","Open the guns shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SMGS]				= CreateConVar("shop_shop_smgs_on","1","Open the smgs shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_RIFLES]				= CreateConVar("shop_shop_riflese_on","1","Open the rifles shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SNIPERS]				= CreateConVar("shop_shop_snipers_on","1","Open the snupers shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SHOTGUNS]			= CreateConVar("shop_shop_shotguns_on","1","Open the shotgunsc shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_OTHERS]				= CreateConVar("shop_shop_others_on","1","Open the others shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_MELEES]				= CreateConVar("shop_shop_melees_on","1","Open the melees shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_THROWABLES]			= CreateConVar("shop_shop_throwables_on","1","Open the throwables shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_AMMOS]				= CreateConVar("shop_shop_ammoss_on","1","Open the ammos shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_MEDICINES]			= CreateConVar("shop_shop_medicines_on","1","Open the ammos shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF]					= CreateConVar("shop_shop_sf_on","1","Open the ammos shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF_TRIAL]			= CreateConVar("shop_shop_sf_trial_on","1","Open the trial shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF_PERMANENT]		= CreateConVar("shop_shop_sf_permanet_on","1","Open the permanet shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_SF_BAG]				= CreateConVar("shop_shop_sf_bag_on","1","Open the bag? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_TRANSFER]			= CreateConVar("shop_shop_sf_transfer_on","1","Open the tansfer shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_shops_on[SHOP_AIRSTRIKE]			= CreateConVar("shop_shop_airstrike_on","1","Open the airstrike shop? 0=OFF, 1=On",CVAR_FLAGS, true, 0.0, true, 1.0);

	cvar_transfer_handling_fee 				= CreateConVar("shop_transfer_handling_fee","20","Percentage of handling fee for each transferring point.",CVAR_FLAGS, true, 0.0, true, 99.0);

	cvar_shop_infected_respawn				= CreateConVar("shop_shop_infected_respawn","0","Where do player respawn after buying infected? 0=Near Survivors, 1=Current location",CVAR_FLAGS, true, 0.0, true, 1.0);

	/* earn points convars */
	cvar_iearn_grab 						= CreateConVar("shop_infected_earn_grab","1","How many points you get [as a smoker] when you pull a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_pounce 						= CreateConVar("shop_infected_earn_pounce","1","How many points you get [as a hunter] when you pounce a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_vomit 						= CreateConVar("shop_infected_earn_vomit","1","How many points you get [as a boomer] when you vomit/explode on a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_charge 						= CreateConVar("shop_infected_earn_charge","1","How many points you get [as a charger] after impact on survivor, for 1 pummel damage. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_charge_collateral			= CreateConVar("shop_infected_earn_charge_collateral","1","How many points you get [as a charger] when hitting nearby survivors. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_jockey_ride 					= CreateConVar("shop_infected_earn_jockey_ride","1","How many points you get when jumping on a survivor. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_hurt 						= CreateConVar("shop_infected_earn_hurt","2","How many points infected get for hurting survivors a number of times. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_incapacitate 				= CreateConVar("shop_infected_earn_incapacitate","5","How many points you get for incapacitating a survivor 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_iearn_survivor 					= CreateConVar("shop_infected_earn_survivor","10","How many points you get for killing a survivor 0=Disabled",CVAR_FLAGS, true, 0.0);

	cvar_earn_witch							= CreateConVar("shop_earn_witch","10","How many points you get for killing a witch. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_witch_in_one_shot 			= CreateConVar("shop_earn_witch_in_one_shot","10","How many extra points you get for killing a witch in one shot. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_tank_burn 					= CreateConVar("shop_earn_tank_burn","3","How many points you get for burning a tank. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_tank_killed 					= CreateConVar("shop_earn_tank_killed","2","How many additional points you get for killing a tank. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_infected 						= CreateConVar("shop_earn_infected","1","How many points for killing a certain number of infected. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_infected_num 					= CreateConVar("shop_earn_infected_num","10","How many killed infected does it take to earn points? Headshot and minigun kills can be used to rank up extra kills. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_special						= CreateConVar("shop_earn_special","1","How many points for killing a special infected. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_heal 							= CreateConVar("shop_earn_heal","5","How many points for healing someone. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_defibrillate					= CreateConVar("shop_earn_defibrillate","5","How many points rewarded to player who used defibrillator 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_protect 						= CreateConVar("shop_earn_protect","1","How many points for protecting someone. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_rescued		 				= CreateConVar("shop_earn_rescued","2","How many points rewarded to player who rescued the dead client. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_revive 						= CreateConVar("shop_earn_revive","2","How many points for reviving someone. 0=Disabled",CVAR_FLAGS, true, 0.0);
	cvar_earn_revive_ledge_hang 			= CreateConVar("shop_earn_revive_ledge_hang","1","How many points for reviving someone who is in ledge hang/ 0=Disabled",CVAR_FLAGS,true,0.0);

	//! cost is refer to shop_cv.inc
	/*Infected Price Convars*/
	CreateCostConVar(SHOP_INFECTED, g_sInfectedItems, sizeof(g_sInfectedItems));

	/*SMG cost Convars*/
	CreateCostConVar(SHOP_SMGS, g_sSmgs, sizeof(g_sSmgs));

	/*Rifle cost Convars*/
	CreateCostConVar(SHOP_RIFLES, g_sRifles, sizeof(g_sRifles));

	/*Sniper cost Convars*/
	CreateCostConVar(SHOP_SNIPERS, g_sSnipers, sizeof(g_sSnipers));

	/*Shotgun cost Convars*/
	CreateCostConVar(SHOP_SHOTGUNS, g_sShotguns, sizeof(g_sShotguns));

	/*Other cost Convars*/
	CreateCostConVar(SHOP_OTHERS, g_sOthers, sizeof(g_sOthers));

	/*Melee cost Convars*/
	CreateCostConVar(SHOP_MELEES, g_sShopMelees, sizeof(g_sShopMelees));

	/*Throwable cost Convars*/
	CreateCostConVar(SHOP_THROWABLES, g_sThrowables, sizeof(g_sThrowables));

	/*Ammo cost Convars*/
	CreateCostConVar(SHOP_AMMOS, g_sAmmos, sizeof(g_sAmmos));

	/*Heal cost Convars*/
	CreateCostConVar(SHOP_MEDICINES, g_sMedicines, sizeof(g_sMedicines));

	/*Airstrike price*/
	CreateCostConVar(SHOP_AIRSTRIKE, g_sAirstrike, sizeof(g_sAirstrike));

	// SF cost Convars
	CreateCostConVar(SHOP_SF_TRIAL, g_sSF, sizeof(g_sSF));
	CreateCostConVar(SHOP_SF_PERMANENT, g_sSF, sizeof(g_sSF));

	/*Item-Related Convars*/
	cvar_tank_limit 						= CreateConVar("shop_limit_tanks"				,"1"	,"How many tanks can be spawned in a round.",CVAR_FLAGS, true, 0.0, true, 60.0);
	cvar_witch_limit 						= CreateConVar("shop_limit_witches"				,"2"	,"How many witches can be spawned in a round.",CVAR_FLAGS, true, 0.0, true, 60.0);

	//
	cvar_invoice_type 						= CreateConVar("shop_inovice_type"				,"1"	,"Inovice display type. 0=simple, 1=detail", DEFAULT_FLAGS, true, 0.0, true, 1.0);

	//3: Event Hooks
	/*Event Hooks*/
	HookEvent("player_death", Event_PlayerDeath);
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
	HookEvent("round_end", RoundEnd);
	HookEvent("round_start", RoundStart);

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
//					pan0s | #3: Database (SQLITE) func.
// ====================================================================================================
//
Database ConnectDB()
{
	if(!cvar_db_on.BoolValue) return null;

	char error[255];
	Database db = SQL_Connect(DATABASE, true, error, sizeof(error));
	
	if (db == null)
	{
	    LogError("[ERROR]: Could not connect: \"%s\"", error);
	}
	return db;
}

void CreateDBTable()
{
	Database db = ConnectDB();
	if (db != null)
	{
		DBResultSet rsShop = SQL_Query(db, "CREATE TABLE IF NOT EXISTS Shop(steamId TEXT, points INTEGER, PRIMARY KEY (steamId))");
		char isSucceed[255];
		isSucceed = rsShop.RowCount>0? "Success." : "Already existesd.";
		if(rsShop.RowCount>0)
		{
			LogMessage("[CREATE]: Create Shop table: \"%s\"", isSucceed);
		}
		else PrintToServer("[Shop] Create Shop table: %s", isSucceed);

		DBResultSet rsSF = SQL_Query(db, "CREATE TABLE IF NOT EXISTS SpecialFunctions(steamId TEXT, functionNo TEXT, isEnabled INTEGER, PRIMARY KEY (steamId, functionNo))");
		isSucceed = rsSF.RowCount>0? "Created." : "Already existesd.";
		if(rsSF.RowCount>0)
		{
			LogMessage("[CREATE]: Create SpecialFunctions table: \"%s\"", isSucceed);
		}
		else PrintToServer("[Shop] Create SpecialFunctions table: %s", isSucceed);

		delete rsShop, rsSF;
	}
	delete db;
}

int LoadPoints(int client)
{
	int db_points = 0;
	Database db = ConnectDB();
	if (db != null)
	{
		char steamId[32];
		char error[255];

		DBStatement hSFQuery, hShopQuery;

		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		///////////////////////////////////////////////////
		// Load special functions
		if ((hSFQuery = SQL_PrepareQuery(db, "SELECT functionNo, isEnabled FROM SpecialFunctions WHERE steamId = ?", error, sizeof(error))) == null)
		{
			LogError("[ERROR]: SELECT SQL_PrepareQuery: \"%s\"", error);
		}
		else
		{
			// Disabled all special function first
			for(int i =0; i< SF_SIZE; i++)
			{
				g_bClientSF[client][0][i] = false;
				g_bClientSF[client][1][i] = false;
			}
			hSFQuery.BindString(0, steamId, false);
			if (SQL_Execute(hSFQuery))
			{
				while(SQL_FetchRow(hSFQuery))
				{
					char functionNo[32];
					SQL_FetchString(hSFQuery, 0, functionNo, sizeof(functionNo));
					int index = GetFunctionIndex(functionNo);
					bool isEnabled = SQL_FetchInt(hSFQuery, 1) == 1;
					g_bClientSF[client][0][index] = isEnabled;
					g_bClientSF[client][1][index] = true;
				}
			}
		}


		///////////////////////////////////////////////////

		///////////////////////////////////////////////////
		// Load points
		if ((hShopQuery = SQL_PrepareQuery(db, "SELECT steamId,points FROM Shop WHERE steamId = ?", error, sizeof(error))) == null)
		{
			LogError("[ERROR]: SELECT SQL_PrepareQuery: \"%s\"", error);
		}
		else
		{
			hShopQuery.BindString(0, steamId, false);
			// Find the client in the database
			if (SQL_Execute(hShopQuery))
			{
				char playerName[64];
				GetClientName(client, playerName, sizeof(playerName));
				if(SQL_FetchRow(hShopQuery))
				{
					SQL_FetchString(hShopQuery, 0, steamId, sizeof(steamId));
					db_points = SQL_FetchInt(hShopQuery, 1);
					LogAction(client, -1, "[LOAD]: \"%L\" loaded the record successfully! Points: \"%d\"", client, db_points);
				}
				else //INSERT
				{
					// if the user is not existed in the database, insert new one.
					DBStatement hInsertStmt;
					if ((hInsertStmt = SQL_PrepareQuery(db, "INSERT INTO Shop(steamId, points) VALUES(?,?)", error, sizeof(error))) == INVALID_HANDLE)
					{
						LogError("[ERROR]: INSERT SQL_PrepareQuery: \"%s\"", error);
					}
					else
					{
						hInsertStmt.BindString(0, steamId, false);
						hInsertStmt.BindInt(1, 0, false); // Default point is 0
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
		}

		delete hSFQuery, hShopQuery;
		////////////////////////////////
	}
	delete db;

	return db_points;
}

int SaveToDB(int client)
{
	//(points)\[(.*)\](.*[\+|\-]=.*)
	//(.*)(points)\[(.*)\](.*-=)(.*);
	//$1g_iPoints[$3]$4$5;\n$1CPrintToChat(client,"%t%t", "SYSTEM", "SUCCEED_TO_BUY",$5, g_iPoints[client]);
	// database connection
	int affectRows = 0;
	Database db = ConnectDB();
	if (db != null)
	{
		if(client && IsValidClient(client) && !IsFakeClient(client))
		{
			char error[255];
			// database statment
			DBStatement hUpdateShopStmt;
			char steamId[32];
			GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
			if ((hUpdateShopStmt = SQL_PrepareQuery(db, "UPDATE Shop SET points = ? WHERE steamId = ?", error, sizeof(error))) == null)
			{
				LogError("[ERROR]: UPDATE SQL_PrepareQuery: \"%s\"", error);
			}
			else
			{
				hUpdateShopStmt.BindInt(0, g_iPoints[client], false);
				hUpdateShopStmt.BindString(1, steamId, false);

				if (!SQL_Execute(hUpdateShopStmt))
				{
					LogError("[ERROR]: Update Shop SQL_Execute: \"%s\"", error);
				}
				else
				{
					char playerName[64];
					GetClientName(client, playerName, sizeof(playerName));
					affectRows = SQL_GetAffectedRows(hUpdateShopStmt);
					if(affectRows>0)
					{
						LogAction(client, -1,"[UPDATE]: \"%L\" saved. Points: \"%d\"", client, g_iPoints[client]);
					}
				}
			}
			delete hUpdateShopStmt;

			
			// SF
			char query[2][256];
			int size[2];
			for(int i=0; i < SF_SIZE; i++)
			{
				if(g_bClientSF[client][1][i])
				{
					if(g_bClientSF[client][0][i])
					{
						if(size[0]++ == 0)
						{
							Format(query[0], 256, "functionNo = '%s'", g_sSF[i][0]);

						}
						else
						{
							Format(query[0], 256, "%s OR functionNo = '%s'", query[0], g_sSF[i][0]);
						}
					}
					else
					{
						if(size[1]++ == 0)
						{
							Format(query[1], 256, "functionNo = '%s'", g_sSF[i][0]);

						}
						else
						{
							Format(query[1], 256, "%s OR functionNo = '%s'", query[1], g_sSF[i][0]);
						}
					}
				}
			}
			// save on
			if(size[0] > 0) 
			{
				Format(query[0], 256, "UPDATE SpecialFunctions SET isEnabled = 1 WHERE steamId = '%s' AND (%s)", steamId, query[0]);
				LogAction(-1, -1, "%s", query[0]);
				SF_UpdateToDB(client, -1, 0, query[0], 256);
			}
			// save off
			if(size[1] > 1) 
			{
				Format(query[1], 256, "UPDATE SpecialFunctions SET isEnabled = 0 WHERE steamId = '%s' AND (%s)", steamId, query[1]);
				LogAction(-1, -1, "%s", query[1]);
				SF_UpdateToDB(client, -1, 0, query[1], 256);
			}
		}
	}
	delete db;
	return affectRows;
}

void SF_InsertToDB(int client, int idx, int isEnabled)
{
	// database connection
	Database db = ConnectDB();
	if (db != null)
	{
		DBStatement hInsertStmt;
		char error[255];
		char steamId[32];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		if ((hInsertStmt = SQL_PrepareQuery(db, "INSERT INTO SpecialFunctions(steamId, functionNo, isEnabled) VALUES(?,?,?)", error, sizeof(error))) == null)
		{
			LogError("[ERROR]: INSERT SpecialFunctions SQL_PrepareQuery: \"%s\"", error);
		}
		else
		{
			hInsertStmt.BindString(0, steamId, false);
			hInsertStmt.BindString(1, g_sSF[idx][0], false);
			hInsertStmt.BindInt(2, isEnabled, false);

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
				LogAction(client, -1, "[SF]: \"%L\" have purchased a permanent item \"%s\" (functionNo:\"%s\").", client, name, g_sSF[idx][0]);
			}
		}
	  	delete hInsertStmt;
	}
	delete db;
}

void SF_UpdateToDB(int client, int idx, int isEnabled, const char[] query, int querySize)
{
	// database connection
	Database db = ConnectDB();
	if (db != null)
	{
		DBStatement hUpdateStmt;
		char steamId[32];
		char error[255];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		if ((hUpdateStmt = SQL_PrepareQuery(db, querySize > 0? query:"UPDATE SpecialFunctions SET isEnabled = ? WHERE steamId = ? AND functionNo = ?", error, sizeof(error))) == null)
		{
			LogError("[ERROR]: UPDATE SpecialFunctions SQL_PrepareQuery: \"%s\"", error);
		}
		else
		{
			if(querySize <= 0)
			{
				hUpdateStmt.BindInt(0, isEnabled, false);
				hUpdateStmt.BindString(1, steamId, false);
				hUpdateStmt.BindString(2, g_sSF[idx][0], false);
			}
			if (!SQL_Execute(hUpdateStmt))
			{
				LogError("[ERROR]: UPDATE SpecialFunctions SQL_Execute: \"%s\"", error);
			}
			else
			{
				char item[32];
				if(idx>=0) g_listItems[SHOP_SF].GetString(idx, item, sizeof(item));
				// LogAction(client, -1, "[SF_ON/OFF]: \"%L\" %s the permanent item \"%T\" (functionNo:\"%s\"). Affected rows: \"%d\"", client, isEnabled?"enabled":"disabled", idx>=0?item:"ALL_AMMO_COLORS", client, idx>=0? g_sSF[idx][0]: "-", SQL_GetAffectedRows(hUpdateStmt));
			}
		}
		delete hUpdateStmt;
	}
	delete db;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | #4: Hook events
// ====================================================================================================
public void RoundResetClient(int client)
{
	// Reset points
	if(!cvar_db_on.BoolValue && cvar_round_clear_on.BoolValue) g_iPoints[client] = cvar_reset_points.IntValue;
	// Reset special Functions
	for(int j = 0; j< SF_SIZE; j++)
	{
		if(!g_bClientSF[client][1][j]) // if client bought the function, dont reset.
			g_bClientSF[client][0][j] = false;
	}
}

// Reset trial special Functions
public void RoundReset()
{
	g_iNoOfWitches = 0;
	g_iNoOfTanks = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		RoundResetClient(i);
	}
}

public Action RoundStart(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;
	//RoundReset();
	return Plugin_Continue;
}

public Action RoundEnd(Event event, char[] event_name, bool dontBroadcast)
{
	//RoundReset();
	SaveAll();
	return Plugin_Continue;
}

public Action PlayerJoinTeam(Event event, char[] event_name, bool dontBroadcast)
{
	int player_id = event.GetInt("userid", 0);
	int player = GetClientOfUserId(player_id);
	int disconnect = event.GetBool("disconnect");

	ResetPoints(player, disconnect);
	//if (!IsFakeClient(player))
	//{
	//	CreateTimer(1.0, ShowLoad, player, 0);
	//}
	return Plugin_Continue;
}
// Handle Timer
public Action ShowLoad(Handle timer, int client)
{
	if (IsClient(client) && IsValidClient(client) && !IsFakeClient(client))
	{
		if(!g_bIsShown[client])
		{
			ShowLoadedMsg(client);
			g_bIsShown[client] = true;
		}
	}
	return Plugin_Continue;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | #5: Overrided functions
// ====================================================================================================
public void OnMapStart()
{
	char gamemode[32];
	GetConVarString(FindConVar("mp_gamemode"), gamemode,sizeof(gamemode));
	PrintToServer("[Shop] cvar_shop_on:%d | GameMode: %s", cvar_shop_on.IntValue, gamemode);
	g_bPointsOn = cvar_shop_on.BoolValue;
	if(g_bPointsOn)
	{
		bool bOffSurvival 		= StrEqual(gamemode,"survival", true) && !cvar_shop_survival_on.BoolValue;
		bool bOffCoop			= StrEqual(gamemode,"coop", true) && !cvar_shop_coop_on.BoolValue;
		bool bOffScavenge 		= StrEqual(gamemode,"scavenge", true) && !cvar_shop_scavenger_on.BoolValue;
		bool bOffRealism		= StrEqual(gamemode,"realism", true) && !cvar_shop_realism_on.BoolValue;
		bool bOffVersus 		= StrEqual(gamemode,"versus", true) && !cvar_shop_versus_on.BoolValue;
		bool bOffTeamscavenge	= StrEqual(gamemode,"teamscavenge", true) && !cvar_shop_team_survival_on.BoolValue;
		bool bOffTteamversus 	= StrEqual(gamemode,"teamversus", true) && !cvar_shop_team_versus_on.BoolValue;
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
}

public void OnClientPostAdminCheck(int client)
{
	// reset the points after connect
	char szSteamId64[32];
	if ( GetClientAuthId(client, AuthId_SteamID64, szSteamId64, sizeof(szSteamId64), true) && IsValidClient(client) && !IsFakeClient(client) && cvar_db_on.BoolValue)
	{
		g_iPoints[client] = LoadPoints(client);
		CreateTimer(1.0, ShowLoad, client, 0);
	}
}

public void OnClientDisconnect(int client)
{
	g_bIsShown[client] = false;
	if(IsValidClient(client)) g_iKilledInfectedCount[client] = 0;
	SaveToDB(client);
	ResetClient(client);
	for(int i =0; i<2; i++) g_iBuyItem[client][i] = 0;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | #6: Control points
// ====================================================================================================
bool AddPoints(int client, int points, bool willSave = false)
{
	if(IsValidClient(client) && !IsFakeClient(client) && points > 0)
	{
		g_iPoints[client] += points;
		if(willSave) SaveToDB(client);
		return true;
	}
	return false;

}

bool ReducePoints(int client, int points, bool willSave = false)
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
//					pan0s | #7: important functions
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
	if(!cvar_db_on.BoolValue) return;
	char playerName[64];
	GetClientName(client, playerName, 64);
	CPrintToChat(client,"%T%T", "SYSTEM", client, "SUCCEED_TO_LOAD", client, playerName, g_iPoints[client]);
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
	if(cvar_db_on.BoolValue) return;

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
	if(cvar_buy_notify_all_on.BoolValue)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			char name2[32];
			AddTimeTag(i, g_iBuyItem[client][0], item, name2);
			if(IsValidClient(i) && i != client)
				CPrintToChat(i, "%T%T", "SYSTEM", i, "NOTIFY_ALL", i, client, name2, price);
		}
	}
	if(cvar_invoice_type.IntValue ==1)
	{
		CPrintToChat(client,"============%T%T============", "SYSTEM", client, "INVOICE", client);
		DataPack hPack = new DataPack();
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
public bool Checkout(const int client, const char[] item, const int price, bool bPrint)
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
	return Plugin_Continue;
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
	delete hPack;
	return Plugin_Continue;
}

public Action HandleDelayRow3(Handle timer, int client)
{
	CPrintToChat(client,"%T", "INVOICE_THANKS", client);
	CreateTimer(0.2, HandleDelayRow4, client);
	return Plugin_Continue;
}

public Action HandleDelayRow4(Handle timer, int client)
{
	CPrintToChat(client,"%T", "INVOICE_END", client);
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
// gen command sm_xxxx #i %d
void ExternalCmd(int client, const char[] cmd, int arg)
{
	char args[12];
	Format(args, sizeof(args), "#%i %d", GetClientUserId(client), arg);
	CheatCommand(client, cmd, args);
}

void CheckHavingGunToUseItem(int client, const char[] item)
{
	Weapon w;
	w.client = client;
	if(!w.IsGun())
	{
		char itemName[32];
		Format(itemName, sizeof(itemName), "%T", item, client);
		CPrintToChat(client,"%T%T", "SYSTEM", client, "NO_GUN_TO_ACTIVE", client, itemName);
	}
}

// pan0s | Buy functions
bool BuyItem(int client, const char[] item, int price, int team = TEAM_SURVIVOR)
{
	if(!g_bPointsOn) return false;
	if(IsSurvivorDeadEx(client, item)) return false;

	if(team == TEAM_INFECTED && cvar_infected_buy_respawn_on.BoolValue && IsPlayerAlive(client) && !(StrEqual(item, "kill") || StrEqual(item, "health") || StrEqual(item, "mob") || StrEqual(item, "director_force_panic_event")))
	{
		CPrintToChat(client, "%T%T", "SYSTEM", client, "YOU_ARE_ALIVE", client);
		return false;
	}

	if (Checkout(client, item, price, true))
	{
		if(team == TEAM_INFECTED)
		{
			char spawnCmd[12];
			if(cvar_shop_infected_respawn.BoolValue) Format(spawnCmd, sizeof(spawnCmd), "z_spawn");
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
		else
		{
			if(StrEqual(item, "extinguisher"))
			{
				CheckHavingGunToUseItem(client, item);
				ExternalCmd(client, "sm_giveext", 1);
			}
			else if(IndexOf(item, 32, "airstrike", 9) != -1)
			{
				int target = 0;
				/* Create an Airstrike. Usage: 
				// sm_strikes <#userid|name> <type: 
					1=Aim position. 
					2=On position> 
					OR vector position <X> <Y> <Z> <angle>
				*/
				char crosshair[] = "crosshair";
				char position[] = "position";
				if(IndexOf(item, 32, crosshair, sizeof(crosshair)) != -1) target = 1;
				else if (IndexOf(item, 32, position, sizeof(position)) != -1) target = 2;

				ExternalCmd(client, "sm_strikes", target);
			}
			else if(StrEqual(item, "lethal_ammo_3"))
			{
				ExternalCmd(client, "sm_give_lethal_ammo", 3);
			}
			else CheatCommand(client, "give", item);
		}
		return true;
	}
	return false;
}

bool BuyMelee(int client, const char[] melee, int price)
{
	if(!g_bPointsOn) return false;
	if(IsSurvivorDeadEx(client, melee)) return false;

	bool isSucceed = false;
	if (Checkout(client, melee, price, false))
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
	if(!g_bPointsOn) return false;
	if(IsSurvivorDeadEx(client, component)) return false;

	int priWeapon = GetPlayerWeaponSlot(client, 0);
	if (priWeapon == -1)
	{
		char name[32];
		AddTimeTag(client, g_iBuyItem[client][0], component, name);
		CPrintToChat(client,"%T%T %T", "SYSTEM", client, "NO_PRIMARY_WEAPON", client, "FAILED_TO_BUY", client, name);
		return false;
	}

	if(Checkout(client, component, price, true))
	{
		CheatCommand(client, "upgrade_add", component);
		return true;
	}
	return false;
}

bool BuySF(int client, int idx, int price, bool isPermanent)
{
	if(!g_bPointsOn) return false;
	char item[32];
	g_listItems[SHOP_SF].GetString(idx, item, sizeof(item));

	if(((g_bClientSF[client][0][idx] || g_bClientSF[client][1][idx]) && !isPermanent )|| (g_bClientSF[client][1][idx] && isPermanent))
	{
		char name[32];
		AddTimeTag(client, g_iBuyItem[client][0], item, name);
		CPrintToChat(client,"%T%T", "SYSTEM", client, "IS_IN_YOUR_BAG", client, name);
		return false;
	}

	if (Checkout(client, item, price, true))
	{
 		ActivateSF(client, idx, isPermanent);
		if(isPermanent) SF_InsertToDB(client, idx, true); // Update SpecialFunctions
		return true;
	}
	return false;
}
////////////////////////////////////////////////////////////////////

// Tell the agent what item you want to buy and which shop, it will help you buy it.
void CallAgent(int client, int shopId = -1, int id = -1)
{
	if(!g_bPointsOn) return;
	if(id == -1) id = g_iBuyItem[client][1];
	if(shopId == -1) shopId = g_iBuyItem[client][0];
	if(shopId == SHOP_MAIN) return;

	g_iBuyItem[client][0] = shopId;
	g_iBuyItem[client][1] = id;
 	int cost = cvar_costs[shopId][id].IntValue;
	char item [32];
	g_listItems[shopId==SHOP_SF_TRIAL || shopId==SHOP_SF_PERMANENT? SHOP_SF : shopId].GetString(id, item, sizeof(item));

	if(!cvar_shops_on[shopId].BoolValue || (IsInfected(client) && shopId != SHOP_INFECTED))
	{
		CPrintToChat(client, "%T{GREEN}%T{ORANGE}%T", "SYSTEM", client, g_sShopNames[shopId], client, "DISABLED", client);
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

	// Check shop and specified item id
	if(shopId == SHOP_MEDICINES && id == 4)
	{
		if(BuyItem(client, item, cost))
		{
			//Remove buffer hp
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		}
	}
	else
	{
		switch(shopId)
		{
			case SHOP_INFECTED:
			{
				if(!IsInfected(client)) return;
				if(id == 8) //tank, fixed by ryxzxz
				{
					if (g_iNoOfTanks + 1 < cvar_tank_limit.IntValue + 1)
					{
						// Tank and Witch limit bug, reported by laurauwu.
						if(BuyItem(client, item, cost, TEAM_INFECTED)) g_iNoOfTanks++;
					}
					else
					{
						CPrintToChat(client,"%T%T", "SYSTEM", client, "UP_TO_LIMIT", client, item);
						return;
					}
				}
				else if(id == 9) // witch, fixed by ryxzxz
				{
					if (g_iNoOfWitches + 1 < cvar_witch_limit.IntValue + 1)
					{
						// Tank and Witch limit bug, reported by laurauwu.
						if(BuyItem(client, item, cost, TEAM_INFECTED)) g_iNoOfWitches++;
					}
					else
					{
						CPrintToChat(client,"%T%T", "SYSTEM", client, "UP_TO_LIMIT", client, item);
						return;
					}
				}
				else BuyItem(client, item, cost, TEAM_INFECTED);
			}

			case SHOP_MELEES: BuyMelee(client, item, cost);

			case SHOP_AMMOS: switch(id)
			{
				case 1, 4, 5, 6: // Ammo upgrade packs / refill ammo / lethal ammo
				{
					BuyItem(client, item, cost);
				}
				default :
				{
					UpgradeWeapon(client, item, cost);
				}
			}

			case SHOP_SF_TRIAL: BuySF(client, id, cost, false);
			case SHOP_SF_PERMANENT: BuySF(client, id, cost, true);
			default: BuyItem(client, item, cost);
		}
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
	if(isPermanent) g_bClientSF[client][1][idx] = true;
	SetSFOn(client, idx);
}

// pan0s | Check functions
bool IsSurvivorDeadEx(int client, const char[] item)
{
	if(IsSurvivorHumanDead(client))
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
	bool isSurvivorHumanAlive = IsSurvivorHumanAlive(client);
	bool isInfectedHumanAlive = IsInfectedHumanAlive(client);
	bool suicideSuccessful = false;
	
	if (isSurvivorHumanAlive || isInfectedHumanAlive)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsSurvivorHumanAlive(client))
			{
				CPrintToChat(i, "{BLUE}%N{DEFAULT}%T", client, "SUICIDE", i);
			}
			else if(IsInfectedHumanAlive(client))
			{
				CPrintToChat(i, "{RED}%N{DEFAULT}%T", client, "SUICIDE", i);
			}
			ForcePlayerSuicide(client);
			suicideSuccessful = true; // Mark that the suicide was successful
		}
	}
	if (suicideSuccessful) {
		return; // Exit the function if the suicide was successful
	}
	if (!isSurvivorHumanAlive || !isInfectedHumanAlive)
	{
		CPrintToChat(client, "%T", "YOU_ARE_DEAD", client);
	}
}

//  pan0s | check the fucnctionNo is one of ammo color
public bool IsAmmoColors(int idx)
{
	for(int i=GRAY_AMMO; i <= RED_AMMO; i++)
		if(StrEqual(g_sSF[i][0], g_sSF[idx][0])) return true;
	return false;
}

// pan0s | close other ammo color before turning on an ammo color.
public void TurnOffAllAmmoColors(int client)
{
	if(GetEanbledAmmoColorIndex(client) != -1)
	{
		// char ammo[255];
		for(int i=GRAY_AMMO; i <= RED_AMMO; i++)
		{
			int idx = GetFunctionIndex(g_sSF[i][0]);
			g_bClientSF[client][0][idx] = false;
		}
	}
}

public void SetWish(int client, int shopId, int item)
{
	g_iBuyItem[client][0] = shopId;
	g_iBuyItem[client][1] = g_listSellable[shopId].Get(item);
}

int GetHandlingFee(int client)
{
	float fhandling = cvar_transfer_handling_fee.FloatValue / 100.0 * g_iTransferPoints[client];
	int handling = RoundFloat(fhandling);
	return handling>0? handling: 1; // at least charge 1
}
// ====================================================================================================



// ====================================================================================================
//					pan0s | #8: Earning points hook functions
// ====================================================================================================
// ---------For special infected or survivor team--------------
//Kill special infected / survivors
public Action Event_PlayerDeath(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (IsSurvivor(attacker) && IsInfected(client))
	{
		int points = cvar_earn_special.IntValue;
		if(AddPoints(attacker, points))
			CPrintToChat(attacker, "%T%T%T%T", "SYSTEM", attacker, "KILLED_SPECIAL_INFECTED", attacker, "REWARD_POINTS", attacker, points, "ADVERTISEMENT", attacker);
		if (IsClient(client) && !IsFakeClient(client) && GetClientTeam(client) == 3) && !IsPlayerAlive(client))
			RoundResetClient(client)
	}
	else if(IsInfected(attacker) && IsSurvivor(client))
	{
		int points = cvar_iearn_survivor.IntValue;
		if(AddPoints(attacker, points))
			CPrintToChat(attacker, "%T%T%T%T", "SYSTEM", attacker, "KILLED_SURVIVOR", attacker, "REWARD_POINTS", attacker, points, "ADVERTISEMENT", attacker);
		if (IsClient(client) && !IsFakeClient(client) && GetClientTeam(client) == 2) && !IsPlayerAlive(client))
			RoundResetClient(client)
	}

	return Plugin_Continue;
}

// ---------For special infected team--------------
// Make survivor Incapacitated

public void PrintEarningMsg(int client, const char[] reason, int points)
{
	CPrintToChat(client, "%T%T%T%T", "SYSTEM", client, reason, client, "REWARD_POINTS", client, points, "ADVERTISEMENT", client);
}

public Action IncapacitatePoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsInfected(attacker) && IsSurvivor(client))
	{
		int points = cvar_iearn_incapacitate.IntValue;
		if(AddPoints(attacker, points))
			PrintEarningMsg(attacker, "INCAPACITATE_SURVIVOR", points);
	}
	return Plugin_Continue;
}
// smoke grabs survivor
public Action GrabPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int victim = GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfected(attacker) && IsSurvivor(victim))
	{
		int points = cvar_iearn_grab.IntValue;
		if(AddPoints(attacker, points))
			PrintEarningMsg(attacker, "PULLED_SURVIVOR", points);
	}
	return Plugin_Continue;
}
// Charge pounces survivor
public Action PouncePoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (IsInfected(attacker) && IsSurvivor(victim))
	{
		int points = cvar_iearn_pounce.IntValue;
		if(AddPoints(attacker, points))
			PrintEarningMsg(attacker, "POUNCED_SURVIVOR", points);
	}
	return Plugin_Continue;
}
// Boomers
public Action VomitPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsInfected(attacker))
	{
		int points = cvar_iearn_vomit.IntValue;
		if(AddPoints(attacker, points))
			PrintEarningMsg(attacker, "TAGGED_SURVIVOR", points);
	}
	return Plugin_Continue;
}

public Action Charge_Pummel_Points(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

    int attacker = GetClientOfUserId(event.GetInt("userid")); // charger
    int client = GetClientOfUserId(event.GetInt("victim"));
    if (IsInfected(attacker) && IsSurvivor(client))
    {
		int points = cvar_iearn_charge.IntValue;
		if(AddPoints(attacker, points))
			PrintEarningMsg(attacker, "CHARGED_SURVIVOR", points);
    }
	return Plugin_Continue;
}

public Action Charge_Collateral_Damage_Points(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

    int attacker = GetClientOfUserId(event.GetInt("userid")); // charger
    int client = GetClientOfUserId(event.GetInt("victim"));
    if (IsInfected(attacker) && IsSurvivor(client))
    {
		int points = cvar_iearn_charge_collateral.IntValue;
		if(AddPoints(attacker, points))
			PrintEarningMsg(attacker, "COLLATERAL_DAMAGE", points);
    }
	return Plugin_Continue;
}

public Action Jockey_Ride_Points(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

    int attacker = GetClientOfUserId(event.GetInt("userid")); // Jockey
    int client = GetClientOfUserId(event.GetInt("victim"));
    if (IsInfected(attacker) && IsSurvivor(client))
    {
		int points = cvar_iearn_jockey_ride.IntValue;
		if(AddPoints(attacker, points))
			PrintEarningMsg(attacker, "RODE_SURVIVOR", points);
    }
	return Plugin_Continue;
}

public Action HurtPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsInfected(attacker) && IsSurvivor(client))
	{
  		g_iHurtCount[attacker] += 1;
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == 4)  //is it a spitter?
		{
			if(g_iHurtCount[attacker] >= 8)
			{
				int points = cvar_iearn_hurt.IntValue;
				if(AddPoints(attacker, points))
					PrintEarningMsg(attacker, "BATH_DAMAGE", points);
				g_iHurtCount[attacker] -= 8;
			}
		}
		else  // Any SI but Spitter
		{
			if(g_iHurtCount[attacker] >= 3)
			{
				int points = cvar_iearn_hurt.IntValue;
				if(AddPoints(attacker, points))
					PrintEarningMsg(attacker, "MULTIPLE_DAMAGE", points);
				g_iHurtCount[attacker] -= 3;
			}
		}
	}
	return Plugin_Continue;
}

// ---------For survivor team--------------
public Action TankKill(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	//int attacker = GetClientOfUserId(event.GetInt("attacker"));
	// CPrintToChatAll("Tank kill: %N, %d, %d", attacker, attacker, GetClientTeam(attacker));
	// if (IsSurvivor(attacker))
	{
		int points = cvar_earn_tank_killed.IntValue;
		if( points > 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && !IsFakeClient(i))
				{
					AddPoints(i, points);
					CPrintToChat(i, "%T%T%T%T", "SYSTEM", i, "KILLED_TANK", i,"REWARD_POINTS", i, points, "ADVERTISEMENT", i);
				}
				g_bTankOnFire[i] = false;
			}
		}
	}
	// else for (int i = 1; i <= MaxClients; i++) g_bTankOnFire[i] = false;

	return Plugin_Continue;
}

public Action WitchPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int instakill = event.GetBool("oneshot");
	if(IsSurvivor(client))
	{
		int points = cvar_earn_witch.IntValue;
		if(AddPoints(client, points))
				PrintEarningMsg(client, "KILLED_WITCH", points);
		if (instakill)
		{
			points = cvar_earn_witch_in_one_shot.IntValue;
			if(AddPoints(client, points))
				PrintEarningMsg(client, "KILLED_WITCH_ONE_SHOT", points);
		}
	}
	return Plugin_Continue;
}

public Action TankBurnPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(client))
	{
		char victim[64];
		event.GetString("victimname", victim, sizeof(victim));
		if (StrEqual(victim, "Tank", false))
		{
			if(!g_bTankOnFire[client])
			{
				int points = cvar_earn_tank_burn.IntValue;
				if(AddPoints(client, points))
					PrintEarningMsg(client, "BURNED_TANK", points);
				g_bTankOnFire[client] = true;
			}
		}
	}
	return Plugin_Continue;
}

public Action HealPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	int target = GetClientOfUserId(event.GetInt("subject"));
	if (IsSurvivor(client) && client != target)
	{
		int points = cvar_earn_heal.IntValue;
		if(AddPoints(client, points))
			PrintEarningMsg(client, "HEALED_TEAMMATE", points);
	}
	return Plugin_Continue;
}

public Action KillPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("attacker"));
	// int headshot = event.GetBool("headshot");
	// int minigun = event.GetBool("minigun");
	if (IsSurvivor(client))
	{
		g_iKilledInfectedCount[client] += 1;
		if (g_iKilledInfectedCount[client] >= cvar_earn_infected_num.IntValue)
		{
			int points = cvar_earn_infected.IntValue;
			if(AddPoints(client, points))
				CPrintToChat(client, "%T%T%T%T","SYSTEM", client, "KILLED_INFECTED", client, cvar_earn_infected_num.IntValue, "REWARD_POINTS", client, cvar_earn_infected.IntValue, "ADVERTISEMENT", client);
			g_iKilledInfectedCount[client] -= cvar_earn_infected_num.IntValue;
		}
	}
	return Plugin_Continue;
}

public Action RevivePoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int target = GetClientOfUserId(event.GetInt("subject"));
	bool isLedgeHang = event.GetBool("ledge_hang");

	if (IsSurvivor(client) && client != target)
	{
		if(isLedgeHang)
		{
			int points = cvar_earn_revive_ledge_hang.IntValue;
			if(AddPoints(client, points))
				PrintEarningMsg(client, "REVIVED_TEAMMATE_LEDGE", points);
		}
		else
		{
			int points = cvar_earn_revive.IntValue;
			if(AddPoints(client, points))
				PrintEarningMsg(client, "REVIVED_TEAMMATE", points);
		}
	}
	return Plugin_Continue;
}
public Action AwardPoints(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int award = event.GetInt("award");
	if (IsSurvivor(client))
	{
		if(award == 67) //Protect someone
		{
			delete g_hTimerReward[client];
			g_hTimerReward[client] = CreateTimer(0.3, HandleReward, client);
		}
	}
	return Plugin_Continue;
}

public Action HandleReward(Handle timer, int client)
{
	int points = cvar_earn_protect.IntValue;
	if(AddPoints(client, points))
		PrintEarningMsg(client, "PROTECTED_TEAMMATE", points);
	
	g_hTimerReward[client] = null;
	return Plugin_Continue;
}

public Action Event_DefibrillatorUsed(Event event, char[] event_name, bool dontBroadcast)
{
	if(!g_bPointsOn) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	// int target = GetClientOfUserId(event.GetInt("subject"));

	int points = cvar_earn_defibrillate.IntValue;
	if(AddPoints(client, points))
		PrintEarningMsg(client, "DEFIBRILLATE_TEAMMATE", points);
	return Plugin_Continue;
}

public Action Event_Rescued(Event event, char[] event_name, bool dontBroadcast)
{
	int rescuer = GetClientOfUserId(event.GetInt("rescuer"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if(!g_bPointsOn || rescuer == victim) return Plugin_Continue;

	int points = cvar_earn_rescued.IntValue;
	if(AddPoints(rescuer, points))
		PrintEarningMsg(rescuer, "RESCUED", points);
	return Plugin_Continue;
}
// ====================================================================================================



// ====================================================================================================
//					pan0s | #9: Admin menu (ref: all4dead)
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
	menu.SetTitle("%T","MENU_TITLE_POINTS_LIST", client);
	for(int i = 0; i < sizeof(g_iAdminPointList); i++)
	{
		char option [64];
		char optionName [10];
		Format(option, sizeof(option), "%d",  g_iAdminPointList[i]);
		Format(optionName, sizeof(optionName),"option%d", i);
		menu.AddItem(optionName, option);
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

// Handles callbacks from a client using the director commands menu.
public int MenuPointValuesListHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			g_iAdminPoints[client] = g_iAdminPointList[itemNum];
			MenuPlayerList(client, false);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
				DisplayTopMenu(g_hTopMenu, client, TopMenuPosition_LastCategory);
		}
	}
	return 0;
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
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	GetPlayerList(client, menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

/// Handles callbacks from a client using the director commands menu.
public int MenuPlayerListHandler(Menu menu, MenuAction action, int client, int itempos)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
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
				CPrintToChat(client, "{ORANGE}[SHOP]{DEFAULT} Failed to do that for {BLUE}%N{DEFAULT}. \nReason: steamId doesn't match. (%s != %s)", selectedClient, selectedSteamId, steamId);
				MenuPlayerList(client, false);
				return 0;
			}

			char sAction[16];

			switch(g_iAdminAction[client])
			{
				case ADMIN_ADD_POINT:
				{
					AddPoints(selectedClient, g_iAdminPoints[client]);
					CPrintToChat(selectedClient,"%T%T (%T{GREEN}%d{DEFAULT})", "SYSTEM", client, "ADMIN_ADD_POINT", client, g_iAdminPoints[client], "CURRENT_POINTS", client, g_iPoints[selectedClient]);
					CPrintToChat(client, "{ORANGE}[SHOP]{DEFAULT} Success to reward {GREEN}%d{DEFAULT} points to {BLUE}%N {DEFAULT}(%T{GREEN}%d{DEFAULT}) ",g_iAdminPoints[client], selectedClient, "CURRENT_POINTS", client, g_iPoints[selectedClient]);
					Format(sAction, sizeof(sAction), "rewarded");

				}
				case ADMIN_CONFISCATE:
				{
					ReducePoints(selectedClient, g_iAdminPoints[client]);
					CPrintToChat(selectedClient,"%T%T (%T{GREEN}%d{DEFAULT})", "SYSTEM", client, "ADMIN_CONFISCATE_POINT", client, g_iAdminPoints[client], "CURRENT_POINTS", client, g_iPoints[selectedClient]);
					CPrintToChat(client, "{ORANGE}[SHOP]{DEFAULT} Success to confiscate {GREEN}%d{DEFAULT} points to {BLUE}%N {DEFAULT}(%T{GREEN}%d{DEFAULT}) ",g_iAdminPoints[client], selectedClient, "CURRENT_POINTS", client, g_iPoints[selectedClient]);
					Format(sAction, sizeof(sAction), "reduced");
				}
				case ADMIN_SET_POINT:
				{
					g_iPoints[selectedClient] = g_iAdminPoints[client];
					CPrintToChat(selectedClient,"%T%T (%T{GREEN}%d{DEFAULT})", "SYSTEM", client, "ADMIN_SET_POINT", client, g_iAdminPoints[client], "CURRENT_POINTS", client, g_iPoints[selectedClient]);
					CPrintToChat(client, "{ORANGE}[SHOP]{DEFAULT} Success to set {GREEN}%d{DEFAULT} points to {BLUE}%N {DEFAULT}(%T{GREEN}%d{DEFAULT}) ",g_iAdminPoints[client], selectedClient, "CURRENT_POINTS", client, g_iPoints[selectedClient]);
					Format(sAction, sizeof(sAction), "set");
				}
			}
			// Log the admin action.
			LogAction(client, selectedClient, "[Admin]: \"%L\" %s \"%d\" points for \"%L\" (current: \"%d\")", client, sAction, g_iAdminPoints[client], selectedClient, g_iPoints[selectedClient]);

			MenuPlayerList(client, false);
		}
		case MenuAction_Cancel:
		{
			if (itempos == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
				g_hTopMenu.Display(client, TopMenuPosition_LastCategory);
		}
	}
	return 0;
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | #10: Menu setting functions
// ====================================================================================================
void SetMenuContent(int client, Menu menu, char[][] names, int size, bool isExitable = false)
{
	for(int i = 0; i < size; i++)
	{
		char option [64];
		char optionName [10];
		Format(option, sizeof(option), "%T", names[i], client);
		Format(optionName, sizeof(optionName),"option%d", i);
		menu.AddItem(optionName, option);
	}
	if(isExitable) menu.ExitBackButton = true;
	menu.ExitButton = true;
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

			menu.AddItem(optionName, clientName);
		}
	}
}

public void ShowShopMenu(int client, Menu menu, int shopId)
{
	menu.SetTitle("%T\n%T%d", g_sShopNames[shopId], client, "CURRENT_POINTS", client, g_iPoints[client]);

	switch (shopId)
	{
		case SHOP_MAIN:
			SetMenuContent(client, menu, g_sMainShop, sizeof(g_sMainShop));
		case SHOP_GUNS:
			SetMenuContent(client, menu, g_sGunsShop, sizeof(g_sGunsShop), true);
		case SHOP_SF:
			SetMenuContent(client, menu, g_sSFShop, sizeof(g_sSFShop), true);
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
					menu.AddItem(optionName, option);
					menu.ExitBackButton= true;
					menu.ExitButton = true;
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
			menu.SetTitle("%T%d\n%T", "CURRENT_POINTS", client, g_iPoints[client], "MENU_TITLE_POINTS_LIST", client );
			for(int i = 0; i < sizeof(g_iTransferPointList); i++)
			{
				char option [64];
				char optionName [10];
				Format(option, sizeof(option), "%d",  g_iTransferPointList[i]);
				Format(optionName, sizeof(optionName),"option%d", i);
				menu.AddItem(optionName, option);
				menu.ExitBackButton= true;
				menu.ExitButton = true;
			}
		}
		default:
		{
			int index = shopId;
			if(shopId == SHOP_SF_TRIAL || shopId == SHOP_SF_PERMANENT) index = SHOP_SF;
			g_listSellable[index].Clear();
			for(int i = 0; i< g_listItems[index].Length; i++)
			{
				if(cvar_costs[shopId][i].IntValue >= 0)
				{
					char option[64];
					char optionName[10];
					char item[32];
					char name[32];
					g_listItems[index].GetString(i, item, 32);
					AddTimeTag(client, shopId, item, name);

					Format(option, sizeof(option),"%s", name);
					Format(optionName, sizeof(optionName),"option%d", i);
					menu.AddItem(optionName, option);
					g_listSellable[shopId].Push(i);
				}
			}
			menu.ExitBackButton= true;
			menu.ExitButton = true;
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
}
// ====================================================================================================


// ====================================================================================================
//					pan0s | #11: Handle commands functions
// ====================================================================================================
public bool IsShopOff(int client, int shopId)
{
	// check case.
	bool on = false;
	switch(shopId)
	{
		case SHOP_SF, SHOP_SF_TRIAL, SHOP_SF_BAG: on = cvar_sf_on.BoolValue;
		case SHOP_SF_PERMANENT: on = cvar_sf_on.BoolValue && cvar_db_on.BoolValue;
		default: on = cvar_shops_on[shopId].BoolValue;
	}

	if(!on) CPrintToChat(client, "%T{GREEN}%T{ORANGE}%T", "SYSTEM", client, g_sShopNames[shopId], client, "DISABLED", client);

	return !on;
}

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

public bool FindBuyInfoByCmd(int shopId, const char[] cmd, const char[][][] item, int size, int[] buffer)
{
	for(int i =0; i<size; i++)
		if(StrEqual(item[i][0], cmd, false))
		{
			if(!cvar_shops_on[shopId].BoolValue) return false;
			buffer[0] = shopId; // shop id
			buffer[1] = i; // item id
			return true;
		}
	return false;
}

public bool GetBuyItemInfoByCmd(const char[] cmd, int[] buffer, bool isInfeected)
{
	if(isInfeected)
	{
		if(FindBuyInfoByCmd(SHOP_INFECTED, cmd, g_sInfectedItems, sizeof(g_sInfectedItems), buffer)) return true;
	}
	else
	{
		if(FindBuyInfoByCmd(SHOP_MELEES, cmd, g_sShopMelees, sizeof(g_sShopMelees), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_SMGS, cmd, g_sSmgs, sizeof(g_sSmgs), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_RIFLES, cmd, g_sRifles, sizeof(g_sRifles), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_SNIPERS, cmd, g_sSnipers, sizeof(g_sSnipers), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_SHOTGUNS, cmd, g_sShotguns, sizeof(g_sShotguns), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_OTHERS, cmd, g_sOthers, sizeof(g_sOthers), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_THROWABLES, cmd, g_sThrowables, sizeof(g_sThrowables), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_AMMOS, cmd, g_sAmmos, sizeof(g_sAmmos), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_MEDICINES, cmd, g_sMedicines, sizeof(g_sMedicines), buffer)) return true;
		else if(FindBuyInfoByCmd(SHOP_AIRSTRIKE, cmd, g_sAirstrike, sizeof(g_sAirstrike), buffer)) return true;
	}
	return false;
}

public Action HandleCmdOpenShop(int client, int args)
{
	if(!g_bPointsOn) return Plugin_Continue;

	Menu menu = null;

	if(IsInfected(client))
	{
		menu = new Menu(HandleMenuInfected);
		ShowShopMenu(client, menu, SHOP_INFECTED);
		return Plugin_Handled;
	}
	else if(IsSurvivor(client))
	{
		char cmd[32];
		GetCmdArgString(cmd, sizeof(cmd));
		int shopId = args == 0? 1: StringToInt(cmd);

		if(shopId != 0)
		{
			shopId -= 1;

			if(IsShopOff(client, shopId)) return Plugin_Continue;

			switch(shopId)
			{
				case SHOP_MAIN:
					menu = new Menu(HandleMenuBuy);
				case SHOP_GUNS:
					menu = new Menu(HandleMenuGuns, MENU_ACTIONS_ALL);
				case SHOP_SMGS:
					menu = new Menu(HandleMenuSmgs);
				case SHOP_RIFLES:
					menu = new Menu(HandleMenuRifles);
				case SHOP_SNIPERS:
					menu = new Menu(HandleMenuSnipers);
				case SHOP_SHOTGUNS:
					menu = new Menu(HandleMenuShotguns);
				case SHOP_OTHERS:
					menu = new Menu(HandleMenuOthers);
				case SHOP_MELEES:
					menu = new Menu(HandleMenuMelees);
				case SHOP_THROWABLES:
					menu = new Menu(HandleMenuThrowables);
				case SHOP_AMMOS:
					menu = new Menu(HandleMenuAmmos);
				case SHOP_MEDICINES:
					menu = new Menu(HandleMenuMedicines);
				case SHOP_SF:
					menu = new Menu(HandleMenuSF);
				case SHOP_SF_TRIAL:
					menu = new Menu(HandleMenuSFTrial);
				case SHOP_SF_PERMANENT:
					menu = new Menu(HandleMenuSFPermanent);
				case SHOP_SF_BAG:
					menu = new Menu(HandleMenuBag);
				case SHOP_TRANSFER:
					menu = new Menu(HandleMenuTransfer);
				case SHOP_AIRSTRIKE:
					menu = new Menu(HandleMenuAirstrike);
				default:
				{
					CPrintToChat(client, "%T shop does not exist.", "SYSTEM", client);
					return Plugin_Continue;
				}
			}
			ShowShopMenu(client, menu, shopId);
			return Plugin_Handled;
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
	return Plugin_Continue;
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
	return Plugin_Continue;
}

public Action HandleCmdBuyConfirm(int client, int args)
{
	if(!g_bPointsOn) return Plugin_Continue;
	Menu menu = new Menu(HandleMenuBuyConfirm);

	int shopId = g_iBuyItem[client][0];
	int id = g_iBuyItem[client][1];

	int cost = cvar_costs[shopId][id].IntValue;
	int remaining = g_iPoints[client]-cost;

	char item[32];
	char name[32];
	g_listItems[shopId==SHOP_SF_TRIAL || shopId==SHOP_SF_PERMANENT? SHOP_SF : shopId].GetString(id, item, sizeof(item));
	AddTimeTag(client, g_iBuyItem[client][0], item, name);

	menu.SetTitle("%T", "MENU_BUY_CONFIRM", client, name, cost, g_iPoints[client], remaining);

	for(int i=0; i< sizeof(g_sBuyConfirmOptions); i++)
	{
		char option [64];
		char optionName [10];
		Format(option, sizeof(option), "%T", g_sBuyConfirmOptions[i], client);
		Format(optionName, sizeof(optionName),"option%d", i);
		menu.AddItem(optionName, option);
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

public Action HandleCmdPointsHelp(int client, int args)
{
	if(!g_bPointsOn) return Plugin_Continue;
	CPrintToChat(client, "%T%T", "SYSTEM", client, "HELP", client);
	return Plugin_Continue;
}

public Action HandleCmdShowPoints(int client, int args)
{
	if(!g_bPointsOn) return Plugin_Continue;
	CPrintToChat(client, "%T%T {GREEN}%d{DEFAULT}.", "SYSTEM", client, "CURRENT_POINTS", client ,g_iPoints[client]);
	FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
	return Plugin_Continue;
}

public Action HandleCmdRefill(int client, int args)
{
	//Give player ammo
	CheatCommand(client, "give", "ammo");
	return Plugin_Continue;
}

public Action HandleCmdHeal(int client, int args)
{
	//Give player health
	CheatCommand(client, "give", "health");
	return Plugin_Continue;
}

public Action HandleCmdManOfSteel(int client, int args)
{
	if (g_iMOSOn[client] <= 0)
	{
		g_iMOSOn[client] = 1;
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	else
	{
		g_iMOSOn[client] = 0;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}

	return Plugin_Continue;
}

// Repact buy
public Action HandleCmdRepeatBuy(int client, int args)
{
	CallAgent(client);
	return Plugin_Continue;
}

public Action HandleCmdSuicide(int client, int args)
{
	if(!g_bPointsOn || !cvar_suicide_cmd_on.BoolValue) return Plugin_Continue;

	if(IsInfected(client))
	{
		if(cvar_costs[SHOP_INFECTED][0].IntValue < 0)
		{
			CPrintToChat(client,"%T%T", "SYSTEM", client, "NOT_ALLOW_SUICIDE", client);
			return Plugin_Continue;
		}
		HandleCmdBuyConfirm(client, 0);
	}
	else
	{	// Suicide without cost for survivors.
		Menu menu = CreateMenu(HandleMenuSuicide);
		menu.SetTitle("%T", "MENU_SUICIDE" ,client);
		SetMenuContent(client, menu, g_sSuicideOptions, sizeof(g_sSuicideOptions));
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////////////
//Added airstrike and extinguisher(Thanks VYRNACH_GAMING for adding this)
public Action HandleCmdAirstrike(int client, int args)
{
	CallAgent(client, SHOP_AIRSTRIKE, 0);
	return Plugin_Continue;
}

public Action HandleCmdExtinguisher(int client, int args)
{
	CallAgent(client, SHOP_OTHERS, 3);
	return Plugin_Continue;
}
/////////////////////////////////////////////////////////////////////////////

// ====================================================================================================


// ====================================================================================================
//					pan0s | #12: Menu menu selected functions.
// ====================================================================================================
public int MainShopId2CmdId(int id)
{
	for(int i = 0; i<sizeof(g_sShopNames); i++)
	{
		if(StrEqual(g_sShopNames[i], g_sMainShop[id])) return i;
	}
	return -1;
}

public int GunShopId2CmdId(int id)
{
	for(int i = 0; i<sizeof(g_sShopNames); i++)
	{
		if(StrEqual(g_sShopNames[i], g_sGunsShop[id])) return i;
	}
	return -1;
}

public int HandleMenuBuy(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			g_iBuyItem[client][0] = SHOP_MAIN;
			if(0 <= itemNum <= 7)
			{
				int cmdId = MainShopId2CmdId(itemNum);
				if(cmdId == -1) 
				{
					CPrintToChat(client, "%T{GREEN}%T{ORANGE}%T", "SYSTEM", client, g_sMainShop[itemNum], client, "DISABLED", client);
					return 0;
				}
				FakeClientCommand(client, g_sShopCmds[cmdId]);
			}
		}
	}
	return 0;
}

public int HandleMenuInfected(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_INFECTED, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuGuns(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			g_iBuyItem[client][0] = SHOP_GUNS;
			if(0 <= itemNum <= 4)
			{
				int cmdId = GunShopId2CmdId(itemNum);
				if(cmdId == -1) 
				{
					CPrintToChat(client, "%T{GREEN}%T{ORANGE}%T", "SYSTEM", client, g_sMainShop[itemNum], client, "DISABLED", client);
					return 0;
				}
				FakeClientCommand(client, g_sShopCmds[cmdId]);
			}
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuSmgs(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SMGS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;
}

public int HandleMenuRifles(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_RIFLES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;

}

public int HandleMenuSnipers(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SNIPERS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;
}

public int HandleMenuShotguns(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SHOTGUNS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_GUNS]);
			}
		}
	}
	return 0;
}

public int HandleMenuOthers(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_OTHERS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuMelees(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_MELEES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuThrowables(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_THROWABLES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuAmmos(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_AMMOS, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}

	}
	return 0;
}

public int HandleMenuMedicines(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_MEDICINES, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuSFTrial(Menu menu, MenuAction action, int client, int itemNum)
{

	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SF_TRIAL, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_SF]);
			}
		}
	}
	return 0;
}

public int HandleMenuSFPermanent(Menu menu, MenuAction action, int client, int itemNum)
{

	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_SF_PERMANENT, itemNum);
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_SF]);
			}
		}
	}
	return 0;
}

// Points trasnfer--------------------------------------------------------------------------->
public int HandleMenuTransfer(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			g_iTransferPoints[client] = g_iTransferPointList[itemNum];
			ShowMenuTransferPlayerList(client);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public Action ShowMenuTransferPlayerList(int client)
{
	Menu menu = CreateMenu(HandleTransferPlayerList);
	char title[64];
	Format(title, sizeof(title), "%T%d\n%T", "CURRENT_POINTS", client, g_iPoints[client], "MENU_TITLE_TRANSFER_POINT", client, g_iTransferPoints[client]);
	menu.SetTitle(title);

	GetPlayerList(client, menu, false);
	menu.ExitBackButton = true;
	menu.ExitButton = true;

	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int HandleTransferPlayerList(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			g_iTransferTarget[client] = itemNum;
			ShowMenuTransferConfirm(client, itemNum);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_TRANSFER]);
			}
		}
	}
	return 0;
}

public void DrawClose(Panel panel, int client)
{
	char line[32];
	panel.CurrentKey = 10;
	Format(line, sizeof(line), "%T", "CLOSE", client);
	panel.DrawItem(line);
}

public Action ShowMenuTransferConfirm(int client, int args)
{
	// Panel panel = new Panel();
	// panel.Send(p.id, HandlePanelTop10Selected, MENU_TIME_FOREVER);


	Menu menu = new Menu(HandleTransferConfirm);
	char title[128];
	int handling = GetHandlingFee(client);
	int selectedClient = g_listIHuman.Get(args);
	int after = g_iPoints[client] - handling - g_iTransferPoints[client];
	Format(title,sizeof(title),"%T%N\n%T%d\n%T%d", "MENU_TITLE_TRANSFER_POINT", client, g_iTransferPoints[client], selectedClient, "HANDLING_FEE", client, handling, "AFTER_TRANSFERRED_BALANCE", client, after);
	menu.SetTitle(title);
	menu.ExitButton = false;
	SetMenuContent(client, menu, g_sYesNo, sizeof(g_sYesNo));
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int HandleTransferConfirm(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
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
					ShowMenuTransferPlayerList(client);
					return 0;
				}

				int handling = GetHandlingFee(client);
				if(handling + g_iTransferPoints[client] > g_iPoints[client])
				{
					CPrintToChat(client, "%T%T","SYSTEM", client, "FAILED_TO_TRANSFER", client, client, g_iTransferPoints[client], handling, g_iPoints[client]);
					return 0;
				}

				AddPoints(selectedClient, g_iTransferPoints[client]);
				ReducePoints(client, handling + g_iTransferPoints[client], false);

				if(cvar_transfer_notify_all_on.BoolValue)
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
				FakeClientCommand(client, g_sShopCmds[SHOP_TRANSFER]);
			}
		}
	}
	return 0;
}
// <--------------------------------------------------------------------------- Points trasnfer
public int HandleMenuBuyConfirm(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			if(itemNum == 0) CallAgent(client);
			else
			{
				// return to last visiting shopId.
				int shopId = g_iBuyItem[client][0];
				FakeClientCommand(client, g_sShopCmds[shopId]);
			}
		}
	}
	return 0;
}

public int HandleMenuSuicide(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			if(itemNum == 0 && IsSurvivor(client))
			{
				KillClient(client);
			}
		}
	}
	return 0;
}

// Special functions shop
public int HandleMenuSF(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
      		switch (itemNum)
			{
				case 0: // Trial shop
				{
					FakeClientCommand(client, g_sShopCmds[SHOP_SF_TRIAL]);
				}
				case 1: // Permanent shop
				{
					FakeClientCommand(client, g_sShopCmds[SHOP_SF_PERMANENT]);
				}
				case 2: // Bag
				{
					FakeClientCommand(client, g_sShopCmds[SHOP_SF_BAG]);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

void SetSFOn(int client, int sfId, bool bOn = true)
{
	g_bClientSF[client][0][sfId] = bOn;
	if(bOn)
	{
		switch(sfId)
		{
			case AUTO_BHOP: CPrintToChat(client, "%T%T", "SYSTEM", client, "AUTO_BHOP_TUT", client);
		}
	}
}

public int HandleMenuBag(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			int idx = 0;
			for(int i=0; i< SF_SIZE; i++)
			{
				if(g_bClientSF[client][1][i])
				{
					if(idx++ == itemNum)
					{
						if(itemNum == AUTO_BHOP && !g_bClientSF[client][0][AUTO_BHOP] )
						{
							bool tempValue = !g_bClientSF[client][0][i];
							int id = AUTO_BHOP;
							SetSFOn(client, id, tempValue);
						}
						else
						{
							bool tempValue = !g_bClientSF[client][0][i];
							if(tempValue && i>= GRAY_AMMO && i<= RED_AMMO)
							{
								// turn off all colorful ammo
								TurnOffAllAmmoColors(client);
							}
							SetSFOn(client, i, tempValue);
						}
						FakeClientCommand(client, g_sShopCmds[SHOP_SF_BAG]);
						return 0;
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_SF]);
			}
		}
	}
	return 0;
}

public int HandleMenuInfectedItems(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			HandleCmdBuyConfirm(client, 0);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
			{
				FakeClientCommand(client, g_sShopCmds[SHOP_MAIN]);
			}
		}
	}
	return 0;
}

public int HandleMenuAirstrike(Handle menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			SetWish(client, SHOP_AIRSTRIKE, itemNum);
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
//					pan0s | #13: Speical functions (Copy from other plugin)
// ====================================================================================================
// Speical functions
public void SetSFOffWhenSFOn(int client, int sfId[2], bool bSave)
{
	char names[2][32];
	Format(names[0], 32, "%T", g_sSF[sfId[0]][0], client);
	Format(names[1], 32, "%T", g_sSF[sfId[1]][0], client);
	CPrintToChat(client, "%T%T", "SYSTEM", client, "WHEN_SF_IS_ON", client, names[0],names[1]);
	
	SetSFOn(client, sfId[0], true);
	SetSFOn(client, sfId[1], false);
	if(bSave) SF_UpdateToDB(client, sfId[0], true, "", 0);	
}

public bool IsSFOn (int client, int idx)
{
	if(!g_bPointsOn) return false;

	bool isOn = cvar_costs[SHOP_SF_TRIAL][idx].IntValue >= 0 && cvar_costs[SHOP_SF_PERMANENT][idx].IntValue >= 0;
	return g_bClientSF[client][0][idx] && cvar_sf_on.BoolValue && isOn;
}


int GetFunctionIndex(const char[] functionNo)
{
	for(int i=0; i<sizeof(g_sSF); i++)
		if(StrEqual(functionNo, g_sSF[i][0]))
			return i;
	return -1;
}

// |------------------------------ Laser tag ------------------------------|
public int GetEanbledAmmoColorIndex(int client)
{
	for(int i=GRAY_AMMO; i <= RED_AMMO; i++)
	{
		int idx = GetFunctionIndex(g_sSF[i][0]);
		if(g_bClientSF[client][0][idx]) return idx;
	}
	return -1;
}

// ====================================================================================================
//					pan0s | #14: Native registion
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool isLate, char[] error, int err_max)
{
	char game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	LoadTranslations("l4d2_shop.phrases");
	LoadTranslations("l4d2_weapons.phrases");
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("%T", "Game Check Fail", LANG_SERVER);
	}
	// Native function
	CreateNative("Shop_GetVersion", Shop_GetVersion);
	CreateNative("Shop_GetPoints", Shop_GetPoints);
	CreateNative("Shop_BuyItem", Shop_BuyItem);
	CreateNative("Shop_BuyMelee", Shop_BuyMelee);
	CreateNative("Shop_UpgradeWeapon", Shop_UpgradeWeapon);
	CreateNative("Shop_BuySF", Shop_BuySF);
	CreateNative("Shop_IsSFOn", Shop_IsSFOn);
	CreateNative("Shop_Checkout", Shop_Checkout);
	CreateNative("Shop_GetEanbledAmmoColorIndex", Shop_GetEanbledAmmoColorIndex);
	CreateNative("Shop_GetClientSFOn", Shop_GetClientSFOn);
	CreateNative("Shop_GetFunctionIndex", Shop_GetFunctionIndex);
	CreateNative("Shop_IsShopOff", Shop_IsShopOff);
	CreateNative("Shop_CallAgent", Shop_CallAgent);
	CreateNative("Shop_SetSFOn", Shop_SetSFOn);
	CreateNative("Shop_SetSFOffWhenSFOn", Shop_SetSFOffWhenSFOn);
	CreateNative("Shop_AddPoints", Shop_AddPoints);
	CreateNative("Shop_ReducePoints", Shop_ReducePoints);
	CreateNative("Shop_SetPoints", Shop_SetPoints);

	g_hFowards[0] = CreateGlobalForward("OnShopLoaded", ET_Ignore);
	g_hFowards[1] = CreateGlobalForward("OnShopUnloaded", ET_Ignore);
	RegPluginLibrary("l4d2_shop");
	// g_bIsLate = isLate;
	return APLRes_Success;
}

// ====================================================================================================
//					pan0s | #15: Library functions override
// ====================================================================================================
public any Shop_GetVersion(Handle plugin, int numParams)
{
	SetNativeString(1, PLUGIN_VERSION, 10, false);
	return 0;
}

public any Shop_GetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_iPoints[client];
}

public any Shop_BuyItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char buffer[32];
	GetNativeString(2, buffer, 32);
	int price = GetNativeCell(3);
	int team = GetNativeCell(4);

	return BuyItem(client, buffer, price, team);
}

public any Shop_BuyMelee(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char buffer[32];
	GetNativeString(2, buffer, 32);
	int price = GetNativeCell(3);

	return BuyMelee(client, buffer, price);
}

public any Shop_UpgradeWeapon(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char buffer[32];
	GetNativeString(2, buffer, 32);
	int price = GetNativeCell(3);

	return UpgradeWeapon(client, buffer, price);
}

public any Shop_BuySF(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int price = GetNativeCell(2);
	int id = GetNativeCell(3);
	bool isPermanent = GetNativeCell(4);

	return BuySF(client, id, price, isPermanent);
}

public any Shop_IsSFOn(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int idx = GetNativeCell(2);

	return IsSFOn(client, idx);
}

public any Shop_Checkout(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char item[32];
	GetNativeString(2, item, 32);
	int price = GetNativeCell(3);
	bool bPrint = GetNativeCell(4);
	return Checkout(client, item, price, bPrint);
}

public any Shop_GetEanbledAmmoColorIndex(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return GetEanbledAmmoColorIndex(client);
}

public any Shop_GetClientSFOn(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int index = GetNativeCell(2);
	int isPermanent = GetNativeCell(3);
	return g_bClientSF[client][isPermanent][index];
}

public any Shop_GetFunctionIndex(Handle plugin, int numParams)
{
	char functionNo[32];
	GetNativeString(1, functionNo, 32);
	return GetFunctionIndex(functionNo);
}

public any Shop_IsShopOff(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int shopId = GetNativeCell(2);
	return IsShopOff(client, shopId);
}

public any Shop_CallAgent(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int shopId = GetNativeCell(2);
	int itemId = GetNativeCell(3);
	CallAgent(client, shopId, itemId);
	return 0;
}

public any Shop_SetSFOn(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sfId = GetNativeCell(2);
	bool bOn = view_as<bool>(GetNativeCell(3));
	g_bClientSF[client][0][sfId] = bOn;
	return 0;
}

public any Shop_SetSFOffWhenSFOn(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int ids[2];
	SetNativeArray(2, ids, 2);
	bool bSave = view_as<bool>(GetNativeCell(3));
	SetSFOffWhenSFOn(client, ids, bSave);
	return 0;
}

public any Shop_AddPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int points= GetNativeCell(2);
	bool bSave = view_as<bool>(GetNativeCell(3));
	AddPoints(client, points, bSave);
	return 0;
}

public any Shop_ReducePoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int points= GetNativeCell(2);
	bool bSave = view_as<bool>(GetNativeCell(3));
	ReducePoints(client, points, bSave);
	return 0;
}

public any Shop_SetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int points= GetNativeCell(2);
	bool bSave = view_as<bool>(GetNativeCell(3));
	g_iPoints[client] = 0;
	AddPoints(client, points, bSave);
	return 0;
}

public void OnAllPluginsLoaded()
{
	//forward
	Call_StartForward(g_hFowards[0]);
	Call_Finish();
}

public void OnPluginEnd()
{
	Action result;
	Call_StartForward(g_hFowards[1]);
	Call_Finish(view_as<int>(result));
}