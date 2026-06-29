#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <geoip>
#include <adminmenu>
#undef REQUIRE_PLUGIN
//#include <autoupdate>

#define PLUGIN_VERSION "10.0"
#define DBVERSION 39

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

new Handle:plgnversion = INVALID_HANDLE;

new Handle:TeleUsePoints = INVALID_HANDLE;

new bool:rankingenabled = false;

new Handle:showranktoall  = INVALID_HANDLE;
new Handle:v_TimeOffset = INVALID_HANDLE;
new Handle:showrankonroundend = INVALID_HANDLE;
new Handle:roundendranktochat = INVALID_HANDLE;
new Handle:showrankonconnect = INVALID_HANDLE;
new Handle:showSessionStatsOnRoundEnd = INVALID_HANDLE;

new Handle:removeoldplayers = INVALID_HANDLE;
new Handle:removeoldplayersdays = INVALID_HANDLE;
new Handle:removeoldmaps = INVALID_HANDLE;
new Handle:removeoldmapssdays = INVALID_HANDLE;

new Handle:Capturepoints = INVALID_HANDLE;
new Handle:FileCapturepoints = INVALID_HANDLE;
new Handle:CTFCapPlayerPoints = INVALID_HANDLE;
new Handle:CPCapPlayerPoints = INVALID_HANDLE;
new Handle:Captureblockpoints = INVALID_HANDLE;

new Handle:webrank = INVALID_HANDLE;
new Handle:webrankurl = INVALID_HANDLE;

new Handle:neededplayercount = INVALID_HANDLE;
new Handle:disableafterwin = INVALID_HANDLE;

new Handle:ConnectSoundFile	= INVALID_HANDLE;
new Handle:ConnectSound = INVALID_HANDLE;
new Handle:CountryCodeHandler = INVALID_HANDLE;
new Handle:ConnectSoundTop10 = INVALID_HANDLE;
new Handle:ConnectSoundFileTop10 = INVALID_HANDLE;

new Handle:logips = INVALID_HANDLE;

new Handle:ignorebots = INVALID_HANDLE;
new Handle:ignoreTeamKills = INVALID_HANDLE;

new Handle:ShowTeleNotices = INVALID_HANDLE;

new Handle:big_stun_points = INVALID_HANDLE;

new Handle:stun_points = INVALID_HANDLE;

//Some chat cvars
//--------------------
new Handle:ShowEnoughPlayersNotice = INVALID_HANDLE;
new Handle:ShowRoundEnableNotice = INVALID_HANDLE;


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

new bool:oldshowranktoallvalue = true;


new g_iLastRankCheck[MAXPLAYERS+1] = 0;
new Handle:v_RankCheckTimeout = INVALID_HANDLE;


