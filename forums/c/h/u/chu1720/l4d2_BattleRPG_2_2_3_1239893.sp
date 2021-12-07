/* L4D2 RPG Construction Kit by.#Zipcore */

#include <sourcemod>
#include <sdktools>

/* Number of Jobs (Change Jobnames in RPG-Menu) */
#define JOBMAX 13

/* Number of Items in Job Menu (Ammo not included! Change Itemnames & items!! in BuyShop-Menu ) */
#define ITEMMAX 12 

/* Plugin Info */
#define PLUGIN_VERSION "2.2.2"
#define PLUGIN_AUTHOR ".#Zipcore; Credits: chu1720 & Predailien12"
#define PLUGIN_NAME "Battle RPG 2"
#define PLUGIN_DESCRIPTION "L4D2 RPG Construction Kit"
#define PLUGIN_URL "http://forums.alliedmods.net/showthread.php?t=129588"

/* Identifications */
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8

/* Cvar Flags */
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo=
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/* Config */

new Handle:CfgCashLimit

new Handle:CfgExpChatEnable
new Handle:CfgExpLevelUp
new Handle:CfgExpTimer
new Handle:CfgExpMode

new Handle:CfgExpHealTeammate
new Handle:CfgExpReviveTeammate
new Handle:CfgExpReanimateTeammate
new Handle:CfgExpCommonKilled
new Handle:CfgExpBoomerKilled
new Handle:CfgExpChargerKilled
new Handle:CfgExpHunterKilled
new Handle:CfgExpJockeyKilled
new Handle:CfgExpSmokerKilled
new Handle:CfgExpSpitterKilled
new Handle:CfgExpTankMode
new Handle:CfgExpTankKilled
new Handle:CfgExpTankSurvived
new Handle:CfgExpWitchKilled
new Handle:CfgExpWitchSurvived

new Handle:CfgItemsJobEnable
new Handle:CfgItemsJobTimerEnable
new Handle:CfgItemsJobTimer
new Handle:CfgItemsJobOnLevelUp

new Handle:CfgItemsShopCost[ITEMMAX+1]

new Handle:CfgJobChatRemindJob
new Handle:CfgJobChatRemindJobTimer

new Handle:CfgJobReqLevel[JOBMAX+1]
new Handle:CfgJobCash[JOBMAX+1]
new Handle:CfgJobHealthBasis[JOBMAX+1]
new Handle:CfgJobHealthBonus[JOBMAX+1]
new Handle:CfgJobAgility[JOBMAX+1]
new Handle:CfgJobStrength[JOBMAX+1]
new Handle:CfgJobEndurance[JOBMAX+1]

new Handle:CfgMenuRPGTimer
new Handle:CfgMenuRPGTimerEnable
new Handle:CfgMenuRPGBackPack

new Handle:CfgSaveToFileMode

new Handle:CfgSkillMode
new Handle:CfgSkillHealthMode

new Handle:CfgSkillHealthLimit
new Handle:CfgSkillAgilitySpeedLimit
new Handle:CfgSkillAgilityGravityLimit
new Handle:CfgSkillStrengthLimit
new Handle:CfgSkillEnduranceLimit
new Handle:CfgSkillEnduranceReflectOnly
new Handle:CfgSkillEnduranceShieldLimit

new ClientLevel[MAXPLAYERS+1]
new ClientLevelTemp[MAXPLAYERS+1]
new ClientLevelJob[MAXPLAYERS+1][JOBMAX+1]
new ClientCash[MAXPLAYERS+1]

new ClientEXP[MAXPLAYERS+1]
new ClientJob[MAXPLAYERS+1]
new ClientLockJob[MAXPLAYERS+1]
new ClientLockAgiligy[MAXPLAYERS+1]

new ClientHealBonus[MAXPLAYERS+1]
new ClientStrength[MAXPLAYERS+1]
new ClientAgility[MAXPLAYERS+1]
new ClientEndurance[MAXPLAYERS+1]

new ClientJobConfirm[MAXPLAYERS+1]

new MZombieClass
new MOffset

new Handle:TRemindJob[MAXPLAYERS+1]
new Handle:TOpenRPGMenu[MAXPLAYERS+1]
new Handle:TCheckExp[MAXPLAYERS+1]
new Handle:TGiveItems[MAXPLAYERS+1]

new WitchTargetBuffer[MAXPLAYERS+1]

new Handle:RPGSave = INVALID_HANDLE;
new String:SavePath[256]

/* Plugin Start */
public OnPluginStart()
{
	/* Build Save Path */
	RPGSave = CreateKeyValues("Battle-RPG Save");
	BuildPath(Path_SM, SavePath, 255, "data/BattleRPGSave.txt");
	if (FileExists(SavePath)) {
		FileToKeyValues(RPGSave, SavePath);
	} else 
	{
		PrintToServer("Cannot find save file: %s", SavePath);
		KeyValuesToFile(RPGSave, SavePath);
	}
	
	/* Create Plugin Info */
	CreateConVar(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS)
	
	/* Client Commands */
	RegConsoleCmd("rpgmenu", CmdRPG_Menu)
	RegConsoleCmd("jobmenu", CmdJob_Menu)
	RegConsoleCmd("jobinfo", CmdPlayersSkills)
	RegConsoleCmd("jobconfirm", CmdJobConfirmChooseMenu)
	RegConsoleCmd("rpgskills", CmdPlayersSkills)
	RegConsoleCmd("buymenu", CmdBuy_Menu)
	RegConsoleCmd("buyshop", CmdBuy_Menu)
	RegConsoleCmd("buy", CmdBuy_Menu)
	RegConsoleCmd("shop", CmdBuy_Menu)
	
	/* Admin Commads */
	RegAdminCmd("rpgkit_spy",CmdSpyPlayer,ADMFLAG_KICK,"rpgkit_spy [#userid|name]")
	//RegAdminCmd("rpgkit_reset_job",CmdResetJob,ADMFLAG_KICK,"rpgkit_reset_job [#userid|name]")
	//RegAdminCmd("rpgkit_reset_save",CmdResetSave,ADMFLAG_KICK,"rpgkit_reset_save [#userid|name]")
	RegAdminCmd("rpgkit_givecash",CmdGiveCash,ADMFLAG_KICK,"rpgkit_givecash [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveexp",CmdGiveEXP,ADMFLAG_KICK,"rpgkit_giveexp [#userid|name] [number]")
	RegAdminCmd("rpgkit_givelevel",CmdGiveLevel,ADMFLAG_KICK,"rpgkit_givelevel [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveagi",CmdGiveAgility,ADMFLAG_KICK,"rpgkit_giveagi [#userid|name] [number]")
	RegAdminCmd("rpgkit_givestr",CmdGiveStrength,ADMFLAG_KICK,"rpgkit_givestr [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveend",CmdGiveEndurance,ADMFLAG_KICK,"rpgkit_giveend [#userid|name] [number]")
	RegAdminCmd("rpgkit_givehp",CmdGiveHealth,ADMFLAG_KICK,"rpgkit_givehp [#userid|name] [number]")
	
	/* Hook Events */
	HookEvent("witch_killed", RunOnWitchKilled)
	HookEvent("witch_harasser_set", RunOnWitchTargetBufferSet)
	HookEvent("revive_success", RunOnReviveTeammate)
	HookEvent("defibrillator_used", RunOnDefibrillatorUsed)
	HookEvent("player_death", RunOnInfectedDead)
	HookEvent("infected_death", RunOnCommonDead)
	HookEvent("heal_success", RunOnPlayerHeal)
	HookEvent("player_first_spawn", RunOnPlayerSpawnFirst)
	HookEvent("player_spawn", RunOnPlayerSpawn)
	HookEvent("player_hurt", RunOnPlayerHurt)
	HookEvent("infected_hurt", RunOnInfectedHurt)
	HookEvent("jockey_ride", RunOnJocRide, EventHookMode_Pre)
	HookEvent("jockey_ride_end", RunOnJocRideEnd)
	HookEvent("round_start", RunOnRoundStart)
	HookEvent("round_end", RunOnRoundEnd)
	
	MZombieClass = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")
	MOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue")
	
	CreateCvars() // Create all Cvars
	AutoExecConfig(true, "l4d2_battle_rpg_2.2.2") // Create/Load Config
	LogMessage("[Battle-RPG 2] - Loaded")
}

