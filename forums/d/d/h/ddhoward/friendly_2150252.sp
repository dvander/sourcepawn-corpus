#pragma semicolon 1
#define PLUGIN_VERSION "14.0612.0"

#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>

#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#include <updater>

#define UPDATE_URL "http://ddhoward.bitbucket.org/friendly.txt"

#define CHAT_PREFIX "{olive}[Friendly]{default}"
#define CHAT_PREFIX_SPACE "{olive}[Friendly]{default} "
#define CHAT_PREFIX_NOCOLOR "[Friendly]"
#define CHAT_NAME "{olive}Friendly Mode{default}"

#define DEFAULT_BLOCKED_WEAPONCLASSES "tf_weapon_flamethrower,tf_weapon_medigun,tf_weapon_lunchbox,tf_weapon_buff_item,tf_weapon_wrench"
/* Default blocked weapon classes are:
	tf_weapon_flamethrower	- Pyro's flamethrowers, to prevent airblasting
	tf_weapon_medigun		- Medic's Mediguns, to prevent healing
	tf_weapon_lunchbox		- Heavy's snacks, to prevent healing through sandvich throwing
	tf_weapon_buff_item		- Soldier's buffing secondary weapons
	tf_weapon_wrench		- Engie's wrenches, to prevent refilling/repairing/upgrading non-Friendly buildings
*/
#define DEFAULT_BLOCKED_WEAPONS "656,447,44,58,1083,222,305,1079,528,997"
/* Default blocked weapons are:
	656  - Holiday Punch, to prevent taunt forcing
	447  - Disciplinary Action, to prevent speed buff
	44   - Sandman, to prevent ball stun
	58   - Jarate, to prevent mini-crits
	1083 - Festive Jarate, to prevent mini-crits
	222  - Mad Milk, to prevent healing
	305  - Crusader's Crossbow, to prevent healing
	1079 - Festive Crusader's Crossbow, to prevent healing
	997  - Rescue Ranger, to prevent repairing non-Friendly buildings
	528  - Short Circuit, to prevent projectile destruction
*/
#define DEFAULT_WHITELISTED_WEAPONS "594,159,433"
/* Default whitelisted weapons are:
	594  - Phlogistinator, cannot airblast
	159  - Dalokohs Bar, cannot be thrown
	433  - Fishcake, cannot be thrown
*/
#define DEFAULT_BLOCKED_TAUNTS "37,1003,304,56,1005,142"
/* Default taunt-blocked weapons are:
	37   - Ubersaw
	1003 - Festive Ubersaw
	304  - Amputator
	56   - Huntsman
	1005 - Festive Huntsman
	142  - Gunslinger
*/

#define DEFAULT_OVERLAY_1 "Effects/CombineShield/comshieldwall"
#define DEFAULT_OVERLAY_2 "Effects/CombineShield/comshieldwall2"
#define DEFAULT_OVERLAY_3 "Effects/CombineShield/comshieldwall3"
#define DEFAULT_OVERLAY_4 "Effects/com_shield002a"
#define DEFAULT_OVERLAY_5 "debug/yuv"
#define DEFAULT_OVERLAY_6 "Effects/tp_eyefx/tp_eyefx"

enum f_invulnmode {
	INVULNMODE_GODMODE = 0,
	INVULNMODE_GOD = 0,
	INVULNMODE_BUDDAH = 1,
	INVULNMODE_BUDDHA = 1,
	INVULNMODE_MORTAL = 2,
};

enum f_validclientlevel {
	VCLIENT_VALIDINDEX,
	VCLIENT_CONNECTED,
	VCLIENT_INGAME,
	VCLIENT_ONATEAM,
	VCLIENT_ONAREALTEAM,
	VCLIENT_ALIVE,
};

new _:FriendlyPlayerCount;

new bool:IsFriendly[MAXPLAYERS+1];
new bool:RequestedChange[MAXPLAYERS+1];
new bool:IsAdmin[MAXPLAYERS+1];
new bool:RFETRIZ[MAXPLAYERS+1];
new bool:IsInSpawn[MAXPLAYERS+1];
new bool:IsLocked[MAXPLAYERS+1];
new _:SeenAdvert[MAXPLAYERS+1];
new Float:ToggleTimer[MAXPLAYERS+1];
new Float:AfkTime[MAXPLAYERS+1];
new p_lastbtnstate[MAXPLAYERS+1];

new Handle:hcvar_version;

new Handle:hcvar_enabled;
new bool:cvar_enabled;
new Handle:hcvar_logging;
new _:cvar_logging;
new Handle:hcvar_advert;
new bool:cvar_advert;
new Handle:hcvar_update;
new _:cvar_update;
new Handle:hcvar_maxfriendlies;
new _:cvar_maxfriendlies;
new Handle:hcvar_delay;
new Float:cvar_delay;
new Handle:hcvar_afklimit;
new _:cvar_afklimit;
new Handle:hcvar_afkinterval;
new Float:cvar_afkinterval;

new Handle:hcvar_action_h;
new _:cvar_action_h;
new Handle:hcvar_action_f;
new _:cvar_action_f;
new Handle:hcvar_action_h_spawn;
new _:cvar_action_h_spawn;
new Handle:hcvar_action_f_spawn;
new _:cvar_action_f_spawn;
new Handle:hcvar_overlay;
new String:cvar_overlay[255];
new Handle:hcvar_remember;
new bool:cvar_remember;
new Handle:hcvar_goomba;
new bool:cvar_goomba;
new Handle:hcvar_blockrtd;
new bool:cvar_blockrtd;
new Handle:hcvar_thirdperson;
new bool:cvar_thirdperson;
//new Handle:hcvar_botignore;
//new bool:cvar_botignore;
//new Handle:hcvar_settransmit;
//new _:cvar_settransmit;

new Handle:hcvar_stopcap;
new bool:cvar_stopcap;
new Handle:hcvar_stopintel;
new bool:cvar_stopintel;
new Handle:hcvar_ammopack;
new bool:cvar_ammopack;
new Handle:hcvar_healthpack;
new bool:cvar_healthpack;
new Handle:hcvar_money;
new bool:cvar_money;
new Handle:hcvar_spellbook;
new bool:cvar_spellbook;
new Handle:hcvar_pumpkin;
new bool:cvar_pumpkin;
new Handle:hcvar_airblastkill;
new bool:cvar_airblastkill;
new Handle:hcvar_funcbutton;
new bool:cvar_funcbutton;
new Handle:hcvar_usetele;
new cvar_usetele;

new Handle:hcvar_blockweps_black;
new cvar_blockweps_black[255];
new Handle:hcvar_blockweps_classes;
new String:cvar_blockweps_classes[255][64];
new Handle:hcvar_blockweps_white;
new cvar_blockweps_white[255];
new Handle:hcvar_blocktaunt;
new cvar_blocktaunt[255];

new Handle:hcvar_invuln_p;
new _:cvar_invuln_p;
new Handle:hcvar_invuln_s;
new _:cvar_invuln_s;
new Handle:hcvar_invuln_d;
new _:cvar_invuln_d;
new Handle:hcvar_invuln_t;
new _:cvar_invuln_t;

new Handle:hcvar_notarget_p;
new cvar_notarget_p;
new Handle:hcvar_notarget_s;
new bool:cvar_notarget_s;
new Handle:hcvar_notarget_d;
new bool:cvar_notarget_d;
new Handle:hcvar_notarget_t;
new bool:cvar_notarget_t;

new Handle:hcvar_noblock_p;
new _:cvar_noblock_p;
new Handle:hcvar_noblock_s;
new _:cvar_noblock_s;
new Handle:hcvar_noblock_d;
new _:cvar_noblock_d;
new Handle:hcvar_noblock_t;
new _:cvar_noblock_t;

new Handle:hcvar_alpha_p;
new _:cvar_alpha_p;
new Handle:hcvar_alpha_w;
new _:cvar_alpha_w;
new Handle:hcvar_alpha_wep;
new _:cvar_alpha_wep;
new Handle:hcvar_alpha_s;
new _:cvar_alpha_s;
new Handle:hcvar_alpha_d;
new _:cvar_alpha_d;
new Handle:hcvar_alpha_t;
new _:cvar_alpha_t;
new Handle:hcvar_alpha_proj;
new _:cvar_alpha_proj;

new Handle:hcvar_nobuild_s;
new bool:cvar_nobuild_s;
new Handle:hcvar_nobuild_d;
new bool:cvar_nobuild_d;
new Handle:hcvar_nobuild_t;
new bool:cvar_nobuild_t;
new Handle:hcvar_killbuild_h_s;
new bool:cvar_killbuild_h_s;
new Handle:hcvar_killbuild_h_d;
new bool:cvar_killbuild_h_d;
new Handle:hcvar_killbuild_h_t;
new bool:cvar_killbuild_h_t;
new Handle:hcvar_killbuild_f_s;
new bool:cvar_killbuild_f_s;
new Handle:hcvar_killbuild_f_d;
new bool:cvar_killbuild_f_d;
new Handle:hcvar_killbuild_f_t;
new bool:cvar_killbuild_f_t;


new Handle:h_timer_afkcheck;

new Handle:hfwd_CanToggleFriendly;
new Handle:hfwd_FriendlyPre;
new Handle:hfwd_Friendly;
new Handle:hfwd_FriendlyPost;
new Handle:hfwd_HostilePre;
new Handle:hfwd_Hostile;
new Handle:hfwd_HostilePost;
new Handle:hfwd_RefreshPre;
new Handle:hfwd_Refresh;
new Handle:hfwd_RefreshPost;
new Handle:hfwd_FriendlySpawn;
new Handle:hfwd_FriendlyEnable;
new Handle:hfwd_FriendlyDisable;
new Handle:hfwd_FriendlyLoad;
new Handle:hfwd_FriendlyUnload;

new Handle:g_hWeaponReset;

new g_minigunoffsetstate;


