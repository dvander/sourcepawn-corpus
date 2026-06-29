/* L4D2 RPG Construction Kit by.#Zipcore */

#include <sourcemod>
#include <sdktools>

/* Number of Jobs (Change Jobnames in RPG-Menu) */
#define JOBMAX 13


/* Number of Items in Job Menu (Ammo not included! Change Itemnames & items!! in BuyShop-Menu ) */
#define ITEMMAX 12 

/* Plugin Info */
#define PLUGIN_VERSION "2.2.4"
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


/* Cvars */
new Handle:CfgCashLimit = INVALID_HANDLE
new Handle:CfgExpChatEnable = INVALID_HANDLE
new Handle:CfgExpLevelUp = INVALID_HANDLE
new Handle:CfgExpTimer = INVALID_HANDLE
new Handle:CfgExpMode = INVALID_HANDLE
new Handle:CfgExpHealTeammate = INVALID_HANDLE
new Handle:CfgExpReviveTeammate = INVALID_HANDLE
new Handle:CfgExpReanimateTeammate = INVALID_HANDLE
new Handle:CfgExpCommonKilled = INVALID_HANDLE
new Handle:CfgExpBoomerKilled = INVALID_HANDLE
new Handle:CfgExpChargerKilled = INVALID_HANDLE
new Handle:CfgExpHunterKilled = INVALID_HANDLE
new Handle:CfgExpJockeyKilled = INVALID_HANDLE
new Handle:CfgExpSmokerKilled = INVALID_HANDLE
new Handle:CfgExpSpitterKilled = INVALID_HANDLE
new Handle:CfgExpTankMode = INVALID_HANDLE
new Handle:CfgExpTankKilled = INVALID_HANDLE
new Handle:CfgExpTankSurvived = INVALID_HANDLE
new Handle:CfgExpWitchKilled = INVALID_HANDLE
new Handle:CfgExpWitchSurvived = INVALID_HANDLE
new String:CfgJobName[][JOBMAX+1]
new Handle:CfgJobChatRemindJob = INVALID_HANDLE
new Handle:CfgJobChatRemindJobTimer = INVALID_HANDLE
new Handle:CfgJobReqLevel[JOBMAX+1] = INVALID_HANDLE
new Handle:CfgJobCash[JOBMAX+1] = INVALID_HANDLE
new Handle:CfgJobHealthBasis[JOBMAX+1] = INVALID_HANDLE
new Handle:CfgJobHealthBonus[JOBMAX+1] = INVALID_HANDLE
new Handle:CfgJobAgility[JOBMAX+1] = INVALID_HANDLE
new Handle:CfgJobStrength[JOBMAX+1] = INVALID_HANDLE
new Handle:CfgJobEndurance[JOBMAX+1] = INVALID_HANDLE
new Handle:CfgMenuRPGTimer = INVALID_HANDLE
new Handle:CfgMenuRPGTimerEnable = INVALID_HANDLE
new Handle:CfgSaveToFileMode = INVALID_HANDLE
new Handle:CfgSkillMode = INVALID_HANDLE
new Handle:CfgSkillHealthMode = INVALID_HANDLE
new Handle:CfgSkillHealthLimit = INVALID_HANDLE
new Handle:CfgSkillAgilitySpeedLimit = INVALID_HANDLE
new Handle:CfgSkillAgilityGravityLimit = INVALID_HANDLE
new Handle:CfgSkillStrengthLimit = INVALID_HANDLE
new Handle:CfgSkillEnduranceLimit = INVALID_HANDLE
new Handle:CfgSkillEnduranceReflectOnly = INVALID_HANDLE
new Handle:CfgSkillEnduranceShieldLimit = INVALID_HANDLE
new Handle:CfgShopShotgunCost = INVALID_HANDLE
new Handle:CfgShopSmgCost = INVALID_HANDLE
new Handle:CfgShopRifleCost  = INVALID_HANDLE
new Handle:CfgShopShotgunAutoCost = INVALID_HANDLE
new Handle:CfgShopHuntingCost = INVALID_HANDLE
new Handle:CfgShopPipeCost = INVALID_HANDLE
new Handle:CfgShopMolotovCost = INVALID_HANDLE
new Handle:CfgShopPillsCost = INVALID_HANDLE
new Handle:CfgShopMedikitCost = INVALID_HANDLE
new Handle:CfgShopPistolCost = INVALID_HANDLE
new Handle:CfgShopHealCost = INVALID_HANDLE
new Handle:CfgShopRefillCost = INVALID_HANDLE
new Handle:CfgShopInfHealCost = INVALID_HANDLE
new Handle:CfgShopBoomerCost = INVALID_HANDLE
new Handle:CfgShopHunterCost = INVALID_HANDLE
new Handle:CfgShopChargerCost = INVALID_HANDLE
new Handle:CfgShopTankCost = INVALID_HANDLE
new Handle:CfgShopTankLimit = INVALID_HANDLE
new Handle:CfgShopSpitterCost = INVALID_HANDLE
new Handle:CfgShopWitchCost = INVALID_HANDLE
new Handle:CfgShopWitchLimit = INVALID_HANDLE
new Handle:CfgShopMobCost = INVALID_HANDLE
new Handle:CfgShopPanicCost = INVALID_HANDLE
new Handle:CfgShopSmokerCost = INVALID_HANDLE
new Handle:CfgShopSuicideCost = INVALID_HANDLE
new Handle:CfgShopIncendiaryCost = INVALID_HANDLE
new Handle:CfgShopIncendiaryPackCost = INVALID_HANDLE
new Handle:CfgShopAdrenalineCost = INVALID_HANDLE
new Handle:CfgShopDefibCost = INVALID_HANDLE
new Handle:CfgShopShotgunSpasCost = INVALID_HANDLE
new Handle:CfgShopMagnumCost = INVALID_HANDLE
new Handle:CfgShopShotgunChromeCost = INVALID_HANDLE
new Handle:CfgShopAk47Cost = INVALID_HANDLE
new Handle:CfgShopSg552Cost = INVALID_HANDLE
new Handle:CfgShopDesertCost = INVALID_HANDLE
new Handle:CfgShopSmgSilencedCost = INVALID_HANDLE
new Handle:CfgShopMp5Cost = INVALID_HANDLE
new Handle:CfgShopAwpCost = INVALID_HANDLE
new Handle:CfgShopMilitaryCost = INVALID_HANDLE
new Handle:CfgShopScoutCost = INVALID_HANDLE
new Handle:CfgShopVomitjarCost = INVALID_HANDLE
new Handle:CfgShopFireworkCost = INVALID_HANDLE
new Handle:CfgShopOxygenCost = INVALID_HANDLE
new Handle:CfgShopPropaneCost = INVALID_HANDLE
new Handle:CfgShopExplosivePackCost = INVALID_HANDLE
new Handle:CfgShopChainsawCost = INVALID_HANDLE
new Handle:CfgShopGascanCost = INVALID_HANDLE
new Handle:CfgShopGrenadeLauncherCost = INVALID_HANDLE
new Handle:CfgShopJockeyCost = INVALID_HANDLE
new Handle:CfgShopExplosiveCost = INVALID_HANDLE
new Handle:CfgShopLaserCost = INVALID_HANDLE
new Handle:CfgRobBot = INVALID_HANDLE

/* Client Buffer */
new ClientLevel[MAXPLAYERS+1]
new ClientLevelTemp[MAXPLAYERS+1]
new ClientLevelJob[MAXPLAYERS+1][JOBMAX+1]
new ClientCash[MAXPLAYERS+1]
new ClientPoints[MAXPLAYERS+1]
new ClientEXP[MAXPLAYERS+1]
new ClientJob[MAXPLAYERS+1]
new ClientLockJob[MAXPLAYERS+1]
new ClientLockAgiligy[MAXPLAYERS+1]
new ClientHealBonus[MAXPLAYERS+1]
new ClientStrength[MAXPLAYERS+1]
new ClientAgility[MAXPLAYERS+1]
new ClientEndurance[MAXPLAYERS+1]
new ClientJobConfirm[MAXPLAYERS+1]
new ClientBuyConfirm[MAXPLAYERS+1]
new ClientRobLevel[MAXPLAYERS+1]

/* Prob Info */
new MZombieClass
new MOffset

/* Timer */
new Handle:TRemindJob[MAXPLAYERS+1] = INVALID_HANDLE
new Handle:TOpenRPGMenu[MAXPLAYERS+1] = INVALID_HANDLE
new Handle:TCheckExp[MAXPLAYERS+1] = INVALID_HANDLE

/* Buffer */
new BufferWitchTarget[MAXPLAYERS+1]

/* Counter */
new CounterTank = 0
new CounterWitch = 0

/* Save to File */
new Handle:RPGSave = INVALID_HANDLE
new String:SavePath[PLATFORM_MAX_PATH]

/* Plugin Start */
public OnPluginStart()
{
	/* Create Plugin Info */
	CreateConVar(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS)
	
	/* Prob Info */
	MZombieClass = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")
	MOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue")
	
	/* Build Save File */
	if(GetConVarInt(CfgSaveToFileMode) != 0)
	{
		BuildSaveFile()
	}
	
	/* Build/Load Cvars */
	BuildCvars()
	BuildStrings()
	AutoExecConfig(true, "l4d2_battle_rpg_2.2.5")
	
	/* Hook Events */
	HookEvent("witch_killed", RunOnWitchKilled)
	HookEvent("witch_harasser_set", RunOnWitchTargetBufferSet)
	HookEvent("revive_success", RunOnReviveTeammate)
	HookEvent("defibrillator_used", RunOnDefibrillatorUsed)
	HookEvent("player_death", RunOnPlayerDeath)
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
	
	/* Client Commands */
	RegConsoleCmd("rpgmenu", CmdRPGMenu)
	RegConsoleCmd("rpgstats", CmdPlayersSkills)
	RegConsoleCmd("jobs", CmdJobMenu)
	RegConsoleCmd("jobconfirm", CmdJobConfirm)
	RegConsoleCmd("buyconfirm", CmdBuyConfirm)
	RegConsoleCmd("lastjob", CmdJobConfirm)
	RegConsoleCmd("repeatbuy", CmdBuyConfirm)
	RegConsoleCmd("healthshop", CmdShopHealth)
	RegConsoleCmd("buymenu", CmdBuyShop)
	RegConsoleCmd("shop", CmdBuyShop)
	RegConsoleCmd("buy", CmdBuyShop)
	RegConsoleCmd("ammoshop", CmdShopAmmo)
	RegConsoleCmd("explosiveshop", CmdShopExplosive)
	RegConsoleCmd("pistolshop", CmdShopPistol)
	RegConsoleCmd("rifleshop", CmdShopRifle)
	RegConsoleCmd("shotgunshop", CmdShopShotgun)
	RegConsoleCmd("smgshop", CmdShopSmg)
	RegConsoleCmd("snipershop", CmdShopSniper)
	RegConsoleCmd("specialshop", CmdSpecialShop)
	RegConsoleCmd("exchange", CmdExchange)
	
	/* Admin Commads */
	RegAdminCmd("rpgkit_spy",CmdAdminSpyPlayer,ADMFLAG_KICK,"rpgkit_spy [#userid|name]")
	//RegAdminCmd("rpgkit_reset_job",CmdAdminResetJob,ADMFLAG_KICK,"rpgkit_reset_job [#userid|name]")
	//RegAdminCmd("rpgkit_reset_save",CmdAdminResetSave,ADMFLAG_KICK,"rpgkit_reset_save [#userid|name]")
	RegAdminCmd("rpgkit_givecash",CmdAdminGiveCash,ADMFLAG_KICK,"rpgkit_givecash [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveexp",CmdAdminGiveEXP,ADMFLAG_KICK,"rpgkit_giveexp [#userid|name] [number]")
	RegAdminCmd("rpgkit_givelevel",CmdAdminGiveLevel,ADMFLAG_KICK,"rpgkit_givelevel [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveagi",CmdAdminGiveAgility,ADMFLAG_KICK,"rpgkit_giveagi [#userid|name] [number]")
	RegAdminCmd("rpgkit_givestr",CmdAdminGiveStrength,ADMFLAG_KICK,"rpgkit_givestr [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveend",CmdAdminGiveEndurance,ADMFLAG_KICK,"rpgkit_giveend [#userid|name] [number]")
	RegAdminCmd("rpgkit_givehp",CmdAdminGiveHealth,ADMFLAG_KICK,"rpgkit_givehp [#userid|name] [number]")
	
	/* Log: Loaded */
	LogMessage("[Battle-RPG 2] - Loaded")
}

