#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks >
#include <geoip>
#undef REQUIRE_PLUGIN
#include <autoupdate>
#define PLUGIN_VERSION "6.6.4"
#define DBVERSION 12
#define MAX_LINE_WIDTH 60

new bool:cpmap = false
new mapisset
new classfunctionloaded = 0

new Handle:db = INVALID_HANDLE;			/** Database connection */

new bool:rankingenabled = false

// Death Points
new Handle:Scoutdiepoints = INVALID_HANDLE;
new Handle:Soldierdiepoints = INVALID_HANDLE;
new Handle:Pyrodiepoints = INVALID_HANDLE;
new Handle:Medicdiepoints = INVALID_HANDLE;
new Handle:Sniperdiepoints = INVALID_HANDLE;
new Handle:Spydiepoints = INVALID_HANDLE;
new Handle:Demomandiepoints = INVALID_HANDLE;
new Handle:Heavydiepoints = INVALID_HANDLE;
new Handle:Engineerdiepoints = INVALID_HANDLE;

new bool:oldshowranktoallvalue = true

/*
1. Add handles
*/


//Scout Points
//-------------------

// Default Weapons
new Handle:scattergunpoints = INVALID_HANDLE;
new Handle:batpoints = INVALID_HANDLE;
new Handle:pistolpoints = INVALID_HANDLE;

//Unlocks
new Handle:force_a_naturepoints = INVALID_HANDLE;
new Handle:sandmanpoints = INVALID_HANDLE;
new Handle:bat_woodpoints = INVALID_HANDLE;

//Other
new Handle:ballpoints = INVALID_HANDLE;
new Handle:taunt_scoutpoints = INVALID_HANDLE;

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

//Other
new Handle:taunt_soldierpoints = INVALID_HANDLE;
new Handle:paintrainpoints = INVALID_HANDLE;

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

//Other
new Handle:taunt_pyropoints = INVALID_HANDLE;
new Handle:deflect_flarepoints = INVALID_HANDLE;
new Handle:deflect_rocketpoints = INVALID_HANDLE;
new Handle:deflect_promodepoints = INVALID_HANDLE;
new Handle:deflect_stickypoints = INVALID_HANDLE;
new Handle:deflect_arrowpoints = INVALID_HANDLE;

//Special
new Handle:sledgehammerpoints = INVALID_HANDLE;

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

//Other
new Handle:taunt_demomanpoints = INVALID_HANDLE;

//--------------------


//Heavy Points
//--------------------

// Default Weapons
new Handle:minigunpoints = INVALID_HANDLE;

new Handle:fistspoints = INVALID_HANDLE;

//Unlocks
new Handle:nataschapoints = INVALID_HANDLE;
new Handle:glovespoints = INVALID_HANDLE;

//Other
new Handle:taunt_heavypoints = INVALID_HANDLE;

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
new Handle:taunt_guitar_killPoints  = INVALID_HANDLE; //new shotgun taunt kill : added v6:6

//--------------------


//Medic Points
//--------------------

// Default Weapons
new Handle:bonesawpoints = INVALID_HANDLE;
new Handle:syringegun_medicpoints = INVALID_HANDLE;

//Unlocks
new Handle:blutsaugerpoints = INVALID_HANDLE;
new Handle:ubersawpoints = INVALID_HANDLE;

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

//Special
new Handle:woodknifepoints = INVALID_HANDLE;

//Other
new Handle:taunt_sniperpoints = INVALID_HANDLE;

//--------------------


//Spy Points
//--------------------

// Default Weapons
new Handle:revolverpoints = INVALID_HANDLE;
new Handle:knifepoints = INVALID_HANDLE;

//Unlocks
new Handle:ambassadorpoints = INVALID_HANDLE;
new Handle:samrevolverpoints = INVALID_HANDLE;

//Other
new Handle:taunt_spypoints = INVALID_HANDLE;

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

//--------------------


//Other - Kills
//--------------------

new Handle:pumpkinpoints = INVALID_HANDLE;
new Handle:goombapoints = INVALID_HANDLE; //Added v6:5

//--------------------


//Other

new Handle:ignorebots = INVALID_HANDLE;

new Handle:logips = INVALID_HANDLE; //Added v6:6

new Handle:showranktoall  = INVALID_HANDLE;
new Handle:showrankonroundend = INVALID_HANDLE;
new Handle:showrankonconnect = INVALID_HANDLE;

new Handle:webrank = INVALID_HANDLE;
new Handle:webrankurl = INVALID_HANDLE;

new Handle:removeoldplayers = INVALID_HANDLE;
new Handle:removeoldplayersdays = INVALID_HANDLE;
new Handle:removeoldmaps = INVALID_HANDLE;
new Handle:removeoldmapssdays = INVALID_HANDLE;

new Handle:Capturepoints = INVALID_HANDLE;
new Handle:FileCapturepoints = INVALID_HANDLE;
new Handle:Captureblockpoints = INVALID_HANDLE;

new Handle:neededplayercount = INVALID_HANDLE;
new Handle:disableafterwin = INVALID_HANDLE;
new Handle:worldpoints = INVALID_HANDLE;
new Handle:plgnversion = INVALID_HANDLE;

new Handle:ConnectSoundFile		= INVALID_HANDLE;
new Handle:ConnectSound	= INVALID_HANDLE;

new Handle:CheckCookieTimers[MAXPLAYERS+1]

new bool:sqllite = false
new bool:rankingactive = true
new bool:extendedloggingenabled = false

new onconrank[MAXPLAYERS + 1]
new onconpoints[MAXPLAYERS + 1]
new rankedclients = 0
new playerpoints[MAXPLAYERS + 1]
new playerrank[MAXPLAYERS + 1]
new String:ranksteamidreq[MAXPLAYERS + 1][25];
new String:ranknamereq[MAXPLAYERS + 1][32];
new reqplayerrankpoints[MAXPLAYERS + 1]
new reqplayerrank[MAXPLAYERS + 1]

new TF_classoffsets, maxents, ResourceEnt, maxplayers;

new sessionpoints[MAXPLAYERS + 1]
new sessionkills[MAXPLAYERS + 1]
new sessiondeath[MAXPLAYERS + 1]
new sessionassi[MAXPLAYERS + 1]

new overchargescoring[MAXPLAYERS + 1]
new Handle:overchargescoringtimer[MAXPLAYERS + 1]
new Handle:pointmsg = INVALID_HANDLE;

new bool:roundactive = true


new Handle:CV_chattag = INVALID_HANDLE;
new Handle:CV_showchatcommands = INVALID_HANDLE;
new String:CHATTAG[MAX_LINE_WIDTH]

new bool:cookieshowrankchanges[MAXPLAYERS + 1]
new bool:showchatcommands = true

new Handle:CV_extendetlogging = INVALID_HANDLE
new Handle:CV_extlogcleanuptime = INVALID_HANDLE
new Handle:CV_rank_enable = INVALID_HANDLE


public Plugin:myinfo =
{
	name = "[TF2] Player Stats",
	author = "DarthNinja, R-Hehl",
	description = "TF2 Player Stats",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=109006"
};

public OnPluginStart()
{
	versioncheck()
	openDatabaseConnection()
	createdbtables()
	convarcreating()
	AutoExecConfig(false,"tf2-stats","")
	CreateConVar("sm_tf_stats_version", PLUGIN_VERSION, "TF2 Player Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	//TF_classoffsets = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass");
	createeventhooks()
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegAdminCmd("rank_admin", Menu_adm, ADMFLAG_ROOT, "Open Rank Admin Menu");
	CreateTimer(60.0,sec60evnt,INVALID_HANDLE,TIMER_REPEAT);
	startconvarhooking()
}

