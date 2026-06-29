//===VS Saxton Hale Mode===
//
//By Rainbolt Dash: programmer, modeller, mapper.
//Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
//And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
//And author of VS Saxton Hale Mode...no, wait, it's a this mode :D
//(Yes, it's a self-advertisement)
//
//Plugin thread on AM: http://forums.alliedmods.net/showthread.php?p=1384630
//===Coming Soon: Freak Fortress 2===
//Be obviously as Seeman and Seeldier
//Try to sale Stout Shako for 2 refined as Demopan
//Be Really Brutal as Advanced Christian Brutal Sniper
//EAT PEOPLE AS PAINIS CUPCAKE!!!
//
//Video Demonstration: http://www.youtube.com/watch?v=oHg5SJYRHA0
//
//Both plugins needs to be about 20% cooler.
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <colors>
#include <nextmap>
#include <tf2items>
#include <clientprefs>
#define ME 2048
#define PLUGIN_VERSION "1.369"
#define HaleModel "models/player/saxton_hale/saxton_hale.mdl"
#define CBSModel "models/player/saxton_hale/cbs_v2.mdl"
#define SaxtonHale "saxton_hale/saxton_hale_responce_1a.wav"
#define HaleRageSoundB "saxton_hale/saxton_hale_responce_1b.wav"
#define Arms "saxton_hale/saxton_hale_responce_2.wav"
#define HaleLastB "vo/announcer_am_lastmanalive"
#define HaleEnabled QueuePanelH(Handle:0, MenuAction:0, 9001, 0)
#define HaleKSpree "saxton_hale/saxton_hale_responce_3.wav"
#define HaleKSpree2 "saxton_hale/saxton_hale_responce_4.wav"	//this line is broken and unused
#define VagineerModel "models/player/saxton_hale/vagineer_v134.mdl"
#define VagineerLastA "saxton_hale/lolwut_0.wav"
#define VagineerRageSound "saxton_hale/lolwut_2.wav"
#define VagineerStart "saxton_hale/lolwut_1.wav"
#define VagineerKSpree "saxton_hale/lolwut_3.wav"
#define VagineerKSpree2 "saxton_hale/lolwut_4.wav"
#define VagineerHit "saxton_hale/lolwut_5.wav"
#define WrenchModel "models/weapons/w_models/w_wrench.mdl"
#define ShivModel "models/weapons/c_models/c_wood_machete/c_wood_machete.mdl"
#define HHHModel "models/player/saxton_hale/hhh_jr_mk2.1.mdl"
#define AxeModel "models/weapons/c_models/c_headtaker/c_headtaker.mdl"
#define HHHLaught "vo/halloween_boss/knight_laugh"
#define HHHRage "vo/halloween_boss/knight_attack01.wav"
#define HHHRage2 "vo/halloween_boss/knight_alert.wav"
#define HHHAttack "vo/halloween_boss/knight_attack"
#define CBS0 "vo/sniper_specialweapon08.wav"
#define CBS1 "vo/taunts/sniper_taunts02.wav"
#define CBS2 "vo/sniper_award"
#define CBS3 "vo/sniper_battlecry03.wav"
#define CBS4 "vo/sniper_domination"
#define HHHTheme "ui/holiday/gamestartup_halloween.mp3"
#define CBSTheme "saxton_hale/the_millionaires_holiday.mp3"
#define CBSJump1 "vo/sniper_specialcompleted02.wav"
//===New responces===
#define HaleRoundStart "saxton_hale/saxton_hale_responce_start"	//1-5
#define HaleJump "saxton_hale/saxton_hale_responce_jump"			//1-2
#define HaleRageSound "saxton_hale/saxton_hale_responce_rage"			//1-4
#define HaleKillMedic "saxton_hale/saxton_hale_responce_kill_medic.wav"
#define HaleKillSniper1 "saxton_hale/saxton_hale_responce_kill_sniper1.wav"
#define HaleKillSniper2 "saxton_hale/saxton_hale_responce_kill_sniper2.wav"
#define HaleKillSpy1 "saxton_hale/saxton_hale_responce_kill_spy1.wav"
#define HaleKillSpy2 "saxton_hale/saxton_hale_responce_kill_spy2.wav"
#define HaleKillEngie1 "saxton_hale/saxton_hale_responce_kill_eggineer1.wav"
#define HaleKillEngie2 "saxton_hale/saxton_hale_responce_kill_eggineer2.wav"
#define HaleKSpreeNew "saxton_hale/saxton_hale_responce_spree"	//1-5
#define HaleWin "saxton_hale/saxton_hale_responce_win"			//1-2
#define HaleLastMan "saxton_hale/saxton_hale_responce_lastman"	//1-5
//#define HaleLastMan2Fixed "saxton_hale/saxton_hale_responce_lastman2.wav"
#define HaleFail "saxton_hale/saxton_hale_responce_fail"			//1-3
//===1.32 responces===
#define HaleJump132 "saxton_hale/saxton_hale_132_jump_"	//1-2
#define HaleStart132 "saxton_hale/saxton_hale_132_start_"	//1-5
#define HaleKillDemo132  "saxton_hale/saxton_hale_132_kill_demo.wav"
#define HaleKillEngie132  "saxton_hale/saxton_hale_132_kill_engie_" //1-2
#define HaleKillHeavy132  "saxton_hale/saxton_hale_132_kill_heavy.wav"
#define HaleKillScout132  "saxton_hale/saxton_hale_132_kill_scout.wav"
#define HaleKillSpy132  "saxton_hale/saxton_hale_132_kill_spie.wav"
#define HaleKillPyro132  "saxton_hale/saxton_hale_132_kill_w_and_m1.wav"
#define HaleSappinMahSentry132  "saxton_hale/saxton_hale_132_kill_toy.wav"
#define HaleKillKSpree132  "saxton_hale/saxton_hale_132_kspree_"	//1-2
#define HaleKillLast132  "saxton_hale/saxton_hale_132_last.wav"
#define HaleStubbed132 "saxton_hale/saxton_hale_132_stub_"	//1-4
//===New Vagineer's responces===
#define VagineerRoundStart "saxton_hale/vagineer_responce_intro.wav"
#define VagineerJump "saxton_hale/vagineer_responce_jump_"			//1-2
#define VagineerRageSound2 "saxton_hale/vagineer_responce_rage_"			//1-4
#define VagineerKSpreeNew "saxton_hale/vagineer_responce_taunt_"		//1-5
#define VagineerFail "saxton_hale/vagineer_responce_fail_"			//1-2
#define SOUNDEXCEPT_MUSIC 0
#define SOUNDEXCEPT_VOICE 1
new OtherTeam = 2;
new HaleTeam = 3;
new VSHRoundState = -1;
new playing;
new healthcheckused;
new RedAlivePlayers;
new RoundCount;
new Special;
new Incoming;
new Damage[MAXPLAYERS + 1];
new curHelp[MAXPLAYERS + 1];
#define VSHFLAG_HELPED		(1 << 0)
#define VSHFLAG_UBERREADY	(1 << 1)
new VSHFlags[MAXPLAYERS + 1];
new Hale = 1;
new HaleHealthMax;
new HaleHealth;
new HaleHealthLast;
new HaleCharge = 0;
new HaleRage;
new NextHale;
new Float:Stabbed;
new Float:HPTime;
new Float:KSpreeTimer;
new Float:WeighDownTimer;
new KSpreeCount = 1;
new Float:UberRageCount;
new Float:GlowTimer;
new bool:bEnableSuperDuperJump;
new Handle:cvarHaleSpeed;
new Handle:cvarPointDelay;
new Handle:cvarRageDMG;
new Handle:cvarRageDist;
new Handle:cvarAnnounce;
new Handle:cvarSpecials;
new Handle:cvarEnabled;
new Handle:cvarAliveToEnable;
new Handle:cvarPointType;
new Handle:cvarCrits;
new Handle:cvarRageSentry;
new Handle:cvarFirstRound;
new Handle:PointCookie;
new Handle:MusicCookie;
new Handle:VoiceCookie;
new Handle:ClasshelpinfoCookie;
new Handle:doorchecktimer;
new Handle:jumpHUD;
new Handle:rageHUD;
new Handle:healthHUD;
new bool:Enabled = false;
new bool:Enabled2 = false;
new Float:HaleSpeed = 340.0;
new PointDelay = 6;
new RageDMG = 1900;
new Float:RageDist = 800.0;
new Float:Announce = 120.0;
new bSpecials = true;
new AliveToEnable = 5;
new PointType = 0;
new bool:haleCrits = true;
new bool:newRageSentry = true;
new Handle:MusicTimer;
new TeamRoundCounter;
new botqueuepoints = 0;
new String:currentmap[99];
new tf_arena_use_queue;
new mp_teams_unbalance_limit;
new tf_arena_first_blood;
new mp_forcecamera;
new defaulttakedamagetype;
static const String:haleversiontitles[][] =		//the last line of this is what determines the displayed plugin version
{
	"1.0",
	"1.1",
	"1.11",
	"1.12",
	"1.2",
	"1.22",
	"1.23",
	"1.24",
	"1.25",
	"1.26",
	"Christian Brutal Sniper",
	"1.28",
	"1.29",
	"1.30",
	"1.31",
	"1.32",
	"1.33",
	"1.34",
	"1.35",
	"1.35_3",
	"1.36",
	"1.36",
	"1.36",
	"1.36",
	"1.36",
	"1.36",
	"1.362",
	"1.363",
	"1.364",
	"1.365",
	"1.366",
	"1.367",
	"1.368",
	"1.369",
	"1.369",
	"1.369"
};
static const String:haleversiondates[][] =
{
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"--",
	"25 Aug 2011",
	"26 Aug 2011",
	"09 Oct 2011",
	"09 Oct 2011",
	"09 Oct 2011"
};
static const maxversion = (sizeof(haleversiontitles) - 1);
new Handle:OnHaleJump = INVALID_HANDLE;
new Handle:OnHaleRage = INVALID_HANDLE;
new Handle:OnHaleWeighdown = INVALID_HANDLE;
//new bool:ACH_Enabled;
enum dirMode
{
	o = 511,
	g = 511,
	u = 511
};
public Plugin:myinfo = {
	name = "VS Saxton Hale",
	author = "Rainbolt Dash, FlaminSarge",
	description = "RUUUUNN!! COWAAAARRDSS!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=146884",
};
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("VSH_IsSaxtonHaleModeEnabled", Native_IsEnabled);
	CreateNative("VSH_GetSaxtonHaleUserId", Native_GetHale);
	CreateNative("VSH_GetSaxtonHaleTeam", Native_GetTeam);
	CreateNative("VSH_GetSpecialRoundIndex", Native_GetSpecial);
	CreateNative("VSH_GetSaxtonHaleHealth", Native_GetHealth);
	CreateNative("VSH_GetSaxtonHaleHealthMax", Native_GetHealthMax);
	CreateNative("VSH_GetClientDamage", Native_GetDamage);
	CreateNative("VSH_GetRoundState", Native_GetRoundState);
	OnHaleJump = CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	OnHaleWeighdown = CreateGlobalForward("VSH_OnDoWeighdown", ET_Hook);
	RegPluginLibrary("saxtonhale");
	return APLRes_Success;
}
public OnPluginStart()
{
	//ACH_Enabled=LibraryExists("hale_achievements");
	LogMessage("===VS Saxton Hale Initializing - v.%s===", haleversiontitles[maxversion]);
	new Handle:cvarVersion = CreateConVar("hale_version", haleversiontitles[maxversion], "VS Saxton Hale Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarHaleSpeed = CreateConVar("hale_speed", "340.0", "Speed of Saxton Hale", FCVAR_PLUGIN);
	cvarPointType = CreateConVar("hale_point_type", "0", "Select condition to enable point (0 - alive players, 1 - time)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarPointDelay = CreateConVar("hale_point_delay", "6", "Addition (for each player) delay before point's activation.", FCVAR_PLUGIN);
	cvarAliveToEnable = CreateConVar("hale_point_alive", "5", "Enable control points when there are X people left alive.", FCVAR_PLUGIN);
	cvarRageDMG = CreateConVar("hale_rage_damage", "1900", "Damage required for Hale to gain rage", FCVAR_PLUGIN, true, 0.0);
	cvarRageDist  = CreateConVar("hale_rage_dist", "800.0", "Distance to stun in Hale's rage. Vagineer and CBS are /3 (/2 for sentries)", FCVAR_PLUGIN, true, 0.0);
	cvarAnnounce = CreateConVar("hale_announce", "120.0", "Info about mode will show every X seconds. Must be greater than 1.0 to show.", FCVAR_PLUGIN, true, 0.0);
	cvarSpecials = CreateConVar("hale_specials", "1", "Enable Special Rounds (Vagineer, HHH, CBS)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnabled = CreateConVar("hale_enabled", "1", "Do you really want set it to 0?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCrits = CreateConVar("hale_crits", "1", "Can Hale get crits?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRageSentry = CreateConVar("hale_ragesentrydamagemode", "1", "If 0, to repair a sentry that has been damaged by rage, the Engineer must pick it up and put it back down.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarFirstRound = CreateConVar("hale_first_round", "0", "Disable(0) or Enable(1) VSH in 1st round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("player_changeclass", event_changeclass);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death, EventHookMode_Pre);
	HookEvent("player_chargedeployed", event_uberdeployed);
	HookEvent("player_hurt", event_hurt, EventHookMode_Pre);
	HookEvent("object_destroyed", event_destroy, EventHookMode_Pre);
	HookEvent("object_deflected", event_deflect, EventHookMode_Pre);
	HookConVarChange(cvarHaleSpeed, CvarChange);
	HookConVarChange(cvarRageDMG, CvarChange);
	HookConVarChange(cvarRageDist, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarSpecials, CvarChange);
	HookConVarChange(cvarPointType, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAliveToEnable, CvarChange);
	HookConVarChange(cvarCrits, CvarChange);
	HookConVarChange(cvarRageSentry, CvarChange);
	RegConsoleCmd("hale", HalePanel);
	RegConsoleCmd("hale_hp", Command_GetHPCmd);
	RegConsoleCmd("halehp", Command_GetHPCmd);
	RegConsoleCmd("hale_next", QueuePanelCmd);
	RegConsoleCmd("halenext", QueuePanelCmd);
	RegConsoleCmd("hale_help", HelpPanelCmd);
	RegConsoleCmd("halehelp", HelpPanelCmd);
	RegConsoleCmd("hale_class", HelpPanel2Cmd);
	RegConsoleCmd("haleclass", HelpPanel2Cmd);
	RegConsoleCmd("hale_classinfotoggle", ClasshelpinfoCmd);
	RegConsoleCmd("haleclassinfotoggle", ClasshelpinfoCmd);
	RegConsoleCmd("hale_new", NewPanelCmd);
	RegConsoleCmd("halenew", NewPanelCmd);
//	RegConsoleCmd("hale_me", SkipHalePanelCmd);
//	RegConsoleCmd("haleme", SkipHalePanelCmd);
	RegConsoleCmd("halemusic", MusicTogglePanelCmd);
	RegConsoleCmd("hale_music", MusicTogglePanelCmd);
	RegConsoleCmd("halevoice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_voice", VoiceTogglePanelCmd);
	AddCommandListener(DoTaunt, "+taunt");
	AddCommandListener(DoSuicide, "explode");
	AddCommandListener(DoSuicide, "kill");
	RegAdminCmd("hale_select", Command_HaleSelect, ADMFLAG_CHEATS, "hale_select <target> - Select a player to be next boss");
	RegAdminCmd("hale_special", Command_MakeNextSpecial, ADMFLAG_CHEATS, "Call a special to next round.");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "hale_addpoints <target> <points> - Add queue points to user.");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable CP. Only with hale_point_type=0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable CP. Only with hale_point_type=0");
	RegAdminCmd("hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music.");
	AutoExecConfig(true, "SaxtonHale");
	PointCookie = RegClientCookie("hale_queuepoints1", "Amount of VSH Queue points player has", CookieAccess_Protected);
	MusicCookie = RegClientCookie("hale_music_setting", "HaleMusic setting", CookieAccess_Public);
	VoiceCookie = RegClientCookie("hale_voice_setting", "HaleVoice setting", CookieAccess_Public);
	ClasshelpinfoCookie = RegClientCookie("hale_classinfo", "HaleClassinfo setting", CookieAccess_Public);
	jumpHUD = CreateHudSynchronizer();
	rageHUD = CreateHudSynchronizer();
	healthHUD = CreateHudSynchronizer();
	decl String:oldversion[64];
	GetConVarString(cvarVersion, oldversion, sizeof(oldversion));
	if (strcmp(oldversion, haleversiontitles[maxversion], false) != 0) LogError("[VS Saxton Hale] Warning: your config may be outdated. Back up your tf/cfg/sourcemod/SaxtonHale.cfg file and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	LoadTranslations("saxtonhale.phrases");
	LoadTranslations("common.phrases");
	for (new client = 0; client <= MaxClients; client++)
	{
		VSHFlags[client] = 0;
		Damage[client] = 0;
		if (IsValidClient(client, false)) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
/*
public OnLibraryAdded(const String:name[])
{
	if (!strcmp(name, "hale_achievements"))
		ACH_Enabled=true;
}
public OnLibraryRemoved(const String:name[])
{
	if (!strcmp(name, "hale_achievements"))
		ACH_Enabled=false;
}
*/
public OnConfigsExecuted()
{
	SetConVarString(FindConVar("hale_version"), haleversiontitles[maxversion]);
	HaleSpeed = GetConVarFloat(cvarHaleSpeed);
	RageDMG = GetConVarInt(cvarRageDMG);
	RageDist = GetConVarFloat(cvarRageDist);
	Announce = GetConVarFloat(cvarAnnounce);
	bSpecials = GetConVarBool(cvarSpecials);
	PointType = GetConVarInt(cvarPointType);
	PointDelay = GetConVarInt(cvarPointDelay);
	if (PointDelay < 0) PointDelay *= -1;
	AliveToEnable = GetConVarInt(cvarAliveToEnable);
	haleCrits = GetConVarBool(cvarCrits);
	newRageSentry = GetConVarBool(cvarRageSentry);
}
public OnMapStart()
{
	MusicTimer = INVALID_HANDLE;
	TeamRoundCounter = 0;
	doorchecktimer = INVALID_HANDLE;
	if (!IsSaxtonHaleMap() || !GetConVarInt(cvarEnabled))
	{
		Enabled2 = false;
		Enabled = false;
	}
	else
	{
		if (FileExists("bNextMapToHale"))
			DeleteFile("bNextMapToHale");
		Enabled = true;
		Enabled2 = true;
		AddToDownload();
		tf_arena_use_queue = GetConVarInt(FindConVar("tf_arena_use_queue"));
		mp_teams_unbalance_limit = GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
		tf_arena_first_blood = GetConVarInt(FindConVar("tf_arena_first_blood"));
		mp_forcecamera = GetConVarInt(FindConVar("mp_forcecamera"));
		SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
		SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
		SetConVarInt(FindConVar("mp_forcecamera"), 0);
		Hale = 1;
		new Float:time = Announce;
		if (time > 1.0)
		{
			/*if (ACH_Enabled)
				CreateTimer(time, Timer_Announce, true, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			else*/
				CreateTimer(time, Timer_Announce, false, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		for (new i = 1; i <= MaxClients; i++)
			VSHFlags[i] = 0;
/*		decl String:s[PLATFORM_MAX_PATH];
		decl String:arg[32][2];
		BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/saxton_hale_config.cfg");
		if (FileExists(s))
		{
			new Handle:fileh = OpenFile(s, "r");
			while(ReadFileLine(fileh, s, sizeof(s)))
			{
				ExplodeString(s, " ", arg, 2, 32);
				if (!StrContains(s, "hale_speed", false))
					SetConVarFloat(cvarHaleSpeed, StringToFloat(arg[1]));
				else if (!StrContains(s, "hale_point_delay", false))
					SetConVarInt(cvarPointDelay, StringToInt(arg[1]));
				else if (!StrContains(s, "hale_rage_damage", false))
					SetConVarInt(cvarRageDMG, StringToInt(arg[1]));
				else if (!StrContains(s, "hale_rage_dist", false))
					SetConVarFloat(cvarRageDist, StringToFloat(arg[1]));
				else if (!StrContains(s, "hale_announce", false))
					SetConVarFloat(cvarAnnounce, StringToFloat(arg[1]));
				else if (!StrContains(s, "hale_specials", false))
					SetConVarInt(cvarSpecials, StringToInt(arg[1]));
				else if (!StrContains(s, "hale_point_type", false))
					SetConVarInt(cvarPointType, StringToInt(arg[1]));
				else if (!StrContains(s, "hale_point_delay", false))
					SetConVarInt(cvarPointDelay, StringToInt(arg[1]));
				else if (!StrContains(s, "hale_point_alive", false))
					SetConVarInt(cvarAliveToEnable, StringToInt(arg[1]));
			}
			CloseHandle(fileh);
		}
		else
			WriteConfig();*/
		AddNormalSoundHook(HookSound);
	}
	RoundCount = 0;
}
public OnMapEnd()
{
	if (Enabled2 || Enabled)
	{
		SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
		SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
		SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
	}
	if (MusicTimer != INVALID_HANDLE)
	{
		KillTimer(MusicTimer);
		MusicTimer = INVALID_HANDLE;
	}
}
public AddToDownload()
{
	decl String:s[PLATFORM_MAX_PATH];
	new String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	new String:extensionsb[][] = {".vtf", ".vmt"};
	decl i;
	for (i = 0; i < sizeof(extensions); i++)
	{
		Format(s, PLATFORM_MAX_PATH, "models/player/saxton_hale/saxton_hale%s", extensions[i]);
		AddFileToDownloadsTable(s);
		if (bSpecials)
		{
			Format(s, PLATFORM_MAX_PATH, "models/player/saxton_hale/vagineer_v134%s", extensions[i]);
			AddFileToDownloadsTable(s);
			Format(s, PLATFORM_MAX_PATH, "models/player/saxton_hale/hhh_jr_mk2.1%s", extensions[i]);
			AddFileToDownloadsTable(s);
		}
	}
	PrecacheModel(HaleModel, true);
	if (bSpecials)
	{
		PrecacheModel(VagineerModel, true);
		PrecacheModel(HHHModel, true);
		PrecacheModel(CBSModel, true);
		AddFileToDownloadsTable(CBSModel);
	}
	for (i = 0; i < sizeof(extensionsb); i++)
	{
		Format(s, PLATFORM_MAX_PATH, "materials/models/player/saxton_hale/eye%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/player/saxton_hale/hale_head%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/player/saxton_hale/hale_body%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/player/saxton_hale/hale_misc%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/player/saxton_hale/sniper_red%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/player/saxton_hale/sniper_lens%s", extensionsb[i]);
		AddFileToDownloadsTable(s);
	}
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head_red.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_misc_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/eyeball_r.vmt");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vtf");
	AddFileToDownloadsTable("materials/models/player/saxton_hale/hale_egg.vmt");
	PrecacheSound(Arms, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", Arms);
	AddFileToDownloadsTable(s);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKSpree);
	PrecacheSound(HaleKSpree, true);
	AddFileToDownloadsTable(s);
	PrecacheSound("saxton_hale/9000.wav", true);
	AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
	for (i = 1; i <= 4; i++)
	{
		Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HaleLastB, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HHHLaught, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HHHAttack, i);
		PrecacheSound(s, true);
	}
	if (bSpecials)
	{
		PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
		PrecacheSound("ui/halloween_boss_defeated_fx.wav", true);
		PrecacheSound(VagineerLastA, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", VagineerLastA);
		AddFileToDownloadsTable(s);
		PrecacheSound(VagineerStart, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", VagineerStart);
		AddFileToDownloadsTable(s);
		PrecacheSound(VagineerRageSound, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", VagineerRageSound);
		AddFileToDownloadsTable(s);
		PrecacheSound(VagineerKSpree, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", VagineerKSpree);
		AddFileToDownloadsTable(s);
		PrecacheSound(VagineerKSpree2, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", VagineerKSpree2);
		AddFileToDownloadsTable(s);
		PrecacheSound(VagineerHit, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", VagineerHit);
		AddFileToDownloadsTable(s);
		PrecacheSound(HHHRage, true);
		PrecacheSound(HHHRage2, true);
		PrecacheSound(CBS0, true);
		PrecacheSound(CBS1, true);
		PrecacheSound(HHHTheme, true);
		PrecacheSound(CBSTheme, true);
		AddFileToDownloadsTable("sound/saxton_hale/the_millionaires_holiday.mp3");
		PrecacheSound(CBSJump1, true);
		for (i = 1; i <= 9; i++)
		{
			Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", CBS2, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", CBS4, i);
			PrecacheSound(s, true);
		}
		for (i = 10; i <= 25; i++)
		{
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", CBS4, i);
			PrecacheSound(s, true);
		}
	}
	PrecacheSound(HaleKillMedic, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillMedic);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillSniper1, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillSniper1);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillSniper2, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillSniper2);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillSpy1, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillSpy1);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillSpy2, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillSpy2);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillEngie1, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillEngie1);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillEngie2, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillEngie2);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillDemo132, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillDemo132);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillHeavy132, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillHeavy132);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillScout132, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillScout132);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillSpy132, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillSpy132);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillPyro132, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillPyro132);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleSappinMahSentry132, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleSappinMahSentry132);
	AddFileToDownloadsTable(s);
	PrecacheSound(HaleKillLast132, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", HaleKillLast132);
	AddFileToDownloadsTable(s);
	PrecacheSound("vo/announcer_am_capincite01.wav", true);
	PrecacheSound("vo/announcer_am_capincite03.wav", true);
	PrecacheSound("vo/announcer_am_capenabled02.wav", true);
	for (i = 1; i <= 5; i++)
	{
		if (i <= 2)
		{
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
			if (bSpecials)
			{
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, i);
				PrecacheSound(s, true);
				Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
				AddFileToDownloadsTable(s);
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerRageSound2, i);
				PrecacheSound(s, true);
				Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
				AddFileToDownloadsTable(s);
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerFail, i);
				PrecacheSound(s, true);
				Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
				AddFileToDownloadsTable(s);
			}
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleWin, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump132, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
		}
		if (i <= 3)
		{
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleFail, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
		}
		if (i <= 4)
		{
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRageSound, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStubbed132, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
		}
		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);
		if (bSpecials)
		{
			PrecacheSound(VagineerRoundStart, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", VagineerRoundStart);
			AddFileToDownloadsTable(s);
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerKSpreeNew, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
		}
		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleLastMan, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStart132, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);
	}
	PrecacheSound("vo/engineer_no01.wav", true);
	PrecacheSound("vo/engineer_jeers02.wav", true);
	PrecacheSound("vo/halloween_boss/knight_pain01.wav", true);
	PrecacheSound("vo/halloween_boss/knight_pain02.wav", true);
	PrecacheSound("vo/halloween_boss/knight_pain03.wav", true);
	PrecacheSound("vo/halloween_boss/knight_death01.wav", true);
	PrecacheSound("vo/halloween_boss/knight_death02.wav", true);
}
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarHaleSpeed)
		HaleSpeed = GetConVarFloat(convar);
	else if (convar == cvarPointDelay)
	{
		PointDelay = GetConVarInt(convar);
		if (PointDelay < 0) PointDelay *= -1;
	}
	else if (convar == cvarRageDMG)
		RageDMG = GetConVarInt(convar);
	else if (convar == cvarRageDist)
		RageDist = GetConVarFloat(convar);
	else if (convar == cvarAnnounce)
		Announce = GetConVarFloat(convar);
	else if (convar == cvarSpecials)
		bSpecials = GetConVarBool(convar);
	else if (convar == cvarPointType)
		PointType = GetConVarInt(convar);
	else if (convar == cvarPointDelay)
		PointDelay = GetConVarInt(convar);
	else if (convar == cvarAliveToEnable)
		AliveToEnable = GetConVarInt(convar);
	else if (convar == cvarCrits)
		haleCrits = GetConVarBool(convar);
	else if (convar == cvarRageSentry)
		newRageSentry = GetConVarBool(convar);
}
public Action:Timer_Announce(Handle:hTimer, any:withachievements)
{
	static announcecount=-1;
	announcecount++;
	if (Announce > 1.0 && Enabled2)
	{
		switch (announcecount)
		{
			case 1:
			{
				CPrintToChatAll("{olive}[VSH]{default} VS Saxton Hale group: {olive}http://steamcommunity.com/groups/vssaxtonhale{default}");
			}
			case 3:
			{
				CPrintToChatAll("{default}===VS Saxton Hale by {olive}Rainbolt Dash plus FlaminSarge{default} v.%s===", haleversiontitles[maxversion]);
			}
			case 5:
			{
				announcecount=0;
				CPrintToChatAll("{olive}[VSH]{default} %t", "last_update", haleversiontitles[maxversion], haleversiondates[maxversion]);
			}
			default:
			{
				if (withachievements)
					CPrintToChatAll("{olive}[VSH]{default} %t\n%t (experimental)", "type_hale_to_open_menu", "type_haleach_to_open_ach");
				else
					CPrintToChatAll("{olive}[VSH]{default} %t", "type_hale_to_open_menu");
			}
		}
	}
	return Plugin_Continue;
}
public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (Enabled2)
	{
		Format(gameDesc, sizeof(gameDesc), "VS Saxton Hale (%s)", haleversiontitles[maxversion]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
stock bool:IsSaxtonHaleMap()
{
	decl Handle:fileh;
	decl String:s[PLATFORM_MAX_PATH];
	GetCurrentMap(currentmap, sizeof(currentmap));
	if (FileExists("bNextMapToHale"))
	{
		return true;
	}
	BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/saxton_hale_maps.cfg");
	fileh = OpenFile(s, "r");
	new pingas = 0;
	while (ReadFileLine(fileh, s, sizeof(s)) && (pingas < 100))
	{
		pingas++;
		if (pingas == 100)
			LogError("[VS Saxton Hale] Breaking infinite loop when trying to check the map.");
		Format(s, strlen(s)-1, s);
		if ((StrContains(currentmap, s, false) != -1) || (StrContains(s, "all", false) == 0))
		{
			CloseHandle(fileh);
			return true;
		}
	}
	CloseHandle(fileh);
	return false;
}
bool:CheckNextSpecial()
{
	if (!bSpecials)
	{
		Special = 0;
		return true;
	}
	while (Incoming == -1 || (Special && Special == Incoming))
	{
		Incoming = GetRandomInt(0, 17);
		if (Special != 0 && !GetRandomInt(0, 5)) Incoming = 0;
		else
		{
			switch (Incoming)
			{
				case 12, 13: Incoming = 1;
				case 11, 10: Incoming = 2;
				case 14, 15: Incoming = 4;
				default: Incoming = 0;
			}
		}
	}
	Special = Incoming;
	Incoming = -1;
	return true;		//OH GOD WHAT AM I DOING THIS ALWAYS RETURNS TRUE (still better than using QueuePanelH as a dummy)
}
public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	Enabled = Enabled2;
	if (CheckNextSpecial() && !Enabled)	//QueuePanelH(Handle:0, MenuAction:0, 9001, 0) is HaleEnabled
		return Plugin_Continue;
	if (FileExists("bNextMapToHale"))
		DeleteFile("bNextMapToHale");
	KSpreeCount = 0;
	CheckArena();
	GetCurrentMap(currentmap, sizeof(currentmap));
	new bool:bBluHale;
	if (strncmp(currentmap, "vsh_", 4, false) == 0) bBluHale = true;
	else if (TeamRoundCounter >= 3 && GetRandomInt(0, 1))
	{
		bBluHale = (HaleTeam != 3);
		TeamRoundCounter = 0;
	}
	else bBluHale = (HaleTeam == 3);
	if (bBluHale)
	{
		new score1 = GetTeamScore(OtherTeam);
		new score2 = GetTeamScore(HaleTeam);
		SetTeamScore(2, score1);
		SetTeamScore(3, score2);
		OtherTeam = 2;
		HaleTeam = 3;
		bBluHale = false;
	}
	else
	{
		new score1 = GetTeamScore(HaleTeam);
		new score2 = GetTeamScore(OtherTeam);
		SetTeamScore(2, score1);
		SetTeamScore(3, score2);
		HaleTeam = 2;
		OtherTeam = 3;
		bBluHale = true;
	}
	playing = 0;
	for (new ionplay = 1; ionplay <= MaxClients; ionplay++)
	{
		Damage[ionplay] = 0;
		if (IsValidClient(ionplay))
		{
			StopHaleMusic(ionplay);
			if (GetClientTeam(ionplay) > _:TFTeam_Spectator) playing++;
		}
	}
	if (GetClientCount() <= 1 || playing < 2)
	{
		CPrintToChatAll("{olive}[VSH]{default} %t", "needmoreplayers");
		Enabled = false;
		VSHRoundState = -1;
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if (RoundCount > 0)
		Enabled = true;
	else if (!GetConVarBool(cvarFirstRound))
	{
		CPrintToChatAll("{olive}[VSH]{default} %t", "first_round");
		Enabled = false;
		VSHRoundState = -1;
		SetControlPoint(true);
		return Plugin_Continue;
	}
	if (GetTeamPlayerCount(TFTeam_Blue) <= 0 || GetTeamPlayerCount(TFTeam_Red) <= 0)
	{
		if (IsValidClient(Hale))
		{
			ChangeClientTeam(Hale, HaleTeam);
			TF2_RespawnPlayer(Hale);
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && i != Hale && GetClientTeam(i) != _:TFTeam_Spectator && GetClientTeam(i) != _:TFTeam_Unassigned)
			{
				ChangeClientTeam(i, OtherTeam);
				TF2_RespawnPlayer(i);
			}
		}
		return Plugin_Continue;
	}
	new bool:see[MAXPLAYERS + 1];
	new tHale = FindNextHale(see);
	if (NextHale > 0)
	{
		Hale = NextHale;
		NextHale = -1;
	}
	else
	{
		Hale = tHale;
	}
	CreateTimer(9.1, StartHaleTimer);
	CreateTimer(3.5, StartResponceTimer);
	CreateTimer(9.6, MessageTimer, 9001);
	HaleRage = 0;
	Stabbed = 0.0;
	new ent = -1;
	decl Float:pos[3];
	while ((ent = FindEntityByClassname2(ent, "func_regenerate")) != -1)
		AcceptEntityInput(ent, "Disable");
	ent = -1;
	while ((ent = FindEntityByClassname2(ent, "func_respawnroomvisualizer")) != -1)
		AcceptEntityInput(ent, "Disable");
	ent = -1;
	while ((ent = FindEntityByClassname2(ent, "obj_dispenser")) != -1)
	{
		SetVariantInt(OtherTeam);
		AcceptEntityInput(ent, "SetTeam");
		AcceptEntityInput(ent, "skin");
		SetEntProp(ent, Prop_Send, "m_nSkin", OtherTeam-2);
	}
	ent = -1;
	while ((ent = FindEntityByClassname2(ent, "mapobj_cart_dispenser")) != -1)
	{
		SetVariantInt(OtherTeam);
		AcceptEntityInput(ent, "SetTeam");
		AcceptEntityInput(ent, "skin");
	}
	ent = -1;
	while ((ent = FindEntityByClassname2(ent, "item_ammopack_full")) != -1)
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AcceptEntityInput(ent, "Kill");
		new ent2 = CreateEntityByName("item_ammopack_small");
		TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent2);
	}
	ent = -1;
	while ((ent = FindEntityByClassname2(ent, "item_ammopack_medium")) != -1)
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AcceptEntityInput(ent, "Kill");
		new ent2 = CreateEntityByName("item_ammopack_small");
		TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent2);
	}
	CreateTimer(0.2, Timer_GogoHale);
	healthcheckused = 0;
	VSHRoundState = 0;
	return Plugin_Continue;
}
stock GetTeamPlayerCount(TFTeam:team)
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == _:team)
			count++;
	}
	return count;
}
public Action:Timer_GogoHale(Handle:hTimer)
{
	CreateTimer(0.1, MakeHale);
}
public Action:Timer_CheckDoors(Handle:hTimer)
{
	if (strcmp(currentmap, "arena_nucleus", false) == 0)
	{
		doorchecktimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if (!Enabled) return Plugin_Continue;
	if (VSHRoundState != 1) return Plugin_Continue;
	new ent = -1;
	while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
	{
		AcceptEntityInput(ent, "Open");
		AcceptEntityInput(ent, "Unlock");
	}
	return Plugin_Continue;
}
public CheckArena()
{
	new ent = -1;
	if ((ent = FindEntityByClassname2(-1, "tf_logic_arena")) != -1 && IsValidEdict(ent))
	{
		if (PointType)
		{
			decl String:s[8];
			IntToString(45 + PointDelay * (playing - 1), s, 8);
			DispatchKeyValue(ent, "CapEnableDelay", s);
		}
		else
		{
			DispatchKeyValue(ent, "CapEnableDelay", "0");
			SetControlPoint(false);
		}
	}
//	SetControlPoint(false);
}
public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:s[265];
	decl String:s2[265];
	new bool:see = false;
	GetNextMap(s, 64);
	if (!strncmp(s, "Hale ", 5, false))
	{
		see = true;
		strcopy(s2, sizeof(s2), s[5]);
	}
	else if (!strncmp(s, "(Hale) ", 7, false))
	{
		see = true;
		strcopy(s2, sizeof(s2), s[7]);
	}
	else if (!strncmp(s, "(Hale)", 6, false))
	{
		see = true;
		strcopy(s2, sizeof(s2), s[6]);
	}
	if (see)
	{
		new Handle:fileh = OpenFile("bNextMapToHale", "w");
		WriteFileString(fileh, s2, false);
		CloseHandle(fileh);
		SetNextMap(s2);
		CPrintToChatAll("{olive}[VSH]{default} %t", "nextmap_hale", s2);
	}
	RoundCount++;
	if (!Enabled)
	{
		return Plugin_Continue;
	}
	VSHRoundState = 2;
	TeamRoundCounter++;
	if (GetEventInt(event, "team") == HaleTeam)
	{
		switch (Special)
		{
			case 0:
			{
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleWin, GetRandomInt(1, 2));
				EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
			}
			case 1:
			{
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerKSpreeNew, GetRandomInt(1, 5));
				EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, _, NULL_VECTOR, false, 0.0);
			}
		}
	}
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		StopHaleMusic(i);
	}
	if (IsValidClient(Hale))
	{
		if (IsPlayerAlive(Hale))
		{
			decl String:translation[32];
			switch (Special)
			{
				case 1:		strcopy(translation, sizeof(translation), "vagineer_is_alive");
				case 2:		strcopy(translation, sizeof(translation), "hhh_is_alive");
				case 4:		strcopy(translation, sizeof(translation), "cbs_is_alive");
				default:		strcopy(translation, sizeof(translation), "hale_is_alive");
			}
			CPrintToChatAll("{olive}[VSH]{default} %t", translation, Hale, HaleHealth, HaleHealthMax);
			SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					ShowHudText(i, -1, "%T", translation, i, Hale, HaleHealth, HaleHealthMax);
				}
			}
		}
		else
			ChangeClientTeam(Hale, OtherTeam);
		new top[3];
		Damage[0]=0;
		for (new i = 0; i <= MaxClients; i++)
		{
			if (Damage[i] >= Damage[top[0]])
			{
				top[2]=top[1];
				top[1]=top[0];
				top[0]=i;
			}
			else if (Damage[i] >= Damage[top[1]])
			{
				top[2]=top[1];
				top[1]=i;
			}
			else if (Damage[i] >= Damage[top[2]])
			{
				top[2]=i;
			}
		}
		if (Damage[top[0]] > 9000)
		{
			CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		decl String:s1[80];
		if (IsValidClient(top[0]) && (GetClientTeam(top[0]) >= 1))
			GetClientName(top[0], s, 80);
		else
		{
			Format(s, 80, "---");
			top[0]=0;
		}
		if (IsValidClient(top[1]) && (GetClientTeam(top[1]) >= 1))
			GetClientName(top[1], s1, 80);
		else
		{
			Format(s1, 80, "---");
			top[1]=0;
		}
		if (IsValidClient(top[2]) && (GetClientTeam(top[2]) >= 1))
			GetClientName(top[2], s2, 80);
		else
		{
			Format(s2, 80, "---");
			top[2]=0;
		}
		SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
		PrintCenterTextAll("");	//Should clear center text
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				SetGlobalTransTarget(i);
//				Format(s3, 512, "%t:\n1)%i - %s\n2)%i - %s\n3)%i - %s\n\n%t %i\n%t %i", "top_3", Damage[top[0]], s, Damage[top[1]], s1, Damage[top[2]], s2, "damage_fx", Damage[i], "scores", RoundFloat(Damage[i]/600.0));
				ShowHudText(i, -1, "%t\n1)%i - %s\n2)%i - %s\n3)%i - %s\n\n%t %i\n%t %i", "top_3", Damage[top[0]], s, Damage[top[1]], s1, Damage[top[2]], s2, "damage_fx", Damage[i], "scores", RoundFloat(Damage[i] / 600.0));
			}
		}
	}
	CalcScores();
	return Plugin_Continue;
}
public Action:Timer_NineThousand(Handle:timer)
{
	EmitSoundToAll("saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
}
CalcScores()
{
	decl j, damage;
	botqueuepoints += 5;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			damage = Damage[i];
			new Handle:aevent = CreateEvent("player_escort_score", true);
			SetEventInt(aevent, "player", i);
			for (j = 0; damage - 600 > 0; damage -= 600, j++) {}
			SetEventInt(aevent, "points", j);
			FireEvent(aevent);
			if (i == Hale)
			{
				if (IsFakeClient(Hale)) botqueuepoints = 0;
				else SetClientQueuePoints(i, 0);
			}
			else
			{
				CPrintToChat(i, "{olive}[VSH]{default} %t", "add_points", 10);
				SetClientQueuePoints(i, GetClientQueuePoints(i)+10);
			}
		}
	}
}
public Action:StartResponceTimer(Handle:hTimer)
{
	decl String:s[PLATFORM_MAX_PATH];
	decl Float:pos[3];
	switch (Special)
	{
		case 1:
		{
			if (!GetRandomInt(0, 1))
				strcopy(s, PLATFORM_MAX_PATH, VagineerStart);
			else
				strcopy(s, PLATFORM_MAX_PATH, VagineerRoundStart);
		}
		case 2: Format(s, PLATFORM_MAX_PATH, "ui/halloween_boss_summoned_fx.wav");
		case 4: strcopy(s, PLATFORM_MAX_PATH, CBS0);
		default:
		{
			if (!GetRandomInt(0, 1))
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, GetRandomInt(1, 5));
			else
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStart132, GetRandomInt(1, 5));
		}
	}
	EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
	if (Special == 4)
	{
		EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
		EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
	}
	return Plugin_Continue;
}
public Action:StartHaleTimer(Handle:hTimer)
{
	CreateTimer(0.1, GottamTimer);
	if (!IsValidClient(Hale))
	{
		VSHRoundState = 2;
		return Plugin_Continue;
	}
	if (!IsPlayerAlive(Hale))
	{
		TF2_RespawnPlayer(Hale);
	}
	playing = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && (client != Hale) && IsPlayerAlive(client))
		{
			playing++;
			CreateTimer(0.15, MakeNoHale, GetClientUserId(client));
		}
	}
	if (playing < 5)
		playing += 2;
	HaleHealthMax = RoundFloat(Pow(((760.0+playing)*(playing-1)), 1.04));
	if (HaleHealthMax == 0)
		HaleHealthMax = 1322;
	SetEntProp(Hale, Prop_Data, "m_iMaxHealth", HaleHealthMax);
	SetEntProp(Hale, Prop_Data, "m_iHealth", HaleHealthMax);
	SetEntProp(Hale, Prop_Send, "m_iHealth", HaleHealthMax);
	HaleHealth = HaleHealthMax;
	HaleHealthLast = HaleHealth;
	CreateTimer(0.2, CheckAlivePlayers);
	CreateTimer(0.2, HaleTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, StartRound);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (!PointType)
	{
		SetControlPoint(false);
	}
	if ((Special == 2 || Special == 4) && VSHRoundState == 0)
	{
		CreateTimer(2.0, Timer_MusicPlay, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}
public Action:Timer_MusicPlay(Handle:timer)
{
	if (VSHRoundState != 1) return Plugin_Stop;
	if (Special == 4)
		EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, CBSTheme, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	else
		EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, HHHTheme, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	if (MusicTimer != INVALID_HANDLE)
	{
		KillTimer(MusicTimer);
		MusicTimer = INVALID_HANDLE;
	}
	if (Special == 4)
		MusicTimer = CreateTimer(137.0, Timer_MusicTheme, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	else
		MusicTimer = CreateTimer(87.0, Timer_MusicTheme, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	return Plugin_Continue;
}
public Action:Timer_MusicTheme(Handle:timer)
{
	if (Enabled && VSHRoundState == 1 && (Special == 2 || Special == 4))
	{
		if (Special == 4)
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, CBSTheme, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
		else
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, HHHTheme, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	}
	else
	{
		MusicTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
stock EmitSoundToAllExcept(exceptiontype = SOUNDEXCEPT_MUSIC, const String:sample[],
				 entity = SOUND_FROM_PLAYER,
				 channel = SNDCHAN_AUTO,
				 level = SNDLEVEL_NORMAL,
				 flags = SND_NOFLAGS,
				 Float:volume = SNDVOL_NORMAL,
				 pitch = SNDPITCH_NORMAL,
				 speakerentity = -1,
				 const Float:origin[3] = NULL_VECTOR,
				 const Float:dir[3] = NULL_VECTOR,
				 bool:updatePos = true,
				 Float:soundtime = 0.0)
{
	new clients[MaxClients];
	new total = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && CheckSoundException(i, exceptiontype))
		{
			clients[total++] = i;
		}
	}
	if (!total)
	{
		return;
	}
	EmitSound(clients, total, sample, entity, channel,
		level, flags, volume, pitch, speakerentity,
		origin, dir, updatePos, soundtime);
}
stock bool:CheckSoundException(client, excepttype)
{
	if (!IsValidClient(client)) return false;
	if (IsFakeClient(client)) return true;
	if (!AreClientCookiesCached(client)) return true;
	decl String:strCookie[32];
	if (excepttype == SOUNDEXCEPT_VOICE) GetClientCookie(client, VoiceCookie, strCookie, sizeof(strCookie));
	else GetClientCookie(client, MusicCookie, strCookie, sizeof(strCookie));
	if (strCookie[0] == 0) return true;
	else return bool:StringToInt(strCookie);
}

SetClientSoundOptions(client, excepttype, bool:on)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	new String:strCookie[32];
	if (on) strCookie = "1";
	else strCookie = "0";
	if (excepttype == SOUNDEXCEPT_VOICE) SetClientCookie(client, VoiceCookie, strCookie);
	else SetClientCookie(client, MusicCookie, strCookie);
}
public Action:GottamTimer(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsValidClient(i) && IsPlayerAlive(i))
			SetEntityMoveType(i, MOVETYPE_WALK);
}
public Action:StartRound(Handle:hTimer)
{
	VSHRoundState = 1;
	if (IsValidClient(Hale))
	{
		if (!IsPlayerAlive(Hale) && TFTeam:GetClientTeam(Hale) != TFTeam_Spectator && TFTeam:GetClientTeam(Hale) != TFTeam_Unassigned)
		{
			TF2_RespawnPlayer(Hale);
		}
		if (GetClientTeam(Hale) != HaleTeam)
		{
			ChangeClientTeam(Hale, HaleTeam);
			TF2_RespawnPlayer(Hale);
		}
		if (GetClientTeam(Hale) == HaleTeam && !IsValidEntity(GetPlayerWeaponSlot(Hale, TFWeaponSlot_Melee)))
		{
			CreateTimer(0.05, Timer_ReEquipSaxton, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	CreateTimer(10.0, Timer_SkipHalePanel);
	return Plugin_Continue;
}
public Action:Timer_ReEquipSaxton(Handle:timer)
{
	if (IsValidClient(Hale))
	{
		EquipSaxton(Hale);
	}
}
public Action:Timer_SkipHalePanel(Handle:hTimer)
{
	new bool:added[MAXPLAYERS + 1];
	new i, j;
	new client = Hale;
	do
	{
		client = FindNextHale(added);
		added[client]=true;
		if (IsValidClient(client) && client != Hale)
		{
			if (!IsFakeClient(client)) CPrintToChat(client, "{olive}[VSH]{default} %t", "to0_near");
//			Do some notification here
			i++;
		}
		j++;
	}
	while (i < 3 && j < MAXPLAYERS + 1);
}
public Action:EnableSG(Handle:hTimer, any:iid)
{
	new i = EntRefToEntIndex(iid);
	if (VSHRoundState == 1 && IsValidEdict(i) && i > MaxClients)
	{
		decl String:s[64];
		GetEdictClassname(i, s, 64);
		if (StrEqual(s, "obj_sentrygun"))
		{
			SetEntProp(i, Prop_Send, "m_bDisabled", 0);
			for (new ent = MaxClients+1; ent < ME; ent++)
			{
				if (IsValidEdict(ent))
				{
					new String:s2[64];
					GetEdictClassname(ent, s2, 64);
					if (StrEqual(s2, "info_particle_system") && (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == i))
					{
						AcceptEntityInput(ent, "Kill");
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:RemoveEnt(Handle:timer, any:entid)
{
	new ent = EntRefToEntIndex(entid);
	if (ent > 0 && IsValidEntity(ent))
		AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}
public Action:MessageTimer(Handle:hTimer, any:client)
{
	if (!IsValidClient(Hale) || ((client != 9001) && !IsValidClient(client)))
		return Plugin_Continue;
	if (strcmp(currentmap, "arena_nucleus", false) != 0)
	{
		new ent = -1;
		while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)
		{
			AcceptEntityInput(ent, "Open");
			AcceptEntityInput(ent, "Unlock");
		}
		if (doorchecktimer == INVALID_HANDLE)
			doorchecktimer = CreateTimer(5.0, Timer_CheckDoors, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	decl String:translation[32];
	switch (Special)
	{
		case 1: strcopy(translation, sizeof(translation), "start_vagineer");
		case 2: strcopy(translation, sizeof(translation), "start_hhh");
		case 4: strcopy(translation, sizeof(translation), "start_cbs");
		default: strcopy(translation, sizeof(translation), "start_hale");
	}
	SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
	if (client != 9001)
		ShowHudText(client, -1, "%T", translation, client, Hale, HaleHealthMax);
	else
		for (new i = 1; i <= MaxClients; i++)
			if (IsValidClient(i))
				ShowHudText(i, -1, "%T", translation, i, Hale, HaleHealthMax);
	return Plugin_Continue;
}
public Action:MakeModelTimer(Handle:hTimer)
{
	if (!IsValidClient(Hale) || !IsPlayerAlive(Hale) || VSHRoundState == 2)
	{
		return Plugin_Stop;
	}
	new body = 0;
	switch (Special)
	{
		case 1:
		{
			SetVariantString(VagineerModel);
			SetEntProp(Hale, Prop_Send, "m_nSkin", GetClientTeam(Hale)-2);
		}
		case 2:
			SetVariantString(HHHModel);
		case 4:
			SetVariantString(CBSModel);
		default:
		{
			SetVariantString(HaleModel);
//			decl String:steamid[32];
//			GetClientAuthString(Hale, steamid, sizeof(steamid));
			if (GetUserFlagBits(Hale) & ADMFLAG_CUSTOM1) body = (1 << 0)|(1 << 1);
		}
	}
//	DispatchKeyValue(Hale, "targetname", "hale");
	AcceptEntityInput(Hale, "SetCustomModel");
	SetEntProp(Hale, Prop_Send, "m_bUseClassAnimations", 1);
	SetEntProp(Hale, Prop_Send, "m_nBody", body);
	return Plugin_Continue;
}
EquipSaxton(client)
{
	bEnableSuperDuperJump = false;
	new SaxtonWeapon;
	TF2_RemoveAllWeapons(client);
	HaleCharge = 0;
	switch (Special)
	{
		case 1:
		{
			SaxtonWeapon = SpawnWeapon(client, "tf_weapon_wrench", 197, 100, 5, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0");
			SetEntProp(SaxtonWeapon, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
		}
		case 2:
		{
			SaxtonWeapon = SpawnWeapon(client, "tf_weapon_sword", 266, 100, 5, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0");
			SetEntProp(SaxtonWeapon, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
			HaleCharge = -500;
		}
		case 4:
		{
			SaxtonWeapon = SpawnWeapon(client, "tf_weapon_club", 171, 100, 5, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0");
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
			SetEntProp(client, Prop_Send, "m_nBody", 0);
		}
		default:
		{
			decl String:attribs[64];
			Format(attribs, sizeof(attribs), "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 214 ; %d", GetRandomInt(9999, 99999));
			SaxtonWeapon = SpawnWeapon(client, "tf_weapon_shovel", 5, 100, 4, attribs);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
		}
	}
}
public Action:MakeHale(Handle:hTimer)
{
	if (!IsValidClient(Hale))
		return Plugin_Continue;
	switch (Special)
	{
		case 0:
			TF2_SetPlayerClass(Hale, TFClass_Soldier, _, false);
		case 1:
			TF2_SetPlayerClass(Hale, TFClass_Engineer, _, false);
		case 2, 5:
			TF2_SetPlayerClass(Hale, TFClass_DemoMan, _, false);
		case 4:
			TF2_SetPlayerClass(Hale, TFClass_Sniper, _, false);
	}
	ChangeClientTeam(Hale, HaleTeam);
	if (VSHRoundState < 0)
		return Plugin_Continue;
	if (!IsPlayerAlive(Hale))
	{
		if (VSHRoundState == 0) TF2_RespawnPlayer(Hale);
		else return Plugin_Continue;
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	ClientCommand(Hale, "r_screenoverlay \"\"");
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
	CreateTimer(0.2, MakeModelTimer, _);
	CreateTimer(20.0, MakeModelTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	new ent = -1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == Hale)
		{
			new index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
			switch (index)
			{
				case 438, 463, 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536: {}
				default:	AcceptEntityInput(ent, "kill");
			}
		}
	}
	ent = -1;
	while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == Hale)
			AcceptEntityInput(ent, "kill");
	}
	EquipSaxton(Hale);
	HintPanel(Hale);
	return Plugin_Continue;
}
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if (!Enabled2) return Plugin_Continue;
//	if (client == Hale) return Plugin_Continue;
	if (hItem != INVALID_HANDLE) return Plugin_Continue;
	switch (iItemDefinitionIndex)
	{
		case 226:
		{
//			new Handle:hItemOverride = PrepareItemHandle(_, _, "116 ; 4.0", true);
			new Handle:hItemOverride = PrepareItemHandle(_, _, "140 ; 10.0");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 305:
		{
			new Handle:hItemOverride = PrepareItemHandle(_, _, "17 ; 0.1 ; 2 ; 2.0"); // ; 266 ; 1.0");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 56:
		{
			new Handle:hItemOverride = PrepareItemHandle(_, _, "2 ; 1.5");
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 38, 457:
		{
			new Handle:hItemOverride = PrepareItemHandle(_, _, "", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
//		case 132, 266, 482:
//		{
//			new Handle:hItemOverride = PrepareItemHandle(_, _, "202 ; 0.5 ; 125 ; -15", true);
//			if (hItemOverride != INVALID_HANDLE)
//			{
//				hItem = hItemOverride;
//				return Plugin_Changed;
//			}
//		}
		case 43, 239:
		{
			new Handle:hItemOverride = PrepareItemHandle(_, 239, "107 ; 1.5 ; 1 ; 0.5 ; 128 ; 1 ; 191 ; -7", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
		case 415:
		{
			new Handle:hItemOverride = PrepareItemHandle(_, _, "265 ; 99999.0 ; 178 ; 0.6 ; 2 ; 1.1 ; 3 ; 0.5", true);
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
//		case 526:
	}
	if (TF2_GetPlayerClass(client) == TFClass_Soldier && (strncmp(classname, "tf_weapon_rocketlauncher", 24, false) == 0 || strncmp(classname, "tf_weapon_shotgun", 17, false) == 0))
	{
		new Handle:hItemOverride;
		if (iItemDefinitionIndex == 127) hItemOverride = PrepareItemHandle(_, _, "265 ; 99999.0 ; 179 ; 1.0");
		else hItemOverride = PrepareItemHandle(_, _, "265 ; 99999.0");
		if (hItemOverride != INVALID_HANDLE)
		{
			hItem = hItemOverride;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
stock Handle:PrepareItemHandle(String:name[] = "", index = -1, const String:att[] = "", bool:dontpreserve = false)
{
	new String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(att, " ; ", weaponAttribsArray, 32, 32);
	new flags = OVERRIDE_ATTRIBUTES;
	if (!dontpreserve) flags |= PRESERVE_ATTRIBUTES;
	new Handle:hWeapon = TF2Items_CreateItem(flags);
	if (name[0] != '\0')
	{
		flags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(hWeapon, name);
	}
	if (index != -1)
	{
		flags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(hWeapon, index);
	}
	if (attribCount > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, attribCount/2);
		new i2 = 0;
		for (new i = 0; i < attribCount; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	TF2Items_SetFlags(hWeapon, flags);
	return hWeapon;
}
public Action:MakeNoHale(Handle:hTimer, any:clientid)
{
	new client = GetClientOfUserId(clientid);
	if (!IsValidClient(client) || !IsPlayerAlive(client) || VSHRoundState == 2 || client == Hale)
		return Plugin_Continue;
//	SetVariantString("");
//	AcceptEntityInput(client, "SetCustomModel");
	ChangeClientTeam(client, OtherTeam);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	if (!VSHRoundState && GetClientClasshelpinfoCookie(client))
		HelpPanel2(client);
	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new index = -1;
	if (weapon > MaxClients && IsValidEdict(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
			case 41:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				weapon = SpawnWeapon(client, "tf_weapon_minigun", 15, 1, 0, "");
			}
			case 402:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_sniperrifle", 14, 1, 0, "");
			}
			case 237:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				weapon = SpawnWeapon(client, "tf_weapon_rocketlauncher", 18, 1, 0, "265 ; 99999.0");
				SetAmmo(client, 0, 20);
			}
			case 17, 204, 36, 412:
			{
				if (GetEntProp(weapon, Prop_Send, "m_iEntityQuality") != 10)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
					SpawnWeapon(client, "tf_weapon_syringegun_medic", 17, 1, 10, "17 ; 0.05 ; 144 ; 1");
				}
			}
		}
	}
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (weapon > MaxClients && IsValidEdict(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
//			case 226:
//			{
//				TF2_RemoveWeaponSlot(client, 1);
//				weapon = SpawnWeapon(client, "tf_weapon_shotgun_soldier", 10, 1, 0, "");
//			}
			case 57, 58, 231:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = SpawnWeapon(client, "tf_weapon_smg", 16, 1, 0, "");
			}
			case 265:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				weapon = SpawnWeapon(client, "tf_weapon_pipebomblauncher", 20, 1, 0, "");
				SetAmmo(client, 1, 24);
			}
			case 39, 351:
			{
				if (GetEntProp(weapon, Prop_Send, "m_iEntityQuality") != 10)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					weapon = SpawnWeapon(client, "tf_weapon_flaregun", 39, 5, 10, "25 ; 0.5 ; 207 ; 1.33 ; 144 ; 1.0 ; 58 ; 5.0");
				}
			}
		}
	}
	if (FindPlayerBack(client))
	{
		RemovePlayerBack(client);
		weapon = SpawnWeapon(client, "tf_weapon_smg", 16, 1, 0, "");
	}
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if (weapon > MaxClients && IsValidEdict(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
			case 331:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				weapon = SpawnWeapon(client, "tf_weapon_fists", 195, 1, 6, "");
			}
			case 355:
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				weapon = SpawnWeapon(client, "tf_weapon_bat", 0, 1, 0, "");
			}
			case 357:
			{
				CreateTimer(1.0, Timer_NoHonorBound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	weapon = GetPlayerWeaponSlot(client, 4);
	if (weapon > MaxClients && IsValidEdict(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 60)
	{
		TF2_RemoveWeaponSlot(client, 4);
		weapon = SpawnWeapon(client, "tf_weapon_invis", 297, 1, 6, "");
	}
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		new mediquality = (weapon > MaxClients && IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iEntityQuality") : -1);
		if (mediquality != 10)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			weapon = SpawnWeapon(client, "tf_weapon_medigun", 35, 5, 10, "10 ; 1.25 ; 178 ; 0.75");	//200 ; 1 for area of effect healing	// ; 178 ; 0.75 ; 128 ; 1.0 Faster switch-to
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 0.41);
		}
	}
	return Plugin_Continue;
}
public Action:Timer_NoHonorBound(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		new index = ((IsValidEntity(weapon) && weapon > MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
		new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:classname[64];
		if (IsValidEdict(active)) GetEdictClassname(active, classname, sizeof(classname));
		if (index == 357 && active == weapon && strcmp(classname, "tf_weapon_katana", false) == 0)
		{
			SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
			if (GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
				SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
		}
	}
}
stock RemovePlayerBack(client)
{
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 57 || idx == 231) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				RemoveEdict(edict);
			}
		}
	}
}
stock FindPlayerBack(client)
{
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 57 || idx == 231) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return true;
			}
		}
	}
	return false;
}
public Action:event_destroy(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Enabled)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new customkill = GetEventInt(event, "customkill");
		if (attacker == Hale) /* || (attacker == Companion)*/
		{
			if (!Special)
			{
				if (customkill != TF_CUSTOM_BOOTS_STOMP) SetEventString(event, "weapon", "fists");
				if (!GetRandomInt(0, 4))
				{
					decl String:s[PLATFORM_MAX_PATH];
					strcopy(s, PLATFORM_MAX_PATH, HaleSappinMahSentry132);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:event_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == Hale)
	{
		switch(Special)
		{
			case 0: if (TF2_GetPlayerClass(client) != TFClass_Soldier)
				TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
			case 1: if (TF2_GetPlayerClass(client) != TFClass_Engineer)
				TF2_SetPlayerClass(client, TFClass_Engineer, _, false);
			case 2: if (TF2_GetPlayerClass(client) != TFClass_DemoMan)
				TF2_SetPlayerClass(client, TFClass_DemoMan, _, false);
			case 4: if (TF2_GetPlayerClass(client) != TFClass_Sniper)
				TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
		}
	}
	return Plugin_Continue;
}
public Action:event_uberdeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:s[64];
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if (IsValidEntity(medigun))
		{
			GetEdictClassname(medigun, s, sizeof(s));
			if (strcmp(s, "tf_weapon_medigun", false) == 0)
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				new target = GetHealingTarget(client);
				if (IsValidClient(target, false) && IsPlayerAlive(target))
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 1.51);
//				VSHFlags[client] &= ~VSHFLAG_UBERREADY;
				CreateTimer(0.4, Timer_Lazor, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}
public Action:Timer_Lazor(Handle:hTimer, any:medigunid)
{
	new medigun = EntRefToEntIndex(medigunid);
	if (medigun && IsValidEntity(medigun) && VSHRoundState == 1)
	{
		new client = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		new Float:charge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == medigun)
		{
			new target = GetHealingTarget(client);
			if (charge > 0.05)
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if (IsValidClient(target, false) && IsPlayerAlive(target))
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
			}
		}
		if (charge <= 0.05)
		{
			CreateTimer(3.0, Timer_Lazor2, EntIndexToEntRef(medigun));
			VSHFlags[client] &= ~VSHFLAG_UBERREADY;
			return Plugin_Stop;
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}
public Action:Timer_Lazor2(Handle:hTimer, any:medigunid)
{
	new medigun = EntRefToEntIndex(medigunid);
	if (IsValidEntity(medigun))
		SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+0.31);
	return Plugin_Continue;
}
public Action:Command_GetHPCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	Command_GetHP(client);
	return Plugin_Handled;
}
public Action:Command_GetHP(client)
{
	if (!Enabled || VSHRoundState != 1)
		return Plugin_Continue;
	if (client == Hale)
	{
		switch (Special)
		{
			case 1:
				PrintCenterTextAll("%t", "vagineer_show_hp", HaleHealth, HaleHealthMax);
			case 2:
				PrintCenterTextAll("%t", "hhh_show_hp", HaleHealth, HaleHealthMax);
			case 4:
				PrintCenterTextAll("%t", "cbs_show_hp", HaleHealth, HaleHealthMax);
			default:
				PrintCenterTextAll("%t", "hale_show_hp", HaleHealth, HaleHealthMax);
		}
		HaleHealthLast = HaleHealth;
		return Plugin_Continue;
	}
	if (RoundFloat(HPTime) <= 0)
	{
		healthcheckused++;
		switch (Special)
		{
			case 1:
			{
				PrintCenterTextAll("%t", "vagineer_hp", HaleHealth, HaleHealthMax);
				CPrintToChatAll("{olive}[VSH]{default} %t", "vagineer_hp", HaleHealth, HaleHealthMax);
			}
			case 2:
			{
				PrintCenterTextAll("%t", "hhh_hp", HaleHealth, HaleHealthMax);
				CPrintToChatAll("{olive}[VSH]{default} %t", "hhh_hp", HaleHealth, HaleHealthMax);
			}
			case 4:
			{
				PrintCenterTextAll("%t", "cbs_hp", HaleHealth, HaleHealthMax);
				CPrintToChatAll("{olive}[VSH]{default} %t", "cbs_hp", HaleHealth, HaleHealthMax);
			}
			default:
			{
				PrintCenterTextAll("%t", "hale_hp", HaleHealth, HaleHealthMax);
				CPrintToChatAll("{olive}[VSH]{default} %t", "hale_hp", HaleHealth, HaleHealthMax);
			}
		}
		HaleHealthLast = HaleHealth;
		HPTime = (healthcheckused < 3 ? 20.0 : 80.0);
	}
	else if (RedAlivePlayers == 1)
		CPrintToChat(client, "{olive}[VSH]{default} %t", "already_see");
	else
		CPrintToChat(client, "{olive}[VSH]{default} %t", "wait_hp", RoundFloat(HPTime), HaleHealthLast);
	return Plugin_Continue;
}
public Action:Command_MakeNextSpecial(client, args)
{
	decl String:arg[32];
	decl String:name[64];
	if (args < 1)
	{
		ReplyToCommand(client, "[VSH] Usage: hale_special <hale, vagineer, hhh, christian>");
		return Plugin_Handled;
	}
	GetCmdArgString(arg, sizeof(arg));
	if (StrContains(arg, "hal", false) != -1)
	{
		Incoming = 0;
		name = "Saxton Hale";
	}
	else if (StrContains(arg, "vag", false) != -1)
	{
		Incoming = 1;
		name = "the Vagineer";
	}
	else if (StrContains(arg, "hhh", false) != -1)
	{
		Incoming = 2;
		name = "the Horseless Headless Horsemann Jr.";
	}
	else if (StrContains(arg, "chr", false) != -1)
	{
		Incoming = 4;
		name = "the Christian Brutal Sniper";
	}
	else
	{
		ReplyToCommand(client, "[VSH] Usage: hale_special <hale, vagineer, hhh, christian>");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[VS Saxton Hale] Set the next Special to %s", name);
	return Plugin_Handled;
}
public Action:Command_NextHale(client, args)
{
	if (Enabled)
		CreateTimer(0.2, MessageTimer);
	return Plugin_Continue;
}
public Action:Command_HaleSelect(client, args)
{
	if (!Enabled2)
		return Plugin_Continue;
	if (args < 1)
	{
		ReplyToCommand(client, "[VSH] Usage: hale_select <target> [\"hidden\"]");
		return Plugin_Handled;
	}
	decl String:s2[80];
	decl String:targetname[32];
	GetCmdArg(1, targetname, sizeof(targetname));
	GetCmdArg(2, s2, sizeof(s2));
	if (strcmp(targetname, "@me", false) == 0 && IsValidClient(client))
		ForceHale(client, client, StrContains(s2, "hidden", false) > 0);
	else
	{
		new target = FindTarget(client, targetname);
		if (IsValidClient(target))
		{
			ForceHale(client, target, StrContains(s2, "hidden", false) >= 0);
		}
	}
	return Plugin_Handled;
}
public Action:Command_Points(client, args)
{
	if (!Enabled2)
		return Plugin_Continue;
	if (args != 2)
	{
		ReplyToCommand(client, "[VSH] Usage: hale_addpoints <target> <points>");
		return Plugin_Handled;
	}
	decl String:s2[80];
	decl String:targetname[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetname, sizeof(targetname));
	GetCmdArg(2, s2, sizeof(s2));
	new points = StringToInt(s2);
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			targetname,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		SetClientQueuePoints(target_list[i], GetClientQueuePoints(target_list[i])+points);
	}
	ReplyToCommand(client, "[VSH] Added %d queue points to %s", points, target_name);
	return Plugin_Handled;
}
stock StopHaleMusic(client)
{
	if (!IsValidClient(client)) return;
	StopSound(client, SNDCHAN_AUTO, HHHTheme);
	StopSound(client, SNDCHAN_AUTO, CBSTheme);
}
public Action:Command_StopMusic(client, args)
{
	if (!Enabled2)
		return Plugin_Continue;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		StopHaleMusic(i);
	}
	ReplyToCommand(client, "[VSH] Stopped boss music.");
	return Plugin_Handled;
}
public Action:Command_Point_Disable(client, args)
{
	if (Enabled) SetControlPoint(false);
	return Plugin_Handled;
}
public Action:Command_Point_Enable(client, args)
{
	if (Enabled) SetControlPoint(true);
	return Plugin_Handled;
}
stock SetControlPoint(bool:enable)
{
	new CPm=-1;	//CP = -1;
	while ((CPm = FindEntityByClassname2(CPm, "team_control_point")) != -1)
	{
		if (CPm > MaxClients && IsValidEdict(CPm))
		{
			AcceptEntityInput(CPm, (enable ? "ShowModel" : "HideModel"));
			SetVariantInt(enable ? 0 : 1);
			AcceptEntityInput(CPm, "SetLocked");
		}
	}
}
stock ForceHale(admin, client, bool:hidden, bool:forever = false)
{
	if (forever)
		Hale = client;
	else
		NextHale = client;
	if (!hidden)
	{
		CPrintToChatAllEx(client, "{olive}[VSH] {teamcolor}%N {default}%t", client, "hale_select_text");
	}
}
public OnClientPutInServer(client)
{
	VSHFlags[client] = 0;
//	MusicDisabled[client] = false;
//	VoiceDisabled[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	//bSkipNextHale[client] = false;
	Damage[client] = 0;
}
public OnClientDisconnect(client)
{
	Damage[client] = 0;
	if (Enabled)
	{
		if (client == Hale)
		{
			if (VSHRoundState == 1)
				ForceTeamWin(OtherTeam);
			if (VSHRoundState == 0)
			{
				new bool:see[MAXPLAYERS + 1];
				see[Hale] = true;
				new tHale = FindNextHale(see);
				if (NextHale > 0)
				{
					tHale = NextHale;
					NextHale = -1;
				}
				if (IsValidClient(tHale))
				{
					Hale = tHale;
					ChangeClientTeam(Hale, HaleTeam);
					TF2_RespawnPlayer(Hale);
					CPrintToChat(Hale, "{olive}[VSH]{default} Surprise! You're on NOW!");
				}
			}
			CPrintToChatAll("{olive}[VSH]{default} %t", "hale_disconnected");
		}
		else
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				CheckAlivePlayers(INVALID_HANDLE);
			}
			if (client == NextHale)
			{
				NextHale = -1;
			}
		}
	}
}
public Action:AdminUpdateTimer(Handle:hTimer, any:clientid)
{
	new client = GetClientOfUserId(clientid);
	if (IsValidClient(client))
		PrintHintText(client, "%t", "new_update");
	return Plugin_Continue;
}
public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client, false))
		return Plugin_Continue;
	if (!Enabled)
		return Plugin_Continue;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	if (client == Hale && VSHRoundState < 2 && VSHRoundState != -1)
		CreateTimer(0.1, MakeHale);
	else if (VSHRoundState >= 0)
		CreateTimer(0.1, MakeNoHale, GetClientUserId(client));
	if (!(VSHFlags[client] & VSHFLAG_HELPED))
	{
		HelpPanel(client);
		VSHFlags[client] |= VSHFLAG_HELPED;
	}
	VSHFlags[client] &= ~VSHFLAG_UBERREADY;
	return Plugin_Continue;
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (Enabled && client == Hale && Special == 2 && HaleCharge >= 47 && (buttons & IN_ATTACK))
	{
		buttons &= ~IN_ATTACK;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action:ClientTimer(Handle:hTimer)
{
	if (VSHRoundState > 1 || VSHRoundState == -1)
	{
		return Plugin_Stop;
	}
	new i = -1;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && client != Hale && GetClientTeam(client) == OtherTeam)
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			if (!IsPlayerAlive(client))
			{
				new obstarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (IsValidClient(obstarget) && obstarget != Hale && obstarget != client)
					ShowSyncHudText(client, rageHUD, "Damage: %d - %N's Damage: %d", Damage[client], obstarget, Damage[obstarget]);
				else
					ShowSyncHudText(client, rageHUD, "Damage: %d", Damage[client]);
				continue;
			}
			ShowSyncHudText(client, rageHUD, "Damage: %d", Damage[client]);
			if (!IsPlayerAlive(client)) continue;
			new TFClassType:class = TF2_GetPlayerClass(client);
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new bool:validwep = (weapon > MaxClients && IsValidEntity(weapon));
			new index = (validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if (class == TFClass_Medic)
			{
				if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					decl String:mediclassname[64];
					if (IsValidEdict(medigun) && GetEdictClassname(medigun, mediclassname, sizeof(mediclassname)) && strcmp(mediclassname, "tf_weapon_medigun", false) == 0)
					{
						SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
						new charge = RoundFloat(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") * 100);
						ShowSyncHudText(client, jumpHUD, "%T: %i", "uber-charge", client, charge);
						if (charge == 100 && !(VSHFlags[client] & VSHFLAG_UBERREADY))
						{
							FakeClientCommandEx(client, "voicemenu 1 7");
							VSHFlags[client] |= VSHFLAG_UBERREADY;
						}
					}
				}
				if (weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				{
					new healtarget = GetHealingTarget(client);
					if (IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget) == TFClass_Scout)
					{
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
					}
				}
			}
//			else if (AirBlastReload[client]>0)
//			{
//				SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
//				ShowHudText(client, -1, "%t", "airblast", RoundFloat(AirBlastReload[client])+1);
//				AirBlastReload[client]-=0.2;
//			}
			if (RedAlivePlayers == 1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				if (class == TFClass_Engineer && (IsValidEntity(primary) && primary > MaxClients ? GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex") : -1) == 141) SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
				continue;
			}
			if (RedAlivePlayers == 2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
			new TFCond:cond = TFCond_HalloweenCritCandy;
			if (TF2_IsPlayerInCondition(client, TFCond_CritCola) && (class == TFClass_Scout || class == TFClass_Heavy))
			{
				TF2_AddCondition(client, cond, 0.3);
				continue;
			}
			new bool:addmini = false;
			for (i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && GetHealingTarget(i) == client)
				{
					addmini = true;
					break;
				}
			}
			new bool:addthecrit = false;
			if (validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && index != 4 && index != 194 && index != 225 && index != 356 && index != 461) addthecrit = true;	//class != TFClass_Spy
			switch (index)
			{
				case 305, 14, 56, 201, 230, 402, 16, 203, 58, 526: addthecrit = true;
				case 22, 23, 160, 209, 294, 449:
				{
					addthecrit = true;
					if (class == TFClass_Scout && cond == TFCond_HalloweenCritCandy) cond = TFCond_Buffed;
				}
			}
			if (class == TFClass_DemoMan && !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))) addthecrit = true;
			if (addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if (addmini && cond != TFCond_Buffed) TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}
			if (class == TFClass_Spy && validwep && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
			{
				if (!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))
				{
					TF2_AddCondition(client, TFCond_CritCola, 0.3);
				}
			}
			if (class == TFClass_Engineer && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && index == 141)
			{
				new sentry = FindSentry(client);
				if (IsValidEntity(sentry) && GetEntPropEnt(sentry, Prop_Send, "m_hEnemy") == Hale)
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
					TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
				}
				else
				{
					if (GetEntProp(client, Prop_Send, "m_iRevengeCrits")) SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
					else if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
					{
						TF2_RemoveCondition(client, TFCond_Kritzkrieged);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
stock FindSentry(client)
{
	new i=-1;
	while ((i = FindEntityByClassname2(i, "obj_sentrygun")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client) return i;
	}
	return -1;
}
public Action:HaleTimer(Handle:hTimer)
{
	if (VSHRoundState == 2)
	{
		if (IsValidClient(Hale, false) && IsPlayerAlive(Hale)) TF2_AddCondition(Hale, TFCond_SpeedBuffAlly, 14.0);
		return Plugin_Stop;
	}
	if (!IsValidClient(Hale))
		return Plugin_Continue;
	if (TF2_IsPlayerInCondition(Hale, TFCond_Jarated))
		TF2_RemoveCondition(Hale, TFCond_Jarated);
//	if ((Special==4) && (UberRageCount<=0) && (GetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(Hale, 2)))
//		SetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(Hale, 2));

	new Float:speed = HaleSpeed + 0.7 * (100 - HaleHealth * 100 / HaleHealthMax);
	SetEntPropFloat(Hale, Prop_Send, "m_flMaxspeed", speed);
	SetEntProp(Hale, Prop_Data, "m_iHealth", HaleHealth);
	SetEntProp(Hale, Prop_Send, "m_iHealth", HaleHealth);
	SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
	SetGlobalTransTarget(Hale);
	ShowSyncHudText(Hale, healthHUD, "%t", "health", HaleHealth, HaleHealthMax);
	if (HaleRage/RageDMG >= 1)
	{
		SetHudTextParams(-1.0, 0.83, 0.35, 255, 64, 64, 255);
		ShowSyncHudText(Hale, rageHUD, "%t", "do_rage");
	}
	else
	{
		SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255);
		ShowSyncHudText(Hale, rageHUD, "%t", "rage_meter", HaleRage*100/RageDMG);
	}
	SetHudTextParams(-1.0, 0.88, 0.35, 255, 255, 255, 255);
	if (GlowTimer <= 0.0)
	{
		SetEntProp(Hale, Prop_Send, "m_bGlowEnabled", 0);
		GlowTimer = 0.0;
	}
	else
		GlowTimer -= 0.2;
	if (bEnableSuperDuperJump)
	{
		if (HaleCharge <= 0)
		{
			HaleCharge = 0;
			ShowSyncHudText(Hale, jumpHUD, "%t", "super_duper_jump");
		}
		SetHudTextParams(-1.0, 0.88, 0.35, 255, 64, 64, 255);
	}

	new buttons = GetClientButtons(Hale);
	if (((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && (HaleCharge >= 0) && !(buttons & IN_JUMP))
	{
		if (Special == 2)
		{
			if (HaleCharge + 5 < 50)
				HaleCharge += 5;
			else
				HaleCharge = 50;
			ShowSyncHudText(Hale, jumpHUD, "%t", "teleport_status", HaleCharge*2);
		}
		else
		{
			if (HaleCharge + 5 < 25)
				HaleCharge += 5;
			else
				HaleCharge = 25;
			ShowSyncHudText(Hale, jumpHUD, "%t", "jump_status", HaleCharge*4);
		}
	}
	else if (HaleCharge < 0)
	{
		HaleCharge += 5;
		if (Special == 2)
			ShowSyncHudText(Hale, jumpHUD, "%t %i", "teleport_status_2", -HaleCharge/20);
		else
			ShowSyncHudText(Hale, jumpHUD, "%t %i", "jump_status_2", -HaleCharge/20);
	}
	else
	{
		decl Float:ang[3];
		GetClientEyeAngles(Hale, ang);
		if ((ang[0] < -45.0) && (HaleCharge > 1))
		{
			new Action:act = Plugin_Continue;
			new bool:super = bEnableSuperDuperJump;
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(super);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return Plugin_Continue;
			if (act == Plugin_Changed) bEnableSuperDuperJump = super;
			decl Float:pos[3];
			if (Special == 2 && (HaleCharge == 50 || bEnableSuperDuperJump))
			{
				decl target;
				do
				{
					target = GetRandomInt(1, MaxClients);
				}
				while ((RedAlivePlayers > 0) && (!IsValidClient(target, false) || (target == Hale) || !IsPlayerAlive(target)));
				if (IsValidClient(target))
				{
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
					TF2_StunPlayer(Hale, (bEnableSuperDuperJump ? 4.0 : 2.0), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
					TeleportEntity(Hale, pos, NULL_VECTOR, NULL_VECTOR);
					CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(Hale, "ghost_appearation")));
					CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(Hale, "ghost_appearation", _, false)));
					HaleCharge=-1100;
				}
				if (bEnableSuperDuperJump)
					bEnableSuperDuperJump = false;
			}
			else if (Special != 2)
			{
				decl Float:vel[3];
				GetEntPropVector(Hale, Prop_Data, "m_vecVelocity", vel);
				if (bEnableSuperDuperJump)
				{
					vel[2]=750 + HaleCharge * 13.0 + 2000;
					bEnableSuperDuperJump = false;
				}
				else
					vel[2]=750 + HaleCharge * 13.0;
				SetEntProp(Hale, Prop_Send, "m_bJumping", 1);
				vel[0] *= (1+Sine(float(HaleCharge) * FLOAT_PI / 50));
				vel[1] *= (1+Sine(float(HaleCharge) * FLOAT_PI / 50));
				TeleportEntity(Hale, NULL_VECTOR, NULL_VECTOR, vel);
				HaleCharge=-120;
				if (!Special || Special == 1 || Special == 4)
				{
					decl String:s[PLATFORM_MAX_PATH];
					GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
					if (!Special && GetRandomInt(0, 1))
						Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump, GetRandomInt(1, 2));
					else if (Special == 1)
						Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, GetRandomInt(1, 2));
					else if (Special == 4)
						strcopy(s, PLATFORM_MAX_PATH, CBSJump1);
					else
					{
						Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump132, GetRandomInt(1, 2));
					}
					EmitSoundToAll(s, Hale, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
					EmitSoundToAll(s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
					for (new i = 1; i <= MaxClients; i++)
						if (IsValidClient(i) && (i != Hale))
						{
							EmitSoundToClient(i, s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
							EmitSoundToClient(i, s, Hale, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, true, 0.0);
						}
				}
			}
		}
		else
			HaleCharge = 0;
	}
	if (RedAlivePlayers == 1)
	{
		switch (Special)
		{
			case 1:
				PrintCenterTextAll("%t", "vagineer_hp", HaleHealth, HaleHealthMax);
			case 2:
				PrintCenterTextAll("%t", "hhh_hp", HaleHealth, HaleHealthMax);
			case 4:
				PrintCenterTextAll("%t", "cbs_hp", HaleHealth, HaleHealthMax);
			default:
				PrintCenterTextAll("%t", "hale_hp", HaleHealth, HaleHealthMax);
		}
	}
	if (OnlyScoutsLeft())
	{
		new Float:rage = 0.001*RageDMG;
		HaleRage += RoundToCeil(rage);
		if (HaleRage > RageDMG)
			HaleRage = RageDMG;
	}
	HPTime -= 0.2;
	if (HPTime < 0)
		HPTime = 0.0;
	if (KSpreeTimer > 0)
		KSpreeTimer -= 0.2;
	if (!(GetEntityFlags(Hale) & FL_ONGROUND)) WeighDownTimer += 0.2;
	else WeighDownTimer = 0.0;
	if (WeighDownTimer >= 4.0 && buttons & IN_DUCK)
	{
		decl Float:ang[3];
		GetClientEyeAngles(Hale, ang);
		if ((ang[0] > 60.0))
		{
			new Action:act = Plugin_Continue;
			Call_StartForward(OnHaleWeighdown);
			Call_Finish(act);
			if (act != Plugin_Continue)
				return Plugin_Continue;
			new Float:fVelocity[3];
			GetEntPropVector(Hale, Prop_Data, "m_vecVelocity", fVelocity);
			fVelocity[2] = -1000.0;
			TeleportEntity(Hale, NULL_VECTOR, NULL_VECTOR, fVelocity);
			SetEntityGravity(Hale, 6.0);
			CreateTimer(2.0, Timer_GravityCat, Hale, TIMER_FLAG_NO_MAPCHANGE);
			CPrintToChat(Hale, "{olive}[VSH]{default} %t", "used_weighdown");
			WeighDownTimer = 0.0;
		}
	}
	return Plugin_Continue;
}
stock OnlyScoutsLeft()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client) && client != Hale && TF2_GetPlayerClass(client) != TFClass_Scout)
			return false;
	}
	return true;
}
public Action:Timer_GravityCat(Handle:timer, any:client)
{
	if (IsValidClient(client)) SetEntityGravity(client, 1.0);
}
public Action:DoTaunt(client, const String:command[], argc)
{
	if (!Enabled || (client != Hale))
		return Plugin_Continue;
	decl String:s[PLATFORM_MAX_PATH];
	if (HaleRage/RageDMG >= 1)
	{
		decl Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 20.0;
		new Action:act = Plugin_Continue;
		Call_StartForward(OnHaleRage);
		new Float:dist;
		new Float:newdist;
		switch (Special)
		{
			case 1, 4: dist = RageDist/2;
			default: dist = RageDist;
		}
		newdist = dist;
		Call_PushFloatRef(newdist);
		Call_Finish(act);
		if (act != Plugin_Continue && act != Plugin_Changed)
			return Plugin_Continue;
		if (act == Plugin_Changed) dist = newdist;
		switch (Special)
		{
			case 1:
			{
				if (GetRandomInt(0, 2))
					strcopy(s, PLATFORM_MAX_PATH, VagineerRageSound);
				else
					Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerRageSound2, GetRandomInt(1, 2));
				TF2_AddCondition(Hale, TFCond_Ubercharged, 99.0);
				UberRageCount = 0.0;
				SetEntProp(Hale, Prop_Send, "m_nSkin", GetClientTeam(Hale)-2);
				CreateTimer(0.1, UseUberRage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.6, UseRage, dist);
			}
			case 2:
			{
				Format(s, PLATFORM_MAX_PATH, "%s", HHHRage2);
				CreateTimer(0.6, UseRage, dist);
			}
			case 4:
			{
				if (GetRandomInt(0, 1))
					Format(s, PLATFORM_MAX_PATH, "%s", CBS1);
				else
					Format(s, PLATFORM_MAX_PATH, "%s", CBS3);
				EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_compound_bow", 56, 100, 5, "6 ; 0.01 ; 37 ; 0.0"));
				SetAmmo(client, 0, ((RedAlivePlayers >= 9) ? 9 : RedAlivePlayers));
				CreateTimer(0.6, UseRage, dist);
				CreateTimer(0.1, UseBowRage);
			}
			default:
			{
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRageSound, GetRandomInt(1, 4));
				CreateTimer(0.6, UseRage, dist);
			}
		}
		EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
		EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && i != Hale)
			{
				EmitSoundToClient(i, s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
				EmitSoundToClient(i, s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
			}
		}
		HaleRage = 0;
	}
	return Plugin_Continue;
}
public Action:DoSuicide(client, const String:command[], argc)
{
	if (Enabled && client == Hale && VSHRoundState == 0)
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action:UseRage(Handle:hTimer, any:dist)
{
	decl Float:pos[3];
	decl Float:pos2[3];
	decl i;
	decl Float:distance;
	TF2_RemoveCondition(Hale, TFCond_Taunting);
	GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && (i != Hale))
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			distance = GetVectorDistance(pos, pos2);
			if (!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && distance < dist)
			{
				TF2_StunPlayer(i, 5.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, Hale);
				CreateTimer(5.0, RemoveEnt, EntIndexToEntRef(AttachParticle(i, "yikes_fx", 75.0)));
			}
		}
	}
	i = -1;
	while ((i = FindEntityByClassname2(i, "obj_sentrygun")) != -1)
	{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
		distance = GetVectorDistance(pos, pos2);
		if (dist <= RageDist/3) dist = RageDist/2;
		if (distance < dist)	//(!mode && (distance < RageDist)) || (mode && (distance < RageDist/2)))
		{
			SetEntProp(i, Prop_Send, "m_bDisabled", 1);
			AttachParticle(i, "yikes_fx", 75.0);
			if (newRageSentry)
			{
				SetVariantInt(GetEntProp(i, Prop_Send, "m_iHealth")/2);
				AcceptEntityInput(i, "RemoveHealth");
			}
			else
				SetEntProp(i, Prop_Send, "m_iHealth", GetEntProp(i, Prop_Send, "m_iHealth")/2);
			CreateTimer(8.0, EnableSG, EntIndexToEntRef(i));
		}
	}
	return Plugin_Continue;
}
public Action:UseUberRage(Handle:hTimer, any:param)
{
	if (!IsValidClient(Hale))
		return Plugin_Stop;
	if (UberRageCount == 1)
	{
		TF2_RemoveCondition(Hale, TFCond_Taunting);
//		TF2_StunPlayer(Hale, 0.0, _, TF_STUNFLAG_NOSOUNDOREFFECT);
	}
	else if (UberRageCount >= 100)
	{
		SetEntProp(Hale, Prop_Data, "m_takedamage", defaulttakedamagetype);
		defaulttakedamagetype = 0;
		SetEntProp(Hale, Prop_Send, "m_nSkin", GetClientTeam(Hale)-2);
		TF2_RemoveCondition(Hale, TFCond_Ubercharged);
		return Plugin_Stop;
	}
	else if (UberRageCount >= 85)
	{
		TF2_AddCondition(Hale, TFCond_UberchargeFading, 3.0);
	}
	if (!defaulttakedamagetype)
		defaulttakedamagetype = GetEntProp(Hale, Prop_Data, "m_takedamage");
	SetEntProp(Hale, Prop_Data, "m_takedamage", 0);
	UberRageCount += 1.0;
	return Plugin_Continue;
}
public Action:UseBowRage(Handle:hTimer)
{
	TF2_RemoveCondition(Hale, TFCond_Taunting);
//	TF2_StunPlayer(Hale, 0.0, _, TF_STUNFLAG_NOSOUNDOREFFECT);
//	UberRageCount = 9.0;
	SetAmmo(Hale, 0, ((RedAlivePlayers >= 9) ? 9 : RedAlivePlayers));
	return Plugin_Continue;
}
public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[PLATFORM_MAX_PATH];
	if (!Enabled)
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || GetClientHealth(client) > 0)
		return Plugin_Continue;
	CreateTimer(0.1, CheckAlivePlayers);
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deathflags = GetEventInt(event, "death_flags");
	new customkill = GetEventInt(event, "customkill");
	if (client != Hale && VSHRoundState == 1)
		CreateTimer(1.0, Timer_Damage, GetClientUserId(client));
		//CPrintToChat(client, "{olive}%t. %t %i{default}", "damage", Damage[client], "scores", RoundFloat(Damage[client]/600.0));
	if (client == Hale && VSHRoundState == 1)
	{
		switch (Special)
		{
			case 2:
			{
				Format(s, PLATFORM_MAX_PATH, "vo/halloween_boss/knight_death0%d.wav", GetRandomInt(1, 2));
				EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll("ui/halloween_boss_defeated_fx.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				CreateTimer(0.1, Timer_ChangeRagdoll, any:GetEventInt(event, "userid"));
			}
			case 0:
			{
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleFail, GetRandomInt(1, 3));
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				CreateTimer(0.1, Timer_ChangeRagdoll, any:GetEventInt(event, "userid"));
			}
			case 1:
			{
				Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerFail, GetRandomInt(1, 2));
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				CreateTimer(0.1, Timer_ChangeRagdoll, any:GetEventInt(event, "userid"));
			}
		}
		if (HaleHealth < 0)
			HaleHealth = 0;
		ForceTeamWin(OtherTeam);
		return Plugin_Continue;
	}
	if (attacker == Hale && VSHRoundState == 1)
	{
		if (deathflags & TF_DEATHFLAG_DEADRINGER)
		{
			if (customkill != TF_CUSTOM_BOOTS_STOMP)
			{
				if (!Special) SetEventString(event, "weapon", "fists");
			}
			return Plugin_Continue;
		}
		switch (Special)
		{
			case 0:
			{
				if (customkill != TF_CUSTOM_BOOTS_STOMP) SetEventString(event, "weapon", "fists");
				if (!GetRandomInt(0, 2) && RedAlivePlayers != 1)
				{
					Format(s, PLATFORM_MAX_PATH, "");
					switch (TF2_GetPlayerClass(client))
					{
						case TFClass_Scout:	 	strcopy(s, PLATFORM_MAX_PATH, HaleKillScout132);
						case TFClass_Pyro:	 	strcopy(s, PLATFORM_MAX_PATH, HaleKillPyro132);
						case TFClass_DemoMan:	strcopy(s, PLATFORM_MAX_PATH, HaleKillDemo132);
						case TFClass_Heavy:	 	strcopy(s, PLATFORM_MAX_PATH, HaleKillHeavy132);
						case TFClass_Medic:	 	strcopy(s, PLATFORM_MAX_PATH, HaleKillMedic);
						case TFClass_Sniper:
						{
							if (GetRandomInt(0, 1)) strcopy(s, PLATFORM_MAX_PATH, HaleKillSniper1);
							else strcopy(s, PLATFORM_MAX_PATH, HaleKillSniper2);
						}
						case TFClass_Spy:
						{
							new see = GetRandomInt(0, 2);
							if (!see) strcopy(s, PLATFORM_MAX_PATH, HaleKillSpy1);
							else if (see == 1) strcopy(s, PLATFORM_MAX_PATH, HaleKillSpy2);
							else strcopy(s, PLATFORM_MAX_PATH, HaleKillSpy132);
						}
						case TFClass_Engineer:
						{
							new see = GetRandomInt(0, 3);
							if (!see) strcopy(s, PLATFORM_MAX_PATH, HaleKillEngie1);
							else if (see == 1) strcopy(s, PLATFORM_MAX_PATH, HaleKillEngie2);
							else Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, GetRandomInt(1, 2));
						}
					}
					if (!StrEqual(s, ""))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
					}
				}
			}
			case 1:
			{
				strcopy(s, PLATFORM_MAX_PATH, VagineerHit);
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				CreateTimer(0.1, Timer_DissolveRagdoll, any:GetEventInt(event, "userid"));
			}
			case 2:
			{
				Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HHHAttack, GetRandomInt(1, 4));
				EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			}
			case 4:
			{
				new weapon = GetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon");
				if (weapon == GetPlayerWeaponSlot(Hale, TFWeaponSlot_Melee))
				{
					TF2_RemoveWeaponSlot(Hale, TFWeaponSlot_Melee);
					new clubindex, wepswitch = GetRandomInt(0, 3);
					switch (wepswitch)
					{
						case 0: clubindex = 171;
						case 1: clubindex = 3;
						case 2: clubindex = 232;
						case 3: clubindex = 401;
					}
					weapon = SpawnWeapon(Hale, "tf_weapon_club", clubindex, 100, 5, "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0");
					SetEntPropEnt(Hale, Prop_Send, "m_hActiveWeapon", weapon);
				}
			}
		}
		if (KSpreeTimer > 0)
			KSpreeCount++;
		else
			KSpreeCount = 1;
		if (KSpreeCount == 3 && RedAlivePlayers != 1)
		{
			switch (Special)
			{
				case 0:
				{
					new see = GetRandomInt(0, 7);
					if (!see || see == 1)
						strcopy(s, PLATFORM_MAX_PATH, HaleKSpree);
					else if (see < 5)
						Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, GetRandomInt(1, 5));
					else
						Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, GetRandomInt(1, 2));
				}
				case 1:
				{
					if (GetRandomInt(0, 4) == 1)
						strcopy(s, PLATFORM_MAX_PATH, VagineerKSpree);
					else if (GetRandomInt(0, 3) == 1)
						strcopy(s, PLATFORM_MAX_PATH, VagineerKSpree2);
					else
						Format(s, PLATFORM_MAX_PATH, "%s%i.wav", VagineerKSpreeNew, GetRandomInt(1, 5));
				}
				case 2: Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HHHLaught, GetRandomInt(1, 4));
				case 4:
				{
					if (!GetRandomInt(0, 3))
						Format(s, PLATFORM_MAX_PATH, CBS0);
					else if (!GetRandomInt(0, 3))
						Format(s, PLATFORM_MAX_PATH, CBS1);
					else
						Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", CBS2, GetRandomInt(1, 9));
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				}
			}
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			KSpreeCount = 0;
		}
		else
			KSpreeTimer = 5.0;
	}
	if ((TF2_GetPlayerClass(client) == TFClass_Engineer) && !(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		for (new ent = MaxClients + 1; ent < ME; ent++)
		{
			if (IsValidEdict(ent))
			{
				if (GetEdictClassname(ent, s, sizeof(s)) && !strcmp(s, "obj_sentrygun", false) && GetEntPropEnt(ent, Prop_Send, "m_hBuilder") == client)
				{
//					SDKHooks_TakeDamage(ent, Hale, Hale, Float:(GetEntProp(ent, Prop_Send, "m_iMaxHealth")+8), DMG_CLUB);
					SetVariantInt(GetEntProp(ent, Prop_Send, "m_iMaxHealth")+8);
					AcceptEntityInput(ent, "RemoveHealth");
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action:Timer_Damage(Handle:hTimer, any:id)
{
	new client = GetClientOfUserId(id);
	if (IsValidClient(client, false))
		CPrintToChat(client, "{olive}[VSH] %t. %t %i{default}", "damage", Damage[client], "scores", RoundFloat(Damage[client]/600.0));
	return Plugin_Continue;
}
public Action:Timer_DissolveRagdoll(Handle:timer, any:userid)
{
	new victim = GetClientOfUserId(userid);
	new ragdoll;
	if (IsValidClient(victim)) ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
	else ragdoll = -1;
	if (ragdoll != -1)
	{
		DissolveRagdoll(ragdoll);
	}
}
DissolveRagdoll(ragdoll)
{
	new dissolver = CreateEntityByName("env_entity_dissolver");
	if (dissolver == -1)
	{
		return;
	}
	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");
	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
	return;
}
public Action:Timer_ChangeRagdoll(Handle:timer, any:userid)
{
	new victim = GetClientOfUserId(userid);
	new ragdoll;
	if (IsValidClient(victim)) ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
	else ragdoll = -1;
	if (IsValidEntity(ragdoll))
	{
		switch (Special)
		{
			case 0: SetEntityModel(ragdoll, HaleModel);
			case 1: SetEntityModel(ragdoll, VagineerModel);
			case 2: SetEntityModel(ragdoll, HHHModel);
			case 4: SetEntityModel(ragdoll, CBSModel);
		}
	}
}
public Action:event_deflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	new deflector = GetClientOfUserId(GetEventInt(event, "userid"));
	new owner = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new weaponid = GetEventInt(event, "weaponid");
	if (owner != Hale) return Plugin_Continue;
	if (weaponid != 0) return Plugin_Continue;
	new Float:rage = 0.04*RageDMG;
	HaleRage += RoundToCeil(rage);
	if (HaleRage > RageDMG)
		HaleRage = RageDMG;
	if (Special != 1) return Plugin_Continue;
	if (!TF2_IsPlayerInCondition(owner, TFCond_Ubercharged)) return Plugin_Continue;
	if (UberRageCount > 11) UberRageCount -= 10;
	new newammo = GetAmmo(deflector, 0) - 5;
	SetAmmo(deflector, 0, newammo <= 0 ? 0 : newammo);
	return Plugin_Continue;
}
public Action:CheckAlivePlayers(Handle:hTimer)
{
	if (VSHRoundState == 2 || VSHRoundState == -1)
		return Plugin_Continue;
	RedAlivePlayers = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && (GetClientTeam(i) == OtherTeam))
			RedAlivePlayers++;
	}
	if (Special == 4 && GetAmmo(Hale, 0) > RedAlivePlayers && RedAlivePlayers != 0) SetAmmo(Hale, 0, RedAlivePlayers);
	if (RedAlivePlayers == 0)
		ForceTeamWin(HaleTeam);
	else if (RedAlivePlayers == 1 && IsValidClient(Hale))
	{
		decl Float:pos[3];
		decl String:s[PLATFORM_MAX_PATH];
		GetEntPropVector(Hale, Prop_Send, "m_vecOrigin", pos);
		if (Special != 2)
		{
			if (Special == 4)
			{
				if (!GetRandomInt(0, 2))
					Format(s, PLATFORM_MAX_PATH, "%s", CBS0);
				else
				{
					new a = GetRandomInt(1, 25);
					if (a < 10)
						Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", CBS4, a);
					else
						Format(s, PLATFORM_MAX_PATH, "%s%i.wav", CBS4, a);
				}
				EmitSoundToAll(s, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
			}
			else if (Special == 1)
				strcopy(s, PLATFORM_MAX_PATH, VagineerLastA);
			else
			{
				new see = GetRandomInt(0, 5);
				switch (see)
				{
					case 0: strcopy(s, PLATFORM_MAX_PATH, Arms);
					case 1: Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HaleLastB, GetRandomInt(1, 4));
					case 2: strcopy(s, PLATFORM_MAX_PATH, HaleKillLast132);
					default: Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleLastMan, GetRandomInt(1, 5));
				}
			}
			EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, pos, NULL_VECTOR, false, 0.0);
		}
	}
	else if (!PointType && (RedAlivePlayers <= (AliveToEnable = GetConVarInt(cvarAliveToEnable))))
	{
		PrintHintTextToAll("%t", "point_enable", AliveToEnable);
		if (RedAlivePlayers == AliveToEnable) EmitSoundToAll("vo/announcer_am_capenabled02.wav");
		else if (RedAlivePlayers < AliveToEnable)
		{
			decl String:s[PLATFORM_MAX_PATH];
			Format(s, PLATFORM_MAX_PATH, "vo/announcer_am_capincite0%i.wav", GetRandomInt(0, 1) ? 1 : 3);
			EmitSoundToAll(s);
		}
		SetControlPoint(true);
	}
	return Plugin_Continue;
}
public Action:event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled)
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "damageamount");
	new custom = GetEventInt(event, "custom");
	if (client != Hale)	// || !IsValidEdict(client) || !IsValidEdict(attacker) || (client <= 0) || (attacker <= 0) || (attacker > MaxClients))
		return Plugin_Continue;
	if (!IsValidClient(attacker) || !IsValidClient(client) || client == attacker)
		return Plugin_Continue;
	if (custom == TF_CUSTOM_BACKSTAB)
		return Plugin_Continue;
	if (custom == 16) damage = 9001;
	HaleHealth -= damage;
	HaleRage += damage;
	if (custom == 16) SetEventInt(event, "damageamount", 9001);
	Damage[attacker] += damage;
	new healers[MAXPLAYERS];
	new healercount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && (GetHealingTarget(i) == attacker))
		{
			healers[healercount] = i;
			healercount++;
		}
	}
	for (new i = 0; i < healercount; i++)
	{
		if (IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
		{
			Damage[healers[i]] += damage/(healercount+1);
		}
	}
	if (HaleRage > RageDMG)
		HaleRage = RageDMG;
	return Plugin_Continue;
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!Enabled || !IsValidEdict(attacker) || ((attacker <= 0) && (client == Hale)) || TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		return Plugin_Continue;
	if (VSHRoundState == 0 && client == Hale)
	{
		damage *= 0.0;
		return Plugin_Changed;
	}
	decl Float:Pos[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);
	if ((attacker == Hale) && IsValidClient(client) && (client != Hale) && !TF2_IsPlayerInCondition(client, TFCond_Bonked) && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{
		if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
		{
			ScaleVector(damageForce, 9.0);
			damage *= 0.3;
			return Plugin_Changed;
		}
		new ent = -1;
		while ((ent = FindEntityByClassname2(ent, "tf_wearable_demoshield")) != -1)
		{
			if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(ent, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(ent, "Kill");
				EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				return Plugin_Continue;
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Spy && (GetEntProp(client, Prop_Send, "m_bFeignDeathReady") || TF2_IsPlayerInCondition(client, TFCond_DeadRingered)))
		{
			if (damagetype & DMG_CRIT) damagetype &= ~DMG_CRIT;
			damage = 590.0;
			return Plugin_Changed;
		}
		new buffweapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		new buffindex = (IsValidEntity(buffweapon) && buffweapon > MaxClients ? GetEntProp(buffweapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
		if (buffindex == 226 && Special != 5)
		{
			CreateTimer(0.25, Timer_CheckBuffRage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		if (damage <= 160.0)
		{
			damage *= 3;
			return Plugin_Changed;
		}
	}
	else if (attacker != Hale && client == Hale)
	{
		if (attacker <= MaxClients)
		{
			new wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if (inflictor == attacker)
			{
				if (!IsValidEntity(weapon) && (damagetype & DMG_CRUSH) == DMG_CRUSH && damage == 1000.0)	//THIS IS A TELEFRAG
				{
					damage = (HaleHealth > 9001 ? 15.0 : 9001.0);
					new teleowner = FindTeleOwner(attacker);
					if (IsValidClient(teleowner) && teleowner != attacker)
					{
						Damage[teleowner] += RoundFloat(9001.0 * 3 / 5);
						PrintCenterText(teleowner, "TELEFRAG ASSIST! Nice job setting up!");
					}
					PrintCenterText(attacker, "TELEFRAG! You are a pro.");
					PrintCenterText(client, "TELEFRAG! Be careful around quantum tunneling devices!");
					return Plugin_Changed;
				}
				switch (wepindex)
				{
					case 14, 201:
					{
						new Float:chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						new Float:time = 2.0;
						time += 4*(chargelevel/100);
						SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
						GlowTimer += RoundToCeil(time);
						if (GlowTimer > 30.0) GlowTimer = 30.0;
					}
					case 132, 266, 482: IncrementHeadCount(attacker);
					case 317: SpawnSmallHealthPackAt(client, GetClientTeam(attacker));
					case 214:
					{
						new health = GetClientHealth(attacker);
						new max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						new newhealth = health+25;
						if (health < max+50)
						{
							if (newhealth > max+50) newhealth = max+50;
							SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
						}
						if (TF2_IsPlayerInCondition(attacker, TFCond_OnFire)) TF2_RemoveCondition(attacker, TFCond_OnFire);
					}
					case 357:
					{
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if (GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						new health = GetClientHealth(attacker);
						new max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						new newhealth = health+35;
						if (health < max+25)
						{
							if (newhealth > max+25) newhealth = max+25;
							SetEntProp(attacker, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(attacker, Prop_Send, "m_iHealth", newhealth);
						}
						if (TF2_IsPlayerInCondition(attacker, TFCond_OnFire)) TF2_RemoveCondition(attacker, TFCond_OnFire);
					}
				}
				if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage > 1000.0)	//lousy way of checking backstabs
				{
					decl String:wepclassname[32];
					if (GetEdictClassname(weapon, wepclassname, sizeof(wepclassname)) && strcmp(wepclassname, "tf_weapon_knife", false) == 0)	//more robust knife check
					{
						new Float:changedamage = HaleHealthMax*(0.12-Stabbed/90);
						Damage[attacker] += RoundFloat(changedamage);
						if (HaleHealth > RoundFloat(changedamage)) damage = 0.0;
						else damage = changedamage;
						HaleHealth -= RoundFloat(changedamage);
						HaleRage += RoundFloat(changedamage);
						if (HaleRage > RageDMG)
							HaleRage = RageDMG;
						EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
						EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, Pos, NULL_VECTOR, false, 0.0);
						EmitSoundToClient(client, "player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
						EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, _, NULL_VECTOR, false, 0.0);
						SwitchToOtherWeapon(attacker);
						PrintCenterText(attacker, "You backstabbed him!");
						PrintCenterText(client, "You were just backstabbed!");
						new Handle:stabevent = CreateEvent("player_hurt", true);
						SetEventInt(stabevent, "userid", GetClientUserId(client));
						SetEventInt(stabevent, "health", HaleHealth);
						SetEventInt(stabevent, "attacker", GetClientUserId(attacker));
						SetEventInt(stabevent, "damageamount", RoundFloat(changedamage));
						SetEventInt(stabevent, "custom", TF_CUSTOM_BACKSTAB);
						SetEventBool(stabevent, "crit", true);
						SetEventBool(stabevent, "minicrit", false);
						SetEventBool(stabevent, "allseecrit", true);
						SetEventInt(stabevent, "weaponid", TF_WEAPON_KNIFE);
						FireEvent(stabevent);
						if (TF2_GetPlayerClass(attacker) == TFClass_Spy && wepindex == 225)
						{
							CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker));
						}
						if (wepindex == 356)
						{
							new health = GetClientHealth(attacker) + 100;
							if (health > 270) health = 270;
							SetEntProp(attacker, Prop_Data, "m_iHealth", health);
							SetEntProp(attacker, Prop_Send, "m_iHealth", health);
						}
						if (!Special)
						{
							decl String:s[PLATFORM_MAX_PATH];
							Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStubbed132, GetRandomInt(1, 4));
							EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
							EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
						}
						else if (Special == 1)
						{
							EmitSoundToAll("vo/engineer_positivevocalization01.wav", _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
							EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "vo/engineer_positivevocalization01.wav", _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
						}
						else if (Special == 2)
						{
							decl String:s[PLATFORM_MAX_PATH];
							Format(s, PLATFORM_MAX_PATH, "vo/halloween_boss/knight_pain0%d.wav", GetRandomInt(1, 3));
							EmitSoundToAll(s, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
							EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, s, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Hale, NULL_VECTOR, NULL_VECTOR, false, 0.0);
						}
						if (Stabbed < 5)
							Stabbed++;
						new healers[MAXPLAYERS];
						new healercount = 0;
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsValidClient(i) && IsPlayerAlive(i) && (GetHealingTarget(i) == attacker))
							{
								healers[healercount] = i;
								healercount++;
							}
						}
						for (new i = 0; i < healercount; i++)
						{
							if (IsValidClient(healers[i]) && IsPlayerAlive(healers[i]))
							{
								Damage[healers[i]] += RoundFloat(changedamage/(healercount+1));
							}
						}
						return Plugin_Changed;
					}
				}
			}
			if (TF2_GetPlayerClass(attacker) == TFClass_Scout)
			{
				if (wepindex == 45 || ((wepindex == 209 || wepindex == 294 || wepindex == 23 || wepindex == 160 || wepindex == 449) && (TF2_IsPlayerCritBuffed(client) || TF2_IsPlayerInCondition(client, TFCond_CritCola) || TF2_IsPlayerInCondition(client, TFCond_Buffed) || TF2_IsPlayerInCondition(client, TFCond_CritHype))))
				{
					ScaleVector(damageForce, 0.38);
					return Plugin_Changed;
				}
			}
			else if (TF2_GetPlayerClass(attacker) == TFClass_Engineer)
			{
				if (weapon == GetPlayerWeaponSlot(attacker, 1))
				{
					new windex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
					if (windex==528)
						TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
				}
			}
		}
		else
		{
			decl String:s[64];
			GetEdictClassname(attacker, s, sizeof(s));
			if (strcmp(s, "trigger_hurt", false) == 0)	// && damage >= 250)
			{
				if (strncmp(currentmap, "vsh_oilrig", 10, false) == 0 && StringToInt(currentmap[12]) >= 14)
				{
					if (damage >= 300.0) bEnableSuperDuperJump = true;
				}
				else
				{
					if (damage >= 250.0) bEnableSuperDuperJump = true;
				}
				if (damage > 1500.0)
				{
					damage = 1500.0;
				}
				if (strcmp(currentmap, "arena_arakawa_b3", false) == 0 && damage > 1000.0) damage = 490.0;
				HaleHealth -= RoundFloat(damage);
				HaleRage += RoundFloat(damage);
				if (HaleRage > RageDMG)
					HaleRage = RageDMG;
				return Plugin_Changed;
			}
		}
	}
	else if (attacker == 0 && client != Hale && IsValidClient(client, false) && TF2_GetPlayerClass(client) == TFClass_Soldier && (damagetype & DMG_FALL))
	{
		new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if (secondary <= 0 || !IsValidEntity(secondary))
		{
			damage /= 10.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
stock SpawnSmallHealthPackAt(client, ownerteam = 0)
{
	if (!IsValidClient(client, false) || !IsPlayerAlive(client)) return;
	new healthpack = CreateEntityByName("item_healthkit_small");
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 20.0;
	if (IsValidEntity(healthpack))
	{
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", ownerteam, 4);
		SetEntityMoveType(healthpack, MOVETYPE_FLYGRAVITY);
		new Float:vel[3];
		vel[0] = float(GetRandomInt(0, 10)), vel[1] = float(GetRandomInt(0, 10)), vel[2] = 50.0;	//I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, pos, NULL_VECTOR, vel);
		CreateTimer(17.0, Timer_RemoveCandycaneHealthPack, EntIndexToEntRef(healthpack), TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:Timer_RemoveCandycaneHealthPack(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if (entity > MaxClients && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}
public Action:Timer_CheckBuffRage(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	}
}
stock IncrementHeadCount(client)
{
	if (!TF2_IsPlayerInCondition(client, TFCond_DemoBuff)) TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	new health = GetClientHealth(client);
//	health += (decapitations >= 4 ? 10 : 15);
	health += 15;
	SetEntProp(client, Prop_Data, "m_iHealth", health);
	SetEntProp(client, Prop_Send, "m_iHealth", health);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}
stock SwitchToOtherWeapon(client)
{
	new ammo = GetAmmo(client, 0);
	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new clip = (IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);
	if (!(ammo == 0 && clip <= 0)) SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	else SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary));
}
stock FindTeleOwner(client)
{
	if (!IsValidClient(client)) return -1;
	if (!IsPlayerAlive(client)) return -1;
	new tele = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	decl String:classname[32];
	if (IsValidEntity(tele) && GetEdictClassname(tele, classname, sizeof(classname)) && strcmp(classname, "obj_teleporter", false) == 0)
	{
		new owner = GetEntPropEnt(tele, Prop_Send, "m_hBuilder");
		if (IsValidClient(owner, false)) return owner;
	}
	return -1;
}
stock TF2_IsPlayerCritBuffed(client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond:34) || TF2_IsPlayerInCondition(client, TFCond:35) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill));
}
public Action:Timer_DisguiseBackstab(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client, false))
	{
		RandomlyDisguise(client);
	}
}
stock RandomlyDisguise(client)	//mechamechamechamechamecha
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_AddCondition(client, TFCond_Disguised, 99999.0);
		new disguisetarget = -1;
		new team = GetClientTeam(client);
		new Handle:hArray = CreateArray();
		for (new clientcheck = 0; clientcheck <= MaxClients; clientcheck++) {
			if (IsValidClient(clientcheck) && GetClientTeam(clientcheck) == team && clientcheck != client)
			{
				new TFClassType:class = TF2_GetPlayerClass(clientcheck);
				if (class == TFClass_Scout || class == TFClass_Medic || class == TFClass_Engineer || class == TFClass_Sniper || class == TFClass_Pyro)
					PushArrayCell(hArray, clientcheck);
			}
		}
		if (GetArraySize(hArray) <= 0) disguisetarget = client;
		else disguisetarget = GetArrayCell(hArray, GetRandomInt(0, GetArraySize(hArray)-1));
		if (!IsValidClient(disguisetarget)) disguisetarget = client;
		new disguisehealth = GetRandomInt(75, 125);
		new class = GetRandomInt(0, 4);
		new TFClassType:classarray[] = { TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper };
//		new disguiseclass = classarray[class];
		new disguiseclass = _:(disguisetarget != client ? (TF2_GetPlayerClass(disguisetarget)) : classarray[class]);
//		new weapon = GetEntPropEnt(disguisetarget, Prop_Send, "m_hActiveWeapon");
		CloseHandle(hArray);
		SetEntProp(client, Prop_Send, "m_nDisguiseClass", disguiseclass);
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
		SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguisetarget);
		SetEntProp(client, Prop_Send, "m_iDisguiseHealth", disguisehealth);
		TF2_DisguisePlayer(client, TFTeam:team, TFClassType:disguiseclass);
		FakeClientCommandEx(client, "lastdisguise");
		TF2_AddCondition(client, TFCond_Disguised, 99999.0);
	}
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (client == Hale && !haleCrits)
	{
		result = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
stock FindNextHale(bool:array[])
{
	new tBoss;
	new tBossPoints = GetClientQueuePoints(tBoss);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) != _:TFTeam_Unassigned)
		{
			new points = GetClientQueuePoints(i);
			if (points >= tBossPoints && !array[i])
			{
				tBoss = i;
				tBossPoints = points;
			}
		}
	}
	return tBoss;
}
ForceTeamWin(team)
{
	new ent = FindEntityByClassname2(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}
stock AttachParticle(ent, String:particleType[], Float:offset = 0.0, bool:battach = true)
{
	new particle = CreateEntityByName("info_particle_system");
	decl String:tName[128];
	decl Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2] += offset;
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	if (battach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}
stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon == INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}
public HintPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	return;
}

