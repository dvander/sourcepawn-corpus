#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_TITLE "1.6.9 Dimitte"

#define MSGTAG "\x04[PS]\x01"
#define MSGTAG2 "\x04[PS]\x01 "
#define MODULES_SIZE 100

new Float:version = 1.69; //x.x.x isn't allowed only one decimal is allowed :(

new Handle:ModulesArray = INVALID_HANDLE;
new Handle:Forward1 = INVALID_HANDLE;
new Handle:Forward2 = INVALID_HANDLE;

//melee check
#define MAX_MELEE_LENGTH 12
new String:meleelist[MAX_MELEE_LENGTH][20] =
{
	"cricket_bat",
	"crowbar",
	"baseball_bat",
	"electric_guitar",
	"fireaxe",
	"katana",
	"knife",
	"tonfa",
	"golfclub",
	"machete",
	"frying_pan",
	"riotshield"
};
new String:validmelee[MAX_MELEE_LENGTH][20];	

new String:MapName[60];
new String:item[MAXPLAYERS][64];
new String:bought[MAXPLAYERS][64];
new boughtcost[MAXPLAYERS];
new hurtcount[MAXPLAYERS];
new protectcount[MAXPLAYERS];
new cost[MAXPLAYERS];
new tankburning[MAXPLAYERS];
new tankbiled[MAXPLAYERS];
new witchburning[MAXPLAYERS];
new points[MAXPLAYERS];
new killcount[MAXPLAYERS];
new headshotcount[MAXPLAYERS];
new wassmoker[MAXPLAYERS];
new tanksspawned;
new witchsspawned;
new ucommonleft;
//Definitions to save space
#define ATTACKER new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT new client = GetClientOfUserId(GetEventInt(event, "userid"));
#define ACHECK2 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK2 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define ACHECK3 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK3 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
//Other
new Handle:Enable = INVALID_HANDLE;
new Handle:Modes = INVALID_HANDLE;
new Handle:Notifications = INVALID_HANDLE;
//Item buyables
new Handle:PointsPistol = INVALID_HANDLE;
new Handle:PointsMagnum = INVALID_HANDLE;
new Handle:PointsSMG = INVALID_HANDLE;
new Handle:PointsSSMG = INVALID_HANDLE;
new Handle:PointsMP5 = INVALID_HANDLE;
new Handle:PointsM16 = INVALID_HANDLE;
new Handle:PointsAK = INVALID_HANDLE;
new Handle:PointsSCAR = INVALID_HANDLE;
new Handle:PointsSG = INVALID_HANDLE;
new Handle:PointsHunting = INVALID_HANDLE;
new Handle:PointsMilitary = INVALID_HANDLE;
new Handle:PointsAWP = INVALID_HANDLE;
new Handle:PointsScout = INVALID_HANDLE;
new Handle:PointsAuto = INVALID_HANDLE;
new Handle:PointsSpas = INVALID_HANDLE;
new Handle:PointsChrome = INVALID_HANDLE;
new Handle:PointsPump = INVALID_HANDLE;
new Handle:PointsGL = INVALID_HANDLE;
new Handle:PointsM60 = INVALID_HANDLE;
new Handle:PointsGasCan = INVALID_HANDLE;
new Handle:PointsOxy = INVALID_HANDLE;
new Handle:PointsPropane = INVALID_HANDLE;
new Handle:PointsGnome = INVALID_HANDLE;
new Handle:PointsCola = INVALID_HANDLE;
new Handle:PointsFireWorks = INVALID_HANDLE;
new Handle:PointsBat = INVALID_HANDLE;
new Handle:PointsMachete = INVALID_HANDLE;
new Handle:PointsKatana = INVALID_HANDLE;
new Handle:PointsKnife = INVALID_HANDLE;
new Handle:PointsShield = INVALID_HANDLE;
new Handle:PointsTonfa = INVALID_HANDLE;
new Handle:PointsFireaxe = INVALID_HANDLE;
new Handle:PointsGuitar = INVALID_HANDLE;
new Handle:PointsPan = INVALID_HANDLE;
new Handle:PointsCBat = INVALID_HANDLE;
new Handle:PointsCrow = INVALID_HANDLE;
new Handle:PointsClub = INVALID_HANDLE;
new Handle:PointsSaw = INVALID_HANDLE;
new Handle:PointsPipe = INVALID_HANDLE;
new Handle:PointsMolly = INVALID_HANDLE;
new Handle:PointsBile = INVALID_HANDLE;
new Handle:PointsKit = INVALID_HANDLE;
new Handle:PointsDefib = INVALID_HANDLE;
new Handle:PointsAdren = INVALID_HANDLE;
new Handle:PointsPills = INVALID_HANDLE;
new Handle:PointsEAmmo = INVALID_HANDLE;
new Handle:PointsIAmmo = INVALID_HANDLE;
new Handle:PointsEAmmoPack = INVALID_HANDLE;
new Handle:PointsIAmmoPack = INVALID_HANDLE;
new Handle:PointsLSight = INVALID_HANDLE;
new Handle:PointsRefill = INVALID_HANDLE;
new Handle:PointsHeal = INVALID_HANDLE;
//Survivor point earning things
new Handle:SValueKillingSpree = INVALID_HANDLE;
new Handle:SNumberKill = INVALID_HANDLE;
new Handle:SValueHeadSpree = INVALID_HANDLE;
new Handle:SNumberHead = INVALID_HANDLE;
new Handle:SSIKill = INVALID_HANDLE;
new Handle:STankKill = INVALID_HANDLE;
new Handle:SWitchKill = INVALID_HANDLE;
new Handle:SWitchCrown = INVALID_HANDLE;
new Handle:SHeal = INVALID_HANDLE;
new Handle:SHealWarning = INVALID_HANDLE;
new Handle:SProtect = INVALID_HANDLE;
new Handle:SRevive = INVALID_HANDLE;
new Handle:SLedge = INVALID_HANDLE;
new Handle:SDefib = INVALID_HANDLE;
new Handle:STBurn = INVALID_HANDLE;
new Handle:STSolo = INVALID_HANDLE;
new Handle:SWBurn = INVALID_HANDLE;
new Handle:STag = INVALID_HANDLE;
//Infected point earning things
new Handle:IChoke = INVALID_HANDLE;
new Handle:IPounce = INVALID_HANDLE;
new Handle:ICarry = INVALID_HANDLE;
new Handle:IImpact = INVALID_HANDLE;
new Handle:IRide = INVALID_HANDLE;
new Handle:ITag = INVALID_HANDLE;
new Handle:IIncap = INVALID_HANDLE;
new Handle:IHurt = INVALID_HANDLE;
new Handle:IKill = INVALID_HANDLE;
//Infected buyables
new Handle:PointsSuicide = INVALID_HANDLE;
new Handle:PointsHunter = INVALID_HANDLE;
new Handle:PointsJockey = INVALID_HANDLE;
new Handle:PointsSmoker = INVALID_HANDLE;
new Handle:PointsCharger = INVALID_HANDLE;
new Handle:PointsBoomer = INVALID_HANDLE;
new Handle:PointsSpitter = INVALID_HANDLE;
new Handle:PointsIHeal = INVALID_HANDLE;
new Handle:PointsWitch = INVALID_HANDLE;
new Handle:PointsTank = INVALID_HANDLE;
new Handle:PointsTankHealMult = INVALID_HANDLE;
new Handle:PointsHorde = INVALID_HANDLE;
new Handle:PointsMob = INVALID_HANDLE;
new Handle:PointsUMob = INVALID_HANDLE;
//Catergory Enables
new Handle:CatRifles = INVALID_HANDLE;
new Handle:CatSMG = INVALID_HANDLE;
new Handle:CatSnipers = INVALID_HANDLE;
new Handle:CatShotguns = INVALID_HANDLE;
new Handle:CatHealth = INVALID_HANDLE;
new Handle:CatUpgrades = INVALID_HANDLE;
new Handle:CatThrowables = INVALID_HANDLE;
new Handle:CatMisc = INVALID_HANDLE;
new Handle:CatMelee = INVALID_HANDLE;
new Handle:CatWeapons = INVALID_HANDLE;
//Misc
new Handle:TankLimit = INVALID_HANDLE;
new Handle:WitchLimit = INVALID_HANDLE;
new Handle:ResetPoints = INVALID_HANDLE;
new Handle:StartPoints = INVALID_HANDLE;
new Handle:SpawnTries = INVALID_HANDLE;

//stuffs
new SendProp_IsAlive;
new SendProp_IsGhost;
new SendProp_LifeState;

new bool:lateload = false;
new bool:bFirstRun = true;

public Plugin:myinfo = 
{
	name = "[L4D2] Points System",
	author = "McFlurry",
	description = "Points system to buy items on the fly.",
	version = PLUGIN_TITLE,
	url = "N/A"
}

