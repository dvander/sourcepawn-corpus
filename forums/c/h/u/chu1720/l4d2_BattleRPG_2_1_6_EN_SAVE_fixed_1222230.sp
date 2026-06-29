//BattleRPG by .#Zipcore & Max Chu

#include <sourcemod>
#include <sdktools>

/* Number of Jobs (Change Jobnames in RPG-Menu) */
#define JOBMAX 13

/* Number of Items in Job Menu (Ammo not included! Change Itemnames & items!! in BuyShop-Menu ) */
#define ITEMMAX 9 

/* Plugin Info */
#define Version "2.1.6"
#define Author ".#Zipcore & Max Chu"
#define Name "Battle RPG 2"
#define Description "Roleplay Game Mode for L4D2"
#define URL ""

/* Identifications */
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8

/* Cvar Flags */
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo=
{
	name = Name,
	author = Author,
	description = Description,
	version = Version,
	url = URL
}

/* Config */
new Handle:CfgJobHPOnLevelUp
new Handle:CfgCheckExpTimer
new Handle:CfgRemindJobTimer
new Handle:CfgItemsTimer
new Handle:CfgFirstAnnounceTimer
new Handle:CfgItemsEnable
new Handle:CfgItemsOnLevelUp
new Handle:CfgSkillMode
new Handle:CfgBackPackAvailable
new Handle:CfgDamageReflectOnly
new Handle:CfgTankMode
new Handle:CfgExpMode

/* Skill Limits */
new Handle:CfgLimitCash
new Handle:CfgLimitHealth
new Handle:CfgLimitAgilitySpeed
new Handle:CfgLimitAgilityGravity
new Handle:CfgLimitStrength
new Handle:CfgLimitEndurance

/* Announcements */
new Handle:MsgExpEnable
new Handle:MsgRemindJobEnable

/* Infected EXP */
new Handle:JocExp
new Handle:HunExp
new Handle:ChaExp
new Handle:SmoExp
new Handle:SpiExp
new Handle:BooExp
new Handle:TanExp
new Handle:TanSurExp
new Handle:WitExp
new Handle:ComExp
new Handle:ReviveExp
new Handle:HealExp
new Handle:DefExp
new Handle:LevelUpExp

/* Jobs */
new Handle:JobReqLevel[JOBMAX+1]
new Handle:JobCash[JOBMAX+1]
new Handle:JobHealth[JOBMAX+1]
new Handle:JobHP[JOBMAX+1]
new Handle:JobAgi[JOBMAX+1]
new Handle:JobStr[JOBMAX+1]
new Handle:JobEnd[JOBMAX+1]

/* Costs */
new Handle:ItemCost[ITEMMAX+1]

/* Client */
new Level[MAXPLAYERS+1]
new JobLevel[MAXPLAYERS+1]
new Cash[MAXPLAYERS+1]

new EXP[MAXPLAYERS+1]
new Job[MAXPLAYERS+1]
new JobLock[MAXPLAYERS+1]

new TempHP[MAXPLAYERS+1]
new TempStr[MAXPLAYERS+1]
new TempAgi[MAXPLAYERS+1]
new TempEnd[MAXPLAYERS+1]

/* Other */
new ZC
new LegValue
new Handle:AnnounceRemindJob[MAXPLAYERS+1]
new Handle:AnnounceFirst[MAXPLAYERS+1]
new Handle:CheckExp[MAXPLAYERS+1]
new Handle:GiveTimedItems[MAXPLAYERS+1]
new ISJOBCONFIRM[MAXPLAYERS+1]

/*Save Path*/
new String:SavePath[256];

/*Save Config*/
new Handle:SaveConfig

/* Plugin Start */
public OnPluginStart()
{
	//Build Save Path
	BuildPath(Path_SM, SavePath, 255, "data/BattleRPGSave.txt");
	
	CreateConVar(Name, Version, Description, CVAR_FLAGS)
	
	/* Client Commands */
	RegConsoleCmd("rpgmenu", RPG_Menu)
	RegConsoleCmd("jobmenu", Job_Menu)
	RegConsoleCmd("jobs", PlayersSkills)
	RegConsoleCmd("jobconfirm", JobConfirmChooseMenu)
	RegConsoleCmd("rpgskills", PlayersSkills)
	RegConsoleCmd("buymenu", Buy_Menu)
	RegConsoleCmd("buyshop", Buy_Menu)
	RegConsoleCmd("buy", Buy_Menu)
	RegConsoleCmd("shop", Buy_Menu)
	
	/* Admin Commads */
	RegAdminCmd("rpgkit_givelevel",GiveLevel,ADMFLAG_KICK,"rpgkit_givelevel [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveagi",GiveAgility,ADMFLAG_KICK,"rpgkit_giveagi [#userid|name] [number]")
	RegAdminCmd("rpgkit_givestr",GiveStrength,ADMFLAG_KICK,"rpgkit_givestr [#userid|name] [number]")
	RegAdminCmd("rpgkit_giveend",GiveEndurance,ADMFLAG_KICK,"rpgkit_giveend [#userid|name] [number]")
	RegAdminCmd("rpgkit_givehp",GiveHealth,ADMFLAG_KICK,"rpgkit_givehp [#userid|name] [number]")
	
	/* Hook Events */
	HookEvent("witch_killed", ExpWitchKilled)
	HookEvent("revive_success", ExpRevive)
	HookEvent("defibrillator_used", ExpDefUsed)
	HookEvent("player_death", ExpInfectedKilled)
	HookEvent("infected_death", ExpInfectedDead)
	HookEvent("heal_success", HealPlayer)
	HookEvent("player_first_spawn", SpawnFirst)
	HookEvent("player_spawn", PlayerSpawn)
	HookEvent("player_hurt", PlayerHurt)
	HookEvent("infected_hurt", InfectedHurt)
	HookEvent("jockey_ride", JocRide, EventHookMode_Pre)
	HookEvent("jockey_ride_end", JocRideEnd)
	HookEvent("round_start", RoundStart)
	HookEvent("round_end", RoundEnd);
	
	ZC = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")
	LegValue = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue")
	
	CreateCvars() // Create all Cvars
	AutoExecConfig(true, "l4d2_battle_rpg_2.1.6") // Create/Load Config
	LogMessage("[Battle-RPG 2] - Loaded")
}