//We make a two-dimensional array of the following structure
// {name, points, description}
// ------------- START OF WEAPON ARRAY 
new String:myWeapons[][][] = {
{"katana","8","Points:Samurai - Half-Zatoichi (Katana)","KW_katana"},
{"pistol","3","Points:Generic - Pistol","KW_pistol"},
{"maxgun","3","Points:Generic - The Lugermorph","KW_maxgun"},
{"shotgun","2","Points:Generic - Shotgun","KW_shotgun"},
{"telefrag","10","Points:Generic - Telefrag","KW_telefrag"},
{"goombastomp","6","Points:Generic - Goomba Stomp (mod)","KW_goombastomp"},
{"pumpkin","2","Points:Generic - Pumpkin Bomb","KW_pumpkin"},
{"world","4","Points:Generic - World Kill","KW_world"},
{"stealsandvich","1","Points:Generic - Steal Sandvich","KW_stealsandvich"},
{"extingushing","1","Points:Generic - Extingush Player","KW_extingushing"},
{"bleed_kill","3","Points:Generic - Bleed Kill","KW_bleed_kill"},
{"fryingpan","4","Points:Generic - Frying Pan","KW_fryingpan"},
{"headshot_bonus","2","Points:Generic - Extra points to award for headshots","KW_headshot_bonus"},
{"saxxy","4","Points:Generic Weapon - Saxxy","KW_saxxy"},
{"objector","4","Points:Generic Weapon - Conscientious Objector","KW_objector"},
{"eyeboss_kill","10","Points: Monoculus Kill Assist","KW_eyeboss_kill"},
{"eyeboss_stun","5","Points: Monoculus Stun","KW_eyeboss_stun"},
{"scattergun","2","Points:Scout - Scattergun","KW_scattergun"},
{"bat","4","Points:Scout - Bat","KW_bat"},
{"ball","5","Points:Scout - Baseball","KW_ball"},
{"stun","1","Points: Scout - Stun Player","KW_stun"},
{"big_stun","2","Points:Scout - Big Stun","KW_big_stun"},
{"bat_wood","3","Points:Scout - Sandman","KW_bat_wood"},
{"force_a_nature","2","Points:Scout - Force-a-Nature","KW_force_a_nature"},
{"sandman","3","Points:Scout - Sandman","KW_sandman"},
{"taunt_scout","6","Points:Scout - Sandman Taunt","KW_taunt_scout"},
{"short_stop","2","Points:Scout - ShortStop","KW_short_stop"},
{"holy_mackerel","4","Points:Scout - Holy Mackerel","KW_holy_mackerel"},
{"candycane","4","Points:Scout - Candy Cane","KW_candycane"},
{"boston_basher","6","Points:Scout - Boston Basher","KW_boston_basher"},
{"sunbat","6","Points:Scout - Sun-on-a-Stick","KW_sunbat"},
{"warfan","6","Points:Scout - Fan O'War","KW_warfan"},
{"witcher_sword","6","Points:Scout - Three-Rune Blade","KW_witcher_sword"},
{"soda_popper","2","Points:Scout - The Soda Popper","KW_soda_popper"},
{"winger","3","Points:Scout - The Winger","KW_winger"},
{"atomizer","4","Points:Scout - The Atomizer","KW_atomizer"},
{"unarmedcombat","4","Points:Scout - Unarmed Combat","KW_unarmedcombat"},
{"wrapassassin","6","Points:Scout - The Wrap Assassin","KW_wrapassassin"},
{"brawlerblaster","3","Points:Scout - Baby Face's Blaster","KW_brawlerblaster"},
{"pbpp","3","Points:Scout - Pretty Boy's Pocket Pistol","KW_pbpp"},
{"tf_projectile_rocket","2","Points:Soldier - Rocket Launcher","KW_tf_projectile_rocket"},
{"shovel","4","Points:Soldier - Shovel","KW_shovel"},
{"rocketlauncher_directhit","2","Points:Soldier - Direct Hit","KW_rocketlauncher_directhit"},
{"pickaxe","4","Points:Soldier - Equalizer","KW_pickaxe"},
{"taunt_soldier","15","Points:Soldier - Grenade Taunt","KW_taunt_soldier"},
{"paintrain","4","Points:Soldier - Paintrain","KW_paintrain"},
{"pickaxe_lowhealth","6","Points:Soldier - Equalizer - Low Health (defunct)","KW_pickaxe_lowhealth"},
{"blackbox","2","Points:Soldier - Black Box","KW_blackbox"},
{"worms_grenade","15","Points:Soldier - Grenade Taunt (With worms hat)","KW_worms_grenade"},
{"liberty_launcher","2","Points:Soldier - Liberty Launcher","KW_liberty_launcher"},
{"reserve_shooter","2","Points:Soldier - Reserve Shooter","KW_reserve_shooter"},
{"disciplinary_action","5","Points:Soldier - Disciplinary Action","KW_disciplinary_action"},
{"market_gardener","5","Points:Soldier - Market Gardener","KW_market_gardener"},
{"mantreads","15","Points:Soldier - Mantreads","KW_mantreads"},
{"mangler","2","Points:Soldier - Cow Mangler","KW_mangler"},
{"bison","3","Points:Soldier - Righteous Bison","KW_bison"},
{"the_original","3","Points:Soldier - The Original","KW_the_original"},
{"beggarsbazooka","4","Points:Soldier - Beggar's Bazooka","KW_beggarsbazooka"},
{"pickaxe_escape","6","Points:Soldier - The Escape Plan","KW_pickaxe_escape"},
{"flamethrower","3","Points:Pyro - Flamethrower","KW_flamethrower"},
{"backburner","2","Points:Pyro - Backburner","KW_backburner"},
{"fireaxe","4","Points:Pyro - Fireaxe","KW_fireaxe"},
{"flaregun","4","Points:Pyro - Flaregun","KW_flaregun"},
{"axtinguisher","4","Points:Pyro - Axtinguisher","KW_axtinguisher"},
{"taunt_pyro","6","Points:Pyro - Taunt","KW_taunt_pyro"},
{"sledgehammer","5","Points:Pyro - Sledgehammer","KW_sledgehammer"},
{"deflect_rocket","2","Points:Pyro - Deflected Rocket","KW_deflect_rocket"},
{"deflect_promode","2","Points:Pyro - Deflected ???","KW_deflect_promode"},
{"deflect_sticky","2","Points:Pyro - Deflected Sticky","KW_deflect_sticky"},
{"deflect_arrow","15","Points:Pyro - Deflected Arrow","KW_deflect_arrow"},
{"deflect_flare","8","Points:Pyro - Deflected Flare","KW_deflect_flare"},
{"powerjack","4","Points:Pyro - PowerJack","KW_powerjack"},
{"degreaser","3","Points:Pyro - Degreaser","KW_degreaser"},
{"backscratcher","5","Points:Pyro - Back Scratcher","KW_backscratcher"},
{"lava_axe","6","Points:Pyro - Sharpened Volcano Fragment","KW_lava_axe"},
{"maul","5","Points:Pyro - The Maul","KW_maul"},
{"detonator","5","Points:Pyro - The Detonator","KW_detonator"},
{"mailbox","4","Points:Pyro - The Postal Pummeler","KW_mailbox"},
{"mangler_reflect", "8", "Points:Pyro - Deflected Cow Mangler","KW_mangler_reflect"},
{"phlogistinator", "2", "Points:Pyro - The Phlogistinator","KW_phlogistinator"},
{"manmelter", "3", "Points:Pyro - The Manmelter","KW_manmelter"},
{"thirddegree", "5", "Points:Pyro - The Third Degree","KW_thirddegree"},
{"rainblower", "3", "Points:Pyro - The Rainblower","KW_rainblower"},
{"scorchedshot", "5", "Points:Pyro - The scorchedshot","KW_scorchedshot"},
{"Lollichop", "4", "Points:Pyro - Lollichop","KW_Lollichop"},
{"armageddon", "15", "Points:Pyro - Armageddon taunt","KW_armageddon"},
{"tf_projectile_pipe","2","Points:Demo - Pipebomb Launcher","KW_tf_projectile_pipe"},
{"tf_projectile_pipe_remote","2","Points:Demo - Sticky Launcher","KW_tf_projectile_pipe_remote"},
{"bottle","4","Points:Demo - Bottle","KW_bottle"},
{"demoshield","10","Points:Demo - Shield Charge","KW_demoshield"},
{"sword","4","Points:Demo - Eyelander","KW_sword"},
{"taunt_demoman","9","Points:Demo - Taunt","KW_taunt_demoman"},
{"sticky_resistance","2","Points:Demo - Scottish Resistance","KW_sticky_resistance"},
{"battleaxe","4","Points:Demo - Skullcutter","KW_battleaxe"},
{"headtaker","5","Points:Demo - Unusual Headtaker Axe","KW_headtaker"},
{"ullapool_caber","6","Points:Demo - Ullapool Caber","KW_ullapool_caber"},
{"ullapool_explode","5","Points:Demo - Ullapool Caber Explosion","KW_ullapool_explode"},
{"lochnload","4","Points:Demo - Loch-n-Load","KW_lochnload"},
{"gaelicclaymore","4","Points:Demo - Claidheamh Mor","KW_gaelicclaymore"},
{"persian_persuader","4","Points:Demo - Persian Persuader","KW_persian_persuader"},
{"splendid_screen","8","Points:Demo - Splendid Screen Shield Charge","KW_splendid_screen"},
{"golfclub","4","Points:Demo - Nessie's Nine Iron","KW_golfclub"},
{"scottish_handshake","4","Points:Demo - Scottish Handshake","KW_scottish_handshake"},
{"minigun","1","Points:Heavy - Minigun","KW_minigun"},
{"fists","4","Points:Heavy - Fist","KW_fists"},
{"killinggloves","4","Points:Heavy - KGBs","KW_killinggloves"},
{"taunt_heavy","6","Points:Heavy - Taunt","KW_taunt_heavy"},
{"natascha","1","Points:Heavy - Natascha","KW_natascha"},
{"urgentgloves","6","Points:Heavy - Gloves of Running Urgently","KW_urgentgloves"},
{"ironcurtain","1","Points:Heavy - Iron Curtain","KW_ironcurtain"},
{"brassbeast","1","Points:Heavy - Brass Beast","KW_brassbeast"},
{"warriors_spirit","4","Points:Heavy - Warrior's Spirit","KW_warriors_spirit"},
{"fistsofsteel","4","Points:Heavy - Fists of Steel","KW_fistsofsteel"},
{"tomislav","1","Points:Heavy - Tomislav","KW_tomislav"},
{"family_business","3","Points:Heavy - Family Business","KW_family_business"},
{"eviction_notice","4","Points:Heavy - Eviction Notice","KW_eviction_notice"},
{"holiday_punch","4","Points:Heavy - The Holiday Punch","KW_holiday_punch"},
{"apocofist","4","Points:Heavy - The Apocofists","KW_apocofist"},
{"minisentry","4","Points:Engineer - Mini-Sentry","KW_minisentry"},
{"wrench","7","Points:Engineer - Wrench","KW_wrench"},
{"frontier_justice","3","Points:Engineer - Frontier Justice","KW_frontier_justice"},
{"wrangler","4","Points:Engineer - Wrangler","KW_wrangler"},
{"robot_arm","5","Points:Engineer - Gunslinger","KW_robot_arm"},
{"southern_hospitality","6","Points:Engineer - Southern Hospitality","KW_southern_hospitality"},
{"robot_arm_blender","10","Points:Engineer - Gunslinger Taunt","KW_robot_arm_blender"},
{"taunt_guitar","10","Points:Engineer - Taunt Guitar","KW_taunt_guitar"},
{"robot_arm_combo_kill","20","Points:Engineer - Gunslinger 3-Hit Combo Kill","KW_robot_arm_combo_kill"},
{"jag","8","Points:Engineer - The Jag","KW_jag"},
{"tele_use","1","Points:Engineer - Teleporter Use","KW_tele_use"},
{"widowmaker","3","Points:Engineer - Widowmaker","KW_widowmaker"},
{"shortcircuit","30","Points:Engineer - The Short Circuit","KW_shortcircuit"},
{"pomson","4","Points:Engineer - The Pomson 6000","KW_pomson"},
{"eureka_effect","7","Points:Engineer - The Eureka Effect","KW_eureka_effect"},
{"bonesaw","6","Points:Medic - Bonesaw","KW_bonesaw"},
{"syringegun_medic","4","Points:Medic - Syringe Gun","KW_syringegun_medic"},
{"killasimedic","3","Points:Medic - Kill Asist","KW_killasimedic"},
{"overcharge","2","Points:Medic - Ubercharge","KW_overcharge"},
{"ubersaw","6","Points:Medic - Ubersaw","KW_ubersaw"},
{"blutsauger","4","Points:Medic - Blutsauger","KW_blutsauger"},
{"battleneedle","6","Points:Medic - Vita-Saw","KW_battleneedle"},
{"amputator","6","Points:Medic - Amputator","KW_amputator"},
{"mediccrossbow","5","Points:Medic - Amputator","KW_mediccrossbow"},
{"overdose","4","Points:Medic - The Overdose","KW_overdose"},
{"solemn_vow","6","Points:Medic - The Solemn Vow","KW_solemn_vow"},
{"sniperrifle","1","Points:Sniper - Rifle","KW_sniperrifle"},
{"smg","3","Points:Sniper - SMG","KW_smg"},
{"club","4","Points:Sniper - Kukri","KW_club"},
{"woodknife","4","Points:Sniper - Shiv","KW_woodknife"},
{"tf_projectile_arrow","1","Points:Sniper - Huntsman","KW_tf_projectile_arrow"},
{"taunt_sniper","6","Points:Sniper - Huntsman Taunt","KW_taunt_sniper"},
{"compound_bow","2","Points:Sniper - Huntsman","KW_compound_bow"},
{"sleeper","2","Points:Sniper - Sydney Sleeper","KW_sleeper"},
{"bushwacka","4","Points:Sniper - Bushwacka","KW_bushwacka"},
{"bazaar_bargain","1","Points:Sniper - Bazaar Bargain","KW_bazaar_bargain"},
{"shahanshah", "5", "Points:Sniper - Shahanshah","KW_shahanshah"},
{"machina", "2", "Points:Sniper - Machina","KW_machina"},
{"machina_doublekill", "5", "Points:Sniper - Machina Double Kill","KW_machina_doublekill"},
{"hitmansheatmaker", "1", "Points:Sniper - Hitman's Heatmaker","KW_hitmansheatmaker"},
{"cleanerscarbine", "2", "Points:Sniper - Cleaner's Carbine","KW_cleanerscarbine"},
{"revolver","3","Points:Spy - Revolver","KW_revolver"},
{"knife","4","Points:Spy - Knife","KW_knife"},
{"ambassador","4","Points:Spy - Ambassador","KW_ambassador"},
{"taunt_spy","12","Points:Spy - Knife Taunt","KW_taunt_spy"},
{"samrevolver","3","Points:Spy - Sam's Revolver","KW_samrevolver"},
{"eternal_reward","4","Points:Spy - Eternal Reward","KW_eternal_reward"},
{"letranger","3","Points:Spy - L'Etranger","KW_letranger"},
{"kunai","4","Points:Spy - Conniver's Kunai","KW_kunai"},
{"enforcer","3","Points:Spy - The Enforcer","KW_enforcer"},
{"big_earner","3","Points:Spy - The Big Earner","KW_big_earner"},
{"diamondback","3","Points:Spy - The Diamondback","KW_diamondback"},
{"wanga_prick","4","Points:Spy - Wanga Prick","KW_wanga_prick"},
{"sharp_dresser","4","Points:Spy - The Sharp Dresser","KW_sharp_dresser"},
{"spy_cicle","4","Points:Spy - The Spy-cicle","KW_spy_cicle"},
{"blackrose","4","Points:Spy - The Black Rose","KW_blackrose"},
{"long_heatmaker","1","Points:Heavy - The Huo-Long Heater","KW_long_heatmaker"},
{"annihilator","3","Points:Pyro - The Neon Annihilator","KW_annihilator"},
{"guillotine","4","Points:Scout - The Flying Guillotine","KW_guillotine"},
{"recorder","1","Points:Spy - The Red-Tape Recorder","KW_recorder"},
{"the_rescue_ranger","1","Points:Engineer - Rescue Ranger","KW_the_rescue_ranger"},
{"loose_cannon_impact","1","Points:Demoman - Loose Cannon","KW_loose_cannon_impact"},
{"awper_hand","1","Points:Sniper - AWPer Hand","KW_awper_hand"},
{"freedom_staff","1","Points:Freedom Staff","KW_freedom_staff"},
{"skullbat","1","Points:Bat Outta Hell","KW_skullbat"},
{"wrenchmotron","1","Points:Engineer - Eureka Effect","KW_wrenchmotron"},
{"obj_sentrygun1","3","Points: Engineer - Sentry - Level 1", "KW_obj_sentrygun1"},
{"obj_sentrygun2","3","Points: Engineer - Sentry - Level 2", "KW_obj_sentrygun2"},
{"obj_sentrygun3","3","Points: Engineer - Sentry - Level 3", "KW_obj_sentrygun3"}
};
// ------- END OF WEAPON ARRAY



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