versioncheck()
{
	if (FileExists("addons/sourcemod/plugins/n1g-tf2-stats.smx"))
	{
		ServerCommand("say [OLD-VERSION] file n1g-tf2-stats.smx exists and is being disabled! ");
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
	SQL_TQuery(db,SQLErrorCheckCallback, query)
}

public playerstimeupdateondb()
{
	new String:clsteamId[MAX_LINE_WIDTH];
	new maxclients = GetMaxClients()
	new time = GetTime()
	for(new i=1; i <= maxclients; i++)
	{
		if (IsClientInGame(i))
		{
			GetClientAuthString(i, clsteamId, sizeof(clsteamId));
			new String:query[512];
			Format(query, sizeof(query), "UPDATE Player SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE STEAMID = '%s'",time ,clsteamId);
			SQL_TQuery(db,SQLErrorCheckCallback, query)
		}
	}
}

openDatabaseConnection()
{
	if (SQL_CheckConfig("tf2stats"))
	{
		new String:error[255]
		db = SQL_Connect("tf2stats",true,error, sizeof(error))
		if (db == INVALID_HANDLE)
		{
			PrintToServer("Failed to connect: %s", error)
		}
		else
		{
			LogMessage("DatabaseInit (CONNECTED) with db config");
			/* Set codepage to utf8 */

			decl String:query[255];
			Format(query, sizeof(query), "SET NAMES \"UTF8\"");
			if (!SQL_FastQuery(db, query))
			{
				LogError("Can't select character set (%s)", query);
			}

			/* End of Set codepage to utf8 */
		}
	}
	else
	{
		new String:error[255]
		sqllite = true
		db = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "tf2stats", error, sizeof(error), true, 0);
		if (db == INVALID_HANDLE)
		{
			LogMessage("Failed to connect: %s", error)
		}
		else
		{
			LogMessage("DatabaseInit SQLLITE (CONNECTED)");
		}
	}
}

createdb()
{
	if (!sqllite)
	{
		createdbplayer()
		createdbmap()
		createitemstabel()
		createdbkillog()
	}
	else
	{
		createdbplayersqllite()
	}
}

/*
2. Add new SQL DB queries
*/
createdbplayer()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player` (");
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
	len += Format(query[len], sizeof(query)-len, "`IPAddress` varchar(17) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`KW_frontier_justice` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_wrangler_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_maxgun` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_southern_hospitality` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_bleed_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_robot_arm_blender_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_taunt_guitar_kill` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_samrevolver` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`KW_jar` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`STEAMID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	SQL_FastQuery(db, query);
}

/*
3. Add new SQLite DB queries
*/
createdbplayersqllite()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` INTEGER,`PLAYTIME` INTEGER, `LASTONTIME` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` INTEGER, `Death` INTEGER, `KillAssist` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KillAssistMedic` INTEGER, `BuildSentrygun` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `BuildDispenser` INTEGER, `HeadshotKill` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KOSentrygun` INTEGER, `Domination` INTEGER, `Overcharge` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KOSapper` INTEGER, `BOTeleporterentrace` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KODispenser` INTEGER, `BOTeleporterExit` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `CPBlocked` INTEGER, `CPCaptured` INTEGER, `FileCaptured` INTEGER, `ADCaptured` INTEGER, `KOTeleporterExit` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KOTeleporterEntrace` INTEGER, `BOSapper` INTEGER, `Revenge` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_Axe` INTEGER, `KW_Bnsw` INTEGER, `KW_Bt` INTEGER, `KW_Bttl` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_Cg` INTEGER, `KW_Fsts` INTEGER, `KW_Ft` INTEGER, `KW_Gl` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_Kn` INTEGER, `KW_Mctte` INTEGER, `KW_Mgn` INTEGER, `KW_Ndl` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_Pistl` INTEGER, `KW_Rkt` INTEGER, `KW_Sg` INTEGER, `KW_Sky` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_Smg` INTEGER, `KW_Spr` INTEGER, `KW_Stgn` INTEGER, `KW_Wrnc` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_Sntry` INTEGER, `KW_Shvl` INTEGER, `KW_Ubersaw` INTEGER, `KW_Flaregun` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_Axtinguisher` INTEGER, `KW_taunt_pyro` INTEGER, `KW_taunt_heavy` INTEGER, `KW_gloves` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_backburner` INTEGER, `KW_natascha` INTEGER, `KW_blutsauger` INTEGER, `KW_deflect_rocket` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_deflect_promode` INTEGER, `KW_deflect_sticky` INTEGER, `KW_world` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_bat_wood` INTEGER, `player_stunned` INTEGER, `drunk_bonk` INTEGER, `player_stealsandvich` INTEGER, `chat_status` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_tf_projectile_arrow` INTEGER, `KW_ambassador` INTEGER, `KW_taunt_sniper` INTEGER, `KW_taunt_spy` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `player_extinguished` INTEGER, `player_teleported` INTEGER, `player_feigndeath` INTEGER, `KW_force_a_nature` INTEGER, `KW_sandman` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `K_backstab` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_compound_bow` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_scout` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_deflect_arrow` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_rocketlauncher_directhit` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_telefrag` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_deflect_flare` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_soldier` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_pickaxe` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_demoshield` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_sword` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_demoman` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_sticky_resistance` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_SntryL1` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_SntryL2` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_SntryL3` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_tribalkukri` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_battleaxe` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_ball` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_paintrain` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_sledgehammer` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_unique_pickaxe` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_pumpkin` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_goomba` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_frontier_justice` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_wrangler_kill` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_robot_arm` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_maxgun` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_southern_hospitality` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_bleed_kill` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_robot_arm_blender_kill` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_taunt_guitar_kill` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_samrevolver` INTEGER");
	len += Format(query[len], sizeof(query)-len, ", `KW_jar` INTEGER");
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
	len += Format(query[len], sizeof(query)-len, ") ENGINE = MYISAM ;");
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
	len += Format(query[len], sizeof(query)-len, " `KW_Sntry` int(11) NOT NULL , `KW_Shvl` int(11) NOT NULL , PRIMARY KEY (`NAME`));");
	SQL_FastQuery(db, query);
}

/*
4. Add point cvars - see step 1
*/

