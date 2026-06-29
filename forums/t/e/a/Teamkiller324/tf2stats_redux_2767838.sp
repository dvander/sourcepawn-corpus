#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <tf2_stocks>
#include <geoip>
#include <adminmenu>
#include <clientprefs>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.01 Redux"
#define DBVERSION 37

#define MAX_LINE_WIDTH 60

#define FlagPickedUp 1
#define FlagCaptured 2
#define FlagDefended 3
#define FlagDropped  4


bool cpmap = false;
int mapisset;
int classfunctionloaded = 0;

Database db = null;			/** Database connection */
Handle dbReconnect = null;

bool rankingenabled = false;

// Death Points
ConVar Scoutdiepoints = null;
ConVar Soldierdiepoints = null;
ConVar Pyrodiepoints = null;
ConVar Medicdiepoints = null;
ConVar Sniperdiepoints = null;
ConVar Spydiepoints = null;
ConVar Demomandiepoints = null;
ConVar Heavydiepoints = null;
ConVar Engineerdiepoints = null;

bool oldshowranktoallvalue = true;


int g_iLastRankCheck[MAXPLAYERS+1] = {0, ...};
ConVar v_RankCheckTimeout = null;
//int g_iCanCheckKDR[MAXPLAYERS+1] = {0, ...};	//We wont add this yet since KDR checks arent that expensive on the database

/*
#1. Add handles
*/


//Sleeping Dogs
//-------------------
ConVar long_heatmaker = null;
ConVar annihilator = null;
ConVar recorder = null;
ConVar guillotine = null;


//All-Class Weapons
//-------------------
ConVar Objector_Points = null;
ConVar Saxxy_Points = null;


//Scout Points
//-------------------

// Default Weapons
ConVar scattergunpoints = null;
ConVar batpoints = null;
ConVar pistolpoints = null;

//Unlocks
ConVar force_a_naturepoints = null;
ConVar sandmanpoints = null;
ConVar bat_woodpoints = null;

//Polycount
ConVar short_stoppoints = null;
ConVar holy_mackerelpoints = null;

//Other
ConVar ballpoints = null;
ConVar taunt_scoutpoints = null;
ConVar stun_points = null;
ConVar big_stun_points = null;

//Rift
ConVar SunBatPoints = null;

//Samurai
ConVar Warfan_Points = null;

//Christmas Update
ConVar candy_canePoints = null;
ConVar boston_basherPoints = null;

//Witcher
ConVar Scout_Sword_Points = null;

//Uber Update
ConVar Popper_Points = null;
ConVar Winger_Points = null;
ConVar Atomizer_Points = null;

//Halloween 2011
ConVar Unarmed_Combat_Points = null;

//Christmas 2011
ConVar WrapAssassin_Points = null;

//Meet the pyro
ConVar Brawlerblaster_Points = null;
ConVar Pep_pistol_Points = null;

//--------------------


//Soldier Points
//--------------------

// Default Weapons
ConVar tf_projectile_rocketpoints = null;
ConVar shotgunpoints = null;
ConVar shovelpoints = null;

//Unlocks
ConVar rocketlauncher_directhitpoints = null;
ConVar pickaxepoints = null;
ConVar uniquepickaxepoints = null; //Defunct

//Polycount
ConVar blackboxpoints = null;

//Other
ConVar taunt_soldierpoints = null;
ConVar paintrainpoints = null;
ConVar worms_grenade_points = null;

//Samurai
ConVar Katana_Points = null;

//Uber Update
ConVar Liberty_Points = null;
ConVar ReserveShooter_Points = null;
ConVar DisciplinaryAction_Points = null;
ConVar MarketGardener_Points = null;
ConVar Mantreads_Points = null;

//Space Update
ConVar Mangler_Points = null;
ConVar RighteousBison_Points = null;

// Quakecon
ConVar Quake_RocketLauncher_Points = null;

//Meet the pyro
ConVar Dumpster_Device_Points = null;
ConVar Pickaxe_Escape_Points = null;

//--------------------


//Pyro Points
//--------------------

// Default Weapons
ConVar flamethrowerpoints = null;
ConVar fireaxepoints = null;

//Unlocks
ConVar backburnerpoints = null;
ConVar flaregunpoints = null;
ConVar axtinguisherpoints = null;

//Polycount
ConVar powerjackpoints = null;
ConVar degreaserpoints = null;

//Other
ConVar taunt_pyropoints = null;
ConVar deflect_flarepoints = null;
ConVar deflect_rocketpoints = null;
ConVar deflect_promodepoints = null;
ConVar deflect_stickypoints = null;
ConVar deflect_arrowpoints = null;

//Rift
ConVar LavaAxePoints = null;

//Special
ConVar sledgehammerpoints = null;

//Christmas Update
ConVar back_scratcherPoints = null;

//Red Faction: Armageddon
ConVar The_Maul_Points = null;

//Uber Update
ConVar Detonator_Points = null;

//Summer Update
ConVar Mailbox_Points = null;

//Spacetek Update
ConVar ManglerReflect_Points = null;

//Christmas 2011
ConVar Phlogistinator_Points = null;
ConVar Manmelter_Points = null;
ConVar Thirddegree_Points = null;

//Meet the pyro
ConVar Rainblower_Points = null;
ConVar Scorchshot_Points = null;
ConVar Lollichop_Points = null;
ConVar Armageddon_taunt_Points = null;

//--------------------


//Demo Points
//--------------------

// Default Weapons
ConVar tf_projectile_pipepoints = null;
ConVar tf_projectile_pipe_remotepoints = null;
ConVar bottlepoints = null;

//Unlocks
ConVar sticky_resistancepoints = null;
ConVar demoshieldpoints = null;
ConVar swordpoints = null;

//Special
ConVar battleaxepoints = null;
ConVar fryingpanpoints = null;

//Other
ConVar taunt_demomanpoints = null;
ConVar headtakerpoints = null;

//Christmas Update
ConVar ullapool_caberPoints = null;
ConVar lochnloadPoints = null;
ConVar gaelicclaymorePoints = null;
ConVar UllaExplodePoints = null;

//Uber Update
ConVar Persian_Persuader_Points = null;
ConVar Splendid_Screen_Points = null;

//Summer Update
ConVar Golfclub_Points = null;

//Halloween 2011
ConVar Scottish_Handshake_Points = null;

//--------------------


//Heavy Points
//--------------------

// Default Weapons
ConVar minigunpoints = null;

ConVar fistspoints = null;

//Unlocks
ConVar nataschapoints = null;
ConVar glovespoints = null;

//Polycount
ConVar urgentglovespoints = null;

//Taunt
ConVar taunt_heavypoints = null;

//Poker Night
ConVar ironcurtainpoints = null;

//Christmas Update 2010
ConVar bear_clawsPoints = null;
ConVar steel_fistsPoints = null;
ConVar BrassBeastPoints = null;

//Saints Row 3
ConVar ApocoFists_Points = null;

//Uber Update
ConVar Tomislav_Points = null;
ConVar Family_Business_Points = null;
ConVar Eviction_Notice_Points = null;

//Christmas 2011
ConVar Holiday_Punch_Points = null;

//--------------------


//Engi Points
//--------------------

// Default Weapons
ConVar obj_sentrygunpoints = null;
ConVar wrenchpoints = null;

//Unlocks
ConVar frontier_justicePoints = null; //new shotgun : added v6:6
ConVar wrangler_killPoints = null; //manual sentry control : added v6:6
ConVar robot_armPoints = null; //mech-arm wrench : added v6:6

//Special
ConVar maxgunPoints  = null; //sam and max pistol : added v6:6
ConVar southern_hospitalityPoints  = null; //bleed-wrench : added v6:6
ConVar bleed_killPoints  = null; //bleed kill, also for sniper's wood knife : added v6:6

//Other
ConVar robot_arm_blender_killPoints  = null; //mech-arm taunt : added v6:6
ConVar robot_arm_combo_killPoints  = null;
ConVar taunt_guitar_killPoints  = null; //new shotgun taunt kill : added v6:6
ConVar TeleUsePoints = null;

//Christmas Update
ConVar wrench_jagPoints = null;
ConVar MinisentryPoints = null;

//Deus Ex
ConVar WidowmakerPoints = null;
ConVar Short_CircuitPoints = null;

//Christmas 2011
ConVar Pomson_Points = null;
ConVar Eureka_Effect_Points = null;

//--------------------


//Medic Points
//--------------------

// Default Weapons
ConVar bonesawpoints = null;
ConVar syringegun_medicpoints = null;

//Polycount
ConVar battleneedlepoints = null;

//Unlocks
ConVar blutsaugerpoints = null;
ConVar ubersawpoints = null;

//Christmas Update:
ConVar amputatorPoints = null;
ConVar medicCrossbowPoints = null;

//Uber Update
ConVar Proto_Syringe_Points = null;
ConVar Solemn_Vow_Points = null;

//--------------------


//Sniper Points
//--------------------

// Default Weapons
ConVar sniperriflepoints = null;
ConVar smgpoints = null;
ConVar clubpoints = null;

//Unlocks
ConVar compound_bowpoints = null;
ConVar tf_projectile_arrowpoints = null;
ConVar woodknifepoints = null;

//Polycount
ConVar sleeperpoints = null;
ConVar bushwackapoints = null;

//Other
ConVar taunt_sniperpoints = null;

//Uber Update
ConVar Bazaar_Bargain_Points = null;
ConVar Shahanshah_Points = null;

//Deus Ex
ConVar Machina_Points = null;
ConVar Machina_DoubleKill_Points = null;

//Meet the pyro
ConVar Pro_rifle_Points = null;
ConVar Pro_smg_Points = null;

//--------------------


//Spy Points
//--------------------

// Default Weapons
ConVar revolverpoints = null;
ConVar knifepoints = null;

//Unlocks
ConVar ambassadorpoints = null;
ConVar samrevolverpoints = null;

//Polycount
ConVar eternal_rewardpoints = null;
ConVar letrangerpoints = null;

//Other
ConVar taunt_spypoints = null;

//Samurai
ConVar Kunai_Points = null;

//Uber Update
ConVar Enforcer_Points = null;
ConVar Big_Earner_Points = null;

//Deus Ex
ConVar Diamondback_Points = null;

//Halloween 2011
ConVar Wanga_Prick_Points = null;

//Assassins Creed
ConVar Sharp_Dresser_Points = null;

//Christmas 2011
ConVar Spy_Cicle_Points = null;

// Alliance of Valiant Arms
ConVar BlackRose_Points = null;

//--------------------


//Other - Events
//--------------------

ConVar killsapperpoints = null;
ConVar killteleinpoints = null;
ConVar killteleoutpoints = null;
ConVar killdisppoints = null;
ConVar killsentrypoints = null;
ConVar killasipoints = null;
ConVar killasimedipoints = null;
ConVar overchargepoints = null;
ConVar telefragpoints = null;
ConVar extingushingpoints = null;
ConVar stealsandvichpoints = null;

//Halloween 2011
ConVar EyeBossKillAssist = null;
ConVar EyeBossStun = null;

//--------------------


//Other - Kills
//--------------------

ConVar pumpkinpoints = null;
ConVar goombapoints = null; //Added v6:5
ConVar headshotpoints = null;

//--------------------

//Other - VIPs
//--------------------
ConVar vip_points1 = null;
ConVar vip_points2 = null;
ConVar vip_points3 = null;
ConVar vip_points4 = null;
ConVar vip_points5 = null;

ConVar vip_steamid1 = null;
ConVar vip_steamid2 = null;
ConVar vip_steamid3 = null;
ConVar vip_steamid4 = null;
ConVar vip_steamid5 = null;

ConVar vip_message1 = null;
ConVar vip_message2 = null;
ConVar vip_message3 = null;
ConVar vip_message4 = null;
ConVar vip_message5 = null;
//--------------------

//Other - Menus
//--------------------
int g_iMenuTarget[MAXPLAYERS+1];
//--------------------

//Some chat cvars
//--------------------
ConVar ShowEnoughPlayersNotice = null;
ConVar ShowRoundEnableNotice = null;

//Other
//--------------------
ConVar ignorebots = null;
ConVar ignoreTeamKills = null;

ConVar v_TimeOffset = null;

ConVar logips = null; //Added v6:6

ConVar showranktoall  = null;
ConVar showrankonroundend = null;
ConVar showSessionStatsOnRoundEnd = null;
ConVar roundendranktochat = null;
ConVar showrankonconnect = null;

ConVar ShowTeleNotices = null;

ConVar webrank = null;
ConVar webrankurl = null;

ConVar removeoldplayers = null;
ConVar removeoldplayersdays = null;

ConVar Capturepoints = null;
ConVar FileCapturepoints = null;
ConVar CTFCapPlayerPoints = null;
ConVar CPCapPlayerPoints = null;
ConVar Captureblockpoints = null;

ConVar neededplayercount = null;
ConVar disableafterwin = null;
ConVar worldpoints = null;

ConVar ConnectSoundFile	= null;
ConVar ConnectSound = null;
ConVar CountryCodeHandler = null;
ConVar ConnectSoundTop10 = null;
ConVar ConnectSoundFileTop10 = null;

Handle CheckCookieTimers[MAXPLAYERS+1];

bool rankingactive = true;

int onconrank[MAXPLAYERS + 1];
int onconpoints[MAXPLAYERS + 1];
int rankedclients = 0;
int playerpoints[MAXPLAYERS + 1];
int playerrank[MAXPLAYERS + 1];
char ranksteamidreq[MAXPLAYERS + 1][25];
char ranknamereq[MAXPLAYERS + 1][32];
int reqplayerrankpoints[MAXPLAYERS + 1];
int reqplayerrank[MAXPLAYERS + 1];

int maxents, ResourceEnt, maxplayers;

int sessionpoints[MAXPLAYERS + 1];
int sessionkills[MAXPLAYERS + 1];
int sessiondeath[MAXPLAYERS + 1];
int sessionassi[MAXPLAYERS + 1];

int TotalHealing[MAXPLAYERS+1] = {0, ...};
//iHealing

int overchargescoring[MAXPLAYERS + 1];
Handle overchargescoringtimer[MAXPLAYERS + 1];
ConVar pointmsg = null;

bool g_IsRoundActive = true;
//bool callKDeath[MAXPLAYERS+1] = false;

ConVar CV_chattag = null;
ConVar CV_showchatcommands = null;
char CHATTAG[MAX_LINE_WIDTH];

bool cookieshowrankchanges[MAXPLAYERS + 1];
bool showchatcommands = true;

ConVar CV_rank_enable = null;

char sTableName[64];

public Plugin myinfo = {
	name = "[TF2] Player Stats",
	author = "DarthNinja, xiaoli, Tk /id/Teamkiller324",
	description = "TF2 Player Statistical tracker.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=335778"
}

