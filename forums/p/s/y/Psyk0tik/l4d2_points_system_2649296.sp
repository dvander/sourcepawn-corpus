#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.8.0"

#define MSGTAG "\x04[PS]\x01"
#define MODULES_SIZE 100
#define MAX_MELEE_LENGTH 10

#pragma semicolon 1
//#pragma newdecls required

public Plugin myinfo =
{
	name = "Points System",
	author = "McFlurry & evilmaniac and modified by Psykotik",
	description = "Customized edition of McFlurry's points system",
	version = PLUGIN_VERSION,
	url = "http://www.evilmania.net"
}

Handle hDatabase;
Handle ModulesArray = null;
Handle Forward1 = null;
Handle Forward2 = null;

enum plugin_settings{
	Float:fVersion,
	iStringSize,
	Handle:hVersion,
	Handle:hEnabled,
	Handle:hModes,
	Handle:hNotifications,
	Handle:hKillSpreeNum,
	Handle:hHeadShotNum,
	Handle:hTankLimit,
	Handle:hWitchLimit,
	Handle:hResetPoints,
	Handle:hStartPoints,
	Handle:hSpawnAttempts
}
new PluginSettings[plugin_settings];

void initPluginSettings(){
	PluginSettings[fVersion] = 1.80;
	PluginSettings[iStringSize] = 64;

	PluginSettings[hVersion] = CreateConVar("em_points_sys_version", PLUGIN_VERSION, "Version of Points System on this server.", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	PluginSettings[hStartPoints] = CreateConVar("l4d2_points_start", "100", "Points to start each round/map with.");
	PluginSettings[hNotifications] = CreateConVar("l4d2_points_notify", "1", "Show messages when points are earned?");
	PluginSettings[hEnabled] = CreateConVar("l4d2_points_enable", "1", "Enable Point System?");
	PluginSettings[hModes] = CreateConVar("l4d2_points_modes", "coop,realism", "Which game modes to use Point System");
	PluginSettings[hResetPoints] = CreateConVar("l4d2_points_reset_mapchange", "", "Which game modes to reset point count on round end and round start");
	PluginSettings[hTankLimit] = CreateConVar("l4d2_points_tank_limit", "2", "How many tanks to be allowed spawned per team");
	PluginSettings[hWitchLimit] = CreateConVar("l4d2_points_witch_limit", "3", "How many witches to be allowed spawned per team");
	PluginSettings[hSpawnAttempts] = CreateConVar("l4d2_points_spawn_tries", "99", "How many times to attempt respawning when buying an special infected");
	PluginSettings[hKillSpreeNum] = CreateConVar("l4d2_points_cikills", "10", "How many kills you need to earn a killing spree bounty");
	PluginSettings[hHeadShotNum] = CreateConVar("l4d2_points_headshots", "5", "How many headshot kills you need to earn a head hunter bonus");
	return;
}

enum plugin_sprites{
	BeamSprite,
	HaloSprite
}
new PluginSprites[plugin_sprites];

void initPluginSprites(){
	PluginSprites[BeamSprite] = PrecacheModel("sprites/laserbeam.vmt");
	PluginSprites[HaloSprite] = PrecacheModel("sprites/glow01.vmt");
	return;
}

enum player_data{
	bool:bMessageSent, // Whether welcome message has been displayed to player or not
	bool:bPointsLoaded, // Whether a player's points have been loaded from the Clientprefs database
	bool:bWitchBurning, // Whether a player has ignited a witch on fire or not
	bool:bTankBurning, // Whether a player has ignited a tank on fire or not
	String:sBought[64], // Last purchased item (redundant)
	String:sItemName[64], // The item the player intends to purchase
	iBoughtCost, // Cost of last purchased item (redundant)
	iItemCost, // The cost of an item the player intends to purchase
	iPlayerPoints, // Amount of spendable points
	iProtectCount, // Number of times player has protected a team mate
	iKillCount, // Kills made as a survivor
	iHeadShotCount, // Headshots dealt to infected as a survivor
	iHurtCount // Damage dealt to survivors while infected
}
new PlayerData[MAXPLAYERS][player_data];

void initPlayerData(iClientIndex){
	if(iClientIndex < MAXPLAYERS){
		PlayerData[iClientIndex][bMessageSent] 		= false;
		PlayerData[iClientIndex][bPointsLoaded] 	= false;
		PlayerData[iClientIndex][bWitchBurning] 	= false;
		PlayerData[iClientIndex][bTankBurning] 		= false;

		PlayerData[iClientIndex][iBoughtCost]		= 0;
		PlayerData[iClientIndex][iItemCost] 		= 0;
		PlayerData[iClientIndex][iPlayerPoints] 	= 0;
		PlayerData[iClientIndex][iProtectCount] 	= 0;
		PlayerData[iClientIndex][iKillCount] 		= 0;
		PlayerData[iClientIndex][iHeadShotCount] 	= 0;
		PlayerData[iClientIndex][iHurtCount] 		= 0;
		initPlayerData(++iClientIndex);
	}
	return;
}

void initAllPlayerData(){
	initPlayerData(1);
	return;
}

enum counter_data{
	iTanksSpawned,
	iWitchesSpawned,
	iUCommonLeft,
}
new CounterData[counter_data];

void initCounterData(){
	CounterData[iTanksSpawned] = 0;
	CounterData[iWitchesSpawned] = 0;
	return;
}

enum item_costs{
	Handle:CostP220,
	Handle:CostMagnum,
	Handle:CostUzi,
	Handle:CostSilenced,
	Handle:CostMP5,
	Handle:CostM16,
	Handle:CostAK47,
	Handle:CostSCAR,
	Handle:CostSG552,
	Handle:CostHunting,
	Handle:CostMilitary,
	Handle:CostAWP,
	Handle:CostScout,
	Handle:CostAuto,
	Handle:CostSPAS,
	Handle:CostChrome,
	Handle:CostPump,
	Handle:CostGrenade,
	Handle:CostM60,
	Handle:CostGasCan,
	Handle:CostOxygen,
	Handle:CostPropane,
	Handle:CostGnome,
	Handle:CostCola,
	Handle:CostFireworks,
	Handle:CostBaseballbat,
	Handle:CostCricketbat,
	Handle:CostCrowbar,
	Handle:CostElectricguitar,
	Handle:CostFireaxe,
	Handle:CostFryingpan,
	Handle:CostGolfclub,
	Handle:CostKatana,
	Handle:CostMachete,
	Handle:CostTonfa,
	Handle:CostChainsaw,
	Handle:CostPipe,
	Handle:CostMolotov,
	Handle:CostBile,
	Handle:CostHealthKit,
	Handle:CostDefib,
	Handle:CostAdren,
	Handle:CostPills,
	Handle:CostExplosiveAmmo,
	Handle:CostFireAmmo,
	Handle:CostExplosivePack,
	Handle:CostFirePack,
	Handle:CostLaserSight,
	Handle:CostAmmo,
	Handle:CostHeal,
	Handle:CostSuicide,
	Handle:CostHunter,
	Handle:CostJockey,
	Handle:CostSmoker,
	Handle:CostCharger,
	Handle:CostBoomer,
	Handle:CostSpitter,
	Handle:CostInfectedHeal,
	Handle:CostWitch,
	Handle:CostTank,
	Handle:CostTankHealMultiplier,
	Handle:CostHorde,
	Handle:CostMob,
	Handle:CostUncommonMob,
}
new ItemCosts[item_costs];

void initItemCosts(){
	ItemCosts[CostP220] = CreateConVar("l4d2_points_pistol", "200", "How many points the p220 pistol costs");
	ItemCosts[CostMagnum] = CreateConVar("l4d2_points_magnum", "200", "How many points the magnum pistol costs");
	ItemCosts[CostUzi] = CreateConVar("l4d2_points_smg", "250", "How many points the smg costs");
	ItemCosts[CostSilenced] = CreateConVar("l4d2_points_silenced", "250", "How many points the silenced smg costs");
	ItemCosts[CostMP5] = CreateConVar("l4d2_points_mp5", "250", "How many points the mp5 smg costs");
	ItemCosts[CostM16] = CreateConVar("l4d2_points_m16", "350", "How many points the m16 rifle costs");
	ItemCosts[CostAK47] = CreateConVar("l4d2_points_ak47", "350", "How many points the ak47 rifle costs");
	ItemCosts[CostSCAR] = CreateConVar("l4d2_points_scar", "350", "How many points the scar-l rifle costs");
	ItemCosts[CostSG552] = CreateConVar("l4d2_points_sg552", "350", "How many points the sg552 rifle costs");
	ItemCosts[CostMilitary] = CreateConVar("l4d2_points_military", "400", "How many points the military sniper rifle costs");
	ItemCosts[CostAWP] = CreateConVar("l4d2_points_awp", "400", "How many points the awp sniper rifle costs");
	ItemCosts[CostScout] = CreateConVar("l4d2_points_scout", "400", "How many points the scout sniper rifle costs");
	ItemCosts[CostHunting] = CreateConVar("l4d2_points_hunting", "400", "How many points the hunting rifle costs");
	ItemCosts[CostAuto] = CreateConVar("l4d2_points_auto", "300", "How many points the autoshotgun costs");
	ItemCosts[CostSPAS] = CreateConVar("l4d2_points_spas", "300", "How many points the spas shotgun costs");
	ItemCosts[CostChrome] = CreateConVar("l4d2_points_chrome", "250", "How many points the chrome shotgun costs");
	ItemCosts[CostPump] = CreateConVar("l4d2_points_pump", "250", "How many points the pump shotgun costs");
	ItemCosts[CostGrenade] = CreateConVar("l4d2_points_grenade", "450", "How many points the grenade launcher costs");
	ItemCosts[CostM60] = CreateConVar("l4d2_points_m60", "450", "How many points the m60 rifle costs");
	ItemCosts[CostGasCan] = CreateConVar("l4d2_points_gascan", "50", "How many points the gas can costs");
	ItemCosts[CostOxygen] = CreateConVar("l4d2_points_oxygen", "50", "How many points the oxgen tank costs");
	ItemCosts[CostPropane] = CreateConVar("l4d2_points_propane", "50", "How many points the propane tank costs");
	ItemCosts[CostGnome] = CreateConVar("l4d2_points_gnome", "50", "How many points the gnome costs");
	ItemCosts[CostCola] = CreateConVar("l4d2_points_cola", "50", "How many points cola bottles costs");
	ItemCosts[CostFireworks] = CreateConVar("l4d2_points_fireworks", "50", "How many points the fireworks crate costs");
	ItemCosts[CostBaseballbat] = CreateConVar("l4d2_points_baseballbat", "200", "How many points the baseball bat costs");
	ItemCosts[CostCricketbat] = CreateConVar("l4d2_points_cricketbat", "200", "How many points the cricket bat costs");
	ItemCosts[CostCrowbar] = CreateConVar("l4d2_points_crowbar", "200", "How many points the crowbar costs");
	ItemCosts[CostElectricguitar] = CreateConVar("l4d2_points_electricguitar", "200", "How many points the electric guitar costs");
	ItemCosts[CostFireaxe] = CreateConVar("l4d2_points_fireaxe", "200", "How many points the fire axe costs");
	ItemCosts[CostFryingpan] = CreateConVar("l4d2_points_fryingpan", "200", "How many points the frying pan costs");
	ItemCosts[CostGolfclub] = CreateConVar("l4d2_points_golfclub", "200", "How many points the golf club costs");
	ItemCosts[CostKatana] = CreateConVar("l4d2_points_katana", "200", "How many points the katana costs");
	ItemCosts[CostMachete] = CreateConVar("l4d2_points_machete", "200", "How many points the machete costs");
	ItemCosts[CostTonfa] = CreateConVar("l4d2_points_tonfa", "200", "How many points the nightstick costs");
	ItemCosts[CostChainsaw] = CreateConVar("l4d2_points_chainsaw", "200", "How many points the chainsaw costs");
	ItemCosts[CostPipe] = CreateConVar("l4d2_points_pipe", "100", "How many points the pipe bomb costs");
	ItemCosts[CostMolotov] = CreateConVar("l4d2_points_molotov", "100", "How many points the molotov costs");
	ItemCosts[CostBile] = CreateConVar("l4d2_points_bile", "100", "How many points the bile jar costs");
	ItemCosts[CostHealthKit] = CreateConVar("l4d2_points_medkit", "150", "How many points the health kit costs");
	ItemCosts[CostDefib] = CreateConVar("l4d2_points_defib", "150", "How many points the defib costs");
	ItemCosts[CostAdren] = CreateConVar("l4d2_points_adrenaline", "50", "How many points the adrenaline costs");
	ItemCosts[CostPills] = CreateConVar("l4d2_points_pills", "50", "How many points the pills costs");
	ItemCosts[CostExplosiveAmmo] = CreateConVar("l4d2_points_explosive_ammo", "150", "How many points the explosive ammo costs");
	ItemCosts[CostFireAmmo] = CreateConVar("l4d2_points_incendiary_ammo", "150", "How many points the incendiary ammo costs");
	ItemCosts[CostExplosivePack] = CreateConVar("l4d2_points_explosive_ammo_pack", "150", "How many points the explosive ammo pack costs");
	ItemCosts[CostFirePack] = CreateConVar("l4d2_points_incendiary_ammo_pack", "150", "How many points the incendiary ammo pack costs");
	ItemCosts[CostLaserSight] = CreateConVar("l4d2_points_laser", "100", "How many points the laser sight costs");
	ItemCosts[CostHeal] = CreateConVar("l4d2_points_survivor_heal", "100", "How many points a complete heal costs");
	ItemCosts[CostAmmo] = CreateConVar("l4d2_points_refill", "100", "How many points an ammo refill costs");

	ItemCosts[CostSuicide] = CreateConVar("l4d2_points_suicide", "100", "How many points does suicide cost");
	ItemCosts[CostHunter] = CreateConVar("l4d2_points_hunter", "250", "How many points does a hunter cost");
	ItemCosts[CostJockey] = CreateConVar("l4d2_points_jockey", "325", "How many points does a jockey cost");
	ItemCosts[CostSmoker] = CreateConVar("l4d2_points_smoker", "250", "How many points does a smoker cost");
	ItemCosts[CostCharger] = CreateConVar("l4d2_points_charger", "600", "How many points does a charger cost");
	ItemCosts[CostBoomer] = CreateConVar("l4d2_points_boomer", "50", "How many points does a boomer cost");
	ItemCosts[CostSpitter] = CreateConVar("l4d2_points_spitter", "100", "How many points does a spitter cost");
	ItemCosts[CostInfectedHeal] = CreateConVar("l4d2_points_infected_heal", "50", "How many points does healing yourself as an infected cost");
	ItemCosts[CostWitch] = CreateConVar("l4d2_points_witch", "1000", "How many points does a witch cost");
	ItemCosts[CostTank] = CreateConVar("l4d2_points_tank", "4000", "How many points does a tank cost");
	ItemCosts[CostTankHealMultiplier] = CreateConVar("l4d2_points_tank_heal_mult", "0", "How much l4d2_points_infected_heal should be multiplied for tank players");
	ItemCosts[CostHorde] = CreateConVar("l4d2_points_horde", "50", "How many points does a horde cost");
	ItemCosts[CostMob] = CreateConVar("l4d2_points_mob", "50", "How many points does a mob cost");
	ItemCosts[CostUncommonMob] = CreateConVar("l4d2_points_umob", "50", "How many points does an uncommon mob cost");
	return;
}

enum categories_enabled{
	Handle:CategoryRifles,
	Handle:CategorySMG,
	Handle:CategorySnipers,
	Handle:CategoryShotguns,
	Handle:CategoryHealth,
	Handle:CategoryUpgrades,
	Handle:CategoryThrowables,
	Handle:CategoryMisc,
	Handle:CategoryMelee,
	Handle:CategoryWeapons
}
new CategoriesEnabled[categories_enabled];

void initCategoriesEnabled(){
	CategoriesEnabled[CategoryRifles] = CreateConVar("l4d2_points_cat_rifles", "1", "Enable rifles category");
	CategoriesEnabled[CategorySMG] = CreateConVar("l4d2_points_cat_smg", "1", "Enable smg category");
	CategoriesEnabled[CategorySnipers] = CreateConVar("l4d2_points_cat_snipers", "1", "Enable snipers category");
	CategoriesEnabled[CategoryShotguns] = CreateConVar("l4d2_points_cat_shotguns", "1", "Enable shotguns category");
	CategoriesEnabled[CategoryHealth] = CreateConVar("l4d2_points_cat_health", "1", "Enable health category");
	CategoriesEnabled[CategoryUpgrades] = CreateConVar("l4d2_points_cat_upgrades", "1", "Enable upgrades category");
	CategoriesEnabled[CategoryThrowables] = CreateConVar("l4d2_points_cat_throwables", "1", "Enable throwables category");
	CategoriesEnabled[CategoryMisc] = CreateConVar("l4d2_points_cat_misc", "1", "Enable misc category");
	CategoriesEnabled[CategoryMelee] = CreateConVar("l4d2_points_cat_melee", "1", "Enable melee category");
	CategoriesEnabled[CategoryWeapons] = CreateConVar("l4d2_points_cat_weapons", "1", "Enable weapons category");
	return;
}

enum point_rewards{
	Handle:SurvRewardKillSpree,
	Handle:SurvRewardHeadShots,
	Handle:SurvKillInfec,
	Handle:SurvKillTank,
	Handle:SurvKillWitch,
	Handle:SurvCrownWitch,
	Handle:SurvTeamHeal,
	Handle:SurvTeamHealFarm,
	Handle:SurvTeamProtect,
	Handle:SurvTeamRevive,
	Handle:SurvTeamLedge,
	Handle:SurvTeamDefib,
	Handle:SurvBurnTank,
	Handle:SurvBileTank,
	Handle:SurvBurnWitch,
	Handle:SurvTankSolo,
	Handle:InfecChokeSurv,
	Handle:InfecPounceSurv,
	Handle:InfecChargeSurv,
	Handle:InfecImpactSurv,
	Handle:InfecRideSurv,
	Handle:InfecBoomSurv,
	Handle:InfecIncapSurv,
	Handle:InfecHurtSurv,
	Handle:InfecKillSurv
}
new PointRewards[point_rewards];

void initPointRewards(){
	PointRewards[SurvRewardKillSpree] = CreateConVar("l4d2_points_cikill_value", "3", "How many points does killing a certain amount of infected earn");
	PointRewards[SurvRewardHeadShots] = CreateConVar("l4d2_points_headshots_value", "5", "How many points does killing a certain amount of infected with headshots earn");
	PointRewards[SurvKillInfec] = CreateConVar("l4d2_points_sikill", "3", "How many points does killing a special infected earn");
	PointRewards[SurvKillTank] = CreateConVar("l4d2_points_tankkill", "25", "How many points does killing a tank earn");
	PointRewards[SurvKillWitch] = CreateConVar("l4d2_points_witchkill", "10", "How many points does killing a witch earn");
	PointRewards[SurvCrownWitch] = CreateConVar("l4d2_points_witchcrown", "25", "How many points does crowning a witch earn");
	PointRewards[SurvTeamHeal] = CreateConVar("l4d2_points_heal", "2", "How many points does healing a team mate earn");
	PointRewards[SurvTeamHealFarm] = CreateConVar("l4d2_points_heal_warning", "0", "How many points does healing a team mate who did not need healing earn");
	PointRewards[SurvTeamProtect] = CreateConVar("l4d2_points_protect", "2", "How many points does protecting a team mate earn");
	PointRewards[SurvTeamRevive] = CreateConVar("l4d2_points_revive", "2", "How many points does reviving a team mate earn");
	PointRewards[SurvTeamLedge] = CreateConVar("l4d2_points_ledge", "2", "How many points does reviving a hanging team mate earn");
	PointRewards[SurvTeamDefib] = CreateConVar("l4d2_points_defib_action", "2", "How many points does defibbing a team mate earn");
	PointRewards[SurvBurnTank] = CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn");
	PointRewards[SurvTankSolo] = CreateConVar("l4d2_points_tanksolo", "50", "How many points does killing a tank single-handedly earn");
	PointRewards[SurvBurnWitch] = CreateConVar("l4d2_points_witchburn", "2", "How many points does burning a witch earn");
	PointRewards[SurvBileTank] = CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn");
	PointRewards[InfecChokeSurv] = CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn");
	PointRewards[InfecPounceSurv] = CreateConVar("l4d2_points_pounce", "2", "How many points does pouncing a survivor earn");
	PointRewards[InfecChargeSurv] = CreateConVar("l4d2_points_charge", "2", "How many points does charging a survivor earn");
	PointRewards[InfecImpactSurv] = CreateConVar("l4d2_points_impact", "2", "How many points does impacting a survivor earn");
	PointRewards[InfecRideSurv] = CreateConVar("l4d2_points_ride", "2", "How many points does riding a survivor earn");
	PointRewards[InfecBoomSurv] = CreateConVar("l4d2_points_boom", "2", "How many points does booming a survivor earn");
	PointRewards[InfecIncapSurv] = CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn");
	PointRewards[InfecHurtSurv] = CreateConVar("l4d2_points_damage", "2", "How many points does doing damage earn");
	PointRewards[InfecKillSurv] = CreateConVar("l4d2_points_kill", "5", "How many points does killing a survivor earn");
	return;
}

void initStructures(){
	initPluginSettings();
	initAllPlayerData();
	initPluginSprites();
	initCounterData();
	initItemCosts();
	initCategoriesEnabled();
	initPointRewards();
	return;
}

//melee check
char meleelist[][] =
{
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"katana",
	"machete",
	"tonfa"
};

char validmelee[MAX_MELEE_LENGTH][25];
char MapName[60];

//stuffs
int SendProp_IsAlive;
int SendProp_IsGhost;
int SendProp_LifeState;

bool IsDatabaseLoaded = false;
bool bLateLoad = false;
bool bFirstRun = true;

void registerAdminCommands(){
	RegAdminCmd("sm_listmodules", ListModules, ADMFLAG_GENERIC, "List modules currently loaded to Points System");
	RegAdminCmd("sm_listmelee", ListMelee, ADMFLAG_GENERIC, "List melee weapons available on this map");
	RegAdminCmd("sm_listpoints", ListPoints, ADMFLAG_ROOT, "List each player's points.");
	RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_SLAY, "sm_heal <target>");
	RegAdminCmd("sm_givepoints", Command_Points, ADMFLAG_ROOT, "sm_givepoints <target> [amount]");
	RegAdminCmd("sm_setpoints", Command_SPoints, ADMFLAG_ROOT, "sm_setpoints <target> [amount]");
	return;
}

