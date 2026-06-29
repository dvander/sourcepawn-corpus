/*
 * MyJailShop Plugin.
 * by: shanapu
 * https://github.com/shanapu/MyJailShop
 * Based on: https://forums.alliedmods.net/showthread.php?t=247917
 * Credits to original author: Dkmuniz
 * Include code by bacardi https:// forums.alliedmods.net/showthread.php?t=269846
 * 
 * Copyright (C) 2016-2017 Thomas Schmidt (shanapu)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */


/******************************************************************************
                   STARTUP
******************************************************************************/


// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <colors>
#include <autoexecconfig>
#include <myjailshop>
#include <mystocks>

// Optional Plugins
#undef REQUIRE_PLUGIN
#include <smartjaildoors>
#include <myjailbreak>
#include <CustomPlayerSkins>
#include <myjbwarden>
#include <myicons>
#define REQUIRE_PLUGIN


// Compiler Options
#pragma semicolon 1
#pragma newdecls required


// Defines
#define VERSION "1.5.0-<COMMIT>"
#define URL "https://github.com/shanapu/MyJailShop"


// Console Variables
// Shop Settings
ConVar gc_bEnable;
ConVar gc_bCreditSystem;
ConVar gc_iCreditsMax;
ConVar gc_iCreditsKillCT;
ConVar gc_iCreditsKillT;
ConVar gc_bCreditsWinAlive;
ConVar gc_iCreditsWinCT;
ConVar gc_iCreditsWinT;
ConVar gc_iCreditsVIPWinCT;
ConVar gc_iCreditsVIPWinT;
ConVar gc_iCreditsLR;
ConVar gc_iCreditsVIPKillCT;
ConVar gc_iCreditsVIPKillT;
ConVar gc_iCreditsVIPLR;
ConVar gc_bCreditsSave;
ConVar gc_bOnlyT;
ConVar gc_bWelcome;
ConVar gc_bMySQL;
ConVar gc_bCreditsWarmup;
ConVar gc_iMinPlayersToGetCredits;
ConVar gc_fCreditsTimeInterval;
ConVar gc_iCreditsTime;
ConVar gc_iCreditsVIPPerTime;
ConVar gc_fBuyTime;
ConVar gc_bBuyTimeCells;
ConVar gc_bEventdays;
ConVar gc_bNotification;
ConVar gc_bRemoveWeapon;
ConVar gc_bClose;
ConVar gc_bTag;
ConVar gc_bLogging;
ConVar gc_bRemoveOnLR;
ConVar gc_bBuyOnLR;
ConVar gc_fSale;

// Shop Items
ConVar gc_iFroggyJumpOnlyTeam;
ConVar gc_iWallhackOnlyTeam;
ConVar gc_iGravOnlyTeam;
ConVar gc_iBhopOnlyTeam;
ConVar gc_iReviveOnlyTeam;
ConVar gc_iHealOnlyTeam;
ConVar gc_iNoDamageOnlyTeam;
ConVar gc_iHealthExtraOnlyTeam;
ConVar gc_iInvisible;
ConVar gc_fInvisibleTime;
ConVar gc_iAWP;
ConVar gc_iNoDamage;
ConVar gc_fNoDamageTime;
ConVar gc_iOpenCells;
ConVar gc_iVampire;
ConVar gc_fVampireSpeed;
ConVar gc_fVampireDamageMultiplier;
ConVar gc_iHealth;
ConVar gc_iHealthExtra;
ConVar gc_iDeagle;
ConVar gc_iKnife;
ConVar gc_iThrowKnifeCount;
ConVar gc_iHeal;
ConVar gc_iMolotov;
ConVar gc_iFakeModel;
ConVar gc_sModelPathFakeGuard;
ConVar gc_iPoisonSmoke;
ConVar gc_iBird;
ConVar gc_iBirdMode;
ConVar gc_iTeleportSmoke;
ConVar gc_iRevive;
ConVar gc_iFireHE;
ConVar gc_iBhop;
ConVar gc_iGravity;
ConVar gc_fGravValue;
ConVar gc_iTaser;
ConVar gc_iNoClip;
ConVar gc_bNoClipKill;
ConVar gc_fNoClipTime;
ConVar gc_iThrowKnife;
ConVar gc_iWallhack;
ConVar gc_fWallhackTime;
ConVar gc_iFroggyJump;
ConVar gc_iPaperClip;
ConVar gc_iPaperClipAmount;
ConVar gc_iRandomTP;

ConVar gc_sInvisibleFlag;
ConVar gc_sAWPFlag;
ConVar gc_sNoDamageFlag;
ConVar gc_sOpenCellsFlag;
ConVar gc_sVampireFlag;
ConVar gc_sHealthFlag;
ConVar gc_sDeagleFlag;
ConVar gc_sKnifeFlag;
ConVar gc_sHealFlag;
ConVar gc_sMolotovFlag;
ConVar gc_sFakeModelFlag;
ConVar gc_sPoisonSmokeFlag;
ConVar gc_sBirdFlag;
ConVar gc_sTeleportSmokeFlag;
ConVar gc_sReviveFlag;
ConVar gc_sFireHEFlag;
ConVar gc_sBhopFlag;
ConVar gc_sGravityFlag;
ConVar gc_sTaserFlag;
ConVar gc_sNoClipFlag;
ConVar gc_sThrowKnifeFlag;
ConVar gc_sWallhackFlag;
ConVar gc_sFroggyJumpFlag;
ConVar gc_sPaperClipFlag;
ConVar gc_sRandomTPFlag;

// Custom Commands
ConVar gc_sCustomCommandShop;
ConVar gc_sCustomCommandGift;
ConVar gc_sCustomCommandRevive;
ConVar gc_sCustomCommandCredits;
ConVar gc_sCustomCommandMassCredits;

// Extern Plugins
ConVar g_bHandcuff;


// Booleans
bool g_bInvisible[MAXPLAYERS+1] = false;
bool g_bFly[MAXPLAYERS+1] = false;
bool g_bFakeGuard[MAXPLAYERS+1] = false;
bool g_bNoDamage[MAXPLAYERS+1] = false;
bool g_bPoison[MAXPLAYERS+1] = false;
bool g_bVampire[MAXPLAYERS+1] = false;
bool g_bSuperKnife[MAXPLAYERS+1] = false;
bool g_bTeleportSmoke[MAXPLAYERS+1] = false;
bool g_bFireHE[MAXPLAYERS+1] = false;
bool g_bOneBulletAWP[MAXPLAYERS+1] = false;
bool g_bOneMagDeagle[MAXPLAYERS+1] = false;
bool g_bBhop[MAXPLAYERS+1] = false;
bool g_bMolotov[MAXPLAYERS+1] = false;
bool g_bHealth[MAXPLAYERS+1] = false;
bool g_bWallhack[MAXPLAYERS+1] = false;
bool g_bFroggyJump[MAXPLAYERS+1] = false;
bool g_bNoClip[MAXPLAYERS+1] = true;
bool g_bThrowingKnife[MAXPLAYERS+1] = true;
bool g_bGravity[MAXPLAYERS+1] = false;
bool g_bRandomTP[MAXPLAYERS+1] = false;
bool g_bLadder[MAXPLAYERS+1] = false;
bool g_bDBConnected = false;
bool g_bAllowBuy = true;
bool g_bCellsOpen = true;
bool g_bIsLR = true;
bool g_bSale = false;

bool gp_bSmartJailDoors = false;
bool gp_bMyJailBreak = false;
bool gp_bCustomPlayerSkins = false;
bool gp_bMyJBWarden = false;
bool gp_bMyIcons = false;


// Intergers
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iCredits[MAXPLAYERS+1];
int g_iFroggyJumped[MAXPLAYERS + 1];
int g_iKnifesThrown[MAXPLAYERS + 1] = 0;


// Handles
Handle g_hTimerCredits;
Handle g_hCookieCredits = INVALID_HANDLE;
Handle g_hDB = INVALID_HANDLE;
Handle gF_hOnPlayerGetCredits;
Handle gF_hOnPlayerBuyItem;
Handle g_hTimerDelay[MAXPLAYERS+1];
Handle g_hThrownKnives;

Handle gF_hOnGetCredits;
Handle gF_hOnSetCredits;

Handle gF_hOnShopMenu;
Handle gF_hOnShopMenuHandler;

Handle gF_hOnResetPlayer;


// Strings
char g_sSQLBuffer[1024];
char g_sModelPathPrevious[MAXPLAYERS+1][256];
char g_sModelPathFakeGuard[256];
char g_sPurchaseLogFile[PLATFORM_MAX_PATH];
char g_sGiftLogFile[PLATFORM_MAX_PATH];
char g_sInvisibleFlag[64];
char g_sAWPFlag[64];
char g_sNoDamageFlag[64];
char g_sOpenCellsFlag[64];
char g_sVampireFlag[64];
char g_sHealthFlag[64];
char g_sDeagleFlag[64];
char g_sKnifeFlag[64];
char g_sHealFlag[64];
char g_sMolotovFlag[64];
char g_sFakeModelFlag[64];
char g_sPoisonSmokeFlag[64];
char g_sBirdFlag[64];
char g_sTeleportSmokeFlag[64];
char g_sReviveFlag[64];
char g_sFireHEFlag[64];
char g_sBhopFlag[64];
char g_sGravityFlag[64];
char g_sTaserFlag[64];
char g_sNoClipFlag[64];
char g_sThrowKnifeFlag[64];
char g_sWallhackFlag[64];
char g_sFroggyJumpFlag[64];
char g_sPaperClipFlag[64];
char g_sRandomTPFlag[64];


// Info
public Plugin myinfo = {
	name = "MyJailShop",
	author = "shanapu",
	description = "MyJailShop provide you a high customizable shop with credits system intended for jailbreak server",
	version = VERSION,
	url = URL
};