public OnPluginStart()
{
	ModulesArray = CreateArray(100);
	if(ModulesArray == INVALID_HANDLE)
	{
		SetFailState("%T", "Modules Array Failure", LANG_SERVER);
	}
	AddMultiTargetFilter("@survivors", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@survivor", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@s", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@infected", FilterInfected, "all Infected players", true);
	AddMultiTargetFilter("@i", FilterInfected, "all Infected players", true);
	CreateConVar("l4d2_points_sys_version", PLUGIN_TITLE, "Version of Points System on this server.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	StartPoints = CreateConVar("l4d2_points_start", "0", "Points to start each round/map with.", FCVAR_PLUGIN);
	Notifications = CreateConVar("l4d2_points_notify", "1", "Show messages when points are earned?", FCVAR_PLUGIN);
	Enable = CreateConVar("l4d2_points_enable", "1", "Enable Point System?", FCVAR_PLUGIN);
	Modes = CreateConVar("l4d2_points_modes", "coop,realism,versus,teamversus", "Which game modes to use Point System", FCVAR_PLUGIN);
	ResetPoints = CreateConVar("l4d2_points_reset_mapchange", "versus,teamversus", "Which game modes to reset point count on round end and round start", FCVAR_PLUGIN);
	TankLimit = CreateConVar("l4d2_points_tank_limit", "2", "How many tanks to be allowed spawned per team", FCVAR_PLUGIN);
	WitchLimit = CreateConVar("l4d2_points_witch_limit", "3", "How many witchs' to be allwed spawned per team", FCVAR_PLUGIN);
	SpawnTries = CreateConVar("l4d2_points_spawn_tries", "2", "How many times to attempt respawning when buying an special infected", FCVAR_PLUGIN);
	PointsPistol = CreateConVar("l4d2_points_pistol", "4", "How many points the pistol costs", FCVAR_PLUGIN);
	PointsSMG = CreateConVar("l4d2_points_smg", "7", "How many points the smg costs", FCVAR_PLUGIN);
	PointsM16 = CreateConVar("l4d2_points_m16", "12", "How many points the m16 costs", FCVAR_PLUGIN);
	PointsHunting = CreateConVar("l4d2_points_hunting_rifle", "10", "How many points the hunting rifle costs", FCVAR_PLUGIN);
	PointsAuto = CreateConVar("l4d2_points_autoshotgun", "10", "How many points the autoshotgun costs", FCVAR_PLUGIN);
	PointsPump = CreateConVar("l4d2_points_pump", "7", "How many points the pump shotgun costs", FCVAR_PLUGIN);
	PointsGasCan = CreateConVar("l4d2_points_gascan", "5", "How many points the gas can costs", FCVAR_PLUGIN);
	PointsPropane = CreateConVar("l4d2_points_propane", "2", "How many points the propane tank costs", FCVAR_PLUGIN);
	PointsMagnum = CreateConVar("l4d2_points_magnum", "6", "How many points the magnum costs", FCVAR_PLUGIN);
	PointsSSMG = CreateConVar("l4d2_points_ssmg", "7", "How many points the silenced smg costs", FCVAR_PLUGIN);
	PointsMP5 = CreateConVar("l4d2_points_mp5", "7", "How many points the mp5 costs", FCVAR_PLUGIN);
	PointsAK = CreateConVar("l4d2_points_ak", "12", "How many points the ak47 costs", FCVAR_PLUGIN);
	PointsSCAR = CreateConVar("l4d2_points_scar", "12", "How many points the scar costs", FCVAR_PLUGIN);
	PointsSG = CreateConVar("l4d2_points_sg", "12", "How many points the sg552 costs", FCVAR_PLUGIN);
	PointsMilitary = CreateConVar("l4d2_points_military_sniper", "14", "How many points the military sniper costs", FCVAR_PLUGIN);
	PointsAWP = CreateConVar("l4d2_points_awp", "15", "How many points the awp costs", FCVAR_PLUGIN);
	PointsScout = CreateConVar("l4d2_points_scout", "10", "How many points the scout sniper costs", FCVAR_PLUGIN);
	PointsSpas = CreateConVar("l4d2_points_spas", "10", "How many points the spas shotgun costs", FCVAR_PLUGIN);
	PointsChrome = CreateConVar("l4d2_points_chrome", "7", "How many points the chrome shotgun costs", FCVAR_PLUGIN);
	PointsGL = CreateConVar("l4d2_points_grenade", "15", "How many points the grenade launcher costs", FCVAR_PLUGIN);
	PointsM60 = CreateConVar("l4d2_points_m60", "50", "How many points the m60 costs", FCVAR_PLUGIN);
	PointsOxy = CreateConVar("l4d2_points_oxygen", "2", "How many points the oxgen tank costs", FCVAR_PLUGIN);
	PointsGnome = CreateConVar("l4d2_points_gnome", "8", "How many points the gnome costs", FCVAR_PLUGIN);
	PointsCola = CreateConVar("l4d2_points_cola", "8", "How many points cola bottles costs", FCVAR_PLUGIN);
	PointsFireWorks = CreateConVar("l4d2_points_fireworks", "2", "How many points the fireworks crate costs", FCVAR_PLUGIN);
	PointsBat = CreateConVar("l4d2_points_bat", "4", "How many points the baseball bat costs", FCVAR_PLUGIN);
	PointsMachete = CreateConVar("l4d2_points_machete", "6", "How many points the machete costs", FCVAR_PLUGIN);
	PointsKatana = CreateConVar("l4d2_points_katana", "6", "How many points the katana costs", FCVAR_PLUGIN);
	PointsKnife = CreateConVar("l4d2_points_knife", "6", "How many points the knife costs", FCVAR_PLUGIN);
	PointsShield = CreateConVar("l4d2_points_shield", "6", "How many points the shield costs", FCVAR_PLUGIN);
	PointsTonfa = CreateConVar("l4d2_points_tonfa", "4", "How many points the tonfa costs", FCVAR_PLUGIN);
	PointsFireaxe = CreateConVar("l4d2_points_fireaxe", "4", "How many points the fireaxe costs", FCVAR_PLUGIN);
	PointsGuitar = CreateConVar("l4d2_points_guitar", "4", "How many points the guitar costs", FCVAR_PLUGIN);
	PointsPan = CreateConVar("l4d2_points_pan", "4", "How many points the frying pan costs", FCVAR_PLUGIN);
	PointsCBat = CreateConVar("l4d2_points_cricketbat", "4", "How many points the cricket bat costs", FCVAR_PLUGIN);
	PointsCrow = CreateConVar("l4d2_points_crowbar", "4", "How many points the crowbar costs", FCVAR_PLUGIN);
	PointsClub = CreateConVar("l4d2_points_golfclub", "6", "How many points the golf club costs", FCVAR_PLUGIN);
	PointsSaw = CreateConVar("l4d2_points_chainsaw", "10", "How many points the chainsaw costs", FCVAR_PLUGIN);
	PointsPipe = CreateConVar("l4d2_points_pipe", "8", "How many points the pipe bomb costs", FCVAR_PLUGIN);
	PointsMolly = CreateConVar("l4d2_points_molotov", "8", "How many points the molotov costs", FCVAR_PLUGIN);
	PointsBile = CreateConVar("l4d2_points_bile", "8", "How many points the bile jar costs", FCVAR_PLUGIN);
	PointsKit = CreateConVar("l4d2_points_kit", "20", "How many points the health kit costs", FCVAR_PLUGIN);
	PointsDefib = CreateConVar("l4d2_points_defib", "20", "How many points the defib costs", FCVAR_PLUGIN);
	PointsAdren = CreateConVar("l4d2_points_adrenaline", "10", "How many points the adrenaline costs", FCVAR_PLUGIN);
	PointsPills = CreateConVar("l4d2_points_pills", "10", "How many points the pills costs", FCVAR_PLUGIN);
	PointsEAmmo = CreateConVar("l4d2_points_explosive_ammo", "10", "How many points the explosive ammo costs", FCVAR_PLUGIN);
	PointsIAmmo = CreateConVar("l4d2_points_incendiary_ammo", "10", "How many points the incendiary ammo costs", FCVAR_PLUGIN);
	PointsEAmmoPack = CreateConVar("l4d2_points_explosive_ammo_pack", "15", "How many points the explosive ammo pack costs", FCVAR_PLUGIN);
	PointsIAmmoPack = CreateConVar("l4d2_points_incendiary_ammo_pack", "15", "How many points the incendiary ammo pack costs", FCVAR_PLUGIN);
	PointsLSight = CreateConVar("l4d2_points_laser", "10", "How many points the laser sight costs", FCVAR_PLUGIN);
	PointsHeal = CreateConVar("l4d2_points_survivor_heal", "25", "How many points a complete heal costs", FCVAR_PLUGIN);
	PointsRefill = CreateConVar("l4d2_points_refill", "8", "How many points an ammo refill costs", FCVAR_PLUGIN);
	SValueKillingSpree = CreateConVar("l4d2_points_cikill_value", "2", "How many points does killing a certain amount of infected earn", FCVAR_PLUGIN);
	SNumberKill = CreateConVar("l4d2_points_cikills", "25", "How many kills you need to earn a killing spree bounty", FCVAR_PLUGIN);
	SValueHeadSpree = CreateConVar("l4d2_points_headshots_value", "4", "How many points does killing a certain amount of infected with headshots earn", FCVAR_PLUGIN);
	SNumberHead = CreateConVar("l4d2_points_headshots", "20", "How many kills you need to earn a head hunter bonus", FCVAR_PLUGIN);
	SSIKill = CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn", FCVAR_PLUGIN);
	STankKill = CreateConVar("l4d2_points_tankkill", "2", "How many points does killing a tank earn", FCVAR_PLUGIN);
	SWitchKill = CreateConVar("l4d2_points_witchkill", "4", "How many points does killing a witch earn", FCVAR_PLUGIN);
	SWitchCrown = CreateConVar("l4d2_points_witchcrown", "2", "How many points does crowning a witch earn", FCVAR_PLUGIN);
	SHeal = CreateConVar("l4d2_points_heal", "5", "How many points does healing a team mate earn", FCVAR_PLUGIN);
	SHealWarning = CreateConVar("l4d2_points_heal_warning", "1", "How many points does healing a team mate who did not need healing earn", FCVAR_PLUGIN);
	SProtect = CreateConVar("l4d2_points_protect", "1", "How many points does protecting a team mate earn", FCVAR_PLUGIN);
	SRevive = CreateConVar("l4d2_points_revive", "3", "How many points does reviving a team mate earn", FCVAR_PLUGIN);
	SLedge = CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn", FCVAR_PLUGIN);
	SDefib = CreateConVar("l4d2_points_defib_action", "5", "How many points does defibbing a team mate earn", FCVAR_PLUGIN);
	STBurn = CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn", FCVAR_PLUGIN);
	STSolo = CreateConVar("l4d2_points_tanksolo", "8", "How many points does killing a tank single-handedly earn", FCVAR_PLUGIN);
	SWBurn = CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn", FCVAR_PLUGIN);
	STag = CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn", FCVAR_PLUGIN);
	IChoke = CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn", FCVAR_PLUGIN);
	IPounce = CreateConVar("l4d2_points_pounce", "1", "How many points does pouncing a survivor earn", FCVAR_PLUGIN);
	ICarry = CreateConVar("l4d2_points_charge", "2", "How many points does charging a survivor earn", FCVAR_PLUGIN);
	IImpact = CreateConVar("l4d2_points_impact", "1", "How many points does impacting a survivor earn", FCVAR_PLUGIN);
	IRide = CreateConVar("l4d2_points_ride", "2", "How many points does riding a survivor earn", FCVAR_PLUGIN);
	ITag = CreateConVar("l4d2_points_boom", "1", "How many points does booming a survivor earn", FCVAR_PLUGIN);
	IIncap = CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn", FCVAR_PLUGIN);
	IHurt = CreateConVar("l4d2_points_damage", "2", "How many points does doing damage earn", FCVAR_PLUGIN);
	IKill = CreateConVar("l4d2_points_kill", "5", "How many points does killing a survivor earn", FCVAR_PLUGIN);
	PointsSuicide = CreateConVar("l4d2_points_suicide", "4", "How many points does suicide cost", FCVAR_PLUGIN);
	PointsHunter = CreateConVar("l4d2_points_hunter", "4", "How many points does a hunter cost", FCVAR_PLUGIN);
	PointsJockey = CreateConVar("l4d2_points_jockey", "6", "How many points does a jockey cost", FCVAR_PLUGIN);
	PointsSmoker = CreateConVar("l4d2_points_smoker", "4", "How many points does a smoker cost", FCVAR_PLUGIN);
	PointsCharger = CreateConVar("l4d2_points_charger", "6", "How many points does a charger cost", FCVAR_PLUGIN);
	PointsBoomer = CreateConVar("l4d2_points_boomer", "5", "How many points does a boomer cost", FCVAR_PLUGIN);
	PointsSpitter = CreateConVar("l4d2_points_spitter", "6", "How many points does a spitter cost", FCVAR_PLUGIN);
	PointsIHeal = CreateConVar("l4d2_points_infected_heal", "6", "How many points does healing yourself as an infected cost", FCVAR_PLUGIN);
	PointsWitch = CreateConVar("l4d2_points_witch", "20", "How many points does a witch cost", FCVAR_PLUGIN);
	PointsTank = CreateConVar("l4d2_points_tank", "30", "How many points does a tank cost", FCVAR_PLUGIN);
	PointsTankHealMult = CreateConVar("l4d2_points_tank_heal_mult", "3", "How much l4d2_points_infected_heal should be multiplied for tank players", FCVAR_PLUGIN);
	PointsHorde = CreateConVar("l4d2_points_horde", "15", "How many points does a horde cost", FCVAR_PLUGIN);
	PointsMob = CreateConVar("l4d2_points_mob", "10", "How many points does a mob cost", FCVAR_PLUGIN);
	PointsUMob = CreateConVar("l4d2_points_umob", "12", "How many points does an uncommon mob cost", FCVAR_PLUGIN);
	CatRifles = CreateConVar("l4d2_points_cat_rifles", "1", "Enable rifles catergory", FCVAR_PLUGIN);
	CatSMG = CreateConVar("l4d2_points_cat_smg", "1", "Enable smg catergory", FCVAR_PLUGIN);
	CatSnipers = CreateConVar("l4d2_points_cat_snipers", "1", "Enable snipers catergory", FCVAR_PLUGIN);
	CatShotguns = CreateConVar("l4d2_points_cat_shotguns", "1", "Enable shotguns catergory", FCVAR_PLUGIN);
	CatHealth = CreateConVar("l4d2_points_cat_health", "1", "Enable health catergory", FCVAR_PLUGIN);
	CatUpgrades = CreateConVar("l4d2_points_cat_upgrades", "1", "Enable upgrades catergory", FCVAR_PLUGIN);
	CatThrowables = CreateConVar("l4d2_points_cat_throwables", "1", "Enable throwables catergory", FCVAR_PLUGIN);
	CatMisc = CreateConVar("l4d2_points_cat_misc", "1", "Enable misc catergory", FCVAR_PLUGIN);
	CatMelee = CreateConVar("l4d2_points_cat_melee", "1", "Enable melee catergory", FCVAR_PLUGIN);
	CatWeapons = CreateConVar("l4d2_points_cat_weapons", "1", "Enable weapons catergory", FCVAR_PLUGIN);
	RegConsoleCmd("sm_buystuff", BuyMenu, "Open the buy menu (only in-game)");
	RegAdminCmd("sm_listmodules", ListModules, ADMFLAG_GENERIC, "List modules currently loaded to Points System");
	RegConsoleCmd("sm_buy", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_points", ShowPoints, "Show the amount of points you have (only in-game)");
	RegAdminCmd("sm_listmelee", ListMelee, ADMFLAG_GENERIC, "List melee weapons available on this map");
	RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_SLAY, "sm_heal <target>");
	RegAdminCmd("sm_givepoints", Command_Points, ADMFLAG_SLAY, "sm_givepoints <target> [amount]");
	RegAdminCmd("sm_setpoints", Command_SPoints, ADMFLAG_SLAY, "sm_setpoints <target> [amount]");
	RegConsoleCmd("sm_repeatbuy", Command_RBuy, "Repeat your last buy transaction");
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
	SendProp_LifeState = FindSendPropInfo("CTerrorPlayer", "m_lifeState");
	SendProp_IsAlive = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	SendProp_IsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	AutoExecConfig(true, "l4d2_points_system");
	if(!lateload) CreateTimer(0.5, PrecacheGuns);
}

public bool:FilterSurvivors(const String:pattern[], Handle:clients)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			PushArrayCell(clients, i);
		}
	}
	return true;
}