/* Creat all Cvars */
CreateCvars()
{

	/* Save Config */
	SaveConfig = CreateConVar("rpgkit_cfg_save_config","0","0: Saved by player's name; 1: Saved by player's SteamID", FCVAR_PLUGIN)
	
	/* Config Menu */
	CfgFirstAnnounceTimer = CreateConVar("rpgkit_cfg_menu_rpg_timer ","0.0","0.0: Disable; X.x: Enable Timer: Show up RPG-Menu once after X.x seconds", FCVAR_PLUGIN)
	
	CfgBackPackAvailable = CreateConVar("rpgkit_cfg_menu_rpg_backpack","0","0: Disable; 1: Show BackPack access button in RPGMenu", FCVAR_PLUGIN)
	
	/* Config EXP */
	MsgExpEnable = CreateConVar("rpgkit_cfg_exp_chat_enable","1","0: Disable; 1: Prints chat message to player if he/she got EXP", FCVAR_PLUGIN)
	
	CfgCheckExpTimer = CreateConVar("rpgkit_cfg_exp_timer","2.0","0.0: Disable; X.x : Enable Timer: Check players exp for level up every X.x seconds", FCVAR_PLUGIN)
	
	LevelUpExp = CreateConVar("rpgkit_cfg_exp_levelup","3000","Needed EXP to become a level up", FCVAR_PLUGIN)
	CfgExpMode = CreateConVar("rpgkit_cfg_exp_mode","1","1: Subtract EXP on level up; 2: Keep EXP on level up and multiply required EXP by job level; 3: SubtractEXP on level up and multiply required EXP by job level", FCVAR_PLUGIN)
	
	JocExp = CreateConVar("rpgkit_cfg_exp_jockey_killed","210","EXP that Jockey gives", FCVAR_PLUGIN)
	HunExp = CreateConVar("rpgkit_cfg_exp_hunter_killed","220", "EXP that Hunter gives", FCVAR_PLUGIN)
	ChaExp = CreateConVar("rpgkit_cfg_exp_charger_killed","240","EXP that Charger gives", FCVAR_PLUGIN)
	SmoExp = CreateConVar("rpgkit_cfg_exp_smoker_killed","190","EXP that Smoker gives", FCVAR_PLUGIN)
	SpiExp = CreateConVar("rpgkit_cfg_exp_spitter_killed","170","EXP that Spitter gives", FCVAR_PLUGIN)
	BooExp = CreateConVar("rpgkit_cfg_exp_boomer_killed","150","EXP that Boomer gives", FCVAR_PLUGIN)
	
	WitExp = CreateConVar("rpgkit_cfg_exp_witch_killed","350","EXP that Witch gives", FCVAR_PLUGIN)
	ComExp = CreateConVar("rpgkit_cfg_exp_common_killed","25","EXP that Common Zombie gives", FCVAR_PLUGIN)
	
	TanExp = CreateConVar("rpgkit_cfg_exp_tank_killed","900","EXP that Tank gives on tank exp mode 1: (killer) & mode 3: (killer)", FCVAR_PLUGIN)
	TanSurExp = CreateConVar("rpgkit_cfg_exp_tank_survived","900","EXP that Tank gives on tank exp mode 2 (all) & mode 3 (other)", FCVAR_PLUGIN)
	CfgTankMode = CreateConVar("rpgkit_cfg_exp_tank_mode","3","1: Give EXP only tank killer tank kill EXP; 2: Give all alive players tank survive EXP 3: give killer tankk kill EXP & other survivors tank survive EXP", FCVAR_PLUGIN)
	
	ReviveExp = CreateConVar("rpgkit_cfg_exp_revive","400","EXP when you succeed setting someone up", FCVAR_PLUGIN)
	DefExp = CreateConVar("rpgkit_cfg_exp_defibrillator","600","EXP when you succeed to revive someone with defibrillator", FCVAR_PLUGIN)
	HealExp = CreateConVar("rpgkit_cfg_exp_heal","300","EXP when you succeed to heal someone with first aid kit", FCVAR_PLUGIN)
	
	/* Config Job */
	MsgRemindJobEnable = CreateConVar("rpgkit_cfg_job_chat_remindjob_enable","1","0: Disable; 1: Enable timer: rpgkit_cfg_chat_remindjob_timer", FCVAR_PLUGIN)
	CfgRemindJobTimer = CreateConVar("rpgkit_cfg_job_chat_remindjob_timer","15.0","0.0: Disable; X.x : Enable Timer: Remind player choose a job every X.x seconds", FCVAR_PLUGIN)
	
	JobReqLevel[0] = CreateConVar("rpgkit_cfg_job_reqlevel_0","0","ReqLevel of Job 0", FCVAR_PLUGIN)
	JobReqLevel[1] = CreateConVar("rpgkit_cfg_job_reqlevel_1","0","ReqLevel of Job 1", FCVAR_PLUGIN)
	JobReqLevel[2] = CreateConVar("rpgkit_cfg_job_reqlevel_2","10","ReqLevel of Job 2", FCVAR_PLUGIN)
	JobReqLevel[3] = CreateConVar("rpgkit_cfg_job_reqlevel_3","20","ReqLevel of Job 3", FCVAR_PLUGIN)
	JobReqLevel[4] = CreateConVar("rpgkit_cfg_job_reqlevel_4","20","ReqLevel of Job 4", FCVAR_PLUGIN)
	JobReqLevel[5] = CreateConVar("rpgkit_cfg_job_reqlevel_5","40","ReqLevel of Job 5", FCVAR_PLUGIN)
	JobReqLevel[6] = CreateConVar("rpgkit_cfg_job_reqlevel_6","40","ReqLevel of Job 6", FCVAR_PLUGIN)
	JobReqLevel[7] = CreateConVar("rpgkit_cfg_job_reqlevel_7","50","ReqLevel of Job 7", FCVAR_PLUGIN)
	JobReqLevel[8] = CreateConVar("rpgkit_cfg_job_reqlevel_8","60","ReqLevel of Job 8", FCVAR_PLUGIN)
	JobReqLevel[9] = CreateConVar("rpgkit_cfg_job_reqlevel_9","80","ReqLevel of Job 9", FCVAR_PLUGIN)
	JobReqLevel[10] = CreateConVar("rpgkit_cfg_job_reqlevel_10","100","ReqLevel of Job 10", FCVAR_PLUGIN)
	JobReqLevel[11] = CreateConVar("rpgkit_cfg_job_reqlevel_11","125","ReqLevel of Job 11", FCVAR_PLUGIN)
	JobReqLevel[12] = CreateConVar("rpgkit_cfg_job_reqlevel_12","150","ReqLevel of Job 12", FCVAR_PLUGIN)
	JobReqLevel[13] = CreateConVar("rpgkit_cfg_job_reqlevel_13","200","ReqLevel of Job 13", FCVAR_PLUGIN)
	
	/* Config */
	CfgLimitCash = CreateConVar("rpgkit_cfg_cash_limit","0","0: Disable; X: Limit players cash", FCVAR_PLUGIN)

	/* Skills */
	CfgSkillMode = CreateConVar("rpgkit_cfg_skill_mode","1","0: Disable; Mode1: Add job skills on level up; Mode2: Add job skills on job select; Effects strength, agility & endurance", FCVAR_PLUGIN)
	CfgLimitAgilityGravity = CreateConVar("rpgkit_cfg_skill_agility_gravity_limit","1000","Limit agiligy skill converted into gravity", FCVAR_PLUGIN)
	CfgLimitAgilitySpeed = CreateConVar("rpgkit_cfg_skill_agility_speed_limit","350","Limit agiligy skill converted into speed", FCVAR_PLUGIN)
	CfgLimitEndurance = CreateConVar("rpgkit_cfg_skill_endurance_limit","0","0: Disable; X: Limit endurance skill", FCVAR_PLUGIN)
	CfgDamageReflectOnly = CreateConVar("rpgkit_cfg_skill_endurance_dmgreflectonly","0","0: Disable; 1: Damage reflect only, no shield", FCVAR_PLUGIN)
	CfgLimitHealth = CreateConVar("rpgkit_cfg_skill_health_limit ","0","0: Disable; X: Limit players health", FCVAR_PLUGIN)
	CfgJobHPOnLevelUp = CreateConVar("rpgkit_cfg_skill_health_mode","3","0: Disable; Mode1: Incease Only Health on level up; Mode2: Increase Only Max Health on level up; Mode3: Increase Health & Max Health on level up", FCVAR_PLUGIN)
	CfgLimitStrength = CreateConVar("rpgkit_cfg_skill_strength_limit","0","0: Disable; X: Limit strength skill", FCVAR_PLUGIN)
	
	/* Config Items */
	CfgItemsEnable = CreateConVar("rpgkit_cfg_items_job_enable","1","0: Disable; 1: Enable job items & give Items after job selected", FCVAR_PLUGIN)
	CfgItemsTimer = CreateConVar("rpgkit_cfg_items_job_timer ","0.0","0.0: Disable; X.x: Enable Timer: Give job items", FCVAR_PLUGIN)
	CfgItemsOnLevelUp = CreateConVar("rpgkit_cfg_items_job_onlevelup","0","0: Disable; 1: Give job items on level up", FCVAR_PLUGIN)
	ItemCost[0] = CreateConVar("rpgkit_cfg_items_shop_0","10","Cost of Item 0", FCVAR_PLUGIN)
	ItemCost[1] = CreateConVar("rpgkit_cfg_items_shop_1","50","Cost of Item 1", FCVAR_PLUGIN)
	ItemCost[2] = CreateConVar("rpgkit_cfg_items_shop_2","35","Cost of Item 2", FCVAR_PLUGIN)
	ItemCost[3] = CreateConVar("rpgkit_cfg_items_shop_3","30","Cost of Item 3", FCVAR_PLUGIN)
	ItemCost[4] = CreateConVar("rpgkit_cfg_items_shop_4","75","Cost of Item 4", FCVAR_PLUGIN)
	ItemCost[5] = CreateConVar("rpgkit_cfg_items_shop_5","50","Cost of Item 5", FCVAR_PLUGIN)
	ItemCost[6] = CreateConVar("rpgkit_cfg_items_shop_6","35","Cost of Item 6", FCVAR_PLUGIN)
	ItemCost[7] = CreateConVar("rpgkit_cfg_items_shop_7","100","Cost of Item 7", FCVAR_PLUGIN)
	ItemCost[8] = CreateConVar("rpgkit_cfg_items_shop_8","125","Cost of Item 8", FCVAR_PLUGIN)
	ItemCost[9] = CreateConVar("rpgkit_cfg_items_shop_9","150","Cost of Item 9", FCVAR_PLUGIN)
	
	/* Cash of Job X */
	JobCash[0] = CreateConVar("rpgkit_cfg_job_cash_0","0","Cash of Job 0", FCVAR_PLUGIN)
	JobCash[1] = CreateConVar("rpgkit_cfg_job_cash_1","3","Cash of Job 1", FCVAR_PLUGIN)
	JobCash[2] = CreateConVar("rpgkit_cfg_job_cash_2","4","Cash of Job 2", FCVAR_PLUGIN)
	JobCash[3] = CreateConVar("rpgkit_cfg_job_cash_3","5","Cash of Job 3", FCVAR_PLUGIN)
	JobCash[4] = CreateConVar("rpgkit_cfg_job_cash_4","4","Cash of Job 4", FCVAR_PLUGIN)
	JobCash[5] = CreateConVar("rpgkit_cfg_job_cash_5","6","Cash of Job 5", FCVAR_PLUGIN)
	JobCash[6] = CreateConVar("rpgkit_cfg_job_cash_6","7","Cash of Job 6", FCVAR_PLUGIN)
	JobCash[7] = CreateConVar("rpgkit_cfg_job_cash_7","10","Cash of Job 7", FCVAR_PLUGIN)
	JobCash[8] = CreateConVar("rpgkit_cfg_job_cash_8","9","Cash of Job 8", FCVAR_PLUGIN)
	JobCash[9] = CreateConVar("rpgkit_cfg_job_cash_9","12","Cash of Job 9", FCVAR_PLUGIN)
	JobCash[10] = CreateConVar("rpgkit_cfg_job_cash_10","14","Cash of Job 10", FCVAR_PLUGIN)
	JobCash[11] = CreateConVar("rpgkit_cfg_job_cash_11","15","Cash of Job 11", FCVAR_PLUGIN)
	JobCash[12] = CreateConVar("rpgkit_cfg_job_cash_12","20","Cash of Job 12", FCVAR_PLUGIN)
	JobCash[13] = CreateConVar("rpgkit_cfg_job_cash_13","30","Cash of Job 13", FCVAR_PLUGIN)
	
	/* Health of Job X */
	JobHealth[0] = CreateConVar("rpgkit_cfg_job_health_0","100","Health of Job 0", FCVAR_PLUGIN)
	JobHealth[1] = CreateConVar("rpgkit_cfg_job_health_1","100","Health of Job 1", FCVAR_PLUGIN)
	JobHealth[2] = CreateConVar("rpgkit_cfg_job_health_2","120","Health of Job 2", FCVAR_PLUGIN)
	JobHealth[3] = CreateConVar("rpgkit_cfg_job_health_3","130","Health of Job 3", FCVAR_PLUGIN)
	JobHealth[4] = CreateConVar("rpgkit_cfg_job_health_4","140","Health of Job 4", FCVAR_PLUGIN)
	JobHealth[5] = CreateConVar("rpgkit_cfg_job_health_5","150","Health of Job 5", FCVAR_PLUGIN)
	JobHealth[6] = CreateConVar("rpgkit_cfg_job_health_6","160","Health of Job 6", FCVAR_PLUGIN)
	JobHealth[7] = CreateConVar("rpgkit_cfg_job_health_7","170","Health of Job 7", FCVAR_PLUGIN)
	JobHealth[8] = CreateConVar("rpgkit_cfg_job_health_8","180","Health of Job 8", FCVAR_PLUGIN)
	JobHealth[9] = CreateConVar("rpgkit_cfg_job_health_9","200","Health of Job 9", FCVAR_PLUGIN)
	JobHealth[10] = CreateConVar("rpgkit_cfg_job_health_10","220","Health of Job 10", FCVAR_PLUGIN)
	JobHealth[11] = CreateConVar("rpgkit_cfg_job_health_11","250","Health of Job 11", FCVAR_PLUGIN)
	JobHealth[12] = CreateConVar("rpgkit_cfg_job_health_12","280","Health of Job 12", FCVAR_PLUGIN)
	JobHealth[13] = CreateConVar("rpgkit_cfg_job_health_13","300","Health of Job 13", FCVAR_PLUGIN)
	
	/* HP of Job X */
	JobHP[0] = CreateConVar("rpgkit_cfg_job_hp_0","0","HP of Job 0", FCVAR_PLUGIN)
	JobHP[1] = CreateConVar("rpgkit_cfg_job_hp_1","1","HP of Job 1", FCVAR_PLUGIN)
	JobHP[2] = CreateConVar("rpgkit_cfg_job_hp_2","2","HP of Job 2", FCVAR_PLUGIN)
	JobHP[3] = CreateConVar("rpgkit_cfg_job_hp_3","3","HP of Job 3", FCVAR_PLUGIN)
	JobHP[4] = CreateConVar("rpgkit_cfg_job_hp_4","4","HP of Job 4", FCVAR_PLUGIN)
	JobHP[5] = CreateConVar("rpgkit_cfg_job_hp_5","5","HP of Job 5", FCVAR_PLUGIN)
	JobHP[6] = CreateConVar("rpgkit_cfg_job_hp_6","6","HP of Job 6", FCVAR_PLUGIN)
	JobHP[7] = CreateConVar("rpgkit_cfg_job_hp_7","7","HP of Job 7", FCVAR_PLUGIN)
	JobHP[8] = CreateConVar("rpgkit_cfg_job_hp_8","8","HP of Job 8", FCVAR_PLUGIN)
	JobHP[9] = CreateConVar("rpgkit_cfg_job_hp_9","9","HP of Job 9", FCVAR_PLUGIN)
	JobHP[10] = CreateConVar("rpgkit_cfg_job_hp_10","10","HP of Job 10", FCVAR_PLUGIN)
	JobHP[11] = CreateConVar("rpgkit_cfg_job_hp_11","11","HP of Job 11", FCVAR_PLUGIN)
	JobHP[12] = CreateConVar("rpgkit_cfg_job_hp_12","12","HP of Job 12", FCVAR_PLUGIN)
	JobHP[13] = CreateConVar("rpgkit_cfg_job_hp_13","13","HP of Job 13", FCVAR_PLUGIN)
	
	/* Agi of Job X */
	JobAgi[0] = CreateConVar("rpgkit_cfg_job_agi_0","0","Agi of Job 0", FCVAR_PLUGIN)
	JobAgi[1] = CreateConVar("rpgkit_cfg_job_agi_1","1","Agi of Job 1", FCVAR_PLUGIN)
	JobAgi[2] = CreateConVar("rpgkit_cfg_job_agi_2","4","Agi of Job 2", FCVAR_PLUGIN)
	JobAgi[3] = CreateConVar("rpgkit_cfg_job_agi_3","2","Agi of Job 3", FCVAR_PLUGIN)
	JobAgi[4] = CreateConVar("rpgkit_cfg_job_agi_4","2","Agi of Job 4", FCVAR_PLUGIN)
	JobAgi[5] = CreateConVar("rpgkit_cfg_job_agi_5","2","Agi of Job 5", FCVAR_PLUGIN)
	JobAgi[6] = CreateConVar("rpgkit_cfg_job_agi_6","2","Agi of Job 6", FCVAR_PLUGIN)
	JobAgi[7] = CreateConVar("rpgkit_cfg_job_agi_7","3","Agi of Job 7", FCVAR_PLUGIN)
	JobAgi[8] = CreateConVar("rpgkit_cfg_job_agi_8","3","Agi of Job 8", FCVAR_PLUGIN)
	JobAgi[9] = CreateConVar("rpgkit_cfg_job_agi_9","4","Agi of Job 9", FCVAR_PLUGIN)
	JobAgi[10] = CreateConVar("rpgkit_cfg_job_agi_10","4","Agi of Job 10", FCVAR_PLUGIN)
	JobAgi[11] = CreateConVar("rpgkit_cfg_job_agi_11","5","Agi of Job 11", FCVAR_PLUGIN)
	JobAgi[12] = CreateConVar("rpgkit_cfg_job_agi_12","6","Agi of Job 12", FCVAR_PLUGIN)
	JobAgi[13] = CreateConVar("rpgkit_cfg_job_agi_13","7","Agi of Job 13", FCVAR_PLUGIN)
	
	/* Str of Job X */
	JobStr[0] = CreateConVar("rpgkit_cfg_job_str_0","0","Str of Job 0", FCVAR_PLUGIN)
	JobStr[1] = CreateConVar("rpgkit_cfg_job_str_1","2","Str of Job 1", FCVAR_PLUGIN)
	JobStr[2] = CreateConVar("rpgkit_cfg_job_str_2","3","Str of Job 2", FCVAR_PLUGIN)
	JobStr[3] = CreateConVar("rpgkit_cfg_job_str_3","5","Str of Job 3", FCVAR_PLUGIN)
	JobStr[4] = CreateConVar("rpgkit_cfg_job_str_4","3","Str of Job 4", FCVAR_PLUGIN)
	JobStr[5] = CreateConVar("rpgkit_cfg_job_str_5","3","Str of Job 5", FCVAR_PLUGIN)
	JobStr[6] = CreateConVar("rpgkit_cfg_job_str_6","5","Str of Job 6", FCVAR_PLUGIN)
	JobStr[7] = CreateConVar("rpgkit_cfg_job_str_7","6","Str of Job 7", FCVAR_PLUGIN)
	JobStr[8] = CreateConVar("rpgkit_cfg_job_str_8","6","Str of Job 8", FCVAR_PLUGIN)
	JobStr[9] = CreateConVar("rpgkit_cfg_job_str_9","7","Str of Job 9", FCVAR_PLUGIN)
	JobStr[10] = CreateConVar("rpgkit_cfg_job_str_10","7","Str of Job 10", FCVAR_PLUGIN)
	JobStr[11] = CreateConVar("rpgkit_cfg_job_str_11","8","Str of Job 11", FCVAR_PLUGIN)
	JobStr[12] = CreateConVar("rpgkit_cfg_job_str_12","8","Str of Job 12", FCVAR_PLUGIN)
	JobStr[13] = CreateConVar("rpgkit_cfg_job_str_13","10","Str of Job 13", FCVAR_PLUGIN)
	
	/* End of Job X */
	JobEnd[0] = CreateConVar("rpgkit_cfg_job_end_0","0","End of Job 0", FCVAR_PLUGIN)
	JobEnd[1] = CreateConVar("rpgkit_cfg_job_end_1","1","End of Job 1", FCVAR_PLUGIN)
	JobEnd[2] = CreateConVar("rpgkit_cfg_job_end_2","2","End of Job 2", FCVAR_PLUGIN)
	JobEnd[3] = CreateConVar("rpgkit_cfg_job_end_3","1","End of Job 3", FCVAR_PLUGIN)
	JobEnd[4] = CreateConVar("rpgkit_cfg_job_end_4","1","End of Job 4", FCVAR_PLUGIN)
	JobEnd[5] = CreateConVar("rpgkit_cfg_job_end_5","2","End of Job 5", FCVAR_PLUGIN)
	JobEnd[6] = CreateConVar("rpgkit_cfg_job_end_6","3","End of Job 6", FCVAR_PLUGIN)
	JobEnd[7] = CreateConVar("rpgkit_cfg_job_end_7","4","End of Job 7", FCVAR_PLUGIN)
	JobEnd[8] = CreateConVar("rpgkit_cfg_job_end_8","5","End of Job 8", FCVAR_PLUGIN)
	JobEnd[9] = CreateConVar("rpgkit_cfg_job_end_9","5","End of Job 9", FCVAR_PLUGIN)
	JobEnd[10] = CreateConVar("rpgkit_cfg_job_end_10","6","End of Job 10", FCVAR_PLUGIN)
	JobEnd[11] = CreateConVar("rpgkit_cfg_job_end_11","7","End of Job 11", FCVAR_PLUGIN)
	JobEnd[12] = CreateConVar("rpgkit_cfg_job_end_12","8","End of Job 12", FCVAR_PLUGIN)
	JobEnd[13] = CreateConVar("rpgkit_cfg_job_end_13","10","End of Job 13", FCVAR_PLUGIN)
}