// Start
public void OnPluginStart()
{
	// Translation
	LoadTranslations("common.phrases");
	LoadTranslations("MyJailShop.phrases");
	g_hCookieCredits = RegClientCookie("Credits", "Credits", CookieAccess_Private);
	
	
	// Client Commands
	RegConsoleCmd("sm_jailshop", Command_Menu_OpenShop, "Open the jail shop menu");
	RegConsoleCmd("sm_jailcredits", Commands_Credits, "Show your jail shop credits");
	RegConsoleCmd("sm_jailgift", Command_SendCredits, "Gift jail credits to a player - Use: sm_jailgift <#userid|name> [amount]");
	RegConsoleCmd("sm_revive", Command_Revive, "Use shop item revive");
	RegConsoleCmd("sm_showjailcredits", Command_ShowCredits, "Show jail credits of all online player");
	RegConsoleCmd("drop", Command_ToggleFly, "Change the flymode 'be a bird'-item");
	
	
	// Admin Commands
	RegAdminCmd("sm_sale", AdminCommand_Sale, ADMFLAG_ROOT, "Happy Hour");
	RegAdminCmd("sm_jailgive", AdminCommand_GiveCredits, ADMFLAG_ROOT, "Give jail shop credits to a player - Use: sm_jailgive <#userid|name> [amount]");
	RegAdminCmd("sm_jailset", AdminCommand_SetCredits, ADMFLAG_ROOT, "Set jail shop credits of a player - Use: sm_jailset <#userid|name> [amount]");
	
	
	// AutoExecConfig
	DirExistsEx("cfg/MyJailShop");

	AutoExecConfig_SetFile("Settings", "MyJailShop");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_jailshop_version", VERSION, "The version of this MyJailShop SourceMod plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bEnable = AutoExecConfig_CreateConVar("sm_jailshop_enable", "1", "0 - disabled, 1 - enable the MyJailShop SourceMod plugin", _, true, 0.0, true, 1.0);
	
	gc_bCreditSystem = AutoExecConfig_CreateConVar("sm_jailshop_credits_system", "1", "1 - MyJailShop Credits, 0 - Zephrus store or 'SM Store' or FrozDark shop (need extra support plugin)", _, true, 0.0, true, 1.0);
	gc_bCreditsSave = AutoExecConfig_CreateConVar("sm_jailshop_credits_save", "1", "0 - disabled, 1 - Save credits on player disconnect", _, true, 0.0, true, 1.0);
	gc_bMySQL = AutoExecConfig_CreateConVar("sm_jailshop_mysql", "0", "0 - disabled, 1 - Should we use a mysql database to store credits", _, true, 0.0, true, 1.0);
	gc_iCreditsMax = AutoExecConfig_CreateConVar("sm_jailshop_credits_max", "50000", "Maximum of credits to earn for a player");
	gc_iMinPlayersToGetCredits = AutoExecConfig_CreateConVar("sm_jailshop_minplayers", "4", "Minimum players to earn credits", _, true, 0.0);
	gc_bCreditsWarmup = AutoExecConfig_CreateConVar("sm_jailshop_warmupcredits", "1", "0 - disabled, 1 - enable players get credits on warmup", _, true, 0.0, true, 1.0);
	
	gc_iCreditsKillT = AutoExecConfig_CreateConVar("sm_jailshop_credits_kill_t", "150", "0 - disabled, amount of credits a prisoner earns when kill a Guard", _, true, 0.0);
	gc_iCreditsVIPKillT = AutoExecConfig_CreateConVar("sm_jailshop_credits_kill_t_vip", "200", "0 - disabled, amount of credits a VIP prisoner earns when kill a Guard", _, true, 0.0);
	gc_iCreditsKillCT = AutoExecConfig_CreateConVar("sm_jailshop_credits_kill_ct", "15", "0 - disabled, amount of credits a guard earns when kill a prisoner", _, true, 0.0);
	gc_iCreditsVIPKillCT = AutoExecConfig_CreateConVar("sm_jailshop_credits_kill_ct_vip", "20", "0 - disabled, amount of credits a VIP guard earns when kill a prisoner", _, true, 0.0);
	
	gc_iCreditsWinT = AutoExecConfig_CreateConVar("sm_jailshop_credits_win_t", "50", "0 - disabled, amount of credits a prisoner earns when win round", _, true, 0.0);
	gc_iCreditsVIPWinT = AutoExecConfig_CreateConVar("sm_jailshop_credits_win_t_vip", "100", "0 - disabled, amount of credits a VIP prisoner earns when win round", _, true, 0.0);
	gc_iCreditsWinCT = AutoExecConfig_CreateConVar("sm_jailshop_credits_win_ct", "50", "0 - disabled, amount of credits a guard earns when win round", _, true, 0.0);
	gc_iCreditsVIPWinCT = AutoExecConfig_CreateConVar("sm_jailshop_credits_win_ct_vip", "100", "0 - disabled, amount of credits a VIP guard earns when win round", _, true, 0.0);
	gc_bCreditsWinAlive = AutoExecConfig_CreateConVar("sm_jailshop_credits_win_alive", "1", "0 - disabled, 1 - only alive player get credits when team win the round", _, true, 0.0, true, 1.0);
	
	gc_iCreditsLR = AutoExecConfig_CreateConVar("sm_jailshop_credits_lr", "300", "0 - disabled, amount of credits for reach last request as prisoner (only if hosties is available)", _, true, 0.0);
	gc_iCreditsVIPLR = AutoExecConfig_CreateConVar("sm_jailshop_credits_lr_vip", "400", "0 - disabled, amount of credits for reach last request as prisoner (only if hosties is available)", _, true, 0.0);
	
	gc_iCreditsTime = AutoExecConfig_CreateConVar("sm_jailshop_credits_per_time", "5", "0 - disabled, how many credits players receive every x seconds 'sm_jailshop_credits_time_interval'", _, true, 0.0);
	gc_fCreditsTimeInterval = AutoExecConfig_CreateConVar("sm_jailshop_credits_per_time_interval", "120", "Time in seconds a player recieved credits per time", _, true, 0.0);
	gc_iCreditsVIPPerTime = AutoExecConfig_CreateConVar("sm_jailshop_credits_per_time_vip", "10", "0 - disabled, how many credits VIP players receive for 'sm_jailshop_credits_time_interval", _, true, 0.0);
	
	gc_bWelcome = AutoExecConfig_CreateConVar("sm_jailshop_welcome", "1", "0 - disabled, 1 - welcome messages on spawn", _, true, 0.0, true, 1.0);
	gc_bNotification = AutoExecConfig_CreateConVar("sm_jailshop_notification", "1", "0 - disabled, 1 - enable chat notification everytime player get credits", _, true, 0.0, true, 1.0);
	gc_fBuyTime = AutoExecConfig_CreateConVar("sm_jailshop_buytime", "180", "0 - disabled, Time in seconds after roundstart shopping is allowed", _, true, 0.0);
	gc_bBuyTimeCells = AutoExecConfig_CreateConVar("sm_jailshop_buytime_cells", "0", "0 - disabled, 1 - only shopping until cell doors opened (only if smartjaildoors is available)", _, true, 0.0, true, 1.0);
	gc_bBuyOnLR = AutoExecConfig_CreateConVar("sm_jailshop_buy_lr", "1", "0 - disabled, 1 - restrict shopping on Last lequest", _, true, 0.0, true, 1.0);
	gc_bRemoveOnLR = AutoExecConfig_CreateConVar("sm_jailshop_remove_lr", "1", "Remove the bought perks on a last request. (bought weapons will stay)", _, true, 0.0, true, 1.0);
	gc_bOnlyT = AutoExecConfig_CreateConVar("sm_jailshop_access", "0", "0 - shop available for guards & prisoner, 1 - only prisoner", _, true, 0.0, true, 1.0);
	gc_bEventdays = AutoExecConfig_CreateConVar("sm_jailshop_myjb", "1", "0 - disable shopping on MyJailbreak Event Days, 1 - enable shopping on MyJailbreak Event Days (only if myjb is available)(show/gift/... credits is still enabled)", _, true, 0.0, true, 1.0);
	gc_bRemoveWeapon = AutoExecConfig_CreateConVar("sm_jailshop_removeweapon", "1", "0 - disabled, 1 - When a player already got a prim/sec weapon and buy deagle or awp the current weapon disappear", _, true, 0.0, true, 1.0);
	gc_bClose = AutoExecConfig_CreateConVar("sm_jailshop_close", "1", "0 - disabled, 1 - enable close menu after action", _, true, 0.0, true, 1.0);
	gc_bTag = AutoExecConfig_CreateConVar("sm_jailshop_tag", "1", "Allow \"MyJailShop\" to be added to the server tags? So player will find servers with MyJailShop faster. it dont touch you sv_tags", _, true, 0.0, true, 1.0);
	gc_bLogging = AutoExecConfig_CreateConVar("sm_jailshop_log", "1", "Allow MyJailShop to log purchases and gifts in logs/MyJailShop", _, true, 0.0, true, 1.0);
	
	gc_sCustomCommandShop = AutoExecConfig_CreateConVar("sm_jailshop_cmds_shop", "jbshop,jbstore,jailstore", "Set your custom chat commands for shop menu(!jailshop (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands)");
	gc_sCustomCommandGift = AutoExecConfig_CreateConVar("sm_jailshop_cmds_gift", "jbgift,send", "Set your custom chat commands for gifting credits(!jailgift (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands)");
	gc_sCustomCommandRevive = AutoExecConfig_CreateConVar("sm_jailshop_cmds_revive", "revive,jbrevive,alive", "Set your custom chat commands for revive(!jailrevive (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands)");
	gc_sCustomCommandCredits = AutoExecConfig_CreateConVar("sm_jailshop_cmds_credits", "points,credits", "Set your custom chat commands to see you credits (!jailcredits (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands)");
	gc_sCustomCommandMassCredits = AutoExecConfig_CreateConVar("sm_jailshop_cmds_showcredits", "showpoints,allcredits,showcredits", "Set your custom chat commands for see all online players credits(!showjailcredits (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands)");
	
	gc_fSale = AutoExecConfig_CreateConVar("sm_jailshop_sale_multi", "40", "How many percent discount on a sale!", _, true, 1.0, true, 100.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	AutoExecConfig_SetFile("Items", "MyJailShop");
	AutoExecConfig_SetCreateFile(true);
	
	// Items
	gc_iOpenCells = AutoExecConfig_CreateConVar("sm_jailshop_openjails_price", "800", "0 - disabled, price of the 'Open jails' shop item", _, true, 0.0);
	gc_sOpenCellsFlag = AutoExecConfig_CreateConVar("sm_jailshop_openjails_flag", "", "Set flag for admin/vip must have to get access to open cells. No flag = is available for all players!");
	gc_iHeal = AutoExecConfig_CreateConVar("sm_jailshop_heal_price", "250", "0 - disabled, price of the 'Heal' shop item", _, true, 0.0);
	gc_iHealOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_heal_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only ", _, true, 0.0, true, 2.0);
	gc_sHealFlag = AutoExecConfig_CreateConVar("sm_jailshop_heal_flag", "", "Set flag for admin/vip must have to get access to heal. No flag = is available for all players!");
	gc_iHealth = AutoExecConfig_CreateConVar("sm_jailshop_armor_hp_price", "1500", "0 - disabled, price of the 'Armor & HP' shop item", _, true, 0.0);
	gc_iHealthExtra = AutoExecConfig_CreateConVar("sm_jailshop_health_extra", "150", "How many HP get extra with the armor", _, true, 0.0);
	gc_iHealthExtraOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_health_extra_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only", _, true, 0.0, true, 2.0);
	gc_sHealthFlag = AutoExecConfig_CreateConVar("sm_jailshop_health_flag", "", "Set flag for admin/vip must have to get access to health. No flag = is available for all players!");
	gc_iRevive = AutoExecConfig_CreateConVar("sm_jailshop_revive_price", "8000", "0 - disabled, price of the 'Revive' shop item", _, true, 0.0);
	gc_iReviveOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_revive_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only  ", _, true, 0.0, true, 2.0);
	gc_sReviveFlag = AutoExecConfig_CreateConVar("sm_jailshop_revive_flag", "", "Set flag for admin/vip must have to get access to revive. No flag = is available for all players!");
	gc_iVampire = AutoExecConfig_CreateConVar("sm_jailshop_vampire_price", "4000", "0 - disabled, price of the 'Vampire' shop item", _, true, 0.0);
	gc_fVampireSpeed = AutoExecConfig_CreateConVar("sm_jailshop_vampire_speed", "1.5", "Ratio for how fast the player will walk (1 - normal)", _, true, 0.5);
	gc_fVampireDamageMultiplier = AutoExecConfig_CreateConVar("sm_jailshop_vampire_multiplier", "0.5", "Multiplier how many heatlh per damage  (e.g. 100damage * 0.5 = 50HP extra)", _, true, 1.0);
	gc_sVampireFlag = AutoExecConfig_CreateConVar("sm_jailshop_vampire_flag", "", "Set flag for admin/vip must have to get access to vampire. No flag = is available for all players!");
	gc_iBhop = AutoExecConfig_CreateConVar("sm_jailshop_bhop_price", "5000", "0 - disabled, price of the 'Bunny Hop' shop item", _, true, 0.0);
	gc_iBhopOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_bhop_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only ", _, true, 0.0, true, 2.0);
	gc_sBhopFlag = AutoExecConfig_CreateConVar("sm_jailshop_bhop_flag", "", "Set flag for admin/vip must have to get access to bhop. No flag = is available for all players!");
	gc_iFroggyJump = AutoExecConfig_CreateConVar("sm_jailshop_froggyjump_price", "4000", "0 - disabled, price of the 'Froggy Jump' shop item", _, true, 0.0);
	gc_iFroggyJumpOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_froggyjump_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only ", _, true, 0.0, true, 2.0);
	gc_sFroggyJumpFlag = AutoExecConfig_CreateConVar("sm_jailshop_froggyjump_flag", "", "Set flag for admin/vip must have to get access to froggyjump. No flag = is available for all players!");
	gc_iGravity = AutoExecConfig_CreateConVar("sm_jailshop_gravity_price", "2500", "0 - disabled, price of the 'Low Gravity' shop item", _, true, 0.0);
	gc_fGravValue = AutoExecConfig_CreateConVar("sm_jailshop_gravity_value", "0.6", "Ratio for Gravity (1.0 earth, 0.5 moon)", _, true, 0.1, true, 1.0);
	gc_iGravOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_gravity_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only ", _, true, 0.0, true, 2.0);
	gc_sGravityFlag = AutoExecConfig_CreateConVar("sm_jailshop_gravity_flag", "", "Set flag for admin/vip must have to get access to gravity. No flag = is available for all players!");
	gc_iInvisible = AutoExecConfig_CreateConVar("sm_jailshop_invisible_price", "8000", "0 - disabled, price of the 'Invisible' shop item", _, true, 0.0);
	gc_fInvisibleTime = AutoExecConfig_CreateConVar("sm_jailshop_invisible_time", "10.0", "Time in seconds how long the player is invisible", _, true, 1.0);
	gc_sInvisibleFlag = AutoExecConfig_CreateConVar("sm_jailshop_invisible_flag", "", "Set flag for admin/vip must have to get access to invisible. No flag = is available for all players!");
	gc_iPaperClip = AutoExecConfig_CreateConVar("sm_jailshop_paperclip_price", "500", "0 - disabled, price of the 'PaperClips' shop item (only if myjb is available)", _, true, 0.0);
	gc_iPaperClipAmount = AutoExecConfig_CreateConVar("sm_jailshop_paperclip_amount", "2", "Amount of paperclips a player get (only if myjb is available)", _, true, 1.0);
	gc_sPaperClipFlag = AutoExecConfig_CreateConVar("sm_jailshop_paperclip_flag", "", "Set flag for admin/vip must have to get access to paperclip. No flag = is available for all players!");
	gc_iNoDamage = AutoExecConfig_CreateConVar("sm_jailshop_nodamage_price", "1500", "0 - disabled, price of the 'NoDamage' shop item", _, true, 0.0);
	gc_fNoDamageTime = AutoExecConfig_CreateConVar("sm_jailshop_nodamage_time", "20.0", "Time in seconds how long the player got nodamage", _, true, 1.0);
	gc_iNoDamageOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_nodamage_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only", _, true, 0.0, true, 2.0);
	gc_sNoDamageFlag = AutoExecConfig_CreateConVar("sm_jailshop_nodamage_flag", "", "Set flag for admin/vip must have to get access to damage. No flag = is available for all players!");
	gc_iNoClip = AutoExecConfig_CreateConVar("sm_jailshop_noclip_price", "9000", "0 - disabled, price of the 'No Clip' shop item", _, true, 0.0);
	gc_fNoClipTime = AutoExecConfig_CreateConVar("sm_jailshop_noclip_time", "5.0", "Time in seconds how long the player has noclip", _, true, 1.0);
	gc_sNoClipFlag = AutoExecConfig_CreateConVar("sm_jailshop_noclip_flag", "", "Set flag for admin/vip must have to get access to noclip. No flag = is available for all players!");
	gc_bNoClipKill = AutoExecConfig_CreateConVar("sm_jailshop_noclip_stuck", "1", "0 - disabled / 1 - kill player when stuck after noclip", _, true, 0.0, true, 1.0);
	gc_iWallhack = AutoExecConfig_CreateConVar("sm_jailshop_wallhack_price", "25000", "0 - disabled, price of the 'Wallhack' shop item (only if CustomPlayerSkins is available)", _, true, 0.0);
	gc_fWallhackTime = AutoExecConfig_CreateConVar("sm_jailshop_wallhack_time", "10.0", "Time in seconds how long the player has wallhack", _, true, 1.0);
	gc_iWallhackOnlyTeam = AutoExecConfig_CreateConVar("sm_jailshop_wallhack_access", "1", "0 - guards only, 1 - guards & prisoner, 2 - prisoner only", _, true, 0.0, true, 2.0);
	gc_sWallhackFlag = AutoExecConfig_CreateConVar("sm_jailshop_wallhack_flag", "", "Set flag for admin/vip must have to get access to wallhack. No flag = is available for all players!");
	gc_iBird = AutoExecConfig_CreateConVar("sm_jailshop_bird_price", "1500", "0 - disabled, price of the 'Be a Bird' shop item", _, true, 0.0);
	gc_iBirdMode = AutoExecConfig_CreateConVar("sm_jailshop_bird_mode", "1", "1 - Chicken / 2 - Pigeon / 3 - Crow", _, true, 1.0, true, 3.0);
	gc_sBirdFlag = AutoExecConfig_CreateConVar("sm_jailshop_bird_flag", "", "Set flag for admin/vip must have to get access to bird. No flag = is available for all players!");
	gc_iFakeModel = AutoExecConfig_CreateConVar("sm_jailshop_fakeguard_price", "9000", "0 - disabled, price of the 'Fake guard model' shop item", _, true, 0.0);
	gc_sModelPathFakeGuard = AutoExecConfig_CreateConVar("sm_jailshop_fakeguard_model", "models/player/ctm_gign_variantc.mdl", "Path to the model for fake guard.");
	gc_sFakeModelFlag = AutoExecConfig_CreateConVar("sm_jailshop_fakeguard_flag", "", "Set flag for admin/vip must have to get access to fake model. No flag = is available for all players!");
	gc_iTeleportSmoke = AutoExecConfig_CreateConVar("sm_jailshop_teleportsmoke_price", "7000", "0 - disabled, price of the 'Teleport smoke' shop item", _, true, 0.0);
	gc_sTeleportSmokeFlag = AutoExecConfig_CreateConVar("sm_jailshop_teleportsmoke_flag", "", "Set flag for admin/vip must have to get access to teleport smoke. No flag = is available for all players!");
	gc_iPoisonSmoke = AutoExecConfig_CreateConVar("sm_jailshop_poisonsmoke_price", "2500", "0 - disabled, price of the 'Poison smoke' shop item", _, true, 0.0);
	gc_sPoisonSmokeFlag = AutoExecConfig_CreateConVar("sm_jailshop_poisonsmoke_flag", "", "Set flag for admin/vip must have to get access to Poison Smoke. No flag = is available for all players!");
	gc_iFireHE = AutoExecConfig_CreateConVar("sm_jailshop_firehe_price", "3000", "0 - disabled, price of the 'Fire Grenade' shop item", _, true, 0.0);
	gc_sFireHEFlag = AutoExecConfig_CreateConVar("sm_jailshop_firehe_flag", "", "Set flag for admin/vip must have to get access to firehe. No flag = is available for all players!");
	gc_iAWP = AutoExecConfig_CreateConVar("sm_jailshop_awp_price", "8000", "0 - disabled, price of the 'One bullet AWP' shop item", _, true, 0.0);
	gc_sAWPFlag = AutoExecConfig_CreateConVar("sm_jailshop_awp_flag", "", "Set flag for admin/vip must have to get access to awp. No flag = is available for all players!");
	gc_iDeagle = AutoExecConfig_CreateConVar("sm_jailshop_deagle_price", "10000", "0 - disabled, price of the '7 bullets Deagle' shop item", _, true, 0.0);
	gc_sDeagleFlag = AutoExecConfig_CreateConVar("sm_jailshop_deagle_flag", "", "Set flag for admin/vip must have to get access to deagle. No flag = is available for all players!");
	gc_iKnife = AutoExecConfig_CreateConVar("sm_jailshop_knife_price", "4000", "0 - disabled, price of the 'One hit knife' shop item", _, true, 0.0);
	gc_sKnifeFlag = AutoExecConfig_CreateConVar("sm_jailshop_knife_flag", "", "Set flag for admin/vip must have to get access to knife. No flag = is available for all players!");
	gc_iThrowKnife = AutoExecConfig_CreateConVar("sm_jailshop_throw_knife_price", "12000", "0 - disabled, price of the 'Throwing one hit knife' shop item", _, true, 0.0);
	gc_iThrowKnifeCount = AutoExecConfig_CreateConVar("sm_jailshop_throw_knife_count", "2", "how many knifes a prisoner can throw", _, true, 1.0);
	gc_sThrowKnifeFlag = AutoExecConfig_CreateConVar("sm_jailshop_throw_knife_flag", "", "Set flag for admin/vip must have to get access to throw knife. No flag = is available for all players!");
	gc_iTaser = AutoExecConfig_CreateConVar("sm_jailshop_taser_price", "6000", "0 - disabled, price of the '3 bullets Taser' shop item", _, true, 0.0);
	gc_sTaserFlag = AutoExecConfig_CreateConVar("sm_jailshop_taser_flag", "", "Set flag for admin/vip must have to get access to taser. No flag = is available for all players!");
	gc_iMolotov = AutoExecConfig_CreateConVar("sm_jailshop_molotov_price", "2500", "0 - disabled, price of the 'Molotov & flashs' shop item", _, true, 0.0);
	gc_sMolotovFlag = AutoExecConfig_CreateConVar("sm_jailshop_molotov_flag", "", "Set flag for admin/vip must have to get access to molotov. No flag = is available for all players!");
	gc_iRandomTP = AutoExecConfig_CreateConVar("sm_jailshop_randomtp", "6500", "0 - disable, price of the 'Random teleport' shop item", _, true, 0.0);
	gc_sRandomTPFlag = AutoExecConfig_CreateConVar("sm_jailshop_randomtp_flag", "", "Set flag for admin/vip must have to get accesso to RandomTP. No flag = is avaible for all players!");
	
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	
	// Hooks
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("smokegrenade_detonate", Event_SmokeGrenadeDetonate, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookConVarChange(gc_sModelPathFakeGuard, OnSettingChanged);
	HookConVarChange(gc_sInvisibleFlag, OnSettingChanged);
	HookConVarChange(gc_sAWPFlag, OnSettingChanged);
	HookConVarChange(gc_sNoDamageFlag, OnSettingChanged);
	HookConVarChange(gc_sOpenCellsFlag, OnSettingChanged);
	HookConVarChange(gc_sVampireFlag, OnSettingChanged);
	HookConVarChange(gc_sHealthFlag, OnSettingChanged);
	HookConVarChange(gc_sDeagleFlag, OnSettingChanged);
	HookConVarChange(gc_sKnifeFlag, OnSettingChanged);
	HookConVarChange(gc_sHealFlag, OnSettingChanged);
	HookConVarChange(gc_sMolotovFlag, OnSettingChanged);
	HookConVarChange(gc_sFakeModelFlag, OnSettingChanged);
	HookConVarChange(gc_sPoisonSmokeFlag, OnSettingChanged);
	HookConVarChange(gc_sBirdFlag, OnSettingChanged);
	HookConVarChange(gc_sTeleportSmokeFlag, OnSettingChanged);
	HookConVarChange(gc_sReviveFlag, OnSettingChanged);
	HookConVarChange(gc_sFireHEFlag, OnSettingChanged);
	HookConVarChange(gc_sBhopFlag, OnSettingChanged);
	HookConVarChange(gc_sGravityFlag, OnSettingChanged);
	HookConVarChange(gc_sTaserFlag, OnSettingChanged);
	HookConVarChange(gc_sNoClipFlag, OnSettingChanged);
	HookConVarChange(gc_sThrowKnifeFlag, OnSettingChanged);
	HookConVarChange(gc_sWallhackFlag, OnSettingChanged);
	HookConVarChange(gc_sFroggyJumpFlag, OnSettingChanged);
	HookConVarChange(gc_sPaperClipFlag, OnSettingChanged);
	HookConVarChange(gc_sRandomTPFlag, OnSettingChanged);
	
	
	// FindConVar
	gc_sModelPathFakeGuard.GetString(g_sModelPathFakeGuard, sizeof(g_sModelPathFakeGuard));
	gc_sInvisibleFlag.GetString(g_sInvisibleFlag, sizeof(g_sInvisibleFlag));
	gc_sAWPFlag.GetString(g_sAWPFlag, sizeof(g_sAWPFlag));
	gc_sNoDamageFlag.GetString(g_sNoDamageFlag, sizeof(g_sNoDamageFlag));
	gc_sOpenCellsFlag.GetString(g_sOpenCellsFlag, sizeof(g_sOpenCellsFlag));
	gc_sVampireFlag.GetString(g_sVampireFlag, sizeof(g_sVampireFlag));
	gc_sHealthFlag.GetString(g_sHealthFlag, sizeof(g_sHealthFlag));
	gc_sDeagleFlag.GetString(g_sDeagleFlag, sizeof(g_sDeagleFlag));
	gc_sKnifeFlag.GetString(g_sKnifeFlag, sizeof(g_sKnifeFlag));
	gc_sHealFlag.GetString(g_sHealFlag, sizeof(g_sHealFlag));
	gc_sMolotovFlag.GetString(g_sMolotovFlag, sizeof(g_sMolotovFlag));
	gc_sFakeModelFlag.GetString(g_sFakeModelFlag, sizeof(g_sFakeModelFlag));
	gc_sPoisonSmokeFlag.GetString(g_sPoisonSmokeFlag, sizeof(g_sPoisonSmokeFlag));
	gc_sBirdFlag.GetString(g_sBirdFlag, sizeof(g_sBirdFlag));
	gc_sTeleportSmokeFlag.GetString(g_sTeleportSmokeFlag, sizeof(g_sTeleportSmokeFlag));
	gc_sReviveFlag.GetString(g_sReviveFlag, sizeof(g_sReviveFlag));
	gc_sFireHEFlag.GetString(g_sFireHEFlag, sizeof(g_sFireHEFlag));
	gc_sBhopFlag.GetString(g_sBhopFlag, sizeof(g_sBhopFlag));
	gc_sGravityFlag.GetString(g_sGravityFlag, sizeof(g_sGravityFlag));
	gc_sTaserFlag.GetString(g_sTaserFlag, sizeof(g_sTaserFlag));
	gc_sNoClipFlag.GetString(g_sNoClipFlag, sizeof(g_sNoClipFlag));
	gc_sThrowKnifeFlag.GetString(g_sThrowKnifeFlag, sizeof(g_sThrowKnifeFlag));
	gc_sWallhackFlag.GetString(g_sWallhackFlag, sizeof(g_sWallhackFlag));
	gc_sFroggyJumpFlag.GetString(g_sFroggyJumpFlag, sizeof(g_sFroggyJumpFlag));
	gc_sPaperClipFlag.GetString(g_sPaperClipFlag, sizeof(g_sPaperClipFlag));
	gc_sRandomTPFlag.GetString(g_sRandomTPFlag, sizeof(g_sRandomTPFlag));
	
	if (!g_bDBConnected && gc_bMySQL.BoolValue)
		DB_Connect();
	
	if (gc_bCreditsSave.BoolValue)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, true))
		{
			if (gc_bMySQL.BoolValue)
			{
				DB_AddPlayer(i);
				DB_FetchCredits(i);
			}
			else if (AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
	
	g_hThrownKnives = CreateArray();

	char sBuffer[256];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "logs/MyJailShop");
	DirExistsEx(sBuffer);

	SetLogFile(g_sPurchaseLogFile, "purchase", "MyJailShop");
	SetLogFile(g_sGiftLogFile, "gift", "MyJailShop");
}


// ConVarChange for Strings
public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sModelPathFakeGuard)
	{
		strcopy(g_sModelPathFakeGuard, sizeof(g_sModelPathFakeGuard), newValue);
		PrecacheModel(g_sModelPathFakeGuard);
	}
	else if (convar == gc_sInvisibleFlag)
	{
		strcopy(g_sInvisibleFlag, sizeof(g_sInvisibleFlag), newValue);
	}
	else if (convar == gc_sAWPFlag)
	{
		strcopy(g_sAWPFlag, sizeof(g_sAWPFlag), newValue);
	}
	else if (convar == gc_sNoDamageFlag)
	{
		strcopy(g_sNoDamageFlag, sizeof(g_sNoDamageFlag), newValue);
	}
	else if (convar == gc_sOpenCellsFlag)
	{
		strcopy(g_sOpenCellsFlag, sizeof(g_sOpenCellsFlag), newValue);
	}
	else if (convar == gc_sVampireFlag)
	{
		strcopy(g_sVampireFlag, sizeof(g_sVampireFlag), newValue);
	}
	else if (convar == gc_sHealthFlag)
	{
		strcopy(g_sHealthFlag, sizeof(g_sHealthFlag), newValue);
	}
	else if (convar == gc_sMolotovFlag)
	{
		strcopy(g_sMolotovFlag, sizeof(g_sMolotovFlag), newValue);
	}
	else if (convar == gc_sFakeModelFlag)
	{
		strcopy(g_sFakeModelFlag, sizeof(g_sFakeModelFlag), newValue);
	}
	else if (convar == gc_sPoisonSmokeFlag)
	{
		strcopy(g_sPoisonSmokeFlag, sizeof(g_sPoisonSmokeFlag), newValue);
	}
	else if (convar == gc_sBirdFlag)
	{
		strcopy(g_sBirdFlag, sizeof(g_sBirdFlag), newValue);
	}
	else if (convar == gc_sTeleportSmokeFlag)
	{
		strcopy(g_sTeleportSmokeFlag, sizeof(g_sTeleportSmokeFlag), newValue);
	}
	else if (convar == gc_sReviveFlag)
	{
		strcopy(g_sReviveFlag, sizeof(g_sReviveFlag), newValue);
	}
	else if (convar == gc_sFireHEFlag)
	{
		strcopy(g_sFireHEFlag, sizeof(g_sFireHEFlag), newValue);
	}
	else if (convar == gc_sBhopFlag)
	{
		strcopy(g_sBhopFlag, sizeof(g_sBhopFlag), newValue);
	}
	else if (convar == gc_sGravityFlag)
	{
		strcopy(g_sGravityFlag, sizeof(g_sGravityFlag), newValue);
	}
	else if (convar == gc_sTaserFlag)
	{
		strcopy(g_sTaserFlag, sizeof(g_sTaserFlag), newValue);
	}
	else if (convar == gc_sNoClipFlag)
	{
		strcopy(g_sNoClipFlag, sizeof(g_sNoClipFlag), newValue);
	}
	else if (convar == gc_sThrowKnifeFlag)
	{
		strcopy(g_sThrowKnifeFlag, sizeof(g_sThrowKnifeFlag), newValue);
	}
	else if (convar == gc_sWallhackFlag)
	{
		strcopy(g_sWallhackFlag, sizeof(g_sWallhackFlag), newValue);
	}
	else if (convar == gc_sFroggyJumpFlag)
	{
		strcopy(g_sFroggyJumpFlag, sizeof(g_sFroggyJumpFlag), newValue);
	}
	else if (convar == gc_sPaperClipFlag)
	{
		strcopy(g_sPaperClipFlag, sizeof(g_sPaperClipFlag), newValue);
	}
	else if (convar == gc_sRandomTPFlag)
	{
		strcopy(g_sRandomTPFlag, sizeof(g_sRandomTPFlag), newValue);
	}
}