public bool:FilterInfected(const String:pattern[], Handle:clients)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			PushArrayCell(clients, i);
		}
	}
	return true;
}

public Action:PrecacheGuns(Handle:Timer)
{
	new String:map[128];
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

stock DispatchAndRemove(const String:gun[])
{
	new ent = CreateEntityByName(gun);
	if(IsValidEdict(ent))
	{
		DispatchSpawn(ent);
		RemoveEdict(ent);
		return true;
	}
	else return false;
}

public OnAllPluginsLoaded()
{
	//forward
	Call_StartForward(Forward1);
	Call_Finish();
}

public OnConfigsExecuted()
{
	if(bFirstRun)
	{
		for(new i=0;i<=MaxClients;i++)
		{
			points[i] = GetConVarInt(StartPoints);
		}
		bFirstRun = false;
	}
}

public OnMapStart()
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
	GetCurrentMap(MapName, sizeof(MapName));
	CreateTimer(6.0, CheckMelee, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CheckMelee(Handle:Timer)
{
	new mCounter;
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		Format(validmelee[i], sizeof(validmelee[]), "");
	}
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		new entity = CreateEntityByName("weapon_melee");
		DispatchKeyValue(entity, "melee_script_name", meleelist[i]);
		DispatchSpawn(entity);
		decl String:modelname[256];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if(StrContains(modelname, "hunter", false) == -1)
		{
			Format(validmelee[mCounter++], sizeof(validmelee[]), meleelist[i]);
		}
		RemoveEdict(entity);
	}
}

public Action:ListMelee(client, args)
{
	if(args > 0) return;
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		if(strlen(validmelee[i]) > 0) ReplyToCommand(client, validmelee[i]);
	}
}

public Action:ListModules(client, args)
{
	if(args > 0) return Plugin_Handled;
	ReplyToCommand(client, "%s %T", MSGTAG, "Modules", LANG_SERVER);
	new size = GetArraySize(ModulesArray);
	for(new i=0; i<size; i++)
	{
		decl String:buffer[MODULES_SIZE];
		GetArrayString(ModulesArray, i, buffer, MODULES_SIZE);
		if(strlen(buffer) > 0) ReplyToCommand(client, buffer);
	}
	ReplyToCommand(client, "%s %T", MSGTAG, "End...", LANG_SERVER);
	return Plugin_Handled;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("points_system.phrases");
	LoadTranslations("points_system_menus.phrases");
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("%T", "Game Check Fail", LANG_SERVER);
	}
	CreateNative("PS_GetVersion", PS_GetVersion);
	CreateNative("PS_SetPoints", PS_SetPoints);
	CreateNative("PS_SetItem", PS_SetItem);
	CreateNative("PS_SetCost", PS_SetCost);
	CreateNative("PS_SetBought", PS_SetBought);
	CreateNative("PS_SetBoughtCost", PS_SetBoughtCost);
	CreateNative("PS_SetupUMob", PS_SetupUMob);
	CreateNative("PS_GetPoints", PS_GetPoints);
	CreateNative("PS_GetBoughtCost", PS_GetBoughtCost);
	CreateNative("PS_GetCost", PS_GetCost);
	CreateNative("PS_GetItem", PS_GetItem);
	CreateNative("PS_GetBought", PS_GetBought);
	CreateNative("PS_RegisterModule", PS_RegisterModule);
	CreateNative("PS_UnregisterModule", PS_UnregisterModule);
	Forward1 = CreateGlobalForward("OnPSLoaded", ET_Ignore);
	Forward2 = CreateGlobalForward("OnPSUnloaded", ET_Ignore);
	RegPluginLibrary("ps_natives");
	lateload = late;
	return APLRes_Success;
}

public OnPluginEnd()
{
	new Action:result;
	Call_StartForward(Forward2);
	Call_Finish(_:result);
}

public PS_RegisterModule(Handle:plugin, numParams)
{
	new size = GetArraySize(ModulesArray);
	decl String:test[MODULES_SIZE];
	GetNativeString(1, test, MODULES_SIZE);
	for(new i; i<size; i++)
	{
		decl String:buffer[MODULES_SIZE];
		GetArrayString(ModulesArray, i, buffer, MODULES_SIZE);
		if(StrEqual(buffer, test))
		{
			return true;
		}
	}
	PushArrayString(ModulesArray, test);
	return false;
}

public PS_UnregisterModule(Handle:plugin, numParams)
{
	new size = GetArraySize(ModulesArray);
	new String:container[MODULES_SIZE];
	GetNativeString(1, container, MODULES_SIZE);
	for(new i; i<size; i++)
	{
		decl String:buffer[MODULES_SIZE];
		GetArrayString(ModulesArray, i, buffer, MODULES_SIZE);
		if(StrEqual(buffer, container))
		{
			RemoveFromArray(ModulesArray, i);
			return true;
		}
	}
	return false;
}

public PS_GetVersion(Handle:plugin, numParams)
{
	return _:version;
}

public PS_SetPoints(Handle:plugin, numParams)
{
	points[GetNativeCell(1)] = GetNativeCell(2);
}

public PS_SetItem(Handle:plugin, numParams)
{
	GetNativeString(2, item[GetNativeCell(1)], sizeof(item[]));
}

public PS_SetCost(Handle:plugin, numParams)
{
	cost[GetNativeCell(1)] = GetNativeCell(2);
}

public PS_SetBought(Handle:plugin, numParams)
{
	GetNativeString(2, bought[GetNativeCell(1)], sizeof(bought[]));
}

public PS_SetBoughtCost(Handle:plugin, numParams)
{
	boughtcost[GetNativeCell(1)] = GetNativeCell(2);
}

public PS_SetupUMob(Handle:plugin, numParams)
{
	ucommonleft = GetNativeCell(1);
}

public PS_GetPoints(Handle:plugin, numParams)
{
	return points[GetNativeCell(1)];
}

public PS_GetCost(Handle:plugin, numParams)
{
	return cost[GetNativeCell(1)];
}

public PS_GetBoughtCost(Handle:plugin, numParams)
{
	return boughtcost[GetNativeCell(1)];
}

public PS_GetItem(Handle:plugin, numParams)
{
	SetNativeString(2, item[GetNativeCell(1)], GetNativeCell(3));
}

public PS_GetBought(Handle:plugin, numParams)
{
	SetNativeString(2, bought[GetNativeCell(1)], GetNativeCell(3));
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		new userid = GetClientUserId(client);
		CreateTimer(5.0, Check, userid);
	}
}