/* Creat all Cvars */
CreateCvars()
{
	/* Config Menu */
	CfgMenuRPGTimer = CreateConVar("rpgkit_cfg_menu_rpg_timer ","15.0","0.0: Disable; X.x: Create Timer: Show up RPG-Menu once after X.x seconds", FCVAR_PLUGIN)
	CfgMenuRPGTimerEnable = CreateConVar("rpgkit_cfg_menu_rpg_enable ","1","0: Disable; 1: Enable Timer: Show up RPG-Menu & Welcome Msg if job is selected", FCVAR_PLUGIN)
	
	CfgMenuRPGBackPack = CreateConVar("rpgkit_cfg_menu_rpg_backpack","1","0: Disable; 1: Show BackPack access button in RPGMenu", FCVAR_PLUGIN)
	
	/* Config EXP */
	CfgExpChatEnable = CreateConVar("rpgkit_cfg_exp_chat_enable","1","0: Disable; 1: Prints chat message to player if he/she got EXP", FCVAR_PLUGIN)
	
	CfgExpTimer = CreateConVar("rpgkit_cfg_exp_timer","1.0","0.0: Disable; X.x : Enable Timer: Check players exp for level up every X.x seconds", FCVAR_PLUGIN)
	
	CfgExpLevelUp = CreateConVar("rpgkit_cfg_exp_levelup","500","Needed EXP to become a level up", FCVAR_PLUGIN)
	CfgExpMode = CreateConVar("rpgkit_cfg_exp_mode","3","1: Subtract EXP on level up; 2: Keep EXP on level up and multiply required EXP by job level; 3: SubtractEXP on level up and multiply required EXP by job level", FCVAR_PLUGIN)
	
	CfgExpJockeyKilled = CreateConVar("rpgkit_cfg_exp_jockey_killed","210","EXP that Jockey kill gives", FCVAR_PLUGIN)
	CfgExpHunterKilled = CreateConVar("rpgkit_cfg_exp_hunter_killed","220", "EXP that Hunter kill gives", FCVAR_PLUGIN)
	CfgExpChargerKilled = CreateConVar("rpgkit_cfg_exp_charger_killed","240","EXP that Charger kill gives", FCVAR_PLUGIN)
	CfgExpSmokerKilled = CreateConVar("rpgkit_cfg_exp_smoker_killed","190","EXP that Smoker kill gives", FCVAR_PLUGIN)
	CfgExpSpitterKilled = CreateConVar("rpgkit_cfg_exp_spitter_killed","170","EXP that Spitter kill gives", FCVAR_PLUGIN)
	CfgExpBoomerKilled = CreateConVar("rpgkit_cfg_exp_boomer_killed","150","EXP that Boomer kill gives", FCVAR_PLUGIN)
	CfgExpWitchKilled = CreateConVar("rpgkit_cfg_exp_witch_killed","400","EXP that Witch kill gives", FCVAR_PLUGIN)
	CfgExpWitchSurvived = CreateConVar("rpgkit_cfg_exp_witch_survived","250","EXP that Witch survive gives", FCVAR_PLUGIN)
	CfgExpCommonKilled = CreateConVar("rpgkit_cfg_exp_common_killed","25","EXP that Common Zombie gives", FCVAR_PLUGIN)
	CfgExpTankKilled = CreateConVar("rpgkit_cfg_exp_tank_killed","900","EXP that Tank gives on tank exp mode 1: (killer) & mode 3: (killer)", FCVAR_PLUGIN)
	CfgExpTankSurvived = CreateConVar("rpgkit_cfg_exp_tank_survived","650","EXP that Tank gives on tank exp mode 2 (all) & mode 3 (other)", FCVAR_PLUGIN)
	CfgExpTankMode = CreateConVar("rpgkit_cfg_exp_tank_mode","3","1: Give EXP only tank killer tank kill EXP; 2: Give all alive players tank survive EXP 3: give killer tankk kill EXP & other survivors tank survive EXP", FCVAR_PLUGIN)
	
	CfgExpReviveTeammate = CreateConVar("rpgkit_cfg_exp_revive_teammate","400","EXP when you succeed setting someone up", FCVAR_PLUGIN)
	CfgExpReanimateTeammate = CreateConVar("rpgkit_cfg_exp_reanimate_teammate","600","EXP when you succeed to revive someone with defibrillator", FCVAR_PLUGIN)
	CfgExpHealTeammate = CreateConVar("rpgkit_cfg_exp_heal_teammate","300","EXP when you succeed to heal someone with first aid kit", FCVAR_PLUGIN)
	
	/* Config Job */
	CfgJobChatRemindJob = CreateConVar("rpgkit_cfg_job_chat_remindjob_enable","1","0: Disable; 1: Enable timer: rpgkit_cfg_chat_remindjob_timer", FCVAR_PLUGIN)
	CfgJobChatRemindJobTimer = CreateConVar("rpgkit_cfg_job_chat_remindjob_timer","10.0","0.0: Disable; X.x : Create Timer: Remind player choose a job every X.x seconds", FCVAR_PLUGIN)
	
	
	/* Config */
	CfgCashLimit = CreateConVar("rpgkit_cfg_cash_limit","100000","0: Disable; X: Limit players cash", FCVAR_PLUGIN)
	
	/* Save Config */
	CfgSaveToFileMode = CreateConVar("rpgkit_cfg_savetofile_mode","1","0: Disable; 1: Saved by player's name; 2: Saved by player's SteamID", FCVAR_PLUGIN)

	/* Skills */
	CfgSkillMode = CreateConVar("rpgkit_cfg_skill_mode","1","0: Disable; Mode1: Add job skills on level up; Mode2: Add job skills on job select; Effects strength, agility & endurance", FCVAR_PLUGIN)
	CfgSkillAgilityGravityLimit = CreateConVar("rpgkit_cfg_skill_agility_gravity_limit","100","Limit agiligy skill converted into gravity (MAX: 180?)", FCVAR_PLUGIN)
	CfgSkillAgilitySpeedLimit = CreateConVar("rpgkit_cfg_skill_agility_speed_limit","350","Limit agiligy skill converted into speed (-1: unlimited)", FCVAR_PLUGIN)
	CfgSkillEnduranceLimit = CreateConVar("rpgkit_cfg_skill_endurance_limit","1000","0: Disable; X: Limit endurance skill (-1: unlimited)", FCVAR_PLUGIN)
	CfgSkillEnduranceShieldLimit = CreateConVar("rpgkit_cfg_skill_endurance_shield_limit","50","limit shield in percent (>=100: no damage/godmode)", FCVAR_PLUGIN)
	CfgSkillEnduranceReflectOnly = CreateConVar("rpgkit_cfg_skill_endurance_dmgreflectonly","0","0: Disable; 1: Damage reflect only, no shield", FCVAR_PLUGIN)
	CfgSkillHealthLimit = CreateConVar("rpgkit_cfg_skill_health_limit ","1000","0: Disable; X: Limit players health", FCVAR_PLUGIN)
	CfgSkillHealthMode = CreateConVar("rpgkit_cfg_skill_health_mode","3","0: Disable; Mode1: Incease Only Health on level up; Mode2: Increase Only Max Health on level up; Mode3: Increase Health & Max Health on level up", FCVAR_PLUGIN)
	CfgSkillStrengthLimit = CreateConVar("rpgkit_cfg_skill_strength_limit","1000","0: Disable; X: Limit strength skill", FCVAR_PLUGIN)
	
	/* Config Items */
	CfgItemsJobEnable = CreateConVar("rpgkit_cfg_items_job_enable","1","0: Disable; 1: Enable job items & give Items after job selected", FCVAR_PLUGIN)
	CfgItemsJobTimerEnable = CreateConVar("rpgkit_cfg_items_job_timer_enable ","0","0: Disable; 1: Enable Timer: Give job items", FCVAR_PLUGIN)
	CfgItemsJobTimer = CreateConVar("rpgkit_cfg_items_job_timer ","0.0","0.0: Disable; X.x: Create Timer: Give job items every X.x sec", FCVAR_PLUGIN)
	CfgItemsJobOnLevelUp = CreateConVar("rpgkit_cfg_items_job_onlevelup","0","0: Disable; 1: Give job items on level up", FCVAR_PLUGIN)
	
	CfgItemsShopCost[0] = CreateConVar("rpgkit_cfg_items_shop_cost_0","10","Cost of Ammo in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[1] = CreateConVar("rpgkit_cfg_items_shop_cost_1","50","Cost of Molotov 1 in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[2] = CreateConVar("rpgkit_cfg_items_shop_cost_2","35","Cost of Pipe Bomb 2 in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[3] = CreateConVar("rpgkit_cfg_items_shop_cost_3","30","Cost of Vomitjar in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[4] = CreateConVar("rpgkit_cfg_items_shop_cost_4","75","Cost of First Aid Kit in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[5] = CreateConVar("rpgkit_cfg_items_shop_cost_5","50","Cost of Pain Pills in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[6] = CreateConVar("rpgkit_cfg_items_shop_cost_6","35","Cost of Adrenaline in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[7] = CreateConVar("rpgkit_cfg_items_shop_cost_7","100","Cost of Defibrillator in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[8] = CreateConVar("rpgkit_cfg_items_shop_cost_8","125","Cost of Explosive Pack in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[9] = CreateConVar("rpgkit_cfg_items_shop_cost_9","150","Cost of Incendiary Pack in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[10] = CreateConVar("rpgkit_cfg_items_shop_cost_10","77","Cost of Magnum in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[11] = CreateConVar("rpgkit_cfg_items_shop_cost_11","666","Cost of Chainsaw Pack in Shop", FCVAR_PLUGIN)
	CfgItemsShopCost[12] = CreateConVar("rpgkit_cfg_items_shop_cost_12","1337","Cost of Grenade Launcher Pack in Shop", FCVAR_PLUGIN)
	
	/* Required Level of Job X */
	CfgJobReqLevel[0] = CreateConVar("rpgkit_cfg_job_reqlevel_0","0","ReqLevel of Civilian", FCVAR_PLUGIN)
	CfgJobReqLevel[1] = CreateConVar("rpgkit_cfg_job_reqlevel_1","0","ReqLevel of Rookie", FCVAR_PLUGIN)
	CfgJobReqLevel[2] = CreateConVar("rpgkit_cfg_job_reqlevel_2","5","ReqLevel of Scout", FCVAR_PLUGIN)
	CfgJobReqLevel[3] = CreateConVar("rpgkit_cfg_job_reqlevel_3","5","ReqLevel of Soldier", FCVAR_PLUGIN)
	CfgJobReqLevel[4] = CreateConVar("rpgkit_cfg_job_reqlevel_4","5","ReqLevel of Medic", FCVAR_PLUGIN)
	CfgJobReqLevel[5] = CreateConVar("rpgkit_cfg_job_reqlevel_5","15","ReqLevel of Pain Master", FCVAR_PLUGIN)
	CfgJobReqLevel[6] = CreateConVar("rpgkit_cfg_job_reqlevel_6","15","ReqLevel of Sniper", FCVAR_PLUGIN)
	CfgJobReqLevel[7] = CreateConVar("rpgkit_cfg_job_reqlevel_7","25","ReqLevel of Weapon Dealer", FCVAR_PLUGIN)
	CfgJobReqLevel[8] = CreateConVar("rpgkit_cfg_job_reqlevel_8","35","ReqLevel of Firebug", FCVAR_PLUGIN)
	CfgJobReqLevel[9] = CreateConVar("rpgkit_cfg_job_reqlevel_9","50","ReqLevel of Witch Hunter", FCVAR_PLUGIN)
	CfgJobReqLevel[10] = CreateConVar("rpgkit_cfg_job_reqlevel_10","75","Tank Buster", FCVAR_PLUGIN)
	CfgJobReqLevel[11] = CreateConVar("rpgkit_cfg_job_reqlevel_11","100","ReqLevel of Task Force", FCVAR_PLUGIN)
	CfgJobReqLevel[12] = CreateConVar("rpgkit_cfg_job_reqlevel_12","150","ReqLevel of General", FCVAR_PLUGIN)
	CfgJobReqLevel[13] = CreateConVar("rpgkit_cfg_job_reqlevel_13","200","ReqLevel of Mighty Master", FCVAR_PLUGIN)
	
	/* Cash of Job X */
	CfgJobCash[0] = CreateConVar("rpgkit_cfg_job_cash_0","0","Cash/Payout of Civilian", FCVAR_PLUGIN)
	CfgJobCash[1] = CreateConVar("rpgkit_cfg_job_cash_1","3","Cash/Payout of Rookie", FCVAR_PLUGIN)
	CfgJobCash[2] = CreateConVar("rpgkit_cfg_job_cash_2","4","Cash/Payout of Scout", FCVAR_PLUGIN)
	CfgJobCash[3] = CreateConVar("rpgkit_cfg_job_cash_3","5","Cash/Payout of Soldier", FCVAR_PLUGIN)
	CfgJobCash[4] = CreateConVar("rpgkit_cfg_job_cash_4","4","Cash/Payout of Medic", FCVAR_PLUGIN)
	CfgJobCash[5] = CreateConVar("rpgkit_cfg_job_cash_5","6","Cash/Payout of Pain Master", FCVAR_PLUGIN)
	CfgJobCash[6] = CreateConVar("rpgkit_cfg_job_cash_6","7","Cash/Payout of Sniper", FCVAR_PLUGIN)
	CfgJobCash[7] = CreateConVar("rpgkit_cfg_job_cash_7","10","Cash/Payout of Weapon Dealer", FCVAR_PLUGIN)
	CfgJobCash[8] = CreateConVar("rpgkit_cfg_job_cash_8","9","Cash/Payout of Firebug", FCVAR_PLUGIN)
	CfgJobCash[9] = CreateConVar("rpgkit_cfg_job_cash_9","12","Cash/Payout of Witch Hunter", FCVAR_PLUGIN)
	CfgJobCash[10] = CreateConVar("rpgkit_cfg_job_cash_10","14","Cash/Payout of Tank Buster", FCVAR_PLUGIN)
	CfgJobCash[11] = CreateConVar("rpgkit_cfg_job_cash_11","15","Cash/Payout of Task Force", FCVAR_PLUGIN)
	CfgJobCash[12] = CreateConVar("rpgkit_cfg_job_cash_12","20","Cash/Payout of General", FCVAR_PLUGIN)
	CfgJobCash[13] = CreateConVar("rpgkit_cfg_job_cash_13","30","Cash/Payout of Mighty Master", FCVAR_PLUGIN)
	
	/* Health of Job X */
	CfgJobHealthBasis[0] = CreateConVar("rpgkit_cfg_job_health_basis_0","100","Basis Health of Civilian", FCVAR_PLUGIN)
	CfgJobHealthBasis[1] = CreateConVar("rpgkit_cfg_job_health_basis_1","100","Basis Health of Rookie", FCVAR_PLUGIN)
	CfgJobHealthBasis[2] = CreateConVar("rpgkit_cfg_job_health_basis_2","120","Basis Health of Scout", FCVAR_PLUGIN)
	CfgJobHealthBasis[3] = CreateConVar("rpgkit_cfg_job_health_basis_3","130","Basis Health of Soldier", FCVAR_PLUGIN)
	CfgJobHealthBasis[4] = CreateConVar("rpgkit_cfg_job_health_basis_4","140","Basis Health of Medic", FCVAR_PLUGIN)
	CfgJobHealthBasis[5] = CreateConVar("rpgkit_cfg_job_health_basis_5","150","Basis Health of Pain Master", FCVAR_PLUGIN)
	CfgJobHealthBasis[6] = CreateConVar("rpgkit_cfg_job_health_basis_6","160","Basis Health of Sniper", FCVAR_PLUGIN)
	CfgJobHealthBasis[7] = CreateConVar("rpgkit_cfg_job_health_basis_7","170","Basis Health of Weapon Dealer", FCVAR_PLUGIN)
	CfgJobHealthBasis[8] = CreateConVar("rpgkit_cfg_job_health_basis_8","180","Basis Health of Firebug", FCVAR_PLUGIN)
	CfgJobHealthBasis[9] = CreateConVar("rpgkit_cfg_job_health_basis_9","200","Basis Health of Witch Hunter", FCVAR_PLUGIN)
	CfgJobHealthBasis[10] = CreateConVar("rpgkit_cfg_job_health_basis_10","220","Basis Health of Tank Buster", FCVAR_PLUGIN)
	CfgJobHealthBasis[11] = CreateConVar("rpgkit_cfg_job_health_basis_11","250","Basis Health of Task Force", FCVAR_PLUGIN)
	CfgJobHealthBasis[12] = CreateConVar("rpgkit_cfg_job_health_basis_12","280","Basis Health of General", FCVAR_PLUGIN)
	CfgJobHealthBasis[13] = CreateConVar("rpgkit_cfg_job_health_basis_13","300","Basis Health of Mighty Master", FCVAR_PLUGIN)
	
	/* HP of Job X */
	CfgJobHealthBonus[0] = CreateConVar("rpgkit_cfg_job_health_bonus_0","0","Bonus Health of Civilian", FCVAR_PLUGIN)
	CfgJobHealthBonus[1] = CreateConVar("rpgkit_cfg_job_health_bonus_1","1","Bonus Health of Rookie", FCVAR_PLUGIN)
	CfgJobHealthBonus[2] = CreateConVar("rpgkit_cfg_job_health_bonus_2","2","Bonus Health of Scout", FCVAR_PLUGIN)
	CfgJobHealthBonus[3] = CreateConVar("rpgkit_cfg_job_health_bonus_3","3","Bonus Health of Soldier", FCVAR_PLUGIN)
	CfgJobHealthBonus[4] = CreateConVar("rpgkit_cfg_job_health_bonus_4","4","Bonus Health of Medic", FCVAR_PLUGIN)
	CfgJobHealthBonus[5] = CreateConVar("rpgkit_cfg_job_health_bonus_5","5","Bonus Health of Pain Master", FCVAR_PLUGIN)
	CfgJobHealthBonus[6] = CreateConVar("rpgkit_cfg_job_health_bonus_6","6","Bonus Health of Sniper", FCVAR_PLUGIN)
	CfgJobHealthBonus[7] = CreateConVar("rpgkit_cfg_job_health_bonus_7","7","Bonus Health of Weapon Dealer", FCVAR_PLUGIN)
	CfgJobHealthBonus[8] = CreateConVar("rpgkit_cfg_job_health_bonus_8","8","Bonus Health of Firebug", FCVAR_PLUGIN)
	CfgJobHealthBonus[9] = CreateConVar("rpgkit_cfg_job_health_bonus_9","9","Bonus Health of Witch Hunter", FCVAR_PLUGIN)
	CfgJobHealthBonus[10] = CreateConVar("rpgkit_cfg_job_health_bonus_10","10","Bonus HP of Tank Buster", FCVAR_PLUGIN)
	CfgJobHealthBonus[11] = CreateConVar("rpgkit_cfg_job_health_bonus_11","11","Bonus HP of Task Force", FCVAR_PLUGIN)
	CfgJobHealthBonus[12] = CreateConVar("rpgkit_cfg_job_health_bonus_12","12","Bonus HP of General", FCVAR_PLUGIN)
	CfgJobHealthBonus[13] = CreateConVar("rpgkit_cfg_job_health_bonus_13","13","Bonus HP of Mighty Master", FCVAR_PLUGIN)
	
	/* Agi of Job X */
	CfgJobAgility[0] = CreateConVar("rpgkit_cfg_job_agility_0","0","Agility of Civilian", FCVAR_PLUGIN)
	CfgJobAgility[1] = CreateConVar("rpgkit_cfg_job_agility_1","1","Agility of Rookie", FCVAR_PLUGIN)
	CfgJobAgility[2] = CreateConVar("rpgkit_cfg_job_agility_2","4","Agility of Scout", FCVAR_PLUGIN)
	CfgJobAgility[3] = CreateConVar("rpgkit_cfg_job_agility_3","2","Agility of Soldier", FCVAR_PLUGIN)
	CfgJobAgility[4] = CreateConVar("rpgkit_cfg_job_agility_4","2","Agility of Medic", FCVAR_PLUGIN)
	CfgJobAgility[5] = CreateConVar("rpgkit_cfg_job_agility_5","2","Agility of Pain Master", FCVAR_PLUGIN)
	CfgJobAgility[6] = CreateConVar("rpgkit_cfg_job_agility_6","2","Agility of Sniper", FCVAR_PLUGIN)
	CfgJobAgility[7] = CreateConVar("rpgkit_cfg_job_agility_7","3","Agility of Weapon Dealer", FCVAR_PLUGIN)
	CfgJobAgility[8] = CreateConVar("rpgkit_cfg_job_agility_8","3","Agility of Firebug", FCVAR_PLUGIN)
	CfgJobAgility[9] = CreateConVar("rpgkit_cfg_job_agility_9","4","Agility of Witch Hunter", FCVAR_PLUGIN)
	CfgJobAgility[10] = CreateConVar("rpgkit_cfg_job_agility_10","4","Agility of Tank Buster", FCVAR_PLUGIN)
	CfgJobAgility[11] = CreateConVar("rpgkit_cfg_job_agility_11","5","Agility of Task Force", FCVAR_PLUGIN)
	CfgJobAgility[12] = CreateConVar("rpgkit_cfg_job_agility_12","6","Agility of General", FCVAR_PLUGIN)
	CfgJobAgility[13] = CreateConVar("rpgkit_cfg_job_agility_13","7","Agility of Mighty Master", FCVAR_PLUGIN)
	
	/* Str of Job X */
	CfgJobStrength[0] = CreateConVar("rpgkit_cfg_job_strength_0","0","Strength of Civilian", FCVAR_PLUGIN)
	CfgJobStrength[1] = CreateConVar("rpgkit_cfg_job_strength_1","2","Strength of Rookie", FCVAR_PLUGIN)
	CfgJobStrength[2] = CreateConVar("rpgkit_cfg_job_strength_2","3","Strength of Scout", FCVAR_PLUGIN)
	CfgJobStrength[3] = CreateConVar("rpgkit_cfg_job_strength_3","5","Strength of Soldier", FCVAR_PLUGIN)
	CfgJobStrength[4] = CreateConVar("rpgkit_cfg_job_strength_4","3","Strength of Medic", FCVAR_PLUGIN)
	CfgJobStrength[5] = CreateConVar("rpgkit_cfg_job_strength_5","3","Strength of Pain Master", FCVAR_PLUGIN)
	CfgJobStrength[6] = CreateConVar("rpgkit_cfg_job_strength_6","5","Strength of Sniper", FCVAR_PLUGIN)
	CfgJobStrength[7] = CreateConVar("rpgkit_cfg_job_strength_7","6","Strength of Weapon Dealer", FCVAR_PLUGIN)
	CfgJobStrength[8] = CreateConVar("rpgkit_cfg_job_strength_8","6","Strength of Firebug", FCVAR_PLUGIN)
	CfgJobStrength[9] = CreateConVar("rpgkit_cfg_job_strength_9","7","Strength of Witch Hunter", FCVAR_PLUGIN)
	CfgJobStrength[10] = CreateConVar("rpgkit_cfg_job_strength_10","7","Strength of Tank Buster", FCVAR_PLUGIN)
	CfgJobStrength[11] = CreateConVar("rpgkit_cfg_job_strength_11","8","Strength of Task Force", FCVAR_PLUGIN)
	CfgJobStrength[12] = CreateConVar("rpgkit_cfg_job_strength_12","8","Strength of General", FCVAR_PLUGIN)
	CfgJobStrength[13] = CreateConVar("rpgkit_cfg_job_strength_13","10","Strength of Mighty Master", FCVAR_PLUGIN)
	
	/* End of Job X */
	CfgJobEndurance[0] = CreateConVar("rpgkit_cfg_job_endurance_0","0","Endurance of Civilian", FCVAR_PLUGIN)
	CfgJobEndurance[1] = CreateConVar("rpgkit_cfg_job_endurance_1","1","Endurance of Rookie", FCVAR_PLUGIN)
	CfgJobEndurance[2] = CreateConVar("rpgkit_cfg_job_endurance_2","2","Endurance of Scout", FCVAR_PLUGIN)
	CfgJobEndurance[3] = CreateConVar("rpgkit_cfg_job_endurance_3","1","Endurance of Soldier", FCVAR_PLUGIN)
	CfgJobEndurance[4] = CreateConVar("rpgkit_cfg_job_endurance_4","1","Endurance of Medic", FCVAR_PLUGIN)
	CfgJobEndurance[5] = CreateConVar("rpgkit_cfg_job_endurance_5","2","Endurance of Pain Master", FCVAR_PLUGIN)
	CfgJobEndurance[6] = CreateConVar("rpgkit_cfg_job_endurance_6","3","Endurance of Sniper", FCVAR_PLUGIN)
	CfgJobEndurance[7] = CreateConVar("rpgkit_cfg_job_endurance_7","4","Endurance of Weapon Dealer", FCVAR_PLUGIN)
	CfgJobEndurance[8] = CreateConVar("rpgkit_cfg_job_endurance_8","5","Endurance of Firebug", FCVAR_PLUGIN)
	CfgJobEndurance[9] = CreateConVar("rpgkit_cfg_job_endurance_9","5","Endurance of Witch Hunter", FCVAR_PLUGIN)
	CfgJobEndurance[10] = CreateConVar("rpgkit_cfg_job_endurance_10","6","Endurance of Tank Buster", FCVAR_PLUGIN)
	CfgJobEndurance[11] = CreateConVar("rpgkit_cfg_job_endurance_11","7","Endurance of Task Force", FCVAR_PLUGIN)
	CfgJobEndurance[12] = CreateConVar("rpgkit_cfg_job_endurance_12","8","Endurance of General", FCVAR_PLUGIN)
	CfgJobEndurance[13] = CreateConVar("rpgkit_cfg_job_endurance_13","10","Endurance of Mighty Master", FCVAR_PLUGIN)
}

/* Commands */

/*  Cmd Show Skills */
public Action:CmdPlayersSkills(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MsgPlayersSkills(client, client)
	}
	return Plugin_Handled
}

/* Cmd Job Confirm Menu */
public Action:CmdJobConfirmChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_JobConfirm(client)
	}
	return Plugin_Handled
}

/* Cmd Job Menu */
public Action:CmdJob_Menu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_Job(client)
	}
	return Plugin_Handled
}

/* Cmd RPG Menu */
public Action:CmdRPG_Menu(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_RPG(client)
	}
	return Plugin_Handled
}