public void OnPluginStart()	{
	BuildServerIp();
	
	versioncheck();
	openDatabaseConnection();
	//createdbtables();
	CreateCvars();
	AutoExecConfig(false, "tf2-stats", "");
	AutoExecConfig(false, "tf2-stats");
	CreateConVar("rank_version", PLUGIN_VERSION, "TF2Stats Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY).AddChangeHook(VersionChanged);
	HookEvents();
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	//HookEvent("player_say", Command_Say, EventHookMode_Pre);

	RegAdminCmd("sm_rankadmin", Menu_RankAdmin, ADMFLAG_ROOT, "Open Rank Admin Menu");
	RegAdminCmd("rank_givepoints", Rank_GivePoints, ADMFLAG_ROOT, "Give Ranking Points");
	RegAdminCmd("rank_removepoints", Rank_RemovePoints, ADMFLAG_ROOT, "Remove Ranking Points");
	RegAdminCmd("rank_setpoints", Rank_SetPoints, ADMFLAG_ROOT, "Set Ranking Points");
	RegAdminCmd("rank_debug_resetallctfcaps", Rank_ResetCTFCaps, ADMFLAG_ROOT, "Reset all CTF cap stats to 0");
	RegAdminCmd("rank_debug_resetallcpcaps", Rank_ResetCPCaps, ADMFLAG_ROOT, "Reset all CP cap stats to 0");
	LoadTranslations("common.phrases");
	startconvarhooking();
}

void VersionChanged(ConVar cvar, const char[] oldvalue, const char[] newvalue)	{
	if(!StrEqual(newvalue, PLUGIN_VERSION))
		cvar.SetString(PLUGIN_VERSION);
}

void versioncheck()	{
	if(FileExists("addons/sourcemod/plugins/n1g-tf2-stats.smx"))	{
		ServerCommand("say [OLD-VERSION] file n1g-tf2-stats.smx exists and is being disabled!");
		LogError("say [OLD-VERSION] file n1g-tf2-stats.smx exists and is being disabled!");
		ServerCommand("sm plugins unload n1g-tf2-stats.smx");
		RenameFile("addons/sourcemod/plugins/disabled/n1g-tf2-stats.smx", "addons/sourcemod/plugins/n1g-tf2-stats.smx");
	}
}

Action sec60evnt(Handle timer)	{
	playerstimeupdateondb();
}

void playerstimeupdateondb()	{
	char clsteamId[MAX_LINE_WIDTH];
	int time = GetTime();
	time = time + v_TimeOffset.IntValue;
	for(int i = 1; i <= MaxClients; i++)	{
		if(IsClientInGame(i))	{
			GetClientAuthId(i, AuthId_Steam2, clsteamId, sizeof(clsteamId));
			char query[512];
			Format(query, sizeof(query), "UPDATE %s SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE STEAMID = '%s'", sTableName, time ,clsteamId);
			db.Query(SQLErrorCheckCallback, query);
		}
	}
}

Action ReconnectToDB(Handle timer)	{
	if(SQL_CheckConfig("tf2stats_redux"))	{
		if(db != null)	{
			delete db;
			db = null;
		}
		Database.Connect(Connected, "tf2stats_redux");
	}
}

void openDatabaseConnection()	{
	if(SQL_CheckConfig("tf2stats_redux"))	{
		if(db != null)	{
			delete db;
			db = null;
		}
		Database.Connect(Connected, "tf2stats_redux");
	}
}

void Connected(Database database, const char[] error, any data)	{
	if(database == null || !StrEqual(error, ""))	{
		PrintToServer("Failed to connect: %s", error);
		LogError("TF2 Stats Failed to connect! Error: %s", error);
		LogError("Please check your database settings and permssions and try again!");	// use LogError twice rather then a newline so plugin name is prepended
		SetFailState("Could not reach database server!");
		return;
	}
	
	LogMessage("TF2_Stats connected to MySQL Database!");
	char query[255];
	Format(query, sizeof(query), "SET NAMES \"UTF8\"");	/* Set codepage to utf8 */
	
	//if (!SQL_FastQuery(db, query))
		//LogError("Can't select character set (%s)", query);
		
	db = database;
	db.Query(SQL_PostSetNames, query);
}

void SQL_PostSetNames(Database database, DBResultSet results, const char[] error, any data)	{
	if(results == null || !StrEqual(error, ""))
		LogError("Can't select character set (%s)", error);

	createdbtables();
	CreateTimer(60.0, sec60evnt, _, TIMER_REPEAT);
}

/*
#2. Add new SQL DB queries
*/
void createdbplayer()	{
	int len = 0;
	char query[20000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s` (", sTableName);
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`POINTS` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`PLAYTIME` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`LASTONTIME` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KILLS` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Death` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KillAssist` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KillAssistMedic` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`BuildSentrygun` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`BuildDispenser` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`HeadshotKill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KOSentrygun` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Domination` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Overcharge` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KOSapper` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`BOTeleporterentrace` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KODispenser` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`BOTeleporterExit` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`CPBlocked` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`CPCaptured` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`FileCaptured` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`ADCaptured` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KOTeleporterExit` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KOTeleporterEntrace` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`BOSapper` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Revenge` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Axe` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Bnsw` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Bt` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Bttl` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Cg` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Fsts` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Ft` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Gl` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Kn` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Mctte` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Mgn` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Ndl` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Pistl` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Rkt` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Sg` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Sky` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Smg` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Spr` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Stgn` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Wrnc` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Sntry` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_SntryL1` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_SntryL2` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_SntryL3` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Shvl` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Ubersaw` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Flaregun` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Axtinguisher` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_pyro` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_heavy` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_gloves` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_backburner` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_natascha` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_blutsauger` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_rocket` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_promode` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_sticky` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_world` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bat_wood` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_stunned` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`drunk_bonk` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_stealsandvich` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`chat_status` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_tf_projectile_arrow` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ambassador` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_sniper` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_spy` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_extinguished` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_teleported` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_feigndeath` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_force_a_nature` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sandman` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`K_backstab` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_compound_bow` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_scout` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_arrow` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_rocketlauncher_directhit` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_telefrag` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_flare` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_soldier` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_pickaxe` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_demoshield` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sword` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_demoman` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sticky_resistance` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_tribalkukri` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_battleaxe` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ball` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_paintrain` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sledgehammer` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_unique_pickaxe` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_pumpkin` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_goomba` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`IPAddress` varchar(50) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_frontier_justice` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_wrangler_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_maxgun` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_southern_hospitality` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bleed_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm_blender_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_guitar_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_samrevolver` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_powerjack` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_degreaser` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_battleneedle` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_eternal_reward` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_letranger` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_short_stop` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_holy_mackerel` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bushwacka` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_urgentgloves` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sleeperrifle` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_blackbox` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`ScoutDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`SoldierDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`PyroDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`DemoDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`HeavyDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`EngiDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`MedicDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`SniperDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`SpyDeaths` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`ScoutKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`SoldierKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`PyroKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`DemoKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`HeavyKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`EngiKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`MedicKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`SniperKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`SpyKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`MedicHealing` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm_combo_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_fryingpan` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_headtaker` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_iron_curtain` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_amputator` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_healingcrossbow` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_brassbeast` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bearclaws` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_steelfists` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ullapool_caber` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ullapool_caber_explosion` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_minisentry` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_lochnload` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_candy_cane` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_boston_basher` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_back_scratcher` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_wrench_jag` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_claidheamohmor` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_worms_grenade` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_lava_axe` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sun_bat` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_jar` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_warfan` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_katana` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_kunai` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_witcher_sword` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_maul` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_soda_popper` int(11) NOT NULL default '0',"); //Uber update start
	len += Format(query[len], sizeof(query)-len, "`KW_the_winger` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_atomizer` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_liberty_launcher` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_reserve_shooter` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_disciplinary_action` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_market_gardener` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_mantreads` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_detonator` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_persian_persuader` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_splendid_screen` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_tomislav` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_family_business` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_eviction_notice` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_proto_syringe` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_solemn_vow` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bazaar_bargain` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_shahanshah` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_enforcer` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_big_earner` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_mailbox` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_golfclub` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bison` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_mangler` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_QuakeRL` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`TotalPlayersTeleported` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ManglerReflect` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Widowmaker` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Short_Circuit` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Machina` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Machina_DoubleKill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Diamondback` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_UnarmedCombat` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_WangaPrick` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ScottishHandshake` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ConscientiousObjector` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Saxxy` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`EyeBossStuns` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`EyeBossKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_phlogistinator` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_manmelter` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_thirddegree` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_holiday_punch` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_pomson` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_eureka_effect` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sharp_dresser` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_spy_cicle` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_wrap_assassin` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_apocofists` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_black_rose` int(11) NOT NULL default '0',");
	
	len += Format(query[len], sizeof(query)-len, "`pep_brawlerblaster` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`pep_pistol` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`dumpster_device` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`unique_pickaxe_escape` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`rainblower` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`scorchshot` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`lollichop` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`armageddon` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`pro_rifle` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`pro_smg` int(11) NOT NULL default '0',");
	
	len += Format(query[len], sizeof(query)-len, "`long_heatmaker` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`annihilator` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`guillotine` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`recorder` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`STEAMID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	SQL_FastQuery(db, query);
}

/*
#4. Add point cvars - see step 1
*/

void CreateCvars()	{
	//Generic kills and weapons
	Katana_Points			= CreateConVar("rank_katana_points",		"8", "TF2Stats - Points:Samurai - Half-Zatoichi (Katana)", _, true, 0.0);
	pistolpoints			= CreateConVar("rank_pistolpoints",			"3", "TF2Stats - Points:Generic - Pistol", _, true, 0.0);
	maxgunPoints			= CreateConVar("rank_maxgunpoints",			"3", "TF2Stats - Points:Generic - The Lugermorph", _, true, 0.0);
	shotgunpoints			= CreateConVar("rank_shotgunpoints",		"2", "TF2Stats - Points:Generic - Shotgun", _, true, 0.0);
	telefragpoints			= CreateConVar("rank_telefragpoints",		"10", "TF2Stats - Points:Generic - Telefrag", _, true, 0.0);
	goombapoints			= CreateConVar("rank_goombastomp",			"6", "TF2Stats - Points:Generic - Goomba Stomp (mod)", _, true, 0.0);
	pumpkinpoints			= CreateConVar("rank_pumpkinpoints",		"2", "TF2Stats - Points:Generic - Pumpkin Bomb", _, true, 0.0);
	worldpoints				= CreateConVar("rank_worldpoints",			"4", "TF2Stats - Points:Generic - World Kill", _, true, 0.0);
	stealsandvichpoints		= CreateConVar("rank_stealsandvichpoints",	"1", "TF2Stats - Points:Generic - Steal Sandvich", _, true, 0.0);
	extingushingpoints		= CreateConVar("rank_extingushingpoints",	"1", "TF2Stats - Points:Generic - Extingush Player", _, true, 0.0);
	bleed_killPoints		= CreateConVar("rank_bleed_killpoints",		"3", "TF2Stats - Points:Generic - Bleed Kill", _, true, 0.0); //New v6:6
	fryingpanpoints			= CreateConVar("rank_fryingpanpoints",		"4", "TF2Stats - Points:Generic - Frying Pan", _, true, 0.0);
	headshotpoints			= CreateConVar("rank_headshot_bonuspoints",	"2", "TF2Stats - Points:Generic - Extra points to award for headshots", _, true, 0.0);
	Saxxy_Points			= CreateConVar("rank_saxxy_points",			"4", "TF2Stats - Points:Generic Weapon - Saxxy", _, true, 0.0);
	Objector_Points			= CreateConVar("rank_objector_points",		"4", "TF2Stats - Points:Generic Weapon - Conscientious Objector", _, true, 0.0);

	EyeBossKillAssist		= CreateConVar("rank_eyeboss_kill_points",	"10", "TF2Stats - Points: Monoculus Kill Assist", _, true, 0.0);
	EyeBossStun				= CreateConVar("rank_eyeboss_stun_points",	"5", "TF2Stats - Points: Monoculus Stun", _, true, 0.0);

	//Scout
	scattergunpoints		= CreateConVar("rank_scattergunpoints",		"2", "TF2Stats - Points:Scout - Scattergun", _, true, 0.0);
	batpoints				= CreateConVar("rank_batpoints",			"4", "TF2Stats - Points:Scout - Bat", _, true, 0.0);
	ballpoints				= CreateConVar("rank_ballpoints",			"5", "TF2Stats - Points:Scout - Baseball", _, true, 0.0);
	stun_points				= CreateConVar("rank_stunpoints",			"1", "TF2Stats - Points:Scout - Stun Player", _, true, 0.0);
	big_stun_points			= CreateConVar("rank_big_stun",				"2", "TF2Stats - Points:Scout - Big Stun", _, true, 0.0);
	bat_woodpoints			= CreateConVar("rank_bat_woodpoints",		"3", "TF2Stats - Points:Scout - Sandman", _, true, 0.0);
	force_a_naturepoints	= CreateConVar("rank_force_a_naturepoints",	"2", "TF2Stats - Points:Scout - Force-a-Nature", _, true, 0.0);
	sandmanpoints			= CreateConVar("rank_sandmanpoints",		"3", "TF2Stats - Points:Scout - Sandman", _, true, 0.0);
	taunt_scoutpoints		= CreateConVar("rank_taunt_scoutpoints",	"6", "TF2Stats - Points:Scout - Sandman Taunt", _, true, 0.0);
	short_stoppoints		= CreateConVar("rank_short_stoppoints",		"2", "TF2Stats - Points:Scout - ShortStop", _, true, 0.0);
	holy_mackerelpoints		= CreateConVar("rank_holy_mackerelpoints",	"4", "TF2Stats - Points:Scout - Holy Mackerel", _, true, 0.0);
	candy_canePoints		= CreateConVar("rank_candycanepoints",		"4", "TF2Stats - Points:Scout - Candy Cane", _, true, 0.0);
	boston_basherPoints		= CreateConVar("rank_boston_basherpoints",	"6", "TF2Stats - Points:Scout - Boston Basher", _, true, 0.0);
	SunBatPoints			= CreateConVar("rank_sunbat_points",		"6", "TF2Stats - Points:Scout - Sun-on-a-Stick", _, true, 0.0);
	Warfan_Points			= CreateConVar("rank_warfan_points",		"6", "TF2Stats - Points:Scout - Fan O'War", _, true, 0.0);
	Scout_Sword_Points		= CreateConVar("rank_witcher_sword_points",	"6", "TF2Stats - Points:Scout - Three-Rune Blade", _, true, 0.0);
	Popper_Points			= CreateConVar("rank_soda_popper_points",	"2", "TF2Stats - Points:Scout - The Soda Popper", _, true, 0.0);
	Winger_Points			= CreateConVar("rank_winger_points",		"3", "TF2Stats - Points:Scout - The Winger", _, true, 0.0);
	Atomizer_Points			= CreateConVar("rank_atomizer_points",		"4", "TF2Stats - Points:Scout - The Atomizer", _, true, 0.0);
	Unarmed_Combat_Points	= CreateConVar("rank_unarmedcombat_points",	"4", "TF2Stats - Points:Scout - Unarmed Combat", _, true, 0.0);
	WrapAssassin_Points		= CreateConVar("rank_wrapassassin_points",	"6", "TF2Stats - Points:Scout - The Wrap Assassin", _, true, 0.0);
	
	Brawlerblaster_Points	= CreateConVar("rank_brawlerblaster_points","3", "TF2Stats - Points:Scout - Baby Face's Blaster", _, true, 0.0);
	Pep_pistol_Points		= CreateConVar("rank_pbpp_points",			"3", "TF2Stats - Points:Scout - Pretty Boy's Pocket Pistol", _, true, 0.0);

	//Soldier
	tf_projectile_rocketpoints		= CreateConVar("rank_tf_projectile_rocketpoints",		"2", "TF2Stats - Points:Soldier - Rocket Launcher", _, true, 0.0);
	shovelpoints					= CreateConVar("rank_shovelpoints",						"4", "TF2Stats - Points:Soldier - Shovel", _, true, 0.0);
	rocketlauncher_directhitpoints	= CreateConVar("rank_rocketlauncher_directhitpoints",	"2", "TF2Stats - Points:Soldier - Direct Hit", _, true, 0.0);
	pickaxepoints					= CreateConVar("rank_pickaxepoints",					"4", "TF2Stats - Points:Soldier - Equalizer", _, true, 0.0);
	taunt_soldierpoints				= CreateConVar("rank_taunt_soldierpoints",				"15", "TF2Stats - Points:Soldier - Grenade Taunt", _, true, 0.0);
	paintrainpoints					= CreateConVar("rank_paintrainpoints",					"4", "TF2Stats - Points:Soldier - Paintrain", _, true, 0.0);
	uniquepickaxepoints				= CreateConVar("rank_pickaxepoints_lowhealth",			"6", "TF2Stats - Points:Soldier - Equalizer - Low Health (defunct)", _, true, 0.0); //Defunct
	blackboxpoints					= CreateConVar("rank_blackboxpoints",					"2", "TF2Stats - Points:Soldier - Black Box", _, true, 0.0);
	worms_grenade_points			= CreateConVar("rank_worms_grenade_points",				"15", "TF2Stats - Points:Soldier - Grenade Taunt (With worms hat)", _, true, 0.0);
	Liberty_Points					= CreateConVar("rank_liberty_launcher_points",			"2", "TF2Stats - Points:Soldier - Liberty Launcher", _, true, 0.0);
	ReserveShooter_Points			= CreateConVar("rank_reserve_shooter_points",			"2", "TF2Stats - Points:Soldier - Reserve Shooter", _, true, 0.0);
	DisciplinaryAction_Points		= CreateConVar("rank_disciplinary_action_points",		"5", "TF2Stats - Points:Soldier - Disciplinary Action", _, true, 0.0);
	MarketGardener_Points			= CreateConVar("rank_market_gardener_points",			"5", "TF2Stats - Points:Soldier - Market Gardener", _, true, 0.0);
	Mantreads_Points				= CreateConVar("rank_mantreads_points",					"15", "TF2Stats - Points:Soldier - Mantreads", _, true, 0.0);
	Mangler_Points					= CreateConVar("rank_mangler_points",					"2", "TF2Stats - Points:Soldier - Cow Mangler", _, true, 0.0);
	RighteousBison_Points			= CreateConVar("rank_bison_points",						"3", "TF2Stats - Points:Soldier - Righteous Bison", _, true, 0.0);
	Quake_RocketLauncher_Points		= CreateConVar("rank_the_original_points",				"3", "TF2Stats - Points:Soldier - The Original", _, true, 0.0);
	
	Dumpster_Device_Points			= CreateConVar("rank_beggarsbazooka_points",			"4", "TF2Stats - Points:Soldier - Beggar's Bazooka", _, true, 0.0);
	Pickaxe_Escape_Points			= CreateConVar("rank_pickaxe_escape_points",			"6", "TF2Stats - Points:Soldier - The Escape Plan", _, true, 0.0);

	//Pyro
	flamethrowerpoints		= CreateConVar("rank_flamethrowerpoints",		"3", "TF2Stats - Points:Pyro - Flamethrower", _, true, 0.0);
	backburnerpoints		= CreateConVar("rank_backburnerpoints",			"2", "TF2Stats - Points:Pyro - Backburner", _, true, 0.0);
	fireaxepoints			= CreateConVar("rank_fireaxepoints",			"4", "TF2Stats - Points:Pyro - Fireaxe", _, true, 0.0);
	flaregunpoints			= CreateConVar("rank_flaregunpoints",			"4", "TF2Stats - Points:Pyro - Flaregun", _, true, 0.0);
	axtinguisherpoints		= CreateConVar("rank_axtinguisherpoints",		"4", "TF2Stats - Points:Pyro - Axtinguisher", _, true, 0.0);
	taunt_pyropoints		= CreateConVar("rank_taunt_pyropoints",			"6", "TF2Stats - Points:Pyro - Taunt", _, true, 0.0);
	sledgehammerpoints		= CreateConVar("rank_sledgehammerpoints",		"5", "TF2Stats - Points:Pyro - Sledgehammer", _, true, 0.0);
	deflect_rocketpoints	= CreateConVar("rank_deflect_rocketpoints",		"2", "TF2Stats - Points:Pyro - Deflected Rocket", _, true, 0.0);
	deflect_promodepoints	= CreateConVar("rank_deflect_promodepoints",	"2", "TF2Stats - Points:Pyro - Deflected ???", _, true, 0.0);
	deflect_stickypoints	= CreateConVar("rank_deflect_stickypoints",		"2", "TF2Stats - Points:Pyro - Deflected Sticky", _, true, 0.0);
	deflect_arrowpoints		= CreateConVar("rank_deflect_arrowpoints",		"15", "TF2Stats - Points:Pyro - Deflected Arrow", _, true, 0.0);
	deflect_flarepoints		= CreateConVar("rank_deflect_flarepoints",		"8", "TF2Stats - Points:Pyro - Deflected Flare", _, true, 0.0);
	powerjackpoints			= CreateConVar("rank_powerjackpoints",			"4", "TF2Stats - Points:Pyro - PowerJack", _, true, 0.0);
	degreaserpoints			= CreateConVar("rank_degreaserpoints",			"3", "TF2Stats - Points:Pyro - Degreaser", _, true, 0.0);
	back_scratcherPoints	= CreateConVar("rank_backscratcherpoints",		"5", "TF2Stats - Points:Pyro - Back Scratcher", _, true, 0.0);
	LavaAxePoints			= CreateConVar("rank_lava_axe_points",			"6", "TF2Stats - Points:Pyro - Sharpened Volcano Fragment", _, true, 0.0);
	The_Maul_Points			= CreateConVar("rank_maul_points",				"5", "TF2Stats - Points:Pyro - The Maul", _, true, 0.0);
	Detonator_Points		= CreateConVar("rank_detonator_points",			"5", "TF2Stats - Points:Pyro - The Detonator", _, true, 0.0);
	Mailbox_Points			= CreateConVar("rank_mailbox_points",			"4", "TF2Stats - Points:Pyro - The Postal Pummeler", _, true, 0.0);
	ManglerReflect_Points	= CreateConVar("rank_mangler_reflect_points",	"8", "TF2Stats - Points:Pyro - Deflected Cow Mangler", _, true, 0.0);
	Phlogistinator_Points	= CreateConVar("rank_phlogistinator_points",	"2", "TF2Stats - Points:Pyro - The Phlogistinator", _, true, 0.0);
	Manmelter_Points		= CreateConVar("rank_manmelter_points",			"3", "TF2Stats - Points:Pyro - The Manmelter", _, true, 0.0);
	Thirddegree_Points		= CreateConVar("rank_thirddegree_points",		"5", "TF2Stats - Points:Pyro - The Third Degree", _, true, 0.0);
	
	Rainblower_Points		= CreateConVar("rank_rainblower_points",		"3", "TF2Stats - Points:Pyro - The Rainblower", _, true, 0.0);
	Scorchshot_Points		= CreateConVar("rank_scorchedshot_points",		"5", "TF2Stats - Points:Pyro - The scorchedshot", _, true, 0.0);
	Lollichop_Points		= CreateConVar("rank_Lollichop_points",			"4", "TF2Stats - Points:Pyro - Lollichop", _, true, 0.0);
	Armageddon_taunt_Points	= CreateConVar("rank_armageddon_points",		"15", "TF2Stats - Points:Pyro - Armageddon taunt", _, true, 0.0);


	//Demo
	tf_projectile_pipepoints		= CreateConVar("rank_tf_projectile_pipepoints",			"2", "TF2Stats - Points:Demo - Pipebomb Launcher", _, true, 0.0);
	tf_projectile_pipe_remotepoints	= CreateConVar("rank_tf_projectile_pipe_remotepoints",	"2", "TF2Stats - Points:Demo - Sticky Launcher", _, true, 0.0);
	bottlepoints					= CreateConVar("rank_bottlepoints",						"4", "TF2Stats - Points:Demo - Bottle", _, true, 0.0);
	demoshieldpoints				= CreateConVar("rank_demoshieldpoints",					"10", "TF2Stats - Points:Demo - Shield Charge", _, true, 0.0);
	swordpoints						= CreateConVar("rank_swordpoints",						"4", "TF2Stats - Points:Demo - Eyelander", _, true, 0.0);
	taunt_demomanpoints				= CreateConVar("rank_taunt_demomanpoints",				"9", "TF2Stats - Points:Demo - Taunt", _, true, 0.0);
	sticky_resistancepoints			= CreateConVar("rank_sticky_resistancepoints",			"2", "TF2Stats - Points:Demo - Scottish Resistance", _, true, 0.0);
	battleaxepoints					= CreateConVar("rank_battleaxepoints",					"4", "TF2Stats - Points:Demo - Skullcutter", _, true, 0.0);
	headtakerpoints					= CreateConVar("rank_headtakerpoints",					"5", "TF2Stats - Points:Demo - Unusual Headtaker Axe", _, true, 0.0);
	ullapool_caberPoints			= CreateConVar("rank_ullapool_caberpoints",				"6", "TF2Stats - Points:Demo - Ullapool Caber", _, true, 0.0);
	UllaExplodePoints				= CreateConVar("rank_ullapool_explode_points",			"5", "TF2Stats - Points:Demo - Ullapool Caber Explosion", _, true, 0.0);
	lochnloadPoints					= CreateConVar("rank_lochnloadpoints",					"4", "TF2Stats - Points:Demo - Loch-n-Load", _, true, 0.0);
	gaelicclaymorePoints			= CreateConVar("rank_gaelicclaymore",					"4", "TF2Stats - Points:Demo - Claidheamh Mor", _, true, 0.0);
	Persian_Persuader_Points		= CreateConVar("rank_persian_persuader_points",			"4", "TF2Stats - Points:Demo - Persian Persuader", _, true, 0.0);
	Splendid_Screen_Points			= CreateConVar("rank_splendid_screen_points",			"8", "TF2Stats - Points:Demo - Splendid Screen Shield Charge", _, true, 0.0);
	Golfclub_Points					= CreateConVar("rank_golfclub_points",					"4", "TF2Stats - Points:Demo - Nessie's Nine Iron", _, true, 0.0);
	Scottish_Handshake_Points		= CreateConVar("rank_scottish_handshake_points",		"4", "TF2Stats - Points:Demo - Scottish Handshake", _, true, 0.0);


	//Heavy
	minigunpoints			= CreateConVar("rank_minigunpoints",			"1", "TF2Stats - Points:Heavy - Minigun", _, true, 0.0);
	fistspoints				= CreateConVar("rank_fistspoints",				"4", "TF2Stats - Points:Heavy - Fist", _, true, 0.0);
	glovespoints			= CreateConVar("rank_killingglovespoints",		"4", "TF2Stats - Points:Heavy - KGBs", _, true, 0.0);
	taunt_heavypoints		= CreateConVar("rank_taunt_heavypoints",		"6", "TF2Stats - Points:Heavy - Taunt", _, true, 0.0);
	nataschapoints			= CreateConVar("rank_nataschapoints",			"1", "TF2Stats - Points:Heavy - Natascha");
	urgentglovespoints		= CreateConVar("rank_urgentglovespoints",		"6", "TF2Stats - Points:Heavy - Gloves of Running Urgently", _, true, 0.0);
	ironcurtainpoints		= CreateConVar("rank_ironcurtainpoints",		"1", "TF2Stats - Points:Heavy - Iron Curtain", _, true, 0.0);
	BrassBeastPoints		= CreateConVar("rank_brassbeastpoints",			"1", "TF2Stats - Points:Heavy - Brass Beast", _, true, 0.0);
	bear_clawsPoints		= CreateConVar("rank_warriors_spiritpoints",	"4", "TF2Stats - Points:Heavy - Warrior's Spirit", _, true, 0.0);
	steel_fistsPoints		= CreateConVar("rank_fistsofsteelpoints",		"4", "TF2Stats - Points:Heavy - Fists of Steel", _, true, 0.0);
	Tomislav_Points			= CreateConVar("rank_tomislav_points",			"1", "TF2Stats - Points:Heavy - Tomislav", _, true, 0.0);
	Family_Business_Points	= CreateConVar("rank_family_business_points",	"3", "TF2Stats - Points:Heavy - Family Business", _, true, 0.0);
	Eviction_Notice_Points	= CreateConVar("rank_eviction_notice_points",	"4", "TF2Stats - Points:Heavy - Eviction Notice", _, true, 0.0);
	Holiday_Punch_Points	= CreateConVar("rank_holiday_punch_points",		"4", "TF2Stats - Points:Heavy - The Holiday Punch", _, true, 0.0);
	ApocoFists_Points		= CreateConVar("rank_apocofist_points",			"4", "TF2Stats - Points:Heavy - The Apocofists", _, true, 0.0);

	//Engi
	obj_sentrygunpoints				= CreateConVar("rank_obj_sentrygunpoints",			"3", "TF2Stats - Points:Engineer - Sentry", _, true, 0.0);
	MinisentryPoints				= CreateConVar("rank_minisentry_points",			"4", "TF2Stats - Points:Engineer - Mini-Sentry", _, true, 0.0);
	wrenchpoints					= CreateConVar("rank_wrenchpoints",					"7", "TF2Stats - Points:Engineer - Wrench", _, true, 0.0);
	frontier_justicePoints			= CreateConVar("rank_frontier_justicepoints",		"3", "TF2Stats - Points:Engineer - Frontier Justice", _, true, 0.0); //New v6:6
	wrangler_killPoints				= CreateConVar("rank_wrangler_points",				"4", "TF2Stats - Points:Engineer - Wrangler", _, true, 0.0); //New v6:6
	robot_armPoints					= CreateConVar("rank_robot_armpoints",				"5", "TF2Stats - Points:Engineer - Gunslinger", _, true, 0.0); //New v6:6
	southern_hospitalityPoints		= CreateConVar("rank_southern_hospitalitypoints",	"6", "TF2Stats - Points:Engineer - Southern Hospitality", _, true, 0.0); //New v6:6
	robot_arm_blender_killPoints	= CreateConVar("rank_robot_arm_blender_points",		"10", "TF2Stats - Points:Engineer - Gunslinger Taunt", _, true, 0.0); //New v6:6
	taunt_guitar_killPoints			= CreateConVar("rank_taunt_guitar_points",			"10", "TF2Stats - Points:Engineer - Taunt Guitar", _, true, 0.0); //New v6:6
	robot_arm_combo_killPoints		= CreateConVar("rank_robot_arm_combo_killpoints",	"20", "TF2Stats - Points:Engineer - Gunslinger 3-Hit Combo Kill", _, true, 0.0);
	wrench_jagPoints				= CreateConVar("rank_jagpoints",					"8", "TF2Stats - Points:Engineer - The Jag", _, true, 0.0);
	TeleUsePoints					= CreateConVar("rank_tele_use_points",				"1", "TF2Stats - Points:Engineer - Teleporter Use", _, true, 0.0);
	WidowmakerPoints				= CreateConVar("rank_widowmaker_points",			"3", "TF2Stats - Points:Engineer - Widowmaker", _, true, 0.0);
	Short_CircuitPoints				= CreateConVar("rank_shortcircuit_points",			"30", "TF2Stats - Points:Engineer - The Short Circuit", _, true, 0.0);
	Pomson_Points					= CreateConVar("rank_pomson_points",				"4", "TF2Stats - Points:Engineer - The Pomson 6000", _, true, 0.0);
	Eureka_Effect_Points			= CreateConVar("rank_eureka_effect_points",			"7", "TF2Stats - Points:Engineer - The Eureka Effect", _, true, 0.0);


	//Medic
	bonesawpoints					= CreateConVar("rank_bonesawpoints",				"6", "TF2Stats - Points:Medic - Bonesaw", _, true, 0.0);
	syringegun_medicpoints			= CreateConVar("rank_syringegun_medicpoints",		"4", "TF2Stats - Points:Medic - Syringe Gun", _, true, 0.0);
	killasimedipoints				= CreateConVar("rank_killasimedicpoints",			"3", "TF2Stats - Points:Medic - Kill Asist", _, true, 0.0);
	overchargepoints				= CreateConVar("rank_overchargepoints",				"2", "TF2Stats - Points:Medic - Ubercharge", _, true, 0.0);
	ubersawpoints					= CreateConVar("rank_ubersawpoints",				"6", "TF2Stats - Points:Medic - Ubersaw", _, true, 0.0);
	blutsaugerpoints				= CreateConVar("rank_blutsaugerpoints",				"4", "TF2Stats - Points:Medic - Blutsauger", _, true, 0.0);
	battleneedlepoints				= CreateConVar("rank_battleneedlepoints",			"6", "TF2Stats - Points:Medic - Vita-Saw", _, true, 0.0);
	amputatorPoints					= CreateConVar("rank_amputatorpoints",				"6", "TF2Stats - Points:Medic - Amputator", _, true, 0.0);
	medicCrossbowPoints				= CreateConVar("rank_mediccrossbowpoints",			"5", "TF2Stats - Points:Medic - Amputator", _, true, 0.0);
	Proto_Syringe_Points			= CreateConVar("rank_overdose_points",				"4", "TF2Stats - Points:Medic - The Overdose", _, true, 0.0);
	Solemn_Vow_Points				= CreateConVar("rank_solemn_vow_points",			"6", "TF2Stats - Points:Medic - The Solemn Vow", _, true, 0.0);


	//Sniper
	sniperriflepoints				= CreateConVar("rank_sniperriflepoints",			"1", "TF2Stats - Points:Sniper - Rifle", _, true, 0.0);
	smgpoints						= CreateConVar("rank_smgpoints",					"3", "TF2Stats - Points:Sniper - SMG", _, true, 0.0);
	clubpoints						= CreateConVar("rank_clubpoints",					"4", "TF2Stats - Points:Sniper - Kukri", _, true, 0.0);
	woodknifepoints					= CreateConVar("rank_woodknifepoints",				"4", "TF2Stats - Points:Sniper - Shiv", _, true, 0.0);
	tf_projectile_arrowpoints		= CreateConVar("rank_tf_projectile_arrowpoints",	"1", "TF2Stats - Points:Sniper - Huntsman", _, true, 0.0);
	taunt_sniperpoints				= CreateConVar("rank_taunt_sniperpoints",			"6", "TF2Stats - Points:Sniper - Huntsman Taunt", _, true, 0.0);
	compound_bowpoints				= CreateConVar("rank_compound_bowpoints",			"2", "TF2Stats - Points:Sniper - Huntsman", _, true, 0.0);
	sleeperpoints					= CreateConVar("rank_sleeperpoints",				"2", "TF2Stats - Points:Sniper - Sydney Sleeper", _, true, 0.0);
	bushwackapoints					= CreateConVar("rank_bushwackapoints",				"4", "TF2Stats - Points:Sniper - Bushwacka", _, true, 0.0);
	Bazaar_Bargain_Points			= CreateConVar("rank_bazaar_bargain_points",		"1", "TF2Stats - Points:Sniper - Bazaar Bargain", _, true, 0.0);
	Shahanshah_Points				= CreateConVar("rank_shahanshah_points",			"5", "TF2Stats - Points:Sniper - Shahanshah", _, true, 0.0);
	Machina_Points					= CreateConVar("rank_machina_points",				"2", "TF2Stats - Points:Sniper - Machina", _, true, 0.0);
	Machina_DoubleKill_Points		= CreateConVar("rank_machina_doublekill_points",	"5", "TF2Stats - Points:Sniper - Machina Double Kill", _, true, 0.0);
	
	Pro_rifle_Points				= CreateConVar("rank_hitmansheatmaker_points",		"1", "TF2Stats - Points:Sniper - Hitman's Heatmaker", _, true, 0.0);
	Pro_smg_Points					= CreateConVar("rank_cleanerscarbine_points",		"2", "TF2Stats - Points:Sniper - Cleaner's Carbine", _, true, 0.0);


	//Spy
	revolverpoints			= CreateConVar("rank_revolverpoints",			"3", "TF2Stats - Points:Spy - Revolver", _, true, 0.0);
	knifepoints				= CreateConVar("rank_knifepoints",				"4", "TF2Stats - Points:Spy - Knife", _, true, 0.0);
	ambassadorpoints		= CreateConVar("rank_ambassadorpoints",			"4", "TF2Stats - Points:Spy - Ambassador", _, true, 0.0);
	taunt_spypoints			= CreateConVar("rank_taunt_spypoints",			"12", "TF2Stats - Points:Spy - Knife Taunt", _, true, 0.0);
	samrevolverpoints		= CreateConVar("rank_samrevolverpoints",		"3", "TF2Stats - Points:Spy - Sam's Revolver", _, true, 0.0);
	eternal_rewardpoints	= CreateConVar("rank_eternal_rewardpoints",		"4", "TF2Stats - Points:Spy - Eternal Reward", _, true, 0.0);
	letrangerpoints			= CreateConVar("rank_letrangerpoints",			"3", "TF2Stats - Points:Spy - L'Etranger", _, true, 0.0);
	Kunai_Points			= CreateConVar("rank_kunai_points",				"4", "TF2Stats - Points:Spy - Conniver's Kunai", _, true, 0.0);
	Enforcer_Points			= CreateConVar("rank_enforcer_points",			"3", "TF2Stats - Points:Spy - The Enforcer", _, true, 0.0);
	Big_Earner_Points		= CreateConVar("rank_big_earner_points",		"3", "TF2Stats - Points:Spy - The Big Earner", _, true, 0.0);
	Diamondback_Points		= CreateConVar("rank_diamondback_points",		"3", "TF2Stats - Points:Spy - The Diamondback", _, true, 0.0);
	Wanga_Prick_Points		= CreateConVar("rank_wanga_prickpoints",		"4", "TF2Stats - Points:Spy - Wanga Prick", _, true, 0.0);
	Sharp_Dresser_Points	= CreateConVar("rank_sharp_dresser_points",		"4", "TF2Stats - Points:Spy - The Sharp Dresser", _, true, 0.0);
	Spy_Cicle_Points		= CreateConVar("rank_spy_cicle_points",			"4", "TF2Stats - Points:Spy - The Spy-cicle", _, true, 0.0);
	BlackRose_Points		= CreateConVar("rank_blackrose_points",			"4", "TF2Stats - Points:Spy - The Black Rose", _, true, 0.0);
	
	// Sleeping Dogs Items
	long_heatmaker			= CreateConVar("rank_long_heatmaker_points",	"1", "TF2Stats - Points:Heavy - The Huo-Long Heater", _, true, 0.0);
	annihilator				= CreateConVar("rank_annihilator_points",		"3", "TF2Stats - Points:Pyro - The Neon Annihilator", _, true, 0.0);
	guillotine				= CreateConVar("rank_guillotine_points",		"4", "TF2Stats - Points:Scout - The Flying Guillotine", _, true, 0.0);
	recorder				= CreateConVar("rank_recorder_points",			"1", "TF2Stats - Points:Spy - The Red-Tape Recorder", _, true, 0.0);


	//Events
	killsapperpoints		= CreateConVar("rank_killsapperpoints",			"1", "TF2Stats - Points:Generic - Sapper Kill", _, true, 0.0);
	killteleinpoints		= CreateConVar("rank_killteleinpoints",			"1", "TF2Stats - Points:Generic - Tele Kill", _, true, 0.0);
	killteleoutpoints		= CreateConVar("rank_killteleoutpoints",		"1", "TF2Stats - Points:Generic - Tele Kill", _, true, 0.0);
	killdisppoints			= CreateConVar("rank_killdisppoints",			"2", "TF2Stats - Points:Generic - Dispensor Kill", _, true, 0.0);
	killsentrypoints		= CreateConVar("rank_killsentrypoints",			"3", "TF2Stats - Points:Generic - Sentry Kill", _, true, 0.0);

	//Other cvars
	v_RankCheckTimeout			= CreateConVar("rank_player_check_rank_timeout",	"300.0", "TF2Stats - Time time to make players wait before they check check 'rank' again", _, true, 1.0, false);
	v_TimeOffset				= CreateConVar("rank_time_offset",					"0", "TF2Stats - Number of seconds to change the server timestamp by", _, true, 0.0);
	showrankonroundend			= CreateConVar("rank_showrankonroundend",			"1", "TF2Stats - Shows player's ranks on Roundend", _, true, 0.0);
	roundendranktochat			= CreateConVar("rank_show_roundend_rank_in_chat",	"0", "TF2Stats - Prints all connected players' ranks to chat on round end (will spam chat!)", _, true, 0.0);
	showSessionStatsOnRoundEnd	= CreateConVar("rank_show_kdr_onroundend",			"1", "TF2Stats - Show clients their session stats and kill/death ratio when the round ends", _, true, 0.0);
	removeoldplayers			= CreateConVar("rank_removeoldplayers",				"0", "TF2Stats - Enable automatic removal of players who don't connect within a specific number of days. (Old records will be removed on round end)", _, true, 0.0);
	removeoldplayersdays		= CreateConVar("rank_removeoldplayersdays",			"0", "TF2Stats - Number of days to keep players in database (since last connection)", _, true, 0.0);
	killasipoints				= CreateConVar("rank_killasipoints",				"2", "TF2Stats - Points:Generic - Kill Asist", _, true, 0.0);

	Capturepoints		= CreateConVar("rank_capturepoints",				"2", "TF2Stats - Points:Generic - Capture Points", _, true, 0.0);
	Captureblockpoints	= CreateConVar("rank_blockcapturepoints",			"4", "TF2Stats - Points:Generic - Capture Block Points", _, true, 0.0);
	FileCapturepoints	= CreateConVar("rank_filecapturepoints",			"4", "TF2Stats - Points:Generic - CTF Capture Points (Whole team bonus)", _, true, 0.0);
	CTFCapPlayerPoints	= CreateConVar("rank_filecapturepoints_player",		"20", "TF2Stats - Points:Generic - CTF Capture Points (Capping player)", _, true, 0.0);
	CPCapPlayerPoints	= CreateConVar("rank_pointcapturepoints_player",	"10", "TF2Stats - Points:Generic - Control Point Capture Points (Capping player)", _, true, 0.0);

	showrankonconnect		= CreateConVar("rank_show_on_connect",			"4", "TF2Stats - Show player's rank on connect, 0 = Disabled, 1 = To Client, 2 = Public Chat, 3 = Panel (Client only), 4 = Panel + Public Chat", _, true, 0.0, true, 4.0);
	webrank					= CreateConVar("rank_webrank",					"0", "TF2Stats - Enable/Disable Webrank", _, true, 0.0, true, 1.0);
	webrankurl				= CreateConVar("rank_webrankurl",				"", "TF2Stats - Webrank URL, example: http://yoursite.com/stats/", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	neededplayercount		= CreateConVar("rank_neededplayers",			"4", "TF2Stats - How many clients are needed to start ranking", _, true, 0.0);
	disableafterwin			= CreateConVar("rank_disableafterroundwin",		"1", "TF2Stats - Disable kill counting after round ends", _, true, 0.0, true, 1.0);
	pointmsg				= CreateConVar("rank_pointmsg",					"2", "TF2Stats - Show point earned message to: 0 = disabled, 1 = all, 2 = only who earned", _, true, 0.0, true, 2.0);
	CV_chattag				= CreateConVar("rank_chattag",					"RANK",	"TF2Stats - Set the Chattag");
	CV_showchatcommands		= CreateConVar("rank_showchatcommands",			"1", "TF2Stats - show chattags 1=enable 0=disable", _, true, 0.0, true, 1.0);
	ConnectSound			= CreateConVar("rank_connectsound",				"1", "TF2Stats - Play a sound when a player connects? 1= Yes 0 = No", _, true, 0.0, true, 1.0);
	ConnectSoundFile		= CreateConVar("rank_connectsoundfile",			"buttons/blip1.wav", "TF2Stats - Sound to play when a player connects (plays for all players)");
	ConnectSoundTop10		= CreateConVar("rank_connectsoundtop10",		"0", "TF2Stats - Play a special sound for players in the Top 10", _, true, 0.0);
	ConnectSoundFileTop10	= CreateConVar("rank_connectsoundfiletop10",	"tf2stats/top10.wav", "TF2Stats - Sound to play for Top10s");

	CountryCodeHandler	= CreateConVar("rank_connectcountry",			"3", "TF2Stats - How to display connecting player's country, 0 = Don't show country, 1 = two char: (US, CA, etc), 2 = three char: (USA, CAN, etc), 3 = Full country name: (United States, etc)", 0, true, 0.0, true, 3.0);
	showranktoall		= CreateConVar("rank_showranktoall",			"1", "TF2Stats - Show player's rank to everybody");
	ignorebots 			= CreateConVar("rank_ignorebots",				"1", "TF2Stats - Give bots points? 1/0 - 0 allows bots to get points");
	ignoreTeamKills		= CreateConVar("rank_ignoreteamkills",			"1", "TF2Stats - 1 = Teamkills are ignored, 0 = Teamkills are tracked", 0, true, 0.0, true, 1.0);
	ShowTeleNotices		= CreateConVar("rank_show_tele_point_notices",	"1", "TF2Stats - 1 = Tell the engi when a player uses their tele, 0 = Don't show the message", 0, true, 0.0, true, 1.0);
	logips				= CreateConVar("rank_logips",					"1", "TF2Stats - Log player's ip addresses 1/0"); //new v6:6

	ShowEnoughPlayersNotice	= CreateConVar("rank_show_player_count_notice",			"1", "TF2Stats - Set to 0 to hide the 'there are enough players' messages", 0, true, 0.0, true, 1.0);
	ShowRoundEnableNotice	= CreateConVar("rank_show_round_enable_disable_notice",	"1", "TF2Stats - Set to 0 to hide the rank enabled/disabled due to round start/end notices", 0, true, 0.0, true, 1.0);

	//Death points
	Scoutdiepoints		= CreateConVar("rank_Scoutdiepoints",		"2", "TF2Stats - Points Scouts lose when killed", _, true, 0.0);
	Soldierdiepoints	= CreateConVar("rank_Soldierdiepoints",		"2", "TF2Stats - Points Soldiers lose when killed", _, true, 0.0);
	Pyrodiepoints		= CreateConVar("rank_Pyrodiepoints",		"2", "TF2Stats - Points Pyros lose when killed", _, true, 0.0);
	Medicdiepoints		= CreateConVar("rank_Medicdiepoints",		"2", "TF2Stats - Points Medics lose when killed", _, true, 0.0);
	Sniperdiepoints		= CreateConVar("rank_Sniperdiepoints",		"2", "TF2Stats - Points Snipers lose when killed", _, true, 0.0);
	Spydiepoints		= CreateConVar("rank_Spydiepoints",			"2", "TF2Stats - Points Spies lose when killed", _, true, 0.0);
	Demomandiepoints	= CreateConVar("rank_Demomandiepoints",		"2", "TF2Stats - Points Demos lose when killed", _, true, 0.0);
	Heavydiepoints		= CreateConVar("rank_Heavydiepoints",		"2", "TF2Stats - Points Heavies lose when killed", _, true, 0.0);
	Engineerdiepoints	= CreateConVar("rank_Engineerdiepoints",	"2", "TF2Stats - Points Engineers lose when killed", _, true, 0.0);

	//---========---
	CV_rank_enable = CreateConVar("rank_enable", "1", "1 Enables / 0 Disables gaining points", _, true, 0.0, true, 1.0);
	//---========---

	//VIPs

	vip_points1 = CreateConVar("rank_vip_points1", "0", "TF2Stats - Points players earn for killing VIP #1", _, true, 0.0, true, 1.0);
	vip_points2 = CreateConVar("rank_vip_points2", "0", "TF2Stats - Points players earn for killing VIP #2", _, true, 0.0, true, 1.0);
	vip_points3 = CreateConVar("rank_vip_points3", "0", "TF2Stats - Points players earn for killing VIP #3", _, true, 0.0, true, 1.0);
	vip_points4 = CreateConVar("rank_vip_points4", "0", "TF2Stats - Points players earn for killing VIP #4", _, true, 0.0, true, 1.0);
	vip_points5 = CreateConVar("rank_vip_points5", "0", "TF2Stats - Points players earn for killing VIP #5", _, true, 0.0, true, 1.0);

	vip_steamid1 = CreateConVar("rank_vip_steamid1", "", "TF2Stats - SteamID of VIP #1");
	vip_steamid2 = CreateConVar("rank_vip_steamid2", "", "TF2Stats - SteamID of VIP #2");
	vip_steamid3 = CreateConVar("rank_vip_steamid3", "", "TF2Stats - SteamID of VIP #3");
	vip_steamid4 = CreateConVar("rank_vip_steamid4", "", "TF2Stats - SteamID of VIP #4");
	vip_steamid5 = CreateConVar("rank_vip_steamid5", "", "TF2Stats - SteamID of VIP #5");

	vip_message1 = CreateConVar("rank_vip_message1", "", "TF2Stats - Extra text to show players who kill VIP #1", _, true, 0.0, true, 1.0);
	vip_message2 = CreateConVar("rank_vip_message2", "", "TF2Stats - Extra text to show players who kill VIP #2", _, true, 0.0, true, 1.0);
	vip_message3 = CreateConVar("rank_vip_message3", "", "TF2Stats - Extra text to show players who kill VIP #3", _, true, 0.0, true, 1.0);
	vip_message4 = CreateConVar("rank_vip_message4", "", "TF2Stats - Extra text to show players who kill VIP #4", _, true, 0.0, true, 1.0);
	vip_message5 = CreateConVar("rank_vip_message5", "", "TF2Stats - Extra text to show players who kill VIP #5", _, true, 0.0, true, 1.0);
}

void HookEvents()	{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_builtobject", Event_player_builtobject);
	HookEvent("object_destroyed", Event_object_destroyed);
	HookEvent("teamplay_round_win", Event_round_end);
	HookEvent("teamplay_point_captured", Event_point_captured);
	//HookEvent("ctf_flag_captured", Event_flag_captured);
	HookEvent("teamplay_flag_event", FlagEvent);
	HookEvent("teamplay_capture_blocked", Event_capture_blocked);
	HookEvent("player_invulned", Event_player_invulned);
	HookEvent("teamplay_round_active", Event_teamplay_round_active);
	HookEvent("arena_round_start", Event_teamplay_round_active);
	HookEvent("player_stealsandvich", Event_player_stealsandvich);
	HookEvent("player_teleported", Event_player_teleported);
	HookEvent("player_extinguished", Event_player_extinguished);
	HookEvent("player_stunned", Event_player_stunned);

	//Halloween 2011!
	HookEvent("eyeball_boss_killer", OnEyeBossDeath);
	HookEvent("eyeball_boss_stunned", OnEyeBossStunned);
}

void OnEyeBossDeath(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		int client = event.GetInt("player_entindex");
		char SteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		char query[512];
		int iPoints = EyeBossKillAssist.IntValue;

		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, EyeBossKills = EyeBossKills + 1 WHERE STEAMID = '%s'", sTableName, iPoints, SteamID);
		sessionpoints[client] = sessionpoints[client] + iPoints;
		db.Query(SQLErrorCheckCallback, query);
		int pointmsgval = pointmsg.IntValue;
		if(pointmsgval >=1)	{
			if(pointmsgval == 1)
				PrintToChatAll("\x04[%s]\x05 %N\x01 got %i points for helping to kill \x06The Monoculus!!", CHATTAG, client, iPoints);
			else if (cookieshowrankchanges[client])
				PrintToChat(client,"\x04[%s]\x01 you got %i points for helping to kill \x06The Monoculus!!", CHATTAG, iPoints);
		}
	}
}

void OnEyeBossStunned(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		int client = event.GetInt("player_entindex");
		char SteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		char query[512];
		int iPoints = EyeBossStun.IntValue;

		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, EyeBossStuns = EyeBossStuns + 1 WHERE STEAMID = '%s'", sTableName, iPoints, SteamID);
		sessionpoints[client] = sessionpoints[client] + iPoints;
		db.Query(SQLErrorCheckCallback, query);
		int pointmsgval = pointmsg.IntValue;
		if(pointmsgval >=1 && iPoints > 0)	{
			if(pointmsgval == 1)
				PrintToChatAll("\x04[%s]\x05 %N\x01 got %i points for stunning \x06The Monoculus!!", CHATTAG, client, iPoints);
			else if (cookieshowrankchanges[client])
				PrintToChat(client,"\x04[%s]\x01 you got %i points for stunning \x06The Monoculus!!", CHATTAG, iPoints);
		}
	}
}


void Event_player_stunned(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		int victim = GetClientOfUserId(event.GetInt("victim"));
		int attacker = GetClientOfUserId(event.GetInt("stunner"));
		bool bigstun = event.GetBool("big_stun");
		
		if(attacker != 0 && !IsFakeClient(attacker))	{
			char steamId[MAX_LINE_WIDTH];
			GetClientAuthId(attacker, AuthId_Steam2, steamId, sizeof(steamId));
			char query[512];
			int pointvalue = bigstun ? big_stun_points.IntValue : stun_points.IntValue;
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, player_stunned = player_stunned + 1 WHERE STEAMID = '%s'", sTableName, pointvalue, steamId);
			sessionpoints[attacker] = sessionpoints[attacker] + pointvalue;
			db.Query(SQLErrorCheckCallback,query);
			int pointmsgval = pointmsg.IntValue;
			if(pointmsgval >=1 && pointvalue > 0)	{
				if(pointmsgval == 1)	{
					if(bigstun)
						PrintToChatAll("\x04[%s]\x05 %N\x01 got %i points for stunning \x05%N\x01 (Moon Shot)", CHATTAG, attacker, pointvalue, victim);
					else
						PrintToChatAll("\x04[%s]\x05 %N\x01 got %i points for stunning \x05%N\x01", CHATTAG, attacker, pointvalue, victim);
				}
				else	{
					if(cookieshowrankchanges[attacker])	{
						if(bigstun)
							PrintToChat(attacker,"\x04[%s]\x01 you got %i points for stunning \x05%N\x01 (Moon Shot)",CHATTAG,pointvalue, victim);
						else
							PrintToChat(attacker,"\x04[%s]\x01 you got %i points for stunning \x05%N\x01",CHATTAG,pointvalue, victim);
					}
				}
			}
		}
	}
}

void Event_player_stealsandvich(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		int client = GetClientOfUserId(event.GetInt("target"));
		if(client != 0 && !IsFakeClient(client))	{
			char steamId[MAX_LINE_WIDTH];
			GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
			char query[512];
			int pointvalue = stealsandvichpoints.IntValue;
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, player_stealsandvich = player_stealsandvich + 1 WHERE STEAMID = '%s'", sTableName,pointvalue, steamId);
			sessionpoints[client] = sessionpoints[client] + pointvalue;
			db.Query(SQLErrorCheckCallback, query);
			int pointmsgval = pointmsg.IntValue;
			if(pointmsgval >= 1)	{
				int playeruid = event.GetInt("owner");
				int playerid = GetClientOfUserId(playeruid);
				if(pointmsgval == 1)
					PrintToChatAll("\x04[%s]\x01 %N got %i points for stealing %N's Sandvich", CHATTAG, client, pointvalue, playerid);
				else	{
					if(cookieshowrankchanges[client])
						PrintToChat(client,"\x04[%s]\x01 you got %i points for stealing %N's Sandvich", CHATTAG, pointvalue, playerid);
				}
			}
		}
	}
}

