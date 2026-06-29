#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <sourcebans>

#pragma semicolon 1

// Constants
#define PLUGIN_VERSION	 "1.11"

#define GAMEDESC		 "Hosties/jailbreak"
#define SERVERTAG		 "SM_Hosties"
#define MESS			 "\x03[SM_Hosties] \x01%t"
#define DEBUG_MESS		 "\x04[SM_Hosties DEBUG] \x01"
#define SOUND_BLIP		 "buttons/blip1.wav"

// Global vars
new g_iRaceCountdown;
new Float:gV_StartRaceLocation[3];
new Float:gV_EndRaceLocation[3];
new Handle:LRsenabled;
new LRchoises[MAXPLAYERS];
new LRaskcaller;
new LRtype;
new LRplayers[MAXPLAYERS];
new bool:LRblock = true;
new bool:LRinprogress = false;
new LRprogressplayer1;
new LRprogressplayer2;

new mute = 0;
new muteImmuneAdmSetting = -1;
new AdminFlag:muteImmuneAdm;
new Handle:muteTimer = INVALID_HANDLE;
new bool:unmuteTsRun = true;
new ct_give;
new Handle:playerBeacons[MAXPLAYERS + 1];

new CFloser;
new bool:CFdone = false;

new bool:GTp1dropped = false;
new bool:GTp2dropped = false;
new Float:GTp1droppos[3];
new Float:GTp2droppos[3];
new bool:GTcheckerstarted = false;
new bool:GTp1done = false;
new bool:GTp2done = false;
new Float:GTdeagle1lastpos[3];
new Float:GTdeagle2lastpos[3];

new BeamSprite;
new HaloSprite;
new redColor[] = {255, 25, 15, 255};
new blueColor[] = {50, 75, 255, 255};
new greenColor[] = {15, 255, 15, 255};
new greyColor[] = {128, 128, 128, 255};
new yellowColor[] = {255, 255, 0, 255};

new GTdeagle1;
new GTdeagle2;

new S4Slastshot;
new S4Sp1latestammo;
new S4Sp2latestammo;
new s4s_doubleshot_action;
new lr_gt_mode;

new Handle:HPtimer = INVALID_HANDLE;
new HPdeagle;
new HPloser;
new bool:HPendrunning = false;
new Handle:HPdeagleBeacon = INVALID_HANDLE;

new Handle:DBtimer = INVALID_HANDLE;

new NSweaponChoises[MAXPLAYERS + 1];

new RPSplayerChosen = -1;

new bool:LRannounced = false;

new rebels[MAXPLAYERS];
new rebelscount;
new CTfreekills[MAXPLAYERS + 1];
new bool:AllowWeaponDrop = true;

// ConVar-stuff
new Handle:sm_hosties_lr_race_enable         = INVALID_HANDLE;
new Handle:sm_hosties_lr_kf_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_kf_cheat_action	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_s4s_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_s4s_dblsht_action	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_s4s_shot_taken		 = INVALID_HANDLE;
new Handle:sm_hosties_lr_gt_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_gt_mode			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_gt_markers			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_slay			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_cheat_action	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_loser_color1	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_loser_color2	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_cf_loser_color3	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_hp_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_hp_mintime			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_hp_maxtime			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_hp_pickupannounce	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_hp_cheat_action	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_hp_teleport		 = INVALID_HANDLE;
new Handle:sm_hosties_lr_hp_speed_multipl	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_db_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_db_gravity			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_db_cheatcheck		 = INVALID_HANDLE;
new Handle:sm_hosties_lr_db_flash_duration	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_ns_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_ns_weapon			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_ns_delay			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_rps_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_lr					 = INVALID_HANDLE;
new Handle:sm_hosties_lr_ts_max				 = INVALID_HANDLE;
new Handle:sm_hosties_lr_beacon				 = INVALID_HANDLE;
new Handle:sm_hosties_lr_beacon_interval	 = INVALID_HANDLE;
new Handle:sm_hosties_lr_rebel_mode			 = INVALID_HANDLE;
new Handle:sm_hosties_lr_p_killed_action	 = INVALID_HANDLE;
new Handle:sm_hosties_ct_start				 = INVALID_HANDLE;
new Handle:sm_hosties_rebel_color1			 = INVALID_HANDLE;
new Handle:sm_hosties_rebel_color2			 = INVALID_HANDLE;
new Handle:sm_hosties_rebel_color3			 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_sound		 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_sound_mode	 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_treshold		 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_punishment	 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_ban_length	 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_reset		 = INVALID_HANDLE;
new Handle:sm_hosties_freekill_notify		 = INVALID_HANDLE;
new Handle:sm_hosties_lr_sound				 = INVALID_HANDLE;
new Handle:sm_hosties_noscope_sound			 = INVALID_HANDLE;
new Handle:sm_hosties_announce_rebel		 = INVALID_HANDLE;
new Handle:sm_hosties_announce_rules		 = INVALID_HANDLE;
new Handle:sm_hosties_announce_attack		 = INVALID_HANDLE;
new Handle:sm_hosties_announce_wpn_attack	 = INVALID_HANDLE;
new Handle:sm_hosties_announce_rebel_down	 = INVALID_HANDLE;
new Handle:sm_hosties_announce_lr			 = INVALID_HANDLE;
new Handle:sm_hosties_rules_enable			 = INVALID_HANDLE;
new Handle:sm_hosties_checkplayers_enable	 = INVALID_HANDLE;
new Handle:sm_hosties_mute					 = INVALID_HANDLE;
new Handle:sm_hosties_mute_ct				 = INVALID_HANDLE;
new Handle:sm_hosties_roundstart_mute		 = INVALID_HANDLE;
new Handle:sm_hosties_mute_immune			 = INVALID_HANDLE;
new Handle:sm_hosties_override_gamedesc		 = INVALID_HANDLE;
new Handle:sm_hosties_add_servertag			 = INVALID_HANDLE;
new Handle:sm_hosties_noblock_enable		 = INVALID_HANDLE;
new Handle:sm_hosties_roundend_overlay_t	 = INVALID_HANDLE;
new Handle:sm_hosties_roundend_overlay_ct	 = INVALID_HANDLE;
new Handle:sm_hosties_version				 = INVALID_HANDLE;

new String:freekill_sound[PLATFORM_MAX_PATH] = "-1";
new String:lr_sound[PLATFORM_MAX_PATH] = "-1";
new String:noscope_sound[PLATFORM_MAX_PATH] = "-1";

new Handle:g_hDropWeapon;
//new g_iFlashAlpha = -1;
new g_offsCollisionGroup = -1;

new bool:EST_FOUND = false;
new bool:CV_overrideGameDesc = false;
new bool:MS_overrideGameDesc = false;

new bool:g_bSBAvailable = false;