public Action:HintPanel(client)
{
	if (IsVoteInProgress())
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[512];
	SetGlobalTransTarget(client);
	switch (Special)
	{
		case 0:
			Format(s, 512, "%t", "help_hale");
		case 1:
			Format(s, 512, "%t", "help_vagineer");
		case 2:
			Format(s, 512, "%t", "help_hhh");
		case 4:
			Format(s, 512, "%t", "help_cbs");
	}
	DrawPanelText(panel, s);
	Format(s, 512, "%t", "menu_6");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, HintPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
public QueuePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 == 10)
		TurnToZeroPanel(param1);
	return false;
}
public Action:QueuePanelCmd(client, Args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	QueuePanel(client);
	return Plugin_Handled;
}
public Action:QueuePanel(client)
{
	if (!Enabled2)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[512];
	Format(s, 512, "%T", "thequeue", client);
	SetPanelTitle(panel, s);
	new bool:added[MAXPLAYERS + 1];
	new tHale = Hale;
	added[Hale]=true;
	if (IsValidClient(tHale))
	{
		if (!Enabled)
			Format(s, sizeof(s), "None");
		else
			Format(s, sizeof(s), "%N - %i", tHale, GetClientQueuePoints(tHale));
		DrawPanelItem(panel, s);
	}
	new i, pingas, bool:botadded;
	DrawPanelText(panel, "---");
	do
	{
		tHale = FindNextHale(added);
		if (IsValidClient(tHale))
		{
			if (client == tHale)
			{
				Format(s, 64, "%N - %i", tHale, GetClientQueuePoints(tHale));
				DrawPanelText(panel, s);
				i--;
			}
			else
			{
				if (IsFakeClient(tHale))
				{
					if (botadded)
					{
						added[tHale]=true;
						continue;
					}
					Format(s, 64, "BOT - %i", botqueuepoints);
					botadded = true;
				}
				else Format(s, 64, "%N - %i", tHale, GetClientQueuePoints(tHale));
				DrawPanelItem(panel, s);
			}
			added[tHale]=true;
			i++;
		}
		pingas++;
	}
	while (i < 8 && pingas < 100);
	for (; i < 8; i++)
		DrawPanelItem(panel, "");
	Format(s, 64, "%T %i (%T)", "your_points", client, GetClientQueuePoints(client), "to0", client);
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, QueuePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
public TurnToZeroPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 == 1)
	{
		SetClientQueuePoints(param1, 0);
		CPrintToChat(param1, "{olive}[VSH]{default} %t", "to0_done");
	}
}
public Action:TurnToZeroPanel(client)
{
	if (!Enabled2)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[512];
	SetGlobalTransTarget(client);
	Format(s, 512, "%t", "to0_title");
	SetPanelTitle(panel, s);
	Format(s, 512, "%t", "Yes");
	DrawPanelItem(panel, s);
	Format(s, 512, "%t", "No");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, TurnToZeroPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
bool:GetClientClasshelpinfoCookie(client)
{
	if (!IsValidClient(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!AreClientCookiesCached(client)) return true;
	decl String:strCookie[32];
	GetClientCookie(client, ClasshelpinfoCookie, strCookie, sizeof(strCookie));
	if (strCookie[0] == 0) return true;
	else return bool:StringToInt(strCookie);
}
GetClientQueuePoints(client)
{
	if (!IsValidClient(client)) return 0;
	if (IsFakeClient(client))
	{
		return botqueuepoints;
	}
	if (!AreClientCookiesCached(client)) return 0;
	decl String:strPoints[32];
	GetClientCookie(client, PointCookie, strPoints, sizeof(strPoints));
	return StringToInt(strPoints);
}
SetClientQueuePoints(client, points)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	decl String:strPoints[32];
	IntToString(points, strPoints, sizeof(strPoints));
	SetClientCookie(client, PointCookie, strPoints);
}
public HalePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
				Command_GetHP(param1);
			case 2:
				HelpPanel(param1);
			case 3:
				HelpPanel2(param1);
			case 4:
				NewPanel(param1, maxversion);
			case 5:
				QueuePanel(param1);
			case 6:
				MusicTogglePanel(param1);
			case 7:
				VoiceTogglePanel(param1);
			case 8:
				ClasshelpinfoSetting(param1);
/*			case 9:
			{
				if (ACH_Enabled)
					FakeClientCommand(param1, "haleach");
				else
					return;
			}
			case 0:
			{
				if (ACH_Enabled)
					FakeClientCommand(param1, "haleach_stats");
				else
					return;
			}*/
			default: return;
		}
	}
}