void Event_player_invulned(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		int userid = event.GetInt("medic_userid");
		int client = GetClientOfUserId(userid);
		if(overchargescoring[client])	{
			overchargescoring[client] = false;
			overchargescoringtimer[client] = CreateTimer(40.0, resetoverchargescoring, client);
			char steamIdassister[MAX_LINE_WIDTH];
			GetClientAuthId(client, AuthId_Steam2, steamIdassister, sizeof(steamIdassister));
			char query[512];

			/*
			#############################
			# 							#
			#		-- Bot Check --		#
			#							#
			#############################
			*/

			bool isbotassist;
			switch(StrEqual(steamIdassister, "BOT"))	{
				case	true:	{
					// Player is assister. Assister is a bot
					isbotassist = true;
					//PrintToChatAll("Assister is a BOT");
				}
				case	false:	{
					//Not a bot.
					isbotassist = false;
					//PrintToChatAll("Killer is not a BOT");
				}
			}
			
			bool ShouldIgnoreBots = ignorebots.BoolValue;
			if(ShouldIgnoreBots == false)
				isbotassist = false;

			int pointvalue = overchargepoints.IntValue;
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, Overcharge = Overcharge + 1 WHERE STEAMID = '%s'", sTableName,pointvalue, steamIdassister);
			sessionpoints[client] = sessionpoints[client] + pointvalue;
			if(isbotassist == false)
				db.Query(SQLErrorCheckCallback, query);
			
			int pointmsgval = pointmsg.IntValue;
			if(pointmsgval >= 1)	{
				char medicname[MAX_LINE_WIDTH];
				GetClientName(client, medicname, sizeof(medicname));
				int playeruid = event.GetInt("userid");
				int playerid = GetClientOfUserId(playeruid);
				char playername[MAX_LINE_WIDTH];
				GetClientName(playerid,playername, sizeof(playername));
				if(pointmsgval == 1)
					PrintToChatAll("\x04[%s]\x01 %s got %i points for Ubercharging %s",CHATTAG,medicname,pointvalue,playername);
				else	{
					if(cookieshowrankchanges[client])
						PrintToChat(client,"\x04[%s]\x01 you got %i points for Ubercharging %s",CHATTAG,pointvalue,playername);
				}
			}
		}
	}
}