new maxents, ResourceEnt, maxplayers;

new sessionpoints[MAXPLAYERS + 1]
new sessionkills[MAXPLAYERS + 1]
new sessiondeath[MAXPLAYERS + 1]
new sessionassi[MAXPLAYERS + 1]

new TotalHealing[MAXPLAYERS+1] = 0;
//iHealing

new overchargescoring[MAXPLAYERS + 1]
new Handle:overchargescoringtimer[MAXPLAYERS + 1]
new Handle:pointmsg = INVALID_HANDLE;

new bool:g_IsRoundActive = true
//new bool:callKDeath[MAXPLAYERS+1] = false

new Handle:CV_chattag = INVALID_HANDLE;
new Handle:CV_showchatcommands = INVALID_HANDLE;
new String:CHATTAG[MAX_LINE_WIDTH]

new bool:cookieshowrankchanges[MAXPLAYERS + 1]
new bool:showchatcommands = true

new Handle:CV_extendetlogging = INVALID_HANDLE
new Handle:CV_extlogcleanuptime = INVALID_HANDLE
new Handle:CV_rank_enable = INVALID_HANDLE

//Other - Menus
//--------------------
new g_iMenuTarget[MAXPLAYERS+1];


//Other - Kills
//--------------------

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
new Handle:extingushingpoints = INVALID_HANDLE;
new Handle:stealsandvichpoints = INVALID_HANDLE;