void registerConsoleCommands(){
	RegConsoleCmd("sm_buystuff", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_repeatbuy", Command_RBuy, "Repeat your last buy transaction");
	RegConsoleCmd("sm_buy", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_shop", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_store", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_points", ShowPoints, "Show the amount of points you have (only in-game)");
	return;
}

void hookGameEvents(){
	HookEvent("infected_death", Event_Kill);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_death", Event_Death);
	HookEvent("tank_killed", Event_TankDeath, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("heal_success", Event_Heal);
	HookEvent("award_earned", Event_Protect);
	HookEvent("revive_success", Event_Revive);
	HookEvent("defibrillator_used", Event_Shock);
	HookEvent("choke_start", Event_Choke);
	HookEvent("player_now_it", Event_Boom);
	HookEvent("lunge_pounce", Event_Pounce);
	HookEvent("jockey_ride", Event_Ride);
	HookEvent("charger_carry_start", Event_Carry);
	HookEvent("charger_impact", Event_Impact);
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("zombie_ignited", Event_Burn);
	HookEvent("round_end", Event_REnd);
	HookEvent("round_start", Event_RStart);
	HookEvent("finale_win", Event_Finale);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_Post);
	return;
}

public void OnPluginStart(){
	ModulesArray = CreateArray(10); // Reduced from 100 to 10.
	if(ModulesArray == null)
		SetFailState("%T", "Modules Array Failure", LANG_SERVER);

	AddMultiTargetFilter("@survivors", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@survivor", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@s", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@infected", FilterInfected, "all Infected players", true);
	AddMultiTargetFilter("@i", FilterInfected, "all Infected players", true);

	registerAdminCommands();
	registerConsoleCommands();
	hookGameEvents();
	initStructures();

	SendProp_LifeState = FindSendPropInfo("CTerrorPlayer", "m_lifeState");
	SendProp_IsAlive = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	SendProp_IsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");

	AutoExecConfig(true, "l4d2_points_system");
	if(!bLateLoad)
		CreateTimer(0.5, PrecacheGuns, _, TIMER_FLAG_NO_MAPCHANGE);
	if (!IsDatabaseLoaded)
	{
		IsDatabaseLoaded = true;
		MySQL_Init();
	}
}

MySQL_Init()
{	
	char Error[192];

	hDatabase = SQLite_UseDatabase("PointsSystem", Error, sizeof(Error));
	
	if(hDatabase == INVALID_HANDLE)
		SetFailState("SQL error: %s", Error);

	SQL_FastQuery(hDatabase, "CREATE TABLE IF NOT EXISTS accounts (steamid TEXT PRIMARY KEY, points INTEGER);");
}

void SaveData(iClientIndex)
{
	if(0 < iClientIndex <= MaxClients && IsClientConnected(iClientIndex) && CheckCommandAccess(iClientIndex, "sm_perks", ADMFLAG_CUSTOM1, true))
	{
		char TQuery[3000], SteamID[64];
		if (GetClientAuthId(iClientIndex, AuthId_Steam2, SteamID, sizeof(SteamID)))
		{
			int m_survivorCharacter = GetEntProp(iClientIndex, Prop_Send, "m_survivorCharacter");
			if(IsFakeClient(iClientIndex) && m_survivorCharacter > 0)
			{
				Format(SteamID, sizeof(SteamID), "%s_%d", SteamID, m_survivorCharacter);
			}
			Format(TQuery, sizeof(TQuery), "INSERT OR REPLACE INTO accounts VALUES ('%s', %d);", SteamID, PlayerData[iClientIndex][iPlayerPoints]);
			SQL_FastQuery(hDatabase, TQuery);
		}
	}
}

public Action Reminder(Handle hTimer, int userid)
{
	int iClientIndex = GetClientOfUserId(userid);
	if (0 < iClientIndex <= MaxClients && IsClientConnected(iClientIndex))
	{
		PrintToChat(iClientIndex, "%s !buy points: %d", MSGTAG, PlayerData[iClientIndex][iPlayerPoints]);
		PrintHintText(iClientIndex, "[PS] !buy points: %d", PlayerData[iClientIndex][iPlayerPoints]);
		PrintCenterText(iClientIndex, "[PS] !buy points: %d", PlayerData[iClientIndex][iPlayerPoints]);
	}
}

public Action LoadAllData(Handle hTimer, int userid)
{
	int iClientIndex = GetClientOfUserId(userid);
	if (0 < iClientIndex <= MaxClients && IsClientConnected(iClientIndex))
	{
		LoadData(iClientIndex);
	}
}

void LoadData(iClientIndex)
{
	if(0 < iClientIndex <= MaxClients && IsClientConnected(iClientIndex) && CheckCommandAccess(iClientIndex, "sm_perks", ADMFLAG_CUSTOM1, true))
	{
		char TQuery[192], SteamID[64];

		if (GetClientAuthId(iClientIndex, AuthId_Steam2, SteamID, sizeof(SteamID)))
		{
			int m_survivorCharacter = GetEntProp(iClientIndex, Prop_Send, "m_survivorCharacter");
			if(IsFakeClient(iClientIndex) && m_survivorCharacter > 0)
			{
				Format(SteamID, sizeof(SteamID), "%s_%d", SteamID, m_survivorCharacter);
			}
			Format(TQuery, sizeof(TQuery), "SELECT * FROM accounts WHERE steamId = '%s';", SteamID);
			SQL_TQuery(hDatabase, LoadPlayerData, TQuery, iClientIndex);
		}
	}
}

public void LoadPlayerData(Handle owner, Handle hndl, const char[] error, any iClientIndex)
{
	if(hndl == INVALID_HANDLE || SQL_GetRowCount(hndl) == 0 || (IsClientInGame(iClientIndex) && GetClientTeam(iClientIndex) == 3))
	{
		return;
	}	

	PlayerData[iClientIndex][iPlayerPoints] = SQL_FetchInt(hndl, 1);
}

/**
 * Retreives the current gamemode and places the value into a char array that is passed by refrence
 *
 * @param sGameMode Char array that will have the game mode placed into it
 * @param iSize Size of the passed char array
*/
void getGameMode(char[] sGameMode, int iSize){
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, iSize);
	return;
}

void getGameName(char[] sGameName, int iSize){
	GetGameFolderName(sGameName, iSize);
	return;
}

int getAttackerIndex(Handle hEvent){
	int iAttackerIndex = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	return(iAttackerIndex);
}

int getClientIndex(Handle hEvent){
	int iClientIndex = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	return(iClientIndex);
}

bool IsClientPlaying(int iClientIndex){
	if(iClientIndex > 0){
		if(IsClientConnected(iClientIndex))
			if(IsClientInGame(iClientIndex))
				if(GetClientTeam(iClientIndex) > 1)
					return true;
	}
	return false;
}

bool IsClientBot(int iClientIndex){
	if(iClientIndex > 0){
		if(IsClientConnected(iClientIndex))
			if(IsFakeClient(iClientIndex))
				return true;
	}
	return false;
}

bool IsPlayerGhost(int iClientIndex){
	if(iClientIndex > 0){
		if(GetEntData(iClientIndex, SendProp_IsGhost, 1))
			return true;
	}
	return false;
}

bool IsClientTank(int iClientIndex){
	if(iClientIndex > 0){
		if(GetEntProp(iClientIndex, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}

bool IsClientSurvivor(int iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 2) // Survivor
			return true;
	}
	return false;
}

bool IsClientInfected(int iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 3) // Infected
			return true;
	}
	return false;
}

bool IsModEnabled(){
	if(GetConVarInt(PluginSettings[hEnabled]) == 1){
		if(IsAllowedGameMode())
			return true;
	}
	return false;
}

stock bool IsAllowedGameMode(){ // change name
	decl String:sGameMode[40]; sGameMode[0] = '\0';
	decl String:sEnabledModes[64]; sEnabledModes[0] = '\0';

	getGameMode(sGameMode, sizeof(sGameMode));
	GetConVarString(PluginSettings[hModes], sEnabledModes, sizeof(sEnabledModes));

	return (StrContains(sEnabledModes, sGameMode) != -1);
}

stock bool IsAllowedReset(){
	decl String:sGameMode[40]; sGameMode[0] = '\0';
	decl String:sEnabledModes[64]; sEnabledModes[0] = '\0';

	getGameMode(sGameMode, sizeof(sGameMode));
	GetConVarString(PluginSettings[hResetPoints], sEnabledModes, sizeof(sEnabledModes));

	return (StrContains(sEnabledModes, sGameMode) != -1);
}

void setStartPoints(int iClientIndex){
	if(iClientIndex <= 0 || PlayerData[iClientIndex][iPlayerPoints] > 0)
		return;

	int iStartPoints = GetConVarInt(PluginSettings[hStartPoints]);
	PlayerData[iClientIndex][iPlayerPoints] = iStartPoints;
	return;
}

void addPointsToTeam(int iClientIndex, int iTeam, int iPoints, const char[] sMessage){
	if(MaxClients >= iClientIndex){
		if(!IsClientBot(iClientIndex))
			if(GetClientTeam(iClientIndex) == iTeam)
				addPoints(iClientIndex, iPoints, sMessage);
		addPointsToTeam(++iClientIndex, iTeam, iPoints, sMessage);
	}
	return;
}

void addPoints(int iClientIndex, int iPoints, const char[] sMessage){
	if(!IsClientBot(iClientIndex)){
		PlayerData[iClientIndex][iPlayerPoints] += iPoints;
		if(GetConVarBool(PluginSettings[hNotifications])){
			PrintToChat(iClientIndex, "%s %T", MSGTAG, sMessage, LANG_SERVER, iPoints);
			return;
		}
	}
	return;
}

void removePoints(int iClientIndex, int iPoints){
	PlayerData[iClientIndex][iPlayerPoints] -= iPoints;
	return;
}

public bool FilterSurvivors(const char[] sPattern, Handle hClients){
	for(int iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++)
		if(IsClientInGame(iClientIndex) && IsClientSurvivor(iClientIndex))
			PushArrayCell(hClients, iClientIndex);
	return true;
}

public bool FilterInfected(const char[] sPattern, Handle hClients){
	for(int iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++)
		if(IsClientInGame(iClientIndex) && IsClientInfected(iClientIndex))
			PushArrayCell(hClients, iClientIndex);
	return true;
}

public Action PrecacheGuns(Handle Timer)
{
	decl String:map[128]; map[0] = '\0';
	GetCurrentMap(map, sizeof(map));
	if(DispatchAndRemove("weapon_rifle_sg552") &&
	DispatchAndRemove("weapon_smg_mp5") &&
	DispatchAndRemove("weapon_sniper_awp") &&
	DispatchAndRemove("weapon_sniper_scout") &&
	DispatchAndRemove("weapon_rifle_m60"))
	{
		ForceChangeLevel(map, "Initialize CS:S weapons");
	}
	else
	{
		LogError("Plugin failed to initialize a CS:S weapon, consult developer!");
		ForceChangeLevel(map, "Initialize CS:S weapons");
	}
}

stock DispatchAndRemove(const char[] sGun){
	int iEntity = CreateEntityByName(sGun);
	if(IsValidEdict(iEntity)){
		DispatchSpawn(iEntity);
		RemoveEdict(iEntity);
		return true;
	}
	else
		return false;
}

public void OnAllPluginsLoaded(){
	//forward
	Call_StartForward(Forward1);
	Call_Finish();
	return;
}

public void OnConfigsExecuted(){
	if(bFirstRun){
		for(int iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++)
			setStartPoints(iClientIndex);
		bFirstRun = false;
	}
	return;
}

public void OnMapStart()
{
	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	initPluginSprites();
	GetCurrentMap(MapName, sizeof(MapName));
	CreateTimer(6.0, CheckMelee, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(600.0, RewardMembers, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action CheckMelee(Handle hTimer)
{
	int mCounter;
	for(int i = 0; i < MAX_MELEE_LENGTH; i++)
		Format(validmelee[i], sizeof(validmelee[]), "");

	for(int i = 0; i < MAX_MELEE_LENGTH; i++){
		int iEntity = CreateEntityByName("weapon_melee");
		DispatchKeyValue(iEntity, "melee_script_name", meleelist[i]);
		DispatchSpawn(iEntity);

		decl String:modelname[256];
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if(StrContains(modelname, "hunter", false) == -1)
			Format(validmelee[mCounter++], sizeof(validmelee[]), meleelist[i]);

		RemoveEdict(iEntity);
	}
}

public Action RewardMembers(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++){
		if(0 < i <= MaxClients && IsClientConnected(i) && !IsFakeClient(i)){
			if(CheckCommandAccess(i, "sm_perks", ADMFLAG_CUSTOM1, true)){
				PlayerData[i][iPlayerPoints] += 100;
				SaveData(i);
				PrintToChat(i, "%s You received\x03 100\x01 points for being a Steam group member!", MSGTAG);
			}
			else{
				PrintToChat(i, "%s You can receive\x03 100\x01 points every 10 minutes by joining our Steam group! Type\x04 !group\x01 and be a part of our community!", MSGTAG);
			}
		}
	}
}

public Action ListMelee(int iClientIndex, int iNumArguments){
	if(iNumArguments == 0){
		for(int iCount = 0; iCount < MAX_MELEE_LENGTH; iCount++)
			if(strlen(validmelee[iCount]) > 0) ReplyToCommand(iClientIndex, validmelee[iCount]);
	}
	return Plugin_Handled;
}

public Action ListPoints(int iClientIndex, int iNumArguments)
{
	if(iNumArguments == 0){
		for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(IsClientInGame(iPlayer)) ReplyToCommand(iClientIndex, "%s %N: %d", MSGTAG, iPlayer, PlayerData[iPlayer][iPlayerPoints]);
	}
	return Plugin_Handled;
}

public Action ListModules(int iClientIndex, int iNumArguments){
	if(iNumArguments == 0){
		ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Modules", LANG_SERVER);

		int iNumModules = GetArraySize(ModulesArray);
		for(int iModule = 0; iModule < iNumModules; iModule++){
			char sModuleName[MODULES_SIZE];
			GetArrayString(ModulesArray, iModule, sModuleName, MODULES_SIZE);
			if(strlen(sModuleName) > 0)
				ReplyToCommand(iClientIndex, sModuleName);
		}
	}
	return Plugin_Handled;
}

void loadTranslationFiles(){
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("points_system.phrases");
	LoadTranslations("points_system_menus.phrases");
	return;
}

void createNatives(){
	CreateNative("PS_IsSystemEnabled", Native_PS_IsSystemEnabled);
	CreateNative("PS_GetVersion", Native_PS_GetVersion);
	CreateNative("PS_SetPoints", Native_PS_SetPoints);
	CreateNative("PS_SetItem", Native_PS_SetItem);
	CreateNative("PS_SetCost", Native_PS_SetCost);
	CreateNative("PS_SetBought", Native_PS_SetBought);
	CreateNative("PS_SetBoughtCost", Native_PS_SetBoughtCost);
	CreateNative("PS_SetupUMob", Native_PS_SetupUMob);
	CreateNative("PS_GetPoints", Native_PS_GetPoints);
	CreateNative("PS_GetBoughtCost", Native_PS_GetBoughtCost);
	CreateNative("PS_GetCost", Native_PS_GetCost);
	CreateNative("PS_GetItem", Native_PS_GetItem);
	CreateNative("PS_GetBought", Native_PS_GetBought);
	CreateNative("PS_RegisterModule", Native_PS_RegisterModule);
	CreateNative("PS_UnregisterModule", Native_PS_UnregisterModule);
	CreateNative("PS_RemovePoints", Native_PS_RemovePoints);
	Forward1 = CreateGlobalForward("OnPSLoaded", ET_Ignore);
	Forward2 = CreateGlobalForward("OnPSUnloaded", ET_Ignore);
	RegPluginLibrary("ps_natives");

	return;
}

/**
 * @link https://sm.alliedmods.net/new-api/sourcemod/AskPluginLoad2
 *
 * @param hPlugin Handle to the plugin.
 * @param bLate Whether or not the plugin was loaded "late" (after map load).
 * @param sError Error message buffer in case load failed.
 * @param iErrorSize Maximum number of characters for error message buffer.
 *
 * @return APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise
 */
public APLRes:AskPluginLoad2(Handle hPlugin, bool bLate, char[] sError, int iErrorSize){
	loadTranslationFiles();

	char sGameName[15];
	getGameName(sGameName, sizeof(sGameName));
	if(!StrEqual(sGameName, "left4dead2", false))
		SetFailState("%T", "Game Check Fail", LANG_SERVER);

	createNatives();

	bLateLoad = bLate;
	return APLRes_Success;
}

public void OnPluginEnd()
{
	Action result;
	Call_StartForward(Forward2);
	Call_Finish(result);
}

public int Native_PS_IsSystemEnabled(Handle hPlugin, int iNumArguments){
	return (IsModEnabled());
}

public int Native_PS_RemovePoints(Handle hPlugin, int iNumArguments){
	removePoints(GetNativeCell(1), GetNativeCell(2));
	return;
}

public Native_PS_RegisterModule(Handle hPlugin, int iNumArguments){
	int iNumModules = GetArraySize(ModulesArray);

	decl String:sNewModuleName[MODULES_SIZE];
	GetNativeString(1, sNewModuleName, MODULES_SIZE);

	// Make sure the module is not already loaded
	for(int iModule = 0; iModule < iNumModules; iModule++){
		decl String:sModuleName[MODULES_SIZE];
		GetArrayString(ModulesArray, iModule, sModuleName, MODULES_SIZE);
		if(StrEqual(sModuleName, sNewModuleName))
			return false;
	}

	PushArrayString(ModulesArray, sNewModuleName);
	return true;
}

public Native_PS_UnregisterModule(Handle hPlugin, int iNumArguments){
	int iNumModules = GetArraySize(ModulesArray);

	decl String:sUnloadModuleName[MODULES_SIZE];
	GetNativeString(1, sUnloadModuleName, MODULES_SIZE);

	for(int iModule = 0; iModule < iNumModules; iModule++){
		decl String:sModuleName[MODULES_SIZE];
		GetArrayString(ModulesArray, iModule, sModuleName, MODULES_SIZE);
		if(StrEqual(sModuleName, sUnloadModuleName)){
			RemoveFromArray(ModulesArray, iModule);
			return true;
		}
	}
	return false;
}

public int Native_PS_GetVersion(Handle hPlugin, int iNumArguments){
	return _:PluginSettings[fVersion];
}

public int Native_PS_SetPoints(Handle hPlugin, int iNumArguments)
{
	PlayerData[GetNativeCell(1)][iPlayerPoints] = GetNativeCell(2);
}

public int Native_PS_SetItem(Handle hPlugin, int iNumArguments)
{
	GetNativeString(2, PlayerData[GetNativeCell(1)][sItemName], 64);
}

public int Native_PS_SetCost(Handle hPlugin, int iNumArguments)
{
	PlayerData[GetNativeCell(1)][iItemCost] = GetNativeCell(2);
}

public int Native_PS_SetBought(Handle hPlugin, int iNumArguments)
{
	GetNativeString(2, PlayerData[GetNativeCell(1)][sBought], 64);
}

public int Native_PS_SetBoughtCost(Handle hPlugin, int iNumArguments)
{
	PlayerData[GetNativeCell(1)][iBoughtCost] = GetNativeCell(2);
}

public int Native_PS_SetupUMob(Handle hPlugin, int iNumArguments)
{
	CounterData[iUCommonLeft] = GetNativeCell(1);
}

public int Native_PS_GetPoints(Handle hPlugin, int iNumArguments)
{
	return PlayerData[GetNativeCell(1)][iPlayerPoints];
}

public int Native_PS_GetCost(Handle hPlugin, int iNumArguments)
{
	return PlayerData[GetNativeCell(1)][iItemCost];
}

public int Native_PS_GetBoughtCost(Handle hPlugin, int iNumArguments)
{
	return PlayerData[GetNativeCell(1)][iBoughtCost];
}

public int Native_PS_GetItem(Handle hPlugin, int iNumArguments)
{
	SetNativeString(2, PlayerData[GetNativeCell(1)][sItemName], GetNativeCell(3));
}

public int Native_PS_GetBought(Handle hPlugin, int iNumArguments)
{
	SetNativeString(2, PlayerData[GetNativeCell(1)][sBought], 64);
}

void resetClientData(int iClientIndex){
	setStartPoints(iClientIndex);

	PlayerData[iClientIndex][iKillCount] 		= 0;
	PlayerData[iClientIndex][iHurtCount] 		= 0;
	PlayerData[iClientIndex][iProtectCount] 	= 0;
	PlayerData[iClientIndex][iHeadShotCount] 	= 0;
	PlayerData[iClientIndex][bMessageSent] 		= false;
	return;
}

public Action Check(Handle hTimer, int userid){
	int iClientIndex = GetClientOfUserId(userid);
	if(iClientIndex == 0 || !IsClientConnected(iClientIndex))
		resetClientData(iClientIndex);
}

public void OnClientAuthorized(int iClientIndex, const char[] sSteamID){
	if(IsClientBot(iClientIndex))
		return;
	else{
		if(PlayerData[iClientIndex][iPlayerPoints] < GetConVarInt(PluginSettings[hStartPoints]))
			setStartPoints(iClientIndex);
	}
}

public OnClientPostAdminCheck(client)
{
	if(0 < client <= MaxClients && IsClientConnected(client))
	{
		CreateTimer(0.2, LoadAllData, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(120.0, Reminder, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_PlayerBotReplace(Handle hEvent, char[] sEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client> 0 && IsClientInGame(client) && IsFakeClient(client))
		CreateTimer(0.5, LoadAllData, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientDisconnect(int iClientIndex){
	if(IsClientBot(iClientIndex))
		return;
	else{
		SaveData(iClientIndex);
		if(PlayerData[iClientIndex][iPlayerPoints] < GetConVarInt(PluginSettings[hStartPoints]))
			resetClientData(iClientIndex);
		CreateTimer(4.0, Check, GetClientUserId(iClientIndex), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void resetAllPlayers(int iClientIndex){ // Check if 0
	if(MaxClients >= iClientIndex){
		resetClientData(iClientIndex);
		resetAllPlayers(++iClientIndex);
	}
	return;
}

public Action Event_REnd(Handle hEvent, char[] sEventName, bool bDontBroadcast){
	if(IsAllowedReset())
		resetAllPlayers(1);

	initCounterData();
	return Plugin_Continue;
}

public Action Event_RStart(Handle hEvent, char[] sEventName, bool bDontBroadcast){
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");

	if(IsAllowedReset())
		resetAllPlayers(1);

	initCounterData();
	return Plugin_Continue;
}

public Action Event_Finale(Handle hEvent, char[] sEventName, bool bDontBroadcast){
	decl String:sGameMode[40]; sGameMode[0] = '\0';
	getGameMode(sGameMode, sizeof(sGameMode));

	if(StrContains(sGameMode, "versus", false) != -1)
		return Plugin_Continue;
	else resetAllPlayers(1);
	return Plugin_Continue;
}

void handleHeadshots(int iClientIndex){
	int iHeadShotReward = GetConVarInt(PointRewards[SurvRewardHeadShots]);
	int iHeadShotsRequired = GetConVarInt(PluginSettings[hHeadShotNum]);
	if(iHeadShotReward > 0){
		PlayerData[iClientIndex][iHeadShotCount]++;
		if(PlayerData[iClientIndex][iHeadShotCount] >= iHeadShotsRequired){
			addPoints(iClientIndex, iHeadShotReward, "Head Hunter");
			PlayerData[iClientIndex][iHeadShotCount] -= iHeadShotsRequired;
		}
	}
	return;
}

void handleKillSpree(int iClientIndex){
	int iKillSpreeReward = GetConVarInt(PointRewards[SurvRewardKillSpree]);
	int iKillSpreeRequired = GetConVarInt(PluginSettings[hKillSpreeNum]);
	if(iKillSpreeReward > 0){
		PlayerData[iClientIndex][iKillCount]++;
		if(PlayerData[iClientIndex][iKillCount] >= iKillSpreeRequired){
			addPoints(iClientIndex, iKillSpreeReward, "Killing Spree");
			PlayerData[iClientIndex][iKillCount] -= iKillSpreeRequired;
		}
	}
	return;
}

public Action Event_Kill(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	bool bHeadShot = GetEventBool(hEvent, "bHeadShot");
	int iAttackerIndex = getAttackerIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientSurvivor(iAttackerIndex)){
			if(bHeadShot)
				handleHeadshots(iAttackerIndex);
			handleKillSpree(iAttackerIndex);
		}
	}
	return Plugin_Continue;
}

public Action Event_Incap(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int iAttackerIndex = getAttackerIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientInfected(iAttackerIndex)){
			int iIncapPoints = GetConVarInt(PointRewards[InfecIncapSurv]);
			if(iIncapPoints > 0)
				addPoints(iAttackerIndex, iIncapPoints, "Incapped Survivor");
		}
	}
	return Plugin_Continue;
}

public Action Event_Death(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int iAttackerIndex = getAttackerIndex(hEvent);
	int iVictimIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientSurvivor(iAttackerIndex)){
			int iInfectedKilledReward = GetConVarInt(PointRewards[SurvKillInfec]);
			if(iInfectedKilledReward > 0){
				if(IsClientInfected(iVictimIndex)){ // If the person killed by the survivor is infected
					if(IsClientTank(iVictimIndex)) // Ignore tank death since it is handled elsewhere
						return Plugin_Continue;
					else{
						handleHeadshots(iAttackerIndex);
						addPoints(iAttackerIndex, iInfectedKilledReward, "Killed SI");
					}
				}
			}
		}
		else if(IsClientInfected(iAttackerIndex)){
			int iSurvivorKilledReward = GetConVarInt(PointRewards[InfecKillSurv]);
			if(iSurvivorKilledReward > 0)
				if(IsClientSurvivor(iVictimIndex)) // If the person killed by the infected is a survivor
					addPoints(iAttackerIndex, iSurvivorKilledReward, "Killed Survivor");
		}
	}
	return Plugin_Continue;
}

void handleTankKilled(){
	int iTankKilledReward = GetConVarInt(PointRewards[SurvKillTank]);
	if(iTankKilledReward > 0)
		handleTankKilledPoints(1, iTankKilledReward, "Killed Tank");
	return;
}

void handleTankKilledPoints(int iClientIndex, int iPoints, const char[] sMessage){
	if(iClientIndex > 0 && MaxClients >= iClientIndex){
		if(!IsClientBot(iClientIndex))
			if(IsClientInGame(iClientIndex))
				if(IsClientSurvivor(iClientIndex))
					if(IsPlayerAlive(iClientIndex)){
						addPoints(iClientIndex, iPoints, sMessage);
					}
		handleTankKilledPoints(++iClientIndex, iPoints, sMessage);
	}
	return;
}

public Action Event_TankDeath(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	bool bSoloKill = GetEventBool(hEvent, "solo");
	int iAttackerIndex = getAttackerIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientSurvivor(iAttackerIndex)){
			int iTankSoloReward = GetConVarInt(PointRewards[SurvTankSolo]); // Points to be rewarded for killing a tank, solo
			if(iTankSoloReward > 0){ // If solo kill reward is enabled
				if(bSoloKill) // If kill was solo
					addPoints(iAttackerIndex, iTankSoloReward, "TANK SOLO");
				else
					handleTankKilled(); // Reward survivors for killing a tank
			}
		}
	}
	PlayerData[iAttackerIndex][bTankBurning] = false;
	return Plugin_Continue;
}

public Action Event_WitchDeath(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	bool bOneShot = GetEventBool(hEvent, "oneshot");
	int iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			int iWitchKilledReward = GetConVarInt(PointRewards[SurvKillWitch]);
			if(iWitchKilledReward > 0)
				addPoints(iClientIndex, iWitchKilledReward, "Killed Witch");

			if(bOneShot){
				int iWitchCrownedReward = GetConVarInt(PointRewards[SurvCrownWitch]);
				if(iWitchCrownedReward > 0)
					addPoints(iClientIndex, iWitchCrownedReward, "Crowned Witch");
			}
		}
	}
	PlayerData[iClientIndex][bWitchBurning] = false;
	return Plugin_Continue;
}

public Action Event_Heal(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int iHealthRestored = GetEventInt(hEvent, "health_restored");
	int iTargetIndex = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	int iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			if(iClientIndex != iTargetIndex){ // If player did not heal himself with the medkit
				if(iHealthRestored > 39){
					int iHealTeamReward = GetConVarInt(PointRewards[SurvTeamHeal]);
					if(iHealTeamReward > 0)
						addPoints(iClientIndex, iHealTeamReward, "Team Heal");
				}
				else{
					int iHealTeamReward = GetConVarInt(PointRewards[SurvTeamHealFarm]);
					if(iHealTeamReward > 0)
						addPoints(iClientIndex, iHealTeamReward, "Team Heal Warning");
				}
			}
		}
	}
	return Plugin_Continue;
}