public convarcreating()
{
	//Generic kills and weapons
	pistolpoints = CreateConVar("rank_pistolpoints","3","Points:Generic - Pistol");
	maxgunPoints = CreateConVar("rank_maxgunpoints","3","Points:Generic - Max's Gun");
	shotgunpoints = CreateConVar("rank_shotgunpoints","2","Points:Generic - Shotgun");
	telefragpoints = CreateConVar("rank_telefragpoints","10","Points:Generic - Telefrag");
	goombapoints = CreateConVar("rank_goombastomp","6","Points:Generic - Goomba Stomp (mod)");
	pumpkinpoints = CreateConVar("rank_pumpkinpoints","2","Points:Generic - Pumpkin Bomb");
	worldpoints = CreateConVar("rank_worldpoints","4","Points:Generic - World Kill");
	stealsandvichpoints = CreateConVar("rank_stealsandvichpoints","1","Points:Generic - Steal Sandvich");
	extingushingpoints = CreateConVar("rank_extingushingpoints","1","Points:Generic - Extingush Player");
	bleed_killPoints = CreateConVar("rank_bleed_killpoints","3","Points:Generic - Bleed Kill"); //New v6:6
	//Scout
	scattergunpoints = CreateConVar("rank_scattergunpoints","2","Points:Scout - Scattergun");
	batpoints = CreateConVar("rank_batpoints","4","Points:Scout - Bat");
	ballpoints = CreateConVar("rank_ballpoints","5","Points:Scout - Baseball");
	bat_woodpoints = CreateConVar("rank_bat_woodpoints","4","Points:Scout - Sandman");
	force_a_naturepoints = CreateConVar("rank_force_a_naturepoints","2","Points:Scout - Force-a-Nature");
	sandmanpoints = CreateConVar("rank_sandmanpoints","3","Points:Scout - Sandman");
	taunt_scoutpoints = CreateConVar("rank_taunt_scoutpoints","6","Points:Scout - Sandman Taunt");
	//Soldier
	tf_projectile_rocketpoints = CreateConVar("rank_tf_projectile_rocketpoints","2","Points:Soldier - Rocket Launcher");
	shovelpoints = CreateConVar("rank_shovelpoints","4","Points:Soldier - Shovel");
	rocketlauncher_directhitpoints = CreateConVar("rank_rocketlauncher_directhitpoints","2","Points:Soldier - Direct Hit");
	pickaxepoints = CreateConVar("rank_pickaxepoints","4","Points:Soldier - Equalizer");
	taunt_soldierpoints = CreateConVar("rank_taunt_soldierpoints","15","Points:Soldier - Taunt");
	paintrainpoints = CreateConVar("rank_paintrainpoints","4","Points:Soldier - Paintrain");
	uniquepickaxepoints = CreateConVar("rank_pickaxepoints_lowhealth","6","Points:Soldier - Equalizer - Low Health (defunct)"); //Defunct
	//Pyro
	flamethrowerpoints = CreateConVar("rank_flamethrowerpoints","3","Points:Pyro - Flamethrower");
	backburnerpoints = CreateConVar("rank_backburnerpoints","2","Points:Pyro - Backburner");
	fireaxepoints = CreateConVar("rank_fireaxepoints","4","Points:Pyro - Fireaxe");
	flaregunpoints = CreateConVar("rank_flaregunpoints","3","Points:Pyro - Flaregun");
	axtinguisherpoints = CreateConVar("rank_axtinguisherpoints","4","Points:Pyro - Axtinguisher");
	taunt_pyropoints = CreateConVar("rank_taunt_pyropoints","6","Points:Pyro - Taunt");
	sledgehammerpoints = CreateConVar("rank_sledgehammerpoints","5","Points:Pyro - Sledgehammer");
	deflect_rocketpoints = CreateConVar("rank_deflect_rocketpoints","2","Points:Pyro - Deflected Rocket");
	deflect_promodepoints = CreateConVar("rank_deflect_promodepoints","2","Points:Pyro - Deflected ???");
	deflect_stickypoints = CreateConVar("rank_deflect_stickypoints","2","Points:Pyro - Deflected Sticky");
	deflect_arrowpoints = CreateConVar("rank_deflect_arrowpoints","6","Points:Pyro - Deflected Arrow");
	deflect_flarepoints = CreateConVar("rank_deflect_flarepoints","6","Points:Pyro - Deflected Flare");
	//Demo
	tf_projectile_pipepoints = CreateConVar("rank_tf_projectile_pipepoints","2","Points:Demo - Pipebomb Launcher");
	tf_projectile_pipe_remotepoints = CreateConVar("rank_tf_projectile_pipe_remotepoints","2","Points:Demo - Sticky Launcher");
	bottlepoints = CreateConVar("rank_bottlepoints","4","Points:Demo - Bottle");
	demoshieldpoints = CreateConVar("rank_demoshieldpoints","7","Points:Demo - Shield Charge");
	swordpoints = CreateConVar("rank_swordpoints","4","Points:Demo - Eyelander");
	taunt_demomanpoints = CreateConVar("rank_taunt_demomanpoints","9","Points:Demo - Taunt");
	sticky_resistancepoints = CreateConVar("rank_sticky_resistancepoints","2","Points:Demo - Scottish Resistance");
	battleaxepoints = CreateConVar("rank_battleaxepoints","4","Points:Demo - Skullcutter");
	//Heavy
	minigunpoints = CreateConVar("rank_minigunpoints","1","Points:Heavy - Minigun");
	fistspoints = CreateConVar("rank_fistspoints","4","Points:Heavy - Fist");
	glovespoints = CreateConVar("rank_killingglovespoints","4","Points:Heavy - KGBs");
	taunt_heavypoints = CreateConVar("rank_taunt_heavypoints","6","Points:Heavy - Taunt");
	nataschapoints = CreateConVar("rank_nataschapoints","1","Points:Heavy - Natascha");
	//Engi
	obj_sentrygunpoints = CreateConVar("rank_obj_sentrygunpoints","3","Points:Engineer - Sentry");
	wrenchpoints = CreateConVar("rank_wrenchpoints","7","Points:Engineer - Wrench");
	frontier_justicePoints = CreateConVar("rank_frontier_justicepoints","3","Points:Engineer - Frontier Justice"); //New v6:6
	wrangler_killPoints = CreateConVar("rank_wrangler_points","4","Points:Engineer - Wrangler"); //New v6:6
	robot_armPoints = CreateConVar("rank_robot_armpoints","5","Points:Engineer - Gunslinger"); //New v6:6
	southern_hospitalityPoints = CreateConVar("rank_southern_hospitalitypoints","6","Points:Engineer - Southern Hospitality"); //New v6:6
	robot_arm_blender_killPoints = CreateConVar("rank_robot_arm_blender_points","10","Points:Engineer - Gunslinger Taunt"); //New v6:6
	taunt_guitar_killPoints = CreateConVar("rank_taunt_guitar_points","10","Points:Engineer - Taunt Guitar"); //New v6:6
	//Medic
	bonesawpoints = CreateConVar("rank_bonesawpoints","4","Points:Medic - Bonesaw");
	syringegun_medicpoints = CreateConVar("rank_syringegun_medicpoints","2","Points:Medic - Needle Gun");
	killasimedipoints = CreateConVar("rank_killasimedicpoints","2","Points:Medic - Kill Asist");
	overchargepoints = CreateConVar("rank_overchargepoints","1","Points:Medic - Ubercharge");
	ubersawpoints = CreateConVar("rank_ubersawpoints","4","Points:Medic - Ubersaw");
	blutsaugerpoints = CreateConVar("rank_blutsaugerpoints","2","Points:Medic - Blutsauger");
	//Sniper
	sniperriflepoints = CreateConVar("rank_sniperriflepoints","1","Points:Sniper - Rifle");
	smgpoints = CreateConVar("rank_smgpoints","3","Points:Sniper - SMG");
	clubpoints = CreateConVar("rank_clubpoints","4","Points:Sniper - Kukri");
	woodknifepoints = CreateConVar("rank_woodknifepoints","4","Points:Sniper - Shiv");
	tf_projectile_arrowpoints = CreateConVar("rank_tf_projectile_arrowpoints","1","Points:Sniper - Huntsman");
	taunt_sniperpoints = CreateConVar("rank_taunt_sniperpoints","6","Points:Sniper - Huntsman Taunt");
	compound_bowpoints = CreateConVar("rank_compound_bowpoints","2","Points:Sniper - Huntsman");
	//Spy
	revolverpoints = CreateConVar("rank_revolverpoints","3","Points:Spy - Revolver");
	knifepoints = CreateConVar("rank_knifepoints","2","Points:Sniper - Knife");
	ambassadorpoints = CreateConVar("rank_ambassadorpoints","2","Points:Spy - Ambassador");
	taunt_spypoints = CreateConVar("rank_taunt_spypoints","6","Points:Spy - Knife Taunt");
	samrevolverpoints = CreateConVar("rank_samrevolverpoints","3","Points:Spy - Sam's Revolver");
	//Events
	killsapperpoints = CreateConVar("rank_killsapperpoints","1","Points:Generic - Sapper Kill");
	killteleinpoints = CreateConVar("rank_killteleinpoints","1","Points:Generic - Tele Kill");
	killteleoutpoints = CreateConVar("rank_killteleoutpoints","1","Points:Generic - Tele Kill");
	killdisppoints = CreateConVar("rank_killdisppoints","2","Points:Generic - Dispensor Kill");
	killsentrypoints = CreateConVar("rank_killsentrypoints","3","Points:Generic - Sentry Kill");
	//Other cvars
	showrankonroundend = CreateConVar("rank_showrankonroundend","1","Shows Top 10 on Roundend");
	removeoldplayers = CreateConVar("rank_removeoldplayers","1","Enable automatic removal of players who don't connect within a specific number of days. (Old records will be removed on round end) ");
	removeoldplayersdays = CreateConVar("rank_removeoldplayersdays","28","Number of days to keep players in database (since last connection)");
	killasipoints = CreateConVar("rank_killasipoints","2","Points:Generic - Kill Asist");
	Capturepoints = CreateConVar("rank_capturepoints","2","Points:Generic - Capture Points");
	Captureblockpoints = CreateConVar("rank_blockcapturepoints","4","Points:Generic - Capture Block Points");
	FileCapturepoints = CreateConVar("rank_filecapturepoints","4","Points:Generic - Capture Points");
	removeoldmaps = CreateConVar("rank_removeoldmaps","1","Enable Automatic Removing Maps who wasn't played a specific time on every Roundend");
	removeoldmapssdays = CreateConVar("rank_removeoldmapsdays","14","The time in days after a map get removed, min 1 day");
	showrankonconnect = CreateConVar("rank_show","4","Show on connect, 0=disabled, 1=clientchat, 2=allchat, 3=panel, 4=panel + all chat");
	webrank = CreateConVar("rank_webrank","0","Enable/Disable Webrank");
	webrankurl = CreateConVar("rank_webrankurl","","Webrank URL, example: http://yoursite.com/stats/", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	neededplayercount = CreateConVar("rank_neededplayers","4","How many clients are needed to start ranking");
	disableafterwin = CreateConVar("rank_disableafterroundwin","1","Disable kill counting after round ends");
	pointmsg = CreateConVar("rank_pointmsg","2","Show point earned message to: 0 = disabled, 1 = all, 2 = only who earned");
	CV_chattag = CreateConVar("rank_chattag","RANK","Set the Chattag");
	CV_showchatcommands = CreateConVar("rank_showchatcommands","1","show chattags 1=enable 0=disable");
	ConnectSound = CreateConVar("rank_connectsound","1","Play a sound when a player connects? 1= Yes 0 = No");
	ConnectSoundFile = CreateConVar("rank_connectsoundfile","buttons/blip1.wav","Sound to play when a player connects (plays for all players)");
	showranktoall = CreateConVar("rank_showranktoall","1","Show the rank to everybody");
	ignorebots = CreateConVar("rank_ignorebots","1","Give bots points? 1/0 - 0 allows bots to get points");
	logips = CreateConVar("rank_logips","1","Log player's ip addresses 1/0"); //new v6:6
	//Death points
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
	CV_extendetlogging = CreateConVar("rank_extendetlogging", "0", "1 Enables / 0 Disables Extended Logging")
	CV_extlogcleanuptime = CreateConVar("rank_extlogcleanuptime", "72", "Defines the time until a entry in the Kill-log gets removed in hours 0 = disabled")
	CV_rank_enable = CreateConVar("rank_enable", "1", "1 Enables / 0 Disables gaining points")
	//---========---
}

public createeventhooks()
{
	HookEvent("player_death", Event_PlayerDeath)
	HookEvent("player_builtobject", Event_player_builtobject)
	HookEvent("object_destroyed", Event_object_destroyed)
	HookEvent("teamplay_round_win", Event_round_end)
	HookEvent("teamplay_point_captured", Event_point_captured)
	HookEvent("ctf_flag_captured", Event_flag_captured)
	HookEvent("teamplay_capture_blocked", Event_capture_blocked)
	HookEvent("player_invulned", Event_player_invulned)
	HookEvent("teamplay_round_active", Event_teamplay_round_active)
	HookEvent("arena_round_start", Event_teamplay_round_active)
	HookEvent("item_found", Event_item_found)
	HookEvent("player_stealsandvich", Event_player_stealsandvich)
	HookEvent("player_teleported", Event_player_teleported)
	HookEvent("player_extinguished", Event_player_extinguished)
}

public Event_player_stealsandvich(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "target"))
		if (client != 0)
		{
			new String:steamId[MAX_LINE_WIDTH];
			GetClientAuthString(client, steamId, sizeof(steamId));
			decl String:query[512];
			new pointvalue = GetConVarInt(stealsandvichpoints)
			Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, player_stealsandvich = player_stealsandvich + 1 WHERE STEAMID = '%s'",pointvalue, steamId);
			sessionpoints[client] = sessionpoints[client] + pointvalue
			SQL_TQuery(db,SQLErrorCheckCallback, query)
			new pointmsgval = GetConVarInt(pointmsg)
			if (pointmsgval >= 1)
			{
				new String:medicname[MAX_LINE_WIDTH];
				GetClientName(client,medicname, sizeof(medicname))
				new playeruid = GetEventInt(event, "owner")
				new playerid = GetClientOfUserId(playeruid)
				new String:playername[MAX_LINE_WIDTH];
				GetClientName(playerid,playername, sizeof(playername))
				if (pointmsgval == 1)
				{
					PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for stealing a Sandvich %s",CHATTAG,medicname,pointvalue,playername)
				}
				else
				{
					if (cookieshowrankchanges[client])
					{
						PrintToChat(client,"\x04[\x03%s\x04]\x01 you got %i points for stealing a Sandvich %s",CHATTAG,pointvalue,playername)
					}
				}
			}
			PrintToChat(client,"Event_player_stealsandvich")
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
			GetClientAuthString(client, steamIdassister, sizeof(steamIdassister));
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
				SQL_TQuery(db,SQLErrorCheckCallback, query)
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
		new victimId = GetEventInt(event, "userid")
		new attackerId = GetEventInt(event, "attacker")
		new assisterId = GetEventInt(event, "assister")
		new deathflags = GetEventInt(event, "death_flags")
		new bool:nofakekill = true

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
					GetClientAuthString(assister, steamIdassister, sizeof(steamIdassister));
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
								SQL_TQuery(db,SQLErrorCheckCallback, query)
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
								SQL_TQuery(db,SQLErrorCheckCallback, query)
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
							SQL_TQuery(db,SQLErrorCheckCallback, query)
						}
					}
					if (df_assisterrevenge)
					{
						Format(query, sizeof(query), "UPDATE Player SET Revenge = Revenge + 1 WHERE STEAMID = '%s'", steamIdassister);
						if (isbotassist == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query)
						}
					}
				}

				new String:weapon[64]
				GetEventString(event, "weapon_logclassname", weapon, sizeof(weapon))
				PrintToConsole(attacker,"[TF2 Stats Debug] Weapon %s",weapon)

				new String:steamIdattacker[MAX_LINE_WIDTH];
				new String:steamIdavictim[MAX_LINE_WIDTH];
				GetClientAuthString(attacker, steamIdattacker, sizeof(steamIdattacker));
				GetClientAuthString(victim, steamIdavictim, sizeof(steamIdavictim));

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

			/*
			5. Add point-adding queries
			*/
				new diepointsvalue
				new TFClassType:class = TF2_GetPlayerClass(victim)
				switch(class)
				{
					case TFClass_Sniper:
					{
						diepointsvalue = GetConVarInt(Sniperdiepoints)
					}
					case TFClass_Medic:
					{
						diepointsvalue = GetConVarInt(Medicdiepoints)
					}
					case TFClass_Soldier:
					{
						diepointsvalue = GetConVarInt(Soldierdiepoints)
					}
					case TFClass_Pyro:
					{
						diepointsvalue = GetConVarInt(Pyrodiepoints)
					}
					case TFClass_DemoMan:
					{
						diepointsvalue = GetConVarInt(Demomandiepoints)
					}
					case TFClass_Engineer:
					{
						diepointsvalue = GetConVarInt(Engineerdiepoints)
					}
					case TFClass_Spy:
					{
						diepointsvalue = GetConVarInt(Spydiepoints)
					}
					case TFClass_Scout:
					{
						diepointsvalue = GetConVarInt(Scoutdiepoints)
					}
					case TFClass_Heavy:
					{
						diepointsvalue = GetConVarInt(Heavydiepoints)
					}
				}
				if (nofakekill == true)
				{
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS - %i, Death = Death + 1 WHERE STEAMID = '%s'",diepointsvalue ,steamIdavictim);

					sessiondeath[victim]++
					sessionpoints[victim] = sessionpoints[victim] - diepointsvalue

				}
				else
				{
					Format(query, sizeof(query), "UPDATE Player SET player_feigndeath = player_feigndeath + 1 WHERE STEAMID = '%s'",steamIdavictim);
				}
				if (isvicbot == false) //player killed is not a bot, so death++ and points -X
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query)
				}
				if (pointmsgval >= 1)
				{
					new String:victimname[MAX_LINE_WIDTH];
					GetClientName(victim,victimname, sizeof(victimname))

					if (pointmsgval == 1)
					{
						PrintToChatAll("\x04[\x03%s\x04]\x01 %s lost %i points for dying",CHATTAG,victimname,diepointsvalue)
					}
					else
					{
						if (cookieshowrankchanges[victim])
						{
							if (nofakekill == true && isbot == false)
							{
								PrintToChat(victim,"\x04[\x03%s\x04]\x01 you lost %i points for dying",CHATTAG,diepointsvalue)
							}
						}
					}
				}

				if (df_killerdomination)
				{
					Format(query, sizeof(query), "UPDATE Player SET Domination = Domination + 1 WHERE STEAMID = '%s'", steamIdattacker);
					if (isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				if (df_killerrevenge)
				{
					Format(query, sizeof(query), "UPDATE Player SET Revenge = Revenge + 1 WHERE STEAMID = '%s'", steamIdattacker);
					if (isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
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
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "bat", false) == 0)
				{
					pointvalue = GetConVarInt(batpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bt = KW_Bt + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "pistol_scout", false) == 0)
				{
					pointvalue = GetConVarInt(pistolpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Pistl = KW_Pistl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "tf_projectile_rocket", false) == 0)
				{
					pointvalue = GetConVarInt(tf_projectile_rocketpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Rkt = KW_Rkt + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "shotgun_soldier", false) == 0)
				{
					pointvalue = GetConVarInt(shotgunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "shovel", false) == 0)
				{
					pointvalue = GetConVarInt(shovelpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Shvl = KW_Shvl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "flamethrower", false) == 0)
				{
					pointvalue = GetConVarInt(flamethrowerpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ft = KW_Ft + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "fireaxe", false) == 0)
				{
					pointvalue = GetConVarInt(fireaxepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Axe = KW_Axe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "shotgun_pyro", false) == 0)
				{
					pointvalue = GetConVarInt(shotgunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "tf_projectile_pipe", false) == 0)
				{
					pointvalue = GetConVarInt(tf_projectile_pipepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Gl = KW_Gl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "tf_projectile_pipe_remote", false) == 0)
				{
					pointvalue = GetConVarInt(tf_projectile_pipe_remotepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sky = KW_Sky + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "bottle", false) == 0)
				{
					pointvalue = GetConVarInt(bottlepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bttl = KW_Bttl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "minigun", false) == 0)
				{
					pointvalue = GetConVarInt(minigunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_CG = KW_CG + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "fists", false) == 0)
				{
					pointvalue = GetConVarInt(fistspoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Fsts = KW_Fsts + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "shotgun_hwg", false) == 0)
				{
					pointvalue = GetConVarInt(shotgunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "obj_sentrygun", false) == 0)
				{
					pointvalue = GetConVarInt(obj_sentrygunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL1 = KW_SntryL1 + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "obj_sentrygun2", false) == 0)
				{
					pointvalue = GetConVarInt(obj_sentrygunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL2 = KW_SntryL2 + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "obj_sentrygun3", false) == 0)
				{
					pointvalue = GetConVarInt(obj_sentrygunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Sntry = KW_Sntry + 1, KW_SntryL3 = KW_SntryL3 + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "wrench", false) == 0)
				{
					pointvalue = GetConVarInt(wrenchpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Wrnc = KW_Wrnc + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "pistol", false) == 0)
				{
					pointvalue = GetConVarInt(pistolpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Pistl = KW_Pistl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "shotgun_primary", false) == 0)
				{
					pointvalue = GetConVarInt(shotgunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Stgn = KW_Stgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "bonesaw", false) == 0)
				{
					pointvalue = GetConVarInt(bonesawpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Bnsw = KW_Bnsw + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "syringegun_medic", false) == 0)
				{
					pointvalue = GetConVarInt(syringegun_medicpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ndl = KW_Ndl + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "club", false) == 0)
				{
					pointvalue = GetConVarInt(clubpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Mctte = KW_Mctte + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "smg", false) == 0)
				{
					pointvalue = GetConVarInt(smgpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Smg = KW_Smg + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "sniperrifle", false) == 0)
				{
					pointvalue = GetConVarInt(sniperriflepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Spr = KW_Spr + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				//Random insert of engi update shizz;
				else if (strcmp(weapon[0], "samrevolver", false) == 0)
				{
					pointvalue = GetConVarInt(samrevolverpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_samrevolver = KW_samrevolver + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "frontier_justice", false) == 0)
				{
					pointvalue = GetConVarInt(frontier_justicePoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_frontier_justice = KW_frontier_justice + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "wrangler_kill", false) == 0)
				{
					pointvalue = GetConVarInt(wrangler_killPoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_wrangler_kill = KW_wrangler_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "robot_arm", false) == 0)
				{
					pointvalue = GetConVarInt(robot_armPoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm = KW_robot_arm + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "maxgun", false) == 0)
				{
					pointvalue = GetConVarInt(maxgunPoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_maxgun = KW_maxgun + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "southern_hospitality", false) == 0)
				{
					pointvalue = GetConVarInt(southern_hospitalityPoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_southern_hospitality = KW_southern_hospitality + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "bleed_kill", false) == 0)
				{
					pointvalue = GetConVarInt(bleed_killPoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bleed_kill = KW_bleed_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "robot_arm_blender_kill", false) == 0)
				{
					pointvalue = GetConVarInt(robot_arm_blender_killPoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_robot_arm_blender_kill = KW_robot_arm_blender_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_guitar_kill", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_guitar_killPoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_guitar_kill = KW_taunt_guitar_kill + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				// /engi
				else if (strcmp(weapon[0], "revolver", false) == 0)
				{
					pointvalue = GetConVarInt(revolverpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Mgn = KW_Mgn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "knife", false) == 0)
				{
					isknife = true
					pointvalue = GetConVarInt(knifepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Kn = KW_Kn + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "ubersaw", false) == 0)
				{
					pointvalue = GetConVarInt(ubersawpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Ubersaw = KW_Ubersaw + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "rocketlauncher_directhit", false) == 0)
				{
					pointvalue = GetConVarInt(rocketlauncher_directhitpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_rocketlauncher_directhit = KW_rocketlauncher_directhit + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "telefrag", false) == 0)
				{
					pointvalue = GetConVarInt(telefragpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_telefrag = KW_telefrag + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "deflect_flare", false) == 0)
				{
					pointvalue = GetConVarInt(deflect_flarepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_flare = KW_deflect_flare + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_soldier", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_soldierpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_soldier = KW_taunt_soldier + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "goomba", false) == 0)
				{
					pointvalue = GetConVarInt(goombapoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_goomba = KW_goomba + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "pickaxe", false) == 0)
				{
					pointvalue = GetConVarInt(pickaxepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pickaxe = KW_pickaxe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "demoshield", false) == 0)
				{
					pointvalue = GetConVarInt(demoshieldpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_demoshield = KW_demoshield + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "sword", false) == 0)
				{
					pointvalue = GetConVarInt(swordpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sword = KW_sword + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_demoman", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_demomanpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_demoman = KW_taunt_demoman + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "sticky_resistance", false) == 0)
				{
					pointvalue = GetConVarInt(sticky_resistancepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sticky_resistance = KW_sticky_resistance + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "flaregun", false) == 0)
				{
					pointvalue = GetConVarInt(flaregunpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Flaregun = KW_Flaregun + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "axtinguisher", false) == 0)
				{
					pointvalue = GetConVarInt(axtinguisherpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_Axtinguisher = KW_Axtinguisher + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_pyro", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_pyropoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_pyro = KW_taunt_pyro + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "gloves", false) == 0)
				{
					pointvalue = GetConVarInt(glovespoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_gloves = KW_gloves + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_heavy", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_heavypoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_heavy = KW_taunt_heavy + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "backburner", false) == 0)
				{
					pointvalue = GetConVarInt(backburnerpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_backburner = KW_backburner + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "natascha", false) == 0)
				{
					pointvalue = GetConVarInt(nataschapoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_natascha = KW_natascha + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				//Begin custom weapon update
				else if (strcmp(weapon[0], "tribalkukri", false) == 0)
				{
					pointvalue = GetConVarInt(woodknifepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tribalkukri = KW_tribalkukri + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "battleaxe", false) == 0)
				{
					pointvalue = GetConVarInt(battleaxepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_battleaxe = KW_battleaxe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "ball", false) == 0)
				{
					pointvalue = GetConVarInt(ballpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ball = KW_ball + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "paintrain", false) == 0)
				{
					pointvalue = GetConVarInt(paintrainpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_paintrain = KW_paintrain + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "sledgehammer", false) == 0)
				{
					pointvalue = GetConVarInt(sledgehammerpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sledgehammer = KW_sledgehammer + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "unique_pickaxe", false) == 0)
				{
					pointvalue = GetConVarInt(uniquepickaxepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_unique_pickaxe = KW_unique_pickaxe + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "tf_pumpkin_bomb", false) == 0)
				{
					pointvalue = GetConVarInt(pumpkinpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pumpkin = KW_pumpkin + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				//End custom weapon update
				else if (strcmp(weapon[0], "blutsauger", false) == 0)
				{
					pointvalue = GetConVarInt(blutsaugerpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_blutsauger = KW_blutsauger + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "deflect_rocket", false) == 0)
				{
					pointvalue = GetConVarInt(deflect_rocketpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_rocket = KW_deflect_rocket + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "deflect_promode", false) == 0)
				{
					pointvalue = GetConVarInt(deflect_promodepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_promode = KW_deflect_promode + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "deflect_sticky", false) == 0)
				{
					pointvalue = GetConVarInt(deflect_stickypoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_sticky = KW_deflect_sticky + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "world", false) == 0)
				{
					pointvalue = GetConVarInt(worldpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_world = KW_world + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "bat_wood", false) == 0)
				{
					pointvalue = GetConVarInt(bat_woodpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_bat_wood = KW_bat_wood + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "tf_projectile_arrow", false) == 0)
				{
					pointvalue = GetConVarInt(tf_projectile_arrowpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tf_projectile_arrow = KW_tf_projectile_arrow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "ambassador", false) == 0)
				{
					pointvalue = GetConVarInt(ambassadorpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ambassador = KW_ambassador + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_sniper", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_sniperpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_sniper = KW_taunt_sniper + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_spy", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_spypoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_spy = KW_taunt_spy + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "force_a_nature", false) == 0)
				{
					pointvalue = GetConVarInt(force_a_naturepoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_force_a_nature = KW_force_a_nature + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "sandman", false) == 0)
				{
					pointvalue = GetConVarInt(sandmanpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sandman = KW_sandman + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "compound_bow", false) == 0)
				{
					pointvalue = GetConVarInt(compound_bowpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_compound_bow = KW_compound_bow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "taunt_scout", false) == 0)
				{
					pointvalue = GetConVarInt(taunt_scoutpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_taunt_scout = KW_taunt_scout + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "deflect_arrow", false) == 0)
				{
					pointvalue = GetConVarInt(deflect_arrowpoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deflect_arrow = KW_deflect_arrow + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
				}
				else if (strcmp(weapon[0], "jar", false) == 0)
				{
					pointvalue = GetConVarInt(killasipoints)
					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_jar = KW_jar + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
					if (nofakekill == true && isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}
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
				else
				{
					decl String:file[PLATFORM_MAX_PATH];
					BuildPath(Path_SM, file, sizeof(file), "logs/TF2STATS_WEAPONERRORS.log");
					LogToFile(file,"Weapon: %s", weapon)
				}
				new String:additional[MAX_LINE_WIDTH]
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
								SQL_TQuery(db,SQLErrorCheckCallback, query)
							}
						}
					}
					else if (customkill == 1)
					{
						Format(query, sizeof(query), "UPDATE Player SET HeadshotKill = HeadshotKill + 1 WHERE STEAMID = '%s'",steamIdattacker);
						Format(additional, sizeof(additional), "with a Headshot")
						if (isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query)
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
					if (pointvalue != 0)
					{
						if (pointmsgval == 1)
						{
							PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for killing %s %s",CHATTAG,attackername,pointvalue,victimname,additional)
						}
						else
						{
							if (cookieshowrankchanges[attacker])
							{
								PrintToChat(attacker,"\x04[\x03%s\x04]\x01 you got %i points for killing %s %s",CHATTAG,pointvalue,victimname,additional)
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
		new object = GetEventInt(event, "object")
		GetClientAuthString(user, steamIdbuilder, sizeof(steamIdbuilder));
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

		if (object == 0)
		{
			Format(query, sizeof(query), "UPDATE Player SET BuildDispenser = BuildDispenser + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query)
			}
		}
		else if (object == 1)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOTeleporterentrace = BOTeleporterentrace + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query)
			}
		}
		else if (object == 1)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOTeleporterExit = BOTeleporterExit + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query)
			}
		}
		else if (object == 2)
		{
			Format(query, sizeof(query), "UPDATE Player SET BuildSentrygun = BuildSentrygun + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query)
			}
		}
		else if (object == 3)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOSapper = BOSapper + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query)
			}
		}
	}
}

public Action:Event_object_destroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		if (GetEventInt(event, "userid") != GetEventInt(event, "attacker"))
		{
			new userId = GetEventInt(event, "attacker")
			new object = GetEventInt(event, "objecttype")
			new user = GetClientOfUserId(userId)
			new String:steamIdattacker[MAX_LINE_WIDTH];
			GetClientAuthString(user, steamIdattacker, sizeof(steamIdattacker));
			new String:query[512];
			new pointvalue = 0
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

			if (object == 0)
			{
				pointvalue = GetConVarInt(killdisppoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KODispenser = KODispenser + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query)
				}
			}
			else if (object == 1)
			{
				pointvalue = GetConVarInt(killteleinpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOTeleporterEntrace = KOTeleporterEntrace + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query)
				}
			}
			else if (object == 1)
			{
				pointvalue = GetConVarInt(killteleoutpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOTeleporterExit = KOTeleporterExit + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query)
				}
			}
			else if (object == 2)
			{
				pointvalue = GetConVarInt(killsentrypoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOSentrygun = KOSentrygun + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query)
				}
			}
			else if (object == 3)
			{
				pointvalue = GetConVarInt(killsapperpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOSapper = KOSapper + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query)
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

public Action:Command_Say(client, args)
{
	new String:text[512], String:command[512];
	new bool:chatcommand = false
	new startidx = 0;

	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
		startidx += 4;

	if (strcmp(text[startidx], "!Rank", false) == 0)
	{
		echo_rank(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "Rank", false) == 0)
	{
		echo_rank(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "Top10", false) == 0)
	{
		top10pnl(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "Top", false) == 0)
	{
		top10pnl(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "rankinfo", false) == 0)
	{
		rankinfo(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "players", false) == 0)
	{
		listplayers(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "session", false) == 0)
	{
		session(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "webtop", false) == 0)
	{
		webtop(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "webrank", false) == 0)
	{
		webranking(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "hidepoints", false) == 0)
	{
		sayhidepoints(client)
		chatcommand = true
	}
	else if (strcmp(text[startidx], "unhidepoints", false) == 0)
	{
		sayunhidepoints(client)
		chatcommand = true
	}

	if (chatcommand == false)
	{
		return Plugin_Continue;
	}
	else
	{
		if (showchatcommands == true)
		{
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Handled;
		}
	}
}

public Action:rankinfo(client)
{
	new Handle:infopanel = CreatePanel();
	SetPanelTitle(infopanel, "About TF2Rank:")
	DrawPanelText(infopanel, "Plugin Coded by DarthNinja & R-Hehl")
	DrawPanelText(infopanel, "Visit AlliedModders.net")
	DrawPanelText(infopanel, "Contact DarthNinja for")
	DrawPanelText(infopanel, "Feature Requests or Bug reports")
	new String:value[128];
	new String:tmpdbtype[10]

	if (sqllite)
	{
		Format(tmpdbtype, sizeof(tmpdbtype), "SQLLITE");
	}
	else
	{
		Format(tmpdbtype, sizeof(tmpdbtype), "MYSQL");
	}

	Format(value, sizeof(value), "Version %s DB Typ %s",PLUGIN_VERSION ,tmpdbtype);
	DrawPanelText(infopanel, value)
	DrawPanelItem(infopanel, "Close")

	SendPanelToClient(infopanel, client, InfoPanelHandler, 20)

	CloseHandle(infopanel)

	return Plugin_Handled
}

public InfoPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
	}
	else if (action == MenuAction_Cancel)
	{
	}
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
	roundactive = false

	if (GetConVarInt(showrankonroundend) == 1)
	{
		oldshowranktoallvalue = GetConVarBool(showranktoall)
		SetConVarBool(showranktoall,false,false,false)
		showeallrank()
		CreateTimer(5.0, resetshow2alltimer)
	}
	if (GetConVarInt(removeoldplayers) == 1)
	{
		removetooldplayers()
	}

	if (!sqllite)
	{
		if (extendedloggingenabled)
		{
			removeoldkilllogentrys()
		}
		if (GetConVarInt(removeoldmaps) == 1)
		{
			removetooldmaps()
		}
	}

	if (GetConVarInt(disableafterwin) == 1)
	{
		rankingactive = false
		if (rankingenabled)
		{
			PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Disabled: round end",CHATTAG)
		}
	}
}

public Action:Event_teamplay_round_active(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundactive = true
	if (GetConVarInt(disableafterwin) == 1)
	{
		if (GetConVarInt(neededplayercount) <= GetClientCount(true))
		{
			rankingactive = true
			if (rankingenabled)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Enabled: round start",CHATTAG)
			}
		}
	}
}

public showeallrank()
{
	new l_maxplayers
	l_maxplayers = GetMaxClients()

	for (new i=1; i<=l_maxplayers; i++)
	{
		if (IsClientInGame(i))
		{
			new String:steamIdclient[MAX_LINE_WIDTH];
			GetClientAuthString(i, steamIdclient, sizeof(steamIdclient));
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
		SQL_TQuery(db,SQLErrorCheckCallback, query)
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
		SQL_TQuery(db,SQLErrorCheckCallback, query)
	}
}

public Event_point_captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		if (cpmap)
		{
			new team = GetEventInt(event, "team")
			new l_maxplayers
			new pointmsgval = GetConVarInt(pointmsg)
			new pointvalue = GetConVarInt(Capturepoints)
			l_maxplayers = GetMaxClients()

			for (new i=1; i<=l_maxplayers; i++)
			{
				if (IsClientInGame(i))
				{
					if (GetClientTeam(i) == team)
					{
						new String:steamIdattacker[MAX_LINE_WIDTH];
						GetClientAuthString(i, steamIdattacker, sizeof(steamIdattacker));
						new String:query[512];
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

						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, CPCaptured = CPCaptured + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

						if (isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query)
						}

						sessionpoints[i] = sessionpoints[i] + pointvalue

						if (pointmsgval >= 1)
						{
							if (cookieshowrankchanges[i])
							{
								new String:teamname[MAX_LINE_WIDTH];
								GetTeamName(team,teamname, sizeof(teamname) );
								PrintToChat(i,"\x04[\x03%s\x04]\x01 Team %s got %i points for Capturing",CHATTAG,teamname,pointvalue)
							}
						}
					}
				}
			}
		}
	}
}

public Event_flag_captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new team = GetEventInt(event, "capping_team")
		new l_maxplayers
		l_maxplayers = GetMaxClients()
		new pointmsgval = GetConVarInt(pointmsg)
		new pointvalue = GetConVarInt(FileCapturepoints)
		for (new i=1; i<=l_maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == team)
				{
					new String:steamIdattacker[MAX_LINE_WIDTH];
					GetClientAuthString(i, steamIdattacker, sizeof(steamIdattacker));
					new String:query[512];
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

					Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, FileCaptured = FileCaptured + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

					if (isbot == false)
					{
						SQL_TQuery(db,SQLErrorCheckCallback, query)
					}

					sessionpoints[i] = sessionpoints[i] + pointvalue

					if (pointmsgval >= 1)
					{
						if (cookieshowrankchanges[i])
						{
							new String:teamname[MAX_LINE_WIDTH];
							GetTeamName(team,teamname, sizeof(teamname) );
							PrintToChat(i,"\x04[\x03%s\x04]\x01 Team %s got %i points for Capturing",CHATTAG,teamname,pointvalue)
						}
					}
				}
			}
		}
	}
}