public Action:Check(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client == 0 || !IsClientConnected(client))
	{
		points[client] = GetConVarInt(StartPoints);
		killcount[client] = 0;
		wassmoker[client] = 0;
		hurtcount[client] = 0;
		protectcount[client] = 0;
		headshotcount[client] = 0;
	}
}

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(Modes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

stock bool:IsAllowedReset()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(ResetPoints, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

public Action:Event_REnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(IsAllowedReset())
	{
		new startval = GetConVarInt(StartPoints);
		for (new i=1; i<=MaxClients; i++)
		{
			points[i] = startval;
			hurtcount[i] = 0;
			protectcount[i] = 0;
			headshotcount[i] = 0;
			killcount[i] = 0;
			wassmoker[i] = 0;
		}    
	}
	tanksspawned = 0;
	witchsspawned = 0;
}

public Action:Event_RStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");
	if(IsAllowedReset())
	{
		new startval = GetConVarInt(StartPoints);
		for (new i=1; i<=MaxClients; i++)
		{
			points[i] = startval;
			hurtcount[i] = 0;
			protectcount[i] = 0;
			headshotcount[i] = 0;
			killcount[i] = 0;
			wassmoker[i] = 0;
		}    
	}
	tanksspawned = 0;
	witchsspawned = 0;
}

public Action:Event_Finale(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new String:gamemode[40];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(StrContains(gamemode, "versus", false) != -1) return;
	new startval = GetConVarInt(StartPoints);
	for (new i=1; i<=MaxClients; i++)
	{
		points[i] = startval;
		killcount[i] = 0;
		hurtcount[i] = 0;
		protectcount[i] = 0;
		headshotcount[i] = 0;
		wassmoker[i] = 0;
	}
}

public Action:Event_Kill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:headshot = GetEventBool(event, "headshot");
	ATTACKER
	ACHECK2
	{
		if(headshot) headshotcount[attacker]++;	
		new headpoints = GetConVarInt(SValueHeadSpree);
		new heads = GetConVarInt(SNumberHead);
		
		if(headshotcount[attacker] == heads && headpoints > 0)
		{
			points[attacker] += headpoints;
			headshotcount[attacker] -= heads;
			if(GetConVarBool(Notifications)) CPrintToChat(attacker, "%s %t", MSGTAG, "Head Hunter", headpoints);
		}
		killcount[attacker]++;
		
		new spreepoints = GetConVarInt(SValueKillingSpree);
		new kills = GetConVarInt(SNumberKill);
		if(killcount[attacker] == kills && spreepoints > 0)
		{
			points[attacker] += spreepoints;
			killcount[attacker] -= kills;
			if(GetConVarBool(Notifications)) CPrintToChat(attacker, "%s %t", MSGTAG, "Killing Spree", spreepoints);
		}
	}
}

public Action:Event_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	ACHECK3
	{
		new incappoints = GetConVarInt(IIncap);
		if(incappoints <= 0) return;
		points[attacker] += incappoints;
		if(GetConVarBool(Notifications)) PrintToChat(attacker, "%s %T", MSGTAG, "Incapped Survivor", LANG_SERVER, incappoints);
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	CLIENT
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		new bool:notify = GetConVarBool(Notifications);
		if(GetClientTeam(attacker) == 2)
		{
			new sipoints = GetConVarInt(SSIKill);
			if(sipoints < 1 || GetClientTeam(client) == 2 || GetEntProp(client, Prop_Send, "m_zombieClass") == 8) return;
			new bool:headshot = GetEventBool(event, "headshot");
			if(headshot) headshotcount[attacker]++;
			new headsneeded = GetConVarInt(SNumberHead);
			new headpoints = GetConVarInt(SValueHeadSpree);
			if(headshotcount[attacker] == headsneeded && headpoints > 0)
			{
				points[attacker] += headpoints;
				headshotcount[attacker] -= headsneeded;
				if(notify) CPrintToChat(attacker, "%s %t", MSGTAG, "Head Hunter", headpoints);
			}
			points[attacker] += sipoints;
			if(notify) CPrintToChat(attacker, "%s %t", MSGTAG, "Killed SI", sipoints);
		}
		else if(GetClientTeam(attacker) == 3)
		{
			new killpoints = GetConVarInt(IKill);
			if(killpoints < 1 || GetClientTeam(client) == 3) return;
			points[attacker] += killpoints;
			if(notify) PrintToChat(attacker, "%s %T", MSGTAG, "Killed Survivor", LANG_SERVER, killpoints);
		}
	}
}

public Action:Event_TankDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new solo = GetEventBool(event, "solo");
	ATTACKER
	ACHECK2
	{
		new solopoints = GetConVarInt(STSolo);
		if(solo && solopoints > 0)
		{
			points[attacker] += solopoints;
			if(GetConVarBool(Notifications)) CPrintToChat(attacker, "%s %t", MSGTAG, "TANK SOLO", solopoints);
		}
	}
	new tankpoints = GetConVarInt(STankKill);
	for (new i=1; i<=MaxClients; i++)
	{
		if(i && IsClientInGame(i)&& !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && tankpoints > 0 && GetConVarInt(Enable) == 1 && IsAllowedGameMode())
		{
			points[i] += tankpoints;
			if(GetConVarBool(Notifications)) CPrintToChat(i, "%s %t", MSGTAG, "Killed Tank", tankpoints);
		}
	}
	tankburning[attacker] = 0;
	tankbiled[attacker] = 0;
}

public Action:Event_WitchDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new oneshot = GetEventBool(event, "oneshot");
	CLIENT
	CCHECK2
	{
		new witchpoints = GetConVarInt(SWitchKill);
		if(witchpoints <= 0) return;
		new notify = GetConVarBool(Notifications);
		points[client] += witchpoints;
		new crownpoints = GetConVarInt(SWitchCrown);
		if(oneshot && crownpoints > 0)
		{
			points[client] += crownpoints;
			if(notify) CPrintToChat(client, "%s %t", MSGTAG, "Crowned Witch", crownpoints);
		}
		if(notify) CPrintToChat(client, "%s %t", MSGTAG, "Killed Witch", witchpoints);
	}
	witchburning[client] = 0;
}

public Action:Event_Heal(Handle:event, const String:name[], bool:dontBroadcast)
{
	new restored = GetEventInt(event, "health_restored");
	CLIENT
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	if(subject > 0 && client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(client == subject) return;
		new notify = GetConVarBool(Notifications);
		if(restored > 39)
		{
			new healpoints = GetConVarInt(SHeal);
			if(healpoints <= 0) return;
			points[client] += healpoints;
			if(notify) CPrintToChat(client, "%s %t", MSGTAG, "Team Heal", healpoints);
		}
		else
		{
			new healpoints = GetConVarInt(SHealWarning);
			if(healpoints <= 0) return;
			points[client] += healpoints;
			if(notify) CPrintToChat(client, "%s %t", MSGTAG, "Team Heal Warning", healpoints);
		}
	}
}

public Action:Event_Protect(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	new award = GetEventInt(event, "award");
	if(client > 0 && award == 67 && GetConVarInt(SProtect) > 0 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && !IsFakeClient(client) && IsAllowedGameMode())
	{
		new protectpoints = GetConVarInt(SProtect);
		if(protectpoints <= 0) return;
		protectcount[client]++;
		if(protectcount[client] == 6)
		{
			points[client] += protectpoints;
			protectcount[client] = 0;
			if(GetConVarBool(Notifications)) CPrintToChat(client, "%s %t", MSGTAG, "Protect", protectpoints);
		}
	}
}

public Action:Event_Revive(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:ledge = GetEventBool(event, "ledge_hang");
	CLIENT
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	CCHECK2
	{
		if(subject == client) return;
		new revivepoints = GetConVarInt(SRevive);
		new ledgepoints = GetConVarInt(SLedge);
		new notify = GetConVarBool(Notifications);
		if(!ledge && revivepoints > 0)
		{
			points[client] += revivepoints;
			if(notify) CPrintToChat(client, "%s %t", MSGTAG, "Revive", revivepoints);
		}
		else if(ledge && ledgepoints > 0)
		{
			points[client] += ledgepoints;
			if(notify) CPrintToChat(client, "%s %t", MSGTAG, "Ledge Revive", ledgepoints);
		}
	}
}

public Action:Event_Shock(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK2
	{
		new defibpoints = GetConVarInt(SDefib);
		if(defibpoints <= 0) return;
		points[client] += defibpoints;
		if(GetConVarBool(Notifications)) CPrintToChat(client, "%s %t", MSGTAG, "Defib", defibpoints);
	}
}	

public Action:Event_Choke(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		new chokepoints = GetConVarInt(IChoke);
		if(chokepoints <= 0) return;
		points[client] += chokepoints;
		if(GetConVarBool(Notifications)) PrintToChat(client, "%s %T", MSGTAG, "Smoke", LANG_SERVER, chokepoints);
	}
}

public Action:Event_Boom(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	CLIENT
	if(attacker > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		new team = GetClientTeam(attacker);
		new itag = GetConVarInt(ITag);
		new stag = GetConVarInt(STag);
		if(team == 3 && itag > 0)
		{
			points[attacker] += itag;
			if(GetClientTeam(client) == 2 && GetConVarBool(Notifications)) PrintToChat(attacker, "%s %T", MSGTAG, "Boom", LANG_SERVER, itag);
		}
		else if(team == 2 && stag > 0)
		{
			points[attacker] += stag;
			if(GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && GetConVarBool(Notifications)) PrintToChat(attacker, "%s %T", MSGTAG, "Biled", LANG_SERVER, stag);
			tankbiled[attacker] = 1;
		}
	}
}

public Action:Event_Pounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		new pouncepoints = GetConVarInt(IPounce);
		if(pouncepoints <= 0) return;
		points[client] += pouncepoints;
		if(GetConVarBool(Notifications)) PrintToChat(client, "%s %T", MSGTAG, "Pounce", LANG_SERVER, pouncepoints);
	}
}

public Action:Event_Ride(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		new ridepoints = GetConVarInt(IRide);
		if(ridepoints <= 0) return;
		points[client] += ridepoints;
		if(GetConVarBool(Notifications)) PrintToChat(client, "%s %T", MSGTAG, "Jockey Ride", LANG_SERVER, ridepoints);
	}
}

public Action:Event_Carry(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		new carrypoints = GetConVarInt(ICarry);
		if(carrypoints <= 0) return;
		points[client] += carrypoints;
		if(GetConVarBool(Notifications)) PrintToChat(client, "%s %T", MSGTAG, "Charge", LANG_SERVER, carrypoints);
	}
}

public Action:Event_Impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		new impactpoints = GetConVarInt(IImpact);
		if(impactpoints <= 0) return;
		points[client] += impactpoints;
		if(GetConVarBool(Notifications)) PrintToChat(client, "%s %T", MSGTAG, "Charge Collateral", LANG_SERVER, impactpoints);
	}
}