/* Cmd Buy Menu */
public Action:CmdBuy_Menu(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_Buy(client)
	}
	return Plugin_Handled
}

/* ADMIN Commands */

/* Spy Player */
public Action:CmdSpyPlayer(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_spy [Name]")
		return Plugin_Handled
	}

	new String:arg[MAX_NAME_LENGTH]
	GetCmdArg(1, arg, sizeof(arg))

	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			MsgPlayersSkills(client, targetclient)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled
}

/* Give EXP */
public Action:CmdGiveEXP(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_giveexp [Name] [Amount of EXP to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			ClientEXP[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled;
}

/* Give Cash */
public Action:CmdGiveCash(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_givecash [Name] [Amount of cash to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			ClientCash[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled;
}

/* Give Level */
public Action:CmdGiveLevel(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_givelevel [Name] [Amount of Level to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			ClientLevel[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled;
}

/* Give Agiligy */
public Action:CmdGiveAgility(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_giveagi [Name] [Amount of Agility to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			ClientAgility[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	ClientRebuildSkills(targetclient)
	return Plugin_Handled
}

/* Give Strength */
public Action:CmdGiveStrength(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_givestr [Name] [Amount of Strength to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			ClientStrength[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled
}

/* Give Endurance */
public Action:CmdGiveEndurance(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_giveend [Name] [Amount of Endurance to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			ClientEndurance[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled
}

/* Give Health */
public Action:CmdGiveHealth(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: rpgkit_givehp [Name] [Amount of Health to give]")
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16]
	GetCmdArg(1, arg, sizeof(arg))

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
	}
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	new targetclient
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i]
			ClientHealBonus[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	ClientRebuildSkills(targetclient)
	return Plugin_Handled
}

public OnMapStart()
{
	RPGSave = CreateKeyValues("Battle-RPG Save");
	BuildPath(Path_SM, SavePath, 255, "data/BattleRPGSave.txt");
	FileToKeyValues(RPGSave, SavePath);
}

public OnMapEnd()
{
	CloseHandle(RPGSave);
}

public OnClientConnected(client)
{
	/* Load Saves From file */
	ClientSaveToFileLoad(client)
}

public OnClientDisconnect(client)
{
	if(!IsValidEntity(client))
		return;
		
	/* Save To File */
	ClientSaveToFileSave(client)
}

/* Player First Spawn */
public Action:RunOnPlayerSpawnFirst(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(target != 0)
	{
		TCheckExp[target] = CreateTimer(GetConVarFloat(CfgExpTimer), TimerCheckExp, target, TIMER_REPEAT)
	
		if(!IsFakeClient(target) && GetClientTeam(target) == TEAM_SURVIVORS)
		{
			/* Create First Announce Timer */
			if(GetConVarInt(CfgMenuRPGTimerEnable) == 1)
			{
				TOpenRPGMenu[target] = CreateTimer(GetConVarFloat(CfgMenuRPGTimer), TimerAnnounceFirst, target)
			}
			
			/* Create Job Remind Timer */
			if(GetConVarInt(CfgJobChatRemindJob) == 1)
			{
				TRemindJob[target] = CreateTimer(GetConVarFloat(CfgJobChatRemindJobTimer), TimerRemindJob, target, TIMER_REPEAT)
			}
		}
	}
}

/* Player Spawn */
public Action:RunOnPlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(target != 0)
	{
		if(GetClientTeam(target) == TEAM_SURVIVORS && !IsFakeClient(target))
		{
			ClientResetLite(target)
		}
	}
}

/* Round Start */
public Action:RunOnRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i = 1; i < MaxClients; i++)
	{
		ClientResetLite(i)
	}
}

/* Round End */
public Action:RunOnRoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(!IsFakeClient(i))
		{
			/* Save To File */
			ClientSaveToFileSave(i)
			ClientResetLite(i)
		}
	}	 
}


public Action:RunOnPlayerHeal(Handle:event, String:event_name[], bool:dontBroadcast)
{
	/* Set player's health on healing */
	new HealSucTarget = GetClientOfUserId(GetEventInt(event, "subject"))
	new HealPerformer = GetClientOfUserId(GetEventInt(event, "userid"))
	if(HealSucTarget != 0 && HealPerformer != 0) //Filter invalid client ID's
	{
		if(GetClientTeam(HealSucTarget) == TEAM_SURVIVORS && !IsFakeClient(HealSucTarget)) //Confirm Client
		{
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), GetHealthMaxToSet(HealSucTarget), 4, true)
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), GetHealthMaxToSet(HealSucTarget), 4, true)
			if(HealSucTarget != HealPerformer && !IsFakeClient(HealPerformer))
			{
				ClientEXP[HealPerformer] += GetConVarInt(CfgExpHealTeammate)
				MsgExpHeal(HealPerformer, HealSucTarget)
			}
		}
	}
}

public Action:RunOnJocRide(Handle:event, String:event_name[], bool:dontBroadcast)
{
	/* Set player's speed back to normal on jockey ride */
	new targetid = GetClientOfUserId(GetEventInt(event, "victim"))
	if(targetid != 0) //Filter invalid client ID's
	{
		if(GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid)) //Confirm Client
		{
			ClientResetAgility(targetid)
			ClientLockAgiligy[targetid] = 1
		}
	}
}

