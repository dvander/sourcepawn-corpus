#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <geoip>
#include <adminmenu>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "9.3.3"
#define DBVERSION 44

#define MAX_LINE_WIDTH 60

#define FlagPickedUp 1
#define FlagCaptured 2
#define FlagDefended 3
#define FlagDropped  4

new bool:cpmap = false;
new mapisset;
new classfunctionloaded = 0;

new Handle:db = INVALID_HANDLE;			/** Database connection */
new Handle:dbReconnect = INVALID_HANDLE;
new Handle:DBCharSetDef = INVALID_HANDLE;

new bool:rankingenabled = false;

// Death Points
new Handle:disablediepoints = INVALID_HANDLE;
new Handle:Scoutdiepoints = INVALID_HANDLE;
new Handle:Soldierdiepoints = INVALID_HANDLE;
new Handle:Pyrodiepoints = INVALID_HANDLE;
new Handle:Medicdiepoints = INVALID_HANDLE;
new Handle:Sniperdiepoints = INVALID_HANDLE;
new Handle:Spydiepoints = INVALID_HANDLE;
new Handle:Demomandiepoints = INVALID_HANDLE;
new Handle:Heavydiepoints = INVALID_HANDLE;
new Handle:Engineerdiepoints = INVALID_HANDLE;

new bool:oldshowranktoallvalue = true;


new g_iLastRankCheck[MAXPLAYERS+1] = 0;
new Handle:v_RankCheckTimeout = INVALID_HANDLE;
//new g_iCanCheckKDR[MAXPLAYERS+1] = 0;	//We wont add this yet since KDR checks arent that expensive on the database

/*
#1. Add handles
*/


//New Weapons
//-------------------
new Handle:ham_shank = INVALID_HANDLE;
new Handle:awper_hand = INVALID_HANDLE;
new Handle:loose_cannon_impact = INVALID_HANDLE;
new Handle:loose_cannon = INVALID_HANDLE;
new Handle:skullbat = INVALID_HANDLE;
new Handle:freedom_staff = INVALID_HANDLE;
new Handle:the_rescue_ranger = INVALID_HANDLE;
new Handle:memory_maker = INVALID_HANDLE;
new Handle:golden_fryingpan = INVALID_HANDLE;
new Handle:panic_attack = INVALID_HANDLE;
new Handle:iron_bomber = INVALID_HANDLE;
new Handle:ai_flamethrower = INVALID_HANDLE;
new Handle:quickiebomb_launcher = INVALID_HANDLE;
new Handle:necro_smasher = INVALID_HANDLE;
new Handle:taunt_medic = INVALID_HANDLE;
new Handle:crossing_guard = INVALID_HANDLE;
new Handle:rescue_ranger_reflect = INVALID_HANDLE;
new Handle:medigun_shield = INVALID_HANDLE;



//Spells
//-------------------
new Handle:spellbook_athletic = INVALID_HANDLE;
new Handle:spellbook_bats = INVALID_HANDLE;
new Handle:spellbook_blastjump = INVALID_HANDLE;
new Handle:spellbook_boss = INVALID_HANDLE;
new Handle:spellbook_fireball = INVALID_HANDLE;
new Handle:spellbook_lightning = INVALID_HANDLE;
new Handle:spellbook_meteor = INVALID_HANDLE;
new Handle:spellbook_mirv = INVALID_HANDLE;
new Handle:spellbook_skeleton = INVALID_HANDLE;
new Handle:spellbook_teleport = INVALID_HANDLE;


//RTD
//-------------------
new Handle:rtd_toxic = INVALID_HANDLE;
new Handle:rtd_timebomb = INVALID_HANDLE;
new Handle:rtd_instant_kills = INVALID_HANDLE;



//Sleeping Dogs
//-------------------
new Handle:long_heatmaker = INVALID_HANDLE;
new Handle:annihilator = INVALID_HANDLE;
new Handle:recorder = INVALID_HANDLE;
new Handle:guillotine = INVALID_HANDLE;





//All-Class Weapons
//-------------------
new Handle:Objector_Points = INVALID_HANDLE;
new Handle:Saxxy_Points = INVALID_HANDLE;


//Scout Points
//-------------------

// Default Weapons
new Handle:scattergunpoints = INVALID_HANDLE;
new Handle:backscatter_points = INVALID_HANDLE;
new Handle:batpoints = INVALID_HANDLE;
new Handle:pistolpoints = INVALID_HANDLE;

//Unlocks
new Handle:force_a_naturepoints = INVALID_HANDLE;
new Handle:sandmanpoints = INVALID_HANDLE;
new Handle:bat_woodpoints = INVALID_HANDLE;

//Polycount
new Handle:short_stoppoints = INVALID_HANDLE;
new Handle:holy_mackerelpoints = INVALID_HANDLE;

//Other
new Handle:ballpoints = INVALID_HANDLE;
new Handle:taunt_scoutpoints = INVALID_HANDLE;
new Handle:stun_points = INVALID_HANDLE;
new Handle:big_stun_points = INVALID_HANDLE;

//Rift
new Handle:SunBatPoints = INVALID_HANDLE;

//Samurai
new Handle:Warfan_Points = INVALID_HANDLE;

//Christmas Update
new Handle:candy_canePoints = INVALID_HANDLE;
new Handle:boston_basherPoints = INVALID_HANDLE;

//Witcher
new Handle:Scout_Sword_Points = INVALID_HANDLE;

//Uber Update
new Handle:Popper_Points = INVALID_HANDLE;
new Handle:Winger_Points = INVALID_HANDLE;
new Handle:Atomizer_Points = INVALID_HANDLE;

//Halloween 2011
new Handle:Unarmed_Combat_Points = INVALID_HANDLE;

//Christmas 2011
new Handle:WrapAssassin_Points = INVALID_HANDLE;

//Meet the pyro
new Handle:Brawlerblaster_Points = INVALID_HANDLE;
new Handle:Pep_pistol_Points = INVALID_HANDLE;

//--------------------


//Soldier Points
//--------------------

// Default Weapons
new Handle:tf_projectile_rocketpoints = INVALID_HANDLE;
new Handle:shotgunpoints = INVALID_HANDLE;
new Handle:shovelpoints = INVALID_HANDLE;

//Unlocks
new Handle:rocketlauncher_directhitpoints = INVALID_HANDLE;
new Handle:pickaxepoints = INVALID_HANDLE;
new Handle:uniquepickaxepoints = INVALID_HANDLE; //Defunct

//Polycount
new Handle:blackboxpoints = INVALID_HANDLE;

//Other
new Handle:taunt_soldierpoints = INVALID_HANDLE;
new Handle:paintrainpoints = INVALID_HANDLE;
new Handle:worms_grenade_points = INVALID_HANDLE;

//Samurai
new Handle:Katana_Points = INVALID_HANDLE;

//Uber Update
new Handle:Liberty_Points = INVALID_HANDLE;
new Handle:ReserveShooter_Points = INVALID_HANDLE;
new Handle:DisciplinaryAction_Points = INVALID_HANDLE;
new Handle:MarketGardener_Points = INVALID_HANDLE;
new Handle:Mantreads_Points = INVALID_HANDLE;

//Space Update
new Handle:Mangler_Points = INVALID_HANDLE;
new Handle:RighteousBison_Points = INVALID_HANDLE;

// Quakecon
new Handle:Quake_RocketLauncher_Points = INVALID_HANDLE;

// Love and War
new Handle:Airstrike_Points = INVALID_HANDLE;

//Meet the pyro
new Handle:Dumpster_Device_Points = INVALID_HANDLE;
new Handle:Pickaxe_Escape_Points = INVALID_HANDLE;

//--------------------


//Pyro Points
//--------------------

// Default Weapons
new Handle:flamethrowerpoints = INVALID_HANDLE;
new Handle:fireaxepoints = INVALID_HANDLE;

//Unlocks
new Handle:backburnerpoints = INVALID_HANDLE;
new Handle:flaregunpoints = INVALID_HANDLE;
new Handle:axtinguisherpoints = INVALID_HANDLE;

//Polycount
new Handle:powerjackpoints = INVALID_HANDLE;
new Handle:degreaserpoints = INVALID_HANDLE;

//Other
new Handle:taunt_pyropoints = INVALID_HANDLE;
new Handle:deflect_flarepoints = INVALID_HANDLE;
new Handle:deflect_rocketpoints = INVALID_HANDLE;
new Handle:deflect_promodepoints = INVALID_HANDLE;
new Handle:deflect_stickypoints = INVALID_HANDLE;
new Handle:deflect_arrowpoints = INVALID_HANDLE;

//Rift
new Handle:LavaAxePoints = INVALID_HANDLE;

//Special
new Handle:sledgehammerpoints = INVALID_HANDLE;

//Christmas Update
new Handle:back_scratcherPoints = INVALID_HANDLE;

//Red Faction: Armageddon
new Handle:The_Maul_Points = INVALID_HANDLE;

//Uber Update
new Handle:Detonator_Points = INVALID_HANDLE;

//Summer Update
new Handle:Mailbox_Points = INVALID_HANDLE;

//Spacetek Update
new Handle:ManglerReflect_Points = INVALID_HANDLE;

//Christmas 2011
new Handle:Phlogistinator_Points = INVALID_HANDLE;
new Handle:Manmelter_Points = INVALID_HANDLE;
new Handle:Thirddegree_Points = INVALID_HANDLE;

//Meet the pyro
new Handle:Rainblower_Points = INVALID_HANDLE;
new Handle:Scorchshot_Points = INVALID_HANDLE;
new Handle:Lollichop_Points = INVALID_HANDLE;
new Handle:Armageddon_taunt_Points = INVALID_HANDLE;


//--------------------


//Demo Points
//--------------------

// Default Weapons
new Handle:tf_projectile_pipepoints = INVALID_HANDLE;
new Handle:tf_projectile_pipe_remotepoints = INVALID_HANDLE;
new Handle:bottlepoints = INVALID_HANDLE;

//Unlocks
new Handle:sticky_resistancepoints = INVALID_HANDLE;
new Handle:demoshieldpoints = INVALID_HANDLE;
new Handle:swordpoints = INVALID_HANDLE;

//Special
new Handle:battleaxepoints = INVALID_HANDLE;
new Handle:fryingpanpoints = INVALID_HANDLE;

//Other
new Handle:taunt_demomanpoints = INVALID_HANDLE;
new Handle:headtakerpoints = INVALID_HANDLE;

//Christmas Update
new Handle:ullapool_caberPoints = INVALID_HANDLE;
new Handle:lochnloadPoints = INVALID_HANDLE;
new Handle:gaelicclaymorePoints = INVALID_HANDLE;
new Handle:UllaExplodePoints = INVALID_HANDLE;

//Uber Update
new Handle:Persian_Persuader_Points = INVALID_HANDLE;
new Handle:Splendid_Screen_Points = INVALID_HANDLE;

//Love and War Update
new Handle:Tide_Turner_Points = INVALID_HANDLE;

//Summer Update
new Handle:Golfclub_Points = INVALID_HANDLE;

//Halloween 2011
new Handle:Scottish_Handshake_Points = INVALID_HANDLE;

//--------------------


//Heavy Points
//--------------------

// Default Weapons
new Handle:minigunpoints = INVALID_HANDLE;

new Handle:fistspoints = INVALID_HANDLE;

//Unlocks
new Handle:nataschapoints = INVALID_HANDLE;
new Handle:glovespoints = INVALID_HANDLE;

//Polycount
new Handle:urgentglovespoints = INVALID_HANDLE;

//Love and War Update
new Handle:bread_bite_points = INVALID_HANDLE;

//Taunt
new Handle:taunt_heavypoints = INVALID_HANDLE;

//Poker Night
new Handle:ironcurtainpoints = INVALID_HANDLE;

//Christmas Update 2010
new Handle:bear_clawsPoints = INVALID_HANDLE;
new Handle:steel_fistsPoints = INVALID_HANDLE;
new Handle:BrassBeastPoints = INVALID_HANDLE;

//Saints Row 3
new Handle:ApocoFists_Points = INVALID_HANDLE;

//Uber Update
new Handle:Tomislav_Points = INVALID_HANDLE;
new Handle:Family_Business_Points = INVALID_HANDLE;
new Handle:Eviction_Notice_Points = INVALID_HANDLE;

//Christmas 2011
new Handle:Holiday_Punch_Points = INVALID_HANDLE;

//--------------------


//Engi Points
//--------------------

// Default Weapons
new Handle:obj_sentrygunpoints = INVALID_HANDLE;
new Handle:wrenchpoints = INVALID_HANDLE;

//Unlocks
new Handle:frontier_justicePoints = INVALID_HANDLE; //new shotgun : added v6:6
new Handle:wrangler_killPoints = INVALID_HANDLE; //manual sentry control : added v6:6
new Handle:robot_armPoints = INVALID_HANDLE; //mech-arm wrench : added v6:6

//Special
new Handle:maxgunPoints  = INVALID_HANDLE; //sam and max pistol : added v6:6
new Handle:southern_hospitalityPoints  = INVALID_HANDLE; //bleed-wrench : added v6:6
new Handle:bleed_killPoints  = INVALID_HANDLE; //bleed kill, also for sniper's wood knife : added v6:6

//Other
new Handle:robot_arm_blender_killPoints  = INVALID_HANDLE; //mech-arm taunt : added v6:6
new Handle:robot_arm_combo_killPoints  = INVALID_HANDLE;
new Handle:taunt_guitar_killPoints  = INVALID_HANDLE; //new shotgun taunt kill : added v6:6
new Handle:TeleUsePoints = INVALID_HANDLE;

//Christmas Update
new Handle:wrench_jagPoints = INVALID_HANDLE;
new Handle:MinisentryPoints = INVALID_HANDLE;

//Deus Ex
new Handle:WidowmakerPoints = INVALID_HANDLE;
new Handle:Short_CircuitPoints = INVALID_HANDLE;

//Christmas 2011
new Handle:Pomson_Points = INVALID_HANDLE;
new Handle:Eureka_Effect_Points = INVALID_HANDLE;


//--------------------


//Medic Points
//--------------------

// Default Weapons
new Handle:bonesawpoints = INVALID_HANDLE;
new Handle:syringegun_medicpoints = INVALID_HANDLE;

//Polycount
new Handle:battleneedlepoints = INVALID_HANDLE;

//Unlocks
new Handle:blutsaugerpoints = INVALID_HANDLE;
new Handle:ubersawpoints = INVALID_HANDLE;

//Christmas Update:
new Handle:amputatorPoints = INVALID_HANDLE;
new Handle:medicCrossbowPoints = INVALID_HANDLE;

//Uber Update
new Handle:Proto_Syringe_Points = INVALID_HANDLE;
new Handle:Solemn_Vow_Points = INVALID_HANDLE;


//--------------------


//Sniper Points
//--------------------

// Default Weapons
new Handle:sniperriflepoints = INVALID_HANDLE;
new Handle:smgpoints = INVALID_HANDLE;
new Handle:clubpoints = INVALID_HANDLE;

//Unlocks
new Handle:compound_bowpoints = INVALID_HANDLE;
new Handle:tf_projectile_arrowpoints = INVALID_HANDLE;
new Handle:woodknifepoints = INVALID_HANDLE;

//Polycount
new Handle:sleeperpoints = INVALID_HANDLE;
new Handle:bushwackapoints = INVALID_HANDLE;

//Other
new Handle:taunt_sniperpoints = INVALID_HANDLE;

//Uber Update
new Handle:Bazaar_Bargain_Points = INVALID_HANDLE;
new Handle:Shahanshah_Points = INVALID_HANDLE;

//Deus Ex
new Handle:Machina_Points = INVALID_HANDLE;
new Handle:Machina_DoubleKill_Points = INVALID_HANDLE;

//Meet the pyro
new Handle:Pro_rifle_Points = INVALID_HANDLE;
new Handle:Pro_smg_Points = INVALID_HANDLE;

//Love&war
new Handle:The_classic_Points = INVALID_HANDLE;


//--------------------


//Spy Points
//--------------------

// Default Weapons
new Handle:revolverpoints = INVALID_HANDLE;
new Handle:knifepoints = INVALID_HANDLE;

//Unlocks
new Handle:ambassadorpoints = INVALID_HANDLE;
new Handle:samrevolverpoints = INVALID_HANDLE;

//Polycount
new Handle:eternal_rewardpoints = INVALID_HANDLE;
new Handle:letrangerpoints = INVALID_HANDLE;

//Other
new Handle:taunt_spypoints = INVALID_HANDLE;

//Samurai
new Handle:Kunai_Points = INVALID_HANDLE;

//Uber Update
new Handle:Enforcer_Points = INVALID_HANDLE;
new Handle:Big_Earner_Points = INVALID_HANDLE;

//Deus Ex
new Handle:Diamondback_Points = INVALID_HANDLE;

//Halloween 2011
new Handle:Wanga_Prick_Points = INVALID_HANDLE;

//Assassins Creed
new Handle:Sharp_Dresser_Points = INVALID_HANDLE;

//Christmas 2011
new Handle:Spy_Cicle_Points = INVALID_HANDLE;

// Alliance of Valiant Arms
new Handle:BlackRose_Points = INVALID_HANDLE;

//--------------------


//Other - Events
//--------------------

new Handle:killsapperpoints = INVALID_HANDLE;
new Handle:killteleinpoints = INVALID_HANDLE;
new Handle:killteleoutpoints = INVALID_HANDLE;
new Handle:killdisppoints = INVALID_HANDLE;
new Handle:killsentrypoints = INVALID_HANDLE;
new Handle:killasipoints = INVALID_HANDLE;
new Handle:killasimedipoints = INVALID_HANDLE;
new Handle:overchargepoints = INVALID_HANDLE;
new Handle:telefragpoints = INVALID_HANDLE;
new Handle:extingushingpoints = INVALID_HANDLE;
new Handle:stealsandvichpoints = INVALID_HANDLE;

//Halloween 2011
new Handle:EyeBossKillAssist = INVALID_HANDLE;
new Handle:EyeBossStun = INVALID_HANDLE;

//--------------------


//Other - Kills
//--------------------

new Handle:pumpkinpoints = INVALID_HANDLE;
new Handle:goombapoints = INVALID_HANDLE; //Added v6:5
new Handle:headshotpoints = INVALID_HANDLE;

//--------------------



//Other - VIPs
//--------------------
new Handle:vip_points1 = INVALID_HANDLE;
new Handle:vip_points2 = INVALID_HANDLE;
new Handle:vip_points3 = INVALID_HANDLE;
new Handle:vip_points4 = INVALID_HANDLE;
new Handle:vip_points5 = INVALID_HANDLE;

new Handle:vip_steamid1 = INVALID_HANDLE;
new Handle:vip_steamid2 = INVALID_HANDLE;
new Handle:vip_steamid3 = INVALID_HANDLE;
new Handle:vip_steamid4 = INVALID_HANDLE;
new Handle:vip_steamid5 = INVALID_HANDLE;

new Handle:vip_message1 = INVALID_HANDLE;
new Handle:vip_message2 = INVALID_HANDLE;
new Handle:vip_message3 = INVALID_HANDLE;
new Handle:vip_message4 = INVALID_HANDLE;
new Handle:vip_message5 = INVALID_HANDLE;
//--------------------


//Other - Menus
//--------------------
new g_iMenuTarget[MAXPLAYERS+1];
//--------------------


//Some chat cvars
//--------------------
new Handle:ShowEnoughPlayersNotice = INVALID_HANDLE;
new Handle:ShowRoundEnableNotice = INVALID_HANDLE;


//Other
//--------------------
new Handle:ignorebots = INVALID_HANDLE;
new Handle:ignoreTeamKills = INVALID_HANDLE;

new Handle:v_TimeOffset = INVALID_HANDLE;

new Handle:logips = INVALID_HANDLE; //Added v6:6

new Handle:showranktoall  = INVALID_HANDLE;
new Handle:showrankonroundend = INVALID_HANDLE;
new Handle:showSessionStatsOnRoundEnd = INVALID_HANDLE;
new Handle:roundendranktochat = INVALID_HANDLE;
new Handle:showrankonconnect = INVALID_HANDLE;

new Handle:ShowTeleNotices = INVALID_HANDLE;

new Handle:webrank = INVALID_HANDLE;
new Handle:webrankurl = INVALID_HANDLE;

new Handle:removeoldplayers = INVALID_HANDLE;
new Handle:removeoldplayersdays = INVALID_HANDLE;
new Handle:removeoldmaps = INVALID_HANDLE;
new Handle:removeoldmapssdays = INVALID_HANDLE;

new Handle:Capturepoints = INVALID_HANDLE;
new Handle:FileCapturepoints = INVALID_HANDLE;
new Handle:CTFCapPlayerPoints = INVALID_HANDLE;
new Handle:CPCapPlayerPoints = INVALID_HANDLE;
new Handle:Captureblockpoints = INVALID_HANDLE;

new Handle:neededplayercount = INVALID_HANDLE;
new Handle:disableafterwin = INVALID_HANDLE;
new Handle:worldpoints = INVALID_HANDLE;
new Handle:plgnversion = INVALID_HANDLE;

new Handle:ConnectSoundFile	= INVALID_HANDLE;
new Handle:ConnectSound = INVALID_HANDLE;
new Handle:CountryCodeHandler = INVALID_HANDLE;
new Handle:ConnectSoundTop10 = INVALID_HANDLE;
new Handle:ConnectSoundFileTop10 = INVALID_HANDLE;

new Handle:CheckCookieTimers[MAXPLAYERS+1];

new bool:sqllite = false;
new bool:rankingactive = true;
new bool:extendedloggingenabled = false;

new onconrank[MAXPLAYERS + 1];
new onconpoints[MAXPLAYERS + 1];
new rankedclients = 0;
new playerpoints[MAXPLAYERS + 1];
new playerrank[MAXPLAYERS + 1];
new String:ranksteamidreq[MAXPLAYERS + 1][25];
new String:ranknamereq[MAXPLAYERS + 1][32];
new reqplayerrankpoints[MAXPLAYERS + 1];
new reqplayerrank[MAXPLAYERS + 1];

new maxents, ResourceEnt, maxplayers;

new sessionpoints[MAXPLAYERS + 1];
new sessionkills[MAXPLAYERS + 1];
new sessiondeath[MAXPLAYERS + 1];
new sessionassi[MAXPLAYERS + 1];

new TotalHealing[MAXPLAYERS+1] = 0;
//iHealing

new overchargescoring[MAXPLAYERS + 1];
new Handle:overchargescoringtimer[MAXPLAYERS + 1];
new Handle:pointmsg = INVALID_HANDLE;

new bool:g_IsRoundActive = true;
//new bool:callKDeath[MAXPLAYERS+1] = false;

new Handle:CV_chattag = INVALID_HANDLE;
new Handle:CV_showchatcommands = INVALID_HANDLE;
new String:CHATTAG[MAX_LINE_WIDTH];

new bool:cookieshowrankchanges[MAXPLAYERS + 1];
new bool:showchatcommands = true;

new Handle:CV_extendetlogging = INVALID_HANDLE;
new Handle:CV_extlogcleanuptime = INVALID_HANDLE;
new Handle:CV_rank_enable = INVALID_HANDLE;
new String:DBCharSet[10];


public Plugin:myinfo =
{
	name = "[TF2] Player Stats",
	author = "DarthNinja",
	description = "TF2 Player Stats",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=109006"
};

public OnPluginStart()
{
	versioncheck();
	CreateCvars();
	//openDatabaseConnection();
	//createdbtables();
	//CreateCvars();
	AutoExecConfig(false, "tf2-stats", "");
	AutoExecConfig(false, "tf2-stats");
	CreateConVar("sm_tf_stats_version", PLUGIN_VERSION, "TF2 Player Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SelectDBCharset();
	openDatabaseConnection();
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

versioncheck()
{
	if (FileExists("addons/sourcemod/plugins/n1g-tf2-stats.smx"))
	{
		ServerCommand("say [OLD-VERSION] file n1g-tf2-stats.smx exists and is being disabled!");
		LogError("say [OLD-VERSION] file n1g-tf2-stats.smx exists and is being disabled!");
		ServerCommand("sm plugins unload n1g-tf2-stats.smx");
		RenameFile("addons/sourcemod/plugins/disabled/n1g-tf2-stats.smx", "addons/sourcemod/plugins/n1g-tf2-stats.smx");
	}
}

public Action:sec60evnt(Handle:timer, Handle:hndl)
{
	playerstimeupdateondb()
	if (!sqllite)
	{
		refreshmaptime()
	}
}

public refreshmaptime()
{
	new String:name[MAX_LINE_WIDTH];
	GetCurrentMap(name,MAX_LINE_WIDTH);
	new time = GetTime()
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Map SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE NAME LIKE '%s'",time ,name);
	SQL_TQuery(db,SQLErrorCheckCallback, query);
}

public playerstimeupdateondb()
{
	new String:clsteamId[MAX_LINE_WIDTH];
	new time = GetTime();
	time = time + GetConVarInt(v_TimeOffset);
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			GetClientAuthId(i, AuthId_Steam2, clsteamId, sizeof(clsteamId));
			new String:query[512];
			Format(query, sizeof(query), "UPDATE Player SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE STEAMID = '%s'",time ,clsteamId);
			SQL_TQuery(db,SQLErrorCheckCallback, query);
		}
	}
}

public Action:ReconnectToDB(Handle:timer, any:nothing)
{
	if (SQL_CheckConfig("tf2stats"))
	{
		SQL_TConnect(Connected, "tf2stats");
	}
	else
	{
		new String:error[255];
		sqllite = true;
		
		new Handle:kv;
		kv = CreateKeyValues("");
		KvSetString(kv, "driver", "sqlite");
		KvSetString(kv, "database", "tf2stats");
		db = SQL_ConnectCustom(kv, error, sizeof(error), false);
		CloseHandle(kv);		
		
		if (db == INVALID_HANDLE)
			LogMessage("Failed to connect: %s", error);
		else
			LogMessage("TF2_Stats connected to SQLite Database!");
	}
}

SelectDBCharset(){
	switch(GetConVarInt(DBCharSetDef)){
		case 1:
		{
			DBCharSet = "UTF8";
		}
		case 2:
		{
			DBCharSet = "UTF8MB4";
		}
		default:
		{
			DBCharSet = "UTF8";
			LogMessage("TF2_Stats unknown character set choosen reversing back to UTF8!");
		}
	}
}

openDatabaseConnection()
{
	if (SQL_CheckConfig("tf2stats"))
	{
		SQL_TConnect(Connected, "tf2stats");
	}
	else
	{
		new String:error[255];
		sqllite = true;
		
		new Handle:kv;
		kv = CreateKeyValues("");
		KvSetString(kv, "driver", "sqlite");
		KvSetString(kv, "database", "tf2stats");
		db = SQL_ConnectCustom(kv, error, sizeof(error), false);
		CloseHandle(kv);		
		
		if (db == INVALID_HANDLE)
			LogMessage("Failed to connect: %s", error);
		else
			LogMessage("TF2_Stats connected to SQLite Database!");
		
		createdbtablessqllite();
		CreateTimer(60.0, sec60evnt, INVALID_HANDLE, TIMER_REPEAT);
	}
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	
	if (hndl == INVALID_HANDLE || !StrEqual(error, ""))
	{
		PrintToServer("Failed to connect: %s", error);
		LogError("TF2 Stats Failed to connect! Error: %s", error);
		LogError("Please check your database settings and permssions and try again!");	// use LogError twice rather then a newline so plugin name is prepended
		SetFailState("Could not reach database server!");
		return;
	}
	else
	{
		LogMessage("TF2_Stats connected to MySQL Database!");
		decl String:query[255];
		Format(query, sizeof(query), "SET NAMES \"%s\"", DBCharSet);	/* Set codepage to utf8 */
		
		//if (!SQL_FastQuery(db, query))
			//LogError("Can't select character set (%s)", query);
		
		db = hndl;
		SQL_TQuery(db, SQL_PostSetNames, query);
	}
}

public SQL_PostSetNames(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE || !StrEqual(error, ""))
		LogError("Can't select character set (%s)", error);

	createdbtables();
	CreateTimer(60.0, sec60evnt, INVALID_HANDLE, TIMER_REPEAT);
}


createdb()
{
	if (!sqllite)
	{
		createdbplayer();
		createdbmap();
		CreateItemsTable();
		createdbkillog();
	}
	else
	{
		createdbplayersqllite();
		createdbmapsqllite();
		CreateItemsTablesqllite();
		createdbkillogsqllite();
	}
}