public Plugin:myinfo = {
	name = "[TF2] Friendly Mode",
	author = "Derek D. Howard",
	description = "Allows players to become invulnerable to damage from other players, while also being unable to attack other players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=213205"
};

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErr_Max) {
	MarkNativeAsOptional("GetUserMessageType"); 
	decl String:strGame[32]; strGame[0] = '\0';
	GetGameFolderName(strGame, sizeof(strGame));
	if (!StrEqual(strGame, "tf")) {
		Format(strError, iErr_Max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	CreateNative("TF2Friendly_IsFriendly", Native_CheckIfFriendly);
	CreateNative("TF2Friendly_SetFriendly", Native_SetFriendly);
	CreateNative("TF2Friendly_IsLocked", Native_CheckIfFriendlyLocked);
	CreateNative("TF2Friendly_SetLock", Native_SetFriendlyLock);
	CreateNative("TF2Friendly_IsAdmin", Native_CheckIfFriendlyAdmin);
	CreateNative("TF2Friendly_SetAdmin", Native_SetFriendlyAdmin);
	CreateNative("TF2Friendly_RefreshFriendly", Native_RefreshFriendly);
	CreateNative("TF2Friendly_IsPluginEnabled", Native_CheckPluginEnabled);
	RegPluginLibrary("[TF2] Friendly Mode");

	return APLRes_Success;
}

public OnPluginStart() {

	g_minigunoffsetstate = FindSendPropInfo("CTFMinigun", "m_iWeaponState");

	LoadTranslations("common.phrases");

	for (new client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client)) {
			OnClientPutInServer(client);
			DisableAdvert(client);
		}
	}
	
	hcvar_version = CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Friendly Mode Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);

	hcvar_enabled = CreateConVar("sm_friendly_enabled", "1", "(0/1) Enables/Disables Friendly Mode", FCVAR_PLUGIN|FCVAR_DONTRECORD);

	hcvar_update = CreateConVar("sm_friendly_update", "1", "(0/1/2) Updater compatibility. 0 = disabled, 1 = auto-download, 2 = auto-download and auto-install", FCVAR_PLUGIN);
	hcvar_logging = CreateConVar("sm_friendly_logging", "2", "(0/1/2/3) 0 = No logging, 1 = Log admins targeting others, 2 = (1 + Log players using sm_friendly), 3 = (2 + list all players affected by admin commands).", FCVAR_PLUGIN);
	hcvar_advert = CreateConVar("sm_friendly_advert", "1", "(0/1) If enabled, players will see a message informing them about the plugin when they join the server.", FCVAR_PLUGIN);
	hcvar_maxfriendlies = CreateConVar("sm_friendly_maxfriendlies", "32", "(Any positive integer) This sets a limit how many players can simultaneously be Friendly.", FCVAR_PLUGIN);
	hcvar_delay = CreateConVar("sm_friendly_delay", "5.0", "(Any non-negative value) How long, in seconds, must a player wait after changing modes until he can use sm_friendly again?", FCVAR_PLUGIN);
	hcvar_afklimit = CreateConVar("sm_friendly_afklimit", "300", "(Any non-negative integer) Time in seconds players can be AFK before being moved out of Friendly mode. Set to 0 to disable.", FCVAR_PLUGIN);
	hcvar_afkinterval = CreateConVar("sm_friendly_afkinterval", "1.0", "Time in seconds between AFK checks. This should be a very low value, between 0.1 and 5.0, and should only be as high as 5.0 if you notice that the checks are causing lag.", FCVAR_PLUGIN);

	hcvar_action_h = CreateConVar("sm_friendly_action_h", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Hostile? See this plugin's thread for details.", FCVAR_PLUGIN);
	hcvar_action_f = CreateConVar("sm_friendly_action_f", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Friendly? See this plugin's thread for details.", FCVAR_PLUGIN);
	hcvar_action_h_spawn = CreateConVar("sm_friendly_action_h_spawn", "0", "(Any integer, -2 or greater) Same as sm_friendly_action_h, but applies to players in a spawn room.", FCVAR_PLUGIN);
	hcvar_action_f_spawn = CreateConVar("sm_friendly_action_f_spawn", "0", "(Any integer, -2 or greater) Same as sm_friendly_action_f, but applies to players in a spawn room.", FCVAR_PLUGIN);
	hcvar_remember = CreateConVar("sm_friendly_remember", "0", "(0/1) If enabled, a player who somehow dies while Friendly be Friendly upon respawn.", FCVAR_PLUGIN);
	hcvar_goomba = CreateConVar("sm_friendly_goomba", "1", "(0/1) If enabled, Goomba Stomp will follow the same damage rules of Friendly mode as regular attacks.", FCVAR_PLUGIN);
	hcvar_blockrtd = CreateConVar("sm_friendly_blockrtd", "1", "(0/1) If enabled, Friendly players will be unable to activate Roll The Dice.", FCVAR_PLUGIN);
	hcvar_overlay = CreateConVar("sm_friendly_overlay", "0", "You can set a path to an overlay to display to Friendly players. Set to 0 to disable.", FCVAR_PLUGIN);
	hcvar_thirdperson = CreateConVar("sm_friendly_thirdperson", "0", "(0/1) Set Third-Person view on Friendly players?", FCVAR_PLUGIN);
	//hcvar_botignore = CreateConVar("sm_friendly_botignore", "1", "(0/1) If enabled, friendly players will be invisible to bots.", FCVAR_PLUGIN);
	//hcvar_settransmit = CreateConVar("sm_friendly_settransmit", "0", "(0/1/2) 0 = Disabled, 1 = Friendlies will be invisible to non-Friendlies, 2 = No visibility between Friendlies and non-Friendlies", FCVAR_PLUGIN);
	
	hcvar_stopcap = CreateConVar("sm_friendly_stopcap", "1", "(0/1) If enabled, Friendly players will be unable to cap points or push carts.", FCVAR_PLUGIN);
	hcvar_stopintel = CreateConVar("sm_friendly_stopintel", "1", "(0/1) If enabled, Friendly players will be unable to grab the intel.", FCVAR_PLUGIN);
	hcvar_ammopack = CreateConVar("sm_friendly_ammopack", "1", "(0/1) If enabled, Friendly players will be unable to pick up ammo boxes, dropped weapons, or Sandman balls.", FCVAR_PLUGIN);
	hcvar_healthpack = CreateConVar("sm_friendly_healthpack", "1", "(0/1) If enabled, Friendly players will be unable to pick up health boxes or sandviches.", FCVAR_PLUGIN);
	hcvar_spellbook = CreateConVar("sm_friendly_spellbook", "1", "(0/1) If enabled, Friendly players will be unable to pick up spellbooks.", FCVAR_PLUGIN);
	hcvar_money = CreateConVar("sm_friendly_money", "1", "(0/1) If enabled, Friendly players will be unable to pick up MvM money.", FCVAR_PLUGIN);
	hcvar_pumpkin = CreateConVar("sm_friendly_pumpkin", "1", "(0/1) If enabled, Friendly players will be unable to blow up pumpkins.", FCVAR_PLUGIN);
	hcvar_airblastkill = CreateConVar("sm_friendly_airblastkill", "1", "(0/1) If enabled, Friendly projectiles will vanish upon being airblasted by non-Friendly pyros.", FCVAR_PLUGIN);
	hcvar_funcbutton = CreateConVar("sm_friendly_funcbutton", "0", "(0/1) If enabled, Friendly projectiles will be unable to trigger func_buttons by damaging them.", FCVAR_PLUGIN);
	hcvar_usetele = CreateConVar("sm_friendly_usetele", "3", "(0/1/2/3) who can use what teleporter? See thread for usage.", FCVAR_PLUGIN);

	hcvar_blockweps_classes = CreateConVar("sm_friendly_blockwep_classes", "-1", "What weapon classes to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	hcvar_blockweps_black = CreateConVar("sm_friendly_blockweps", "-1", "What weapon index definiteion numbers to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	hcvar_blockweps_white = CreateConVar("sm_friendly_blockweps_whitelist", "-1", "What weapon index definiteion numbers to whitelist? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	hcvar_blocktaunt = CreateConVar("sm_friendly_blocktaunt", "-1", "What weapon index definition numbers to block taunting with? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);

	hcvar_invuln_p = CreateConVar("sm_friendly_invuln", "2", "(0/1/2/3) 0 = Friendly players have full godmode. 1 = Buddha. 2 = Only invulnerable to other players. 3 = Invuln to other players AND himself.", FCVAR_PLUGIN);
	hcvar_invuln_s = CreateConVar("sm_friendly_invuln_s", "0", "(0/1/2) 0 = Disabled, 1 = Friendly sentries will be invulnerable to other players, 2 = Friendly sentries have full Godmode.", FCVAR_PLUGIN);
	hcvar_invuln_d = CreateConVar("sm_friendly_invuln_d", "0", "(0/1/2) 0 = Disabled, 1 = Friendly dispensers will be invulnerable to other players, 2 = Friendly dispensers have full Godmode.", FCVAR_PLUGIN);
	hcvar_invuln_t = CreateConVar("sm_friendly_invuln_t", "0", "(0/1/2) 0 = Disabled, 1 = Friendly teleporters will be invulnerable to other players, 2 = Friendly teleporters have full Godmode.", FCVAR_PLUGIN);

	hcvar_notarget_p = CreateConVar("sm_friendly_notarget", "1", "(0/1/2/3) If enabled, a Friendly player will be invisible to sentries, immune to airblasts, etc.", FCVAR_PLUGIN);
	hcvar_notarget_s = CreateConVar("sm_friendly_notarget_s", "1", "(0/1) If enabled, a Friendly player's sentry will be invisible to enemy sentries.", FCVAR_PLUGIN);
	hcvar_notarget_d = CreateConVar("sm_friendly_notarget_d", "1", "(0/1) If enabled, a Friendly player's dispenser will be invisible to enemy sentries. Friendly dispensers will have their healing act buggy.", FCVAR_PLUGIN);
	hcvar_notarget_t = CreateConVar("sm_friendly_notarget_t", "1", "(0/1) If enabled, a Friendly player's teleporters will be invisible to enemy sentries.", FCVAR_PLUGIN);

	hcvar_alpha_p = CreateConVar("sm_friendly_alpha", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_w = CreateConVar("sm_friendly_alpha_w", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' cosmetics. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_wep = CreateConVar("sm_friendly_alpha_wep", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' weapons. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_s = CreateConVar("sm_friendly_alpha_s", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly sentries. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_d = CreateConVar("sm_friendly_alpha_d", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly dispensers. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_t = CreateConVar("sm_friendly_alpha_t", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly teleporters. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_proj = CreateConVar("sm_friendly_alpha_proj", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' projectiles. -1 disables this feature.", FCVAR_PLUGIN);

	hcvar_noblock_p = CreateConVar("sm_friendly_noblock", "2", "(0/1/2/3) Sets the collision group of Friendly players, see the forum thread for details.", FCVAR_PLUGIN);
	hcvar_noblock_s = CreateConVar("sm_friendly_noblock_s", "3", "(0/1/2/3) Sets the collision group of Friendly sentries, see the forum thread for details.", FCVAR_PLUGIN);
	hcvar_noblock_d = CreateConVar("sm_friendly_noblock_d", "3", "(0/1/2/3) Sets the collision group of Friendly dispensers, see the forum thread for details.", FCVAR_PLUGIN);
	hcvar_noblock_t = CreateConVar("sm_friendly_noblock_t", "3", "(0/1/2/3) Sets the collision group of Friendly teleporters, see the forum thread for details.", FCVAR_PLUGIN);

	hcvar_killbuild_h_s = CreateConVar("sm_friendly_killsentry", "1", "(0/1) When enabled, a Friendly Engineer's sentry will vanish upon becoming hostile.", FCVAR_PLUGIN);
	hcvar_killbuild_h_d = CreateConVar("sm_friendly_killdispenser", "1", "(0/1) When enabled, a Friendly Engineer's dispenser will vanish upon becoming hostile.", FCVAR_PLUGIN);
	hcvar_killbuild_h_t = CreateConVar("sm_friendly_killtele", "1", "(0/1) When enabled, a Friendly Engineer's teleporters will vanish upon becoming hostile.", FCVAR_PLUGIN);
	hcvar_killbuild_f_s = CreateConVar("sm_friendly_killsentry_f", "1", "(0/1) When enabled, an Engineer's sentry will vanish upon becoming Friendly.", FCVAR_PLUGIN);
	hcvar_killbuild_f_d = CreateConVar("sm_friendly_killdispenser_f", "1", "(0/1) When enabled, an Engineer's dispenser will vanish upon becoming Friendly.", FCVAR_PLUGIN);
	hcvar_killbuild_f_t = CreateConVar("sm_friendly_killtele_f", "1", "(0/1) When enabled, an Engineer's teleporters will vanish upon becoming Friendly.", FCVAR_PLUGIN);
	hcvar_nobuild_s = CreateConVar("sm_friendly_nobuild_s", "0", "(0/1) When enabled, a Friendly engineer will not be able to build sentries.", FCVAR_PLUGIN);
	hcvar_nobuild_d = CreateConVar("sm_friendly_nobuild_d", "1", "(0/1) When enabled, a Friendly engineer will not be able to build dispensers.", FCVAR_PLUGIN);
	hcvar_nobuild_t = CreateConVar("sm_friendly_nobuild_t", "0", "(0/1) a Friendly engineer will not be able to build teleporters.", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_friendly", UseFriendlyCmd, 0, "Toggles Friendly Mode");
	RegAdminCmd("sm_friendly_admin", UseAdminCmd, ADMFLAG_BAN, "Toggles Friendly Admin Mode");
	RegAdminCmd("sm_friendly_a", UseAdminCmd2, 0, _);
	RegAdminCmd("sm_friendly_lock", UseLockCmd, ADMFLAG_BAN, "Blocks a player from using sm_friendly (with no arguments).");
	RegAdminCmd("sm_friendly_l", UseLockCmd2, 0, _);
	RegAdminCmd("sm_friendly_v", smFriendlyVer, 0, "Outputs the current version of Friendly Mode to the chat.");
	RegAdminCmd("sm_friendly_ver", smFriendlyVer2, 0, "Outputs the current version of Friendly Mode to the chat.");

	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("player_builtobject", Object_Built);
	HookEvent("player_sapped_object", Object_Sapped);
	HookEvent("post_inventory_application", Inventory_App);
	HookEvent("object_deflected", Airblast);

	AutoExecConfig(false, "friendly");

	AddNormalSoundHook(Hook_NormalSound);

	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(TauntCmd, "+taunt");

	AddCommandListener(OnClientSpeaks, "say");
	AddCommandListener(OnClientSpeaks, "say_team");
	
	AddMultiTargetFilter("@friendly", TargetFriendlies, "Friendly players", false);
	AddMultiTargetFilter("@friendlies", TargetFriendlies, "Friendly players", false);
	AddMultiTargetFilter("@!friendly", TargetHostiles, "non-Friendly players", false);
	AddMultiTargetFilter("@!friendlies", TargetHostiles, "non-Friendly players", false);
	AddMultiTargetFilter("@friendlyadmins", TargetFriendlyAdmins, "players in Friendly Admin mode", false);
	AddMultiTargetFilter("@!friendlyadmins", TargetFriendlyNonAdmins, "players not in Friendly Admin mode", false);
	AddMultiTargetFilter("@friendlylocked", TargetFriendlyLocked, "Friendly-locked players", false);
	AddMultiTargetFilter("@!friendlylocked", TargetFriendlyUnlocked, "non Friendly-locked players", false);
	
	hfwd_CanToggleFriendly = CreateGlobalForward("TF2Friendly_CanToggleFriendly", ET_Event, Param_Cell);
	hfwd_FriendlyPre = CreateGlobalForward("TF2Friendly_OnEnableFriendly_Pre", ET_Ignore, Param_Cell);
	hfwd_Friendly = CreateGlobalForward("TF2Friendly_OnEnableFriendly", ET_Ignore, Param_Cell);
	hfwd_FriendlyPost = CreateGlobalForward("TF2Friendly_OnEnableFriendly_Post", ET_Ignore, Param_Cell);
	hfwd_HostilePre = CreateGlobalForward("TF2Friendly_OnDisableFriendly_Pre", ET_Ignore, Param_Cell);
	hfwd_Hostile = CreateGlobalForward("TF2Friendly_OnDisableFriendly", ET_Ignore, Param_Cell);
	hfwd_HostilePost = CreateGlobalForward("TF2Friendly_OnDisableFriendly_Post", ET_Ignore, Param_Cell);
	hfwd_RefreshPre = CreateGlobalForward("TF2Friendly_OnRefreshFriendly_Pre", ET_Ignore, Param_Cell);
	hfwd_Refresh = CreateGlobalForward("TF2Friendly_OnRefreshFriendly", ET_Ignore, Param_Cell);
	hfwd_RefreshPost = CreateGlobalForward("TF2Friendly_OnRefreshFriendly_Post", ET_Ignore, Param_Cell);
	hfwd_FriendlySpawn = CreateGlobalForward("TF2Friendly_OnFriendlySpawn", ET_Ignore, Param_Cell);
	hfwd_FriendlyEnable = CreateGlobalForward("TF2Friendly_OnPluginEnabled", ET_Ignore);
	hfwd_FriendlyDisable = CreateGlobalForward("TF2Friendly_OnPluginDisabled", ET_Ignore);
	hfwd_FriendlyLoad = CreateGlobalForward("TF2Friendly_OnPluginLoaded", ET_Ignore);
	hfwd_FriendlyUnload = CreateGlobalForward("TF2Friendly_OnPluginUnloaded", ET_Ignore);

	decl String:file[PLATFORM_MAX_PATH]; file[0] = '\0';
	BuildPath(Path_SM, file, sizeof(file), "gamedata/friendly.txt");
	if (FileExists(file)) {
		new Handle:hConf = LoadGameConfigFile("friendly");
		if (hConf != INVALID_HANDLE) {
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "WeaponReset");
			g_hWeaponReset = EndPrepSDKCall();
			if(g_hWeaponReset == INVALID_HANDLE) {
				LogError("Could not initialize call for CTFWeaponBase::WeaponReset. Plugin will not be able to reset weapons before switching!");
			}
		}
		CloseHandle(hConf);
	}
	else {
		LogError("Could not read gamedata/friendly.txt. Plugin will not be able to reset weapons before switching!");
	}
}

public OnConfigsExecuted() {
	cvarChange(INVALID_HANDLE, "0", "0");

	Call_StartForward(hfwd_FriendlyLoad);
	Call_Finish();
}

public Action:UseFriendlyCmd(client, args) {
	new numargs = GetCmdArgs();
	new target[MAXPLAYERS];
	decl String:target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	new direction = -1;
	new method = 0;
	new numtargets;
	if (client != 0) { DisableAdvert(client); }
	if (!cvar_enabled) {
		CReplyToCommand(client, "%s Friendly Mode is currently disabled.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	if (numargs == 0 || !CheckCommandAccess(client, "sm_friendly_targetothers", ADMFLAG_BAN, true)) {
		UseFriendlyOnSelf(client);
		return Plugin_Handled;
	}
	if (numargs > 3) {
		CReplyToCommand(client, "%s Usage: \"sm_friendly [target] [-1/0/1] [1]\"", CHAT_PREFIX);
		return Plugin_Handled;
	}
	if (numargs >= 1) {
		decl String:arg1[64]; arg1[0] = '\0';
		new bool:tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		decl String:arg2[2]; arg2[0] = '\0';
		GetCmdArg(2, arg2, sizeof(arg2));
		direction = StringToInt(arg2);
		if (!(direction == -1 || direction == 0 || direction == 1)) {
			CReplyToCommand(client, "%s Second argument must be either 0 or 1. 0 to disable Friendly, or 1 to enable.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numargs == 3) {
		decl String:arg3[2]; arg3[0] = '\0';
		GetCmdArg(3, arg3, sizeof(arg3));
		method = StringToInt(arg3);
		if (!(method == 1 || method == 0)) {
			CReplyToCommand(client, "%s Third argument must be either 0 or 1. 0 to toggle Friendly instantly, or 1 to slay the player.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numtargets == 1) {
		new singletarget = target[0];
		if (IsFriendly[singletarget] && direction == 1) {
			CReplyToCommand(client, "%s That player is already Friendly!", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (!IsFriendly[singletarget] && direction == 0) {
			CReplyToCommand(client, "%s That player is already non-Friendly.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	new count;
	if (direction == -1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsFriendly[currenttarget]) {
				MakeClientHostile(currenttarget);
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
				}
				if (method == 1 && !IsAdmin[currenttarget]) {
					KillPlayer(currenttarget);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly mode on \"%L\".", client, currenttarget);
				}
			}
			else {
				MakeClientFriendly(currenttarget);
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Mode.", CHAT_PREFIX);
				}
				if (IsPlayerAlive(currenttarget)) {
					if (method == 1 && !IsAdmin[currenttarget]) {
						KillPlayer(currenttarget);
						if (!cvar_remember) {
							RFETRIZ[currenttarget] = true;
						}
					}
				}
				else {
					if (!cvar_remember) {
						RFETRIZ[currenttarget] = true;
					}
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" enabled Friendly mode on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly mode on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (!IsFriendly[currenttarget]) {
				MakeClientFriendly(currenttarget);
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Mode.", CHAT_PREFIX);
				}
				if (IsPlayerAlive(currenttarget)) {
					if (method == 1 && !IsAdmin[currenttarget]) {
						KillPlayer(currenttarget);
						if (!cvar_remember) {
							RFETRIZ[currenttarget] = true;
						}
					}
				}
				else {
					if (!cvar_remember) {
						RFETRIZ[currenttarget] = true;
					}
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" enabled Friendly mode on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly mode on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsFriendly[currenttarget]) {
				MakeClientHostile(currenttarget);
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
				}
				if (method == 1 && !IsAdmin[currenttarget]) {
					KillPlayer(currenttarget);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly mode on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly mode on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

UseFriendlyOnSelf(const client) {
	if (client == 0) {
		CReplyToCommand(client, "%s Not a valid client. You must be in the game to use sm_friendly.", CHAT_PREFIX);
		return;
	}
	if (IsLocked[client]) {
		CReplyToCommand(client, "%s You are locked out of toggling Friendly mode!", CHAT_PREFIX);
		return;
	}
	if (GetForwardFunctionCount(hfwd_CanToggleFriendly) > 0) {
		Call_StartForward(hfwd_CanToggleFriendly);
		Call_PushCell(client);
		new Action:result = Plugin_Continue;
		Call_Finish(result);
		if (result != Plugin_Continue) {
			return;
		}
	}
	new Float:time = GetEngineTime();
	if (time < ToggleTimer[client]) {
		CReplyToCommand(client, "%s You must wait %d seconds.", CHAT_PREFIX, RoundToCeil(ToggleTimer[client] - time));
		return;
	}		
	if (IsPlayerAlive(client)) {
		if (RequestedChange[client]) {
			RequestedChange[client] = false;
			CReplyToCommand(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
		}
		else {
			new action;
			if (IsFriendly[client]) {
				if (IsInSpawn[client]) {
					action = cvar_action_h_spawn;
				}
				else {
					action = cvar_action_h;
				}
				if (IsAdmin[client]) {
					MakeClientHostile(client);
					CReplyToCommand(client, "%s You are no longer Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
					if (cvar_logging >= 2) {
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
					}
				}
				else if (action == -2) {
					CReplyToCommand(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
				}
				else if (action == -1) {
					CReplyToCommand(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
					FakeClientCommand(client, "voicemenu 0 7"); //"No"
					KillPlayer(client);
				}
				else if (action == 0) {
					MakeClientHostile(client);
					CReplyToCommand(client, "%s You are no longer Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
					if (cvar_logging >= 2) {
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
					}
				}
				else if (action > 0) {
					MakeClientHostile(client);
					SlapPlayer(client, action);
					CReplyToCommand(client, "%s You are no longer Friendly, but took damage because of the switch!", CHAT_PREFIX);
					if (cvar_logging >= 2) {
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
					}
				}
			}
			else {
				if (IsInSpawn[client]) {
					action = cvar_action_f_spawn;
				}
				else {
					action = cvar_action_f;
				}
				if (IsAdmin[client]) {
					MakeClientFriendly(client);
					CReplyToCommand(client, "%s You are now Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
					if (cvar_logging >= 2) {
						LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
					}
				}
				else if (action == -2) {
					CReplyToCommand(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
				}
				else if (action == -1) {
					CReplyToCommand(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
					FakeClientCommand(client, "voicemenu 0 7"); //"No"
					KillPlayer(client);
				}
				else if (action == 0) {
					if (FriendlyPlayerCount < cvar_maxfriendlies) {
						if (cvar_logging >= 2) {
							LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
						}
						MakeClientFriendly(client);
						CReplyToCommand(client, "%s You are now Friendly.", CHAT_PREFIX);
						FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
					}
					else {
						CReplyToCommand(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
					}
				}
				else if (action > 0) {
					if (FriendlyPlayerCount < cvar_maxfriendlies) {
						if (cvar_logging >= 2) {
							LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
						}
						MakeClientFriendly(client);
						CReplyToCommand(client, "%s You were made Friendly, but took damage because of the switch!", CHAT_PREFIX);
						SlapPlayer(client, action);
					}
					else {
						CReplyToCommand(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
					}
				}
			}
		}
	}
	else {
		if (RequestedChange[client]) {
			RequestedChange[client] = false;
			CReplyToCommand(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
			if (IsFriendly[client] && !cvar_remember) {
				RFETRIZ[client] = true;
			}
		}
		else {
			RequestedChange[client] = true;
			CReplyToCommand(client, "%s You will toggle Friendly mode upon respawning.", CHAT_PREFIX);
			RFETRIZ[client] = false;
		}
	}
}

public Action:UseAdminCmd(client, args) {
	new target[MAXPLAYERS];
	decl String:target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	new direction = -1;
	new numtargets;
	if (client != 0) { DisableAdvert(client); }
	if (!cvar_enabled) {
		CReplyToCommand(client, "%s Friendly Mode is currently disabled.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	new numargs = GetCmdArgs();
	if (numargs == 0 || !CheckCommandAccess(client, "sm_friendly_admin_targetothers", ADMFLAG_ROOT, true)) {
		if (client != 0) {
			if (IsAdmin[client]) {
				IsAdmin[client] = false;
				CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Admin mode.");
				if (cvar_logging > 0) {
					LogAction(client, -1, "\"%L\" disabled Friendly Admin mode.", client);
				}
				if (cvar_stopintel && IsFriendly[client]) {
					FakeClientCommand(client, "dropitem");
				}
			}
			else {
				IsAdmin[client] = true;
				CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Admin mode.");
				if (cvar_logging > 0) {
					LogAction(client, -1, "\"%L\" activated Friendly Admin mode.", client);
				}
			}
		}
		else {
			CReplyToCommand(client, "%s Not a valid client.", CHAT_PREFIX);
		}
		return Plugin_Handled;
	}
	if (numargs > 3) {
		CReplyToCommand(client, "%s Usage: \"sm_friendly_admin [target] [-1/0/1]\"", CHAT_PREFIX);
		return Plugin_Handled;
	}
	if (numargs >= 1) {
		decl String:arg1[64]; arg1[0] = '\0';
		new bool:tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		decl String:arg2[2]; arg2[0] = '\0';
		GetCmdArg(2, arg2, sizeof(arg2));
		direction = StringToInt(arg2);
		if (!(direction == -1 || direction == 0 || direction == 1)) {
			CReplyToCommand(client, "%s Second argument must be 0, 1, or -1. 0 to disable Friendly Admin, 1 to enable, -1 to toggle.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numtargets == 1) {
		new singletarget = target[0];
		if (IsAdmin[singletarget] && direction == 1) {
			CReplyToCommand(client, "%s That player is already in Friendly Admin mode!", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (!IsAdmin[singletarget] && direction == 0) {
			CReplyToCommand(client, "%s That player is already not in Friendly Admin mode!.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	new count;
	if (direction == -1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = false;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Admin mode.", CHAT_PREFIX);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Admin mode on \"%L\".", client, currenttarget);
				}
				if (cvar_stopintel && IsFriendly[currenttarget]) {
					FakeClientCommand(currenttarget, "dropitem");
				}
			}
			else {
				IsAdmin[currenttarget] = true;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Admin Mode.", CHAT_PREFIX);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" enabled Friendly Admin mode on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Admin on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Admin mode on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Admin mode on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (!IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = true;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Admin mode.", CHAT_PREFIX);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" enabled Friendly mode on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Admin on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Admin mode on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Admin on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = false;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Admin mode.", CHAT_PREFIX);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Admin mode on \"%L\".", client, currenttarget);
				}
				if (cvar_stopintel && IsFriendly[currenttarget]) {
					FakeClientCommand(currenttarget, "dropitem");
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Admin on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Admin mode on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Admin on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

public Action:UseLockCmd(client, args) {
	new target[MAXPLAYERS];
	decl String:target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	new direction = -1;
	new numtargets;
	if (client != 0) { DisableAdvert(client); }
	if (!cvar_enabled) {
		CReplyToCommand(client, "%s Friendly Mode is currently disabled.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	new numargs = GetCmdArgs();
	if (numargs == 0 || numargs > 2) {
		CReplyToCommand(client, "%s Usage: \"sm_friendly_lock [target] [-1/0/1]\"", CHAT_PREFIX);
		return Plugin_Handled;
	}
	if (numargs >= 1) {
		decl String:arg1[64]; arg1[0] = '\0';
		new bool:tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		decl String:arg2[2]; arg2[0] = '\0';
		GetCmdArg(2, arg2, sizeof(arg2));
		direction = StringToInt(arg2);
		if (!(direction == -1 || direction == 0 || direction == 1)) {
			CReplyToCommand(client, "%s Second argument must be 0, 1, or -1. 0 to disable Friendly Lock, 1 to enable, -1 to toggle.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numtargets == 1) {
		new singletarget = target[0];
		if (IsLocked[singletarget] && direction == 1) {
			CReplyToCommand(client, "%s That player is already Friendly Locked!", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (!IsLocked[singletarget] && direction == 0) {
			CReplyToCommand(client, "%s That player is already not Friendly Locked!.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	new count;
	if (direction == -1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsLocked[currenttarget]) {
				IsLocked[currenttarget] = false;
				count++;
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Lock on \"%L\".", client, currenttarget);
				}
			}
			else {
				IsLocked[currenttarget] = true;
				count++;
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" enabled Friendly Lock on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Lock on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Lock on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Lock on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (!IsLocked[currenttarget]) {
				IsLocked[currenttarget] = true;
				count++;
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" enabled Friendly Lock on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Lock on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Lock on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Lock on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsLocked[currenttarget]) {
				IsLocked[currenttarget] = false;
				count++;
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Lock on \"%L\".", client, currenttarget);
				}
			}
		}
		if (count < 1) {
			CReplyToCommand(client, "%s No players were affected.", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (numtargets > 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Lock on %s, affecting %i players.", target_name, count);
			if (cvar_logging > 0 && cvar_logging < 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Lock on %s.", client, target_name);
			}
			else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Lock on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (cvar_advert) { DoAdvert(client); }
	if (RFETRIZ[client] || (IsLocked[client] && IsFriendly[client])) {
		CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
		RequestedChange[client] = false;
		RFETRIZ[client] = false;
		// Inventory_App should take care of things from here
	}
	else if (RequestedChange[client]) {
		if (IsFriendly[client]) {
			MakeClientHostile(client);
			if (cvar_logging >= 2) {
				LogAction(client, -1, "\"%L\" deactivated Friendly mode on spawn.", client);
			}
			CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
		}
		else {
			if (FriendlyPlayerCount < cvar_maxfriendlies) {
				MakeClientFriendly(client);
				CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
				if (cvar_logging >= 2) {
					LogAction(client, -1, "\"%L\" activated Friendly mode on spawn.", client);
				}
			}
			else {
				CPrintToChat(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
			}
		}
	}
	else {
		if (IsFriendly[client]) {
			if (cvar_remember) {
				CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
				RequestedChange[client] = false;
				// Inventory_App should take care of things from here
			}
			else {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You have been taken out of Friendly mode because you respawned.", CHAT_PREFIX);
				if (cvar_logging >= 2) {
					LogAction(client, -1, "\"%L\" deactivated Friendly mode due to a respawn.", client);
				}
			}
		}
	}
	if (IsFriendly[client] && GetForwardFunctionCount(hfwd_FriendlySpawn) > 0) {
		Call_StartForward(hfwd_FriendlySpawn);
		Call_PushCell(client);
		Call_Finish();
	}
}

public Action:UseAdminCmd2(client, args) {
	if (CheckCommandAccess(client, "sm_friendly_admin", ADMFLAG_BAN)) {
		UseAdminCmd(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:UseLockCmd2(client, args) {
	if (CheckCommandAccess(client, "sm_friendly_lock", ADMFLAG_BAN)) {
		UseLockCmd(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:smFriendlyVer2(client, args) {
	if (CheckCommandAccess(client, "sm_friendly_v", 0)) {
		smFriendlyVer(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action:OnClientCommand(client, args) {
	AfkTime[client] = 0.0;
	return Plugin_Continue;
}

public Action:OnClientSpeaks(client, const String:strCommand[], iArgs) {
	AfkTime[client] = 0.0;
	return Plugin_Continue;
}
	
public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	//SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public OnClientDisconnect_Post(client) {
	if (IsFriendly[client]) {
		FriendlyPlayerCount--;
	}
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	IsAdmin[client] = false;
	IsLocked[client] = false;
	RFETRIZ[client] = false;
	SeenAdvert[client] = 0;
	IsInSpawn[client] = false;
	ToggleTimer[client] = 0.0;
	AfkTime[client] = 0.0;
	p_lastbtnstate[client] = 0;
}

MakeClientHostile(const client) {

	new Float:time = GetEngineTime();
	ToggleTimer[client] = time + cvar_delay;

	if (GetForwardFunctionCount(hfwd_HostilePre) > 0) {
		Call_StartForward(hfwd_HostilePre);
		Call_PushCell(client);
		Call_Finish();
	}

	if (GetForwardFunctionCount(hfwd_Hostile) > 0) {
		Call_StartForward(hfwd_Hostile);
		Call_PushCell(client);
		Call_Finish();
	}
	
	FriendlyPlayerCount--;
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	RFETRIZ[client] = false;
	MakeBuildingsHostile(client);
	DestroyStickies(client);
	if (!StrEqual(cvar_overlay, "0")) {
		SetOverlay(client, false);
	}
	if (cvar_invuln_p < 2) {
		ApplyInvuln(client, INVULNMODE_MORTAL);
	}
	if (cvar_notarget_p > 0) {
		SetNotarget(client, false);
	}
	if (cvar_noblock_p > 0) {
		ApplyNoblock(client, true);
	}
	if (cvar_alpha_p > -1) {
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, _);
	}
	if (cvar_alpha_w > -1) {
		SetWearableInvis(client, false);
	}
	if (cvar_alpha_wep > -1) {
		SetWeaponInvis(client, false);
	}
	if (cvar_thirdperson) {
		SetThirdPerson(client, false);
	}
	/* if (cvar_botignore) {
		SetBotIgnore(client, false);
	} */

	if (GetForwardFunctionCount(hfwd_HostilePost) > 0) {
		Call_StartForward(hfwd_HostilePost);
		Call_PushCell(client);
		Call_Finish();
	}
}

MakeClientFriendly(const client) {

	new Float:time = GetEngineTime();
	ToggleTimer[client] = time + cvar_delay;

	if (GetForwardFunctionCount(hfwd_FriendlyPre) > 0) {
		Call_StartForward(hfwd_FriendlyPre);
		Call_PushCell(client);
		Call_Finish();
	}

	if (GetForwardFunctionCount(hfwd_Friendly) > 0) {
		Call_StartForward(hfwd_Friendly);
		Call_PushCell(client);
		Call_Finish();
	}

	FriendlyPlayerCount++;
	MakeBuildingsFriendly(client);
	ReapplyFriendly(client);
	RemoveMySappers(client);
	MakeStickiesFriendly(client);
	RequestedChange[client] = false;
	RFETRIZ[client] = false;
	ForceWeaponSwitches(client);
	if (cvar_stopintel && !IsAdmin[client]) {
		FakeClientCommand(client, "dropitem");
	}

	if (GetForwardFunctionCount(hfwd_FriendlyPost) > 0) {
		Call_StartForward(hfwd_FriendlyPost);
		Call_PushCell(client);
		Call_Finish();
	}


}

public Inventory_App(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFriendly[client]) {
		ReapplyFriendly(client);
	}
}

ReapplyFriendly(const client) {

	if (GetForwardFunctionCount(hfwd_RefreshPre) > 0) {
		Call_StartForward(hfwd_RefreshPre);
		Call_PushCell(client);
		Call_Finish();
	}

	if (GetForwardFunctionCount(hfwd_Refresh) > 0) {
		Call_StartForward(hfwd_Refresh);
		Call_PushCell(client);
		Call_Finish();
	}

	IsFriendly[client] = true;
	if (!StrEqual(cvar_overlay, "0")) {
		SetOverlay(client, true);
	}
	if (cvar_invuln_p == 0) {
		ApplyInvuln(client, INVULNMODE_GOD);
	}
	if (cvar_invuln_p == 1) {
		ApplyInvuln(client, INVULNMODE_BUDDHA);
	}
	if (cvar_notarget_p > 0) {
		SetNotarget(client, true);
	}
	if (cvar_noblock_p > 0) {
		ApplyNoblock(client, false);
	}
	if (cvar_alpha_p > -1) {
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, _, _, _, cvar_alpha_p);
	}
	if (cvar_alpha_w > -1) {
		SetWearableInvis(client);
	}
	if (cvar_alpha_wep > -1) {
		SetWeaponInvis(client);
	}
	if (cvar_thirdperson) {
		SetThirdPerson(client, true);
	}
	/* if (cvar_botignore) {
		SetBotIgnore(client, true);
	} */

	if (GetForwardFunctionCount(hfwd_RefreshPost) > 0) {
		Call_StartForward(hfwd_RefreshPost);
		Call_PushCell(client);
		Call_Finish();
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (!IsValidClient(attacker) || (client == attacker && cvar_invuln_p != 3)) {
		return Plugin_Continue;
	}
	if ((IsFriendly[attacker] || IsFriendly[client]) && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

ApplyNoblock(entity, bool:remove) {
	new cvarValue;
	new normalValue;
	if (IsValidClient(entity, VCLIENT_VALIDINDEX)) {
		cvarValue = cvar_noblock_p;
		normalValue = 5;
	}
	else {
		decl String:classname[64]; classname[0] = '\0';
		if (!GetEntityClassname(entity, classname, sizeof(classname))) {
			return;
		}
		else if (StrEqual(classname, "obj_sentrygun")) {
			cvarValue = cvar_noblock_s;
			normalValue = 21;
		}
		else if (StrEqual(classname, "obj_dispenser")) {
			cvarValue = cvar_noblock_d;
			normalValue = 21;
		}
		else if (StrEqual(classname, "obj_teleporter")) {
			cvarValue = cvar_noblock_t;
			normalValue = 22;
		}
	}
	if (cvarValue == 0 || remove) {
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", normalValue);
	}
	else if (cvarValue == 1) {
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
	}
	else if (cvarValue == 2) {
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 10);
	}
	else if (cvarValue == 3) {
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
	}
}

ApplyInvuln(entity, f_invulnmode:mode) {
	SetEntProp(entity, Prop_Data, "m_takedamage", mode, 1);
}

SetOverlay(client, bool:apply) {
	if (apply) {
		ClientCommand(client, "r_screenoverlay \"%s\"", cvar_overlay);
	}
	else {
		ClientCommand(client, "r_screenoverlay \"\"");
	}
}

SetNotarget(ent, bool:apply) {
	new flags;
	if (apply) {
		flags = GetEntityFlags(ent)|FL_NOTARGET;
	}
	else {
		flags = GetEntityFlags(ent)&~FL_NOTARGET;
	}
	SetEntityFlags(ent, flags);
}

SetThirdPerson(const client, bool:apply) {
	if (apply) {
		CreateTimer(0.2, TimerThirdPerson, GetClientUserId(client));
	}
	else {
		CreateTimer(0.2, TimerFirstPerson, GetClientUserId(client));
	}
}
public Action:TimerThirdPerson(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (client == 0) {
		return;
	}
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
}
public Action:TimerFirstPerson(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (client == 0) {
		return;
	}
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

/* SetBotIgnore(client, bool:apply) {
	if (apply) {
		TF2_AddCondition(client, TFCond_StealthedUserBuffFade, -1.0);
	}
	else {
		TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade);
	}
}
public TF2_OnConditionRemoved(client, TFCond:condition) {
	if (cvar_botignore && IsFriendly[client] && condition == TFCond_StealthedUserBuffFade) {
		SetBotIgnore(client, true);
	}
} */


public Action:Player_AFKCheck(Handle:htimer) {
	if (cvar_afklimit > 0) {
		for (new client = 1; client <= MaxClients; client++) {
			if (IsValidClient(client, _, true)) {
				if (p_lastbtnstate[client] != GetClientButtons(client)) {
					p_lastbtnstate[client] = GetClientButtons(client);
					AfkTime[client] = 0.0;
					continue;
				}
				if (!IsFriendly[client] || IsLocked[client]) {
					AfkTime[client] = 0.0;
					continue;
				}
				if (cvar_afklimit && (AfkTime[client] += cvar_afkinterval) > cvar_afklimit) {
					AfkTime[client] = 0.0;
					MakeClientHostile(client);
					KillPlayer(client);
					CPrintToChat(client, "%s You have been removed from Friendly mode for being AFK too long.", CHAT_PREFIX);
					if (cvar_logging >= 2) {
						LogAction(-1, -1, "\"%L\" was removed from Friendly Mode for being AFK too long.", client);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

RestartAFKTimer() {
	if (h_timer_afkcheck != INVALID_HANDLE) {
		KillTimer(h_timer_afkcheck);
		h_timer_afkcheck = INVALID_HANDLE;
	}
	for (new client = 1; client <= MaxClients; client++) {
		AfkTime[client] = 0.0;
	}
	h_timer_afkcheck = CreateTimer(cvar_afkinterval, Player_AFKCheck, INVALID_HANDLE, TIMER_REPEAT);
}

DestroyStickies(const client) {
    new sticky = -1;
    while ((sticky = FindEntityByClassname(sticky, "tf_projectile_pipe_remote"))!=INVALID_ENT_REFERENCE) {
        if (!IsValidEntity(sticky)) {
            continue;
        }
        if (GetEntPropEnt(sticky, Prop_Send, "m_hThrower") == client) {
            AcceptEntityInput(sticky, "Kill");
        }
    }
}

MakeStickiesFriendly(const client) {
	new sticky = -1;
	while ((sticky = FindEntityByClassname(sticky, "tf_projectile_pipe_remote"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sticky) && (GetEntPropEnt(sticky, Prop_Send, "m_hThrower") == client)) {
			if (cvar_alpha_proj >= 0 && cvar_alpha_proj <= 255) {	
				SetEntityRenderMode(sticky, RENDER_TRANSALPHA);
				SetEntityRenderColor(sticky, _, _, _, cvar_alpha_proj);
			}
		}
	}
}

KillPlayer(const client) {
	if (IsPlayerAlive(client)) {
		ForcePlayerSuicide(client);
		if (IsPlayerAlive(client)) {
			SlapPlayer(client, 99999, false);
			if (IsPlayerAlive(client)) {
				SDKHooks_TakeDamage(client, client, client, 99999.0);
				if (IsPlayerAlive(client)) {
					CreateTimer(0.1, ForceRespawnImmortalPlayer, GetClientUserId(client));
				}
			}
		}
	}
}
public Action:ForceRespawnImmortalPlayer(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (client == 0) {
		return;
	}
	if (IsPlayerAlive(client)) { TF2_RespawnPlayer(client); }
}

public OnPluginEnd() {
	for (new client = 1; client <= MaxClients; client++) {
		if (IsFriendly[client]) {
			CPrintToChat(client, "%s Plugin has been unloaded or restarted.", CHAT_PREFIX);
			MakeClientHostile(client);
			if (IsAdmin[client]) { continue; }
			new action;
			if (IsInSpawn[client]) {
				action = cvar_action_h_spawn;
			}
			else {
				action = cvar_action_h;
			}
			if (action < 0) {
				KillPlayer(client);
			}
			else if (action > 0) {
				SlapPlayer(client, action);
			}
		}
	}
	RemoveMultiTargetFilter("@friendly", TargetFriendlies);
	RemoveMultiTargetFilter("@friendlies", TargetFriendlies);
	RemoveMultiTargetFilter("@!friendly", TargetHostiles);
	RemoveMultiTargetFilter("@!friendlies", TargetHostiles);
	RemoveMultiTargetFilter("@friendlyadmins", TargetFriendlyAdmins);
	RemoveMultiTargetFilter("@!friendlyadmins", TargetFriendlyNonAdmins);
	RemoveMultiTargetFilter("@friendlylocked", TargetFriendlyLocked);
	RemoveMultiTargetFilter("@!friendlylocked", TargetFriendlyUnlocked);

	if (GetForwardFunctionCount(hfwd_FriendlyUnload) > 0) {
		Call_StartForward(hfwd_FriendlyUnload);
		Call_Finish();
	}
}

public Airblast(Handle:event, const String:name[], bool:dontBroadcast) {
	new pyro = GetClientOfUserId(GetEventInt(event, "userid"));
	new pitcher = GetClientOfUserId(GetEventInt(event, "ownerid"));
	//new weaponid = GetEventInt(event, "weaponid");
	new object = GetEventInt(event, "object_entindex");
	if (!IsValidClient(pyro) || !IsValidClient(pitcher) || !IsValidEntity(object)) {
		return;
	}
	decl String:classname[64]; classname[0] = '\0';
	if (!GetEntityClassname(object, classname, sizeof(classname))) {
		return;
	}
	if (!(StrEqual(classname, "tf_projectile_pipe_remote") || StrEqual(classname, "player"))) {
		if (IsFriendly[pitcher] && !IsFriendly[pyro] && cvar_airblastkill) {
			AcceptEntityInput(object, "Kill");
		}
	}
}

/* public Action:Hook_SetTransmit(entity, client) {
	if (cvar_settransmit == 0 || !IsValidClient(entity) || !IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (cvar_settransmit > 0 && !IsFriendly[client] && IsFriendly[entity]) {
		return Plugin_Handled;
	}
	if (cvar_settransmit == 2 && IsFriendly[client] && !IsFriendly[entity]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
} */

public OnEntityCreated(entity, const String:classname[]) {
	if (cvar_ammopack) {
		if (StrContains(classname, "item_ammopack_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
		}
		if (StrEqual(classname, "tf_ammo_pack", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
			SDKHook(entity, SDKHook_Spawn, OnAmmoPackSpawned);
		}
		if (StrEqual(classname, "tf_projectile_stun_ball", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
		}
	}
	if (cvar_healthpack) {
		if (StrContains(classname, "item_healthkit_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnHealthPackTouch);
			SDKHook(entity, SDKHook_Touch, OnHealthPackTouch);
		}
	}
	if (cvar_money) {
		if (StrContains(classname, "item_currencypack_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnMoneyTouch);
			SDKHook(entity, SDKHook_Touch, OnMoneyTouch);
		}
	}
	if (cvar_spellbook) {
		if (StrContains(classname, "tf_spell_pickup", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnSpellTouch);
			SDKHook(entity, SDKHook_Touch, OnSpellTouch);
		}
	}
	if (cvar_stopcap) {
		if (StrEqual(classname, "trigger_capture_area", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnCPTouch );
			SDKHook(entity, SDKHook_Touch, OnCPTouch );
		}
	}
	if (cvar_stopintel) {
		if (StrEqual(classname, "item_teamflag", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnFlagTouch );
			SDKHook(entity, SDKHook_Touch, OnFlagTouch );
		}
	}
	if (cvar_pumpkin) {
		if (StrEqual(classname, "tf_pumpkin_bomb", false)) {
			SDKHook(entity, SDKHook_OnTakeDamage, PumpkinTakeDamage);
		}
	}
	if (StrEqual(classname, "tf_projectile_pipe_remote", false)) {
		SDKHook(entity, SDKHook_OnTakeDamage, StickyTakeDamage);
	}
	if (cvar_funcbutton) {
		if (StrEqual(classname, "func_button", false)) {
			SDKHook(entity, SDKHook_OnTakeDamage, ButtonTakeDamage);
			SDKHook(entity, SDKHook_Use, ButtonUsed);
		}
	}
	if (StrEqual(classname, "func_respawnroom", false)) {
		SDKHook(entity, SDKHook_Touch, SpawnTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
	}
	if (cvar_notarget_p > 1) {
		if (StrEqual(classname, "func_regenerate", false)) {
			SDKHook(entity, SDKHook_StartTouch, CabinetStartTouch);
			SDKHook(entity, SDKHook_EndTouch, CabinetEndTouch);
			if (cvar_notarget_p == 3) {
				SDKHook(entity, SDKHook_Touch, CabinetTouch);
			}
		}
	}
	/* if (cvar_settransmit > 0) {
		if (StrEqual(classname, "tf_weapon_minigun", false)) {
			new flags = GetEdictFlags(entity)|FL_EDICT_FULLCHECK;
			flags = flags|FL_EDICT_DONTSEND;
			SetEdictFlags(entity, flags);
		}
	} */
	if (cvar_alpha_proj >= 0 && cvar_alpha_proj <= 255) {
		if (StrEqual(classname, "tf_projectile_arrow", false) ||
			StrEqual(classname, "tf_projectile_ball_ornament", false) ||
			//StrEqual(classname, "tf_projectile_energy_ball", false) ||
			//StrEqual(classname, "tf_projectile_energy_ring", false) ||
			StrEqual(classname, "tf_projectile_flare", false) ||
			StrEqual(classname, "tf_projectile_healing_bolt", false) ||
			StrEqual(classname, "tf_projectile_jar", false) ||
			StrEqual(classname, "tf_projectile_jar_milk", false) ||
			StrEqual(classname, "tf_projectile_pipe", false) ||
			StrEqual(classname, "tf_projectile_pipe_remote", false) ||
			StrEqual(classname, "tf_projectile_rocket", false) ||
			//StrEqual(classname, "tf_projectile_sentryrocket", false) ||
			StrEqual(classname, "tf_projectile_stun_ball", false) ||
			//StrEqual(classname, "tf_projectile_syringe", false) ||
			StrEqual(classname, "tf_projectile_cleaver", false)) {
			SDKHook(entity, SDKHook_Spawn, OnProjectileSpawned);
		}
	}
}

public OnProjectileSpawned(projectile) {
	new client = GetEntPropEnt(projectile, Prop_Data, "m_hOwnerEntity");
	if (!IsValidClient(client)) {
		return;
	}
	if (IsFriendly[client]) {
		SetEntityRenderMode(projectile, RENDER_TRANSALPHA);
		SetEntityRenderColor(projectile, _, _, _, cvar_alpha_proj);
	}
}

public OnAmmoPackSpawned(entity) {
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (!IsValidClient(client)) {
		return;
	}
	if (IsFriendly[client] && cvar_ammopack) {
		AcceptEntityInput(entity, "Kill");
	}
}

HookThings() {
	new ent = -1;
	if (cvar_stopcap) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
			SDKHook(ent, SDKHook_StartTouch, OnCPTouch );
			SDKHook(ent, SDKHook_Touch, OnCPTouch );
		}
	}
	if (cvar_stopintel) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
			SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
			SDKHook(ent, SDKHook_Touch, OnFlagTouch );
		}
	}
	if (cvar_pumpkin) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
			SDKHook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
		}
	}
	if (cvar_funcbutton) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "func_button"))!=INVALID_ENT_REFERENCE) {
			SDKHook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
			SDKHook(ent, SDKHook_Use, ButtonUsed);
		}
	}
	if (cvar_healthpack) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_healthkit_full")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
			SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_healthkit_medium")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
			SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_healthkit_small")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
			SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
		}
	}
	if (cvar_ammopack) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_ammopack_medium")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_ammopack_small")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_ammo_pack")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
		}
	}
	if (cvar_money) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
			SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_currencypack_medium")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
			SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_currencypack_small")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
			SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
		}
	}
	if (cvar_spellbook) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_spell_pickup")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, OnSpellTouch);
			SDKHook(ent, SDKHook_Touch, OnSpellTouch);
		}
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1) {
		SDKHook(ent, SDKHook_OnTakeDamage, BuildingTakeDamage);
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1) {
		SDKHook(ent, SDKHook_OnTakeDamage, BuildingTakeDamage);
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1) {
		SDKHook(ent, SDKHook_OnTakeDamage, BuildingTakeDamage);
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1) {
		SDKHook(ent, SDKHook_Touch, SpawnTouch);
		SDKHook(ent, SDKHook_EndTouch, SpawnEndTouch);
	}
	if (cvar_notarget_p > 1) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "func_regenerate")) != -1) {
			SDKHook(ent, SDKHook_StartTouch, CabinetStartTouch);
			SDKHook(ent, SDKHook_EndTouch, CabinetEndTouch);
			if (cvar_notarget_p == 3) {
				SDKHook(ent, SDKHook_Touch, CabinetTouch);
			}
		}
	}
	/* if (cvar_settransmit > 0) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_weapon_minigun")) != -1) {
			new flags = GetEdictFlags(ent)|FL_EDICT_FULLCHECK;
			flags = flags|FL_EDICT_DONTSEND;
			SetEdictFlags(ent, flags);
		}
	} */
}

public Action:CabinetStartTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_notarget_p > 1) {
		SetNotarget(client, false);
	}
	return Plugin_Continue;
}

public Action:CabinetTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_notarget_p == 3) {
		SetNotarget(client, false);
	}
	return Plugin_Continue;
}

public Action:CabinetEndTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_notarget_p > 1) {
		SetNotarget(client, true);
	}
	return Plugin_Continue;
}

public Action:OnCPTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_stopcap && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:TF2_OnPlayerTeleport(client, teleporter, &bool:result) {
	if (cvar_usetele == 0 || !IsValidClient(client)) {
		return Plugin_Continue;
	}
	new engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
	if (engie == client || !IsValidClient(engie)) {
		return Plugin_Continue;
	}
	if (cvar_usetele & 1 && IsFriendly[client] && !IsFriendly[engie]) {
		result = false;
		return Plugin_Handled;
	}
	if (cvar_usetele & 2 && !IsFriendly[client] && IsFriendly[engie]) {
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnFlagTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_stopintel && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnHealthPackTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_healthpack && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnAmmoPackTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_ammopack && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnMoneyTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_money && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnSpellTouch(point, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_spellbook && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:PumpkinTakeDamage(pumpkin, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if (IsFriendly[attacker] && cvar_pumpkin && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:ButtonTakeDamage(button, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if (IsFriendly[attacker] && cvar_funcbutton && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:ButtonUsed(entity, activator, caller, UseType:type, Float:value) {
	if (!IsValidClient(activator)) {
		return Plugin_Continue;
	}
	if (IsFriendly[activator] && cvar_funcbutton && !IsAdmin[activator]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:StickyTakeDamage(sticky, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if ((IsFriendly[attacker]) && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	new demoman = GetEntPropEnt(sticky, Prop_Send, "m_hThrower");
	if (!IsValidClient(demoman)) {
		return Plugin_Continue;
	}
	if (IsFriendly[demoman]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SpawnTouch(spawn, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (GetEntProp(spawn, Prop_Send, "m_iTeamNum") == GetClientTeam(client)) {
		IsInSpawn[client] = true;
	}
	return Plugin_Continue;
}

public Action:SpawnEndTouch(spawn, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	IsInSpawn[client] = false;
	return Plugin_Continue;
}


/* ///////////////////////////////////////////////////////////////////////////////////////
Engie Building shit. Code modified from the following plugins:
forums.alliedmods.net/showthread.php?t=171518
forums.alliedmods.net/showthread.php?p=1553549
*/

public Action:Object_Built(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	new building = GetEventInt(event, "index");
	SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
	if (IsFriendly[client]) {
		new buildtype = GetEventInt(event, "object"); //dispenser 0, tele 1, sentry 2
		if (buildtype == 2) {
			if (cvar_nobuild_s && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build sentries while Friendly!", CHAT_PREFIX);
			}
			else {
				if (cvar_invuln_s == 2) {
					ApplyInvuln(building, INVULNMODE_GOD);
				}
				if (cvar_noblock_s > 0) {
					ApplyNoblock(building, false);
				}
				if (cvar_notarget_s) {
					SetNotarget(building, true);
				}
				if (cvar_alpha_s > -1) {
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, cvar_alpha_s);
				}
			}
		}
		else if (buildtype == 0) {
			if (cvar_nobuild_d && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build dispensers while Friendly!", CHAT_PREFIX);
			}
			else {
				if (cvar_invuln_d == 2) {
					ApplyInvuln(building, INVULNMODE_GOD);
				}
				if (cvar_noblock_d > 0) {
					ApplyNoblock(building, false);
				}
				if (cvar_notarget_d) {
					SetNotarget(building, true);
				}
				if (cvar_alpha_d > -1) {	
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, cvar_alpha_d);
				}
			}
		}
		else if (buildtype == 1) {
			if (cvar_nobuild_t && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build teleporters while Friendly!", CHAT_PREFIX);
			}
			else {
				if (cvar_invuln_t == 2) {
					ApplyInvuln(building, INVULNMODE_GOD);
				}
				if (cvar_noblock_t > 0) {
					ApplyNoblock(building, false);
				}
				if (cvar_notarget_t) {
					SetNotarget(building, true);
				}
				if (cvar_alpha_t > -1) {	
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, cvar_alpha_t);
				}
			}
		}
	}
	return Plugin_Continue;
}

MakeBuildingsFriendly(const client) {
	new sentrygun = -1;
	new dispenser = -1;
	new teleporter = -1;
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sentrygun) && (GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_f_s && !IsAdmin[client]) {
				AcceptEntityInput(sentrygun, "Kill");
			}
			else {
				if (cvar_invuln_s == 1) {
					RemoveActiveSapper(sentrygun, false);
				}
				else if (cvar_invuln_s == 2) {
					ApplyInvuln(sentrygun, INVULNMODE_GOD);
					RemoveActiveSapper(sentrygun, true);
				}
				if (cvar_noblock_s > 0) {
					ApplyNoblock(sentrygun, false);
				}
				if (cvar_notarget_s) {
					SetNotarget(sentrygun, true);
				}
				if (cvar_alpha_s > -1) {	
					SetEntityRenderMode(sentrygun, RENDER_TRANSALPHA);
					SetEntityRenderColor(sentrygun, _, _, _, cvar_alpha_s);
				}
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(dispenser) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_f_d && !IsAdmin[client]) {
				AcceptEntityInput(dispenser, "Kill");
			}
			else {
				if (cvar_invuln_d == 1) {
					RemoveActiveSapper(dispenser, false);
				}
				else if (cvar_invuln_d == 2) {
					ApplyInvuln(dispenser, INVULNMODE_GOD);
					RemoveActiveSapper(dispenser, true);
				}
				if (cvar_noblock_d > 0) {
					ApplyNoblock(dispenser, false);
				}
				if (cvar_notarget_d) {
					SetNotarget(dispenser, true);
				}
				if (cvar_alpha_d > -1) {	
					SetEntityRenderMode(dispenser, RENDER_TRANSALPHA);
					SetEntityRenderColor(dispenser, _, _, _, cvar_alpha_d);
				}
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(teleporter) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_f_t && !IsAdmin[client]) {
				AcceptEntityInput(teleporter, "Kill");
			}
			else {
				if (cvar_invuln_t == 1) {
					RemoveActiveSapper(teleporter, false);
				}
				else if (cvar_invuln_t == 2) {
					ApplyInvuln(teleporter, INVULNMODE_GOD);
					RemoveActiveSapper(teleporter, true);
				}
				if (cvar_noblock_t > 0) {
					ApplyNoblock(teleporter, false);
				}
				if (cvar_notarget_t) {
					SetNotarget(teleporter, true);
				}
				if (cvar_alpha_t > -1) {	
					SetEntityRenderMode(teleporter, RENDER_TRANSALPHA);
					SetEntityRenderColor(teleporter, _, _, _, cvar_alpha_t);
				}
			}
		}
	}
}


MakeBuildingsHostile(const client) {
	new sentrygun = -1;
	new dispenser = -1;
	new teleporter = -1;
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sentrygun) && (GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_h_s && !IsAdmin[client]) {
				AcceptEntityInput(sentrygun, "Kill");
			}
			else {
				if (cvar_invuln_s == 2) {
					ApplyInvuln(sentrygun, INVULNMODE_MORTAL);
				}
				if (cvar_noblock_s > 0) {
					ApplyNoblock(sentrygun, true);
				}
				if (cvar_notarget_s) {
					SetNotarget(sentrygun, false);
				}
				if (cvar_alpha_s != -1) {	
					SetEntityRenderMode(sentrygun, RENDER_NORMAL);
					SetEntityRenderColor(sentrygun, _, _, _, _);
				}
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(dispenser) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_h_d && !IsAdmin[client]) {
				AcceptEntityInput(dispenser, "Kill");
			}
			else {
				if (cvar_invuln_d == 2) {
					ApplyInvuln(dispenser, INVULNMODE_MORTAL);
				}
				if (cvar_noblock_d > 0) {
					ApplyNoblock(dispenser, true);
				}
				if (cvar_notarget_d) {
					SetNotarget(dispenser, false);
				}
				if (cvar_alpha_d != -1) {	
					SetEntityRenderMode(dispenser, RENDER_NORMAL);
					SetEntityRenderColor(dispenser, _, _, _, _);
				}
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(teleporter) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_h_t && !IsAdmin[client]) {
				AcceptEntityInput(teleporter, "Kill");
			}
			else {
				if (cvar_invuln_t == 2) {
					ApplyInvuln(teleporter, INVULNMODE_MORTAL);
				}
				if (cvar_noblock_t > 0) {
					ApplyNoblock(teleporter, true);
				}
				if (cvar_notarget_t) {
					SetNotarget(teleporter, false);
				}
				if (cvar_alpha_t != -1) {	
					SetEntityRenderMode(teleporter, RENDER_NORMAL);
					SetEntityRenderColor(teleporter, _, _, _, _);
				}
			}
		}
	}
}

public Action:BuildingTakeDamage(building, &attacker, &inflictor, &Float:damage, &damagetype) {
	new engie = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	decl String:classname[64]; classname[0] = '\0';
	if (!GetEntityClassname(building, classname, sizeof(classname))) {
		return Plugin_Continue;
	}
	if (!IsValidClient(attacker) || !IsValidClient(engie)) {
		return Plugin_Continue;
	}
	if (!IsAdmin[attacker]) {
		if (StrEqual(classname, "obj_sentrygun", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_s > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		else if (StrEqual(classname, "obj_dispenser", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_d > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		else if (StrEqual(classname, "obj_teleporter", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_t > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Object_Sapped(Handle:event, const String:name[], bool:dontBroadcast) {
	new spy = GetClientOfUserId(GetEventInt(event, "userid"));
	new sapper = GetEventInt(event, "sapperid");
	if (IsFriendly[spy] && !IsAdmin[spy]) {
		AcceptEntityInput(sapper, "Kill");
		return Plugin_Continue;
	}
	new engie = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new building = GetEventInt(event, "object"); //dispenser 0, tele 1, sentry 2
	if (IsFriendly[engie]) {
		if (building == 0) {
			if (cvar_invuln_d == 2 || (cvar_invuln_d == 1 && !IsAdmin[spy])) {
				AcceptEntityInput(sapper, "Kill");
			}
			else if (cvar_invuln_d == 0 || (cvar_invuln_d == 1 && IsAdmin[spy])) {
				SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
			}
		}
		else if (building == 1) {
			if (cvar_invuln_t == 2 || (cvar_invuln_t == 1 && !IsAdmin[spy])) {
				AcceptEntityInput(sapper, "Kill");
			}
			else if (cvar_invuln_t == 0 || (cvar_invuln_t == 1 && IsAdmin[spy])) {
				SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
			}
		}
		else if (building == 2) {
			if (cvar_invuln_s == 2 || (cvar_invuln_s == 1 && !IsAdmin[spy])) {
				AcceptEntityInput(sapper, "Kill");
			}
			else if (cvar_invuln_s == 0 || (cvar_invuln_s == 1 && IsAdmin[spy])) {
				SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
			}
		}
	}
	else {
		SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
	}
	return Plugin_Continue;
}

public Action:SapperTakeDamage(sapper, &attacker, &inflictor, &Float:damage, &damagetype) {
	new homewrecker = attacker;
	new building = GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity");
	new engie = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if (!IsAdmin[homewrecker] && IsFriendly[homewrecker] && !IsFriendly[engie]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public RemoveActiveSapper(building, bool:ignoreadmin) {
	new sapper = -1;
	while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sapper) && (GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity") == building)) {
			new spy = GetEntPropEnt(sapper, Prop_Send, "m_hBuilder");
			if (ignoreadmin || !IsAdmin[spy]) {
				AcceptEntityInput(sapper, "Kill");
			}
		}
	}	
}

public RemoveMySappers(client) {
	if (!IsAdmin[client]) {
		new sapper = -1;
		while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(sapper) && GetEntPropEnt(sapper, Prop_Send, "m_hBuilder") == client) {
				AcceptEntityInput(sapper, "Kill");
			}
		}
	}
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {
	if (StrEqual(sample, "weapons/sapper_timer.wav", false)
	|| (StrContains(sample, "spy_tape_01.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_02.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_03.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_04.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_05.wav", false) != -1)) {
		if (!IsValidEntity(GetEntPropEnt(entity, Prop_Send, "m_hBuiltOnEntity"))) {
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
The following code was borrowed from FlaminSarge's Ghost Mode plugin: forums.alliedmods.net/showthread.php?t=183266
This code makes wearables change alpha if sm_friendly_alpha_w is higher than -1 */

stock SetWearableInvis(client, bool:set = true) {
	new alpha = cvar_alpha_w;
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1) {
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
	i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable_demoshield")) != -1) {
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
	while ((i = FindEntityByClassname(i, "tf_powerup_bottle")) != -1) {
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
}


stock SetWeaponInvis(client, bool:set = true) {
	new alpha = cvar_alpha_wep;
	for (new i = 0; i < 5; i++) {
		new entity = GetPlayerWeaponSlot(client, i);
		if (entity != -1) {
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, _, _, _, set ? alpha : 255);
		}
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Updater code begins here, code shamelessly borrowed and modified from Dr. McKay's "Automatic Steam Update" plugin. */

public OnAllPluginsLoaded() {
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
	else {
		decl String:prefix[] = CHAT_PREFIX_NOCOLOR;
		decl String:part1[] = "Please consider installing Updater!";
		decl String:part2[] = "It will help you automatically keep your plugins up to date!";
		decl String:part3[] = "Please go to:";
		decl String:url[] = "https://forums.alliedmods.net/showthread.php?t=169095";
		PrintToServer("%s %s %s %s %s", prefix, part1, part2, part3, url);
	}
}

public Action:Updater_OnPluginDownloading() {
	if (cvar_update > 0) {
		return Plugin_Continue;
	}
	else {
		PrintToServer("%s An update to Friendly Mode is available! Please see the forum thread for more info.", CHAT_PREFIX_NOCOLOR);
		return Plugin_Handled;
	}
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Updater_OnPluginUpdated() {
	if (cvar_update == 2) {
		ReloadPlugin();
	}
	else {
		PrintToServer("%s An update has been downloaded, and will be installed on the next map change.", CHAT_PREFIX_NOCOLOR);
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Goomba Stomp Integration */

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower) {
	if ((IsFriendly[attacker] || IsFriendly[victim]) && !IsAdmin[attacker] && cvar_goomba) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
RTD Integration */

public Action:RTD_CanRollDice(client) {
	if (IsFriendly[client] && !IsAdmin[client] && cvar_blockrtd) {
		CPrintToChat(client, "%s You cannot RTD while Friendly!", CHAT_PREFIX);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Advert/sm_friendly_v Code */

DoAdvert(const client) {
	if (SeenAdvert[client] < 4) {
		SeenAdvert[client]++;
	}
	if (SeenAdvert[client] == 4) {
		SeenAdvert[client]++;
		if (cvar_enabled && CheckCommandAccess(client, "sm_friendly", 0)) {
			CPrintToChat(client, "%s This server is currently running %s v.{lightgreen}%s{default}. Type {olive}/friendly{default} to use.", CHAT_PREFIX, CHAT_NAME, PLUGIN_VERSION);
		}
	}
}

public Action:smFriendlyVer(client, args) {
	if (client != 0) {
		DisableAdvert(client);
	}
	if (CheckCommandAccess(client, "sm_friendly", 0) && cvar_enabled) {
		CReplyToCommand(client, "%s This server is currently running %s v.{lightgreen}%s{default} by Derek (ddhoward). Type {olive}/friendly{default} to use. There are currently {lightgreen}%i{default} players in Friendly mode.", CHAT_PREFIX, CHAT_NAME, PLUGIN_VERSION, FriendlyPlayerCount);
	}
	else {
		CReplyToCommand(client, "%s This server is currently running %s v.{lightgreen}%s{default}.", CHAT_PREFIX, CHAT_NAME, PLUGIN_VERSION);
	}
	return Plugin_Handled;
}

DisableAdvert(const client) {
	SeenAdvert[client] = 5;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Begin code relevant to weaponblocker and tauntblocker */

public Action:OnWeaponSwitch(client, weapon) {
	if (!IsFriendly[client] || IsAdmin[client] || !IsValidEdict(weapon)) {
		return Plugin_Continue;
	}
	if (IsWeaponBlocked(weapon)) {
		return Plugin_Handled;
	}
	else {
		return Plugin_Continue;
	}
}

stock bool:IsWeaponBlocked(weapon) {
	decl String:weaponClass[64]; weaponClass[0] = '\0';
	if (!GetEntityClassname(weapon, weaponClass, sizeof(weaponClass))) {
		return false;
	}
	new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	new bool:blocked = false;
	for (new i = 0; i < sizeof(cvar_blockweps_classes) && !blocked && !StrEqual(cvar_blockweps_classes[i], "-1"); i++) {
		if (StrEqual(cvar_blockweps_classes[i], weaponClass)) {
			blocked = true;
		}
	}
	if (blocked) {
		for (new i = 0; i < sizeof(cvar_blockweps_white) && cvar_blockweps_white[i] != -1; i++) {
			if (cvar_blockweps_white[i] == weaponIndex) {
				return false;
			}
		}
		return true;
	}
	else {
		for (new i = 0; i < sizeof(cvar_blockweps_black) && cvar_blockweps_black[i] != -1; i++) {
			if (cvar_blockweps_black[i] == weaponIndex) {
				return true;
			}
		}
		return false;
	}
}

public Action:TauntCmd(client, const String:strCommand[], iArgs) {
	if (IsFriendly[client] && !IsAdmin[client]) {
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(weapon)) {
			new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			for (new i = 0; i < sizeof(cvar_blocktaunt) && cvar_blocktaunt[i] != -1; i++) {
				if (cvar_blocktaunt[i] == weaponIndex) {
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}


ForceWeaponSwitches(const client) {
	if (!IsPlayerAlive(client) || IsAdmin[client]) {
		return;
	}
	new curwep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(curwep) || !IsWeaponBlocked(curwep)) {
		return;
	}
	
	if (g_minigunoffsetstate > 0) {
		decl String:curwepclass[32]; curwepclass[0] = '\0';
		GetEntityClassname(curwep, curwepclass, sizeof(curwepclass));
		if (StrEqual(curwepclass, "tf_weapon_minigun")) {
			SetEntData(curwep, g_minigunoffsetstate, 0);
			if (TF2_IsPlayerInCondition(client, TFCond_Slowed)) {
				TF2_RemoveCondition(client, TFCond_Slowed);
			}
		}
	}
	
	for (new i = 0; i <= 5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);
		if (!IsValidEdict(weapon)) {
			continue;
		}
		if (curwep == weapon) {
			continue;
		}
		if (IsWeaponBlocked(weapon)) {
			continue;
		}
		decl String:classname[64]; classname[0] = '\0';
		if (GetEntityClassname(weapon, classname, sizeof(classname))) {
			if (StrEqual(classname, "tf_weapon_invis") 
			||  StrEqual(classname, "tf_weapon_builder")) {
				continue;
			}
			else {
				if (g_hWeaponReset != INVALID_HANDLE) {
					SDKCall(g_hWeaponReset, curwep);
				}
				SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
				ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
				return;
			}
		}
	}
	for (new i = 0; i <= 5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);
		if (!IsValidEdict(weapon)) {
			continue;
		}
		if (IsWeaponBlocked(weapon)) {
			TF2_RemoveWeaponSlot(client, i);
		}
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Targeting Filters */

public bool:TargetFriendlies(const String:pattern[], Handle:clients) {
	for (new client = 1; client <= MaxClients; client++) {
		if (IsFriendly[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool:TargetHostiles(const String:pattern[], Handle:clients) {
	for (new client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && !IsFriendly[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool:TargetFriendlyAdmins(const String:pattern[], Handle:clients) {
	for (new client = 1; client <= MaxClients; client++) {
		if (IsAdmin[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool:TargetFriendlyNonAdmins(const String:pattern[], Handle:clients) {
	for (new client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && !IsAdmin[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool:TargetFriendlyLocked(const String:pattern[], Handle:clients) {
	for (new client = 1; client <= MaxClients; client++) {
		if (IsLocked[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool:TargetFriendlyUnlocked(const String:pattern[], Handle:clients) {
	for (new client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && !IsLocked[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Natives */

public Native_CheckIfFriendly(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return false;
	}
	if (!IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return false;
	}
	if (IsFriendly[client]) {
		return true;
	}
	else {
		return false;
	}
}

public Native_CheckIfFriendlyLocked(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return false;
	}
	if (!IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return false;
	}
	if (IsLocked[client]) {
		return true;
	}
	else {
		return false;
	}
}

public Native_CheckIfFriendlyAdmin(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return false;
	}
	if (!IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return false;
	}
	if (IsAdmin[client]) {
		return true;
	}
	else {
		return false;
	}
}

public Native_SetFriendly(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new direction = GetNativeCell(2);
	new action = GetNativeCell(3);
	
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return -3;
	}
	if (!IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return -2;
	}
	if ((IsFriendly[client] && direction > 0) || (!IsFriendly[client] && direction == 0)) {
		return -1;
		//Client is already in the requested Friendly state
	}
	if (IsFriendly[client] && (direction <= 0)) {
		MakeClientHostile(client);
		if (action < 0 && IsPlayerAlive(client)) {
			KillPlayer(client);
		}
		else if (action > 0 && IsPlayerAlive(client)) {
			SlapPlayer(client, action);
			if (!IsPlayerAlive(client)) {
				return 2;
			}
		}
		return 0;
	}
	if (!IsFriendly[client] && (direction != 0)) {
		MakeClientFriendly(client);
		if (action < 0 && IsPlayerAlive(client)) {
			KillPlayer(client);
			if (!cvar_remember) {
				RFETRIZ[client] = true;
			}
		}
		else if (action > 0 && IsPlayerAlive(client)) {
			SlapPlayer(client, action);
			if (!IsPlayerAlive(client)) {
				if (!cvar_remember) {
					RFETRIZ[client] = true;
				}
				return 3;
			}
			
		}
		return 1;
	}
	return -4;
}

public Native_SetFriendlyLock(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new direction = GetNativeCell(2);
	
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return -3;
	}
	if (!IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return -2;
	}
	if ((IsLocked[client] && direction > 0) || (!IsLocked[client] && direction == 0)) {
		return -1;
		//Client is already in the requested Friendly state
	}
	if (IsLocked[client] && (direction <= 0)) {
		IsLocked[client] = false;
		return 0;
	}
	if (!IsLocked[client] && (direction != 0)) {
		IsLocked[client] = true;
		return 1;
	}
	return -4;
}

public Native_SetFriendlyAdmin(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new direction = GetNativeCell(2);
	
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return -3;
	}
	if (!IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return -2;
	}
	if ((IsAdmin[client] && direction > 0) || (!IsAdmin[client] && direction == 0)) {
		return -1;
		//Client is already in the requested Friendly state
	}
	if (IsAdmin[client] && (direction <= 0)) {
		IsAdmin[client] = false;
		return 0;
	}
	if (!IsAdmin[client] && (direction != 0)) {
		IsAdmin[client] = true;
		return 1;
	}
	return -4;
}

public Native_RefreshFriendly(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return -3;
	}
	if (!IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return -2;
	}
	if (!IsFriendly[client]) {
		ThrowNativeError(SP_ERROR_PARAM, "Cannot refresh Friendly Mode! Client %N is not Friendly!", client);
		return -1;
	}
	ReapplyFriendly(client);
	return 1;
}

public Native_CheckPluginEnabled(Handle:plugin, numParams) {
	return cvar_enabled;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Begin code relevant to caching convars */

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	if (hHandle == hcvar_version || hHandle == INVALID_HANDLE) {
		SetConVarString(hcvar_version, PLUGIN_VERSION);
	}
	if (hHandle == hcvar_enabled || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_enabled;
		cvar_enabled = GetConVarBool(hcvar_enabled);
		if (hHandle != INVALID_HANDLE) {
			if (cvar_enabled && !oldValue) {
				if (GetForwardFunctionCount(hfwd_FriendlyEnable) > 0) {
					Call_StartForward(hfwd_FriendlyEnable);
					Call_Finish();
				}
				if (cvar_logging > 0) {
					LogAction(-1, -1, "Friendly mode plugin was enabled.");
				}
				CPrintToChatAll("%s An admin has re-enabled Friendly Mode. Type {olive}/friendly{default} to use.", CHAT_PREFIX);
			}
			else if (!cvar_enabled && oldValue) {
				if (cvar_logging > 0) {
					LogAction(-1, -1, "Friendly mode plugin was disabled. All players forced out of Friendly mode.");
				}
				CPrintToChatAll("%s An admin has disabled Friendly Mode.", CHAT_PREFIX);
				for (new client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						MakeClientHostile(client);
						if (!IsAdmin[client]) {
							new action;
							if (IsInSpawn[client]) {
								action = cvar_action_h_spawn;
							}
							else {
								action = cvar_action_h;
							}
							if (action < 0) {
								KillPlayer(client);
							} if (action > 0) {
								SlapPlayer(client, action);
							}
						}
					}
				}
				if (GetForwardFunctionCount(hfwd_FriendlyDisable) > 0) {
					Call_StartForward(hfwd_FriendlyDisable);
					Call_Finish();
				}
			}
		}
	}
	if (hHandle == hcvar_logging || hHandle == INVALID_HANDLE) {
		cvar_logging = GetConVarInt(hcvar_logging);
		if (cvar_logging < 0) {
			cvar_logging = 0;
			LogError("Value of sm_friendly_logging is less than 0. Plugin will behave as if value was 0.");
		}
		else if (cvar_logging > 3) {
			cvar_logging = 3;
			LogError("Value of sm_friendly_logging is greater than 3. Plugin will behave as if value was 3.");
		}
	}
	if (hHandle == hcvar_advert || hHandle == INVALID_HANDLE) {
		cvar_advert = GetConVarBool(hcvar_advert);
	}
	if (hHandle == hcvar_update || hHandle == INVALID_HANDLE) {
		cvar_update = GetConVarInt(hcvar_update);
		if (cvar_update < 0 || cvar_update > 2) {
			cvar_update = 1;
			LogError("Value of sm_friendly_update is invalid. Plugin will behave as if value was 1.");
		}
	}
	if (hHandle == hcvar_maxfriendlies || hHandle == INVALID_HANDLE) {
		cvar_maxfriendlies = GetConVarInt(hcvar_maxfriendlies);
		if (cvar_maxfriendlies < 0) {
			cvar_maxfriendlies = 0;
			LogError("Value of sm_friendly_maxfriendlies is invalid. Plugin will behave as if value was 0. This disables Friendly mode except to admins!");
		}
	}
	if (hHandle == hcvar_delay || hHandle == INVALID_HANDLE) {
		cvar_delay = GetConVarFloat(hcvar_delay);
		if (cvar_delay < 0.0) {
			cvar_delay = 0.0;
			LogError("Value of sm_friendly_delay is invalid. Plugin will behave as if value was 0.0.");
		}
	}
	if (hHandle == hcvar_afklimit || hHandle == INVALID_HANDLE) {
		cvar_afklimit = GetConVarInt(hcvar_afklimit);
		if (cvar_afklimit < 0) {
			cvar_afklimit = 0;
			LogError("Value of sm_friendly_afklimit is invalid. Plugin will behave as if value was 0. This disables the AFK scanner!");
		}
		if (hHandle != INVALID_HANDLE) {
			RestartAFKTimer();
		}
	}
	if (hHandle == hcvar_afkinterval || hHandle == INVALID_HANDLE) {
		cvar_afkinterval = GetConVarFloat(hcvar_afkinterval);
		if (cvar_afkinterval < 0.1) {
			cvar_afkinterval = 1.0;
			LogError("Value of sm_friendly_afkinterval is invalid. Plugin will behave as if value was 1.0.");
		}
		if (hHandle != INVALID_HANDLE) {
			RestartAFKTimer();
		}
	}
	if (hHandle == hcvar_action_h || hHandle == INVALID_HANDLE) {
		cvar_action_h = GetConVarInt(hcvar_action_h);
		if (cvar_action_h < -2) {
			cvar_action_h = -2;
			LogError("Value of sm_friendly_action_h is invalid. Plugin will behave as if value was -2.");
		}
	}
	if (hHandle == hcvar_action_f || hHandle == INVALID_HANDLE) {
		cvar_action_f = GetConVarInt(hcvar_action_f);
		if (cvar_action_f < -2) {
			cvar_action_f = -2;
			LogError("Value of sm_friendly_action_f is invalid. Plugin will behave as if value was -2.");
		}
	}
	if (hHandle == hcvar_action_h_spawn || hHandle == INVALID_HANDLE) {
		cvar_action_h_spawn = GetConVarInt(hcvar_action_h_spawn);
		if (cvar_action_h_spawn < -2) {
			cvar_action_h_spawn = 0;
			LogError("Value of sm_friendly_action_h_spawn is invalid. Plugin will behave as if value was -2.");
		}
	}
	if (hHandle == hcvar_action_f_spawn || hHandle == INVALID_HANDLE) {
		cvar_action_f_spawn = GetConVarInt(hcvar_action_f_spawn);
		if (cvar_action_f_spawn < -2) {
			cvar_action_f_spawn = 0;
			LogError("Value of sm_friendly_action_f_spawn is invalid. Plugin will behave as if value was -2.");
		}
	}
	if (hHandle == hcvar_remember || hHandle == INVALID_HANDLE) {
		cvar_remember = GetConVarBool(hcvar_remember);
	}
	if (hHandle == hcvar_goomba || hHandle == INVALID_HANDLE) {
		cvar_goomba = GetConVarBool(hcvar_goomba);
	}
	if (hHandle == hcvar_blockrtd || hHandle == INVALID_HANDLE) {
		cvar_blockrtd = GetConVarBool(hcvar_blockrtd);
	}
	/* if (hHandle == hcvar_botignore || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_botignore;
		cvar_botignore = GetConVarBool(hcvar_botignore);
		if (hHandle != INVALID_HANDLE) {
			if (cvar_botignore && !oldValue) {
				for (new client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						SetBotIgnore(client, true);
					}
				}
			}
			else if (!cvar_botignore && oldValue) {
				for (new client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						SetBotIgnore(client, false);
					}
				}
			}
		}
	} */
	if (hHandle == hcvar_thirdperson || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_thirdperson;
		cvar_thirdperson = GetConVarBool(hcvar_thirdperson);
		if (hHandle != INVALID_HANDLE) {
			if (cvar_thirdperson && !oldValue) {
				for (new client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						SetThirdPerson(client, true);
					}
				}
			}
			else if (!cvar_thirdperson && oldValue) {
				for (new client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						SetThirdPerson(client, false);
					}
				}
			}
		}
	}
	/* if (hHandle == hcvar_settransmit || hHandle == INVALID_HANDLE) {
		cvar_settransmit = GetConVarInt(hcvar_settransmit);
		if (cvar_settransmit < 0 || cvar_settransmit > 2) {
			cvar_settransmit = 0;
			LogError("Value of sm_friendly_settransmit is invalid. Plugin will behave as if value was 0.");
		}
	} */
	if (hHandle == hcvar_stopcap || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_stopcap;
		cvar_stopcap = GetConVarBool(hcvar_stopcap);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_stopcap && !oldValue) {
				while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_StartTouch, OnCPTouch);
					SDKHook(ent, SDKHook_Touch, OnCPTouch);
				}
			}
			else if (!cvar_stopcap && oldValue) {
				while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_StartTouch, OnCPTouch);
					SDKUnhook(ent, SDKHook_Touch, OnCPTouch);
				}
			}
		}
	}
	if (hHandle == hcvar_stopintel || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_stopintel;
		cvar_stopintel = GetConVarBool(hcvar_stopintel);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_stopintel && !oldValue) {
				while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
					SDKHook(ent, SDKHook_Touch, OnFlagTouch );
				}
			}
			else if (!cvar_stopintel && oldValue) {
				while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_StartTouch, OnFlagTouch );
					SDKUnhook(ent, SDKHook_Touch, OnFlagTouch );
				}
			}
		}
	}
	if (hHandle == hcvar_ammopack || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_ammopack;
		cvar_ammopack = GetConVarBool(hcvar_ammopack);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_ammopack && !oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_medium")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_small")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_ammo_pack")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_stun_ball")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
			}
			else if (!cvar_ammopack && oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_medium")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_small")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_ammo_pack")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_stun_ball")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
			}
		}
	}
	if (hHandle == hcvar_healthpack || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_healthpack;
		cvar_healthpack = GetConVarBool(hcvar_healthpack);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_healthpack && !oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_healthkit_full")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
					SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_healthkit_medium")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
					SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_healthkit_small")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
					SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
				}
			}
			else if (!cvar_healthpack && oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_healthkit_full")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnHealthPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnHealthPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_healthkit_medium")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnHealthPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnHealthPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_healthkit_small")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnHealthPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnHealthPackTouch);
				}
			}
		}
	}
	if (hHandle == hcvar_money || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_money;
		cvar_money = GetConVarBool(hcvar_money);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_money && !oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
					SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_medium")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
					SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_small")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
					SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
				}
			}
			else if (!cvar_money && oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnMoneyTouch);
					SDKUnhook(ent, SDKHook_Touch, OnMoneyTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_medium")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnMoneyTouch);
					SDKUnhook(ent, SDKHook_Touch, OnMoneyTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_small")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnMoneyTouch);
					SDKUnhook(ent, SDKHook_Touch, OnMoneyTouch);
				}
			}
		}
	}
	if (hHandle == hcvar_spellbook || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_spellbook;
		cvar_spellbook = GetConVarBool(hcvar_spellbook);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_spellbook && !oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnSpellTouch);
					SDKHook(ent, SDKHook_Touch, OnSpellTouch);
				}
			}
			else if (!cvar_spellbook && oldValue) {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnSpellTouch);
					SDKUnhook(ent, SDKHook_Touch, OnSpellTouch);
				}
			}
		}
	}
	if (hHandle == hcvar_usetele || hHandle == INVALID_HANDLE) {
		cvar_usetele = GetConVarInt(hcvar_usetele);
		if (cvar_usetele < 0 || cvar_usetele > 3) {
			cvar_usetele = 3;
			LogError("Value of sm_friendly_usetele is invalid. Plugin will behave as if value was 3.");
		}
	}
	if (hHandle == hcvar_pumpkin || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_pumpkin;
		cvar_pumpkin = GetConVarBool(hcvar_pumpkin);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_pumpkin && !oldValue) {
				while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
				}
			}
			else if (!cvar_pumpkin && oldValue) {
				while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
				}
			}
		}
	}
	if (hHandle == hcvar_airblastkill || hHandle == INVALID_HANDLE) {
		cvar_airblastkill = GetConVarBool(hcvar_airblastkill);
	}
	if (hHandle == hcvar_funcbutton || hHandle == INVALID_HANDLE) {
		new bool:oldValue = cvar_funcbutton;
		cvar_funcbutton = GetConVarBool(hcvar_funcbutton);
		if (hHandle != INVALID_HANDLE) {
			new ent = -1;
			if (cvar_funcbutton && !oldValue) {
				while ((ent = FindEntityByClassname(ent, "func_button"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
					SDKHook(ent, SDKHook_Use, ButtonUsed);
				}
			}
			else if (!cvar_funcbutton && oldValue) {
				while ((ent = FindEntityByClassname(ent, "func_button"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
					SDKUnhook(ent, SDKHook_Use, ButtonUsed);
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_p || hHandle == INVALID_HANDLE) {
		cvar_invuln_p = GetConVarInt(hcvar_invuln_p);
		if (cvar_invuln_p > 3 || cvar_invuln_p < 0) {
			cvar_invuln_p = 2;
			LogError("Value of sm_friendly_invuln is invalid. Plugin will behave as if value was 2.");
		}
		if (hHandle != INVALID_HANDLE) {
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFriendly[client]) {
					if (cvar_invuln_p == 0) {
						ApplyInvuln(client, INVULNMODE_GOD);
					}
					else if (cvar_invuln_p == 1) {
						ApplyInvuln(client, INVULNMODE_BUDDHA);
					}
					else {
						ApplyInvuln(client, INVULNMODE_MORTAL);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_s || hHandle == INVALID_HANDLE) {
		cvar_invuln_s = GetConVarInt(hcvar_invuln_s);
		if (cvar_invuln_s > 2 || cvar_invuln_s < 0) {
			cvar_invuln_s = 0;
			LogError("Value of sm_friendly_invuln_s is invalid. Plugin will behave as if value was 0.");
		}
		if (hHandle != INVALID_HANDLE) {
			new sentry = -1;
			while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(sentry)) {
					new engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_invuln_s < 2) {
							ApplyInvuln(sentry, INVULNMODE_MORTAL);
							RemoveActiveSapper(sentry, false);
						}
						else if (cvar_invuln_s == 2) {
							ApplyInvuln(sentry, INVULNMODE_GOD);
							RemoveActiveSapper(sentry, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_d || hHandle == INVALID_HANDLE) {
		cvar_invuln_d = GetConVarInt(hcvar_invuln_d);
		if (cvar_invuln_d > 2 || cvar_invuln_d < 0) {
			cvar_invuln_d = 0;
			LogError("Value of sm_friendly_invuln_d is invalid. Plugin will behave as if value was 0.");
		}
		if (hHandle != INVALID_HANDLE) {
			new dispenser = -1;
			while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(dispenser)) {
					new engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_invuln_d < 2) {
							ApplyInvuln(dispenser, INVULNMODE_MORTAL);
							RemoveActiveSapper(dispenser, false);
						}
						else if (cvar_invuln_d == 2) {
							ApplyInvuln(dispenser, INVULNMODE_GOD);
							RemoveActiveSapper(dispenser, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_t || hHandle == INVALID_HANDLE) {
		cvar_invuln_t = GetConVarInt(hcvar_invuln_t);
		if (cvar_invuln_t > 2 || cvar_invuln_t < 0) {
			cvar_invuln_t = 0;
			LogError("Value of sm_friendly_invuln_t is invalid. Plugin will behave as if value was 0.");
		}
		if (hHandle != INVALID_HANDLE) {
			new teleporter = -1;
			while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(teleporter)) {
					new engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_invuln_t < 2) {
							ApplyInvuln(teleporter, INVULNMODE_MORTAL);
							RemoveActiveSapper(teleporter, false);
						}
						else if (cvar_invuln_t == 2) {
							ApplyInvuln(teleporter, INVULNMODE_GOD);
							RemoveActiveSapper(teleporter, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_notarget_p || hHandle == INVALID_HANDLE) {
		cvar_notarget_p = GetConVarInt(hcvar_notarget_p);
		if (cvar_notarget_p > 3 || cvar_notarget_p < 0) {
			cvar_notarget_p = 1;
			LogError("Value of sm_friendly_notarget is invalid. Plugin will behave as if value was 1.");
		}
		if (hHandle != INVALID_HANDLE) {
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFriendly[client]) {
					if (cvar_notarget_p > 0) {
						SetNotarget(client, true);
					}
					else {
						SetNotarget(client, false);
					}
				}
			}
			new entity = -1;
			while ((entity = FindEntityByClassname(entity, "func_regenerate"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(entity, SDKHook_StartTouch, CabinetStartTouch);
				SDKUnhook(entity, SDKHook_EndTouch, CabinetEndTouch);
				SDKUnhook(entity, SDKHook_Touch, CabinetTouch);
				if (cvar_notarget_p > 1) {
					SDKHook(entity, SDKHook_StartTouch, CabinetStartTouch);
					SDKHook(entity, SDKHook_EndTouch, CabinetEndTouch);
					if (cvar_notarget_p == 3) {
						SDKHook(entity, SDKHook_Touch, CabinetTouch);
					}
				}
			}

		}
	}
	if (hHandle == hcvar_notarget_s || hHandle == INVALID_HANDLE) {
		cvar_notarget_s = GetConVarBool(hcvar_notarget_s);
		if (hHandle != INVALID_HANDLE) {
			new sentry = -1;
			while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(sentry)) {
					new engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_notarget_s) {
							SetNotarget(sentry, true);
						}
						else {
							SetNotarget(sentry, false);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_notarget_d || hHandle == INVALID_HANDLE) {
		cvar_notarget_d = GetConVarBool(hcvar_notarget_d);
		if (hHandle != INVALID_HANDLE) {
			new dispenser = -1;
			while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(dispenser)) {
					new engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_notarget_d) {
							SetNotarget(dispenser, true);
						}
						else {
							SetNotarget(dispenser, false);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_notarget_t || hHandle == INVALID_HANDLE) {
		cvar_notarget_t = GetConVarBool(hcvar_notarget_t);
		if (hHandle != INVALID_HANDLE) {
			new teleporter = -1;
			while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(teleporter)) {
					new engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_notarget_t) {
							SetNotarget(teleporter, true);
						}
						else {
							SetNotarget(teleporter, false);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_p || hHandle == INVALID_HANDLE) {
		cvar_noblock_p = GetConVarInt(hcvar_noblock_p);
		if (cvar_noblock_p > 3 || cvar_noblock_p < 0) {
			cvar_noblock_p = 2;
			LogError("Value of sm_friendly_noblock is invalid. Plugin will behave as if value was 2.");
		}
		if (hHandle != INVALID_HANDLE) {
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFriendly[client]) {
					if (cvar_noblock_p == 0) {
						ApplyNoblock(client, false);
					}
					else {
						ApplyNoblock(client, true);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_s || hHandle == INVALID_HANDLE) {
		cvar_noblock_s = GetConVarInt(hcvar_noblock_s);
		if (cvar_noblock_s > 3 || cvar_noblock_s < 0) {
			cvar_noblock_s = 3;
			LogError("Value of sm_friendly_noblock_s is invalid. Plugin will behave as if value was 3.");
		}
		if (hHandle != INVALID_HANDLE) {
			new sentry = -1;
			while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(sentry)) {
					new engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_noblock_s == 0) {
							ApplyNoblock(sentry, false);
						}
						else {
							ApplyNoblock(sentry, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_d || hHandle == INVALID_HANDLE) {
		cvar_noblock_d = GetConVarInt(hcvar_noblock_d);
		if (cvar_noblock_d > 3 || cvar_noblock_d < 0) {
			cvar_noblock_d = 3;
			LogError("Value of sm_friendly_noblock_d is invalid. Plugin will behave as if value was 3.");
		}
		if (hHandle != INVALID_HANDLE) {
			new dispenser = -1;
			while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(dispenser)) {
					new engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_noblock_d == 0) {
							ApplyNoblock(dispenser, false);
						}
						else {
							ApplyNoblock(dispenser, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_t || hHandle == INVALID_HANDLE) {
		cvar_noblock_t = GetConVarInt(hcvar_noblock_t);
		if (cvar_noblock_t > 3 || cvar_noblock_t < 0) {
			cvar_noblock_t = 3;
			LogError("Value of sm_friendly_noblock_t is invalid. Plugin will behave as if value was 3.");
		}
		if (hHandle != INVALID_HANDLE) {
			new teleporter = -1;
			while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(teleporter)) {
					new engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_noblock_t == 0) {
							ApplyNoblock(teleporter, false);
						}
						else {
							ApplyNoblock(teleporter, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_p || hHandle == INVALID_HANDLE) {
		cvar_alpha_p = GetConVarInt(hcvar_alpha_p);
		if (cvar_alpha_p > 255 || cvar_alpha_p < -1) {
			cvar_alpha_p = 50;
			LogError("Value of sm_friendly_alpha is invalid. Plugin will behave as if value was 50.");
		}
		if (hHandle != INVALID_HANDLE) {
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFriendly[client]) {
					if (cvar_alpha_p >= 0 && cvar_alpha_p <= 255) {
						SetEntityRenderMode(client, RENDER_TRANSALPHA);
						SetEntityRenderColor(client, _, _, _, cvar_alpha_p);
					}
					else {
						SetEntityRenderMode(client, RENDER_NORMAL);
						SetEntityRenderColor(client, _, _, _, _);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_w || hHandle == INVALID_HANDLE) {
		cvar_alpha_w = GetConVarInt(hcvar_alpha_w);
		if (cvar_alpha_w > 255 || cvar_alpha_w < -1) {
			cvar_alpha_w = 50;
			LogError("Value of sm_friendly_alpha_w is invalid. Plugin will behave as if value was 50.");
		}
		if (hHandle != INVALID_HANDLE) {
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFriendly[client]) {
					if (cvar_alpha_w >= 0 && cvar_alpha_w <= 255) {
						SetWearableInvis(client);
					}
					else {
						SetWearableInvis(client, false);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_wep || hHandle == INVALID_HANDLE) {
		cvar_alpha_wep = GetConVarInt(hcvar_alpha_wep);
		if (cvar_alpha_wep > 255 || cvar_alpha_wep < -1) {
			cvar_alpha_wep = 50;
			LogError("Value of sm_friendly_alpha_wep is invalid. Plugin will behave as if value was 50.");
		}
		if (hHandle != INVALID_HANDLE) {
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFriendly[client]) {
					if (cvar_alpha_wep >= 0 && cvar_alpha_wep <= 255) {
						SetWeaponInvis(client);
					}
					else {
						SetWeaponInvis(client, false);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_s || hHandle == INVALID_HANDLE) {
		cvar_alpha_s = GetConVarInt(hcvar_alpha_s);
		if (cvar_alpha_s > 255 || cvar_alpha_s < -1) {
			cvar_alpha_s = 50;
			LogError("Value of sm_friendly_alpha_s is invalid. Plugin will behave as if value was 50.");
		}
		if (hHandle != INVALID_HANDLE) {
			new sentry = -1;
			while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(sentry)) {
					new engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_alpha_s >= 0) {
							SetEntityRenderMode(sentry, RENDER_TRANSALPHA);
							SetEntityRenderColor(sentry, _, _, _, cvar_alpha_s);
						}
						else {
							SetEntityRenderMode(sentry, RENDER_NORMAL);
							SetEntityRenderColor(sentry, _, _, _, _);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_d || hHandle == INVALID_HANDLE) {
		cvar_alpha_d = GetConVarInt(hcvar_alpha_d);
		if (cvar_alpha_d > 255 || cvar_alpha_d < -1) {
			cvar_alpha_d = 50;
			LogError("Value of sm_friendly_alpha_d is invalid. Plugin will behave as if value was 50.");
		}
		if (hHandle != INVALID_HANDLE) {
			new dispenser = -1;
			while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(dispenser)) {
					new engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_alpha_d >= 0) {
							SetEntityRenderMode(dispenser, RENDER_TRANSALPHA);
							SetEntityRenderColor(dispenser, _, _, _, cvar_alpha_d);
						}
						else {
							SetEntityRenderMode(dispenser, RENDER_NORMAL);
							SetEntityRenderColor(dispenser, _, _, _, _);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_t || hHandle == INVALID_HANDLE) {
		cvar_alpha_t = GetConVarInt(hcvar_alpha_t);
		if (cvar_alpha_t > 255 || cvar_alpha_t < -1) {
			cvar_alpha_t = 50;
			LogError("Value of sm_friendly_alpha_t is invalid. Plugin will behave as if value was 50.");
		}
		if (hHandle != INVALID_HANDLE) {
			new teleporter = -1;
			while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(teleporter)) {
					new engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
					if (!IsValidClient(engie)) {
						continue;
					}
					if (IsFriendly[engie]) {
						if (cvar_alpha_t >= 0) {
							SetEntityRenderMode(teleporter, RENDER_TRANSALPHA);
							SetEntityRenderColor(teleporter, _, _, _, cvar_alpha_t);
						}
						else {
							SetEntityRenderMode(teleporter, RENDER_NORMAL);
							SetEntityRenderColor(teleporter, _, _, _, _);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_proj || hHandle == INVALID_HANDLE) {
		cvar_alpha_proj = GetConVarInt(hcvar_alpha_proj);
		if (cvar_alpha_proj > 255 || cvar_alpha_proj < -1) {
			cvar_alpha_proj = 50;
			LogError("Value of sm_friendly_alpha_proj is invalid. Plugin will behave as if value was 50.");
		}
	}
	if (hHandle == hcvar_nobuild_s || hHandle == INVALID_HANDLE) {
		cvar_nobuild_s = GetConVarBool(hcvar_nobuild_s);
	}
	if (hHandle == hcvar_nobuild_d || hHandle == INVALID_HANDLE) {
		cvar_nobuild_d = GetConVarBool(hcvar_nobuild_d);
	}
	if (hHandle == hcvar_nobuild_t || hHandle == INVALID_HANDLE) {
		cvar_nobuild_t = GetConVarBool(hcvar_nobuild_t);
	}
	if (hHandle == hcvar_killbuild_h_s || hHandle == INVALID_HANDLE) {
		cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_h_s);
	}
	if (hHandle == hcvar_killbuild_h_d || hHandle == INVALID_HANDLE) {
		cvar_killbuild_h_d = GetConVarBool(hcvar_killbuild_h_d);
	}
	if (hHandle == hcvar_killbuild_h_t || hHandle == INVALID_HANDLE) {
		cvar_killbuild_h_t = GetConVarBool(hcvar_killbuild_h_t);
	}
	if (hHandle == hcvar_killbuild_f_s || hHandle == INVALID_HANDLE) {
		cvar_killbuild_f_s = GetConVarBool(hcvar_killbuild_f_s);
	}
	if (hHandle == hcvar_killbuild_f_d || hHandle == INVALID_HANDLE) {
		cvar_killbuild_f_d = GetConVarBool(hcvar_killbuild_f_d);
	}
	if (hHandle == hcvar_killbuild_f_t || hHandle == INVALID_HANDLE) {
		cvar_killbuild_f_t = GetConVarBool(hcvar_killbuild_f_t);
	}
	if (hHandle == hcvar_blockweps_black || hHandle == INVALID_HANDLE) {
		decl String:strWeaponsBlack[255]; strWeaponsBlack[0] = '\0';
		GetConVarString(hcvar_blockweps_black, strWeaponsBlack, sizeof(strWeaponsBlack));
		if (StrEqual(strWeaponsBlack, "-2")) {
			cvar_blockweps_black[0] = -1;
		}
		else {
			decl String:strWeaponsBlack2[255][8];
			if (StrEqual(strWeaponsBlack, "-1")) {
				strWeaponsBlack = DEFAULT_BLOCKED_WEAPONS;
			}
			new numweps = ExplodeString(strWeaponsBlack, ",", strWeaponsBlack2, sizeof(strWeaponsBlack2), sizeof(strWeaponsBlack2[]));
			for (new i=0; i < sizeof(cvar_blockweps_black) && i < numweps; i++) {
				cvar_blockweps_black[i] = StringToInt(strWeaponsBlack2[i]);
			}
			cvar_blockweps_black[numweps] = -1;
		}
	}
	if (hHandle == hcvar_blockweps_white || hHandle == INVALID_HANDLE) {
		decl String:strWeaponsWhite[255]; strWeaponsWhite[0] = '\0';
		GetConVarString(hcvar_blockweps_white, strWeaponsWhite, sizeof(strWeaponsWhite));
		if (StrEqual(strWeaponsWhite, "-2")) {
			cvar_blockweps_white[0] = -1;
		}
		else {
			decl String:strWeaponsWhite2[255][8];
			if (StrEqual(strWeaponsWhite, "-1")) {
				strWeaponsWhite = DEFAULT_WHITELISTED_WEAPONS;
			}
			new numweps = ExplodeString(strWeaponsWhite, ",", strWeaponsWhite2, sizeof(strWeaponsWhite2), sizeof(strWeaponsWhite2[]));
			for (new i=0; i < sizeof(cvar_blockweps_white) && i < numweps; i++) {
				cvar_blockweps_white[i] = StringToInt(strWeaponsWhite2[i]);
			}
			cvar_blockweps_white[numweps] = -1;
		}
	}
	if (hHandle == hcvar_blockweps_classes || hHandle == INVALID_HANDLE) {
		decl String:strWeaponsClass[256]; strWeaponsClass[0] = '\0';
		GetConVarString(hcvar_blockweps_classes, strWeaponsClass, sizeof(strWeaponsClass));
		if (StrEqual(strWeaponsClass, "-2")) {
			cvar_blockweps_classes[0] = "-1";
		}
		else {
			if (StrEqual(strWeaponsClass, "-1")) {
				strWeaponsClass = DEFAULT_BLOCKED_WEAPONCLASSES;
			}
			new numclasses = ExplodeString(strWeaponsClass, ",", cvar_blockweps_classes, sizeof(cvar_blockweps_classes), sizeof(cvar_blockweps_classes[]));
			cvar_blockweps_classes[numclasses] = "-1";
		}
	}
	if (hHandle == hcvar_blocktaunt || hHandle == INVALID_HANDLE) {
		decl String:strWeaponsTaunt[255]; strWeaponsTaunt[0] = '\0';
		GetConVarString(hcvar_blocktaunt, strWeaponsTaunt, sizeof(strWeaponsTaunt));
		if (StrEqual(strWeaponsTaunt, "-2")) {
			cvar_blocktaunt[0] = -1;
		}
		else {
			decl String:strWeaponsTaunt2[255][8];
			if (StrEqual(strWeaponsTaunt, "-1")) {
				strWeaponsTaunt = DEFAULT_BLOCKED_TAUNTS;
			}
			new numweps = ExplodeString(strWeaponsTaunt, ",", strWeaponsTaunt2, sizeof(strWeaponsTaunt2), sizeof(strWeaponsTaunt2[]));
			for (new i=0; i < sizeof(cvar_blocktaunt) && i < numweps; i++) {
				cvar_blocktaunt[i] = StringToInt(strWeaponsTaunt2[i]);
			}
			cvar_blocktaunt[numweps] = -1;
		}
	}
	if (hHandle == hcvar_overlay || hHandle == INVALID_HANDLE) {
		GetConVarString(hcvar_overlay, cvar_overlay, sizeof(cvar_overlay));
		if (StrEqual(cvar_overlay, "0")) {
			cvar_overlay = "0";
		}
		else if (StrEqual(cvar_overlay, "")) {
			cvar_overlay = "0";
		}
		else if (StrEqual(cvar_overlay, "1")) {
			cvar_overlay = DEFAULT_OVERLAY_1;
		}
		else if (StrEqual(cvar_overlay, "2")) {
			cvar_overlay = DEFAULT_OVERLAY_2;
		}
		else if (StrEqual(cvar_overlay, "3")) {
			cvar_overlay = DEFAULT_OVERLAY_3;
		}
		else if (StrEqual(cvar_overlay, "4")) {
			cvar_overlay = DEFAULT_OVERLAY_4;
		}
		else if (StrEqual(cvar_overlay, "5")) {
			cvar_overlay = DEFAULT_OVERLAY_5;
		}
		else if (StrEqual(cvar_overlay, "6")) {
			cvar_overlay = DEFAULT_OVERLAY_6;
		}
		if (hHandle != INVALID_HANDLE) {
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFriendly[client]) {
					if (!StrEqual(cvar_overlay, "0")) {
						SetOverlay(client, true);
					}
					else {
						SetOverlay(client, false);
					}
				}
			}
		}
	}
	if (hHandle == INVALID_HANDLE) {
		HookCvars();
		HookThings();
		RestartAFKTimer();
	}
}

HookCvars() {
	HookConVarChange(hcvar_version, cvarChange);
	HookConVarChange(hcvar_enabled, cvarChange);
	HookConVarChange(hcvar_update, cvarChange);
	HookConVarChange(hcvar_logging, cvarChange);
	HookConVarChange(hcvar_advert, cvarChange);
	HookConVarChange(hcvar_maxfriendlies, cvarChange);
	HookConVarChange(hcvar_delay, cvarChange);
	HookConVarChange(hcvar_afklimit, cvarChange);
	HookConVarChange(hcvar_afkinterval, cvarChange);
	HookConVarChange(hcvar_action_h, cvarChange);
	HookConVarChange(hcvar_action_f, cvarChange);
	HookConVarChange(hcvar_action_h_spawn, cvarChange);
	HookConVarChange(hcvar_action_f_spawn, cvarChange);
	HookConVarChange(hcvar_remember, cvarChange);
	HookConVarChange(hcvar_goomba, cvarChange);
	HookConVarChange(hcvar_blockrtd, cvarChange);
	HookConVarChange(hcvar_overlay, cvarChange);
	HookConVarChange(hcvar_thirdperson, cvarChange);
	//HookConVarChange(hcvar_botignore, cvarChange);
	//HookConVarChange(hcvar_settransmit, cvarChange);
	HookConVarChange(hcvar_stopcap, cvarChange);
	HookConVarChange(hcvar_stopintel, cvarChange);
	HookConVarChange(hcvar_ammopack, cvarChange);
	HookConVarChange(hcvar_healthpack, cvarChange);
	HookConVarChange(hcvar_money, cvarChange);
	HookConVarChange(hcvar_spellbook, cvarChange);
	HookConVarChange(hcvar_pumpkin, cvarChange);
	HookConVarChange(hcvar_airblastkill, cvarChange);
	HookConVarChange(hcvar_funcbutton, cvarChange);
	HookConVarChange(hcvar_usetele, cvarChange);
	HookConVarChange(hcvar_blockweps_classes, cvarChange);
	HookConVarChange(hcvar_blockweps_black, cvarChange);
	HookConVarChange(hcvar_blockweps_white, cvarChange);
	HookConVarChange(hcvar_blocktaunt, cvarChange);
	HookConVarChange(hcvar_invuln_p, cvarChange);
	HookConVarChange(hcvar_invuln_s, cvarChange);
	HookConVarChange(hcvar_invuln_d, cvarChange);
	HookConVarChange(hcvar_invuln_t, cvarChange);
	HookConVarChange(hcvar_notarget_p, cvarChange);
	HookConVarChange(hcvar_notarget_s, cvarChange);
	HookConVarChange(hcvar_notarget_d, cvarChange);
	HookConVarChange(hcvar_notarget_t, cvarChange);
	HookConVarChange(hcvar_alpha_p, cvarChange);
	HookConVarChange(hcvar_alpha_w, cvarChange);
	HookConVarChange(hcvar_alpha_wep, cvarChange);
	HookConVarChange(hcvar_alpha_s, cvarChange);
	HookConVarChange(hcvar_alpha_d, cvarChange);
	HookConVarChange(hcvar_alpha_t, cvarChange);
	HookConVarChange(hcvar_alpha_proj, cvarChange);
	HookConVarChange(hcvar_noblock_p, cvarChange);
	HookConVarChange(hcvar_noblock_s, cvarChange);
	HookConVarChange(hcvar_noblock_d, cvarChange);
	HookConVarChange(hcvar_noblock_t, cvarChange);
	HookConVarChange(hcvar_killbuild_h_s, cvarChange);
	HookConVarChange(hcvar_killbuild_h_d, cvarChange);
	HookConVarChange(hcvar_killbuild_h_t, cvarChange);
	HookConVarChange(hcvar_killbuild_f_s, cvarChange);
	HookConVarChange(hcvar_killbuild_f_d, cvarChange);
	HookConVarChange(hcvar_killbuild_f_t, cvarChange);
	HookConVarChange(hcvar_nobuild_s, cvarChange);
	HookConVarChange(hcvar_nobuild_d, cvarChange);
	HookConVarChange(hcvar_nobuild_t, cvarChange);
}

////////////////////////////////////////////////////
//Other stocks, probably going to be moving these into a custom .inc

/**
* Checks if the specified index is a player and connected.
*
* @param client				A client index.
* @param threshold			Defines what a "valid client" is.
* @param bots				If true, bots will always return FALSE.
* @param replay				If true, Replay and SourceTV will always return FALSE.
* @param convert			If true, client indexes above 4096 will be run through EntRefToEntIndex();
* @return					TRUE or FALSE.
*/
stock bool:IsValidClient(client, f_validclientlevel:threshold=VCLIENT_INGAME, bool:nobots=false, bool:noreplay=true, bool:convert=true) {
	if (convert && client > 4096) {
		client = EntRefToEntIndex(client);
	}
	if (threshold >= VCLIENT_VALIDINDEX && (client < 1 || client > MaxClients)) {
		return false;
	}
	if (threshold == VCLIENT_CONNECTED && !IsClientConnected(client)) {
		return false;
	}
	if (threshold >= VCLIENT_INGAME && !IsClientInGame(client)) {
		return false;
	}
	if (threshold >= VCLIENT_ONATEAM && GetClientTeam(client) < 1) {
		return false;
	}
	if (threshold >= VCLIENT_ONAREALTEAM && GetClientTeam(client) < 2) {
		return false;
	}
	if (threshold >= VCLIENT_ALIVE && !IsPlayerAlive(client)) {
		return false;
	}
	if (nobots && IsFakeClient(client)) {
		return false;
	}
	if (noreplay && (IsClientSourceTV(client) || IsClientReplay(client))) {
		return false;
	}
	return true;
}