public Event_capture_blocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		if (cpmap)
		{
			new blocker = GetEventInt(event, "blocker")
			new blockerclient = GetClientOfUserId(blocker)
			if (blockerclient > 0)
			{
				new String:steamIdattacker[MAX_LINE_WIDTH];

				GetClientAuthString(blockerclient, steamIdattacker, sizeof(steamIdattacker));
				new String:query[512];
				new pointvalue = GetConVarInt(Captureblockpoints)
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
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, CPBlocked = CPBlocked + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);
				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query)
				}
				sessionpoints[blockerclient] = sessionpoints[blockerclient] + pointvalue

				new pointmsgval = GetConVarInt(pointmsg)
				if (pointmsgval >= 1)
				{
					new String:playername[MAX_LINE_WIDTH];
					GetClientName(blockerclient,playername, sizeof(playername))
					if (pointmsgval == 1)
					{
						PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for Blocking Capture",CHATTAG,playername,pointvalue)
					}
					else
					{
						if (cookieshowrankchanges[blockerclient])
						{
							PrintToChat(blockerclient,"\x04[\x03%s\x04]\x01 you got %i points for Blocking Capture",CHATTAG,pointvalue)
						}
					}
				}
			}
		}
	}
}

public OnMapStart()
{
	MapInit()
	new String:name[MAX_LINE_WIDTH];
	GetCurrentMap(name,MAX_LINE_WIDTH);

	if (StrContains(name, "cp_", false) != -1)
	{
		cpmap = true
	}
	else
	{
		if (StrContains(name, "tc_", false) != -1)
		{
			cpmap = true
		}
		else
		{
			if (StrContains(name, "arena_", false) != -1)
			{
				cpmap = true
			}
			else
			{
				cpmap = false
			}
		}
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
			SQL_TQuery(db,SQLErrorCheckCallback, query)

			mapisset = 1
		}
	}
}