/* ADMIN Commands */

/* Give Level */
public Action:GiveLevel(client, args)
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
			Level[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled;
}
/* Give Agiligy */
public Action:GiveAgility(client, args)
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
			TempAgi[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	RebuildStatus(targetclient)
	return Plugin_Handled
}
/* Give Strength */
public Action:GiveStrength(client, args)
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
			TempStr[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled
}
/* Give Endurance */
public Action:GiveEndurance(client, args)
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
			TempEnd[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	return Plugin_Handled
}
/* Give Health */
public Action:GiveHealth(client, args)
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
			TempHP[targetclient] += StringToInt(arg2)
		}
	}
	else
	{
		ReplyToTargetError(client, target_count)
	}
	RebuildStatus(targetclient)
	return Plugin_Handled
}

/* Load From File Function*/
PlayerLoadFromFile(client)
{
	if(!IsFakeClient(client))
	{
		decl Handle:kv;
		decl String:cName[MAX_NAME_LENGTH];
		kv = CreateKeyValues("Battle-RPG Save");
		FileToKeyValues(kv, SavePath);
		if(GetConVarInt(SaveConfig) == 0)
		{
			GetClientName(client, cName, sizeof(cName));
		}else{
			GetClientAuthString(client, cName, sizeof(cName));
		}
		KvJumpToKey(kv, cName, true);
		Level[client] = KvGetNum(kv, "Basic Level", 0);
		EXP[client] = KvGetNum(kv, "EXP", 0);
		Cash[client] = KvGetNum(kv, "Cash", 0);
		CloseHandle(kv);
		LogMessage("%N's Save is loaded!",client);
	}
}