/* Build Save File */
BuildSaveFile()
{
	RPGSave = CreateKeyValues("Battle-RPG Save")
	BuildPath(Path_SM, SavePath, 255, "data/BattleRPGSave.txt")
	if (FileExists(SavePath)) 
	{
		FileToKeyValues(RPGSave, SavePath)
	} 
	else 
	{
		PrintToServer("Cannot find save file: %s", SavePath)
		KeyValuesToFile(RPGSave, SavePath)
	}
}

/* Build all Cvars */
BuildCvars()
{
	/* Config Menu */
	CfgMenuRPGTimer = CreateConVar("rpgkit_cfg_menu_rpg_timer ","15.0","0.0: Disable; X.x: Create Timer: Show up RPG-Menu once after X.x seconds", FCVAR_PLUGIN)
	CfgMenuRPGTimerEnable = CreateConVar("rpgkit_cfg_menu_rpg_enable ","1","0: Disable; 1: Enable Timer: Show up RPG-Menu & Welcome Msg if job is selected", FCVAR_PLUGIN)

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
	
	/* Shop */
	CfgShopAdrenalineCost = CreateConVar("rpgkit_cfg_shop_adrenaline_cost","2999","Cost of: Adrenaline", FCVAR_PLUGIN)
	CfgShopAk47Cost = CreateConVar("rpgkit_cfg_shop_ak47_cost","4047","Cost of: Ak47", FCVAR_PLUGIN)
	CfgShopAwpCost = CreateConVar("rpgkit_cfg_shop_awp_cost","4399","Cost of: Awp", FCVAR_PLUGIN)
	CfgShopBoomerCost = CreateConVar("rpgkit_cfg_shop_boomer_cost","2000","Cost of: Boomer", FCVAR_PLUGIN)
	CfgShopChainsawCost = CreateConVar("rpgkit_cfg_shop_chainsaw_cost","4200","Cost of: Chainsaw", FCVAR_PLUGIN)
	CfgShopChargerCost = CreateConVar("rpgkit_cfg_shop_charger_cost","2000","Cost of: Charger", FCVAR_PLUGIN)
	CfgShopDefibCost = CreateConVar("rpgkit_cfg_shop_defib_cost","6777","Cost of: Defib", FCVAR_PLUGIN)
	CfgShopDesertCost = CreateConVar("rpgkit_cfg_shop_desert_cost","3498","Cost of: Desert", FCVAR_PLUGIN)
	CfgShopExplosiveCost = CreateConVar("rpgkit_cfg_shop_explosive_cost","1399","Cost of: Explosive", FCVAR_PLUGIN)
	CfgShopExplosivePackCost = CreateConVar("rpgkit_cfg_shop_explosive_pack_cost","3499","Cost of: ExplosivePack", FCVAR_PLUGIN)
	CfgShopFireworkCost = CreateConVar("rpgkit_cfg_shop_firework_cost","469","Cost of: Firework Crate", FCVAR_PLUGIN)
	CfgShopGascanCost = CreateConVar("rpgkit_cfg_shop_gascan_cost","899","Cost of: Gascan", FCVAR_PLUGIN)
	CfgShopGrenadeLauncherCost = CreateConVar("rpgkit_cfg_shop_grenade_launcher_cost","4000","Cost of: GrenadeLauncher", FCVAR_PLUGIN)
	CfgShopHealCost = CreateConVar("rpgkit_cfg_shop_heal_cost","7500","Cost of: Survivor Heal", FCVAR_PLUGIN)
	CfgShopHunterCost = CreateConVar("rpgkit_cfg_shop_hunter_cost","2000","Cost of: Hunter", FCVAR_PLUGIN)
	CfgShopHuntingCost = CreateConVar("rpgkit_cfg_shop_hunting_cost","2334","Cost of: Hunting Sniper", FCVAR_PLUGIN)
	CfgShopIncendiaryCost = CreateConVar("rpgkit_cfg_shop_incendiary_cost","1337","Cost of: Incendiary", FCVAR_PLUGIN)
	CfgShopIncendiaryPackCost = CreateConVar("rpgkit_cfg_shop_incendiary_pack_cost","3500","Cost of: IncendiaryPack", FCVAR_PLUGIN)
	CfgShopInfHealCost = CreateConVar("rpgkit_cfg_shop_inf_heal_cost","2000","Cost of: Infected Heal", FCVAR_PLUGIN)
	CfgShopJockeyCost = CreateConVar("rpgkit_cfg_shop_jockey_cost","2000","Cost of: Jockey", FCVAR_PLUGIN)
	CfgShopLaserCost = CreateConVar("rpgkit_cfg_shop_laser_cost","1399","Cost of: Laser", FCVAR_PLUGIN)
	CfgShopMagnumCost = CreateConVar("rpgkit_cfg_shop_magum_cost","2999","Cost of: Magnum", FCVAR_PLUGIN)
	CfgShopMedikitCost = CreateConVar("rpgkit_cfg_shop_medikit_cost","4999","Cost of: Medikit", FCVAR_PLUGIN)
	CfgShopMilitaryCost = CreateConVar("rpgkit_cfg_shop_military_cost","3399","Cost of: Military Sniper", FCVAR_PLUGIN)
	CfgShopMobCost = CreateConVar("rpgkit_cfg_shop_mob_cost","2500","Cost of: MobCost", FCVAR_PLUGIN)
	CfgShopMolotovCost = CreateConVar("rpgkit_cfg_shop_molotov_cost","2299","Cost of: Molotov", FCVAR_PLUGIN)
	CfgShopMp5Cost = CreateConVar("rpgkit_cfg_shop_mp5_cost","2798","Cost of: Mp5", FCVAR_PLUGIN)
	CfgShopOxygenCost = CreateConVar("rpgkit_cfg_shop_oxygen_cost","699","Cost of: Oxygen", FCVAR_PLUGIN)
	CfgShopPanicCost = CreateConVar("rpgkit_cfg_shop_panic_cost","5000","Cost of: Panic Event", FCVAR_PLUGIN)
	CfgShopPillsCost = CreateConVar("rpgkit_cfg_shop_pills_cost","3090","Cost of: Pills", FCVAR_PLUGIN)
	CfgShopPipeCost = CreateConVar("rpgkit_cfg_shop_pipe_cost","2150","Cost of: Pipe", FCVAR_PLUGIN)
	CfgShopPistolCost = CreateConVar("rpgkit_cfg_shop_pistol_cost","299","Cost of: Pistol", FCVAR_PLUGIN)
	CfgShopPropaneCost = CreateConVar("rpgkit_cfg_shop_propane_cost","649","Cost of: Propane", FCVAR_PLUGIN)
	CfgShopRefillCost = CreateConVar("rpgkit_cfg_shop_refill_cost","998","Cost of: Refill", FCVAR_PLUGIN)
	CfgShopRifleCost = CreateConVar("rpgkit_cfg_shop_rifle_cost","3100","Cost of: Rifle", FCVAR_PLUGIN)
	CfgShopScoutCost = CreateConVar("rpgkit_cfg_shop_scout_cost","2900","Cost of: Scout", FCVAR_PLUGIN)
	CfgShopSg552Cost = CreateConVar("rpgkit_cfg_shop_sg552_cost","3444","Cost of: Sg552", FCVAR_PLUGIN)
	CfgShopShotgunAutoCost = CreateConVar("rpgkit_cfg_shop_shotgun_auto_cost","3350","Cost of: Shotgun Auto", FCVAR_PLUGIN)
	CfgShopShotgunChromeCost = CreateConVar("rpgkit_cfg_shop_shotgun_chrome_cost","3499","Cost of: Ahotgun Chrome", FCVAR_PLUGIN)
	CfgShopShotgunCost = CreateConVar("rpgkit_cfg_shop_shotgun_cost","2121","Cost of: Shotgun", FCVAR_PLUGIN)
	CfgShopShotgunSpasCost = CreateConVar("rpgkit_cfg_shop_shotgun_spas_cost","3449","Cost of: Shotgun Spas", FCVAR_PLUGIN)
	CfgShopSmgCost = CreateConVar("rpgkit_cfg_shop_smg_cost","2490","Cost of: Smg", FCVAR_PLUGIN)
	CfgShopSmgSilencedCost = CreateConVar("rpgkit_cfg_shop_smg_silenced_cost","2589","Cost of: Smg Silenced", FCVAR_PLUGIN)
	CfgShopSmokerCost = CreateConVar("rpgkit_cfg_shop_smoker_cost","2000","Cost of: Smoker", FCVAR_PLUGIN)
	CfgShopSpitterCost = CreateConVar("rpgkit_cfg_shop_spitter_cost","2000","Cost of: Spitter", FCVAR_PLUGIN)
	CfgShopSuicideCost = CreateConVar("rpgkit_cfg_shop_suicide_cost","2500","Cost of: Suicide", FCVAR_PLUGIN)
	CfgShopTankCost = CreateConVar("rpgkit_cfg_shop_tank_cost","10000","Cost of: Tank", FCVAR_PLUGIN)
	CfgShopTankLimit = CreateConVar("rpgkit_cfg_shop_tank_limit","1","Shop Tank Limit", FCVAR_PLUGIN)
	CfgShopVomitjarCost = CreateConVar("rpgkit_cfg_shop_vomitjar_cost","1999","Cost of: Vomitjar", FCVAR_PLUGIN)
	CfgShopWitchCost = CreateConVar("rpgkit_cfg_shop_witch_cost","6000","Cost of: Witch", FCVAR_PLUGIN)
	CfgShopWitchLimit = CreateConVar("rpgkit_cfg_shop_witch_limit","3","Shop Witch Limit", FCVAR_PLUGIN)
}