/*
############ No longer needed :: replace with TF2_GetClass ###########
stock TF_GetClass(client){
	if (client >= 0)
	{
	return GetEntData(ResourceEnt, TF_classoffsets + (client*4), 4);
}
	return 0
}
*/

stock FindResourceObject()
{
	new i, String:classname[64];

	//Isen't there a easier way?
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
		SQL_TQuery(db,SQLErrorCheckCallback, query)
	}
}

public updateplayername(client)
{
// !NAME!
	new String:steamId[MAX_LINE_WIDTH];
	GetClientAuthString(client, steamId, sizeof(steamId));
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
	Format(query, sizeof(query), "UPDATE Player SET NAME = `%s` WHERE STEAMID = `%s`",name ,steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	new String:ip[20]
	GetClientIP(client,ip,sizeof(ip),true)
	new String:ClientSteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));

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

public Action:Menu_adm(client, args)
{
	new Handle:menu = CreateMenu(MenuHandlerrnkadm)
	SetMenuTitle(menu, "Rank Admin Menu")
	AddMenuItem(menu, "reset", "Reset Rank")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)

	return Plugin_Handled
}

public MenuHandlerrnkadm(Handle:menu, MenuAction:action, param1, param2)
{
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))

		if (strcmp(info,"rank",false))
		{
			resetdb()
		}
	}

	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public resetdb()
{
	new String:query[512];
	Format(query, sizeof(query), "TRUNCATE TABLE Player");
	SQL_TQuery(db,SQLErrorCheckCallback, query)

	if (!sqllite)
	{
		Format(query, sizeof(query), "TRUNCATE TABLE Map");
		SQL_TQuery(db,SQLErrorCheckCallback, query)
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
		GetClientAuthString(i, steamId, sizeof(steamId));
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
	InitializeClientonDB(client)
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
			if (roundactive)
			{
				rankingactive = true
				PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Enabled: enough players",CHATTAG)
			}
		}
	}
}

