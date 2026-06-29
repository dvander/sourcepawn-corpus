#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5.4"

new String:MapName[30];
new String:item[MAXPLAYERS+1][64];
new String:bought[MAXPLAYERS][64];
new boughtcost[MAXPLAYERS];
new hurtcount[MAXPLAYERS];
new cost[MAXPLAYERS];
new tankburning[MAXPLAYERS];
new tankbiled[MAXPLAYERS];
new witchburning[MAXPLAYERS];
new points[MAXPLAYERS];
new killcount[MAXPLAYERS];
new headshotcount[MAXPLAYERS];
new wassmoker[MAXPLAYERS];
new tanksspawned = 0;
new witchsspawned = 0;
new ucommonleft = 0;
//Definitions to save space
#define ATTACKER new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT new client = GetClientOfUserId(GetEventInt(event, "userid"));
#define ACHECK2 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK2 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define ACHECK3 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
#define CCHECK3 if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 3 && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
//Other
new Handle:Enable;
new Handle:Modes;
//Item buyables
new Handle:PointsPistol;
new Handle:PointsMagnum;
new Handle:PointsSMG;
new Handle:PointsSSMG;
new Handle:PointsMP5;
new Handle:PointsM16;
new Handle:PointsAK;
new Handle:PointsSCAR;
new Handle:PointsSG;
new Handle:PointsHunting;
new Handle:PointsMilitary;
new Handle:PointsAWP;
new Handle:PointsScout;
new Handle:PointsAuto;
new Handle:PointsSpas;
new Handle:PointsChrome;
new Handle:PointsPump;
new Handle:PointsGL;
new Handle:PointsM60;
new Handle:PointsGasCan;
new Handle:PointsOxy;
new Handle:PointsPropane;
new Handle:PointsGnome;
new Handle:PointsCola;
new Handle:PointsFireWorks;
new Handle:PointsBat;
new Handle:PointsMachete;
new Handle:PointsKatana;
new Handle:PointsTonfa;
new Handle:PointsFireaxe;
new Handle:PointsGuitar;
new Handle:PointsPan;
new Handle:PointsCBat;
new Handle:PointsCrow;
new Handle:PointsClub;
new Handle:PointsSaw;
new Handle:PointsPipe;
new Handle:PointsMolly;
new Handle:PointsBile;
new Handle:PointsKit;
new Handle:PointsDefib;
new Handle:PointsAdren;
new Handle:PointsPills;
new Handle:PointsEAmmo;
new Handle:PointsIAmmo;
new Handle:PointsEAmmoPack;
new Handle:PointsIAmmoPack;
new Handle:PointsLSight;
new Handle:PointsRefill;
new Handle:PointsHeal;
//Survivor point earning things
new Handle:SValueKillingSpree;
new Handle:SNumberKill;
new Handle:SValueHeadSpree;
new Handle:SNumberHead;
new Handle:SSIKill;
new Handle:STankKill;
new Handle:SWitchKill;
new Handle:SWitchCrown;
new Handle:SHeal;
new Handle:SProtect;
new Handle:SRevive;
new Handle:SLedge;
new Handle:SDefib;
new Handle:STBurn;
new Handle:STSolo;
new Handle:SWBurn;
new Handle:STag;
//Infected point earning things
new Handle:IChoke;
new Handle:IPounce;
new Handle:ICarry;
new Handle:IImpact;
new Handle:IRide;
new Handle:ITag;
new Handle:IIncap;
new Handle:IHurt;
new Handle:IKill;
//Infected buyables
new Handle:PointsSuicide;
new Handle:PointsHunter;
new Handle:PointsJockey;
new Handle:PointsSmoker;
new Handle:PointsCharger;
new Handle:PointsBoomer;
new Handle:PointsSpitter;
new Handle:PointsIHeal;
new Handle:PointsWitch;
new Handle:PointsTank;
new Handle:PointsTankHealMult;
new Handle:PointsHorde;
new Handle:PointsMob;
new Handle:PointsUMob;
//Catergory Enables
new Handle:CatRifles;
new Handle:CatSMG;
new Handle:CatSnipers;
new Handle:CatShotguns;
new Handle:CatHealth;
new Handle:CatUpgrades;
new Handle:CatThrowables;
new Handle:CatMisc;
new Handle:CatMelee;
new Handle:CatWeapons;
new Handle:TankLimit;
new Handle:WitchLimit;
new Handle:ResetPoints;
new Handle:StartPoints;