BuildStrings()
{
	CfgJobName[0] = "Civilian"
	CfgJobName[1] = "Rookie"
	CfgJobName[2] = "Scout"
	CfgJobName[3] = "Soldier"
	CfgJobName[4] = "Medic"
	CfgJobName[5] = "Pain Master"
	CfgJobName[6] = "Sniper"
	CfgJobName[7] = "Weapon Dealer"
	CfgJobName[8] = "FireBug"
	CfgJobName[9] = "Witch Hunter"
	CfgJobName[10] = "Tank Buster"
	CfgJobName[11] = "Task Force"
	CfgJobName[12] = "General"
	CfgJobName[13] = "Mighty Master"
}

public OnMapStart()
{
	RPGSave = CreateKeyValues("Battle-RPG Save")
	BuildPath(Path_SM, SavePath, 255, "data/BattleRPGSave.txt")
	FileToKeyValues(RPGSave, SavePath)
}

public OnMapEnd()
{
	CloseHandle(RPGSave)
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

public Action:CmdAdminGiveAgility(client, args)
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

/* Give Cash */
public Action:CmdAdminGiveCash(client, args)
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

/* Give Endurance */
public Action:CmdAdminGiveEndurance(client, args)
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

/* Give EXP */
public Action:CmdAdminGiveEXP(client, args)
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

/* Give Health */
public Action:CmdAdminGiveHealth(client, args)
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

/* Give Level */
public Action:CmdAdminGiveLevel(client, args)
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

public Action:CmdAdminSpyPlayer(client, args)
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

/* Give Strength */
public Action:CmdAdminGiveStrength(client, args)
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

public Action:CmdBuyConfirm(client,args)
{
	MenuFunc_BuyConfirm(client)
	return Plugin_Handled
}

public Action:CmdJobConfirm(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_JobConfirm(client)
	}
	return Plugin_Handled
}

public Action:CmdJobMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_Job(client)
	}
	return Plugin_Handled
}

public Action:CmdPlayersSkills(client, args)
{
	MsgPlayersSkills(client, client)
	return Plugin_Handled
}

public Action:CmdRPGMenu(client,args)
{
	MenuFunc_RPG(client)
	return Plugin_Handled
}

public Action:CmdShopHealth(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopHealth(client)
	}
	return Plugin_Handled
}

public Action:CmdShopSmg(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopSmg(client)
	}
	return Plugin_Handled
}

public Action:CmdShopRifle(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopRifle(client)
	}
	return Plugin_Handled
}

public Action:CmdShopSniper(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopSniper(client)
	}
	return Plugin_Handled
}

public Action:CmdShopShotgun(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopShotgun(client)
	}
	return Plugin_Handled
}

public Action:CmdShopPistol(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopPistol(client)
	}
	return Plugin_Handled
}

public Action:CmdShopExplosive(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopExplosive(client)
	}
	return Plugin_Handled
}

public Action:CmdShopAmmo(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShopAmmo(client)
	}
	return Plugin_Handled
}

public Action:CmdBuyShop(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		MenuFunc_ItemShop(client)
	}
	else if(GetClientTeam(client) == TEAM_INFECTED)
	{
		MenuFunc_SpecialShop(client)
	}
	return Plugin_Handled
}

public Action:CmdSpecialShop(client,args)
{
	if(GetClientTeam(client) == TEAM_INFECTED)
	{
		MenuFunc_SpecialShop(client)
	}
	return Plugin_Handled
}


public Action:CmdExchange(client,args)
{
	if(GetClientTeam(client) == TEAM_INFECTED)
	{
		MenuFunc_Exchange(client)
	}
	return Plugin_Handled
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
			ClientResetTemp(target)
		}
	}
}

/* Round Start */
public Action:RunOnRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i = 1; i < MaxClients; i++)
	{
		ClientResetTemp(i)
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
			ClientResetTemp(i)
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
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), GetJobHealthMax(HealSucTarget), 4, true)
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), GetJobHealthMax(HealSucTarget), 4, true)
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
public Action:RunOnPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)	
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	new killed = GetClientOfUserId(GetEventInt(event, "userid"))
	new bool:headshot = GetEventBool(event, "headshot")
	
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
					if(!IsFakeClient(killed))
					{
						MsgSpecialKillReport(killed, killer, headshot)
					}
				}
			}
			//Boomer
			else if(EventZombieClass == 2 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpBoomerKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpBoomerKilled(killer)
					if(!IsFakeClient(killed))
					{
						MsgSpecialKillReport(killed, killer, headshot)
					}
				}
			}
			// Hunter
			else if(EventZombieClass == 3 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpHunterKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpHunterKilled(killer)
					if(!IsFakeClient(killed))
					{
						MsgSpecialKillReport(killed, killer, headshot)
					}
				}
			}
			// Spitter
			else if(EventZombieClass == 4 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpSpitterKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpSpitterKilled(killer)
					if(!IsFakeClient(killed))
					{
						MsgSpecialKillReport(killed, killer, headshot)
					}
				}
			}
			// Jockey
			else if(EventZombieClass == 5 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpJockeyKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpJockeyKilled(killer)
					if(!IsFakeClient(killed))
					{
						MsgSpecialKillReport(killed, killer, headshot)
					}
				}
			}
			// Charger
			else if(EventZombieClass == 6 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(CfgExpChargerKilled) // Give EXP
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpChargerKilled(killer)
					if(!IsFakeClient(killed))
					{
						MsgSpecialKillReport(killed, killer, headshot)
					}
				}
			}
			// Tank
			else if(ClientIsTank(killed))
			{
				if(GetConVarInt(CfgExpTankMode) == 1 && !IsFakeClient(killer))
				{
					/* give killer EXP */
					targetexp += GetConVarInt(CfgExpTankKilled) // Give EXP
					if(GetConVarInt(CfgExpChatEnable) == 1)
					{
						MsgExpTankKilled(killer)
						if(!IsFakeClient(killed))
						{
							MsgSpecialKillReport(killed, killer, headshot)
						}
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
								if(!IsFakeClient(killed))
								{
									MsgSpecialKillReport(killed, killer, headshot)
								}
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
							if(!IsFakeClient(killed))
							{
								MsgSpecialKillReport(killed, killer, headshot)
							}
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
		if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer) && (BufferWitchTarget[targetwitch] == killer || BufferWitchTarget[targetwitch] == 0)) //Confirm Client
		{
			ClientEXP[killer] += GetConVarInt(CfgExpWitchKilled)
			if(GetConVarInt(CfgExpChatEnable) == 1)
			{
				MsgExpWitchKilled(killer)
			}
		}
		/* EXP Witch Survived */
		if(BufferWitchTarget[targetwitch] != 0)
		{
			if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer) && BufferWitchTarget[targetwitch] != killer && IsPlayerAlive(BufferWitchTarget[targetwitch]))
			{
				ClientEXP[killer] += GetConVarInt(CfgExpWitchSurvived)
				if(GetConVarInt(CfgExpChatEnable) == 1)
				{
					MsgExpWitchSurvived(BufferWitchTarget[targetwitch], killer)
				}
			}
		}
		BufferWitchTarget[targetwitch] = 0
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
            BufferWitchTarget[targetwitch] = targetuser
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
		if(GetClientTeam(hurted) == TEAM_SURVIVORS) //Confirm Client
		{
			if(GetConVarInt(CfgSkillEnduranceReflectOnly) == 1 && !IsFakeClient(hurted))
			{
				if(GetClientTeam(attacker) != TEAM_SURVIVORS)
				{
					new Float:RefFloat = (ClientEndurance[hurted])*0.01
					new RefDecHealth = RoundToNearest(dmg*RefFloat)
					new RefHealth = GetClientHealth(attacker)
					ClientSetEndReflect(attacker, RefHealth, RefDecHealth)
				}
			}
			else if (!IsFakeClient(hurted))
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
			
			/* Rob Player */
			if(attacker != 0 && attacker < (MAXPLAYERS+1))
			{
				ClientRob(attacker, hurted)
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
			new Float:StrFloat = ClientStrength[attacker]*0.01
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
	PrintToChat(targetid, "\x04[RPG] \x03Hello %N! Welcome to \x04[Left 4 Dead 2 RPG] \x03by .#Zipcore", targetid)
	PrintToChat(targetid, "\x04[RPG] \x03Credits: \x04chu1720 & Predailien12", targetid)
	PrintToChat(targetid, "\x04[RPG] \x03This plugin is in process, many features missing", targetid)
	PrintToChat(targetid, "\x04[RPG] \x03You have to choose a new job every round!")
	PrintToChat(targetid, "\x04[RPG] \x03Type \x04!rpgmenu\x03 in chat to show up [Main-Menu]")
	PrintToChat(targetid, "\x04[RPG] \x03[Your Stats] !rpgstats")
	PrintToChat(targetid, "\x04[RPG] \x03[JobMenu] !jobs [Quick Job] !lastjob")
	PrintToChat(targetid, "\x04[RPG] \x03[BuyShop] !buymenu [Quick Buy] !repeatbuy, !healthshop, !ammoshop, !explosiveshop, !pistolshop, !rifleshop, !shotgunshop, !smgshop & !snipershop")
	PrintToChat(targetid, "\x04[RPG] \x03[Special Infected Shop] !buymenu & !specialshop")
}

/* Message: already job shoosen a job this round */
MsgJobLock(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You have already choosen a job this round: \x04%s", CfgJobName[ClientJob[targetid]])
}

/* Message: job comfirmend */
MsgJobConfirmed(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03Job Confirmed: \x04%s", CfgJobName[ClientJob[targetid]])
	PrintToChat(targetid, "\x04[RPG] \x03Basis health set to \x04%d\x03", GetJobHealth(ClientJob[targetid]))
	PrintToChat(targetid, "\x04[RPG] \x03You'll get \x04%d\x03$ Cash, \x04%d\x03 HP, \x04%d\x03 Str, \x04%d\x03 Agi & \x04%d\x03 End on levelup", GetJobCash(ClientJob[targetid]), GetJobHP(ClientJob[targetid]), GetJobStr(ClientJob[targetid]), GetJobAgi(ClientJob[targetid]), GetJobEnd(ClientJob[targetid]))
}

/* Message: job requires bigger level */
MsgJobReqLevel(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03Job: \x04%s\x03 Need Level \x04%d\x03 Your Level: \x04%d\x03", CfgJobName[ClientJob[targetid]], GetJobReqLevel(ClientJobConfirm[targetid]), ClientLevel[targetid])
}

/* Message: information about players job */
MsgPlayersSkills(client, targetid)
{
	PrintToChat(client, "\x04[RPG] \x03Name: \x04%N\x03 Job: \x04%s\x03 Cash: \x04%d\x03", targetid, CfgJobName[ClientJob[targetid]], ClientCash[targetid])
	PrintToChat(client, "\x04[RPG] \x03Level: \x04%d\x03 JobLevel: \x04%d\x03", ClientLevel[targetid], ClientLevelJob[targetid][ClientJob[targetid]])
	PrintToChat(client, "\x04[RPG] \x03Health: \x04%d\x03/\x04%d\x03 HP", GetEntData(targetid, FindDataMapOffs(targetid, "m_iHealth"), 4), (GetJobHealth(ClientJob[targetid])+ClientHealBonus[targetid]))
	PrintToChat(client, "\x04[RPG] \x03BasisHealth: \x04%d\x03 HP & BonusHealth: \x04%d\x03 HP", GetJobHealth(ClientJob[targetid]), ClientHealBonus[targetid])
	PrintToChat(client, "\x04[RPG] \x03Str: +\x04%d\x03% dmg, Agi: +\x04%d\x03% speed", ClientStrength[targetid], ClientAgility[targetid])
	
	if(GetConVarInt(CfgSkillEnduranceReflectOnly) == 1)
	{
		PrintToChat(client, "\x04[RPG] \x03Endurance: \x04%d\x03% Reflect", ClientEndurance[targetid])	
	}
	else
	{
		if(ClientEndurance[targetid] <= GetConVarInt(CfgSkillEnduranceShieldLimit))
		{
		PrintToChat(client, "\x04[RPG] \x03Endurance: \x04%d\x03% Shield", ClientEndurance[targetid])
		}
		else
		{
				PrintToChat(client, "\x04[RPG] \x03Endurance: \x04%d\x03% \x05 Shield & \x04%d\x03% Reflect", ClientEndurance[targetid], (ClientEndurance[targetid]-GetConVarInt(CfgSkillEnduranceShieldLimit)))
		}
	}
}

/* Rob Successful */
MsgRobSuccessful(targetclient, victim, cash)
{
	PrintToChat(targetclient, "\x04[RPG] \x03Robbed \x04%N\x03 successful, you captured \x04%d\x03% cash", victim, cash)
	PrintToChat(targetclient, "\x04[RPG] \x03type !exchange to convert cash into bloodpoints")	
}

/* Rob Victim */
MsgRobVitctim(targetclient, robber, cash)
{
	PrintToChat(targetclient, "\x04[RPG] \x03You've been robbed by \x04%N\x03, you lost \x04%d\x03% cash", robber, cash)
}

/* Special Kill Report Job */
MsgSpecialKillReport(killed, killer, bool:headshot)
{
	if(headshot)
	{
		PrintToChat(killed, "\x04[RPG] \x03You got killed by a \x04%s\x03 (Headshot)", CfgJobName[ClientJob[killer]])
	}
	else
	{
		PrintToChat(killed, "\x04[RPG] \x03You got killed by a \x04%s\x03", CfgJobName[ClientJob[killer]])
	}
}

/* Message: information about specific job */
MsgJobInfo(targetid, jobid)
{
	PrintToChat(targetid, "\x04[RPG] \x03JobInfo about JobID: \x04%d\x03",jobid)
	new hpmode = GetConVarInt(CfgSkillHealthMode)
	new skillmode = GetConVarInt(CfgSkillMode)
	
	if(hpmode == 1) //Mode 1: Incease Only Health
	{
		PrintToChat(targetid, "\x04[RPG] \x03Max Health: \x04%d\x03HP(+\x04%d\x03 to \x05Health \x03on level up)", GetJobHealth(jobid), GetJobHP(jobid))
	}
	if(hpmode == 2) //Mode 2: Increase Only Max Health
	{
		PrintToChat(targetid, "\x04[RPG] \x03Max Health: \x04%d\x03HP(+\x04%d\x03 to \x05Max Health \x03on level up)", GetJobHealth(jobid), GetJobHP(jobid))
	}
	if(hpmode == 3) //Mode 3: Increase Health & Max Health
	{
		PrintToChat(targetid, "\x04[RPG] \x03Max Health: \x04%d\x03HP(+\x04%d\x03 to \x05Health & Max Health \x03on level up)", GetJobHealth(jobid), GetJobHP(jobid))
	}
	if(skillmode == 1) //Mode 1: Job skill on level up
	{
		PrintToChat(targetid, "\x04[RPG] \x03Strength: +\x04%d\x03% \x05dmg \x03& Agi: +\x04%d\x03% \x05movement speed \x03on level up", GetJobStr(jobid), GetJobAgi(jobid))
		PrintToChat(targetid, "\x04[RPG] \x03Endurance: -\x04%d\x03% \x05dmg (shield) and & if End > 50 \x04%d\x03% \x05dmg reflect \x03on level up", GetJobEnd(jobid), GetJobEnd(jobid))
	}
	if(skillmode == 2) //Mode 2: Job skill on job select
	{
		PrintToChat(targetid, "\x04[RPG] \x03Strength: +\x04%d\x03% \x05dmg \x03& Agi: +\x04%d\x03% \x05movement speed", GetJobStr(jobid), GetJobAgi(jobid))
		PrintToChat(targetid, "\x04[RPG] \x03Endurance: -\x04%d\x03% \x05dmg (shield) and & if End > 50 \x04%d\x03% \x05dmg reflect", GetJobEnd(jobid), GetJobEnd(jobid))
	}
}

/* Message: on levelup */
MsgLevelUp(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03Your level has increased to \x04%d", ClientLevel[targetid])
}

/* Message: remind to chaoose a job */
MsgChooseAJob(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You should definitely choose a job!")
	PrintToChat(targetid, "\x04[RPG] \x03Type \x04!jobmenu\x03 in chat to see [Job-Menu]")
}

/* Message: exchange successful */
MsgExchangeSuccess(targetid, reqamount, newamount)
{
	if(GetClientTeam(targetid) == TEAM_INFECTED)
	{
		PrintToChat(targetid, "\x04[RPG] \x03You god \x04%d\x03% points and lost \x04%d\x03% cash", newamount, reqamount)
	}
	else if(GetClientTeam(targetid) == TEAM_SURVIVORS)
	{
		PrintToChat(targetid, "\x04[RPG] \x03You god \x04%d\x03% cash and lost \x04%d\x03% points", newamount, reqamount)
	}
}

/* Message: exchange failed */
MsgExchangeFail(targetid, reqamount)
{
	if(GetClientTeam(targetid) == TEAM_INFECTED)
	{
		PrintToChat(targetid, "\x04[RPG] \x03Exchange failed, need \x04%d\x03% cash", reqamount)
	}
	else if(GetClientTeam(targetid) == TEAM_SURVIVORS)
	{
		PrintToChat(targetid, "\x04[RPG] \x03Exchange failed, need \x04%d\x03% points", reqamount)
	}
}

/* Message: killing a witch */
MsgExpWitchKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Witch\x03!", GetConVarInt(CfgExpWitchKilled))
}