public void OnConfigsExecuted()
{
	if (gc_bTag.BoolValue)
	{
		ConVar hTags = FindConVar("sv_tags");
		char sTags[128];
		hTags.GetString(sTags, sizeof(sTags));
		if (StrContains(sTags, "MyJailShop", false) == -1)
		{
			StrCat(sTags, sizeof(sTags), ", MyJailShop");
			hTags.SetString(sTags);
		}
	}
	
	// Set custom Commands
	int iCount = 0;
	char sCommands[128], sCommandsL[12][32], sCommand[32];
	
	// Shop menu
	gc_sCustomCommandShop.GetString(sCommands, sizeof(sCommands)); // Get new commands
	ReplaceString(sCommands, sizeof(sCommands), " ",""); // Remove the spaces " "
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[])); // Split commands to single command and count
	
	for (int i = 0; i < iCount; i++) // Loop the counted single commands
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]); // Add sm_ for console command
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)  // if command not already exist
			RegConsoleCmd(sCommand, Command_Menu_OpenShop, "Open the jail shop menu"); // set new command
	}
	
	// Shop show credits
	gc_sCustomCommandCredits.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ","");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)  // if command not already exist
			RegConsoleCmd(sCommand, Commands_Credits,"Show your jail shop credits");
	}
	
	// Shop revive
	gc_sCustomCommandRevive.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ","");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)  // if command not already exist
			RegConsoleCmd(sCommand, Command_Revive, "Use jail shop item revive");
	}
	
	// Shop show all credits menu
	gc_sCustomCommandMassCredits.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ","");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)  // if command not already exist
			RegConsoleCmd(sCommand, Command_ShowCredits, "Show jail shop credits of all online player");
	}
	
	// Shop send gift credits
	gc_sCustomCommandGift.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ","");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)  // if command not already exist
			RegConsoleCmd(sCommand, Command_SendCredits, "Gift jail shop credits to a player - Use: sm_jailgift <#userid|name> [amount]");
	}
}


/******************************************************************************
                   COMMANDS
******************************************************************************/


// sm_jailcredits
public Action Commands_Credits(int client, int args)
{
	if (client == 0) // if client is server/serverconsole
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	// Show credits in chat
	CReplyToCommand(client, "%t %t", "shop_tag", "shop_credits", Forward_OnGetCredits(client));
	return Plugin_Handled;
}


// sm_jailcredits
public Action AdminCommand_Sale(int client, int args)
{
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	if (args > 0)
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int bOpenSale = StringToInt(arg);

		if (bOpenSale == 1 && !g_bSale)
		{
			SaleOn();
		}
		else if (bOpenSale == 0 && g_bSale)
		{
			SaleOff();
		}
		else
		{
			CReplyToCommand(client, "%t Use: sm_sale <1|0>", "shop_tag");
		}
	}
	else if (!g_bSale)
	{
		SaleOn();
	}
	else
	{
		SaleOff();
	}
	
	return Plugin_Handled;
}


void SaleOff()
{
	ServerCommand("exec MyJailShop/Items.cfg");
	g_bSale = false;
	CPrintToChatAll("%t %t", "shop_tag", "shop_saleend");
}


void SaleOn()
{
	gc_iInvisible.IntValue = (gc_iInvisible.IntValue - ((gc_iInvisible.IntValue / 100) * gc_fSale.IntValue));
	gc_iAWP.IntValue = (gc_iAWP.IntValue - ((gc_iAWP.IntValue / 100) * gc_fSale.IntValue));
	gc_iNoDamage.IntValue = (gc_iNoDamage.IntValue - ((gc_iNoDamage.IntValue / 100) * gc_fSale.IntValue));
	gc_iOpenCells.IntValue = (gc_iOpenCells.IntValue - ((gc_iOpenCells.IntValue / 100) * gc_fSale.IntValue));
	gc_iVampire.IntValue = (gc_iVampire.IntValue - ((gc_iVampire.IntValue / 100) * gc_fSale.IntValue));
	gc_iHealth.IntValue = (gc_iHealth.IntValue - ((gc_iHealth.IntValue / 100) * gc_fSale.IntValue));
	gc_iDeagle.IntValue = (gc_iDeagle.IntValue - ((gc_iDeagle.IntValue / 100) * gc_fSale.IntValue));
	gc_iKnife.IntValue = (gc_iKnife.IntValue - ((gc_iKnife.IntValue / 100) * gc_fSale.IntValue));
	gc_iHeal.IntValue = (gc_iHeal.IntValue - ((gc_iHeal.IntValue / 100) * gc_fSale.IntValue));
	gc_iMolotov.IntValue = (gc_iMolotov.IntValue - ((gc_iMolotov.IntValue / 100) * gc_fSale.IntValue));
	gc_iFakeModel.IntValue = (gc_iFakeModel.IntValue - ((gc_iFakeModel.IntValue / 100) * gc_fSale.IntValue));
	gc_iPoisonSmoke.IntValue = (gc_iPoisonSmoke.IntValue - ((gc_iPoisonSmoke.IntValue / 100) * gc_fSale.IntValue));
	gc_iBird.IntValue = (gc_iBird.IntValue - ((gc_iBird.IntValue / 100) * gc_fSale.IntValue));
	gc_iTeleportSmoke.IntValue = (gc_iTeleportSmoke.IntValue - ((gc_iTeleportSmoke.IntValue / 100) * gc_fSale.IntValue));
	gc_iRevive.IntValue = (gc_iRevive.IntValue - ((gc_iRevive.IntValue / 100) * gc_fSale.IntValue));
	gc_iFireHE.IntValue = (gc_iFireHE.IntValue - ((gc_iFireHE.IntValue / 100) * gc_fSale.IntValue));
	gc_iBhop.IntValue = (gc_iBhop.IntValue - ((gc_iBhop.IntValue / 100) * gc_fSale.IntValue));
	gc_iGravity.IntValue = (gc_iGravity.IntValue - ((gc_iGravity.IntValue / 100) * gc_fSale.IntValue));
	gc_iTaser.IntValue = (gc_iTaser.IntValue - ((gc_iTaser.IntValue / 100) * gc_fSale.IntValue));
	gc_iNoClip.IntValue = (gc_iNoClip.IntValue - ((gc_iNoClip.IntValue / 100) * gc_fSale.IntValue));
	gc_iThrowKnife.IntValue = (gc_iThrowKnife.IntValue - ((gc_iThrowKnife.IntValue / 100) * gc_fSale.IntValue));
	gc_iWallhack.IntValue = (gc_iWallhack.IntValue - ((gc_iWallhack.IntValue / 100) * gc_fSale.IntValue));
	gc_iFroggyJump.IntValue = (gc_iFroggyJump.IntValue - ((gc_iFroggyJump.IntValue / 100) * gc_fSale.IntValue));
	gc_iPaperClip.IntValue = (gc_iPaperClip.IntValue - ((gc_iPaperClip.IntValue / 100) * gc_fSale.IntValue));
	gc_iRandomTP.IntValue = (gc_iRandomTP.IntValue - ((gc_iRandomTP.IntValue / 100) * gc_fSale.IntValue));
	
	g_bSale = true;
	CPrintToChatAll("%t %t", "shop_tag", "shop_saleon", gc_fSale.IntValue);
}

public void TG_OnGamePrepare()
{
	for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, true))
	{
		ResetPlayer(i);
	}
}

// sm_jailshop
public Action Command_Menu_OpenShop(int client, int args)
{
	if (client == 0) // if client is server/serverconsole
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	if (gp_bMyJailBreak && !gc_bEventdays.BoolValue) // Check if myjailbreak is available and if shop is allowed on eventdays
	{
		if (MyJailbreak_IsEventDayRunning())
		{
			CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
			return Plugin_Handled;
		}
	}
	
	if (gc_bOnlyT.BoolValue) // shop only for terror?
	{
		if (GetClientTeam(client) != 2)
		{
			CReplyToCommand(client, "%t %t", "shop_tag", "shop_tonly");
			return Plugin_Handled;
		}
		else Menu_OpenShop(client);
	}
	else Menu_OpenShop(client);
	return Plugin_Handled;
}