public Action:RunOnJocRideEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	/* Rebuild player's speed an max health on jockey ride end */
	new targetid = GetClientOfUserId(GetEventInt(event, "victim"))
	if(targetid != 0) //Filter invalid client ID's
	{
		if(GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid)) //Confirm Client
		{
			ClientLockAgiligy[targetid] = 0
			ClientRebuildSkills(targetid)
		}
	}
}

/* Run On Special Infected */
public Action:RunOnInfectedDead(Handle:event, String:event_name[], bool:dontBroadcast)	
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	new killed = GetClientOfUserId(GetEventInt(event, "userid"))
	if (0 < killer <= MaxClients && killed != 0) //Filter invalid client ID's
	{
		new EventZombieClass = GetEntData(killed, MZombieClass)
		if(GetClientTeam(killer) == TEAM_SURVIVORS) //Confirm Client
		{
			new targetexp = ClientEXP[killer]
			//Smoker
			if(EventZombieClass == 1 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpSmokerKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpSmokerKilled(killer)
				}
			}
			//Boomer
			else if(EventZombieClass == 2 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpBoomerKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpBoomerKilled(killer)
				}
			}
			// Hunter
			else if(EventZombieClass == 3 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpHunterKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpHunterKilled(killer)
				}
			}
			// Spitter
			else if(EventZombieClass == 4 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpSpitterKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpSpitterKilled(killer)
				}
			}
			// Jockey
			else if(EventZombieClass == 5 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpJockeyKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpJockeyKilled(killer)
				}
			}
			// Charger
			else if(EventZombieClass == 6 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpChargerKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpChargerKilled(killer)
				}
			}
			// Tank
			else if(IsPlayerTank(killed))
			{
				if(GetConVarInt(CfgExpTankMode) == 1 && !IsFakeClient(killer))
				{
					/* give killer EXP */
					targetexp += GetConVarInt(CfgExpTankKilled) // Give EXP
					if(GetConVarInt(CfgExpChatEnable) == 1)
					{
						MsgExpTankKilled(killer)
					}
				}
				if(GetConVarInt(CfgExpTankMode) == 2)
				{
					/* give all survivors EXP */
					for(new i = 1; i < MaxClients; i++)
					{
						if(GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i) && IsPlayerAlive(i)) //Confirm Client
						{
							ClientEXP[i] += GetConVarInt(CfgExpTankSurvived) // Give EXP
							if(GetConVarInt(CfgExpChatEnable) == 1)
							{
								MsgExpTankSurvive(i)
							}
						}
					}
				}
				if(GetConVarInt(CfgExpTankMode) == 3)
				{
					/* give killer EXP */
					if(!IsFakeClient(killer))
					{
						targetexp += GetConVarInt(CfgExpTankKilled) // Give EXP
						if(GetConVarInt(CfgExpChatEnable) == 1)
						{
							MsgExpTankKilled(killer)
						}
					}
					/* give other survivors EXP */
					for(new i = 1; i < MaxClients; i++)
					{
						if(GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i) && IsPlayerAlive(i) && i != killer) //Confirm Client
						{
							ClientEXP[i] += GetConVarInt(CfgExpTankSurvived) // Give EXP
							if(GetConVarInt(CfgExpChatEnable) == 1)
							{
								MsgExpTankSurvive(i)
							}
						}
					}
				}
			}
			ClientEXP[killer] = targetexp
		}
	}
}