//Halloween 2011
new Handle:EyeBossKillAssist = INVALID_HANDLE;
new Handle:EyeBossStun = INVALID_HANDLE;



public Plugin:myinfo =
{
	name = "[TF2] Test Data Structures",
	author = "Sobuno",
	description = "TF2 Player Stats",
	version = "0.12",
	url = "http://forums.alliedmods.net/showthread.php?t=109006"
};

public OnPluginStart()
{
	versioncheck();
	openDatabaseConnection();
	createCvars();
	
	AutoExecConfig(true, "sobuno", "");
	AutoExecConfig(false, "sobuno");
	
	CreateConVar("sm_tf_stats_version", PLUGIN_VERSION, "TF2 Player Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
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
			GetClientAuthString(i, clsteamId, sizeof(clsteamId));
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
		
		createdbtables();
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
		Format(query, sizeof(query), "SET NAMES \"UTF8\"");	/* Set codepage to utf8 */
		
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
		createdbplayer()
		createdbmap()
		CreateItemsTable()
		createdbkillog()
	}
	else
	{
		createdbplayer()
	}
}


public createCvars()
{

	//Creating config variables for the points for each weapon
	new numWeapons = sizeof(myWeapons);
	for(new i = 0; i<numWeapons;i++)
	{
		//PrintToServer(myWeapons[i][1]);
		//Creating config variables for the points for each weapon
		new String:pointCvar[255];
		Format(pointCvar, sizeof(pointCvar), "%s%s%s", "rank_", myWeapons[i][0], "_points");
		CreateConVar(pointCvar, myWeapons[i][1], myWeapons[i][2]);
	}
	
	//Other config variables
	headshotpoints = CreateConVar("rank_headshot_bonuspoints","2","Points:Generic - Extra points to award for headshots");
	
	killasimedipoints = CreateConVar("rank_killasimedicpoints","3","Points:Medic - Kill Asist");
	
	//Events
	killsapperpoints = CreateConVar("rank_killsapperpoints","1","Points:Generic - Sapper Kill");
	killteleinpoints = CreateConVar("rank_killteleinpoints","1","Points:Generic - Tele Kill");
	killteleoutpoints = CreateConVar("rank_killteleoutpoints","1","Points:Generic - Tele Kill");
	killdisppoints = CreateConVar("rank_killdisppoints","2","Points:Generic - Dispensor Kill");
	killsentrypoints = CreateConVar("rank_killsentrypoints","3","Points:Generic - Sentry Kill");
	overchargepoints = CreateConVar("rank_overchargepoints","2","Points:Medic - Ubercharge");

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

	CountryCodeHandler = CreateConVar("rank_connectcountry", "3", "How to display connecting player's country, 0 = Don't show country, 1 = two char: (US, CA, etc), 2 = three char: (USA, CAN, etc), 3 = Full country name: (United States, etc)", 0, true, 0.0, true, 3.0);
	showranktoall = CreateConVar("rank_showranktoall","1","Show player's rank to everybody");
	ignorebots = CreateConVar("rank_ignorebots","1","Give bots points? 1/0 - 0 allows bots to get points");
	ignoreTeamKills = CreateConVar("rank_ignoreteamkills", "1", "1 = Teamkills are ignored, 0 = Teamkills are tracked", 0, true, 0.0, true, 1.0);
	ShowTeleNotices = CreateConVar("rank_show_tele_point_notices", "1", "1 = Tell the engi when a player uses their tele, 0 = Don't show the message", 0, true, 0.0, true, 1.0);
	logips = CreateConVar("rank_logips","1","Log player's ip addresses 1/0"); //new v6:6

	ShowEnoughPlayersNotice = CreateConVar("rank_show_player_count_notice", "1", "Set to 0 to hide the 'there are enough players' messages", 0, true, 0.0, true, 1.0);
	ShowRoundEnableNotice = CreateConVar("rank_show_round_enable_disable_notice", "1", "Set to 0 to hide the rank enabled/disabled due to round start/end notices", 0, true, 0.0, true, 1.0);

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

createdbplayer()
{
	PrintToServer("Starting creation of player table");
	new len = 0;
	decl String:query[20000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player` (");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) PRIMARY KEY,");
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
	len += Format(query[len], sizeof(query)-len, "`IPAddress` varchar(50) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_extinguished` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_teleported` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_feigndeath` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_stunned` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`drunk_bonk` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`player_stealsandvich` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`chat_status` int(11) NOT NULL default '0',");
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
	len += Format(query[len], sizeof(query)-len, "`EyeBossStuns` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`EyeBossKills` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`K_backstab` int(11) NOT NULL default '0',");
	
	//Creating SQL statements for each weapon
	new numWeapons = sizeof(myWeapons);
	for(new i = 0; i<numWeapons;i++)
	{
		len += Format(query[len], sizeof(query)-len, "`%s` int(11) NOT NULL default '0',", myWeapons[i][3]);
	}
	
	len += Format(query[len], sizeof(query)-len, "`TotalPlayersTeleported` int(11) NOT NULL default '0')");
	
	//len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`STEAMID`))");
	//len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	
	//new Handle:queryHndl = SQL_Query(db, query);
	//if (queryHndl == INVALID_HANDLE)
	//{
	//	new String:error[255]
	//	SQL_GetError(db, error, sizeof(error))
	//	PrintToServer("Failed to query (error: %s)", error)
	//}
	
	//CloseHandle(queryHndl);
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
		GetClientAuthString(client, SteamID, sizeof(SteamID));
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
		GetClientAuthString(client, SteamID, sizeof(SteamID));
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
			GetClientAuthString(attacker, steamId, sizeof(steamId));
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
			GetClientAuthString(client, steamId, sizeof(steamId));
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
					new String:pointCvar[255];
					Format(pointCvar, sizeof(pointCvar), "%s%s%s", "rank_", weapon[0], "_points");
					new Handle:weaponCvar = FindConVar(pointCvar);
					if(weaponCvar != INVALID_HANDLE) //The weapon actually exists in our database
					{
						pointvalue = GetConVarInt(weaponCvar);
						new String:weaponTableName[255];
						Format(weaponTableName, sizeof(weaponTableName), "%s%s", "KW_", weapon[0]);
						Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, %s = %s + 1 WHERE steamId = '%s'",pointvalue, weaponTableName, weaponTableName, steamIdattacker);
						if (nofakekill == true && isbot == false)
						{
							SQL_TQuery(db,SQLErrorCheckCallback, query);
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
						else if (customkill == 1)
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
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (object == 1)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOTeleporterentrace = BOTeleporterentrace + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (object == 1)
		{
			Format(query, sizeof(query), "UPDATE Player SET BOTeleporterExit = BOTeleporterExit + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (object == 2)
		{
			Format(query, sizeof(query), "UPDATE Player SET BuildSentrygun = BuildSentrygun + 1 WHERE STEAMID = '%s'",steamIdbuilder);
			if (isbot == false)
			{
				SQL_TQuery(db,SQLErrorCheckCallback, query);
			}
		}
		else if (object == 3)
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
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (object == 1)
			{
				pointvalue = GetConVarInt(killteleinpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOTeleporterEntrace = KOTeleporterEntrace + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (object == 1)
			{
				pointvalue = GetConVarInt(killteleoutpoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOTeleporterExit = KOTeleporterExit + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (object == 2)
			{
				pointvalue = GetConVarInt(killsentrypoints)
				Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KOSentrygun = KOSentrygun + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdattacker);

				if (isbot == false)
				{
					SQL_TQuery(db,SQLErrorCheckCallback, query);
				}
			}
			else if (object == 3)
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
	if (!IsClientInGame(client) || client == 0)
		return Plugin_Continue;
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
		GetClientAuthString(client, steamId, sizeof(steamId));
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
					GetClientAuthString(i, SteamID, sizeof(SteamID));
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
				GetClientAuthString(client, SteamID, sizeof(SteamID));
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
				GetClientAuthString(i, SteamID, sizeof(SteamID));
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
			GetClientAuthString(client, SteamID, sizeof(SteamID));
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
				GetClientAuthString(client, SteamID, sizeof(SteamID));
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
	Format(query, sizeof(query), "UPDATE Player SET NAME = '%s' WHERE STEAMID = '%s'", name, steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query);
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
		GetClientAuthString(target_list[i], TargetSteamID, sizeof(TargetSteamID));
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
		GetClientAuthString(target_list[i], TargetSteamID, sizeof(TargetSteamID));
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
		GetClientAuthString(target_list[i], TargetSteamID, sizeof(TargetSteamID));
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
		GetClientAuthString(g_iMenuTarget[client], TargetSteamID, sizeof(TargetSteamID));


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
		GetClientAuthString(g_iMenuTarget[client], TargetSteamID, sizeof(TargetSteamID));


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
	if (db == INVALID_HANDLE)
		return;
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
		ReplaceString(clientname, sizeof(clientname), "<?PHP", "");
		ReplaceString(clientname, sizeof(clientname), "<?php", "");
		ReplaceString(clientname, sizeof(clientname), "<?", "");
		ReplaceString(clientname, sizeof(clientname), "?>", "");
		ReplaceString(clientname, sizeof(clientname), "<", "[");
		ReplaceString(clientname, sizeof(clientname), ">", "]");
		ReplaceString(clientname, sizeof(clientname), ",", ".");
		new String:ClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
		//Stupid buffer, its all your fault!
		new String:buffer[1500];
		new String:ip[20]
		GetClientIP(client,ip,sizeof(ip),true)

		if (!SQL_GetRowCount(hndl))
		{
			/*insert user*/

			Format(buffer, sizeof(buffer), "INSERT INTO Player (`NAME`,`STEAMID`) VALUES ('%s','%s')", clientname, ClientSteamID)
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			
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
		return;
	
	if (IsFakeClient(client))
		return;

	if (hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
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
		GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));

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
		GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));

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
	GetClientAuthString(client, STEAMID, sizeof(STEAMID));
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
		LogError("Query failed! %s", error);
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
	GetClientAuthString(client, STEAMID, sizeof(STEAMID));
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
		LogError("Query failed! %s", error);
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
	GetClientAuthString(client, STEAMID, sizeof(STEAMID));
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
		LogError("Query failed! %s", error);
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


			if (tmpdbversion <= DBVERSION) //Something has been updated, time to look for clues
			{
			
				new numWeapons = sizeof(myWeapons);
				for(new i = 0; i<numWeapons;i++)
				{
					//The following should be changed when a smarter way is found
					//that works for both DB types. Or just seperate it.
					
					new String:weaponQuery[255];
					Format(weaponQuery, sizeof(weaponQuery), "SELECT %s FROM Player", myWeapons[i][3]);
					if (!SQL_FastQuery(db, weaponQuery))
					{
						//The SQL failed. We ASSUME that it is because the table has no column for the given weapon (This may be unwise) and therefore add it
						new String:queryError[255]
						SQL_GetError(db, queryError, sizeof(queryError))
						PrintToServer("Failed to query (queryError: %s)", queryError);
						new len = 0;
						new String:query[600];
						len += Format(query[len], sizeof(query)-len, "ALTER TABLE `Player` ADD `%s` int(11) NOT NULL DEFAULT '0';", myWeapons[i][3]);
						SQL_TQuery(db,SQLErrorCheckCallback, query);
					}
				
					
					
				}
				
				new String:buffer[600];
				Format(buffer, sizeof(buffer), "UPDATE data SET dataint = %i where `name` = 'dbversion';", DBVERSION);
				SQL_TQuery(db,SQLErrorCheckCallback, buffer);

			}

			//---------

		}

		initonlineplayers()
	}
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

public OnAllPluginsLoaded()
{
	if (LibraryExists("pluginautoupdate"))
	{
		// only register myself if the autoupdater is loaded
		// AutoUpdate_AddPlugin(const String:url[], const String:file[], const String:version[])
	//	AutoUpdate_AddPlugin("darthninja.com", "/sm/tf2stats/plugin.xml", PLUGIN_VERSION);
	}
}

public OnPluginEnd()
{
	if (LibraryExists("pluginautoupdate"))
	{
	//	AutoUpdate_RemovePlugin();
	}
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    //MarkNativeAsOptional("AutoUpdate_AddPlugin");
   // MarkNativeAsOptional("AutoUpdate_RemovePlugin");
    return APLRes_Success;
}


CreateItemsTable()
{
	new len = 0;
	decl String:query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `founditems` (");
	len += Format(query[len], sizeof(query)-len, "`ID` int(11) NOT NULL AUTO_INCREMENT,");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ACTUALTIME` int(11) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ITEM` varchar(50) COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',"); //no longer used
	len += Format(query[len], sizeof(query)-len, "`ItemIndex` int(10) NOT NULL DEFAULT '0' COMMENT 'Item definition index from items_game.txt',");
	len += Format(query[len], sizeof(query)-len, "`Quality` int(3) NOT NULL DEFAULT '0' COMMENT 'Int value for vintage, strange, etc',");
	len += Format(query[len], sizeof(query)-len, "`Method` int(3) NOT NULL DEFAULT '0' COMMENT 'Crafted, traded, found, unboxed, etc',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`ID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;");
	SQL_FastQuery(db, query);
}

public Action:Event_item_found(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "isfake"))	//Item is fake
		return;

	if (!sqllite)
	{
		new String:steamid[64];
		GetClientAuthString(GetEventInt(event, "player"), steamid, sizeof(steamid));

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
		
		GetClientAuthString(client, SteamID, sizeof(SteamID));
		
		//Number of times a player has used a teleporter
		Format(query, sizeof(query), "UPDATE Player SET player_teleported = player_teleported + 1 WHERE STEAMID = '%s'", SteamID);
		SQL_TQuery(db,SQLErrorCheckCallback, query);

		//Get builders steamid
		new builder = GetClientOfUserId(GetEventInt(event, "builderid"))
		if (builder == 0 || client == 0)
			return Plugin_Continue;
		if (GetConVarBool(ignorebots) && IsFakeClient(builder))
			return Plugin_Continue;	// Tele owner is a bot -> ignore it
		
		GetClientAuthString(builder, SteamID, sizeof(SteamID));

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

		GetClientAuthString(healer, SteamID, sizeof(SteamID));
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
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET chat_status = '2' WHERE STEAMID = '%s'",steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query);
	cookieshowrankchanges[client] = false
}

public sayunhidepoints(client)
{
	new String:steamId[MAX_LINE_WIDTH]
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET chat_status = '1' WHERE STEAMID = '%s'",steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query);
	cookieshowrankchanges[client] = true
}