// sm_revive
public Action Command_Revive(int client, int args)
{
	if (gc_iRevive.IntValue == 0)
	{
		return Plugin_Handled;
	}
	if (client == 0) // if client is server/serverconsole
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	if (gc_iReviveOnlyTeam.IntValue == 2 && GetClientTeam(client) == CS_TEAM_CT) // shopitem only for terror?
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_onlyt");
		return Plugin_Handled;
	}
	if (gc_iReviveOnlyTeam.IntValue == 0 && GetClientTeam(client) == CS_TEAM_T) // shopitem only for counter-terror?
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_onlyct");
		return Plugin_Handled;
	}
	Item_Revive(client, "Revive");
	return Plugin_Handled;
}


// drop weapon button
public Action Command_ToggleFly(int client, int args)
{
	if (g_bFly[client]) // if player is a bird
	{
		MoveType movetype = GetEntityMoveType(client);
		
		if (movetype != MOVETYPE_FLY)
		{
			SetEntityMoveType(client, MOVETYPE_FLY);
		}
		else SetEntityMoveType(client, MOVETYPE_WALK);
	}
	return Plugin_Continue;
}


// sm_jailgift
public Action Command_SendCredits(int client, int args)
{
	if (client == 0) // if client is server/serverconsole
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	
	if (args < 2) // Not enough parameters
	{
		CReplyToCommand(client, "%t Use: sm_jailgift <#userid|name> [amount]", "shop_tag");
		return Plugin_Handled;
	}
	
	char arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int amount = StringToInt(arg2);
	
	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char strTargetName[MAX_TARGET_LENGTH];
	int TargetList[MAXPLAYERS], TargetCount;
	bool TargetTranslate;
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_IMMUNITY,
		strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < TargetCount; i++)
	{
		int iClient = TargetList[i];
		if (IsClientInGame(iClient) && amount > 0)
		{
			if (client != iClient)
			{
				if (Forward_OnGetCredits(client) < amount)
					ReplyToCommand(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), amount);
				else
				{
					Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-amount));
					Forward_OnSetCredits(iClient,(Forward_OnGetCredits(iClient)+amount));
					Forward_OnPlayerGetCredits(iClient, amount);
					
					CPrintToChat(client, "%t %t", "shop_tag", "shop_give", amount, iClient);
					CPrintToChat(iClient, "%t %t", "shop_tag", "shop_get", amount, client);
					if (gc_bLogging.BoolValue) LogToFileEx(g_sGiftLogFile, "Player %L has gift %i credits to %L ", client, amount, iClient);
				}
			}
			CPrintToChat(client, "%t %t", "shop_tag", "shop_giftyourself");
		}
	}
	return Plugin_Handled;
}


// sm_jailcredits
public Action Command_ShowCredits(int client, int args) 
{
	if (client == 0) // if client is server/serverconsole
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	
	char sName[MAX_NAME_LENGTH], sUserId[10];
	
	Menu menu = CreateMenu(Handler_ShowCredits);
	SetMenuTitle(menu, "%t","shop_menu_playercredits");
	
	for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, true))
	{
		GetClientName(i, sName, sizeof(sName));
		IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
		char buffer[255];
		Format(buffer, sizeof(buffer), "%s: %d", sName, Forward_OnGetCredits(i));
		AddMenuItem(menu, sUserId, buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitButton = true;
	menu.Display(client, 20);
	
	return Plugin_Handled;
}


public int Handler_ShowCredits(Menu menu, MenuAction action, int param1, int param2){}


// sm_jailset
public Action AdminCommand_SetCredits(int client, int args)
{
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	if (args < 2) 
	{
		CReplyToCommand(client, "%t Use: sm_jailset <#userid|name> [amount]", "shop_tag");
		return Plugin_Handled;
	}
	
	char arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int amount = StringToInt(arg2);
	
	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char strTargetName[MAX_TARGET_LENGTH];
	int TargetList[MAXPLAYERS], TargetCount;
	bool TargetTranslate;
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	for(int i = 0; i < TargetCount; i++)
	{
		int iClient = TargetList[i];
		if (IsClientInGame(iClient))
		{
			Forward_OnSetCredits(iClient, amount);
			Forward_OnPlayerGetCredits(iClient, amount);
			
			CReplyToCommand(client, "%t %t", "shop_tag", "shop_set", amount, iClient);
			CPrintToChat(iClient, "%t %t", "shop_tag", "shop_getset", amount, client);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sGiftLogFile, "Admin %L set %L credits to %i ", client, iClient, amount);
		}
	}
	return Plugin_Handled;
}


// sm_jailgive
public Action AdminCommand_GiveCredits(int client, int args)
{
	if (!gc_bEnable.BoolValue) // if plugin is disbaled
	{
		CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
		return Plugin_Handled;
	}
	if (args < 2) 
	{
		CReplyToCommand(client, "%t Use: sm_jailgive <#userid|name> [amount]", "shop_tag");
		return Plugin_Handled;
	}
	
	char arg2[10];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int amount = StringToInt(arg2);
	
	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget));
	char strTargetName[MAX_TARGET_LENGTH];
	
	int TargetList[MAXPLAYERS], TargetCount;
	bool TargetTranslate;
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	for(int i = 0; i < TargetCount; i++) 
	{
		int iClient = TargetList[i];
		if (IsClientInGame(iClient))
		{
			Forward_OnSetCredits(iClient,(Forward_OnGetCredits(iClient)+amount));
			Forward_OnPlayerGetCredits(iClient, amount);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_give", amount, iClient);
			CPrintToChat(iClient, "%t %t", "shop_tag", "shop_get", amount, client);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sGiftLogFile, "Admin %L gifted %i credits to %L ", client, amount, iClient);
		}
	}
	return Plugin_Handled;
}


/******************************************************************************
                   EVENTS
******************************************************************************/


public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker")); // get victim & attacker
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!gc_bEnable.BoolValue) // if plugin is disbaled
		return;

	// Start timer: show !revive chat hint if enought credits & enabled
	if ((Forward_OnGetCredits(client) >= gc_iRevive.IntValue) && gc_iRevive.IntValue != 0)
	{
		CreateTimer(2.0, Timer_DeathMessage, GetClientUserId(client));
	}

	if (g_bFly[client]) // if player was a bird reset model, thirdperson and flymode
	{
		g_bFly[client] = false;
		ClientCommand(client, "firstperson");
		SetEntityModel(client, g_sModelPathPrevious[client]);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}

	if (!attacker)
		return;

	if (attacker == client)
		return;

	if (GetClientTeam(attacker) == CS_TEAM_CT && gc_iCreditsKillCT.IntValue == 0 && gc_iCreditsVIPKillCT.IntValue == 0)
		return;

	if (GetClientTeam(attacker) == CS_TEAM_T && gc_iCreditsKillT.IntValue == 0 && gc_iCreditsVIPKillT.IntValue == 0)
		return;

	if (GetAllPlayersCount() >= gc_iMinPlayersToGetCredits.IntValue && (gc_bCreditsWarmup.BoolValue || GameRules_GetProp("m_bWarmupPeriod") != 1)) 
	{
		if (GetClientTeam(attacker) == CS_TEAM_CT)
		{
			if (IsPlayerReservationAdmin(attacker))
			{
				Forward_OnSetCredits(attacker,(Forward_OnGetCredits(attacker) + gc_iCreditsVIPKillCT.IntValue));
				Forward_OnPlayerGetCredits(attacker, gc_iCreditsVIPKillCT.IntValue);
			}
			else
			{
				Forward_OnSetCredits(attacker,(Forward_OnGetCredits(attacker) + gc_iCreditsKillCT.IntValue));
				Forward_OnPlayerGetCredits(attacker, gc_iCreditsKillCT.IntValue);
			}
		}
		
		if (GetClientTeam(attacker) == CS_TEAM_T)
		{
			if (IsPlayerReservationAdmin(attacker))
			{
				Forward_OnSetCredits(attacker,(Forward_OnGetCredits(attacker) + gc_iCreditsVIPKillT.IntValue));
				Forward_OnPlayerGetCredits(attacker, gc_iCreditsVIPKillT.IntValue);
			}
			else
			{
				Forward_OnSetCredits(attacker,(Forward_OnGetCredits(attacker) + gc_iCreditsKillT.IntValue));
				Forward_OnPlayerGetCredits(attacker, gc_iCreditsKillT.IntValue);
			}
		}
	}

	if (Forward_OnGetCredits(attacker) > gc_iCreditsMax.IntValue)
	{
		Forward_OnSetCredits(attacker, gc_iCreditsMax.IntValue);
		CPrintToChat(attacker, "%t %t", "shop_tag", "shop_maxcredits", Forward_OnGetCredits(attacker));
	}

	if (!gc_bNotification.BoolValue)
		return;

	if (GetAllPlayersCount() >= gc_iMinPlayersToGetCredits.IntValue && (gc_bCreditsWarmup.IntValue != 0 || GameRules_GetProp("m_bWarmupPeriod") != 1)) 
	{
		if (GetClientTeam(attacker) == CS_TEAM_CT)
		{
			if (IsPlayerReservationAdmin(attacker))
			{
				CPrintToChat(attacker, "%t %t", "shop_tag", "shop_killedt", Forward_OnGetCredits(attacker), gc_iCreditsVIPKillCT.IntValue, client);
			}
			else
			{
				CPrintToChat(attacker, "%t %t", "shop_tag", "shop_killedt", Forward_OnGetCredits(attacker), gc_iCreditsKillCT.IntValue, client);
			}
		}
		else if (GetClientTeam(attacker) == CS_TEAM_T)
		{
			if (IsPlayerReservationAdmin(attacker))
			{
				CPrintToChat(attacker, "%t %t", "shop_tag", "shop_killedct", Forward_OnGetCredits(attacker), gc_iCreditsVIPKillT.IntValue, client);
			}
			else
			{
				CPrintToChat(attacker, "%t %t", "shop_tag", "shop_killedct", Forward_OnGetCredits(attacker), gc_iCreditsKillT.IntValue, client);
			}
		}
	}
}


public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event,"userid")); // get victim & attacker
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker == 0 || !g_bFireHE[attacker] || g_bIsLR) 
		return;

	if (victim != attacker && attacker !=0 && attacker <MAXPLAYERS)
	{
		char sWeaponUsed[50];
		GetEventString(event,"weapon",sWeaponUsed,sizeof(sWeaponUsed));

		if (StrEqual(sWeaponUsed,"hegrenade"))
		{
			IgniteEntity(victim, 5.0);
		}
	}

	g_bFireHE[attacker] = false;
}


public Action Event_SmokeGrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	float DetonateOrigin[3];
	DetonateOrigin[0] = event.GetFloat("x");
	DetonateOrigin[1] = event.GetFloat("y");
	DetonateOrigin[2] = event.GetFloat("z");

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (g_bTeleportSmoke[client])
	{
		g_bTeleportSmoke[client] = false;
		if (IsClientInGame(client))
		{
			SetClientViewEntity(client, client);
		}

		TeleportEntity(client, DetonateOrigin, NULL_VECTOR, NULL_VECTOR);
	}

	if (!g_bPoison[client])
		return;

	int iEntity = CreateEntityByName("light_dynamic");

	if (iEntity == -1)
		return;

	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "5");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 96.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "6");
	DispatchKeyValue(iEntity, "_light", "0 255 0");
	DispatchKeyValueFloat(iEntity, "distance", 256.0);
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
	CreateTimer(17.0, Timer_Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);

	TE_SetupBeamRingPoint(DetonateOrigin, 99.0, 100.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 20.0, 10.0, 220.0, {50, 255, 50, 255}, 10, 0);
	TE_SendToAll();

	TE_SetupBeamRingPoint(DetonateOrigin, 99.0, 100.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 20.0, 10.0, 220.0, {50, 50, 255, 255}, 10, 0);
	TE_SendToAll();

	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, DetonateOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");

	CreateTimer(1.0, Timer_CheckDamage, iEntity, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);

	g_bPoison[client] = false;
}


public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");

	if (winner == CS_TEAM_T)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, gc_bCreditsWinAlive.BoolValue)) if (GetAllPlayersCount() >= gc_iMinPlayersToGetCredits.IntValue && (gc_bCreditsWarmup.BoolValue || GameRules_GetProp("m_bWarmupPeriod") != 1)) 
		{
			if (IsPlayerReservationAdmin(i) && gc_iCreditsVIPWinT.IntValue != 0)
			{
				Forward_OnSetCredits(i, (Forward_OnGetCredits(i) + gc_iCreditsVIPWinT.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsVIPWinT.IntValue);

				if (gc_bNotification.BoolValue)
				{
					CPrintToChat(i, "%t %t", "shop_tag", "shop_win", Forward_OnGetCredits(i), gc_iCreditsVIPWinT.IntValue);
				}
			}
			else if (gc_iCreditsWinT.IntValue != 0)
			{
				Forward_OnSetCredits(i, (Forward_OnGetCredits(i) + gc_iCreditsWinT.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsWinT.IntValue);

				if (gc_bNotification.BoolValue)
				{
					CPrintToChat(i, "%t %t", "shop_tag", "shop_win", Forward_OnGetCredits(i), gc_iCreditsWinT.IntValue);
				}
			}
		}
	}
	else if (winner == CS_TEAM_CT)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, gc_bCreditsWinAlive.BoolValue)) if (GetAllPlayersCount() >= gc_iMinPlayersToGetCredits.IntValue && (gc_bCreditsWarmup.BoolValue || GameRules_GetProp("m_bWarmupPeriod") != 1)) 
		{
			if (IsPlayerReservationAdmin(i) && gc_iCreditsVIPWinCT.IntValue != 0)
			{
				Forward_OnSetCredits(i,(Forward_OnGetCredits(i) + gc_iCreditsVIPWinCT.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsVIPWinCT.IntValue);

				if (gc_bNotification.BoolValue)
				{
					CPrintToChat(i, "%t %t", "shop_tag", "shop_win", Forward_OnGetCredits(i), gc_iCreditsVIPWinCT.IntValue);
				}
			}
			else if (gc_iCreditsVIPWinCT.IntValue != 0)
			{
				Forward_OnSetCredits(i,(Forward_OnGetCredits(i) + gc_iCreditsWinCT.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsWinCT.IntValue);

				if (gc_bNotification.BoolValue)
				{
					CPrintToChat(i, "%t %t", "shop_tag", "shop_win", Forward_OnGetCredits(i), gc_iCreditsWinCT.IntValue);
				}
			}
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, false, true))
			continue;

		ResetPlayer(i);

		if (gc_bMySQL.BoolValue)
		{
			DB_WriteCredits(i);
		}
	}

	g_bIsLR = true;
}


public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bAllowBuy = true;
	g_bCellsOpen = false;
	g_bIsLR = false;

	if (gc_fBuyTime.FloatValue != 0)
	{
		CreateTimer (gc_fBuyTime.FloatValue, Timer_BuyTime);
	}
}


public void Event_WeaponFire(Event event, char[] name, bool dontBroadcast)
{
	char weapon[20];
	event.GetString("weapon", weapon, sizeof(weapon));

	if (StrContains(weapon, "knife", false) == -1)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!g_bThrowingKnife[client])
		return;

	g_hTimerDelay[client] = CreateTimer(0.0, Timer_CreateKnife, GetClientUserId(client));
}


/******************************************************************************
                   FUNCTIONS LISTEN
******************************************************************************/


// Check for optional Plugins
public void OnAllPluginsLoaded()
{
	gp_bSmartJailDoors = LibraryExists("smartjaildoors");
	gp_bMyJailBreak = LibraryExists("myjailbreak");
	gp_bCustomPlayerSkins = LibraryExists("CustomPlayerSkins");
	gp_bMyJBWarden = LibraryExists("myjbwarden");
	gp_bMyIcons = LibraryExists("myicons");

	g_bHandcuff = FindConVar("sm_warden_handcuffs");
}


public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "smartjaildoors"))
		gp_bSmartJailDoors = false;

	if (StrEqual(name, "myjailbreak"))
		gp_bMyJailBreak = false;

	if (StrEqual(name, "CustomPlayerSkins"))
		gp_bCustomPlayerSkins = false;

	if (StrEqual(name, "myjbwarden"))
		gp_bMyJBWarden = false;

	if (StrEqual(name, "myicons"))
		gp_bMyIcons = false;
}


public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "smartjaildoors"))
		gp_bSmartJailDoors = true;

	if (StrEqual(name, "myjailbreak"))
		gp_bMyJailBreak = true;

	if (StrEqual(name, "CustomPlayerSkins"))
		gp_bCustomPlayerSkins = true;

	if (StrEqual(name, "myjbwarden"))
		gp_bMyJBWarden = true;

	if (StrEqual(name, "myicons"))
		gp_bMyIcons = true;
}