void Event_PlayerDeath(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		if(db == null && dbReconnect == null)	{
			dbReconnect = CreateTimer(900.0, ReconnectToDB);
			return;
		}
		
		int victimId = event.GetInt("userid");
		int attackerId = event.GetInt("attacker");
		int assisterId = event.GetInt("assister");
		int deathflags = event.GetInt("death_flags");
		bool nofakekill = true;

		int df_assisterrevenge = 0;
		int df_killerrevenge = 0;
		int df_assisterdomination = 0;
		int df_killerdomination = 0;

		if(deathflags & 32)
			nofakekill = false;

		if(deathflags & 8)
			df_assisterrevenge = 1;

		if(deathflags & 4)
			df_killerrevenge = 1;

		if(deathflags & 2)
			df_assisterdomination = 1;

		if(deathflags & 1)
			df_killerdomination = 1;

		int assister = GetClientOfUserId(assisterId);
		int victim = GetClientOfUserId(victimId);
		int attacker = GetClientOfUserId(attackerId);
		int customkill = event.GetInt("customkill");

		bool isknife = false;
		char attackername[MAX_LINE_WIDTH];
		int pointvalue = killasimedipoints.IntValue;
		int pointmsgval = pointmsg.IntValue;

		// Teamkill check
		TFTeam aTeam = view_as<TFTeam>(-1);
		if(attacker != 0)
			aTeam = TF2_GetClientTeam(attacker);
			
		TFTeam vTeam = TF2_GetClientTeam(victim);

		if(aTeam != vTeam || !ignoreTeamKills.BoolValue)	{
			if(attacker != 0)	{
				if(attacker != victim)	{
					char steamIdassister[MAX_LINE_WIDTH];
					GetClientName(attacker, attackername, sizeof(attackername));
					char query[512];
					if(assister != 0)	{
						sessionassi[assister]++;
						GetClientAuthId(assister, AuthId_Steam2, steamIdassister, sizeof(steamIdassister));
						//new class = TF2_GetPlayerClass(assister) //changed from TF_GetClass

						/*
						#############################
						# 							#
						#		-- Bot Check --		#
						#							#
						#############################
						*/

						bool isbotassist;
						switch(StrEqual(steamIdassister, "BOT"))	{
							case	true:	{
								// Player is assister. Assister is a bot
								isbotassist = true;
								//PrintToChatAll("Assister is a BOT");
							}
							case	false:	{
								//Not a bot.
								isbotassist = false;
								//PrintToChatAll("Assister is not a BOT");
							}
						}
						
						if(!ignorebots.BoolValue)
							isbotassist = false;

						switch(TF2_GetPlayerClass(assister) == TFClass_Medic)	{ //changed from == 5
							case	true:	{
								if(nofakekill)	{
									Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KillAssistMedic = KillAssistMedic + 1 WHERE STEAMID = '%s'", sTableName,pointvalue, steamIdassister);
	
									if(!isbotassist)
										db.Query(SQLErrorCheckCallback, query);
									
									sessionpoints[assister] = sessionpoints[assister] + pointvalue;
								}
							}
							case	false:	{
								if(nofakekill)	{
									pointvalue = killasipoints.IntValue;
									Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KillAssist = KillAssist + 1 WHERE STEAMID = '%s'", sTableName,pointvalue, steamIdassister);
	
									if(!isbotassist)
										db.Query(SQLErrorCheckCallback, query);
									
									sessionpoints[assister] = sessionpoints[assister] + pointvalue;
								}
							}
						}

						if(pointmsgval >= 1)	{
							char assiname[MAX_LINE_WIDTH];
							GetClientName(assister,assiname, sizeof(assiname));
							
							switch(pointmsgval == 1)	{
								case	true:	PrintToChatAll("\x04[%s]\x01 %s got %i points for assisting %s",CHATTAG,assiname,pointvalue,attackername);
								case	false:	{
									if(cookieshowrankchanges[assister])
										PrintToChat(assister,"\x04[%s]\x01 you got %i points for assisting %s",CHATTAG,pointvalue,attackername);
								}
							}
						}

						if(df_assisterdomination && !isbotassist)	{
							Format(query, sizeof(query), "UPDATE %s SET Domination = Domination + 1 WHERE STEAMID = '%s'", sTableName,steamIdassister);
							db.Query(SQLErrorCheckCallback, query);
						}

						if(df_assisterrevenge && !isbotassist)	{
							Format(query, sizeof(query), "UPDATE %s SET Revenge = Revenge + 1 WHERE STEAMID = '%s'", sTableName, steamIdassister);
							db.Query(SQLErrorCheckCallback, query);
						}
					}

					char weapon[64];
					event.GetString("weapon_logclassname", weapon, sizeof(weapon));
					PrintToConsole(attacker,"[TF2 Stats Debug] Weapon %s",weapon);

					char steamIdattacker[MAX_LINE_WIDTH];
					char steamIdavictim[MAX_LINE_WIDTH];
					GetClientAuthId(attacker, AuthId_Steam2, steamIdattacker, sizeof(steamIdattacker));
					GetClientAuthId(victim, AuthId_Steam2, steamIdavictim, sizeof(steamIdavictim));

					/*
					#############################
					# 							#
					#		-- Bot Check --		#
					#			Attacker		#
					#############################
					*/


					bool isbot;
					switch(StrEqual(steamIdattacker, "BOT"))	{
						case	true:	{
							//Attacker is a bot
							isbot = true;
							//PrintToChatAll("Killer is a BOT");
						}
						case	false:	{
							//Not a bot
							isbot = false;
							//PrintToChatAll("Killer is not a BOT");
						}
					}
					
					if (!ignorebots.BoolValue)
						isbot = false;

					/*
					#############################
					# 							#
					#		-- Bot Check --		#
					#			Victim			#
					#############################
					*/

					bool isvicbot;
					switch(StrEqual(steamIdavictim, "BOT"))	{
						case	true:	{
							// Player is victim. Victim is a bot
							isvicbot = true;
						}
						case	false:	{
							//Not a bot.
							isvicbot = false;
						}
					}
					
					if(!ignorebots.BoolValue)
						isvicbot = false;

					switch(TF2_GetPlayerClass(attacker))	{
						case	TFClass_Sniper:	{
							Format(query, sizeof(query), "UPDATE %s SET SniperKills = SniperKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_Medic:	{
							Format(query, sizeof(query), "UPDATE %s SET MedicKills = MedicKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_Soldier:	{
							Format(query, sizeof(query), "UPDATE %s SET SoldierKills = SoldierKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_Pyro:	{
							Format(query, sizeof(query), "UPDATE %s SET PyroKills = PyroKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_DemoMan:	{
							Format(query, sizeof(query), "UPDATE %s SET DemoKills = DemoKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_Engineer:	{
							Format(query, sizeof(query), "UPDATE %s SET EngiKills = EngiKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_Spy:	{
							Format(query, sizeof(query), "UPDATE %s SET SpyKills = SpyKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_Scout:	{
							Format(query, sizeof(query), "UPDATE %s SET ScoutKills = ScoutKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						case	TFClass_Heavy:	{
							Format(query, sizeof(query), "UPDATE %s SET HeavyKills = HeavyKills + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
					}

					/*
						------- VIP Checks --------
					*/

					char VIPSteamID1[32];
					char VIPSteamID2[32];
					char VIPSteamID3[32];
					char VIPSteamID4[32];
					char VIPSteamID5[32];

					vip_steamid1.GetString(VIPSteamID1, sizeof(VIPSteamID1));
					vip_steamid2.GetString(VIPSteamID2, sizeof(VIPSteamID2));
					vip_steamid3.GetString(VIPSteamID3, sizeof(VIPSteamID3));
					vip_steamid4.GetString(VIPSteamID4, sizeof(VIPSteamID4));
					vip_steamid5.GetString(VIPSteamID5, sizeof(VIPSteamID5));

					char VIPMessage[512];
					int bonuspoints = 0;
					if(StrEqual(steamIdavictim, VIPSteamID1, false))	{
						//VIP #1
						bonuspoints = vip_points1.IntValue;
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, bonuspoints, steamIdattacker);
						if(nofakekill && !isbot)	{
							db.Query(SQLErrorCheckCallback, query);
							//Chat
							vip_message1.GetString(VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[%s]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}
					}
					else if(StrEqual(steamIdavictim, VIPSteamID2, false))	{
						//VIP #2
						bonuspoints = vip_points2.IntValue;
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, bonuspoints, steamIdattacker);
						if(nofakekill && !isbot){
							db.Query(SQLErrorCheckCallback, query);
							//Chat
							vip_message2.GetString(VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[%s]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}
					}
					else if(StrEqual(steamIdavictim, VIPSteamID3, false))	{
						//VIP #3
						bonuspoints = vip_points3.IntValue;
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, bonuspoints, steamIdattacker);
						if(nofakekill && !isbot)	{
							db.Query(SQLErrorCheckCallback, query);
							//Chat
							vip_message3.GetString(VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[%s]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}
					}
					else if(StrEqual(steamIdavictim, VIPSteamID4, false))	{
						//VIP #4
						bonuspoints = vip_points4.IntValue;
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, bonuspoints, steamIdattacker);
						if(nofakekill && !isbot)	{
							db.Query(SQLErrorCheckCallback, query);
							//Chat
							vip_message4.GetString(VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[%s]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}
					}
					else if(StrEqual(steamIdavictim, VIPSteamID5, false))	{
						//VIP #5
						bonuspoints = vip_points5.IntValue;
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, bonuspoints, steamIdattacker);
						if(nofakekill && !isbot)	{
							db.Query(SQLErrorCheckCallback, query);
							//Chat
							vip_message5.GetString(VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[%s]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}
					}

					//------ End VIP stuff ----------

					int iHealing = GetEntProp(victim, Prop_Send, "m_iHealPoints");
					//PrintToChatAll("%N healed a total of %i", victim, iHealing)
					int currentHeal = iHealing - TotalHealing[victim];
					//PrintToChatAll("%N healed %i this life", victim, currentHeal)
					TotalHealing[victim] = iHealing;

					if(currentHeal > 0)	{
						Format(query, sizeof(query), "UPDATE %s SET MedicHealing = MedicHealing + %i WHERE STEAMID = '%s'", sTableName, currentHeal, steamIdavictim);
						db.Query(SQLErrorCheckCallback, query);
						//PrintToChatAll("Data Sent")
					}

					/*
					#5. Add point-adding queries
					*/

					int diepointsvalue;
					char DeathClass[128];
					switch(TF2_GetPlayerClass(victim))	{
						case	TFClass_Sniper:	{
							diepointsvalue = Sniperdiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "SniperDeaths");
						}
						case	TFClass_Medic:	{
							diepointsvalue = Medicdiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "MedicDeaths");
						}
						case	TFClass_Soldier:	{
							diepointsvalue = Soldierdiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "SoldierDeaths");
						}
						case	TFClass_Pyro:	{
							diepointsvalue = Pyrodiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "PyroDeaths");
						}
						case	TFClass_DemoMan:	{
							diepointsvalue = Demomandiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "DemoDeaths");
						}
						case	TFClass_Engineer:	{
							diepointsvalue = Engineerdiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "EngiDeaths");
						}
						case	TFClass_Spy:	{
							diepointsvalue = Spydiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "SpyDeaths");
						}
						case	TFClass_Scout:	{
							diepointsvalue = Scoutdiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "ScoutDeaths");
						}
						case	TFClass_Heavy:	{
							diepointsvalue = Heavydiepoints.IntValue;
							strcopy(DeathClass, sizeof(DeathClass), "HeavyDeaths");
						}
					}

					switch(nofakekill)	{
						case	true:	{
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i, %s = %s + 1, Death = Death + 1 WHERE STEAMID = '%s'", sTableName, diepointsvalue, DeathClass, DeathClass, steamIdavictim);
							sessiondeath[victim]++;
							sessionpoints[victim] = sessionpoints[victim] - diepointsvalue;
						}
						case	false:	Format(query, sizeof(query), "UPDATE %s SET player_feigndeath = player_feigndeath + 1 WHERE STEAMID = '%s'", sTableName, steamIdavictim);
					}
					
					if(isvicbot == false) //player killed is not a bot, so death++ and points -X
						db.Query(SQLErrorCheckCallback, query);
					
					if(pointmsgval >= 1)	{
						char victimname[MAX_LINE_WIDTH];
						GetClientName(victim,victimname, sizeof(victimname));

						switch(pointmsgval == 1 && diepointsvalue > 0)	{
							case	true:	PrintToChatAll("\x04[%s]\x01 %s lost %i points for dying",CHATTAG,victimname,diepointsvalue);
							case	false:	{
								if(cookieshowrankchanges[victim] && diepointsvalue > 0)	{
									if(nofakekill && !isbot)
										PrintToChat(victim,"\x04[%s]\x01 you lost %i points for dying",CHATTAG,diepointsvalue);
								}
							}
						}
					}

					if(df_killerdomination && !isbot)	{
						Format(query, sizeof(query), "UPDATE %s SET Domination = Domination + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
						db.Query(SQLErrorCheckCallback, query);
					}
					if(df_killerrevenge && !isbot)	{
						Format(query, sizeof(query), "UPDATE %s SET Revenge = Revenge + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
						db.Query(SQLErrorCheckCallback, query);
					}
					if(nofakekill && !isbot)	{
						sessionkills[attacker]++;
						
						if(StrEqual(weapon, "scattergun", false))	{
							pointvalue = scattergunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sg = KW_Sg + 1 WHERE steamId = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "bat", false))	{
							pointvalue = batpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bt = KW_Bt + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "pistol_scout", false))	{
							pointvalue = pistolpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Pistl = KW_Pistl + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "tf_projectile_rocket", false))	{
							//Fixy for valve's stupidity
							int weaponent = GetPlayerWeaponSlot(attacker, 0);
							if(weaponent > 0 && IsValidEdict(weaponent) && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 228)	{
								//its a Black-Box!
								// Changed in one of the updates around 1/10
								pointvalue = blackboxpoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_blackbox = KW_blackbox + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
							// /Fixy for valve's stupidity
							else	{
								pointvalue = tf_projectile_rocketpoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Rkt = KW_Rkt + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(StrEqual(weapon, "blackbox", false))	{
							pointvalue = blackboxpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_blackbox = KW_blackbox + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "shotgun_soldier", false))	{
							pointvalue = shotgunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "shovel", false))	{
							pointvalue = shovelpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Shvl = KW_Shvl + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "flamethrower", false))	{
							pointvalue = flamethrowerpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ft = KW_Ft + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "fireaxe", false))	{
							pointvalue = fireaxepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Axe = KW_Axe + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "shotgun_pyro", false))	{
							pointvalue = shotgunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Sleeping Dogs Promo Update---------------------------------
						else if(StrEqual(weapon, "long_heatmaker", false))	{
							pointvalue = long_heatmaker.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, long_heatmaker = long_heatmaker + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "annihilator", false))	{
							pointvalue = annihilator.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, annihilator = annihilator + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "guillotine", false))	{
							pointvalue = guillotine.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, guillotine = guillotine + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "recorder", false))	{
							pointvalue = recorder.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, recorder = recorder + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Sleeping Dogs Promo Update---------------------------------
						//----------------------------Assassin's Creed Promo Update---------------------------------
						else if(StrEqual(weapon, "sharp_dresser", false))	{
							pointvalue = Sharp_Dresser_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sharp_dresser = KW_sharp_dresser + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Assassin's Creed Promo Update---------------------------------
	
						//----------------------------Christmas 2011 Update---------------------------------
						else if(StrEqual(weapon, "phlogistinator", false))	{
							pointvalue = Phlogistinator_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_phlogistinator = KW_phlogistinator + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "manmelter", false))	{
							pointvalue = Manmelter_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_manmelter = KW_manmelter + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "thirddegree", false))	{
							pointvalue = Thirddegree_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_thirddegree = KW_thirddegree + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "holiday_punch", false))	{
							pointvalue = Holiday_Punch_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_holiday_punch = KW_holiday_punch + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						// Meet the pyro items
						else if(StrEqual(weapon, "pep_brawlerblaster", false))	{
							pointvalue = Brawlerblaster_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, pep_brawlerblaster = pep_brawlerblaster + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "pep_pistol", false))	{
							pointvalue = Pep_pistol_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, pep_pistol = pep_pistol + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "dumpster_device", false))	{
							pointvalue = Dumpster_Device_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, dumpster_device = dumpster_device + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "unique_pickaxe_escape", false))	{
							pointvalue = Pickaxe_Escape_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, unique_pickaxe_escape = unique_pickaxe_escape + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "rainblower", false))	{
							pointvalue = Rainblower_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, rainblower = rainblower + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "scorchshot", false))	{
							pointvalue = Scorchshot_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, scorchshot = scorchshot + 1 WHERE STEAMID = '%s'", sTableName, pointvalue, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "lollichop", false))	{
							pointvalue = Lollichop_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, lollichop = lollichop + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "armageddon", false))	{
							pointvalue = Armageddon_taunt_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, armageddon = armageddon + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "pro_rifle", false))	{
							pointvalue = Pro_rifle_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, pro_rifle = pro_rifle + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "pro_smg", false))	{
							pointvalue = Pro_smg_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, pro_smg = pro_smg + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//-------
						else if(StrEqual(weapon, "pomson", false))	{
							pointvalue = Pomson_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pomson = KW_pomson + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "eureka_effect", false))	{
							pointvalue = Eureka_Effect_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_eureka_effect = KW_eureka_effect + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "spy_cicle", false))	{
							pointvalue = Spy_Cicle_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_spy_cicle = KW_spy_cicle + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Christmas 2011 Update---------------------------------
	
						//----------------------------Halloween 2011 Update---------------------------------
						else if(StrEqual(weapon, "nonnonviolent_protest", false))	{
							pointvalue = Objector_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ConscientiousObjector = KW_ConscientiousObjector + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "unarmed_combat", false))	{
							pointvalue = Unarmed_Combat_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_UnarmedCombat = KW_UnarmedCombat + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "scotland_shard", false))	{
							pointvalue = Scottish_Handshake_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ScottishHandshake = KW_ScottishHandshake + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "voodoo_pin", false))	{
							pointvalue = Wanga_Prick_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_WangaPrick = KW_WangaPrick + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Halloween 2011 Update---------------------------------
						//----------------------------Quakecon Update---------------------------------
						else if(StrEqual(weapon, "quake_rl", false))	{
							pointvalue = Quake_RocketLauncher_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_QuakeRL = KW_QuakeRL + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Deus Ex Update---------------------------------
						else if(StrEqual(weapon, "widowmaker", false))	{
							pointvalue = WidowmakerPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Widowmaker = KW_Widowmaker + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "short_circuit", false))	{
							pointvalue = Short_CircuitPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Short_Circuit = KW_Short_Circuit + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "machina", false))	{
							pointvalue = Machina_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Machina = KW_Machina + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "player_penetration", false))	{
							pointvalue = Machina_DoubleKill_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Machina_DoubleKill = KW_Machina_DoubleKill + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "diamondback", false))	{
							pointvalue = Diamondback_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Diamondback = KW_Diamondback + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Space Update---------------------------------
						else if(StrEqual(weapon, "cow_mangler", false))	{
							pointvalue = Mangler_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mangler = KW_mangler + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "righteous_bison", false))	{
							pointvalue = RighteousBison_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bison = KW_bison + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "tf_projectile_energy_ball", false))	{
							pointvalue = ManglerReflect_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ManglerReflect = KW_ManglerReflect + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Witcher Update---------------------------------
						else if(StrEqual(weapon, "scout_sword", false))	{
							pointvalue = Scout_Sword_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_witcher_sword = KW_witcher_sword + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Red Faction: Armageddon Update---------------------------------
						else if(StrEqual(weapon, "the_maul", false))	{
							pointvalue = The_Maul_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_maul = KW_maul + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Samurai Update---------------------------------
						else if(StrEqual(weapon, "demokatana", false))	{
							pointvalue = Katana_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_katana = KW_katana + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "kunai", false))	{
							pointvalue = Kunai_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_kunai = KW_kunai + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(strcmp(weapon, "warfan", false))	{
							pointvalue = Warfan_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_warfan = KW_warfan + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Samurai Update---------------------------------
						//----------------------------Summer Update---------------------------------
						else if(StrEqual(weapon, "mailbox", false))	{
							pointvalue = Mailbox_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mailbox = KW_mailbox + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "nessieclub", false))	{
							pointvalue = Golfclub_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_golfclub = KW_golfclub + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------Summer Update---------------------------------
						//----------------------------Uber Update---------------------------------
						else if(StrEqual(weapon, "soda_popper", false))	{
							pointvalue = Popper_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_soda_popper = KW_soda_popper + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "the_winger", false))	{
							pointvalue = Winger_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_the_winger = KW_the_winger + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "atomizer", false))	{
							pointvalue = Atomizer_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_atomizer = KW_atomizer + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "liberty_launcher", false))	{
							pointvalue = Liberty_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_liberty_launcher = KW_liberty_launcher + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "reserve_shooter", false))	{
							pointvalue = ReserveShooter_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_reserve_shooter = KW_reserve_shooter + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "disciplinary_action", false))	{
							pointvalue = DisciplinaryAction_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_disciplinary_action = KW_disciplinary_action + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "market_gardener", false))	{
							pointvalue = MarketGardener_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_market_gardener = KW_market_gardener + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "mantreads", false))	{
							pointvalue = Mantreads_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mantreads = KW_mantreads + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "detonator", false))	{
							pointvalue = Detonator_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_detonator = KW_detonator + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "persian_persuader", false))	{
							pointvalue = Persian_Persuader_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_persian_persuader = KW_persian_persuader + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "splendid_screen", false))	{
							pointvalue = Splendid_Screen_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_splendid_screen = KW_splendid_screen + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "tomislav", false))	{
							pointvalue = Tomislav_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tomislav = KW_tomislav + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "family_business", false))	{
							pointvalue = Family_Business_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_family_business = KW_family_business + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "eviction_notice", false))	{
							pointvalue = Eviction_Notice_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_eviction_notice = KW_eviction_notice + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "proto_syringe", false))	{
							pointvalue = Proto_Syringe_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_proto_syringe = KW_proto_syringe + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "solemn_vow", false))	{
							pointvalue = Solemn_Vow_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_solemn_vow = KW_solemn_vow + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "bazaar_bargain", false))	{
							pointvalue = Bazaar_Bargain_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bazaar_bargain = KW_bazaar_bargain + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "shahanshah", false))	{
							pointvalue = Shahanshah_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_shahanshah = KW_shahanshah + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "enforcer", false))	{
							pointvalue = Enforcer_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_enforcer = KW_enforcer + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "big_earner", false))	{
							pointvalue = Big_Earner_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_big_earner = KW_big_earner + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------End Uber Update---------------------------------
						else if(StrEqual(weapon, "taunt_soldier_lumbricus", false))	{
							pointvalue = worms_grenade_points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_worms_grenade = KW_worms_grenade + 1 WHERE STEAMID = '%s'", pointvalue, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "tf_projectile_pipe", false))	{
							int weaponent = GetPlayerWeaponSlot(attacker, 0);
							if(weaponent > 0 && IsValidEdict(weaponent) && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 308)	{
								// Loch-n-Load
								// Fixed 1/10
								pointvalue = lochnloadPoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_lochnload = KW_lochnload + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
							else	{
								pointvalue = tf_projectile_pipepoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Gl = KW_Gl + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(StrEqual(weapon, "loch_n_load", false))	{
							pointvalue = lochnloadPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_lochnload = KW_lochnload + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "tf_projectile_pipe_remote", false))	{
							pointvalue = tf_projectile_pipe_remotepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sky = KW_Sky + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "bottle", false))	{
							pointvalue = bottlepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bttl = KW_Bttl + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "minigun", false))	{
							pointvalue = minigunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_CG = KW_CG + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "fists", false) || StrEqual(weapon, "tf_weapon_fists", false))	{
							pointvalue = fistspoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Fsts = KW_Fsts + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "shotgun_hwg", false))	{
							pointvalue = shotgunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "obj_sentrygun", false))	{
							pointvalue = obj_sentrygunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL1 = KW_SntryL1 + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "obj_sentrygun2", false))	{
							pointvalue = obj_sentrygunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL2 = KW_SntryL2 + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "obj_sentrygun3", false))	{
							pointvalue = obj_sentrygunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL3 = KW_SntryL3 + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "wrench", false))	{
							pointvalue = wrenchpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Wrnc = KW_Wrnc + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "wrench_golden", false))	{
							pointvalue = wrenchpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Wrnc = KW_Wrnc + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "pistol", false))	{
							pointvalue = pistolpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Pistl = KW_Pistl + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "fryingpan", false))	{
							pointvalue = fryingpanpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_fryingpan = KW_fryingpan + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "robot_arm_combo_kill", false))	{
							pointvalue = robot_arm_combo_killPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm_combo_kill = KW_robot_arm_combo_kill + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "shotgun_primary", false))	{
							pointvalue = shotgunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "bonesaw", false))	{
							pointvalue = bonesawpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bnsw = KW_Bnsw + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "syringegun_medic", false))	{
							pointvalue = syringegun_medicpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ndl = KW_Ndl + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "club", false))	{
							pointvalue = clubpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Mctte = KW_Mctte + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "smg", false))	{
							pointvalue = smgpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Smg = KW_Smg + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "headtaker", false))	{
							pointvalue = headtakerpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_headtaker = KW_headtaker + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "sniperrifle", false))	{
							//Fixy for valve's stupidity
							int weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
							if(weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 230)	{
								//itza Sydney Sleeper!
								// Changed in one of the updates around 1/10
								pointvalue = sleeperpoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sleeperrifle = KW_sleeperrifle + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
							// /Fixy for valve's stupidity
							else	{
								pointvalue = sniperriflepoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Spr = KW_Spr + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(StrEqual(weapon, "sydney_sleeper", false))	{
							pointvalue = sleeperpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sleeperrifle = KW_sleeperrifle + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//Random insert of engi update shizz;
						else if(StrEqual(weapon, "samrevolver", false))	{
							pointvalue = samrevolverpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_samrevolver = KW_samrevolver + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "frontier_justice", false))	{
							pointvalue = frontier_justicePoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_frontier_justice = KW_frontier_justice + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "wrangler_kill", false))	{
							pointvalue = wrangler_killPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_wrangler_kill = KW_wrangler_kill + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "robot_arm", false))	{
							pointvalue = robot_armPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm = KW_robot_arm + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "maxgun", false))	{
							pointvalue = maxgunPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_maxgun = KW_maxgun + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "southern_hospitality", false))	{
							pointvalue = southern_hospitalityPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_southern_hospitality = KW_southern_hospitality + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "bleed_kill", false))	{
							pointvalue = bleed_killPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bleed_kill = KW_bleed_kill + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "robot_arm_blender_kill", false))	{
							pointvalue = robot_arm_blender_killPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm_blender_kill = KW_robot_arm_blender_kill + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "taunt_guitar_kill", false))	{
							pointvalue = taunt_guitar_killPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_guitar_kill = KW_taunt_guitar_kill + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//engi
						else if(StrEqual(weapon, "revolver", false))	{
							pointvalue = revolverpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Mgn = KW_Mgn + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "knife", false))	{
							isknife = true;
							pointvalue = knifepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Kn = KW_Kn + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "ubersaw", false))	{
							pointvalue = ubersawpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ubersaw = KW_Ubersaw + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						// Rift crap
						else if(StrEqual(weapon, "lava_axe", false))	{
							pointvalue = LavaAxePoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_lava_axe = KW_lava_axe + 1 WHERE STEAMID = '%s'", pointvalue, steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "lava_bat", false))	{
							pointvalue = SunBatPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sun_bat = KW_sun_bat + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						// ---------
						else if(StrEqual(weapon, "rocketlauncher_directhit", false))	{
							pointvalue = rocketlauncher_directhitpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_rocketlauncher_directhit = KW_rocketlauncher_directhit + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------- Polycount 1 --------------------------------
						else if(StrEqual(weapon, "short_stop", false))	{
							pointvalue = short_stoppoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_short_stop = KW_short_stop + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "holy_mackerel", false))	{
							pointvalue = holy_mackerelpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_holy_mackerel = KW_holy_mackerel + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "powerjack", false))	{
							pointvalue = powerjackpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_powerjack = KW_powerjack + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "degreaser", false))	{
							pointvalue = degreaserpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_degreaser = KW_degreaser + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "battleneedle", false))	{
							pointvalue = battleneedlepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_battleneedle = KW_battleneedle + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "eternal_reward", false))	{
							pointvalue = eternal_rewardpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_eternal_reward = KW_eternal_reward + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "letranger", false))	{
							pointvalue = letrangerpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_letranger = KW_letranger + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//-------------------------------------------------------
						else if(StrEqual(weapon, "telefrag", false))	{
							pointvalue = telefragpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_telefrag = KW_telefrag + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "deflect_flare", false))	{
							pointvalue = deflect_flarepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_flare = KW_deflect_flare + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "taunt_soldier", false))	{
							pointvalue = taunt_soldierpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_soldier = KW_taunt_soldier + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "goomba", false))	{
							pointvalue = goombapoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_goomba = KW_goomba + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "iron_curtain", false))	{
							pointvalue = ironcurtainpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_iron_curtain = KW_iron_curtain + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "pickaxe", false))	{
							pointvalue = pickaxepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pickaxe = KW_pickaxe + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "demoshield", false))	{
							pointvalue = demoshieldpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_demoshield = KW_demoshield + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "claidheamohmor", false))	{
							pointvalue = gaelicclaymorePoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_claidheamohmor = KW_claidheamohmor + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "sword", false))	{
							int weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
							if(weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 327)	{
								// Claidheamh Mòr
								//Fixed in 1/10 update
								pointvalue = gaelicclaymorePoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_claidheamohmor = KW_claidheamohmor + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
							else	{
								pointvalue = swordpoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sword = KW_sword + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(StrEqual(weapon, "taunt_demoman", false))	{
							pointvalue = taunt_demomanpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_demoman = KW_taunt_demoman + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "sticky_resistance", false))	{
							pointvalue = sticky_resistancepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sticky_resistance = KW_sticky_resistance + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "flaregun", false))	{
							pointvalue = flaregunpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Flaregun = KW_Flaregun + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "axtinguisher", false))	{
							pointvalue = axtinguisherpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Axtinguisher = KW_Axtinguisher + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "wrap_assassin", false))	{
							pointvalue = WrapAssassin_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_wrap_assassin = KW_wrap_assassin + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "apocofists", false))	{
							pointvalue = ApocoFists_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_apocofists = KW_apocofists + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "black_rose", false))	{
							pointvalue = BlackRose_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_black_rose = KW_black_rose + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "taunt_pyro", false))	{
							pointvalue = taunt_pyropoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_pyro = KW_taunt_pyro + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "gloves_running_urgently", false))	{
							pointvalue = urgentglovespoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_urgentgloves = KW_urgentgloves + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "gloves", false))	{
							//Fixy for valve's stupidity
							int weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
							if(weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 239)	{
								//itza Gloves of Running Urgently!
								//Fixed around 1/10
								pointvalue = urgentglovespoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_urgentgloves = KW_urgentgloves + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
							// /Fixy for valve's stupidity
							else	{
								pointvalue = glovespoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_gloves = KW_gloves + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(StrEqual(weapon, "taunt_heavy", false))	{
							pointvalue = taunt_heavypoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_heavy = KW_taunt_heavy + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "backburner", false))	{
							pointvalue = backburnerpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_backburner = KW_backburner + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "natascha", false))	{
							int weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
							if(weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 312)	{
								// Brass Beast
								// Fixed in an update around 1/10
								pointvalue = BrassBeastPoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_brassbeast = KW_brassbeast + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
							else	{
								pointvalue = nataschapoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_natascha = KW_natascha + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(StrEqual(weapon, "brass_beast", false))	{
							pointvalue = BrassBeastPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_brassbeast = KW_brassbeast + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "bushwacka", false))	{
							pointvalue = bushwackapoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bushwacka = KW_bushwacka + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//Begin custom weapon update
						else if(StrEqual(weapon, "tribalkukri", false))	{
							//Fixy for valve's stupidity
							int weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
							if(weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 232)	{
								//itza bushwacka!
								//Valve fixed this in 1/10 update
								pointvalue = bushwackapoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bushwacka = KW_bushwacka + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
							// /Fixy for valve's stupidity
							else	{
								pointvalue = woodknifepoints.IntValue;
								Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tribalkukri = KW_tribalkukri + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(StrEqual(weapon, "obj_minisentry", false))	{
							pointvalue = MinisentryPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_minisentry = KW_minisentry + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "ullapool_caber_explosion", false))	{
							pointvalue = UllaExplodePoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ullapool_caber_explosion = KW_ullapool_caber_explosion + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "battleaxe", false))	{
							pointvalue = battleaxepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_battleaxe = KW_battleaxe + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "ball", false))	{
							pointvalue = ballpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ball = KW_ball + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "paintrain", false))	{
							pointvalue = paintrainpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_paintrain = KW_paintrain + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "sledgehammer", false))	{
							pointvalue = sledgehammerpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sledgehammer = KW_sledgehammer + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "unique_pickaxe", false))	{
							pointvalue = uniquepickaxepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_unique_pickaxe = KW_unique_pickaxe + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "tf_pumpkin_bomb", false))	{
							pointvalue = pumpkinpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pumpkin = KW_pumpkin + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//End custom weapon update
						else if(StrEqual(weapon, "blutsauger", false))	{
							pointvalue = blutsaugerpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_blutsauger = KW_blutsauger + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "deflect_rocket", false))	{
							pointvalue = deflect_rocketpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_rocket = KW_deflect_rocket + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "deflect_promode", false))	{
							pointvalue = deflect_promodepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_promode = KW_deflect_promode + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "deflect_sticky", false))	{
							pointvalue = deflect_stickypoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_sticky = KW_deflect_sticky + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//-------------------- Christmas 2010 Update --------------------
						//Weapons with incorrect kill strings will be elsewhere
						else if(StrEqual(weapon, "candy_cane", false))	{
							pointvalue = candy_canePoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_candy_cane = KW_candy_cane + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "boston_basher", false))	{
							pointvalue = boston_basherPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_boston_basher = KW_boston_basher + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "back_scratcher", false))	{
							pointvalue = back_scratcherPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_back_scratcher = KW_back_scratcher + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "ullapool_caber", false))	{
							pointvalue = ullapool_caberPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ullapool_caber = KW_ullapool_caber + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//else if(StrEqual(weapon, "bear_claws", false))
						else if(StrEqual(weapon, "warrior_spirit", false))	{
							pointvalue = bear_clawsPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bearclaws = KW_bearclaws + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "steel_fists", false))	{
							pointvalue = steel_fistsPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_steelfists = KW_steelfists + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "wrench_jag", false))	{
							pointvalue = wrench_jagPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_wrench_jag = KW_wrench_jag + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "amputator", false))	{
							pointvalue = amputatorPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_amputator = KW_amputator + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//else if(StrEqual(weapon, "tf_projectile_healing_bolt", false)) changed to crusaders_crossbow
						else if(StrEqual(weapon, "crusaders_crossbow", false))	{
							pointvalue = medicCrossbowPoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_healingcrossbow = KW_healingcrossbow + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						//----------------------------------------------------------
						else if(StrEqual(weapon, "world", false))	{
							pointvalue = worldpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_world = KW_world + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "bat_wood", false))	{
							pointvalue = bat_woodpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bat_wood = KW_bat_wood + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "tf_projectile_arrow", false))	{
							pointvalue = tf_projectile_arrowpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tf_projectile_arrow = KW_tf_projectile_arrow + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "ambassador", false))	{
							pointvalue = ambassadorpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ambassador = KW_ambassador + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "taunt_sniper", false))	{
							pointvalue = taunt_sniperpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_sniper = KW_taunt_sniper + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "taunt_spy", false))	{
							pointvalue = taunt_spypoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_spy = KW_taunt_spy + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "force_a_nature", false))	{
							pointvalue = force_a_naturepoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_force_a_nature = KW_force_a_nature + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "sandman", false))	{
							pointvalue = sandmanpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sandman = KW_sandman + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "compound_bow", false))	{
							pointvalue = compound_bowpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_compound_bow = KW_compound_bow + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "taunt_scout", false))	{
							pointvalue = taunt_scoutpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_scout = KW_taunt_scout + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "deflect_arrow", false))	{
							pointvalue = deflect_arrowpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_arrow = KW_deflect_arrow + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "jar", false))	{
							pointvalue = killasipoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_jar = KW_jar + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "saxxy", false))	{
							pointvalue = Saxxy_Points.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Saxxy = KW_Saxxy + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
						else if(StrEqual(weapon, "player", false)
						|| StrEqual(weapon, "prop_physics")
						|| StrEqual(weapon, "builder")
						|| StrEqual(weapon, "pda_engineer_build"))
							pointvalue = 0;
						else	{
					//		char file[PLATFORM_MAX_PATH];
					//		BuildPath(Path_SM, file, sizeof(file), "logs/TF2STATS_WEAPONERRORS.log");
					//		LogToFile(file,"Weapon: %s", weapon)
							
							pointvalue = 3;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
							db.Query(SQLErrorCheckCallback, query);
						}
					}
					char additional[MAX_LINE_WIDTH];
					int iBPN = 0;
					if(nofakekill && !isbot)	{
						sessionpoints[attacker] = sessionpoints[attacker] + pointvalue;
						if(customkill == 2 && !isbot)	{
							if(isknife)	{
								Format(query, sizeof(query), "UPDATE %s SET K_backstab = K_backstab + 1 WHERE STEAMID = '%s'", sTableName, steamIdattacker);
								Format(additional, sizeof(additional), "with a Backstab");
								db.Query(SQLErrorCheckCallback, query);
							}
						}
						else if(customkill == 1 && !isbot)	{
							iBPN = headshotpoints.IntValue;
							Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, HeadshotKill = HeadshotKill + 1 WHERE STEAMID = '%s'", sTableName, iBPN, steamIdattacker);
							Format(additional, sizeof(additional), "with a Headshot");
							db.Query(SQLErrorCheckCallback, query);
						}
						else Format(additional, sizeof(additional), "");
					}
					if(pointmsgval >= 1)	{
						char victimname[MAX_LINE_WIDTH];
						GetClientName(victim,victimname, sizeof(victimname));

						if(pointvalue + iBPN != 0)	{
							if(pointmsgval == 1)
								PrintToChatAll("\x04[%s]\x01 %s got %i points for killing %s %s",CHATTAG,attackername,pointvalue + iBPN,victimname,additional);
							else	{
								if(cookieshowrankchanges[attacker])
									PrintToChat(attacker,"\x04[%s]\x01 you got %i points for killing %s %s",CHATTAG,pointvalue + iBPN,victimname,additional);
							}
						}
					}
				}
			}
		}
	}
}