void handleProtect(int iClientIndex){
	int iProtectReward = GetConVarInt(PointRewards[SurvTeamProtect]);
	if(iProtectReward > 0){
		PlayerData[iClientIndex][iProtectCount]++;
		if(PlayerData[iClientIndex][iProtectCount] == 6){
			addPoints(iClientIndex, iProtectReward, "Protect");
			PlayerData[iClientIndex][iProtectCount] -= 6;
		}
	}
	return;
}

public Action Event_Protect(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int iAwardType = GetEventInt(hEvent, "award");
	int iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex))
		if(IsClientPlaying(iClientIndex))
			if(IsClientSurvivor(iClientIndex))
				if(iAwardType == 67) // if(iAwardType == Protect)
					handleProtect(iClientIndex);
	return Plugin_Continue;
}

public Action Event_Revive(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	bool bLedgeRevive = GetEventBool(hEvent, "ledge_hang");
	int iTargetIndex = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	int iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			if(iClientIndex != iTargetIndex){
				if(bLedgeRevive){
					int iLedgeReviveReward = GetConVarInt(PointRewards[SurvTeamLedge]);
					if(iLedgeReviveReward > 0)
						addPoints(iClientIndex, iLedgeReviveReward, "Ledge Revive");
				}
				else{
					int iReviveReward = GetConVarInt(PointRewards[SurvTeamRevive]);
					if(iReviveReward > 0)
						addPoints(iClientIndex, iReviveReward, "Revive");

				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_Shock(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){ // Defib
	int iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			int iDefibReward = GetConVarInt(PointRewards[SurvTeamDefib]);
			if(iDefibReward > 0)
				addPoints(iClientIndex, iDefibReward, "Defib");
		}
	}
	return Plugin_Continue;
}

public Action Event_Choke(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){
	int iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			int iChokeReward = GetConVarInt(PointRewards[InfecChokeSurv]);
			if(iChokeReward > 0)
				addPoints(iClientIndex, iChokeReward, "Smoke");
		}
	}
	return Plugin_Continue;
}