public Plugin:myinfo =
{
	name = "SM_Hosties",
	author = "dataviruset",
	description = "Hosties/ba_jail/jailbreak functionality for SourceMod",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Load translations
	LoadTranslations("hosties.phrases");

	new Handle:hGameConf = LoadGameConfigFile("hosties.games");
	if (hGameConf == INVALID_HANDLE)
		SetFailState("Unable to load gamedata file hosties.games.txt");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hDropWeapon = EndPrepSDKCall();

	/*g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	if (g_iFlashAlpha == -1)
		LogMessage("[SM_Hosties] Failed to get offset for CCSPlayer::m_flFlashMaxAlpha. Dodgeball fights will be very bright.");*/
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_offsCollisionGroup == -1)
		LogMessage("[SM_Hosties] Failed to get offset for CBaseEntity::m_CollisionGroup. Integrated noblock isn't going to work.");

	// Console commands
	RegConsoleCmd("sm_lr", Command_LastRequest);
	RegConsoleCmd("sm_lastrequest", Command_LastRequest);
	RegConsoleCmd("sm_checkplayers", Command_CheckPlayers);

	decl String:file[256];
	BuildPath(Path_SM, file, 255, "configs/hosties_rulesdisable.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh == INVALID_HANDLE)
		RegConsoleCmd("sm_rules", Command_Rules);

	// Events hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	//HookEvent("player_blind", Event_PlayerBlind);
	HookEvent("player_spawn", Event_PlayerSpawn);
	//HookEvent("flashbang_detonate", Event_FlashDetonate);
	HookEvent("weapon_zoom", Event_WeaponZoom);

	// Create ConVars
	sm_hosties_lr = CreateConVar("sm_hosties_lr", "1", "Enable or disable Last Requests (the !lr command): 0 - disable, 1 - enable");
	sm_hosties_lr_race_enable = CreateConVar("sm_hosties_lr_race_enable", "1", "Enable or disable race option in last request");
	sm_hosties_lr_ts_max = CreateConVar("sm_hosties_lr_ts_max", "2", "The maximum number of terrorists left to enable LR: 0 - LR is always enabled, >0 - maximum number of Ts");
	sm_hosties_lr_beacon = CreateConVar("sm_hosties_lr_beacon", "1", "Beacon players on LR or not: 0 - disable, 1 - enable");
	sm_hosties_lr_beacon_interval = CreateConVar("sm_hosties_lr_beacon_interval", "1.0", "The interval in seconds of which the beacon 'beeps' on LR", _, true, 0.1, true, 3.0);
	sm_hosties_lr_rebel_mode = CreateConVar("sm_hosties_lr_rebel_mode", "1", "LR-mode for rebelling terrorists: 0 - Rebelling Ts can never have a LR, 1 - Rebelling Ts must let the CT decide if a LR is OK, 2 - Rebelling Ts can have a LR just like other Ts");
	sm_hosties_lr_p_killed_action = CreateConVar("sm_hosties_lr_p_killed_action", "0", "What to do when a LR-player gets killed by a player not in LR during LR: 0 - just abort LR, 1 - abort LR and slay the attacker");
	sm_hosties_ct_start = CreateConVar("sm_hosties_ct_start", "2", "Weapons given CT on spawn: 0 - knife only, 1 - knife and deagle, 2 - knife, deagle and colt");
	sm_hosties_lr_kf_enable = CreateConVar("sm_hosties_lr_kf_enable", "1", "Enable LR Knife Fight: 0 - disable, 1 - enable");
	sm_hosties_lr_kf_cheat_action = CreateConVar("sm_hosties_lr_kf_cheat_action", "1", "What to do with a knife fighter who attacks the other player with another weapon than knife: 0 - abort LR, 1 - slay player");
	sm_hosties_lr_s4s_enable = CreateConVar("sm_hosties_lr_s4s_enable", "1", "Enable LR Shot4Shot: 0 - disable, 1 - enable");
	sm_hosties_lr_s4s_dblsht_action = CreateConVar("sm_hosties_lr_s4s_dblsht_action", "1", "What to do with someone who fires 2 shots in a row in Shot4Shot: 0 - nothing (ignore completely), 1 - abort the LR, 2 - slay the player who fired 2 shots in a row");
	sm_hosties_lr_s4s_shot_taken = CreateConVar("sm_hosties_lr_s4s_shot_taken", "1", "Enable announcements in Shot4Shot when a contestant has taken his shot: 0 - disable, 1 - enable");
	sm_hosties_lr_gt_enable = CreateConVar("sm_hosties_lr_gt_enable", "1", "Enable LR Gun Toss: 0 - disable, 1 - enable");
	sm_hosties_lr_gt_mode = CreateConVar("sm_hosties_lr_gt_mode", "1", "How Gun Toss will be played: 0 - no double-dropping checking, deagle gets 7 ammo at start, 1 - double dropping check, deagle gets 7 ammo on drop, colouring of deagles, deagle markers");
	sm_hosties_lr_gt_markers = CreateConVar("sm_hosties_lr_gt_markers", "0", "Deagle marking (requires sm_hosties_lr_gt_mode 1): 0 - markers straight up where the deagles land, 1 - markers starting where the deagle was dropped ending at the deagle landing point");
	sm_hosties_lr_cf_enable = CreateConVar("sm_hosties_lr_cf_enable", "1", "Enable LR Chicken Fight: 0 - disable, 1 - enable");
	sm_hosties_lr_cf_slay = CreateConVar("sm_hosties_lr_cf_slay", "1", "Slay the loser of a Chicken Fight instantly? 0 - disable, 1 - enable");
	sm_hosties_lr_cf_cheat_action = CreateConVar("sm_hosties_lr_cf_cheat_action", "1", "What to do with a chicken fighter who attacks the other player with another weapon than knife: 0 - abort LR, 1 - slay player");
	sm_hosties_lr_cf_loser_color1 = CreateConVar("sm_hosties_lr_cf_loser_color1", "255", "What color to turn the loser of a chicken fight into (only if sm_hosties_lr_cf_slay == 0, set R, G and B values to 255 to disable) (Rgb): x - red value");
	sm_hosties_lr_cf_loser_color2 = CreateConVar("sm_hosties_lr_cf_loser_color2", "255", "What color to turn the loser of a chicken fight into (rGb): x - green value");
	sm_hosties_lr_cf_loser_color3 = CreateConVar("sm_hosties_lr_cf_loser_color3", "0", "What color to turn the loser of a chicken fight into (rgB): x - blue value");
	sm_hosties_lr_hp_enable = CreateConVar("sm_hosties_lr_hp_enable", "1", "Enable LR Hot Potato: 0 - disable, 1 - enable");
	sm_hosties_lr_hp_mintime = CreateConVar("sm_hosties_lr_hp_mintime", "10.0", "Minimum time in seconds the Hot Potato contest will last for (time is randomized): float value - time", _, true, 0.0, true, 45.0);
	sm_hosties_lr_hp_maxtime = CreateConVar("sm_hosties_lr_hp_maxtime", "20.0", "Maximum time in seconds the Hot Potato contest will last for (time is randomized): float value - time", _, true, 8.0, true, 120.0);
	sm_hosties_lr_hp_pickupannounce = CreateConVar("sm_hosties_lr_hp_pickupannounce", "1", "Enable announcement when a Hot Potato contestant picks up the hot potato: 0 - disable, 1 - enable");
	sm_hosties_lr_hp_cheat_action = CreateConVar("sm_hosties_lr_hp_cheat_action", "1", "What to do with a hot potato contestant who attacks the other player: 0 - abort LR, 1 - slay player");
	sm_hosties_lr_hp_teleport = CreateConVar("sm_hosties_lr_hp_teleport", "1", "Teleport CT to T on hot potato contest start: 0 - disable, 1 - enable");
	sm_hosties_lr_hp_speed_multipl = CreateConVar("sm_hosties_lr_hp_speed_multipl", "1.15", "What speed multiplier a hot potato contestant who has the deagle is gonna get: <1.0 - slower, >1.0 - faster", _, true, 0.8, true, 3.0);
	sm_hosties_lr_db_enable = CreateConVar("sm_hosties_lr_db_enable", "1", "Enable LR Dodgeball: 0 - disable, 1 - enable");
	sm_hosties_lr_db_gravity = CreateConVar("sm_hosties_lr_db_gravity", "0.6", "What gravity multiplier the dodgeball contestants will get: <1.0 - less/lower, >1.0 - more/higher", _, true, 0.1, true, 2.0);
	sm_hosties_lr_db_cheatcheck = CreateConVar("sm_hosties_lr_db_cheatcheck", "1", "Enable health-checker in LR Dodgeball to prevent contestant cheating (healing themselves): 0 - disable, 1 - enable");
	sm_hosties_lr_db_flash_duration = CreateConVar("sm_hosties_lr_db_flash_duration", "1.4", "The amount of time after a thrown flash before a new flash is given to a contestant: float value - delay in seconds", _, true, 0.7, true, 6.0);
	sm_hosties_lr_ns_enable = CreateConVar("sm_hosties_lr_ns_enable", "1", "Enable LR No Scope Battle: 0 - disable, 1 - enable");
	sm_hosties_lr_ns_weapon = CreateConVar("sm_hosties_lr_ns_weapon", "2", "Weapon to use in a No Scope Battle: 0 - awp, 1 - scout, 2 - let the terrorist choose");
	sm_hosties_lr_ns_delay = CreateConVar("sm_hosties_lr_ns_delay", "2.0", "Delay in seconds before a No Scope Battle begins (to prepare the contestants...): float value - delay in seconds", _, true, 0.5, true, 8.0);
	sm_hosties_lr_rps_enable = CreateConVar("sm_hosties_lr_rps_enable", "1", "Enable LR Rock Paper Scissors: 0 - disable, 1 - enable");
	sm_hosties_rebel_color1 = CreateConVar("sm_hosties_rebel_color1", "255", "What color to turn a rebel into (set R, G and B values to 255 to disable) (Rgb): x - red value");
	sm_hosties_rebel_color2 = CreateConVar("sm_hosties_rebel_color2", "0", "What color to turn a rebel into (rGb): x - green value");
	sm_hosties_rebel_color3 = CreateConVar("sm_hosties_rebel_color3", "0", "What color to turn a rebel into (rgB): x - blue value");
	sm_hosties_freekill_sound = CreateConVar("sm_hosties_freekill_sound", "sm_hosties/freekill1.mp3", "What sound to play if a non-rebelling T gets 'freekilled', relative to the sound-folder: -1 - disable, path - path to sound file (set downloading and precaching in addons/sourcemod/configs/hosties_sounddownloads.ini)");
	sm_hosties_freekill_sound_mode = CreateConVar("sm_hosties_freekill_sound_mode", "1", "When to play the 'freekill sound': 0 - on freeATTACK, 1 - on freeKILL");
	sm_hosties_freekill_treshold = CreateConVar("sm_hosties_freekill_treshold", "5", "The amount of non-rebelling terrorists a CT is allowed to kill before action is taken: 0 - disabled, >0 - amount of Ts");
	sm_hosties_freekill_punishment = CreateConVar("sm_hosties_freekill_punishment", "0", "The punishment to give to a CT who overrides the treshold: 0 - slay, 1 - kick, 2 - ban");
	sm_hosties_freekill_ban_length = CreateConVar("sm_hosties_freekill_ban_length", "60", "The length of an automated freekill ban (if sm_hosties_freekill_punishment is 2): x - ban length in minutes", _, true, 0.0);
	sm_hosties_freekill_reset = CreateConVar("sm_hosties_freekill_reset", "0", "When to reset the 'freekill counter' for all CTs: 0 - on round start, 1 - on map end");
	sm_hosties_freekill_notify = CreateConVar("sm_hosties_freekill_notify", "0", "Whether to notify CTs who kills a non-rebelling T about how many 'freekills' they have, or not: 0 - disable, 1 - enable");
	sm_hosties_lr_sound = CreateConVar("sm_hosties_lr_sound", "sm_hosties/lr1.mp3", "What sound to play when LR gets available, relative to the sound-folder (also requires sm_hosties_announce_lr to be 1): -1 - disable, path - path to sound file (set downloading and precaching in addons/sourcemod/configs/hosties_sounddownloads.ini)");
	sm_hosties_noscope_sound = CreateConVar("sm_hosties_noscope_sound", "sm_hosties/noscopestart1.mp3", "What sound to play when a No Scope Battle starts, relative to the sound-folder: -1 - disable, path - path to sound file (set downloading and precaching in addons/sourcemod/configs/hosties_sounddownloads.ini)");	
	sm_hosties_announce_rebel = CreateConVar("sm_hosties_announce_rebel", "1", "Enable or disable chat announcements when a terrorist becomes a rebel: 0 - disable, 1 - enable");
	sm_hosties_announce_rules = CreateConVar("sm_hosties_announce_rules", "1", "Enable or disable rule announcements in the beginning of every round ('please follow the rules listed in !rules'): 0 - disable, 1 - enable");
	sm_hosties_announce_attack = CreateConVar("sm_hosties_announce_attack", "1", "Enable or disable announcements when a CT attacks a non-rebelling T: 0 - disable, 1 - enable");
	sm_hosties_announce_wpn_attack = CreateConVar("sm_hosties_announce_wpn_attack", "0", "Enable or disable an announcement telling that a non-rebelling T has a weapon when he gets attacked by a CT (also requires sm_hosties_announce_attack 1): 0 - disable, 1 - enable");
	sm_hosties_announce_rebel_down = CreateConVar("sm_hosties_announce_rebel_down", "1", "Enable or disable chat announcements when a rebel is killed: 0 - disable, 1 - enable");
	sm_hosties_announce_lr = CreateConVar("sm_hosties_announce_lr", "1", "Enable or disable chat announcements when Last Requests starts to be available: 0 - disable, 1 - enable");
	sm_hosties_rules_enable = CreateConVar("sm_hosties_rules_enable", "1", "Enable or disable rules showing up at !rules command (if you need to disable the command registration on plugin startup, add a file in your sourcemod/configs/ named hosties_rulesdisable.ini with any content): 0 - disable, 1 - enable");
	sm_hosties_checkplayers_enable = CreateConVar("sm_hosties_checkplayers_enable", "1", "Enable or disable the !checkplayers command: 0 - disable, 1 - enable");
	sm_hosties_mute = CreateConVar("sm_hosties_mute", "0", "Setting for muting terrorists automatically: 0 - disable, 1 - terrorists are muted the first 30 seconds of a round, 2 - terrorists are muted when they die, 3 - both");
	sm_hosties_mute_ct = CreateConVar("sm_hosties_mute_ct", "0", "Setting for muting counter-terrorists automatically when they die (requires sm_hosties_mute 2 or 3): 0 - disable, 1 - enable");
	sm_hosties_roundstart_mute = CreateConVar("sm_hosties_roundstart_mute", "30.0", "If sm_hosties_mute is 1 or 3, how many seconds the roundstart mute will last: float value - time in seconds", _, true, 3.0, true, 90.0);
	sm_hosties_mute_immune = CreateConVar("sm_hosties_mute_immune", "root", "Admin flag which is immune from getting muted: 0 - nobody, 1 - all admins, immunity flag - valid values (case-sensitive): reservation,generic,kick,ban,unban,slay,changemap,convars,config,chat,vote,password,rcon,cheats,root,custom1,custom2, (...)");
	sm_hosties_override_gamedesc = CreateConVar("sm_hosties_override_gamedesc", "1", "Enable or disable an override of the game description (standard Counter-Strike: Source, override to Hosties/jailbreak): 0 - disable, 1 - enable");
	sm_hosties_add_servertag = CreateConVar("sm_hosties_add_servertag", "1", "Enable or disable automatic adding of SM_Hosties in sv_tags (visible from the server browser in CS:S): 0 - disable, 1 - enable");
	sm_hosties_noblock_enable = CreateConVar("sm_hosties_noblock_enable", "0", "Enable or disable integrated removing of player vs player collisions (noblock): 0 - disable, 1 - enable");
	sm_hosties_roundend_overlay_t = CreateConVar("sm_hosties_roundend_overlay_t", "overlays/sm_hosties/prisoners_win", "What overlay to display if Ts win, relative to the materials-folder: path - path to overlay material without file extension (set downloading and precaching in addons/sourcemod/configs/hosties_decaldownloads.ini)");
	sm_hosties_roundend_overlay_ct = CreateConVar("sm_hosties_roundend_overlay_ct", "overlays/sm_hosties/prisonguards_win", "What overlay to display if CTs win, relative to the materials-folder: path - path to overlay material without file extension (set downloading and precaching in addons/sourcemod/configs/hosties_decaldownloads.ini)");
	sm_hosties_version = CreateConVar("sm_hosties_version", PLUGIN_VERSION, "SM_Hosties plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	SetConVarString(sm_hosties_version, PLUGIN_VERSION);
	AutoExecConfig(true, "sm_hosties");

	// Hook ConVar-changes
	HookConVarChange(sm_hosties_version, VersionChange);

	LRsenabled = CreateArray(2);
}

public OnMapStart()
{
	decl String:file[256];
	BuildPath(Path_SM, file, 255, "configs/hosties_sounddownloads.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh != INVALID_HANDLE)
	{
		decl String:buffer[256];
		decl String:buffer_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			if ( (StrContains(buffer, "//") == -1) && (!StrEqual(buffer, "")) )
			{
				Format(buffer_full, sizeof(buffer_full), "sound/%s", buffer);
				if (FileExists(buffer_full))
				{
					PrecacheSound(buffer, true);
					AddFileToDownloadsTable(buffer_full);
				}
				else
				{
					PrintToServer("File does not exist! %s", buffer_full);
				}
			}
		}
	}

	decl String:file2[256];
	BuildPath(Path_SM, file2, 255, "configs/hosties_decaldownloads.ini");
	new Handle:fileh2 = OpenFile(file2, "r");
	if (fileh2 != INVALID_HANDLE)
	{
		decl String:buffer2[256];
		decl String:buffer2_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh2, buffer2, sizeof(buffer2)))
		{
			TrimString(buffer2);
			if ( (StrContains(buffer2, "//") == -1) && (!StrEqual(buffer2, "")) )
			{
				Format(buffer2_full, sizeof(buffer2_full), "materials/%s", buffer2);
				if (FileExists(buffer2_full))
				{
					PrecacheDecal(buffer2, true);
					AddFileToDownloadsTable(buffer2_full);
				}
				else
				{
					PrintToServer("File does not exist! %s", buffer2_full);
				}
			}
		}
	}

	BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	PrecacheSound(SOUND_BLIP, true);
	MS_overrideGameDesc = true;
}

public OnMapEnd()
{
	MS_overrideGameDesc = false;

	if (GetConVarInt(sm_hosties_freekill_reset) > 0)
		for (new i = 0; i < sizeof(CTfreekills); i++)
			CTfreekills[i] = 0;
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
	{
		g_bSBAvailable = true;
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = false;
	}
}