/*
#2. Add new SQL DB queries
*/
createdbplayer()
{
	new len = 0;
	decl String:query[50000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player` (");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`NAME` varchar(50) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`POINTS` int(25) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`PLAYTIME` int(25) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`LASTONTIME` int(25) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`IPAddress` varchar(50) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`tide_turner` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KILLS` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`Death` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KillAssist` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KillAssistMedic` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`BuildSentrygun` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`BuildDispenser` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`HeadshotKill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KOSentrygun` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`Domination` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`Overcharge` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KOSapper` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`BOTeleporterentrace` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KODispenser` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`BOTeleporterExit` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`CPBlocked` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`CPCaptured` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`FileCaptured` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ADCaptured` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KOTeleporterExit` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KOTeleporterEntrace` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`BOSapper` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`Revenge` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Axe` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Bnsw` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Bt` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Bttl` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Cg` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Fsts` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Ft` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Gl` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Kn` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Mctte` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Mgn` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Ndl` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Pistl` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Rkt` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Sg` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Sky` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Smg` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Spr` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Stgn` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Wrnc` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Sntry` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_SntryL1` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_SntryL2` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_SntryL3` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Shvl` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Ubersaw` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Flaregun` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Axtinguisher` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_pyro` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_heavy` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_gloves` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_backburner` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_natascha` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_blutsauger` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_rocket` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_promode` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_sticky` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_world` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bat_wood` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`player_stunned` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`drunk_bonk` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`player_stealsandvich` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`chat_status` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_tf_projectile_arrow` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ambassador` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_sniper` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_spy` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`player_extinguished` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`player_teleported` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`player_feigndeath` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_force_a_nature` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sandman` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`K_backstab` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_compound_bow` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_scout` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_arrow` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_rocketlauncher_directhit` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_telefrag` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_deflect_flare` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_soldier` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_pickaxe` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_demoshield` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sword` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_demoman` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sticky_resistance` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_tribalkukri` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_battleaxe` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ball` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_paintrain` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sledgehammer` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_unique_pickaxe` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_pumpkin` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_goomba` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_frontier_justice` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_wrangler_kill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_maxgun` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_southern_hospitality` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bleed_kill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm_blender_kill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_guitar_kill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_samrevolver` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_powerjack` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_degreaser` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_battleneedle` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_eternal_reward` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_letranger` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_short_stop` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_holy_mackerel` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bushwacka` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_urgentgloves` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sleeperrifle` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_blackbox` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ScoutDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`SoldierDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`PyroDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`DemoDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`HeavyDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`EngiDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`MedicDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`SniperDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`SpyDeaths` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ScoutKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`SoldierKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`PyroKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`DemoKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`HeavyKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`EngiKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`MedicKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`SniperKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`SpyKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`MedicHealing` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm_combo_kill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_fryingpan` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_headtaker` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_iron_curtain` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_amputator` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_healingcrossbow` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_brassbeast` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bearclaws` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_steelfists` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ullapool_caber` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ullapool_caber_explosion` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_minisentry` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_lochnload` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_candy_cane` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_boston_basher` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_back_scratcher` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_wrench_jag` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_claidheamohmor` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_worms_grenade` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_lava_axe` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sun_bat` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_jar` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_warfan` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_katana` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_kunai` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_witcher_sword` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_maul` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_soda_popper` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_the_winger` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_atomizer` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_liberty_launcher` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_reserve_shooter` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_disciplinary_action` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_market_gardener` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_mantreads` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_detonator` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_persian_persuader` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_splendid_screen` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_tomislav` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_family_business` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_eviction_notice` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_proto_syringe` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_solemn_vow` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bazaar_bargain` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_shahanshah` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_enforcer` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_big_earner` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_mailbox` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_golfclub` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bison` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_mangler` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_QuakeRL` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`TotalPlayersTeleported` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ManglerReflect` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Widowmaker` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Short_Circuit` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Machina` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Machina_DoubleKill` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Diamondback` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_UnarmedCombat` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_WangaPrick` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ScottishHandshake` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_ConscientiousObjector` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_Saxxy` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`EyeBossStuns` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`EyeBossKills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_phlogistinator` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_manmelter` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_thirddegree` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_holiday_punch` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_pomson` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_eureka_effect` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_sharp_dresser` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_spy_cicle` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_wrap_assassin` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_apocofists` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_black_rose` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`pep_brawlerblaster` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`pep_pistol` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`dumpster_device` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`unique_pickaxe_escape` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`rainblower` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`scorchshot` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`lollichop` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`armageddon` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`pro_rifle` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`pro_smg` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`long_heatmaker` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`annihilator` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`guillotine` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`recorder` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ham_shank` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`awper_hand` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`loose_cannon_impact` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`loose_cannon` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`skullbat` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`freedom_staff` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`the_rescue_ranger` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`memory_maker` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`golden_fryingpan` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`panic_attack` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`quickiebomb_launcher` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`necro_smasher` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`taunt_medic` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`crossing_guard` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`rescue_ranger_reflect` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`medigun_shield` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`iron_bomber` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ai_flamethrower` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_athletic` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_bats` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_blastjump` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_boss` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_fireball` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_lightning` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_mirv` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_skeleton` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_teleport` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`K_jar` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`rtd_toxic` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`rtd_timebomb` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`rtd_instant_kills` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`back_scatter` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`bread_bite` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`the_classic` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`spellbook_meteor` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`airstrike` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`STEAMID`)");
	len += Format(query[len], sizeof(query)-len, ") DEFAULT CHARSET=%s DEFAULT COLLATE=%s_unicode_ci;", DBCharSet, DBCharSet);
	SQL_FastQuery(db, query);
}

/*
#3. Add new SQLite DB queries
*/
createdbplayersqllite()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` INTEGER DEFAULT 0,`PLAYTIME` INTEGER DEFAULT 0, `LASTONTIME` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` INTEGER DEFAULT 0, `Death` INTEGER DEFAULT 0, `KillAssist` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KillAssistMedic` INTEGER DEFAULT 0, `BuildSentrygun` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `BuildDispenser` INTEGER DEFAULT 0, `HeadshotKill` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KOSentrygun` INTEGER DEFAULT 0, `Domination` INTEGER DEFAULT 0, `Overcharge` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KOSapper` INTEGER DEFAULT 0, `BOTeleporterentrace` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KODispenser` INTEGER DEFAULT 0, `BOTeleporterExit` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `CPBlocked` INTEGER DEFAULT 0, `CPCaptured` INTEGER DEFAULT 0, `FileCaptured` INTEGER DEFAULT 0, `ADCaptured` INTEGER DEFAULT 0, `KOTeleporterExit` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KOTeleporterEntrace` INTEGER DEFAULT 0, `BOSapper` INTEGER DEFAULT 0, `Revenge` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_Axe` INTEGER DEFAULT 0, `KW_Bnsw` INTEGER DEFAULT 0, `KW_Bt` INTEGER DEFAULT 0, `KW_Bttl` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_Cg` INTEGER DEFAULT 0, `KW_Fsts` INTEGER DEFAULT 0, `KW_Ft` INTEGER DEFAULT 0, `KW_Gl` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_Kn` INTEGER DEFAULT 0, `KW_Mctte` INTEGER DEFAULT 0, `KW_Mgn` INTEGER DEFAULT 0, `KW_Ndl` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_Pistl` INTEGER DEFAULT 0, `KW_Rkt` INTEGER DEFAULT 0, `KW_Sg` INTEGER DEFAULT 0, `KW_Sky` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_Smg` INTEGER DEFAULT 0, `KW_Spr` INTEGER DEFAULT 0, `KW_Stgn` INTEGER DEFAULT 0, `KW_Wrnc` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_Sntry` INTEGER DEFAULT 0, `KW_Shvl` INTEGER DEFAULT 0, `KW_Ubersaw` INTEGER DEFAULT 0, `KW_Flaregun` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_Axtinguisher` INTEGER DEFAULT 0, `KW_taunt_pyro` INTEGER DEFAULT 0, `KW_taunt_heavy` INTEGER DEFAULT 0, `KW_gloves` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_backburner` INTEGER DEFAULT 0, `KW_natascha` INTEGER DEFAULT 0, `KW_blutsauger` INTEGER DEFAULT 0, `KW_deflect_rocket` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_deflect_promode` INTEGER DEFAULT 0, `KW_deflect_sticky` INTEGER DEFAULT 0, `KW_world` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_bat_wood` INTEGER DEFAULT 0, `player_stunned` INTEGER DEFAULT 0, `drunk_bonk` INTEGER DEFAULT 0, `player_stealsandvich` INTEGER DEFAULT 0, `chat_status` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `KW_tf_projectile_arrow` INTEGER DEFAULT 0, `KW_ambassador` INTEGER DEFAULT 0, `KW_taunt_sniper` INTEGER DEFAULT 0, `KW_taunt_spy` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `player_extinguished` INTEGER DEFAULT 0, `player_teleported` INTEGER DEFAULT 0, `player_feigndeath` INTEGER DEFAULT 0, `KW_force_a_nature` INTEGER DEFAULT 0, `KW_sandman` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `K_backstab` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_compound_bow` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_scout` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_deflect_arrow` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_rocketlauncher_directhit` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_telefrag` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_deflect_flare` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_soldier` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_pickaxe` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_demoshield` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_sword` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_demoman` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_sticky_resistance` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_SntryL1` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_SntryL2` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_SntryL3` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_tribalkukri` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_battleaxe` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_ball` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_paintrain` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_sledgehammer` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_unique_pickaxe` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_pumpkin` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_goomba` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_frontier_justice` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_wrangler_kill` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_robot_arm` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_maxgun` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_southern_hospitality` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_bleed_kill` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_robot_arm_blender_kill` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_guitar_kill` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_samrevolver` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_powerjack` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_degreaser` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_battleneedle` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_eternal_reward` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_letranger` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_short_stop` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_holy_mackerel` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_bushwacka` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_urgentgloves` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `bread_bite` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_sleeperrifle` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_blackbox` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `ScoutDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `SoldierDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `PyroDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `DemoDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `HeavyDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `EngiDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `MedicDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `SniperDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `SpyDeaths` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `ScoutKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `SoldierKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `PyroKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `DemoKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `HeavyKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `EngiKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `MedicKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `SniperKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `SpyKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_robot_arm_combo_kill` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_fryingpan` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `MedicHealing` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_headtaker` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_iron_curtain` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_amputator` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_healingcrossbow` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_brassbeast` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_bearclaws` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_steelfists` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_ullapool_caber` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_ullapool_caber_explosion` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_minisentry` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_lochnload` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_candy_cane` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_boston_basher` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_back_scratcher` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_wrench_jag` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_claidheamohmor` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_worms_grenade` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_lava_axe` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_sun_bat` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_jar` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_warfan` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_katana` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_kunai` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_witcher_sword` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_maul` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_soda_popper` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_the_winger` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_atomizer` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_liberty_launcher` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_reserve_shooter` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_disciplinary_action` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_market_gardener` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_mantreads` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_detonator` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_persian_persuader` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_splendid_screen` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_tomislav` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_family_business` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_eviction_notice` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_proto_syringe` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_solemn_vow` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_bazaar_bargain` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_shahanshah` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_enforcer` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_big_earner` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_mailbox` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_golfclub` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_bison` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_mangler` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_QuakeRL` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `airstrike` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `TotalPlayersTeleported` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_ManglerReflect` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_Widowmaker` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_Short_Circuit` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_Machina` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_Machina_DoubleKill` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_Diamondback` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_UnarmedCombat` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_WangaPrick` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_ScottishHandshake` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_ConscientiousObjector` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_Saxxy` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `EyeBossKills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `EyeBossStuns` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_phlogistinator` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_manmelter` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_thirddegree` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_holiday_punch` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_pomson` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_eureka_effect` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_sharp_dresser` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_spy_cicle` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_wrap_assassin` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_apocofists` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `KW_black_rose` INTEGER DEFAULT 0");
	
	len += Format(query[len], sizeof(query)-len, ", `pep_brawlerblaster` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `pep_pistol` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `dumpster_device` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `unique_pickaxe_escape` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `rainblower` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `scorchshot` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `lollichop` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `armageddon` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `pro_rifle` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `the_classic` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `pro_smg` INTEGER DEFAULT 0");
	
	len += Format(query[len], sizeof(query)-len, ", `long_heatmaker` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `annihilator` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `guillotine` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `recorder` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `ham_shank` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `awper_hand` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `loose_cannon_impact` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `loose_cannon` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `skullbat` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `freedom_staff` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `the_rescue_ranger` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `memory_maker` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `golden_fryingpan` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `panic_attack` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `quickiebomb_launcher` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `necro_smasher` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `taunt_medic` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `iron_bomber` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `ai_flamethrower` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `crossing_guard` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `rescue_ranger_reflect` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `medigun_shield` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `back_scatter` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `rtd_instant_kills` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `rtd_timebomb` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `rtd_toxic` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `K_jar` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `tide_turner` INTEGER DEFAULT 0");

	len += Format(query[len], sizeof(query)-len, ", `spellbook_athletic` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_bats` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_blastjump` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_boss` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_fireball` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_lightning` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_meteor` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_mirv` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_skeleton` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ", `spellbook_teleport` INTEGER DEFAULT 0");
	len += Format(query[len], sizeof(query)-len, ");");
	SQL_FastQuery(db, query);
}

createdbkillog()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `killlog` (");
	len += Format(query[len], sizeof(query)-len, "`attacker` VARCHAR( 20 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`victim` VARCHAR( 20 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`assister` VARCHAR( 20 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`weapon` VARCHAR( 25 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`killtime` INT( 11 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`dominated` BOOL NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`assister_dominated` BOOL NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`revenge` BOOL NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`assister_revenge` BOOL NOT NULL");
	len += Format(query[len], sizeof(query)-len, ") DEFAULT CHARSET=%s DEFAULT COLLATE=%s_unicode_ci;", DBCharSet, DBCharSet);
	SQL_FastQuery(db, query);
}

createdbkillogsqllite()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `killlog` (");
	len += Format(query[len], sizeof(query)-len, "`attacker` VARCHAR( 20 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`victim` VARCHAR( 20 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`assister` VARCHAR( 20 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`weapon` VARCHAR( 25 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`killtime` INT( 11 ) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`dominated` BOOL NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`assister_dominated` BOOL NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`revenge` BOOL NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, "`assister_revenge` BOOL NOT NULL");
	len += Format(query[len], sizeof(query)-len, ");");
	SQL_FastQuery(db, query);
}

createdbmap()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Map`");
	len += Format(query[len], sizeof(query)-len, " (`NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` int(25) NOT NULL,`PLAYTIME` int(25) NOT NULL, `LASTONTIME` int(25) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` int(11) NOT NULL , `Death` int(11) NOT NULL , `KillAssist` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KillAssistMedic` int(11) NOT NULL , `BuildSentrygun` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `BuildDispenser` int(11) NOT NULL , `HeadshotKill` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KOSentrygun` int(11) NOT NULL , `Domination` int(11) NOT NULL , `Overcharge` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KOSapper` int(11) NOT NULL , `BOTeleporterentrace` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KODispenser` int(11) NOT NULL , `BOTeleporterExit` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `CPBlocked` int(11) NOT NULL , `Captured` int(11) NOT NULL , `KOTeleporterExit` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KOTeleporterEntrace` int(11) NOT NULL , `BOSapper` int(11) NOT NULL , `Revenge` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Axe` int(11) NOT NULL , `KW_Bnsw` int(11) NOT NULL , `KW_Bt` int(11) NOT NULL , `KW_Bttl` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Cg` int(11) NOT NULL , `KW_Fsts` int(11) NOT NULL , `KW_Ft` int(11) NOT NULL , `KW_Gl` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Kn` int(11) NOT NULL , `KW_Mctte` int(11) NOT NULL , `KW_Mgn` int(11) NOT NULL , `KW_Ndl` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Pistl` int(11) NOT NULL , `KW_Rkt` int(11) NOT NULL , `KW_Sg` int(11) NOT NULL , `KW_Sky` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Smg` int(11) NOT NULL , `KW_Spr` int(11) NOT NULL , `KW_Stgn` int(11) NOT NULL , `KW_Wrnc` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Sntry` int(11) NOT NULL , `KW_Shvl` int(11) NOT NULL , PRIMARY KEY (`NAME`)) DEFAULT CHARSET=%s DEFAULT COLLATE=%s_unicode_ci;", DBCharSet, DBCharSet);
	SQL_FastQuery(db, query);
}

createdbmapsqllite()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Map`");
	len += Format(query[len], sizeof(query)-len, " (`NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` int(25) NOT NULL,`PLAYTIME` int(25) NOT NULL, `LASTONTIME` int(25) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` int(11) NOT NULL , `Death` int(11) NOT NULL , `KillAssist` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KillAssistMedic` int(11) NOT NULL , `BuildSentrygun` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `BuildDispenser` int(11) NOT NULL , `HeadshotKill` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KOSentrygun` int(11) NOT NULL , `Domination` int(11) NOT NULL , `Overcharge` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KOSapper` int(11) NOT NULL , `BOTeleporterentrace` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KODispenser` int(11) NOT NULL , `BOTeleporterExit` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `CPBlocked` int(11) NOT NULL , `Captured` int(11) NOT NULL , `KOTeleporterExit` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KOTeleporterEntrace` int(11) NOT NULL , `BOSapper` int(11) NOT NULL , `Revenge` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Axe` int(11) NOT NULL , `KW_Bnsw` int(11) NOT NULL , `KW_Bt` int(11) NOT NULL , `KW_Bttl` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Cg` int(11) NOT NULL , `KW_Fsts` int(11) NOT NULL , `KW_Ft` int(11) NOT NULL , `KW_Gl` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Kn` int(11) NOT NULL , `KW_Mctte` int(11) NOT NULL , `KW_Mgn` int(11) NOT NULL , `KW_Ndl` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Pistl` int(11) NOT NULL , `KW_Rkt` int(11) NOT NULL , `KW_Sg` int(11) NOT NULL , `KW_Sky` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Smg` int(11) NOT NULL , `KW_Spr` int(11) NOT NULL , `KW_Stgn` int(11) NOT NULL , `KW_Wrnc` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_Sntry` int(11) NOT NULL , `KW_Shvl` int(11) NOT NULL , PRIMARY KEY (`NAME`));");
	SQL_FastQuery(db, query);
}

/*
#4. Add point cvars - see step 1
*/

public CreateCvars()
{
	//Generic kills and weapons
	Katana_Points = CreateConVar("rank_katana_points","8","Points:Samurai - Half-Zatoichi (Katana)");
	pistolpoints = CreateConVar("rank_pistolpoints","3","Points:Generic - Pistol");
	maxgunPoints = CreateConVar("rank_maxgunpoints","3","Points:Generic - The Lugermorph");
	shotgunpoints = CreateConVar("rank_shotgunpoints","2","Points:Generic - Shotgun");
	telefragpoints = CreateConVar("rank_telefragpoints","10","Points:Generic - Telefrag");
	goombapoints = CreateConVar("rank_goombastomp","6","Points:Generic - Goomba Stomp (mod)");
	pumpkinpoints = CreateConVar("rank_pumpkinpoints","2","Points:Generic - Pumpkin Bomb");
	worldpoints = CreateConVar("rank_worldpoints","4","Points:Generic - World Kill");
	stealsandvichpoints = CreateConVar("rank_stealsandvichpoints","1","Points:Generic - Steal Sandvich");
	extingushingpoints = CreateConVar("rank_extingushingpoints","1","Points:Generic - Extingush Player");
	bleed_killPoints = CreateConVar("rank_bleed_killpoints","3","Points:Generic - Bleed Kill"); //New v6:6
	fryingpanpoints = CreateConVar("rank_fryingpanpoints","4","Points:Generic - Frying Pan");
	headshotpoints = CreateConVar("rank_headshot_bonuspoints","2","Points:Generic - Extra points to award for headshots");
	Saxxy_Points = CreateConVar("rank_saxxy_points","4","Points:Generic Weapon - Saxxy");
	Objector_Points = CreateConVar("rank_objector_points","4","Points:Generic Weapon - Conscientious Objector");

	EyeBossKillAssist = CreateConVar("rank_eyeboss_kill_points","10","Points: Monoculus Kill Assist");
	EyeBossStun = CreateConVar("rank_eyeboss_stun_points","5","Points: Monoculus Stun");

	//Scout
	scattergunpoints = CreateConVar("rank_scattergunpoints","2","Points:Scout - Scattergun");
	batpoints = CreateConVar("rank_batpoints","4","Points:Scout - Bat");
	ballpoints = CreateConVar("rank_ballpoints","5","Points:Scout - Baseball");
	stun_points = CreateConVar("rank_stunpoints","1","Points: Scout - Stun Player");
	big_stun_points = CreateConVar("rank_big_stun","2","Points:Scout - Big Stun");
	bat_woodpoints = CreateConVar("rank_bat_woodpoints","3","Points:Scout - Sandman");
	force_a_naturepoints = CreateConVar("rank_force_a_naturepoints","2","Points:Scout - Force-a-Nature");
	sandmanpoints = CreateConVar("rank_sandmanpoints","3","Points:Scout - Sandman");
	taunt_scoutpoints = CreateConVar("rank_taunt_scoutpoints","6","Points:Scout - Sandman Taunt");
	short_stoppoints = CreateConVar("rank_short_stoppoints","2","Points:Scout - ShortStop");
	holy_mackerelpoints = CreateConVar("rank_holy_mackerelpoints","4","Points:Scout - Holy Mackerel");
	candy_canePoints = CreateConVar("rank_candycanepoints","4","Points:Scout - Candy Cane");
	boston_basherPoints = CreateConVar("rank_boston_basherpoints","6","Points:Scout - Boston Basher");
	SunBatPoints = CreateConVar("rank_sunbat_points","6","Points:Scout - Sun-on-a-Stick");
	Warfan_Points = CreateConVar("rank_warfan_points","6","Points:Scout - Fan O'War");
	Scout_Sword_Points = CreateConVar("rank_witcher_sword_points","6","Points:Scout - Three-Rune Blade");
	Popper_Points = CreateConVar("rank_soda_popper_points","2","Points:Scout - The Soda Popper");
	Winger_Points = CreateConVar("rank_winger_points","3","Points:Scout - The Winger");
	Atomizer_Points = CreateConVar("rank_atomizer_points","4","Points:Scout - The Atomizer");
	Unarmed_Combat_Points = CreateConVar("rank_unarmedcombat_points","4","Points:Scout - Unarmed Combat");
	WrapAssassin_Points = CreateConVar("rank_wrapassassin_points","6","Points:Scout - The Wrap Assassin");
	
	Brawlerblaster_Points = CreateConVar("rank_brawlerblaster_points","3","Points:Scout - Baby Face's Blaster");
	Pep_pistol_Points = CreateConVar("rank_pbpp_points","3","Points:Scout - Pretty Boy's Pocket Pistol");
	backscatter_points = CreateConVar("rank_backscatter_points","2","Points:Scout - Back Scatter");

	//Soldier
	tf_projectile_rocketpoints = CreateConVar("rank_tf_projectile_rocketpoints","2","Points:Soldier - Rocket Launcher");
	shovelpoints = CreateConVar("rank_shovelpoints","4","Points:Soldier - Shovel");
	rocketlauncher_directhitpoints = CreateConVar("rank_rocketlauncher_directhitpoints","2","Points:Soldier - Direct Hit");
	pickaxepoints = CreateConVar("rank_pickaxepoints","4","Points:Soldier - Equalizer");
	taunt_soldierpoints = CreateConVar("rank_taunt_soldierpoints","15","Points:Soldier - Grenade Taunt");
	paintrainpoints = CreateConVar("rank_paintrainpoints","4","Points:Soldier - Paintrain");
	uniquepickaxepoints = CreateConVar("rank_pickaxepoints_lowhealth","6","Points:Soldier - Equalizer - Low Health (defunct)"); //Defunct
	blackboxpoints = CreateConVar("rank_blackboxpoints","2","Points:Soldier - Black Box");
	worms_grenade_points = CreateConVar("rank_worms_grenade_points","15","Points:Soldier - Grenade Taunt (With worms hat)");
	Liberty_Points = CreateConVar("rank_liberty_launcher_points","2","Points:Soldier - Liberty Launcher");
	ReserveShooter_Points = CreateConVar("rank_reserve_shooter_points","2","Points:Soldier - Reserve Shooter");
	DisciplinaryAction_Points = CreateConVar("rank_disciplinary_action_points","5","Points:Soldier - Disciplinary Action");
	MarketGardener_Points = CreateConVar("rank_market_gardener_points","5","Points:Soldier - Market Gardener");
	Mantreads_Points = CreateConVar("rank_mantreads_points","15","Points:Soldier - Mantreads");
	Mangler_Points = CreateConVar("rank_mangler_points","2","Points:Soldier - Cow Mangler");
	RighteousBison_Points = CreateConVar("rank_bison_points","3","Points:Soldier - Righteous Bison");
	Quake_RocketLauncher_Points = CreateConVar("rank_the_original_points","3","Points:Soldier - The Original");
	
	Dumpster_Device_Points = CreateConVar("rank_beggarsbazooka_points","4","Points:Soldier - Beggar's Bazooka");
	Pickaxe_Escape_Points = CreateConVar("rank_pickaxe_escape_points","6","Points:Soldier - The Escape Plan");
	Airstrike_Points = CreateConVar("rank_airstrike_points","3","Points:Soldier - AirStrike");

	//Pyro
	flamethrowerpoints = CreateConVar("rank_flamethrowerpoints","3","Points:Pyro - Flamethrower");
	backburnerpoints = CreateConVar("rank_backburnerpoints","2","Points:Pyro - Backburner");
	fireaxepoints = CreateConVar("rank_fireaxepoints","4","Points:Pyro - Fireaxe");
	flaregunpoints = CreateConVar("rank_flaregunpoints","4","Points:Pyro - Flaregun");
	axtinguisherpoints = CreateConVar("rank_axtinguisherpoints","4","Points:Pyro - Axtinguisher");
	taunt_pyropoints = CreateConVar("rank_taunt_pyropoints","6","Points:Pyro - Taunt");
	sledgehammerpoints = CreateConVar("rank_sledgehammerpoints","5","Points:Pyro - Sledgehammer");
	deflect_rocketpoints = CreateConVar("rank_deflect_rocketpoints","2","Points:Pyro - Deflected Rocket");
	deflect_promodepoints = CreateConVar("rank_deflect_promodepoints","2","Points:Pyro - Deflected ???");
	deflect_stickypoints = CreateConVar("rank_deflect_stickypoints","2","Points:Pyro - Deflected Sticky");
	deflect_arrowpoints = CreateConVar("rank_deflect_arrowpoints","15","Points:Pyro - Deflected Arrow");
	deflect_flarepoints = CreateConVar("rank_deflect_flarepoints","8","Points:Pyro - Deflected Flare");
	powerjackpoints = CreateConVar("rank_powerjackpoints","4","Points:Pyro - PowerJack");
	degreaserpoints = CreateConVar("rank_degreaserpoints","3","Points:Pyro - Degreaser");
	back_scratcherPoints = CreateConVar("rank_backscratcherpoints","5","Points:Pyro - Back Scratcher");
	LavaAxePoints = CreateConVar("rank_lava_axe_points","6","Points:Pyro - Sharpened Volcano Fragment");
	The_Maul_Points = CreateConVar("rank_maul_points","5","Points:Pyro - The Maul");
	Detonator_Points = CreateConVar("rank_detonator_points","5","Points:Pyro - The Detonator");
	Mailbox_Points = CreateConVar("rank_mailbox_points","4","Points:Pyro - The Postal Pummeler");
	ManglerReflect_Points = CreateConVar("rank_mangler_reflect_points", "8", "Points:Pyro - Deflected Cow Mangler");
	Phlogistinator_Points = CreateConVar("rank_phlogistinator_points", "2", "Points:Pyro - The Phlogistinator");
	Manmelter_Points = CreateConVar("rank_manmelter_points", "3", "Points:Pyro - The Manmelter");
	Thirddegree_Points = CreateConVar("rank_thirddegree_points", "5", "Points:Pyro - The Third Degree");
	
	Rainblower_Points = CreateConVar("rank_rainblower_points", "3", "Points:Pyro - The Rainblower");
	Scorchshot_Points = CreateConVar("rank_scorchedshot_points", "5", "Points:Pyro - The scorchedshot");
	Lollichop_Points = CreateConVar("rank_Lollichop_points", "4", "Points:Pyro - Lollichop");
	Armageddon_taunt_Points = CreateConVar("rank_armageddon_points", "15", "Points:Pyro - Armageddon taunt");


	//Demo
	tf_projectile_pipepoints = CreateConVar("rank_tf_projectile_pipepoints","2","Points:Demo - Pipebomb Launcher");
	tf_projectile_pipe_remotepoints = CreateConVar("rank_tf_projectile_pipe_remotepoints","2","Points:Demo - Sticky Launcher");
	bottlepoints = CreateConVar("rank_bottlepoints","4","Points:Demo - Bottle");
	demoshieldpoints = CreateConVar("rank_demoshieldpoints","10","Points:Demo - Shield Charge");
	swordpoints = CreateConVar("rank_swordpoints","4","Points:Demo - Eyelander");
	taunt_demomanpoints = CreateConVar("rank_taunt_demomanpoints","9","Points:Demo - Taunt");
	sticky_resistancepoints = CreateConVar("rank_sticky_resistancepoints","2","Points:Demo - Scottish Resistance");
	battleaxepoints = CreateConVar("rank_battleaxepoints","4","Points:Demo - Skullcutter");
	headtakerpoints = CreateConVar("rank_headtakerpoints","5","Points:Demo - Unusual Headtaker Axe");
	ullapool_caberPoints = CreateConVar("rank_ullapool_caberpoints","6","Points:Demo - Ullapool Caber");
	UllaExplodePoints = CreateConVar("rank_ullapool_explode_points","5","Points:Demo - Ullapool Caber Explosion");
	lochnloadPoints = CreateConVar("rank_lochnloadpoints","4","Points:Demo - Loch-n-Load");
	gaelicclaymorePoints = CreateConVar("rank_gaelicclaymore","4","Points:Demo - Claidheamh Mor");
	Persian_Persuader_Points = CreateConVar("rank_persian_persuader_points","4","Points:Demo - Persian Persuader");
	Splendid_Screen_Points = CreateConVar("rank_splendid_screen_points","8","Points:Demo - Splendid Screen Shield Charge");
	Golfclub_Points = CreateConVar("rank_golfclub_points","4","Points:Demo - Nessie's Nine Iron");
	Scottish_Handshake_Points = CreateConVar("rank_scottish_handshake_points","4","Points:Demo - Scottish Handshake");
	
	Tide_Turner_Points = CreateConVar("rank_tide_turner_points","8","Points:Demo - Tide Turner Shield Charge");


	//Heavy
	minigunpoints = CreateConVar("rank_minigunpoints","1","Points:Heavy - Minigun");
	fistspoints = CreateConVar("rank_fistspoints","4","Points:Heavy - Fist");
	glovespoints = CreateConVar("rank_killingglovespoints","4","Points:Heavy - KGBs");
	taunt_heavypoints = CreateConVar("rank_taunt_heavypoints","6","Points:Heavy - Taunt");
	nataschapoints = CreateConVar("rank_nataschapoints","1","Points:Heavy - Natascha");
	urgentglovespoints = CreateConVar("rank_urgentglovespoints","6","Points:Heavy - Gloves of Running Urgently");
	ironcurtainpoints = CreateConVar("rank_ironcurtainpoints","1","Points:Heavy - Iron Curtain");
	BrassBeastPoints = CreateConVar("rank_brassbeastpoints","1","Points:Heavy - Brass Beast");
	bear_clawsPoints = CreateConVar("rank_warriors_spiritpoints","4","Points:Heavy - Warrior's Spirit");
	steel_fistsPoints = CreateConVar("rank_fistsofsteelpoints","4","Points:Heavy - Fists of Steel");
	Tomislav_Points = CreateConVar("rank_tomislav_points","1","Points:Heavy - Tomislav");
	Family_Business_Points = CreateConVar("rank_family_business_points","3","Points:Heavy - Family Business");
	Eviction_Notice_Points = CreateConVar("rank_eviction_notice_points","4","Points:Heavy - Eviction Notice");
	Holiday_Punch_Points = CreateConVar("rank_holiday_punch_points","4","Points:Heavy - The Holiday Punch");
	ApocoFists_Points = CreateConVar("rank_apocofist_points","4","Points:Heavy - The Apocofists");
	
	bread_bite_points = CreateConVar("rank_bread_bite_points","4","Points:Heavy - Bread Bite");

	//Engi
	obj_sentrygunpoints = CreateConVar("rank_obj_sentrygunpoints","3","Points:Engineer - Sentry");
	MinisentryPoints = CreateConVar("rank_minisentry_points","4","Points:Engineer - Mini-Sentry");
	wrenchpoints = CreateConVar("rank_wrenchpoints","7","Points:Engineer - Wrench");
	frontier_justicePoints = CreateConVar("rank_frontier_justicepoints","3","Points:Engineer - Frontier Justice"); //New v6:6
	wrangler_killPoints = CreateConVar("rank_wrangler_points","4","Points:Engineer - Wrangler"); //New v6:6
	robot_armPoints = CreateConVar("rank_robot_armpoints","5","Points:Engineer - Gunslinger"); //New v6:6
	southern_hospitalityPoints = CreateConVar("rank_southern_hospitalitypoints","6","Points:Engineer - Southern Hospitality"); //New v6:6
	robot_arm_blender_killPoints = CreateConVar("rank_robot_arm_blender_points","10","Points:Engineer - Gunslinger Taunt"); //New v6:6
	taunt_guitar_killPoints = CreateConVar("rank_taunt_guitar_points","10","Points:Engineer - Taunt Guitar"); //New v6:6
	robot_arm_combo_killPoints = CreateConVar("rank_robot_arm_combo_killpoints","20","Points:Engineer - Gunslinger 3-Hit Combo Kill");
	wrench_jagPoints = CreateConVar("rank_jagpoints","8","Points:Engineer - The Jag");
	TeleUsePoints = CreateConVar("rank_tele_use_points","1","Points:Engineer - Teleporter Use");
	WidowmakerPoints = CreateConVar("rank_widowmaker_points","3","Points:Engineer - Widowmaker");
	Short_CircuitPoints = CreateConVar("rank_shortcircuit_points","30","Points:Engineer - The Short Circuit");
	Pomson_Points = CreateConVar("rank_pomson_points","4","Points:Engineer - The Pomson 6000");
	Eureka_Effect_Points = CreateConVar("rank_eureka_effect_points","7","Points:Engineer - The Eureka Effect");


	//Medic
	bonesawpoints = CreateConVar("rank_bonesawpoints","6","Points:Medic - Bonesaw");
	syringegun_medicpoints = CreateConVar("rank_syringegun_medicpoints","4","Points:Medic - Syringe Gun");
	killasimedipoints = CreateConVar("rank_killasimedicpoints","3","Points:Medic - Kill Asist");
	overchargepoints = CreateConVar("rank_overchargepoints","2","Points:Medic - Ubercharge");
	ubersawpoints = CreateConVar("rank_ubersawpoints","6","Points:Medic - Ubersaw");
	blutsaugerpoints = CreateConVar("rank_blutsaugerpoints","4","Points:Medic - Blutsauger");
	battleneedlepoints = CreateConVar("rank_battleneedlepoints","6","Points:Medic - Vita-Saw");
	amputatorPoints = CreateConVar("rank_amputatorpoints","6","Points:Medic - Amputator");
	medicCrossbowPoints = CreateConVar("rank_mediccrossbowpoints","5","Points:Medic - Amputator");
	Proto_Syringe_Points = CreateConVar("rank_overdose_points","4","Points:Medic - The Overdose");
	Solemn_Vow_Points = CreateConVar("rank_solemn_vow_points","6","Points:Medic - The Solemn Vow");


	//Sniper
	sniperriflepoints = CreateConVar("rank_sniperriflepoints","1","Points:Sniper - Rifle");
	smgpoints = CreateConVar("rank_smgpoints","3","Points:Sniper - SMG");
	clubpoints = CreateConVar("rank_clubpoints","4","Points:Sniper - Kukri");
	woodknifepoints = CreateConVar("rank_woodknifepoints","4","Points:Sniper - Shiv");
	tf_projectile_arrowpoints = CreateConVar("rank_tf_projectile_arrowpoints","1","Points:Sniper - Huntsman");
	taunt_sniperpoints = CreateConVar("rank_taunt_sniperpoints","6","Points:Sniper - Huntsman Taunt");
	compound_bowpoints = CreateConVar("rank_compound_bowpoints","2","Points:Sniper - Huntsman");
	sleeperpoints = CreateConVar("rank_sleeperpoints","2","Points:Sniper - Sydney Sleeper");
	bushwackapoints = CreateConVar("rank_bushwackapoints","4","Points:Sniper - Bushwacka");
	Bazaar_Bargain_Points = CreateConVar("rank_bazaar_bargain_points","1","Points:Sniper - Bazaar Bargain");
	Shahanshah_Points = CreateConVar("rank_shahanshah_points", "5", "Points:Sniper - Shahanshah");
	Machina_Points = CreateConVar("rank_machina_points", "2", "Points:Sniper - Machina");
	Machina_DoubleKill_Points = CreateConVar("rank_machina_doublekill_points", "5", "Points:Sniper - Machina Double Kill");
	
	Pro_rifle_Points = CreateConVar("rank_pro_rifle_points", "1", "Points:Sniper - Hitman's Heatmaker");
	The_classic_Points = CreateConVar("rank_the_classic_points", "1", "Points:Sniper - The Classic");
	Pro_smg_Points = CreateConVar("rank_pro_smg_points", "2", "Points:Sniper - Cleaner's Carbine");


	//Spy
	revolverpoints = CreateConVar("rank_revolverpoints","3","Points:Spy - Revolver");
	knifepoints = CreateConVar("rank_knifepoints","4","Points:Spy - Knife");
	ambassadorpoints = CreateConVar("rank_ambassadorpoints","4","Points:Spy - Ambassador");
	taunt_spypoints = CreateConVar("rank_taunt_spypoints","12","Points:Spy - Knife Taunt");
	samrevolverpoints = CreateConVar("rank_samrevolverpoints","3","Points:Spy - Sam's Revolver");
	eternal_rewardpoints = CreateConVar("rank_eternal_rewardpoints","4","Points:Spy - Eternal Reward");
	letrangerpoints = CreateConVar("rank_letrangerpoints","3","Points:Spy - L'Etranger");
	Kunai_Points = CreateConVar("rank_kunai_points","4","Points:Spy - Conniver's Kunai");
	Enforcer_Points = CreateConVar("rank_enforcer_points","3","Points:Spy - The Enforcer");
	Big_Earner_Points = CreateConVar("rank_big_earner_points","3","Points:Spy - The Big Earner");
	Diamondback_Points = CreateConVar("rank_diamondback_points","3","Points:Spy - The Diamondback");
	Wanga_Prick_Points = CreateConVar("rank_wanga_prickpoints","4","Points:Spy - Wanga Prick");
	Sharp_Dresser_Points = CreateConVar("rank_sharp_dresser_points","4","Points:Spy - The Sharp Dresser");
	Spy_Cicle_Points = CreateConVar("rank_spy_cicle_points","4","Points:Spy - The Spy-cicle");
	BlackRose_Points = CreateConVar("rank_blackrose_points","4","Points:Spy - The Black Rose");
	
	// Sleeping Dogs Items
	long_heatmaker = CreateConVar("rank_long_heatmaker_points","1","Points:Heavy - The Huo-Long Heater");
	annihilator = CreateConVar("rank_annihilator_points","3","Points:Pyro - The Neon Annihilator");
	guillotine = CreateConVar("rank_guillotine_points","4","Points:Scout - The Flying Guillotine");
	recorder = CreateConVar("rank_recorder_points","1","Points:Spy - The Red-Tape Recorder");


	// New Weapons
	ham_shank = CreateConVar("rank_ham_shank_points","4","Points:Generic - The Ham Shank");
	awper_hand = CreateConVar("rank_awper_hand_points","1","Points:Sniper - The AWPer Hand");
	loose_cannon_impact = CreateConVar("rank_loose_cannon_impact_points","2","Points:Demo - The Loose Cannon");
	loose_cannon = CreateConVar("rank_loose_cannon_points","2","Points:Demo - The Loose Cannon");
	skullbat = CreateConVar("rank_skullbat_points","2","Points:Generic - The Bat Outta Hell");
	freedom_staff = CreateConVar("rank_freedom_staff_points","2","Points:Generic - The Freedom Staff");
	the_rescue_ranger = CreateConVar("rank_the_rescue_ranger_points","3","Points:Engineer - The Rescue Ranger");
	memory_maker = CreateConVar("rank_memory_maker_points","3","Points:Generic - The Memory Maker");
	golden_fryingpan = CreateConVar("rank_golden_fryingpan_points","4","Points:Generic - The Golden Frying Pan");
	panic_attack = CreateConVar("rank_panic_attack_points","2","Points:Generic - The Panic Attack");
	iron_bomber = CreateConVar("rank_iron_bomber_points","2","Points:Demo - The Iron Bomber");
	ai_flamethrower = CreateConVar("rank_ai_flamethrower_points","2","Points:Pyro - The AI Flamethrower");
	quickiebomb_launcher = CreateConVar("rank_quickiebomb_launcher_points","2","Points:Demo - The QuickieBomb Launcher");
	necro_smasher = CreateConVar("rank_necro_smasher_points","2","Points:Generic - The Necro Smasher");
	taunt_medic = CreateConVar("rank_taunt_medic_points","2","Points:Medic - The Necro Smasher");
	crossing_guard = CreateConVar("rank_crossing_guard_points","2","Points:Generic - The Crossing Guard");
	rescue_ranger_reflect = CreateConVar("rank_rescue_ranger_reflect_points","2","Points:Pyro - The Rescue Ranger Reflect");
	medigun_shield = CreateConVar("rank_medigun_shield_points","2","Points:Medic - The Medigun Shield");


	// Spells
	spellbook_athletic = CreateConVar("rank_spellbook_athletic_points","2","Points:Generic - Spell Minify");
	spellbook_bats = CreateConVar("rank_spellbook_bats_points","2","Points:Generic - Spell Ball O' Bats");
	spellbook_blastjump = CreateConVar("rank_spellbook_blastjump_points","2","Points:Generic - Spell Superjump");
	spellbook_boss = CreateConVar("rank_spellbook_boss_points","2","Points:Generic - Spell Summon MONOCULUS");
	spellbook_fireball = CreateConVar("rank_spellbook_fireball_points","2","Points:Generic - Spell Fireball");
	spellbook_lightning = CreateConVar("rank_spellbook_lightning_points","2","Points:Generic - Spell Tesla Bolt");
	spellbook_meteor = CreateConVar("rank_spellbook_meteor_points","2","Points:Generic - Spell Meteor Shower");
	spellbook_mirv = CreateConVar("rank_spellbook_mirv_points","2","Points:Generic - Spell Pumpkin MIRV");
	spellbook_skeleton = CreateConVar("rank_spellbook_skeleton_points","2","Points:Generic - Spell Summon Skeletons");
	spellbook_teleport = CreateConVar("rank_spellbook_teleport_points","2","Points:Generic - Spell Teleport");


	// RTD
	rtd_toxic = CreateConVar("rank_rtd_toxic_points","1","Points:Generic - RTD Toxic");
	rtd_timebomb = CreateConVar("rank_rtd_timebomb_points","1","Points:Generic - RTD Timebomb");
	rtd_instant_kills = CreateConVar("rank_rtd_instant_kills_points","1","Points:Generic - RTD Instant Kills");

	//Events
	killsapperpoints = CreateConVar("rank_killsapperpoints","1","Points:Generic - Sapper Kill");
	killteleinpoints = CreateConVar("rank_killteleinpoints","1","Points:Generic - Tele Kill");
	killteleoutpoints = CreateConVar("rank_killteleoutpoints","1","Points:Generic - Tele Kill");
	killdisppoints = CreateConVar("rank_killdisppoints","2","Points:Generic - Dispensor Kill");
	killsentrypoints = CreateConVar("rank_killsentrypoints","3","Points:Generic - Sentry Kill");

	//Other cvars
	v_RankCheckTimeout = CreateConVar("rank_player_check_rank_timeout","300.0","Time time to make players wait before they check check 'rank' again", 0, true, 1.0, false);
	v_TimeOffset = CreateConVar("rank_time_offset","0","Number of seconds to change the server timestamp by");
	showrankonroundend = CreateConVar("rank_showrankonroundend","1","Shows player's ranks on Roundend");
	roundendranktochat = CreateConVar("rank_show_roundend_rank_in_chat","0", "Prints all connected players' ranks to chat on round end (will spam chat!)");
	showSessionStatsOnRoundEnd = CreateConVar("rank_show_kdr_onroundend","1", "Show clients their session stats and kill/death ratio when the round ends");
	removeoldplayers = CreateConVar("rank_removeoldplayers","0","Enable automatic removal of players who don't connect within a specific number of days. (Old records will be removed on round end) ");
	removeoldplayersdays = CreateConVar("rank_removeoldplayersdays","0","Number of days to keep players in database (since last connection)");
	killasipoints = CreateConVar("rank_killasipoints","2","Points:Generic - Kill Asist");

	Capturepoints = CreateConVar("rank_capturepoints","2","Points:Generic - Capture Points");
	Captureblockpoints = CreateConVar("rank_blockcapturepoints","4","Points:Generic - Capture Block Points");
	FileCapturepoints = CreateConVar("rank_filecapturepoints","4","Points:Generic - CTF Capture Points (Whole team bonus)");
	CTFCapPlayerPoints = CreateConVar("rank_filecapturepoints_player","20","Points:Generic - CTF Capture Points (Capping player)");
	CPCapPlayerPoints = CreateConVar("rank_pointcapturepoints_player","10","Points:Generic - Control Point Capture Points (Capping player)");

	removeoldmaps = CreateConVar("rank_removeoldmaps","1","Enable Automatic Removing Maps who wasn't played a specific time on every Roundend");
	removeoldmapssdays = CreateConVar("rank_removeoldmapsdays","14","The time in days after a map get removed, min 1 day");
	showrankonconnect = CreateConVar("rank_show_on_connect","4","Show player's rank on connect, 0 = Disabled, 1 = To Client, 2 = Public Chat, 3 = Panel (Client only), 4 = Panel + Public Chat", 0, true, 0.0, true, 4.0);
	webrank = CreateConVar("rank_webrank","0","Enable/Disable Webrank");
	webrankurl = CreateConVar("rank_webrankurl","","Webrank URL, example: http://yoursite.com/stats/", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	neededplayercount = CreateConVar("rank_neededplayers","4","How many clients are needed to start ranking");
	disableafterwin = CreateConVar("rank_disableafterroundwin","1","Disable kill counting after round ends");
	pointmsg = CreateConVar("rank_pointmsg","2","Show point earned message to: 0 = disabled, 1 = all, 2 = only who earned");
	CV_chattag = CreateConVar("rank_chattag","RANK","Set the Chattag");
	CV_showchatcommands = CreateConVar("rank_showchatcommands","1","show chattags 1=enable 0=disable");
	ConnectSound = CreateConVar("rank_connectsound","1","Play a sound when a player connects? 1= Yes 0 = No");
	ConnectSoundFile = CreateConVar("rank_connectsoundfile","buttons/blip1.wav","Sound to play when a player connects (plays for all players)");
	ConnectSoundTop10 = CreateConVar("rank_connectsoundtop10","0","Play a special sound for players in the Top 10");
	ConnectSoundFileTop10 = CreateConVar("rank_connectsoundfiletop10","tf2stats/top10.wav","Sound to play for Top10s");
	DBCharSetDef = CreateConVar("rank_DBCharSet","1","Sets database character set default utf8.");

	CountryCodeHandler = CreateConVar("rank_connectcountry", "3", "How to display connecting player's country, 0 = Don't show country, 1 = two char: (US, CA, etc), 2 = three char: (USA, CAN, etc), 3 = Full country name: (United States, etc)", 0, true, 0.0, true, 3.0);
	showranktoall = CreateConVar("rank_showranktoall","1","Show player's rank to everybody");
	ignorebots = CreateConVar("rank_ignorebots","1","Give bots points? 1/0 - 0 allows bots to get points");
	ignoreTeamKills = CreateConVar("rank_ignoreteamkills", "1", "1 = Teamkills are ignored, 0 = Teamkills are tracked", 0, true, 0.0, true, 1.0);
	ShowTeleNotices = CreateConVar("rank_show_tele_point_notices", "1", "1 = Tell the engi when a player uses their tele, 0 = Don't show the message", 0, true, 0.0, true, 1.0);
	logips = CreateConVar("rank_logips","1","Log player's ip addresses 1/0"); //new v6:6

	ShowEnoughPlayersNotice = CreateConVar("rank_show_player_count_notice", "1", "Set to 0 to hide the 'there are enough players' messages", 0, true, 0.0, true, 1.0);
	ShowRoundEnableNotice = CreateConVar("rank_show_round_enable_disable_notice", "1", "Set to 0 to hide the rank enabled/disabled due to round start/end notices", 0, true, 0.0, true, 1.0);

	//Death points
	disablediepoints = CreateConVar("rank_chatdiepoints","1","Disable message when killed");
	Scoutdiepoints = CreateConVar("rank_Scoutdiepoints","2","Points Scouts lose when killed");
	Soldierdiepoints = CreateConVar("rank_Soldierdiepoints","2","Points Soldiers lose when killed");
	Pyrodiepoints = CreateConVar("rank_Pyrodiepoints","2","Points Pyros lose when killed");
	Medicdiepoints = CreateConVar("rank_Medicdiepoints","2","Points Medics lose when killed");
	Sniperdiepoints = CreateConVar("rank_Sniperdiepoints","2","Points Snipers lose when killed");
	Spydiepoints = CreateConVar("rank_Spydiepoints","2","Points Spies lose when killed");
	Demomandiepoints = CreateConVar("rank_Demomandiepoints","2","Points Demos lose when killed");
	Heavydiepoints = CreateConVar("rank_Heavydiepoints","2","Points Heavies lose when killed");
	Engineerdiepoints = CreateConVar("rank_Engineerdiepoints","2","Points Engineers lose when killed");

	//---========---
	CV_extendetlogging = CreateConVar("rank_extendetlogging", "1", "1 Enables / 0 Disables Extended Logging")
	CV_extlogcleanuptime = CreateConVar("rank_extlogcleanuptime", "72", "Defines the time until a entry in the Kill-log gets removed in hours 0 = disabled")
	CV_rank_enable = CreateConVar("rank_enable", "1", "1 Enables / 0 Disables gaining points")
	//---========---

	//VIPs

	vip_points1 = CreateConVar("rank_vip_points1", "0", "Points players earn for killing VIP #1");
	vip_points2 = CreateConVar("rank_vip_points2", "0", "Points players earn for killing VIP #2");
	vip_points3 = CreateConVar("rank_vip_points3", "0", "Points players earn for killing VIP #3");
	vip_points4 = CreateConVar("rank_vip_points4", "0", "Points players earn for killing VIP #4");
	vip_points5 = CreateConVar("rank_vip_points5", "0", "Points players earn for killing VIP #5");

	vip_steamid1 = CreateConVar("rank_vip_steamid1", "", "SteamID of VIP #1");
	vip_steamid2 = CreateConVar("rank_vip_steamid2", "", "SteamID of VIP #2");
	vip_steamid3 = CreateConVar("rank_vip_steamid3", "", "SteamID of VIP #3");
	vip_steamid4 = CreateConVar("rank_vip_steamid4", "", "SteamID of VIP #4");
	vip_steamid5 = CreateConVar("rank_vip_steamid5", "", "SteamID of VIP #5");

	vip_message1 = CreateConVar("rank_vip_message1", "", "Extra text to show players who kill VIP #1");
	vip_message2 = CreateConVar("rank_vip_message2", "", "Extra text to show players who kill VIP #2");
	vip_message3 = CreateConVar("rank_vip_message3", "", "Extra text to show players who kill VIP #3");
	vip_message4 = CreateConVar("rank_vip_message4", "", "Extra text to show players who kill VIP #4");
	vip_message5 = CreateConVar("rank_vip_message5", "", "Extra text to show players who kill VIP #5");
}

public HookEvents()
{
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
	HookEvent("item_found", Event_item_found);
	HookEvent("player_stealsandvich", Event_player_stealsandvich);
	HookEvent("player_teleported", Event_player_teleported);
	HookEvent("player_extinguished", Event_player_extinguished);
	HookEvent("player_stunned", Event_player_stunned);

	//Halloween 2011!
	HookEvent("eyeball_boss_killer", OnEyeBossDeath);
	HookEvent("eyeball_boss_stunned", OnEyeBossStunned);
}

public OnEyeBossDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new client = GetEventInt(event, "player_entindex")
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		decl String:query[512];
		new iPoints = GetConVarInt(EyeBossKillAssist);

		Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, EyeBossKills = EyeBossKills + 1 WHERE STEAMID = '%s'", iPoints, SteamID);
		sessionpoints[client] = sessionpoints[client] + iPoints;
		SQL_TQuery(db, SQLErrorCheckCallback, query);
		new pointmsgval = GetConVarInt(pointmsg);
		if (pointmsgval >=1)
		{
			if (pointmsgval == 1)
				PrintToChatAll("\x04[\x03%s\x04]\x05 %N\x01 got %i points for helping to kill \x06The Monoculus!!", CHATTAG, client, iPoints)
			else if (cookieshowrankchanges[client])
			{
				PrintToChat(client,"\x04[\x03%s\x04]\x01 you got %i points for helping to kill \x06The Monoculus!!", CHATTAG, iPoints)
			}
		}
	}
}

public OnEyeBossStunned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new client = GetEventInt(event, "player_entindex")
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		decl String:query[512];
		new iPoints = GetConVarInt(EyeBossStun);

		Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, EyeBossStuns = EyeBossStuns + 1 WHERE STEAMID = '%s'", iPoints, SteamID);
		sessionpoints[client] = sessionpoints[client] + iPoints;
		SQL_TQuery(db, SQLErrorCheckCallback, query);
		new pointmsgval = GetConVarInt(pointmsg);
		if (pointmsgval >=1)
		{
			if (pointmsgval == 1)
				PrintToChatAll("\x04[\x03%s\x04]\x05 %N\x01 got %i points for stunning \x06The Monoculus!!", CHATTAG, client, iPoints)
			else if (cookieshowrankchanges[client])
			{
				PrintToChat(client,"\x04[\x03%s\x04]\x01 you got %i points for stunning \x06The Monoculus!!", CHATTAG, iPoints)
			}
		}
	}
}