public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt", true);
	PrecacheModel("models/chicken/chicken.mdl");
	PrecacheModel(g_sModelPathFakeGuard);

	if (!g_bDBConnected && gc_bMySQL.BoolValue)
	{
		DB_Connect();
	}

	if (gc_bMySQL.BoolValue) for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, true))
	{
		DB_AddPlayer(i);
		DB_FetchCredits(i);
	}

	if (gc_iCreditsTime.IntValue != 0)
	{
		g_hTimerCredits = CreateTimer(gc_fCreditsTimeInterval.FloatValue, Timer_Credits, _, TIMER_REPEAT);
	}
}


public void OnClientDisconnect(int client)
{
	if (!gc_bCreditsSave.BoolValue)
	{
		g_iCredits[client] = 0;
		return;
	}

	if (gc_bMySQL.BoolValue)
	{
		if (!g_bDBConnected)
		{
			DB_Connect();
		}

		DB_WriteCredits(client);
	}
	else if (AreClientCookiesCached(client))
	{
		char CreditsString[12];
		Format(CreditsString, sizeof(CreditsString), "%i", Forward_OnGetCredits(client));
		SetClientCookie(client, g_hCookieCredits, CreditsString);
	}
}


public void OnClientCookiesCached(int client)
{
	if (!gc_bCreditsSave.BoolValue) 
		return;

	if (gc_bMySQL.BoolValue)
	{
		if (!g_bDBConnected)
		{
			DB_Connect();
		}

		DB_WriteCredits(client);
	}
	else
	{
		char CreditsString[12];
		GetClientCookie(client, g_hCookieCredits, CreditsString, sizeof(CreditsString));
		g_iCredits[client] = StringToInt(CreditsString);
	}

	if (!gc_bCreditSystem.BoolValue)
	{
		g_iCredits[client] = Forward_OnGetCredits(client);
	}
}


public void OnPluginEnd()
{
	if (!gc_bCreditsSave.BoolValue)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, false, true))
		continue;

		OnClientDisconnect(i);
	}
}


public void OnEntityCreated(int iEntity, const char[] classname) 
{
	if (StrEqual(classname, "smokegrenade_projectile"))
	{
		SDKHook(iEntity, SDKHook_SpawnPost, Hook_OnEntitySpawned);
	}
}


public void Hook_OnEntitySpawned(int iGrenade)
{
	int client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");

	if (IsValidClient(client, true, true) && g_bTeleportSmoke[client])
	{
		SetClientViewEntity(client, iGrenade);
	}
}


public void OnClientPostAdminCheck(int client)
{
	g_bNoDamage[client] = false;
	g_bInvisible[client] = false;
	g_bFireHE[client] = false;
	g_bSuperKnife[client] = false;
	g_bPoison[client] = false;
	g_bVampire[client] = false;
	g_bFly[client] = false;
	g_bFakeGuard[client] = false;
	g_bNoClip[client] = false;
	g_bThrowingKnife[client] = false;
	g_bFroggyJump[client] = false;
	g_bWallhack[client] = false;
	g_bOneBulletAWP[client] = false;
	g_bOneMagDeagle[client] = false;
	g_bTeleportSmoke[client] = false;
	g_bBhop[client] = false;
	g_bGravity[client] = false;
	g_bMolotov[client] = false;
	g_bHealth[client] = false;
}


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, Hook_OnWeaponCanUse);

	g_bNoDamage[client] = false;
	g_bInvisible[client] = false;
	g_bPoison[client] = false;
	g_bVampire[client] = false;
	g_bSuperKnife[client] = false;
	g_bTeleportSmoke[client] = false;
	g_bNoClip[client] = false;
	g_bThrowingKnife[client] = false;
	g_bFroggyJump[client] = false;
	g_bWallhack[client] = false;
	g_bFireHE[client] = false;
	g_bBhop[client] = false;
	g_bGravity[client] = false;
	g_bMolotov[client] = false;
	g_bHealth[client] = false;
	g_bOneBulletAWP[client] = false;
	g_bOneMagDeagle[client] = false;

	if (gc_bWelcome.BoolValue)
	{
		CreateTimer(5.0, Timer_WelcomeMessage, GetClientUserId(client));
	}
}