void Event_player_builtobject(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		char steamIdbuilder[MAX_LINE_WIDTH];
		int userId = event.GetInt("userid");
		int user = GetClientOfUserId(userId);
		int obj = event.GetInt("object");
		GetClientAuthId(user, AuthId_Steam2, steamIdbuilder, sizeof(steamIdbuilder));
		char query[512];
		// Bot Check
		if(StrEqual(steamIdbuilder,"BOT") || IsFakeClient(user))
			return;	//We should queue points to a bot.
		
		switch(obj)	{
			case	0:	{
				Format(query, sizeof(query), "UPDATE %s SET BuildDispenser = BuildDispenser + 1 WHERE STEAMID = '%s'", sTableName, steamIdbuilder);
				db.Query(SQLErrorCheckCallback, query);
			}
			case	1:	{
				Format(query, sizeof(query), "UPDATE %s SET BOTeleporterentrace = BOTeleporterentrace + 1 WHERE STEAMID = '%s'", sTableName, steamIdbuilder);
				db.Query(SQLErrorCheckCallback, query);
				
				Format(query, sizeof(query), "UPDATE %s SET BOTeleporterExit = BOTeleporterExit + 1 WHERE STEAMID = '%s'", sTableName, steamIdbuilder);
				db.Query(SQLErrorCheckCallback, query);
			}
			case	2:	{
				Format(query, sizeof(query), "UPDATE %s SET BuildSentrygun = BuildSentrygun + 1 WHERE STEAMID = '%s'", sTableName, steamIdbuilder);
				db.Query(SQLErrorCheckCallback, query);
			}
			case	3:	{
				Format(query, sizeof(query), "UPDATE %s SET BOSapper = BOSapper + 1 WHERE STEAMID = '%s'", sTableName, steamIdbuilder);
				db.Query(SQLErrorCheckCallback, query);
			}
		}
	}
}