public Plugin:myinfo = 
{
	name = "[L4D2] Points System",
	author = "McFlurry (Modified by CAPSLOCK)",
	description = "Points system to buy items on the fly.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	new String:game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 2");
	}	
	LoadTranslations("common.phrases");
	CreateConVar("l4d2_points_sys_version", PLUGIN_VERSION, "Version of Points System on this server.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	StartPoints = CreateConVar("l4d2_points_start", "0", "Points to start each round/map with.", FCVAR_PLUGIN);
	Enable = CreateConVar("l4d2_points_enable", "1", "Enable Point System?", FCVAR_PLUGIN);
	Modes = CreateConVar("l4d2_points_modes", "coop,realism,versus,teamversus", "Which game modes to use Point System", FCVAR_PLUGIN);
	ResetPoints = CreateConVar("l4d2_points_reset_mapchange", "versus,teamversus", "Which game modes to reset point count on round end and round start", FCVAR_PLUGIN);
	TankLimit = CreateConVar("l4d2_points_tank_limit", "2", "How many tanks to be allowed spawned per team", FCVAR_PLUGIN);
	WitchLimit = CreateConVar("l4d2_points_witch_limit", "3", "How many witchs' to be allwed spawned per team", FCVAR_PLUGIN);
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
	SNumberHead = CreateConVar("l4d2_points_headshots", "20", "How many kills you need to earn a killing spree bounty", FCVAR_PLUGIN);
	SSIKill = CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn", FCVAR_PLUGIN);
	STankKill = CreateConVar("l4d2_points_tankkill", "2", "How many points does killing a tank earn", FCVAR_PLUGIN);
	SWitchKill = CreateConVar("l4d2_points_witchkill", "4", "How many points does killing a witch earn", FCVAR_PLUGIN);
	SWitchCrown = CreateConVar("l4d2_points_witchcrown", "2", "How many points does crowning a witch earn", FCVAR_PLUGIN);
	SHeal = CreateConVar("l4d2_points_heal", "5", "How many points does healing a team mate earn", FCVAR_PLUGIN);
	SProtect = CreateConVar("l4d2_points_protect", "1", "How many points does protecting a teammate earn", FCVAR_PLUGIN);
	SRevive = CreateConVar("l4d2_points_revive", "3", "How many points does reviving a team mate earn", FCVAR_PLUGIN);
	SLedge = CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn", FCVAR_PLUGIN);
	SDefib = CreateConVar("l4d2_points_defib_action", "5", "How many points does defibbing a team mate earn", FCVAR_PLUGIN);
	STBurn = CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn", FCVAR_PLUGIN);
	STSolo = CreateConVar("l4d2_points_tanksolo", "8", "How many points does killing a tank single-handedly earn", FCVAR_PLUGIN);
	SWBurn = CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn", FCVAR_PLUGIN);
	STag = CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn", FCVAR_PLUGIN);
	IChoke = CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn", FCVAR_PLUGIN);
	IPounce = CreateConVar("l4d2_points_pounce", "1", "How many points does pouning a survivor earn", FCVAR_PLUGIN);
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
	RegConsoleCmd("buystuff", BuyMenu);
	RegConsoleCmd("buy", BuyMenu);
	RegConsoleCmd("points", ShowPoints);
	RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_SLAY, "sm_heal <target>");
	RegAdminCmd("sm_givepoints", Command_Points, ADMFLAG_SLAY, "sm_givepoints <target> [amount]");
	RegAdminCmd("sm_setpoints", Command_SPoints, ADMFLAG_SLAY, "sm_setpoints <target> [amount]");
	RegConsoleCmd("sm_repeatbuy", Command_RBuy);
	HookEvent("infected_death", Event_Kill);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_death", Event_Death);
	HookEvent("tank_killed", Event_TankDeath, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("heal_success", Event_Heal);
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
	HookEvent("award_earned", Event_Protect);
	AutoExecConfig(true, "l4d2_points_system");
}

public OnMapStart()
{
	PrecacheModel("models/v_models/v_rif_sg552.mdl", true);
	PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", true);
	PrecacheModel("models/v_models/v_snip_awp.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	PrecacheModel("models/v_models/v_snip_scout.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", true);
	PrecacheModel("models/v_models/v_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
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
}	

public OnClientAuthorized(client, const String:auth[])
{
	if(points[client] > GetConVarInt(StartPoints)) return;
	points[client] = GetConVarInt(StartPoints);
	if(killcount[client] > 0) return;
	killcount[client] = 0;
	wassmoker[client] = 0;
}	

public OnClientDisconnect(client)
{
	if(IsFakeClient(client)) return;
	CreateTimer(5.0, Check, client);
	if(points[client] > GetConVarInt(StartPoints)) return;
	points[client] = GetConVarInt(StartPoints);
	killcount[client] = 0;
	wassmoker[client] = 0;
}	

public Action:Check(Handle:Timer, any:client)
{
	if(!IsClientConnected(client))
	{
		points[client] = GetConVarInt(StartPoints);
		killcount[client] = 0;
		wassmoker[client] = 0;
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
		for (new i=1; i<=MaxClients; i++)
		{
			points[i] = GetConVarInt(StartPoints);
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
		for (new i=1; i<=MaxClients; i++)
		{
			points[i] = GetConVarInt(StartPoints);
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
	if(StrEqual(gamemode, "versus", false) || StrEqual(gamemode, "teamversus", false)) return;
	for (new i=1; i<=MaxClients; i++)
	{
		points[i] = GetConVarInt(StartPoints);
		killcount[i] = 0;
	}
}	

public Action:Event_Kill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:headshot = GetEventBool(event, "headshot");
	ATTACKER
	ACHECK2
	{
		if(headshot)
		{
			headshotcount[attacker] += 1;
		}	
		if(headshotcount[attacker] == GetConVarInt(SValueHeadSpree) && GetConVarInt(SValueHeadSpree) > 0)
		{
			points[attacker] += GetConVarInt(SValueHeadSpree);
			headshotcount[attacker] -= GetConVarInt(SNumberHead);
			PrintToChat(attacker, "[PS] Head Hunter + %d points", GetConVarInt(SValueHeadSpree));
		}
		killcount[attacker] += 1;
		if(killcount[attacker] == GetConVarInt(SNumberKill) && GetConVarInt(SValueKillingSpree) > 0)
		{
			points[attacker] += GetConVarInt(SValueKillingSpree);
			killcount[attacker] -= GetConVarInt(SNumberKill);
			PrintToChat(attacker, "[PS] Killing Spree + %d points", GetConVarInt(SValueKillingSpree));
		}
	}	
}	

public Action:Event_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IIncap) == -1) return;
		points[attacker] += GetConVarInt(IIncap);
		PrintToChat(attacker, "[PS] Incapped Survivor + %d points", GetConVarInt(IIncap));
	}	
}	

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	CLIENT
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(GetClientTeam(attacker) == 2)
		{
			if(GetConVarInt(SSIKill) == -1 || GetClientTeam(client) == 2) return;
			if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8) return;
			points[attacker] += GetConVarInt(SSIKill);
			PrintToChat(attacker, "[PS] Killed Special Infected + %d points", GetConVarInt(SSIKill));
		}
		if(GetClientTeam(attacker) == 3)
		{
			if(GetConVarInt(IKill) == -1 || GetClientTeam(client) == 3) return;
			points[attacker] += GetConVarInt(IKill);
			PrintToChat(attacker, "[PS] Killed Survivor + %d points", GetConVarInt(IKill));
		}	
	}	
}	