/* Run On Revive Someone */
public Action:RunOnReviveTeammate(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(Reviver != 0 && Subject != 0 && Reviver != Subject) //Filter invalid client ID's
	{
		if(!IsFakeClient(Reviver) && GetClientTeam(Reviver) == TEAM_SURVIVORS) //Confirm Client
		{
			ClientEXP[Reviver] += GetConVarInt(CfgExpReviveTeammate)
			ClientRebuildSkills(Subject)
			if(GetConVarInt(CfgExpChatEnable) == 1)
			{
				MsgExpRevive(Reviver, Subject)
			}
		}
	}
}

/* Run On Defibrillator Used */
public Action:RunOnDefibrillatorUsed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(Reviver != 0 && Subject != 0 && Reviver != Subject) //Filter invalid client ID's
	{
		if(GetClientTeam(Reviver) == TEAM_SURVIVORS && !IsFakeClient(Reviver)) //Confirm Client
		{
			ClientEXP[Reviver] += GetConVarInt(CfgExpReanimateTeammate)
			ClientRebuildSkills(Subject)
			if(GetConVarInt(CfgExpChatEnable) == 1)
			{
				MsgExpDefUsed(Reviver, Subject)
			}
		}
	}
}

/* Run On Witch Killed */
public Action:RunOnWitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
    new killer = GetClientOfUserId(GetEventInt(event, "userid"))
    new targetwitch = GetEventInt(event, "witchid")
    
    if(killer != 0 && targetwitch != 0) //Filter invalid client ID's
	{
		/* EXP Witch Killed */
		if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer) && (WitchTargetBuffer[targetwitch] == killer || WitchTargetBuffer[targetwitch] == 0)) //Confirm Client
		{
			ClientEXP[killer] += GetConVarInt(CfgExpWitchKilled)
			if(GetConVarInt(CfgExpChatEnable) == 1)
			{
				MsgExpWitchKilled(killer)
			}
		}
		/* EXP Witch Survived */
		if(WitchTargetBuffer[targetwitch] != 0)
		{
			if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer) && WitchTargetBuffer[targetwitch] != killer && IsPlayerAlive(WitchTargetBuffer[targetwitch]))
			{
				ClientEXP[killer] += GetConVarInt(CfgExpWitchSurvived)
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpWitchSurvived(WitchTargetBuffer[targetwitch], killer)
				}
			}
		}
		WitchTargetBuffer[targetwitch] = 0
	}
}

public Action:RunOnWitchTargetBufferSet(Handle:event, String:event_name[], bool:dontBroadcast)
{
    new targetuser = GetClientOfUserId(GetEventInt(event, "userid"))
    new targetwitch = GetEventInt(event, "witchid")
    
    if(targetuser != 0 && targetwitch != 0) //Filter invalid client ID's
    {
        if(GetClientTeam(targetuser) == TEAM_SURVIVORS && !IsFakeClient(targetuser))
        {
            WitchTargetBuffer[targetwitch] = targetuser
        }
    }
}

/* Run On Common Infected Killed*/
public Action:RunOnCommonDead(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(killer != 0) //Filter invalid client ID's
	{
		if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer)) //Confirm Client
		{
			ClientEXP[killer] += GetConVarInt(CfgExpCommonKilled)
		}
	}
}

/* Run On Player Hurt*/
public Action:RunOnPlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "dmg_health")
	if(hurted != 0 && attacker != 0) //Filter invalid client ID's
	{
		if(GetClientTeam(hurted) == TEAM_SURVIVORS && !IsFakeClient(hurted)) //Confirm Client
		{
			if(GetConVarInt(CfgSkillEnduranceReflectOnly) == 1)
			{
				if(GetClientTeam(attacker) != TEAM_SURVIVORS)
				{
					new Float:RefFloat = (ClientEndurance[hurted])*0.01
					new RefDecHealth = RoundToNearest(dmg*RefFloat)
					new RefHealth = GetClientHealth(attacker)
					ClientSetEndReflect(attacker, RefHealth, RefDecHealth)
				}
			}
			else
			{
				new el = GetConVarInt(CfgSkillEnduranceLimit)
				if(ClientEndurance[hurted] <= el || el == -1)
				{
					ClientEndurance[hurted] = el
				}
				if(ClientEndurance[hurted] <= GetConVarInt(CfgSkillEnduranceShieldLimit))
				{
					new EndHealth = GetEventInt(event, "health")
					new Float:EndFloat = ClientEndurance[hurted]*0.01
					new EndAddHealth = RoundToNearest(dmg*EndFloat)
					ClientSetEndurance(hurted, EndHealth, EndAddHealth)
				}
				else
				{
					new EndHealth = GetEventInt(event, "health")
					new EndAddHealth = RoundToNearest(dmg*0.01*GetConVarInt(CfgSkillEnduranceShieldLimit))
					ClientSetEndurance(hurted, EndHealth, EndAddHealth)
					
					if(GetClientTeam(attacker) != TEAM_SURVIVORS)
					{
						new Float:RefFloat = (ClientEndurance[hurted]-GetConVarInt(CfgSkillEnduranceShieldLimit))*0.01
						new RefDecHealth = RoundToNearest(dmg*RefFloat)
						new RefHealth = GetClientHealth(attacker)
						ClientSetEndReflect(attacker, RefHealth, RefDecHealth)
					}
				}
			}
		}
		
		if(GetClientTeam(hurted) == TEAM_INFECTED) //Confirm Client
		{
			/* Deal Damage */
			new sl = GetConVarInt(CfgSkillStrengthLimit)
			if(ClientStrength[hurted] <= sl && sl != 0)
			{
				ClientStrength[hurted] = sl
			}
			new StrHealth = GetEventInt(event, "health")
			new Float:StrFloat = ClientStrength[attacker]*0.01
			new StrRedHealth = RoundToNearest(dmg*StrFloat)
			ClientSetStrDamage(hurted, StrHealth, StrRedHealth)
		}
	}
}

/* Run On Infected Hurt*/
public Action:RunOnInfectedHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetEventInt(event, "entityid")
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "amount")
	if(attacker != 0 && hurted != 0 && attacker <= MaxClients) //Filter invalid client ID's
	{
		if(GetClientTeam(attacker) == TEAM_SURVIVORS && !IsFakeClient(attacker))
		{
			new Float:StrFloat = ClientStrength[attacker]*0.02
			new StrRedHealth = RoundToNearest(dmg*StrFloat)
			if(GetEntProp(hurted, Prop_Data, "m_iHealth") > StrRedHealth)
			{
				SetEntProp(hurted, Prop_Data, "m_iHealth", GetEntProp(hurted, Prop_Data, "m_iHealth")-StrRedHealth)
			}
		}
	}
}

/* Chat Messages */

/* Message: welcome */
MsgWelcome(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Hello %N! Welcome to \x04[Battle-RPG] \x03by .#Zipcore", targetid)
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Type \x04!rpgmenu\x03 in chat to show up [Main-Menu]")
}

/* Message: already job shoosen a job this round*/
MsgJobLock(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You have already choosen a job this round!")
}

/* Message: job comfirmend */
MsgJobConfirmed(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Job Confirmed! Basis health set to \x04%d\x03", GetJobHealth(ClientJob[targetid]))
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You'll get \x04%d\x03$ Cash, \x04%d\x03 HP, \x04%d\x03 Str, \x04%d\x03 Agi & \x04%d\x03 End on levelup", GetJobCash(ClientJob[targetid]), GetJobHP(ClientJob[targetid]), GetJobStr(ClientJob[targetid]), GetJobAgi(ClientJob[targetid]), GetJobEnd(ClientJob[targetid]))
}

/* Message: job requires bigger level */
MsgJobReqLevel(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Need Level \x04%d\x03 Your Level: \x04%d\x03", GetJobReqLevel(ClientJobConfirm[targetid]), ClientLevel[targetid])
}

/* Message: feature requires job */
MsgFeatureReqJob(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03This feature requires a job.")
}

/* Message: information about players job */
MsgPlayersSkills(client, targetid)
{
	PrintToChat(client, "\x04[Battle-RPG] \x03Name: \x04%N\x03 Cash: \x04%d\x03", targetid, ClientCash[targetid])
	PrintToChat(client, "\x04[Battle-RPG] \x03Level: \x04%d\x03 JobLevel: \x04%d\x03", ClientLevel[targetid], ClientLevelJob[targetid])
	PrintToChat(client, "\x04[Battle-RPG] \x03Health: \x04%d\x03/\x04%d\x03 HP", GetEntData(targetid, FindDataMapOffs(targetid, "m_iHealth"), 4), (GetJobHealth(ClientJob[targetid])+ClientHealBonus[targetid]))
	PrintToChat(client, "\x04[Battle-RPG] \x03BasisHealth: \x04%d\x03 HP & BonusHealth: \x04%d\x03 HP", GetJobHealth(ClientJob[targetid]), ClientHealBonus[targetid])
	PrintToChat(client, "\x04[Battle-RPG] \x03Str: +\x04%d\x03% dmg, Agi: +\x04%d\x03% speed", ClientStrength[targetid], ClientAgility[targetid])
	
	if(GetConVarInt(CfgSkillEnduranceReflectOnly) == 1)
	{
		PrintToChat(client, "\x04[Battle-RPG] \x03Endurance: \x04%d\x03% Reflect", ClientEndurance[targetid])	
	}
	else
	{
		if(ClientEndurance[targetid] <= GetConVarInt(CfgSkillEnduranceShieldLimit))
		{
		PrintToChat(client, "\x04[Battle-RPG] \x03Endurance: \x04%d\x03% Shield", ClientEndurance[targetid])
		}
		else
		{
				PrintToChat(client, "\x04[Battle-RPG] \x03Endurance: \x04%d\x03% \x05 Shield & \x04%d\x03% Reflect", ClientEndurance[targetid], (ClientEndurance[targetid]-GetConVarInt(CfgSkillEnduranceShieldLimit)))
		}
	}
}