public Action Event_Boom(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){
	int iAttackerIndex = getAttackerIndex(hEvent);
	int iVictimIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientInfected(iAttackerIndex)){ // If boomer biles survivors
			int iBoomedReward = GetConVarInt(PointRewards[InfecBoomSurv]);
			if(iBoomedReward > 0)
				addPoints(iAttackerIndex, iBoomedReward, "Boom");
		}
		else if(IsClientSurvivor(iAttackerIndex)){ // If survivor biles a tank
			int iBiledReward = GetConVarInt(PointRewards[SurvBileTank]);
			if(iBiledReward > 0){
				if(IsClientTank(iVictimIndex))
					addPoints(iAttackerIndex, iBiledReward, "Biled");
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_Pounce(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){
	int iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			int iPounceReward = GetConVarInt(PointRewards[InfecPounceSurv]);
			if(iPounceReward > 0)
				addPoints(iClientIndex, iPounceReward, "Pounce");
		}
	}
	return Plugin_Continue;
}

public Action Event_Ride(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){
	int iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			int iRideReward = GetConVarInt(PointRewards[InfecRideSurv]);
			if(iRideReward > 0)
				addPoints(iClientIndex, iRideReward, "Jockey Ride");
		}
	}
	return Plugin_Continue;
}

public Action Event_Carry(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){
	int iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			int iCarryReward = GetConVarInt(PointRewards[InfecChargeSurv]);
			if(iCarryReward > 0)
				addPoints(iClientIndex, iCarryReward, "Charge");
		}
	}
	return Plugin_Continue;
}