public InitializeClientonDB(client)
{
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:buffer[255];

	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
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

	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
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
		LogError("Query failed! %s", error);
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
		LogError("Query failed! %s", error);
	}
	else
	{
		new String:clientname[MAX_LINE_WIDTH];
		GetClientName( client, clientname, sizeof(clientname) );
		ReplaceString(clientname, sizeof(clientname), "'", "");
		ReplaceString(clientname, sizeof(clientname), "<?", "");
		ReplaceString(clientname, sizeof(clientname), "?>", "");
		ReplaceString(clientname, sizeof(clientname), "<?PHP", "");
		ReplaceString(clientname, sizeof(clientname), "<?php", "");
		ReplaceString(clientname, sizeof(clientname), "<", "[");
		ReplaceString(clientname, sizeof(clientname), ">", "]");
		ReplaceString(clientname, sizeof(clientname), ",", ".");
		new String:ClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
		//Stupid buffer, its all your fault! !255
		new String:buffer[1025];
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
				Format(buffer, sizeof(buffer), "INSERT INTO Player VALUES('%s','%s',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);", ClientSteamID,clientname )
				SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			}
			PrintToChatAll("\x04[\x03%s\x04]\x01 Welcome %s",CHATTAG, clientname)
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
6. SQLite - add one 0, for each new entry (see about 25 lines above)
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
		LogError("Query failed! %s", error);
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
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0)
		}

		new String:country[3]
		new String:ip[20]
		GetClientIP(client,ip,sizeof(ip),true)
		GeoipCode2(ip,country)

		if (GetConVarInt(showrankonconnect) == 1)
		{
			PrintToChat(client,"Your Rank: %i out of %i", onconrank[client],rankedclients)
		}
		else if (GetConVarInt(showrankonconnect) == 2)
		{
			new String:clientname[MAX_LINE_WIDTH];
			GetClientName( client, clientname, sizeof(clientname) );
			PrintToChatAll("\x04[\x03%s\x04]\x01 %s connected from %s. \x04[\x03Rank: %i out of %i\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients)
		}
		else if (GetConVarInt(showrankonconnect) == 3)
		{
			ConRankPanel(client)
		}
		else if (GetConVarInt(showrankonconnect) == 4)
		{
			new String:clientname[MAX_LINE_WIDTH];
			GetClientName( client, clientname, sizeof(clientname) );
			PrintToChatAll("\x04[\x03%s\x04]\x01 %s connected from %s. \x04[\x03Rank: %i out of %i\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients)
			ConRankPanel(client)
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
		LogError("Query failed! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0)
			new String:ConUsrSteamID[MAX_LINE_WIDTH];
			new String:buffer[255];
			GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
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
		LogError("Query failed! %s", error);
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
		LogError("Query failed! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			playerrank[client] = SQL_FetchInt(hndl,0)
		}

		new String:ConUsrSteamID[MAX_LINE_WIDTH];
		new String:buffer[255];
		GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
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
		LogError("Query failed! %s", error);
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

public Action:SessionPanel(client,kills,death,killassi,playtime)
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
		GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));

		Format(showrankurl, sizeof(showrankurl), "%s/id/%s?time=%i",rankurl,UsrSteamID,GetTime())
		PrintToConsole(client, "RANK MOTDURL %s", showrankurl)
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
		GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));

		Format(showrankurl, sizeof(showrankurl), "%s/top?time=%i",rankurl,GetTime())
		PrintToConsole(client, "RANK MOTDURL %s", showrankurl)
		ShowMOTDPanel(client, "Rank:", showrankurl, 2)
	}
}