/* Message: killing a witch */
MsgExpWitchSurvived(targetid, killer)
{
	PrintToChat(targetid, "\x04[RPG] \x03You Survived a Witch and got \x04%d\x03 EXP, but \x05%N\x03 has killed the witch and got \x04%d\x03 EXP", GetConVarInt(CfgExpWitchSurvived), killer, GetConVarInt(CfgExpWitchKilled))
}

/* Message: defibrillator used */
MsgExpDefUsed(targetid, subject)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by reanimating \x04%N\x03!", GetConVarInt(CfgExpReanimateTeammate), subject)
}

/* Message: revive somebody */
MsgExpRevive(targetid, subject)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by reviving \x04%N\x03!", GetConVarInt(CfgExpReviveTeammate), subject)
}

/* Message: heal somebody */
MsgExpHeal(targetid, subject)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by healing \x04%N\x03!", GetConVarInt(CfgExpHealTeammate), subject)
}

/* Message: killing a Tank */
MsgExpTankKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Tank\x03!", GetConVarInt(CfgExpTankKilled))
}

/* Message: surviveing a Tank */
MsgExpTankSurvive(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by surviving a \x04Tank\x03!", GetConVarInt(CfgExpTankSurvived))
}

/* Message: killing a Charger */
MsgExpChargerKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Charger\x03!", GetConVarInt(CfgExpChargerKilled))
}

/* Message: killing a Jockey */
MsgExpJockeyKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Jockey\x03!", GetConVarInt(CfgExpJockeyKilled))
}

/* Message: killing a Spitter */
MsgExpSpitterKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Spitter\x03!", GetConVarInt(CfgExpSpitterKilled))
}

/* Message: killing a Hunter */
MsgExpHunterKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Hunter\x03!", GetConVarInt(CfgExpHunterKilled))
}

/* Message: killing a Boomer */
MsgExpBoomerKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Boomer\x03!", GetConVarInt(CfgExpBoomerKilled))
}

/* Message: killing a Smoker */
MsgExpSmokerKilled(targetid)
{
	PrintToChat(targetid, "\x04[RPG] \x03You got \x04%d\x03 EXP by killing a \x04Smoker\x03!", GetConVarInt(CfgExpSmokerKilled))
}

/* Message: buy failed */
MsgBuyFailed(targetid)
{
	PrintToChat(targetid,"\x04[RPG] \x03Buy failed!")
}


/* Message: buy disabled */
MsgBuyDisabled(targetid)
{
	PrintToChat(targetid,"\x04[RPG] \x03Buy failed!")
}

GetJobAgi(jobid)
{
	return GetConVarInt(CfgJobAgility[jobid])
}

GetJobCash(jobid)
{
	return GetConVarInt(CfgJobCash[jobid])
}

GetJobEnd(jobid)
{
	return GetConVarInt(CfgJobEndurance[jobid])
}

GetJobHealth(jobid)
{
	return GetConVarInt(CfgJobHealthBasis[jobid])
}

GetJobHealthMax(targetid) //Job Basis Health + Temp HP Skill
{
	new MaxHealth = (GetJobHealth(ClientJob[targetid])+ClientHealBonus[targetid])
	new hl = GetConVarInt(CfgSkillHealthLimit)
	if(MaxHealth > hl && hl != 0)
	{
		MaxHealth = hl
	}
	return MaxHealth
}

GetJobHP(jobid)
{
	return GetConVarInt(CfgJobHealthBonus[jobid])
}

GetJobReqLevel(jobid)
{
	return GetConVarInt(CfgJobReqLevel[jobid])
}

GetJobStr(jobid)
{
	return GetConVarInt(CfgJobStrength[jobid])
}


/* Is Player Valid */
ClientIsValid(client)
{
	if (client == 0)
		return false

	if (!IsClientConnected(client))
		return false
	
	if (IsFakeClient(client))
		return false

	if (!IsValidEntity(client))
	return false
	return true
}

/* Is Player Tank*/
bool:ClientIsTank(client)
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

