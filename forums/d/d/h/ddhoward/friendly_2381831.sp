#pragma semicolon 1
#define PLUGIN_VERSION "16.0108"
#define UPDATE_FILE "friendly.txt"
#define CONVAR_PREFIX "sm_friendly"
#define DEFAULT_UPDATE_SETTING "2"
#define UPD_LIBFUNC

#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>

#undef REQUIRE_PLUGIN
#include <ddhoward_updater>
#include <validClient>
#tryinclude <goomba>
#tryinclude <rtd>
#pragma newdecls required;

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
	1105 - The Self-Aware Beauty Mark
	222  - Mad Milk, to prevent healing
	1121 - Mutated Milk, to prevent healing
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

enum f_invulnmode {
	INVULNMODE_GODMODE = 0,
	INVULNMODE_GOD = 0,
	INVULNMODE_BUDDAH = 1,
	INVULNMODE_BUDDHA = 1,
	INVULNMODE_MORTAL = 2,
};

int FriendlyPlayerCount;

bool IsFriendly[MAXPLAYERS+1];
bool RequestedChange[MAXPLAYERS+1];
bool IsAdmin[MAXPLAYERS+1];
bool RFETRIZ[MAXPLAYERS+1];
bool IsInSpawn[MAXPLAYERS+1];
bool IsLocked[MAXPLAYERS+1];
float ToggleTimer[MAXPLAYERS+1];
float AfkTime[MAXPLAYERS+1];
int p_lastbtnstate[MAXPLAYERS+1];

ConVar cvar_enabled;
ConVar cvar_logging;
ConVar cvar_maxfriendlies;
ConVar cvar_delay;
ConVar cvar_afklimit;
ConVar cvar_afkinterval;

ConVar cvar_action_h;
ConVar cvar_action_f;
ConVar cvar_action_h_spawn;
ConVar cvar_action_f_spawn;
ConVar cvar_remember;
ConVar cvar_goomba;
ConVar cvar_blockrtd;
//ConVar cvar_botignore;
//ConVar cvar_settransmit;

ConVar cvar_stopcap;
ConVar cvar_stopintel;
ConVar cvar_ammopack;
ConVar cvar_healthpack;
ConVar cvar_money;
ConVar cvar_spellbook;
ConVar cvar_pumpkin;
ConVar cvar_airblastkill;
ConVar cvar_funcbutton;
ConVar cvar_usetele;

ConVar cvar_blockweps_black;
int g_blockweps_black[255];
ConVar cvar_blockweps_classes;
char g_blockweps_classes[255][64];
ConVar cvar_blockweps_white;
int g_blockweps_white[255];
ConVar cvar_blocktaunt;
int g_blocktaunt[255];

ConVar cvar_invuln_p;
ConVar cvar_invuln_s;
ConVar cvar_invuln_d;
ConVar cvar_invuln_t;

ConVar cvar_notarget_p;
ConVar cvar_notarget_s;
ConVar cvar_notarget_d;
ConVar cvar_notarget_t;

ConVar cvar_noblock_p;
ConVar cvar_noblock_s;
ConVar cvar_noblock_d;
ConVar cvar_noblock_t;

ConVar cvar_alpha_p;
ConVar cvar_alpha_w;
ConVar cvar_alpha_wep;
ConVar cvar_alpha_s;
ConVar cvar_alpha_d;
ConVar cvar_alpha_t;
ConVar cvar_alpha_proj;

ConVar cvar_nobuild_s;
ConVar cvar_nobuild_d;
ConVar cvar_nobuild_t;
ConVar cvar_killbuild_h_s;
ConVar cvar_killbuild_h_d;
ConVar cvar_killbuild_h_t;
ConVar cvar_killbuild_f_s;
ConVar cvar_killbuild_f_d;
ConVar cvar_killbuild_f_t;


Handle h_timer_afkcheck;

Handle hfwd_CanToggleFriendly;
Handle hfwd_FriendlyPre;
Handle hfwd_Friendly;
Handle hfwd_FriendlyPost;
Handle hfwd_HostilePre;
Handle hfwd_Hostile;
Handle hfwd_HostilePost;
Handle hfwd_RefreshPre;
Handle hfwd_Refresh;
Handle hfwd_RefreshPost;
Handle hfwd_FriendlySpawn;
Handle hfwd_FriendlyEnable;
Handle hfwd_FriendlyDisable;
Handle hfwd_FriendlyLoad;
Handle hfwd_FriendlyUnload;

Handle g_hWeaponReset;

int g_minigunoffsetstate;