public Action:Event_TankDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new solo = GetEventBool(event, "solo");
	ATTACKER
	ACHECK2
	{
		if(solo && GetConVarInt(STSolo) > 0)
		{
			points[attacker] += GetConVarInt(STSolo);
			PrintToChat(attacker, "[PS] TANK SOLO! + %d points", GetConVarInt(STSolo));
		}
	}
	for (new i=1; i<=MaxClients; i++)
	{
		if(i && IsClientInGame(i)&& !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && GetConVarInt(STankKill) > 0 && GetConVarInt(Enable) == 1)
		{
			points[i] += GetConVarInt(STankKill);
			PrintToChat(i, "[PS] Killed Tank + %d points", GetConVarInt(STankKill));
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
		if(GetConVarInt(SWitchKill) == -1) return;
		points[client] += GetConVarInt(SWitchKill);
		PrintToChat(client, "[PS] Killed Witch + %d points", GetConVarInt(SWitchKill));
		if(oneshot && GetConVarInt(SWitchCrown) > 0)
		{
			points[client] += GetConVarInt(SWitchCrown);
			PrintToChat(client, "[PS] Cr0wned The Witch + %d points", GetConVarInt(SWitchCrown));
		}	
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
		if(restored > 39)
		{
			if(GetConVarInt(SHeal) == -1) return;
			points[client] += GetConVarInt(SHeal);
			PrintToChat(client, "[PS] Healed Team Mate + %d points", GetConVarInt(SHeal));
		}
		else
		{
			if(GetConVarInt(SHeal) > 1)
			{
				points[client] += 1;
				PrintToChat(client, "[PS] Don't Harvest Heal Points! + 1 points");
			}
		}
	}
}	

public Action:Event_Protect(Handle:event, const String:name[], bool:dontBroadcast)
{
//	new Attacker = GetEventInt(event, "userid");
//	new Hitgroup = GetEventInt(event, "subjectentid");
	new Amount = GetEventInt(event, "award");
	CLIENT
//	new protectorname = GetClientOfUserId(Attacker);
//	new protectedname = GetClientOfUserId(Hitgroup);
	if (Amount == 67)
	{
		if(GetConVarInt(SProtect) == -1) return;
		points[client] += GetConVarInt(SProtect);
		PrintToChat(client, "[PS] Protected Teammate + %d points", GetConVarInt(SProtect));
	}
}

public Action:Event_Revive(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:ledge = GetEventBool(event, "ledge_hang");
	CLIENT
	CCHECK2
	{
		if(!ledge && GetConVarInt(SRevive) > 0 && GetConVarInt(SLedge) > 0)
		{
			points[client] += GetConVarInt(SRevive);
			PrintToChat(client, "[PS] Revived Team Mate + %d points", GetConVarInt(SRevive));
		}
		else if(ledge && GetConVarInt(SRevive) > 0 && GetConVarInt(SLedge) > 0)
		{
			points[client] += GetConVarInt(SLedge);
			PrintToChat(client, "[PS] Revived Survivor From Ledge + %d points", GetConVarInt(SLedge));
		}	
	}
}	

public Action:Event_Shock(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK2
	{
		if(GetConVarInt(SDefib) == -1) return;
		points[client] += GetConVarInt(SDefib);
		PrintToChat(client, "[PS] Defibbed Team Mate + %d points", GetConVarInt(SDefib));
	}
}	

public Action:Event_Choke(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	CCHECK3
	{
		if(GetConVarInt(IChoke) == -1) return;
		points[client] += GetConVarInt(IChoke);
		PrintToChat(client, "[PS] Choked Survivor + %d points", GetConVarInt(IChoke));
	}
}

public Action:Event_Boom(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	CLIENT
	if(attacker > 0 && !IsFakeClient(attacker) && IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		if(GetClientTeam(attacker) == 3 && GetConVarInt(ITag) > 0)
		{
			points[attacker] += GetConVarInt(ITag);
			if(GetClientTeam(client) == 2) PrintToChat(attacker, "[PS] Boomed Survivor + %d points", GetConVarInt(ITag));
		}
		if(GetClientTeam(attacker) == 2 && GetConVarInt(STag) > 0)
		{
			points[attacker] += GetConVarInt(STag);
			if(GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8) PrintToChat(attacker, "[PS] Biled Tank + %d points", GetConVarInt(STag));
			tankbiled[attacker] = 1;
		}	
	}
}	

public Action:Event_Pounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IPounce) == -1) return;
		points[attacker] += GetConVarInt(IPounce);
		PrintToChat(attacker, "[PS] Pounced Survivor + %d points", GetConVarInt(IPounce));
	}
}	

public Action:Event_Ride(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IRide) == -1) return;
		points[attacker] += GetConVarInt(IRide);
		PrintToChat(attacker, "[PS] Jockeyed Survivor + %d points", GetConVarInt(IRide));
	}
}	

public Action:Event_Carry(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(ICarry) == -1) return;
		points[attacker] += GetConVarInt(ICarry);
		PrintToChat(attacker, "[PS] Charged Survivor + %d points", GetConVarInt(ICarry));
	}
}	

public Action:Event_Impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	ATTACKER
	ACHECK3
	{
		if(GetConVarInt(IImpact) == -1) return;
		points[attacker] += GetConVarInt(IImpact);
		PrintToChat(attacker, "[PS] Crashed Into Another Survivor + %d points", GetConVarInt(IImpact));
	}
}	