public Event_player_stunned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		new attacker = GetClientOfUserId(GetEventInt(event, "stunner"));
		new bool:bigstun = GetEventBool(event, "big_stun")
		
		if (attacker != 0 && !IsFakeClient(attacker))
		{
			new String:steamId[MAX_LINE_WIDTH];
			GetClientAuthId(attacker, AuthId_Steam2, steamId, sizeof(steamId));
			decl String:query[512];
			new pointvalue;
			if (bigstun)
				pointvalue = GetConVarInt(big_stun_points);
			else
				pointvalue = GetConVarInt(stun_points);
			Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, player_stunned = player_stunned + 1 WHERE STEAMID = '%s'",pointvalue, steamId);
			sessionpoints[attacker] = sessionpoints[attacker] + pointvalue;
			SQL_TQuery(db,SQLErrorCheckCallback,query);
			new pointmsgval = GetConVarInt(pointmsg);
			if (pointmsgval >=1)
			{
				if (pointmsgval == 1)
				{
					if (bigstun)
						PrintToChatAll("\x04[\x03%s\x04]\x05 %N\x01 got %i points for stunning \x05%N\x01 (Moon Shot)", CHATTAG, attacker, pointvalue, victim)
					else
						PrintToChatAll("\x04[\x03%s\x04]\x05 %N\x01 got %i points for stunning \x05%N\x01", CHATTAG, attacker, pointvalue, victim)
				}
				else
				{
					if (cookieshowrankchanges[attacker])
					{
						if (bigstun)
							PrintToChat(attacker,"\x04[\x03%s\x04]\x01 you got %i points for stunning \x05%N\x01 (Moon Shot)",CHATTAG,pointvalue, victim)
						else
							PrintToChat(attacker,"\x04[\x03%s\x04]\x01 you got %i points for stunning \x05%N\x01",CHATTAG,pointvalue, victim)
					}
				}
			}
		}
	}
	return;
}

public Event_player_stealsandvich(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "target"))
		if (client != 0 && !IsFakeClient(client))
		{
			new String:steamId[MAX_LINE_WIDTH];
			GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
			decl String:query[512];
			new pointvalue = GetConVarInt(stealsandvichpoints)
			Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, player_stealsandvich = player_stealsandvich + 1 WHERE STEAMID = '%s'",pointvalue, steamId);
			sessionpoints[client] = sessionpoints[client] + pointvalue
			SQL_TQuery(db,SQLErrorCheckCallback, query);
			new pointmsgval = GetConVarInt(pointmsg)
			if (pointmsgval >= 1)
			{
				new playeruid = GetEventInt(event, "owner")
				new playerid = GetClientOfUserId(playeruid)
				if (pointmsgval == 1)
				{
					PrintToChatAll("\x04[\x03%s\x04]\x01 %N got %i points for stealing %N's Sandvich", CHATTAG, client, pointvalue, playerid)
				}
				else
				{
					if (cookieshowrankchanges[client])
					{
						PrintToChat(client,"\x04[\x03%s\x04]\x01 you got %i points for stealing %N's Sandvich", CHATTAG, pointvalue, playerid)
					}
				}
			}
		}
	}
}

public Event_player_invulned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new userid = GetEventInt(event, "medic_userid")
		new client = GetClientOfUserId(userid)
		if (overchargescoring[client])
		{
			overchargescoring[client] = false
			overchargescoringtimer[client] = CreateTimer(40.0,resetoverchargescoring,client)
			new String:steamIdassister[MAX_LINE_WIDTH];
			GetClientAuthId(client, AuthId_Steam2, steamIdassister, sizeof(steamIdassister));
			decl String:query[512];

			/*
			#############################
			# 							#
			#		-- Bot Check --		#
			#							#
			#############################
			*/

			new bool:isbotassist;
			if (StrEqual(steamIdassister,"BOT"))
			{
				// Player is assister. Assister is a bot
				isbotassist = true;
				//PrintToChatAll("Assister is a BOT");
			}
			else
			{
				//Not a bot.
				isbotassist = false;
				//PrintToChatAll("Killer is not a BOT");
			}
			new bool:ShouldIgnoreBots = GetConVarBool(ignorebots);
			if (ShouldIgnoreBots == false)
			{
				isbotassist = false;
			}

			new pointvalue = GetConVarInt(overchargepoints)
			Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, Overcharge = Overcharge + 1 WHERE STEAMID = '%s'",pointvalue, steamIdassister);
			sessionpoints[client] = sessionpoints[client] + pointvalue
			if (isbotassist == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
			new pointmsgval = GetConVarInt(pointmsg)
			if (pointmsgval >= 1)
			{
				new String:medicname[MAX_LINE_WIDTH];
				GetClientName(client,medicname, sizeof(medicname))
				new playeruid = GetEventInt(event, "userid")
				new playerid = GetClientOfUserId(playeruid)
				new String:playername[MAX_LINE_WIDTH];
				GetClientName(playerid,playername, sizeof(playername))
				if (pointmsgval == 1)
				{
					PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for Ubercharging %s",CHATTAG,medicname,pointvalue,playername)
				}
				else
				{
					if (cookieshowrankchanges[client])
					{
						PrintToChat(client,"\x04[\x03%s\x04]\x01 you got %i points for Ubercharging %s",CHATTAG,pointvalue,playername)
					}
				}
			}
		}
	}
}