public Action Event_Impact(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){
	int iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			int iImpactReward = GetConVarInt(PointRewards[InfecImpactSurv]);
			if(iImpactReward > 0)
				addPoints(iClientIndex, iImpactReward, "Charge Collateral");
		}
	}
	return Plugin_Continue;
}

public Action Event_Burn(Handle: hEvent, const char[] sEventName, bool bDontBroadcast){
	decl String:sVictimName[30]; sVictimName[0] = '\0';
	GetEventString(hEvent, "victimname", sVictimName, sizeof(sVictimName));
	int iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			if(StrEqual(sVictimName, "Tank", false)){
				int iTankBurnReward = GetConVarInt(PointRewards[SurvBurnTank]);
				if(iTankBurnReward > 0)
					if(!PlayerData[iClientIndex][bTankBurning]){
						PlayerData[iClientIndex][bTankBurning] = true;
						addPoints(iClientIndex, iTankBurnReward, "Burn Tank");
					}
			}
			else if(StrEqual(sVictimName, "Witch", false)){
				int iWitchBurnReward = GetConVarInt(PointRewards[SurvBurnWitch]);
				if(iWitchBurnReward > 0){
					if(!PlayerData[iClientIndex][bWitchBurning]){
						PlayerData[iClientIndex][bWitchBurning] = true;
						addPoints(iClientIndex, iWitchBurnReward, "Burn Witch");
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void handleSpit(int iClientIndex, int iPoints){
    if(PlayerData[iClientIndex][iHurtCount] >= 8){
        addPoints(iClientIndex, iPoints, "Spit Damage");
        PlayerData[iClientIndex][iHurtCount] -= 8;
    }
    return;
}

void handleDamage(int iClientIndex, int iPoints){
    if(PlayerData[iClientIndex][iHurtCount] >= 3){
        addPoints(iClientIndex, iPoints, "Damage");
        PlayerData[iClientIndex][iHurtCount] -= 3;
    }
    return;
}

bool IsFireDamage(int iDamageType){
	if(iDamageType == 8 || iDamageType == 2056)
		return true;
	else return false;
}

bool IsSpitterDamage(int iDamageType){
    if(iDamageType == 263168 || iDamageType == 265216)
        return true;
    else return false;
}

public Action Event_Hurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int iVictimIndex = getClientIndex(hEvent);
	int iAttackerIndex = getAttackerIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientInfected(iAttackerIndex) && IsClientSurvivor(iVictimIndex)){
			PlayerData[iAttackerIndex][iHurtCount]++;
			int iSurvivorDamagedReward = GetConVarInt(PointRewards[InfecHurtSurv]);
			if(iSurvivorDamagedReward > 0){
				int iDamageType = GetEventInt(hEvent, "type");
				if(IsFireDamage(iDamageType)) // If infected is dealing fire damage, ignore
					return Plugin_Continue;
				else if(IsSpitterDamage(iDamageType))
					handleSpit(iAttackerIndex, iSurvivorDamagedReward);
				else{
					if(!IsSpitterDamage(iDamageType))
						handleDamage(iAttackerIndex, iSurvivorDamagedReward);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action BuyMenu(int iClientIndex, int iNumArguments){
	if(IsModEnabled() && iNumArguments == 0){
		if(IsClientPlaying(iClientIndex)){
			BuildBuyMenu(iClientIndex);
			if(!CheckCommandAccess(iClientIndex, "sm_perks", ADMFLAG_CUSTOM1, true))
				ReplyToCommand(iClientIndex, "%s\x03 Type\x04 !group\x03 and join our Steam group to save your points for next time!\x04 (Non-members start with 100 credits on every campaign.)", MSGTAG);
		}
	}
	return Plugin_Handled;
}

public Action ShowPoints(int iClientIndex, int iNumArguments){
	if(IsModEnabled() && iNumArguments == 0){
		if(IsClientPlaying(iClientIndex))
			ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Your Points", LANG_SERVER, PlayerData[iClientIndex][iPlayerPoints]);
	}
	return Plugin_Handled;
}

bool CheckPurchase(int iClientIndex, int iCost){
	if(iClientIndex > 0){
		if(IsItemEnabled(iClientIndex, iCost) && HasEnoughPoints(iClientIndex, iCost))
			return true;
		else
			return false;
	}
	return false;
}

bool IsItemEnabled(int iClientIndex, int iCost){
	if(iClientIndex > 0){
		if(iCost >= 0)
			return true;
		else{
			ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Item Disabled", LANG_SERVER);
			return false;
		}
	}
	return false;
}

bool HasEnoughPoints(int iClientIndex, int iCost){
	if(iClientIndex > 0){
		if(PlayerData[iClientIndex][iPlayerPoints] >= iCost)
			return true;
		else{
			ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Insufficient Funds", LANG_SERVER);
			return false;
		}
	}
	return false;
}

void performSuicide(int iClientIndex, int iCost){
	if(iClientIndex > 0 && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			ForcePlayerSuicide(iClientIndex);
			removePoints(iClientIndex, iCost);
		}
	}
	return;
}

public Action Command_RBuy(int iClientIndex, int iNumArguments){
	if(iClientIndex > 0 && iNumArguments == 0){
		if(!IsClientBot(iClientIndex) && IsClientPlaying(iClientIndex)){
			if(CheckPurchase(iClientIndex, PlayerData[iClientIndex][iItemCost])){ // Check if item is Enabled & Player has points
				if(StrEqual(PlayerData[iClientIndex][sItemName], "suicide", false)){
					performSuicide(iClientIndex, PlayerData[iClientIndex][iItemCost]);
					return Plugin_Handled;
				}
				else{ // If we are not dealing with a suicide
					execClientCommand(iClientIndex, PlayerData[iClientIndex][sItemName]);
					removePoints(iClientIndex, PlayerData[iClientIndex][iItemCost]);
					//do additional actions for certain items
					if(StrEqual(PlayerData[iClientIndex][sItemName], "z_spawn_old mob", false))
						CounterData[iUCommonLeft] += GetConVarInt(FindConVar("z_common_limit"));
					else if(StrEqual(PlayerData[iClientIndex][sItemName], "give ammo", false))
						reloadAmmo(iClientIndex, PlayerData[iClientIndex][iItemCost], PlayerData[iClientIndex][sItemName]);
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_Heal(client, args)
{
	if(args == 0)
	{
		execClientCommand(client, "give health");
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			ShowActivity2(client, MSGTAG, " %t", "Give Health", target_name);

			for (new i = 0; i < target_count; i++)
			{
				new targetclient = target_list[i];
				execClientCommand(targetclient, "give health");
				SetEntPropFloat(targetclient, Prop_Send, "m_healthBuffer", 0.0);
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s%T", MSGTAG, "Usage sm_heal", LANG_SERVER);
		return Plugin_Handled;
	}
}

public Action Command_Points(client, args)
{
	if(args == 2)
	{
		decl String:arg[MAX_NAME_LENGTH], String:arg2[32];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		new targetclient, amount = StringToInt(arg2);
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			for (new i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				PlayerData[targetclient][iPlayerPoints] += amount;
				SaveData(targetclient);
				ReplyToCommand(client, "%s %T", MSGTAG, "Give Points", LANG_SERVER, amount, targetclient);
				PrintToChat(targetclient, "%s You received %d points from %N!", MSGTAG, amount, client);
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_givepoints", LANG_SERVER);
		return Plugin_Handled;
	}
}

public Action Command_SPoints(client, args)
{
	if(args == 2)
	{
		decl String:arg[MAX_NAME_LENGTH], String:arg2[32];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		new targetclient, amount = StringToInt(arg2);
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			//ShowActivity2(client, MSGTAG, "%t", "Set Points", target_name, amount);
			for (new i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				PlayerData[targetclient][iPlayerPoints] = amount;
				SaveData(targetclient);
				ReplyToCommand(client, "%s %T", MSGTAG, "Set Points", LANG_SERVER, targetclient, amount);
				PrintToChat(targetclient, "%s %N set your points to %d!", MSGTAG, client, amount);
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_setpoints", LANG_SERVER, MSGTAG);
		return Plugin_Handled;
	}
}

void execClientCommand(int iClientIndex, const char[] sCommand){
	RemoveFlags();
	FakeClientCommand(iClientIndex, sCommand);
	AddFlags();
	return;
}

// Currently unmaintained code below //
// TODO: Rewrite McFlurry's menu system

void RemoveFlags(){
	int flagsgive = GetCommandFlags("give");
	int flagszspawn = GetCommandFlags("z_spawn_old");
	int flagsupgradeadd = GetCommandFlags("upgrade_add");
	int flagspanic = GetCommandFlags("director_force_panic_event");

	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic & ~FCVAR_CHEAT);
	return;
}

void AddFlags(){
	int flagsgive = GetCommandFlags("give");
	int flagszspawn = GetCommandFlags("z_spawn_old");
	int flagsupgradeadd = GetCommandFlags("upgrade_add");
	int flagspanic = GetCommandFlags("director_force_panic_event");

	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic|FCVAR_CHEAT);
	return;
}

BuildBuyMenu(client)
{
	if(GetClientTeam(client) == 2)
	{
		decl String:title[40], String:weapons[40], String:upgrades[40], String:health[40];
		new Handle:menu = CreateMenu(TopMenu);
		if(GetConVarInt(CategoriesEnabled[CategoryWeapons]) == 1)
		{
			Format(weapons, sizeof(weapons), "%T", "Weapons", LANG_SERVER);
			AddMenuItem(menu, "g_WeaponsMenu", weapons);
		}
		if(GetConVarInt(CategoriesEnabled[CategoryUpgrades]) == 1)
		{
			Format(upgrades, sizeof(upgrades), "%T", "Upgrades", LANG_SERVER);
			AddMenuItem(menu, "g_UpgradesMenu", upgrades);
		}
		if(GetConVarInt(CategoriesEnabled[CategoryHealth]) == 1)
		{
			Format(health, sizeof(health), "%T", "Health", LANG_SERVER);
			AddMenuItem(menu, "g_HealthMenu", health);
		}
		Format(title, sizeof(title), "%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if(GetClientTeam(client) == 3)
	{
		decl String:title[40], String:boomer[40], String:spitter[40], String:smoker[40], String:hunter[40], String:charger[40], String:jockey[40], String:tank[40], String:witch[40], String:witch_bride[40], String:heal[40], String:suicide[40], String:horde[40], String:mob[40], String:umob[40];
		new Handle:menu = CreateMenu(InfectedMenu);
		if(GetConVarInt(ItemCosts[CostInfectedHeal]) > -1)
		{
			Format(heal, sizeof(heal), "%T", "Heal", LANG_SERVER);
			AddMenuItem(menu, "heal", heal);
		}
		if(GetConVarInt(ItemCosts[CostSuicide]) > -1)
		{
			Format(suicide, sizeof(suicide), "%T", "Suicide", LANG_SERVER);
			AddMenuItem(menu, "suicide", suicide);
		}
		if(GetConVarInt(ItemCosts[CostBoomer]) > -1)
		{
			Format(boomer, sizeof(boomer), "%T", "Boomer", LANG_SERVER);
			AddMenuItem(menu, "boomer", boomer);
		}
		if(GetConVarInt(ItemCosts[CostSpitter]) > -1)
		{
			Format(spitter, sizeof(spitter), "%T", "Spitter", LANG_SERVER);
			AddMenuItem(menu, "spitter", spitter);
		}
		if(GetConVarInt(ItemCosts[CostSmoker]) > -1)
		{
			Format(smoker, sizeof(smoker), "%T", "Smoker", LANG_SERVER);
			AddMenuItem(menu, "smoker", smoker);
		}
		if(GetConVarInt(ItemCosts[CostHunter]) > -1)
		{
			Format(hunter, sizeof(hunter), "%T", "Hunter", LANG_SERVER);
			AddMenuItem(menu, "hunter", hunter);
		}
		if(GetConVarInt(ItemCosts[CostCharger]) > -1)
		{
			Format(charger, sizeof(charger), "%T", "Charger", LANG_SERVER);
			AddMenuItem(menu, "charger", charger);
		}
		if(GetConVarInt(ItemCosts[CostJockey]) > -1)
		{
			Format(jockey, sizeof(jockey), "%T", "Jockey", LANG_SERVER);
			AddMenuItem(menu, "jockey", jockey);
		}
		if(GetConVarInt(ItemCosts[CostTank]) > -1)
		{
			Format(tank, sizeof(tank), "%T", "Tank", LANG_SERVER);
			AddMenuItem(menu, "tank", tank);
		}
		if(StrEqual(MapName, "c6m1_riverbank", false) && GetConVarInt(ItemCosts[CostWitch]) > -1)
		{
			Format(witch_bride, sizeof(witch_bride), "%T", "Witch Bride", LANG_SERVER);
			AddMenuItem(menu, "witch_bride", witch_bride);
		}
		else if(GetConVarInt(ItemCosts[CostWitch]) > -1)
		{
			Format(witch, sizeof(witch), "%T", "Witch", LANG_SERVER);
			AddMenuItem(menu, "witch", witch);
		}
		if(GetConVarInt(ItemCosts[CostHorde]) > -1)
		{
			Format(horde, sizeof(horde), "%T", "Horde", LANG_SERVER);
			AddMenuItem(menu, "horde", horde);
		}
		if(GetConVarInt(ItemCosts[CostMob]) > -1)
		{
			Format(mob, sizeof(mob), "%T", "Mob", LANG_SERVER);
			AddMenuItem(menu, "mob", mob);
		}
		if(GetConVarInt(ItemCosts[CostUncommonMob]) > -1)
		{
			Format(umob, sizeof(umob), "%T", "Uncommon Mob", LANG_SERVER);
			AddMenuItem(menu, "uncommon_mob", umob);
		}
		Format(title, sizeof(title), "%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

BuildWeaponsMenu(client)
{
	decl String:melee[40], String:rifles[40], String:shotguns[40], String:smg[40], String:snipers[40], String:misc[40], String:title[40], String:throwables[40];
	new Handle:menu = CreateMenu(MenuHandler);
	SetMenuExitBackButton(menu, true);
	if(GetConVarInt(CategoriesEnabled[CategoryMelee]) == 1)
	{
		Format(melee, sizeof(melee), "%T", "Melee", LANG_SERVER);
		AddMenuItem(menu, "g_MeleeMenu", melee);
	}
	if(GetConVarInt(CategoriesEnabled[CategorySnipers]) == 1)
	{
		Format(snipers, sizeof(snipers), "%T", "Sniper Rifles", LANG_SERVER);
		AddMenuItem(menu, "g_SnipersMenu", snipers);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryRifles]) == 1)
	{
		Format(rifles, sizeof(rifles), "%T", "Assault Rifles", LANG_SERVER);
		AddMenuItem(menu, "g_RiflesMenu", rifles);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryShotguns]) == 1)
	{
		Format(shotguns, sizeof(shotguns), "%T", "Shotguns", LANG_SERVER);
		AddMenuItem(menu, "g_ShotgunsMenu", shotguns);
	}
	if(GetConVarInt(CategoriesEnabled[CategorySMG]) == 1)
	{
		Format(smg, sizeof(smg), "%T", "Submachine Guns", LANG_SERVER);
		AddMenuItem(menu, "g_SMGMenu", smg);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryThrowables]) == 1)
	{
		Format(throwables, sizeof(throwables), "%T", "Throwables", LANG_SERVER);
		AddMenuItem(menu, "g_ThrowablesMenu", throwables);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryMisc]) == 1)
	{
		Format(misc, sizeof(misc), "%T", "Misc", LANG_SERVER);
		AddMenuItem(menu, "g_MiscMenu", misc);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public TopMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_WeaponsMenu"))
			{
				BuildWeaponsMenu(param1);
			}
			else if(StrEqual(menu1, "g_HealthMenu"))
			{
				BuildHealthMenu(param1);
			}
			else if(StrEqual(menu1, "g_UpgradesMenu"))
			{
				BuildUpgradesMenu(param1);
			}
		}
	}
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_MeleeMenu"))
			{
				BuildMeleeMenu(param1);
			}
			else if(StrEqual(menu1, "g_RiflesMenu"))
			{
				BuildRiflesMenu(param1);
			}
			else if(StrEqual(menu1, "g_SnipersMenu"))
			{
				BuildSniperMenu(param1);
			}
			else if(StrEqual(menu1, "g_ShotgunsMenu"))
			{
				BuildShotgunMenu(param1);
			}
			else if(StrEqual(menu1, "g_SMGMenu"))
			{
				BuildSMGMenu(param1);
			}
			else if(StrEqual(menu1, "g_ThrowablesMenu"))
			{
				BuildThrowablesMenu(param1);
			}
			else if(StrEqual(menu1, "g_MiscMenu"))
			{
				BuildMiscMenu(param1);
			}
		}
	}
}

BuildMeleeMenu(client)
{
	decl String:container[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Melee);
	for(new i;i<MAX_MELEE_LENGTH;i++)
	{
		if(strlen(validmelee[i]) < 1)
		{
			continue;
		}
		if(i == 0 && GetConVarInt(ItemCosts[CostBaseballbat]) < 0)
		{
			continue;
		}
		else if(i == 1 && GetConVarInt(ItemCosts[CostCricketbat]) < 0)
		{
			continue;
		}
		else if(i == 2 && GetConVarInt(ItemCosts[CostCrowbar]) < 0)
		{
			continue;
		}
		else if(i == 3 && GetConVarInt(ItemCosts[CostElectricguitar]) < 0)
		{
			continue;
		}
		else if(i == 4 && GetConVarInt(ItemCosts[CostFireaxe]) < 0)
		{
			continue;
		}
		else if(i == 5 && GetConVarInt(ItemCosts[CostFryingpan]) < 0)
		{
			continue;
		}
		else if(i == 6 && GetConVarInt(ItemCosts[CostGolfclub]) < 0)
		{
			continue;
		}
		else if(i == 7 && GetConVarInt(ItemCosts[CostKatana]) < 0)
		{
			continue;
		}
		else if(i == 8 && GetConVarInt(ItemCosts[CostMachete]) < 0)
		{
			continue;
		}
		else if(i == 9 && GetConVarInt(ItemCosts[CostTonfa]) < 0)
		{
			continue;
		}
		Format(container, sizeof(container), "%T", validmelee[i], LANG_SERVER);
		AddMenuItem(menu, validmelee[i], container);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildSniperMenu(client)
{
	decl String:hunting_rifle[40], String:title[40], String:sniper_military[40], String:sniper_scout[40], String:sniper_awp[40];
	new Handle:menu = CreateMenu(MenuHandler_Snipers);
	if(GetConVarInt(ItemCosts[CostHunting]) > -1)
	{
		Format(hunting_rifle, sizeof(hunting_rifle), "%T", "Hunting Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle);
	}
	if(GetConVarInt(ItemCosts[CostMilitary]) > -1)
	{
		Format(sniper_military, sizeof(sniper_military), "%T", "Military Sniper Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_sniper_military", sniper_military);
	}
	if(GetConVarInt(ItemCosts[CostAWP]) > -1)
	{
		Format(sniper_awp, sizeof(sniper_awp), "%T", "AWP Sniper Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_sniper_awp", sniper_awp);
	}
	if(GetConVarInt(ItemCosts[CostScout]) > -1)
	{
		Format(sniper_scout, sizeof(sniper_scout), "%T", "Scout Sniper Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_sniper_scout", sniper_scout);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildRiflesMenu(client)
{
	decl String:rifle[40], String:title[40], String:rifle_desert[40], String:rifle_ak47[40], String:rifle_sg552[40], String:rifle_m60[40];
	new Handle:menu = CreateMenu(MenuHandler_Rifles);
	if(GetConVarInt(ItemCosts[CostM60]) > -1)
	{
		Format(rifle_m60, sizeof(rifle_m60), "%T", "M60 Assault Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_m60", rifle_m60);
	}
	if(GetConVarInt(ItemCosts[CostM16]) > -1)
	{
		Format(rifle, sizeof(rifle), "%T", "M16 Assault Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle", rifle);
	}
	if(GetConVarInt(ItemCosts[CostSCAR]) > -1)
	{
		Format(rifle_desert, sizeof(rifle_desert), "%T", "SCAR-L Assault Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_desert", rifle_desert);
	}
	if(GetConVarInt(ItemCosts[CostAK47]) > -1)
	{
		Format(rifle_ak47, sizeof(rifle_ak47), "%T", "AK-47 Assault Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_ak47", rifle_ak47);
	}
	if(GetConVarInt(ItemCosts[CostSG552]) > -1)
	{
		Format(rifle_sg552, sizeof(rifle_sg552), "%T", "SG552 Assault Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_sg552", rifle_sg552);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildShotgunMenu(client)
{
	decl String:autoshotgun[40], String:shotgun_chrome[40], String:shotgun_spas[40], String:pumpshotgun[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Shotguns);
	if(GetConVarInt(ItemCosts[CostAuto]) > -1)
	{
		Format(autoshotgun, sizeof(autoshotgun), "%T", "Tactical Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_autoshotgun", autoshotgun);
	}
	if(GetConVarInt(ItemCosts[CostChrome]) > -1)
	{
		Format(shotgun_chrome, sizeof(shotgun_chrome), "%T", "Chrome Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_shotgun_chrome", shotgun_chrome);
	}
	if(GetConVarInt(ItemCosts[CostSPAS]) > -1)
	{
		Format(shotgun_spas, sizeof(shotgun_spas), "%T", "SPAS Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_shotgun_spas", shotgun_spas);
	}
	if(GetConVarInt(ItemCosts[CostPump]) > -1)
	{
		Format(pumpshotgun, sizeof(pumpshotgun), "%T", "Pump Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_pumpshotgun", pumpshotgun);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildSMGMenu(client)
{
	decl String:smg[40], String:title[40], String:smg_silenced[40], String:smg_mp5[40];
	new Handle:menu = CreateMenu(MenuHandler_SMG);
	if(GetConVarInt(ItemCosts[CostUzi]) > -1)
	{
		Format(smg, sizeof(smg), "%T", "Uzi", LANG_SERVER);
		AddMenuItem(menu, "weapon_smg", smg);
	}
	if(GetConVarInt(ItemCosts[CostSilenced]) > -1)
	{
		Format(smg_silenced, sizeof(smg_silenced), "%T", "Silenced SMG", LANG_SERVER);
		AddMenuItem(menu, "weapon_smg_silenced", smg_silenced);
	}
	if(GetConVarInt(ItemCosts[CostMP5]) > -1)
	{
		Format(smg_mp5, sizeof(smg_mp5), "%T", "MP5 SMG", LANG_SERVER);
		AddMenuItem(menu, "weapon_smg_mp5", smg_mp5);
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildHealthMenu(client)
{
	decl String:adrenaline[40], String:defibrillator[40], String:first_aid_kit[40], String:pain_pills[40], String:health[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Health);
	if(GetConVarInt(ItemCosts[CostHealthKit]) > -1)
	{
		Format(first_aid_kit, sizeof(first_aid_kit), "%T", "First Aid Kit", LANG_SERVER);
		AddMenuItem(menu, "weapon_first_aid_kit", first_aid_kit);
	}
	if(GetConVarInt(ItemCosts[CostDefib]) > -1)
	{
		Format(defibrillator, sizeof(defibrillator), "%T", "Defibrillator", LANG_SERVER);
		AddMenuItem(menu, "weapon_defibrillator", defibrillator);
	}
	if(GetConVarInt(ItemCosts[CostPills]) > -1)
	{
		Format(pain_pills, sizeof(pain_pills), "%T", "Pills", LANG_SERVER);
		AddMenuItem(menu, "weapon_pain_pills", pain_pills);
	}
	if(GetConVarInt(ItemCosts[CostAdren]) > -1)
	{
		Format(adrenaline, sizeof(adrenaline), "%T", "Adrenaline", LANG_SERVER);
		AddMenuItem(menu, "weapon_adrenaline", adrenaline);
	}
	if(GetConVarInt(ItemCosts[CostHeal]) > -1)
	{
		Format(health, sizeof(health), "%T", "Full Heal", LANG_SERVER);
		AddMenuItem(menu, "health", health);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildThrowablesMenu(client)
{
	decl String:molotov[40], String:pipe_bomb[40], String:vomitjar[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Throwables);
	if(GetConVarInt(ItemCosts[CostMolotov]) > -1)
	{
		Format(molotov, sizeof(molotov), "%T", "Molotov", LANG_SERVER);
		AddMenuItem(menu, "weapon_molotov", molotov);
	}
	if(GetConVarInt(ItemCosts[CostPipe]) > -1)
	{
		Format(pipe_bomb, sizeof(pipe_bomb), "%T", "Pipe Bomb", LANG_SERVER);
		AddMenuItem(menu, "weapon_pipe_bomb", pipe_bomb);
	}
	if(GetConVarInt(ItemCosts[CostBile]) > -1)
	{
		Format(vomitjar, sizeof(vomitjar), "%T", "Bile Bomb", LANG_SERVER);
		AddMenuItem(menu, "weapon_vomitjar", vomitjar);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildMiscMenu(client)
{
	decl String:grenade_launcher[40], String:fireworkcrate[40], String:gascan[40], String:oxygentank[40], String:propanetank[40], String:pistol[40], String:pistol_magnum[40], String:title[40];
	decl String:gnome[40], String:cola_bottles[40], String:chainsaw[40];
	new Handle:menu = CreateMenu(MenuHandler_Misc);
	if(GetConVarInt(ItemCosts[CostGrenade]) > -1)
	{
		Format(grenade_launcher, sizeof(grenade_launcher), "%T", "Grenade Launcher", LANG_SERVER);
		AddMenuItem(menu, "weapon_grenade_launcher", grenade_launcher);
	}
	if(GetConVarInt(ItemCosts[CostP220]) > -1)
	{
		Format(pistol, sizeof(pistol), "%T", "P220 Pistol", LANG_SERVER);
		AddMenuItem(menu, "weapon_pistol", pistol);
	}
	if(GetConVarInt(ItemCosts[CostMagnum]) > -1)
	{
		Format(pistol_magnum, sizeof(pistol_magnum), "%T", "Magnum Pistol", LANG_SERVER);
		AddMenuItem(menu, "weapon_pistol_magnum", pistol_magnum);
	}
	if(GetConVarInt(ItemCosts[CostChainsaw]) > -1)
	{
		Format(chainsaw, sizeof(chainsaw), "%T", "Chainsaw", LANG_SERVER);
		AddMenuItem(menu, "weapon_chainsaw", chainsaw);
	}
	if(GetConVarInt(ItemCosts[CostGnome]) > -1)
	{
		Format(gnome, sizeof(gnome), "%T", "Gnome", LANG_SERVER);
		AddMenuItem(menu, "weapon_gnome", gnome);
	}
	if(!StrEqual(MapName, "c1m2_streets", false) && GetConVarInt(ItemCosts[CostCola]) > -1)
	{
		Format(cola_bottles, sizeof(cola_bottles), "%T", "Cola Bottles", LANG_SERVER);
		AddMenuItem(menu, "weapon_cola_bottles", cola_bottles);
	}
	if(GetConVarInt(ItemCosts[CostFireworks]) > -1)
	{
		Format(fireworkcrate, sizeof(fireworkcrate), "%T", "Fireworks Crate", LANG_SERVER);
		AddMenuItem(menu, "weapon_fireworkcrate", fireworkcrate);
	}
	new String:gamemode[20];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(!StrEqual(gamemode, "scavenge", false) && GetConVarInt(ItemCosts[CostGasCan]) > -1)
	{
		Format(gascan, sizeof(gascan), "%T", "Gascan", LANG_SERVER);
		AddMenuItem(menu, "weapon_gascan", gascan);
	}
	if(GetConVarInt(ItemCosts[CostOxygen]) > -1)
	{
		Format(oxygentank, sizeof(oxygentank), "%T", "Oxygen Tank", LANG_SERVER);
		AddMenuItem(menu, "weapon_oxygentank", oxygentank);
	}
	if(GetConVarInt(ItemCosts[CostPropane]) > -1)
	{
		Format(propanetank, sizeof(propanetank), "%T", "Propane Tank", LANG_SERVER);
		AddMenuItem(menu, "weapon_propanetank", propanetank);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildUpgradesMenu(client)
{
	decl String:upgradepack_explosive[40], String:upgradepack_incendiary[40], String:title[40];
	decl String:laser_sight[40], String:explosive_ammo[40], String:incendiary_ammo[40], String:ammo[40];
	new Handle:menu = CreateMenu(MenuHandler_Upgrades);
	if(GetConVarInt(ItemCosts[CostLaserSight]) > -1)
	{
		Format(laser_sight, sizeof(laser_sight), "%T", "Laser Sight", LANG_SERVER);
		AddMenuItem(menu, "laser_sight", laser_sight);
	}
	if(GetConVarInt(ItemCosts[CostExplosiveAmmo]) > -1)
	{
		Format(explosive_ammo, sizeof(explosive_ammo), "%T", "Explosive Ammo", LANG_SERVER);
		AddMenuItem(menu, "explosive_ammo", explosive_ammo);
	}
	if(GetConVarInt(ItemCosts[CostFireAmmo]) > -1)
	{
		Format(incendiary_ammo, sizeof(incendiary_ammo), "%T", "Incendiary Ammo", LANG_SERVER);
		AddMenuItem(menu, "incendiary_ammo", incendiary_ammo);
	}
	if(GetConVarInt(ItemCosts[CostExplosivePack]) > -1)
	{
		Format(upgradepack_explosive, sizeof(upgradepack_explosive), "%T", "Explosive Ammo Pack", LANG_SERVER);
		AddMenuItem(menu, "upgradepack_explosive", upgradepack_explosive);
	}
	if(GetConVarInt(ItemCosts[CostFirePack]) > -1)
	{
		Format(upgradepack_incendiary, sizeof(upgradepack_incendiary), "%T", "Incendiary Ammo Pack", LANG_SERVER);
		AddMenuItem(menu, "upgradepack_incendiary", upgradepack_incendiary);
	}
	if(GetConVarInt(ItemCosts[CostAmmo]) > -1)
	{
		Format(ammo, sizeof(ammo), "%T", "Ammo", LANG_SERVER);
		AddMenuItem(menu, "ammo", ammo);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Melee(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "baseball_bat", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give baseball_bat");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostBaseballbat]);
			}
			else if(StrEqual(item1, "cricket_bat", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give cricket_bat");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostCricketbat]);
			}
			else if(StrEqual(item1, "crowbar", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give crowbar");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostCrowbar]);
			}
			else if(StrEqual(item1, "electric_guitar", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give electric_guitar");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostElectricguitar]);
			}
			else if(StrEqual(item1, "fireaxe", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give fireaxe");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFireaxe]);
			}
			else if(StrEqual(item1, "frying_pan", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give frying_pan");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFryingpan]);
			}
			else if(StrEqual(item1, "golfclub", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give golfclub");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostGolfclub]);
			}
			else if(StrEqual(item1, "katana", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give katana");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostKatana]);
			}
			else if(StrEqual(item1, "machete", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give machete");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMachete]);
			}
			else if(StrEqual(item1, "tonfa", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give tonfa");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostTonfa]);
			}
			DisplayConfirmMenuMelee(param1);
		}
	}
}

public MenuHandler_SMG(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_smg", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give smg");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostUzi]);
			}
			else if(StrEqual(item1, "weapon_smg_silenced", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give smg_silenced");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSilenced]);
			}
			else if(StrEqual(item1, "weapon_smg_mp5", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give smg_mp5");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMP5]);
			}
			DisplayConfirmMenuSMG(param1);
		}
	}
}

public MenuHandler_Rifles(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_rifle", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give weapon_rifle");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostM16]);
			}
			else if(StrEqual(item1, "weapon_rifle_desert", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_desert");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSCAR]);
			}
			else if(StrEqual(item1, "weapon_rifle_ak47", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_ak47");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAK47]);
			}
			else if(StrEqual(item1, "weapon_rifle_sg552", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_sg552");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSG552]);
			}
			else if(StrEqual(item1, "weapon_rifle_m60", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_m60");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostM60]);
			}
			DisplayConfirmMenuRifles(param1);
		}
	}
}

public MenuHandler_Snipers(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_hunting_rifle", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give hunting_rifle");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostHunting]);
			}
			else if(StrEqual(item1, "weapon_sniper_scout", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give sniper_scout");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostScout]);
			}
			else if(StrEqual(item1, "weapon_sniper_awp", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give sniper_awp");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostScout]);
			}
			else if(StrEqual(item1, "weapon_sniper_military", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give sniper_military");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMilitary]);
			}
			DisplayConfirmMenuSnipers(param1);
		}
	}
}

public MenuHandler_Shotguns(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_shotgun_chrome", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give shotgun_chrome");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostChrome]);
			}
			else if(StrEqual(item1, "weapon_pumpshotgun", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pumpshotgun");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPump]);
			}
			else if(StrEqual(item1, "weapon_autoshotgun", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give autoshotgun");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAuto]);
			}
			else if(StrEqual(item1, "weapon_shotgun_spas", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give shotgun_spas");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSPAS]);
			}
			DisplayConfirmMenuShotguns(param1);
		}
	}
}

public MenuHandler_Throwables(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_molotov", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give molotov");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMolotov]);
			}
			else if(StrEqual(item1, "weapon_pipe_bomb", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pipe_bomb");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPipe]);
			}
			else if(StrEqual(item1, "weapon_vomitjar", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give vomitjar");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostBile]);
			}
			DisplayConfirmMenuThrow(param1);
		}
	}
}

public MenuHandler_Misc(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_pistol", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pistol");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostP220]);
			}
			else if(StrEqual(item1, "weapon_pistol_magnum", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pistol_magnum");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMagnum]);
			}
			else if(StrEqual(item1, "weapon_grenade_launcher", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give grenade_launcher");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostGrenade]);
			}
			else if(StrEqual(item1, "weapon_chainsaw", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give chainsaw");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostChainsaw]);
			}
			else if(StrEqual(item1, "weapon_gnome", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give gnome");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostGnome]);
			}
			else if(StrEqual(item1, "weapon_cola_bottles", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give cola_bottles");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostCola]);
			}
			else if(StrEqual(item1, "weapon_gascan", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give gascan");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostGasCan]);
			}
			else if(StrEqual(item1, "weapon_propanetank", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give propanetank");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPropane]);
			}
			else if(StrEqual(item1, "weapon_fireworkcrate", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give fireworkcrate");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFireworks]);
			}
			else if(StrEqual(item1, "weapon_oxygentank", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give oxygentank");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostOxygen]);
			}
			DisplayConfirmMenuMisc(param1);
		}
	}
}

public MenuHandler_Health(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
		}
	case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_first_aid_kit", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give first_aid_kit");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostHealthKit]);
			}
			else if(StrEqual(item1, "weapon_defibrillator", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give defibrillator");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostDefib]);
			}
			else if(StrEqual(item1, "weapon_pain_pills", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pain_pills");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPills]);
			}
			else if(StrEqual(item1, "weapon_adrenaline", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give adrenaline");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAdren]);
			}
			else if(StrEqual(item1, "health", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give health");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostHeal]);
			}
			DisplayConfirmMenuHealth(param1);
		}
	}
}

public MenuHandler_Upgrades(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "upgradepack_explosive", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give upgradepack_explosive");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostExplosiveAmmo]);
			}
			else if(StrEqual(item1, "upgradepack_incendiary", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give upgradepack_incendiary");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFireAmmo]);
			}
			else if(StrEqual(item1, "explosive_ammo", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "upgrade_add EXPLOSIVE_AMMO");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostExplosivePack]);
			}
			else if(StrEqual(item1, "incendiary_ammo", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "upgrade_add INCENDIARY_AMMO");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFirePack]);
			}
			else if(StrEqual(item1, "laser_sight", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "upgrade_add LASER_SIGHT");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostLaserSight]);
			}
			else if(StrEqual(item1, "ammo", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give ammo");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAmmo]);
			}
			DisplayConfirmMenuUpgrades(param1);
		}
	}
}

public InfectedMenu(Handle:hMenu, MenuAction:action, iClientIndex, iPosition)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	case MenuAction_Select:
		{
			decl String:sItem[64]; sItem[0] = '\0';
			GetMenuItem(hMenu, iPosition, sItem, sizeof(sItem));
			if (StrEqual(sItem, "heal", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "give health");
				if(IsClientTank(iClientIndex))
					PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostInfectedHeal])*GetConVarInt(ItemCosts[CostTankHealMultiplier]);
				else
					PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostInfectedHeal]);
			}
			else if (StrEqual(sItem, "suicide", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "suicide");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostSuicide]);
			}
			else if (StrEqual(sItem, "boomer", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old boomer auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostBoomer]);
			}
			else if (StrEqual(sItem, "spitter", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old spitter auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostSpitter]);
			}
			else if (StrEqual(sItem, "smoker", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old smoker auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostSmoker]);
			}
			else if (StrEqual(sItem, "hunter", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old hunter auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostHunter]);
			}
			else if (StrEqual(sItem, "charger", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old charger auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostCharger]);
			}
			else if (StrEqual(sItem, "jockey", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old jockey auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostJockey]);
			}
			else if (StrEqual(sItem, "witch", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old witch auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostWitch]);
			}
			else if (StrEqual(sItem, "witch_bride", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old witch_bride auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostWitch]);
			}
			else if (StrEqual(sItem, "tank", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old tank auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostTank]);
			}
			else if (StrEqual(sItem, "horde", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "director_force_panic_event");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostHorde]);
			}
			else if (StrEqual(sItem, "mob", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old mob auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostMob]);
			}
			else if (StrEqual(sItem, "uncommon_mob", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old mob");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostUncommonMob]);
			}
			DisplayConfirmMenuI(iClientIndex);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "infected", false) && CounterData[iUCommonLeft] > 0)
	{
		new rand = GetRandomInt(1, 6);
		switch(rand)
		{
			case 1:
			{
				SetEntityModel(entity, "models/infected/common_male_riot.mdl");
			}
			case 2:
			{
				SetEntityModel(entity, "models/infected/common_male_ceda.mdl");
			}
			case 3:
			{
				SetEntityModel(entity, "models/infected/common_male_clown.mdl");
			}
			case 4:
			{
				SetEntityModel(entity, "models/infected/common_male_mud.mdl");
			}
			case 5:
			{
				SetEntityModel(entity, "models/infected/common_male_roadcrew.mdl");
			}
			case 6:
			{
				SetEntityModel(entity, "models/infected/common_male_fallen_survivor.mdl");
			}
		}
		CounterData[iUCommonLeft]--;
	}
}