/* Save To File Function*/
PlayerSaveToFile(client, bool:SaveLevel, bool:SaveEXP, bool:SaveCash)
{
	if(!IsFakeClient(client))
	{
		decl Handle:kv;
		decl String:cName[MAX_NAME_LENGTH];
		kv = CreateKeyValues("Battle-RPG Save");
		FileToKeyValues(kv, SavePath);
		if(GetConVarInt(SaveConfig) == 0)
		{
			GetClientName(client, cName, sizeof(cName));
		}else{
			GetClientAuthString(client, cName, sizeof(cName));
		}
		KvJumpToKey(kv, cName, true);
		if(SaveLevel == true)	KvSetNum(kv, "Basic Level", Level[client]);
		if(SaveEXP == true)	KvSetNum(kv, "EXP", EXP[client]);
		if(SaveCash == true)	KvSetNum(kv, "Cash", Cash[client]);
		KvRewind(kv);
		KeyValuesToFile(kv, SavePath);
		CloseHandle(kv);
	}
}

/* Player First Spawn */
public Action:SpawnFirst(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	CheckExp[target] = CreateTimer(GetConVarFloat(CfgCheckExpTimer), CheckExpTimer, target, TIMER_REPEAT)
	
	if(!IsFakeClient(target) && GetClientTeam(target) == TEAM_SURVIVORS)
	{
		if(GetConVarFloat(CfgFirstAnnounceTimer) != 0.0)
		{
			AnnounceFirst[target] = CreateTimer(GetConVarFloat(CfgFirstAnnounceTimer), AnnounceFirstTimer, target, TIMER_REPEAT)
		}
		
		if(GetConVarInt(MsgRemindJobEnable) == 1)
		{
			AnnounceRemindJob[target] = CreateTimer(GetConVarFloat(CfgRemindJobTimer), AnnounceRemindJobTimer, target, TIMER_REPEAT)
		}
		
		/* Load From File */
		PlayerLoadFromFile(target)
	}
}