public rankpanel(client, const String:steamid[])
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
		LogError("Query failed! %s", error);
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
		LogError("Query failed! %s", error);
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
		LogError("Query failed! %s", error);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			reqplayerrank[client] = SQL_FetchInt(hndl,0)
		}

		new String:ConUsrSteamID[MAX_LINE_WIDTH];
		new String:buffer[255];
		GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
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
		LogError("Query failed! %s", error);
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
			SQL_FetchString(hndl,4, ranknamereq[client] , 32)
		}

		RankPanel(client,kills,death,killassi,playtime)
	}
}

public Action:RankPanel(client,kills,death,killassi,playtime)
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

	if (GetConVarBool(showranktoall))
	{
		PrintToChatAll("\x04[\x03%s\x04]\x01 %s has Rank %i out of %i Players",CHATTAG,ranknamereq[client],reqplayerrank[client],rankedclients)
	}

	CloseHandle(rnkpanel)

	return Plugin_Handled
}

	public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public echo_rank(client)
{
	if(IsClientInGame(client))
	{
		new String:steamId[MAX_LINE_WIDTH]
		GetClientAuthString(client, steamId, sizeof(steamId));
		rankpanel(client, steamId)
	}
}

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
		LogError("Query failed! %s", error);
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
	TagsCheck("n1grank");
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
	len += Format(query[len], sizeof(query)-len, "(`name` TEXT, `datatxt` TEXT, `dataint` INTEGER);");
	SQL_TQuery(db, T_CheckDBUptodate1, query)
}