public Action:Event_Burn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:victim[30];
	GetEventString(event, "victimname", victim, sizeof(victim));
	CLIENT
	CCHECK2
	{
		new tankpoints = GetConVarInt(STBurn);
		new witchpoints = GetConVarInt(SWBurn);
		if(StrEqual(victim, "Tank", false) && tankburning[client] == 0 && tankpoints > 0)
		{
			points[client] += tankpoints;
			if(GetConVarBool(Notifications)) CPrintToChat(client, "%s %t", MSGTAG, "Burn Tank", tankpoints);
			tankburning[client] = 1;
		}
		else if(StrEqual(victim, "Witch", false) && witchburning[client] == 0 && witchpoints > 0)
		{
			points[client] += witchpoints;
			if(GetConVarBool(Notifications)) CPrintToChat(client, "%s %t", MSGTAG, "Burn Witch", witchpoints);
			witchburning[client] = 1;
		}
	}
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	ATTACKER
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1 && GetConVarInt(IHurt) > 0)
	{
		hurtcount[attacker]++;
		new type = GetEventInt(event, "type");
		//PrintToChat(attacker, "Damagetype: %d", type);
		if( (type == 263168 || type == 265216) && hurtcount[attacker] >= 8 )
		{
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "%s %T", MSGTAG, "Spit Damage", LANG_SERVER, GetConVarInt(IHurt));
			points[attacker] += GetConVarInt(IHurt);
			hurtcount[attacker] -= 8;
		} 
		/*else if(GetEntProp(attacker, Prop_Send, "m_zombieClass") == 1 && !IsPlayerAlive(attacker))
		{
			if(FindConVar("l4d_cloud_damage_enabled") != INVALID_HANDLE)
			{
				if(GetConVarInt(FindConVar("l4d_cloud_damage_enabled")) == 1 && hurtcount[attacker] >= 8 && GetEntProp(attacker, Prop_Send, "m_isGhost") != 1)
				{
					if(GetConVarBool(Notifications)) PrintToChat(attacker, "%s %T", MSGTAG, "Cloud Damage", LANG_SERVER, GetConVarInt(IHurt));
					points[attacker] += GetConVarInt(IHurt);
					hurtcount[attacker] -= 10;
				}
			}	
		}*/
		else if(type != 263168 && type != 265216 && hurtcount[attacker] >= 3)
		{
			if(GetConVarBool(Notifications)) PrintToChat(attacker, "%s %T", MSGTAG, "Damage", LANG_SERVER, GetConVarInt(IHurt));
			points[attacker] += GetConVarInt(IHurt);
			hurtcount[attacker] -= 3;
		} 
	}
}

public Action:BuyMenu(client,args)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		BuildBuyMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:ShowPoints(client,args)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1 && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) > 1 && args == 0)
	{
		ReplyToCommand(client, "%s %t", MSGTAG, "Your Points", points[client]);
	}
	return Plugin_Handled;
}

public Action:Command_RBuy(client, args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "%T", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;
	}
	else if (args == 0 && IsClientInGame(client))
	{
		RemoveFlags();
		if(points[client] < cost[client])
		{
			ReplyToCommand(client, "%s %T", MSGTAG, "Insufficient Funds", client);
			AddFlags();
			return Plugin_Handled;
		}
		if(cost[client] == -1)
		{
			ReplyToCommand(client, "%s %T", MSGTAG, "Item Disabled", client);
			AddFlags();
			return Plugin_Handled;
		}
		points[client] -= cost[client];
		if(StrEqual(item[client], "suicide", false))
		{
			ForcePlayerSuicide(client);
		}
		else FakeClientCommand(client, "%s", item[client]);
		//do additional actions for certain items
		if(StrEqual(item[client], "z_spawn mob", false))
		{
			ucommonleft += GetConVarInt(FindConVar("z_common_limit"));
		}
		else if(StrEqual(item[client], "give ammo", false))
		{
			new wep = GetPlayerWeaponSlot(client, 0);
			if(wep == -1)
			{
				ReplyToCommand(client, "%s %T", MSGTAG, "Primary Warning", client);
				points[client] += cost[client]; //refund
				AddFlags();
				return Plugin_Handled;
			}
			new m60ammo = 150;
			new nadeammo = 30;
			new Handle:cvar = FindConVar("l4d2_guncontrol_m60ammo");
			new Handle:cvar2 = FindConVar("ammo_grenadelauncher_max");
			if(cvar != INVALID_HANDLE)
			{
				m60ammo = GetConVarInt(cvar);
				CloseHandle(cvar);
			}
			if(cvar2 != INVALID_HANDLE)
			{
				nadeammo = GetConVarInt(cvar2);
				CloseHandle(cvar2);
			}
			new String:class[40];
			GetEdictClassname(wep, class, sizeof(class));
			if(StrEqual(class, "weapon_rifle_m60", false)) SetEntProp(wep, Prop_Data, "m_iClip1", m60ammo, 1);
			else if(StrEqual(class, "weapon_grenade_launcher", false))
			{
				new offset = FindDataMapOffs(client, "m_iAmmo");
				SetEntData(client, offset+68, nadeammo);
			}
		}
		AddFlags();
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_repeatbuy", client);
		return Plugin_Handled;
	}
}

public Action:Command_Heal(client, args)
{
	if(args == 0)
	{
		RemoveFlags();
		FakeClientCommand(client, "give health");
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		AddFlags();
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
			ShowActivity2(client, MSGTAG2, "%t", "Give Health", target_name);
			
			for (new i = 0; i < target_count; i++)
			{
				RemoveFlags();
				new targetclient = target_list[i];
				FakeClientCommand(targetclient, "give health");
				SetEntPropFloat(targetclient, Prop_Send, "m_healthBuffer", 0.0);
				AddFlags();
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_heal", client);
		return Plugin_Handled;
	}
}

public Action:Command_Points(client, args)
{
	if(args == 2)
	{
		decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
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
				COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			ShowActivity2(client, MSGTAG2, "%t", "Give Points", amount, target_name);
			
			for (new i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				points[targetclient] += amount;
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_givepoints", client);
		return Plugin_Handled;
	}
}

public Action:Command_SPoints(client, args)
{
	if(args == 2)
	{
		decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
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
				COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			ShowActivity2(client, MSGTAG2, "%t", "Set Points", target_name, amount);
		
			for (new i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				points[targetclient] = amount;
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_setpoints", client);
		return Plugin_Handled;
	}
}

RemoveFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flagszspawn & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic & ~FCVAR_CHEAT);
}

AddFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flagszspawn|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic|FCVAR_CHEAT);
}