DisplayConfirmMenuMelee(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMelee);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuSMG(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSMG);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuRifles(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmRifles);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuSnipers(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSniper);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuShotguns(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmShotguns);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuThrow(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmThrow);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuMisc(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMisc);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuHealth(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmHealth);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuUpgrades(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmUpgrades);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuI(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmI);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

public MenuHandler_ConfirmMelee(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildMeleeMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMeleeMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}
			}
		}
	}
}

public MenuHandler_ConfirmRifles(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildRiflesMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildRiflesMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}
			}
		}
	}
}

public MenuHandler_ConfirmSniper(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildSniperMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSniperMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}
			}
		}
	}
}

public MenuHandler_ConfirmSMG(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildSMGMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSMGMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}
			}
		}
	}
}

public MenuHandler_ConfirmShotguns(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildShotgunMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildShotgunMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}
			}
		}
	}
}

public MenuHandler_ConfirmThrow(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildThrowablesMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildThrowablesMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}
			}
		}
	}
}

public MenuHandler_ConfirmMisc(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildMiscMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMiscMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}
			}
		}
	}
}

public MenuHandler_ConfirmHealth(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildHealthMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildHealthMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if(StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost])){
					if(StrEqual(PlayerData[param1][sItemName], "give health", false))
					{
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
						execClientCommand(param1, PlayerData[param1][sItemName]);
						SetEntPropFloat(param1, Prop_Send, "m_healthBuffer", 0.0);
					}
					else
					{
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
						execClientCommand(param1, PlayerData[param1][sItemName]);
					}
				}
			}
		}
	}
}