/* Level Up */
ClientLevelUp(targetid, bool:templevelonly)
{
	/* Level */
	ClientLevelTemp[targetid] += 1
	MsgLevelUp(targetid)
	if(!templevelonly)
	{
		ClientLevel[targetid] += 1
		ClientLevelJob[targetid][ClientJob[targetid]] += 1
	}
	
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

ClientSetExchangeSpecial(client, itemNum)
{
	new reqcash
	new newpoints
	new tax
	switch (itemNum)
	{
		case 0: //100
		{
			reqcash = 100
			newpoints = 10
		}
		case 1: //500
		{
			reqcash = 500
			newpoints = 60
		}
		case 2: //1000
		{
			reqcash = 1000
			newpoints = 130
		}
		case 3: //5000
		{
			reqcash = 5000
			newpoints = 777
		}
		case 4: //10000
		{
			reqcash = 10000
			newpoints = 1777
		}
	}
	tax = RoundToNearest(newpoints*20*0.01)
	newpoints -= tax
	
	if(ClientCash[client] >= reqcash)
	{
		ClientCash[client] -= reqcash
		ClientPoints[client] += newpoints
		MsgExchangeSuccess(client, reqcash, newpoints)
	}
	else
	{
		MsgExchangeFail(client, reqcash)
	}
}

ClientSetExchangeSurvivor(client, itemNum)
{
	new newcash
	new reqpoints
	new tax
	switch (itemNum)
	{
		case 0: //10
		{
			reqpoints = 10
			newcash = 100
		}
		case 1: //50
		{
			reqpoints = 50
			newcash = 600
		}
		case 2: //100
		{
			reqpoints = 100
			newcash = 1300
		}
		case 3: //500
		{
			reqpoints = 500
			newcash = 6777
		}
		case 4: //1000
		{
			reqpoints = 1000
			newcash = 17777
		}
	}
	tax = RoundToNearest(reqpoints*20*0.01)
	newcash -= tax
	
	if(ClientPoints[client] >= reqpoints)
	{
		ClientPoints[client] -= reqpoints
		ClientCash[client] += newcash
		MsgExchangeSuccess(client, reqpoints, newcash)
	}
	else
	{
		MsgExchangeFail(client, reqpoints)
	}
}

ClientSetHealth(targetid, amount)
{
	if(targetid != 0 && !IsFakeClient(targetid))
	{
		SetEntData(targetid, FindDataMapOffs(targetid, "m_iHealth"), amount, 4, true)
	}
}

ClientSetHealthMax(targetid, amount)
{
	if(targetid != 0 && !IsFakeClient(targetid))
	{
		SetEntData(targetid, FindDataMapOffs(targetid, "m_iMaxHealth"), amount, 4, true)		
	}
}

ClientSetStrDamage(client, health, str)
{
	if(health > str)
	{
		SetEntityHealth(client, health-str)
	}
}

ClientRebuildSkills(client)
{
	if(ClientLockAgiligy[client] == 0)
	{
		ClientSetHealthMax(client, GetJobHealthMax(client))
		ClientSetAgility(client)
	}
}

ClientResetAgility(targetid)
{
	SetEntityGravity(targetid, 1.0)
	SetEntDataFloat(targetid, MOffset, 1.0, true)
}

ClientResetTemp(targetid)
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

ClientRob(client, targetclient)
{
	if(client != 0 && targetclient != 0 && !IsFakeClient(client))
	{
		if(GetClientTeam(client) == TEAM_INFECTED && GetClientTeam(targetclient) == TEAM_SURVIVORS)
		{
			if(IsFakeClient(targetclient))
			{
				ClientCash[client] += GetConVarInt(CfgRobBot)
			}
			else
			{
				new robfloat = 0
				
				switch(ClientRobLevel[client])
				{
					case 0: //Rob Level 0
					{
						robfloat += 1
					}
					case 1: //Rob Level 1
					{
						robfloat += 2
					}
					case 2: //Rob Level 2
					{
						robfloat += 3
					}
					case 3: //Rob Level 3
					{
						robfloat += 5
					}
					case 4: //Rob Level 4
					{
						robfloat += 7
					}
					case 5: //Rob Level 5
					{
						robfloat += 10
					}
					case 6: //Rob Level 6
					{
						robfloat += 13
					}
					case 7: //Rob Level 7
					{
						robfloat += 16
					}
					case 8: //Rob Level 8
					{
						robfloat += 20
					}
					case 9: //Rob Level 9
					{
						robfloat += 25
					}
					case 10: //Rob Level 10
					{
						robfloat += 33
					}
				}
				
				new robcash = RoundToNearest(ClientCash[targetclient]*robfloat*0.01)
				ClientCash[client] += robcash
				ClientCash[targetclient] -= robcash
				ClientSaveToFileSave(client)
				ClientSaveToFileSave(targetclient)
				MsgRobSuccessful(client, targetclient, robcash)
				MsgRobVitctim(targetclient, client, robcash)
			}
		}
	}
}

/* Load Save From File */
ClientSaveToFileLoad(targetid)
{
	new savetofilemode = GetConVarInt(CfgSaveToFileMode)
	if(savetofilemode != 0)
	{
		if(ClientIsValid(targetid))
		{
			/* Identify Client */
			decl String:user_name[MAX_NAME_LENGTH]=""
			if(savetofilemode == 1) // Identify Key: Name
			{
				GetClientName(targetid, user_name, sizeof(user_name))
				ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}")//DQM Double quotation mark
				ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}")//SQM Single quotation mark
				ReplaceString(user_name, sizeof(user_name), "/*", "{SST}")//SST Slash Star
				ReplaceString(user_name, sizeof(user_name), "*/", "{STS}")//STS Star Slash
				ReplaceString(user_name, sizeof(user_name), "//", "{DSL}")//DSL Double Slash
			}
			else if(savetofilemode == 2) // Identify Key: Steam-ID
			{
				GetClientAuthString(targetid, user_name, sizeof(user_name))
			}
			KvJumpToKey(RPGSave, user_name, true)
			ClientLevel[targetid] = KvGetNum(RPGSave, "Basic Level", 0)
			ClientCash[targetid] = KvGetNum(RPGSave, "Cash", 0)
			ClientPoints[targetid] = KvGetNum(RPGSave, "Points", 0)
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

/* Save To File */
ClientSaveToFileSave(targetid)
{
	new savetofilemode = GetConVarInt(CfgSaveToFileMode)
	if(savetofilemode != 0)
	{
		if(ClientIsValid(targetid))
		{
			/* Identify Client */
			decl String:user_name[MAX_NAME_LENGTH]=""
			if(savetofilemode == 1) // Identify Key: Name
			{
				GetClientName(targetid, user_name, sizeof(user_name))
				ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}")//DQM Double quotation mark
				ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}")//SQM Single quotation mark
				ReplaceString(user_name, sizeof(user_name), "/*", "{SST}")//SST Slash Star
				ReplaceString(user_name, sizeof(user_name), "*/", "{STS}")//STS Star Slash
				ReplaceString(user_name, sizeof(user_name), "//", "{DSL}")//DSL Double Slash
			}
			else if(savetofilemode == 2) // Identify Key: Steam-ID
			{
				GetClientAuthString(targetid, user_name, sizeof(user_name))
			}
			
			/* Load Saves */
			KvJumpToKey(RPGSave, user_name, true)
			KvSetNum(RPGSave, "Basic Level", ClientLevel[targetid])
			KvSetNum(RPGSave, "Cash", ClientCash[targetid])
			KvSetNum(RPGSave, "Points", ClientPoints[targetid])
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
				ClientLevelUp(targetid, false)
			}
		}
		if(GetConVarInt(CfgExpMode) == 2) // Keep EXP + multiply required EXP by job level
		{
			if(TargetEXP >= (GetConVarInt(CfgExpLevelUp)*(ClientLevelTemp[targetid]+1)))
			{
				ClientLevelUp(targetid, false)
			}
		}
		if(GetConVarInt(CfgExpMode) == 3) // Subtract EXP + multiply required EXP by job level
		{
			if(TargetEXP >= (GetConVarInt(CfgExpLevelUp)*(ClientLevelTemp[targetid])))
			{
				ClientEXP[targetid] -= GetConVarInt(CfgExpLevelUp)*(ClientLevelTemp[targetid])
				ClientLevelUp(targetid, false)
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

public Action:MenuFunc_BuyConfirm(clientId) 
{
	new cost
	switch (ClientBuyConfirm[clientId])
	{
		case 0: //shotgun
		{
			cost = GetConVarInt(CfgShopShotgunCost)
		}
		case 1: //smg
        {
			cost = GetConVarInt(CfgShopSmgCost)
        }
		case 2: //rifle
        {
            cost = GetConVarInt(CfgShopRifleCost)
        }
		case 3: //hunting rifle
		{
			cost = GetConVarInt(CfgShopHuntingCost)
		}
		case 4: //auto shotgun
		{
			cost = GetConVarInt(CfgShopShotgunAutoCost)
		}
		case 5: //pipe bomb
		{
			cost = GetConVarInt(CfgShopPipeCost)
		}
		case 6: //molotov
		{
			cost = GetConVarInt(CfgShopMolotovCost)
		}
		case 7: //extra pistol
		{
			cost = GetConVarInt(CfgShopPistolCost)
		}
		case 8: //pills
		{
			cost = GetConVarInt(CfgShopPillsCost)
		}
		case 9: //medkit
		{
			cost = GetConVarInt(CfgShopMedikitCost)
		}
		case 10: //refill
		{
			cost = GetConVarInt(CfgShopRefillCost)
		}
		case 11: //heal
		{
			cost = GetConVarInt(CfgShopHealCost)
		}
		case 12: //suicide
		{
			cost = GetConVarInt(CfgShopSuicideCost)
		}
		case 13: //iheal
		{
			cost = GetConVarInt(CfgShopInfHealCost)
		}
		case 14: //boomer
		{
			cost = GetConVarInt(CfgShopBoomerCost)
		}
		case 15: //hunter
		{
			cost = GetConVarInt(CfgShopHunterCost)
		}
		case 16: //smoker
		{
			cost = GetConVarInt(CfgShopSmokerCost)
		}
		case 17: //tank
		{
			cost = GetConVarInt(CfgShopTankCost)
		}
		case 18: //witch
		{
			cost = GetConVarInt(CfgShopWitchCost)
		}
		case 19: //mob
		{
			cost = GetConVarInt(CfgShopMobCost)
		}
		case 20: //panic
		{
			cost = GetConVarInt(CfgShopPanicCost)
		}
		case 21: //incendiary
		{
			cost = GetConVarInt(CfgShopIncendiaryCost)
		}
		case 22: //incendiary pack
		{
			cost = GetConVarInt(CfgShopIncendiaryPackCost)
		}
		case 23: //adrenaline
		{
			cost = GetConVarInt(CfgShopAdrenalineCost)
		}
		case 24: //defib
		{
			cost = GetConVarInt(CfgShopDefibCost)
		}
		case 25: //spas shotgun
		{
			cost = GetConVarInt(CfgShopShotgunSpasCost)
		}
		case 26: //chrome shotgun
		{
			cost = GetConVarInt(CfgShopShotgunChromeCost)
		}
		case 27: //magnum
		{
			cost = GetConVarInt(CfgShopMagnumCost)
		}
		case 28: //ak47
		{
			cost = GetConVarInt(CfgShopAk47Cost)
		}
		case 29: //desert rifle
		{
			cost = GetConVarInt(CfgShopDesertCost)
		}
		case 30: //sg552
		{
			cost = GetConVarInt(CfgShopSg552Cost)
		}
		case 31: //silenced smg
		{
			cost = GetConVarInt(CfgShopSmgSilencedCost)
		}
		case 32: //mp5
		{
			cost = GetConVarInt(CfgShopMp5Cost)
		}
		case 33: //awp
		{
			cost = GetConVarInt(CfgShopAwpCost)
		}
		case 34: //military sniper
		{
			cost = GetConVarInt(CfgShopMilitaryCost)
		}
		case 35: //scout sniper
		{
			cost = GetConVarInt(CfgShopScoutCost)
		}
		case 36: //grenade launcher
		{
			cost = GetConVarInt(CfgShopGrenadeLauncherCost)
		}
		case 37: //firework crate
		{
			cost = GetConVarInt(CfgShopFireworkCost)
		}
		case 38: //vomitjar
		{
			cost = GetConVarInt(CfgShopVomitjarCost)
		}
		case 39: //oxygen tank
		{
			cost = GetConVarInt(CfgShopOxygenCost)
		}
		case 40: //propane tank
		{
			cost = GetConVarInt(CfgShopPropaneCost)
		}
		case 41: //explosive pack
		{
			cost = GetConVarInt(CfgShopExplosivePackCost)
		}
		case 42: //chainsaw
		{
			cost = GetConVarInt(CfgShopChainsawCost)
		}
		case 43: //gascan
		{
			cost = GetConVarInt(CfgShopGascanCost)
		}
		case 44: //spitter
		{
			cost = GetConVarInt(CfgShopSpitterCost)
		}
		case 45: //charger
		{
			cost = GetConVarInt(CfgShopChargerCost)
		}
		case 46: //jockey
		{
			cost = GetConVarInt(CfgShopJockeyCost)
		}
		case 47: //explosive
		{
			cost = GetConVarInt(CfgShopExplosiveCost)
		}
		
		case 48: //laser upgrade
		{
			cost = GetConVarInt(CfgShopLaserCost)
		}
	}
	new Handle:menu = CreateMenu(MenuHandler_BuyConfirm)
	SetMenuTitle(menu, "Cost: %d", cost)
	AddMenuItem(menu, "option1", "Yes")
	AddMenuItem(menu, "option2", "No")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_ItemShop(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShop)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "Health Shop")
	AddMenuItem(menu, "option2", "SMG Shop")
	AddMenuItem(menu, "option3", "Rifle Shop")
	AddMenuItem(menu, "option4", "Sniper Shop")
	AddMenuItem(menu, "option5", "Shotgun Shop")
	AddMenuItem(menu, "option6", "Pistol/Special Shop")
	AddMenuItem(menu, "option7", "Explosives")
	AddMenuItem(menu, "option8", "Ammo Shop")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)

	return Plugin_Handled
}

public Action:MenuFunc_ItemShopAmmo(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopAmmo)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "Incendiary Ammo")
	AddMenuItem(menu, "option2", "Incendiary Ammo Pack")
	AddMenuItem(menu, "option3", "Explosive Ammo Pack")
	AddMenuItem(menu, "option4", "Explosive Ammo")
	AddMenuItem(menu, "option5", "Refill")
	AddMenuItem(menu, "option6", "Laser Sight")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)

	return Plugin_Handled
}