public T_CheckDBUptodate1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
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
		LogError("Query failed! %s", error);
	}
	else
	{
		if (!SQL_GetRowCount(hndl))
		{
			createdb()

			new String:buffer[255];
			Format(buffer, sizeof(buffer), "INSERT INTO data (`name`,`dataint`) VALUES ('dbversion',%i)", DBVERSION)
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
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bat_wood INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_stunned INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add drunk_bonk INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_stealsandvich INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add chat_status INTEGER;")
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
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_tf_projectile_arrow INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ambassador INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_sniper INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_spy INTEGER;")
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
					Format(buffer, sizeof(buffer), "ALTER table Player add player_extinguished INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_teleported INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add player_feigndeath INTEGER;")
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
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_force_a_nature INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sandman INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 5 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}

			if (tmpdbversion <= 5)
			{
				if (!sqllite)
				{
					createitemstabel()
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
					Format(buffer, sizeof(buffer), "ALTER table Player add K_backstab INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_compound_bow INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_scout INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_deflect_arrow INTEGER;")
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
					Format(buffer, sizeof(buffer), "ALTER table Player add K_jar INTEGER;")
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
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_rocketlauncher_directhit INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_telefrag INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_deflect_flare INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_soldier INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_pickaxe INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_demoshield INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sword INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_demoman INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sticky_resistance INTEGER;")
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
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_tribalkukri INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_battleaxe INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_ball INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_paintrain INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_sledgehammer INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_unique_pickaxe INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_pumpkin INTEGER;")
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
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_goomba INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_SntryL1 INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_SntryL2 INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_SntryL3 INTEGER;")
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
					len += Format(query[len], sizeof(query)-len, "ADD `IPAddress` varchar(17) NOT NULL DEFAULT '0',");
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
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_frontier_justice INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_wrangler_kill INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_robot_arm INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_maxgun INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_southern_hospitality INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_bleed_kill INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_robot_arm_blender_kill INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_taunt_guitar_kill INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "ALTER table Player add KW_samrevolver INTEGER;")
					SQL_TQuery(db, SQLErrorCheckCallback, buffer);
					Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 12 where `name` = 'dbversion';");
					SQL_TQuery(db,SQLErrorCheckCallback, buffer)
				}
			}
		}
		initonlineplayers()
	}
}

/*
7. Add DB update queries above
*/
public OnClientDisconnect(client)
{
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

public OnAllPluginsLoaded()
{
	if (LibraryExists("pluginautoupdate"))
	{
		// only register myself if the autoupdater is loaded
		// AutoUpdate_AddPlugin(const String:url[], const String:file[], const String:version[])
		AutoUpdate_AddPlugin("darthninja.com", "/sm/tf2stats/plugin.xml", PLUGIN_VERSION);
	}
}

public OnPluginEnd()
{
	if (LibraryExists("pluginautoupdate"))
	{
		AutoUpdate_RemovePlugin();
	}
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    MarkNativeAsOptional("AutoUpdate_AddPlugin");
    MarkNativeAsOptional("AutoUpdate_RemovePlugin");
    return true;
}

createitemstabel()
{
	new len = 0;
	decl String:query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `founditems`");
	len += Format(query[len], sizeof(query)-len, " (`ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` VARCHAR( 25 ) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ACTUALTIME` INT NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ITEM` VARCHAR( 50 ) NOT NULL DEFAULT '0'");
	len += Format(query[len], sizeof(query)-len, ") ENGINE = MYISAM ;");
	SQL_FastQuery(db, query);
}

public Action:Event_item_found(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!sqllite)
	{
		new userid = GetEventInt(event, "player")
		new String:steamid[64];
		GetClientAuthString(userid, steamid, sizeof(steamid));
		new String:item[64]
		GetEventString(event, "item", item, sizeof(item))
		new time = GetTime()
		new String:query[512];

		Format(query, sizeof(query), "INSERT INTO founditems (`STEAMID`,`ACTUALTIME`,`ITEM`) VALUES ('%s','%i','%s')", steamid, time, item)
		SQL_TQuery(db,SQLErrorCheckCallback, query)
	}
}

public Action:Event_player_teleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new String:steamId[MAX_LINE_WIDTH]
		GetClientAuthString(GetClientOfUserId(GetEventInt(event, "userid")), steamId, sizeof(steamId));
		new String:query[512];
		Format(query, sizeof(query), "UPDATE Player SET player_teleported = player_teleported + 1 WHERE STEAMID = '%s'",steamId);
		SQL_TQuery(db,SQLErrorCheckCallback, query)
	}
}

public Action:Event_player_extinguished(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive && rankingenabled)
	{
		new healer = GetClientOfUserId(GetEventInt(event, "healer"))
		if (healer > 0)
		{
			new eventvictim = GetEventInt(event, "victim")
			new victim = GetClientOfUserId(eventvictim)
			new pointvalue = GetConVarInt(extingushingpoints)
			new String:steamId[MAX_LINE_WIDTH]
			new String:healername[MAX_LINE_WIDTH];
			GetClientName( healer, healername, sizeof(healername));

			new String:extingushedname[MAX_LINE_WIDTH];

			if (victim > 0)
			{
				GetClientName( victim, extingushedname, sizeof(extingushedname));
			}

			GetClientAuthString(healer, steamId, sizeof(steamId));
			new String:query[512];
			Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, player_extinguished = player_extinguished + 1 WHERE STEAMID = '%s'",pointvalue ,steamId);
			SQL_TQuery(db,SQLErrorCheckCallback, query)


			new pointmsgval = GetConVarInt(pointmsg)
			if (pointmsgval == 1)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for extingushing %s",CHATTAG,healername,pointvalue,extingushedname)
			}
			else
			{
				if (cookieshowrankchanges[healer])
				{
					PrintToChat(healer,"\x04[\x03%s\x04]\x01 you got %i points for extingushing %s",CHATTAG,pointvalue,extingushedname)
					PrintToConsole(healer,"[RANKDEBUG] event victim value = %i , client = %i",eventvictim,victim )
				}
			}
		}
	}
}

public sayhidepoints(client)
{
	new String:steamId[MAX_LINE_WIDTH]
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET chat_status = '2' WHERE STEAMID = '%s'",steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	cookieshowrankchanges[client] = false
}

public sayunhidepoints(client)
{
	new String:steamId[MAX_LINE_WIDTH]
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET chat_status = '1' WHERE STEAMID = '%s'",steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	cookieshowrankchanges[client] = true
}