/* Message: information about specific job */
MsgJobInfo(targetid, jobid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03JobInfo about JobID: \x04%d\x03",jobid)
	new hpmode = GetConVarInt(CfgSkillHealthMode)
	new skillmode = GetConVarInt(CfgSkillMode)
	
	if(hpmode == 1) //Mode 1: Incease Only Health
	{
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Max Health: \x04%d\x03HP(+\x04%d\x03 to \x05Health \x03on level up)", GetJobHealth(jobid), GetJobHP(jobid))
	}
	if(hpmode == 2) //Mode 2: Increase Only Max Health
	{
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Max Health: \x04%d\x03HP(+\x04%d\x03 to \x05Max Health \x03on level up)", GetJobHealth(jobid), GetJobHP(jobid))
	}
	if(hpmode == 3) //Mode 3: Increase Health & Max Health
	{
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Max Health: \x04%d\x03HP(+\x04%d\x03 to \x05Health & Max Health \x03on level up)", GetJobHealth(jobid), GetJobHP(jobid))
	}
	if(skillmode == 1) //Mode 1: Job skill on level up
	{
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Strength: +\x04%d\x03% \x05dmg \x03& Agi: +\x04%d\x03% \x05movement speed \x03on level up", GetJobStr(jobid), GetJobAgi(jobid))
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Endurance: -\x04%d\x03% \x05dmg (shield) and & if End > 50 \x04%d\x03% \x05dmg reflect \x03on level up", GetJobEnd(jobid), GetJobEnd(jobid))
	}
	if(skillmode == 2) //Mode 2: Job skill on job select
	{
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Strength: +\x04%d\x03% \x05dmg \x03& Agi: +\x04%d\x03% \x05movement speed", GetJobStr(jobid), GetJobAgi(jobid))
		PrintToChat(targetid, "\x04[Battle-RPG] \x03Endurance: -\x04%d\x03% \x05dmg (shield) and & if End > 50 \x04%d\x03% \x05dmg reflect", GetJobEnd(jobid), GetJobEnd(jobid))
	}
}

/* Message: on levelup */
MsgLevelUp(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Your level has increased to \x04%d", ClientLevel[targetid])
}

/* Message: remind to chaoose a job */
MsgChooseAJob(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You should definitely choose a job!")
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Type \x04!jobmenu\x03 in chat to see [Job-Menu]")
}

/* Message: killing a witch */
MsgExpWitchKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Witch\x03!", GetConVarInt(CfgExpWitchKilled))
}

/* Message: killing a witch */
MsgExpWitchSurvived(targetid, killer)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You Survived a Witch and got \x04%d\x03 EXP, but \x05%N\x03 has killed the witch and got \x04%d\x03 EXP", GetConVarInt(CfgExpWitchSurvived), killer, GetConVarInt(CfgExpWitchKilled))
}

/* Message: defibrillator used */
MsgExpDefUsed(targetid, subject)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by reanimating \x04%N\x03!", GetConVarInt(CfgExpReanimateTeammate), subject)
}

/* Message: revive somebody */
MsgExpRevive(targetid, subject)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by reviving \x04%N\x03!", GetConVarInt(CfgExpReviveTeammate), subject)
}

/* Message: heal somebody */
MsgExpHeal(targetid, subject)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by healing \x04%N\x03!", GetConVarInt(CfgExpHealTeammate), subject)
}

/* Message: killing a Tank */
MsgExpTankKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Tank\x03!", GetConVarInt(CfgExpTankKilled))
}

/* Message: surviveing a Tank */
MsgExpTankSurvive(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by surviving a \x04Tank\x03!", GetConVarInt(CfgExpTankSurvived))
}

/* Message: killing a Charger */
MsgExpChargerKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Charger\x03!", GetConVarInt(CfgExpChargerKilled))
}

/* Message: killing a Jockey */
MsgExpJockeyKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Jockey\x03!", GetConVarInt(CfgExpJockeyKilled))
}

/* Message: killing a Spitter */
MsgExpSpitterKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Spitter\x03!", GetConVarInt(CfgExpSpitterKilled))
}

/* Message: killing a Hunter */
MsgExpHunterKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Hunter\x03!", GetConVarInt(CfgExpHunterKilled))
}

/* Message: killing a Boomer */
MsgExpBoomerKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Boomer\x03!", GetConVarInt(CfgExpBoomerKilled))
}

/* Message: killing a Smoker */
MsgExpSmokerKilled(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Smoker\x03!", GetConVarInt(CfgExpSmokerKilled))
}

/* Message: buy item success */
MsgBuySucc(targetid, itemcost)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Buy success! Paid: \x04%d\x03$ Left: \x04%d\x03$", itemcost, ClientCash[targetid])
}

/* Message: buy item failed */
MsgBuyFail(targetid, itemcost)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Buy failed! Need: \x04%d\x03$ Cash: \x04%d\x03$", itemcost, ClientCash[targetid])
}

GetHealthMaxToSet(targetid) //Job Basis Health + Temp Health Skill
{
	new MaxHealth = (GetJobHealth(ClientJob[targetid])+ClientHealBonus[targetid])
	new hl = GetConVarInt(CfgSkillHealthLimit)
	if(MaxHealth > hl && hl != 0)
	{
		MaxHealth = hl
	}
	return MaxHealth
}

GetJobHealth(jobid)
{
	return GetConVarInt(CfgJobHealthBasis[jobid])
}

GetJobReqLevel(jobid)
{
	return GetConVarInt(CfgJobReqLevel[jobid])
}

GetJobHP(jobid)
{
	return GetConVarInt(CfgJobHealthBonus[jobid])
}

GetJobCash(jobid)
{
	return GetConVarInt(CfgJobCash[jobid])
}

GetJobAgi(jobid)
{
	return GetConVarInt(CfgJobAgility[jobid])
}

GetJobStr(jobid)
{
	return GetConVarInt(CfgJobStrength[jobid])
}

GetJobEnd(jobid)
{
	return GetConVarInt(CfgJobEndurance[jobid])
}

GetItemCost(itemNum)
{
	return GetConVarInt(CfgItemsShopCost[itemNum])
}

ClientResetLite(targetid)
{
	ClientLevelTemp[targetid] = 0
	ClientJob[targetid] = 0
	ClientLockJob[targetid] = 0
	ClientStrength[targetid] = 0
	ClientAgility[targetid] = 0
	ClientHealBonus[targetid] = 0
	ClientEndurance[targetid] = 0	
	ClientRebuildSkills(targetid)
}

/* Level Up */
ClientLevelUp(targetid)
{
	/* Level */
	ClientLevel[targetid] += 1
	ClientLevelTemp[targetid] += 1
	ClientLevelJob[targetid][ClientJob[targetid]] += 1
	MsgLevelUp(targetid)

	/* Cash */
	new cl = GetConVarInt(CfgCashLimit)
	
	if(ClientCash[targetid] <= cl || cl == 0)
	{
		ClientCash[targetid] += GetJobCash(ClientJob[targetid])
	}
	else
	{
		ClientCash[targetid] = cl
	}
	
	/* Items */
	if(GetConVarInt(CfgItemsJobOnLevelUp) == 1)
	{
		ClientGiveJobItems(targetid, 1, 1, 1, 1, 1)
	}
	
	/* Health Mode */
	new hpmode = GetConVarInt(CfgSkillHealthMode)
	if(hpmode == 1) // Mode 1: Incease Only Health
	{
		ClientSetHealth(targetid, (GetClientHealth(targetid)+GetJobHP(ClientJob[targetid])))
	}
	if(hpmode == 2) // Mode 2: Increase Only Max Health
	{
		ClientHealBonus[targetid] += GetJobHP(ClientJob[targetid])
	}
	if(hpmode == 3) // Mode 3: Increase Health & Max Health
	{
		ClientSetHealth(targetid, (GetClientHealth(targetid)+GetJobHP(ClientJob[targetid])))
		ClientHealBonus[targetid] += GetJobHP(ClientJob[targetid])
	}
	
	/* RPG Mode */
	if(GetConVarInt(CfgSkillMode) == 1) // Mode 1: Job skill on level up */
	{
		ClientStrength[targetid] += GetJobStr(ClientJob[targetid])
		ClientAgility[targetid] += GetJobAgi(ClientJob[targetid])
		ClientEndurance[targetid] += GetJobEnd(ClientJob[targetid])
	}
	
	/* Rebuild Movement Speed & Gravity  & Health */
	ClientRebuildSkills(targetid)
	
	/* Save To file */
	ClientSaveToFileSave(targetid)
}

ClientRebuildSkills(client)
{
	if(ClientLockAgiligy[client] == 0)
	{
		ClientSetHealthMax(client, GetHealthMaxToSet(client))
		ClientSetAgility(client)
	}
}

ClientSetEndurance(client, health, endurance)
{
	SetEntityHealth(client, health+endurance)
}

ClientSetEndReflect(client, health, endurance)
{
	if(health > endurance)
	{
		SetEntityHealth(client, health-endurance)
	}
	else
	{
		ForcePlayerSuicide(client)
	}
}

ClientSetStrDamage(client, health, str)
{
	if(health > str)
	{
		SetEntityHealth(client, health-str)
	}
}

ClientSetHealthMax(targetid, amount)
{
	if(targetid != 0 && !IsFakeClient(targetid))
	{
		SetEntData(targetid, FindDataMapOffs(targetid, "m_iMaxHealth"), amount, 4, true)		
	}
}

ClientSetHealth(targetid, amount)
{
	if(targetid != 0 && !IsFakeClient(targetid))
	{
		SetEntData(targetid, FindDataMapOffs(targetid, "m_iHealth"), amount, 4, true)
	}
}