public Action:Event_Burn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:victim[30];
	new bool:fireammo = GetEventBool(event, "fire_ammo");
	GetEventString(event, "victimname", victim, sizeof(victim));
	ATTACKER
	ACHECK2
	{
		if(fireammo) return;
		if(StrEqual(victim, "Tank", false) && tankburning[attacker] == 0 && GetConVarInt(STBurn) > 0)
		{
			points[attacker] += GetConVarInt(STBurn);
			PrintToChat(attacker, "[PS] Burned The Tank + %d points", GetConVarInt(STBurn));
			tankburning[attacker] = 1;
		}
		if(StrEqual(victim, "Witch", false) && witchburning[attacker] == 0 && GetConVarInt(SWBurn) > 0)
		{
			points[attacker] += GetConVarInt(SWBurn);
			PrintToChat(attacker, "[PS] Burned The Witch + %d points", GetConVarInt(SWBurn));
			witchburning[attacker] = 1;
		}
	}
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	CLIENT
	ATTACKER
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 3 && GetClientTeam(client) == 2 && IsAllowedGameMode() && GetConVarInt(Enable) == 1 && GetConVarInt(IHurt) > 0)
	{
		hurtcount[attacker] += 1;
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == 4 && GetEntProp(attacker, Prop_Send, "m_isGhost") == 0)
		{
			if(hurtcount[attacker] >= 8)
			{
				PrintToChat(attacker, "[PS] Spit Damage + %d points", GetConVarInt(IHurt));
				points[attacker] += GetConVarInt(IHurt);
				hurtcount[attacker] -= 8;
				if(wassmoker[attacker] == 1) return;
			}
		}    
		else if(GetEntProp(attacker, Prop_Send, "m_zombieClass") == 1 && !IsPlayerAlive(attacker))
		{
			if(FindConVar("l4d_cloud_damage_enabled") == INVALID_HANDLE) return;
			if(GetConVarInt(FindConVar("l4d_cloud_damage_enabled")) == 1)
			{
				if(hurtcount[attacker] >= 8)
				{
					if(GetEntProp(attacker, Prop_Send, "m_isGhost") == 1) return;
					PrintToChat(attacker, "[SM] Smoker Cloud Damage + %d points",GetConVarInt(IHurt));
					points[attacker] += GetConVarInt(IHurt);
					hurtcount[attacker] -= 10;
					wassmoker[attacker] = 1;
				}
			}
		}	
		else
		{
			if(hurtcount[attacker] >= 3)
			{
				if(wassmoker[attacker] == 1) return;
				PrintToChat(attacker, "[SM] Multiple Damage + %d points",GetConVarInt(IHurt));
				points[attacker] += GetConVarInt(IHurt);
				hurtcount[attacker] -= 3;
			}
		}    
	}	
}	

public Action:BuyMenu(client,args)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		BuildBuyMenu(client);
	}
	return Plugin_Handled;
}

public Action:ShowPoints(client,args)
{
	if(IsAllowedGameMode() && GetConVarInt(Enable) == 1)
	{
		PrintToChat(client, "[PS] You have %d points", points[client]);
	}
	return Plugin_Handled;
}