void Event_object_destroyed(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		if(event.GetInt("userid") != event.GetInt("attacker"))	{
			int userId = event.GetInt("attacker");
			int obj = event.GetInt("objecttype");
			int user = GetClientOfUserId(userId);
			char steamIdattacker[MAX_LINE_WIDTH];
			GetClientAuthId(user, AuthId_Steam2, steamIdattacker, sizeof(steamIdattacker));
			char query[512];
			int pointvalue = 0;
			// Bot Check
			bool isbot = StrEqual(steamIdattacker,"BOT");

			//PrintToChatAll("Attacker is %s BOT", isbot ? "a" : "is not a");

			if(isbot)
				return;	//We shouldn't do anything here since it's a bot.
			
			if(!isbot)	{
				switch(obj)	{
					case	0:	{
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KODispenser = KODispenser + 1 WHERE STEAMID = '%s'", sTableName, killdisppoints.IntValue ,steamIdattacker);
						db.Query(SQLErrorCheckCallback, query);
					}
					case	1:	{
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KOTeleporterEntrace = KOTeleporterEntrace + 1 WHERE STEAMID = '%s'", sTableName, killteleinpoints.IntValue ,steamIdattacker);
						db.Query(SQLErrorCheckCallback, query);
						
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KOTeleporterExit = KOTeleporterExit + 1 WHERE STEAMID = '%s'", sTableName, killteleoutpoints.IntValue ,steamIdattacker);
						db.Query(SQLErrorCheckCallback, query);
					}
					case	2:	{
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KOSentrygun = KOSentrygun + 1 WHERE STEAMID = '%s'", sTableName, killsentrypoints.IntValue ,steamIdattacker);
						db.Query(SQLErrorCheckCallback, query);
					}
					case	3:	{
						Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KOSapper = KOSapper + 1 WHERE STEAMID = '%s'", sTableName, killsapperpoints.IntValue ,steamIdattacker);
						db.Query(SQLErrorCheckCallback, query);
					}
				}
	
				sessionpoints[user] = sessionpoints[user] + pointvalue;
				int pointmsgval = pointmsg.IntValue;
	
				if(pointmsgval >= 1)	{
					char username[MAX_LINE_WIDTH];
					GetClientName(user,username, sizeof(username));
	
					switch(pointmsgval == 1)	{
						case	true:	PrintToChatAll("\x04[%s]\x01 %s got %i points for destroying object",CHATTAG,username,pointvalue);
						case	false:	{
							if(cookieshowrankchanges[user])
								PrintToChat(user,"\x04[%s]\x01 you got %i points for destroying object",CHATTAG,pointvalue);
					
						}	
					}
				}
			}
		}
	}
}

//Action Command_Say(Event event, const char[] event_name, bool dontBroadcast)
Action Command_Say(int client, int args)	{
	//int client = GetClientOfUserId(event.GetInt("userid"));
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Continue;
	char text[512];
	bool chatcommand = false;

	//event.GetString("text", text, sizeof(text));
	GetCmdArg(1, text, sizeof(text));

	if(StrEqual(text, "!Rank", false)
	|| StrEqual(text, "Rank", false)
	|| StrEqual(text, "Place", false)
	|| StrEqual(text, "Points", false)
	|| StrEqual(text, "Stats", false))	{
		int iTime =  GetTime();
		int iElapsed = iTime - g_iLastRankCheck[client];
		int iDelayNeeded = v_RankCheckTimeout.IntValue;
		if(iElapsed < iDelayNeeded)	{
			float fTimeLeft = float(iDelayNeeded - iElapsed);
			if(fTimeLeft > 60.0)	{
				fTimeLeft = fTimeLeft/60;
				PrintToChat(client, "\x04[%s]:\x01 Sorry, please wait another \x05%-.2f minutes\x01 before checking your rank!", CHATTAG, fTimeLeft);
			}
			else PrintToChat(client, "\x04[%s]:\x01 Sorry, please wait another \x05%i seconds\x01 before checking your rank!", CHATTAG, RoundToFloor(fTimeLeft));
			return Plugin_Handled;
		}
		g_iLastRankCheck[client] = iTime;

		char steamId[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		rankpanel(client, steamId);
		chatcommand = true;
	}
	//---------Kill-Death-------
	else if(StrEqual(text, "kdeath", false)
	|| StrEqual(text, "!kdeath", false)
	|| StrEqual(text, "kdr", false)
	|| StrEqual(text, "!kdr", false)
	|| StrEqual(text, "kd", false)
	|| StrEqual(text, "killdeath", false))	{
		Echo_KillDeath(client);
		chatcommand = true;
	}
	//---------Kill-Death per Class ---------
	/*
		1 = Scout
		2 = Soldier
		3 = Pyro
		4 = Demo
		5 = Heavy
		6 = Engi
		7 = Medic
		8 = Sniper
		9 = Spy
	*/
	else if(StrEqual(text, "kdscout", false)|| StrEqual(text, "!kdscout", false))	{
		Echo_KillDeathClass(client, 1);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdsoldier", false) || StrEqual(text, "!kdsoldier", false))	{
		Echo_KillDeathClass(client, 2);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdsolly", false) || StrEqual(text, "!kdsolly", false))	{
		Echo_KillDeathClass(client, 2);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdpyro", false) || StrEqual(text, "!kdpyro", false))	{
		Echo_KillDeathClass(client, 3);
		chatcommand = true;
	}
	else if(StrEqual(text, "kddemo", false) || StrEqual(text, "!kddemo", false) || StrEqual(text, "kddemoman", false) || StrEqual(text, "kdemo", false))	{
		Echo_KillDeathClass(client, 4);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdheavy", false) || StrEqual(text, "!kdheavy", false))	{
		Echo_KillDeathClass(client, 5);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdengi", false) || StrEqual(text, "!kdengi", false))	{
		Echo_KillDeathClass(client, 6);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdengineer", false) || StrEqual(text, "!kdengineer", false))	{
		Echo_KillDeathClass(client, 6);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdmedic", false) || StrEqual(text, "!kdmedic", false))	{
		Echo_KillDeathClass(client, 7);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdsniper", false) || StrEqual(text, "!kdsniper", false))	{
		Echo_KillDeathClass(client, 8);
		chatcommand = true;
	}
	else if(StrEqual(text, "kdspy", false) || StrEqual(text, "!kdspy", false))	{
		Echo_KillDeathClass(client, 9);
		chatcommand = true;
	}
	else if(StrEqual(text, "lifetimeheals", false) || StrEqual(text, "!lifetimeheals", false))	{
		Echo_LifetimeHealz(client);
		chatcommand = true;
	}
	//------------------------------------
	else if(StrEqual(text, "Top10", false) || StrEqual(text, "Top", false) || StrEqual(text, "!Top10", false))	{
		top10pnl(client);
		chatcommand = true;
	}
	else if(StrEqual(text, "rankinfo", false))	{
		rankinfo(client);
		chatcommand = true;
	}
	else if(StrEqual(text, "players", false))
	{
		listplayers(client);
		chatcommand = true;
	}
	else if(StrEqual(text, "session", false))
	{
		session(client);
		chatcommand = true;
	}
	else if(StrEqual(text, "webtop", false))
	{
		webtop(client);
		chatcommand = true;
	}
	else if(StrEqual(text, "webrank", false))	{
		webranking(client);
		chatcommand = true;
	}
	else if(StrEqual(text, "hidepoints", false))	{
		sayhidepoints(client);
		chatcommand = true;
	}
	else if(StrEqual(text, "unhidepoints", false))	{
		sayunhidepoints(client);
		chatcommand = true;
	}

	if(!chatcommand || showchatcommands)
		return Plugin_Continue;
	return Plugin_Handled;
}

void rankinfo(int client)	{
	Panel infopanel = new Panel();
	infopanel.SetTitle("About TF2 Stats:");
	infopanel.DrawText("Plugin Coded by DarthNinja");
	//infopanel.DrawText("Based on code by R-Hehl");
	infopanel.DrawText("Visit AlliedModders.net or DarthNinja.com");
	infopanel.DrawText("For the latest version of TF2 Stats!");
	infopanel.DrawText("Contact DarthNinja for Feature Requests or Bug reports");
	char value[128];
	char tmpdbtype[10];

	Format(tmpdbtype, sizeof(tmpdbtype), "MYSQL");
	Format(value, sizeof(value), "Version %s Database Type %s",PLUGIN_VERSION ,tmpdbtype);
	infopanel.DrawText(value);
	infopanel.DrawItem("Close");
	infopanel.Send(client, InfoPanelHandler, 20);
	delete infopanel;
}

int InfoPanelHandler(Menu menu, MenuAction action, int client, int selection)	{}

Action resetshow2alltimer(Handle timer)	{
	resetshow2all();
}

void resetshow2all()	{
	showranktoall.SetBool(oldshowranktoallvalue);
}

void Event_round_end(Event event, const char[] event_name, bool dontBroadcast)	{
	g_IsRoundActive = false;
	//It's now round-end!
	if(showrankonroundend.BoolValue)	{
		oldshowranktoallvalue = showranktoall.BoolValue;
		showranktoall.SetBool(false);
		showallrank();
		CreateTimer(5.0, resetshow2alltimer);
	}

	if(removeoldplayers.BoolValue)
		removetooldplayers();

	if(disableafterwin.BoolValue)	{
		rankingactive = false;

		if(rankingenabled && ShowRoundEnableNotice.BoolValue)
			PrintToChatAll("\x04[%s]\x01 Ranking Disabled: round end",CHATTAG);
	}
}

void Event_teamplay_round_active(Event event, const char[] event_name, bool dontBroadcast)	{
	g_IsRoundActive = true;
	if(disableafterwin.BoolValue)	{
		if(neededplayercount.IntValue <= GetClientCount(true))	{
			rankingactive = true;
			if (rankingenabled && ShowRoundEnableNotice.BoolValue)
				PrintToChatAll("\x04[%s]\x01 Ranking Enabled: round start", CHATTAG);
		}
	}
}

void showallrank()	{
	for(int i = 1; i <= MaxClients; i++)	{
		if(IsClientInGame(i))	{
			char steamIdclient[MAX_LINE_WIDTH];
			GetClientAuthId(i, AuthId_Steam2, steamIdclient, sizeof(steamIdclient));
			rankpanel(i, steamIdclient);
		}
	}
}

void removetooldplayers()	{
	if(removeoldplayersdays.IntValue >= 1)	{
		int timesec = GetTime() - (removeoldplayersdays.IntValue * 86400);
		char query[512];
		Format(query, sizeof(query), "DELETE FROM %s WHERE LASTONTIME < '%i'",sTableName,timesec);
		db.Query(SQLErrorCheckCallback, query);
	}
}

void Event_point_captured(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled && cpmap)	{
		int iTeam = event.GetInt("team");
		char teamname[MAX_LINE_WIDTH];
		GetTeamName(iTeam, teamname, sizeof(teamname));
		int pointmsgval = pointmsg.IntValue;
		int pointvalue = Capturepoints.IntValue;
		if(pointvalue != 0)	{
			for(int i = 1; i <= MaxClients; i++)	{
				if(IsClientInGame(i) && GetClientTeam(i) == iTeam)	{
					if(IsFakeClient(i) && ignorebots.BoolValue)
						break;

					char SteamID[MAX_LINE_WIDTH];
					GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
					char query[512];

					//Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, CPCaptured = CPCaptured + 1 WHERE STEAMID = '%s'",pointvalue ,SteamID);
					Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, pointvalue, SteamID);
					db.Query(SQLErrorCheckCallback, query);

					sessionpoints[i] = sessionpoints[i] + pointvalue;
					if(pointmsgval >= 1 && cookieshowrankchanges[i])
						PrintToChat(i,"\x04[%s]\x01 %s Team got %i points for capturing a point!", CHATTAG, teamname, pointvalue);
				}
			}
		}
		int iPoints = CPCapPlayerPoints.IntValue;
		if(iPoints != 0)	{
			char CappedBy[MAXPLAYERS+1] = {"", ...};
			event.GetString("cappers", CappedBy, MAXPLAYERS);
			int x = strlen(CappedBy);
			//PrintToChatAll("Point capped by %i total players!", x);

			for(int i = 0; i < x; i++)	{
				int client = CappedBy[i];
				if(IsFakeClient(client) && ignorebots.BoolValue)
					break;

				char SteamID[MAX_LINE_WIDTH];
				GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
				char query[512];
				Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, CPCaptured = CPCaptured + 1 WHERE STEAMID = '%s'", sTableName, iPoints, SteamID);
				db.Query(SQLErrorCheckCallback, query);
				if(pointmsgval >= 1 && cookieshowrankchanges[i])
					PrintToChat(client, "\x04[%s]\x01 You got %i points for capturing a point!", CHATTAG, iPoints);
			}
		}
	}
}

//void Event_flag_captured(Event event, const char[] event_name, bool dontBroadcast)
void FlagEvent(Event event, const char[] event_name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled && event.GetInt("eventtype") == FlagCaptured)	{
		int client = GetEventInt(event, "player");
		int iCappingTeam = GetClientTeam(client);

		int pointmsgval = pointmsg.IntValue;
		int iTeamPointValue = FileCapturepoints.IntValue;
		int iPlayerPointValue = CTFCapPlayerPoints.IntValue;

		if(iTeamPointValue != 0)	{
			for(int i = 1; i <= MaxClients; i++)	{
				if(!IsClientInGame(i))
					break;
				if(GetClientTeam(i) != iCappingTeam)
					break;
				if(IsFakeClient(i) && ignorebots.BoolValue)
					break;

				char SteamID[MAX_LINE_WIDTH];
				GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
				char query[512];
				//Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, FileCaptured = FileCaptured + 1 WHERE STEAMID = '%s'", sTableName, pointvalue ,steamIdattacker);
				Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, iTeamPointValue, SteamID);
				db.Query(SQLErrorCheckCallback, query);

				sessionpoints[i] = sessionpoints[i] + iTeamPointValue;

				if(pointmsgval >= 1 && cookieshowrankchanges[i])	{
					char teamname[MAX_LINE_WIDTH];
					GetTeamName(iCappingTeam, teamname, sizeof(teamname));
					PrintToChat(i, "\x04[%s]\x01 %s Team got %i points for capturing the intel!", CHATTAG, teamname, iTeamPointValue);
				}
			}
		}
		//solo points here
		if(iPlayerPointValue != 0)	{
			sessionpoints[client] = sessionpoints[client] + iPlayerPointValue;
			if(IsFakeClient(client) && ignorebots.BoolValue)
				return;

			char SteamID[MAX_LINE_WIDTH];
			GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
			char query[512];
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, FileCaptured = FileCaptured + 1 WHERE STEAMID = '%s'", sTableName, iPlayerPointValue, SteamID);
			db.Query(SQLErrorCheckCallback, query);

			if(pointmsgval >= 1 && cookieshowrankchanges[client])
				PrintToChat(client, "\x04[%s]\x01 You got %i points for capturing the intel!", CHATTAG, iPlayerPointValue);
		}
	}
	return;
}

void Event_capture_blocked(Event event, const char[] name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled && cpmap)	{
		int client = event.GetInt("blocker");
		if(client > 0)	{
			if(IsFakeClient(client) && ignorebots.BoolValue)
				return;

			int pointvalue = Captureblockpoints.IntValue;
			if(pointvalue != 0)	{
				char SteamID[MAX_LINE_WIDTH];
				GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
				char query[512];
				Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, CPBlocked = CPBlocked + 1 WHERE STEAMID = '%s'", sTableName, pointvalue, SteamID);
				db.Query(SQLErrorCheckCallback, query);

				sessionpoints[client] = sessionpoints[client] + pointvalue;

				int pointmsgval = pointmsg.IntValue;
				if(pointmsgval >= 1)	{
					char playername[MAX_LINE_WIDTH];
					GetClientName(client, playername, sizeof(playername));

					if(pointmsgval == 1)
						PrintToChatAll("\x04[%s]\x01 %s got %i points for Blocking a Capture", CHATTAG, playername, pointvalue);
					else if(cookieshowrankchanges[client])
						PrintToChat(client, "\x04[%s]\x01 you got %i points for Blocking a Capture", CHATTAG, pointvalue);
				}
			}
		}
	}
}

Action DelayOnMapStart(Handle timer)	{
	OnMapStart();
}

public void OnMapStart()	{
	// If the plugin is late loaded, OnMapStart will be called before the database connects
	// Here we will check to see if there is a connection, and if not retry in 10 seconds
	if(db == null)	{
		CreateTimer(10.0, DelayOnMapStart);
		return;
	}
		
	if(ConnectSound.BoolValue)	{
		char SoundFile[128];
		ConnectSoundFile.GetString(SoundFile, sizeof(SoundFile));

		if(!StrEqual(SoundFile, ""))	{ //Added safety
			PrecacheSound(SoundFile);
			char SoundFileLong[192];
			Format(SoundFileLong, sizeof(SoundFileLong), "sound/%s", SoundFile);
			AddFileToDownloadsTable(SoundFileLong);
		}
	}

	if(ConnectSoundTop10.BoolValue)	{
		char SoundFile2[128];
		ConnectSoundFileTop10.GetString(SoundFile2, sizeof(SoundFile2));

		if(!StrEqual(SoundFile2, ""))	{ //Added safety
			PrecacheSound(SoundFile2);
			char SoundFileLong2[192];
			Format(SoundFileLong2, sizeof(SoundFileLong2), "sound/%s", SoundFile2);
			AddFileToDownloadsTable(SoundFileLong2);
		}
	}

	MapInit();
	char name[MAX_LINE_WIDTH];
	GetCurrentMap(name,MAX_LINE_WIDTH);

	cpmap = ((StrContains(name, "cp_", false) != -1)
	|| (StrContains(name, "tc_", false) != -1)
	|| (StrContains(name, "pl_", false) != -1)
	|| (StrContains(name, "plr_", false) != -1)
	|| (StrContains(name, "arena_", false) != -1));
}

public void OnMapEnd()	{
	mapisset = 0;
	resetshow2all();
}

void MapInit()	{
	if(mapisset == 0)	{
		if(classfunctionloaded == 0)	{
			maxplayers = MaxClients;
			maxents = GetMaxEntities();
			ResourceEnt = FindResourceObject();

			if(ResourceEnt == -1)	{
				LogMessage("Achtung! Server could not find player data table");
				classfunctionloaded = 1;
			}
		}
	}
}

stock int FindResourceObject()	{
	int i;
	char classname[64];

	//Isn't there a easier way?
	//FindResourceObject does not work

	for(i = maxplayers; i <= maxents; i++)	{
		if(IsValidEntity(i))	{
			GetEntityNetClass(i, classname, 64);

			if(StrEqual(classname, "CTFPlayerResource"))	{
				//LogMessage("Found CTFPlayerResource at %d", i)
				return i;
			}
		}
	}
	return -1;
}

void updateplayername(int client)
{
	// !NAME!
	char steamId[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	char name[MAX_LINE_WIDTH];
	GetClientName(client, name, sizeof(name));
	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), "<?", "");
	ReplaceString(name, sizeof(name), "?>", "");
	ReplaceString(name, sizeof(name), "`", "");
	ReplaceString(name, sizeof(name), ",", "");
	ReplaceString(name, sizeof(name), "<?PHP", "");
	ReplaceString(name, sizeof(name), "<?php", "");
	ReplaceString(name, sizeof(name), "<", "[");
	ReplaceString(name, sizeof(name), ">", "]");
	char query[512];
	Format(query, sizeof(query), "UPDATE %s SET NAME = '%s' WHERE STEAMID = '%s'", sTableName, name, steamId);
	db.Query(SQLErrorCheckCallback, query);
	char ip[20];
	GetClientIP(client, ip, sizeof(ip));
	char ClientSteamID[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));

	if(logips.BoolValue)	{
		char buffer[255];
		Format(buffer, sizeof(buffer), "UPDATE %s SET IPAddress = '%s' WHERE STEAMID = '%s'", sTableName, ip, ClientSteamID);
		db.Query(SQLErrorCheckCallback, buffer);
	}
}

void initonlineplayers()	{
	for(int i = 1; i <= MaxClients; i++)	{
		if(IsClientInGame(i))	{
			updateplayername(i);
			InitializeClientonDB(i);
		}
	}
}