/* Player Spawn */
public Action:PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(target) == TEAM_SURVIVORS && !IsFakeClient(target))
	{
		ResetTarget(target)
		if(Level[target] == 0 && EXP[target] == 0 && Cash[target] == 0)
		{
			/* Load From File */
			PlayerLoadFromFile(target)
		}
	}
}

/* Round Start */
public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i = 1; i < MaxClients; i++)
	{
		ResetTarget(i)
		if(Level[i] == 0 && EXP[i] == 0 && Cash[i] == 0)
		{
			/* Load From File */
			PlayerLoadFromFile(i)
		}
	}
}

/* Round End */
public Action:RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{

	for (new i = 1; i <= MaxClients; i++)
	{		
		if( Level[i] != 0 || EXP[i] != 0 || Cash[i] != 0 )
		{
			/* Save To File */
			PlayerSaveToFile(i, true, true, true)
		}
	}	 
}

/* Set player's health on healing */
public Action:HealPlayer(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new HealSucTarget = GetClientOfUserId(GetEventInt(event, "subject"))
	new HealPerformer = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(HealSucTarget) == TEAM_SURVIVORS && !IsFakeClient(HealSucTarget))
	{
		SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), GetHealthMaxToSet(HealSucTarget), 4, true)
		SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), GetHealthMaxToSet(HealSucTarget), 4, true)
		if(HealSucTarget != HealPerformer && !IsFakeClient(HealPerformer))
		{
			EXP[HealPerformer] += GetConVarInt(HealExp)
			MsgExpHeal(HealPerformer, HealSucTarget)
		}
	}
}

/* Set player's speed back to normal on jockey ride */
public Action:JocRide(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new targetid = GetClientOfUserId(GetEventInt(event, "victim"))
	if(targetid != 0)
	{
		if(GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid))
		{
			ResetAgility(targetid)
		}
	}
}

/* Rebuild player's speed an max health on jockey ride end */
public Action:JocRideEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new targetid = GetClientOfUserId(GetEventInt(event, "victim"))
	if(targetid != 0)
	{
		if(GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid))
		{
			RebuildStatus(targetid)
		}
	}
}

/* Give EXP Special Infected */
public Action:ExpInfectedKilled(Handle:event, String:event_name[], bool:dontBroadcast)	
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	new killed = GetClientOfUserId(GetEventInt(event, "userid"))
	new ZClass = GetEntData(killed, ZC)

	if (killer <= MaxClients && killer != 0)
	{
		if(GetClientTeam(killer) == TEAM_SURVIVORS)
		{
			new targetexp = EXP[killer]
			//Smoker
			if(ZClass == 1 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(SmoExp)
				if(GetConVarInt(MsgExpEnable) == 1)
				{
					MsgExpSmoker(killer)
				}
			}
			//Boomer
			else if(ZClass == 2 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(BooExp)
				if(GetConVarInt(MsgExpEnable) == 1)
				{
					MsgExpBoomer(killer)
				}
			}
			// Hunter
			else if(ZClass == 3 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(HunExp)
				if(GetConVarInt(MsgExpEnable) == 1)
				{
					MsgExpHunter(killer)
				}
			}
			// Spitter
			else if(ZClass == 4 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(SpiExp)
				if(GetConVarInt(MsgExpEnable) == 1)
				{
					MsgExpSpitter(killer)
				}
			}
			// Jockey
			else if(ZClass == 5 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(JocExp)
				if(GetConVarInt(MsgExpEnable) == 1)
				{
					MsgExpJockey(killer)
				}
			}
			// Charger
			else if(ZClass == 6 && !IsFakeClient(killer))
			{
				targetexp += GetConVarInt(ChaExp)
				if(GetConVarInt(MsgExpEnable) == 1)
				{
					MsgExpCharger(killer)
				}
			}
			// Tank
			else if(IsPlayerTank(killed))
			{
				if(GetConVarInt(CfgTankMode) == 1 && !IsFakeClient(killer))
				{
					/* give killer EXP */
					targetexp += GetConVarInt(TanExp)
					if(GetConVarInt(MsgExpEnable) == 1)
					{
						MsgExpTank(killer)
					}
				}
				if(GetConVarInt(CfgTankMode) == 2)
				{
					/* give all survivors EXP */
					for(new i = 1; i < MaxClients; i++)
					{
						if(GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i) && IsPlayerAlive(i))
						{
							EXP[i] += GetConVarInt(TanSurExp)
							if(GetConVarInt(MsgExpEnable) == 1)
							{
								MsgExpTankSurvive(i)
							}
							
							/* Save To File */
							PlayerSaveToFile(i, false, true, false)
						}
					}
				}
				if(GetConVarInt(CfgTankMode) == 3)
				{
					/* give killer EXP */
					if(!IsFakeClient(killer))
					{
						targetexp += GetConVarInt(TanExp)
						if(GetConVarInt(MsgExpEnable) == 1)
						{
							MsgExpTank(killer)
						}
					}
					/* give other survivors EXP */
					for(new i = 1; i < MaxClients; i++)
					{
						if(GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i) && IsPlayerAlive(i) && i != killer)
						{
							EXP[i] += GetConVarInt(TanSurExp)
							if(GetConVarInt(MsgExpEnable) == 1)
							{
								MsgExpTankSurvive(i)
							}
							
							/* Save To File */
							PlayerSaveToFile(i, false, true, false)
						}
					}
				}
			}
			EXP[killer] = targetexp
			
			/* Save To File */
			PlayerSaveToFile(killer, false, true, false)
		}
	}
}

/* Get EXP Revive Someone */
public Action:ExpRevive(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(!IsFakeClient(Reviver) && GetClientTeam(Reviver) == TEAM_SURVIVORS && Reviver != Subject)
	{
		EXP[Reviver] += GetConVarInt(ReviveExp)
		RebuildStatus(Subject)
		if(GetConVarInt(MsgExpEnable) == 1)
		{
			MsgExpRevive(Reviver, Subject)
		}
		
		/* Save To File */
		PlayerSaveToFile(Reviver, false, true, false)
	}
}

/* Get EXP Defibrillator Used */
public Action:ExpDefUsed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(Reviver) == TEAM_SURVIVORS && !IsFakeClient(Reviver))
	{
		EXP[Reviver] += GetConVarInt(DefExp)
		RebuildStatus(Subject)
		if(GetConVarInt(MsgExpEnable) == 1)
		{
			MsgExpDefUsed(Reviver, Subject)
		}
		
		/* Save To File */
		PlayerSaveToFile(Reviver, false, true, false)
	}
}

/* Get EXP Witch Killed */
public Action:ExpWitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(WitExp)
		if(GetConVarInt(MsgExpEnable) == 1)
		{
			MsgExpWitch(killer)
		}
		
		/* Save To File */
		PlayerSaveToFile(killer, false, true, false)
	}
}

/* Get EXP Common Infected Killed*/
public Action:ExpInfectedDead(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(ComExp)
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
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Job Confirmed! Basis health set to \x04%d\x03", GetJobHealth(Job[targetid]))
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You'll get \x04%d\x03$ Cash, \x04%d\x03 HP, \x04%d\x03 Str, \x04%d\x03 Agi & \x04%d\x03 End on levelup", GetJobCash(Job[targetid]), GetJobHP(Job[targetid]), GetJobStr(Job[targetid]), GetJobAgi(Job[targetid]), GetJobEnd(Job[targetid]))
}

/* Message: job requires bigger level */
MsgJobReqLevel(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Need Level \x04%d\x03 Your Level: \x04%d\x03", GetJobReqLevel(ISJOBCONFIRM[targetid]), Level[targetid])
}

/* Message: feature requires job */
MsgFeatureReqJob(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03This feature requires a job.")
}

/* Message: information about players job */
MsgPlayersSkills(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Your Skills: Level: \x04%d\x03 JobLevel: \x04%d\x03", Level[targetid], JobLevel[targetid])
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Health: \x04%d\x03 HP(+\x04%d\x03 TempHP)", GetJobHealth(Job[targetid]), TempHP[targetid])
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Str: +\x04%d\x03% dmg, Agi: +\x04%d\x03% speed", TempStr[targetid], TempAgi[targetid])
	if(TempEnd[targetid] <= 50)
	{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Endurance: -\x04%d\x03% dmg (shield)", TempEnd[targetid])
	}
	else
	{
			PrintToChat(targetid, "\x04[Battle-RPG] \x03Endurance: -\x04%d\x03% \x05dmg (shield) & +\x04%d\x03% dmg reflect", TempEnd[targetid], (TempEnd[targetid]-50))
	}
}