public Action:Command_RBuy(client, args)
{
	if (args > 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_repeatbuy");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		RemoveFlags();
		if(points[client] < cost[client])
		{
			PrintToChat(client, "[PS] Not Enough Points");
			return Plugin_Handled;
		}	
		if(cost[client] == -1)
		{
			PrintToChat(client, "[PS] Item Disabled");
			return Plugin_Handled;
		}	
		points[client] -= cost[client];
		FakeClientCommand(client, "%s", item[client]);
		AddFlags();
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_Heal(client, args)
{
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_heal <target>");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		RemoveFlags();
		FakeClientCommand(client, "give health");
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		AddFlags();
		return Plugin_Handled;
	}
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
	for (new i = 0; i < target_count; i++)
	{
		RemoveFlags();
		new targetclient;
		targetclient = target_list[i];
		if (IsClientInGame(targetclient)) FakeClientCommand(targetclient, "give health");
		if (IsClientInGame(targetclient)) SetEntPropFloat(targetclient, Prop_Send, "m_healthBuffer", 0.0);
		AddFlags();
	}
	return Plugin_Handled;
}

public Action:Command_Points(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givepoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] += StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_SPoints(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setpoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] = StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
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
		SetMenuExitBackButton(menu, true);
		if(GetConVarInt(CatWeapons) == 1)
		{
			Format(weapons, sizeof(weapons),"Weapons");
			AddMenuItem(menu, "g_WeaponsMenu", weapons);
		}
		if(GetConVarInt(CatUpgrades) == 1)
		{
			Format(upgrades, sizeof(upgrades),"Upgrades");
			AddMenuItem(menu, "g_UpgradesMenu", upgrades);
		}
		if(GetConVarInt(CatHealth) == 1)
		{
			Format(health, sizeof(health),"Health Items");
			AddMenuItem(menu, "g_HealthMenu", health);
		}	
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	if(GetClientTeam(client) == 3)
	{
		decl String:title[40], String:boomer[40], String:spitter[40], String:smoker[40], String:hunter[40], String:charger[40], String:jockey[40];
		decl String:tank[40], String:witch[40], String:witch_bride[40], String:heal[40], String:suicide[40], String:horde[40], String:mob[40], String:umob[40];
		new Handle:menu = CreateMenu(InfectedMenu);
		SetMenuExitBackButton(menu, true);
		Format(heal, sizeof(heal),"Heal");
		AddMenuItem(menu, "heal", heal);
		Format(suicide, sizeof(suicide),"Suicide");
		AddMenuItem(menu, "suicide", suicide);
		Format(boomer, sizeof(boomer),"Boomer");
		AddMenuItem(menu, "boomer", boomer);
		Format(spitter, sizeof(spitter),"Spitter");
		AddMenuItem(menu, "spitter", spitter);
		Format(smoker, sizeof(smoker),"Smoker");
		AddMenuItem(menu, "smoker", smoker);
		Format(hunter, sizeof(hunter),"Hunter");
		AddMenuItem(menu, "hunter", hunter);
		Format(charger, sizeof(charger),"Charger");
		AddMenuItem(menu, "charger", charger);
		Format(jockey, sizeof(jockey),"jockey");
		AddMenuItem(menu, "jockey", jockey);
		Format(tank, sizeof(tank),"Tank");
		AddMenuItem(menu, "tank", tank);
		if(StrEqual(MapName, "c6m1_riverbank", false))
		{
			Format(witch_bride, sizeof(witch_bride),"Witch Bride");
			AddMenuItem(menu, "witch_bride", witch_bride);
		}
		else
		{
			Format(witch, sizeof(witch),"Witch");
			AddMenuItem(menu, "witch", witch);
		}	
		Format(horde, sizeof(horde),"Horde");
		AddMenuItem(menu, "horde", horde);
		Format(mob, sizeof(mob),"Mob");
		AddMenuItem(menu, "mob", mob);
		Format(umob, sizeof(umob),"Uncommon Mob");
		AddMenuItem(menu, "uncommon_mob", umob);
		Format(title, sizeof(title),"%d Points Left", points[client]);
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
		Format(melee, sizeof(melee),"Melee");
		AddMenuItem(menu, "g_MeleeMenu", melee);
	}
	if(GetConVarInt(CatSnipers) == 1)
	{
		Format(snipers, sizeof(snipers),"Snipers");
		AddMenuItem(menu, "g_SnipersMenu", snipers);
	}
	if(GetConVarInt(CatRifles) == 1)
	{
		Format(rifles, sizeof(rifles),"Rifles");
		AddMenuItem(menu, "g_RiflesMenu", rifles);
	}
	if(GetConVarInt(CatShotguns) == 1)
	{
		Format(shotguns, sizeof(shotguns),"Shotguns");
		AddMenuItem(menu, "g_ShotgunsMenu", shotguns);
	}
	if(GetConVarInt(CatSMG) == 1)
	{
		Format(smg, sizeof(smg),"SMGs");
		AddMenuItem(menu, "g_SMGMenu", smg);
	}
	if(GetConVarInt(CatThrowables) == 1)
	{
		Format(throwables, sizeof(throwables),"Throwables");
		AddMenuItem(menu, "g_ThrowablesMenu", throwables);
	}
	if(GetConVarInt(CatMisc) == 1)
	{
		Format(misc, sizeof(misc),"Misc Items");
		AddMenuItem(menu, "g_MiscMenu", misc);
	}	
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public TopMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		CloseHandle(menu);	
	case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_WeaponsMenu", false))
			{
				BuildWeaponsMenu(param1);
			}	
			if(StrEqual(menu1, "g_HealthMenu", false))
			{
				BuildHealthMenu(param1);
			}	
			if(StrEqual(menu1, "g_UpgradesMenu", false))
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
		CloseHandle(menu);	
		
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
			if(StrEqual(menu1, "g_MeleeMenu", false))
			{
				BuildMeleeMenu(param1);
			}
			if(StrEqual(menu1, "g_RiflesMenu", false))
			{
				BuildRiflesMenu(param1);
			}
			if(StrEqual(menu1, "g_SnipersMenu", false))
			{
				BuildSniperMenu(param1);
			}
			if(StrEqual(menu1, "g_ShotgunsMenu", false))
			{
				BuildShotgunMenu(param1);
			}	
			if(StrEqual(menu1, "g_SMGMenu", false))
			{
				BuildSMGMenu(param1);
			}
			if(StrEqual(menu1, "g_ThrowablesMenu", false))
			{
				BuildThrowablesMenu(param1);
			}	
			if(StrEqual(menu1, "g_MiscMenu", false))
			{
				BuildMiscMenu(param1);
			}	
		}
	}
}