Action Rank_GivePoints(int client, int args)	{
	if(args != 2)	{
		ReplyToCommand(client, "Usage: rank_givepoints <Player> <Value to Add>");
		return Plugin_Handled;
	}

	char buffer[64];
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));
	if((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	int iPointsAdd = StringToInt(buffer);
	char query[512];
	char TargetSteamID[MAX_LINE_WIDTH];

	for(int i = 0; i < target_count; i ++)	{
		GetClientAuthId(target_list[i], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, iPointsAdd, TargetSteamID);
		db.Query(SQLErrorCheckCallback, query);
	}

	ReplyToCommand(client, "\x04[%s]\x01: Gave \x04%s\x01 \x05%i\x01 points!", CHATTAG, target_name, iPointsAdd);
	return Plugin_Handled;
}

Action Rank_RemovePoints(int client, int args)	{
	if(args != 2)	{
		ReplyToCommand(client, "Usage: rank_removepoints <Player> <Value to Remove>");
		return Plugin_Handled;
	}

	char buffer[64];
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));
	if((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	int iPointsRemove = StringToInt(buffer);
	char query[512];
	char TargetSteamID[MAX_LINE_WIDTH];

	for(int i = 0; i < target_count; i ++)	{
		GetClientAuthId(target_list[i], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i WHERE STEAMID = '%s'", sTableName, iPointsRemove, TargetSteamID);
		db.Query(SQLErrorCheckCallback, query);
	}

	ReplyToCommand(client, "\x04[%s]\x01: Removed \x05%i\x01 points from \x04%s's\x01 ranking!", CHATTAG, iPointsRemove, target_name);
	return Plugin_Handled;
}

Action Rank_SetPoints(int client, int args)	{
	if(args != 2)	{
		ReplyToCommand(client, "Usage: rank_setpoints <Player> <New Value>");
		return Plugin_Handled;
	}

	char buffer[64];
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));
	if((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	int iPointsNew = StringToInt(buffer);
	char query[512];
	char TargetSteamID[MAX_LINE_WIDTH];

	for(int i = 0; i < target_count; i ++)	{
		GetClientAuthId(target_list[i], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = %i WHERE STEAMID = '%s'", sTableName, iPointsNew, TargetSteamID);
		db.Query(SQLErrorCheckCallback, query);
	}

	ReplyToCommand(client, "\x04[%s]\x01: Set \x04%s's\x01 Ranking points to \x05%i\x01!", CHATTAG, target_name, iPointsNew);
	return Plugin_Handled;
}


Action Rank_ResetCTFCaps(int client, int args)	{
	char query[512];
	Format(query, sizeof(query), "UPDATE `%s` SET `FileCaptured` = '0' WHERE `FileCaptured` != '0' ;", sTableName);
	db.Query(SQLErrorCheckCallback, query);

	ReplyToCommand(client, "All FileCaptured records have been reset to 0.");
	return Plugin_Handled;
}

Action Rank_ResetCPCaps(int client, int args)	{
	char query[512];
	Format(query, sizeof(query), "UPDATE `%s` SET `CPCaptured` = '0' WHERE `CPCaptured` != '0' ;", sTableName);
	db.Query(SQLErrorCheckCallback, query);

	ReplyToCommand(client, "All CPCaptured records have been reset to 0.");
	return Plugin_Handled;
}

Action Menu_RankAdmin(int client, int args)	{
	Menu menu = new Menu(MenuHandlerRankAdmin);
	menu.SetTitle("Rank Admin Menu");
	//menu.AddItem("reset", "Reset TF2 Stats Database");  I think this is a bad idea...
	menu.AddItem("reload", "Reload TF2 Stats Plugin");
	menu.AddItem("givepoints", "Give Points");
	menu.AddItem("removepoints", "Remove Points");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

/*
###################################
##		  Rank Admin Main		 ##
###################################
*/
int MenuHandlerRankAdmin(Menu menu, MenuAction action, int client, int selection)	{
	switch(action)	{
		case	MenuAction_Select:	{
			char sSelection[64];
			menu.GetItem(selection, sSelection, sizeof(sSelection));
	
			if(StrEqual("reset", sSelection))	{
				//resetdb()
				PrintToChat(client, "This command has been disabled for safety!  \n Edit 'MenuHandlerRankAdmin' to enable.");
			}
			else if(StrEqual("reload", sSelection))	{
				char FileName[64];
				GetPluginFilename(null, FileName, sizeof(FileName));
				PrintToChat(client, "\x04[%s]\x01: Reloading plugin file %s", CHATTAG, FileName);
				ServerCommand("sm plugins reload %s", FileName);
			}
			else if(StrEqual("givepoints", sSelection))	{
				//PrintToChat(client, "givepoints selected");
	
				Menu menuNext = new Menu(MenuHandler_GivePoints);
	
				menuNext.SetTitle("Select Client:");
				menu.ExitBackButton = true;
	
				AddTargetsToMenu2(menuNext, client, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED);
	
				menuNext.Display(client, MENU_TIME_FOREVER);
			}
			else if(StrEqual("removepoints", sSelection))	{
				Menu menuNext = new Menu(MenuHandler_RemovePoints);
	
				menuNext.SetTitle("Select Client:");
				menu.ExitBackButton = true;
	
				AddTargetsToMenu2(menuNext, client, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED);
	
				menuNext.Display(client, MENU_TIME_FOREVER);
			}
		}
		case	MenuAction_End:	delete menu;
		
	}
}

/*
###################################
##		  Add Points Menu		 ##
###################################
*/

int MenuHandler_GivePoints(Menu menu, MenuAction action, int client, int selection)	{
	switch(action)	{
		case	MenuAction_Select:	{
			char strTarget[32];
			int userid, target;
	
			menu.GetItem(selection, strTarget, sizeof(strTarget));
			userid = StringToInt(strTarget);
	
			switch((target = GetClientOfUserId(userid)) == 0)	{
				case	true:	PrintToChat(client, "[SM] That player is no longer available");
				case	false:	{
					g_iMenuTarget[client] = target;
					
					Menu menuNext = new Menu(MenuHandler_GivePointsHandler);
					menuNext.SetTitle("Points to Add:");
					
					menuNext.AddItem("1", "1 Point");
					menuNext.AddItem("5", "5 Points");
					menuNext.AddItem("10", "10 Points");
					menuNext.AddItem("25", "25 Points");
					menuNext.AddItem("50", "50 Points");
					menuNext.AddItem("100", "100 Points");
					menuNext.AddItem("250", "250 Points");
					menuNext.AddItem("500", "500 Points");
					menuNext.AddItem("1000", "1000 Points");
					menuNext.AddItem("2500", "2500 Points");
					menuNext.AddItem("5000", "5000 Points");
					menuNext.AddItem("1000000", "ONE MILLION POINTS #Trololo");
					
					menuNext.ExitButton = true;
					menuNext.Display(client, MENU_TIME_FOREVER);
				}
			}
			
			//PrintToChat(client, "player selected");
		}
		case	MenuAction_End:	delete menu;
	}
}


int MenuHandler_GivePointsHandler(Menu menu, MenuAction action, int client, int selection)	{
	switch(action)	{
		case	MenuAction_Select:	{
			char strPoints[32];
			menu.GetItem(selection, strPoints, sizeof(strPoints));
			//PrintToChat(client, "Selection %s", strPoints);
	
			//------------------
	
			int bonuspointvalue = StringToInt(strPoints);
			char query[512];
			char TargetSteamID[MAX_LINE_WIDTH];
			GetClientAuthId(g_iMenuTarget[client], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
	
			//ShowActivity2(client, "\x04[%s]\x01 ","Increased \x04%N's\x01 ranking by awarding them \x05%i\x01 points!", CHATTAG, g_iMenuTarget[client], bonuspointvalue);
			//PrintToChat(g_iMenuTarget[client], "\x04[%s]\x01: \x04%N\x01 increased your ranking by giving you \x05%i\x01 bonus points!", CHATTAG, client, bonuspointvalue);
	
			PrintToChatAll("\x04[%s]\x01: \x04%N\x01 Increased \x04%N's\x01 ranking by awarding them \x05%i\x01 points!", CHATTAG, client, g_iMenuTarget[client], bonuspointvalue);
	
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, bonuspointvalue, TargetSteamID);
			db.Query(SQLErrorCheckCallback, query);
		}
		case	MenuAction_End: delete menu;
	}
}

/*
###################################
##		 Remove Points Menu		 ##
###################################
*/

int MenuHandler_RemovePoints(Menu menu, MenuAction action, int client, int selection)	{
	//PrintToChat(client, "player selected");
	switch(action)	{
		case	MenuAction_Select:	{
			char strTarget[32];
			int userid, target;
	
			menu.GetItem(selection, strTarget, sizeof(strTarget));
			userid = StringToInt(strTarget);
	
			switch ((target = GetClientOfUserId(userid)) == 0)	{
				case	true:	PrintToChat(client, "[SM] That player is no longer available");
				case	false:	{
					g_iMenuTarget[client] = target;
					
					Menu menuNext = new Menu(MenuHandler_RemovePointsHandler);
					menuNext.SetTitle("Points to Remove:");
		
					menuNext.AddItem("1", "1 Point");
					menuNext.AddItem("5", "5 Points");
					menuNext.AddItem("10", "10 Points");
					menuNext.AddItem("25", "25 Points");
					menuNext.AddItem("50", "50 Points");
					menuNext.AddItem("100", "100 Points");
					menuNext.AddItem("250", "250 Points");
					menuNext.AddItem("500", "500 Points");
					menuNext.AddItem("1000", "1000 Points");
					menuNext.AddItem("2500", "2500 Points");
					menuNext.AddItem("5000", "5000 Points");
					menuNext.AddItem("1000000", "ONE MILLION POINTS #Trololo");
					
					menuNext.ExitButton = true;
					menuNext.Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case	MenuAction_End:	delete menu;
	}
}

int MenuHandler_RemovePointsHandler(Menu menu, MenuAction action, int client, int selection)	{
	switch(action)	{
		case	MenuAction_Select:	{
			char strPoints[32];
			menu.GetItem(selection, strPoints, sizeof(strPoints));
			//PrintToChat(client, "Selection %s", strPoints);
			
			//------------------
			
			int bonuspointvalue = StringToInt(strPoints);
			char query[512];
			char TargetSteamID[MAX_LINE_WIDTH];
			GetClientAuthId(g_iMenuTarget[client], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
			
			PrintToChatAll("\x04[%s]\x01: \x04%N\x01 Decreased \x04%N's\x01 ranking by removing \x05%i\x01 points from their ranking!", CHATTAG, client, g_iMenuTarget[client], bonuspointvalue);
			
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i WHERE STEAMID = '%s'", sTableName, bonuspointvalue, TargetSteamID);
			db.Query(SQLErrorCheckCallback, query);
		}
		case	MenuAction_End: delete menu;
	}
}


stock void resetdb()	{
	char query[512];
	Format(query, sizeof(query), "TRUNCATE TABLE %s", sTableName);
	db.Query(SQLErrorCheckCallback, query);

	initonlineplayers();
}

void listplayers(int client)	{
	Menu_playerlist(client);
}

Action Menu_playerlist(int client)	{
	Menu menu = new Menu(MenuHandlerplayerslist);
	menu.SetTitle("Online Players:");

	for(int i = 1; i <= MaxClients; i++)	{
		if(!IsClientInGame(i))
			continue;
		
		char name[65];
		GetClientName(i, name, sizeof(name));
		char steamId[MAX_LINE_WIDTH];
		GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
		menu.AddItem(steamId, name);
	}
	menu.ExitButton = true;
	menu.Display(client, 20);
	return Plugin_Handled;
}

int MenuHandlerplayerslist(Menu menu, MenuAction action, int client, int selection)	{
	/* Either Select or Cancel will ALWAYS be sent! */
	switch(action)	{
		case	MenuAction_Select:	{
			char info[32];
			menu.GetItem(selection, info, sizeof(info));
			rankpanel(client, info);
		}
		/* If the menu has ended, destroy it */
		case	MenuAction_End: delete menu;
	}
}

/* New Code Full Threaded SQL Clean Code ---------------------------------------*/
public void OnClientPostAdminCheck(int client)	{
	if(db == null)
		return;
	
	InitializeClientonDB(client);

	if(ConnectSound.BoolValue)	{
		char soundfile[MAX_LINE_WIDTH];
		ConnectSoundFile.GetString(soundfile, sizeof(soundfile));
		EmitSoundToAll(soundfile);
	}

	sessionpoints[client] = 0;
	sessionkills[client] = 0;
	sessiondeath[client] = 0;
	sessionassi[client] = 0;
	overchargescoring[client] = true;
	loadclientsettings(client);
	
	if(!rankingactive)	{
		if(neededplayercount.IntValue <= GetClientCount(true))	{
			if(g_IsRoundActive)	{
				rankingactive = true;
				if(ShowEnoughPlayersNotice.BoolValue)
					PrintToChatAll("\x04[%s]\x01 Ranking Enabled: enough players", CHATTAG);
			}
		}
	}
}

void InitializeClientonDB(int client)	{
	char ConUsrSteamID[MAX_LINE_WIDTH];
	char buffer[255];

	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT POINTS FROM %s WHERE STEAMID = '%s'",sTableName, ConUsrSteamID);
	db.Query(T_CheckConnectingUsr, buffer, GetClientUserId(client));
}

void loadclientsettings(int client)	{
	/* delaying the check to make sure the client is added correct before loading the settings */
	cookieshowrankchanges[client] = false;
	CheckCookieTimers[client] = CreateTimer(5.0, CheckMSGCookie, client);
}

Action CheckMSGCookie(Handle timer, int client)	{
	PrintToConsole(client, "[RANKDEBUG] Loading Client Settings ...");
	CheckCookieTimers[client] = null;
	char ConUsrSteamID[MAX_LINE_WIDTH];
	char buffer[255];
	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT chat_status FROM %s WHERE STEAMID = '%s'", sTableName, ConUsrSteamID);
	int conuserid;
	conuserid = GetClientUserId(client);
	db.Query(T_LoadUsrSettings1, buffer, conuserid);
}

void T_LoadUsrSettings1(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;
	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int chat_status = 0;
	
	while(results.FetchRow())
		chat_status = results.FetchInt(0);

	switch(chat_status)	{
		case	2:	cookieshowrankchanges[client] = false;
		default:	cookieshowrankchanges[client] = true;
	}
}

void T_CheckConnectingUsr(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */

	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	char clientname[MAX_LINE_WIDTH];
	GetClientName( client, clientname, sizeof(clientname) );
	ReplaceString(clientname, sizeof(clientname), "'", "");
	ReplaceString(clientname, sizeof(clientname), "<?PHP", "");
	ReplaceString(clientname, sizeof(clientname), "<?php", "");
	ReplaceString(clientname, sizeof(clientname), "<?", "");
	ReplaceString(clientname, sizeof(clientname), "?>", "");
	ReplaceString(clientname, sizeof(clientname), "<", "[");
	ReplaceString(clientname, sizeof(clientname), ">", "]");
	ReplaceString(clientname, sizeof(clientname), ",", ".");
	char ClientSteamID[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
	//Stupid buffer, its all your fault!
	char buffer[1500];
	char ip[20];
	GetClientIP(client, ip, sizeof(ip));
	
	if(!results.RowCount)	{
		/*insert user*/
		
		Format(buffer, sizeof(buffer), "INSERT INTO %s (`NAME`,`STEAMID`) VALUES ('%s','%s')", sTableName, clientname, ClientSteamID);
		db.Query(SQLErrorCheckCallback, buffer);
		
		switch(showrankonconnect.BoolValue)	{
			case	true:	{
				/*update name*/
				Format(buffer, sizeof(buffer), "UPDATE %s SET NAME = '%s' WHERE STEAMID = '%s'", sTableName, clientname, ClientSteamID);
				db.Query(SQLErrorCheckCallback, buffer);
	
				if(logips.BoolValue)	{
					char buffer2[255];
					Format(buffer2, sizeof(buffer2), "UPDATE %s SET IPAddress = '%s' WHERE STEAMID = '%s'", sTableName, ip, ClientSteamID);
					db.Query(SQLErrorCheckCallback, buffer2);
				}
	
				int clientpoints;
				while(results.FetchRow())	{
					clientpoints = results.FetchInt(0);
					onconpoints[client] = clientpoints;
					Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s` WHERE `POINTS` >=%i", sTableName, clientpoints);
					int conuserid;
					conuserid = GetClientUserId(client);
					db.Query(T_ShowrankConnectingUsr1, buffer, conuserid);
				}
			}
			case	false: PrintToChatAll("\x04[%s]\x01 Welcome %s", CHATTAG, clientname);
		}
	}
}

/*
#6. SQLite - add one 0, for each new entry (see about 25 lines above)
*/
void SQLErrorCheckCallback(Database owner, DBResultSet results, const char[] error, any data)	{
	if(!StrEqual("", error))
		LogMessage("SQL Error: %s", error);
}

void T_ShowrankConnectingUsr1(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int rank;

	while(results.FetchRow())
		rank = results.FetchInt(0);

	onconrank[client] = rank;
		
	if(showrankonconnect.BoolValue)	{
		char buffer[255];
		Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s`", sTableName);
		db.Query(T_ShowrankConnectingUsr2, buffer, userid);
	}
}

void T_ShowrankConnectingUsr2(Database owner, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;
	
	if(IsFakeClient(client))
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	while(results.FetchRow())
		rankedclients = results.FetchInt(0);

	int CCH = CountryCodeHandler.IntValue;
	
	char countrySmaller[3];
	char countrySmall[4];
	char country[50];
	char ip[20];
	GetClientIP(client, ip, sizeof(ip));
	
	switch(CCH)	{
		case	1:	{
			GeoipCode2(ip,countrySmaller);
			strcopy(country, sizeof(country), countrySmaller);
		}
		case	2:	{
			GeoipCode3(ip,countrySmall);
			strcopy(country, sizeof(country), countrySmall);
		}
		case	3:	GeoipCountry(ip, country, sizeof(country));
	}
	
	if(StrEqual(country, ""))	{
/* 		if(IsFakeClient(client))
			strcopy(country, sizeof(country), "Localhost");
		else */
		strcopy(country, sizeof(country), "Unknown");
		
		if(StrEqual(country, "United States"))
			strcopy(country, sizeof(country), "The United States");

		if(CCH != 0)	{
			switch(showrankonconnect.IntValue)	{
				case	1:	PrintToChat(client, "You are ranked \x04#%i\x01 out of \x04%i\x01 players with \x04%i\x01 points!",
							onconrank[client],rankedclients,onconpoints[client]);
				case	2:	{
					char clientname[MAX_LINE_WIDTH];
					GetClientName(client, clientname, sizeof(clientname));
					PrintToChatAll("\x04[%s]\x01 \x04%s\x01 connected from \x04%s!\x04\n[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",
					CHATTAG, clientname, country,onconrank[client],rankedclients,onconpoints[client]);
				}
				case	3:	ConRankPanel(client);
				case	4:	{
					char clientname[MAX_LINE_WIDTH];
					GetClientName(client, clientname, sizeof(clientname));
					//PrintToChatAll("\x04[%s]\x01 %s connected from %s. \x04[\x03Rank: %i out of %i\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients)
					PrintToChatAll("\x04[%s]\x01 \x04%s\x01 connected from \x04%s!\x04\n\x04[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",
					CHATTAG, clientname, country,onconrank[client],rankedclients,onconpoints[client]);
					ConRankPanel(client);
				}
			}
		}
		else	{ // country code disabled
			switch(showrankonconnect.IntValue)	{
				case	1:	PrintToChat(client, "You are ranked \x04#%i\x01 out of \x04%i\x01 players with \x04%i\x01 points!",
				onconrank[client],rankedclients,onconpoints[client]);
				case	2:	{
					char clientname[MAX_LINE_WIDTH];
					GetClientName(client, clientname, sizeof(clientname));
					PrintToChatAll("\x04[%s]\x01 \x04%s\x01 connected! \n[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",
					CHATTAG, clientname,onconrank[client],rankedclients,onconpoints[client]);
				}
				case	3:	ConRankPanel(client);
				case	4:	{
					char clientname[MAX_LINE_WIDTH];
					GetClientName(client, clientname, sizeof(clientname));
					PrintToChatAll("\x04[%s]\x01 \x04%s\x01 connected!\n\x04[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",
					CHATTAG, clientname,onconrank[client],rankedclients,onconpoints[client]);
					ConRankPanel(client);
				}
			}
		}
		
		//PrintToChatAll("[Debug] The value of onconrank[client] is %i", onconrank[client])
		if(ConnectSoundTop10.BoolValue && onconrank[client] < 10)	{
			char soundfile[MAX_LINE_WIDTH];
			ConnectSoundFileTop10.GetString(soundfile, sizeof(soundfile));
			EmitSoundToAll(soundfile);
		}
	}
}

int ConRankPanelHandler(Menu menu, MenuAction action, int client, int selection)	{}

Action ConRankPanel(int client)	{
	Panel panel = new Panel();
	char clientname[MAX_LINE_WIDTH];
	GetClientName(client, clientname, sizeof(clientname));
	char buffer[255];

	Format(buffer, sizeof(buffer), "Welcome back %s",clientname);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), "Rank: %i out of %i",onconrank[client],rankedclients);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), "Points: %i",onconpoints[client]);
	panel.DrawText(buffer);
	panel.DrawItem("Close");

	panel.Send(client, ConRankPanelHandler, 20);

	delete panel;

	return Plugin_Handled;
}

void session(int client)	{
	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s`", sTableName);
	db.Query(T_ShowSession1, buffer, GetClientUserId(client));
}

void T_ShowSession1(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	while(results.FetchRow())	{
		rankedclients = results.FetchInt(0);
		char ConUsrSteamID[MAX_LINE_WIDTH];
		char buffer[255];
		GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
		Format(buffer, sizeof(buffer), "SELECT POINTS FROM %s WHERE STEAMID = '%s'", ConUsrSteamID, sTableName);
		db.Query(T_ShowSession2, buffer, userid);
	}
}

void T_ShowSession2(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int clientpoints;
	
	while(results.FetchRow())	{
		clientpoints = results.FetchInt(0);
		playerpoints[client] = clientpoints;
		char buffer[255];
		Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s` WHERE `POINTS` >=%i", clientpoints, sTableName);
		db.Query(T_ShowSession3, buffer, userid);
	}
}

void T_ShowSession3(Database owner, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	while (results.FetchRow())
		playerrank[client] = results.FetchInt(0);
	
	char ConUsrSteamID[MAX_LINE_WIDTH];
	char buffer[255];
	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `KillAssist`, `PLAYTIME` FROM `%s` WHERE STEAMID = '%s'", sTableName, ConUsrSteamID );
	db.Query(T_ShowSession4, buffer, userid);
}

void T_ShowSession4(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int kills, death, assists, playtime;
	
	while(results.FetchRow())	{
		kills = results.FetchInt(0);
		death = results.FetchInt(1);
		assists = results.FetchInt(2);
		playtime = results.FetchInt(3);
	}
	
	SessionPanel(client, kills, death, assists, playtime);
}

void SessionPanel(int client, int kills, int death, int assists, int playtime)	{
	Panel panel = new Panel();
	char buffer[255];
	panel.SetTitle("Session Panel:");
	panel.DrawItem(" - Total");
	Format(buffer, sizeof(buffer), " Rank %i out of %i",playerrank[client],rankedclients);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), " %i Points",playerpoints[client]);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), " %i:%i Frags", kills , death);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), " %i Kill Assist", assists);
	panel.DrawText(buffer);
 	Format(buffer, sizeof(buffer), " Playtime: %i min", playtime);
	panel.DrawText(buffer);
	panel.DrawItem(" - Session");
	/*
	Format(buffer, sizeof(buffer), " Rank %i of %i",playerrank[client],rankedclients);
	panel.DrawText(buffer);
	*/
	Format(buffer, sizeof(buffer), " %i Points",sessionpoints[client]);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), " %i:%i Frags", sessionkills[client] , sessiondeath[client]);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), " %i Kill Assist", sessionassi[client]);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), " Playtime: %i min", RoundToZero(GetClientTime(client)/60));
	panel.DrawText(buffer);
	panel.Send(client, SessionRankPanelHandler, 20);

	delete panel;
}