/* Message: information about specific job */
MsgJobInfo(targetid, jobid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03JobInfo about JobID: \x04%d\x03",jobid)
	new hpmode = GetConVarInt(CfgJobHPOnLevelUp)
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
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Your level has increased to \x04%d", Level[targetid])
}

/* Message: remind to chaoose a job */
MsgChooseAJob(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You should definitely choose a job!")
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Type \x04!jobmenu\x03 in chat to see [Job-Menu]")
}

/* Message: killing a witch */
MsgExpWitch(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Witch\x03!", GetConVarInt(WitExp))
}

/* Message: defibrillator used */
MsgExpDefUsed(targetid, subject)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by using a defibrillator on \x04%N\x03!", GetConVarInt(DefExp), subject)
}

/* Message: revive somebody */
MsgExpRevive(targetid, subject)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by reviving \x04%N\x03!", GetConVarInt(ReviveExp), subject)
}

/* Message: heal somebody */
MsgExpHeal(targetid, subject)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by healing \x04%N\x03!", GetConVarInt(HealExp), subject)
}

/* Message: killing a Tank */
MsgExpTank(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Tank\x03!", GetConVarInt(TanExp))
}

/* Message: surviveing a Tank */
MsgExpTankSurvive(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by surviving a \x04Tank\x03!", GetConVarInt(TanExp))
}

/* Message: killing a Charger */
MsgExpCharger(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Charger\x03!", GetConVarInt(ChaExp))
}

/* Message: killing a Jockey */
MsgExpJockey(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Jockey\x03!", GetConVarInt(JocExp))
}

/* Message: killing a Spitter */
MsgExpSpitter(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Spitter\x03!", GetConVarInt(SpiExp))
}

/* Message: killing a Hunter */
MsgExpHunter(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Hunter\x03!", GetConVarInt(HunExp))
}

/* Message: killing a Boomer */
MsgExpBoomer(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Boomer\x03!", GetConVarInt(BooExp))
}

/* Message: killing a Smoker */
MsgExpSmoker(targetid)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03You got \x04%d\x03 EXP by killing a \x04Smoker\x03!", GetConVarInt(SmoExp))
}

/* Message: buy item success */
MsgBuySucc(targetid, itemcost)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Buy success! Paid: \x04%d\x03$ Left: \x04%d\x03$", itemcost, Cash[targetid])
}

/* Message: buy item failed */
MsgBuyFail(targetid, itemcost)
{
	PrintToChat(targetid, "\x04[Battle-RPG] \x03Buy failed! Need: \x04%d\x03$ Cash: \x04%d\x03$", itemcost, Cash[targetid])
}

/* Reset Target Player */
ResetTarget(targetid)
{
	JobLevel[targetid] = 0
	Job[targetid] = 0
	JobLock[targetid] = 0
	TempStr[targetid] = 0
	TempAgi[targetid] = 0
	TempHP[targetid] = 0
	TempEnd[targetid] = 0	
	RebuildStatus(targetid)
}

/* Rebuild Player */
RebuildStatus(client)
{
	SetHealthMax(client, GetHealthMaxToSet(client))
	SetAgility(client)
}

GetHealthMaxToSet(targetid) //Job Basis Health + Temp Health Skill
{
	new MaxHealth = (GetJobHealth(Job[targetid])+TempHP[targetid])
	new hl = GetConVarInt(CfgLimitHealth)
	if(MaxHealth > hl && hl != 0)
	{
		MaxHealth = hl
	}
	return MaxHealth
}

GetJobHealth(jobid)
{
	return GetConVarInt(JobHealth[jobid])
}

GetJobReqLevel(jobid)
{
	return GetConVarInt(JobReqLevel[jobid])
}

GetJobHP(jobid)
{
	return GetConVarInt(JobHP[jobid])
}

GetJobCash(jobid)
{
	return GetConVarInt(JobCash[jobid])
}

GetJobAgi(jobid)
{
	return GetConVarInt(JobAgi[jobid])
}

GetJobStr(jobid)
{
	return GetConVarInt(JobStr[jobid])
}

GetJobEnd(jobid)
{
	return GetConVarInt(JobEnd[jobid])
}

GetItemCost(itemNum)
{
	return GetConVarInt(ItemCost[itemNum])
}

SetEndurance(client, health, endurance)
{
	SetEntityHealth(client, health+endurance)
}

SetEndReflect(client, health, endurance)
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

SetStrDamage(client, health, str)
{
	if(health > str)
	{
		SetEntityHealth(client, health-str)
	}
}

SetHealthMax(targetid, amount)
{
	if(targetid != 0 && !IsFakeClient(targetid))
	{
		SetEntData(targetid, FindDataMapOffs(targetid, "m_iMaxHealth"), amount, 4, true)
	}
}

SetHealth(targetid, amount)
{
	if(targetid != 0 && !IsFakeClient(targetid))
	{
		SetEntData(targetid, FindDataMapOffs(targetid, "m_iHealth"), amount, 4, true)
	}
}

ResetAgility(targetid)
{
	SetEntityGravity(targetid, 1.0)
	SetEntDataFloat(targetid, LegValue, 1.0, true)
}