public Action:MenuFunc_ItemShopExplosive(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopExplosive)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "Pipebomb")
	AddMenuItem(menu, "option2", "Molotov")
	AddMenuItem(menu, "option3", "Vomitjar")
	AddMenuItem(menu, "option4", "Gascan")
	AddMenuItem(menu, "option5", "Propane Tank")
	AddMenuItem(menu, "option6", "Fireworks Crate")
	AddMenuItem(menu, "option7", "Oxygen Tank")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
    
	return Plugin_Handled
}

public Action:MenuFunc_ItemShopHealth(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopHealth)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "Adrenaline")
	AddMenuItem(menu, "option2", "Medkit")
	AddMenuItem(menu, "option3", "Pain Pills")
	AddMenuItem(menu, "option4", "Defib")
	AddMenuItem(menu, "option5", "Full Health")
	AddMenuItem(menu, "option6", "Back")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_ItemShopPistol(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopPistol)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	
	AddMenuItem(menu, "option1", "Pistol")
	AddMenuItem(menu, "option2", "Magnum")
	AddMenuItem(menu, "option3", "Grenade Launcher")
	AddMenuItem(menu, "option4", "Chainsaw")
	AddMenuItem(menu, "option5", "Back")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_ItemShopRifle(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopRifle)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "M4 Assualt Rifle")
	AddMenuItem(menu, "option2", "Desert Rifle")
	AddMenuItem(menu, "option3", "AK47")
	AddMenuItem(menu, "option4", "SG552")
	AddMenuItem(menu, "option5", "Back")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_ItemShopShotgun(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopShotgun)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "Pump Shotgun")
	AddMenuItem(menu, "option2", "Chrome Shotgun")
	AddMenuItem(menu, "option3", "Auto Shotgun")
	AddMenuItem(menu, "option4", "Spas Shotgun")
	AddMenuItem(menu, "option5", "Back")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_ItemShopSmg(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopSmg)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "SMG")
	AddMenuItem(menu, "option2", "Silenced SMG")
	AddMenuItem(menu, "option3", "MP5 SMG")
	AddMenuItem(menu, "option4", "Back")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_ItemShopSniper(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemShopSniper)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "Hunting Rifle")
	AddMenuItem(menu, "option2", "AWP Sniper")
	AddMenuItem(menu, "option3", "Military Sniper")
	AddMenuItem(menu, "option4", "Scout Sniper")
	AddMenuItem(menu, "option5", "Back")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_Job(targetid) 
{
	new Handle:menu = CreateMenu(MenuHandler_Job)
	SetMenuTitle(menu, "Level: %d | NextLv: -%dExp", ClientLevel[targetid], (GetConVarInt(CfgExpLevelUp)-ClientEXP[targetid]))
	AddMenuItem(menu, "option1", "Last Job")
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

public Action:MenuFunc_JobConfirm(targetid)
{
	new Handle:menu = CreateMenu(MenuHandler_JobConfirm)
	SetMenuTitle(menu, "Need Level: %d", GetJobReqLevel(ClientJobConfirm[targetid]))
	AddMenuItem(menu, "option1", "Yes")
	AddMenuItem(menu, "option2", "No")
	AddMenuItem(menu, "option2", "Jobinfo")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_RPG(targetid) 
{
	new Handle:menu = CreateMenu(MenuHandler_RPG)
	if(GetClientTeam(targetid)== TEAM_SURVIVORS)
	{
		SetMenuTitle(menu, "Level: %d | Cash: %d | EXP: %d", ClientLevel[targetid], ClientCash[targetid], ClientEXP[targetid])
		AddMenuItem(menu, "option1", "Buy Shop")
		AddMenuItem(menu, "option2", "Exchange Menu")
		AddMenuItem(menu, "option3", "Job Menu")
	}
	else if(GetClientTeam(targetid)== TEAM_INFECTED)
	{
		SetMenuTitle(menu, "Level: %d | Points: %d", ClientLevel[targetid], ClientPoints[targetid], ClientEXP[targetid])
		AddMenuItem(menu, "option1", "Buy Shop")
		AddMenuItem(menu, "option2", "Exchange Menu")
	}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_SpecialShop(clientId)
{
	new Handle:menu = CreateMenu(MenuHandler_SpecialShop)
	SetMenuTitle(menu, "Cash: %d", ClientCash[clientId])
	AddMenuItem(menu, "option1", "Suicide")
	AddMenuItem(menu, "option2", "Heal")
	AddMenuItem(menu, "option3", "Spawn Boomer")
	AddMenuItem(menu, "option4", "Spawn Hunter")
	AddMenuItem(menu, "option5", "Spawn Smoker")
	AddMenuItem(menu, "option6", "Spawn Tank")
	AddMenuItem(menu, "option7", "Spawn Witch")
	AddMenuItem(menu, "option8", "Spawn Mob")
	AddMenuItem(menu, "option9", "Spawn Mega Mob")
	AddMenuItem(menu, "option10", "Spawn Spitter")
	AddMenuItem(menu, "option11", "Spawn Charger")
	AddMenuItem(menu, "option12", "Spawn Jockey")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Action:MenuFunc_Exchange(targetclient)
{
	new Handle:menu = CreateMenu(MenuHandler_Exchange)
	if(GetClientTeam(targetclient) == TEAM_INFECTED)
	{
		SetMenuTitle(menu, "Points: %d | Cash: %d", ClientPoints[targetclient], ClientCash[targetclient])
		AddMenuItem(menu, "option1", "Cash: 10")
		AddMenuItem(menu, "option2", "Cash: 50")
		AddMenuItem(menu, "option3", "Cash: 100")
		AddMenuItem(menu, "option4", "Cash: 500")
		AddMenuItem(menu, "option5", "Cash: 1000")
		AddMenuItem(menu, "option6", "Cash: 5000")
		AddMenuItem(menu, "option7", "Cash: 10000")
		AddMenuItem(menu, "option8", "Cash: 50000")
		AddMenuItem(menu, "option9", "Cash: 100000")
	}
	else if(GetClientTeam(targetclient) == TEAM_SURVIVORS)
	{
		SetMenuTitle(menu, "Cash: %d | Points: %d", ClientCash[targetclient], ClientPoints[targetclient])
		AddMenuItem(menu, "option1", "Points: 100")
		AddMenuItem(menu, "option2", "Points: 500")
		AddMenuItem(menu, "option3", "Points: 1000")
		AddMenuItem(menu, "option4", "Points: 5000")
		AddMenuItem(menu, "option5", "Points: 10000")
		AddMenuItem(menu, "option6", "Points: 50000")
		AddMenuItem(menu, "option7", "Points: 100000")
		AddMenuItem(menu, "option8", "Points: 5000000")
		AddMenuItem(menu, "option9", "Points: 10000000")
	}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetclient, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public MenuHandler_BuyConfirm(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give")
	new flags2 = GetCommandFlags("kill")
	new upgradeflags = GetCommandFlags("upgrade_add")
	new flags3 = GetCommandFlags("z_spawn")
	new flags4 = GetCommandFlags("director_force_panic_event")
	SetCommandFlags("give", flags & ~FCVAR_CHEAT)
	SetCommandFlags("upgrade_add", upgradeflags & ~FCVAR_CHEAT)
	SetCommandFlags("kill", flags2 & ~FCVAR_CHEAT)
	SetCommandFlags("z_spawn", flags3 & ~FCVAR_CHEAT)
	SetCommandFlags("director_force_panic_event", flags4 & ~FCVAR_CHEAT)
    
	if (action == MenuAction_Select) 
	{
        if(itemNum == 0)
		{
			switch(ClientBuyConfirm[client])
			{
				case 0: //shotgun
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopShotgunCost))
					{
						//Give the player a shotgun
						FakeClientCommand(client, "give pumpshotgun")
						ClientCash[client] -= GetConVarInt(CfgShopShotgunCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 1: //smg
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopSmgCost))
					{
						//Give the player an SMG
						FakeClientCommand(client, "give smg")
						ClientCash[client] -= GetConVarInt(CfgShopSmgCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 2: //rifle
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopRifleCost))
					{
						//Give the player a rifle
						FakeClientCommand(client, "give rifle")
						ClientCash[client] -= GetConVarInt(CfgShopRifleCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 3: //hunting rifle
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopHuntingCost))
					{
						//Give the player a hunting rifle
						FakeClientCommand(client, "give hunting_rifle")
						ClientCash[client] -= GetConVarInt(CfgShopHuntingCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 4: //auto shotgun
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopShotgunAutoCost))
					{
						//Give the player an auto shotgun
						FakeClientCommand(client, "give autoshotgun")
						ClientCash[client] -= GetConVarInt(CfgShopShotgunAutoCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 5: //pipe bomb
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopPipeCost))
					{
						//Give the player a pipebomb
						FakeClientCommand(client, "give pipe_bomb")
						ClientCash[client] -= GetConVarInt(CfgShopPipeCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 6: //molotov
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopMolotovCost))
					{
						//Give the player a molotov
						FakeClientCommand(client, "give molotov")
						ClientCash[client] -= GetConVarInt(CfgShopMolotovCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 7: //pistol
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopPistolCost))
					{
						//Give the player a pistol
						FakeClientCommand(client, "give pistol")
						ClientCash[client] -= GetConVarInt(CfgShopPistolCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 8: //pills
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopPillsCost))
					{
						//Give the player pain pills
						FakeClientCommand(client, "give pain_pills")
						ClientCash[client] -= GetConVarInt(CfgShopPillsCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 9: //medkit
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopMedikitCost))
					{
						//Give the player a medkit
						FakeClientCommand(client, "give first_aid_kit")
						ClientCash[client] -= GetConVarInt(CfgShopMedikitCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 10: //refill
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopRefillCost))
					{
						//Refill ammo
						FakeClientCommand(client, "give ammo")
						ClientCash[client] -= GetConVarInt(CfgShopRefillCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 11: //heal
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopHealCost))
					{
						//Heal player
						FakeClientCommand(client, "give health")
						ClientCash[client] -= GetConVarInt(CfgShopHealCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 12: //suicide
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopSuicideCost))
					{
						//Kill yourself (for boomers & spitters)
						FakeClientCommand(client, "kill")
						ClientPoints[client] -= GetConVarInt(CfgShopSuicideCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 13: //heal
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopInfHealCost))
					{
						//Give the player health
						FakeClientCommand(client, "give health")
						ClientPoints[client] -= GetConVarInt(CfgShopInfHealCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 14: //boomer
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopBoomerCost))
					{
						//Make the player a boomer
						FakeClientCommand(client, "z_spawn boomer auto")
						ClientPoints[client] -= GetConVarInt(CfgShopBoomerCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 15: //hunter
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopHunterCost))
					{
						//Make the player a hunter
						FakeClientCommand(client, "z_spawn hunter auto")
						ClientPoints[client] -= GetConVarInt(CfgShopHunterCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 16: //smoker
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopSmokerCost))
					{
						//Make the player a smoker
						FakeClientCommand(client, "z_spawn smoker auto")
						ClientPoints[client] -= GetConVarInt(CfgShopSmokerCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 17: //tank
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopTankCost))
					{
						CounterTank += 1;
						if (CounterTank < GetConVarInt(CfgShopTankLimit) + 1)
						{
							//Make the player a tank
							FakeClientCommand(client, "z_spawn tank auto")
							ClientPoints[client] -= GetConVarInt(CfgShopTankCost)
						}
						else
						{
							PrintToChat(client,"[SM] Tank limit for the round has been reached!")
						}
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 18: //spawn witch
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopWitchCost))
					{
						CounterWitch += 1;
						if (CounterWitch < GetConVarInt(CfgShopWitchLimit) + 1)
						{
							//Spawn a witch
							FakeClientCommand(client, "z_spawn witch auto")
							ClientPoints[client] -= GetConVarInt(CfgShopWitchCost)
						}
						else
						{
							PrintToChat(client,"[SM] Witch limit for the round has been reached!")
						}
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 19: //spawn mob
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopMobCost))
					{
						//Spawn a mob
						FakeClientCommand(client, "z_spawn mob")
						ClientPoints[client] -= GetConVarInt(CfgShopMobCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 20: //spawn mega mob
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopPanicCost))
					{
						//Spawn a mob
						FakeClientCommand(client, "director_force_panic_event")
						ClientPoints[client] -= GetConVarInt(CfgShopPanicCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 21: //incendiary
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopIncendiaryCost))
					{
						//Give Incendiary Ammo
						FakeClientCommand(client, "upgrade_add INCENDIARY_AMMO")
						ClientCash[client] -= GetConVarInt(CfgShopIncendiaryCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 22: //super incendiary
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopIncendiaryPackCost))
					{
						//Give Super Incendiary
						FakeClientCommand(client, "give upgradepack_incendiary")
						ClientCash[client] -= GetConVarInt(CfgShopIncendiaryPackCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 23: //adrenaline
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopAdrenalineCost))
					{
						//Give the player an adrenaline shot
						FakeClientCommand(client, "give adrenaline")
						ClientCash[client] -= GetConVarInt(CfgShopAdrenalineCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 24: //defib
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopDefibCost))
					{
						//Give the player a defib
						FakeClientCommand(client, "give defibrillator")
						ClientCash[client] -= GetConVarInt(CfgShopDefibCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 25: //spas shotty
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopShotgunSpasCost))
					{
						//Give the player a spas shotty
						FakeClientCommand(client, "give shotgun_spas")
						ClientCash[client] -= GetConVarInt(CfgShopShotgunSpasCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 26: //chrome shotty
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopShotgunChromeCost))
					{
						//Give the player a chrome shotty
						FakeClientCommand(client, "give shotgun_chrome")
						ClientCash[client] -= GetConVarInt(CfgShopShotgunChromeCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 27: //magnum
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopMagnumCost))
					{
						//Give the player a magnum
						FakeClientCommand(client, "give pistol_magnum")
						ClientCash[client] -= GetConVarInt(CfgShopMagnumCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 28: //ak47
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopAk47Cost))
					{
						//Give the player an ak47
						FakeClientCommand(client, "give rifle_ak47")
						ClientCash[client] -= GetConVarInt(CfgShopAk47Cost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 29: //desert
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopDesertCost))
					{
						//Give the player a desert rifle
						FakeClientCommand(client, "give rifle_desert")
						ClientCash[client] -= GetConVarInt(CfgShopDesertCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 30: //sg552
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopSg552Cost))
					{
						//Give the player a sg552
						FakeClientCommand(client, "give rifle_sg552")
						ClientCash[client] -= GetConVarInt(CfgShopSg552Cost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 31: //silenced smg
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopSmgSilencedCost))
					{
						//Give the player a silenced smg
						FakeClientCommand(client, "give smg_silenced")
						ClientCash[client] -= GetConVarInt(CfgShopSmgSilencedCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 32: //mp5
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopMp5Cost))
					{
						//Give the player a mp5
						FakeClientCommand(client, "give smg_mp5")
						ClientCash[client] -= GetConVarInt(CfgShopMp5Cost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 33: //awp sniper
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopAwpCost))
					{
						//Give the player pain pills
						FakeClientCommand(client, "give sniper_awp")
						ClientCash[client] -= GetConVarInt(CfgShopAwpCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 34: //military sniper
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopMilitaryCost))
					{
						//Give the player pain a military sniper
						FakeClientCommand(client, "give sniper_military")
						ClientCash[client] -= GetConVarInt(CfgShopMilitaryCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 35: //scout sniper
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopScoutCost))
					{
						//Give the player a scount sniper
						FakeClientCommand(client, "give sniper_scout")
						ClientCash[client] -= GetConVarInt(CfgShopScoutCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 36: //grenade launcher
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopGrenadeLauncherCost))
					{
						//Give the player a grenade launcher
						FakeClientCommand(client, "give grenade_launcher")
						ClientCash[client] -= GetConVarInt(CfgShopGrenadeLauncherCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 37: //vomitjar
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopVomitjarCost))
					{
						//Give the player a vomitjar
						FakeClientCommand(client, "give vomitjar")
						ClientCash[client] -= GetConVarInt(CfgShopVomitjarCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 38: //firework crate
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopFireworkCost))
					{
						//Give the player a firework crate
						FakeClientCommand(client, "give fireworkcrate")
						ClientCash[client] -= GetConVarInt(CfgShopFireworkCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 39: //oxygentank
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopOxygenCost))
					{
						//Give the player an oxygentank
						FakeClientCommand(client, "give oxygentank")
						ClientCash[client] -= GetConVarInt(CfgShopOxygenCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 40: //propane tank
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopPropaneCost))
					{
						//Give the player a propane tank
						FakeClientCommand(client, "give propanetank")
						ClientCash[client] -= GetConVarInt(CfgShopPropaneCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 41: //explosive ammo
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopExplosivePackCost))
					{
						//Give the player explosive ammo
						FakeClientCommand(client, "give upgradepack_explosive")
						ClientCash[client] -= GetConVarInt(CfgShopExplosivePackCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 42: //chainsaw
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopChainsawCost))
					{
						//Give the player chainsaw
						FakeClientCommand(client, "give chainsaw")
						ClientCash[client] -= GetConVarInt(CfgShopChainsawCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 43: //gascan
				{
				   if (ClientCash[client] >= GetConVarInt(CfgShopGascanCost))
					{
						//Give the player gascan
						FakeClientCommand(client, "give gascan")
						ClientPoints[client] -= GetConVarInt(CfgShopGascanCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 44: //spitter
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopSpitterCost))
					{
						//Make the player a smoker
						FakeClientCommand(client, "z_spawn spitter auto")
						ClientPoints[client] -= GetConVarInt(CfgShopSpitterCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 45: //charger
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopChargerCost))
					{
						//Make the player a charger
						FakeClientCommand(client, "z_spawn charger auto")
						ClientPoints[client] -= GetConVarInt(CfgShopChargerCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 46: //jockey
				{
					if (ClientPoints[client] >= GetConVarInt(CfgShopJockeyCost))
					{
						//Make the player a smoker
						FakeClientCommand(client, "z_spawn jockey auto")
						ClientPoints[client] -= GetConVarInt(CfgShopJockeyCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 47: //explosive
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopExplosiveCost))
					{
						//Give Incendiary Ammo
						FakeClientCommand(client, "upgrade_add EXPLOSIVE_AMMO")
						ClientCash[client] -= GetConVarInt(CfgShopExplosiveCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
				case 48: //laser
				{
					if (ClientCash[client] >= GetConVarInt(CfgShopLaserCost))
					{
						//Give Incendiary Ammo
						FakeClientCommand(client, "upgrade_add LASER_SIGHT")
						ClientCash[client] -= GetConVarInt(CfgShopLaserCost)
					}
					else
					{
						MsgBuyFailed(client)
					}
				}
			}
		}
    }
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	SetCommandFlags("kill", flags2|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flags3|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", upgradeflags|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4|FCVAR_CHEAT);
}

public MenuHandler_BuyShop(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		switch (itemNum)
		{
			case 0: //normal
			{
				FakeClientCommand(client,"itemshop")
			}
			case 1: //special
			{
				FakeClientCommand(client,"specialshop")
			}
		}
	}
}

public MenuHandler_ItemShop(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
	{
        switch (itemNum)
        {
            case 0: //health
            {
				FakeClientCommand(client, "healthshop")
			}
            case 1: //smgs
            {
				FakeClientCommand(client, "smgshop")
            }
            case 2: //rifle
            {
				FakeClientCommand(client, "rilfeshop")
            }
			case 3: //sniper rifles
            {
				FakeClientCommand(client, "snipershop")
            }
			case 4: //shotguns
            {
				FakeClientCommand(client, "shotgunshop")
            }
			case 5: //pistols
            {
				FakeClientCommand(client, "pistolshop")
            }
			case 6: //explosives
			{
				FakeClientCommand(client, "explosiveshop")
			}
			case 7: //Ammo
			{
				FakeClientCommand(client, "ammoshop")
			}
        }
    }
}

public MenuHandler_ItemShopAmmo(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select) 
	{
        switch (itemNum)
        {
            case 0: //incendiary
            {
				if (GetConVarInt(CfgShopIncendiaryCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 21
					FakeClientCommand(client, "buyconfirm")
				}
			}
			case 1: //super incendiary
			{
				if (GetConVarInt(CfgShopIncendiaryPackCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 22
					FakeClientCommand(client, "buyconfirm")
				}
			}		
			case 2: //explosive ammo pack
			{
				if (GetConVarInt(CfgShopExplosivePackCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 41
					FakeClientCommand(client, "buyconfirm")
				}
			}			
			case 3: //explosive ammo
			{
				if (GetConVarInt(CfgShopExplosiveCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 47
					FakeClientCommand(client, "buyconfirm")
				}
			}	
			case 4: //refill ammo
			{
				if (GetConVarInt(CfgShopRefillCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 10
					FakeClientCommand(client, "buyconfirm")
				}
			}	
			case 5: //laser sight
			{
				if (GetConVarInt(CfgShopLaserCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 48
					FakeClientCommand(client, "buyconfirm")
				}
			}
			case 6: //back
			{
				//Go back
				FakeClientCommand(client, "ammoshop")
			}
        }
	}
}

public MenuHandler_ItemShopExplosive(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
	{
        switch (itemNum)
        {
            case 0: //pipebomb
            {
				if (GetConVarInt(CfgShopPipeCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					//Give the player a pipebomb
					ClientBuyConfirm[client] = 5
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //molotov
            {
				if (GetConVarInt(CfgShopMolotovCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 6
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //vomitjar
            {
				if (GetConVarInt(CfgShopVomitjarCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 37
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 3: //Gascan
            {
				if (GetConVarInt(CfgShopGascanCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 43
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 4: //propane tank
            {
				if (GetConVarInt(CfgShopPropaneCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 40
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 5: //firework crate
            {
				if (GetConVarInt(CfgShopFireworkCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 38
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 6: //oxygentank
            {
				if (GetConVarInt(CfgShopOxygenCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 39
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 7: //back
			{
				//Go back
				FakeClientCommand(client, "explosiveshop")
			}
        }
    }
}

public MenuHandler_ItemShopHealth(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
	{
        switch (itemNum)
        {
            case 0: //adrenaline
            {
				if (GetConVarInt(CfgShopAdrenalineCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					//Give the player a adrenaline shot
					ClientBuyConfirm[client] = 23
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //medkit
            {
				if (GetConVarInt(CfgShopMedikitCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 9
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //pain pills
            {
				if (GetConVarInt(CfgShopPillsCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 8
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 3: //defib
            {
				if (GetConVarInt(CfgShopDefibCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 24
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 4: //full health
            {
				if (GetConVarInt(CfgShopHealCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 11
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 5: //back
			{
				//Go back
				FakeClientCommand(client, "healthmenu")
			}
        }
    }
}

public MenuHandler_ItemShopPistol(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
	{
        switch (itemNum)
        {
            case 0: //pistol
            {
				if (GetConVarInt(CfgShopPistolCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					//Give the player a pistol
					ClientBuyConfirm[client] = 7
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //magnum
            {
				if (GetConVarInt(CfgShopMagnumCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 27
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //grenade launcher
            {
				if (GetConVarInt(CfgShopGrenadeLauncherCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 36
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 3: //chainsaw
            {
				if (GetConVarInt(CfgShopChainsawCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 42
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 4: //back
			{
				//Go back
				FakeClientCommand(client, "pistolshop")
			}
        }
    }
}

public MenuHandler_ItemShopRifle(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
	{
        switch (itemNum)
        {
            case 0: //m4 assault
            {
				if (GetConVarInt(CfgShopRifleCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					//Give the player a adrenaline shot
					ClientBuyConfirm[client] = 2
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //desert rifle
            {
				if (GetConVarInt(CfgShopDesertCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 29
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //ak47
            {
				if (GetConVarInt(CfgShopAk47Cost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 28
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 3: //sg552
            {
				if (GetConVarInt(CfgShopSg552Cost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 30
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 4: //back
			{
				//Go back
				FakeClientCommand(client, "riflesop")
			}
        }
    }
}

public MenuHandler_ItemShopShotgun(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select) 
	{
        switch (itemNum)
        {
            case 0: //pump shotty
            {
				if (GetConVarInt(CfgShopShotgunCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 0
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //chrome shotty
            {
				if (GetConVarInt(CfgShopShotgunChromeCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 26
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //auto shotty
            {
				if (GetConVarInt(CfgShopShotgunAutoCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 4
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 3: //spas shotty
            {
				if (GetConVarInt(CfgShopShotgunSpasCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 25
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 4: //back
			{
				//Go back
				FakeClientCommand(client, "shotgunshop")
			}
        }
    }
}

public MenuHandler_ItemShopSmg(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
	{
        switch (itemNum)
        {
            case 0: //smg
            {
				if (GetConVarInt(CfgShopSmgCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					//Give the player a adrenaline shot
					ClientBuyConfirm[client] = 1
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //silenced smg
            {
				if (GetConVarInt(CfgShopSmgSilencedCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 31
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //mp5
            {
				if (GetConVarInt(CfgShopMp5Cost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 32
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 3: //back
			{
				//Go back
				FakeClientCommand(client, "smghop")
			}
        }
    }
}

public MenuHandler_ItemShopSniper(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if (action == MenuAction_Select)
	{
        
        switch (itemNum)
        {
            case 0: //hunting rifle
            {
				if (GetConVarInt(CfgShopHuntingCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					//Give the player a adrenaline shot
					ClientBuyConfirm[client] = 3
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //awp sniper
            {
				if (GetConVarInt(CfgShopAwpCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 33
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //military sniper
            {
				if (GetConVarInt(CfgShopMilitaryCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 34
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 3: //scout
            {
				if (GetConVarInt(CfgShopScoutCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 35
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 4: //back
			{
				//Go back
				FakeClientCommand(client, "snipershop")
			}
        }
    }
}

public MenuHandler_Job(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		if(itemNum == 0)
		{
			FakeClientCommand(client, "jobconfirm")
		}
		else
		{
			ClientJobConfirm[client] = itemNum
			FakeClientCommand(client, "jobconfirm")
		}
	}
}

public MenuHandler_JobConfirm(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		if(itemNum == 0)
		{
			if(ClientLevel[client] >= GetJobReqLevel(ClientJobConfirm[client]) && ClientLockJob[client] == 0 && ClientJobConfirm[client] != 0)
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
					
					ClientSetHealthMax(client, GetJobHealthMax(client))
					ClientSetHealth(client, GetJobHealthMax(client))
					ClientRebuildSkills(client)
					MsgJobConfirmed(client)
				}
				/* Mode 2: Job skill on job select */
				if(GetConVarInt(CfgSkillMode) == 2)
				{
					ClientStrength[client] = GetJobStr(ClientJob[client])
					ClientAgility[client] = GetJobAgi(ClientJob[client])
					ClientEndurance[client] = GetJobEnd(ClientJob[client])
					
					ClientSetHealthMax(client, GetJobHealthMax(client))
					ClientSetHealth(client, GetJobHealthMax(client))
					ClientRebuildSkills(client)
					MsgJobConfirmed(client)
				}
			}
			else if(ClientJob[client] != 0)
			{
				MsgJobLock(client)
				FakeClientCommand(client,"jobmenu")
			}
			else if(ClientLevel[client] < GetJobReqLevel(ClientJobConfirm[client]))
			{
				MsgJobReqLevel(client)
				FakeClientCommand(client,"jobmenu")
			}
		}
		else if(itemNum == 1)
		{
			FakeClientCommand(client,"jobmenu")
		}
		else if(itemNum == 2)
		{
			MsgJobInfo(client, ClientJobConfirm[client])
			FakeClientCommand(client,"jobconfirm")
		}
	}
}

public MenuHandler_RPG(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		if(GetClientTeam(client) == TEAM_INFECTED)
		{
			switch (itemNum)
			{
				case 0:
				{
					FakeClientCommand(client,"buyshop")
				}
				case 1:
				{
					FakeClientCommand(client,"exchange")
				}
				case 2:
				{
					FakeClientCommand(client,"upgradeshop")
				}
			}
		}
		else if(GetClientTeam(client) == TEAM_SURVIVORS)
		{
			switch (itemNum)
			{
				case 0:
				{
					FakeClientCommand(client,"buyshop")
				}
				case 1:
				{
					FakeClientCommand(client,"exchange")
				}
				case 2:
				{
					FakeClientCommand(client,"jobmenu")
				}
			}
		}
	}
}

public MenuHandler_SpecialShop(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
	{
        switch (itemNum)
        {
            case 0: //suicide
            {
				if (GetConVarInt(CfgShopSuicideCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 12
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 1: //heal
            {
				if (GetConVarInt(CfgShopInfHealCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 13
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 2: //boomer
            {
				if (GetConVarInt(CfgShopBoomerCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 14
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 3: //hunter
            {
				if (GetConVarInt(CfgShopHunterCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 15
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 4: //smoker
            {
				if (GetConVarInt(CfgShopSmokerCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 16
					FakeClientCommand(client, "buyconfirm")
				}
            }
			case 5: //tank
            {
				if (GetConVarInt(CfgShopTankCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 17
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 6: //witch
            {
				if (GetConVarInt(CfgShopWitchCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 18
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 7: //mob
            {
				if (GetConVarInt(CfgShopBoomerCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 19
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 8: //mega mob
            {
				if (GetConVarInt(CfgShopPanicCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 20
					FakeClientCommand(client, "buyconfirm")
				}
            }
            case 9: //spitter
            {
				if (GetConVarInt(CfgShopSpitterCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 44
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 10: //charger
            {
				if (GetConVarInt(CfgShopChargerCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 45
					FakeClientCommand(client, "buyconfirm")
				}
			}
            case 11: //jockey
            {
				if (GetConVarInt(CfgShopJockeyCost) < 0)
				{
					MsgBuyDisabled(client)
				}
				else
				{
					ClientBuyConfirm[client] = 46
					FakeClientCommand(client, "buyconfirm")
				}
			}
			case 12: //back
			{
				//Go back
				FakeClientCommand(client, "specialshop")
			}
        }
    }
}

public MenuHandler_Exchange(Handle:menu, MenuAction:action, client, itemNum)
{
    if(action == MenuAction_Select && itemNum <= 8)
	{
		if(GetClientTeam(client) == TEAM_INFECTED)
		{
			ClientSetExchangeSpecial(client, itemNum)
		}
		else if(GetClientTeam(client) == TEAM_SURVIVORS)
		{
			ClientSetExchangeSurvivor(client, itemNum)
		}
		FakeClientCommand(client, "exchange")
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