int SessionRankPanelHandler(Menu menu, MenuAction action, int client, int selection)	{}

void webranking(int client)	{
	if(webrank.BoolValue)	{
		char rankurl[255];
		webrankurl.GetString(rankurl, sizeof(rankurl));
		char showrankurl[255];
		char UsrSteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, UsrSteamID, sizeof(UsrSteamID));

		Format(showrankurl, sizeof(showrankurl), "%splayer.php?steamid=%s&time=%i",rankurl,UsrSteamID,GetTime());
		PrintToConsole(client, "RANK MOTD-URL %s", showrankurl);
		ShowMOTDPanel(client, "Your Rank:", showrankurl, 2);
	}
}

void webtop(int client)	{
	if(webrank.BoolValue)	{
		char rankurl[255];
		webrankurl.GetString(rankurl, sizeof(rankurl));
		char showrankurl[255];
		char UsrSteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, UsrSteamID, sizeof(UsrSteamID));

		Format(showrankurl, sizeof(showrankurl), "%stop10.php?time=%i", rankurl, GetTime());
		PrintToConsole(client, "RANK MOTD-URL %s", showrankurl);
		ShowMOTDPanel(client, "Rank:", showrankurl, 2);
	}
}

void rankpanel(int client, const char[] steamid)	{
	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s`", sTableName);
	Format(ranksteamidreq[client],25, "%s" ,steamid);
	db.Query(T_ShowRank1, buffer, GetClientUserId(client));
}

void T_ShowRank1(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	while(results.FetchRow())	{
		rankedclients = results.FetchInt(0);
		char buffer[255];
		Format(buffer, sizeof(buffer), "SELECT POINTS FROM %s WHERE STEAMID = '%s'", sTableName, ranksteamidreq[client]);
		db.Query(T_ShowRank2, buffer, userid);
	}
}

void T_ShowRank2(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	while(results.FetchRow())	{
		reqplayerrankpoints[client] = results.FetchInt(0);
		char buffer[255];
		Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s` WHERE `POINTS` >=%i", sTableName, reqplayerrankpoints[client]);
		db.Query(T_ShowRank3, buffer, userid);
	}
}

void T_ShowRank3(Database owner, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	while(results.FetchRow())
		reqplayerrank[client] = results.FetchInt(0);

	char ConUsrSteamID[MAX_LINE_WIDTH];
	char buffer[255];
	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `KillAssist`, `PLAYTIME`, `NAME` FROM `%s` WHERE STEAMID = '%s'", sTableName, ranksteamidreq[client]);
	db.Query(T_ShowRank4, buffer, userid);
}

void T_ShowRank4(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	if(IsClientInGame(client))	{
		int kills, death, assists, playtime;
		
		while(results.FetchRow())	{
			kills = results.FetchInt(0);
			death = results.FetchInt(1);
			assists = results.FetchInt(2);
			playtime = results.FetchInt(3);
			results.FetchString(4, ranknamereq[client] , 32);
		}
		
		RankPanel(client, kills, death, assists, playtime);
	}
}

void RankPanel(int client, int kills, int death, int assists, int playtime)	{
	Panel panel = new Panel();
	char value[MAX_LINE_WIDTH];
	panel.SetTitle("Rank Panel:");
	Format(value, sizeof(value), "Name: %s", ranknamereq[client]);
	panel.DrawText(value);
	Format(value, sizeof(value), "Rank: %i out of %i", reqplayerrank[client],rankedclients);
	panel.DrawText(value);
	Format(value, sizeof(value), "Points: %i" , reqplayerrankpoints[client]);
	panel.DrawText(value);
	Format(value, sizeof(value), "Playtime: %i" , playtime);
	panel.DrawText(value);
	Format(value, sizeof(value), "Kills: %i" , kills);
	panel.DrawText(value);
	Format(value, sizeof(value), "Deaths: %i" , death);
	panel.DrawText(value);
	Format(value, sizeof(value), "Kill Assist: %i", assists);
	panel.DrawText(value);

	if(webrank.BoolValue)
		panel.DrawText("[TYPE webrank FOR MORE DETAILS]");

	panel.DrawItem("Close");
	panel.Send(client, SessionRankPanelHandler, 20);

	if(roundendranktochat.BoolValue || g_IsRoundActive)	{
		if(showranktoall.BoolValue)
			PrintToChatAll("\x04[%s] %s\x01 is Ranked \x04#%i\x01 out of \x04%i\x01 Players with \x04%i\x01 Points!",
			CHATTAG,ranknamereq[client],reqplayerrank[client],rankedclients,reqplayerrankpoints[client]);
		else
			PrintToChat(client, "\x04[%s] %s\x01 is Ranked \x04#%i\x01 out of \x04%i\x01 Players with \x04%i\x01 Points!",
			CHATTAG,ranknamereq[client],reqplayerrank[client],rankedclients,reqplayerrankpoints[client]);
	}

	float kdr;
	float fKills;
	float fDeaths;
	if(!g_IsRoundActive && showSessionStatsOnRoundEnd.BoolValue)	{
		fKills = float(sessionkills[client]);
		fKills = fKills + (float(sessionassi[client]) / 2.0);
		fDeaths = float(sessiondeath[client]);
		if(fDeaths == 0.0)
			fDeaths = 1.0;

		kdr = fKills / fDeaths;
		PrintToChat(client, "\x04[%s] %N:\x01 You have earned \x04%i Points\x01 this session, with \x04%i Kills\x01, \x04%i Deaths\x01, and \x04%i Assists!\x01 Your \x05Kill-to-Death\x01 ratio is \x04%.2f!\x01",
		CHATTAG, client, sessionpoints[client], sessionkills[client], sessiondeath[client], sessionassi[client], kdr);
	}

	delete panel;
}

stock int RankPanelHandler(Menu menu, MenuAction action, int client, int selection)	{}

//------------------KDeath Handler---------------------------------
void Echo_KillDeath(int client)	{
	if(IsClientInGame(client))
		KDeath_GetData(client);
}

void KDeath_GetData(int client)	{
	char STEAMID[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, STEAMID, sizeof(STEAMID));
	Format(ranksteamidreq[client], 25, "%s", STEAMID);

	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `KillAssist`, `PLAYTIME`, `NAME` FROM `%s` WHERE STEAMID = '%s'", sTableName, ranksteamidreq[client]);
	db.Query(KDeath_ProcessData, buffer, GetClientUserId(client));
}

void KDeath_ProcessData(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int iKills, iDeaths, iAssists; //, iPlaytime

	while(results.FetchRow())	{
		iKills = results.FetchInt(0);
		iDeaths = results.FetchInt(1);
		iAssists = results.FetchInt(2);
		//iPlaytime = results.FetchInt(3);
		results.FetchString(4, ranknamereq[client] , 32);
	}

	float kdr;
	float fKills;
	float fDeaths;

	//kdr = float(9000); //error check
	fKills = float(iKills);
	fKills = fKills + (float(iAssists) / 2.0);
	fDeaths = float(iDeaths);
	if(fDeaths == 0.0)
		fDeaths = 1.0;

	kdr = fKills / fDeaths;

	switch(showranktoall.BoolValue)	{
		case	true:	{
			PrintToChatAll("\x04[%s] %N\x01 has an \x04Overall\x01 Kill-to-Death ratio of \x04%.2f\x01 with \x04%i Kills\x01, \x04%i Deaths\x01, and \x04%i Assists!\x01", CHATTAG, client, kdr, iKills, iDeaths, iAssists);
			PrintToChat(client, "\x04[%s]\x01 Type kd<class> to show your Kill/Death ratio for that class.  Eg, kdspy", CHATTAG);
		}
		case	false:	{
			PrintToChat(client, "\x04[%s] %N\x01 has an \x04Overall\x01 Kill-to-Death ratio of \x04%.2f\x01 with \x04%i Kills\x01, \x04%i Deaths\x01, and \x04%i Assists!\x01", CHATTAG, client, kdr, iKills, iDeaths, iAssists);
			PrintToChat(client, "\x04[%s]\x01 Type kd<class> to show your Kill/Death ratio for that class.  Eg, kdspy", CHATTAG);
		}
	}
}
//-----------------KDeath Handler----------------------

//----------------- KDeath Per-Class Handler -------------------

void Echo_KillDeathClass(int client, int class)
{
	/*
	class =
		1 = Scout
		2 = Soldier
		3 = Pyro
		4 = Demo
		5 = Heavy
		6 = Engi
		7 = Medic
		8 = Sniper
		9 = Spy
	*/
	
	if(IsClientInGame(client))
		KDeathClass_GetData(client, class);
}

void KDeathClass_GetData(int client, int class)	{
	char Classy[42];
	switch(class)	{
		case	1:	strcopy(Classy, sizeof(Classy), "Scout");
		case	2:	strcopy(Classy, sizeof(Classy), "Soldier");
		case	3:	strcopy(Classy, sizeof(Classy), "Pyro");
		case	4:	strcopy(Classy, sizeof(Classy), "Demo");
		case	5:	strcopy(Classy, sizeof(Classy), "Heavy");
		case	6:	strcopy(Classy, sizeof(Classy), "Engi");
		case	7:	strcopy(Classy, sizeof(Classy), "Medic");
		case	8:	strcopy(Classy, sizeof(Classy), "Sniper");
		case	9:	strcopy(Classy, sizeof(Classy), "Spy");
	}

	char STEAMID[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, STEAMID, sizeof(STEAMID));
	Format(ranksteamidreq[client], 25, "%s", STEAMID);

	//------

	DataPack pack = new DataPack();

	//------


	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `%sKills`, `%sDeaths`, `KillAssist`, `PLAYTIME`, `NAME` FROM `%s` WHERE STEAMID = '%s'", Classy, Classy, sTableName, ranksteamidreq[client]);
	db.Query(KDeathClass_ProcessData, buffer, pack);

	pack.WriteCell(class);
	pack.WriteCell(GetClientUserId(client));
}

void KDeathClass_ProcessData(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int class = pack.ReadCell();
	int userid = pack.ReadCell();

	delete pack;

	char Classy[42];
	switch(class)	{
		case	1:	strcopy(Classy, sizeof(Classy), "Scout");
		case	2:	strcopy(Classy, sizeof(Classy), "Soldier");
		case	3:	strcopy(Classy, sizeof(Classy), "Pyro");
		case	4:	strcopy(Classy, sizeof(Classy), "Demoman");
		case	5:	strcopy(Classy, sizeof(Classy), "Heavy");
		case	6:	strcopy(Classy, sizeof(Classy), "Engineer");
		case	7:	strcopy(Classy, sizeof(Classy), "Medic");
		case	8:	strcopy(Classy, sizeof(Classy), "Sniper");
		case	9:	strcopy(Classy, sizeof(Classy), "Spy");
	}

	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int iKills, iDeaths; //, iAssists // , iPlaytime

	while(results.FetchRow())	{
		iKills = results.FetchInt(0);
		iDeaths = results.FetchInt(1);
		//iAssists = results.FetchInt(2);
		//iPlaytime = results.FetchInt(3);
		results.FetchString(4, ranknamereq[client] , 32);
	}

	float kdr;
	float fKills;
	float fDeaths;

	//kdr = float(9000); //error check
	fKills = float(iKills);
	//fKills = fKills + (float(iAssists) / 2.0);
	fDeaths = float(iDeaths);
	if(fDeaths == 0.0)
		fDeaths = 1.0;

	kdr = fKills / fDeaths;
	
	switch(showranktoall.BoolValue)	{
		case	true:	PrintToChatAll("\x04[%s] %N\x01 has a \x04Kill-to-Death\x01 ratio of \x04%.2f\x01 as \x05%s\x01 with \x04%i Kills\x01, \x04%i Deaths\x01", CHATTAG, client, kdr, Classy, iKills, iDeaths);
		case	false:	PrintToChat(client, "\x04[%s] %N\x01 has a \x04Kill-to-Death\x01 ratio of \x04%.2f\x01 as \x05%s\x01 with \x04%i Kills\x01, \x04%i Deaths\x01", CHATTAG, client, kdr, Classy, iKills, iDeaths);
	}
}

//----------------- KDeath Per-Class Handler -------------------


//----------------- Lifetime Heals -------------------

void Echo_LifetimeHealz(int client)	{
	if(IsClientInGame(client))
		LTHeals_GetData(client);
}

void LTHeals_GetData(int client)	{
	char STEAMID[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, STEAMID, sizeof(STEAMID));
	Format(ranksteamidreq[client], 25, "%s", STEAMID);

	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `MedicHealing`, `NAME` FROM `%s` WHERE STEAMID = '%s'", sTableName, ranksteamidreq[client]);
	db.Query(LTHeals_ProcessData, buffer, showranktoall);
}

void LTHeals_ProcessData(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	int iHealed;

	while(results.FetchRow())	{
		iHealed = results.FetchInt(0);
		results.FetchString(1, ranknamereq[client], 32);
	}

	PrintToChatAll("\x04[%s] %N\x01 has healed a total of %iHP on this server!", CHATTAG, client, iHealed);
}

//----------------- Lifetime Heals -------------------

void top10pnl(int client)	{
	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT NAME,steamId FROM `%s` ORDER BY POINTS DESC LIMIT 0,100", sTableName);
	db.Query(T_ShowTOP1, buffer, GetClientUserId(client));
}

void T_ShowTOP1(Database database, DBResultSet results, const char[] error, int userid)	{
	int client;

	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(userid)) == 0)
		return;

	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	Menu menu = new Menu(TopMenuHandler1);
	menu.SetTitle("Top Menu:");

	int i = 1;
	while(results.FetchRow())	{
		char plname[32];
		char plid[32];
		results.FetchString(0, plname , 32);
		results.FetchString(1, plid , 32);
		char menuline[40];
		Format(menuline, sizeof(menuline), "%i. %s", i, plname);
		menu.AddItem(plid, menuline);
		i++;
	}
	
	menu.ExitButton = true;
	menu.Display(client, 60);
}

int TopMenuHandler1(Menu menu, MenuAction action, int client, int selection)	{
	switch(action)	{
		/* If an option was selected, tell the client about the item. */
		case	MenuAction_Select:	{
			char info[32];
			menu.GetItem(selection, info, sizeof(info));
			rankpanel(client, info);
		}
		/* If the menu was cancelled, print a message to the server about it. */
		case	MenuAction_Cancel:	PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, selection);
		/* If the menu has ended, destroy it */
		case	MenuAction_End:	delete menu;
	}
}

public void OnConfigsExecuted()	{
	TagsCheck("TF2Stats");
	readcvars();
}

void TagsCheck(const char[] tag)	{
	ConVar hTags = FindConVar("sv_tags");
	char tags[255];
	hTags.GetString(tags, sizeof(tags));

	if(!(StrContains(tags, tag, false)>-1))	{
		char newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		hTags.SetString(newTags);
		hTags.GetString(tags, sizeof(tags));
	}
	delete hTags;
}

void createdbtables()	{
	int len = 0;
	char query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `data`");
	len += Format(query[len], sizeof(query)-len, "(`name` TEXT, `datatxt` TEXT, `dataint` INTEGER);");
	db.Query(T_CheckDBUptodate1, query);
}

void T_CheckDBUptodate1(Database database, DBResultSet results, const char[] error, any data)	{
	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT dataint FROM `data` where `name` = 'dbversion'");
	db.Query(T_CheckDBUptodate2, buffer);
}

void T_CheckDBUptodate2(Database database, DBResultSet results, const char[] error, any data)	{
	if(results == null)	{
		LogError("Query failed! %s", error);
		return;
	}
	
	createdbplayer();
	if(!results.RowCount)	{
		char buffer[255];
		Format(buffer, sizeof(buffer), "INSERT INTO data (`name`,`dataint`) VALUES ('dbversion',%i)", DBVERSION);
		db.Query(SQLErrorCheckCallback, buffer);
	}

	initonlineplayers();
}

public void OnClientDisconnect(int client)	{
	g_iLastRankCheck[client] = 0;

	if(overchargescoringtimer[client] != null)	{
		KillTimer(overchargescoringtimer[client]);
		overchargescoringtimer[client] = null;
	}

	if(CheckCookieTimers[client] != null)	{
		KillTimer(CheckCookieTimers[client]);
		CheckCookieTimers[client] = null;
	}

	if(rankingactive)	{
		if(neededplayercount.IntValue > GetClientCount(true))	{
			rankingactive = false;
			if(ShowEnoughPlayersNotice.BoolValue)
				PrintToChatAll("\x04[%s]\x01 Ranking Disabled: not enough players", CHATTAG);
		}
	}
}

void readcvars()	{
	CV_chattag.GetString(CHATTAG, sizeof(CHATTAG));
	showchatcommands = CV_showchatcommands.BoolValue;
	rankingenabled = CV_rank_enable.BoolValue;
}

void startconvarhooking()	{
	CV_chattag.AddChangeHook(OnConVarChangechattag);
	CV_showchatcommands.AddChangeHook(OnConVarChangeshowchatcommands);
	CV_rank_enable.AddChangeHook(OnConVarChangerank_enable);
}

void OnConVarChangechattag(ConVar cvar, const char[] oldValue, const char[] newValue)	{
	CV_chattag.GetString(CHATTAG, sizeof(CHATTAG));
}

void OnConVarChangerank_enable(ConVar cvar, const char[] oldValue, const char[] newValue)	{
	switch(CV_rank_enable.BoolValue)	{
		case	true:	{
			rankingenabled = true;
			PrintToChatAll("\x04[%s]\x01 Ranking Started", CHATTAG);
		}
		case	false:	{
			PrintToChatAll("\x04[%s]\x01 Ranking Stopped", CHATTAG);
			rankingenabled = false;
		}
	}
}

void OnConVarChangeshowchatcommands(ConVar cvar, const char[] oldValue, const char[] newValue)	{
	showchatcommands = CV_showchatcommands.BoolValue;
}

Action resetoverchargescoring(Handle timer, int client)	{
	overchargescoring[client] = true;
	overchargescoringtimer[client] = null;
}

/*
public bool AskPluginLoad(Handle myself, bool late, char[] error, int err_max)	{
    MarkNativeAsOptional("AutoUpdate_AddPlugin");
    MarkNativeAsOptional("AutoUpdate_RemovePlugin");
    return true;
}
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)	{
    MarkNativeAsOptional("AutoUpdate_AddPlugin");
    MarkNativeAsOptional("AutoUpdate_RemovePlugin");
    return APLRes_Success;
}



void Event_player_teleported(Event event, const char[] name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		char SteamID[64];
		char query[512];

		int client = GetClientOfUserId(event.GetInt("userid"));		
		//if (ignorebots.BoolValue && IsFakeClient(client))
			//return;	//If a bot takes the tele, ignore it.
		
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		
		//Number of times a player has used a teleporter
		Format(query, sizeof(query), "UPDATE %s SET player_teleported = player_teleported + 1 WHERE STEAMID = '%s'", sTableName, SteamID);
		db.Query(SQLErrorCheckCallback, query);

		//Get builders steamid
		int builder = GetClientOfUserId(event.GetInt("builderid"));
		if(builder == 0 || client == 0)
			return;
		if(ignorebots.BoolValue && IsFakeClient(builder))
			return;	// Tele owner is a bot -> ignore it
		
		GetClientAuthId(builder, AuthId_Steam2, SteamID, sizeof(SteamID));

		//Number of times a players teleporter has been used
		Format(query, sizeof(query), "UPDATE %s SET TotalPlayersTeleported = TotalPlayersTeleported + 1 WHERE STEAMID = '%s'", sTableName, SteamID);
		db.Query(SQLErrorCheckCallback, query);

		if(client != builder && TF2_GetClientTeam(client) == TF2_GetClientTeam(builder))	{
			int iPoints = TeleUsePoints.IntValue;
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", sTableName, iPoints, SteamID);
			db.Query(SQLErrorCheckCallback, query);

			if(iPoints > 0 && cookieshowrankchanges[builder] && ShowTeleNotices.BoolValue)
				PrintToChat(builder,"\x04[%s]\x01 You got %i points for teleporting \x03%N\x01!", CHATTAG, iPoints, client);
		}
	}
}

void Event_player_extinguished(Event event, const char[] name, bool dontBroadcast)	{
	if(rankingactive && rankingenabled)	{
		int healer = GetClientOfUserId(event.GetInt("healer"));
		int victim = GetClientOfUserId(event.GetInt("victim"));	
		if (healer == 0 || victim == 0)
			return;

		int pointvalue = extingushingpoints.IntValue;
		char SteamID[64];

		GetClientAuthId(healer, AuthId_Steam2, SteamID, sizeof(SteamID));
		char query[512];
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, player_extinguished = player_extinguished + 1 WHERE STEAMID = '%s'", sTableName, pointvalue, SteamID);
		db.Query(SQLErrorCheckCallback, query);

		if(pointmsg.IntValue == 1)
			PrintToChatAll("\x04[%s]\x01 %N got %i points for extingushing %N", CHATTAG, healer, pointvalue, victim);
		else if(cookieshowrankchanges[healer])
			PrintToChat(healer, "\x04[%s]\x01 you got %i points for extingushing %N!", CHATTAG, pointvalue, victim);
	}
}

void sayhidepoints(int client)	{
	char steamId[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	char query[512];
	Format(query, sizeof(query), "UPDATE %s SET chat_status = '2' WHERE STEAMID = '%s'",sTableName, steamId);
	db.Query(SQLErrorCheckCallback, query);
	cookieshowrankchanges[client] = false;
}

void sayunhidepoints(int client)	{
	char steamId[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	char query[512];
	Format(query, sizeof(query), "UPDATE %s SET chat_status = '1' WHERE STEAMID = '%s'",sTableName, steamId);
	db.Query(SQLErrorCheckCallback, query);
	cookieshowrankchanges[client] = true;
}

void BuildServerIp()	{
    char port[10];
	
    FindConVar("hostport").GetString(port, sizeof(port));
    
    int ipVal = FindConVar("hostip").IntValue;
    int ipVals[4];
    
    ipVals[0] = (ipVal >> 24) & 0x000000FF;
    ipVals[1] = (ipVal >> 16) & 0x000000FF;
    ipVals[2] = (ipVal >> 8) & 0x000000FF;
    ipVals[3] = ipVal & 0x000000FF;
    
    FormatEx(sTableName, 64, "srv_%d_%d_%d_%d__%s", ipVals[0], ipVals[1], ipVals[2], ipVals[3], port);
}