public bool:IsCarryingWeapon(iClientIndex){
	new iWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(iWeapon == -1)
		return false;
	else return true;
}

public reloadAmmo(int iClientIndex, int iCost, const String:sItem[]){
	new hWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(IsCarryingWeapon(iClientIndex)){

		decl String:sWeapon[40]; sWeapon[0] = '\0';
		GetEdictClassname(hWeapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_rifle_m60", false)){
			new iAmmo_m60 = 150;
			new Handle:hGunControl_m60 = FindConVar("l4d2_guncontrol_m60ammo");
			if(hGunControl_m60 != null){
				iAmmo_m60 = GetConVarInt(hGunControl_m60);
				CloseHandle(hGunControl_m60);
			}
			SetEntProp(hWeapon, Prop_Data, "m_iClip1", iAmmo_m60, 1);
		}
		else if(StrEqual(sWeapon, "weapon_grenade_launcher", false)){
			new iAmmo_Launcher = 30;
			new Handle:hGunControl_Launcher = FindConVar("l4d2_guncontrol_grenadelauncherammo");
			if(hGunControl_Launcher != null){
				iAmmo_Launcher = GetConVarInt(hGunControl_Launcher);
				CloseHandle(hGunControl_Launcher);
			}
			new uOffset = FindDataMapOffs(iClientIndex, "m_iAmmo");
			SetEntData(iClientIndex, uOffset + 68, iAmmo_Launcher);
		}
		execClientCommand(iClientIndex, sItem);
		removePoints(iClientIndex, iCost);
	}
	else
		PrintToChat(iClientIndex, "%s %T", MSGTAG, "Primary Warning", LANG_SERVER);
	return;
}