public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)  // todo clean up a bit
{
	if (attacker > 0 && attacker <= MaxClients && victim > 0 && victim <= MaxClients)
	{
		if (g_bNoDamage[victim] || g_bNoClip[attacker])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		else if (IsValidClient(victim, true, false)|| attacker == victim || IsValidClient(attacker, true, false))
		{
			ConVar g_bFF = FindConVar("mp_friendlyfire");
			if ((g_bVampire[attacker] && GetClientTeam(victim) != GetClientTeam(attacker)) || (g_bVampire[attacker] && g_bFF.BoolValue))
			{
				int newHP = RoundToFloor(damage * gc_fVampireDamageMultiplier.FloatValue);
				newHP += GetClientHealth(attacker);
				SetEntityHealth(attacker, newHP);
			}
			
			if (g_bSuperKnife[attacker])
			{
				char weaponName[255];
				GetClientWeapon(attacker, weaponName, sizeof(weaponName));
				
				if (StrContains(weaponName, "knife") != -1)
				{
					damage = 1000.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	int water = GetEntProp(client, Prop_Data, "m_nWaterLevel");

	// Last button
	static bool bPressed[MAXPLAYERS+1] = false;

	if (IsPlayerAlive(client))
	{
		if(g_bGravity[client])
		{
			if (GetEntityMoveType(client) == MOVETYPE_LADDER)
			{
				g_bLadder[client] = true;
			}
			else
			{
				if (g_bLadder[client])
				{
					SetEntityGravity(client, gc_fGravValue.FloatValue);
					g_bLadder[client] = false;
				}
			}
		}

		// Reset when on Ground
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			g_iFroggyJumped[client] = 0;
			bPressed[client] = false;
		}
		else
		{
			// Player pressed jump button?
			if (buttons & IN_JUMP)
			{
				if (water <= 1)
				{
					if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
					{
						SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
						if (!(GetEntityFlags(client) & FL_ONGROUND) && g_bBhop[client]) buttons &= ~IN_JUMP;
					}
				}

				if (!g_bFroggyJump[client])
					return Plugin_Continue;

				// For second time?
				if (!bPressed[client] && g_iFroggyJumped[client]++ == 1)
				{
					float velocity[3];
					float velocity0;
					float velocity1;
					float velocity2;
					float velocity2_new;

					// Get player velocity
					velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
					velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
					velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

					velocity2_new = 200.0;

					// calculate new velocity^^
					if (velocity2 < 150.0) velocity2_new = velocity2_new + 20.0;
					
					if (velocity2 < 100.0) velocity2_new = velocity2_new + 30.0;
					
					if (velocity2 < 50.0) velocity2_new = velocity2_new + 40.0;
					
					if (velocity2 < 0.0) velocity2_new = velocity2_new + 50.0;
					
					if (velocity2 < -50.0) velocity2_new = velocity2_new + 60.0;
					
					if (velocity2 < -100.0) velocity2_new = velocity2_new + 70.0;
					
					if (velocity2 < -150.0) velocity2_new = velocity2_new + 80.0;
					
					if (velocity2 < -200.0) velocity2_new = velocity2_new + 90.0;

					// Set new velocity
					velocity[0] = velocity0 * 0.1;
					velocity[1] = velocity1 * 0.1;
					velocity[2] = velocity2_new;

					// Double Jump
					SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
				}

				bPressed[client] = true;
			}
			else bPressed[client] = false;
		}
	}

	return Plugin_Continue;
}


public Action Hook_OnWeaponCanUse(int client, int weapon)
{
	if (g_bInvisible[client])
	{
		char sClassname[32];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		if (!StrEqual(sClassname, "weapon_knife"))
		return Plugin_Handled;
	}

	if (g_bFly[client])
	{
		char sClassname[32];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		if (!StrEqual(sClassname, "weapon_knife"))
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


public int OnAvailableLR(int Announced)
{
	g_bIsLR = true;

	if (gc_bBuyOnLR.BoolValue)
	{
		g_bAllowBuy = false;
	}

	for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, false)) if (GetClientTeam(i) == CS_TEAM_T && gc_bEnable.BoolValue)
	{
		if (GetAllPlayersCount() >= gc_iMinPlayersToGetCredits.IntValue) 
		{
			if (IsPlayerReservationAdmin(i) && gc_iCreditsVIPLR.IntValue != 0)
			{
				Forward_OnSetCredits(i,(Forward_OnGetCredits(i)+gc_iCreditsVIPLR.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsVIPLR.IntValue);
				
				if (gc_bNotification.BoolValue) CPrintToChat(i, "%t %t", "shop_tag", "shop_lastrequest", Forward_OnGetCredits(i), gc_iCreditsVIPLR.IntValue);
			}
			else if (gc_iCreditsLR.IntValue != 0)
			{
				Forward_OnSetCredits(i,(Forward_OnGetCredits(i)+gc_iCreditsLR.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsLR.IntValue);
				
				if (gc_bNotification.BoolValue) CPrintToChat(i, "%t %t", "shop_tag", "shop_lastrequest", Forward_OnGetCredits(i), gc_iCreditsLR.IntValue);
			}
		}
		if (gc_bRemoveOnLR.BoolValue)
		{
			SetEntityGravity(i, 1.0);
			ResetPlayer(i);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
}


public void SJD_DoorsOpened(int caller, int activator)
{
	if (gc_bBuyTimeCells.BoolValue && g_bAllowBuy)
	{
		g_bAllowBuy = false;
		CPrintToChatAll("%t %t", "shop_tag", "shop_buytime");
	}

	g_bCellsOpen = true;
}


public void SJD_DoorsClosed(int caller, int activator)
{
	g_bCellsOpen = false;
}


public void OnEntityDestroyed(int entity)
{
	if (!IsValidEdict(entity)) return;

	int index = FindValueInArray(g_hThrownKnives, EntIndexToEntRef(entity));
	if (index != -1)
	{
		RemoveFromArray(g_hThrownKnives, index);
	}
}


/******************************************************************************
                   FUNCTIONS
******************************************************************************/


void DealDamage(int victim,int  damage,int  attacker = 0,int  damagetype = DMG_GENERIC, char[] weapon = "")
{
	if (victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		int EntityPointHurt = CreateEntityByName("point_hurt");
		if (EntityPointHurt != 0)
		{
			char sDamage[16];
			IntToString(damage, sDamage, sizeof(sDamage));

			char sDamageType[32];
			IntToString(damagetype, sDamageType, sizeof(sDamageType));

			DispatchKeyValue(victim, "targetname", "hurtme");
			DispatchKeyValue(EntityPointHurt, "DamageTarget", "hurtme");
			DispatchKeyValue(EntityPointHurt, "Damage", sDamage);
			DispatchKeyValue(EntityPointHurt, "DamageType", sDamageType);
			if (!StrEqual(weapon, ""))
			{
				DispatchKeyValue(EntityPointHurt, "classname", weapon);
			}
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt, "Hurt", (attacker != 0) ? attacker : -1);
			DispatchKeyValue(EntityPointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "donthurtme");

			RemoveEdict(EntityPointHurt);
		}
	}
}


public Action Hook_SetTransmit(int entity, int client)
{
	if (entity != client)
		return Plugin_Handled;

	return Plugin_Continue;
}


public Action ResetPlayer(int client)
{
	if (g_bFly[client])
	{
		g_bFly[client] = false;
		ClientCommand(client, "firstperson");
		SetEntityModel(client, g_sModelPathPrevious[client]);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}

	if (g_bFakeGuard[client])
	{
		g_bFakeGuard[client] = false;
		SetEntityModel(client, g_sModelPathPrevious[client]);
	}

	if (g_bInvisible[client])
	{
		g_bInvisible[client] = false;
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}

	if (gp_bCustomPlayerSkins)
	{
		UnhookWallhack(client);
	}

	if (gp_bMyIcons)
	{
		MyIcons_BlockClientIcon(client, false);
	}

	g_bRandomTP[client] = false;
	g_bNoDamage[client] = false;
	g_bPoison[client] = false;
	g_bVampire[client] = false;
	g_bTeleportSmoke[client] = false;
	g_bFireHE[client] = false;
	g_bSuperKnife[client] = false;
	g_bThrowingKnife[client] = false;
	g_bFroggyJump[client] = false;
	g_bWallhack[client] = false;
	g_bBhop[client] = false;
	g_bGravity[client] = false;
	g_bOneBulletAWP[client] = false;
	g_bOneMagDeagle[client] = false;
	g_bMolotov[client] = false;
	g_bHealth[client] = false;

	Forward_OnResetPlayer(client);
}


/******************************************************************************
                   MENU
******************************************************************************/


public Action Menu_OpenShop(int client)
{
	char info[124];
	Menu menu = CreateMenu(Handler_Menu_OpenShop);
	int iCredits = Forward_OnGetCredits(client);

	if (!g_bSale)
	{
		SetMenuTitle(menu, "%t","shop_menu_title", iCredits);
	}
	else
	{
		SetMenuTitle(menu, "%t\n%t","shop_menu_title", iCredits, "shop_menu_title_sale", gc_fSale.IntValue);
	}

	if (GetClientTeam(client) == CS_TEAM_T)
	{
		if (gp_bSmartJailDoors)
		{
			if (SJD_IsCurrentMapConfigured())
			{
				Format(info, sizeof(info), "%T","shop_menu_openjail", client, gc_iOpenCells.IntValue);
				if (iCredits >= gc_iOpenCells.IntValue && gc_iOpenCells.IntValue != 0 && g_bAllowBuy && !g_bCellsOpen && CheckVipFlag(client, g_sOpenCellsFlag)) AddMenuItem(menu, "Doors", info);
				else if (gc_iOpenCells.IntValue != 0 && CheckVipFlag(client, g_sOpenCellsFlag)) AddMenuItem(menu, "Doors", info, ITEMDRAW_DISABLED);
			}
		}

		Format(info, sizeof(info), "%T","shop_menu_heal", client, gc_iHeal.IntValue);
		if (gc_iHealOnlyTeam.IntValue >= 1 && iCredits >= gc_iHeal.IntValue && gc_iHeal.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sHealFlag)) AddMenuItem(menu, "Heal", info);
		else if (gc_iHealOnlyTeam.IntValue >= 1 && gc_iHeal.IntValue != 0 && CheckVipFlag(client, g_sHealFlag)) AddMenuItem(menu, "Heal", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_health", client, gc_iHealth.IntValue, gc_iHealthExtra.IntValue);
		if (gc_iHealthExtraOnlyTeam.IntValue >= 1 && iCredits >= gc_iHealth.IntValue && gc_iHealth.IntValue != 0 && g_bAllowBuy && !g_bHealth[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sHealthFlag)) AddMenuItem(menu, "Health", info);
		else if (gc_iHealthExtraOnlyTeam.IntValue >= 1 && gc_iHealth.IntValue != 0 && CheckVipFlag(client, g_sHealthFlag)) AddMenuItem(menu, "Health", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_revive", client, gc_iRevive.IntValue);
		if (gc_iReviveOnlyTeam.IntValue >= 1 && iCredits >= gc_iRevive.IntValue && gc_iRevive.IntValue != 0 && !IsPlayerAlive(client) && !g_bIsLR && GetAlivePlayersCount(GetClientTeam(client)) > 1 && CheckVipFlag(client, g_sReviveFlag)) AddMenuItem(menu, "Revive", info);
		else if (gc_iReviveOnlyTeam.IntValue >= 1 && gc_iRevive.IntValue != 0 && CheckVipFlag(client, g_sReviveFlag)) AddMenuItem(menu, "Revive", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_vampire", client, gc_iVampire.IntValue);
		if (iCredits >= gc_iVampire.IntValue && gc_iVampire.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sVampireFlag)) AddMenuItem(menu, "Vampire", info);
		else if (gc_iVampire.IntValue != 0 && CheckVipFlag(client, g_sVampireFlag)) AddMenuItem(menu, "Vampire", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_bhop", client, gc_iBhop.IntValue);
		if (gc_iBhopOnlyTeam.IntValue >= 1 && iCredits >= gc_iBhop.IntValue && gc_iBhop.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && !g_bFroggyJump[client] && CheckVipFlag(client, g_sBhopFlag)) AddMenuItem(menu, "Bhop", info);
		else if (gc_iBhopOnlyTeam.IntValue >= 1 && gc_iBhop.IntValue != 0 && CheckVipFlag(client, g_sBhopFlag)) AddMenuItem(menu, "Bhop", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_froggyjump", client, gc_iFroggyJump.IntValue);
		if (gc_iFroggyJumpOnlyTeam.IntValue >= 1 && iCredits >= gc_iFroggyJump.IntValue && gc_iFroggyJump.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && !g_bBhop[client] && CheckVipFlag(client, g_sFroggyJumpFlag)) AddMenuItem(menu, "FroggyJump", info);
		else if (gc_iFroggyJumpOnlyTeam.IntValue >= 1 && gc_iFroggyJump.IntValue != 0 && CheckVipFlag(client, g_sFroggyJumpFlag)) AddMenuItem(menu, "FroggyJump", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_gravity", client, gc_iGravity.IntValue);
		if (gc_iGravOnlyTeam.IntValue >= 1 && iCredits >= gc_iGravity.IntValue && gc_iGravity.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && !g_bGravity[client] && CheckVipFlag(client, g_sGravityFlag)) AddMenuItem(menu, "Gravity", info);
		else if (gc_iGravOnlyTeam.IntValue >= 1 && gc_iGravity.IntValue != 0 && CheckVipFlag(client, g_sGravityFlag)) AddMenuItem(menu, "Gravity", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_invisible", client, gc_iInvisible.IntValue, RoundToCeil(gc_fInvisibleTime.FloatValue));
		if (iCredits >= gc_iInvisible.IntValue && gc_iInvisible.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sInvisibleFlag)) AddMenuItem(menu, "Invisible", info);
		else if (gc_iInvisible.IntValue != 0 && CheckVipFlag(client, g_sInvisibleFlag))AddMenuItem(menu, "Invisible", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_nodamage", client, gc_iNoDamage.IntValue, RoundToCeil(gc_fNoDamageTime.FloatValue));
		if (gc_iNoDamageOnlyTeam.IntValue >= 1 && iCredits >= gc_iNoDamage.IntValue && gc_iNoDamage.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sNoDamageFlag)) AddMenuItem(menu, "NoDamage", info);
		else if (gc_iNoDamageOnlyTeam.IntValue >= 1 && gc_iNoDamage.IntValue != 0 && CheckVipFlag(client, g_sNoDamageFlag)) AddMenuItem(menu, "NoDamage", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_noclip", client, gc_iNoClip.IntValue, RoundToCeil(gc_fNoClipTime.FloatValue));
		if (iCredits >= gc_iNoClip.IntValue && gc_iNoClip.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sNoClipFlag)) AddMenuItem(menu, "NoClip", info);
		else if (gc_iNoClip.IntValue != 0 && CheckVipFlag(client, g_sNoClipFlag)) AddMenuItem(menu, "NoClip", info, ITEMDRAW_DISABLED);

		if (gp_bCustomPlayerSkins)
		{
			Format(info, sizeof(info), "%T","shop_menu_wallhack", client, gc_iWallhack.IntValue);
			if (gc_iWallhackOnlyTeam.IntValue >= 1 && iCredits >= gc_iWallhack.IntValue && gc_iWallhack.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sWallhackFlag)) AddMenuItem(menu, "Wallhack", info);
			else if (gc_iWallhackOnlyTeam.IntValue >= 1 && gc_iWallhack.IntValue != 0 && CheckVipFlag(client, g_sWallhackFlag)) AddMenuItem(menu, "Wallhack", info, ITEMDRAW_DISABLED);
		}

		if (gp_bMyJBWarden)
		{
			if (g_bHandcuff != null)
			{
				if (g_bHandcuff.BoolValue)
				{
					Format(info, sizeof(info), "%T","shop_menu_paperclip", client, gc_iPaperClip.IntValue, gc_iPaperClipAmount.IntValue);
					if (iCredits >= gc_iPaperClip.IntValue && gc_iPaperClip.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sPaperClipFlag)) AddMenuItem(menu, "PaperClip", info);
					else if (gc_iPaperClip.IntValue != 0 && CheckVipFlag(client, g_sPaperClipFlag)) AddMenuItem(menu, "PaperClip", info, ITEMDRAW_DISABLED);
				}
			}
		}

		Format(info, sizeof(info), "%T","shop_menu_model", client, gc_iFakeModel.IntValue);
		if (iCredits >= gc_iFakeModel.IntValue && gc_iFakeModel.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sFakeModelFlag)) AddMenuItem(menu, "FakeModel", info);
		else if (gc_iFakeModel.IntValue != 0 && CheckVipFlag(client, g_sFakeModelFlag)) AddMenuItem(menu, "FakeModel", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_teleportsmoke", client, gc_iTeleportSmoke.IntValue);
		if (iCredits >= gc_iTeleportSmoke.IntValue && gc_iTeleportSmoke.IntValue != 0 && g_bAllowBuy && !g_bTeleportSmoke[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sTeleportSmokeFlag)) AddMenuItem(menu, "TeleportSmoke", info);
		else if (gc_iTeleportSmoke.IntValue != 0 && CheckVipFlag(client, g_sTeleportSmokeFlag)) AddMenuItem(menu, "TeleportSmoke", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_poisonsmoke", client, gc_iPoisonSmoke.IntValue);
		if (iCredits >= gc_iPoisonSmoke.IntValue && gc_iPoisonSmoke.IntValue != 0 && g_bAllowBuy && !g_bPoison[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sPoisonSmokeFlag)) AddMenuItem(menu, "PoisonSmoke", info);
		else if (gc_iPoisonSmoke.IntValue != 0 && CheckVipFlag(client, g_sPoisonSmokeFlag)) AddMenuItem(menu, "PoisonSmoke", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_firegrenade", client, gc_iFireHE.IntValue);
		if (iCredits >= gc_iFireHE.IntValue && gc_iFireHE.IntValue != 0 && g_bAllowBuy && !g_bFireHE[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sFireHEFlag)) AddMenuItem(menu, "FireGrenade", info);
		else if (gc_iFireHE.IntValue != 0 && CheckVipFlag(client, g_sFireHEFlag)) AddMenuItem(menu, "FireGrenade", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_awp", client, gc_iAWP.IntValue);
		if (iCredits >= gc_iAWP.IntValue && gc_iAWP.IntValue != 0 && g_bAllowBuy && !g_bOneBulletAWP[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sAWPFlag)) AddMenuItem(menu, "AWP", info);
		else if (gc_iAWP.IntValue != 0 && CheckVipFlag(client, g_sAWPFlag)) AddMenuItem(menu, "AWP", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_deagle", client, gc_iDeagle.IntValue);
		if (iCredits >= gc_iDeagle.IntValue && gc_iDeagle.IntValue != 0 && g_bAllowBuy && !g_bOneMagDeagle[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sDeagleFlag)) AddMenuItem(menu, "Deagle", info);
		else if (gc_iDeagle.IntValue != 0 && CheckVipFlag(client, g_sDeagleFlag)) AddMenuItem(menu, "Deagle", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_knife", client, gc_iKnife.IntValue);
		if (iCredits >= gc_iKnife.IntValue && gc_iKnife.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && !g_bSuperKnife[client] && CheckVipFlag(client, g_sKnifeFlag)) AddMenuItem(menu, "Knife", info);
		else if (gc_iKnife.IntValue != 0 && CheckVipFlag(client, g_sKnifeFlag)) AddMenuItem(menu, "Knife", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_throwingknife", client, gc_iThrowKnife.IntValue);
		if (iCredits >= gc_iThrowKnife.IntValue && gc_iThrowKnife.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && !g_bThrowingKnife[client] && CheckVipFlag(client, g_sThrowKnifeFlag)) AddMenuItem(menu, "ThrowingKnife", info);
		else if (gc_iThrowKnife.IntValue != 0 && CheckVipFlag(client, g_sThrowKnifeFlag)) AddMenuItem(menu, "ThrowingKnife", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_taser", client, gc_iTaser.IntValue);
		if (iCredits >= gc_iTaser.IntValue && gc_iTaser.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sTaserFlag)) AddMenuItem(menu, "Taser", info);
		else if (gc_iTaser.IntValue != 0 && CheckVipFlag(client, g_sTaserFlag)) AddMenuItem(menu, "Taser", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_molotov", client, gc_iMolotov.IntValue);
		if (iCredits >= gc_iMolotov.IntValue && gc_iMolotov.IntValue != 0 && g_bAllowBuy && !g_bMolotov[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sMolotovFlag)) AddMenuItem(menu, "Molotov", info);
		else if (gc_iMolotov.IntValue != 0 && CheckVipFlag(client, g_sMolotovFlag)) AddMenuItem(menu, "Molotov", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_bird", client, gc_iBird.IntValue);
		if (iCredits >= gc_iBird.IntValue && gc_iBird.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sBirdFlag)) AddMenuItem(menu, "Bird", info);
		else if (gc_iBird.IntValue != 0 && CheckVipFlag(client, g_sBirdFlag)) AddMenuItem(menu, "Bird", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T", "shop_menu_randomtp", client, gc_iRandomTP.IntValue);
		if (iCredits >= gc_iRandomTP.IntValue && gc_iRandomTP.IntValue != 0 && g_bAllowBuy && !g_bRandomTP[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sRandomTPFlag) && GetAlivePlayersCount(CS_TEAM_T) > 1) AddMenuItem(menu, "RandomTP", info);
		else if (gc_iRandomTP.IntValue != 0 && CheckVipFlag(client, g_sRandomTPFlag))AddMenuItem(menu, "RandomTP", info, ITEMDRAW_DISABLED);
	}
	else if (GetClientTeam(client) == CS_TEAM_CT)
	{
		Format(info, sizeof(info), "%T","shop_menu_heal", client, gc_iHeal.IntValue);
		if (gc_iHealOnlyTeam.IntValue <= 1 && iCredits >= gc_iHeal.IntValue && gc_iHeal.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sHealFlag)) AddMenuItem(menu, "Heal", info);
		else if (gc_iHealOnlyTeam.IntValue <= 1 && gc_iHeal.IntValue != 0 && CheckVipFlag(client, g_sHealFlag)) AddMenuItem(menu, "Heal", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_health", client, gc_iHealth.IntValue, gc_iHealthExtra.IntValue);
		if (gc_iHealthExtraOnlyTeam.IntValue <= 1 && iCredits >= gc_iHealth.IntValue && gc_iHealth.IntValue != 0 && g_bAllowBuy && !g_bHealth[client] && IsPlayerAlive(client) && CheckVipFlag(client, g_sHealthFlag)) AddMenuItem(menu, "Health", info);
		else if (gc_iHealthExtraOnlyTeam.IntValue <= 1 && gc_iHealth.IntValue != 0 && CheckVipFlag(client, g_sHealthFlag)) AddMenuItem(menu, "Health", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_revive", client, gc_iRevive.IntValue);
		if (gc_iReviveOnlyTeam.IntValue <= 1 && iCredits >= gc_iRevive.IntValue && gc_iRevive.IntValue != 0 && !IsPlayerAlive(client) && !g_bIsLR && GetAlivePlayersCount(GetClientTeam(client)) > 1 && CheckVipFlag(client, g_sReviveFlag)) AddMenuItem(menu, "Revive", info);
		else if (gc_iReviveOnlyTeam.IntValue <= 1 && gc_iRevive.IntValue != 0 && CheckVipFlag(client, g_sReviveFlag)) AddMenuItem(menu, "Revive", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_bhop", client, gc_iBhop.IntValue);
		if (gc_iBhopOnlyTeam.IntValue <= 1 && iCredits >= gc_iBhop.IntValue && gc_iBhop.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && !g_bFroggyJump[client] && CheckVipFlag(client, g_sBhopFlag)) AddMenuItem(menu, "Bhop", info);
		else if (gc_iBhopOnlyTeam.IntValue <= 1 && gc_iBhop.IntValue != 0 && CheckVipFlag(client, g_sBhopFlag)) AddMenuItem(menu, "Bhop", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_froggyjump", client, gc_iFroggyJump.IntValue);
		if (gc_iFroggyJumpOnlyTeam.IntValue <= 1 && iCredits >= gc_iFroggyJump.IntValue && gc_iFroggyJump.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && !g_bBhop[client] && CheckVipFlag(client, g_sFroggyJumpFlag)) AddMenuItem(menu, "FroggyJump", info);
		else if (gc_iFroggyJumpOnlyTeam.IntValue <= 1 && gc_iFroggyJump.IntValue != 0 && CheckVipFlag(client, g_sFroggyJumpFlag)) AddMenuItem(menu, "FroggyJump", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_gravity", client, gc_iGravity.IntValue);
		if (gc_iGravOnlyTeam.IntValue <= 1 && iCredits >= gc_iGravity.IntValue && gc_iGravity.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sGravityFlag)) AddMenuItem(menu, "Gravity", info);
		else if (gc_iGravOnlyTeam.IntValue <= 1 && gc_iGravity.IntValue != 0 && CheckVipFlag(client, g_sGravityFlag)) AddMenuItem(menu, "Gravity", info, ITEMDRAW_DISABLED);

		Format(info, sizeof(info), "%T","shop_menu_nodamage", client, gc_iNoDamage.IntValue, RoundToCeil(gc_fNoDamageTime.FloatValue));
		if (gc_iNoDamageOnlyTeam.IntValue <= 1 && iCredits >= gc_iNoDamage.IntValue && gc_iNoDamage.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sNoDamageFlag)) AddMenuItem(menu, "NoDamage", info);
		else if (gc_iNoDamageOnlyTeam.IntValue <= 1 && gc_iNoDamage.IntValue != 0 && CheckVipFlag(client, g_sNoDamageFlag)) AddMenuItem(menu, "NoDamage", info, ITEMDRAW_DISABLED);

		if (gp_bCustomPlayerSkins)
		{
			Format(info, sizeof(info), "%T","shop_menu_wallhack", client, gc_iWallhack.IntValue);
			if (gc_iWallhackOnlyTeam.IntValue <= 1 && iCredits >= gc_iWallhack.IntValue && gc_iWallhack.IntValue != 0 && g_bAllowBuy && IsPlayerAlive(client) && CheckVipFlag(client, g_sWallhackFlag)) AddMenuItem(menu, "Wallhack", info);
			else if (gc_iWallhackOnlyTeam.IntValue <= 1 && gc_iWallhack.IntValue != 0 && CheckVipFlag(client, g_sWallhackFlag)) AddMenuItem(menu, "Wallhack", info, ITEMDRAW_DISABLED);
		}
	}

	Call_StartForward(gF_hOnShopMenu);
	Call_PushCell(client);
	Call_PushCell(menu);
	Call_Finish();

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}


public int Handler_Menu_OpenShop(Menu menu, MenuAction action, int client, int itemNum) 
{
	Call_StartForward(gF_hOnShopMenuHandler);
	Call_PushCell(menu);
	Call_PushCell(action);
	Call_PushCell(client);
	Call_PushCell(itemNum);
	Call_Finish();

	if (action == MenuAction_Select)
	{
		if (g_bAllowBuy && gc_bEnable.BoolValue)
		{
			if (gp_bMyJailBreak && !gc_bEventdays.BoolValue)
			{
				if (MyJailbreak_IsEventDayRunning())
				{
					CReplyToCommand(client, "%t %t", "shop_tag", "shop_disabled");
					return;
				}
			}

			char info[32];
			menu.GetItem(itemNum, info, sizeof(info));

			if (strcmp(info,"Invisible") == 0)
			{
				Item_Invisible(client, info);
			}
			else if (strcmp(info,"AWP") == 0)
			{
				Item_AWP(client, info);
			}
			else if (strcmp(info,"NoDamage") == 0)
			{
				Item_NoDamage(client, info);
			}
			else if (strcmp(info,"Doors") == 0)
			{
				Item_Doors(client, info);
			}
			else if (strcmp(info,"Vampire") == 0)
			{
				Item_Vampire(client, info);
			}
			else if (strcmp(info,"Health") == 0)
			{
				Item_Health(client, info);
			}
			else if (strcmp(info,"Deagle") == 0)
			{
				Item_Deagle(client, info);
			}
			else if (strcmp(info,"Knife") == 0)
			{
				Item_Knife(client, info);
			}
			else if (strcmp(info,"Heal") == 0)
			{
				Item_Heal(client, info);
			}
			else if (strcmp(info,"Molotov") == 0)
			{
				Item_Molotov(client, info);
			}
			else if (strcmp(info,"FakeModel") == 0)
			{
				Item_FakeModel(client, info);
			}
			else if (strcmp(info,"PoisonSmoke") == 0)
			{
				Item_PoisonSmoke(client, info);
			}
			else if (strcmp(info,"Bird") == 0)
			{
				Item_Bird(client, info);
			}
			else if (strcmp(info,"TeleportSmoke") == 0)
			{
				Item_TeleportSmoke(client, info);
			}
			else if (strcmp(info,"FireGrenade") == 0)
			{
				Item_FireGrenade(client, info);
			}
			else if (strcmp(info,"Bhop") == 0)
			{
				Item_Bhop(client, info);
			}
			else if (strcmp(info,"Gravity") == 0)
			{
				Item_Gravity(client, info);
			}
			else if (strcmp(info,"Taser") == 0)
			{
				Item_Taser(client, info);
			}
			else if (strcmp(info,"NoClip") == 0)
			{
				Item_NoClip(client, info);
			}
			else if (strcmp(info,"Revive") == 0)
			{
				Item_Revive(client, info);
			}
			else if (strcmp(info,"Wallhack") == 0)
			{
				Item_Wallhack(client, info);
			}
			else if (strcmp(info,"ThrowingKnife") == 0)
			{
				Item_ThrowingKnife(client, info);
			}
			else if (strcmp(info,"FroggyJump") == 0)
			{
				Item_FroggyJump(client, info);
			}
			else if (strcmp(info,"PaperClip") == 0)
			{
				Item_PaperClip(client, info);
			}
			else if (strcmp(info, "RandomTP") == 0)
			{
				Item_RandomTP(client, info);
			}

			if (!gc_bClose.BoolValue)
			{
				Menu_OpenShop(client);
			}
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_buytime");
	}
}


/******************************************************************************
                   'ITEMS'
******************************************************************************/


void Item_Invisible(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iInvisible.IntValue)
		{
			SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
			g_bInvisible[client] = true;
			CreateTimer(gc_fInvisibleTime.FloatValue, Timer_Invisible, GetClientUserId(client));
			
			StripAllPlayerWeapons(client);
			GivePlayerItem(client, "weapon_knife");
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iInvisible.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			if (gp_bMyIcons) MyIcons_BlockClientIcon(client, true);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_invisible", RoundToCeil(gc_fInvisibleTime.FloatValue));
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iInvisible.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Invisible", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iInvisible.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_AWP(int client, char[] name)
{
	if (g_bOneBulletAWP[client])
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_max");
	}
	else if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iAWP.IntValue)
		{
			int weapon;
			if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY)) != -1)   // if player has already a weapon
			{
				SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
				if (gc_bRemoveWeapon.BoolValue) AcceptEntityInput(weapon, "Kill");
			}
			int iAWP = GivePlayerItem(client, "weapon_awp");
			g_bOneBulletAWP[client] = true;
			SetPlayerAmmo(client, iAWP, 1, 0);
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iAWP.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_awp");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iAWP.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: AWP", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iAWP.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_NoDamage(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iNoDamage.IntValue)
		{
			g_bNoDamage[client] = true;
			CreateTimer(gc_fNoDamageTime.FloatValue, Timer_NoDamage, GetClientUserId(client));
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iNoDamage.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_nodamage", RoundToCeil(gc_fNoDamageTime.FloatValue));
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iNoDamage.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: No Damage", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iNoDamage.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Doors(int client, char[] name)
{
	if (!g_bCellsOpen)
	{
		if (Forward_OnGetCredits(client) >= gc_iOpenCells.IntValue)
		{
			SJD_OpenDoors();
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iOpenCells.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_opencell");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iOpenCells.IntValue);
			CPrintToChatAll("%t %t", "shop_tag", "shop_opencellall", client);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Open cells", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iOpenCells.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alreadyopen");
}


void Item_Vampire(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iVampire.IntValue)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", gc_fVampireSpeed.FloatValue);
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iVampire.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			g_bVampire[client] = true;
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_vapire");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iVampire.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Vampire", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iVampire.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Health(int client, char[] name)
{
	if (g_bHealth[client])
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_max");
	}
	else if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iHealth.IntValue)
		{
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iHealth.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			int health = (GetClientHealth(client) + gc_iHealthExtra.IntValue);
			SetEntityHealth(client, health);
			GivePlayerItem(client, "_assaultsuit");
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
			g_bHealth[client] = true;
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_health", gc_iHealthExtra.IntValue);
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iHealth.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Health", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iHealth.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Deagle(int client, char[] name)
{
	if (g_bOneMagDeagle[client])
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_max");
	}
	else if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iDeagle.IntValue)
		{
			int weapon;
			if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != -1)   // if player has already a weapon
			{
				SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
				if (gc_bRemoveWeapon.BoolValue) AcceptEntityInput(weapon, "Kill");
			}
			int iDeagle = GivePlayerItem(client, "weapon_deagle");
			g_bOneMagDeagle[client] = true;
			SetPlayerAmmo(client, iDeagle, 7, 0);
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iDeagle.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_deagle");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iDeagle.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Deagle", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iDeagle.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Knife(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iKnife.IntValue)
		{
			int currentknife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			if (IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(client, currentknife);
				RemoveEdict(currentknife);
			}
			GivePlayerItem(client, "weapon_knifegg");
			
			g_bSuperKnife[client] = true;
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iKnife.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_knife");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iKnife.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: One hit knife", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iKnife.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Heal(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iHeal.IntValue)
		{
			int health = GetEntProp(client, Prop_Send, "m_iHealth");
			
			if (health >= 100)
			{
				CPrintToChat(client, "%t %t", "shop_tag", "shop_fulllive");
			}
			else
			{
				SetEntityHealth(client, 100);
				Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iHeal.IntValue));
				Forward_OnPlayerBuyItem(client, name);
				
				EmitSoundToAll("medicsound/medic.wav");
				CPrintToChat(client, "%t %t", "shop_tag", "shop_heal");
				CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iHeal.IntValue);
				if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: heal", client);
			}
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iHeal.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Molotov(int client, char[] name)
{
	if (g_bMolotov[client])
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_max");
	}
	else if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iMolotov.IntValue)
		{
			GivePlayerItem(client, "weapon_molotov");
			GivePlayerItem(client, "weapon_flashbang");
			GivePlayerItem(client, "weapon_flashbang");
			g_bMolotov[client] = true;
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iMolotov.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_molotov");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iMolotov.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Molotov", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iMolotov.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_FakeModel(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iFakeModel.IntValue)
		{
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iFakeModel.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			g_bFakeGuard[client] = true;
			
			GetEntPropString(client, Prop_Data, "m_ModelName", g_sModelPathPrevious[client], sizeof(g_sModelPathPrevious[]));
			SetEntityModel(client, g_sModelPathFakeGuard);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_model");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iFakeModel.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: FakeModel", client);
			if (gp_bMyIcons) MyIcons_BlockClientIcon(client, true);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iFakeModel.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_PoisonSmoke(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iPoisonSmoke.IntValue)
		{
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iPoisonSmoke.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			GivePlayerItem(client, "weapon_smokegrenade");
			
			g_bPoison[client] = true;
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_poisensmoke");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iPoisonSmoke.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Poison smoke", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iPoisonSmoke.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Bird(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iBird.IntValue)
		{
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iBird.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			SetEntityMoveType(client, MOVETYPE_FLY);
			ClientCommand(client, "thirdperson");
			GetEntPropString(client, Prop_Data, "m_ModelName", g_sModelPathPrevious[client], sizeof(g_sModelPathPrevious[]));
			if (gc_iBirdMode.IntValue == 1) SetEntityModel(client, "models/chicken/chicken.mdl");
			if (gc_iBirdMode.IntValue == 2) SetEntityModel(client, "models/pigeon.mdl");
			if (gc_iBirdMode.IntValue == 3) SetEntityModel(client, "models/crow.mdl");
			
			g_bFly[client] = true;
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_bird");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iBird.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: be a bird", client);
			if (gp_bMyIcons) MyIcons_BlockClientIcon(client, true);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iBird.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_TeleportSmoke(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iTeleportSmoke.IntValue)
		{
			GivePlayerItem(client, "weapon_smokegrenade");
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iTeleportSmoke.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			g_bTeleportSmoke[client] = true;
			CPrintToChat(client, "%t %t", "shop_tag", "shop_teleportsmoke");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iTeleportSmoke.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Teleport smoke", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iTeleportSmoke.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_FireGrenade(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iFireHE.IntValue)
		{
			GivePlayerItem(client, "weapon_hegrenade");
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iFireHE.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			g_bFireHE[client] = true;
			CPrintToChat(client, "%t %t", "shop_tag", "shop_firegrenade");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iFireHE.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Fire HE", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iFireHE.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Gravity(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iGravity.IntValue)
		{
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iGravity.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			g_bGravity[client] = true;
			SetEntityGravity(client, gc_fGravValue.FloatValue);
			CPrintToChat(client, "%t %t", "shop_tag", "shop_gravity");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iGravity.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Gravity", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iGravity.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Bhop(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iBhop.IntValue)
		{
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iBhop.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			g_bBhop[client] = true;
			CPrintToChat(client, "%t %t", "shop_tag", "shop_bhop");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iBhop.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Bhop", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iBhop.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Taser(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iTaser.IntValue)
		{
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iTaser.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			int iTaser = GivePlayerItem(client, "weapon_taser");
			SetEntProp(iTaser, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
			SetEntProp(iTaser, Prop_Send, "m_iClip1", 3);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_taser");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iTaser.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Taser", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iTaser.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_NoClip(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iNoClip.IntValue)
		{
			g_bNoClip[client] = true;
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			CreateTimer(gc_fNoClipTime.FloatValue, Timer_NoClip, GetClientUserId(client));
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iNoClip.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_noclip", RoundToCeil(gc_fNoClipTime.FloatValue));
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iNoClip.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: No clip", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iNoClip.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_ThrowingKnife(int client, char[] name)
{
	if (g_bThrowingKnife[client])
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_max");
	}
	else if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iThrowKnife.IntValue)
		{
			g_bThrowingKnife[client] = true;
			g_iKnifesThrown[client] = 0;
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iThrowKnife.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_throwingknife");
			CPrintToChat(client, "%t %t", "shop_tag", "shop_costs", Forward_OnGetCredits(client), gc_iThrowKnife.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Throw knife", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iThrowKnife.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Revive(int client, char[] name)
{
	if (!IsPlayerAlive(client))
	{
		if (!g_bIsLR && GetAlivePlayersCount(GetClientTeam(client)) > 1)
		{
			if (Forward_OnGetCredits(client) >= gc_iRevive.IntValue)
			{
				CS_RespawnPlayer(client);
				
				Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iRevive.IntValue));
				Forward_OnPlayerBuyItem(client, name);
				
				CPrintToChatAll("%t %t", "shop_tag", "shop_revived", client);
				if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Revive", client);
			}
			else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iRevive.IntValue);
		}
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_dead");
}


void Item_FroggyJump(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iFroggyJump.IntValue)
		{
			g_bFroggyJump[client] = true;
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iFroggyJump.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_froggyjump", client);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: FroggyJump", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iFroggyJump.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_PaperClip(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iPaperClip.IntValue)
		{
			warden_handcuffs_givepaperclip(client, gc_iPaperClipAmount.IntValue);
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iPaperClip.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_paperclip", gc_iPaperClipAmount.IntValue);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Paperclip", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iPaperClip.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}


void Item_Wallhack(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iWallhack.IntValue)
		{
			g_bWallhack[client] = true;
			
			for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) Setup_WallhackSkin(i);
			
			CreateTimer (gc_fWallhackTime.FloatValue, Timer_Wallhack, GetClientUserId(client));
			
			Forward_OnSetCredits(client,(Forward_OnGetCredits(client)-gc_iWallhack.IntValue));
			
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_wallhack", client);
			if (gc_bLogging.BoolValue) LogToFileEx(g_sPurchaseLogFile, "Player %L bought: Wallhack", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iWallhack.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive");
}

//by Hexer10
void Item_RandomTP(int client, char[] name)
{
	if (IsPlayerAlive(client))
	{
		if (Forward_OnGetCredits(client) >= gc_iRandomTP.IntValue)
		{
			if (GetAlivePlayersCount(CS_TEAM_T) < 2)
			{
				CPrintToChat(client, "%t %t", "shop_tag", "shop_randomtp_fail");
				return;
			}
			
			int iRandomClient = GetRandomPlayer(CS_TEAM_T);
			while (client == iRandomClient)
			{
				iRandomClient = GetRandomPlayer(CS_TEAM_T);
			}
			
			float origin[3];
			GetClientAbsOrigin(iRandomClient, origin);
			float location[3];
			GetClientEyePosition(iRandomClient, location);
			float ang[3];
			GetClientEyeAngles(iRandomClient, ang);
			float location2[3];
			location2[0] = (location[0]+(100*((Cosine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
			location2[1] = (location[1]+(100*((Sine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
			ang[0] -= (2*ang[0]);
			location2[2] = origin[2] += 5.0;
			
			TeleportEntity(client, location2, NULL_VECTOR, NULL_VECTOR);
			
			Forward_OnSetCredits(client, (Forward_OnGetCredits(client) - gc_iRandomTP.IntValue));
			Forward_OnPlayerBuyItem(client, name);
			
			CPrintToChat(client, "%t %t", "shop_tag", "shop_randomtp", iRandomClient);
			CPrintToChat(iRandomClient, "%t %t", "shop_tag", "shop_randomtp_teleported", client);
			
			g_bRandomTP[client] = true;
			
			if (gc_bLogging.BoolValue)LogToFileEx(g_sPurchaseLogFile, "Player %L bought: RandomTP", client);
		}
		else CPrintToChat(client, "%t %t", "shop_tag", "shop_missingcredits", Forward_OnGetCredits(client), gc_iRandomTP.IntValue);
	}
	else CPrintToChat(client, "%t %t", "shop_tag", "shop_alive"); 
}


// Perpare client for wallhack
void Setup_WallhackSkin(int client)
{
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));
	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	
	if (iSkin == -1)
		return;
	
	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_Wallhack))
		Setup_Wallhack(iSkin, client);
}


// set client wallhacked
void Setup_Wallhack(int iSkin, int client)
{
	int iOffset;
	
	if ((iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
		return;
	
	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	int iRed = 60;
	int iGreen = 60;
	int iBlue = 60;
	
	if (GetClientTeam(client) == CS_TEAM_CT) iBlue = 240;
	if (GetClientTeam(client) == CS_TEAM_T) iRed = 240;
	
	SetEntData(iSkin, iOffset, iRed, _, true);
	SetEntData(iSkin, iOffset + 1, iGreen, _, true);
	SetEntData(iSkin, iOffset + 2, iBlue, _, true);
	SetEntData(iSkin, iOffset + 3, 255, _, true);
}


// Who can see wallhack if vaild
public Action OnSetTransmit_Wallhack(int iSkin, int client)
{
	if (!IsPlayerAlive(client))
		return Plugin_Handled;
	
	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		if (!CPS_HasSkin(i))
			continue;
		
		if (GetClientTeam(i) == GetClientTeam(client))
			continue;
		
		if (EntRefToEntIndex(CPS_GetSkin(i)) != iSkin)
			continue;
		
		if (g_bWallhack[client])
		
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}


// remove wallhack
void UnhookWallhack(int client)
{
	if (IsValidClient(client, true, true))
	{
		char sModel[PLATFORM_MAX_PATH];
		GetClientModel(client, sModel, sizeof(sModel));
		SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmit_Wallhack);
	}
}


// awesome code by bacardi https:// forums.alliedmods.net/showthread.php?t=269846
public Action KnifeHit(int knife, int other)
{
	if ((0 < other <= MaxClients) && GetClientTeam(other) != CS_TEAM_T) // Hits player index
	{
		int victim = other;
		
		SetVariantString("csblood");
		AcceptEntityInput(knife, "DispatchEffect");
		AcceptEntityInput(knife, "Kill");
		
		int attacker = GetEntPropEnt(knife, Prop_Send, "m_hThrower");
		int inflictor = GetPlayerWeaponSlot(attacker, CS_SLOT_KNIFE);
		
		if (inflictor == -1)
		{
			inflictor = attacker;
		}
		
		float victimeye[3];
		GetClientEyePosition(victim, victimeye);
		
		float damagePosition[3];
		float damageForce[3];
		
		GetEntPropVector(knife, Prop_Data, "m_vecOrigin", damagePosition);
		GetEntPropVector(knife, Prop_Data, "m_vecVelocity", damageForce);
		
		if (GetVectorLength(damageForce) == 0.0) // knife movement stop
		{
			return;
		}
		
		// damage values and type
		float damage = 200.0;
		int dmgtype = DMG_SLASH|DMG_NEVERGIB;
		
		// create damage
		SDKHooks_TakeDamage(victim, inflictor, attacker, damage, dmgtype, knife, damageForce, damagePosition);
		
		// blood effect
		int color[] = {255, 0, 0, 255};
		float dir[3];
		
		TE_SetupBloodSprite(damagePosition, dir, color, 1, PrecacheDecal("sprites/blood.vmt"), PrecacheDecal("sprites/blood.vmt"));
		TE_SendToAll(0.0);
		
		// ragdoll effect
		int ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
		if (ragdoll != -1)
		{
			ScaleVector(damageForce, 50.0);
			damageForce[2] = FloatAbs(damageForce[2]); // push up!
			SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", damageForce);
			SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", damageForce);
		}
	}
	else if (FindValueInArray(g_hThrownKnives, EntIndexToEntRef(other)) != -1) // knives collide
	{
		SDKUnhook(knife, SDKHook_Touch, KnifeHit);
		float pos[3], dir[3];
		GetEntPropVector(knife, Prop_Data, "m_vecOrigin", pos);
		TE_SetupArmorRicochet(pos, dir);
		TE_SendToAll(0.0);
		
		DispatchKeyValue(knife, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(knife, "FireUser1");
	}
}


/******************************************************************************
                   TIMER
******************************************************************************/


public Action Timer_BuyTime(Handle timer)
{
	if (g_bAllowBuy && gc_bEnable.BoolValue)
	{
		g_bAllowBuy = false;
		CPrintToChatAll("%t %t", "shop_tag", "shop_buytime");
	}
}


public Action Timer_NoClip(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client, true, true))
		return Plugin_Handled;

	g_bNoClip[client] = false;
	SetEntityMoveType(client, MOVETYPE_WALK);
	CPrintToChat(client, "%t %t", "shop_tag", "shop_noclipend");
	
	if (IsClientStuck(client))
	{
		if (gc_bNoClipKill.BoolValue) CreateTimer(3.0, Timer_StuckNoClip, userid);
		CPrintToChatAll("%t %t", "shop_tag", "shop_noclipstuck", client);
	}

	return Plugin_Stop;
}

public Action Timer_StuckNoClip(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client, true, true))
		return Plugin_Handled;

	if (GetCommandFlags("sm_timebomb") != INVALID_FCVAR_FLAGS)
	{
		ServerCommand("sm_timebomb %N 1", client);
	}
	else ForcePlayerSuicide(client);

	return Plugin_Stop;
}


public Action Timer_WelcomeMessage(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client, true, true))
		return Plugin_Handled;

	if (gc_bWelcome.BoolValue && gc_bEnable.BoolValue)
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_welcome");
	}

	return Plugin_Handled;
}


public Action Timer_DeathMessage(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client, true, true))
		return Plugin_Handled;

	if (!g_bIsLR && GetAlivePlayersCount(GetClientTeam(client)) > 1 && gc_bEnable.BoolValue)
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_revivehint", gc_iRevive.IntValue);
	}

	return Plugin_Handled;
}


public Action Timer_Delete(Handle timer, any entity)
{
	if (IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "kill");
	}
}


public Action Timer_CheckDamage(Handle timer, any iEntity)
{
	if (!IsValidEdict(iEntity))
		return Plugin_Stop;

	int client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

	if (!IsValidClient(client, true, false))
		return Plugin_Stop;

	float fSmokeOrigin[3], fOrigin[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fSmokeOrigin);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true, true))
			continue;

		if (GetClientTeam(i) != GetClientTeam(client))
		{
			GetClientAbsOrigin(i, fOrigin);
			if (GetVectorDistance(fSmokeOrigin, fOrigin) <= 220)
			{
				DealDamage(i, 75, client, DMG_POISON, "weapon_smokegrenade");
			}
		}
	}
	return Plugin_Continue;
}


public Action Timer_Credits (Handle timer)
{
	if (!gc_bEnable.BoolValue)
		return Plugin_Continue;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true, true))
			continue;

		if (GetClientTeam(i) == CS_TEAM_SPECTATOR)
			continue;

		if (GetAllPlayersCount() >= gc_iMinPlayersToGetCredits.IntValue && (gc_bCreditsWarmup.BoolValue || GameRules_GetProp("m_bWarmupPeriod") != 1)) 
		{
			if (IsPlayerReservationAdmin(i))
			{
				Forward_OnSetCredits(i,(Forward_OnGetCredits(i)+gc_iCreditsVIPPerTime.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsVIPPerTime.IntValue);
				if (gc_bNotification.BoolValue)
				{
					CPrintToChat(i, "%t %t", "shop_tag", "shop_playtime", gc_iCreditsVIPPerTime.IntValue);
				}
			}
			else
			{
				Forward_OnSetCredits(i,(Forward_OnGetCredits(i)+gc_iCreditsTime.IntValue));
				Forward_OnPlayerGetCredits(i, gc_iCreditsTime.IntValue);
				if (gc_bNotification.BoolValue)
				{
					CPrintToChat(i, "%t %t", "shop_tag", "shop_playtime", gc_iCreditsTime.IntValue);
				}
			}
		}
	}

	return Plugin_Continue;
}


public Action Timer_NoDamage(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_unnodamage");
		g_bNoDamage[client] = false;
	}
	
}

public Action Timer_Wallhack(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (IsValidClient(client, true, false))
	{
		CPrintToChat(client, "%t %t", "shop_tag", "shop_unwallhack");
		g_bWallhack[client] = false;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (g_bWallhack[i])
			continue;

		UnhookWallhack(i);
	}
}


public Action Timer_Invisible(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client, true, false))
		return Plugin_Stop;

	g_bInvisible[client] = false;
	CPrintToChat(client, "%t %t", "shop_tag", "shop_visible");

	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);

	if (gp_bMyIcons)
	{
		MyIcons_BlockClientIcon(client, false);
	}

	return Plugin_Stop;
}


// awesome code by bacardi https:// forums.alliedmods.net/showthread.php?t=269846
public Action Timer_CreateKnife(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client, true, true))
		return Plugin_Handled;

	g_hTimerDelay[client] = INVALID_HANDLE;
	
	int slot_knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	int knife = CreateEntityByName("smokegrenade_projectile");
	
	g_iKnifesThrown[client]++;
	
	if (g_iKnifesThrown[client] > gc_iThrowKnifeCount.IntValue)
		return Plugin_Handled;
	
	if (knife == -1 || !DispatchSpawn(knife))
	{
		return Plugin_Handled;
	}
	
	// owner
	int team = GetClientTeam(client);
	SetEntPropEnt(knife, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropEnt(knife, Prop_Send, "m_hThrower", client);
	SetEntProp(knife, Prop_Send, "m_iTeamNum", team);
	
	// player knife model
	char model[PLATFORM_MAX_PATH];
	if (slot_knife != -1)
	{
		GetEntPropString(slot_knife, Prop_Data, "m_ModelName", model, sizeof(model));
		if (ReplaceString(model, sizeof(model), "v_knife_", "w_knife_", true) != 1)
		{
			model[0] = '\0';
		}
		else if (ReplaceString(model, sizeof(model), ".mdl", "_dropped.mdl", true) != 1)
		{
			model[0] = '\0';
		}
	}
	
	// model and size
	SetEntProp(knife, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntPropFloat(knife, Prop_Send, "m_flModelScale", 1.0);
	
	// knive elasticity
	SetEntPropFloat(knife, Prop_Send, "m_flElasticity", 0.2);
	// gravity
	SetEntPropFloat(knife, Prop_Data, "m_flGravity", 1.0);
	
	// Player origin and angle
	float origin[3], angle[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angle);
	
	// knive new spawn position and angle is same as player's
	float pos[3];
	GetAngleVectors(angle, pos, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(pos, 50.0);
	AddVectors(pos, origin, pos);
	
	// knive flying direction and speed/power
	float player_velocity[3], velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", player_velocity);
	GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(velocity, 2250.0);
	AddVectors(velocity, player_velocity, velocity);
	
	// spin knive
	float spin[] = {4000.0, 0.0, 0.0};
	SetEntPropVector(knife, Prop_Data, "m_vecAngVelocity", spin);
	
	// Stop grenade detonate and Kill knive after 1 - 30 sec
	SetEntProp(knife, Prop_Data, "m_nNextThinkTick", -1);
	char buffer[25];
	Format(buffer, sizeof(buffer), "!self,Kill,,%0.1f,-1", 1.5);
	DispatchKeyValue(knife, "OnUser1", buffer);
	AcceptEntityInput(knife, "FireUser1");
	
	int color[4] = {255, ...};
	TE_SetupBeamFollow(knife, PrecacheModel("effects/blueblacklargebeam.vmt"), 0, 0.5, 1.0, 0.1, 0, color);
	
	TE_SendToAll();
	
	// Throw knive!
	TeleportEntity(knife, pos, angle, velocity);
	SDKHookEx(knife, SDKHook_Touch, KnifeHit);
	
	PushArrayCell(g_hThrownKnives, EntIndexToEntRef(knife));

	return Plugin_Handled;
}


/******************************************************************************
                   MYSQL
******************************************************************************/


public void OnMapEnd ()
{
	if (g_hTimerCredits != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerCredits);
		g_hTimerCredits = INVALID_HANDLE;
	}
	if (!g_bDBConnected && gc_bMySQL.BoolValue)
		DB_Connect();
	
	for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, true))
	{
		if (gc_bMySQL.BoolValue) DB_WriteCredits(i);
		OnClientDisconnect(i);
	}
}


public void OnClientAuthorized(int client, const char[] auth)
{
	if (!g_bDBConnected && gc_bMySQL.BoolValue) DB_Connect();
	
	if (gc_bMySQL.BoolValue && !IsFakeClient(client))
	{
		DB_AddPlayer(client);
		DB_FetchCredits(client);
	}
}


public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) // EVENT OR FORWARD
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (gc_bMySQL.BoolValue && client > 0 && !IsFakeClient(client))
	{
		if (!g_bDBConnected && gc_bMySQL.BoolValue) DB_Connect();
		DB_WriteCredits(client);
	}
	if (gp_bCustomPlayerSkins) UnhookWallhack(client);
	return Plugin_Continue;
}


bool IsPlayerReservationAdmin(int client)
{
	if (CheckCommandAccess(client, "Admin_Reservation", ADMFLAG_RESERVATION, false))
	{
		return true;
	}
	return false;
}

/**
 * Attempts to connect to the database.
 * Creates the credits table (TABLE_NAME) ifneeded.
 * 'Cleans' the database eliminating players with a very small number of wins+losses. (meant to reduce database size)
 */
public void DB_Connect()
{
	char error[255];
	g_hDB = SQL_Connect("MyJailShop", true, error, sizeof(error));
	if (g_hDB == INVALID_HANDLE)
	{
		g_bDBConnected = false;
		LogError("Could not connect: %s", error);
	}
	else
	{
		// create the table
		SQL_LockDatabase(g_hDB);
		CreateTables();
		SQL_UnlockDatabase(g_hDB);
		g_bDBConnected = true;
	}
}

static void CreateTables()
{
	Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE if NOT EXISTS myjs_credits (accountID INT NOT NULL PRIMARY KEY default 0, steamid varchar(64) NOT NULL default '', name varchar(64) NOT NULL default '', credits INT NOT NULL default 0);");
	SQL_FastQuery(g_hDB, g_sSQLBuffer);
}

/**
 * Generic SQL threaded query error callback.
 */
public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!StrEqual("", error))
	{
		g_hDB = INVALID_HANDLE;
		g_bDBConnected = false;
		LogError("Last Connect SQL (error: %s)", error);
	}
}

/**
 * Adds a player, updating their name ifthey already exist, to the database.
 */
public void DB_AddPlayer(int client)
{
	if (g_hDB != INVALID_HANDLE)
	{
		int id = GetSteamAccountID(client);
		
		// player name
		char name[64];
		GetClientName(client, name, sizeof(name));
		char sanitized_name[64];
		SQL_EscapeString(g_hDB, name, sanitized_name, sizeof(name));
		
		// steam id
		char steamid[24];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		
		// insert ifnot already in the table
		Format(g_sSQLBuffer, sizeof(g_sSQLBuffer),
			"INSERT IGNORE INTO myjs_credits (accountID,steamid,name,credits) VALUES (%d, '%s', '%s', 0);", id, steamid, sanitized_name);
		SQL_TQuery(g_hDB, SQLErrorCheckCallback, g_sSQLBuffer);
		
		// update the player name
		Format(g_sSQLBuffer, sizeof(g_sSQLBuffer),
			"UPDATE myjs_credits SET name = '%s' WHERE accountID = %d", sanitized_name, id);
		SQL_TQuery(g_hDB, SQLErrorCheckCallback, g_sSQLBuffer);
	}
}

/**
 * Reads a player credits from the database.
 * Note that this is a *SLOW* operation and you should not do it during gameplay
 */
public void DB_FetchCredits(int client)
{
	int credits = 0;
	
	if (g_hDB != INVALID_HANDLE)
	{
		SQL_LockDatabase(g_hDB);
		Format(g_sSQLBuffer, sizeof(g_sSQLBuffer),
			"SELECT credits FROM myjs_credits WHERE accountID = %d", GetSteamAccountID(client));
		Handle query = SQL_Query(g_hDB, g_sSQLBuffer);
		
		if (query == INVALID_HANDLE)
		{
			char error[255];
			SQL_GetError(g_hDB, error, sizeof(error));
			LogError("Failed to query (error: %s)", error);
			g_bDBConnected = false;
			CloseHandle(g_hDB);
		}
		else if (SQL_FetchRow(query)) credits = SQL_FetchInt(query, 0);
		else LogMessage("Couldn't fetchcredits for %N, probably it is first connection of client", client);
		
		CloseHandle(query);
		SQL_UnlockDatabase(g_hDB);
	}
	g_iCredits[client] = credits;
}

/**
 * Writes the credits to the database.
 */


public void DB_WriteCredits(int client)
{
	Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "UPDATE myjs_credits set credits = %d WHERE accountID = %d", Forward_OnGetCredits(client), GetSteamAccountID(client));
	SQL_TQuery(g_hDB, SQLErrorCheckCallback, g_sSQLBuffer);
}


/******************************************************************************
                   NATIVES
******************************************************************************/


// Register Natives
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Forwards
	gF_hOnPlayerGetCredits = CreateGlobalForward("MyJailShop_OnPlayerGetCredits", ET_Ignore, Param_Cell, Param_Cell);
	gF_hOnPlayerBuyItem = CreateGlobalForward("MyJailShop_OnPlayerBuyItem", ET_Ignore, Param_Cell, Param_String);
	gF_hOnResetPlayer = CreateGlobalForward("MyJailShop_OnResetPlayer", ET_Ignore, Param_Cell);
	
	gF_hOnGetCredits = CreateGlobalForward("MyJailShop_OnGetCredits", ET_Event, Param_Cell);
	gF_hOnSetCredits = CreateGlobalForward("MyJailShop_OnSetCredits", ET_Event, Param_Cell, Param_Cell);
	gF_hOnShopMenuHandler= CreateGlobalForward("MyJailShop_OnShopMenuHandler", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	gF_hOnShopMenu = CreateGlobalForward("MyJailShop_OnShopMenu", ET_Ignore, Param_Cell, Param_Cell);
	
	// Natives
	CreateNative("MyJailShop_SetCredits", Native_SetCredits);
	CreateNative("MyJailShop_GetCredits", Native_GetCredits);
	CreateNative("MyJailShop_IsBuyTime", Native_BuyTime);
	
	
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Game is not supported. CS:GO ONLY");
	}
	
	RegPluginLibrary("myjailshop");
	
	return APLRes_Success;
}


public int Native_GetCredits(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	if (!IsValidClient(client, false, true))
	{
		return -1;
	}

	return Forward_OnGetCredits(client);
}

public int Native_BuyTime(Handle plugin, int argc)
{
	return g_bAllowBuy;
}


public int Native_SetCredits(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	if (!IsValidClient(client, false, true))
	{
		return;
	}

	int iCredits = GetNativeCell(2);
	if (0 > iCredits)
	{
		iCredits = 0;
	}

	if (iCredits > gc_iCreditsMax.IntValue)
	{
		iCredits = gc_iCreditsMax.IntValue;
	}

	Forward_OnSetCredits(client, iCredits);
	Forward_OnPlayerGetCredits(client, iCredits);
}


/******************************************************************************
                   FORWARDS CALL
******************************************************************************/


void Forward_OnPlayerGetCredits(int client, int extraCredits)
{
	Call_StartForward(gF_hOnPlayerGetCredits);
	Call_PushCell(client);
	Call_PushCell(extraCredits);
	Call_Finish();
}


void Forward_OnResetPlayer(int client)
{
	Call_StartForward(gF_hOnResetPlayer);
	Call_PushCell(client);
	Call_Finish();
}


void Forward_OnPlayerBuyItem(int client, char[] item)
{
	Call_StartForward(gF_hOnPlayerBuyItem);
	Call_PushCell(client);
	Call_PushString(item);
	Call_Finish();
}


int Forward_OnGetCredits(int client)
{
	int credits = 0;
	if (!gc_bCreditSystem.BoolValue)
	{
		Call_StartForward(gF_hOnGetCredits);
		Call_PushCell(client);
		Call_Finish(credits);
	}
	else credits = g_iCredits[client];
	return credits;
}

void Forward_OnSetCredits(int client, int credits)
{
	if (!gc_bCreditSystem.BoolValue)
	{
		Call_StartForward(gF_hOnSetCredits);
		Call_PushCell(client);
		Call_PushCell(credits);
		Call_Finish();
	}
	else g_iCredits[client] = credits;
}