public Action:HalePanel(client, args)
{
	if (!Enabled2 || !IsValidClient(client, false))
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[256];
	SetGlobalTransTarget(client);
	Format(s, 256, "%t", "menu_1");
	SetPanelTitle(panel, s);
	Format(s, 256, "%t", "menu_2");
	DrawPanelItem(panel, s);
	Format(s, 256, "%t", "menu_3");
	DrawPanelItem(panel, s);
	Format(s, 256, "%t", "menu_7");
	DrawPanelItem(panel, s);
	Format(s, 256, "%t", "menu_4");
	DrawPanelItem(panel, s);
	Format(s, 256, "%t", "menu_5");
	DrawPanelItem(panel, s);
	Format(s, 256, "%t", "menu_8");
	DrawPanelItem(panel, s);
	Format(s, 256, "%t", "menu_9");
	DrawPanelItem(panel, s);
	Format(s, 256, "%t", "menu_9a");
	DrawPanelItem(panel, s);
/*	if (ACH_Enabled)
	{
		Format(s, 256, "%t", "menu_10");
		DrawPanelItem(panel, s);
		Format(s, 256, "%t", "menu_11");
		DrawPanelItem(panel, s);
	}*/
	Format(s, 256, "%t", "menu_6");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, HalePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}
public NewPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				if (curHelp[param1] <= 0)
					NewPanel(param1, 0);
				else
					NewPanel(param1, --curHelp[param1]);
			}
			case 2:
			{
				if (curHelp[param1] >= maxversion)
					NewPanel(param1, maxversion);
				else
					NewPanel(param1, ++curHelp[param1]);
			}
			default: return;
		}
	}
}
public Action:NewPanelCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	NewPanel(client, maxversion);
	return Plugin_Handled;
}
public Action:NewPanel(client, versionindex)
{
	if (!Enabled2)
		return Plugin_Continue;
	curHelp[client]=versionindex;
	new Handle:panel = CreatePanel();
	decl String:s[90];
	SetGlobalTransTarget(client);
	Format(s, 90, "=%t%s:=", "whatsnew", haleversiontitles[versionindex]);
	SetPanelTitle(panel, s);
	FindVersionData(panel, versionindex);
	if (versionindex > 0)
		Format(s, 90, "%t", "older");
	else
		Format(s, 90, "%t", "noolder");
	DrawPanelItem(panel, s);
	if (versionindex < maxversion)
		Format(s, 90, "%t", "newer");
	else
		Format(s, 90, "%t", "nonewer");
	DrawPanelItem(panel, s);
	Format(s, 512, "%t", "menu_6");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, NewPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
stock FindVersionData(Handle:panel, versionindex)
{
	switch (versionindex)
	{
		case 35: //1369
		{
			DrawPanelText(panel, "1) Fixed spawn door blocking.");
			DrawPanelText(panel, "2) Cleaned up HUD text (health, etc).");
			DrawPanelText(panel, "3) VSH_OnDoJump now has a bool for superduper.");
			DrawPanelText(panel, "4) !halenoclass changed to !haleclassinfotoggle.");
			DrawPanelText(panel, "5) Fixed invalid clients becoming Hale");
			DrawPanelText(panel, "6) Removed teamscramble from first round.");
			DrawPanelText(panel, "7) Vagineer noises:");
			DrawPanelText(panel, "-- Nope for no");
			DrawPanelText(panel, "-- Gottam/mottag (same as jump but quieter) for Move Up");
			DrawPanelText(panel, "-- Hurr for everything else");
		}
		case 34: //1369
		{
			DrawPanelText(panel, "8) All map dispensers will be on the non-Hale team (fixes health bug)");
			DrawPanelText(panel, "9) Fixed command flags on overlay command");
			DrawPanelText(panel, "10) Fixed soldier shotgun not dealing midair minicrits.");
			DrawPanelText(panel, "11) Fixed invalid weapons on clients");
			DrawPanelText(panel, "12) Damage indicator (+spec damage indicator)");
			DrawPanelText(panel, "13) Hale speed remains during humiliation time");
			DrawPanelText(panel, "14) SuperDuperTele for HHH stuns for 4s instead of regular 2");
		}
		case 33: //1369
		{
			DrawPanelText(panel, "15) Battalion's Backup adds +10 max hp, but still only overheal to 300");
			DrawPanelText(panel, "-- Full rage meter when hit by Hale. Buff causes drastic defense boost.");
			DrawPanelText(panel, "16) Fixed a telefrag glitch");
			DrawPanelText(panel, "17) Powerjack is now +25hp on hit, heal up to +50 overheal");
			DrawPanelText(panel, "18) Backstab now shows the regular hit indicator (like other weapons do)");
			DrawPanelText(panel, "19) Kunai adds 100hp on backstab, up to 270");
			DrawPanelText(panel, "20) FaN/Scout crit knockback not nerfed to oblivion anymore");
			DrawPanelText(panel, "21) Removed Short Circuit stun (better effect being made)");
			DrawPanelText(panel, "21) SeeTF2: We put back the Short Circuit stun");
		}
		case 32: //1368
		{
			DrawPanelText(panel, "1) Now FaN and Scout crit knockback is REALLY lessened.");
			DrawPanelText(panel, "2) Medic says 'I'm charged' when he gets fully uber-charge with syringegun.");
			DrawPanelText(panel, "3) Team will scramble in 1st round, if 1st round is default arena.");
			DrawPanelText(panel, "4) Now client can disable info about changes of classes, displayed when round started.");
			DrawPanelText(panel, "5) Powerjack adds 50HPs per hit.");
			DrawPanelText(panel, "6) Short Circuit stuns Hale for 2.0 seconds.");
			DrawPanelText(panel, "7) Vagineer says \"hurr\"");
			//DrawPanelText(panel, "8) Added support of VSH achievements.");
		}
		case 31: //1367
		{
			DrawPanelText(panel, "1) Map-specific fixes:");
			DrawPanelText(panel, "-- Oilrig's pit no longer allows HHH to instatele");
			DrawPanelText(panel, "-- Arakawa's pit damage drastically lessened");
			DrawPanelText(panel, "2) General map fixes: disable spawn-blocking walls");
			DrawPanelText(panel, "3) Cap point now properly un/locks instead of fake-unlocking.");
			DrawPanelText(panel, "4) Tried fixing double-music playing.");
			DrawPanelText(panel, "5) Fixed Eternal Reward disguise glitch - edge case.");
			DrawPanelText(panel, "6) Help menus no longer glitch votes.");
		}
		case 30: //1366
		{
			DrawPanelText(panel, "1) Fixed superjump velocity code.");
			DrawPanelText(panel, "2) Fixed replaced Rocket Jumpers not minicritting Hale in midair.");
		}
		case 29: //1365
		{
			DrawPanelText(panel, "1) Half-Zatoichi is now allowed. Heal 35 health on hit, but must hit Hale to remove Honorbound.");
			DrawPanelText(panel, "-- Can add up to 25 overheal");
			DrawPanelText(panel, "-- Starts the round bloodied.");
			DrawPanelText(panel, "2) Fixed Hale not building rage when only Scouts remain.");
			DrawPanelText(panel, "3) Tried fixing Hale disconnect/nextround glitches (including music).");
			DrawPanelText(panel, "4) Candycane spawns healthpack on hit.");
		}
		case 28:	//1364
		{
			DrawPanelText(panel, "1) Added convar hale_first_round (default 0). If it's 0, first round will be default arena.");
			DrawPanelText(panel, "2) Added more translations.");
		}
		case 27:	//1363
		{
			DrawPanelText(panel, "1) Fixed a queue point exploit (VoiDeD is mean)");
			DrawPanelText(panel, "2) HHH has backstab/death sound now");
			DrawPanelText(panel, "3) First rounds are normal arena");
			DrawPanelText(panel, "-- Some weapon replacements still apply!");
			DrawPanelText(panel, "-- Teambalance is still off, too.");
			DrawPanelText(panel, "4) Fixed arena_ maps not switching teams occasionally");
			DrawPanelText(panel, "-- After 3 rounds with a team, has a chance to switch");
			DrawPanelText(panel, "-- Will add a cvar to keep Hale always blue/force team, soon");
			DrawPanelText(panel, "5) Fixed pit damage");
		}
		case 26:	//1361 and 2
		{
			DrawPanelText(panel, "1) CBS music");
			DrawPanelText(panel, "2) Soldiers minicrit Hale while he's in midair.");
			DrawPanelText(panel, "3) Direct Hit crits instead of minicrits");
			DrawPanelText(panel, "4) Reserve Shooter switches faster, +10% dmg");
			DrawPanelText(panel, "5) Added hale_stop_music cmd - admins stop music for all");
			DrawPanelText(panel, "6) FaN and Scout crit knockback is lessened");
			DrawPanelText(panel, "7) Your halemusic/halevoice settings are saved");
			DrawPanelText(panel, "1.362) Sounds aren't stupid .mdl files anymore");
			DrawPanelText(panel, "1.362) Fixed translations");
		}
		case 25:	//136
		{
			DrawPanelText(panel, "MEGA UPDATE by FlaminSarge! Check next few pages");
			DrawPanelText(panel, "SUGGEST MANNO-TECH WEAPON CHANGES");
			DrawPanelText(panel, "1) Updated CBS model");
			DrawPanelText(panel, "2) Fixed last man alive sound");
			DrawPanelText(panel, "3) Removed broken hale line, fixed one");
			DrawPanelText(panel, "4) New HHH rage sound");
			DrawPanelText(panel, "5) HHH music (/halemusic)");
			DrawPanelText(panel, "6) CBS jump noise");
			DrawPanelText(panel, "7) /halevoice and /halemusic to turn off voice/music");
			DrawPanelText(panel, "8) Updated natives/forwards (can change rage dist in fwd)");
		}
		case 24:	//136
		{
			DrawPanelText(panel, "9) hale_crits cvar to turn off hale random crits");
			DrawPanelText(panel, "10) Fixed sentries not repairing when raged");
			DrawPanelText(panel, "-- Set hale_ragesentrydamagemode 0 to force engineer to pick up sentry to repair");
			DrawPanelText(panel, "11) Now uses sourcemod autoconfig (tf/cfg/sourcemod/)");
			DrawPanelText(panel, "12) No longer requires saxton_hale_points.cfg file");
			DrawPanelText(panel, "-- Now using clientprefs for queue points");
			DrawPanelText(panel, "13) When on non-VSH map, team switch does not occur so often.");
			DrawPanelText(panel, "14) Should have full replay compatibility");
			DrawPanelText(panel, "15) Bots work with queue, are Hale less often");
		}
		case 23:	//136
		{
			DrawPanelText(panel, "16) Hale's health increased by 1 (in code)");
			DrawPanelText(panel, "17) Many many many many many fixes");
			DrawPanelText(panel, "18) Crossbow +150% damage +10 uber on hit");
			DrawPanelText(panel, "19) Syringegun has overdose speed boost");
			DrawPanelText(panel, "20) Sniper glow time scales with charge (2 to 8 seconds)");
			DrawPanelText(panel, "21) Eyelander/reskins add heads on hit");
			DrawPanelText(panel, "22) Axetinguisher/reskins use fire axe attributes");
			DrawPanelText(panel, "23) GRU/KGB is +50% speed but -7hp/s");
			DrawPanelText(panel, "24) Airblasting boss adds rage (no airblast reload though)");
			DrawPanelText(panel, "25) Airblasting uber vagineer adds time to uber and takes extra ammo");
		}
		case 22:	//136
		{
			DrawPanelText(panel, "26) Frontier Justice allowed, crits only when sentry sees Hale");
			DrawPanelText(panel, "27) Boss weighdown (look down + crouch) after 5 seconds in midair");
			DrawPanelText(panel, "28) FaN is back");
			DrawPanelText(panel, "29) Scout crits/minicrits do less knockback if not melee");
			DrawPanelText(panel, "30) Saxton has his own fists");
			DrawPanelText(panel, "31) Unlimited /halehp but after 3, longer cooldown");
			DrawPanelText(panel, "32) Fist kill icons");
			DrawPanelText(panel, "33) Fixed CBS arrow count (start at 9, but if less than 9 players, uses only that number of players)");
			DrawPanelText(panel, "34) Spy primary minicrits");
			DrawPanelText(panel, "35) Dead ringer fixed");
		}
		case 21:	//136
		{
			DrawPanelText(panel, "36) Flare gun replaced with detonator. Has large jump but more self-damage (like old detonator beta)");
			DrawPanelText(panel, "37) Eternal Reward backstab disguises as random faster classes");
			DrawPanelText(panel, "38) Kunai adds 60 health on backstab");
			DrawPanelText(panel, "39) Randomizer compatibility.");
			DrawPanelText(panel, "40) Medic uber works as normal with crits added (multiple targets, etc)");
			DrawPanelText(panel, "41) Crits stay when being healed, but adds minicrits too (for sentry, etc)");
			DrawPanelText(panel, "42) Fixed Sniper back weapon replacement");
		}
		case 20:	//136
		{
			DrawPanelText(panel, "43) Vagineer NOPE and Well Don't That Beat All!");
			DrawPanelText(panel, "44) Telefrags do 9001 damage");
			DrawPanelText(panel, "45) Speed boost when healing scouts (like Quick-Fix)");
			DrawPanelText(panel, "46) Rage builds (VERY slowly) if there are only Scouts left");
			DrawPanelText(panel, "47) Healing assist damage split between healers");
			DrawPanelText(panel, "48) Fixed backstab assist damage");
			DrawPanelText(panel, "49) Fixed HHH attacking during tele");
			DrawPanelText(panel, "50) Soldier boots - 1/10th fall damage");
			DrawPanelText(panel, "AND MORE! (I forget all of them)");
		}
		case 19:	//135_3
		{
			DrawPanelText(panel, "1)Added point system (/halenext).");
			DrawPanelText(panel, "2)Added [VSH] to VSH messages.");
			DrawPanelText(panel, "3)Removed native VSH_GetSaxtonHaleHealth() added native VSH_GetRoundState().");
			DrawPanelText(panel, "4)There is mini-crits for scout's pistols. Not full crits, like before.");			
			DrawPanelText(panel, "5)Fixed issues associated with crits.");			
			DrawPanelText(panel, "6)Added FORCE_GENERATION flag to stop errorlogs.");			
			DrawPanelText(panel, "135_2 and 135_3)Bugfixes and updated translations.");
		}
		case 18:	//135
		{
			DrawPanelText(panel, "1)Special crits will not removed by Medic.");
			DrawPanelText(panel, "2)Sniper's glow is working again.");
			DrawPanelText(panel, "3)Less errors in console.");
			DrawPanelText(panel, "4)Less messages in chat.");
			DrawPanelText(panel, "5)Added more natives.");
			DrawPanelText(panel, "6)\"Over 9000\" sound returns! Thx you, FlaminSarge.");
			DrawPanelText(panel, "7)Hopefully no more errors in logs.");
		}
		case 17:	//134
		{
			DrawPanelText(panel, "1)Biohazard skin for CBS");
			DrawPanelText(panel, "2)TF2_IsPlayerInCondition() fixed");
			DrawPanelText(panel, "3)Now sniper rifle must be 100perc.charged to glow Hale.");
			DrawPanelText(panel, "4)Fixed Vagineer's model.");
			DrawPanelText(panel, "5)Added Natives.");
			DrawPanelText(panel, "6)Hunstman deals more damage.");
			DrawPanelText(panel, "7)Added reload time (5sec) for Pyro's airblast. ");
			DrawPanelText(panel, "1.34_1 1)Fixed airblast reload when VSH is disabled.");
			DrawPanelText(panel, "1.34_1 2)Fixed airblast reload after detonator's alt-fire.");
			DrawPanelText(panel, "1.34_1 3)Airblast reload time reduced to 3 seconds.");
			DrawPanelText(panel, "1.34_1 4)hale_special 3 is disabled.");
		}
		case 16:	//133
		{
			DrawPanelText(panel, "1)Fixed bugs, associated with Uber-update.");
			DrawPanelText(panel, "2)FaN replaced with Soda Popper.");
			DrawPanelText(panel, "3)Bazaar Bargain replaced with Sniper Rifle.");
			DrawPanelText(panel, "4)Sniper Rifle adding glow to Hale - anyone can see him for 5 seconds.");
			DrawPanelText(panel, "5)Crusader's Crossbow deals more damage.");
			DrawPanelText(panel, "6)Code optimizing.");
		}
		case 15:	//132
		{
			DrawPanelText(panel, "1)Added new Saxton's lines on...");
			DrawPanelText(panel, "  a)round start");
			DrawPanelText(panel, "  b)jump");
			DrawPanelText(panel, "  c)backstab");
			DrawPanelText(panel, "  d)destroy Sentry");
			DrawPanelText(panel, "  e)kill Scout, Pyro, Heavy, Engineer, Spy");
			DrawPanelText(panel, "  f)last man standing");
			DrawPanelText(panel, "  g)killing spree");
			DrawPanelText(panel, "2)Fixed bugged count of CBS' arrows.");
			DrawPanelText(panel, "3)Reduced Hale's damage versus DR by 20 HPs.");
			DrawPanelText(panel, "4)Now two specials can not be at a stretch.");
			DrawPanelText(panel, "v1.32_1 1)Fixed bug with replay.");
			DrawPanelText(panel, "v1.32_1 2)Fixed bug with help menu.");
		}
		case 14:	//131
			DrawPanelText(panel, "1)Now \"replay\" will not change team.");
		case 13:	//130
			DrawPanelText(panel, "1)Fixed bugs, associated with crushes, error logs, scores.");
		case 12:	//129
		{
			DrawPanelText(panel, "1)Fixed random crushes associated with CBS.");
			DrawPanelText(panel, "2)Now Hale's HP formula is ((760+x-1)*(x-1))^1.04");
			DrawPanelText(panel, "3)Added hale_special0. Use it to change next boss to Hale.");
			DrawPanelText(panel, "4)CBS has 9 arrows for bow-rage. Also he has stun rage, but on little distantion.");
			DrawPanelText(panel, "5)Teammates gets 2 scores per each 600 damage");
			DrawPanelText(panel, "6)Demoman with Targe has crits on his primary weapon.");
			DrawPanelText(panel, "7)Removed support of non-Arena maps, because nobody wasn't use it.");
			DrawPanelText(panel, "8)Pistol/Lugermorph has crits.");
		}
		case 11:	//128
		{
			DrawPanelText(panel, "VS Saxton Hale Mode is back!");
			DrawPanelText(panel, "1)Christian Brutal Sniper is a regular character.");
			DrawPanelText(panel, "2)CBS has 3 melee weapons ad bow-rage.");
			DrawPanelText(panel, "3)Added new lines for Vagineer.");
			DrawPanelText(panel, "4)Updated models of Vagineer and HHH jr.");
		}
		case 10:	//999
			DrawPanelText(panel, "Attachables are broken. Many \"thx\" to Valve.");
		case 9:	//126
		{
			DrawPanelText(panel, "1)Added the second URL for auto-update.");
			DrawPanelText(panel, "2)Fixed problems, when auto-update was corrupt plugin.");
			DrawPanelText(panel, "3)Added a question for the next Hale, if he want to be him. (/haleme)");
			DrawPanelText(panel, "4)Eyelander and Half-Zatoichi was replaced with Claidheamh Mor.");
			DrawPanelText(panel, "5)Fan O'War replaced with Bat.");
			DrawPanelText(panel, "6)Dispenser and TP won't be destoyed after Engineer's death.");
			DrawPanelText(panel, "7)Mode uses the localization file.");
			DrawPanelText(panel, "8)Saxton Hale will be choosed randomly for the first 3 rounds (then by queue).");
		}
		case 8:	//125
		{
			DrawPanelText(panel, "1)Fixed silent HHHjr's rage.");
			DrawPanelText(panel, "2)Now bots (sourcetv too) do not will be Hale");
			DrawPanelText(panel, "3)Fixed invalid uber on Vagineer's head.");
			DrawPanelText(panel, "4)Fixed other little bugs.");
		}
		case 7:	//124
		{
			DrawPanelText(panel, "1)Fixed destroyed buildables associated with spy's fake death.");
			DrawPanelText(panel, "2)Syringe Gun replaced with Blutsauger.");
			DrawPanelText(panel, "3)Blutsauger, on hit: +5 to uber-charge.");
			DrawPanelText(panel, "4)Removed crits from Blutsauger.");
			DrawPanelText(panel, "5)CnD replaced with Invis Watch.");
			DrawPanelText(panel, "6)Fr.Justice replaced with shotgun");
			DrawPanelText(panel, "7)Fists of steel replaced with fists.");
			DrawPanelText(panel, "8)KGB replaced with GRU.");
			DrawPanelText(panel, "9)Added /haleclass.");
			DrawPanelText(panel, "10)Medic gets assist damage scores (1/2 from healing target's damage scores, 1/1 when uber-charged)");
		}
		case 6:	//123
		{
			DrawPanelText(panel, "1)Added Super Duper Jump to rescue Hale from pit");
			DrawPanelText(panel, "2)Removed pyro's ammolimit");
			DrawPanelText(panel, "3)Fixed little bugs.");
		}
		case 5:	//122
		{
			DrawPanelText(panel, "1.21)Point will be enabled when X or less players be alive.");
			DrawPanelText(panel, "1.22)Now it's working :) Also little optimize about player count.");
		}
		case 4:	//120
		{
			DrawPanelText(panel, "1)Added new Hale's phrases.");
			DrawPanelText(panel, "2)More bugfixes.");
			DrawPanelText(panel, "3)Improved super-jump.");
		}
		case 3:	//112
		{
			DrawPanelText(panel, "1)More bugfixes.");
			DrawPanelText(panel, "2)Now \"(Hale)<mapname>\" can be nominated for nextmap.");
			DrawPanelText(panel, "3)Medigun's uber gets uber and crits for Medic and his target.");
			DrawPanelText(panel, "4)Fixed infinite Specials.");
			DrawPanelText(panel, "5)And more bugfixes.");
		}
		case 2:	//111
		{
			DrawPanelText(panel, "1)Fixed immortal spy");
			DrawPanelText(panel, "2)Fixed crashes associated with classlimits.");
		}
		case 1:	//110
		{
			DrawPanelText(panel, "1)Not important changes on code.");
			DrawPanelText(panel, "2)Added hale_enabled convar.");
			DrawPanelText(panel, "3)Fixed bug, when all hats was removed...why?");
		}
		case 0:	//100
		{
			DrawPanelText(panel, "Released!!!");
			DrawPanelText(panel, "On new version you will get info about changes.");
		}
		default:
		{
			DrawPanelText(panel, "-- Somehow you've managed to find a glitched version page!");
			DrawPanelText(panel, "-- Congratulations. Now go fight Hale.");
		}
	}
}
public HelpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		return;
	}
}
public Action:HelpPanelCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	HelpPanel(client);
	return Plugin_Handled;
}
public Action:HelpPanel(client)
{
	if (!Enabled2 || IsVoteInProgress())
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	decl String:s[512];
	SetGlobalTransTarget(client);
	Format(s, 512, "%t", "help_mode");
	DrawPanelItem(panel, s);
	Format(s, 512, "%t", "menu_6");
	DrawPanelItem(panel, s);
	SendPanelToClient(panel, client, HelpPanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
public Action:HelpPanel2Cmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	HelpPanel2(client);
	return Plugin_Handled;
}
public Action:HelpPanel2(client)
{
	if (!Enabled2 || IsVoteInProgress())
		return Plugin_Continue;
	decl String:s[512];
	new TFClassType:class = TF2_GetPlayerClass(client);
	SetGlobalTransTarget(client);
	switch (class)
	{
		case TFClass_Scout:
			Format(s, 512, "%t", "help_scout");
		case TFClass_Soldier:
			Format(s, 512, "%t", "help_soldier");
		case TFClass_Pyro:
			Format(s, 512, "%t", "help_pyro");
		case TFClass_DemoMan:
			Format(s, 512, "%t", "help_demo");
		case TFClass_Heavy:
			Format(s, 512, "%t", "help_heavy");
		case TFClass_Engineer:
			Format(s, 512, "%t", "help_eggineer");
		case TFClass_Medic:
			Format(s, 512, "%t", "help_medic");
		case TFClass_Sniper:
			Format(s, 512, "%t", "help_sniper");
		case TFClass_Spy:
			Format(s, 512, "%t", "help_spie");
		default:
			Format(s, 512, "");
	}
	new Handle:panel = CreatePanel();
	if (class != TFClass_Sniper)
		Format(s, 512, "%t\n%s", "help_melee", s);
	SetPanelTitle(panel, s);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}
public Action:ClasshelpinfoCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	ClasshelpinfoSetting(client);
	return Plugin_Handled;
}
public Action:ClasshelpinfoSetting(client)
{
	if (!Enabled2)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Turn the VS Saxton Hale class info...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, ClasshelpinfoTogglePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Handled;
}
public ClasshelpinfoTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidClient(param1))
	{
		if (action == MenuAction_Select)
		{
			if (param2 == 2)
				SetClientCookie(param1, ClasshelpinfoCookie, "0");
			else
				SetClientCookie(param1, ClasshelpinfoCookie, "1");
			CPrintToChat(param1, "{olive}[VSH]{default} %t", "vsh_classinfo", param2 == 2 ? "off" : "on");
		}
	}
}
public HelpPanelH1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			HelpPanel(param1);
		else if (param2 == 2)
			return;
	}
}
public Action:HelpPanel1(client, Args)
{
	if (!Enabled2)
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Hale is unusually strong.\nBut he doesn't use weapons, because\nhe believes that problems should be\nsolved with bare hands.");
	DrawPanelItem(panel, "Back");
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, HelpPanelH1, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
public Action:MusicTogglePanelCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	MusicTogglePanel(client);
	return Plugin_Handled;
}
public Action:MusicTogglePanel(client)
{
	if (!Enabled2 || !IsValidClient(client))
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Turn the VS Saxton Hale music...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, MusicTogglePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
public MusicTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidClient(param1))
	{
		if (action == MenuAction_Select)
		{
			if (param2 == 2)
			{
				SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, false);
				StopHaleMusic(param1);
			}
			else
				SetClientSoundOptions(param1, SOUNDEXCEPT_MUSIC, true);
			CPrintToChat(param1, "{olive}[VSH]{default} %t", "vsh_music", param2 == 2 ? "off" : "on");
		}
	}
}
public Action:VoiceTogglePanelCmd(client, args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	VoiceTogglePanel(client);
	return Plugin_Handled;
}
public Action:VoiceTogglePanel(client)
{
	if (!Enabled2 || !IsValidClient(client))
		return Plugin_Continue;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Turn the VS Saxton Hale voices...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, VoiceTogglePanelH, 9001);
	CloseHandle(panel);
	return Plugin_Continue;
}
public VoiceTogglePanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (IsValidClient(param1))
	{
		if (action == MenuAction_Select)
		{
			if (param2 == 2)
				SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, false);
			else
				SetClientSoundOptions(param1, SOUNDEXCEPT_VOICE, true);
			CPrintToChat(param1, "{olive}[VSH]{default} %t", "vsh_voice", param2 == 2 ? "off" : "on");
			if (param2 == 2) CPrintToChat(param1, "%t", "vsh_voice2");
		}
	}
}
public Action:HookSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!Enabled || ((entity != Hale) && ((entity <= 0) || !IsValidClient(Hale) || (entity != GetPlayerWeaponSlot(Hale, 0)))))
		return Plugin_Continue;
	if (StrContains(sample, "saxton_hale", false) != -1)
		return Plugin_Continue;
	if (strcmp(sample, "vo/engineer_LaughLong01.wav", false) == 0)
	{
		strcopy(sample, PLATFORM_MAX_PATH, VagineerKSpree);
		return Plugin_Changed;
	}
	if (entity == Hale && Special == 2 && strncmp(sample, "vo", 2, false) == 0 && StrContains(sample, "halloween_boss") == -1)
	{
		if (GetRandomInt(0, 100) <= 10)
		{
			Format(sample, PLATFORM_MAX_PATH, "%s0%i.wav", HHHLaught, GetRandomInt(1, 4));
			return Plugin_Changed;
		}
	}
	if (Special != 4 && !strncmp(sample, "vo", 2, false) && StrContains(sample, "halloween_boss") == -1)
	{
		if (Special == 1)
		{
			if (StrContains(sample, "engineer_moveup", false) != -1)
				Format(sample, PLATFORM_MAX_PATH, "%s%i.wav", VagineerJump, GetRandomInt(1, 2));
			else if (StrContains(sample, "engineer_no", false) != -1 || GetRandomInt(0, 9) > 6)
				strcopy(sample, PLATFORM_MAX_PATH, "vo/engineer_no01.wav");
			else
				strcopy(sample, PLATFORM_MAX_PATH, "vo/engineer_jeers02.wav");
			return Plugin_Changed;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}
stock GetAmmo(client, slot)
{
	if (!IsValidClient(client)) return 0;
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(client, iAmmoTable+iOffset);
	}
	return 0;
}
stock GetHealingTarget(client)
{
	new String:s[64];
	new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (medigun <= MaxClients || !IsValidEdict(medigun))
		return -1;
	GetEdictClassname(medigun, s, sizeof(s));
	if (strcmp(s, "tf_weapon_medigun", false) == 0)
	{
		if (GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}
	return -1;
}
/*WriteConfig()
{
	new String:s[256];
	new String:s2[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, s2, PLATFORM_MAX_PATH, "configs/saxton_hale_config.cfg");
	new Handle:fileh = OpenFile(s2, "wb");
	Format(s, 256, "hale_speed %f", HaleSpeed);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_point_delay %i", PointDelay);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_rage_damage %i", RageDMG);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_rage_dist %f", RageDist);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_announce %f", Announce);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_specials %i", bSpecials);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_point_type %i", PointType);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_point_delay %i", PointDelay);
	WriteFileLine(fileh, s, false);
	Format(s, 256, "hale_point_alive %i", AliveToEnable);
	WriteFileLine(fileh, s, false);
	CloseHandle(fileh);
}*/
stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		decl String:adminname[32];
	//	decl String:auth[32];
		decl String:name[32];
		new AdminId:admin;
		GetClientName(client, name, sizeof(name));
	//	GetClientAuthString(client, auth, sizeof(auth));
		if (strcmp(name, "replay", false) == 0 && IsFakeClient(client)) return false;
		if ((admin = GetUserAdmin(client)) != INVALID_ADMIN_ID)
		{
			GetAdminUsername(admin, adminname, sizeof(adminname));
			if (strcmp(adminname, "Replay", false) == 0 || strcmp(adminname, "SourceTV", false) == 0) return false;
		}
	}
	return true;
}
public Native_IsEnabled(Handle:plugin, numParams)
{
	return Enabled;
}
public Native_GetHale(Handle:plugin, numParams)
{
	if (IsValidClient(Hale))
		return GetClientUserId(Hale);
	return -1;
}
public Native_GetTeam(Handle:plugin, numParams)
{
	return HaleTeam;
}
public Native_GetSpecial(Handle:plugin, numParams)
{
	return Special;
}
public Native_GetHealth(Handle:plugin, numParams)
{
	return HaleHealth;
}
public Native_GetHealthMax(Handle:plugin, numParams)
{
	return HaleHealthMax;
}
public Native_GetRoundState(Handle:plugin, numParams)
{
	return VSHRoundState;
}
public Native_GetDamage(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!IsValidClient(client))
		return 0;
	return Damage[client];
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}