SetAgility(targetid)
{
	new gl = GetConVarInt(CfgLimitAgilityGravity)
	new sl = GetConVarInt(CfgLimitAgilitySpeed)
	
	/* Check Speed Limit */
	if(TempAgi[targetid] < sl || sl == 0)
	{
		SetEntDataFloat(targetid, LegValue, 1.0*(1.0 + TempAgi[targetid]*0.01), true)
	}
	else
	{
		SetEntDataFloat(targetid, LegValue, 1.0*(1.0 + sl*0.01), true)
	}
	/* Check Gravity Limit */
	if(TempAgi[targetid] < gl || gl == 0)
	{
		SetEntityGravity(targetid, 1.0*(1.0-(TempAgi[targetid]*0.005)))
	}
	else
	{
		SetEntityGravity(targetid, 1.0*(1.0-(gl*0.005)))
	}
	
	/* Set Limit */
	if(TempAgi[targetid] > gl && TempAgi[targetid] > sl)
	{
		if(gl < sl)
		{
			TempAgi[targetid] = sl
		}
		else
		{
			TempAgi[targetid] = gl
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
public Action:GiveItemsTimer(Handle:timer, any:targetid)
{
	GiveJobItems(targetid)
	return Plugin_Continue
}

/* Check Exp Timer */
public Action:CheckExpTimer(Handle:timer, any:targetid)
{
	new TargetEXP = EXP[targetid]
	if(GetConVarInt(CfgExpMode) == 1) // Subtract EXP
	{
		if(TargetEXP >= GetConVarInt(LevelUpExp))
		{
			EXP[targetid] -= GetConVarInt(LevelUpExp)
			LevelUp(targetid)
		}
	}
	if(GetConVarInt(CfgExpMode) == 2) // Keep EXP + multiply required EXP by job level
	{
		if(TargetEXP >= (GetConVarInt(LevelUpExp)*(JobLevel[targetid]+1)))
		{
			LevelUp(targetid)
		}
	}
	if(GetConVarInt(CfgExpMode) == 3) // Subtract EXP + multiply required EXP by job level
	{
		if(TargetEXP >= (GetConVarInt(LevelUpExp)*(JobLevel[targetid]+1)))
		{
			EXP[targetid] -= GetConVarInt(LevelUpExp)
			LevelUp(targetid)
		}
	}
	return Plugin_Continue
}

/* Remind Job Timer */
public Action:AnnounceRemindJobTimer(Handle:timer, any:targetid)
{
	if(targetid != 0)
	{
		if(Job[targetid] == 0 && GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid))
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
public Action:AnnounceFirstTimer(Handle:timer, any:targetid)
{
	if(targetid != 0)
	{
		if(Job[targetid] == 0 && GetClientTeam(targetid) == TEAM_SURVIVORS && !IsFakeClient(targetid))
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

/* On Level Up */
public Action:LevelUp(targetid)
{
	/* Level */
	Level[targetid] += 1
	JobLevel[targetid] += 1
	MsgLevelUp(targetid)

	/* Cash */
	new cl = GetConVarInt(CfgLimitCash)
	
	if(Cash[targetid] <= cl || cl == 0)
	{
		Cash[targetid] += GetJobCash(Job[targetid])
	}
	else
	{
		Cash[targetid] = cl
	}
	
	/* Items */
	if(GetConVarInt(CfgItemsOnLevelUp) == 1)
	{
		GiveJobItems(targetid)
	}
	
	/* Health Mode */
	new hpmode = GetConVarInt(CfgJobHPOnLevelUp)
	if(hpmode == 1) // Mode 1: Incease Only Health
	{
		SetHealth(targetid, (GetClientHealth(targetid)+GetJobHP(Job[targetid])))
	}
	if(hpmode == 2) // Mode 2: Increase Only Max Health
	{
		TempHP[targetid] += GetJobHP(Job[targetid])
	}
	if(hpmode == 3) // Mode 3: Increase Health & Max Health
	{
		SetHealth(targetid, (GetClientHealth(targetid)+GetJobHP(Job[targetid])))
		TempHP[targetid] += GetJobHP(Job[targetid])
	}
	
	/* RPG Mode */
	if(GetConVarInt(CfgSkillMode) == 1) // Mode 1: Job skill on level up */
	{
		TempStr[targetid] += GetJobStr(Job[targetid])
		TempAgi[targetid] += GetJobAgi(Job[targetid])
		TempEnd[targetid] += GetJobEnd(Job[targetid])
	}
	RebuildStatus(targetid)
	
	/* Save To File */
	PlayerSaveToFile(targetid, true, true, true)
}

public Action:PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "dmg_health")
	if(hurted != 0)
	{
		if(GetClientTeam(hurted) == TEAM_SURVIVORS && !IsFakeClient(hurted))
		{
			if(GetConVarInt(CfgDamageReflectOnly) == 1)
			{
				new Float:RefFloat = (TempEnd[hurted])*0.01
				new RefDecHealth = RoundToNearest(dmg*RefFloat)
				new RefHealth = GetClientHealth(attacker)
				SetEndReflect(attacker, RefHealth, RefDecHealth)
			}
			else
			{
				new el = GetConVarInt(CfgLimitEndurance)
				if(TempEnd[hurted] <= el && el != 0)
				{
					TempEnd[hurted] = el
				}
				if(TempEnd[hurted] <= 50)
				{
					new EndHealth = GetEventInt(event, "health")
					new Float:EndFloat = TempEnd[hurted]*0.01
					new EndAddHealth = RoundToNearest(dmg*EndFloat)
					SetEndurance(hurted, EndHealth, EndAddHealth)
				}
				else
				{
					new EndHealth = GetEventInt(event, "health")
					new EndAddHealth = RoundToNearest(dmg*0.5)
					SetEndurance(hurted, EndHealth, EndAddHealth)
					new Float:RefFloat = (TempEnd[hurted]-50)*0.01
					new RefDecHealth = RoundToNearest(dmg*RefFloat)
					new RefHealth = GetClientHealth(attacker)
					SetEndReflect(attacker, RefHealth, RefDecHealth)
				}
			}
		}
	}
	if(GetClientTeam(hurted) == TEAM_INFECTED && !IsFakeClient(hurted) && hurted != 0)
	{
		new sl = GetConVarInt(CfgLimitStrength)
		if(TempStr[hurted] <= sl && sl != 0)
		{
			TempStr[hurted] = sl
		}
		new StrHealth = GetEventInt(event, "health")
		new Float:StrFloat = TempStr[attacker]*0.01
		new StrRedHealth = RoundToNearest(dmg*StrFloat)
		SetStrDamage(hurted, StrHealth, StrRedHealth)
	}
}

public Action:InfectedHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetEventInt(event, "entityid")
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "amount")
	if(1 <= attacker <= MaxClients)
	{
		if(GetClientTeam(attacker) == TEAM_SURVIVORS && !IsFakeClient(attacker))
		{
			new Float:StrFloat = TempStr[attacker]*0.01
			new StrRedHealth = RoundToNearest(dmg*StrFloat)
			if(GetEntProp(hurted, Prop_Data, "m_iHealth") > StrRedHealth)
			{
				SetEntProp(hurted, Prop_Data, "m_iHealth", GetEntProp(hurted, Prop_Data, "m_iHealth")-StrRedHealth)
			}
		}
	}
}

/* RPG-MENU*/

//RPG Menu
public Action:RPG_Menu(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		RPG_MenuFunc(client)
	}
	return Plugin_Handled
}

//RPG Menu Func
public Action:RPG_MenuFunc(targetid) 
{
	new Handle:menu = CreateMenu(RPG_MenuHandler)
	SetMenuTitle(menu, "Level: %d | Cash: %d $ | EXP: %d Exp", Level[targetid], Cash[targetid], EXP[targetid])

	AddMenuItem(menu, "option1", "Job Menu")
	AddMenuItem(menu, "option2", "Buy Shop")
	
	/* Show BackPack Button? */
	if(GetConVarInt(CfgBackPackAvailable) == 1)
	{
		AddMenuItem(menu, "option3", "BackPack")
	}
	
	SetMenuExitButton(menu, true)
	
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)

	return Plugin_Handled
}

public RPG_MenuHandler(Handle:menu, MenuAction:action, client, itemNum)
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

//Buy Menu
public Action:Buy_Menu(client,args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		Buy_MenuFunc(client)
	}
	return Plugin_Handled
}

//Buy Menu Func
public Action:Buy_MenuFunc(targetid) 
{
	new Handle:menu = CreateMenu(Buy_MenuHandler)
	SetMenuTitle(menu, "Cash: %d $", Cash[targetid])

	
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
	
	SetMenuExitButton(menu, true)
	
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)

	return Plugin_Handled
}

public Buy_MenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		new targetcash = Cash[client]
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
			}
			Cash[client] = targetcash
			MsgBuySucc(client, itemcost)
		}
		else
		{
			MsgBuyFail(client, itemcost)
		}
	}
}

/* Job MENU */

//Job Menu
public Action:Job_Menu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		Job_MenuFunc(client)
	}
	return Plugin_Handled
}

//Job Menu Func
public Action:Job_MenuFunc(targetid) 
{
	new Handle:menu = CreateMenu(Job_MenuHandler)
	SetMenuTitle(menu, "Level: %d | NextLv: -%dExp", Level[targetid], (GetConVarInt(LevelUpExp)-EXP[targetid]))
	AddMenuItem(menu, "option1", "Show my skills")
	AddMenuItem(menu, "option2", "Civilian")
	AddMenuItem(menu, "option3", "Scout")
	AddMenuItem(menu, "option4", "Soldier")
	AddMenuItem(menu, "option5", "Medic")
	AddMenuItem(menu, "option6", "Drug Dealer")
	AddMenuItem(menu, "option7", "Sniper")
	AddMenuItem(menu, "option8", "Weapon Dealer")
	AddMenuItem(menu, "option9", "Pyrotechnical")
	AddMenuItem(menu, "option10", "Witch Hunter") 
	AddMenuItem(menu, "option11", "Tank Buster")
	AddMenuItem(menu, "option12", "Ninja")
	AddMenuItem(menu, "option13", "General")
	AddMenuItem(menu, "option14", "Fuck Me IM FAMOUS!!")
	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Job_MenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		if(itemNum == 0 && Job[client] > 0)
		{
			FakeClientCommand(client, "rpgskills")
		}
		else if(itemNum == 0 && Job[client] == 0)
		{
			MsgFeatureReqJob(client)	
			FakeClientCommand(client, "jobmenu")
		}
		else
		{
			ISJOBCONFIRM[client] = itemNum
			FakeClientCommand(client, "jobconfirm")
		}
	}
}