public MenuHandler_ConfirmUpgrades(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildUpgradesMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildUpgradesMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost])){
					if(StrEqual(PlayerData[param1][sItemName], "give ammo", false))
						reloadAmmo(param1, PlayerData[param1][iItemCost], PlayerData[param1][sItemName]);
					else
					{
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
						execClientCommand(param1, PlayerData[param1][sItemName]);
					}
				}
			}
		}
	}
}

public MenuHandler_ConfirmI(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildBuyMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if(StrEqual(choice, "yes", false))
			{
				if(!HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
					return;

				if(StrEqual(PlayerData[param1][sItemName], "suicide", false))
				{
					performSuicide(param1, PlayerData[param1][iItemCost]);
					return;
				}
				else if(StrEqual(PlayerData[param1][sItemName], "z_spawn_old mob", false))
				{
					CounterData[iUCommonLeft] += GetConVarInt(FindConVar("z_common_limit"));
				}
				else if(StrEqual(PlayerData[param1][sItemName], "z_spawn_old tank auto", false))
				{
					if(CounterData[iTanksSpawned] == GetConVarInt(PluginSettings[hTankLimit]))
					{
						PrintToChat(param1,  "%T", "Tank Limit", LANG_SERVER);
						return;
					}
					CounterData[iTanksSpawned]++;
				}
				else if(StrEqual(PlayerData[param1][sItemName], "z_spawn_old witch auto", false) || StrEqual(PlayerData[param1][sItemName], "z_spawn_old witch_bride auto", false))
				{
					if(CounterData[iWitchesSpawned] == GetConVarInt(PluginSettings[hWitchLimit]))
					{
						PrintToChat(param1,  "%T", "Witch Limit", LANG_SERVER);
						return;
					}
					CounterData[iWitchesSpawned]++;
				}
				else if(StrContains(PlayerData[param1][sItemName], "z_spawn_old", false) != -1 && StrContains(PlayerData[param1][sItemName], "mob", false) == -1)
				{
					if(IsPlayerAlive(param1) || IsPlayerGhost(param1))
					{
						return;
					}
					new bool:resetGhost[MaxClients+1], bool:resetAlive[MaxClients+1], bool:resetLifeState[MaxClients+1];
					for(new i=1;i<=MaxClients;i++)
					{
						if(i == param1 || !IsClientInGame(i) || GetClientTeam(i) != 3 || IsFakeClient(i))
						{
							continue;
						}

						if(IsPlayerGhost(i))
						{
							resetGhost[i] = true;
							resetAlive[i] = true;
							SetPlayerGhost(i, false);
							SetPlayerAlive(i, true);
						}
						else if(!IsPlayerAlive(i))
						{
							resetLifeState[i] = true;
							SetPlayerLifeState(i, false);
						}
					}

					execClientCommand(param1, PlayerData[param1][sItemName]);

					new maxretry = GetConVarInt(PluginSettings[hSpawnAttempts]);
					for(new i;i<maxretry;i++)
					{
						if(!IsPlayerAlive(param1))
						{
							execClientCommand(param1, PlayerData[param1][sItemName]);
						}
					}

					if(IsPlayerAlive(param1))
					{
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
					}
					else
					{
						PrintToChat(param1, "%s %T", MSGTAG, "Spawn Failed", param1);
					}


					for(new i=1;i<=MaxClients;i++)
					{
						if (resetGhost[i]) SetPlayerGhost(i, true);
						if (resetAlive[i]) SetPlayerAlive(i, false);
						if (resetLifeState[i]) SetPlayerLifeState(i, true);
					}
					return;
				}
				strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
				PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
				removePoints(param1, PlayerData[param1][iItemCost]);
				execClientCommand(param1, PlayerData[param1][sItemName]);
			}
		}
	}
}

stock SetPlayerLifeState(client, bool:lifestate)
{
	SetEntData(client, SendProp_LifeState, lifestate, 1);
}

stock SetPlayerAlive(client, bool:alive)
{
	SetEntData(client, SendProp_IsAlive, alive, 1, true);
}

stock SetPlayerGhost(client, bool:ghost)
{
	SetEntData(client, SendProp_IsGhost, ghost, 1);
}