BuildMeleeMenu(client)
{
	decl String:fireaxe[40], String:crowbar[40], String:tonfa[40], String:baseball_bat[40], String:cricket_bat[40];
	decl String:electric_guitar[40], String:golfclub[40], String:katana[40], String:frying_pan[40];
	decl String:machete[40], String:title[40];
	if ((StrEqual(MapName, "c1m1_hotel", false)) || (StrEqual(MapName, "c1m2_streets", false)) || (StrEqual(MapName, "c1m3_mall", false)) || (StrEqual(MapName, "c1m4_atrium", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		Format(cricket_bat, sizeof(cricket_bat),"Cricket Bat");
		AddMenuItem(menu, "cricket_bat", cricket_bat);
		Format(crowbar, sizeof(crowbar),"Crowbar");
		AddMenuItem(menu, "crowbar", crowbar);
		Format(fireaxe, sizeof(fireaxe),"Fire Axe");
		AddMenuItem(menu, "fireaxe", fireaxe);
		Format(katana, sizeof(katana),"Katana");
		AddMenuItem(menu, "katana", katana);
		Format(baseball_bat, sizeof(baseball_bat),"Baseball Bat");
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if ((StrEqual(MapName, "c2m1_highway", false)) || (StrEqual(MapName, "c2m2_fairgrounds", false)) || (StrEqual(MapName, "c2m3_coaster", false)) || (StrEqual(MapName, "c2m4_barns", false)) || (StrEqual(MapName, "c2m5_concert", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		Format(crowbar, sizeof(crowbar),"Crowbar");
		AddMenuItem(menu, "crowbar", crowbar);
		Format(electric_guitar, sizeof(electric_guitar),"Electric Guitar");
		AddMenuItem(menu, "electric_guitar", electric_guitar);
		Format(fireaxe, sizeof(fireaxe),"Fire Axe");
		AddMenuItem(menu, "fireaxe", fireaxe);
		Format(katana, sizeof(katana),"Katana");
		AddMenuItem(menu, "katana", katana);
		Format(baseball_bat, sizeof(baseball_bat),"Baseball Bat");
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if ((StrEqual(MapName, "c3m1_plankcountry", false)) || (StrEqual(MapName, "c3m2_swamp", false)) || (StrEqual(MapName, "c3m3_shantytown", false)) || (StrEqual(MapName, "c3m4_plantation", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		Format(cricket_bat, sizeof(cricket_bat),"Cricket Bat");
		AddMenuItem(menu, "cricket_bat", cricket_bat);
		Format(fireaxe, sizeof(fireaxe),"Fire Axe");
		AddMenuItem(menu, "fireaxe", fireaxe);
		Format(frying_pan, sizeof(frying_pan),"Frying Pan");
		AddMenuItem(menu, "frying_pan", frying_pan);
		Format(machete, sizeof(machete),"Machete");
		AddMenuItem(menu, "machete", machete);
		Format(baseball_bat, sizeof(baseball_bat),"Baseball Bat");
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if ((StrEqual(MapName, "c4m1_milltown_a", false)) || (StrEqual(MapName, "c4m2_sugarmill_a", false)) || (StrEqual(MapName, "c4m3_sugarmill_b", false)) || (StrEqual(MapName, "c4m4_milltown_b", false)) || (StrEqual(MapName, "c4m5_milltown_escape", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		Format(crowbar, sizeof(crowbar),"Crowbar");
		AddMenuItem(menu, "crowbar", crowbar);
		Format(fireaxe, sizeof(fireaxe),"Fire Axe");
		AddMenuItem(menu, "fireaxe", fireaxe);
		Format(frying_pan, sizeof(frying_pan),"Frying Pan");
		AddMenuItem(menu, "frying_pan", frying_pan);
		Format(katana, sizeof(katana),"Katana");
		AddMenuItem(menu, "katana", katana);
		Format(baseball_bat, sizeof(baseball_bat),"Baseball Bat");
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if ((StrEqual(MapName, "c5m1_waterfront", false)) || (StrEqual(MapName, "c5m1_waterfront_sndscape", false)) || (StrEqual(MapName, "c5m2_park", false)) || (StrEqual(MapName, "c5m3_cemetery", false)) || (StrEqual(MapName, "c5m4_quarter", false)) || (StrEqual(MapName, "c5m5_bridge", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		Format(electric_guitar, sizeof(electric_guitar),"Electric Guitar");
		AddMenuItem(menu, "electric_guitar", electric_guitar);
		Format(frying_pan, sizeof(frying_pan),"Frying Pan");
		AddMenuItem(menu, "frying_pan", frying_pan);
		Format(machete, sizeof(machete),"Machete");
		AddMenuItem(menu, "machete", machete);
		Format(tonfa, sizeof(tonfa),"Tonfa");
		AddMenuItem(menu, "tonfa", tonfa);
		Format(baseball_bat, sizeof(baseball_bat),"Baseball Bat");
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if ((StrEqual(MapName, "c6m1_riverbank", false)) || (StrEqual(MapName, "c6m2_bedlam", false)) || (StrEqual(MapName, "c6m3_port", false)))
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		Format(crowbar, sizeof(crowbar),"Crowbar");
		AddMenuItem(menu, "crowbar", crowbar);	
		Format(baseball_bat, sizeof(baseball_bat),"Baseball Bat");
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(katana, sizeof(katana),"Katana");
		AddMenuItem(menu, "katana", katana);
		Format(fireaxe, sizeof(fireaxe),"Fire Axe");
		AddMenuItem(menu, "fireaxe", fireaxe);
		Format(golfclub, sizeof(golfclub),"Golf Club");
		AddMenuItem(menu, "golfclub", golfclub);	
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}		
	else
	{
		new Handle:menu = CreateMenu(MenuHandler_Melee);
		Format(cricket_bat, sizeof(cricket_bat),"Cricket Bat");
		AddMenuItem(menu, "cricket_bat", cricket_bat);
		Format(crowbar, sizeof(crowbar),"Crowbar");
		AddMenuItem(menu, "crowbar", crowbar);
		Format(electric_guitar, sizeof(electric_guitar),"Electric Guitar");
		AddMenuItem(menu, "electric_guitar", electric_guitar);
		Format(fireaxe, sizeof(fireaxe),"Fire Axe");
		AddMenuItem(menu, "fireaxe", fireaxe);
		Format(frying_pan, sizeof(frying_pan),"Frying Pan");
		AddMenuItem(menu, "frying_pan", frying_pan);
		Format(katana, sizeof(katana),"Katana");
		AddMenuItem(menu, "katana", katana);
		Format(machete, sizeof(machete),"Machete");
		AddMenuItem(menu, "machete", machete);
		Format(tonfa, sizeof(tonfa),"Tonfa");
		AddMenuItem(menu, "tonfa", tonfa);
		Format(baseball_bat, sizeof(baseball_bat),"Baseball Bat");
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(title, sizeof(title),"%d Points Left", points[client]);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

BuildSniperMenu(client)
{
	decl String:hunting_rifle[40], String:title[40], String:sniper_military[40], String:sniper_scout[40], String:sniper_awp[40];
	new Handle:menu = CreateMenu(MenuHandler_Snipers);
	Format(hunting_rifle, sizeof(hunting_rifle),"Hunting Rifle");
	AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle);
	Format(sniper_military, sizeof(sniper_military),"Military Sniper");
	AddMenuItem(menu, "weapon_sniper_military", sniper_military);
	Format(sniper_awp, sizeof(sniper_awp),"AWP");
	AddMenuItem(menu, "weapon_sniper_awp", sniper_awp);
	Format(sniper_scout, sizeof(sniper_scout),"Scout Sniper");
	AddMenuItem(menu, "weapon_sniper_scout", sniper_scout);
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildRiflesMenu(client)
{
	decl String:rifle[40], String:title[40], String:rifle_desert[40], String:rifle_ak47[40], String:rifle_sg552[40], String:rifle_m60[40];
	new Handle:menu = CreateMenu(MenuHandler_Rifles);
	Format(rifle_m60, sizeof(rifle_m60),"M60");
	AddMenuItem(menu, "weapon_rifle_m60", rifle_m60);
	Format(rifle, sizeof(rifle),"M16");
	AddMenuItem(menu, "weapon_rifle", rifle);
	Format(rifle_desert, sizeof(rifle_desert),"SCAR");
	AddMenuItem(menu, "weapon_rifle_desert", rifle_desert);
	Format(rifle_ak47, sizeof(rifle_ak47),"AK-47");
	AddMenuItem(menu, "weapon_rifle_ak47", rifle_ak47);
	Format(rifle_sg552, sizeof(rifle_sg552),"SG 552");
	AddMenuItem(menu, "weapon_rifle_sg552", rifle_sg552);
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildShotgunMenu(client)
{
	decl String:autoshotgun[40], String:shotgun_chrome[40], String:shotgun_spas[40], String:pumpshotgun[40], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Shotguns);
	Format(autoshotgun, sizeof(autoshotgun),"Autoshotgun");
	AddMenuItem(menu, "weapon_autoshotgun", autoshotgun);
	Format(shotgun_chrome, sizeof(shotgun_chrome),"Chrome Shotgun");
	AddMenuItem(menu, "weapon_shotgun_chrome", shotgun_chrome);
	Format(shotgun_spas, sizeof(shotgun_spas),"Spas Shotgun");
	AddMenuItem(menu, "weapon_shotgun_spas", shotgun_spas);
	Format(pumpshotgun, sizeof(pumpshotgun),"Pump Shotgun");
	AddMenuItem(menu, "weapon_pumpshotgun", pumpshotgun);
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildSMGMenu(client)
{
	decl String:smg[40], String:title[40], String:smg_silenced[40], String:smg_mp5[40];
	new Handle:menu = CreateMenu(MenuHandler_SMG);
	Format(smg, sizeof(smg),"SMG");
	AddMenuItem(menu, "weapon_smg", smg);
	Format(smg_silenced, sizeof(smg_silenced),"Silenced SMG");
	AddMenuItem(menu, "weapon_smg_silenced", smg_silenced);
	Format(smg_mp5, sizeof(smg_mp5),"MP5");
	AddMenuItem(menu, "weapon_smg_mp5", smg_mp5);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildHealthMenu(client)
{
	decl String:adrenaline[40], String:defibrillator[40], String:first_aid_kit[40], String:pain_pills[40], String:health[40], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Health);
	Format(first_aid_kit, sizeof(first_aid_kit),"First Aid Kit");
	AddMenuItem(menu, "weapon_first_aid_kit", first_aid_kit);
	Format(defibrillator, sizeof(defibrillator),"Defibrillator");
	AddMenuItem(menu, "weapon_defibrillator", defibrillator);
	Format(pain_pills, sizeof(pain_pills),"Pills");
	AddMenuItem(menu, "weapon_pain_pills", pain_pills);
	Format(adrenaline, sizeof(adrenaline),"Adrenaline");
	AddMenuItem(menu, "weapon_adrenaline", adrenaline);
	Format(health, sizeof(health),"Full Heal");
	AddMenuItem(menu, "health", health);
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildThrowablesMenu(client)
{
	decl String:molotov[40], String:pipe_bomb[40], String:vomitjar[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Throwables);
	Format(molotov, sizeof(molotov),"Molotov");
	AddMenuItem(menu, "weapon_molotov", molotov);
	Format(pipe_bomb, sizeof(pipe_bomb),"Pipe Bomb");
	AddMenuItem(menu, "weapon_pipe_bomb", pipe_bomb);
	Format(vomitjar, sizeof(vomitjar),"Bile Bomb");
	AddMenuItem(menu, "weapon_vomitjar", vomitjar);
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildMiscMenu(client)
{
	decl String:grenade_launcher[40], String:fireworkcrate[40], String:gascan[40], String:oxygentank[40], String:propanetank[40], String:pistol[40], String:pistol_magnum[40], String:title[40];
	decl String:gnome[40], String:cola_bottles[40], String:chainsaw[40];
	new Handle:menu = CreateMenu(MenuHandler_Misc);
	Format(grenade_launcher, sizeof(grenade_launcher),"Grenade Launcher");
	AddMenuItem(menu, "weapon_grenade_launcher", grenade_launcher);
	Format(pistol, sizeof(pistol),"Pistol");
	AddMenuItem(menu, "weapon_pistol", pistol);
	Format(pistol_magnum, sizeof(pistol_magnum),"Magnum");
	AddMenuItem(menu, "weapon_pistol_magnum", pistol_magnum);
	Format(chainsaw, sizeof(chainsaw),"Chainsaw");
	AddMenuItem(menu, "weapon_chainsaw", chainsaw);
	Format(gnome, sizeof(gnome),"Gnome");
	AddMenuItem(menu, "weapon_gnome", gnome);
	if(!StrEqual(MapName, "c1m2_streets", false))
	{
		Format(cola_bottles, sizeof(cola_bottles),"Cola Bottles");
		AddMenuItem(menu, "weapon_cola_bottles", cola_bottles);
	}
	Format(fireworkcrate, sizeof(fireworkcrate),"Fireworks Crate");
	AddMenuItem(menu, "weapon_fireworkcrate", fireworkcrate);
	new String:gamemode[20];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(!StrEqual(gamemode, "scavenge", false))
	{
		Format(gascan, sizeof(gascan),"Gascan");
		AddMenuItem(menu, "weapon_gascan", gascan);
	}	
	Format(oxygentank, sizeof(oxygentank),"Oxygen Tank");
	AddMenuItem(menu, "weapon_oxygentank", oxygentank);
	Format(propanetank, sizeof(propanetank),"Propane Tank");
	AddMenuItem(menu, "weapon_propanetank", propanetank);
	Format(title, sizeof(title),"%d Points Left", points[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildUpgradesMenu(client)
{
	decl String:upgradepack_explosive[40], String:upgradepack_incendiary[40], String:title[40];
	decl String:laser_sight[40], String:explosive_ammo[40], String:incendiary_ammo[40], String:ammo[40];
	new Handle:menu = CreateMenu(MenuHandler_Upgrades);
	Format(laser_sight, sizeof(laser_sight),"Laser Sight");
	AddMenuItem(menu, "laser_sight", laser_sight);
	Format(explosive_ammo, sizeof(explosive_ammo),"Explosive Ammo");
	AddMenuItem(menu, "explosive_ammo", explosive_ammo);
	Format(incendiary_ammo, sizeof(incendiary_ammo),"Incendiary Ammo");
	AddMenuItem(menu, "incendiary_ammo", incendiary_ammo);
	Format(upgradepack_explosive, sizeof(upgradepack_explosive),"Explosive Ammo Pack");
	AddMenuItem(menu, "upgradepack_explosive", upgradepack_explosive);
	Format(upgradepack_incendiary, sizeof(upgradepack_incendiary),"Incendiary Ammo Pack");
	AddMenuItem(menu, "upgradepack_incendiary", upgradepack_incendiary);
	Format(ammo, sizeof(ammo),"Ammo");
	AddMenuItem(menu, "ammo", ammo);
	Format(title, sizeof(title),"%d Points Left", points[client]);
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
			else if(StrEqual(item1, "weapon_silenced_smg", false))
			{
				item[param1] = "give silenced_smg";
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
				ucommonleft += GetConVarInt(FindConVar("z_common_limit"));
				item[param1] = "z_spawn mob auto";
				cost[param1] = GetConVarInt(PointsUMob);
			}
			DisplayConfirmMenuI(param1);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{	
	if(!StrEqual(classname, "infected", false)) return;
	new number = 0;
	if(ucommonleft > 0)
	{
		if(GetRandomInt(1, 6) == 1) SetEntityModel(entity, "models/infected/common_male_riot.mdl");
		if(GetRandomInt(1, 6) == 2) SetEntityModel(entity, "models/infected/common_male_ceda.mdl");
		if(GetRandomInt(1, 6) == 3) SetEntityModel(entity, "models/infected/common_male_clown.mdl");
		if(GetRandomInt(1, 6) == 4) SetEntityModel(entity, "models/infected/common_male_mud.mdl");
		if(GetRandomInt(1, 6) == 5) SetEntityModel(entity, "models/infected/common_male_roadcrew.mdl");
		if(GetRandomInt(1, 6) == 6) SetEntityModel(entity, "models/infected/common_male_fallen_survivor.mdl");
		ucommonleft -= 1;
		if(ucommonleft == number) return;
	}	
}

DisplayConfirmMenuMelee(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMelee);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuSMG(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSMG);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuRifles(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmRifles);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuSnipers(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSniper);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuShotguns(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmShotguns);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuThrow(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmThrow);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuMisc(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMisc);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuHealth(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmHealth);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuUpgrades(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmUpgrades);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}	

DisplayConfirmMenuI(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmI);
	Format(yes, sizeof(yes),"Yes");
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"No");
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"Cost %d", cost[param1]);
	if(cost[param1] == -1) Format(title, sizeof(title),"Disabled");
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
			strcopy(item[param1], sizeof(item), bought[param1]);
			cost[param1] = boughtcost[param1];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildMeleeMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildRiflesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildSniperMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildSMGMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildShotgunMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildThrowablesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildMiscMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildHealthMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{	
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildUpgradesMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(cost[param1] == -1) return;
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
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
			if(cost[param1] == -1) 
			{
				PrintToChat(param1, "[PS] Item Disabled");
				return;
			}
			if (StrEqual(choice, "no", false))
			{
				BuildBuyMenu(param1);
				strcopy(item[param1], sizeof(item), bought[param1]);
				cost[param1] = boughtcost[param1];
			}
			else if (StrEqual(choice, "yes", false))
			{
				strcopy(bought[param1], sizeof(bought), item[param1]);
				boughtcost[param1] = cost[param1];
				if(StrEqual(item[param1], "suicide", false))
				{
					if(cost[param1] == -1) return;
					if(points[param1] < cost[param1]) return;
					ForcePlayerSuicide(param1);
				}
				if(StrEqual(item[param1], "z_spawn tank auto", false))
				{
					if(points[param1] < cost[param1]) return;
					if(cost[param1] == -1) return;
					if(tanksspawned == GetConVarInt(TankLimit)) PrintToChat(param1, "[PS] Tank Limit Reached!");
					if(tanksspawned == GetConVarInt(TankLimit)) return;
					tanksspawned++;
				}
				if(StrEqual(item[param1], "z_spawn witch auto", false) || StrEqual(item[param1], "z_spawn witch_bride auto", false))
				{
					if(points[param1] < cost[param1]) return;
					if(cost[param1] == -1) return;
					if(witchsspawned == GetConVarInt(WitchLimit)) PrintToChat(param1, "[PS] Witch Limit Reached!");
					if(witchsspawned == GetConVarInt(WitchLimit)) return;
					witchsspawned++;
				}
				if(points[param1] < cost[param1])
				{
					PrintToChat(param1, "[PS] Not Enough Points");
				}
				else
				{
					if(cost[param1] == -1) return;
					if(points[param1] < cost[param1]) return;
					if(StrEqual(item[param1], "z_spawn bride auto", false) || StrEqual(item[param1], "z_spawn witch_bride auto", false) && witchsspawned == GetConVarInt(WitchLimit)) return;
					else if(StrEqual(item[param1], "z_spawn tank auto", false) && tanksspawned == GetConVarInt(TankLimit)) return;
					points[param1] -= cost[param1];
					RemoveFlags();
					FakeClientCommand(param1, "%s", item[param1]);
					AddFlags();
				}	
			}
		}
	}
}	