/*  Show Skills */
public Action:PlayersSkills(targetid, args)
{
	if(GetClientTeam(targetid) == TEAM_SURVIVORS)
	{
		MsgPlayersSkills(targetid)
	}
	return Plugin_Handled
}

public Action:JobConfirmChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		JobConfirmFunc(client)
	}
	return Plugin_Handled
}

public Action:JobConfirmFunc(targetid)
{
	MsgJobInfo(targetid, ISJOBCONFIRM[targetid])
	new Handle:menu = CreateMenu(JobConfirmHandler)
	SetMenuTitle(menu, "Sure? You will loose all your job skills!")
	AddMenuItem(menu, "option1", "Yes")
	AddMenuItem(menu, "option2", "No")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, targetid, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public JobConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select && itemNum == 0 && Level[client] >= GetJobReqLevel(ISJOBCONFIRM[client]) && JobLock[client] == 0 && ISJOBCONFIRM[client] != 0)
	{
		JobLock[client] = 1
		Job[client] = ISJOBCONFIRM[client]
		EXP[client] = 0 //Reset Exp
		/* Mode 1: Job skill on level up */
		if(GetConVarInt(CfgSkillMode) == 1)
		{
			TempStr[client] = 0
			TempAgi[client] = 0
			TempHP[client] = 0
			TempEnd[client] = 0
			
			SetHealthMax(client, GetHealthMaxToSet(client))
			SetHealth(client, GetHealthMaxToSet(client))
			RebuildStatus(client)
			MsgJobConfirmed(client)
		}
		/* Mode 2: Job skill on job select */
		if(GetConVarInt(CfgSkillMode) == 2)
		{
			TempStr[client] = GetJobStr(Job[client])
			TempAgi[client] = GetJobAgi(Job[client])
			TempEnd[client] = GetJobEnd(Job[client])
			
			SetHealthMax(client, GetHealthMaxToSet(client))
			SetHealth(client, GetHealthMaxToSet(client))
			RebuildStatus(client)
			MsgJobConfirmed(client)
		}
		/* First give of Job Items */
		GiveJobItems(client)
		
		if(GetConVarFloat(CfgItemsTimer) != 0)
		{
			GiveTimedItems[client] = CreateTimer(GetConVarFloat(CfgItemsTimer), GiveItemsTimer, client, TIMER_REPEAT)
		}
	}
	else if(action == MenuAction_Select && itemNum == 0 && Job[client] != 0)
	{
		MsgJobLock(client)
		FakeClientCommand(client,"jobmenu")
	}
	
	if(action == MenuAction_Select && itemNum == 0 && Level[client] < GetJobReqLevel(ISJOBCONFIRM[client]))
	{
		MsgJobReqLevel(client)
		FakeClientCommand(client,"jobmenu")
	}
}

/* Give Job Items? */
GiveJobItems(client)
{
	if(GetConVarInt(CfgItemsEnable) == 1)
	{
		new targetjob = Job[client]
		switch(targetjob)
		{
			case 1: //Civilian
			{
				//P. Weapon
				CheatCommand(client, "give", "smg_silenced")
				//S. Weapon
				CheatCommand(client, "give", "pistol")
				//Health Item
				//Other Items
			}
			case 2: //Scout
			{
				//P. Weapon
				CheatCommand(client, "give", "sniper_scout")
				//S. Weapon
				CheatCommand(client, "give", "baseball_bat")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				//Other Items
			}
			case 3: //Soldier
			{
				//P. Weapon
				CheatCommand(client, "give", "rifle_ak47")
				//S. Weapon
				CheatCommand(client, "give", "fireaxe")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				//Other Items
			}
			case 4: //Medic
			{
				//P. Weapon
				CheatCommand(client, "give", "smg_silenced")
				//S. Weapon
				CheatCommand(client, "give", "knife")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "defibrillator")
				CheatCommand(client, "give", "first_aid_kit")
				//Other Items
			}
			case 5: //Drug Dealer
			{
				//P. Weapon
				CheatCommand(client, "give", "smg_silenced")
				//S. Weapon
				CheatCommand(client, "give", "baseball_bat")
				//Health Item
				CheatCommand(client, "give", "adrenaline")
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "adrenaline")
				//Other Items
			}
			case 6: //Sniper
			{
				//P. Weapon
				CheatCommand(client, "give", "sniper_awp")
				//S. Weapon
				CheatCommand(client, "give", "baseball_bat")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				//Other Items
				CheatCommand(client, "give", "upgradepack_explosive")
				CheatCommand(client, "give", "pipe_bomb")
			}
			case 7: //Weapon Dealer
			{
				//P. Weapon
				CheatCommand(client, "give", "rifle_sg552")
				//S. Weapon
				CheatCommand(client, "give", "pistol_magnum")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				//Other Items
				CheatCommand(client, "give", "pipe_bomb")
				CheatCommand(client, "give", "vomitjar")
			}
			case 8: //Pyrotechnical
			{
				//P. Weapon
				CheatCommand(client, "give", "smg_silenced")
				//S. Weapon
				CheatCommand(client, "give", "fireaxe")
					//Health Item
				CheatCommand(client, "give", "pain_pills")
				//Other Items
				CheatCommand(client, "give", "vomitjar")
				CheatCommand(client, "give", "molotov")
				CheatCommand(client, "give", "upgradepack_incendiary")
			}
			case 9: //Witch Hunter
			{
				//P. Weapon
				CheatCommand(client, "give", "autoshotgun")
				//S. Weapon
				CheatCommand(client, "give", "pistol_magnum")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "adrenaline")
				//Other Items
				CheatCommand(client, "give", "pipe_bomb")
				CheatCommand(client, "give", "upgradepack_incendiary")
			}
			case 10: //Tank Buster
			{
				//P. Weapon
				CheatCommand(client, "give", "autoshotgun")
				//S. Weapon
				CheatCommand(client, "give", "fireaxe")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "adrenaline")
				CheatCommand(client, "give", "pain_pills")
				//Other Items
				CheatCommand(client, "give", "molotov")
				CheatCommand(client, "give", "pipe_bomb")
				CheatCommand(client, "give", "molotov")
			}
			case 11: //Ninja
			{
				//P. Weapon
				CheatCommand(client, "give", "smg_silenced")
				//S. Weapon
				CheatCommand(client, "give", "katana")
				//Health Item
				CheatCommand(client, "give", "adrenaline")
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "adrenaline")
				//Other Items
				CheatCommand(client, "give", "vomitjar")
				CheatCommand(client, "give", "molotov")
				CheatCommand(client, "give", "upgradepack_explosive")
			}
			case 12: //General
			{
				//P. Weapon
				CheatCommand(client, "give", "smg_silenced")
				//S. Weapon
				CheatCommand(client, "give", "pistol_magnum")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "adrenaline")
				CheatCommand(client, "give", "pain_pills")
				//Other Items
				CheatCommand(client, "give", "vomitjar")
				CheatCommand(client, "give", "pipe_bomb")
				CheatCommand(client, "give", "molotov")
				CheatCommand(client, "give", "upgradepack_explosive")
			}
			case 13: //Fuck Me IM FAMOUS!!
			{
				//P. Weapon
				CheatCommand(client, "give", "grenade_launcher")
				//S. Weapon
				CheatCommand(client, "give", "chainsaw")
				//Health Item
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "adrenaline")
				CheatCommand(client, "give", "pain_pills")
				CheatCommand(client, "give", "defibrillator")
				CheatCommand(client, "give", "first_aid_kit")
				//Other Items
				CheatCommand(client, "give", "vomitjar")
				CheatCommand(client, "give", "pipe_bomb")
				CheatCommand(client, "give", "molotov")
				CheatCommand(client, "give", "vomitjar")
				CheatCommand(client, "give", "pipe_bomb")
				CheatCommand(client, "give", "molotov")
				CheatCommand(client, "give", "upgradepack_explosive")
				CheatCommand(client, "give", "upgradepack_incendiary")
				CheatCommand(client, "give", "upgradepack_explosive")
				//Special Items
				CheatCommand(client, "give", "fireworkcrate")
			}
		}
	}
}

/* Execute Cheat Commads */
stock CheatCommand(client, const String:command[], const String:arguments[])
{
    if (!client) return;
    new admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, admindata);
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