ClientResetAgility(targetid)
{
	SetEntityGravity(targetid, 1.0)
	SetEntDataFloat(targetid, MOffset, 1.0, true)
}

ClientSetAgility(targetid)
{
	new gl = GetConVarInt(CfgSkillAgilityGravityLimit)
	new sl = GetConVarInt(CfgSkillAgilitySpeedLimit)
	
	/* Check Speed Limit */
	if(ClientAgility[targetid] < sl || sl == -1)
	{
		SetEntDataFloat(targetid, MOffset, 1.0*(1.0 + ClientAgility[targetid]*0.01), true)
	}
	else
	{
		SetEntDataFloat(targetid, MOffset, 1.0*(1.0 + sl*0.01), true)
	}
	/* Check Gravity Limit */
	if(ClientAgility[targetid] <= gl && (1.0-(ClientAgility[targetid]*0.005)) > 0.1)
	{
		SetEntityGravity(targetid, 1.0*(1.0-(ClientAgility[targetid]*0.005)))
	}
	else
	{
		SetEntityGravity(targetid, 1.0*(1.0-(gl*0.005)))
	}
}

/* Give Job Items */
ClientGiveJobItems(client, giveitems, givepweapon, givesweapon, givehealth, givespecial)
{
	if(GetConVarInt(CfgItemsJobEnable) == 1)
	{
		new targetjob = ClientJob[client]
		switch(targetjob)
		{
			case 1: //Rookie
			{
				CheatCommand(client, "give", "")
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "pumpshotgun")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					//Nothing
				}
			}
			case 2: //Scout
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "vomitjar")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "sniper_scout")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					
				}
			}
			case 3: //Soldier
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "smg_mp5")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					//Nothing
				}
			}
			case 4: //Doctor
			{	
				//Items
				if(giveitems == 1)
				{
					//Nothing
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "smg")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "defibrillator")
					CheatCommand(client, "give", "first_aid_kit")
					CheatCommand(client, "give", "adrenaline")
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					//Nothing
				}
			}
			case 5: //Pain Master
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "molotov")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "autoshotgun")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "pain_pills")
					CheatCommand(client, "give", "adrenaline")
				}
				//Other Items
				if(givespecial == 1)
				{
					//Nothing
				}
			}
			case 6: //Sniper
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "sniper_awp")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					//Nothing
				}
			}
			case 7: //Weapon Dealer
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "molotov")
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "rifle_ak47")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					CheatCommand(client, "give", "pistol_magnum")
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					//Nothing
				}
			}
			case 8: //Firebug
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "molotov")
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "rifle_m60")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "adrenaline")
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					CheatCommand(client, "give", "upgradepack_incendiary")
				}
			}
			case 9: //Witch Hunter
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "pipe_bomb")
					CheatCommand(client, "give", "vomitjar")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "rifle")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "adrenaline")
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					CheatCommand(client, "give", "explosive")
				}
			}
			case 10: //Tank Buster
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "molotov")
					CheatCommand(client, "give", "vomitjar")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "molotov")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "adrenaline")
					CheatCommand(client, "give", "pain_pills")
					CheatCommand(client, "give", "first_aid_kit")
				}
				//Other Items
				if(givespecial == 1)
				{
					CheatCommand(client, "give", "upgradepack_incendiary")
				}
			}
			case 11: //Task Force
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "molotov")
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "sniper_military")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "adrenaline")
					CheatCommand(client, "give", "first_aid_kit")
				}
				//Other Items
				if(givespecial == 1)
				{
					CheatCommand(client, "give", "upgradepack_incendiary")
				}
			}
			case 12: //General
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "vomitjar")
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "rifle_ak47")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "defibrillator")
					CheatCommand(client, "give", "first_aid_kit")
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					CheatCommand(client, "give", "upgradepack_explosive")
				}
			}
			case 13: //Mighty Master
			{	
				//Items
				if(giveitems == 1)
				{
					CheatCommand(client, "give", "molotov")
					CheatCommand(client, "give", "vomitjar")
					CheatCommand(client, "give", "pipe_bomb")
				}
				//P. Weapon
				if(givepweapon == 1)
				{
					CheatCommand(client, "give", "grenade_launcher")
				}
				//S. Weapon
				if(givesweapon == 1)
				{
					//Nothing
				}
				//Health Item
				if(givehealth == 1)
				{
					CheatCommand(client, "give", "defibrillator")
					CheatCommand(client, "give", "first_aid_kit")
					CheatCommand(client, "give", "adrenaline")
					CheatCommand(client, "give", "pain_pills")
				}
				//Other Items
				if(givespecial == 1)
				{
					CheatCommand(client, "give", "upgradepack_incendiary")
					CheatCommand(client, "give", "upgradepack_explosive")
				}
			}
		}
	}
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}

/* Save To File */
ClientSaveToFileSave(targetid)
{
	new savetofilemode = GetConVarInt(CfgSaveToFileMode)
	if(savetofilemode != 0)
	{
		if(IsValidClient(targetid))
		{
			decl String:user_name[MAX_NAME_LENGTH]="";
			if(savetofilemode == 1)
			{
				GetClientName(targetid, user_name, sizeof(user_name));
				ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}");//DQM Double quotation mark
				ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}");//SQM Single quotation mark
				ReplaceString(user_name, sizeof(user_name), "/*", "{SST}");//SST Slash Star
				ReplaceString(user_name, sizeof(user_name), "*/", "{STS}");//STS Star Slash
				ReplaceString(user_name, sizeof(user_name), "//", "{DSL}");//DSL Double Slash
			}
			else if(savetofilemode == 2)
			{
				GetClientAuthString(targetid, user_name, sizeof(user_name))
			}
			KvJumpToKey(RPGSave, user_name, true)
			KvSetNum(RPGSave, "Basic Level", ClientLevel[targetid])
			KvSetNum(RPGSave, "Cash", ClientCash[targetid])
			KvSetNum(RPGSave, "Rookie Level", ClientLevelJob[targetid][1])
			KvSetNum(RPGSave, "Scout Level", ClientLevelJob[targetid][2])
			KvSetNum(RPGSave, "Soldier Level", ClientLevelJob[targetid][3])
			KvSetNum(RPGSave, "Medic Level", ClientLevelJob[targetid][4])
			KvSetNum(RPGSave, "Pain Master Level", ClientLevelJob[targetid][5])
			KvSetNum(RPGSave, "Sniper Level", ClientLevelJob[targetid][6])
			KvSetNum(RPGSave, "Weapon Dealer Level", ClientLevelJob[targetid][7])
			KvSetNum(RPGSave, "Firebug Level", ClientLevelJob[targetid][8])
			KvSetNum(RPGSave, "Witch Hunter Level", ClientLevelJob[targetid][9])
			KvSetNum(RPGSave, "Tank Buster Level", ClientLevelJob[targetid][10])
			KvSetNum(RPGSave, "Task Force Level", ClientLevelJob[targetid][11])
			KvSetNum(RPGSave, "General Level", ClientLevelJob[targetid][12])
			KvSetNum(RPGSave, "Mighty Master Level", ClientLevelJob[targetid][13])
			KvRewind(RPGSave)
			KeyValuesToFile(RPGSave, SavePath)
		}
	}
}

/* Load Save From File */
ClientSaveToFileLoad(targetid)
{
	new savetofilemode = GetConVarInt(CfgSaveToFileMode)
	if(savetofilemode != 0)
	{
		if(IsValidClient(targetid))
		{
			decl String:user_name[MAX_NAME_LENGTH]="";
			if(savetofilemode == 1)
			{
				GetClientName(targetid, user_name, sizeof(user_name));
				ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}");//DQM Double quotation mark
				ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}");//SQM Single quotation mark
				ReplaceString(user_name, sizeof(user_name), "/*", "{SST}");//SST Slash Star
				ReplaceString(user_name, sizeof(user_name), "*/", "{STS}");//STS Star Slash
				ReplaceString(user_name, sizeof(user_name), "//", "{DSL}");//DSL Double Slash
			}
			else if(savetofilemode == 2)
			{
				GetClientAuthString(targetid, user_name, sizeof(user_name))
			}
			KvJumpToKey(RPGSave, user_name, true)
			ClientLevel[targetid] = KvGetNum(RPGSave, "Basic Level", 0)
			ClientCash[targetid] = KvGetNum(RPGSave, "Cash", 0)
			ClientLevelJob[targetid][1] = KvGetNum(RPGSave, "Rookie Level", 0)
			ClientLevelJob[targetid][2] = KvGetNum(RPGSave, "Scout Level", 0)
			ClientLevelJob[targetid][3] = KvGetNum(RPGSave, "Soldier Level", 0)
			ClientLevelJob[targetid][4] = KvGetNum(RPGSave, "Medic Level", 0)
			ClientLevelJob[targetid][5] = KvGetNum(RPGSave, "Pain Master Level", 0)
			ClientLevelJob[targetid][6] = KvGetNum(RPGSave, "Sniper Level", 0)
			ClientLevelJob[targetid][7] = KvGetNum(RPGSave, "Weapon Dealer Level", 0)
			ClientLevelJob[targetid][8] = KvGetNum(RPGSave, "Firebug Level", 0)
			ClientLevelJob[targetid][9] = KvGetNum(RPGSave, "Witch Hunter Level", 0)
			ClientLevelJob[targetid][10] = KvGetNum(RPGSave, "Tank Buster Level", 0)
			ClientLevelJob[targetid][11] = KvGetNum(RPGSave, "Task Force Level", 0)
			ClientLevelJob[targetid][12] = KvGetNum(RPGSave, "General Level", 0)
			ClientLevelJob[targetid][13] = KvGetNum(RPGSave, "Mighty Master Level", 0)
			KvGoBack(RPGSave)
		}
	}
}

/* Is Player Tank*/
bool:IsPlayerTank(client)
{
	if(client != 0)
	{
		if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		{
			return true
		}
		else
		{
			return false
		}
	}
	else
	{
		return false
	}
}

/* Give Items Timer */
public Action:TimerGiveItems(Handle:timer, any:targetid)
{
	if(targetid != 0 && !IsFakeClient(targetid))
	{
		ClientGiveJobItems(targetid, 1, 1, 1, 1, 1)
		return Plugin_Continue
	}
	else
	{
		return Plugin_Stop
	}
}