public Plugin myinfo = {
	name = "[TF2] Friendly Mode",
	author = "Derek D. Howard",
	description = "Allows players to become invulnerable to damage from other players, while also being unable to attack other players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=213205"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] strError, int iErr_Max) { 
	char strGame[32];
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

public void OnPluginStart() {

	g_minigunoffsetstate = FindSendPropInfo("CTFMinigun", "m_iWeaponState");

	LoadTranslations("common.phrases");

	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client)) {
			OnClientPutInServer(client);
		}
	}
	
	cvar_enabled = CreateConVar("sm_friendly_enabled", "1", "(0/1) Enables/Disables Friendly Mode", _, true, 0.0, true, 1.0);

	cvar_logging = CreateConVar("sm_friendly_logging", "2", "(0/1/2/3) 0 = No logging, 1 = Log admins targeting others, 2 = (1 + Log players using sm_friendly), 3 = (2 + list all players affected by admin commands).", _, true, 0.0, true, 3.0);
	cvar_maxfriendlies = CreateConVar("sm_friendly_maxfriendlies", "32", "(Any positive integer) This sets a limit how many players can simultaneously be Friendly.", _, true, 0.0);
	cvar_delay = CreateConVar("sm_friendly_delay", "5.0", "(Any non-negative value) How long, in seconds, must a player wait after changing modes until he can use sm_friendly again?", _, true, 0.0);
	cvar_afklimit = CreateConVar("sm_friendly_afklimit", "300", "(Any non-negative integer) Time in seconds players can be AFK before being moved out of Friendly mode. Set to 0 to disable.", _, true, 0.0);
	cvar_afkinterval = CreateConVar("sm_friendly_afkinterval", "1.0", "Time in seconds between AFK checks. This should be a very low value, between 0.1 and 5.0, and should only be as high as 5.0 if you notice that the checks are causing lag.", _, true, 0.1, true, 5.0);

	cvar_action_h = CreateConVar("sm_friendly_action_h", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Hostile? See this plugin's thread for details.", _, true, -2.0);
	cvar_action_f = CreateConVar("sm_friendly_action_f", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Friendly? See this plugin's thread for details.", _, true, -2.0);
	cvar_action_h_spawn = CreateConVar("sm_friendly_action_h_spawn", "0", "(Any integer, -2 or greater) Same as sm_friendly_action_h, but applies to players in a spawn room.", _, true, -2.0);
	cvar_action_f_spawn = CreateConVar("sm_friendly_action_f_spawn", "0", "(Any integer, -2 or greater) Same as sm_friendly_action_f, but applies to players in a spawn room.", _, true, -2.0);
	cvar_remember = CreateConVar("sm_friendly_remember", "0", "(0/1) If enabled, a player who somehow dies while Friendly be Friendly upon respawn.", _, true, 0.0, true, 1.0);
	cvar_goomba = CreateConVar("sm_friendly_goomba", "1", "(0/1) If enabled, Goomba Stomp will follow the same damage rules of Friendly mode as regular attacks.", _, true, 0.0, true, 1.0);
	cvar_blockrtd = CreateConVar("sm_friendly_blockrtd", "1", "(0/1) If enabled, Friendly players will be unable to activate Roll The Dice.", _, true, 0.0, true, 1.0);
	//cvar_botignore = CreateConVar("sm_friendly_botignore", "1", "(0/1) If enabled, friendly players will be invisible to bots.", _, true, 0.0, true, 1.0);
	//cvar_settransmit = CreateConVar("sm_friendly_settransmit", "0", "(0/1/2) 0 = Disabled, 1 = Friendlies will be invisible to non-Friendlies, 2 = No visibility between Friendlies and non-Friendlies", _);
	
	cvar_stopcap = CreateConVar("sm_friendly_stopcap", "1", "(0/1) If enabled, Friendly players will be unable to cap points or push carts.", _, true, 0.0, true, 1.0);
	cvar_stopintel = CreateConVar("sm_friendly_stopintel", "1", "(0/1) If enabled, Friendly players will be unable to grab the intel.", _, true, 0.0, true, 1.0);
	cvar_ammopack = CreateConVar("sm_friendly_ammopack", "1", "(0/1) If enabled, Friendly players will be unable to pick up ammo boxes, dropped weapons, or Sandman balls.", _, true, 0.0, true, 1.0);
	cvar_healthpack = CreateConVar("sm_friendly_healthpack", "1", "(0/1) If enabled, Friendly players will be unable to pick up health boxes or sandviches.", _, true, 0.0, true, 1.0);
	cvar_spellbook = CreateConVar("sm_friendly_spellbook", "1", "(0/1) If enabled, Friendly players will be unable to pick up spellbooks.", _, true, 0.0, true, 1.0);
	cvar_money = CreateConVar("sm_friendly_money", "1", "(0/1) If enabled, Friendly players will be unable to pick up MvM money.", _, true, 0.0, true, 1.0);
	cvar_pumpkin = CreateConVar("sm_friendly_pumpkin", "1", "(0/1) If enabled, Friendly players will be unable to blow up pumpkins.", _, true, 0.0, true, 1.0);
	cvar_airblastkill = CreateConVar("sm_friendly_airblastkill", "1", "(0/1) If enabled, Friendly projectiles will vanish upon being airblasted by non-Friendly pyros.", _, true, 0.0, true, 1.0);
	cvar_funcbutton = CreateConVar("sm_friendly_funcbutton", "0", "(0/1) If enabled, Friendly projectiles will be unable to trigger func_buttons by damaging them.", _, true, 0.0, true, 1.0);
	cvar_usetele = CreateConVar("sm_friendly_usetele", "3", "(0/1/2/3) who can use what teleporter? See thread for usage.", _, true, 0.0, true, 3.0);

	cvar_blockweps_classes = CreateConVar("sm_friendly_blockwep_classes", "-1", "What weapon classes to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", _);
	cvar_blockweps_black = CreateConVar("sm_friendly_blockweps", "-1", "What weapon index definiteion numbers to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", _);
	cvar_blockweps_white = CreateConVar("sm_friendly_blockweps_whitelist", "-1", "What weapon index definiteion numbers to whitelist? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", _);
	cvar_blocktaunt = CreateConVar("sm_friendly_blocktaunt", "-1", "What weapon index definition numbers to block taunting with? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", _);

	cvar_invuln_p = CreateConVar("sm_friendly_invuln", "2", "(0/1/2/3) 0 = Friendly players have full godmode. 1 = Buddha. 2 = Only invulnerable to other players. 3 = Invuln to other players AND himself.", _, true, 0.0, true, 3.0);
	cvar_invuln_s = CreateConVar("sm_friendly_invuln_s", "0", "(0/1/2) 0 = Disabled, 1 = Friendly sentries will be invulnerable to other players, 2 = Friendly sentries have full Godmode.", _, true, 0.0, true, 2.0);
	cvar_invuln_d = CreateConVar("sm_friendly_invuln_d", "0", "(0/1/2) 0 = Disabled, 1 = Friendly dispensers will be invulnerable to other players, 2 = Friendly dispensers have full Godmode.", _, true, 0.0, true, 2.0);
	cvar_invuln_t = CreateConVar("sm_friendly_invuln_t", "0", "(0/1/2) 0 = Disabled, 1 = Friendly teleporters will be invulnerable to other players, 2 = Friendly teleporters have full Godmode.", _, true, 0.0, true, 2.0);

	cvar_notarget_p = CreateConVar("sm_friendly_notarget", "1", "(0/1/2/3) If enabled, a Friendly player will be invisible to sentries, immune to airblasts, etc.", _, true, 0.0, true, 3.0);
	cvar_notarget_s = CreateConVar("sm_friendly_notarget_s", "1", "(0/1) If enabled, a Friendly player's sentry will be invisible to enemy sentries.", _, true, 0.0, true, 1.0);
	cvar_notarget_d = CreateConVar("sm_friendly_notarget_d", "1", "(0/1) If enabled, a Friendly player's dispenser will be invisible to enemy sentries. Friendly dispensers will have their healing act buggy.", _, true, 0.0, true, 1.0);
	cvar_notarget_t = CreateConVar("sm_friendly_notarget_t", "1", "(0/1) If enabled, a Friendly player's teleporters will be invisible to enemy sentries.", _, true, 0.0, true, 1.0);

	cvar_alpha_p = CreateConVar("sm_friendly_alpha", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players. -1 disables this feature.", _, true, -1.0, true, 255.0);
	cvar_alpha_w = CreateConVar("sm_friendly_alpha_w", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' cosmetics. -1 disables this feature.", _, true, -1.0, true, 255.0);
	cvar_alpha_wep = CreateConVar("sm_friendly_alpha_wep", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' weapons. -1 disables this feature.", _, true, -1.0, true, 255.0);
	cvar_alpha_s = CreateConVar("sm_friendly_alpha_s", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly sentries. -1 disables this feature.", _, true, -1.0, true, 255.0);
	cvar_alpha_d = CreateConVar("sm_friendly_alpha_d", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly dispensers. -1 disables this feature.", _, true, -1.0, true, 255.0);
	cvar_alpha_t = CreateConVar("sm_friendly_alpha_t", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly teleporters. -1 disables this feature.", _, true, -1.0, true, 255.0);
	cvar_alpha_proj = CreateConVar("sm_friendly_alpha_proj", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' projectiles. -1 disables this feature.", _, true, -1.0, true, 255.0);

	cvar_noblock_p = CreateConVar("sm_friendly_noblock", "2", "(0/1/2/3) Sets the collision group of Friendly players, see the forum thread for details.", _, true, 0.0, true, 3.0);
	cvar_noblock_s = CreateConVar("sm_friendly_noblock_s", "3", "(0/1/2/3) Sets the collision group of Friendly sentries, see the forum thread for details.", _, true, 0.0, true, 3.0);
	cvar_noblock_d = CreateConVar("sm_friendly_noblock_d", "3", "(0/1/2/3) Sets the collision group of Friendly dispensers, see the forum thread for details.", _, true, 0.0, true, 3.0);
	cvar_noblock_t = CreateConVar("sm_friendly_noblock_t", "3", "(0/1/2/3) Sets the collision group of Friendly teleporters, see the forum thread for details.", _, true, 0.0, true, 3.0);

	cvar_killbuild_h_s = CreateConVar("sm_friendly_killsentry", "1", "(0/1) When enabled, a Friendly Engineer's sentry will vanish upon becoming hostile.", _, true, 0.0, true, 1.0);
	cvar_killbuild_h_d = CreateConVar("sm_friendly_killdispenser", "1", "(0/1) When enabled, a Friendly Engineer's dispenser will vanish upon becoming hostile.", _, true, 0.0, true, 1.0);
	cvar_killbuild_h_t = CreateConVar("sm_friendly_killtele", "1", "(0/1) When enabled, a Friendly Engineer's teleporters will vanish upon becoming hostile.", _, true, 0.0, true, 1.0);
	cvar_killbuild_f_s = CreateConVar("sm_friendly_killsentry_f", "1", "(0/1) When enabled, an Engineer's sentry will vanish upon becoming Friendly.", _, true, 0.0, true, 1.0);
	cvar_killbuild_f_d = CreateConVar("sm_friendly_killdispenser_f", "1", "(0/1) When enabled, an Engineer's dispenser will vanish upon becoming Friendly.", _, true, 0.0, true, 1.0);
	cvar_killbuild_f_t = CreateConVar("sm_friendly_killtele_f", "1", "(0/1) When enabled, an Engineer's teleporters will vanish upon becoming Friendly.", _, true, 0.0, true, 1.0);
	cvar_nobuild_s = CreateConVar("sm_friendly_nobuild_s", "0", "(0/1) When enabled, a Friendly engineer will not be able to build sentries.", _, true, 0.0, true, 1.0);
	cvar_nobuild_d = CreateConVar("sm_friendly_nobuild_d", "1", "(0/1) When enabled, a Friendly engineer will not be able to build dispensers.", _, true, 0.0, true, 1.0);
	cvar_nobuild_t = CreateConVar("sm_friendly_nobuild_t", "0", "(0/1) a Friendly engineer will not be able to build teleporters.", _, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_friendly", UseFriendlyCmd, 0, "Toggles Friendly Mode");
	RegAdminCmd("sm_friendly_admin", UseAdminCmd, ADMFLAG_BAN, "Toggles Friendly Admin Mode");
	RegAdminCmd("sm_friendly_a", UseAdminCmd2, 0, _);
	RegAdminCmd("sm_friendly_lock", UseLockCmd, ADMFLAG_BAN, "Blocks a player from using sm_friendly (with no arguments).");
	RegAdminCmd("sm_friendly_l", UseLockCmd2, 0, _);

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

	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "gamedata/friendly.txt");
	if (FileExists(file)) {
		Handle hConf = LoadGameConfigFile("friendly");
		if (hConf != null) {
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "WeaponReset");
			g_hWeaponReset = EndPrepSDKCall();
			if(g_hWeaponReset == null) {
				LogError("Could not initialize call for CTFWeaponBase::WeaponReset. Plugin will not be able to reset weapons before switching!");
			}
		}
		CloseHandle(hConf);
	}
	else {
		LogError("Could not read gamedata/friendly.txt. Plugin will not be able to reset weapons before switching!");
	}
}

public void OnConfigsExecuted() {
	cvarChange(null, "0", "0");

	Call_StartForward(hfwd_FriendlyLoad);
	Call_Finish();
}

public Action UseFriendlyCmd(int client, int args) {
	int numargs = GetCmdArgs();
	int[] target = new int[MaxClients];
	char target_name[MAX_TARGET_LENGTH];
	int direction = -1;
	int method = 0;
	int numtargets;
	if (!cvar_enabled.BoolValue) {
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
		char arg1[64];
		bool tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		char arg2[2];
		GetCmdArg(2, arg2, sizeof(arg2));
		direction = StringToInt(arg2);
		if (!(direction == -1 || direction == 0 || direction == 1)) {
			CReplyToCommand(client, "%s Second argument must be either 0 or 1. 0 to disable Friendly, or 1 to enable.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numargs == 3) {
		char arg3[2];
		GetCmdArg(3, arg3, sizeof(arg3));
		method = StringToInt(arg3);
		if (!(method == 1 || method == 0)) {
			CReplyToCommand(client, "%s Third argument must be either 0 or 1. 0 to toggle Friendly instantly, or 1 to slay the player.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numtargets == 1) {
		int singletarget = target[0];
		if (IsFriendly[singletarget] && direction == 1) {
			CReplyToCommand(client, "%s That player is already Friendly!", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (!IsFriendly[singletarget] && direction == 0) {
			CReplyToCommand(client, "%s That player is already non-Friendly.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	int count;
	if (direction == -1) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (IsFriendly[currenttarget]) {
				MakeClientHostile(currenttarget);
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
				}
				if (method == 1 && !IsAdmin[currenttarget]) {
					KillPlayer(currenttarget);
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
						if (!cvar_remember.BoolValue) {
							RFETRIZ[currenttarget] = true;
						}
					}
				}
				else {
					if (!cvar_remember.BoolValue) {
						RFETRIZ[currenttarget] = true;
					}
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly mode on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (!IsFriendly[currenttarget]) {
				MakeClientFriendly(currenttarget);
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Mode.", CHAT_PREFIX);
				}
				if (IsPlayerAlive(currenttarget)) {
					if (method == 1 && !IsAdmin[currenttarget]) {
						KillPlayer(currenttarget);
						if (!cvar_remember.BoolValue) {
							RFETRIZ[currenttarget] = true;
						}
					}
				}
				else {
					if (!cvar_remember.BoolValue) {
						RFETRIZ[currenttarget] = true;
					}
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly mode on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (IsFriendly[currenttarget]) {
				MakeClientHostile(currenttarget);
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
				}
				if (method == 1 && !IsAdmin[currenttarget]) {
					KillPlayer(currenttarget);
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly mode on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

void UseFriendlyOnSelf(const int client) {
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
		Action result = Plugin_Continue;
		Call_Finish(result);
		if (result != Plugin_Continue) {
			return;
		}
	}
	float time = GetEngineTime();
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
			int action;
			if (IsFriendly[client]) {
				if (IsInSpawn[client]) {
					action = cvar_action_h_spawn.IntValue;
				}
				else {
					action = cvar_action_h.IntValue;
				}
				if (IsAdmin[client]) {
					MakeClientHostile(client);
					CReplyToCommand(client, "%s You are no longer Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
					if (cvar_logging.IntValue >= 2) {
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
					if (cvar_logging.IntValue >= 2) {
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
					}
				}
				else if (action > 0) {
					MakeClientHostile(client);
					SlapPlayer(client, action);
					CReplyToCommand(client, "%s You are no longer Friendly, but took damage because of the switch!", CHAT_PREFIX);
					if (cvar_logging.IntValue >= 2) {
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
					}
				}
			}
			else {
				if (IsInSpawn[client]) {
					action = cvar_action_f_spawn.IntValue;
				}
				else {
					action = cvar_action_f.IntValue;
				}
				if (IsAdmin[client]) {
					MakeClientFriendly(client);
					CReplyToCommand(client, "%s You are now Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
					if (cvar_logging.IntValue >= 2) {
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
					if (FriendlyPlayerCount < cvar_maxfriendlies.IntValue) {
						if (cvar_logging.IntValue >= 2) {
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
					if (FriendlyPlayerCount < cvar_maxfriendlies.IntValue) {
						if (cvar_logging.IntValue >= 2) {
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
			if (IsFriendly[client] && !cvar_remember.BoolValue) {
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

public Action UseAdminCmd(int client, int args) {
	int target[MAXPLAYERS];
	char target_name[MAX_TARGET_LENGTH];
	int direction = -1;
	int numtargets;
	if (!cvar_enabled.BoolValue) {
		CReplyToCommand(client, "%s Friendly Mode is currently disabled.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	int numargs = GetCmdArgs();
	if (numargs == 0 || !CheckCommandAccess(client, "sm_friendly_admin_targetothers", ADMFLAG_ROOT, true)) {
		if (client != 0) {
			if (IsAdmin[client]) {
				IsAdmin[client] = false;
				CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Admin mode.");
				if (cvar_logging.IntValue > 0) {
					LogAction(client, -1, "\"%L\" disabled Friendly Admin mode.", client);
				}
				if (cvar_stopintel.BoolValue && IsFriendly[client]) {
					FakeClientCommand(client, "dropitem");
				}
			}
			else {
				IsAdmin[client] = true;
				CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Admin mode.");
				if (cvar_logging.IntValue > 0) {
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
		char arg1[64];
		bool tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		char arg2[2];
		GetCmdArg(2, arg2, sizeof(arg2));
		direction = StringToInt(arg2);
		if (!(direction == -1 || direction == 0 || direction == 1)) {
			CReplyToCommand(client, "%s Second argument must be 0, 1, or -1. 0 to disable Friendly Admin, 1 to enable, -1 to toggle.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numtargets == 1) {
		int singletarget = target[0];
		if (IsAdmin[singletarget] && direction == 1) {
			CReplyToCommand(client, "%s That player is already in Friendly Admin mode!", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (!IsAdmin[singletarget] && direction == 0) {
			CReplyToCommand(client, "%s That player is already not in Friendly Admin mode!.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	int count;
	if (direction == -1) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = false;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Admin mode.", CHAT_PREFIX);
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Admin mode on \"%L\".", client, currenttarget);
				}
				if (cvar_stopintel.BoolValue && IsFriendly[currenttarget]) {
					FakeClientCommand(currenttarget, "dropitem");
				}
			}
			else {
				IsAdmin[currenttarget] = true;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Admin Mode.", CHAT_PREFIX);
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Admin mode on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Admin mode on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (!IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = true;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Admin mode.", CHAT_PREFIX);
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Admin mode on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Admin on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = false;
				count++;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Admin mode.", CHAT_PREFIX);
				}
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Admin mode on \"%L\".", client, currenttarget);
				}
				if (cvar_stopintel.BoolValue && IsFriendly[currenttarget]) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Admin mode on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Admin on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

public Action UseLockCmd(int client, int args) {
	int target[MAXPLAYERS];
	char target_name[MAX_TARGET_LENGTH];
	int direction = -1;
	int numtargets;
	if (!cvar_enabled.BoolValue) {
		CReplyToCommand(client, "%s Friendly Mode is currently disabled.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	int numargs = GetCmdArgs();
	if (numargs == 0 || numargs > 2) {
		CReplyToCommand(client, "%s Usage: \"sm_friendly_lock [target] [-1/0/1]\"", CHAT_PREFIX);
		return Plugin_Handled;
	}
	if (numargs >= 1) {
		char arg1[64];
		bool tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		char arg2[2];
		GetCmdArg(2, arg2, sizeof(arg2));
		direction = StringToInt(arg2);
		if (!(direction == -1 || direction == 0 || direction == 1)) {
			CReplyToCommand(client, "%s Second argument must be 0, 1, or -1. 0 to disable Friendly Lock, 1 to enable, -1 to toggle.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numtargets == 1) {
		int singletarget = target[0];
		if (IsLocked[singletarget] && direction == 1) {
			CReplyToCommand(client, "%s That player is already Friendly Locked!", CHAT_PREFIX);
			return Plugin_Handled;
		}
		if (!IsLocked[singletarget] && direction == 0) {
			CReplyToCommand(client, "%s That player is already not Friendly Locked!.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	int count;
	if (direction == -1) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (IsLocked[currenttarget]) {
				IsLocked[currenttarget] = false;
				count++;
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Lock on \"%L\".", client, currenttarget);
				}
			}
			else {
				IsLocked[currenttarget] = true;
				count++;
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Lock on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Lock on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (!IsLocked[currenttarget]) {
				IsLocked[currenttarget] = true;
				count++;
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Lock on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Lock on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (int i = 0; i < numtargets; i++) {
			int currenttarget = target[i];
			if (IsLocked[currenttarget]) {
				IsLocked[currenttarget] = false;
				count++;
				if (cvar_logging.IntValue >= 3 || (cvar_logging.IntValue > 0 && numtargets == 1)) {
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
			if (cvar_logging.IntValue > 0 && cvar_logging.IntValue < 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Lock on %s.", client, target_name);
			}
			else if (cvar_logging.IntValue >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		}
		else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Lock on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

public void OnPlayerSpawned(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (RFETRIZ[client] || (IsLocked[client] && IsFriendly[client])) {
		CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
		RequestedChange[client] = false;
		RFETRIZ[client] = false;
		// Inventory_App should take care of things from here
	}
	else if (RequestedChange[client]) {
		if (IsFriendly[client]) {
			MakeClientHostile(client);
			if (cvar_logging.IntValue >= 2) {
				LogAction(client, -1, "\"%L\" deactivated Friendly mode on spawn.", client);
			}
			CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
		}
		else {
			if (FriendlyPlayerCount < cvar_maxfriendlies.IntValue) {
				MakeClientFriendly(client);
				CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
				if (cvar_logging.IntValue >= 2) {
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
			if (cvar_remember.IntValue) {
				CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
				RequestedChange[client] = false;
				// Inventory_App should take care of things from here
			}
			else {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You have been taken out of Friendly mode because you respawned.", CHAT_PREFIX);
				if (cvar_logging.IntValue >= 2) {
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

public Action UseAdminCmd2(int client, int args) {
	if (CheckCommandAccess(client, "sm_friendly_admin", ADMFLAG_BAN)) {
		UseAdminCmd(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action UseLockCmd2(int client, int args) {
	if (CheckCommandAccess(client, "sm_friendly_lock", ADMFLAG_BAN)) {
		UseLockCmd(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnClientCommand(int client, int args) {
	AfkTime[client] = 0.0;
	return Plugin_Continue;
}

public Action OnClientSpeaks(int client, const char[] strCommand, int iArgs) {
	AfkTime[client] = 0.0;
	return Plugin_Continue;
}
	
public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	//SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientDisconnect_Post(int client) {
	if (IsFriendly[client]) {
		FriendlyPlayerCount--;
	}
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	IsAdmin[client] = false;
	IsLocked[client] = false;
	RFETRIZ[client] = false;
	IsInSpawn[client] = false;
	ToggleTimer[client] = 0.0;
	AfkTime[client] = 0.0;
	p_lastbtnstate[client] = 0;
}

void MakeClientHostile(const int client) {

	float time = GetEngineTime();
	ToggleTimer[client] = time + cvar_delay.FloatValue;

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
	if (cvar_invuln_p.IntValue < 2) {
		ApplyInvuln(client, INVULNMODE_MORTAL);
	}
	if (cvar_notarget_p.IntValue > 0) {
		SetNotarget(client, false);
	}
	if (cvar_noblock_p.IntValue > 0) {
		ApplyNoblock(client, true);
	}
	if (cvar_alpha_p.IntValue > -1) {
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, _);
	}
	if (cvar_alpha_w.IntValue > -1) {
		SetWearableInvis(client, false);
	}
	if (cvar_alpha_wep.IntValue > -1) {
		SetWeaponInvis(client, false);
	}
	/* if (cvar_botignore.BoolValue) {
		SetBotIgnore(client, false);
	} */

	if (GetForwardFunctionCount(hfwd_HostilePost) > 0) {
		Call_StartForward(hfwd_HostilePost);
		Call_PushCell(client);
		Call_Finish();
	}
}

void MakeClientFriendly(const int client) {

	float time = GetEngineTime();
	ToggleTimer[client] = time + cvar_delay.FloatValue;

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
	if (cvar_stopintel.BoolValue && !IsAdmin[client]) {
		FakeClientCommand(client, "dropitem");
	}

	if (GetForwardFunctionCount(hfwd_FriendlyPost) > 0) {
		Call_StartForward(hfwd_FriendlyPost);
		Call_PushCell(client);
		Call_Finish();
	}


}

public void Inventory_App(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFriendly[client]) {
		ReapplyFriendly(client);
	}
}

void ReapplyFriendly(const int client) {

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
	if (cvar_invuln_p.IntValue == 0) {
		ApplyInvuln(client, INVULNMODE_GOD);
	}
	if (cvar_invuln_p.IntValue == 1) {
		ApplyInvuln(client, INVULNMODE_BUDDHA);
	}
	if (cvar_notarget_p.IntValue > 0) {
		SetNotarget(client, true);
	}
	if (cvar_noblock_p.IntValue > 0) {
		ApplyNoblock(client, false);
	}
	if (cvar_alpha_p.IntValue > -1) {
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, _, _, _, cvar_alpha_p.IntValue);
	}
	if (cvar_alpha_w.IntValue > -1) {
		SetWearableInvis(client);
	}
	if (cvar_alpha_wep.IntValue > -1) {
		SetWeaponInvis(client);
	}
	/* if (cvar_botignore.BoolValue) {
		SetBotIgnore(client, true);
	} */

	if (GetForwardFunctionCount(hfwd_RefreshPost) > 0) {
		Call_StartForward(hfwd_RefreshPost);
		Call_PushCell(client);
		Call_Finish();
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if (!IsValidClient(attacker) || (client == attacker && cvar_invuln_p.IntValue != 3)) {
		return Plugin_Continue;
	}
	if ((IsFriendly[attacker] || IsFriendly[client]) && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void ApplyNoblock(int entity, bool remove) {
	int cvarValue;
	int normalValue;
	if (IsValidClient(entity, VCLIENT_INDEX)) {
		cvarValue = cvar_noblock_p.IntValue;
		normalValue = 5;
	}
	else {
		char classname[64];
		if (!GetEntityClassname(entity, classname, sizeof(classname))) {
			return;
		}
		else if (StrEqual(classname, "obj_sentrygun")) {
			cvarValue = cvar_noblock_s.IntValue;
			normalValue = 21;
		}
		else if (StrEqual(classname, "obj_dispenser")) {
			cvarValue = cvar_noblock_d.IntValue;
			normalValue = 21;
		}
		else if (StrEqual(classname, "obj_teleporter")) {
			cvarValue = cvar_noblock_t.IntValue;
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

void ApplyInvuln(int entity, f_invulnmode mode) {
	SetEntProp(entity, Prop_Data, "m_takedamage", mode, 1);
}


void SetNotarget(int ent, bool apply) {
	int flags;
	if (apply) {
		flags = GetEntityFlags(ent)|FL_NOTARGET;
	}
	else {
		flags = GetEntityFlags(ent)&~FL_NOTARGET;
	}
	SetEntityFlags(ent, flags);
}

/* SetBotIgnore(int client, bool apply) {
	if (apply) {
		TF2_AddCondition(client, TFCond_StealthedUserBuffFade, -1.0);
	}
	else {
		TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade);
	}
}
public void TF2_OnConditionRemoved(int client, TFCond condition) {
	if (cvar_botignore && IsFriendly[client] && condition == TFCond_StealthedUserBuffFade) {
		SetBotIgnore(client, true);
	}
} */


public Action Player_AFKCheck(Handle htimer) {
	if (cvar_afklimit.FloatValue > 0) {
		for (int client = 1; client <= MaxClients; client++) {
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
				if (cvar_afklimit.FloatValue && (AfkTime[client] += cvar_afkinterval.FloatValue) > cvar_afklimit.FloatValue) {
					AfkTime[client] = 0.0;
					MakeClientHostile(client);
					KillPlayer(client);
					CPrintToChat(client, "%s You have been removed from Friendly mode for being AFK too long.", CHAT_PREFIX);
					if (cvar_logging.IntValue >= 2) {
						LogAction(-1, -1, "\"%L\" was removed from Friendly Mode for being AFK too long.", client);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void RestartAFKTimer() {
	if (h_timer_afkcheck != INVALID_HANDLE) {
		KillTimer(h_timer_afkcheck);
		h_timer_afkcheck = INVALID_HANDLE;
	}
	for (int client = 1; client <= MaxClients; client++) {
		AfkTime[client] = 0.0;
	}
	h_timer_afkcheck = CreateTimer(cvar_afkinterval.FloatValue, Player_AFKCheck, INVALID_HANDLE, TIMER_REPEAT);
}

void DestroyStickies(const int client) {
    int sticky = -1;
    while ((sticky = FindEntityByClassname(sticky, "tf_projectile_pipe_remote"))!=INVALID_ENT_REFERENCE) {
        if (!IsValidEntity(sticky)) {
            continue;
        }
        if (GetEntPropEnt(sticky, Prop_Send, "m_hThrower") == client) {
            AcceptEntityInput(sticky, "Kill");
        }
    }
}

void MakeStickiesFriendly(const int client) {
	int sticky = -1;
	while ((sticky = FindEntityByClassname(sticky, "tf_projectile_pipe_remote"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sticky) && (GetEntPropEnt(sticky, Prop_Send, "m_hThrower") == client)) {
			if (cvar_alpha_proj.IntValue >= 0 && cvar_alpha_proj.IntValue <= 255) {	
				SetEntityRenderMode(sticky, RENDER_TRANSALPHA);
				SetEntityRenderColor(sticky, _, _, _, cvar_alpha_proj.IntValue);
			}
		}
	}
}

void KillPlayer(const int client) {
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
public Action ForceRespawnImmortalPlayer(Handle timer, any userid) {
	int client = GetClientOfUserId(userid);
	if (client == 0) {
		return;
	}
	if (IsPlayerAlive(client)) { TF2_RespawnPlayer(client); }
}

public void OnPluginEnd() {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsFriendly[client]) {
			CPrintToChat(client, "%s Plugin has been unloaded or restarted.", CHAT_PREFIX);
			MakeClientHostile(client);
			if (IsAdmin[client]) { continue; }
			int action;
			if (IsInSpawn[client]) {
				action = cvar_action_h_spawn.IntValue;
			}
			else {
				action = cvar_action_h.IntValue;
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

public void Airblast(Handle event, char[] name, bool dontBroadcast) {
	int pyro = GetClientOfUserId(GetEventInt(event, "userid"));
	int pitcher = GetClientOfUserId(GetEventInt(event, "ownerid"));
	//int weaponid = GetEventInt(event, "weaponid");
	int entity = GetEventInt(event, "object_entindex");
	if (!IsValidClient(pyro) || !IsValidClient(pitcher) || !IsValidEntity(entity)) {
		return;
	}
	char classname[64];
	if (!GetEntityClassname(entity, classname, sizeof(classname))) {
		return;
	}
	if (!(StrEqual(classname, "tf_projectile_pipe_remote") || StrEqual(classname, "player"))) {
		if (IsFriendly[pitcher] && !IsFriendly[pyro] && cvar_airblastkill.BoolValue) {
			AcceptEntityInput(entity, "Kill");
		}
	}
}

/* public Action Hook_SetTransmit(int entity, int client) {
	if (cvar_settransmit.IntValue == 0 || !IsValidClient(entity) || !IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (cvar_settransmit.IntValue > 0 && !IsFriendly[client] && IsFriendly[entity]) {
		return Plugin_Handled;
	}
	if (cvar_settransmit.IntValue == 2 && IsFriendly[client] && !IsFriendly[entity]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
} */

public void OnEntityCreated(int entity, const char[] classname) {
	if (cvar_ammopack.BoolValue) {
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
	if (cvar_healthpack.BoolValue) {
		if (StrContains(classname, "item_healthkit_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnHealthPackTouch);
			SDKHook(entity, SDKHook_Touch, OnHealthPackTouch);
		}
	}
	if (cvar_money.BoolValue) {
		if (StrContains(classname, "item_currencypack_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnMoneyTouch);
			SDKHook(entity, SDKHook_Touch, OnMoneyTouch);
		}
	}
	if (cvar_spellbook.BoolValue) {
		if (StrContains(classname, "tf_spell_pickup", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnSpellTouch);
			SDKHook(entity, SDKHook_Touch, OnSpellTouch);
		}
	}
	if (cvar_stopcap.BoolValue) {
		if (StrEqual(classname, "trigger_capture_area", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnCPTouch );
			SDKHook(entity, SDKHook_Touch, OnCPTouch );
		}
	}
	if (cvar_stopintel.BoolValue) {
		if (StrEqual(classname, "item_teamflag", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnFlagTouch );
			SDKHook(entity, SDKHook_Touch, OnFlagTouch );
		}
	}
	if (cvar_pumpkin.BoolValue) {
		if (StrEqual(classname, "tf_pumpkin_bomb", false)) {
			SDKHook(entity, SDKHook_OnTakeDamage, PumpkinTakeDamage);
		}
	}
	if (StrEqual(classname, "tf_projectile_pipe_remote", false)) {
		SDKHook(entity, SDKHook_OnTakeDamage, StickyTakeDamage);
	}
	if (cvar_funcbutton.BoolValue) {
		if (StrEqual(classname, "func_button", false)) {
			SDKHook(entity, SDKHook_OnTakeDamage, ButtonTakeDamage);
			SDKHook(entity, SDKHook_Use, ButtonUsed);
		}
	}
	if (StrEqual(classname, "func_respawnroom", false)) {
		SDKHook(entity, SDKHook_Touch, SpawnTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
	}
	if (cvar_notarget_p.IntValue > 1) {
		if (StrEqual(classname, "func_regenerate", false)) {
			SDKHook(entity, SDKHook_StartTouch, CabinetStartTouch);
			SDKHook(entity, SDKHook_EndTouch, CabinetEndTouch);
			if (cvar_notarget_p.IntValue == 3) {
				SDKHook(entity, SDKHook_Touch, CabinetTouch);
			}
		}
	}
	/* if (cvar_settransmit.IntValue > 0) {
		if (StrEqual(classname, "tf_weapon_minigun", false)) {
			int flags = GetEdictFlags(entity)|FL_EDICT_FULLCHECK;
			flags = flags|FL_EDICT_DONTSEND;
			SetEdictFlags(entity, flags);
		}
	} */
	if (cvar_alpha_proj.IntValue >= 0 && cvar_alpha_proj.IntValue <= 255) {
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

public void OnProjectileSpawned(int projectile) {
	int client = GetEntPropEnt(projectile, Prop_Data, "m_hOwnerEntity");
	if (!IsValidClient(client)) {
		return;
	}
	if (IsFriendly[client]) {
		SetEntityRenderMode(projectile, RENDER_TRANSALPHA);
		SetEntityRenderColor(projectile, _, _, _, cvar_alpha_proj.IntValue);
	}
}

public void OnAmmoPackSpawned(int entity) {
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (!IsValidClient(client)) {
		return;
	}
	if (IsFriendly[client] && cvar_ammopack.BoolValue) {
		AcceptEntityInput(entity, "Kill");
	}
}

void HookThings() {
	int ent = -1;
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
	/* if (cvar_settransmit.IntValue > 0) {
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_weapon_minigun")) != -1) {
			int flags = GetEdictFlags(ent)|FL_EDICT_FULLCHECK;
			flags = flags|FL_EDICT_DONTSEND;
			SetEdictFlags(ent, flags);
		}
	} */
}

public Action CabinetStartTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_notarget_p.IntValue > 1) {
		SetNotarget(client, false);
	}
	return Plugin_Continue;
}

public Action CabinetTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_notarget_p.IntValue == 3) {
		SetNotarget(client, false);
	}
	return Plugin_Continue;
}

public Action CabinetEndTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_notarget_p.IntValue > 1) {
		SetNotarget(client, true);
	}
	return Plugin_Continue;
}

public Action OnCPTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_stopcap.BoolValue && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result) {
	if (cvar_usetele.IntValue == 0 || !IsValidClient(client)) {
		return Plugin_Continue;
	}
	int engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
	if (engie == client || !IsValidClient(engie)) {
		return Plugin_Continue;
	}
	if (cvar_usetele.IntValue & 1 && IsFriendly[client] && !IsFriendly[engie]) {
		result = false;
		return Plugin_Handled;
	}
	if (cvar_usetele.IntValue & 2 && !IsFriendly[client] && IsFriendly[engie]) {
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnFlagTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_stopintel.BoolValue && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnHealthPackTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_healthpack.BoolValue && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnAmmoPackTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_ammopack.BoolValue && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnMoneyTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_money.BoolValue && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnSpellTouch(int point, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (IsFriendly[client] && cvar_spellbook.BoolValue && !IsAdmin[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action PumpkinTakeDamage(int pumpkin, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if (IsFriendly[attacker] && cvar_pumpkin.BoolValue && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action ButtonTakeDamage(int button, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if (IsFriendly[attacker] && cvar_funcbutton.BoolValue && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action ButtonUsed(int entity, int activator, int caller, UseType type, float value) {
	if (!IsValidClient(activator)) {
		return Plugin_Continue;
	}
	if (IsFriendly[activator] && cvar_funcbutton.BoolValue && !IsAdmin[activator]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action StickyTakeDamage(int sticky, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if ((IsFriendly[attacker]) && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	int demoman = GetEntPropEnt(sticky, Prop_Send, "m_hThrower");
	if (!IsValidClient(demoman)) {
		return Plugin_Continue;
	}
	if (IsFriendly[demoman]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action SpawnTouch(int spawn, int client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	if (GetEntProp(spawn, Prop_Send, "m_iTeamNum") == GetClientTeam(client)) {
		IsInSpawn[client] = true;
	}
	return Plugin_Continue;
}

public Action SpawnEndTouch(int spawn, int client) {
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

public Action Object_Built(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	int building = GetEventInt(event, "index");
	SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
	if (IsFriendly[client]) {
		int buildtype = GetEventInt(event, "object"); //dispenser 0, tele 1, sentry 2
		if (buildtype == 2) {
			if (cvar_nobuild_s.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build sentries while Friendly!", CHAT_PREFIX);
			}
			else {
				if (cvar_invuln_s.IntValue == 2) {
					ApplyInvuln(building, INVULNMODE_GOD);
				}
				if (cvar_noblock_s.IntValue > 0) {
					ApplyNoblock(building, false);
				}
				if (cvar_notarget_s.BoolValue) {
					SetNotarget(building, true);
				}
				if (cvar_alpha_s.IntValue > -1) {
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, cvar_alpha_s.IntValue);
				}
			}
		}
		else if (buildtype == 0) {
			if (cvar_nobuild_d.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build dispensers while Friendly!", CHAT_PREFIX);
			}
			else {
				if (cvar_invuln_d.IntValue == 2) {
					ApplyInvuln(building, INVULNMODE_GOD);
				}
				if (cvar_noblock_d.IntValue > 0) {
					ApplyNoblock(building, false);
				}
				if (cvar_notarget_d.BoolValue) {
					SetNotarget(building, true);
				}
				if (cvar_alpha_d.IntValue > -1) {	
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, cvar_alpha_d.IntValue);
				}
			}
		}
		else if (buildtype == 1) {
			if (cvar_nobuild_t.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build teleporters while Friendly!", CHAT_PREFIX);
			}
			else {
				if (cvar_invuln_t.IntValue == 2) {
					ApplyInvuln(building, INVULNMODE_GOD);
				}
				if (cvar_noblock_t.IntValue > 0) {
					ApplyNoblock(building, false);
				}
				if (cvar_notarget_t.BoolValue) {
					SetNotarget(building, true);
				}
				if (cvar_alpha_t.IntValue > -1) {	
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, cvar_alpha_t.IntValue);
				}
			}
		}
	}
	return Plugin_Continue;
}

void MakeBuildingsFriendly(const int client) {
	int sentrygun = -1;
	int dispenser = -1;
	int teleporter = -1;
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sentrygun) && (GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_f_s.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(sentrygun, "Kill");
			}
			else {
				if (cvar_invuln_s.IntValue == 1) {
					RemoveActiveSapper(sentrygun, false);
				}
				else if (cvar_invuln_s.IntValue == 2) {
					ApplyInvuln(sentrygun, INVULNMODE_GOD);
					RemoveActiveSapper(sentrygun, true);
				}
				if (cvar_noblock_s.IntValue > 0) {
					ApplyNoblock(sentrygun, false);
				}
				if (cvar_notarget_s.BoolValue) {
					SetNotarget(sentrygun, true);
				}
				if (cvar_alpha_s.IntValue > -1) {	
					SetEntityRenderMode(sentrygun, RENDER_TRANSALPHA);
					SetEntityRenderColor(sentrygun, _, _, _, cvar_alpha_s.IntValue);
				}
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(dispenser) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_f_d.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(dispenser, "Kill");
			}
			else {
				if (cvar_invuln_d.IntValue == 1) {
					RemoveActiveSapper(dispenser, false);
				}
				else if (cvar_invuln_d.IntValue == 2) {
					ApplyInvuln(dispenser, INVULNMODE_GOD);
					RemoveActiveSapper(dispenser, true);
				}
				if (cvar_noblock_d.IntValue > 0) {
					ApplyNoblock(dispenser, false);
				}
				if (cvar_notarget_d.BoolValue) {
					SetNotarget(dispenser, true);
				}
				if (cvar_alpha_d.IntValue > -1) {	
					SetEntityRenderMode(dispenser, RENDER_TRANSALPHA);
					SetEntityRenderColor(dispenser, _, _, _, cvar_alpha_d.IntValue);
				}
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(teleporter) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_f_t.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(teleporter, "Kill");
			}
			else {
				if (cvar_invuln_t.IntValue == 1) {
					RemoveActiveSapper(teleporter, false);
				}
				else if (cvar_invuln_t.IntValue == 2) {
					ApplyInvuln(teleporter, INVULNMODE_GOD);
					RemoveActiveSapper(teleporter, true);
				}
				if (cvar_noblock_t.IntValue > 0) {
					ApplyNoblock(teleporter, false);
				}
				if (cvar_notarget_t.BoolValue) {
					SetNotarget(teleporter, true);
				}
				if (cvar_alpha_t.IntValue > -1) {	
					SetEntityRenderMode(teleporter, RENDER_TRANSALPHA);
					SetEntityRenderColor(teleporter, _, _, _, cvar_alpha_t.IntValue);
				}
			}
		}
	}
}


void MakeBuildingsHostile(const int client) {
	int sentrygun = -1;
	int dispenser = -1;
	int teleporter = -1;
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sentrygun) && (GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_h_s.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(sentrygun, "Kill");
			}
			else {
				if (cvar_invuln_s.IntValue == 2) {
					ApplyInvuln(sentrygun, INVULNMODE_MORTAL);
				}
				if (cvar_noblock_s.IntValue > 0) {
					ApplyNoblock(sentrygun, true);
				}
				if (cvar_notarget_s.BoolValue) {
					SetNotarget(sentrygun, false);
				}
				if (cvar_alpha_s.IntValue != -1) {	
					SetEntityRenderMode(sentrygun, RENDER_NORMAL);
					SetEntityRenderColor(sentrygun, _, _, _, _);
				}
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(dispenser) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_h_d.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(dispenser, "Kill");
			}
			else {
				if (cvar_invuln_d.IntValue == 2) {
					ApplyInvuln(dispenser, INVULNMODE_MORTAL);
				}
				if (cvar_noblock_d.IntValue > 0) {
					ApplyNoblock(dispenser, true);
				}
				if (cvar_notarget_d.BoolValue) {
					SetNotarget(dispenser, false);
				}
				if (cvar_alpha_d.IntValue != -1) {	
					SetEntityRenderMode(dispenser, RENDER_NORMAL);
					SetEntityRenderColor(dispenser, _, _, _, _);
				}
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(teleporter) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_h_t.BoolValue && !IsAdmin[client]) {
				AcceptEntityInput(teleporter, "Kill");
			}
			else {
				if (cvar_invuln_t.IntValue == 2) {
					ApplyInvuln(teleporter, INVULNMODE_MORTAL);
				}
				if (cvar_noblock_t.IntValue > 0) {
					ApplyNoblock(teleporter, true);
				}
				if (cvar_notarget_t.BoolValue) {
					SetNotarget(teleporter, false);
				}
				if (cvar_alpha_t.IntValue != -1) {	
					SetEntityRenderMode(teleporter, RENDER_NORMAL);
					SetEntityRenderColor(teleporter, _, _, _, _);
				}
			}
		}
	}
}

public Action BuildingTakeDamage(int building, int &attacker, int &inflictor, float &damage, int &damagetype) {
	int engie = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	char classname[64];
	if (!GetEntityClassname(building, classname, sizeof(classname))) {
		return Plugin_Continue;
	}
	if (!IsValidClient(attacker) || !IsValidClient(engie)) {
		return Plugin_Continue;
	}
	if (!IsAdmin[attacker]) {
		if (StrEqual(classname, "obj_sentrygun", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_s.IntValue > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		else if (StrEqual(classname, "obj_dispenser", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_d.IntValue > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		else if (StrEqual(classname, "obj_teleporter", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_t.IntValue > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action Object_Sapped(Handle event, const char[] name, bool dontBroadcast) {
	int spy = GetClientOfUserId(GetEventInt(event, "userid"));
	int sapper = GetEventInt(event, "sapperid");
	if (IsFriendly[spy] && !IsAdmin[spy]) {
		AcceptEntityInput(sapper, "Kill");
		return Plugin_Continue;
	}
	int engie = GetClientOfUserId(GetEventInt(event, "ownerid"));
	int building = GetEventInt(event, "object"); //dispenser 0, tele 1, sentry 2
	if (IsFriendly[engie]) {
		if (building == 0) {
			if (cvar_invuln_d.IntValue == 2 || (cvar_invuln_d.IntValue == 1 && !IsAdmin[spy])) {
				AcceptEntityInput(sapper, "Kill");
			}
			else if (cvar_invuln_d.IntValue == 0 || (cvar_invuln_d.IntValue == 1 && IsAdmin[spy])) {
				SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
			}
		}
		else if (building == 1) {
			if (cvar_invuln_t.IntValue == 2 || (cvar_invuln_t.IntValue == 1 && !IsAdmin[spy])) {
				AcceptEntityInput(sapper, "Kill");
			}
			else if (cvar_invuln_t.IntValue == 0 || (cvar_invuln_t.IntValue == 1 && IsAdmin[spy])) {
				SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
			}
		}
		else if (building == 2) {
			if (cvar_invuln_s.IntValue == 2 || (cvar_invuln_s.IntValue == 1 && !IsAdmin[spy])) {
				AcceptEntityInput(sapper, "Kill");
			}
			else if (cvar_invuln_s.IntValue == 0 || (cvar_invuln_s.IntValue == 1 && IsAdmin[spy])) {
				SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
			}
		}
	}
	else {
		SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
	}
	return Plugin_Continue;
}

public Action SapperTakeDamage(int sapper, int &attacker, int &inflictor, float &damage, int &damagetype) {
	int homewrecker = attacker;
	int building = GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity");
	int engie = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	if (!IsAdmin[homewrecker] && IsFriendly[homewrecker] && !IsFriendly[engie]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void RemoveActiveSapper(int building, bool ignoreadmin) {
	int sapper = -1;
	while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sapper) && (GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity") == building)) {
			int spy = GetEntPropEnt(sapper, Prop_Send, "m_hBuilder");
			if (ignoreadmin || !IsAdmin[spy]) {
				AcceptEntityInput(sapper, "Kill");
			}
		}
	}	
}

public void RemoveMySappers(int client) {
	if (!IsAdmin[client]) {
		int sapper = -1;
		while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(sapper) && GetEntPropEnt(sapper, Prop_Send, "m_hBuilder") == client) {
				AcceptEntityInput(sapper, "Kill");
			}
		}
	}
}

public Action Hook_NormalSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) {
	char classname[23];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrEqual(classname, "obj_attachment_sapper")) {
		if (!IsValidEntity(GetEntPropEnt(entity, Prop_Send, "m_hBuiltOnEntity"))) {
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
The following code was borrowed from FlaminSarge's Ghost Mode plugin: forums.alliedmods.net/showthread.php?t=183266
This code makes wearables change alpha if sm_friendly_alpha_w is higher than -1 */

stock void SetWearableInvis(int client, bool set = true) {
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1) {
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? cvar_alpha_w.IntValue : 255);
		}
	}
	i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable_demoshield")) != -1) {
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? cvar_alpha_w.IntValue : 255);
		}
	}
	while ((i = FindEntityByClassname(i, "tf_powerup_bottle")) != -1) {
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? cvar_alpha_w.IntValue : 255);
		}
	}
}


stock void SetWeaponInvis(int client, bool set = true) {
	for (int i = 0; i < 5; i++) {
		int entity = GetPlayerWeaponSlot(client, i);
		if (entity != -1) {
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, _, _, _, set ? cvar_alpha_wep.IntValue : 255);
		}
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Goomba Stomp Integration */

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower) {
	if ((IsFriendly[attacker] || IsFriendly[victim]) && !IsAdmin[attacker] && cvar_goomba.BoolValue) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
RTD Integration */

public Action RTD_CanRollDice(int client) {
	if (IsFriendly[client] && !IsAdmin[client] && cvar_blockrtd.BoolValue) {
		CPrintToChat(client, "%s You cannot RTD while Friendly!", CHAT_PREFIX);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Begin code relevant to weaponblocker and tauntblocker */

public Action OnWeaponSwitch(int client, int weapon) {
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

stock bool IsWeaponBlocked(int weapon) {
	char weaponClass[64];
	if (!GetEntityClassname(weapon, weaponClass, sizeof(weaponClass))) {
		return false;
	}
	int weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	bool blocked = false;
	for (int i = 0; i < sizeof(g_blockweps_classes) && !blocked && !StrEqual(g_blockweps_classes[i], "-1"); i++) {
		if (StrEqual(g_blockweps_classes[i], weaponClass)) {
			blocked = true;
		}
	}
	if (blocked) {
		for (int i = 0; i < sizeof(g_blockweps_white) && g_blockweps_white[i] != -1; i++) {
			if (g_blockweps_white[i] == weaponIndex) {
				return false;
			}
		}
		return true;
	}
	else {
		for (int i = 0; i < sizeof(g_blockweps_black) && g_blockweps_black[i] != -1; i++) {
			if (g_blockweps_black[i] == weaponIndex) {
				return true;
			}
		}
		return false;
	}
}

public Action TauntCmd(int client, const char[] strCommand, int iArgs) {
	if (IsFriendly[client] && !IsAdmin[client]) {
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(weapon)) {
			int weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			for (int i = 0; i < sizeof(g_blocktaunt) && g_blocktaunt[i] != -1; i++) {
				if (g_blocktaunt[i] == weaponIndex) {
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}


void ForceWeaponSwitches(const int client) {
	if (!IsPlayerAlive(client) || IsAdmin[client]) {
		return;
	}
	int curwep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(curwep) || !IsWeaponBlocked(curwep)) {
		return;
	}
	
	if (g_minigunoffsetstate > 0) {
		char curwepclass[32];
		GetEntityClassname(curwep, curwepclass, sizeof(curwepclass));
		if (StrEqual(curwepclass, "tf_weapon_minigun")) {
			SetEntData(curwep, g_minigunoffsetstate, 0);
			if (TF2_IsPlayerInCondition(client, TFCond_Slowed)) {
				TF2_RemoveCondition(client, TFCond_Slowed);
			}
		}
	}
	
	for (int i = 0; i <= 5; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
		if (!IsValidEdict(weapon)) {
			continue;
		}
		if (curwep == weapon) {
			continue;
		}
		if (IsWeaponBlocked(weapon)) {
			continue;
		}
		char classname[64];
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
	for (int i = 0; i <= 5; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
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

public bool TargetFriendlies(const char[] pattern, Handle clients) {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsFriendly[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool TargetHostiles(const char[] pattern, Handle clients) {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && !IsFriendly[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool TargetFriendlyAdmins(const char[] pattern, Handle clients) {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsAdmin[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool TargetFriendlyNonAdmins(const char[] pattern, Handle clients) {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && !IsAdmin[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool TargetFriendlyLocked(const char[] pattern, Handle clients) {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsLocked[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}
public bool TargetFriendlyUnlocked(const char[] pattern, Handle clients) {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client) && !IsLocked[client]) {
			PushArrayCell(clients, client);
		}
	}
	return true;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Natives */

public int Native_CheckIfFriendly(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
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

public int Native_CheckIfFriendlyLocked(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
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

public int Native_CheckIfFriendlyAdmin(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
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

public int Native_SetFriendly(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int direction = GetNativeCell(2);
	int action = GetNativeCell(3);
	
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
			if (!cvar_remember.BoolValue) {
				RFETRIZ[client] = true;
			}
		}
		else if (action > 0 && IsPlayerAlive(client)) {
			SlapPlayer(client, action);
			if (!IsPlayerAlive(client)) {
				if (!cvar_remember.BoolValue) {
					RFETRIZ[client] = true;
				}
				return 3;
			}
			
		}
		return 1;
	}
	return -4;
}

public int Native_SetFriendlyLock(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int direction = GetNativeCell(2);
	
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

public int Native_SetFriendlyAdmin(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int direction = GetNativeCell(2);
	
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

public int Native_RefreshFriendly(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
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

public int Native_CheckPluginEnabled(Handle plugin, int numParams) {
	return cvar_enabled.BoolValue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Begin code relevant to caching convars */

public void cvarChange(Handle hHandle, const char[] strOldValue, const char[] strNewValue) {
	if (hHandle == cvar_enabled || hHandle == INVALID_HANDLE) {
		static bool oldValue;
		if (hHandle != INVALID_HANDLE) {
			if (cvar_enabled.BoolValue && !oldValue) {
				if (GetForwardFunctionCount(hfwd_FriendlyEnable) > 0) {
					Call_StartForward(hfwd_FriendlyEnable);
					Call_Finish();
				}
				if (cvar_logging.IntValue > 0) {
					LogAction(-1, -1, "Friendly mode plugin was enabled.");
				}
				CPrintToChatAll("%s An admin has re-enabled Friendly Mode. Type {olive}/friendly{default} to use.", CHAT_PREFIX);
			}
			else if (!cvar_enabled.BoolValue && oldValue) {
				if (cvar_logging.IntValue > 0) {
					LogAction(-1, -1, "Friendly mode plugin was disabled. All players forced out of Friendly mode.");
				}
				CPrintToChatAll("%s An admin has disabled Friendly Mode.", CHAT_PREFIX);
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						MakeClientHostile(client);
						if (!IsAdmin[client]) {
							int action;
							if (IsInSpawn[client]) {
								action = cvar_action_h_spawn.IntValue;
							}
							else {
								action = cvar_action_h.IntValue;
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
		oldValue = cvar_enabled.BoolValue;
	}
	if (hHandle == cvar_afklimit || hHandle == cvar_afkinterval || hHandle == INVALID_HANDLE) {
		RestartAFKTimer();
	}
	/* if (hHandle == cvar_botignore || hHandle == INVALID_HANDLE) {
		bool oldValue = cvar_botignore;
		cvar_botignore = GetConVarBool(cvar_botignore);
		if (hHandle != INVALID_HANDLE) {
			if (cvar_botignore && !oldValue) {
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						SetBotIgnore(client, true);
					}
				}
			}
			else if (!cvar_botignore && oldValue) {
				for (int client = 1; client <= MaxClients; client++) {
					if (IsClientInGame(client) && IsFriendly[client]) {
						SetBotIgnore(client, false);
					}
				}
			}
		}
	} */
	if (hHandle == cvar_stopcap || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_stopcap.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_StartTouch, OnCPTouch);
				SDKUnhook(ent, SDKHook_Touch, OnCPTouch);
				SDKHook(ent, SDKHook_StartTouch, OnCPTouch);
				SDKHook(ent, SDKHook_Touch, OnCPTouch);
			}
		}
		else {
			while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_StartTouch, OnCPTouch);
				SDKUnhook(ent, SDKHook_Touch, OnCPTouch);
			}
		}
	}
	if (hHandle == cvar_stopintel || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_stopintel.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_StartTouch, OnFlagTouch );
				SDKUnhook(ent, SDKHook_Touch, OnFlagTouch );
				SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
				SDKHook(ent, SDKHook_Touch, OnFlagTouch );
			}
		}
		else {
			while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_StartTouch, OnFlagTouch );
				SDKUnhook(ent, SDKHook_Touch, OnFlagTouch );
			}
		}
	}
	if (hHandle == cvar_ammopack || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_ammopack.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "item_ammopack_medium")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "item_ammopack_small")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_ammo_pack")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_projectile_stun_ball")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
				SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
			}
		}
		else {
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
	if (hHandle == cvar_healthpack || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_healthpack.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "item_healthkit_full")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnHealthPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnHealthPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
				SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "item_healthkit_medium")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnHealthPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnHealthPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
				SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "item_healthkit_small")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnHealthPackTouch);
				SDKUnhook(ent, SDKHook_Touch, OnHealthPackTouch);
				SDKHook(ent, SDKHook_StartTouch, OnHealthPackTouch);
				SDKHook(ent, SDKHook_Touch, OnHealthPackTouch);
			}
		}
		else {
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
	if (hHandle == cvar_money || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_money.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnMoneyTouch);
				SDKUnhook(ent, SDKHook_Touch, OnMoneyTouch);
				SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
				SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "item_currencypack_medium")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnMoneyTouch);
				SDKUnhook(ent, SDKHook_Touch, OnMoneyTouch);
				SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
				SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
			}
			ent = -1;
			while ((ent = FindEntityByClassname(ent, "item_currencypack_small")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnMoneyTouch);
				SDKUnhook(ent, SDKHook_Touch, OnMoneyTouch);
				SDKHook(ent, SDKHook_StartTouch, OnMoneyTouch);
				SDKHook(ent, SDKHook_Touch, OnMoneyTouch);
			}
		}
		else {
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
	if (hHandle == cvar_spellbook || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_spellbook.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnSpellTouch);
				SDKUnhook(ent, SDKHook_Touch, OnSpellTouch);
				SDKHook(ent, SDKHook_StartTouch, OnSpellTouch);
				SDKHook(ent, SDKHook_Touch, OnSpellTouch);
			}
		}
		else {
			while ((ent = FindEntityByClassname(ent, "item_currencypack_large")) != -1) {
				SDKUnhook(ent, SDKHook_StartTouch, OnSpellTouch);
				SDKUnhook(ent, SDKHook_Touch, OnSpellTouch);
			}
		}
	}
	if (hHandle == cvar_pumpkin || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_pumpkin.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
				SDKHook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
			}
		}
		else {
			while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
			}
		}
	}
	if (hHandle == cvar_funcbutton || hHandle == INVALID_HANDLE) {
		int ent = -1;
		if (cvar_funcbutton.BoolValue) {
			while ((ent = FindEntityByClassname(ent, "func_button"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
				SDKUnhook(ent, SDKHook_Use, ButtonUsed);
				SDKHook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
				SDKHook(ent, SDKHook_Use, ButtonUsed);
			}
		}
		else {
			while ((ent = FindEntityByClassname(ent, "func_button"))!=INVALID_ENT_REFERENCE) {
				SDKUnhook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
				SDKUnhook(ent, SDKHook_Use, ButtonUsed);
			}
		}
	}
	if (hHandle == cvar_invuln_p) {
		for (int client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsFriendly[client]) {
				switch (cvar_invuln_p.IntValue) {
					case 0: ApplyInvuln(client, INVULNMODE_GOD);
					case 1:ApplyInvuln(client, INVULNMODE_BUDDHA);
					default: ApplyInvuln(client, INVULNMODE_MORTAL);
				}
			}
		}
	}
	if (hHandle == cvar_invuln_s || hHandle == INVALID_HANDLE) {
		int sentry = -1;
		while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(sentry)) {
				int engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie)&& IsFriendly[engie]) {
					if (cvar_invuln_s.IntValue < 2) {
						ApplyInvuln(sentry, INVULNMODE_MORTAL);
						RemoveActiveSapper(sentry, false);
					}
					else if (cvar_invuln_s.IntValue == 2) {
						ApplyInvuln(sentry, INVULNMODE_GOD);
						RemoveActiveSapper(sentry, true);
					}
				}
			}
		}
	}
	if (hHandle == cvar_invuln_d || hHandle == INVALID_HANDLE) {
		int dispenser = -1;
		while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(dispenser)) {
				int engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					if (cvar_invuln_d.IntValue < 2) {
						ApplyInvuln(dispenser, INVULNMODE_MORTAL);
						RemoveActiveSapper(dispenser, false);
					}
					else if (cvar_invuln_d.IntValue == 2) {
						ApplyInvuln(dispenser, INVULNMODE_GOD);
						RemoveActiveSapper(dispenser, true);
					}
				}
			}
		}
	}
	if (hHandle == cvar_invuln_t || hHandle == INVALID_HANDLE) {
		int teleporter = -1;
		while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(teleporter)) {
				int engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					if (cvar_invuln_t.IntValue < 2) {
						ApplyInvuln(teleporter, INVULNMODE_MORTAL);
						RemoveActiveSapper(teleporter, false);
					}
					else if (cvar_invuln_t.IntValue == 2) {
						ApplyInvuln(teleporter, INVULNMODE_GOD);
						RemoveActiveSapper(teleporter, true);
					}
				}
			}
		}
	}
	if (hHandle == cvar_notarget_p || hHandle == INVALID_HANDLE) {
		for (int client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsFriendly[client]) {
				if (cvar_notarget_p.IntValue > 0) SetNotarget(client, true);
				else SetNotarget(client, false);
			}
		}
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "func_regenerate"))!=INVALID_ENT_REFERENCE) {
			SDKUnhook(entity, SDKHook_StartTouch, CabinetStartTouch);
			SDKUnhook(entity, SDKHook_EndTouch, CabinetEndTouch);
			SDKUnhook(entity, SDKHook_Touch, CabinetTouch);
			if (cvar_notarget_p.IntValue > 1) {
				SDKHook(entity, SDKHook_StartTouch, CabinetStartTouch);
				SDKHook(entity, SDKHook_EndTouch, CabinetEndTouch);
				if (cvar_notarget_p.IntValue == 3) {
					SDKHook(entity, SDKHook_Touch, CabinetTouch);
				}
			}
		}
	}
	if (hHandle == cvar_notarget_s) {
		int sentry = -1;
		while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(sentry)) {
				int engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					SetNotarget(sentry, cvar_notarget_s.BoolValue);
				}
			}
		}
	}
	if (hHandle == cvar_notarget_d) {
		int dispenser = -1;
		while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(dispenser)) {
				int engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					SetNotarget(dispenser, cvar_notarget_d.BoolValue);
				}
			}
		}
	}
	if (hHandle == cvar_notarget_t) {
		int teleporter = -1;
		while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(teleporter)) {
				int engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					SetNotarget(teleporter, cvar_notarget_t.BoolValue);
				}
			}
		}
	}
	if (hHandle == cvar_noblock_p) {
		for (int client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsFriendly[client]) {
				ApplyNoblock(client, (cvar_noblock_p.IntValue != 0));
			}
		}
	}
	if (hHandle == cvar_noblock_s) {
		int sentry = -1;
		while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(sentry)) {
				int engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					ApplyNoblock(sentry, (cvar_noblock_s.IntValue != 0));
				}
			}
		}
	}
	if (hHandle == cvar_noblock_d) {
		int dispenser = -1;
		while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(dispenser)) {
				int engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					ApplyNoblock(dispenser, (cvar_noblock_d.IntValue != 0));
				}
			}
		}
	}
	if (hHandle == cvar_noblock_t) {
		int teleporter = -1;
		while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(teleporter)) {
				int engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					ApplyNoblock(teleporter, (cvar_noblock_t.IntValue != 0));
				}
			}
		}
	}
	if (hHandle == cvar_alpha_p) {
		for (int client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsFriendly[client]) {
				if (cvar_alpha_p.IntValue >= 0 && cvar_alpha_p.IntValue <= 255) {
					SetEntityRenderMode(client, RENDER_TRANSALPHA);
					SetEntityRenderColor(client, _, _, _, cvar_alpha_p.IntValue);
				}
				else {
					SetEntityRenderMode(client, RENDER_NORMAL);
					SetEntityRenderColor(client, _, _, _, _);
				}
			}
		}
	}
	if (hHandle == cvar_alpha_w) {
		for (int client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsFriendly[client]) {
				if (cvar_alpha_w.IntValue >= 0 && cvar_alpha_w.IntValue <= 255)
					SetWearableInvis(client);
				else SetWearableInvis(client, false);
			}
		}
	}
	if (hHandle == cvar_alpha_wep) {
		for (int client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsFriendly[client]) {
				if (cvar_alpha_wep.IntValue >= 0 && cvar_alpha_wep.IntValue <= 255)
					SetWeaponInvis(client);
				else SetWeaponInvis(client, false);
			}
		}
	}
	if (hHandle == cvar_alpha_s) {
		int sentry = -1;
		while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(sentry)) {
				int engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					if (cvar_alpha_s.IntValue >= 0) {
						SetEntityRenderMode(sentry, RENDER_TRANSALPHA);
						SetEntityRenderColor(sentry, _, _, _, cvar_alpha_s.IntValue);
					}
					else {
						SetEntityRenderMode(sentry, RENDER_NORMAL);
						SetEntityRenderColor(sentry, _, _, _, _);
					}
				}
			}
		}
	}
	if (hHandle == cvar_alpha_d) {
		int dispenser = -1;
		while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(dispenser)) {
				int engie = GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					if (cvar_alpha_d.IntValue >= 0) {
						SetEntityRenderMode(dispenser, RENDER_TRANSALPHA);
						SetEntityRenderColor(dispenser, _, _, _, cvar_alpha_d.IntValue);
					}
					else {
						SetEntityRenderMode(dispenser, RENDER_NORMAL);
						SetEntityRenderColor(dispenser, _, _, _, _);
					}
				}
			}
		}
	}
	if (hHandle == cvar_alpha_t) {
		int teleporter = -1;
		while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
			if (IsValidEntity(teleporter)) {
				int engie = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
				if (IsValidClient(engie) && IsFriendly[engie]) {
					if (cvar_alpha_t.IntValue >= 0) {
						SetEntityRenderMode(teleporter, RENDER_TRANSALPHA);
						SetEntityRenderColor(teleporter, _, _, _, cvar_alpha_t.IntValue);
					}
					else {
						SetEntityRenderMode(teleporter, RENDER_NORMAL);
						SetEntityRenderColor(teleporter, _, _, _, _);
					}
				}
			}
		}
	}
	if (hHandle == cvar_blockweps_black || hHandle == INVALID_HANDLE) {
		char strWeaponsBlack[255];
		cvar_blockweps_black.GetString(strWeaponsBlack, sizeof(strWeaponsBlack));
		if (StrEqual(strWeaponsBlack, "-2")) {
			g_blockweps_black[0] = -1;
		}
		else {
			char strWeaponsBlack2[255][8];
			if (StrEqual(strWeaponsBlack, "-1")) {
				strWeaponsBlack = DEFAULT_BLOCKED_WEAPONS;
			}
			int numweps = ExplodeString(strWeaponsBlack, ",", strWeaponsBlack2, sizeof(strWeaponsBlack2), sizeof(strWeaponsBlack2[]));
			for (int i=0; i < sizeof(g_blockweps_black) && i < numweps; i++) {
				g_blockweps_black[i] = StringToInt(strWeaponsBlack2[i]);
			}
			g_blockweps_black[numweps] = -1;
		}
	}
	if (hHandle == cvar_blockweps_white || hHandle == INVALID_HANDLE) {
		char strWeaponsWhite[255];
		cvar_blockweps_white.GetString(strWeaponsWhite, sizeof(strWeaponsWhite));
		if (StrEqual(strWeaponsWhite, "-2")) {
			g_blockweps_white[0] = -1;
		}
		else {
			char strWeaponsWhite2[255][8];
			if (StrEqual(strWeaponsWhite, "-1")) {
				strWeaponsWhite = DEFAULT_WHITELISTED_WEAPONS;
			}
			int numweps = ExplodeString(strWeaponsWhite, ",", strWeaponsWhite2, sizeof(strWeaponsWhite2), sizeof(strWeaponsWhite2[]));
			for (int i=0; i < sizeof(g_blockweps_white) && i < numweps; i++) {
				g_blockweps_white[i] = StringToInt(strWeaponsWhite2[i]);
			}
			g_blockweps_white[numweps] = -1;
		}
	}
	if (hHandle == cvar_blockweps_classes || hHandle == INVALID_HANDLE) {
		char strWeaponsClass[256];
		cvar_blockweps_classes.GetString(strWeaponsClass, sizeof(strWeaponsClass));
		if (StrEqual(strWeaponsClass, "-2")) {
			g_blockweps_classes[0] = "-1";
		}
		else {
			if (StrEqual(strWeaponsClass, "-1")) {
				strWeaponsClass = DEFAULT_BLOCKED_WEAPONCLASSES;
			}
			int numclasses = ExplodeString(strWeaponsClass, ",", g_blockweps_classes, sizeof(g_blockweps_classes), sizeof(g_blockweps_classes[]));
			g_blockweps_classes[numclasses] = "-1";
		}
	}
	if (hHandle == cvar_blocktaunt || hHandle == INVALID_HANDLE) {
		char strWeaponsTaunt[255];
		cvar_blocktaunt.GetString(strWeaponsTaunt, sizeof(strWeaponsTaunt));
		if (StrEqual(strWeaponsTaunt, "-2")) {
			g_blocktaunt[0] = -1;
		}
		else {
			char strWeaponsTaunt2[255][8];
			if (StrEqual(strWeaponsTaunt, "-1")) {
				strWeaponsTaunt = DEFAULT_BLOCKED_TAUNTS;
			}
			int numweps = ExplodeString(strWeaponsTaunt, ",", strWeaponsTaunt2, sizeof(strWeaponsTaunt2), sizeof(strWeaponsTaunt2[]));
			for (int i=0; i < sizeof(g_blocktaunt) && i < numweps; i++) {
				g_blocktaunt[i] = StringToInt(strWeaponsTaunt2[i]);
			}
			g_blocktaunt[numweps] = -1;
		}
	}
	if (hHandle == INVALID_HANDLE) {
		HookCvars();
		HookThings();
	}
}

void HookCvars() {
	HookConVarChange(cvar_enabled, cvarChange);
	HookConVarChange(cvar_afklimit, cvarChange);
	HookConVarChange(cvar_afkinterval, cvarChange);
	//HookConVarChange(cvar_botignore, cvarChange);
	HookConVarChange(cvar_stopcap, cvarChange);
	HookConVarChange(cvar_stopintel, cvarChange);
	HookConVarChange(cvar_ammopack, cvarChange);
	HookConVarChange(cvar_healthpack, cvarChange);
	HookConVarChange(cvar_money, cvarChange);
	HookConVarChange(cvar_spellbook, cvarChange);
	HookConVarChange(cvar_pumpkin, cvarChange);
	HookConVarChange(cvar_funcbutton, cvarChange);
	HookConVarChange(cvar_blockweps_classes, cvarChange);
	HookConVarChange(cvar_blockweps_black, cvarChange);
	HookConVarChange(cvar_blockweps_white, cvarChange);
	HookConVarChange(cvar_blocktaunt, cvarChange);
	HookConVarChange(cvar_invuln_p, cvarChange);
	HookConVarChange(cvar_invuln_s, cvarChange);
	HookConVarChange(cvar_invuln_d, cvarChange);
	HookConVarChange(cvar_invuln_t, cvarChange);
	HookConVarChange(cvar_notarget_p, cvarChange);
	HookConVarChange(cvar_notarget_s, cvarChange);
	HookConVarChange(cvar_notarget_d, cvarChange);
	HookConVarChange(cvar_notarget_t, cvarChange);
	HookConVarChange(cvar_alpha_p, cvarChange);
	HookConVarChange(cvar_alpha_w, cvarChange);
	HookConVarChange(cvar_alpha_wep, cvarChange);
	HookConVarChange(cvar_alpha_s, cvarChange);
	HookConVarChange(cvar_alpha_d, cvarChange);
	HookConVarChange(cvar_alpha_t, cvarChange);
	HookConVarChange(cvar_noblock_p, cvarChange);
	HookConVarChange(cvar_noblock_s, cvarChange);
	HookConVarChange(cvar_noblock_d, cvarChange);
	HookConVarChange(cvar_noblock_t, cvarChange);
}