BuildBuyMenu(client)
{
	if(GetClientTeam(client) == 2)
	{
		decl String:title[40], String:weapons[40], String:upgrades[40], String:health[40];
		new Handle:menu = CreateMenu(TopMenu);
		if(GetConVarInt(CatWeapons) == 1)
		{
			Format(weapons, sizeof(weapons), "%T", "Weapons", client);
			AddMenuItem(menu, "g_WeaponsMenu", weapons);
		}
		if(GetConVarInt(CatUpgrades) == 1)
		{
			Format(upgrades, sizeof(upgrades), "%T", "Upgrades", client);
			AddMenuItem(menu, "g_UpgradesMenu", upgrades);
		}
		if(GetConVarInt(CatHealth) == 1)
		{
			Format(health, sizeof(health), "%T", "Health", client);
			AddMenuItem(menu, "g_HealthMenu", health);
		}
		Format(title, sizeof(title), "%T", "Points Left", client, points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if(GetClientTeam(client) == 3)
	{
		decl String:title[40], String:boomer[40], String:spitter[40], String:smoker[40], String:hunter[40], String:charger[40], String:jockey[40], String:tank[40], String:witch[40], String:witch_bride[40], String:heal[40], String:suicide[40], String:horde[40], String:mob[40], String:umob[40];
		new Handle:menu = CreateMenu(InfectedMenu);
		if(GetConVarInt(PointsIHeal) > -1)
		{
			Format(heal, sizeof(heal), "%T", "Heal", LANG_SERVER);
			AddMenuItem(menu, "heal", heal);
		}
		if(GetConVarInt(PointsSuicide) > -1)
		{
			Format(suicide, sizeof(suicide), "%T", "Suicide", LANG_SERVER);
			AddMenuItem(menu, "suicide", suicide);
		}
		if(GetConVarInt(PointsBoomer) > -1)
		{
			Format(boomer, sizeof(boomer), "%T", "Boomer", LANG_SERVER);
			AddMenuItem(menu, "boomer", boomer);
		}
		if(GetConVarInt(PointsSpitter) > -1)
		{
			Format(spitter, sizeof(spitter), "%T", "Spitter", LANG_SERVER);
			AddMenuItem(menu, "spitter", spitter);
		}
		if(GetConVarInt(PointsSmoker) > -1)
		{
			Format(smoker, sizeof(smoker), "%T", "Smoker", LANG_SERVER);
			AddMenuItem(menu, "smoker", smoker);
		}
		if(GetConVarInt(PointsHunter) > -1)
		{
			Format(hunter, sizeof(hunter), "%T", "Hunter", LANG_SERVER);
			AddMenuItem(menu, "hunter", hunter);
		}
		if(GetConVarInt(PointsCharger) > -1)
		{
			Format(charger, sizeof(charger), "%T", "Charger", LANG_SERVER);
			AddMenuItem(menu, "charger", charger);
		}
		if(GetConVarInt(PointsJockey) > -1)
		{
			Format(jockey, sizeof(jockey), "%T", "Jockey", LANG_SERVER);
			AddMenuItem(menu, "jockey", jockey);
		}
		if(GetConVarInt(PointsTank) > -1)
		{
			Format(tank, sizeof(tank), "%T", "Tank", LANG_SERVER);
			AddMenuItem(menu, "tank", tank);
		}
		if(StrEqual(MapName, "c6m1_riverbank", false) && GetConVarInt(PointsWitch) > -1)
		{
			Format(witch_bride, sizeof(witch_bride), "%T", "Witch Bride", LANG_SERVER);
			AddMenuItem(menu, "witch_bride", witch_bride);
		}
		else if(GetConVarInt(PointsWitch) > -1)
		{
			Format(witch, sizeof(witch), "%T", "Witch", LANG_SERVER);
			AddMenuItem(menu, "witch", witch);
		}
		if(GetConVarInt(PointsHorde) > -1)
		{
			Format(horde, sizeof(horde), "%T", "Horde", LANG_SERVER);
			AddMenuItem(menu, "horde", horde);
		}
		if(GetConVarInt(PointsMob) > -1)
		{
			Format(mob, sizeof(mob), "%T", "Mob", LANG_SERVER);
			AddMenuItem(menu, "mob", mob);
		}
		if(GetConVarInt(PointsUMob) > -1)
		{
			Format(umob, sizeof(umob), "%T", "Uncommon Mob", LANG_SERVER);
			AddMenuItem(menu, "uncommon_mob", umob);
		}
		Format(title, sizeof(title), "%T", "Points Left", LANG_SERVER, points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

BuildWeaponsMenu(client)
{
	decl String:melee[40], String:rifles[40], String:shotguns[40], String:smg[40], String:snipers[40], String:misc[40], String:title[40], String:throwables[40];
	new Handle:menu = CreateMenu(MenuHandler);
	SetMenuExitBackButton(menu, true);
	if(GetConVarInt(CatMelee) == 1)
	{
		Format(melee, sizeof(melee), "%T", "Melee", client);
		AddMenuItem(menu, "g_MeleeMenu", melee);
	}
	if(GetConVarInt(CatSnipers) == 1)
	{
		Format(snipers, sizeof(snipers), "%T", "Snipers", client);
		AddMenuItem(menu, "g_SnipersMenu", snipers);
	}
	if(GetConVarInt(CatRifles) == 1)
	{
		Format(rifles, sizeof(rifles), "%T", "Rifles", client);
		AddMenuItem(menu, "g_RiflesMenu", rifles);
	}
	if(GetConVarInt(CatShotguns) == 1)
	{
		Format(shotguns, sizeof(shotguns), "%T", "Shotguns", client);
		AddMenuItem(menu, "g_ShotgunsMenu", shotguns);
	}
	if(GetConVarInt(CatSMG) == 1)
	{
		Format(smg, sizeof(smg), "%T", "SMGs", client);
		AddMenuItem(menu, "g_SMGMenu", smg);
	}
	if(GetConVarInt(CatThrowables) == 1)
	{
		Format(throwables, sizeof(throwables), "%T", "Throwables", client);
		AddMenuItem(menu, "g_ThrowablesMenu", throwables);
	}
	if(GetConVarInt(CatMisc) == 1)
	{
		Format(misc, sizeof(misc), "%T", "Misc", client);
		AddMenuItem(menu, "g_MiscMenu", misc);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
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
		if(i == 0 && GetConVarInt(PointsCBat) < 0)
		{
			continue;
		}
		else if(i == 1 && GetConVarInt(PointsCrow) < 0)
		{
			continue;
		}
		else if(i == 2 && GetConVarInt(PointsBat) < 0)
		{
			continue;
		}
		else if(i == 3 && GetConVarInt(PointsGuitar) < 0)
		{
			continue;
		}
		else if(i == 4 && GetConVarInt(PointsFireaxe) < 0)
		{
			continue;
		}
		else if(i == 5 && GetConVarInt(PointsKatana) < 0)
		{
			continue;
		}
		else if(i == 6 && GetConVarInt(PointsKnife) < 0)
		{
			continue;
		}
		else if(i == 7 && GetConVarInt(PointsTonfa) < 0)
		{
			continue;
		}
		else if(i == 8 && GetConVarInt(PointsClub) < 0)
		{
			continue;
		}
		else if(i == 9 && GetConVarInt(PointsMachete) < 0)
		{
			continue;
		}
		else if(i == 10 && GetConVarInt(PointsPan) < 0)
		{
			continue;
		}
		else if(i == 11 && GetConVarInt(PointsShield) < 0)
		{
			continue;
		}
		Format(container, sizeof(container), "%T", validmelee[i], client);
		AddMenuItem(menu, validmelee[i], container);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildSniperMenu(client)
{
	decl String:hunting_rifle[40], String:title[40], String:sniper_military[64], String:sniper_scout[40], String:sniper_awp[40];
	new Handle:menu = CreateMenu(MenuHandler_Snipers);
	if(GetConVarInt(PointsHunting) > -1)
	{
		Format(hunting_rifle, sizeof(hunting_rifle), "%T", "Hunting Rifle", client);
		AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle);
	}
	if(GetConVarInt(PointsMilitary) > -1)
	{
		Format(sniper_military, sizeof(sniper_military), "%T", "Military Sniper", client);
		AddMenuItem(menu, "weapon_sniper_military", sniper_military);
	}
	if(GetConVarInt(PointsAWP) > -1)
	{
		Format(sniper_awp, sizeof(sniper_awp), "%T", "AWP", client);
		AddMenuItem(menu, "weapon_sniper_awp", sniper_awp);
	}
	if(GetConVarInt(PointsScout) > -1)
	{
		Format(sniper_scout, sizeof(sniper_scout), "%T", "Scout Sniper", client);
		AddMenuItem(menu, "weapon_sniper_scout", sniper_scout);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildRiflesMenu(client)
{
	decl String:rifle[40], String:title[40], String:rifle_desert[40], String:rifle_ak47[40], String:rifle_sg552[40], String:rifle_m60[40];
	new Handle:menu = CreateMenu(MenuHandler_Rifles);
	if(GetConVarInt(PointsM60) > -1)
	{
		Format(rifle_m60, sizeof(rifle_m60), "%T", "M60", client);
		AddMenuItem(menu, "weapon_rifle_m60", rifle_m60);
	}
	if(GetConVarInt(PointsM16) > -1)
	{
		Format(rifle, sizeof(rifle), "%T", "M16", client);
		AddMenuItem(menu, "weapon_rifle", rifle);
	}
	if(GetConVarInt(PointsSCAR) > -1)
	{
		Format(rifle_desert, sizeof(rifle_desert), "%T", "SCAR", client);
		AddMenuItem(menu, "weapon_rifle_desert", rifle_desert);
	}
	if(GetConVarInt(PointsAK) > -1)
	{
		Format(rifle_ak47, sizeof(rifle_ak47), "%T", "AK-47", client);
		AddMenuItem(menu, "weapon_rifle_ak47", rifle_ak47);
	}
	if(GetConVarInt(PointsSG) > -1)
	{
		Format(rifle_sg552, sizeof(rifle_sg552), "%T", "SG552", client);
		AddMenuItem(menu, "weapon_rifle_sg552", rifle_sg552);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildShotgunMenu(client)
{
	decl String:autoshotgun[40], String:shotgun_chrome[40], String:shotgun_spas[40], String:pumpshotgun[40], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Shotguns);
	if(GetConVarInt(PointsAuto) > -1)
	{
		Format(autoshotgun, sizeof(autoshotgun), "%T", "Auto Shotgun", client);
		AddMenuItem(menu, "weapon_autoshotgun", autoshotgun);
	}
	if(GetConVarInt(PointsChrome) > -1)
	{
		Format(shotgun_chrome, sizeof(shotgun_chrome), "%T", "Chrome Shotgun", client);
		AddMenuItem(menu, "weapon_shotgun_chrome", shotgun_chrome);
	}
	if(GetConVarInt(PointsSpas) > -1)
	{
		Format(shotgun_spas, sizeof(shotgun_spas), "%T", "Spas Shotgun", client);
		AddMenuItem(menu, "weapon_shotgun_spas", shotgun_spas);
	}
	if(GetConVarInt(PointsPump) > -1)
	{
		Format(pumpshotgun, sizeof(pumpshotgun), "%T", "Pump Shotgun", client);
		AddMenuItem(menu, "weapon_pumpshotgun", pumpshotgun);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildSMGMenu(client)
{
	decl String:smg[40], String:title[40], String:smg_silenced[40], String:smg_mp5[40];
	new Handle:menu = CreateMenu(MenuHandler_SMG);
	if(GetConVarInt(PointsSMG) > -1)
	{
		Format(smg, sizeof(smg), "%T", "SMG", client);
		AddMenuItem(menu, "weapon_smg", smg);
	}
	if(GetConVarInt(PointsSSMG) > -1)
	{
		Format(smg_silenced, sizeof(smg_silenced), "%T", "Silenced SMG", client);
		AddMenuItem(menu, "weapon_smg_silenced", smg_silenced);
	}
	if(GetConVarInt(PointsMP5) > -1)
	{
		Format(smg_mp5, sizeof(smg_mp5), "%T", "MP5", client);
		AddMenuItem(menu, "weapon_smg_mp5", smg_mp5);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildHealthMenu(client)
{
	decl String:adrenaline[40], String:first_aid_kit[40], String:defibrillator[40], String:pain_pills[40], String:health[64], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Health);
	if(GetConVarInt(PointsKit) > -1)
	{
		Format(first_aid_kit, sizeof(first_aid_kit), "%T", "First Aid", client);
		AddMenuItem(menu, "weapon_first_aid_kit", first_aid_kit);
	}
	if(GetConVarInt(PointsDefib) > -1)
	{
		Format(defibrillator, sizeof(defibrillator), "%T", "Defib2", client);
		AddMenuItem(menu, "weapon_defibrillator", defibrillator);
	}
	if(GetConVarInt(PointsPills) > -1)
	{
		Format(pain_pills, sizeof(pain_pills), "%T", "Pills", client);
		AddMenuItem(menu, "weapon_pain_pills", pain_pills);
	}
	if(GetConVarInt(PointsAdren) > -1)
	{
		Format(adrenaline, sizeof(adrenaline), "%T", "Adrenaline", client);
		AddMenuItem(menu, "weapon_adrenaline", adrenaline);
	}
	if(GetConVarInt(PointsHeal) > -1)
	{
		Format(health, sizeof(health), "%T", "Full Heal", client);
		AddMenuItem(menu, "health", health);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildThrowablesMenu(client)
{
	decl String:molotov[40], String:pipe_bomb[40], String:vomitjar[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Throwables);
	if(GetConVarInt(PointsMolly) > -1)
	{
		Format(molotov, sizeof(molotov), "%T", "Molotov", client);
		AddMenuItem(menu, "weapon_molotov", molotov);
	}
	if(GetConVarInt(PointsPipe) > -1)
	{
		Format(pipe_bomb, sizeof(pipe_bomb), "%T", "Pipe Bomb", client);
		AddMenuItem(menu, "weapon_pipe_bomb", pipe_bomb);
	}
	if(GetConVarInt(PointsBile) > -1)
	{
		Format(vomitjar, sizeof(vomitjar), "%T", "Bile Bomb", client);
		AddMenuItem(menu, "weapon_vomitjar", vomitjar);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildMiscMenu(client)
{
	decl String:grenade_launcher[40], String:fireworkcrate[40], String:gascan[40], String:oxygentank[40], String:propanetank[40], String:pistol[40], String:pistol_magnum[40], String:title[40];
	decl String:gnome[40], String:cola_bottles[40], String:chainsaw[40];
	new Handle:menu = CreateMenu(MenuHandler_Misc);
	if(GetConVarInt(PointsGL) > -1)
	{
		Format(grenade_launcher, sizeof(grenade_launcher), "%T", "Grenade Launcher", client);
		AddMenuItem(menu, "weapon_grenade_launcher", grenade_launcher);
	}
	if(GetConVarInt(PointsPistol) > -1)
	{
		Format(pistol, sizeof(pistol), "%T", "Pistol", client);
		AddMenuItem(menu, "weapon_pistol", pistol);
	}
	if(GetConVarInt(PointsMagnum) > -1)
	{
		Format(pistol_magnum, sizeof(pistol_magnum), "%T", "Magnum", client);
		AddMenuItem(menu, "weapon_pistol_magnum", pistol_magnum);
	}
	if(GetConVarInt(PointsSaw) > -1)
	{
		Format(chainsaw, sizeof(chainsaw), "%T", "Chainsaw", client);
		AddMenuItem(menu, "weapon_chainsaw", chainsaw);
	}
	if(GetConVarInt(PointsGnome) > -1)
	{
		Format(gnome, sizeof(gnome), "%T", "Gnome", client);
		AddMenuItem(menu, "weapon_gnome", gnome);
	}
	if(!StrEqual(MapName, "c1m2_streets", false) && GetConVarInt(PointsCola) > -1)
	{
		Format(cola_bottles, sizeof(cola_bottles), "%T", "Cola Bottles", client);
		AddMenuItem(menu, "weapon_cola_bottles", cola_bottles);
	}
	if(GetConVarInt(PointsFireWorks) > -1)
	{
		Format(fireworkcrate, sizeof(fireworkcrate), "%T", "Fireworks Crate", client);
		AddMenuItem(menu, "weapon_fireworkcrate", fireworkcrate);
	}
	new String:gamemode[20];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(!StrEqual(gamemode, "scavenge", false) && GetConVarInt(PointsGasCan) > -1)
	{
		Format(gascan, sizeof(gascan), "%T", "Gascan", client);
		AddMenuItem(menu, "weapon_gascan", gascan);
	}
	if(GetConVarInt(PointsOxy) > -1)
	{
		Format(oxygentank, sizeof(oxygentank), "%T", "Oxygen Tank", client);
		AddMenuItem(menu, "weapon_oxygentank", oxygentank);
	}
	if(GetConVarInt(PointsPropane) > -1)
	{
		Format(propanetank, sizeof(propanetank), "%T", "Propane Tank", client);
		AddMenuItem(menu, "weapon_propanetank", propanetank);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildUpgradesMenu(client)
{
	decl String:upgradepack_explosive[64], String:upgradepack_incendiary[76], String:title[40];
	decl String:laser_sight[40], String:explosive_ammo[40], String:incendiary_ammo[64], String:ammo[64];
	new Handle:menu = CreateMenu(MenuHandler_Upgrades);
	if(GetConVarInt(PointsLSight) > -1)
	{
		Format(laser_sight, sizeof(laser_sight), "%T", "Laser Sight", client);
		AddMenuItem(menu, "laser_sight", laser_sight);
	}
	if(GetConVarInt(PointsEAmmo) > -1)
	{
		Format(explosive_ammo, sizeof(explosive_ammo), "%T", "Explosive Ammo", client);
		AddMenuItem(menu, "explosive_ammo", explosive_ammo);
	}
	if(GetConVarInt(PointsIAmmo) > -1)
	{
		Format(incendiary_ammo, sizeof(incendiary_ammo), "%T", "Incendiary Ammo", client);
		AddMenuItem(menu, "incendiary_ammo", incendiary_ammo);
	}
	if(GetConVarInt(PointsEAmmoPack) > -1)
	{
		Format(upgradepack_explosive, sizeof(upgradepack_explosive), "%T", "Explosive Ammo Pack", client);
		AddMenuItem(menu, "upgradepack_explosive", upgradepack_explosive);
	}
	if(GetConVarInt(PointsIAmmoPack) > -1)
	{
		Format(upgradepack_incendiary, sizeof(upgradepack_incendiary), "%T", "Incendiary Ammo Pack", client);
		AddMenuItem(menu, "upgradepack_incendiary", upgradepack_incendiary);
	}
	if(GetConVarInt(PointsRefill) > -1)
	{
		Format(ammo, sizeof(ammo), "%T", "Ammo", client);
		AddMenuItem(menu, "ammo", ammo);
	}
	Format(title, sizeof(title),"%T", "Points Left", client, points[client]);
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
			if(StrEqual(item1, "crowbar", false))
			{
				item[param1] = "give crowbar";
				cost[param1] = GetConVarInt(PointsCrow);
			}
			else if(StrEqual(item1, "cricket_bat", false))
			{
				item[param1] = "give cricket_bat";
				cost[param1] = GetConVarInt(PointsCBat);
			}		
			else if(StrEqual(item1, "baseball_bat", false))
			{
				item[param1] = "give baseball_bat";
				cost[param1] = GetConVarInt(PointsBat);
			}
			else if(StrEqual(item1, "machete", false))
			{
				item[param1] = "give machete";
				cost[param1] = GetConVarInt(PointsMachete);
			}
			else if(StrEqual(item1, "tonfa", false))
			{
				item[param1] = "give tonfa";
				cost[param1] = GetConVarInt(PointsTonfa);
			}
			else if(StrEqual(item1, "katana", false))
			{
				item[param1] = "give katana";
				cost[param1] = GetConVarInt(PointsKatana);
			}
			else if(StrEqual(item1, "knife", false))
			{
				item[param1] = "give knife";
				cost[param1] = GetConVarInt(PointsKnife);
			}
			else if(StrEqual(item1, "riotshield", false))
			{
				item[param1] = "give riotshield";
				cost[param1] = GetConVarInt(PointsShield);
			}
			else if(StrEqual(item1, "fireaxe", false))
			{
				item[param1] = "give fireaxe";
				cost[param1] = GetConVarInt(PointsFireaxe);
			}
			else if(StrEqual(item1, "electric_guitar", false))
			{
				item[param1] = "give electric_guitar";
				cost[param1] = GetConVarInt(PointsGuitar);
			}
			else if(StrEqual(item1, "frying_pan", false))
			{
				item[param1] = "give frying_pan";
				cost[param1] = GetConVarInt(PointsPan);
			}
			else if(StrEqual(item1, "golfclub", false))
			{
				item[param1] = "give golfclub";
				cost[param1] = GetConVarInt(PointsClub);
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
				item[param1] = "give smg";
				cost[param1] = GetConVarInt(PointsSMG);
			}
			else if(StrEqual(item1, "weapon_smg_silenced", false))
			{
				item[param1] = "give smg_silenced";
				cost[param1] = GetConVarInt(PointsSSMG);
			}
			else if(StrEqual(item1, "weapon_smg_mp5", false))
			{
				item[param1] = "give smg_mp5";
				cost[param1] = GetConVarInt(PointsMP5);
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
				item[param1] = "give rifle";
				cost[param1] = GetConVarInt(PointsM16);
			}
			else if(StrEqual(item1, "weapon_rifle_desert", false))
			{
				item[param1] = "give rifle_desert";
				cost[param1] = GetConVarInt(PointsSCAR);
			}
			else if(StrEqual(item1, "weapon_rifle_ak47", false))
			{
				item[param1] = "give rifle_ak47";
				cost[param1] = GetConVarInt(PointsAK);
			}
			else if(StrEqual(item1, "weapon_rifle_sg552", false))
			{
				item[param1] = "give rifle_sg552";
				cost[param1] = GetConVarInt(PointsSG);
			}
			else if(StrEqual(item1, "weapon_rifle_m60", false))
			{
				item[param1] = "give rifle_m60";
				cost[param1] = GetConVarInt(PointsM60);
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
				item[param1] = "give hunting_rifle";
				cost[param1] = GetConVarInt(PointsHunting);
			}
			else if(StrEqual(item1, "weapon_sniper_scout", false))
			{
				item[param1] = "give sniper_scout";
				cost[param1] = GetConVarInt(PointsScout);
			}
			else if(StrEqual(item1, "weapon_sniper_awp", false))
			{
				item[param1] = "give sniper_awp";
				cost[param1] = GetConVarInt(PointsAWP);
			}
			else if(StrEqual(item1, "weapon_sniper_military", false))
			{
				item[param1] = "give sniper_military";
				cost[param1] = GetConVarInt(PointsMilitary);
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
				item[param1] = "give shotgun_chrome";
				cost[param1] = GetConVarInt(PointsChrome);
			}
			else if(StrEqual(item1, "weapon_pumpshotgun", false))
			{
				item[param1] = "give pumpshotgun";
				cost[param1] = GetConVarInt(PointsPump);
			}
			else if(StrEqual(item1, "weapon_autoshotgun", false))
			{
				item[param1] = "give autoshotgun";
				cost[param1] = GetConVarInt(PointsAuto);
			}
			else if(StrEqual(item1, "weapon_shotgun_spas", false))
			{
				item[param1] = "give shotgun_spas";
				cost[param1] = GetConVarInt(PointsSpas);
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
				item[param1] = "give molotov";
				cost[param1] = GetConVarInt(PointsMolly);
			}
			else if(StrEqual(item1, "weapon_pipe_bomb", false))
			{
				item[param1] = "give pipe_bomb";
				cost[param1] = GetConVarInt(PointsPipe);
			}
			else if(StrEqual(item1, "weapon_vomitjar", false))
			{
				item[param1] = "give vomitjar";
				cost[param1] = GetConVarInt(PointsBile);
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
				item[param1] = "give pistol";
				cost[param1] = GetConVarInt(PointsPistol);
			}
			else if(StrEqual(item1, "weapon_pistol_magnum", false))
			{
				item[param1] = "give pistol_magnum";
				cost[param1] = GetConVarInt(PointsMagnum);
			}
			else if(StrEqual(item1, "weapon_grenade_launcher", false))
			{
				item[param1] = "give grenade_launcher";
				cost[param1] = GetConVarInt(PointsGL);
			}
			else if(StrEqual(item1, "weapon_chainsaw", false))
			{
				item[param1] = "give chainsaw";
				cost[param1] = GetConVarInt(PointsSaw);
			}
			else if(StrEqual(item1, "weapon_gnome", false))
			{
				item[param1] = "give gnome";
				cost[param1] = GetConVarInt(PointsGnome);
			}
			else if(StrEqual(item1, "weapon_cola_bottles", false))
			{
				item[param1] = "give cola_bottles";
				cost[param1] = GetConVarInt(PointsCola);
			}
			else if(StrEqual(item1, "weapon_gascan", false))
			{
				item[param1] = "give gascan";
				cost[param1] = GetConVarInt(PointsGasCan);
			}
			else if(StrEqual(item1, "weapon_propanetank", false))
			{
				item[param1] = "give propanetank";
				cost[param1] = GetConVarInt(PointsPropane);
			}
			else if(StrEqual(item1, "weapon_fireworkcrate", false))
			{
				item[param1] = "give fireworkcrate";
				cost[param1] = GetConVarInt(PointsFireWorks);
			}
			else if(StrEqual(item1, "weapon_oxygentank", false))
			{
				item[param1] = "give oxygentank";
				cost[param1] = GetConVarInt(PointsOxy);
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
				item[param1] = "give first_aid_kit";
				cost[param1] = GetConVarInt(PointsKit);
			}
			else if(StrEqual(item1, "weapon_defibrillator", false))
			{
				item[param1] = "give defibrillator";
				cost[param1] = GetConVarInt(PointsDefib);
			}
			else if(StrEqual(item1, "weapon_pain_pills", false))
			{
				item[param1] = "give pain_pills";
				cost[param1] = GetConVarInt(PointsPills);
			}
			else if(StrEqual(item1, "weapon_adrenaline", false))
			{
				item[param1] = "give adrenaline";
				cost[param1] = GetConVarInt(PointsAdren);
			}
			else if(StrEqual(item1, "health", false))
			{
				item[param1] = "give health";
				cost[param1] = GetConVarInt(PointsHeal);
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
				item[param1] = "give upgradepack_explosive";
				cost[param1] = GetConVarInt(PointsEAmmoPack);
			}
			else if(StrEqual(item1, "upgradepack_incendiary", false))
			{
				item[param1] = "give upgradepack_incendiary";
				cost[param1] = GetConVarInt(PointsIAmmoPack);
			}
			else if(StrEqual(item1, "explosive_ammo", false))
			{
				item[param1] = "upgrade_add EXPLOSIVE_AMMO";
				cost[param1] = GetConVarInt(PointsEAmmo);
			}
			else if(StrEqual(item1, "incendiary_ammo", false))
			{
				item[param1] = "upgrade_add INCENDIARY_AMMO";
				cost[param1] = GetConVarInt(PointsIAmmo);
			}
			else if(StrEqual(item1, "laser_sight", false))
			{
				item[param1] = "upgrade_add LASER_SIGHT";
				cost[param1] = GetConVarInt(PointsLSight);
			}
			else if(StrEqual(item1, "ammo", false))
			{
				item[param1] = "give ammo";
				cost[param1] = GetConVarInt(PointsRefill);
			}
			DisplayConfirmMenuUpgrades(param1);
		}
	}
}

public InfectedMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new String:item1[64];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if (StrEqual(item1, "heal", false))
			{
				item[param1] = "give health";
				if(GetEntProp(param1, Prop_Send, "m_zombieClass") == 8) cost[param1] = GetConVarInt(PointsIHeal)*GetConVarInt(PointsTankHealMult);
				else cost[param1] = GetConVarInt(PointsIHeal);
			}
			else if (StrEqual(item1, "suicide", false))
			{
				item[param1] = "suicide";
				cost[param1] = GetConVarInt(PointsSuicide);
			}		
			else if (StrEqual(item1, "boomer", false))
			{
				item[param1] = "z_spawn boomer auto";
				cost[param1] = GetConVarInt(PointsBoomer);
			}
			else if (StrEqual(item1, "spitter", false))
			{
				item[param1] = "z_spawn spitter auto";
				cost[param1] = GetConVarInt(PointsSpitter);
			}
			else if (StrEqual(item1, "smoker", false))
			{
				item[param1] = "z_spawn smoker auto";
				cost[param1] = GetConVarInt(PointsSmoker);
			}
			else if (StrEqual(item1, "hunter", false))
			{
				item[param1] = "z_spawn hunter auto";
				cost[param1] = GetConVarInt(PointsHunter);
			}
			else if (StrEqual(item1, "charger", false))
			{
				item[param1] = "z_spawn charger auto";
				cost[param1] = GetConVarInt(PointsCharger);
			}
			else if (StrEqual(item1, "jockey", false))
			{
				item[param1] = "z_spawn jockey auto";
				cost[param1] = GetConVarInt(PointsJockey);
			}
			else if (StrEqual(item1, "witch", false))
			{
				item[param1] = "z_spawn witch auto";
				cost[param1] = GetConVarInt(PointsWitch);
			}
			else if (StrEqual(item1, "witch_bride", false))
			{
				item[param1] = "z_spawn witch_bride auto";
				cost[param1] = GetConVarInt(PointsWitch);
			}
			else if (StrEqual(item1, "tank", false))
			{
				item[param1] = "z_spawn tank auto";
				cost[param1] = GetConVarInt(PointsTank);
			}
			else if (StrEqual(item1, "horde", false))
			{
				item[param1] = "director_force_panic_event";
				cost[param1] = GetConVarInt(PointsHorde);
			}
			else if (StrEqual(item1, "mob", false))
			{
				item[param1] = "z_spawn mob auto";
				cost[param1] = GetConVarInt(PointsMob);
			}
			else if (StrEqual(item1, "uncommon_mob", false))
			{
				item[param1] = "z_spawn mob";
				cost[param1] = GetConVarInt(PointsUMob);
			}
			DisplayConfirmMenuI(param1);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "infected", false) && ucommonleft > 0)
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
		ucommonleft--;
	}
}

DisplayConfirmMenuMelee(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmMelee);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuSMG(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmSMG);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuRifles(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmRifles);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuSnipers(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmSniper);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuShotguns(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmShotguns);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuThrow(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmThrow);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuMisc(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmMisc);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuHealth(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmHealth);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuUpgrades(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmUpgrades);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayConfirmMenuI(param1)
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsvalidClient(i))
		{
			decl String:yes[40], String:no[40], String:title[40];
			new Handle:menu = CreateMenu(MenuHandler_ConfirmI);
			Format(yes, sizeof(yes),"%T", "Yes", i);
			AddMenuItem(menu, "yes", yes);
			Format(no, sizeof(no),"%T", "No", i);
			AddMenuItem(menu, "no", no);
			Format(title, sizeof(title),"%T", "Cost", i, cost[param1]);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, param1, MENU_TIME_FOREVER);
		}
	}
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMeleeMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "%t", "Insufficient Funds");
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildRiflesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSniperMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSMGMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildShotgunMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildThrowablesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMiscMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildHealthMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else if(StrEqual(item[param1], "give health", false))
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					SetEntPropFloat(param1, Prop_Send, "m_healthBuffer", 0.0);
					AddFlags();
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
				}
			}
		}
	}
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildUpgradesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1,  "%t", "Insufficient Funds");
				}
				else if(StrEqual(item[param1], "give ammo", false))
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					new wep = GetPlayerWeaponSlot(param1, 0);
					if(wep == -1)
					{
						if(IsClientInGame(param1)) PrintToChat(param1, "[PS] You must have a primary weapon to refill ammo!");
						return;
					}
					points[param1] -= cost[param1];
					new m60ammo = 150;
					new nadeammo = 30;
					new Handle:cvar = FindConVar("l4d2_guncontrol_m60ammo");
					new Handle:cvar2 = FindConVar("l4d2_guncontrol_grenadelauncherammo");
					if(cvar != INVALID_HANDLE)
					{
						m60ammo = GetConVarInt(cvar);
						CloseHandle(cvar);
					}
					if(cvar2 != INVALID_HANDLE)
					{
						nadeammo = GetConVarInt(cvar2);
						CloseHandle(cvar2);
					}
					new String:class[40];
					GetEdictClassname(wep, class, sizeof(class));
					RemoveFlags();
					if(StrEqual(class, "weapon_rifle_m60", false)) SetEntProp(wep, Prop_Data, "m_iClip1", m60ammo, 1);
					else if(StrEqual(class, "weapon_grenade_launcher", false))
					{
						new offset = FindDataMapOffs(param1, "m_iAmmo");
						SetEntData(param1, offset+68, nadeammo);
					}
					else FakeClientCommand(param1, item[param1]);
					AddFlags();
				}
				else
				{
					strcopy(bought[param1], sizeof(bought), item[param1]);
					boughtcost[param1] = cost[param1];
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					AddFlags();
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildBuyMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(points[param1] < cost[param1])
				{
					ReplyToCommand(param1, "%s %t", MSGTAG, "Insufficient Funds");
					return;
				}
				if(StrEqual(item[param1], "suicide", false))
				{
					ForcePlayerSuicide(param1);
				}
				else if(StrEqual(item[param1], "z_spawn mob", false))
				{
					ucommonleft += GetConVarInt(FindConVar("z_common_limit"));
				}
				else if(StrEqual(item[param1], "z_spawn tank auto", false))
				{
					if(tanksspawned == GetConVarInt(TankLimit))
					{
						PrintToChat(param1,  "%T", "Tank Limit", LANG_SERVER);
						return;
					}
					tanksspawned++;
				}
				else if(StrEqual(item[param1], "z_spawn witch auto", false) || StrEqual(item[param1], "z_spawn witch_bride auto", false))
				{
					if(witchsspawned == GetConVarInt(WitchLimit))
					{
						PrintToChat(param1,  "%T", "Witch Limit", LANG_SERVER);
						return;
					}
					witchsspawned++;
				}
				else if(StrContains(item[param1], "z_spawn", false) != -1 && StrContains(item[param1], "mob", false) == -1)
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

					RemoveFlags();
					FakeClientCommand(param1, item[param1]);
					
					new maxretry = GetConVarInt(SpawnTries);
					for(new i;i<maxretry;i++)
					{
						if(!IsPlayerAlive(param1))
						{
							FakeClientCommand(param1, item[param1]);
						}
					}
					
					if(IsPlayerAlive(param1))
					{
						strcopy(bought[param1], sizeof(bought), item[param1]);
						boughtcost[param1] = cost[param1];
						points[param1] -= cost[param1];
					}
					else
					{
						PrintToChat(param1, "%s %T", MSGTAG, "Spawn Failed", param1);
					}
					AddFlags();

					for(new i=1;i<=MaxClients;i++)
					{
						if (resetGhost[i]) SetPlayerGhost(i, true);
						if (resetAlive[i]) SetPlayerAlive(i, false);
						if (resetLifeState[i]) SetPlayerLifeState(i, true);
					}
					return;
				}
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				points[param1] -= cost[param1];
				RemoveFlags();
				FakeClientCommand(param1, item[param1]);
				AddFlags();
			}
		}
	}
}

stock bool:IsPlayerGhost(client)
{
	if(GetEntData(client, SendProp_IsGhost, 1)) return true;
	return false;
}

stock bool:IsvalidClient(client)
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client)) return false;
	return true;
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