public OnConfigsExecuted()
{
	// Enable Last Requests
	if (GetConVarInt(sm_hosties_lr_kf_enable) == 1)
		PushArrayCell(LRsenabled, 0);
	if (GetConVarInt(sm_hosties_lr_s4s_enable) == 1)
		PushArrayCell(LRsenabled, 1);
	if (GetConVarInt(sm_hosties_lr_gt_enable) == 1)
		PushArrayCell(LRsenabled, 2);
	if (GetConVarInt(sm_hosties_lr_cf_enable) == 1)
		PushArrayCell(LRsenabled, 3);
	if (GetConVarInt(sm_hosties_lr_hp_enable) == 1)
		PushArrayCell(LRsenabled, 4);
	if (GetConVarInt(sm_hosties_lr_db_enable) == 1)
		PushArrayCell(LRsenabled, 5);
	if (GetConVarInt(sm_hosties_lr_ns_enable) == 1)
		PushArrayCell(LRsenabled, 6);
	if (GetConVarInt(sm_hosties_lr_rps_enable) == 1)
		PushArrayCell(LRsenabled, 7);
	if (GetConVarInt(sm_hosties_lr_race_enable) == 1)
		PushArrayCell(LRsenabled, 8);

	s4s_doubleshot_action = GetConVarInt(sm_hosties_lr_s4s_dblsht_action);
	lr_gt_mode = GetConVarInt(sm_hosties_lr_gt_mode);
	mute = GetConVarInt(sm_hosties_mute);

	GetConVarString(sm_hosties_freekill_sound, freekill_sound, sizeof(freekill_sound));
	GetConVarString(sm_hosties_lr_sound, lr_sound, sizeof(lr_sound));
	GetConVarString(sm_hosties_noscope_sound, noscope_sound, sizeof(noscope_sound));

	decl String:mute_immune[16];
	GetConVarString(sm_hosties_mute_immune, mute_immune, sizeof(mute_immune));
	if (StrEqual(mute_immune, "0"))
		muteImmuneAdmSetting = -1;
	else if (StrEqual(mute_immune, "1"))
		muteImmuneAdmSetting = 0;
	else if (!FindFlagByName(mute_immune, muteImmuneAdm))
		muteImmuneAdmSetting = -1;
	else
		muteImmuneAdmSetting = 1;

	if (!StrEqual(freekill_sound, "-1"))
	{
		new String:freekill_sound_full[PLATFORM_MAX_PATH] = "sound/";
		StrCat(freekill_sound_full, sizeof(freekill_sound_full), freekill_sound);
		if (!FileExists(freekill_sound_full))
			freekill_sound = "-1";
	}
	if (!StrEqual(lr_sound, "-1"))
	{
		new String:lr_sound_full[PLATFORM_MAX_PATH] = "sound/";
		StrCat(lr_sound_full, sizeof(lr_sound_full), lr_sound);
		if (!FileExists(lr_sound_full))
			lr_sound = "-1";
	}
	if (!StrEqual(freekill_sound, "-1"))
	{
		new String:freekill_sound_full[PLATFORM_MAX_PATH] = "sound/";
		StrCat(freekill_sound_full, sizeof(freekill_sound_full), freekill_sound);
		if (!FileExists(freekill_sound_full))
			freekill_sound = "-1";
	}

	if (GetConVarInt(sm_hosties_override_gamedesc) == 1)
		CV_overrideGameDesc = true;

	if (GetConVarInt(sm_hosties_add_servertag) == 1)
		ServerCommand("sv_tags %s\n", SERVERTAG);

	if (FindConVar("est_version"))
	{
		EST_FOUND = true;
		LogMessage("WARNING! ES_Tools detected! SM_Hosties doesn't support ES_Tools! For more info, see https://forums.alliedmods.net/showthread.php?p=1168325#post1168325");
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public Action:OnWeaponDrop(client, weapon)
{
	if (AllowWeaponDrop == false)
		return Plugin_Handled;

	if ( (LRinprogress == true) && (lr_gt_mode == 1) && (LRtype == 2) && ((client == LRprogressplayer1) || (client == LRprogressplayer2)) )
	{
		decl String:weapon_name[32];
		GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
		if (StrEqual(weapon_name, "weapon_deagle"))
		{
			if ( ((GTp1dropped == true) && (client == LRprogressplayer1)) || ((GTp2dropped == true) && (client == LRprogressplayer2)) )
			{
				PrintToChat(client, MESS, "Already Dropped Deagle");
				return Plugin_Handled;
			}
			else
			{
				if (client == LRprogressplayer1)
				{
					if (IsValidEntity(GTdeagle1))
						SetEntData(GTdeagle1, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 7);

					GetClientAbsOrigin(client, GTp1droppos);
					//PrintToChatAll("\x04[SM_Hosties DEBUG] \x01GT - P1 DROPPED = TRUE");
					GTp1dropped = true;
				}
				else
				{
					if (IsValidEntity(GTdeagle2))
						SetEntData(GTdeagle2, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 7);

					GetClientAbsOrigin(client, GTp2droppos);
					//PrintToChatAll("\x04[SM_Hosties DEBUG] \x01GT - P2 DROPPED = TRUE");
					GTp2dropped = true;
				}

				if (!GTcheckerstarted)
				{
					GTcheckerstarted = true;
					CreateTimer(0.1, GTchecker, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:OnWeaponEquip(client, weapon)
{
	if (LRinprogress)
	{
		if (LRtype == 2)
		{
			if ( (client == LRprogressplayer1) && (GTp1dropped) && (!GTp1done) )
			{
				decl String:weapon_name[32];
				GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
				if (StrEqual(weapon_name, "weapon_deagle"))
				{
					GTp1done = true;
				}
			}
			else if ( (client == LRprogressplayer2) && (GTp2dropped) && (!GTp2done) )
			{
				decl String:weapon_name[32];
				GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
				if (StrEqual(weapon_name, "weapon_deagle"))
				{
					GTp2done = true;
				}
			}
		}

		// hot potato last pickup stuff :p
		else if (LRtype == 4)
		{
			if ((client == LRprogressplayer1) || (client == LRprogressplayer2))
			{
				if (weapon == HPdeagle)
				{
					HPloser = client;
					if (GetConVarInt(sm_hosties_lr_hp_pickupannounce) == 1)
						PrintToChatAll(MESS, "Hot Potato PickUp", client);

					if (GetConVarFloat(sm_hosties_lr_hp_speed_multipl) != 1.0)
					{
						SetEntPropFloat( ((client == LRprogressplayer1) ? LRprogressplayer1 : LRprogressplayer2), Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(sm_hosties_lr_hp_speed_multipl));
						SetEntPropFloat( ((client == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), Prop_Data, "m_flLaggedMovementValue", 1.0);
					}
				}
				else
				{
					decl String:weapon_name[32];
					GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
					if ( (StrEqual(weapon_name, "weapon_p228")) || (StrEqual(weapon_name, "weapon_deagle"))
					 || (StrEqual(weapon_name, "weapon_elite")) || (StrEqual(weapon_name, "weapon_fiveseven"))
					 || (StrEqual(weapon_name, "weapon_glock")) || (StrEqual(weapon_name, "weapon_usp")) )
					{
						return Plugin_Handled;
					}
				}
			}
			else if (weapon == HPdeagle)
				CreateTimer(0.0, DropPlayerSecondarySlot, client);
		}
	}

	return Plugin_Continue;
}

public Action:DropPlayerSecondarySlot(Handle:timer, any:client)
{
	new ent;
	if ((ent = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != -1)
		SDKCall(g_hDropWeapon, client, ent, false, false);

	return Plugin_Continue;
}

// Gun Toss distance meter and BeamSprite application
public Action:GTchecker(Handle:timer)
{
	if ( (!IsClientInGame(LRprogressplayer1)) || (!IsPlayerAlive(LRprogressplayer1))
	  || (!IsClientInGame(LRprogressplayer2)) || (!IsPlayerAlive(LRprogressplayer2)) )
	{
		return Plugin_Stop;
	}

	new Float:GTdeagle1pos[3];
	new Float:GTdeagle2pos[3];

	if (GTp1dropped && !GTp1done)
	{
		GetEntPropVector(GTdeagle1, Prop_Data, "m_vecOrigin", GTdeagle1pos);
		if (GetVectorDistance(GTdeagle1lastpos, GTdeagle1pos) < 3.00)
		{
			GTp1done = true;

			if (GetConVarInt(sm_hosties_lr_gt_markers) < 1)
			{
				new Float:beamStartP1[3];
				new Float:beamSubtractP1[3] = {0.00, 0.00, -30.00};
				MakeVectorFromPoints(beamSubtractP1, GTdeagle1pos, beamStartP1);
				TE_SetupBeamPoints(beamStartP1, GTdeagle1pos, BeamSprite, 0, 0, 0, 18.0, 10.0, 10.0, 7, 0.0, redColor, 0);
			}
			else
				TE_SetupBeamPoints(GTp1droppos, GTdeagle1pos, BeamSprite, 0, 0, 0, 18.0, 10.0, 10.0, 7, 0.0, redColor, 0);

			TE_SendToAll();
		}
		else
		{
			GTdeagle1lastpos = GTdeagle1pos;
		}
	}
	if (GTp2dropped && !GTp2done)
	{
		GetEntPropVector(GTdeagle2, Prop_Data, "m_vecOrigin", GTdeagle2pos);
		if (GetVectorDistance(GTdeagle2lastpos, GTdeagle2pos) < 3.00)
		{
			GTp2done = true;
			if (GetConVarInt(sm_hosties_lr_gt_markers) < 1)
			{
				new Float:beamStartP2[3];
				new Float:beamSubtractP2[3] = {0.00, 0.00, -30.00};
				MakeVectorFromPoints(beamSubtractP2, GTdeagle2pos, beamStartP2);
				TE_SetupBeamPoints(beamStartP2, GTdeagle2pos, BeamSprite, 0, 0, 0, 18.0, 10.0, 10.0, 7, 0.0, blueColor, 0);
			}
			else
				TE_SetupBeamPoints(GTp2droppos, GTdeagle2pos, BeamSprite, 0, 0, 0, 18.0, 10.0, 10.0, 7, 0.0, blueColor, 0);

			TE_SendToAll();
		}
		else
		{
			GTdeagle2lastpos = GTdeagle2pos;
		}
	}

	if (GTp1done && GTp2done)
		return Plugin_Stop;

	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	LRinprogress = false;
	GTp1dropped = false;
	GTp2dropped = false;

	for (new i = 0; i < sizeof(rebels); i++)
		rebels[i] = 0;

	rebelscount = 0;

	if (GetConVarInt(sm_hosties_freekill_reset) == 0)
		for (new i = 0; i < sizeof(CTfreekills); i++)
			CTfreekills[i] = 0;

	// reset overlay
	ShowOverlayToAll("");

	if (EST_FOUND) // ES_Tools-server :(
		PrintToServer("WARNING! ES_Tools detected! SM_Hosties doesn't support ES_Tools! See server log for further details.");

	// weapon stripping (and giving) done, enable player weapon dropping again
	//AllowWeaponDrop = true;

	// cache the stuff to give to CTs at spawn
	ct_give = GetConVarInt(sm_hosties_ct_start);

	// roundstart done, enable LR
	LRblock = false;

	// print out a messages about SM_Hosties and that the players are able to use the !rules command if enabled...
	PrintToChatAll(MESS, "Powered By Hosties");

	if (GetConVarInt(sm_hosties_announce_rules) == 1)
		PrintToChatAll(MESS, "Please Follow Rules");

	// mute terrorists...
	if (mute == 1 || mute == 3)
	{
		MuteTs();

		if (muteImmuneAdmSetting == 0)
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && GetUserAdmin(i) != INVALID_ADMIN_ID)
					UnmutePlayer(i);
			}
		else if (muteImmuneAdmSetting != -1)
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && GetAdminFlag(GetUserAdmin(i), muteImmuneAdm))
					UnmutePlayer(i);
			}

		new Float:unmuteTime = GetConVarFloat(sm_hosties_roundstart_mute);
		PrintToChatAll(MESS, "Ts Muted", RoundToNearest(unmuteTime));
		unmuteTsRun = false;
		muteTimer = CreateTimer(unmuteTime, UnmuteTs, _, TIMER_FLAG_NO_MAPCHANGE);
	}

}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// roundend - block new LRs
	LRblock = true;

	// disable player weapon dropping
	//AllowWeaponDrop = false;

	// reset LR announce
	LRannounced = false;

	// kill all beacons -- disabled by default in v1.06
	//KillAllBeacons();

	// overlay stuff
	new winner_team = GetEventInt(event, "winner");
	decl String:overlaypath[PLATFORM_MAX_PATH];

	if (winner_team == CS_TEAM_T)
	{
		GetConVarString(sm_hosties_roundend_overlay_t, overlaypath, sizeof(overlaypath));
		ShowOverlayToAll(overlaypath);
	}
	else if (winner_team == CS_TEAM_CT)
	{
		GetConVarString(sm_hosties_roundend_overlay_ct, overlaypath, sizeof(overlaypath));
		ShowOverlayToAll(overlaypath);
	}

	// unmute all
	if (mute > 0)
	{
		if (!unmuteTsRun && (muteTimer != INVALID_HANDLE))
		{
			CloseHandle(muteTimer);
			muteTimer = INVALID_HANDLE;
		}

		UnmuteAll();
	}
}

public Action:UnmuteTs(Handle:timer)
{
	unmuteTsRun = true;
	UnmuteAlive();
	PrintToChatAll(MESS, "Ts Can Speak Again");

	return Plugin_Continue;
}

public Action:DBhealthChecker(Handle:timer)
{
	if (LRinprogress)
	{
		if ( IsValidEntity(LRprogressplayer1) && (GetClientHealth(LRprogressplayer1) > 1) )
			SetEntityHealth(LRprogressplayer1, 1);

		if ( IsValidEntity(LRprogressplayer2) && (GetClientHealth(LRprogressplayer2) > 1) )
			SetEntityHealth(LRprogressplayer2, 1);
	}

	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if (GetConVarInt(sm_hosties_noblock_enable) == 1)
		UnblockEntity(client);
	if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
	{
		new wepIdx;

		// strip all weapons
		for (new s = 0; s < 4; s++)
		{
			if ((wepIdx = GetPlayerWeaponSlot(client, s)) != -1)
			{
				RemovePlayerItem(client, wepIdx);
				RemoveEdict(wepIdx);
			}
		}

		if (!EST_FOUND) // if ES_Tools wasn't found, give weapons to the spawned player
			// if player == T
			if (GetClientTeam(client) == CS_TEAM_T)
			{
				GivePlayerItem(client, "weapon_knife");
			}
			// if player == CT
			else if (GetClientTeam(client) == CS_TEAM_CT)
			{
				GivePlayerItem(client, "weapon_knife");

				if (ct_give > 0)
					GivePlayerItem(client, "weapon_deagle");
				if (ct_give > 1)
					GivePlayerItem(client, "weapon_m4a1");
			}
	}
}

BlockEntity(client)
{
	SetEntData(client, g_offsCollisionGroup, 5, 4, true);
}

UnblockEntity(client)
{
	SetEntData(client, g_offsCollisionGroup, 2, 4, true);
}

// For future use...
/*BlockClientAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) )
		{
			BlockEntity(i);
		}
	}
}

UnblockClientAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) )
		{
			UnblockEntity(i);
		}
	}
}*/

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ev_attacker = GetEventInt(event, "attacker");
	new ev_target = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(ev_attacker);
	new target = GetClientOfUserId(ev_target);

	if ( (LRinprogress) && ((LRtype == 0) || (LRtype == 3) || (LRtype == 4)) && ((attacker == LRprogressplayer1) || (attacker == LRprogressplayer2)) && ((target == LRprogressplayer1) || (target == LRprogressplayer2)) )
	{
		decl String:weapon[32];
		GetEventString(event, "weapon", weapon, 32);
		if (!StrEqual(weapon, "knife"))
		{
			if (LRtype == 0) // knife fight weapon hurt
			{
				if (GetConVarInt(sm_hosties_lr_kf_cheat_action) == 1)
				{
					ForcePlayerSuicide(attacker);
					PrintToChatAll(MESS, "Knife Fight Gun Attack Slay", attacker, target, weapon);
				}
				else
					PrintToChatAll(MESS, "Knife Fight Gun Attack Abort", attacker, target, weapon);

				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					KillLRBeacons();
			}
			else if (LRtype == 3) // chicken fight weapon hurt
			{
				if ( (GetConVarInt(sm_hosties_lr_cf_cheat_action) == 1) && (!CFdone) )
				{
					ForcePlayerSuicide(attacker);
					PrintToChatAll(MESS, "Chicken Fight Gun Attack Slay", attacker, target, weapon);
					if (GetConVarInt(sm_hosties_lr_beacon) == 1)
						KillLRBeacons();

					if (GetConVarInt(sm_hosties_noblock_enable) == 1)
						UnblockEntity(attacker);

					GivePlayerItem(target, "weapon_knife");
				}
				else
				{
					if (!CFdone)
					{
						PrintToChatAll(MESS, "Chicken Fight Gun Attack Abort", attacker, target, weapon);
						if (GetConVarInt(sm_hosties_lr_beacon) == 1)
							KillLRBeacons();

						if (GetConVarInt(sm_hosties_noblock_enable) == 1)
						{
							UnblockEntity(LRprogressplayer1);
							UnblockEntity(LRprogressplayer2);
						}

						GivePlayerItem(target, "weapon_knife");
						GivePlayerItem(attacker, "weapon_knife");
					}
				}
			}

			LRinprogress = false;
		}

		if ( (LRtype == 4) && (!HPendrunning) )
		{
			if (HPtimer != INVALID_HANDLE)
			{
				CloseHandle(HPtimer);
				HPtimer = INVALID_HANDLE;
			}
			if (HPdeagleBeacon != INVALID_HANDLE)
			{
				CloseHandle(HPdeagleBeacon);
				HPdeagleBeacon = INVALID_HANDLE;
			}

			if (GetConVarInt(sm_hosties_lr_beacon) == 1)
				KillLRBeacons();

			if (GetConVarInt(sm_hosties_lr_hp_cheat_action) == 1)
			{
				ForcePlayerSuicide(attacker);
				PrintToChatAll(MESS, "Hot Potato Attack Slay", attacker, target);
				SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}
			else
			{
				PrintToChatAll(MESS, "Hot Potato Attack Abort", attacker, target);
				SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.0);
				SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}

			LRinprogress = false;

			SetEntityRenderColor(HPdeagle, 255, 255, 255);
			SetEntityRenderMode(HPdeagle, RENDER_NORMAL);

		}

	}
	else if ( (attacker != 0) && (target != 0) && (GetClientTeam(attacker) == CS_TEAM_T) && (GetClientTeam(target) == CS_TEAM_CT) ) // if attacker was a terrorist and target was a counter-terrorist
	{
		if (!in_array(rebels, attacker))
		{
			if ( IsPlayerAlive(attacker) && ((!LRinprogress) || ((LRinprogress) && (attacker != LRprogressplayer1) && (attacker != LRprogressplayer2))) )
			{
				if (GetConVarInt(sm_hosties_announce_rebel) == 1)
					PrintToChatAll(MESS, "New Rebel", attacker);

				rebels[rebelscount] = attacker;
				if ( (GetConVarInt(sm_hosties_rebel_color1) != 255) || (GetConVarInt(sm_hosties_rebel_color2) != 255) || (GetConVarInt(sm_hosties_rebel_color3) != 255) )
				{
					SetEntityRenderMode(attacker, RENDER_TRANSCOLOR);
					SetEntityRenderColor(attacker, GetConVarInt(sm_hosties_rebel_color1), GetConVarInt(sm_hosties_rebel_color2), GetConVarInt(sm_hosties_rebel_color3), 255);
				}
				rebelscount++;
			}
		}
	}


	/*
		WARNING! Weird conditions coming... :P
		Don't look... PAOOW, I warned ya ;)
	*/

	else if
	   // and if attacker was a counter-terrorist and target was a terrorist
	( (attacker != 0) && (target != 0) && (GetClientTeam(attacker) == CS_TEAM_CT) && (GetClientTeam(target) == CS_TEAM_T)
	   // and "freeattack" should be announced
	&& (GetConVarInt(sm_hosties_announce_attack) == 1)
	   // and the target isn't a rebel
	&& (!in_array(rebels, target))
	   // and there isn't a LR in progress  ---- OR ---- there's a LR in progress and the attacker isn't one of the contestants
	&& ( (LRinprogress == false) || ((LRinprogress == true) && (attacker != LRprogressplayer1) && (attacker != LRprogressplayer2))) )
	{

		new bool:hasGun = false;
		if (GetConVarInt(sm_hosties_announce_wpn_attack) == 1)
		{
			if (IsClientInGame(target) && IsPlayerAlive(target))
			{
				for (new s = 0; s < 2; s++)
				{
					if (GetPlayerWeaponSlot(target, s) != -1)
					{
						hasGun = true;
						PrintToChatAll(MESS, "CT Attack T Gun", attacker, target);
						break;
					}
				}
			}
		}

		if (!hasGun)
		{
			PrintToChatAll(MESS, "Freeattack", attacker, target);

			if ( (GetConVarInt(sm_hosties_freekill_sound_mode) == 0) && (!StrEqual(freekill_sound, "-1")) )
				EmitSoundToAll(freekill_sound);
		}
	}

}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ev_attacker = GetEventInt(event, "attacker");
	new ev_target = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(ev_attacker);
	new target = GetClientOfUserId(ev_target);

	// check if the death had to do with a LR
	if ( (LRinprogress == true) && (target != CFloser) && (attacker == LRprogressplayer1 || attacker == LRprogressplayer2 || attacker == 0 || attacker == target) && (target == LRprogressplayer1 || target == LRprogressplayer2) )
	{

		// de-beacon and set vars
		if (GetConVarInt(sm_hosties_lr_beacon) == 1)
			KillLRBeacons();

		if ( (LRtype == 2) && (lr_gt_mode != 0) )
		{
			if (IsValidEntity(GTdeagle1))
			{
				SetEntityRenderColor(GTdeagle1, 255, 255, 255);
				SetEntityRenderMode(GTdeagle1, RENDER_NORMAL);
			}

			if (IsValidEntity(GTdeagle2))
			{
				SetEntityRenderColor(GTdeagle2, 255, 255, 255);
				SetEntityRenderMode(GTdeagle2, RENDER_NORMAL);
			}
		}
		else if (LRtype == 3 && (GetConVarInt(sm_hosties_noblock_enable) == 1))
		{
			UnblockEntity( (target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1 );
		}
		else if ( (LRtype == 4) && (!HPendrunning) )
		{
			//PrintToChatAll("%s HotPotato PlayerDeath call!", DEBUG_MESS);

			if (HPtimer != INVALID_HANDLE)
			{
				CloseHandle(HPtimer);
				HPtimer = INVALID_HANDLE;
			}
			if (HPdeagleBeacon != INVALID_HANDLE)
			{
				CloseHandle(HPdeagleBeacon);
				HPdeagleBeacon = INVALID_HANDLE;
			}

			SetEntPropFloat( ((target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), Prop_Data, "m_flLaggedMovementValue", 1.0);

			SetEntityRenderColor(HPdeagle, 255, 255, 255);
			SetEntityRenderMode(HPdeagle, RENDER_NORMAL);
		}
		else if (LRtype == 5)
		{
			SetEntityGravity(LRprogressplayer1, 1.0);
			SetEntityGravity(LRprogressplayer2, 1.0);
			SetEntData( ((target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			GivePlayerItem( ((target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), "weapon_knife");

			if (GetConVarInt(sm_hosties_noblock_enable) == 1)
				UnblockEntity( (target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1 );

			if (DBtimer != INVALID_HANDLE)
			{
				CloseHandle(DBtimer);
				DBtimer = INVALID_HANDLE;
			}
		}

		LRinprogress = false;

		S4Slastshot = 0;

		GTp1dropped = false;
		GTp2dropped = false;
	}
	// check if the victim was the loser of a chicken fight
	else if ( (LRinprogress == true) && (target == CFloser) )
	{
		LRinprogress = false;
		CFdone = false;
		CFloser = 0;
	}
	// check if the victim was a LR-player and the attacker was NOT a LR-player
	else if ( (LRinprogress == true) && (target == LRprogressplayer1 || target == LRprogressplayer2) && ((attacker != LRprogressplayer1) && (attacker != LRprogressplayer2)) && (attacker != 0) )
	{

		// set vars
		LRinprogress = false;

		if (LRtype == 3 && (GetConVarInt(sm_hosties_noblock_enable) == 1))
		{
			UnblockEntity( (target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1 );
		}
		else if ( (LRtype == 4) && (!HPendrunning) )
		{
			if (HPtimer != INVALID_HANDLE)
			{
				CloseHandle(HPtimer);
				HPtimer = INVALID_HANDLE;
			}
			if (HPdeagleBeacon != INVALID_HANDLE)
			{
				CloseHandle(HPdeagleBeacon);
				HPdeagleBeacon = INVALID_HANDLE;
			}

			SetEntPropFloat( ((target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
		else if (LRtype == 5)
		{
			SetEntityGravity(LRprogressplayer1, 1.0);
			SetEntityGravity(LRprogressplayer2, 1.0);
			SetEntData( ((target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			GivePlayerItem( ((target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), "weapon_knife");

			if (GetConVarInt(sm_hosties_noblock_enable) == 1)
				UnblockEntity( (target == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1 );

			if (DBtimer != INVALID_HANDLE)
			{
				CloseHandle(DBtimer);
				DBtimer = INVALID_HANDLE;
			}
		}

		S4Slastshot = 0;

		GTp1dropped = false;
		GTp2dropped = false;
		CFdone = false;
		CFloser = 0;

		if (GetConVarInt(sm_hosties_lr_p_killed_action) == 1)
		{
			ForcePlayerSuicide(attacker);
			PrintToChatAll(MESS, "Non LR Kill LR Slay", attacker, target);
		}
		else
			PrintToChatAll(MESS, "Non LR Kill LR Abort", attacker, target);

		// de-beacon
		if (GetConVarInt(sm_hosties_lr_beacon) == 1)
			KillLRBeacons();
	}
	// check if the victim was a rebelling T
	else if ( (in_array(rebels, target)) && (attacker != 0) && (attacker != target) )
	{
		if (GetConVarInt(sm_hosties_announce_rebel_down) == 1)
			PrintToChatAll(MESS, "Rebel Kill", attacker, target);
	}

	else if
	   // if attacker was a counter-terrorist and target was a terrorist
	( (attacker != 0) && (target != 0) && (GetClientTeam(attacker) == CS_TEAM_CT) && (GetClientTeam(target) == CS_TEAM_T)
	   // and the target wasn't a rebel
	&& (!in_array(rebels, target))
	   // and there isn't a LR in progress  ---- OR ---- there's a LR in progress and the attacker isn't one of the contestants
	&& ((LRinprogress == false) || ((LRinprogress == true) && (attacker != LRprogressplayer1) && (attacker != LRprogressplayer2))) )
	{
		// FREEEEEKILL... rawr...
		if (GetConVarInt(sm_hosties_freekill_treshold) > 0)
		{
			if (CTfreekills[attacker] >= GetConVarInt(sm_hosties_freekill_treshold))
			{
				// Take action...
				switch(GetConVarInt(sm_hosties_freekill_punishment))
				{
					// slay
					case 0:
					{
						ForcePlayerSuicide(attacker);
						PrintToChatAll(MESS, "Freekill Slay", attacker);
						CTfreekills[attacker] = 0;
					}

					// kick
					case 1:
					{
						KickClient(attacker, "%t", "Freekill Kick Reason");
						PrintToChatAll(MESS, "Freekill Kick", attacker);
						LogMessage("%N was kicked for killing too many non-rebelling terrorists.", attacker);
					}

					// ban
					case 2:
					{
						if (g_bSBAvailable)
						{
							SBBanPlayer(0, attacker, GetConVarInt(sm_hosties_freekill_ban_length), "SM_Hosties: Freekilling");
						}
						else
						{
							decl String:ban_message[96];
							Format(ban_message, sizeof(ban_message), "%T", "Freekill Ban Reason", attacker);
							BanClient(attacker, GetConVarInt(sm_hosties_freekill_ban_length), BANFLAG_AUTO, "SM_Hosties: Freekilling", ban_message);
							PrintToChatAll(MESS, "Freekill Ban", attacker);
						}
					}
				}
			}
			else
			{
				// Add 1 freekill to the records...
				CTfreekills[attacker]++;

				// Notify the player if the server owner so desires...
				if (GetConVarInt(sm_hosties_freekill_notify) > 0)
					PrintHintText(attacker, "%t", "Freekill Record Increased", CTfreekills[attacker], GetConVarInt(sm_hosties_freekill_treshold) + 1);
			}
		}

		// if freekill should be announced with a sound (a sound is set and precached)
		if ( (GetConVarInt(sm_hosties_freekill_sound_mode) == 1) && (!StrEqual(freekill_sound, "-1")) )
		{
			EmitSoundToAll(freekill_sound);
		}
	}

	if ( (GetConVarInt(sm_hosties_announce_lr) == 1) && (GetConVarInt(sm_hosties_lr) == 1) && (LRannounced == false) ) // if LR should be announced and LR is enabled
	{
		new Ts, CTs;
		for(new i = 1; i <= MaxClients; i++)
		{
			if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) )
			{
				if (GetClientTeam(i) == CS_TEAM_T)
					Ts++;
				else if (GetClientTeam(i) == CS_TEAM_CT)
					CTs++;
			}
		}
		if ( (Ts == GetConVarInt(sm_hosties_lr_ts_max)) && (CTs > 0) )
		{
			PrintToChatAll(MESS, "LR Available");
			LRannounced = true;
			if (!StrEqual(lr_sound, "-1"))
				EmitSoundToAll(lr_sound);
		}
	}

	// if the Ts should be muted when they die and the player is T 			 or if the CTs should be muted when they die and the player is CT
	if ( ((mute == 2 || mute == 3) && (GetClientTeam(target) == CS_TEAM_T)) || (GetConVarInt(sm_hosties_mute_ct) == 1 && GetClientTeam(target) == CS_TEAM_CT) )
	{
		// check that the player isn't an admin which shouldn't be muted etc...
		if (muteImmuneAdmSetting == -1 || (muteImmuneAdmSetting == 1 && !GetAdminFlag(GetUserAdmin(target), muteImmuneAdm)) || (muteImmuneAdmSetting == 0 && GetUserAdmin(target) == INVALID_ADMIN_ID))
		{
			// mute the player and notify him/her
			MutePlayer(target);
			PrintToChat(target, MESS, "Now Muted");
		}
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ev_client = GetEventInt(event, "userid");
	new client = GetClientOfUserId(ev_client);

	if ( (LRinprogress == true) && ((client == LRprogressplayer1) || (client == LRprogressplayer2)) )
	{
		// set vars
		LRinprogress = false;

		S4Slastshot = 0;

		GTp1dropped = false;
		GTp2dropped = false;
		CFdone = false;
		CFloser = 0;

		if (GetConVarInt(sm_hosties_lr_beacon) == 1)
			KillLRBeacons();

		if (LRtype == 2)
		{
			if (lr_gt_mode != 0)
			{
				if (IsValidEntity(GTdeagle1))
				{
					SetEntityRenderColor(GTdeagle1, 255, 255, 255);
					SetEntityRenderMode(GTdeagle1, RENDER_NORMAL);
				}

				if (IsValidEntity(GTdeagle2))
				{
					SetEntityRenderColor(GTdeagle2, 255, 255, 255);
					SetEntityRenderMode(GTdeagle2, RENDER_NORMAL);
				}
			}
		}
		else if (LRtype == 3 && (GetConVarInt(sm_hosties_noblock_enable) == 1))
		{
			UnblockEntity( (client == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1 );
		}
		else if ( (LRtype == 4) && (!HPendrunning) )
		{
			if (HPtimer != INVALID_HANDLE)
			{
				CloseHandle(HPtimer);
				HPtimer = INVALID_HANDLE;
			}
			if (HPdeagleBeacon != INVALID_HANDLE)
			{
				CloseHandle(HPdeagleBeacon);
				HPdeagleBeacon = INVALID_HANDLE;
			}

			SetEntPropFloat( ((client == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), Prop_Data, "m_flLaggedMovementValue", 1.0);

			SetEntityRenderColor(HPdeagle, 255, 255, 255);
			SetEntityRenderMode(HPdeagle, RENDER_NORMAL);
		}
		else if (LRtype == 5)
		{
			SetEntityGravity( ((client == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), 1.0);
			SetEntData( ((client == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			GivePlayerItem( ((client == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1), "weapon_knife");

			if (GetConVarInt(sm_hosties_noblock_enable) == 1)
				UnblockEntity( (client == LRprogressplayer1) ? LRprogressplayer2 : LRprogressplayer1 );

			if (DBtimer != INVALID_HANDLE)
			{
				CloseHandle(DBtimer);
				DBtimer = INVALID_HANDLE;
			}
		}

		PrintToChatAll(MESS, "LR Player Disconnect", client);
	}

	CTfreekills[client] = 0;
}

public Action:CFchecker(Handle:timer)
{
	if ( (LRinprogress == true) && (CFdone != true) && (LRtype == 3) ) // NEW chicken fight game script :o
	{
		new p1EntityBelow = GetEntDataEnt2(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_hGroundEntity"));
		new p2EntityBelow = GetEntDataEnt2(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_hGroundEntity"));
		if (p1EntityBelow == LRprogressplayer2) // p1 is standing on p2
		{
			if (GetConVarInt(sm_hosties_lr_cf_slay) == 1)
			{
				PrintToChatAll(MESS, "Chicken Fight Win And Slay", LRprogressplayer1, LRprogressplayer2);
				ForcePlayerSuicide(LRprogressplayer2);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					KillLRBeacons();

				LRinprogress = false;
				GivePlayerItem(LRprogressplayer1, "weapon_knife");
			}
			else
			{
				CFdone = true;
				CFloser = LRprogressplayer2;
				PrintToChatAll(MESS, "Chicken Fight Win", LRprogressplayer1);
				PrintToChat(LRprogressplayer1, MESS, "Chicken Fight Kill Loser", LRprogressplayer2);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					KillLRBeacons();

				GivePlayerItem(LRprogressplayer1, "weapon_knife");

				if ( (GetConVarInt(sm_hosties_lr_cf_loser_color1) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color2) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color3) != 255) )
					CreateTimer(0.5, SetLoserColor, LRprogressplayer2, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}

		}
		else if (p2EntityBelow == LRprogressplayer1) // p2 is standing on p1
		{
			if (GetConVarInt(sm_hosties_lr_cf_slay) == 1)
			{
				PrintToChatAll(MESS, "Chicken Fight Win And Slay", LRprogressplayer2, LRprogressplayer1);
				ForcePlayerSuicide(LRprogressplayer1);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					KillLRBeacons();

				LRinprogress = false;
				GivePlayerItem(LRprogressplayer2, "weapon_knife");
			}
			else
			{
				CFdone = true;
				CFloser = LRprogressplayer1;
				PrintToChatAll(MESS, "Chicken Fight Win", LRprogressplayer2);
				PrintToChat(LRprogressplayer2, MESS, "Chicken Fight Kill Loser", LRprogressplayer1);
				if (GetConVarInt(sm_hosties_lr_beacon) == 1)
					KillLRBeacons();

				GivePlayerItem(LRprogressplayer2, "weapon_knife");

				if ( (GetConVarInt(sm_hosties_lr_cf_loser_color1) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color2) != 255) || (GetConVarInt(sm_hosties_lr_cf_loser_color3) != 255) )
					CreateTimer(0.5, SetLoserColor, LRprogressplayer1, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}

		}
	}
	else
		return Plugin_Stop;

	return Plugin_Continue;
}

/*public Action:Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( (LRinprogress) && (LRtype == 5) )
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		SetEntDataFloat(client, g_iFlashAlpha, 0.0);
	}
}

public Action:Event_FlashDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( (LRinprogress) && (LRtype == 5) && ((client == LRprogressplayer1) || (client == LRprogressplayer2)) )
	{
		new flash = CreateEntityByName("weapon_flashbang");
		DispatchSpawn(flash);
		EquipPlayerWeapon(client, flash);
	}
}*/

public OnEntityCreated(entity, const String:classname[])
{
	if ( (LRinprogress) && (LRtype == 5) && StrEqual(classname, "flashbang_projectile") )
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public OnEntitySpawned(entity)
{
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	decl String:classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));

	if (client == LRprogressplayer1 || client == LRprogressplayer2)
		CreateTimer(0.0, Timer_RemoveThinkTick, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_RemoveThinkTick(Handle:timer, any:entity)
{
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	CreateTimer(GetConVarFloat(sm_hosties_lr_db_flash_duration), Timer_RemoveFlashbang, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_RemoveFlashbang(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		AcceptEntityInput(entity, "Kill");

		if ( LRinprogress && (LRtype == 5) && IsClientInGame(client) && IsPlayerAlive(client) )
		{
			new flash = CreateEntityByName("weapon_flashbang");
			DispatchSpawn(flash);
			EquipPlayerWeapon(client, flash);
		}
	}
}

public Action:Event_WeaponZoom(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( (LRinprogress) && (LRtype == 6) && ((client == LRprogressplayer1) || (client == LRprogressplayer2)) )
		SetEntData(client, FindSendPropOffs("CBasePlayer", "m_iFOV"), 0, 4, true);

	return Plugin_Continue;
}

public OnGameFrame()
{
	if (s4s_doubleshot_action != 0)
	{
		if ((LRinprogress == true) && (LRtype == 1))
		{
			if (GetClientButtons(LRprogressplayer1) & IN_ATTACK)
			{
				decl String:weapon[32];
				GetClientWeapon(LRprogressplayer1, weapon, sizeof(weapon));
				if (StrEqual(weapon, "weapon_deagle"))
				{
					if (S4Sp1latestammo == 0)
						S4Sp1latestammo = 50;

					new iWeapon = GetEntDataEnt2(LRprogressplayer1, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
					new currentammo = GetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"));
					if (currentammo < S4Sp1latestammo)
					{
						if (S4Slastshot == LRprogressplayer1)
						{
							if (s4s_doubleshot_action == 2)
							{
								ForcePlayerSuicide(LRprogressplayer1);
								PrintToChatAll(MESS, "S4S Double Shot Slay", LRprogressplayer1);
							}
							else
								PrintToChatAll(MESS, "S4S Double Shot Abort", LRprogressplayer1);

							if (GetConVarInt(sm_hosties_lr_beacon) == 1)
								KillLRBeacons();

							LRinprogress = false;
							S4Slastshot = 0;
							S4Sp1latestammo = 0;
							S4Sp2latestammo = 0;
						}
						else
						{
							S4Sp1latestammo = currentammo;
							S4Slastshot = LRprogressplayer1;
							if (GetConVarInt(sm_hosties_lr_s4s_shot_taken) == 1)
								PrintToChatAll(MESS, "S4S Shot Taken", LRprogressplayer1);
						}
					}
					else
						S4Sp1latestammo = currentammo;
				}
			}

			if (GetClientButtons(LRprogressplayer2) & IN_ATTACK)
			{
				decl String:weapon[32];
				GetClientWeapon(LRprogressplayer2, weapon, sizeof(weapon));
				if (StrEqual(weapon, "weapon_deagle"))
				{
					if (S4Sp2latestammo == 0)
						S4Sp2latestammo = 50;

					new iWeapon = GetEntDataEnt2(LRprogressplayer2, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
					new currentammo = GetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"));
					if (currentammo < S4Sp2latestammo)
					{
						if (S4Slastshot == LRprogressplayer2)
						{
							if (s4s_doubleshot_action == 2)
							{
								ForcePlayerSuicide(LRprogressplayer2);
								PrintToChatAll(MESS, "S4S Double Shot Slay", LRprogressplayer2);
							}
							else
								PrintToChatAll(MESS, "S4S Double Shot Abort", LRprogressplayer2);

							if (GetConVarInt(sm_hosties_lr_beacon) == 1)
								KillLRBeacons();

							LRinprogress = false;
							S4Slastshot = 0;
							S4Sp1latestammo = 0;
							S4Sp2latestammo = 0;
						}
						else
						{
							S4Sp2latestammo = currentammo;
							S4Slastshot = LRprogressplayer2;
							if (GetConVarInt(sm_hosties_lr_s4s_shot_taken) == 1)
								PrintToChatAll(MESS, "S4S Shot Taken", LRprogressplayer2);
						}
					}
					else
						S4Sp2latestammo = currentammo;
				}
			}
		}
	}
}

public Action:HPend(Handle:timer)
{
	HPendrunning = true;

	if (HPloser == LRprogressplayer1)
	{
		ForcePlayerSuicide(LRprogressplayer1);
		PrintToChatAll(MESS, "HP Win", LRprogressplayer2, LRprogressplayer1);
		SetEntPropFloat(LRprogressplayer2, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	else if (HPloser == LRprogressplayer2)
	{
		ForcePlayerSuicide(LRprogressplayer2);
		PrintToChatAll(MESS, "HP Win", LRprogressplayer1, LRprogressplayer2);
		SetEntPropFloat(LRprogressplayer1, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	else
	{
		PrintToChatAll("%s HotPotato_Err :: HPloser: %N (%i)", DEBUG_MESS, HPloser, HPloser);
		KillAllBeacons();
	}

	LRinprogress = false;

	if (HPdeagleBeacon != INVALID_HANDLE)
	{
		CloseHandle(HPdeagleBeacon);
		HPdeagleBeacon = INVALID_HANDLE;
	}

	SetEntityRenderColor(HPdeagle, 255, 255, 255);
	SetEntityRenderMode(HPdeagle, RENDER_NORMAL);

	HPendrunning = false;
	return Plugin_Stop;
}

public Action:SetLoserColor(Handle:timer, any:client)
{
	if (IsPlayerAlive(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, GetConVarInt(sm_hosties_lr_cf_loser_color1), GetConVarInt(sm_hosties_lr_cf_loser_color2), GetConVarInt(sm_hosties_lr_cf_loser_color3), 255);
	}
	else
		return Plugin_Stop;

	return Plugin_Continue;
}

public bool:in_array(any:haystack[], needle)
{
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		if (haystack[i] == needle)
			return true;
	}

	return false;
}

public Action:Command_LastRequest(client, args)
{
	if (GetConVarInt(sm_hosties_lr) == 1)
	{
		if (!LRblock)
		{
			if (!LRinprogress)
			{
				if (IsPlayerAlive(client) && (GetClientTeam(client) == CS_TEAM_T))
				{
					if ( (in_array(rebels, client)) && (GetConVarInt(sm_hosties_lr_rebel_mode) == 0) )
					{
						PrintToChat(client, MESS, "LR Rebel Not Allowed");
					}
					else
					{
						// check the number of terrorists still alive
						new Ts, CTs;
						for(new i=1; i <= MaxClients; i++)
						{
							if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) )
							{
								if (GetClientTeam(i) == CS_TEAM_T)
									Ts++;
								else if (GetClientTeam(i) == CS_TEAM_CT)
									CTs++;
							}
						}

						if (Ts <= GetConVarInt(sm_hosties_lr_ts_max))
						{
							if (CTs > 0)
							{
								new Handle:menu = CreateMenu(MainHandler);
								SetMenuTitle(menu, "%T", "LR Choose", client);

								if (GetConVarInt(sm_hosties_lr_kf_enable) == 1)
								{
									decl String:lr_kf[32];
									Format(lr_kf, sizeof(lr_kf), "%T", "Knife Fight", client);
									AddMenuItem(menu, "knife", lr_kf);
								}
								if (GetConVarInt(sm_hosties_lr_s4s_enable) == 1)
								{
									decl String:lr_s4s[32];
									Format(lr_s4s, sizeof(lr_s4s), "%T", "Shot4Shot", client);
									AddMenuItem(menu, "s4s", lr_s4s);
								}
								if (GetConVarInt(sm_hosties_lr_gt_enable) == 1)
								{
									decl String:lr_gt[32];
									Format(lr_gt, sizeof(lr_gt), "%T", "Gun Toss", client);
									AddMenuItem(menu, "guntoss", lr_gt);
								}
								if (GetConVarInt(sm_hosties_lr_cf_enable) == 1)
								{
									decl String:lr_cf[32];
									Format(lr_cf, sizeof(lr_cf), "%T", "Chicken Fight", client);
									AddMenuItem(menu, "chickenfight", lr_cf);
								}
								if (GetConVarInt(sm_hosties_lr_hp_enable) == 1)
								{
									decl String:lr_hp[32];
									Format(lr_hp, sizeof(lr_hp), "%T", "Hot Potato", client);
									AddMenuItem(menu, "hotpotato", lr_hp);
								}
								if (GetConVarInt(sm_hosties_lr_db_enable) == 1)
								{
									decl String:lr_db[32];
									Format(lr_db, sizeof(lr_db), "%T", "Dodgeball", client);
									AddMenuItem(menu, "dodgeball", lr_db);
								}
								if (GetConVarInt(sm_hosties_lr_ns_enable) == 1)
								{
									decl String:lr_ns[32];
									Format(lr_ns, sizeof(lr_ns), "%T", "No Scope Battle", client);
									AddMenuItem(menu, "noscope", lr_ns);
								}
								if (GetConVarInt(sm_hosties_lr_rps_enable) == 1)
								{
									decl String:lr_rsp[32];
									Format(lr_rsp, sizeof(lr_rsp), "%T", "Rock Paper Scissors", client);
									AddMenuItem(menu, "rockscissorspaper", lr_rsp);
								}

								if (GetConVarInt(sm_hosties_lr_race_enable) == 1)
								{
									decl String:lr_race[32];
									Format(lr_race, sizeof(lr_race), "%T", "Race", client);
									AddMenuItem(menu, "race", lr_race);
								} 

								SetMenuExitButton(menu, true);
								DisplayMenu(menu, client, 20);
							}
							else
								PrintToChat(client, MESS, "No CTs Alive");
						}
						else
							PrintToChat(client, MESS, "Too Many Ts");
					}
				}
				else
					PrintToChat(client, MESS, "Not Alive Or In Wrong Team");
			}
			else
				PrintToChat(client, MESS, "Another LR In Progress");
		}
		else
			PrintToChat(client, MESS, "LR Not Available");
	}
	else
		PrintToChat(client, MESS, "LR Disabled");

	return Plugin_Handled;
}

public MainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!LRblock)
		{
			if (!LRinprogress)
			{
				if (IsPlayerAlive(param1) && (GetClientTeam(param1) == CS_TEAM_T))
				{
					if (param2 == 0 || param2 == 1 || param2 == 2 || param2 == 3 || param2 == 4 || param2 == 5 || param2 == 6 || param2 == 7 || param2 == 8)
					{
						LRchoises[(param1-1)] = GetArrayCell(LRsenabled, param2);

						if ( param2 == 6 && GetConVarInt(sm_hosties_lr_ns_weapon) == 2 )
						{
							// if the LR is noscope and the terrorist should decide which gun that is going to be used

							new Handle:NSweaponMenu = CreateMenu(MainNSweaponHandler);
							SetMenuTitle(NSweaponMenu, "%T", "NS Weapon Chooser Menu", param1);

							AddMenuItem(NSweaponMenu, "awp", "AWP");
							AddMenuItem(NSweaponMenu, "scout", "Scout");

							SetMenuExitButton(NSweaponMenu, true);
							DisplayMenu(NSweaponMenu, param1, 10);
						}
						else if (param2 == 10)
						{
							// create menu for T to choose start point
							new Handle:racemenu1 = CreateMenu(RaceStartPointHandler);
							SetMenuTitle(racemenu1, "Find a Starting Location");
							AddMenuItem(racemenu1, "startloc", "Use current position");
							SetMenuExitButton(racemenu1, true);
							DisplayMenu(racemenu1, param1, MENU_TIME_FOREVER);
						}
						else
						{
							CreateMainPlayerHandler(param1);
						}
					}
					else
						PrintToChat(param1, "%s That last request (%i) is invalid.", DEBUG_MESS, param2);
				}
				else
					PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
			}
			else
				PrintToChat(param1, MESS, "Another LR In Progress");
		}
		else
			PrintToChat(param1, MESS, "LR Not Available");
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

CreateMainPlayerHandler(client)
{
	new Handle:playermenu = CreateMenu(MainPlayerHandler);
	SetMenuTitle(playermenu, "%T", "Choose A Player", client);

	new playeri;
	for(new i=1; i <= MaxClients; i++)
	{
		if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) && (GetClientTeam(i) == CS_TEAM_CT) ) // if player is alive and in CT
		{
			decl String:clientname[32];
			Format(clientname, sizeof(clientname), "%N", i);
			AddMenuItem(playermenu, "player", clientname); // add to the menu
			LRplayers[playeri] = i;
			playeri++;
		}
	}

	if (playeri == 0)
	{
		PrintToChat(client, MESS, "No CTs Alive");
		CloseHandle(playermenu);
	}
	else
	{
		SetMenuExitButton(playermenu, true);
		DisplayMenu(playermenu, client, 20);
	}
}

public MainPlayerHandler(Handle:playermenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!LRblock)
		{
			if (!LRinprogress)
			{
				if (IsPlayerAlive(param1) && (GetClientTeam(param1) == CS_TEAM_T))
				{
					if ((IsClientInGame(LRplayers[param2])) && (IsPlayerAlive(LRplayers[param2])) && (GetClientTeam(LRplayers[param2]) == CS_TEAM_CT))
					{

						// check the number of terrorists still alive
						new Ts, CTs;
						for(new i = 1; i <= MaxClients; i++)
						{
							if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) )
							{
								if (GetClientTeam(i) == CS_TEAM_T)
									Ts++;
								else if (GetClientTeam(i) == CS_TEAM_CT)
									CTs++;
							}
						}

						if (Ts <= GetConVarInt(sm_hosties_lr_ts_max))
						{
							if (CTs > 0)
							{
								if (LRchoises[(param1-1)] != 7 || !IsFakeClient(LRplayers[param2]))
								{
									if ( (!in_array(rebels, param1)) || (GetConVarInt(sm_hosties_lr_rebel_mode) == 2) )
									{
										LRinprogress = true;
										LRprogressplayer1 = param1;
										LRprogressplayer2 = LRplayers[param2];
										LRtype = LRchoises[(param1-1)];

										launchLR(LRtype);
									}
									else
									{
										// if rebel, send a menu to the CT asking for permission
										new Handle:askmenu = CreateMenu(MainAskHandler);
										decl String:lrname[32];
										switch (LRchoises[(param1-1)])
										{
											case 0:
											{
												Format(lrname, sizeof(lrname), "%T", "Knife Fight", LRplayers[param2]);
											}
											case 1:
											{
												Format(lrname, sizeof(lrname), "%T", "Shot4Shot", LRplayers[param2]);
											}
											case 2:
											{
												Format(lrname, sizeof(lrname), "%T", "Gun Toss", LRplayers[param2]);
											}
											case 3:
											{
												Format(lrname, sizeof(lrname), "%T", "Chicken Fight", LRplayers[param2]);
											}
											case 4:
											{
												Format(lrname, sizeof(lrname), "%T", "Hot Potato", LRplayers[param2]);
											}
											case 5:
											{
												Format(lrname, sizeof(lrname), "%T", "Dodgeball", LRplayers[param2]);
											}
											case 6:
											{
												Format(lrname, sizeof(lrname), "%T", "No Scope Battle", LRplayers[param2]);
											}
											case 7:
											{
												Format(lrname, sizeof(lrname), "%T", "Rock Paper Scissors", LRplayers[param2]);
											}
											case 8:
											{
												Format(lrname, sizeof(lrname), "%T", "Race", LRplayers[param2]);
											}
										}

										SetMenuTitle(askmenu, "%T", "Rebel Ask CT For LR", LRplayers[param2], param1, lrname);

										decl String:yes[8];
										decl String:no[8];
										Format(yes, sizeof(yes), "%T", "Yes", LRplayers[param2]);
										Format(no, sizeof(no), "%T", "No", LRplayers[param2]);
										AddMenuItem(askmenu, "yes", yes);
										AddMenuItem(askmenu, "no", no);

										LRaskcaller = param1;
										SetMenuExitButton(askmenu, true);
										DisplayMenu(askmenu, LRplayers[param2], 6);

										PrintToChat(param1, MESS, "Asking For Permission", LRplayers[param2]);
									}
								}
								else
									PrintToChat(param1, MESS, "LR Not With Bot");
							}
							else
								PrintToChat(param1, MESS, "No CTs Alive");
						}
						else
							PrintToChat(param1, MESS, "Too Many Ts");
					}
					else
						PrintToChat(param1, MESS, "Target Is Not Alive Or In Wrong Team");
				}
				else
					PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
			}
			else
				PrintToChat(param1, MESS, "Another LR In Progress");
		}
		else
			PrintToChat(param1, MESS, "LR Not Available");
	}
	else if (action == MenuAction_End)
		CloseHandle(playermenu);
}

public MainAskHandler(Handle:askmenu, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select || ( (GetConVarInt(sm_hosties_lr_rebel_mode) > 0 ) && (param1 > 0) && IsFakeClient(param1)) )
	{
		if (!LRblock)
		{
			if (!LRinprogress)
			{
				if ((IsClientInGame(LRaskcaller)) && (IsPlayerAlive(LRaskcaller)))
				{
					if (IsPlayerAlive(param1) && (GetClientTeam(param1) == CS_TEAM_CT))
					{
						if (param2 == 0 || (param1 != 0 && IsFakeClient(param1)) )
						{
							LRinprogress = true;
							LRprogressplayer1 = LRaskcaller;
							LRprogressplayer2 = param1;
							LRtype = LRchoises[(LRaskcaller-1)];

							launchLR(LRtype);
						}
						else
							PrintToChat(LRaskcaller, MESS, "Declined LR Request", param1);
					}
					else
						PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
				}
				else
					PrintToChat(param1, MESS, "LR Partner Died");
			}
			else
				PrintToChat(param1, MESS, "Too Slow Another LR In Progress");
		}
		else
			PrintToChat(param1, MESS, "LR Not Available");
	}
	else if ( (action == MenuAction_Cancel) && (IsClientInGame(LRaskcaller)) && ( (GetConVarInt(sm_hosties_lr_rebel_mode) == 0) || (!IsFakeClient(param1))) )
	{
		PrintToChat(LRaskcaller, MESS, "LR Request Decline Or Too Long", param1);
	}
	else if (action == MenuAction_End)
		CloseHandle(askmenu);
}

public MainNSweaponHandler(Handle:NSweaponMenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!LRblock)
		{
			if (!LRinprogress)
			{
				if (IsPlayerAlive(param1) && (GetClientTeam(param1) == CS_TEAM_T))
				{
					NSweaponChoises[param1] = param2;
					CreateMainPlayerHandler(param1);
				}
				else
					PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
			}
			else
				PrintToChat(param1, MESS, "Too Slow Another LR In Progress");
		}
		else
			PrintToChat(param1, MESS, "LR Not Available");
	}
	else if (action == MenuAction_End)
		CloseHandle(NSweaponMenu);
}

StripAllWeapons(any:client)
{
	new wepIdx;
	for (new i; i < 4; i++)
		if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wepIdx);
			RemoveEdict(wepIdx);
		}
}

launchLR(type)
{

	switch (type)
	{
		case 0:		// knife fight
		{
			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);

			// set HP
			SetEntData(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			SetEntData(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);

			// give knives
			GivePlayerItem(LRprogressplayer1, "weapon_knife");
			GivePlayerItem(LRprogressplayer2, "weapon_knife");

			// announce LR
			PrintToChatAll(MESS, "LR KF Start", LRprogressplayer1, LRprogressplayer2);
		}

		case 1:		// s4s
		{
			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);

			S4Sp1latestammo = 0;
			S4Sp2latestammo = 0;
			S4Slastshot = 0;

			// give knives and deagles
			GivePlayerItem(LRprogressplayer1, "weapon_knife");
			GivePlayerItem(LRprogressplayer2, "weapon_knife");
			new S4Sdeagle1 = GivePlayerItem(LRprogressplayer1, "weapon_deagle");
			new S4Sdeagle2 = GivePlayerItem(LRprogressplayer2, "weapon_deagle");

			// set ammo
			SetEntData(S4Sdeagle1, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 50);
			SetEntData(S4Sdeagle2, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 50);

			new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
			SetEntData(LRprogressplayer1, ammoOffset+(1*4), 0);
			SetEntData(LRprogressplayer2, ammoOffset+(1*4), 0);

			// set HP
			SetEntData(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			SetEntData(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);

			// announce LR
			PrintToChatAll(MESS, "LR S4S Start", LRprogressplayer1, LRprogressplayer2);
		}

		case 2:		// gun toss
		{

			GTp1dropped = false;
			GTp2dropped = false;
			GTcheckerstarted = false;
			GTp1done = false;
			GTp2done = false;

			new Float:resetTo[] = {0.00, 0.00, 0.00};
			GTdeagle1lastpos = resetTo;
			GTdeagle2lastpos = resetTo;

			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);

			// give knives and deagles
			GivePlayerItem(LRprogressplayer1, "weapon_knife");
			GivePlayerItem(LRprogressplayer2, "weapon_knife");
			GTdeagle1 = GivePlayerItem(LRprogressplayer1, "weapon_deagle");
			GTdeagle2 = GivePlayerItem(LRprogressplayer2, "weapon_deagle");

			// set ammo (Clip2) 0 -- we don't need any extra ammo...
			new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
			SetEntData(LRprogressplayer1, ammoOffset+(1*4), 0);
			SetEntData(LRprogressplayer2, ammoOffset+(1*4), 0);

			if (lr_gt_mode != 0) // if all ammo is going to be removed at first (giving ammo after drop), then remove all ammo...
			{
				// set ammo (Clip1)
				SetEntData(GTdeagle1, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 0);
				SetEntData(GTdeagle2, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 0);
			}

			if ( (LRtype == 2) && (lr_gt_mode != 0) )
			{
				SetEntityRenderMode(GTdeagle1, RENDER_TRANSCOLOR);
				SetEntityRenderColor(GTdeagle1, 255, 0, 0);
				SetEntityRenderMode(GTdeagle2, RENDER_TRANSCOLOR);
				SetEntityRenderColor(GTdeagle2, 0, 0, 255);
			}

			// announce LR
			PrintToChatAll(MESS, "LR GT Start", LRprogressplayer1, LRprogressplayer2);
		}

		case 3:		// chicken fight
		{
			CFdone = false;

			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);

			CreateTimer(0.2, CFchecker, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			if (GetConVarInt(sm_hosties_noblock_enable) == 1)
			{
				BlockEntity(LRprogressplayer1);
				BlockEntity(LRprogressplayer2);
			}

			// announce LR
			PrintToChatAll(MESS, "LR CF Start", LRprogressplayer1, LRprogressplayer2);
		}

		case 4:		// hot potato
		{
			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);

			GivePlayerItem(LRprogressplayer1, "weapon_knife");
			GivePlayerItem(LRprogressplayer2, "weapon_knife");

			// randomize contestant to get the potato deagle
			new potatoPlayer = GetRandomInt(0, 1);
			new potatoClient = (potatoPlayer == 0) ? LRprogressplayer1 : LRprogressplayer2;
			HPloser = potatoClient;

			// create the potato deagle
			HPdeagle = CreateEntityByName("weapon_deagle");
			DispatchSpawn(HPdeagle);
			EquipPlayerWeapon(potatoClient, HPdeagle);

			// set ammo (Clip2) 0
			new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
			SetEntData(potatoClient, ammoOffset+(1*4), 0);
			// set ammo (Clip1) 0
			SetEntData(HPdeagle, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 0);

			SetEntityRenderMode(HPdeagle, RENDER_TRANSCOLOR);
			SetEntityRenderColor(HPdeagle, 255, 255, 0);

			// create timer to end hot potato
			new Float:rndEnd = GetRandomFloat(GetConVarFloat(sm_hosties_lr_hp_mintime), GetConVarFloat(sm_hosties_lr_hp_maxtime));
			HPtimer = CreateTimer(rndEnd, HPend, _, TIMER_FLAG_NO_MAPCHANGE);
			HPdeagleBeacon = CreateTimer(1.0, HPdeagle_Beacon, HPdeagle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			//PrintToChatAll("%s %f sek, PotClient: %N, Rnd0/1: %i", DEBUG_MESS, rndEnd, potatoClient, potatoPlayer);

			if (GetConVarInt(sm_hosties_lr_hp_teleport) == 1)
			{
				decl Float:p1pos[3], Float:p2pos[3];
				GetClientAbsOrigin(LRprogressplayer1, p1pos);
				new Float:subtractFromp1pos[3] = {0.0, 100.0, 0.0};
				MakeVectorFromPoints(subtractFromp1pos, p1pos, p2pos);

				TeleportEntity(LRprogressplayer1, NULL_VECTOR, Float:{0.0, -90.0, 0.0}, NULL_VECTOR);
				TeleportEntity(LRprogressplayer2, p2pos, Float:{0.0, 90.0, 0.0}, NULL_VECTOR);
			}

			// announce LR
			PrintToChatAll(MESS, "LR HP Start", LRprogressplayer1, LRprogressplayer2);
		}

		case 5:		// dodgeball
		{
			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);

			// bug fix...
			new iAmmo = FindSendPropInfo("CBasePlayer", "m_iAmmo");
			SetEntData(LRprogressplayer1, iAmmo + (_:12 * 4), 0, _, true);
			SetEntData(LRprogressplayer2, iAmmo + (_:12 * 4), 0, _, true);

			// set HP
			SetEntData(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_iHealth"), 1);
			SetEntData(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_iHealth"), 1);
			SetEntData(LRprogressplayer1, FindSendPropOffs("CCSPlayer", "m_ArmorValue"), 0);
			SetEntData(LRprogressplayer2, FindSendPropOffs("CCSPlayer", "m_ArmorValue"), 0);

			// give flashbangs
			new flash1 = CreateEntityByName("weapon_flashbang");
			new flash2 = CreateEntityByName("weapon_flashbang");
			DispatchSpawn(flash1);
			DispatchSpawn(flash2);
			EquipPlayerWeapon(LRprogressplayer1, flash1);
			EquipPlayerWeapon(LRprogressplayer2, flash2);

			// gravity
			new Float:gravity = GetConVarFloat(sm_hosties_lr_db_gravity);
			SetEntityGravity(LRprogressplayer1, gravity);
			SetEntityGravity(LRprogressplayer2, gravity);

			if (GetConVarInt(sm_hosties_noblock_enable) == 1)
			{
				BlockEntity(LRprogressplayer1);
				BlockEntity(LRprogressplayer2);
			}

			// timer making sure DB contestants stay @ 1 HP (if enabled by cvar)
			if (GetConVarInt(sm_hosties_lr_db_cheatcheck) == 1)
				DBtimer = CreateTimer(1.0, DBhealthChecker, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			// announce LR
			PrintToChatAll(MESS, "LR DB Start", LRprogressplayer1, LRprogressplayer2);
		}

		case 6:		// no scope battle
		{
			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);

			// set HP
			SetEntData(LRprogressplayer1, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			SetEntData(LRprogressplayer2, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);

			CreateTimer(GetConVarFloat(sm_hosties_lr_ns_delay), NSstart, _, TIMER_FLAG_NO_MAPCHANGE);

			// announce LR
			PrintToChatAll(MESS, "LR NS Start", LRprogressplayer1, LRprogressplayer2);
		}

		case 7:		// rock paper scissors
		{
			new Handle:rpsmenu1 = CreateMenu(RPSmenuHandler);
			SetMenuTitle(rpsmenu1, "%T", "Rock Paper Scissors", LRprogressplayer1);

			decl String:r1[32], String:p1[64], String:s1[64];
			Format(r1, sizeof(r1), "%T", "Rock", LRprogressplayer1);
			Format(p1, sizeof(p1), "%T", "Paper", LRprogressplayer1);
			Format(s1, sizeof(s1), "%T", "Scissors", LRprogressplayer1);
			AddMenuItem(rpsmenu1, "rock", r1);
			AddMenuItem(rpsmenu1, "paper", p1);
			AddMenuItem(rpsmenu1, "scissors", s1);

			SetMenuExitButton(rpsmenu1, true);
			DisplayMenu(rpsmenu1, LRprogressplayer1, 20);

			new Handle:rpsmenu2 = CreateMenu(RPSmenuHandler);
			SetMenuTitle(rpsmenu2, "%T", "Rock Paper Scissors", LRprogressplayer2);

			decl String:r2[32], String:p2[64], String:s2[64];
			Format(r2, sizeof(r2), "%T", "Rock", LRprogressplayer2);
			Format(p2, sizeof(p2), "%T", "Paper", LRprogressplayer2);
			Format(s2, sizeof(s2), "%T", "Scissors", LRprogressplayer2);
			AddMenuItem(rpsmenu2, "rock", r2);
			AddMenuItem(rpsmenu2, "paper", p2);
			AddMenuItem(rpsmenu2, "scissors", s2);

			SetMenuExitButton(rpsmenu2, true);
			DisplayMenu(rpsmenu2, LRprogressplayer2, 20);

			// announce LR
			PrintToChatAll(MESS, "LR RPS Start", LRprogressplayer1, LRprogressplayer2);
		}
		case 8:        // race option
		{
			StripAllWeapons(LRprogressplayer1);
			StripAllWeapons(LRprogressplayer2);
			
			SetEntityMoveType(LRprogressplayer1, MOVETYPE_NONE);
			SetEntityMoveType(LRprogressplayer2, MOVETYPE_NONE);
			
			//  teleport both players to the start of the race
			TeleportEntity(LRprogressplayer1, gV_StartRaceLocation, NULL_VECTOR, NULL_VECTOR);
			TeleportEntity(LRprogressplayer2, gV_StartRaceLocation, NULL_VECTOR, NULL_VECTOR);
			
			g_iRaceCountdown = 3;
			// fire timer for race begin countdown
			CreateTimer(1.0, Timer_RaceCountDown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		} 
	}

	// beacon players
	if (GetConVarInt(sm_hosties_lr_beacon) == 1 && LRinprogress)
	{
		CreateBeacon(LRprogressplayer1);
		CreateBeacon(LRprogressplayer2);
	}

}

public RPSmenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (LRinprogress && LRtype == 7)
		{
			//PrintToChatAll("%s %N chose no. %d", DEBUG_MESS, param1, param2);
			if (RPSplayerChosen != -1) // if the other player has selected rock paper or scissors (= action should be taken now)
			{
				decl String:RPSr[64], String:RPSp[64], String:RPSs[64], String:RPSc1[64], String:RPSc2[64];
				Format(RPSr, sizeof(RPSr), "%T", "Rock", LANG_SERVER);
				Format(RPSp, sizeof(RPSp), "%T", "Paper", LANG_SERVER);
				Format(RPSs, sizeof(RPSs), "%T", "Scissors", LANG_SERVER);

				switch(RPSplayerChosen)
				{
					case 0:
					{
						strcopy(RPSc1, sizeof(RPSc1), RPSr);
					}
					case 1:
					{
						strcopy(RPSc1, sizeof(RPSc1), RPSp);
					}
					case 2:
					{
						strcopy(RPSc1, sizeof(RPSc1), RPSs);
					}
				}

				switch(param2)
				{
					case 0:
					{
						strcopy(RPSc2, sizeof(RPSc2), RPSr);
					}
					case 1:
					{
						strcopy(RPSc2, sizeof(RPSc2), RPSp);
					}
					case 2:
					{
						strcopy(RPSc2, sizeof(RPSc2), RPSs);
					}
				}

				if (RPSplayerChosen == param2) // tie
				{
					if (param1 == LRprogressplayer1)
						PrintToChatAll(MESS, "LR RPS Tie", LRprogressplayer1, RPSc2, LRprogressplayer2, RPSc1);
					else
						PrintToChatAll(MESS, "LR RPS Tie", LRprogressplayer2, RPSc1, LRprogressplayer1, RPSc2);

					LRinprogress = false;
					if (GetConVarInt(sm_hosties_lr_beacon) == 1)
						KillLRBeacons();
				}
				// if THIS player has won
				else if ( (param2 == 0 && RPSplayerChosen == 2) || (param2 == 1 && RPSplayerChosen == 0) || (param2 == 2 && RPSplayerChosen == 1) )
				{
					if (param1 == LRprogressplayer1)
					{
						ForcePlayerSuicide(LRprogressplayer2);
						PrintToChatAll(MESS, "LR RPS Done", LRprogressplayer1, RPSc2, LRprogressplayer2, RPSc1, LRprogressplayer1);
					}
					else
					{
						ForcePlayerSuicide(LRprogressplayer1);
						PrintToChatAll(MESS, "LR RPS Done", LRprogressplayer1, RPSc1, LRprogressplayer2, RPSc2, LRprogressplayer2);
					}
				}
				// otherwise THIS player has lost
				else
				{
					if (param1 == LRprogressplayer2)
					{
						ForcePlayerSuicide(LRprogressplayer2);
						PrintToChatAll(MESS, "LR RPS Done", LRprogressplayer1, RPSc1, LRprogressplayer2, RPSc2, LRprogressplayer1);
					}
					else
					{
						ForcePlayerSuicide(LRprogressplayer1);
						PrintToChatAll(MESS, "LR RPS Done", LRprogressplayer1, RPSc2, LRprogressplayer2, RPSc1, LRprogressplayer2);
					}
				}

				RPSplayerChosen = -1;
			}
			else
			{
				// otherwise, store the selection of this player
				RPSplayerChosen = param2;
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (LRinprogress && LRtype == 7 && (param1 == LRprogressplayer1 || param1 == LRprogressplayer2))
		{
			RPSplayerChosen = -1;
			if (IsClientInGame(param1))
				ForcePlayerSuicide(param1);
			PrintToChatAll(MESS, "LR RPS No Answer", param1);
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public Action:NSstart(Handle:timer)
{
	if ( (IsClientInGame(LRprogressplayer1)) && (IsPlayerAlive(LRprogressplayer1))
	&& (IsClientInGame(LRprogressplayer2)) && (IsPlayerAlive(LRprogressplayer2))
	&& (LRtype == 6) && LRinprogress )
	{
		// play no scope start sound
		if (!StrEqual(noscope_sound, "-1"))
			EmitSoundToAll(noscope_sound);

		GivePlayerItem(LRprogressplayer1, "weapon_knife");
		GivePlayerItem(LRprogressplayer2, "weapon_knife");

		decl NSw1, NSw2;
		switch( GetConVarInt(sm_hosties_lr_ns_weapon) )
		{
			case 0:
			{
				NSw1 = CreateEntityByName("weapon_awp");
				NSw2 = CreateEntityByName("weapon_awp");
			}

			case 1:
			{
				NSw1 = CreateEntityByName("weapon_scout");
				NSw2 = CreateEntityByName("weapon_scout");
			}

			case 2:
			{
				if (NSweaponChoises[LRprogressplayer1] == 0)
				{
					NSw1 = CreateEntityByName("weapon_awp");
					NSw2 = CreateEntityByName("weapon_awp");
				}
				else
				{
					NSw1 = CreateEntityByName("weapon_scout");
					NSw2 = CreateEntityByName("weapon_scout");
				}
			}
		}

		DispatchSpawn(NSw1);
		DispatchSpawn(NSw2);
		EquipPlayerWeapon(LRprogressplayer1, NSw1);
		EquipPlayerWeapon(LRprogressplayer2, NSw2);

		SetEntData(NSw1, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 99);
		SetEntData(NSw2, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 99);
	}

	return Plugin_Continue;
}

public Action:Command_CheckPlayers(client, args)
{
	if (GetConVarInt(sm_hosties_checkplayers_enable) == 1)
	{
		if (IsPlayerAlive(client))
		{
			new listrebels[rebelscount];
			new realrebelscount;
			for(new i; i < rebelscount; i++)
			{
				if ( (IsClientInGame(rebels[i])) && (IsPlayerAlive(rebels[i])) )
				{
					listrebels[realrebelscount] = rebels[i];
					realrebelscount++;
				}
			}

			if (realrebelscount < 1)
				PrintToChat(client, MESS, "No Rebels ATM");
			else
			{
				new Handle:checkplayersmenu = CreateMenu(Handler_DoNothing);
				decl String:rebellingterrorists[32];
				Format(rebellingterrorists, sizeof(rebellingterrorists), "%T", "Rebelling Terrorists", client);
				SetMenuTitle(checkplayersmenu, rebellingterrorists);
				decl String:item[64];
				for(new i; i < realrebelscount; i++)
				{
					GetClientName(listrebels[i], item, sizeof(item));
					AddMenuItem(checkplayersmenu, "player", item);
				}
				SetMenuExitButton(checkplayersmenu, true);
				DisplayMenu(checkplayersmenu, client, MENU_TIME_FOREVER);
			}
		}
	}
	else
		PrintToChatAll(MESS, "CheckPlayers CMD Disabled");

	return Plugin_Handled;
}

public Action:Command_Rules(client, args)
{
	if (GetConVarInt(sm_hosties_rules_enable) == 1)
	{
		decl String:file[256];
		BuildPath(Path_SM, file, sizeof(file), "configs/hosties_rules.ini");
		new Handle:fileh = OpenFile(file, "r");
		if (fileh != INVALID_HANDLE)
		{
			new Handle:rulesmenu = CreateMenu(Handler_DoNothing);
			SetMenuTitle(rulesmenu, "%t", "Server Rules");
			decl String:buffer[256];

			while(ReadFileLine(fileh, buffer, sizeof(buffer)))
				AddMenuItem(rulesmenu, "rule", buffer);

			SetMenuExitButton(rulesmenu, true);
			DisplayMenu(rulesmenu, client, MENU_TIME_FOREVER);
		}
	}

	return Plugin_Handled;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
}

/* beacon functions simplified from SM funcommands */
CreateBeacon(client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
		playerBeacons[client] = CreateTimer(GetConVarFloat(sm_hosties_lr_beacon_interval), Timer_Beacon, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

KillBeacon(client)
{
	if (playerBeacons[client] != INVALID_HANDLE)
	{
		CloseHandle(playerBeacons[client]);
		playerBeacons[client] = INVALID_HANDLE;
	}
}

KillLRBeacons()
{
	KillBeacon(LRprogressplayer1);
	KillBeacon(LRprogressplayer2);
}

KillAllBeacons()
{
	for (new i = 1; i <= MaxClients; i++)
		KillBeacon(i);
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		CloseHandle(playerBeacons[client]);
		playerBeacons[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	new team = GetClientTeam(client);

	decl Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, 375.0, BeamSprite, HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();

	if (team == CS_TEAM_T)
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	else if (team == CS_TEAM_CT)
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);

	TE_SendToAll();
	EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	

	return Plugin_Continue;
}

public Action:HPdeagle_Beacon(Handle:timer, any:entity)
{
	PrintCenterText(HPloser, MESS, "HP Last One To Have The Potato");

	if (!IsValidEdict(entity))
		return Plugin_Stop;

	decl Float:vec[3];
	GetEntPropVector(HPdeagle, Prop_Data, "m_vecOrigin", vec);
	if (vec[0] != 0.0 || vec[1] != 0.00 || vec[2] != 0.0)
	{
		vec[2] += 2;

		TE_SetupBeamRingPoint(vec, 10.0, 230.0, BeamSprite, HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();

		TE_SetupBeamRingPoint(vec, 10.0, 230.0, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, yellowColor, 10, 0);
		TE_SendToAll();
	}

	return Plugin_Continue;
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (CV_overrideGameDesc && MS_overrideGameDesc)
	{
		strcopy(gameDesc, sizeof(gameDesc), GAMEDESC);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

MutePlayer(client)
{
	SetClientListeningFlags(client, VOICE_MUTED);
}

UnmutePlayer(client)
{
	SetClientListeningFlags(client, VOICE_NORMAL);
}

MuteTs()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) ) // if player is in game and alive
		{
			// if player is a terrorist
			if (GetClientTeam(i) == CS_TEAM_T)
			{
				MutePlayer(i);
			}
		}
	}
}

UnmuteAlive()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) ) // if player is in game and alive
		{
			UnmutePlayer(i);
		}
	}
}

UnmuteAll()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) // if player is in game
		{
			UnmutePlayer(i);
		}
	}
}

ShowOverlayToClient(client, const String:overlaypath[])
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

ShowOverlayToAll(const String:overlaypath[])
{
	// x = client index.
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			ShowOverlayToClient(x, overlaypath);
		}
	}
}

public RaceEndPointHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (!LRblock)
		{
			if (!LRinprogress)
			{
				if (IsPlayerAlive(param1) && (GetClientTeam(param1) == CS_TEAM_T))
				{
					// use this location
					GetClientAbsOrigin(param1, gV_EndRaceLocation);
					gV_EndRaceLocation[2] += 10;

					TE_SetupBeamRingPoint(gV_EndRaceLocation, 100.0, 130.0, BeamSprite, HaloSprite, 0, 15, 30.0, 7.0, 0.0, greenColor, 1, 0);
					TE_SendToAll();
					
					// allow them to choose a player finally
					CreateMainPlayerHandler(param1);
				}
				else
					PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
			}
			else
			PrintToChat(param1, MESS, "Too Slow Another LR In Progress");
		}
		else
		PrintToChat(param1, MESS, "LR Not Available");
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public RaceStartPointHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        if (!LRblock)
        {
            if (!LRinprogress)
            {
                if (IsPlayerAlive(param1) && (GetClientTeam(param1) == CS_TEAM_T))
                {
                    // use this location
                    GetClientAbsOrigin(param1, gV_StartRaceLocation);
                    gV_StartRaceLocation[2] += 10;

                    TE_SetupBeamRingPoint(gV_StartRaceLocation, 100.0, 130.0, BeamSprite, HaloSprite, 0, 15, 30.0, 7.0, 0.0, yellowColor, 1, 0);
                    TE_SendToAll();
                    
                    CreateRaceEndPointMenu(param1);
                }
                else
                    PrintToChat(param1, MESS, "Not Alive Or In Wrong Team");
            }
            else
                PrintToChat(param1, MESS, "Too Slow Another LR In Progress");
        }
        else
            PrintToChat(param1, MESS, "LR Not Available");
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

CreateRaceEndPointMenu(client)
{
    new Handle:EndPointMenu = CreateMenu(RaceEndPointHandler);
    SetMenuTitle(EndPointMenu, "Choose an End Point");
    AddMenuItem(EndPointMenu, "endpoint", "Use Current Position");
    SetMenuExitButton(EndPointMenu, true);
    DisplayMenu(EndPointMenu, client, MENU_TIME_FOREVER);
}

public Action:Timer_RaceCountDown(Handle:timer)
{
    if ( (!IsClientInGame(LRprogressplayer1)) || (!IsPlayerAlive(LRprogressplayer1))
      || (!IsClientInGame(LRprogressplayer2)) || (!IsPlayerAlive(LRprogressplayer2)) )
    {
        return Plugin_Stop;
    }
    
    if (g_iRaceCountdown > 0)
    {
        PrintCenterTextAll("Race begins in %i...", g_iRaceCountdown);
        g_iRaceCountdown--;
    }
    else
    {
        PrintCenterTextAll("Go!");

        SetEntityMoveType(LRprogressplayer1, MOVETYPE_WALK);
        SetEntityMoveType(LRprogressplayer2, MOVETYPE_WALK);
        // make timer to check the race winner
        CreateTimer(0.1, Timer_Race, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public Action:Timer_Race(Handle:timer)
{
    if ( (!IsClientInGame(LRprogressplayer1)) || (!IsPlayerAlive(LRprogressplayer1))
      || (!IsClientInGame(LRprogressplayer2)) || (!IsPlayerAlive(LRprogressplayer2)) )
    {
        return Plugin_Stop;
    }

    new Float:LRPlayer1Position[3];
    new Float:LRPlayer2Position[3];

    GetClientAbsOrigin(LRprogressplayer1, LRPlayer1Position);
    GetClientAbsOrigin(LRprogressplayer2, LRPlayer2Position);
    // check if how close they are to the end point
    decl Float:distancePlayer1;
    decl Float:distancePlayer2;    
    distancePlayer1 = GetVectorDistance(LRPlayer1Position, gV_EndRaceLocation, false);
    distancePlayer2 = GetVectorDistance(LRPlayer2Position, gV_EndRaceLocation, false);
    
    // the order dictates we give ties to the terrorist
    // add a photo-finish random call later if they're both within the amount
    if (distancePlayer1 < Float:75.0)
    {
        ForcePlayerSuicide(LRprogressplayer2);
        PrintToChatAll("\x03[SM_Hosties] \x01%N has won the race!", LRprogressplayer1);
        return Plugin_Stop;
    }
    else if (distancePlayer2 < Float:75.0)
    {
        ForcePlayerSuicide(LRprogressplayer1);
        PrintToChatAll("\x03[SM_Hosties] \x01%N has won the race!", LRprogressplayer2);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}