/* Check Exp Timer */
public Action:TimerCheckExp(Handle:timer, any:targetid)
{
	if(ClientJob[targetid] != 0)
	{
		new TargetEXP = ClientEXP[targetid]
		if(GetConVarInt(CfgExpMode) == 1) // Subtract EXP
		{
			if(TargetEXP >= GetConVarInt(CfgExpLevelUp))
			{
				ClientEXP[targetid] -= GetConVarInt(CfgExpLevelUp)
				ClientLevelUp(targetid)
			}
		}
		if(GetConVarInt(CfgExpMode) == 2) // Keep EXP + multiply required EXP by job level
		{
			if(TargetEXP >= (GetConVarInt(CfgExpLevelUp)*(ClientLevelTemp[targetid]+1)))
			{
				ClientLevelUp(targetid)
			}
		}
		if(GetConVarInt(CfgExpMode) == 3) // Subtract EXP + multiply required EXP by job level
		{
			if(TargetEXP >= (GetConVarInt(CfgExpLevelUp)*(ClientLevelTemp[targetid])))
			{
				ClientEXP[targetid] -= GetConVarInt(CfgExpLevelUp)*(ClientLevelTemp[targetid])
				ClientLevelUp(targetid)
			}
		}
	}
	return Plugin_Continue
}

/* Remind Job Timer */
public Action:TimerRemindJob(Handle:timer, any:targetid)
{
	if(targetid != 0)
	{
		if(ClientJob[targetid] == 0 && GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid))
		{
			MsgChooseAJob(targetid) //Remind player to choose a job
		}
		else
		{
			return Plugin_Stop
		}
	}
	else
	{
		return Plugin_Stop
	}
	return Plugin_Continue
}

/* Remind Job Timer */
public Action:TimerAnnounceFirst(Handle:timer, any:targetid)
{
	if(targetid != 0)
	{
		if(ClientJob[targetid] == 0 && GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid))
		{
			MsgWelcome(targetid) // Announce Battle RPG
			FakeClientCommand(targetid,"rpgmenu") // Open RPG-Menu
		}
		else
		{
			return Plugin_Stop
		}
	}
	else
	{
		return Plugin_Stop
	}
	return Plugin_Continue
}

/* RPG-MENU*/

//RPG Menu Func
public Action:MenuFunc_RPG(targetid) 
{
	new Handle:menu = CreateMenu(MenuHandler_RPG)
	SetMenuTitle(menu, "Level: %d | Cash: %d $ | EXP: %d Exp", ClientLevel[targetid], ClientCash[targetid], ClientEXP[targetid])

	AddMenuItem(menu, "option1", "Job Menu")
	AddMenuItem(menu, "option2", "Buy Shop")
	
	/* Show BackPack Button? */
	if(GetConVarInt(CfgMenuRPGBackPack) == 1)
	{
		AddMenuItem(menu, "option3", "BackPack")
	}
	
	SetMenuExitButton(menu, true)
	
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)

	return Plugin_Handled
}

public MenuHandler_RPG(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0:
			{
				FakeClientCommand(client,"jobmenu") //Access JobMenu
			}
			case 1:
			{
				FakeClientCommand(client,"buymenu") //Access BuyShop
			}
			case 2:
			{
				FakeClientCommand(client,"pack") //Access BackPack Plugin
			}
		}
	}
}

/* Buy-Shop */

public Action:MenuFunc_Buy(targetid) 
{
	new Handle:menu = CreateMenu(MenuHandler_Buy)
	SetMenuTitle(menu, "Cash: %d $", ClientCash[targetid])

	
	AddMenuItem(menu, "option1", "Ammo")
	AddMenuItem(menu, "option2", "Molotov")
	AddMenuItem(menu, "option3", "Pipe Bomb")
	AddMenuItem(menu, "option4", "Vomitjar")
	AddMenuItem(menu, "option5", "First Aid Kit")
	AddMenuItem(menu, "option6", "Pain Pills")
	AddMenuItem(menu, "option7", "Adrenaline")
	AddMenuItem(menu, "option8", "Defibrillator")
	AddMenuItem(menu, "option9", "Explosive Pack")
	AddMenuItem(menu, "option10", "Incendiary Pack")
	AddMenuItem(menu, "option11", "Magnum")
	AddMenuItem(menu, "option12", "Chainsaw")
	AddMenuItem(menu, "option13", "Grenade Launcher")
	
	SetMenuExitButton(menu, true)
	
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)

	return Plugin_Handled
}

public MenuHandler_Buy(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		new targetcash = ClientCash[client]
		new itemcost = GetItemCost(itemNum)
		
		if(targetcash >= itemcost)
		{
			targetcash -= itemcost
			
			switch (itemNum)
			{
				case 0:
				{
					CheatCommand(client, "give", "ammo")
				}
				case 1:
				{
					CheatCommand(client, "give", "molotov")
				}
				case 2:
				{
					CheatCommand(client, "give", "pipe_bomb")
				}
				case 3:
				{
					CheatCommand(client, "give", "vomitjar")
				}
				case 4:
				{
					CheatCommand(client, "give", "first_aid_kit")
				}
				case 5:
				{
					CheatCommand(client, "give", "pain_pills")
				}
				case 6:
				{
					CheatCommand(client, "give", "adrenaline")
				}
				case 7:
				{
					CheatCommand(client, "give", "defibrillator")
				}
				case 8:
				{
					CheatCommand(client, "give", "upgradepack_explosive")
				}
				case 9:
				{
					CheatCommand(client, "give", "upgradepack_incendiary")
				}
				case 10:
				{
					CheatCommand(client, "give", "pistol_magnum")
				}
				case 11:
				{
					CheatCommand(client, "give", "chainsaw")
				}
				case 12:
				{
					CheatCommand(client, "give", "grenade_launcher")
				}
			}
			ClientCash[client] = targetcash
			MsgBuySucc(client, itemcost)
		}
		else
		{
			MsgBuyFail(client, itemcost)
		}
	}
}

/* Job MENU */

//Job Menu Func
public Action:MenuFunc_Job(targetid) 
{
	new Handle:menu = CreateMenu(MenuHandler_Job)
	SetMenuTitle(menu, "Level: %d | NextLv: -%dExp", ClientLevel[targetid], (GetConVarInt(CfgExpLevelUp)-ClientEXP[targetid]))
	AddMenuItem(menu, "option1", "Show my skills")
	AddMenuItem(menu, "option2", "Rookie")
	AddMenuItem(menu, "option3", "Scout")
	AddMenuItem(menu, "option4", "Soldier")
	AddMenuItem(menu, "option5", "Medic")
	AddMenuItem(menu, "option6", "Pain Master")
	AddMenuItem(menu, "option7", "Sniper")
	AddMenuItem(menu, "option8", "Weapon Dealer")
	AddMenuItem(menu, "option9", "Firebug")
	AddMenuItem(menu, "option10", "Witch Hunter") 
	AddMenuItem(menu, "option11", "Tank Buster")
	AddMenuItem(menu, "option12", "Task Force")
	AddMenuItem(menu, "option13", "General")
	AddMenuItem(menu, "option14", "Mighty Master")
	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public MenuHandler_Job(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		if(itemNum == 0 && ClientJob[client] > 0)
		{
			FakeClientCommand(client, "rpgskills")
		}
		else if(itemNum == 0 && ClientJob[client] == 0)
		{
			MsgFeatureReqJob(client)	
			FakeClientCommand(client, "jobmenu")
		}
		else
		{
			ClientJobConfirm[client] = itemNum
			FakeClientCommand(client, "jobconfirm")
		}
	}
}

public Action:MenuFunc_JobConfirm(targetid)
{
	MsgJobInfo(targetid, ClientJobConfirm[targetid])
	new Handle:menu = CreateMenu(MenuHandler_JobConfirm)
	SetMenuTitle(menu, "Job requires level: %d", GetJobReqLevel(ClientJobConfirm[targetid]))
	AddMenuItem(menu, "option1", "Yes")
	AddMenuItem(menu, "option2", "No")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public MenuHandler_JobConfirm(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select && itemNum == 0 && ClientLevel[client] >= GetJobReqLevel(ClientJobConfirm[client]) && ClientLockJob[client] == 0 && ClientJobConfirm[client] != 0)
	{
		ClientLockJob[client] = 1
		ClientJob[client] = ClientJobConfirm[client]
		ClientEXP[client] = 0 //Reset Exp
		/* Mode 1: Job skill on level up */
		if(GetConVarInt(CfgSkillMode) == 1)
		{
			ClientStrength[client] = 0
			ClientAgility[client] = 0
			ClientHealBonus[client] = 0
			ClientEndurance[client] = 0
			
			ClientSetHealthMax(client, GetHealthMaxToSet(client))
			ClientSetHealth(client, GetHealthMaxToSet(client))
			ClientRebuildSkills(client)
			MsgJobConfirmed(client)
		}
		/* Mode 2: Job skill on job select */
		if(GetConVarInt(CfgSkillMode) == 2)
		{
			ClientStrength[client] = GetJobStr(ClientJob[client])
			ClientAgility[client] = GetJobAgi(ClientJob[client])
			ClientEndurance[client] = GetJobEnd(ClientJob[client])
			
			ClientSetHealthMax(client, GetHealthMaxToSet(client))
			ClientSetHealth(client, GetHealthMaxToSet(client))
			ClientRebuildSkills(client)
			MsgJobConfirmed(client)
		}
		/* First give of Job Items */
		ClientGiveJobItems(client, 1, 1, 1, 1, 1)
		
		if(GetConVarInt(CfgItemsJobTimerEnable) == 1)
		{
			TGiveItems[client] = CreateTimer(GetConVarFloat(CfgItemsJobTimer), TimerGiveItems, client, TIMER_REPEAT)
		}
	}
	else if(action == MenuAction_Select && itemNum == 0 && ClientJob[client] != 0)
	{
		MsgJobLock(client)
		FakeClientCommand(client,"jobmenu")
	}
	
	if(action == MenuAction_Select && itemNum == 0 && ClientLevel[client] < GetJobReqLevel(ClientJobConfirm[client]))
	{
		MsgJobReqLevel(client)
		FakeClientCommand(client,"jobmenu")
	}
}

/* Execute Cheat Commads */
stock CheatCommand(client, const String:command[], const String:arguments[])
{
    if (!client) return
    new admindata = GetUserFlagBits(client)
    SetUserFlagBits(client, ADMFLAG_ROOT)
    new flags = GetCommandFlags(command)
    SetCommandFlags(command, flags & ~FCVAR_CHEAT)
    FakeClientCommand(client, "%s %s", command, arguments)
    SetCommandFlags(command, flags)
    SetUserFlagBits(client, admindata)
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