public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (rankingactive && rankingenabled)
	{
		if (db == INVALID_HANDLE && dbReconnect == INVALID_HANDLE)
		{
			dbReconnect = CreateTimer(900.0, ReconnectToDB);
			return;
		}
		new victimId = GetEventInt(event, "userid")
		new attackerId = GetEventInt(event, "attacker")
		new assisterId = GetEventInt(event, "assister")
		new deathflags = GetEventInt(event, "death_flags")
		new bool:nofakekill = true
		new bool:ExeQuery = false

		new df_assisterrevenge = 0
		new df_killerrevenge = 0
		new df_assisterdomination = 0
		new df_killerdomination = 0

		if (deathflags & 32)
		{
			nofakekill = false
		}

		if (deathflags & 8)
		{
			df_assisterrevenge = 1
		}

		if (deathflags & 4)
		{
			df_killerrevenge = 1
		}

		if (deathflags & 2)
		{
			df_assisterdomination = 1
		}

		if (deathflags & 1)
		{
			df_killerdomination = 1
		}

		new assister = GetClientOfUserId(assisterId)
		new victim = GetClientOfUserId(victimId)
		new attacker = GetClientOfUserId(attackerId)
		new customkill = GetEventInt(event, "customkill")

		new bool:isknife = false
		new String:attackername[MAX_LINE_WIDTH]
		new pointvalue = GetConVarInt(killasimedipoints)
		new pointmsgval = GetConVarInt(pointmsg)
		new disablediemsgval = GetConVarInt(disablediepoints)

		// Teamkill check
		new aTeam = -1;
		if (attacker != 0)
		{
			aTeam = GetClientTeam(attacker);
		}
		new vTeam = GetClientTeam(victim);

		if (aTeam != vTeam || !GetConVarBool(ignoreTeamKills))
		{


			if (attacker != 0)
			{
				if (attacker != victim)
				{
					new String:steamIdassister[MAX_LINE_WIDTH];
					GetClientName(attacker,attackername,sizeof(attackername))
					decl String:query[512];
					if (assister != 0)
					{
						sessionassi[assister]++
						GetClientAuthId(assister, AuthId_Steam2, steamIdassister, sizeof(steamIdassister));
						//new class = TF2_GetPlayerClass(assister) //changed from TF_GetClass

						/*
						#############################
						# 							#
						#		-- Bot Check --		#
						#							#
						#############################
						*/

						new bool:isbotassist;
						if (StrEqual(steamIdassister,"BOT"))
						{
							// Player is assister. Assister is a bot
							isbotassist = true;
							//PrintToChatAll("Assister is a BOT");
						}
						else
						{
							//Not a bot.
							isbotassist = false;
							//PrintToChatAll("Assister is not a BOT");
						}
						new bool:ShouldIgnoreBots = GetConVarBool(ignorebots);
						if (ShouldIgnoreBots == false)
						{
							isbotassist = false;
						}

						if (TF2_GetPlayerClass(assister) == TF2_GetClass("medic")) //changed from == 5
						{
							if (nofakekill)
							{
								Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KillAssistMedic = KillAssistMedic + 1 WHERE STEAMID = '%s'",pointvalue, steamIdassister);

								if (isbotassist == false)
								{
									SQL_TQuery(db,SQLErrorCheckCallback, query);
								}
								sessionpoints[assister] = sessionpoints[assister] + pointvalue
							}
						}
						else
						{
							if (nofakekill)
							{
								pointvalue = GetConVarInt(killasipoints)
								Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KillAssist = KillAssist + 1 WHERE STEAMID = '%s'",pointvalue, steamIdassister);

								if (isbotassist == false)
								{
									SQL_TQuery(db,SQLErrorCheckCallback, query);
								}
								sessionpoints[assister] = sessionpoints[assister] + pointvalue
							}
						}

						if (pointmsgval >= 1)
						{
							new String:assiname[MAX_LINE_WIDTH];
							GetClientName(assister,assiname, sizeof(assiname))

							if (pointmsgval == 1)
							{
								PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for assisting %s",CHATTAG,assiname,pointvalue,attackername)
							}
							else
							{
								if (cookieshowrankchanges[assister])
								{
									PrintToChat(assister,"\x04[\x03%s\x04]\x01 you got %i points for assisting %s",CHATTAG,pointvalue,attackername)
								}
							}
						}

						if (df_assisterdomination)
						{
							Format(query, sizeof(query), "UPDATE Player SET Domination = Domination + 1 WHERE STEAMID = '%s'", steamIdassister);
							if (isbotassist == false)
							{
								SQL_TQuery(db,SQLErrorCheckCallback, query);
							}
						}

						if (df_assisterrevenge)
						{
							Format(query, sizeof(query), "UPDATE Player SET Revenge = Revenge + 1 WHERE STEAMID = '%s'", steamIdassister);
							if (isbotassist == false)
							{
								SQL_TQuery(db,SQLErrorCheckCallback, query);
							}
						}
					}

					new String:weapon[64]
					GetEventString(event, "weapon_logclassname", weapon, sizeof(weapon))
					PrintToConsole(attacker,"[TF2 Stats Debug] Weapon %s",weapon)

					new String:steamIdattacker[MAX_LINE_WIDTH];
					new String:steamIdavictim[MAX_LINE_WIDTH];
					GetClientAuthId(attacker, AuthId_Steam2, steamIdattacker, sizeof(steamIdattacker));
					GetClientAuthId(victim, AuthId_Steam2, steamIdavictim, sizeof(steamIdavictim));

					/*
					#############################
					# 							#
					#		-- Bot Check --		#
					#			Attacker		#
					#############################
					*/


					new bool:isbot;
					if (StrEqual(steamIdattacker,"BOT"))
					{
						//Attacker is a bot
						isbot = true;
						//PrintToChatAll("Killer is a BOT");
					}
					else
					{
						//Not a bot.
						isbot = false;
						//PrintToChatAll("Killer is not a BOT");
					}
					new bool:ShouldIgnoreBots = GetConVarBool(ignorebots);
					if (ShouldIgnoreBots == false)
					{
						isbot = false;
					}

					/*
					#############################
					# 							#
					#		-- Bot Check --		#
					#			Victim			#
					#############################
					*/

					new bool:isvicbot;
					if (StrEqual(steamIdavictim,"BOT"))
					{
						// Player is victim. Victim is a bot
						isvicbot = true;
					}
					else
					{
						//Not a bot.
						isvicbot = false;
					}
					//new bool:ShouldIgnoreBots = GetConVarBool(ignorebots);
					if (ShouldIgnoreBots == false)
					{
						isvicbot = false;
					}

					new TFClassType:attackerclass = TF2_GetPlayerClass(attacker)
					switch(attackerclass)
					{
						case TFClass_Sniper:
						{
							Format(query, sizeof(query), "UPDATE Player SET SniperKills = SniperKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_Medic:
						{
							Format(query, sizeof(query), "UPDATE Player SET MedicKills = MedicKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_Soldier:
						{
							Format(query, sizeof(query), "UPDATE Player SET SoldierKills = SoldierKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_Pyro:
						{
							Format(query, sizeof(query), "UPDATE Player SET PyroKills = PyroKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_DemoMan:
						{
							Format(query, sizeof(query), "UPDATE Player SET DemoKills = DemoKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_Engineer:
						{
							Format(query, sizeof(query), "UPDATE Player SET EngiKills = EngiKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_Spy:
						{
							Format(query, sizeof(query), "UPDATE Player SET SpyKills = SpyKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_Scout:
						{
							Format(query, sizeof(query), "UPDATE Player SET ScoutKills = ScoutKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						case TFClass_Heavy:
						{
							Format(query, sizeof(query), "UPDATE Player SET HeavyKills = HeavyKills + 1 WHERE STEAMID = '%s'", steamIdattacker);
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
					}

					/*
						------- VIP Checks --------
					*/

					decl String:VIPSteamID1[32];
					decl String:VIPSteamID2[32];
					decl String:VIPSteamID3[32];
					decl String:VIPSteamID4[32];
					decl String:VIPSteamID5[32];

					GetConVarString(vip_steamid1, VIPSteamID1, sizeof(VIPSteamID1));
					GetConVarString(vip_steamid2, VIPSteamID2, sizeof(VIPSteamID2));
					GetConVarString(vip_steamid3, VIPSteamID3, sizeof(VIPSteamID3));
					GetConVarString(vip_steamid4, VIPSteamID4, sizeof(VIPSteamID4));
					GetConVarString(vip_steamid5, VIPSteamID5, sizeof(VIPSteamID5));

					decl String:VIPMessage[512];
					new bonuspoints = 0;
					if (StrEqual(steamIdavictim, VIPSteamID1, false))
					{
						//VIP #1
						bonuspoints = GetConVarInt(vip_points1);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", bonuspoints, steamIdattacker);
						if (nofakekill == true && isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
							//Chat
							GetConVarString(vip_message1, VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[\x03%s\x04]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}

					}
					else if (StrEqual(steamIdavictim, VIPSteamID2, false))
					{
						//VIP #2
						bonuspoints = GetConVarInt(vip_points2);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", bonuspoints, steamIdattacker);
						if (nofakekill == true && isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
							//Chat
							GetConVarString(vip_message2, VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[\x03%s\x04]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}

					}
					else if (StrEqual(steamIdavictim, VIPSteamID3, false))
					{
						//VIP #3
						bonuspoints = GetConVarInt(vip_points3);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", bonuspoints, steamIdattacker);
						if (nofakekill == true && isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
							//Chat
							GetConVarString(vip_message3, VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[\x03%s\x04]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}

					}
					else if (StrEqual(steamIdavictim, VIPSteamID4, false))
					{
						//VIP #4
						bonuspoints = GetConVarInt(vip_points4);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", bonuspoints, steamIdattacker);
						if (nofakekill == true && isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
							//Chat
							GetConVarString(vip_message4, VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[\x03%s\x04]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}

					}
					else if (StrEqual(steamIdavictim, VIPSteamID5, false))
					{
						//VIP #5
						bonuspoints = GetConVarInt(vip_points5);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", bonuspoints, steamIdattacker);
						if (nofakekill == true && isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
							//Chat
							GetConVarString(vip_message5, VIPMessage, sizeof(VIPMessage));
							PrintToChat(attacker, "\x04[\x03%s\x04]\x01 You have earned \x05%i Bonus Points\x01 for killing \x04%N\x01 %s", CHATTAG, bonuspoints, victim, VIPMessage);
						}

					}

					//------ End VIP stuff ----------

					new iHealing = GetEntProp(victim, Prop_Send, "m_iHealPoints");
					//PrintToChatAll("%N healed a total of %i", victim, iHealing)
					new currentHeal = iHealing - TotalHealing[victim];
					//PrintToChatAll("%N healed %i this life", victim, currentHeal)
					TotalHealing[victim] = iHealing;

					if (currentHeal > 0)
					{
						Format(query, sizeof(query), "UPDATE Player SET MedicHealing = MedicHealing + %i WHERE STEAMID = '%s'", currentHeal, steamIdavictim);
						SQL_TQuery(db,SQLErrorCheckCallback, query);
						//PrintToChatAll("Data Sent")
					}

					/*
					#5. Add point-adding queries
					*/

					new diepointsvalue
					new String:DeathClass[128]
					new TFClassType:class = TF2_GetPlayerClass(victim)
					switch(class)
					{
						case TFClass_Sniper:
						{
							diepointsvalue = GetConVarInt(Sniperdiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "SniperDeaths")
						}
						case TFClass_Medic:
						{
							diepointsvalue = GetConVarInt(Medicdiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "MedicDeaths")
						}
						case TFClass_Soldier:
						{
							diepointsvalue = GetConVarInt(Soldierdiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "SoldierDeaths")
						}
						case TFClass_Pyro:
						{
							diepointsvalue = GetConVarInt(Pyrodiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "PyroDeaths")
						}
						case TFClass_DemoMan:
						{
							diepointsvalue = GetConVarInt(Demomandiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "DemoDeaths")
						}
						case TFClass_Engineer:
						{
							diepointsvalue = GetConVarInt(Engineerdiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "EngiDeaths")
						}
						case TFClass_Spy:
						{
							diepointsvalue = GetConVarInt(Spydiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "SpyDeaths")
						}
						case TFClass_Scout:
						{
							diepointsvalue = GetConVarInt(Scoutdiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "ScoutDeaths")
						}
						case TFClass_Heavy:
						{
							diepointsvalue = GetConVarInt(Heavydiepoints)
							strcopy(DeathClass, sizeof(DeathClass), "HeavyDeaths")
						}
					}

					if (nofakekill == true)
					{
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS - %i, %s = %s + 1, Death = Death + 1 WHERE STEAMID = '%s'", diepointsvalue, DeathClass, DeathClass, steamIdavictim);
						sessiondeath[victim]++
						sessionpoints[victim] = sessionpoints[victim] - diepointsvalue
					}
					else
					{
						Format(query, sizeof(query), "UPDATE Player SET player_feigndeath = player_feigndeath + 1 WHERE STEAMID = '%s'",steamIdavictim);
					}
					if (isvicbot == false) //player killed is not a bot, so death++ and points -X
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query);
					}
					if (pointmsgval >= 1)
					{
						new String:victimname[MAX_LINE_WIDTH];
						GetClientName(victim,victimname, sizeof(victimname))

						if (pointmsgval == 1 && disablediemsgval == 1)
						{
							PrintToChatAll("\x04[\x03%s\x04]\x01 %s lost %i points for dying",CHATTAG,victimname,diepointsvalue)
						}
						else
						{
							if (cookieshowrankchanges[victim])
							{
								if (disablediemsgval == 1)
								{
									if (nofakekill == true && isbot == false)
									{
										PrintToChat(victim,"\x04[\x03%s\x04]\x01 you lost %i points for dying",CHATTAG,diepointsvalue)
									}
								}
							}
						}
					}

					if (df_killerdomination)
					{
						Format(query, sizeof(query), "UPDATE Player SET Domination = Domination + 1 WHERE STEAMID = '%s'", steamIdattacker);
						if (isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
					}
					if (df_killerrevenge)
					{
						Format(query, sizeof(query), "UPDATE Player SET Revenge = Revenge + 1 WHERE STEAMID = '%s'", steamIdattacker);
						if (isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
					}
					if (nofakekill == true && isbot == false)
					{
						sessionkills[attacker]++
					}
					pointvalue = 0
					
					if (strcmp(weapon[0], "scattergun", false) == 0)
					{
						pointvalue = GetConVarInt(scattergunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sg = KW_Sg + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "back_scatter", false) == 0)
					{
						pointvalue = GetConVarInt(backscatter_points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, back_scatter = back_scatter + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bat", false) == 0)
					{
						pointvalue = GetConVarInt(batpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bt = KW_Bt + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "pistol_scout", false) == 0)
					{
						pointvalue = GetConVarInt(pistolpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Pistl = KW_Pistl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tf_projectile_rocket", false) == 0)
					{
						//Fixy for valve's stupidity
						new weaponent = GetPlayerWeaponSlot(attacker, 0);
						if (weaponent > 0 && IsValidEdict(weaponent) && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 228)
						{
							//its a Black-Box!
							// Changed in one of the updates around 1/10
							pointvalue = GetConVarInt(blackboxpoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_blackbox = KW_blackbox + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
						// /Fixy for valve's stupidity

						else
						{
							pointvalue = GetConVarInt(tf_projectile_rocketpoints)
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Rkt = KW_Rkt + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
					}
					else if (strcmp(weapon[0], "blackbox", false) == 0)
					{
						pointvalue = GetConVarInt(blackboxpoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_blackbox = KW_blackbox + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "shotgun_soldier", false) == 0)
					{
						pointvalue = GetConVarInt(shotgunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "shovel", false) == 0)
					{
						pointvalue = GetConVarInt(shovelpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Shvl = KW_Shvl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "flamethrower", false) == 0)
					{
						pointvalue = GetConVarInt(flamethrowerpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ft = KW_Ft + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "fireaxe", false) == 0)
					{
						pointvalue = GetConVarInt(fireaxepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Axe = KW_Axe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "shotgun_pyro", false) == 0)
					{
						pointvalue = GetConVarInt(shotgunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------RTD---------------------------------
					else if (strcmp(weapon[0], "rtd_toxic", false) == 0)
					{
						pointvalue = GetConVarInt(rtd_toxic)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, rtd_toxic = rtd_toxic + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "rtd_timebomb", false) == 0)
					{
						pointvalue = GetConVarInt(rtd_timebomb)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, rtd_timebomb = rtd_timebomb + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "rtd_instant_kills", false) == 0)
					{
						pointvalue = GetConVarInt(rtd_instant_kills)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, rtd_instant_kills = rtd_instant_kills + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------RTD---------------------------------
					//----------------------------Spells---------------------------------
					else if (strcmp(weapon[0], "spellbook_athletic", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_athletic)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_athletic = spellbook_athletic + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_bats", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_bats)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_bats = spellbook_bats + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_blastjump", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_blastjump)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_blastjump = spellbook_blastjump + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_boss", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_boss)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_boss = spellbook_boss + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_fireball", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_fireball)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_fireball = spellbook_fireball + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_lightning", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_lightning)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_lightning = spellbook_lightning + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_meteor", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_meteor)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_meteor = spellbook_meteor + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_mirv", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_mirv)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_mirv = spellbook_mirv + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_skeleton", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_skeleton)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_skeleton = spellbook_skeleton + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spellbook_teleport", false) == 0)
					{
						pointvalue = GetConVarInt(spellbook_teleport)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, spellbook_teleport = spellbook_teleport + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Spells---------------------------------
					//----------------------------New Weapons---------------------------------
					else if (strcmp(weapon[0], "ham_shank", false) == 0)
					{
						pointvalue = GetConVarInt(ham_shank)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, ham_shank = ham_shank + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "awper_hand", false) == 0)
					{
						pointvalue = GetConVarInt(awper_hand)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, awper_hand = awper_hand + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "loose_cannon_impact", false) == 0)
					{
						pointvalue = GetConVarInt(loose_cannon_impact)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, loose_cannon_impact = loose_cannon_impact + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "loose_cannon", false) == 0)
					{
						pointvalue = GetConVarInt(loose_cannon)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, loose_cannon = loose_cannon + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "skullbat", false) == 0)
					{
						pointvalue = GetConVarInt(skullbat)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, skullbat = skullbat + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "freedom_staff", false) == 0)
					{
						pointvalue = GetConVarInt(freedom_staff)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, freedom_staff = freedom_staff + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "the_rescue_ranger", false) == 0)
					{
						pointvalue = GetConVarInt(the_rescue_ranger)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, the_rescue_ranger = the_rescue_ranger + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "memory_maker", false) == 0)
					{
						pointvalue = GetConVarInt(memory_maker)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, memory_maker = memory_maker + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "golden_fryingpan", false) == 0)
					{
						pointvalue = GetConVarInt(golden_fryingpan)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, golden_fryingpan = golden_fryingpan + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "panic_attack", false) == 0)
					{
						pointvalue = GetConVarInt(panic_attack)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, panic_attack = panic_attack + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "iron_bomber", false) == 0)
					{
						pointvalue = GetConVarInt(iron_bomber)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, iron_bomber = iron_bomber + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "ai_flamethrower", false) == 0)
					{
						pointvalue = GetConVarInt(ai_flamethrower)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, ai_flamethrower = ai_flamethrower + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "quickiebomb_launcher", false) == 0)
					{
						pointvalue = GetConVarInt(quickiebomb_launcher)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, quickiebomb_launcher = quickiebomb_launcher + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "necro_smasher", false) == 0)
					{
						pointvalue = GetConVarInt(necro_smasher)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, necro_smasher = necro_smasher + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "taunt_medic", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_medic)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, taunt_medic = taunt_medic + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "crossing_guard", false) == 0)
					{
						pointvalue = GetConVarInt(crossing_guard)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, crossing_guard = crossing_guard + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "rescue_ranger_reflect", false) == 0)
					{
						pointvalue = GetConVarInt(rescue_ranger_reflect)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, rescue_ranger_reflect = rescue_ranger_reflect + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "entity_medigun_shield", false) == 0)
					{
						pointvalue = GetConVarInt(medigun_shield)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, medigun_shield = medigun_shield + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------New Weapons---------------------------------
					//----------------------------Sleeping Dogs Promo Update---------------------------------
					else if (strcmp(weapon[0], "long_heatmaker", false) == 0)
					{
						pointvalue = GetConVarInt(long_heatmaker)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, long_heatmaker = long_heatmaker + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "annihilator", false) == 0)
					{
						pointvalue = GetConVarInt(annihilator)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, annihilator = annihilator + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "guillotine", false) == 0)
					{
						pointvalue = GetConVarInt(guillotine)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, guillotine = guillotine + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "recorder", false) == 0)
					{
						pointvalue = GetConVarInt(recorder)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, recorder = recorder + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Sleeping Dogs Promo Update---------------------------------
					//----------------------------Assassin's Creed Promo Update---------------------------------
					else if (strcmp(weapon[0], "sharp_dresser", false) == 0)
					{
						pointvalue = GetConVarInt(Sharp_Dresser_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sharp_dresser = KW_sharp_dresser + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Assassin's Creed Promo Update---------------------------------

					//----------------------------Christmas 2011 Update---------------------------------
					else if (strcmp(weapon[0], "phlogistinator", false) == 0)
					{
						pointvalue = GetConVarInt(Phlogistinator_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_phlogistinator = KW_phlogistinator + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "manmelter", false) == 0)
					{
						pointvalue = GetConVarInt(Manmelter_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_manmelter = KW_manmelter + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "thirddegree", false) == 0)
					{
						pointvalue = GetConVarInt(Thirddegree_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_thirddegree = KW_thirddegree + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "holiday_punch", false) == 0)
					{
						pointvalue = GetConVarInt(Holiday_Punch_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_holiday_punch = KW_holiday_punch + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					// Meet the pyro items
					else if (strcmp(weapon[0], "pep_brawlerblaster", false) == 0)
					{
						pointvalue = GetConVarInt(Brawlerblaster_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, pep_brawlerblaster = pep_brawlerblaster + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "pep_pistol", false) == 0)
					{
						pointvalue = GetConVarInt(Pep_pistol_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, pep_pistol = pep_pistol + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "dumpster_device", false) == 0)
					{
						pointvalue = GetConVarInt(Dumpster_Device_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, dumpster_device = dumpster_device + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "unique_pickaxe_escape", false) == 0)
					{
						pointvalue = GetConVarInt(Pickaxe_Escape_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, unique_pickaxe_escape = unique_pickaxe_escape + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "rainblower", false) == 0)
					{
						pointvalue = GetConVarInt(Rainblower_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, rainblower = rainblower + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "scorchshot", false) == 0)
					{
						pointvalue = GetConVarInt(Scorchshot_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, scorchshot = scorchshot + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "lollichop", false) == 0)
					{
						pointvalue = GetConVarInt(Lollichop_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, lollichop = lollichop + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "armageddon", false) == 0)
					{
						pointvalue = GetConVarInt(Armageddon_taunt_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, armageddon = armageddon + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "pro_rifle", false) == 0)
					{
						pointvalue = GetConVarInt(Pro_rifle_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, pro_rifle = pro_rifle + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "the_classic", false) == 0)
					{
						pointvalue = GetConVarInt(The_classic_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, the_classic = the_classic + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "pro_smg", false) == 0)
					{
						pointvalue = GetConVarInt(Pro_smg_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, pro_smg = pro_smg + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//-------
					else if (strcmp(weapon[0], "pomson", false) == 0)
					{
						pointvalue = GetConVarInt(Pomson_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pomson = KW_pomson + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "eureka_effect", false) == 0)
					{
						pointvalue = GetConVarInt(Eureka_Effect_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_eureka_effect = KW_eureka_effect + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "spy_cicle", false) == 0)
					{
						pointvalue = GetConVarInt(Spy_Cicle_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_spy_cicle = KW_spy_cicle + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Christmas 2011 Update---------------------------------

					//----------------------------Halloween 2011 Update---------------------------------
					else if (strcmp(weapon[0], "nonnonviolent_protest", false) == 0)
					{
						pointvalue = GetConVarInt(Objector_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ConscientiousObjector = KW_ConscientiousObjector + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "unarmed_combat", false) == 0)
					{
						pointvalue = GetConVarInt(Unarmed_Combat_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_UnarmedCombat = KW_UnarmedCombat + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "scotland_shard", false) == 0)
					{
						pointvalue = GetConVarInt(Scottish_Handshake_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ScottishHandshake = KW_ScottishHandshake + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "voodoo_pin", false) == 0)
					{
						pointvalue = GetConVarInt(Wanga_Prick_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_WangaPrick = KW_WangaPrick + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Halloween 2011 Update---------------------------------
					//----------------------------Quakecon Update---------------------------------
					else if (strcmp(weapon[0], "quake_rl", false) == 0)
					{
						pointvalue = GetConVarInt(Quake_RocketLauncher_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_QuakeRL = KW_QuakeRL + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Love and War Update---------------------------------
					else if (strcmp(weapon[0], "airstrike", false) == 0)
					{
						pointvalue = GetConVarInt(Airstrike_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, airstrike = airstrike + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Deus Ex Update---------------------------------
					else if (strcmp(weapon[0], "widowmaker", false) == 0)
					{
						pointvalue = GetConVarInt(WidowmakerPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Widowmaker = KW_Widowmaker + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "short_circuit", false) == 0)
					{
						pointvalue = GetConVarInt(Short_CircuitPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Short_Circuit = KW_Short_Circuit + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "machina", false) == 0)
					{
						pointvalue = GetConVarInt(Machina_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Machina = KW_Machina + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "player_penetration", false) == 0)
					{
						pointvalue = GetConVarInt(Machina_DoubleKill_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Machina_DoubleKill = KW_Machina_DoubleKill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "diamondback", false) == 0)
					{
						pointvalue = GetConVarInt(Diamondback_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Diamondback = KW_Diamondback + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Space Update---------------------------------
					else if (strcmp(weapon[0], "cow_mangler", false) == 0)
					{
						pointvalue = GetConVarInt(Mangler_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mangler = KW_mangler + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "righteous_bison", false) == 0)
					{
						pointvalue = GetConVarInt(RighteousBison_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bison = KW_bison + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tf_projectile_energy_ball", false) == 0)
					{
						pointvalue = GetConVarInt(ManglerReflect_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ManglerReflect = KW_ManglerReflect + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Witcher Update---------------------------------
					else if (strcmp(weapon[0], "scout_sword", false) == 0)
					{
						pointvalue = GetConVarInt(Scout_Sword_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_witcher_sword = KW_witcher_sword + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Red Faction: Armageddon Update---------------------------------
					else if (strcmp(weapon[0], "the_maul", false) == 0)
					{
						pointvalue = GetConVarInt(The_Maul_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_maul = KW_maul + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Samurai Update---------------------------------
					else if (strcmp(weapon[0], "demokatana", false) == 0)
					{
						pointvalue = GetConVarInt(Katana_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_katana = KW_katana + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "kunai", false) == 0)
					{
						pointvalue = GetConVarInt(Kunai_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_kunai = KW_kunai + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "warfan", false) == 0)
					{
						pointvalue = GetConVarInt(Warfan_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_warfan = KW_warfan + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Samurai Update---------------------------------
					//----------------------------Summer Update---------------------------------
					else if (strcmp(weapon[0], "mailbox", false) == 0)
					{
						pointvalue = GetConVarInt(Mailbox_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mailbox = KW_mailbox + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "nessieclub", false) == 0)
					{
						pointvalue = GetConVarInt(Golfclub_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_golfclub = KW_golfclub + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------Summer Update---------------------------------
					//----------------------------Uber Update---------------------------------
					else if (strcmp(weapon[0], "soda_popper", false) == 0)
					{
						pointvalue = GetConVarInt(Popper_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_soda_popper = KW_soda_popper + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "the_winger", false) == 0)
					{
						pointvalue = GetConVarInt(Winger_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_the_winger = KW_the_winger + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "atomizer", false) == 0)
					{
						pointvalue = GetConVarInt(Atomizer_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_atomizer = KW_atomizer + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "liberty_launcher", false) == 0)
					{
						pointvalue = GetConVarInt(Liberty_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_liberty_launcher = KW_liberty_launcher + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "reserve_shooter", false) == 0)
					{
						pointvalue = GetConVarInt(ReserveShooter_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_reserve_shooter = KW_reserve_shooter + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "disciplinary_action", false) == 0)
					{
						pointvalue = GetConVarInt(DisciplinaryAction_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_disciplinary_action = KW_disciplinary_action + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "market_gardener", false) == 0)
					{
						pointvalue = GetConVarInt(MarketGardener_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_market_gardener = KW_market_gardener + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "mantreads", false) == 0)
					{
						pointvalue = GetConVarInt(Mantreads_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mantreads = KW_mantreads + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "detonator", false) == 0)
					{
						pointvalue = GetConVarInt(Detonator_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_detonator = KW_detonator + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "persian_persuader", false) == 0)
					{
						pointvalue = GetConVarInt(Persian_Persuader_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_persian_persuader = KW_persian_persuader + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "splendid_screen", false) == 0)
					{
						pointvalue = GetConVarInt(Splendid_Screen_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_splendid_screen = KW_splendid_screen + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tide_turner", false) == 0)
					{
						pointvalue = GetConVarInt(Tide_Turner_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, tide_turner = tide_turner + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tomislav", false) == 0)
					{
						pointvalue = GetConVarInt(Tomislav_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tomislav = KW_tomislav + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "family_business", false) == 0)
					{
						pointvalue = GetConVarInt(Family_Business_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_family_business = KW_family_business + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "eviction_notice", false) == 0)
					{
						pointvalue = GetConVarInt(Eviction_Notice_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_eviction_notice = KW_eviction_notice + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "proto_syringe", false) == 0)
					{
						pointvalue = GetConVarInt(Proto_Syringe_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_proto_syringe = KW_proto_syringe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "solemn_vow", false) == 0)
					{
						pointvalue = GetConVarInt(Solemn_Vow_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_solemn_vow = KW_solemn_vow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bazaar_bargain", false) == 0)
					{
						pointvalue = GetConVarInt(Bazaar_Bargain_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bazaar_bargain = KW_bazaar_bargain + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "shahanshah", false) == 0)
					{
						pointvalue = GetConVarInt(Shahanshah_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_shahanshah = KW_shahanshah + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "enforcer", false) == 0)
					{
						pointvalue = GetConVarInt(Enforcer_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_enforcer = KW_enforcer + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "big_earner", false) == 0)
					{
						pointvalue = GetConVarInt(Big_Earner_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_big_earner = KW_big_earner + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------End Uber Update---------------------------------
					else if (strcmp(weapon[0], "taunt_soldier_lumbricus", false) == 0)
					{
						pointvalue = GetConVarInt(worms_grenade_points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_worms_grenade = KW_worms_grenade + 1 WHERE STEAMID = '%s'", pointvalue, steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tf_projectile_pipe", false) == 0)
					{
						new weaponent = GetPlayerWeaponSlot(attacker, 0);
						if (weaponent > 0 && IsValidEdict(weaponent) && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 308)
						{
							// Loch-n-Load
							// Fixed 1/10
							pointvalue = GetConVarInt(lochnloadPoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_lochnload = KW_lochnload + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
						else
						{
							pointvalue = GetConVarInt(tf_projectile_pipepoints)
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Gl = KW_Gl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
					}
					else if (strcmp(weapon[0], "loch_n_load", false) == 0)
					{
						pointvalue = GetConVarInt(lochnloadPoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_lochnload = KW_lochnload + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tf_projectile_pipe_remote", false) == 0)
					{
						pointvalue = GetConVarInt(tf_projectile_pipe_remotepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sky = KW_Sky + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bottle", false) == 0)
					{
						pointvalue = GetConVarInt(bottlepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bttl = KW_Bttl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "minigun", false) == 0)
					{
						pointvalue = GetConVarInt(minigunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_CG = KW_CG + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "fists", false) == 0)
					{
						pointvalue = GetConVarInt(fistspoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Fsts = KW_Fsts + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "shotgun_hwg", false) == 0)
					{
						pointvalue = GetConVarInt(shotgunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "obj_sentrygun", false) == 0)
					{
						pointvalue = GetConVarInt(obj_sentrygunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL1 = KW_SntryL1 + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "obj_sentrygun2", false) == 0)
					{
						pointvalue = GetConVarInt(obj_sentrygunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL2 = KW_SntryL2 + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "obj_sentrygun3", false) == 0)
					{
						pointvalue = GetConVarInt(obj_sentrygunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL3 = KW_SntryL3 + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "wrench", false) == 0)
					{
						pointvalue = GetConVarInt(wrenchpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Wrnc = KW_Wrnc + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "wrench_golden", false) == 0)
					{
						pointvalue = GetConVarInt(wrenchpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Wrnc = KW_Wrnc + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "pistol", false) == 0)
					{
						pointvalue = GetConVarInt(pistolpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Pistl = KW_Pistl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "fryingpan", false) == 0)
					{
						pointvalue = GetConVarInt(fryingpanpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_fryingpan = KW_fryingpan + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "robot_arm_combo_kill", false) == 0)
					{
						pointvalue = GetConVarInt(robot_arm_combo_killPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm_combo_kill = KW_robot_arm_combo_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "shotgun_primary", false) == 0)
					{
						pointvalue = GetConVarInt(shotgunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bonesaw", false) == 0)
					{
						pointvalue = GetConVarInt(bonesawpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bnsw = KW_Bnsw + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "syringegun_medic", false) == 0)
					{
						pointvalue = GetConVarInt(syringegun_medicpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ndl = KW_Ndl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "club", false) == 0)
					{
						pointvalue = GetConVarInt(clubpoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Mctte = KW_Mctte + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "smg", false) == 0)
					{
						pointvalue = GetConVarInt(smgpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Smg = KW_Smg + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "headtaker", false) == 0)
					{
						pointvalue = GetConVarInt(headtakerpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_headtaker = KW_headtaker + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "sniperrifle", false) == 0)
					{
						//Fixy for valve's stupidity
						new weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						if (weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 230)
						{
							//itza Sydney Sleeper!
							// Changed in one of the updates around 1/10
							pointvalue = GetConVarInt(sleeperpoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sleeperrifle = KW_sleeperrifle + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
						// /Fixy for valve's stupidity
						else
							{
							pointvalue = GetConVarInt(sniperriflepoints)
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Spr = KW_Spr + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
					}
					else if (strcmp(weapon[0], "sydney_sleeper", false) == 0)
					{
						pointvalue = GetConVarInt(sleeperpoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sleeperrifle = KW_sleeperrifle + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//Random insert of engi update shizz;
					else if (strcmp(weapon[0], "samrevolver", false) == 0)
					{
						pointvalue = GetConVarInt(samrevolverpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_samrevolver = KW_samrevolver + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "frontier_justice", false) == 0)
					{
						pointvalue = GetConVarInt(frontier_justicePoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_frontier_justice = KW_frontier_justice + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "wrangler_kill", false) == 0)
					{
						pointvalue = GetConVarInt(wrangler_killPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_wrangler_kill = KW_wrangler_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "robot_arm", false) == 0)
					{
						pointvalue = GetConVarInt(robot_armPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm = KW_robot_arm + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "maxgun", false) == 0)
					{
						pointvalue = GetConVarInt(maxgunPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_maxgun = KW_maxgun + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "southern_hospitality", false) == 0)
					{
						pointvalue = GetConVarInt(southern_hospitalityPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_southern_hospitality = KW_southern_hospitality + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bleed_kill", false) == 0)
					{
						pointvalue = GetConVarInt(bleed_killPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bleed_kill = KW_bleed_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "robot_arm_blender_kill", false) == 0)
					{
						pointvalue = GetConVarInt(robot_arm_blender_killPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm_blender_kill = KW_robot_arm_blender_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "taunt_guitar_kill", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_guitar_killPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_guitar_kill = KW_taunt_guitar_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//engi
					else if (strcmp(weapon[0], "revolver", false) == 0)
					{
						pointvalue = GetConVarInt(revolverpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Mgn = KW_Mgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "knife", false) == 0)
					{
						isknife = true
						pointvalue = GetConVarInt(knifepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Kn = KW_Kn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "ubersaw", false) == 0)
					{
						pointvalue = GetConVarInt(ubersawpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ubersaw = KW_Ubersaw + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					// Rift crap
					else if (strcmp(weapon[0], "lava_axe", false) == 0)
					{
						pointvalue = GetConVarInt(LavaAxePoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_lava_axe = KW_lava_axe + 1 WHERE STEAMID = '%s'", pointvalue, steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "lava_bat", false) == 0)
					{
						pointvalue = GetConVarInt(SunBatPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sun_bat = KW_sun_bat + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					// ---------
					else if (strcmp(weapon[0], "rocketlauncher_directhit", false) == 0)
					{
						pointvalue = GetConVarInt(rocketlauncher_directhitpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_rocketlauncher_directhit = KW_rocketlauncher_directhit + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------- Polycount 1 --------------------------------
					else if (strcmp(weapon[0], "short_stop", false) == 0)
					{
						pointvalue = GetConVarInt(short_stoppoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_short_stop = KW_short_stop + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "holy_mackerel", false) == 0)
					{
						pointvalue = GetConVarInt(holy_mackerelpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_holy_mackerel = KW_holy_mackerel + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "powerjack", false) == 0)
					{
						pointvalue = GetConVarInt(powerjackpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_powerjack = KW_powerjack + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "degreaser", false) == 0)
					{
						pointvalue = GetConVarInt(degreaserpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_degreaser = KW_degreaser + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "battleneedle", false) == 0)
					{
						pointvalue = GetConVarInt(battleneedlepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_battleneedle = KW_battleneedle + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "eternal_reward", false) == 0)
					{
						pointvalue = GetConVarInt(eternal_rewardpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_eternal_reward = KW_eternal_reward + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "letranger", false) == 0)
					{
						pointvalue = GetConVarInt(letrangerpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_letranger = KW_letranger + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//-------------------------------------------------------
					else if (strcmp(weapon[0], "telefrag", false) == 0)
					{
						pointvalue = GetConVarInt(telefragpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_telefrag = KW_telefrag + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "deflect_flare", false) == 0)
					{
						pointvalue = GetConVarInt(deflect_flarepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_flare = KW_deflect_flare + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "taunt_soldier", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_soldierpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_soldier = KW_taunt_soldier + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "goomba", false) == 0)
					{
						pointvalue = GetConVarInt(goombapoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_goomba = KW_goomba + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "iron_curtain", false) == 0)
					{
						pointvalue = GetConVarInt(ironcurtainpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_iron_curtain = KW_iron_curtain + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "pickaxe", false) == 0)
					{
						pointvalue = GetConVarInt(pickaxepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pickaxe = KW_pickaxe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "demoshield", false) == 0)
					{
						pointvalue = GetConVarInt(demoshieldpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_demoshield = KW_demoshield + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "claidheamohmor", false) == 0)
					{
						pointvalue = GetConVarInt(gaelicclaymorePoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_claidheamohmor = KW_claidheamohmor + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "sword", false) == 0)
					{
						new weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						if (weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 327)
						{
							// Claidheamh Mòr
							//Fixed in 1/10 update
							pointvalue = GetConVarInt(gaelicclaymorePoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_claidheamohmor = KW_claidheamohmor + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
						else
						{
							pointvalue = GetConVarInt(swordpoints)
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sword = KW_sword + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
					}
					else if (strcmp(weapon[0], "taunt_demoman", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_demomanpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_demoman = KW_taunt_demoman + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "sticky_resistance", false) == 0)
					{
						pointvalue = GetConVarInt(sticky_resistancepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sticky_resistance = KW_sticky_resistance + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "flaregun", false) == 0)
					{
						pointvalue = GetConVarInt(flaregunpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Flaregun = KW_Flaregun + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "axtinguisher", false) == 0)
					{
						pointvalue = GetConVarInt(axtinguisherpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Axtinguisher = KW_Axtinguisher + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "wrap_assassin", false) == 0)
					{
						pointvalue = GetConVarInt(WrapAssassin_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_wrap_assassin = KW_wrap_assassin + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "apocofists", false) == 0)
					{
						pointvalue = GetConVarInt(ApocoFists_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_apocofists = KW_apocofists + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "black_rose", false) == 0)
					{
						pointvalue = GetConVarInt(BlackRose_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_black_rose = KW_black_rose + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "taunt_pyro", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_pyropoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_pyro = KW_taunt_pyro + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "gloves_running_urgently", false) == 0)
					{
						pointvalue = GetConVarInt(urgentglovespoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_urgentgloves = KW_urgentgloves + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bread_bite", false) == 0)
					{
						pointvalue = GetConVarInt(bread_bite_points);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, bread_bite = bread_bite + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "gloves", false) == 0)
					{
						//Fixy for valve's stupidity
						new weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						if (weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 239)
						{
							//itza Gloves of Running Urgently!
							//Fixed around 1/10
							pointvalue = GetConVarInt(urgentglovespoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_urgentgloves = KW_urgentgloves + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
						// /Fixy for valve's stupidity
						else
						{
							pointvalue = GetConVarInt(glovespoints)
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_gloves = KW_gloves + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
					}
					else if (strcmp(weapon[0], "taunt_heavy", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_heavypoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_heavy = KW_taunt_heavy + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "backburner", false) == 0)
					{
						pointvalue = GetConVarInt(backburnerpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_backburner = KW_backburner + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "natascha", false) == 0)
					{
						new weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						if (weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 312)
						{
							// Brass Beast
							// Fixed in an update around 1/10
							pointvalue = GetConVarInt(BrassBeastPoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_brassbeast = KW_brassbeast + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
						else
						{
							pointvalue = GetConVarInt(nataschapoints)
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_natascha = KW_natascha + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
					}
					else if (strcmp(weapon[0], "brass_beast", false) == 0)
					{
						pointvalue = GetConVarInt(BrassBeastPoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_brassbeast = KW_brassbeast + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bushwacka", false) == 0)
					{
						pointvalue = GetConVarInt(bushwackapoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bushwacka = KW_bushwacka + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//Begin custom weapon update
					else if (strcmp(weapon[0], "tribalkukri", false) == 0)
					{
						//Fixy for valve's stupidity
						new weaponent = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
						if (weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 232)
						{
							//itza bushwacka!
							//Valve fixed this in 1/10 update
							pointvalue = GetConVarInt(bushwackapoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bushwacka = KW_bushwacka + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
						// /Fixy for valve's stupidity
						else
						{
							pointvalue = GetConVarInt(woodknifepoints)
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tribalkukri = KW_tribalkukri + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
							ExeQuery = true;
						}
					}
					else if (strcmp(weapon[0], "obj_minisentry", false) == 0)
					{
						pointvalue = GetConVarInt(MinisentryPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_minisentry = KW_minisentry + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "ullapool_caber_explosion", false) == 0)
					{
						pointvalue = GetConVarInt(UllaExplodePoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ullapool_caber_explosion = KW_ullapool_caber_explosion + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "battleaxe", false) == 0)
					{
						pointvalue = GetConVarInt(battleaxepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_battleaxe = KW_battleaxe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "ball", false) == 0)
					{
						pointvalue = GetConVarInt(ballpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ball = KW_ball + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "paintrain", false) == 0)
					{
						pointvalue = GetConVarInt(paintrainpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_paintrain = KW_paintrain + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "sledgehammer", false) == 0)
					{
						pointvalue = GetConVarInt(sledgehammerpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sledgehammer = KW_sledgehammer + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "unique_pickaxe", false) == 0)
					{
						pointvalue = GetConVarInt(uniquepickaxepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_unique_pickaxe = KW_unique_pickaxe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tf_pumpkin_bomb", false) == 0)
					{
						pointvalue = GetConVarInt(pumpkinpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pumpkin = KW_pumpkin + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//End custom weapon update
					else if (strcmp(weapon[0], "blutsauger", false) == 0)
					{
						pointvalue = GetConVarInt(blutsaugerpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_blutsauger = KW_blutsauger + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "deflect_rocket", false) == 0)
					{
						pointvalue = GetConVarInt(deflect_rocketpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_rocket = KW_deflect_rocket + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "deflect_promode", false) == 0)
					{
						pointvalue = GetConVarInt(deflect_promodepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_promode = KW_deflect_promode + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "deflect_sticky", false) == 0)
					{
						pointvalue = GetConVarInt(deflect_stickypoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_sticky = KW_deflect_sticky + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//-------------------- Christmas 2010 Update --------------------
					//Weapons with incorrect kill strings will be elsewhere
					else if (strcmp(weapon[0], "candy_cane", false) == 0)
					{
						pointvalue = GetConVarInt(candy_canePoints);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_candy_cane = KW_candy_cane + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "boston_basher", false) == 0)
					{
						pointvalue = GetConVarInt(boston_basherPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_boston_basher = KW_boston_basher + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "back_scratcher", false) == 0)
					{
						pointvalue = GetConVarInt(back_scratcherPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_back_scratcher = KW_back_scratcher + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "ullapool_caber", false) == 0)
					{
						pointvalue = GetConVarInt(ullapool_caberPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ullapool_caber = KW_ullapool_caber + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//else if (strcmp(weapon[0], "bear_claws", false) == 0)
					else if (strcmp(weapon[0], "warrior_spirit", false) == 0)
					{
						pointvalue = GetConVarInt(bear_clawsPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bearclaws = KW_bearclaws + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "steel_fists", false) == 0)
					{
						pointvalue = GetConVarInt(steel_fistsPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_steelfists = KW_steelfists + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "wrench_jag", false) == 0)
					{
						pointvalue = GetConVarInt(wrench_jagPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_wrench_jag = KW_wrench_jag + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "amputator", false) == 0)
					{
						pointvalue = GetConVarInt(amputatorPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_amputator = KW_amputator + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//else if (strcmp(weapon[0], "tf_projectile_healing_bolt", false) == 0) changed to crusaders_crossbow
					else if (strcmp(weapon[0], "crusaders_crossbow", false) == 0)
					{
						pointvalue = GetConVarInt(medicCrossbowPoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_healingcrossbow = KW_healingcrossbow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					//----------------------------------------------------------
					else if (strcmp(weapon[0], "world", false) == 0)
					{
						pointvalue = GetConVarInt(worldpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_world = KW_world + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "bat_wood", false) == 0)
					{
						pointvalue = GetConVarInt(bat_woodpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bat_wood = KW_bat_wood + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "tf_projectile_arrow", false) == 0)
					{
						pointvalue = GetConVarInt(tf_projectile_arrowpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tf_projectile_arrow = KW_tf_projectile_arrow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "ambassador", false) == 0)
					{
						pointvalue = GetConVarInt(ambassadorpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ambassador = KW_ambassador + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "taunt_sniper", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_sniperpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_sniper = KW_taunt_sniper + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "taunt_spy", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_spypoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_spy = KW_taunt_spy + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "force_a_nature", false) == 0)
					{
						pointvalue = GetConVarInt(force_a_naturepoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_force_a_nature = KW_force_a_nature + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "sandman", false) == 0)
					{
						pointvalue = GetConVarInt(sandmanpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sandman = KW_sandman + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "compound_bow", false) == 0)
					{
						pointvalue = GetConVarInt(compound_bowpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_compound_bow = KW_compound_bow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "taunt_scout", false) == 0)
					{
						pointvalue = GetConVarInt(taunt_scoutpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_scout = KW_taunt_scout + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "deflect_arrow", false) == 0)
					{
						pointvalue = GetConVarInt(deflect_arrowpoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_arrow = KW_deflect_arrow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "jar", false) == 0)
					{
						pointvalue = GetConVarInt(killasipoints)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_jar = KW_jar + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "saxxy", false) == 0)
					{
						pointvalue = GetConVarInt(Saxxy_Points)
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Saxxy = KW_Saxxy + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
						ExeQuery = true;
					}
					else if (strcmp(weapon[0], "player", false) == 0)
					{
						pointvalue = 0
					}
					else if (strcmp(weapon[0], "prop_physics", false) == 0)
					{
						pointvalue = 0
					}
					else if (strcmp(weapon[0], "builder", false) == 0)
					{
						pointvalue = 0
					}
					else if (strcmp(weapon[0], "pda_engineer_build", false) == 0)
					{
						pointvalue = 0
					}
					else if (strcmp(weapon[0], "trigger_hurt", false) == 0)
					{
						pointvalue = 0
					}
					else if (strcmp(weapon[0], "worldspawn", false) == 0)
					{
						pointvalue = 0
					}
					else
					{
						decl String:file[PLATFORM_MAX_PATH];
						BuildPath(Path_SM, file, sizeof(file), "logs/TF2STATS_WEAPONERRORS.log");
						LogToFile(file,"Weapon: %s", weapon)
					}
					
					if (ExeQuery){
						if (nofakekill == true && isbot == false){
							SQL_TQuery(db,SQLErrorCheckCallback, query);
						}
						ExeQuery = false;
					}
					
					new String:additional[MAX_LINE_WIDTH]
					new iBPN = 0;
					if (nofakekill == true && isbot == false)
					{
						sessionpoints[attacker] = sessionpoints[attacker] + pointvalue
						if (customkill == 2)
						{
							if (isknife)
							{
								Format(query, sizeof(query), "UPDATE Player SET K_backstab = K_backstab + 1 WHERE STEAMID = '%s'",steamIdattacker);
								Format(additional, sizeof(additional), "with a Backstab")
								if (isbot == false)
								{
									SQL_TQuery(db,SQLErrorCheckCallback, query);
								}
							}
						}
						else if (customkill == 1 || customkill == 51)
						{
							iBPN = GetConVarInt(headshotpoints);
							Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, HeadshotKill = HeadshotKill + 1 WHERE STEAMID = '%s'", iBPN, steamIdattacker);
							Format(additional, sizeof(additional), "with a Headshot")
							if (isbot == false)
							{
								SQL_TQuery(db,SQLErrorCheckCallback, query);
							}
						}
						else
						{
							Format(additional, sizeof(additional), "")
						}
					}
					if (pointmsgval >= 1)
					{
						new String:victimname[MAX_LINE_WIDTH];
						GetClientName(victim,victimname, sizeof(victimname))
						if(extendedloggingenabled && !sqllite)
						{
							new len = 0;
							decl String:buffer[2048];
							len += Format(buffer[len], sizeof(buffer)-len, "INSERT INTO `killlog` (`attacker` ,`victim` ,`assister` ,`weapon` ,`killtime` ,`dominated` ,`assister_dominated` ,`revenge` ,`assister_revenge`)");
							len += Format(buffer[len], sizeof(buffer)-len, " VALUES ('%s', '%s', '%s', '%s', '%i', '%i', '%i', '%i', '%i');",steamIdattacker,steamIdavictim,steamIdassister,weapon,GetTime(),df_killerdomination,df_assisterdomination,df_killerrevenge,df_assisterrevenge);
							SQL_TQuery(db,SQLErrorCheckCallback, buffer)
							PrintToConsole(attacker,"[DEBUG]   %s",buffer)
						}
						if (pointvalue + iBPN != 0)
						{
							if (pointmsgval == 1)
							{
								PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for killing %s %s",CHATTAG,attackername,pointvalue + iBPN,victimname,additional)
							}
							else
							{
								if (cookieshowrankchanges[attacker])
								{
									PrintToChat(attacker,"\x04[\x03%s\x04]\x01 you got %i points for killing %s %s",CHATTAG,pointvalue + iBPN,victimname,additional)
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new String:steamIdbuilder[MAX_LINE_WIDTH];
		new userId = GetEventInt(event, "userid")
		new user = GetClientOfUserId(userId)
		new objekt = GetEventInt(event, "object")
		GetClientAuthId(user, AuthId_Steam2, steamIdbuilder, sizeof(steamIdbuilder));
		new String:query[512];
		// Bot Check
		new bool:isbot;

		if (StrEqual(steamIdbuilder,"BOT"))
		{
			//Builder is a bot
			isbot = true;
			//PrintToChatAll("Builder is a BOT");
		}
		else
		{
			//Not a bot.
			isbot = false;
			//PrintToChatAll("Builder is not a BOT");
		}

		new bool:ShouldIgnoreBots = GetConVarBool(ignorebots);

		if (ShouldIgnoreBots == false)
		{
			isbot = false;
		}

		if (objekt == 0)
		{
			Format(query, sizeof(query), "UPDATE Player SET BuildDispenser = BuildDispenser + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (objekt == 1)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOTeleporterentrace = BOTeleporterentrace + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (objekt == 1)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOTeleporterExit = BOTeleporterExit + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (objekt == 2)
		{
			Format(query, sizeof(query), "UPDATE Player SET BuildSentrygun = BuildSentrygun + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (objekt == 3)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOSapper = BOSapper + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
	}
}

public Action:Event_object_destroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		//test
		new playerid = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (GetEventInt(event, "userid") != GetEventInt(event, "attacker") && playerid != 0 && !IsFakeClient(playerid))
		{
			//Attacker
			new userId = GetEventInt(event, "attacker");
			new objekt = GetEventInt(event, "objecttype");
			new user = GetClientOfUserId(userId);
			new String:steamIdattacker[MAX_LINE_WIDTH];
			GetClientAuthId(user, AuthId_Steam2, steamIdattacker, sizeof(steamIdattacker));
			new String:query[512];
			new pointvalue = 0;
			// Bot Check
			new bool:isbot;

			if (StrEqual(steamIdattacker,"BOT"))
			{
				//Attacker is a bot
				isbot = true;
				//PrintToChatAll("Attacker is a BOT");
			}
			else
			{
				//Not a bot.
				isbot = false;
				//PrintToChatAll("Attacker is not a BOT");
			}

			new bool:ShouldIgnoreBots = GetConVarBool(ignorebots);

			if (ShouldIgnoreBots == false)
			{
				isbot = false;
			}

			if (objekt == 0)
			{
				pointvalue = GetConVarInt(killdisppoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KODispenser = KODispenser + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (objekt == 1)
			{
				pointvalue = GetConVarInt(killteleinpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOTeleporterEntrace = KOTeleporterEntrace + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (objekt == 1)
			{
				pointvalue = GetConVarInt(killteleoutpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOTeleporterExit = KOTeleporterExit + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (objekt == 2)
			{
				pointvalue = GetConVarInt(killsentrypoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOSentrygun = KOSentrygun + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (objekt == 3)
			{
				pointvalue = GetConVarInt(killsapperpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOSapper = KOSapper + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}

			sessionpoints[user] = sessionpoints[user] + pointvalue
			new pointmsgval = GetConVarInt(pointmsg)

			if (pointmsgval >= 1)
			{
				new String:username[MAX_LINE_WIDTH];
				GetClientName(user,username, sizeof(username))

				if (pointmsgval == 1)
				{
					PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for destroying object",CHATTAG,username,pointvalue)
				}
				else
				{
					if (cookieshowrankchanges[user])
					{
						PrintToChat(user,"\x04[\x03%s\x04]\x01 you got %i points for destroying object",CHATTAG,pointvalue)
					}
				}
			}
		}
	}
}

//public Action:Command_Say(Handle:event, const String:name[], bool:dontBroadcast)
public Action:Command_Say(client, args)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0){
		return Plugin_Continue;
	}
	
	if (!IsClientInGame(client)){
		return Plugin_Continue;
	}
	
	new String:text[512];
	new bool:chatcommand = false;

	//GetEventString(event, "text", text, sizeof(text));
	GetCmdArg(1, text, sizeof(text));

	if (StrEqual(text, "!Rank", false) || StrEqual(text, "Rank", false) || StrEqual(text, "Place", false) || StrEqual(text, "Points", false) || StrEqual(text, "Stats", false))
	{
		new iTime =  GetTime();
		new iElapsed = iTime - g_iLastRankCheck[client];
		new iDelayNeeded = GetConVarInt(v_RankCheckTimeout);
		if (iElapsed < iDelayNeeded)
		{
			new Float:fTimeLeft = float(iDelayNeeded - iElapsed);
			if (fTimeLeft > 60.0)
			{
				fTimeLeft = fTimeLeft/60;
				PrintToChat(client, "\x04[\x03%s\x04]:\x01 Sorry, please wait another \x05%-.2f minutes\x01 before checking your rank!", CHATTAG, fTimeLeft);
			}
			else
				PrintToChat(client, "\x04[\x03%s\x04]:\x01 Sorry, please wait another \x05%i seconds\x01 before checking your rank!", CHATTAG, RoundToFloor(fTimeLeft));
			return Plugin_Handled;
		}
		g_iLastRankCheck[client] = iTime;

		new String:steamId[MAX_LINE_WIDTH]
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		rankpanel(client, steamId)
		chatcommand = true;
	}
	//---------Kill-Death-------
	else if (StrEqual(text, "kdeath", false) || StrEqual(text, "!kdeath", false) || StrEqual(text, "kdr", false) || StrEqual(text, "!kdr", false) || StrEqual(text, "kd", false) || StrEqual(text, "killdeath", false))
	{
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
	else if (StrEqual(text, "kdscout", false) || StrEqual(text, "!kdscout", false))
	{
		Echo_KillDeathClass(client, 1);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdsoldier", false) || StrEqual(text, "!kdsoldier", false))
	{
		Echo_KillDeathClass(client, 2);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdsolly", false) || StrEqual(text, "!kdsolly", false))
	{
		Echo_KillDeathClass(client, 2);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdpyro", false) || StrEqual(text, "!kdpyro", false))
	{
		Echo_KillDeathClass(client, 3);
		chatcommand = true;
	}
	else if (StrEqual(text, "kddemo", false) || StrEqual(text, "!kddemo", false) || StrEqual(text, "kddemoman", false) || StrEqual(text, "kdemo", false))
	{
		Echo_KillDeathClass(client, 4);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdheavy", false) || StrEqual(text, "!kdheavy", false))
	{
		Echo_KillDeathClass(client, 5);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdengi", false) || StrEqual(text, "!kdengi", false))
	{
		Echo_KillDeathClass(client, 6);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdengineer", false) || StrEqual(text, "!kdengineer", false))
	{
		Echo_KillDeathClass(client, 6);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdmedic", false) || StrEqual(text, "!kdmedic", false))
	{
		Echo_KillDeathClass(client, 7);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdsniper", false) || StrEqual(text, "!kdsniper", false))
	{
		Echo_KillDeathClass(client, 8);
		chatcommand = true;
	}
	else if (StrEqual(text, "kdspy", false) || StrEqual(text, "!kdspy", false))
	{
		Echo_KillDeathClass(client, 9);
		chatcommand = true;
	}
	else if (StrEqual(text, "lifetimeheals", false) || StrEqual(text, "!lifetimeheals", false))
	{
		Echo_LifetimeHealz(client);
		chatcommand = true;
	}
	//------------------------------------
	else if (StrEqual(text, "Top10", false) || StrEqual(text, "Top", false) || StrEqual(text, "!Top10", false))
	{
		top10pnl(client);
		chatcommand = true;
	}
	else if (StrEqual(text, "rankinfo", false))
	{
		rankinfo(client);
		chatcommand = true;
	}
	else if (StrEqual(text, "players", false))
	{
		listplayers(client);
		chatcommand = true;
	}
	else if (StrEqual(text, "session", false))
	{
		session(client);
		chatcommand = true;
	}
	else if (StrEqual(text, "webtop", false))
	{
		webtop(client);
		chatcommand = true;
	}
	else if (StrEqual(text, "webrank", false))
	{
		webranking(client);
		chatcommand = true;
	}
	else if (StrEqual(text, "hidepoints", false))
	{
		sayhidepoints(client);
		chatcommand = true;
	}
	else if (StrEqual(text, "unhidepoints", false))
	{
		sayunhidepoints(client);
		chatcommand = true;
	}

	if (!chatcommand || showchatcommands)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action:rankinfo(client)
{
	new Handle:infopanel = CreatePanel();
	SetPanelTitle(infopanel, "About TF2 Stats:")
	DrawPanelText(infopanel, "Plugin Coded by DarthNinja")
	//DrawPanelText(infopanel, "Based on code by R-Hehl")
	DrawPanelText(infopanel, "Visit AlliedModders.net or DarthNinja.com")
	DrawPanelText(infopanel, "For the latest version of TF2 Stats!")
	DrawPanelText(infopanel, "Contact DarthNinja for Feature Requests or Bug reports")
	new String:value[128];
	new String:tmpdbtype[10]

	if (sqllite)
		Format(tmpdbtype, sizeof(tmpdbtype), "SQLITE");
	else
		Format(tmpdbtype, sizeof(tmpdbtype), "MYSQL");
	Format(value, sizeof(value), "Version %s Database Type %s",PLUGIN_VERSION ,tmpdbtype);
	DrawPanelText(infopanel, value)
	DrawPanelItem(infopanel, "Close")
	SendPanelToClient(infopanel, client, InfoPanelHandler, 20)
	CloseHandle(infopanel)
	return Plugin_Handled
}

public InfoPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) { }
	else if (action == MenuAction_Cancel) { }
}

public Action:resetshow2alltimer(Handle:timer)
{
	resetshow2all()
}

public resetshow2all()
{
	SetConVarBool(showranktoall,oldshowranktoallvalue,false,false)
}

public Action:Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_IsRoundActive = false
	//It's now round-end!
	if (GetConVarInt(showrankonroundend) == 1)
	{
		oldshowranktoallvalue = GetConVarBool(showranktoall)
		SetConVarBool(showranktoall,false,false,false)
		showallrank()
		CreateTimer(5.0, resetshow2alltimer)
	}

	if (GetConVarInt(removeoldplayers) == 1)
	{
		removetooldplayers()
	}

	if (!sqllite)
	{
		if (extendedloggingenabled)
			removeoldkilllogentrys();

		if (GetConVarInt(removeoldmaps) == 1)
			removetooldmaps();
	}

	if (GetConVarInt(disableafterwin) == 1)
	{
		rankingactive = false;

		if (rankingenabled && GetConVarBool(ShowRoundEnableNotice))
			PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Disabled: round end",CHATTAG)
	}
}

public Action:Event_teamplay_round_active(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_IsRoundActive = true
	if (GetConVarInt(disableafterwin) == 1)
	{
		if (GetConVarInt(neededplayercount) <= GetClientCount(true))
		{
			rankingactive = true;
			if (rankingenabled && GetConVarBool(ShowRoundEnableNotice))
				PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Enabled: round start", CHATTAG);
		}
	}
}

public showallrank()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			new String:steamIdclient[MAX_LINE_WIDTH];
			GetClientAuthId(i, AuthId_Steam2, steamIdclient, sizeof(steamIdclient));
			rankpanel(i, steamIdclient)
		}
	}
}

public removetooldplayers()
{
	new remdays = GetConVarInt(removeoldplayersdays)
	if (remdays >= 1)
	{
		new timesec = GetTime() - (remdays * 86400)
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM Player WHERE LASTONTIME < '%i'",timesec);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}
}

public removeoldkilllogentrys()
{
	new remhours = GetConVarInt(CV_extlogcleanuptime)

	if (remhours >= 1)
	{
		new timesec = GetTime() - (remhours * 3600)
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM killlog WHERE killtime < '%i'",timesec);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}
}

public Event_point_captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled && cpmap)
	{
		new iTeam = GetEventInt(event, "team");
		new String:teamname[MAX_LINE_WIDTH];
		GetTeamName(iTeam,teamname, sizeof(teamname));
		new pointmsgval = GetConVarInt(pointmsg);
		new pointvalue = GetConVarInt(Capturepoints)
		if (pointvalue != 0)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == iTeam)
				{
					if (IsFakeClient(i) && GetConVarBool(ignorebots))
						break;

					new String:SteamID[MAX_LINE_WIDTH];
					GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
					new String:query[512];

					//Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, CPCaptured = CPCaptured + 1 WHERE STEAMID = '%s'",pointvalue ,SteamID);
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", pointvalue, SteamID);
					SQL_TQuery(db,SQLErrorCheckCallback, query);

					sessionpoints[i] = sessionpoints[i] + pointvalue;
					if (pointmsgval >= 1 && cookieshowrankchanges[i])
						PrintToChat(i,"\x04[\x03%s\x04]\x01 %s Team got %i points for capturing a point!", CHATTAG, teamname, pointvalue)
				}
			}
		}
		new iPoints = GetConVarInt(CPCapPlayerPoints);
		if (iPoints != 0)
		{
			decl String:CappedBy[MAXPLAYERS+1] = "";
			GetEventString(event,"cappers", CappedBy, MAXPLAYERS)
			new x = strlen(CappedBy);
			//PrintToChatAll("Point capped by %i total players!", x);

			for(new i=0;i<x;i++)
			{
				new client = CappedBy{i};
				if (IsFakeClient(client) && GetConVarBool(ignorebots))
					break;

				new String:SteamID[MAX_LINE_WIDTH];
				GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
				new String:query[512];
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, CPCaptured = CPCaptured + 1 WHERE STEAMID = '%s'", iPoints, SteamID);
				SQL_TQuery(db,SQLErrorCheckCallback, query);
				if (pointmsgval >= 1 && cookieshowrankchanges[i])
					PrintToChat(client, "\x04[\x03%s\x04]\x01 You got %i points for capturing a point!", CHATTAG, iPoints);
			}
		}
	}
}

//public Event_flag_captured(Handle:event, const String:name[], bool:dontBroadcast)
public FlagEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled && GetEventInt(event, "eventtype") == FlagCaptured)
	{
		new client = GetEventInt(event, "player");
		new iCappingTeam = GetClientTeam(client);

		new pointmsgval = GetConVarInt(pointmsg);
		new iTeamPointValue = GetConVarInt(FileCapturepoints);
		new iPlayerPointValue = GetConVarInt(CTFCapPlayerPoints);

		if (iTeamPointValue != 0)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (!IsClientInGame(i))
					break;
				if (GetClientTeam(i) != iCappingTeam)
					break;
				if (IsFakeClient(i) && GetConVarBool(ignorebots))
					break;

				new String:SteamID[MAX_LINE_WIDTH];
				GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
				new String:query[512];
				//Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, FileCaptured = FileCaptured + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", iTeamPointValue, SteamID);
				SQL_TQuery(db,SQLErrorCheckCallback, query);

				sessionpoints[i] = sessionpoints[i] + iTeamPointValue;

				if (pointmsgval >= 1 && cookieshowrankchanges[i])
				{
					new String:teamname[MAX_LINE_WIDTH];
					GetTeamName(iCappingTeam, teamname, sizeof(teamname));
					PrintToChat(i,"\x04[\x03%s\x04]\x01 %s Team got %i points for capturing the intel!", CHATTAG, teamname, iTeamPointValue)
				}
			}
		}
		//solo points here
		if (iPlayerPointValue != 0)
		{
			sessionpoints[client] = sessionpoints[client] + iPlayerPointValue;
			if (IsFakeClient(client) && GetConVarBool(ignorebots))
				return;

			new String:SteamID[MAX_LINE_WIDTH];
			GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
			new String:query[512];
			Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, FileCaptured = FileCaptured + 1 WHERE STEAMID = '%s'", iPlayerPointValue, SteamID);
			SQL_TQuery(db,SQLErrorCheckCallback, query);

			if (pointmsgval >= 1 && cookieshowrankchanges[client])
			{
				PrintToChat(client, "\x04[\x03%s\x04]\x01 You got %i points for capturing the intel!", CHATTAG, iPlayerPointValue);
			}
		}
	}
	return;
}

public Event_capture_blocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled && cpmap)
	{
		new client = GetEventInt(event, "blocker");
		if (client > 0)
		{
			if (IsFakeClient(client) && GetConVarBool(ignorebots))
				return;

			new pointvalue = GetConVarInt(Captureblockpoints);
			if (pointvalue != 0)
			{
				new String:SteamID[MAX_LINE_WIDTH];
				GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
				new String:query[512];
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, CPBlocked = CPBlocked + 1 WHERE STEAMID = '%s'", pointvalue, SteamID);
				SQL_TQuery(db,SQLErrorCheckCallback, query);

				sessionpoints[client] = sessionpoints[client] + pointvalue;

				new pointmsgval = GetConVarInt(pointmsg);
				if (pointmsgval >= 1)
				{
					new String:playername[MAX_LINE_WIDTH];
					GetClientName(client,playername, sizeof(playername))

					if (pointmsgval == 1)
					{
						PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for Blocking a Capture", CHATTAG, playername, pointvalue)
					}
					else if (cookieshowrankchanges[client])
					{
						PrintToChat(client, "\x04[\x03%s\x04]\x01 you got %i points for Blocking a Capture", CHATTAG, pointvalue)
					}
				}
			}
		}
	}
}

public Action:DelayOnMapStart(Handle:timer)
{
	OnMapStart();
}

public OnMapStart()
{
	// If the plugin is late loaded, OnMapStart will be called before the database connects
	// Here we will check to see if there is a connection, and if not retry in 10 seconds
	if (db == INVALID_HANDLE)
	{
		CreateTimer(10.0, DelayOnMapStart);
		return;
	}
		
	if (GetConVarInt(ConnectSound) == 1)
	{
		new String:SoundFile[128]
		GetConVarString(ConnectSoundFile, SoundFile, sizeof(SoundFile))

		if (!StrEqual(SoundFile, "")) //Added safety
		{
			PrecacheSound(SoundFile);
			decl String:SoundFileLong[192];
			Format(SoundFileLong, sizeof(SoundFileLong), "sound/%s", SoundFile);
			AddFileToDownloadsTable(SoundFileLong);
		}
	}

	if (GetConVarInt(ConnectSoundTop10) == 1)
	{
		new String:SoundFile2[128]
		GetConVarString(ConnectSoundFileTop10, SoundFile2, sizeof(SoundFile2))

		if (!StrEqual(SoundFile2, "")) //Added safety
		{
			PrecacheSound(SoundFile2);
			decl String:SoundFileLong2[192];
			Format(SoundFileLong2, sizeof(SoundFileLong2), "sound/%s", SoundFile2);
			AddFileToDownloadsTable(SoundFileLong2);
		}
	}

	MapInit()
	new String:name[MAX_LINE_WIDTH];
	GetCurrentMap(name,MAX_LINE_WIDTH);

	if (StrContains(name, "cp_", false) != -1)
	{
		cpmap = true
	}
	else if (StrContains(name, "tc_", false) != -1)
	{
		cpmap = true
	}
	else if (StrContains(name, "pl_", false) != -1)
	{
		cpmap = true
	}
	else if (StrContains(name, "plr_", false) != -1)
	{
		cpmap = true
	}
	else if (StrContains(name, "arena_", false) != -1)
	{
		cpmap = true
	}
	else
	{
		cpmap = false
	}
}

public OnMapEnd()
{
	mapisset = 0
	resetshow2all()
}

public MapInit()
{
	if (mapisset == 0)
	{
		InitializeMaponDB()

		if (classfunctionloaded == 0)
		{
			maxplayers = GetMaxClients();
			maxents = GetMaxEntities();
			ResourceEnt = FindResourceObject();

			if (ResourceEnt == -1)
			{
				LogMessage("Achtung! Server could not find player data table");
				classfunctionloaded = 1
			}
		}
	}
}

public InitializeMaponDB()
{
	if (mapisset == 0)
	{
		if (!sqllite)
		{
			new String:name[MAX_LINE_WIDTH];
			GetCurrentMap(name,MAX_LINE_WIDTH);

			new String:query[512];
			Format(query, sizeof(query), "INSERT IGNORE INTO Map (`NAME`) VALUES ('%s')", name)
			SQL_TQuery(db,SQLErrorCheckCallback, query);

			mapisset = 1
		}
	}
}


stock FindResourceObject()
{
	new i, String:classname[64];

	//Isn't there a easier way?
	//FindResourceObject does not work

	for (i = maxplayers; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityNetClass(i, classname, 64);

			if (StrEqual(classname, "CTFPlayerResource"))
			{
				//LogMessage("Found CTFPlayerResource at %d", i)
				return i;
			}
		}
	}
	return -1;
}

public removetooldmaps()
{
	new remdays = GetConVarInt(removeoldmapssdays)

	if (remdays >= 1)
	{
		new timesec = GetTime() - (remdays * 86400)
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM Map WHERE LASTONTIME < '%i'",timesec);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}
}

public updateplayername(client)
{
	// !NAME!
	new String:steamId[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	new String:name[MAX_LINE_WIDTH];
	GetClientName( client, name, sizeof(name) );
	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), "<?", "");
	ReplaceString(name, sizeof(name), "?>", "");
	ReplaceString(name, sizeof(name), "`", "");
	ReplaceString(name, sizeof(name), ",", "");
	ReplaceString(name, sizeof(name), "<?PHP", "");
	ReplaceString(name, sizeof(name), "<?php", "");
	ReplaceString(name, sizeof(name), "<", "[");
	ReplaceString(name, sizeof(name), ">", "]");
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET NAME = '%s' WHERE STEAMID = '%s'", name, steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query);
	new String:ip[20]
	GetClientIP(client,ip,sizeof(ip),true)
	new String:ClientSteamID[MAX_LINE_WIDTH];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));

	if (!sqllite)
	{
		if (GetConVarBool(logips))
		{
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "UPDATE Player SET IPAddress = '%s' WHERE STEAMID = '%s'", ip, ClientSteamID);
			SQL_TQuery(db,SQLErrorCheckCallback, buffer)
		}
	}
}

public initonlineplayers()
{
	new l_maxplayers
	l_maxplayers = GetMaxClients()
	for (new i=1; i<=l_maxplayers; i++)
	{
		if (IsClientInGame(i))
		{
			updateplayername(i)
			InitializeClientonDB(i)
		}
	}
}


public Action:Rank_GivePoints(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: rank_givepoints <Player> <Value to Add>");
		return Plugin_Handled;
	}

	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));

	if ((target_count = ProcessTargetString(
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
	new iPointsAdd = StringToInt(buffer);
	new String:query[512];
	new String:TargetSteamID[MAX_LINE_WIDTH];

	for (new i = 0; i < target_count; i ++)
	{
		GetClientAuthId(target_list[i], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
		Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", iPointsAdd, TargetSteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}

	ReplyToCommand(client, "\x04[\x03%s\x04]\x01: Gave \x04%s\x01 \x05%i\x01 points!", CHATTAG, target_name, iPointsAdd);
	return Plugin_Handled
}

public Action:Rank_RemovePoints(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: rank_removepoints <Player> <Value to Remove>");
		return Plugin_Handled;
	}

	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));

	if ((target_count = ProcessTargetString(
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
	new iPointsRemove = StringToInt(buffer);
	new String:query[512];
	new String:TargetSteamID[MAX_LINE_WIDTH];

	for (new i = 0; i < target_count; i ++)
	{
		GetClientAuthId(target_list[i], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
		Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS - %i WHERE STEAMID = '%s'", iPointsRemove, TargetSteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}

	ReplyToCommand(client, "\x04[\x03%s\x04]\x01: Removed \x05%i\x01 points from \x04%s's\x01 ranking!", CHATTAG, iPointsRemove, target_name);
	return Plugin_Handled
}

public Action:Rank_SetPoints(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: rank_setpoints <Player> <New Value>");
		return Plugin_Handled;
	}

	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));

	if ((target_count = ProcessTargetString(
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
	new iPointsNew = StringToInt(buffer);
	new String:query[512];
	new String:TargetSteamID[MAX_LINE_WIDTH];

	for (new i = 0; i < target_count; i ++)
	{
		GetClientAuthId(target_list[i], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));
		Format(query, sizeof(query), "UPDATE Player SET POINTS = %i WHERE STEAMID = '%s'", iPointsNew, TargetSteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}

	ReplyToCommand(client, "\x04[\x03%s\x04]\x01: Set \x04%s's\x01 Ranking points to \x05%i\x01!", CHATTAG, target_name, iPointsNew);
	return Plugin_Handled
}


public Action:Rank_ResetCTFCaps(client, args)
{
	new String:query[512];
	Format(query, sizeof(query), "UPDATE `Player` SET `FileCaptured` = '0' WHERE `FileCaptured` != '0' ;");
	SQL_TQuery(db,SQLErrorCheckCallback, query);

	ReplyToCommand(client, "All FileCaptured records have been reset to 0.");
	return Plugin_Handled
}

public Action:Rank_ResetCPCaps(client, args)
{
	new String:query[512];
	Format(query, sizeof(query), "UPDATE `Player` SET `CPCaptured` = '0' WHERE `CPCaptured` != '0' ;");
	SQL_TQuery(db,SQLErrorCheckCallback, query);

	ReplyToCommand(client, "All CPCaptured records have been reset to 0.");
	return Plugin_Handled
}


public Action:Menu_RankAdmin(client, args)
{
	new Handle:menu = CreateMenu(MenuHandlerRankAdmin);
	SetMenuTitle(menu, "Rank Admin Menu");
	//AddMenuItem(menu, "reset", "Reset TF2 Stats Database");  I think this is a bad idea...
	AddMenuItem(menu, "reload", "Reload TF2 Stats Plugin");
	AddMenuItem(menu, "givepoints", "Give Points");
	AddMenuItem(menu, "removepoints", "Remove Points");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return Plugin_Handled
}

/*
###################################
##		  Rank Admin Main		 ##
###################################
*/
public MenuHandlerRankAdmin(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_Select)
	{
		new String:sSelection[64];
		GetMenuItem(menu, args, sSelection, sizeof(sSelection));

		if(StrEqual ("reset", sSelection))
		{
			//resetdb()
			PrintToChat(client, "This command has been disabled for safety!  \n Edit 'MenuHandlerRankAdmin' to enable.");
		}
		else if(StrEqual ("reload", sSelection))
		{
			new String:FileName[64];
			GetPluginFilename(INVALID_HANDLE, FileName, sizeof(FileName));
			PrintToChat(client, "\x04[\x03%s\x04]\x01: Reloading plugin file %s", CHATTAG, FileName);
			ServerCommand("sm plugins reload %s", FileName);
		}
		else if(StrEqual ("givepoints", sSelection))
		{
			//PrintToChat(client, "givepoints selected");

			new Handle:menuNext = CreateMenu(MenuHandler_GivePoints);

			SetMenuTitle(menuNext, "Select Client:");
			SetMenuExitBackButton(menu, true);

			AddTargetsToMenu2(menuNext, client, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED);

			DisplayMenu(menuNext, client, MENU_TIME_FOREVER);
		}
		else if(StrEqual ("removepoints", sSelection))
		{
			new Handle:menuNext = CreateMenu(MenuHandler_RemovePoints);

			SetMenuTitle(menuNext, "Select Client:");
			SetMenuExitBackButton(menu, true);

			AddTargetsToMenu2(menuNext, client, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED);

			DisplayMenu(menuNext, client, MENU_TIME_FOREVER);
		}
	}

	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/*
###################################
##		  Add Points Menu		 ##
###################################
*/

public MenuHandler_GivePoints(Handle:menu, MenuAction:action, client, args)
{
	//PrintToChat(client, "player selected");
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}

	else if (action == MenuAction_Select)
	{
		decl String:strTarget[32];
		new userid, target;

		GetMenuItem(menu, args, strTarget, sizeof(strTarget));
		userid = StringToInt(strTarget);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(client, "[SM] That player is no longer available");
		}
		else
		{
			g_iMenuTarget[client] = target;

			new Handle:menuNext = CreateMenu(MenuHandler_GivePointsHandler);
			SetMenuTitle(menuNext, "Points to Add:");

			AddMenuItem(menuNext, "1", "1 Point");
			AddMenuItem(menuNext, "5", "5 Points");
			AddMenuItem(menuNext, "10", "10 Points");
			AddMenuItem(menuNext, "25", "25 Points");
			AddMenuItem(menuNext, "50", "50 Points");
			AddMenuItem(menuNext, "100", "100 Points");
			AddMenuItem(menuNext, "250", "250 Points");
			AddMenuItem(menuNext, "500", "500 Points");
			AddMenuItem(menuNext, "1000", "1000 Points");
			AddMenuItem(menuNext, "2500", "2500 Points");
			AddMenuItem(menuNext, "5000", "5000 Points");
			AddMenuItem(menuNext, "1000000", "ONE MILLION POINTS #Trololo");


			SetMenuExitButton(menuNext, true);
			DisplayMenu(menuNext, client, MENU_TIME_FOREVER);
		}

	}

}


public MenuHandler_GivePointsHandler(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:strPoints[32];
		GetMenuItem(menu, args, strPoints, sizeof(strPoints));
		//PrintToChat(client, "Selection %s", strPoints);

		//------------------

		new bonuspointvalue = StringToInt(strPoints);
		new String:query[512];
		new String:TargetSteamID[MAX_LINE_WIDTH];
		GetClientAuthId(g_iMenuTarget[client], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));


		//ShowActivity2(client, "\x04[\x03%s\x04]\x01 ","Increased \x04%N's\x01 ranking by awarding them \x05%i\x01 points!", CHATTAG, g_iMenuTarget[client], bonuspointvalue);
		//PrintToChat(g_iMenuTarget[client], "\x04[\x03%s\x04]\x01: \x04%N\x01 increased your ranking by giving you \x05%i\x01 bonus points!", CHATTAG, client, bonuspointvalue);

		PrintToChatAll("\x04[\x03%s\x04]\x01: \x04%N\x01 Increased \x04%N's\x01 ranking by awarding them \x05%i\x01 points!", CHATTAG, client, g_iMenuTarget[client], bonuspointvalue);

		Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", bonuspointvalue, TargetSteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}
}

/*
###################################
##		 Remove Points Menu		 ##
###################################
*/

public MenuHandler_RemovePoints(Handle:menu, MenuAction:action, client, args)
{
	//PrintToChat(client, "player selected");
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}

	else if (action == MenuAction_Select)
	{
		decl String:strTarget[32];
		new userid, target;

		GetMenuItem(menu, args, strTarget, sizeof(strTarget));
		userid = StringToInt(strTarget);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(client, "[SM] That player is no longer available");
		}
		else
		{
			g_iMenuTarget[client] = target;

			new Handle:menuNext = CreateMenu(MenuHandler_RemovePointsHandler);
			SetMenuTitle(menuNext, "Points to Remove:");

			AddMenuItem(menuNext, "1", "1 Point");
			AddMenuItem(menuNext, "5", "5 Points");
			AddMenuItem(menuNext, "10", "10 Points");
			AddMenuItem(menuNext, "25", "25 Points");
			AddMenuItem(menuNext, "50", "50 Points");
			AddMenuItem(menuNext, "100", "100 Points");
			AddMenuItem(menuNext, "250", "250 Points");
			AddMenuItem(menuNext, "500", "500 Points");
			AddMenuItem(menuNext, "1000", "1000 Points");
			AddMenuItem(menuNext, "2500", "2500 Points");
			AddMenuItem(menuNext, "5000", "5000 Points");
			AddMenuItem(menuNext, "1000000", "ONE MILLION POINTS #Trololo");


			SetMenuExitButton(menuNext, true);
			DisplayMenu(menuNext, client, MENU_TIME_FOREVER);
		}

	}

}


public MenuHandler_RemovePointsHandler(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:strPoints[32];
		GetMenuItem(menu, args, strPoints, sizeof(strPoints));
		//PrintToChat(client, "Selection %s", strPoints);

		//------------------

		new bonuspointvalue = StringToInt(strPoints);
		new String:query[512];
		new String:TargetSteamID[MAX_LINE_WIDTH];
		GetClientAuthId(g_iMenuTarget[client], AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));


		PrintToChatAll("\x04[\x03%s\x04]\x01: \x04%N\x01 Decreased \x04%N's\x01 ranking by removing \x05%i\x01 points from their ranking!", CHATTAG, client, g_iMenuTarget[client], bonuspointvalue);

		Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS - %i WHERE STEAMID = '%s'", bonuspointvalue, TargetSteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}
}


public resetdb()
{
	new String:query[512];
	Format(query, sizeof(query), "TRUNCATE TABLE Player");
	SQL_TQuery(db,SQLErrorCheckCallback, query);

	if (!sqllite)
	{
		Format(query, sizeof(query), "TRUNCATE TABLE Map");
		SQL_TQuery(db,SQLErrorCheckCallback, query);
	}

	initonlineplayers()
}

public listplayers(client)
{
	Menu_playerlist(client)
}

public Action:Menu_playerlist(client)
{
	new Handle:menu = CreateMenu(MenuHandlerplayerslist)
	SetMenuTitle(menu, "Online Players:")
	new maxClients = GetMaxClients();

	for (new i=1; i<=maxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		new String:name[65];
		GetClientName(i, name, sizeof(name));
		new String:steamId[MAX_LINE_WIDTH];
		GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
		AddMenuItem(menu, steamId, name)
	}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandlerplayerslist(Handle:menu, MenuAction:action, param1, param2)
{
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))
		rankpanel(param1, info)
	}

	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* New Code Full Threaded SQL Clean Code ---------------------------------------*/
public OnClientPostAdminCheck(client)
{
	if (db == INVALID_HANDLE){
		return;
	}

	InitializeClientonDB(client);

	if (GetConVarInt(ConnectSound) == 1)
	{
		new String:soundfile[MAX_LINE_WIDTH]
		GetConVarString(ConnectSoundFile,soundfile,sizeof(soundfile))
		EmitSoundToAll(soundfile);
	}

	sessionpoints[client] = 0
	sessionkills[client] = 0
	sessiondeath[client] = 0
	sessionassi[client] = 0
	overchargescoring[client] = true
	loadclientsettings(client)

	if (!rankingactive)
	{
		if (GetConVarInt(neededplayercount) <= GetClientCount(true))
		{
			if (g_IsRoundActive)
			{
				rankingactive = true
				if (GetConVarBool(ShowEnoughPlayersNotice))
					PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Enabled: enough players", CHATTAG)
			}
		}
	}
}

public InitializeClientonDB(client)
{
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:buffer[255];

	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT POINTS FROM Player WHERE STEAMID = '%s'", ConUsrSteamID);
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_CheckConnectingUsr, buffer, conuserid)
}

public loadclientsettings(client)
{
	/* delaying the check to make sure the client is added correct before loading the settings */
	cookieshowrankchanges[client] = false
	CheckCookieTimers[client] = CreateTimer(5.0, CheckMSGCookie, client)
}

public Action:CheckMSGCookie(Handle:timer, any:client)
{
	PrintToConsole(client, "[RANKDEBUG] Loading Client Settings ...")
	CheckCookieTimers[client] = INVALID_HANDLE
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:buffer[255];
	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT chat_status FROM Player WHERE STEAMID = '%s'", ConUsrSteamID);
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_LoadUsrSettings1, buffer, conuserid)
}

public T_LoadUsrSettings1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 1! %s", error);
	}
	else
	{
		new chat_status = 0

		while (SQL_FetchRow(hndl))
		{
			chat_status = SQL_FetchInt(hndl,0)
		}

		switch (chat_status)
		{
			case 2:
			{
				cookieshowrankchanges[client] = false
			}
			default:
			{
				cookieshowrankchanges[client] = true
			}
		}
	}
}

public T_CheckConnectingUsr(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */

	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 2! %s", error);
	}
	else
	{
		new String:clientname[MAX_LINE_WIDTH];
		GetClientName( client, clientname, sizeof(clientname) );
		ReplaceString(clientname, sizeof(clientname), "'", "");
		ReplaceString(clientname, sizeof(clientname), "<?PHP", "");
		ReplaceString(clientname, sizeof(clientname), "<?php", "");
		ReplaceString(clientname, sizeof(clientname), "<?", "");
		ReplaceString(clientname, sizeof(clientname), "?>", "");
		ReplaceString(clientname, sizeof(clientname), "<", "[");
		ReplaceString(clientname, sizeof(clientname), ">", "]");
		ReplaceString(clientname, sizeof(clientname), ",", ".");
		new String:ClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
		//Stupid buffer, its all your fault!
		new String:buffer[1500];
		new String:ip[20]
		GetClientIP(client,ip,sizeof(ip),true)

		if (!SQL_GetRowCount(hndl))
		{
			/*insert user*/

			if (!sqllite)
			{
				Format(buffer, sizeof(buffer), "INSERT INTO Player (`NAME`,`STEAMID`) VALUES ('%s','%s')", clientname, ClientSteamID)
				SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			}
			else
			{
				//Set default sqlite values >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>VVVVVVV<<<<<<<<<<<<<<<<<<
				Format(buffer, sizeof(buffer), "INSERT INTO Player (STEAMID, NAME) VALUES ('%s','%s');", ClientSteamID,clientname )
				SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			}
			if (GetConVarInt(showrankonconnect) != 0)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 Welcome %s", CHATTAG, clientname);
			}
		}
		else
		{
			/*update name*/
			Format(buffer, sizeof(buffer), "UPDATE Player SET NAME = '%s' WHERE STEAMID = '%s'", clientname, ClientSteamID);
			SQL_TQuery(db,SQLErrorCheckCallback, buffer)

			if (!sqllite)
			{
				if (GetConVarBool(logips))
				{
					new String:buffer2[255];
					Format(buffer2, sizeof(buffer2), "UPDATE Player SET IPAddress = '%s' WHERE STEAMID = '%s'", ip, ClientSteamID);
					SQL_TQuery(db,SQLErrorCheckCallback, buffer2)
				}
			}

			new clientpoints
			while (SQL_FetchRow(hndl))
			{
				clientpoints = SQL_FetchInt(hndl,0)
				onconpoints[client] = clientpoints
				Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player` WHERE `POINTS` >=%i", clientpoints);
				new conuserid
				conuserid = GetClientUserId(client)
				SQL_TQuery(db, T_ShowrankConnectingUsr1, buffer, conuserid);
			}
		}
	}
}

/*
#6. SQLite - add one 0, for each new entry (see about 25 lines above)
*/
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogMessage("SQL Error: %s", error);
	}
}

public T_ShowrankConnectingUsr1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 3! %s", error);
	}
	else
	{
		new rank

		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl,0)
		}

		onconrank[client] = rank

		if (GetConVarInt(showrankonconnect) != 0)
		{
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player`");
			new conuserid
			conuserid = GetClientUserId(client)
			SQL_TQuery(db, T_ShowrankConnectingUsr2, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (IsFakeClient(client))
		return;

	if (hndl == INVALID_HANDLE)
		LogError("Query failed 4! %s", error);
	else
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0)
		}


		new CCH = GetConVarInt(CountryCodeHandler)

		new String:countrySmaller[3]
		new String:countrySmall[4]
		new String:country[50]
		new String:ip[20]
		GetClientIP(client,ip,sizeof(ip),true)

		if (CCH == 1)
		{
			GeoipCode2(ip,countrySmaller)
			strcopy(country, sizeof(country), countrySmaller)
		}
		else if (CCH == 2)
		{
			GeoipCode3(ip,countrySmall)
			strcopy(country, sizeof(country), countrySmall)
		}
		else if (CCH == 3)
		{
			GeoipCountry(ip, country, sizeof(country))
		}

		if (StrEqual(country, ""))
		{
/* 			if (IsFakeClient(client))
			{
				strcopy(country, sizeof(country), "Localhost")
			}
			else */
				strcopy(country, sizeof(country), "Unknown")
		}
		if (StrEqual(country, "United States"))
			strcopy(country, sizeof(country), "The United States")

		if (CCH != 0)
		{
			if (GetConVarInt(showrankonconnect) == 1)
			{
				PrintToChat(client,"You are ranked \x04#%i\x01 out of \x04%i\x01 players with \x04%i\x01 points!", onconrank[client],rankedclients,onconpoints[client])
			}
			else if (GetConVarInt(showrankonconnect) == 2)
			{
				new String:clientname[MAX_LINE_WIDTH];
				GetClientName( client, clientname, sizeof(clientname) );
				PrintToChatAll("\x04[\x03%s\x04]\x01 \x04%s\x01 connected from \x04%s!\x04\n[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients,onconpoints[client])
			}
			else if (GetConVarInt(showrankonconnect) == 3)
			{
				ConRankPanel(client)
			}
			else if (GetConVarInt(showrankonconnect) == 4)
			{
				new String:clientname[MAX_LINE_WIDTH];
				GetClientName( client, clientname, sizeof(clientname) );
				//PrintToChatAll("\x04[\x03%s\x04]\x01 %s connected from %s. \x04[\x03Rank: %i out of %i\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients)
				PrintToChatAll("\x04[\x03%s\x04]\x01 \x04%s\x01 connected from \x04%s!\x04\n\x04[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients,onconpoints[client])
				ConRankPanel(client)
			}
		}
		else // country code disabled
		{
			if (GetConVarInt(showrankonconnect) == 1)
			{
				PrintToChat(client,"You are ranked \x04#%i\x01 out of \x04%i\x01 players with \x04%i\x01 points!", onconrank[client],rankedclients,onconpoints[client])
			}
			else if (GetConVarInt(showrankonconnect) == 2)
			{
				new String:clientname[MAX_LINE_WIDTH];
				GetClientName( client, clientname, sizeof(clientname) );
				PrintToChatAll("\x04[\x03%s\x04]\x01 \x04%s\x01 connected! \n[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",CHATTAG, clientname,onconrank[client],rankedclients,onconpoints[client])
			}
			else if (GetConVarInt(showrankonconnect) == 3)
			{
				ConRankPanel(client)
			}
			else if (GetConVarInt(showrankonconnect) == 4)
			{
				new String:clientname[MAX_LINE_WIDTH];
				GetClientName( client, clientname, sizeof(clientname) );
				PrintToChatAll("\x04[\x03%s\x04]\x01 \x04%s\x01 connected!\n\x04[\x03Ranked: \x04#%i\x03 out of %i players with \x04%i\x03 Points!\x04]",CHATTAG, clientname,onconrank[client],rankedclients,onconpoints[client])
				ConRankPanel(client)
			}
		}


		//PrintToChatAll("[Debug] The value of onconrank[client] is %i", onconrank[client])
		if (GetConVarInt(ConnectSoundTop10) == 1 && onconrank[client] < 10)
		{
			new String:soundfile[MAX_LINE_WIDTH]
			GetConVarString(ConnectSoundFileTop10,soundfile,sizeof(soundfile))
			EmitSoundToAll(soundfile);
		}
	}
}

public ConRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public Action:ConRankPanel(client)
{
	new Handle:panel = CreatePanel();
	new String:clientname[MAX_LINE_WIDTH];
	GetClientName( client, clientname, sizeof(clientname) );
	new String:buffer[255];

	Format(buffer, sizeof(buffer), "Welcome back %s",clientname)
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), "Rank: %i out of %i",onconrank[client],rankedclients)
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), "Points: %i",onconpoints[client])
	DrawPanelText(panel, buffer)
	DrawPanelItem(panel, "Close")

	SendPanelToClient(panel, client, ConRankPanelHandler, 20)

	CloseHandle(panel)

	return Plugin_Handled
}

public session(client)
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player`");
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_ShowSession1, buffer, conuserid);
}

public T_ShowSession1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 5! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0)
			new String:ConUsrSteamID[MAX_LINE_WIDTH];
			new String:buffer[255];
			GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
			Format(buffer, sizeof(buffer), "SELECT POINTS FROM Player WHERE STEAMID = '%s'", ConUsrSteamID);
			new conuserid
			conuserid = GetClientUserId(client)
			SQL_TQuery(db, T_ShowSession2, buffer, conuserid);
		}
	}
}

public T_ShowSession2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 6! %s", error);
	}
	else
	{
		new clientpoints

		while (SQL_FetchRow(hndl))
		{
			clientpoints = SQL_FetchInt(hndl,0)
			playerpoints[client] = clientpoints
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player` WHERE `POINTS` >=%i", clientpoints);
			new conuserid
			conuserid = GetClientUserId(client)
			SQL_TQuery(db, T_ShowSession3, buffer, conuserid);
		}
	}
}

public T_ShowSession3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 7! %s", error);
	}
	else
	{

		while (SQL_FetchRow(hndl))
		{
			playerrank[client] = SQL_FetchInt(hndl,0)
		}
		new String:ConUsrSteamID[MAX_LINE_WIDTH];
		new String:buffer[255];
		GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
		Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `KillAssist`, `PLAYTIME` FROM `Player` WHERE STEAMID = '%s'", ConUsrSteamID);
		new conuserid
		conuserid = GetClientUserId(client)
		SQL_TQuery(db, T_ShowSession4, buffer, conuserid);
	}
}

public T_ShowSession4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 8! %s", error);
	}
	else
	{
		new kills,death,killassi, playtime

		while (SQL_FetchRow(hndl))
		{
			kills = SQL_FetchInt(hndl,0)
			death = SQL_FetchInt(hndl,1)
			killassi = SQL_FetchInt(hndl,2)
			playtime = SQL_FetchInt(hndl,3)
		}
		SessionPanel(client,kills,death,killassi,playtime)
	}
}

public Action:SessionPanel(client, kills, death, killassi, playtime)
{
	new Handle:panel = CreatePanel();
	new String:buffer[255];
	SetPanelTitle(panel, "Session Panel:")
	DrawPanelItem(panel, " - Total")
	Format(buffer, sizeof(buffer), " Rank %i out of %i",playerrank[client],rankedclients)
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i Points",playerpoints[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i:%i Frags", kills , death)
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i Kill Assist", killassi)
	DrawPanelText(panel, buffer)
 	Format(buffer, sizeof(buffer), " Playtime: %i min", playtime)
	DrawPanelText(panel, buffer)
	DrawPanelItem(panel, " - Session")
	/*
	Format(buffer, sizeof(buffer), " Rank %i of %i",playerrank[client],rankedclients)
	DrawPanelText(panel, buffer)
	*/
	Format(buffer, sizeof(buffer), " %i Points",sessionpoints[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i:%i Frags", sessionkills[client] , sessiondeath[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i Kill Assist", sessionassi[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " Playtime: %i min", RoundToZero(GetClientTime(client)/60))
	DrawPanelText(panel, buffer)
	SendPanelToClient(panel, client, SessionRankPanelHandler, 20)


	CloseHandle(panel)

	return Plugin_Handled
}

public SessionRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public webranking(client)
{
	if (GetConVarInt(webrank) == 1)
	{
		new String:rankurl[255]
		GetConVarString(webrankurl,rankurl, sizeof(rankurl))
		new String:showrankurl[255]
		new String:UsrSteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, UsrSteamID, sizeof(UsrSteamID));

		Format(showrankurl, sizeof(showrankurl), "%splayer.php?steamid=%s&time=%i",rankurl,UsrSteamID,GetTime())
		PrintToConsole(client, "RANK MOTD-URL %s", showrankurl)
		ShowMOTDPanel(client, "Your Rank:", showrankurl, 2)
	}
}

public webtop(client)
{
	if (GetConVarInt(webrank) == 1)
	{
		new String:rankurl[255]
		GetConVarString(webrankurl,rankurl, sizeof(rankurl))
		new String:showrankurl[255]
		new String:UsrSteamID[MAX_LINE_WIDTH];
		GetClientAuthId(client, AuthId_Steam2, UsrSteamID, sizeof(UsrSteamID));

		Format(showrankurl, sizeof(showrankurl), "%stop10.php?time=%i",rankurl,GetTime())
		PrintToConsole(client, "RANK MOTD-URL %s", showrankurl)
		ShowMOTDPanel(client, "Rank:", showrankurl, 2)
	}
}

public Action:rankpanel(client, const String:steamid[])
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player`");
	Format(ranksteamidreq[client],25, "%s" ,steamid)
	SQL_TQuery(db, T_ShowRank1, buffer, GetClientUserId(client));
}

public T_ShowRank1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 9! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0)
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT POINTS FROM Player WHERE STEAMID = '%s'", ranksteamidreq[client]);
			SQL_TQuery(db, T_ShowRank2, buffer, data);
		}
	}
}

public T_ShowRank2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 10! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			reqplayerrankpoints[client] = SQL_FetchInt(hndl,0)
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player` WHERE `POINTS` >=%i", reqplayerrankpoints[client]);
			SQL_TQuery(db, T_ShowRank3, buffer, data);
		}
	}
}

public T_ShowRank3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 11! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			reqplayerrank[client] = SQL_FetchInt(hndl,0)
		}

		new String:ConUsrSteamID[MAX_LINE_WIDTH];
		new String:buffer[255];
		GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
		Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `KillAssist`, `PLAYTIME`, `NAME` FROM `Player` WHERE STEAMID = '%s'", ranksteamidreq[client]);
		SQL_TQuery(db, T_ShowRank4, buffer, data);
	}
}

public T_ShowRank4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 12! %s", error);
	}
	else
	{
		new kills,death,killassi, playtime

		while (SQL_FetchRow(hndl))
		{
			kills = SQL_FetchInt(hndl,0);
			death = SQL_FetchInt(hndl,1);
			killassi = SQL_FetchInt(hndl,2);
			playtime = SQL_FetchInt(hndl,3);
			SQL_FetchString(hndl,4, ranknamereq[client] , 32);
		}
		if (IsClientInGame(client))
			RankPanel(client, kills, death, killassi, playtime);
	}
}

public Action:RankPanel(client, kills, death, killassi, playtime)
{
	new Handle:rnkpanel = CreatePanel();
	new String:value[MAX_LINE_WIDTH]
	SetPanelTitle(rnkpanel, "Rank Panel:")
	Format(value, sizeof(value), "Name: %s", ranknamereq[client]);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "Rank: %i out of %i", reqplayerrank[client],rankedclients);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "Points: %i" , reqplayerrankpoints[client]);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "Playtime: %i" , playtime);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "Kills: %i" , kills);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "Deaths: %i" , death);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "Kill Assist: %i", killassi);
	DrawPanelText(rnkpanel, value)

	if (GetConVarInt(webrank) == 1)
	{
		DrawPanelText(rnkpanel, "[TYPE webrank FOR MORE DETAILS]")
	}

	DrawPanelItem(rnkpanel, "Close")
	SendPanelToClient(rnkpanel, client, SessionRankPanelHandler, 20)

	if (GetConVarBool(roundendranktochat) || g_IsRoundActive)
	{
		if (GetConVarBool(showranktoall))
			PrintToChatAll("\x04[\x03%s\x04] %s\x01 is Ranked \x04#%i\x01 out of \x04%i\x01 Players with \x04%i\x01 Points!",CHATTAG,ranknamereq[client],reqplayerrank[client],rankedclients,reqplayerrankpoints[client])
		else
			PrintToChat(client, "\x04[\x03%s\x04] %s\x01 is Ranked \x04#%i\x01 out of \x04%i\x01 Players with \x04%i\x01 Points!",CHATTAG,ranknamereq[client],reqplayerrank[client],rankedclients,reqplayerrankpoints[client])
	}


	new Float:kdr
	new Float:fKills
	new Float:fDeaths
	if (!g_IsRoundActive && GetConVarBool(showSessionStatsOnRoundEnd))
	{
		fKills = float(sessionkills[client]);
		fKills = fKills + (float(sessionassi[client]) / 2.0);
		fDeaths = float(sessiondeath[client]);
		if (fDeaths == 0.0)
		{
			fDeaths = 1.0;
		}

		kdr = fKills / fDeaths;
		PrintToChat(client, "\x04[\x03%s\x04] %N:\x01 You have earned \x04%i Points\x01 this session, with \x04%i Kills\x01, \x04%i Deaths\x01, and \x04%i Assists!\x01 Your \x05Kill-to-Death\x01 ratio is \x04%.2f!\x01", CHATTAG, client, sessionpoints[client], sessionkills[client], sessiondeath[client], sessionassi[client], kdr)
	}

	CloseHandle(rnkpanel);
	return Plugin_Handled
}

public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

//------------------KDeath Handler---------------------------------
public Echo_KillDeath(client)
{
	if(IsClientInGame(client))
	{
		KDeath_GetData(client);
	}
}

public KDeath_GetData(client)
{
	new data = GetClientUserId(client);

	new String:STEAMID[MAX_LINE_WIDTH]
	GetClientAuthId(client, AuthId_Steam2, STEAMID, sizeof(STEAMID));
	Format(ranksteamidreq[client], 25, "%s", STEAMID)

	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `KillAssist`, `PLAYTIME`, `NAME` FROM `Player` WHERE STEAMID = '%s'", ranksteamidreq[client]);
	SQL_TQuery(db, KDeath_ProcessData, buffer, data);

}

public KDeath_ProcessData(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 13! %s", error);
	}
	else
	{
		new iKills, iDeaths, iAssists //, iPlaytime

		while (SQL_FetchRow(hndl))
		{
			iKills = SQL_FetchInt(hndl,0)
			iDeaths = SQL_FetchInt(hndl,1)
			iAssists = SQL_FetchInt(hndl,2)
			//iPlaytime = SQL_FetchInt(hndl,3)
			SQL_FetchString(hndl,4, ranknamereq[client] , 32)
		}

		new Float:kdr
		new Float:fKills
		new Float:fDeaths

		//kdr = float(9000); //error check
		fKills = float(iKills);
		fKills = fKills + (float(iAssists) / 2.0);
		fDeaths = float(iDeaths);
		if (fDeaths == 0.0)
		{
			fDeaths = 1.0;
		}

		kdr = fKills / fDeaths;

		if (GetConVarBool(showranktoall))
		{
			PrintToChatAll("\x04[\x03%s\x04] %N\x01 has an \x04Overall\x01 Kill-to-Death ratio of \x04%.2f\x01 with \x04%i Kills\x01, \x04%i Deaths\x01, and \x04%i Assists!\x01", CHATTAG, client, kdr, iKills, iDeaths, iAssists);
			PrintToChat(client, "\x04[\x03%s\x04]\x01 Type kd<class> to show your Kill/Death ratio for that class.  Eg, kdspy", CHATTAG);
		}
		else
		{
			PrintToChat(client, "\x04[\x03%s\x04] %N\x01 has an \x04Overall\x01 Kill-to-Death ratio of \x04%.2f\x01 with \x04%i Kills\x01, \x04%i Deaths\x01, and \x04%i Assists!\x01", CHATTAG, client, kdr, iKills, iDeaths, iAssists);
			PrintToChat(client, "\x04[\x03%s\x04]\x01 Type kd<class> to show your Kill/Death ratio for that class.  Eg, kdspy", CHATTAG);
		}
	}
}
//-----------------KDeath Handler----------------------

//----------------- KDeath Per-Class Handler -------------------

public Echo_KillDeathClass(client, class)
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

public KDeathClass_GetData(client, class)
{
	new String:Classy[42];
	switch(class)
	{
		case 1:
		{
			strcopy(Classy, sizeof(Classy), "Scout");
		}
		case 2:
		{
			strcopy(Classy, sizeof(Classy), "Soldier");
		}
		case 3:
		{
			strcopy(Classy, sizeof(Classy), "Pyro");
		}
		case 4:
		{
			strcopy(Classy, sizeof(Classy), "Demo");
		}
		case 5:
		{
			strcopy(Classy, sizeof(Classy), "Heavy");
		}
		case 6:
		{
			strcopy(Classy, sizeof(Classy), "Engi");
			//PrintToChatAll("Engi")
		}
		case 7:
		{
			strcopy(Classy, sizeof(Classy), "Medic");
		}
		case 8:
		{
			strcopy(Classy, sizeof(Classy), "Sniper");
		}
		case 9:
		{
			strcopy(Classy, sizeof(Classy), "Spy");
			//PrintToChatAll("Spy!")
		}
	}

	new data = GetClientUserId(client);

	new String:STEAMID[MAX_LINE_WIDTH]
	GetClientAuthId(client, AuthId_Steam2, STEAMID, sizeof(STEAMID));
	Format(ranksteamidreq[client], 25, "%s", STEAMID)

	//------

	new Handle:pack = CreateDataPack();

	//------


	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `%sKills`, `%sDeaths`, `KillAssist`, `PLAYTIME`, `NAME` FROM `Player` WHERE STEAMID = '%s'", Classy, Classy, ranksteamidreq[client]);
	SQL_TQuery(db, KDeathClass_ProcessData, buffer, pack);

	WritePackCell(pack, class);
	WritePackCell(pack, data);

}

public KDeathClass_ProcessData(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	ResetPack(pack);
	new class = ReadPackCell(pack);
	new data = ReadPackCell(pack);

	CloseHandle(pack);

	new String:Classy[42];
	switch(class)
	{
		case 1:
		{
			strcopy(Classy, sizeof(Classy), "Scout");
		}
		case 2:
		{
			strcopy(Classy, sizeof(Classy), "Soldier");
		}
		case 3:
		{
			strcopy(Classy, sizeof(Classy), "Pyro");
		}
		case 4:
		{
			strcopy(Classy, sizeof(Classy), "Demoman");
		}
		case 5:
		{
			strcopy(Classy, sizeof(Classy), "Heavy");
		}
		case 6:
		{
			strcopy(Classy, sizeof(Classy), "Engineer");
		}
		case 7:
		{
			strcopy(Classy, sizeof(Classy), "Medic");
		}
		case 8:
		{
			strcopy(Classy, sizeof(Classy), "Sniper");
		}
		case 9:
		{
			strcopy(Classy, sizeof(Classy), "Spy");
		}
	}

	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 14! %s", error);
	}
	else
	{
		new iKills, iDeaths; //, iAssists // , iPlaytime

		while (SQL_FetchRow(hndl))
		{
			iKills = SQL_FetchInt(hndl,0);
			iDeaths = SQL_FetchInt(hndl,1);
			//iAssists = SQL_FetchInt(hndl,2)
			//iPlaytime = SQL_FetchInt(hndl,3)
			SQL_FetchString(hndl,4, ranknamereq[client] , 32);
		}

		new Float:kdr;
		new Float:fKills;
		new Float:fDeaths;

		//kdr = float(9000); //error check
		fKills = float(iKills);
		//fKills = fKills + (float(iAssists) / 2.0);
		fDeaths = float(iDeaths);
		if (fDeaths == 0.0)
		{
			fDeaths = 1.0;
		}

		kdr = fKills / fDeaths;

		if (GetConVarBool(showranktoall))
		{
			PrintToChatAll("\x04[\x03%s\x04] %N\x01 has a \x04Kill-to-Death\x01 ratio of \x04%.2f\x01 as \x05%s\x01 with \x04%i Kills\x01, \x04%i Deaths\x01", CHATTAG, client, kdr, Classy, iKills, iDeaths);
		}
		else
		{
			PrintToChat(client, "\x04[\x03%s\x04] %N\x01 has a \x04Kill-to-Death\x01 ratio of \x04%.2f\x01 as \x05%s\x01 with \x04%i Kills\x01, \x04%i Deaths\x01", CHATTAG, client, kdr, Classy, iKills, iDeaths);
		}
	}
}

//----------------- KDeath Per-Class Handler -------------------


//----------------- Lifetime Heals -------------------

public Echo_LifetimeHealz(client)
{
	if(IsClientInGame(client))
	{
		LTHeals_GetData(client);
	}
}

public LTHeals_GetData(client)
{
	new data = GetClientUserId(client);

	new String:STEAMID[MAX_LINE_WIDTH]
	GetClientAuthId(client, AuthId_Steam2, STEAMID, sizeof(STEAMID));
	Format(ranksteamidreq[client], 25, "%s", STEAMID)

	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `MedicHealing`, `NAME` FROM `Player` WHERE STEAMID = '%s'", ranksteamidreq[client]);
	SQL_TQuery(db, LTHeals_ProcessData, buffer, data);

}

public LTHeals_ProcessData(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 15! %s", error);
	}
	else
	{
		new iHealed;

		while (SQL_FetchRow(hndl))
		{
			iHealed = SQL_FetchInt(hndl,0)
			SQL_FetchString(hndl, 1, ranknamereq[client], 32)
		}

		PrintToChatAll("\x04[\x03%s\x04] %N\x01 has healed a total of %iHP on this server!", CHATTAG, client, iHealed);
	}
}

//----------------- Lifetime Heals -------------------

public top10pnl(client)
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT NAME,steamId FROM `Player` ORDER BY POINTS DESC LIMIT 0,100");
	SQL_TQuery(db, T_ShowTOP1, buffer, GetClientUserId(client));
}

public T_ShowTOP1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 16! %s", error);
	}
	else
	{
		new Handle:menu = CreateMenu(TopMenuHandler1)
		SetMenuTitle(menu, "Top Menu:")

		new i  = 1
		while (SQL_FetchRow(hndl))
		{
			new String:plname[32];
			new String:plid[32];
			SQL_FetchString(hndl,0, plname , 32)
			SQL_FetchString(hndl,1, plid , 32)
			new String:menuline[40]
			Format(menuline, sizeof(menuline), "%i. %s", i, plname);
			AddMenuItem(menu, plid, menuline )

			i++
		}
		SetMenuExitButton(menu, true)
		DisplayMenu(menu, client, 60)

		return
	}

	return
}

public TopMenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))
		rankpanel(param1, info)
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2)
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public OnConfigsExecuted()
{
	TagsCheck("TF2Stats");
	plgnversion = FindConVar("sm_tf_stats_version")
	SetConVarString(plgnversion,PLUGIN_VERSION,true,true)

	readcvars()
}

TagsCheck(const String:tag[])
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (!(StrContains(tags, tag, false)>-1))
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	CloseHandle(hTags);
}

createdbtables()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `data`");
	len += Format(query[len], sizeof(query)-len, "(`name` TEXT, `datatxt` TEXT, `dataint` INTEGER, `dataenc` VARCHAR(10)) DEFAULT CHARSET=%s DEFAULT COLLATE=%s_unicode_ci;", DBCharSet, DBCharSet);
	SQL_TQuery(db, T_CheckDBUptodate1, query)
}

createdbtablessqllite()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `data`");
	len += Format(query[len], sizeof(query)-len, "(`name` TEXT, `datatxt` TEXT, `dataint` INTEGER, `dataenc` VARCHAR(10));");
	SQL_TQuery(db, T_CheckDBUptodate1, query)
}

public T_CheckDBUptodate1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 17! %s", error);
	}
	else
	{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "SELECT dataint FROM `data` where `name` = 'dbversion'");
		SQL_TQuery(db, T_CheckDBUptodate2, buffer);
	}
}

public T_CheckDBUptodate2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed 18! %s", error);
	}
	else
	{
		if (!SQL_GetRowCount(hndl))
		{
			createdb()
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "INSERT INTO data (`name`,`dataint`, `dataenc`) VALUES ('dbversion',%i,'%s')", DBVERSION, DBCharSet)
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		}
		else
		{
			new tmpdbversion

			while (SQL_FetchRow(hndl))
			{
				tmpdbversion = SQL_FetchInt(hndl,0)
			}

			if (tmpdbversion <= 1)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bat_wood INT NOT NULL DEFAULT '0';")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_stunned INT NOT NULL DEFAULT '0';")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add drunk_bonk INT NOT NULL DEFAULT '0';")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_stealsandvich INT NOT NULL DEFAULT '0';")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add chat_status INT NOT NULL DEFAULT '0';")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 2 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bat_wood INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_stunned INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add drunk_bonk INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_stealsandvich INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add chat_status INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 2 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 2)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_tf_projectile_arrow` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_ambassador` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_taunt_sniper` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_taunt_spy` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 3 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_tf_projectile_arrow INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ambassador INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_sniper INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_spy INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 3 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 3)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `player_extinguished` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `player_teleported` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `player_feigndeath` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 4 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add player_extinguished INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_teleported INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_feigndeath INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 4 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 4)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_force_a_nature` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_sandman` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 5 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_force_a_nature INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sandman INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 5 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 5)
			{
				if (!sqllite)
				{
					CreateItemsTable()
				}
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 6 where `name` = 'dbversion';");
				SQL_TQuery(db,SQLErrorCheckCallback, buffer)
			}
			if (tmpdbversion <= 6)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `K_backstab` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_compound_bow` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_taunt_scout` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_deflect_arrow` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 7 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add K_backstab INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_compound_bow INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_scout INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_deflect_arrow INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 7 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 7)
			{
				if (!sqllite)
				{
					createdbkillog()
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `K_jar` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 8 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add K_jar INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 8 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 8)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_rocketlauncher_directhit` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_telefrag` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_deflect_flare` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_taunt_soldier` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_pickaxe` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_demoshield` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_sword` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_taunt_demoman` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_sticky_resistance` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 9 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_rocketlauncher_directhit INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_telefrag INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_deflect_flare INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_soldier INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_pickaxe INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_demoshield INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sword INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_demoman INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sticky_resistance INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 9 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 9)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_tribalkukri` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_battleaxe` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_ball` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_paintrain` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_sledgehammer` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_unique_pickaxe` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_pumpkin` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 10 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_tribalkukri INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_battleaxe INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ball INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_paintrain INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sledgehammer INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_unique_pickaxe INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_pumpkin INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 10 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 10)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_goomba` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_SntryL1` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_SntryL2` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_SntryL3` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 11 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_goomba INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_SntryL1 INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_SntryL2 INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_SntryL3 INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 11 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 11)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_frontier_justice` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_wrangler_kill` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `IPAddress` varchar(50) NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_robot_arm` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_maxgun` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_southern_hospitality` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_bleed_kill` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_robot_arm_blender_kill` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_taunt_guitar_kill` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_samrevolver` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 12 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_frontier_justice INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_wrangler_kill INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_robot_arm INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_maxgun INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_southern_hospitality INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bleed_kill INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_robot_arm_blender_kill INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_guitar_kill INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_samrevolver INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 12 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 12)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_short_stop` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_holy_mackerel` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_powerjack` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_degreaser` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_battleneedle` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_eternal_reward` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_letranger` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 13 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_short_stop INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_holy_mackerel INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_powerjack INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_degreaser INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_battleneedle INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_eternal_reward INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_letranger INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 13 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 13)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[5000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_bushwacka` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_urgentgloves` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `bread_bite` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_sleeperrifle` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_blackbox` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_robot_arm_combo_kill` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_fryingpan` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `MedicHealing` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `ScoutKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `SoldierKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `PyroKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `DemoKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `HeavyKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `EngiKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `MedicKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `SniperKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `SpyKills` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `ScoutDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `SoldierDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `PyroDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `DemoDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `HeavyDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `EngiDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `MedicDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `SniperDeaths` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `SpyDeaths` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 14 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bushwacka INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_urgentgloves INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add bread_bite INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sleeperrifle INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_robot_arm_combo_kill INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_fryingpan INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_blackbox INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add MedicHealing INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add ScoutDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add SoldierDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add PyroDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add DemoDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add HeavyDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add EngiDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add MedicDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add SniperDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add SpyDeaths INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add ScoutKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add SoldierKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add PyroKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add DemoKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add HeavyKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add EngiKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add MedicKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add SniperKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add SpyKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 14 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 14)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_headtaker` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 15 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_headtaker INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 15 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 15)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_iron_curtain` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 16 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
					//Nothing else needed here
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_iron_curtain INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					//Fixes for null sqlite shit
					//PrintToChatAll("[TF2 Stats]: TF2 Stats will now update your SQLite database and fix any NULL errors.  Please wait.");
					FixSqliteNulls();
					//PrintToChatAll("[TF2 Stats]: SQLite Database repair process has completed!");

					//Set new db version
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 16 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 16)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_candy_cane` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_boston_basher` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_back_scratcher` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_ullapool_caber` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_lochnload` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_claidheamohmor` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_brassbeast` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_bearclaws` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_steelfists` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_wrench_jag` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_amputator` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_healingcrossbow` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 17 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_candy_cane INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_boston_basher INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_back_scratcher INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ullapool_caber INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_lochnload INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_claidheamohmor INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_brassbeast INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bearclaws INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_steelfists INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_wrench_jag INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_amputator INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_healingcrossbow INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 17 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)

					FixSqliteNullsChristmas();
				}
			}

			if (tmpdbversion <= 17)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_minisentry` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_ullapool_caber_explosion` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 18 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_minisentry INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ullapool_caber_explosion INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 18 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)

					FixSqlLiteNulls_1();
				}
			}

			if (tmpdbversion <= 18)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_worms_grenade` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 19 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_worms_grenade INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 19 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)

					FixSqlLiteNulls_2();
				}
			}

			if (tmpdbversion <= 19)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_lava_axe` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_sun_bat` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 20 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_lava_axe INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sun_bat INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 20 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)

					FixSqlLiteNulls_3();
				}
			}

			if (tmpdbversion <= 20)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_warfan` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_kunai` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_katana` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 21 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_warfan INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_kunai INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_katana INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 21 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)

					FixSqlLiteNulls_Samurai();
				}
			}

			if (tmpdbversion <= 21)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_witcher_sword` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_maul` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 22 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_witcher_sword INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_maul INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 22 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)

					FixSqlLiteNulls_Witcher_RF();
				}
			}

			if (tmpdbversion <= 22)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_soda_popper` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_the_winger` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_atomizer` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_liberty_launcher` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_reserve_shooter` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_disciplinary_action` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_market_gardener` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_mantreads` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_detonator` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_persian_persuader` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_splendid_screen` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `tide_turner` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_tomislav` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_family_business` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_eviction_notice` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_proto_syringe` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_solemn_vow` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_bazaar_bargain` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_shahanshah` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_enforcer` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_big_earner` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 23 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_soda_popper INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_the_winger INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_atomizer INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_liberty_launcher INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_reserve_shooter INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_disciplinary_action INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_market_gardener INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_mantreads INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_detonator INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_persian_persuader INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_splendid_screen INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add tide_turner INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_tomislav INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_family_business INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_eviction_notice INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_proto_syringe INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_solemn_vow INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bazaar_bargain INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_shahanshah INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_enforcer INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_big_earner INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 23 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)

					FixSqliteNullsChristmas();
				}
			}

			if (tmpdbversion <= 23)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_mailbox` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_golfclub` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 24 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_mailbox INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_golfclub INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 24 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}


			if (tmpdbversion <= 24)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_mangler` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_bison` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "CHANGE `IPAddress` `IPAddress` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 25 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_mangler INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bison INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 25 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}

			if (tmpdbversion <= 25)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_QuakeRL` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `airstrike` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `TotalPlayersTeleported` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 26 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_QuakeRL INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add TotalPlayersTeleported INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 26 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}

			if (tmpdbversion <= 26)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_ManglerReflect` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_Widowmaker` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_Short_Circuit` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_Machina` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_Machina_DoubleKill` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_Diamondback` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 27 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ManglerReflect INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_Widowmaker INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_Short_Circuit INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_Machina INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_Machina_DoubleKill INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_Diamondback INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 27 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}

			if (tmpdbversion <= 27)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_UnarmedCombat` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_WangaPrick` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_ScottishHandshake` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_ConscientiousObjector` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_Saxxy` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `EyeBossStuns` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `EyeBossKills` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 28 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_UnarmedCombat INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_WangaPrick INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ScottishHandshake INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ConscientiousObjector INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_Saxxy INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add EyeBossStuns INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add EyeBossKills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 28 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}


			if (tmpdbversion <= 28)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_phlogistinator` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_manmelter` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_thirddegree` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_holiday_punch` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_pomson` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_eureka_effect` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_sharp_dresser` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_spy_cicle` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 29 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_phlogistinator INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_manmelter INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_thirddegree INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_holiday_punch INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_pomson INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_eureka_effect INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sharp_dresser INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_spy_cicle INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 29 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}

			if (tmpdbversion <= 32)	//skip a few numbers here in order to get everyone's version numbers resynced again after they were 1 too high for a while...
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[500];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `founditems` ADD `ItemIndex` int(10) NOT NULL DEFAULT '0' COMMENT 'Item definition index from items_game.txt',");
					len += Format(query[len], sizeof(query)-len, "ADD `Quality` int(3) NOT NULL DEFAULT '0' COMMENT 'Int value for vintage, strange, etc',");
					len += Format(query[len], sizeof(query)-len, "ADD `Method` int(3) NOT NULL DEFAULT '0' COMMENT 'Crafted, traded, found, unboxed, etc';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(query, sizeof(query), "DELETE FROM `founditems` WHERE ITEM IS NULL OR ITEM = '' OR ITEM = '0'");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 33 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					//	WELP, NOTHIN TO DO HERR
					new String:buffer[64];
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 33 where `name` = 'dbversion';");
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
				}
			}

			if (tmpdbversion <= 33)
			{
				if (!sqllite)
				{
					CreateItemsTable();	//Make sure this damn thing is created
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 34 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					//	WELP, NOTHIN TO DO HERR
					new String:buffer[64];
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 34 where `name` = 'dbversion';");
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
				}
			}
			
			if (tmpdbversion <= 34)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `KW_wrap_assassin` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_apocofists` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `KW_black_rose` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 35 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_wrap_assassin INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_apocofists INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_black_rose INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 35 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}	
			
			if (tmpdbversion <= 35)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `pep_brawlerblaster` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `pep_pistol` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `dumpster_device` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `unique_pickaxe_escape` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `rainblower` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `scorchshot` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `lollichop` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `armageddon` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `pro_rifle` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `the_classic` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `pro_smg` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 36 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add pep_brawlerblaster INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add pep_pistol INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add dumpster_device INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add unique_pickaxe_escape INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add rainblower INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add scorchshot INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add lollichop INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add armageddon INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add pro_rifle INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add the_classic INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add pro_smg INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 36 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}
			
			if (tmpdbversion <= 36)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `long_heatmaker` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `annihilator` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `guillotine` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `recorder` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 37 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add long_heatmaker INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add annihilator INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add guillotine INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add recorder INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 37 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}

			if (tmpdbversion <= 37)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `ham_shank` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `awper_hand` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `loose_cannon_impact` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `loose_cannon` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `skullbat` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `freedom_staff` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `the_rescue_ranger` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `memory_maker` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `golden_fryingpan` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_athletic` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_bats` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_blastjump` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_boss` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_fireball` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_lightning` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_mirv` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_skeleton` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `spellbook_teleport` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 38 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add ham_shank INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add awper_hand INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add loose_cannon_impact INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add loose_cannon INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add skullbat INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add freedom_staff INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add the_rescue_ranger INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add memory_maker INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add golden_fryingpan INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_athletic INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_bats INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_blastjump INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_boss INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_fireball INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_lightning INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_meteor INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_mirv INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_skeleton INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add spellbook_teleport INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 38 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}

			if (tmpdbversion <= 38)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `rtd_toxic` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `rtd_timebomb` INT NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `rtd_instant_kills` INT NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 39 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add rtd_toxic INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add rtd_timebomb INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add rtd_instant_kills INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 39 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}
			if (tmpdbversion <= 39)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `panic_attack` int(11) NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `iron_bomber` int(11) NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `ai_flamethrower` int(11) NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 40 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add panic_attack INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add iron_bomber INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add ai_flamethrower INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 40 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}
			if (tmpdbversion <= 40)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `quickiebomb_launcher` int(11) NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 41 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add quickiebomb_launcher INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 41 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}
			if (tmpdbversion <= 41)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `necro_smasher` int(11) NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `taunt_medic` int(11) NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 42 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add necro_smasher INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add taunt_medic INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 42 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}
			if (tmpdbversion <= 42)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` CHANGE COLUMN `NAME` `NAME` VARCHAR(50) NOT NULL COMMENT '' ,");
					len += Format(query[len], sizeof(query)-len, "ADD `crossing_guard` int(11) NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `rescue_ranger_reflect` int(11) NOT NULL DEFAULT '0',");
					len += Format(query[len], sizeof(query)-len, "ADD `medigun_shield` int(11) NOT NULL DEFAULT '0';");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 43 where `name` = 'dbversion'");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table Player add crossing_guard INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add rescue_ranger_reflect INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add medigun_shield INTEGER DEFAULT 0 ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 43 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}
			if (tmpdbversion <= 43)
			{
				if (!sqllite)
				{
					new String:buffer[255];
					new len = 0;
										
					decl String:query[1000];
					len += Format(query[len], sizeof(query)-len, "ALTER TABLE `data` ADD `dataenc` VARCHAR(50) NOT NULL COMMENT '' ;");
					SQL_TQuery(db, SQLErrorCheckCallback, query);

					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 44, dataenc = '%s' where `name` = 'dbversion'", DBCharSet);
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
				else
				{
					new String:buffer[600];
					Format(buffer, sizeof(buffer), "ALTER table data add dataenc  VARCHAR(10) NOT NULL ;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					
					
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 44, dataenc = '%s' where `name` = 'dbversion';", DBCharSet);
					SQL_TQuery(db,SQLErrorCheckCallback, buffer);
				}
			}
			//---------

		}

		initonlineplayers()
	}
}

/*
#7. Add DB update queries above
	And null fixes below -> not needed now
	-Done
*/

FixSqliteNulls()
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `POINTS` = '0' WHERE `POINTS` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `PLAYTIME` = '0' WHERE `PLAYTIME` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `LASTONTIME` = '0' WHERE `LASTONTIME` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KILLS` = '0' WHERE `KILLS` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `Death` = '0' WHERE `Death` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KillAssist` = '0' WHERE `KillAssist` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KillAssistMedic` = '0' WHERE `KillAssistMedic` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `BuildSentrygun` = '0' WHERE `BuildSentrygun` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `BuildDispenser` = '0' WHERE `BuildDispenser` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `HeadshotKill` = '0' WHERE `HeadshotKill` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KOSentrygun` = '0' WHERE `KOSentrygun` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `Domination` = '0' WHERE `Domination` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `Overcharge` = '0' WHERE `Overcharge` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KOSapper` = '0' WHERE `KOSapper` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `BOTeleporterentrace` = '0' WHERE `BOTeleporterentrace` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KODispenser` = '0' WHERE `KODispenser` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `BOTeleporterExit` = '0' WHERE `BOTeleporterExit` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `CPBlocked` = '0' WHERE `CPBlocked` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `CPCaptured` = '0' WHERE `CPCaptured` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `FileCaptured` = '0' WHERE `FileCaptured` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `ADCaptured` = '0' WHERE `ADCaptured` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KOTeleporterExit` = '0' WHERE `KOTeleporterExit` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KOTeleporterEntrace` = '0' WHERE `KOTeleporterEntrace` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `BOSapper` = '0' WHERE `BOSapper` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `Revenge` = '0' WHERE `Revenge` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Axe` = '0' WHERE `KW_Axe` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Bnsw` = '0' WHERE `KW_Bnsw` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Bt` = '0' WHERE `KW_Bt` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Bttl` = '0' WHERE `KW_Bttl` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Cg` = '0' WHERE `KW_Cg` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Fsts` = '0' WHERE `KW_Fsts` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Ft` = '0' WHERE `KW_Ft` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Gl` = '0' WHERE `KW_Gl` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Kn` = '0' WHERE `KW_Kn` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Mctte` = '0' WHERE `KW_Mctte` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Mgn` = '0' WHERE `KW_Mgn` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Ndl` = '0' WHERE `KW_Ndl` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Pistl` = '0' WHERE `KW_Pistl` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Rkt` = '0' WHERE `KW_Rkt` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Sg` = '0' WHERE `KW_Sg` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `back_scatter` = '0' WHERE `back_scatter` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Sky` = '0' WHERE `KW_Sky` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Smg` = '0' WHERE `KW_Smg` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Spr` = '0' WHERE `KW_Spr` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Stgn` = '0' WHERE `KW_Stgn` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Wrnc` = '0' WHERE `KW_Wrnc` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Sntry` = '0' WHERE `KW_Sntry` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Shvl` = '0' WHERE `KW_Shvl` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Ubersaw` = '0' WHERE `KW_Ubersaw` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Flaregun` = '0' WHERE `KW_Flaregun` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_Axtinguisher` = '0' WHERE `KW_Axtinguisher` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_pyro` = '0' WHERE `KW_taunt_pyro` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_heavy` = '0' WHERE `KW_taunt_heavy` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_gloves` = '0' WHERE `KW_gloves` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_backburner` = '0' WHERE `KW_backburner` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_natascha` = '0' WHERE `KW_natascha` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_blutsauger` = '0' WHERE `KW_blutsauger` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_deflect_rocket` = '0' WHERE `KW_deflect_rocket` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_deflect_promode` = '0' WHERE `KW_deflect_promode` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_deflect_sticky` = '0' WHERE `KW_deflect_sticky` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_world` = '0' WHERE `KW_world` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_bat_wood` = '0' WHERE `KW_bat_wood` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `player_stunned` = '0' WHERE `player_stunned` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `drunk_bonk` = '0' WHERE `drunk_bonk` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `player_stealsandvich` = '0' WHERE `player_stealsandvich` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `chat_status` = '0' WHERE `chat_status` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_tf_projectile_arrow` = '0' WHERE `KW_tf_projectile_arrow` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_ambassador` = '0' WHERE `KW_ambassador` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_sniper` = '0' WHERE `KW_taunt_sniper` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_spy` = '0' WHERE `KW_taunt_spy` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `player_extinguished` = '0' WHERE `player_extinguished` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `player_teleported` = '0' WHERE `player_teleported` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `player_feigndeath` = '0' WHERE `player_feigndeath` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_force_a_nature` = '0' WHERE `KW_force_a_nature` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_sandman` = '0' WHERE `KW_sandman` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `K_backstab` = '0' WHERE `K_backstab` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_compound_bow` = '0' WHERE `KW_compound_bow` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_scout` = '0' WHERE `KW_taunt_scout` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_deflect_arrow` = '0' WHERE `KW_deflect_arrow` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_rocketlauncher_directhit` = '0' WHERE `KW_rocketlauncher_directhit` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_telefrag` = '0' WHERE `KW_telefrag` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_deflect_flare` = '0' WHERE `KW_deflect_flare` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_soldier` = '0' WHERE `KW_taunt_soldier` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_pickaxe` = '0' WHERE `KW_pickaxe` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_demoshield` = '0' WHERE `KW_demoshield` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_sword` = '0' WHERE `KW_sword` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_demoman` = '0' WHERE `KW_taunt_demoman` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_sticky_resistance` = '0' WHERE `KW_sticky_resistance` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_SntryL1` = '0' WHERE `KW_SntryL1` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_SntryL2` = '0' WHERE `KW_SntryL2` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_SntryL3` = '0' WHERE `KW_SntryL3` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_tribalkukri` = '0' WHERE `KW_tribalkukri` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_battleaxe` = '0' WHERE `KW_battleaxe` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_ball` = '0' WHERE `KW_ball` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_paintrain` = '0' WHERE `KW_paintrain` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_sledgehammer` = '0' WHERE `KW_sledgehammer` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_unique_pickaxe` = '0' WHERE `KW_unique_pickaxe` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_pumpkin` = '0' WHERE `KW_pumpkin` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_goomba` = '0' WHERE `KW_goomba` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_frontier_justice` = '0' WHERE `KW_frontier_justice` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_wrangler_kill` = '0' WHERE `KW_wrangler_kill` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_robot_arm` = '0' WHERE `KW_robot_arm` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_maxgun` = '0' WHERE `KW_maxgun` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_southern_hospitality` = '0' WHERE `KW_southern_hospitality` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_bleed_kill` = '0' WHERE `KW_bleed_kill` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_robot_arm_blender_kill` = '0' WHERE `KW_robot_arm_blender_kill` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_taunt_guitar_kill` = '0' WHERE `KW_taunt_guitar_kill` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_samrevolver` = '0' WHERE `KW_samrevolver` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_powerjack` = '0' WHERE `KW_powerjack` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_degreaser` = '0' WHERE `KW_degreaser` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_battleneedle` = '0' WHERE `KW_battleneedle` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_eternal_reward` = '0' WHERE `KW_eternal_reward` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_letranger` = '0' WHERE `KW_letranger` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_short_stop` = '0' WHERE `KW_short_stop` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_holy_mackerel` = '0' WHERE `KW_holy_mackerel` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_bushwacka` = '0' WHERE `KW_bushwacka` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_urgentgloves` = '0' WHERE `KW_urgentgloves` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `bread_bite` = '0' WHERE `bread_bite` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_sleeperrifle` = '0' WHERE `KW_sleeperrifle` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_blackbox` = '0' WHERE `KW_blackbox` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `ScoutDeaths` = '0' WHERE `ScoutDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `SoldierDeaths` = '0' WHERE `SoldierDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `PyroDeaths` = '0' WHERE `PyroDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `DemoDeaths` = '0' WHERE `DemoDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `HeavyDeaths` = '0' WHERE `HeavyDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `EngiDeaths` = '0' WHERE `EngiDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `MedicDeaths` = '0' WHERE `MedicDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `SniperDeaths` = '0' WHERE `SniperDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `SpyDeaths` = '0' WHERE `SpyDeaths` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `ScoutKills` = '0' WHERE `ScoutKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `SoldierKills` = '0' WHERE `SoldierKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `PyroKills` = '0' WHERE `PyroKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `DemoKills` = '0' WHERE `DemoKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `HeavyKills` = '0' WHERE `HeavyKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `EngiKills` = '0' WHERE `EngiKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `MedicKills` = '0' WHERE `MedicKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `SniperKills` = '0' WHERE `SniperKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `SpyKills` = '0' WHERE `SpyKills` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_robot_arm_combo_kill` = '0' WHERE `KW_robot_arm_combo_kill` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_fryingpan` = '0' WHERE `KW_fryingpan` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `MedicHealing` = '0' WHERE `MedicHealing` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_headtaker` = '0' WHERE `KW_headtaker` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_iron_curtain` = '0' WHERE `KW_iron_curtain` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_jar` = '0' WHERE `KW_jar` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}

FixSqliteNullsChristmas()
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_candy_cane` = '0' WHERE `KW_candy_cane` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_boston_basher` = '0' WHERE `KW_boston_basher` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_back_scratcher` = '0' WHERE `KW_back_scratcher` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_ullapool_caber` = '0' WHERE `KW_ullapool_caber` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_lochnload` = '0' WHERE `KW_lochnload` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_claidheamohmor` = '0' WHERE `KW_claidheamohmor` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_brassbeast` = '0' WHERE `KW_brassbeast` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_bearclaws` = '0' WHERE `KW_bearclaws` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_steelfists` = '0' WHERE `KW_steelfists` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_wrench_jag` = '0' WHERE `KW_wrench_jag` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_amputator` = '0' WHERE `KW_amputator` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_healingcrossbow` = '0' WHERE `KW_healingcrossbow` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}

FixSqlLiteNulls_1()
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_minisentry` = '0' WHERE `KW_minisentry` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_ullapool_caber_explosion` = '0' WHERE `KW_ullapool_caber_explosion` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}

FixSqlLiteNulls_2()
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_worms_grenade` = '0' WHERE `KW_worms_grenade` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}

FixSqlLiteNulls_3()
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_lava_axe` = '0' WHERE `KW_lava_axe` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_sun_bat` = '0' WHERE `KW_sun_bat` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}

FixSqlLiteNulls_Samurai()
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_warfan` = '0' WHERE `KW_warfan` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_kunai` = '0' WHERE `KW_kunai` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_katana` = '0' WHERE `KW_katana` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}

FixSqlLiteNulls_Witcher_RF()
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_witcher_sword` = '0' WHERE `KW_witcher_sword` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	Format(buffer, sizeof(buffer), "UPDATE `Player` SET `KW_maul` = '0' WHERE `KW_maul` IS NULL ;")
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
}

public OnClientDisconnect(client)
{
	g_iLastRankCheck[client] = 0;

	if (overchargescoringtimer[client] != INVALID_HANDLE)
	{
		KillTimer(overchargescoringtimer[client])
		overchargescoringtimer[client] = INVALID_HANDLE
	}

	if (CheckCookieTimers[client] != INVALID_HANDLE)
	{
		KillTimer(CheckCookieTimers[client])
		CheckCookieTimers[client] = INVALID_HANDLE
	}

	if (rankingactive)
	{
		if (GetConVarInt(neededplayercount) > GetClientCount(true))
		{
			rankingactive = false
			if (GetConVarBool(ShowEnoughPlayersNotice))
				PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Disabled: not enough players",CHATTAG)
		}
	}
}

readcvars()
{
	GetConVarString(CV_chattag,CHATTAG, sizeof(CHATTAG))
	showchatcommands = GetConVarBool(CV_showchatcommands)
	extendedloggingenabled = GetConVarBool(CV_extendetlogging)
	rankingenabled = GetConVarBool(CV_rank_enable)
}

startconvarhooking()
{
	HookConVarChange(CV_chattag,OnConVarChangechattag)
	HookConVarChange(CV_showchatcommands,OnConVarChangeshowchatcommands)
	HookConVarChange(CV_rank_enable,OnConVarChangerank_enable)
}

public OnConVarChangechattag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(CV_chattag,CHATTAG, sizeof(CHATTAG))
}

public OnConVarChangerank_enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:value = GetConVarBool(CV_rank_enable)
	if (value)
	{
		rankingenabled = true
		PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Started",CHATTAG)
	}
	else if (!value)
	{
		PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Stopped",CHATTAG)
		rankingenabled = false
	}
}

public OnConVarChangeshowchatcommands(Handle:convar, const String:oldValue[], const String:newValue[])
{
	showchatcommands = GetConVarBool(CV_showchatcommands)
}

public Action:resetoverchargescoring(Handle:timer, any:client)
{
	overchargescoring[client] = true
	overchargescoringtimer[client] = INVALID_HANDLE
}

/*
public OnAllPluginsLoaded()
{
	if (LibraryExists("pluginautoupdate"))
	{
		// only register myself if the autoupdater is loaded
		// AutoUpdate_AddPlugin(const String:url[], const String:file[], const String:version[])
		Updater_AddPlugin("darthninja.com");
	}
}

public OnPluginEnd()
{
	if (LibraryExists("pluginautoupdate"))
	{
		Updater_RemovePlugin();
	}
}
*/

/*
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    MarkNativeAsOptional("AutoUpdate_AddPlugin");
    MarkNativeAsOptional("AutoUpdate_RemovePlugin");
    return true;
}
*/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    MarkNativeAsOptional("AutoUpdate_AddPlugin");
    MarkNativeAsOptional("AutoUpdate_RemovePlugin");
    return APLRes_Success;
}


CreateItemsTable()
{
	new len = 0;
	decl String:query[1000];
		
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `founditems` (");
	len += Format(query[len], sizeof(query)-len, "`ID` int(11) NOT NULL AUTO_INCREMENT,");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ACTUALTIME` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ITEM` varchar(50) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ItemIndex` int(10) NOT NULL DEFAULT '0' COMMENT 'Item definition index from items_game.txt',");
	len += Format(query[len], sizeof(query)-len, "`Quality` int(3) NOT NULL DEFAULT '0' COMMENT 'Int value for vintage, strange, etc',");
	len += Format(query[len], sizeof(query)-len, "`Method` int(3) NOT NULL DEFAULT '0' COMMENT 'Crafted, traded, found, unboxed, etc',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`ID`)");
	len += Format(query[len], sizeof(query)-len, ") DEFAULT CHARSET=%s DEFAULT COLLATE=%s_unicode_ci AUTO_INCREMENT=1 ;", DBCharSet, DBCharSet);
	SQL_FastQuery(db, query);
}

CreateItemsTablesqllite()
{
	new len = 0;
	decl String:query[1000];
		
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `founditems` (");
	len += Format(query[len], sizeof(query)-len, "`ID` int(11) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ACTUALTIME` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ITEM` varchar(50) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ItemIndex` int(10) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`Quality` int(3) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`Method` int(3) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`ID`)");
	len += Format(query[len], sizeof(query)-len, ");");
	SQL_FastQuery(db, query);
}

public Action:Event_item_found(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "isfake"))	//Item is fake
		return;

	if (!sqllite)
	{
		new String:steamid[64];
		GetClientAuthId(GetEventInt(event, "player"), AuthId_Steam2, steamid, sizeof(steamid));

		new String:query[512];
		Format(query, sizeof(query), "INSERT INTO founditems (`STEAMID`, `ACTUALTIME`, `ItemIndex`, `Quality`, `Method`) VALUES ('%s', '%i', '%i', %i, %i)", steamid, GetTime(), GetEventInt(event, "itemdef"), GetEventInt(event, "quality"), GetEventInt(event, "method"));
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
	return;
}


public Action:Event_player_teleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new String:SteamID[64]
		new String:query[512];

		new client = GetClientOfUserId(GetEventInt(event, "userid"));		
		//if (GetConVarBool(ignorebots) && IsFakeClient(client))
			//return;	//If a bot takes the tele, ignore it.
		
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		
		//Number of times a player has used a teleporter
		Format(query, sizeof(query), "UPDATE Player SET player_teleported = player_teleported + 1 WHERE STEAMID = '%s'", SteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);

		//Get builders steamid
		new builder = GetClientOfUserId(GetEventInt(event, "builderid"))
		if (builder == 0 || client == 0)
			return Plugin_Continue;
		if (GetConVarBool(ignorebots) && IsFakeClient(builder))
			return Plugin_Continue;	// Tele owner is a bot -> ignore it
		
		GetClientAuthId(builder, AuthId_Steam2, SteamID, sizeof(SteamID));

		//Number of times a players teleporter has been used
		Format(query, sizeof(query), "UPDATE Player SET TotalPlayersTeleported = TotalPlayersTeleported + 1 WHERE STEAMID = '%s'", SteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);

		if (client != builder && GetClientTeam(client) == GetClientTeam(builder))
		{
			new iPoints = GetConVarInt(TeleUsePoints);
			Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i WHERE STEAMID = '%s'", iPoints, SteamID);
			SQL_TQuery(db,SQLErrorCheckCallback, query);

			if (iPoints > 0 && cookieshowrankchanges[builder] && GetConVarBool(ShowTeleNotices))
			{
				PrintToChat(builder,"\x04[\x03%s\x04]\x01 You got %i points for teleporting \x03%N\x01!", CHATTAG, iPoints, client)
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_player_extinguished(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new healer = GetClientOfUserId(GetEventInt(event, "healer"));
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));	
		if (healer == 0 || victim == 0)
			return Plugin_Continue;

		new pointvalue = GetConVarInt(extingushingpoints);
		new String:SteamID[64];

		GetClientAuthId(healer, AuthId_Steam2, SteamID, sizeof(SteamID));
		
		new bool:isbot;
		if (StrEqual(SteamID,"BOT")){
			isbot = true;
		}
		
		new bool:ShouldIgnoreBots = GetConVarBool(ignorebots);
		if (ShouldIgnoreBots == false)
		{
			isbot = false;
		}
		
		if(isbot){
			return Plugin_Continue;
		}
		
		new String:query[512];
		Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, player_extinguished = player_extinguished + 1 WHERE STEAMID = '%s'", pointvalue, SteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);

		if (GetConVarInt(pointmsg) == 1)
			PrintToChatAll("\x04[\x03%s\x04]\x01 %N got %i points for extingushing %N", CHATTAG, healer, pointvalue, victim);
		else if (cookieshowrankchanges[healer])
			PrintToChat(healer, "\x04[\x03%s\x04]\x01 you got %i points for extingushing %N!", CHATTAG, pointvalue, victim);
	}
	return Plugin_Continue;
}

public sayhidepoints(client)
{
	new String:steamId[MAX_LINE_WIDTH]
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET chat_status = '2' WHERE STEAMID = '%s'",steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query);
	cookieshowrankchanges[client] = false
}

public sayunhidepoints(client)
{
	new String:steamId[MAX_LINE_WIDTH]
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET chat_status = '1' WHERE STEAMID = '%s'",steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query);
	cookieshowrankchanges[client] = true
}

//TODO: Workout more to debug.
//CheckIfTablesAreThere()
//{
//	decl String:query[255];
//	Format(query, sizeof(query), "SELECT Count(*) FROM `Player`);
//	SQL_TQuery(db, T_CheckConnectionStatus, query)
//}
 
//public T_CheckConnectionStatus(Handle:owner, Handle:hndl, const String:error[], any:data)
//{
//	if (hndl == INVALID_HANDLE){
//		LogError("Cannot Find Player Table! %s", error);
//	}
//	else{
//		LogError("Player Database has been found!");
//	}
	
//	if (db == INVALID_HANDLE){
//		LogError("Lost Connection to database! %s", error);
//	}
//	else{
//		LogError("Still Connected to the database!");
//	}
//}
