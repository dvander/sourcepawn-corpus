/*
Changes since 13.0522
	Fixed minor sm_friendly_remember bug involving the action_f cvars being negative
	now notifies server console that an update has been installed/is available
	alt-command adjustments
	Players who have Friendly Admin mode enabled will no longer drop the Intel upon becoming Friendly
	Players who exit Friendly Admin will be forced to drop the intel
	Fixed a few instances of sloppy copy/pasting where logs/CShowActivity2 said admins were enabling things when he is really disabling things.
	Various code visibility fixes. Might be changing block style in a future update
	If the user has access to sm_friendly, sm_friendly_v will display the current number of players in Friendly mode.
To-do
	find a way to retrieve the owner of a sticky, so friendly stickies can be given invuln/alpha
	particle effect
	cvars to clear domination status, or take status into account when determining if damage nullification applies
	figure out how to make Friendly players invisible to bosses/bots
	create a workaround for valve's fl_notarget resupply bug
	menu support?
	Option to stop Friendly players from dropping ammo pickups
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>
#include <morecolors>

#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#tryinclude <updater> //If updater.inc cannot be found, you will get errors on compilation. You should be able to safely ignore them.

#define PLUGIN_VERSION "13.0602"
#define UPDATE_URL "http://ddhoward.bitbucket.org/friendly.txt"

#define CHAT_PREFIX "{olive}[Friendly]{default}"
#define CHAT_PREFIX_SPACE "{olive}[Friendly]{default} "
#define CHAT_PREFIX_NOCOLOR "[Friendly]"
#define CHAT_NAME "{olive}Friendly Mode{default}"

#define DEFAULT_BLOCKED_WEAPONCLASSES "tf_weapon_flamethrower,tf_weapon_medigun,tf_weapon_lunchbox,tf_weapon_buff_item"
/* Default blocked weapon classes are:
	tf_weapon_flamethrower	- Pyro's flamethrowers, to prevent airblasting
	tf_weapon_medigun		- Medic's Mediguns, to prevent healing
	tf_weapon_lunchbox		- Heavy's snacks, to prevent healing through sandvich throwing
	tf_weapon_buff_item		- Soldier's buffing secondary weapons
*/
#define DEFAULT_BLOCKED_WEAPONS "656,447,44,58,222,305,528"
/* Default blocked weapons are:
	656  - Holiday Punch, to prevent taunt forcing
	447  - Disciplinary Action, to prevent speed buff
	44   - Sandman, to prevent ball stun
	58   - Jarate, to prevent mini-crits
	222  - Mad Milk, to prevent healing
	305  - Crusader's Crossbow, to prevent healing
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

new bool:IsFriendly[MAXPLAYERS+1] = {false, ...};
new bool:RequestedChange[MAXPLAYERS+1] = {false, ...};
new bool:IsAdmin[MAXPLAYERS+1] = {false, ...};
new bool:RFETRIZ[MAXPLAYERS+1] = {false, ...};
new bool:IsInSpawn[MAXPLAYERS+1] = false;
new bool:IsLocked[MAXPLAYERS+1] = false;
new _:SeenAdvert[MAXPLAYERS+1] = {0, ...};
new _:FriendlyPlayerCount = 0;
new Float:ToggleTimer[MAXPLAYERS+1];
new Float:AfkTime[MAXPLAYERS+1] = {0.0, ...};
new p_lastbtnstate[MAXPLAYERS+1] = {0, ...};

new Handle:hcvar_version = INVALID_HANDLE;
new bool:FirstCaching = true;

new Handle:hcvar_enabled = INVALID_HANDLE;
new bool:cvar_enabled = true;
new Handle:hcvar_logging = INVALID_HANDLE;
new _:cvar_logging = 2;
new Handle:hcvar_advert = INVALID_HANDLE;
new bool:cvar_advert = true;
new Handle:hcvar_update = INVALID_HANDLE;
new _:cvar_update = 1;
new Handle:hcvar_maxfriendlies = INVALID_HANDLE;
new _:cvar_maxfriendlies = 32;
new Handle:hcvar_delay = INVALID_HANDLE;
new Float:cvar_delay = 5.0;
new Handle:hcvar_afklimit = INVALID_HANDLE;
new _:cvar_afklimit = 300;
new Handle:hcvar_afkinterval = INVALID_HANDLE;
new Float:cvar_afkinterval = 0.2;

new Handle:hcvar_action_h = INVALID_HANDLE;
new _:cvar_action_h = -2;
new Handle:hcvar_action_f = INVALID_HANDLE;
new _:cvar_action_f = -2;
new Handle:hcvar_action_h_spawn = INVALID_HANDLE;
new _:cvar_action_h_spawn = 0;
new Handle:hcvar_action_f_spawn = INVALID_HANDLE;
new _:cvar_action_f_spawn = 0;
new Handle:hcvar_overlay = INVALID_HANDLE;
new String:cvar_overlay[255];
new Handle:hcvar_remember = INVALID_HANDLE;
new bool:cvar_remember = false;
new Handle:hcvar_goomba = INVALID_HANDLE;
new bool:cvar_goomba = true;
new Handle:hcvar_blockrtd = INVALID_HANDLE;
new bool:cvar_blockrtd = true;

new Handle:hcvar_stopcap = INVALID_HANDLE;
new bool:cvar_stopcap = true;
new Handle:hcvar_stopintel = INVALID_HANDLE;
new bool:cvar_stopintel = true;
new Handle:hcvar_ammopack = INVALID_HANDLE;
new bool:cvar_ammopack = true;
new Handle:hcvar_healthpack = INVALID_HANDLE;
new bool:cvar_healthpack = true;
new Handle:hcvar_money = INVALID_HANDLE;
new bool:cvar_money = true;
new Handle:hcvar_pumpkin = INVALID_HANDLE;
new bool:cvar_pumpkin = true;
new Handle:hcvar_airblastkill = INVALID_HANDLE;
new bool:cvar_airblastkill = true;
new Handle:hcvar_funcbutton = INVALID_HANDLE;
new bool:cvar_funcbutton = true;

new Handle:hcvar_blockweps_black = INVALID_HANDLE;
new String:cvar_blockweps_black[255][8];
new Handle:hcvar_blockweps_classes = INVALID_HANDLE;
new String:cvar_blockweps_classes[255][32];
new Handle:hcvar_blockweps_white = INVALID_HANDLE;
new String:cvar_blockweps_white[255][8];
new Handle:hcvar_blocktaunt = INVALID_HANDLE;
new String:cvar_blocktaunt[255][32];

new Handle:hcvar_invuln_p = INVALID_HANDLE;
new _:cvar_invuln_p = 2;
new Handle:hcvar_invuln_s = INVALID_HANDLE;
new _:cvar_invuln_s = 0;
new Handle:hcvar_invuln_d = INVALID_HANDLE;
new _:cvar_invuln_d = 0;
new Handle:hcvar_invuln_t = INVALID_HANDLE;
new _:cvar_invuln_t = 0;

new Handle:hcvar_notarget_p = INVALID_HANDLE;
new bool:cvar_notarget_p = true;
new Handle:hcvar_notarget_s = INVALID_HANDLE;
new bool:cvar_notarget_s = true;
new Handle:hcvar_notarget_d = INVALID_HANDLE;
new bool:cvar_notarget_d = true;
new Handle:hcvar_notarget_t = INVALID_HANDLE;
new bool:cvar_notarget_t = true;

new Handle:hcvar_noblock_p = INVALID_HANDLE;
new _:cvar_noblock_p = 2;
new Handle:hcvar_noblock_s = INVALID_HANDLE;
new _:cvar_noblock_s = 3;
new Handle:hcvar_noblock_d = INVALID_HANDLE;
new _:cvar_noblock_d = 3;
new Handle:hcvar_noblock_t = INVALID_HANDLE;
new _:cvar_noblock_t = 3;

new Handle:hcvar_alpha_p = INVALID_HANDLE;
new _:cvar_alpha_p = 50;
new Handle:hcvar_alpha_w = INVALID_HANDLE;
new _:cvar_alpha_w = 50;
new Handle:hcvar_alpha_wep = INVALID_HANDLE;
new _:cvar_alpha_wep = 50;
new Handle:hcvar_alpha_s = INVALID_HANDLE;
new _:cvar_alpha_s = 50;
new Handle:hcvar_alpha_d = INVALID_HANDLE;
new _:cvar_alpha_d = 50;
new Handle:hcvar_alpha_t = INVALID_HANDLE;
new _:cvar_alpha_t = 50;

new Handle:hcvar_nobuild_s = INVALID_HANDLE;
new bool:cvar_nobuild_s = false;
new Handle:hcvar_nobuild_d = INVALID_HANDLE;
new bool:cvar_nobuild_d = true;
new Handle:hcvar_nobuild_t = INVALID_HANDLE;
new bool:cvar_nobuild_t = false;
new Handle:hcvar_killbuild_h_s = INVALID_HANDLE;
new bool:cvar_killbuild_h_s = true;
new Handle:hcvar_killbuild_h_d = INVALID_HANDLE;
new bool:cvar_killbuild_h_d = true;
new Handle:hcvar_killbuild_h_t = INVALID_HANDLE;
new bool:cvar_killbuild_h_t = true;
new Handle:hcvar_killbuild_f_s = INVALID_HANDLE;
new bool:cvar_killbuild_f_s = true;
new Handle:hcvar_killbuild_f_d = INVALID_HANDLE;
new bool:cvar_killbuild_f_d = true;
new Handle:hcvar_killbuild_f_t = INVALID_HANDLE;
new bool:cvar_killbuild_f_t = true;


new Handle:h_timer_afkcheck = INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "[TF2] Friendly Mode",
	author = "Derek D. Howard",
	description = "Allows players to become invulnerable to damage from other players, while also being unable to attack other players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=213205"
};

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErr_Max)
{
	MarkNativeAsOptional("GetUserMessageType"); 
	new String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));
	if(!StrEqual(strGame, "tf")) {
		Format(strError, iErr_Max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {

	LoadTranslations("common.phrases");

	for (new i=1; i <= MaxClients; i++) {
		IsFriendly[i] = false;
		RequestedChange[i] = false;
		IsAdmin[i] = false;
		RFETRIZ[i] = false;
		IsLocked[i] = false;
		IsInSpawn[i] = false;
		ToggleTimer[i] = -1000.0;
		DisableAdvert(i);
		if (IsClientInGame(i)) {
			HookClient(i);
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
	
	hcvar_stopcap = CreateConVar("sm_friendly_stopcap", "1", "(0/1) If enabled, Friendly players will be unable to cap points or push carts.", FCVAR_PLUGIN);
	hcvar_stopintel = CreateConVar("sm_friendly_stopintel", "1", "(0/1) If enabled, Friendly players will be unable to grab the intel.", FCVAR_PLUGIN);
	hcvar_ammopack = CreateConVar("sm_friendly_ammopack", "1", "(0/1) If enabled, Friendly players will be unable to pick up ammo boxes, dropped weapons, or Sandman balls.", FCVAR_PLUGIN);
	hcvar_healthpack = CreateConVar("sm_friendly_healthpack", "1", "(0/1) If enabled, Friendly players will be unable to pick up health boxes or sandviches.", FCVAR_PLUGIN);
	hcvar_money = CreateConVar("sm_friendly_money", "1", "(0/1) If enabled, Friendly players will be unable to pick up MvM money.", FCVAR_PLUGIN);
	hcvar_pumpkin = CreateConVar("sm_friendly_pumpkin", "1", "(0/1) If enabled, Friendly players will be unable to blow up pumpkins.", FCVAR_PLUGIN);
	hcvar_airblastkill = CreateConVar("sm_friendly_airblastkill", "1", "(0/1) If enabled, Friendly projectiles will vanish upon being airblasted by non-Friendly pyros.", FCVAR_PLUGIN);
	hcvar_funcbutton = CreateConVar("sm_friendly_funcbutton", "0", "(0/1) If enabled, Friendly projectiles will be unable to trigger func_buttons by damaging them.", FCVAR_PLUGIN);

	hcvar_blockweps_classes = CreateConVar("sm_friendly_blockwep_classes", "1", "What weapon classes to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	hcvar_blockweps_black = CreateConVar("sm_friendly_blockweps", "1", "What weapon index definiteion numbers to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	hcvar_blockweps_white = CreateConVar("sm_friendly_blockweps_whitelist", "1", "What weapon index definiteion numbers to whitelist? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	hcvar_blocktaunt = CreateConVar("sm_friendly_blocktaunt", "1", "What weapon index definition numbers to block taunting with? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);

	hcvar_invuln_p = CreateConVar("sm_friendly_invuln", "2", "(0/1/2/3) 0 = Friendly players have full godmode. 1 = Buddha. 2 = Only invulnerable to other players. 3 = Invuln to other players AND himself.", FCVAR_PLUGIN);
	hcvar_invuln_s = CreateConVar("sm_friendly_invuln_s", "0", "(0/1/2) 0 = Disabled, 1 = Friendly sentries will be invulnerable to other players, 2 = Friendly sentries have full Godmode.", FCVAR_PLUGIN);
	hcvar_invuln_d = CreateConVar("sm_friendly_invuln_d", "0", "(0/1/2) 0 = Disabled, 1 = Friendly dispensers will be invulnerable to other players, 2 = Friendly dispensers have full Godmode.", FCVAR_PLUGIN);
	hcvar_invuln_t = CreateConVar("sm_friendly_invuln_t", "0", "(0/1/2) 0 = Disabled, 1 = Friendly teleporters will be invulnerable to other players, 2 = Friendly teleporters have full Godmode.", FCVAR_PLUGIN);

	hcvar_notarget_p = CreateConVar("sm_friendly_notarget", "1", "(0/1) If enabled, a Friendly player will be invisible to sentries, immune to airblasts, etc.", FCVAR_PLUGIN);
	hcvar_notarget_s = CreateConVar("sm_friendly_notarget_s", "1", "(0/1) If enabled, a Friendly player's sentry will be invisible to enemy sentries.", FCVAR_PLUGIN);
	hcvar_notarget_d = CreateConVar("sm_friendly_notarget_d", "1", "(0/1) If enabled, a Friendly player's dispenser will be invisible to enemy sentries. Friendly dispensers will have their healing act buggy.", FCVAR_PLUGIN);
	hcvar_notarget_t = CreateConVar("sm_friendly_notarget_t", "1", "(0/1) If enabled, a Friendly player's teleporters will be invisible to enemy sentries.", FCVAR_PLUGIN);

	hcvar_alpha_p = CreateConVar("sm_friendly_alpha", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_w = CreateConVar("sm_friendly_alpha_w", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' cosmetics. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_wep = CreateConVar("sm_friendly_alpha_wep", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' weapons. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_s = CreateConVar("sm_friendly_alpha_s", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly sentries. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_d = CreateConVar("sm_friendly_alpha_d", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly dispensers. -1 disables this feature.", FCVAR_PLUGIN);
	hcvar_alpha_t = CreateConVar("sm_friendly_alpha_t", "50", "(Any integer, -1 thru 255) Sets the transparency of Friendly teleporters. -1 disables this feature.", FCVAR_PLUGIN);

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
	RegAdminCmd("sm_friendly_r", Restart_Plugin, ADMFLAG_RCON, "Unloads and reloads plugin smx, relies on updater.inc");
	RegAdminCmd("sm_friendly_reload", Restart_Plugin2, 0, _);

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

}

public OnConfigsExecuted() {
	FirstCaching = true;
	cvarChange(INVALID_HANDLE, "0", "0");
}

public Action:UseFriendlyCmd(client, args) {
	new numargs = GetCmdArgs();
	new target[MAXPLAYERS];
	new String:target_name[MAX_TARGET_LENGTH];
	new direction = -1;
	new method = 0;
	new numtargets;
	if (client != 0) {
		DisableAdvert(client);
	}
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
		new String:arg1[64];
		new bool:tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		new String:arg2[2];
		GetCmdArg(2, arg2, sizeof(arg2));
		direction = StringToInt(arg2);
		if (!(direction == -1 || direction == 0 || direction == 1)) {
			CReplyToCommand(client, "%s Second argument must be either 0 or 1. 0 to disable Friendly, or 1 to enable.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
	if (numargs == 3) {
		new String:arg3[2];
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
				count = count + 1;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
				}
				if (method == 1 && !IsAdmin[currenttarget]) {
					ForcePlayerSuicide(currenttarget);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly mode on \"%L\".", client, currenttarget);
				}
			} else {
				MakeClientFriendly(currenttarget);
				count = count + 1;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Mode.", CHAT_PREFIX);
				}
				if (IsPlayerAlive(currenttarget)) {
					if (method == 1 && !IsAdmin[currenttarget]) {
						ForcePlayerSuicide(currenttarget);
						if (!cvar_remember) {
							RFETRIZ[currenttarget] = true;
						}
					}
				} else {
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (!IsFriendly[currenttarget]) {
				MakeClientFriendly(currenttarget);
				count = count + 1;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you into Friendly Mode.", CHAT_PREFIX);
				}
				if (IsPlayerAlive(currenttarget)) {
					if (method == 1 && !IsAdmin[currenttarget]) {
						ForcePlayerSuicide(currenttarget);
						if (!cvar_remember) {
							RFETRIZ[currenttarget] = true;
						}
					}
				} else {
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsFriendly[currenttarget]) {
				MakeClientHostile(currenttarget);
				count = count + 1;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
				}
				if (method == 1 && !IsAdmin[currenttarget]) {
					ForcePlayerSuicide(currenttarget);
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
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
	new Float:time = GetEngineTime();
	if (time < ToggleTimer[client]) {
		CReplyToCommand(client, "%s You must wait %d seconds.", CHAT_PREFIX, RoundToCeil(ToggleTimer[client] - time));
		return;
	}		
	if (IsPlayerAlive(client)) {
		if (RequestedChange[client]) {
			RequestedChange[client] = false;
			CReplyToCommand(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
		} else {
			new action;
			if (IsFriendly[client]) {
				if (IsInSpawn[client]) {
					action = cvar_action_h_spawn;
				} else {
					action = cvar_action_h;
				}
				if (IsAdmin[client]) {
					MakeClientHostile(client);
					CReplyToCommand(client, "%s You are no longer Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
					if (cvar_logging >= 2)
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
				} else if (action == -2) {
					CReplyToCommand(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
				} else if (action == -1) {
					CReplyToCommand(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
					FakeClientCommand(client, "voicemenu 0 7"); //"No"
					ForcePlayerSuicide(client);
				} else if (action == 0) {
					MakeClientHostile(client);
					CReplyToCommand(client, "%s You are no longer Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
					if (cvar_logging >= 2)
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
				} else if (action > 0) {
					MakeClientHostile(client);
					SlapPlayer(client, action);
					CReplyToCommand(client, "%s You are no longer Friendly, but took damage because of the switch!", CHAT_PREFIX);
					if (cvar_logging >= 2)
						LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
				}
			} else {
				if (IsInSpawn[client]) {
					action = cvar_action_f_spawn;
				} else {
					action = cvar_action_f;
				}
				if (IsAdmin[client]) {
					MakeClientFriendly(client);
					CReplyToCommand(client, "%s You are now Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
					if (cvar_logging >= 2)
						LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
				} else if (action == -2) {
					CReplyToCommand(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
				} else if (action == -1) {
					CReplyToCommand(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
					RequestedChange[client] = true;
					FakeClientCommand(client, "voicemenu 0 7"); //"No"
					ForcePlayerSuicide(client);
				} else if (action == 0) {
					if (FriendlyPlayerCount < cvar_maxfriendlies) {
						if (cvar_logging >= 2)
							LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
						MakeClientFriendly(client);
						CReplyToCommand(client, "%s You are now Friendly.", CHAT_PREFIX);
						FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
					} else {
						CReplyToCommand(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
					}
				} else if (action > 0) {
					if (FriendlyPlayerCount < cvar_maxfriendlies) {
						if (cvar_logging >= 2)
							LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
						MakeClientFriendly(client);
						CReplyToCommand(client, "%s You were made Friendly, but took damage because of the switch!", CHAT_PREFIX);
						SlapPlayer(client, action);
					} else {
						CReplyToCommand(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
					}
				}
			}
		}
	} else {
		if (RequestedChange[client]) {
			RequestedChange[client] = false;
			CReplyToCommand(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
			if (IsFriendly[client] && !cvar_remember) {
				RFETRIZ[client] = true;
			}
		} else {
			RequestedChange[client] = true;
			CReplyToCommand(client, "%s You will toggle Friendly mode upon respawning.", CHAT_PREFIX);
			RFETRIZ[client] = false;
		}
	}
}

public Action:UseAdminCmd(client, args) {
	new target[MAXPLAYERS];
	new String:target_name[MAX_TARGET_LENGTH];
	new direction = -1;
	new numtargets;
	if (client != 0) {
		DisableAdvert(client);
	}
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
			} else {
				IsAdmin[client] = true;
				CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Admin mode.");
				if (cvar_logging > 0) {
					LogAction(client, -1, "\"%L\" activated Friendly Admin mode.", client);
				}
			}
		} else {
			CReplyToCommand(client, "%s Not a valid client.", CHAT_PREFIX);
		}
		return Plugin_Handled;
	}
	if (numargs > 3) {
		CReplyToCommand(client, "%s Usage: \"sm_friendly_admin [target] [-1/0/1]\"", CHAT_PREFIX);
		return Plugin_Handled;
	}
	if (numargs >= 1) {
		new String:arg1[64];
		new bool:tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		new String:arg2[2];
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
				count = count + 1;
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Admin mode.", CHAT_PREFIX);
				}
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Admin mode on \"%L\".", client, currenttarget);
				}
				if (cvar_stopintel && IsFriendly[currenttarget]) {
					FakeClientCommand(currenttarget, "dropitem");
				}
			} else {
				IsAdmin[currenttarget] = true;
				count = count + 1;
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Admin mode on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (!IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = true;
				count = count + 1;
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Admin on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsAdmin[currenttarget]) {
				IsAdmin[currenttarget] = false;
				count = count + 1;
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Admin mode on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Admin on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

public Action:UseLockCmd(client, args) {
	new target[MAXPLAYERS];
	new String:target_name[MAX_TARGET_LENGTH];
	new direction = -1;
	new numtargets;
	if (client != 0) {
		DisableAdvert(client);
	}
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
		new String:arg1[64];
		new bool:tn_is_ml;
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		new String:arg2[2];
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
				count = count + 1;
				if (cvar_logging >= 3 || (cvar_logging > 0 && numtargets == 1)) {
					LogAction(client, currenttarget, "\"%L\" disabled Friendly Lock on \"%L\".", client, currenttarget);
				}
			} else {
				IsLocked[currenttarget] = true;
				count = count + 1;
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" toggled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Toggled Friendly Lock on %s.", target_name);
		}
	}
	if (direction == 1) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (!IsLocked[currenttarget]) {
				IsLocked[currenttarget] = true;
				count = count + 1;
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" enabled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Enabled Friendly Lock on %s.", target_name);
		}
	}
	if (direction == 0) {
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsLocked[currenttarget]) {
				IsLocked[currenttarget] = false;
				count = count + 1;
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
			} else if (cvar_logging >= 3) {
				LogAction(client, -1, "\"%L\" disabled Friendly Lock on %s, affecting the previous %i players.", client, target_name, count);
			}
		} else if (numtargets == 1) {
			CShowActivity2(client, CHAT_PREFIX_SPACE, "Disabled Friendly Lock on %s.", target_name);
		}
	}
	return Plugin_Handled;
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (cvar_advert) {
		DoAdvert(client);
	}
	if (RFETRIZ[client] || (IsLocked[client] && IsFriendly[client])) {
		CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
		RequestedChange[client] = false;
		RFETRIZ[client] = false;
		// Inventory_App should take care of things from here
	} else if (RequestedChange[client]) {
		if (IsFriendly[client]) {
			MakeClientHostile(client);
			if (cvar_logging >= 2) {
				LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
			}
			CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
		} else {
			if (FriendlyPlayerCount < cvar_maxfriendlies) {
				MakeClientFriendly(client);
				CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
				if (cvar_logging >= 2) {
					LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
				}
			} else {
				CPrintToChat(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
			}
		}
	} else if (!RequestedChange[client]) {
		if (IsFriendly[client]) {
			if (cvar_remember) {
				CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
				RequestedChange[client] = false;
				// Inventory_App should take care of things from here
			} else {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You have been taken out of Friendly mode because you respawned.", CHAT_PREFIX);
				if (cvar_logging >= 2) {
					LogAction(client, -1, "\"%L\" deactivated Friendly mode.", client);
				}
			}
		}
	}
}

public Action:UseAdminCmd2(client, args) {
	if (CheckCommandAccess(client, "sm_friendly_admin", ADMFLAG_BAN, true)) {
		UseAdminCmd(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:UseLockCmd2(client, args) {
	if (CheckCommandAccess(client, "sm_friendly_lock", ADMFLAG_BAN, true)) {
		UseLockCmd(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:smFriendlyVer2(client, args) {
	if (CheckCommandAccess(client, "sm_friendly_v", 0, true)) {
		smFriendlyVer(client, args);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Restart_Plugin2(client, args) {
	if (CheckCommandAccess(client, "sm_friendly_r", ADMFLAG_RCON, true)) {
		Restart_Plugin(client, args);
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
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	IsAdmin[client] = false;
	IsLocked[client] = false;
	RFETRIZ[client] = false;
	HookClient(client);
	SeenAdvert[client] = 0;
	IsInSpawn[client] = false;
	ToggleTimer[client] = -1000.0;
	AfkTime[client] = 0.0;
}

public OnClientDisconnect(client) {
	if (IsFriendly[client]) {
		FriendlyPlayerCount = FriendlyPlayerCount - 1;
	}
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	IsAdmin[client] = false;
	IsLocked[client] = false;
	RFETRIZ[client] = false;
	SeenAdvert[client] = 0;
	IsInSpawn[client] = false;
	ToggleTimer[client] = -1000.0;
	UnhookClient(client);
}

MakeClientHostile(const client) {

	new Float:time = GetEngineTime();
	ToggleTimer[client] = time + cvar_delay;

	FriendlyPlayerCount = FriendlyPlayerCount - 1;
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	RFETRIZ[client] = false;
	MakeBuildingsHostile(client);
	if (!StrEqual(cvar_overlay, "0")) {
		SetOverlay(client, false);
	}
	if (cvar_invuln_p < 2) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	if (cvar_notarget_p) {
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
}

MakeClientFriendly(const client) {

	new Float:time = GetEngineTime();
	ToggleTimer[client] = time + cvar_delay;

	FriendlyPlayerCount = FriendlyPlayerCount + 1;
	MakeBuildingsFriendly(client);
	ReapplyFriendly(client);
	RemoveMySappers(client);
	RequestedChange[client] = false;
	RFETRIZ[client] = false;
	if (cvar_stopintel && !IsAdmin[client]) {
		FakeClientCommand(client, "dropitem");
	}
	if (!IsAdmin[client]) {
		ForceWeaponSwitches(client);
	}
}

public Inventory_App(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFriendly[client]) {
		ReapplyFriendly(client);
	}
}

ReapplyFriendly(const client) {
	IsFriendly[client] = true;
	if (!StrEqual(cvar_overlay, "0")) {
		SetOverlay(client, true);
	}
	if (cvar_invuln_p < 2) {
		if (cvar_invuln_p == 0) {
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //godmode
		}
		if (cvar_invuln_p == 1) {
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1); //buddha
		}
	}
	if (cvar_notarget_p) {
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
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (attacker < 1 || attacker > MaxClients || (client == attacker && cvar_invuln_p != 3)) {
		return Plugin_Continue;
	}
	if ((IsFriendly[attacker] || IsFriendly[client]) && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

ApplyNoblock(i, bool:remove) {
	new String:classname[64];
	new cvarValue;
	GetEntityClassname(i, classname, sizeof(classname));
	if (StrEqual(classname, "player"))
		cvarValue = cvar_noblock_p;
	if (StrEqual(classname, "obj_sentrygun"))
		cvarValue = cvar_noblock_p;
	if (StrEqual(classname, "obj_dispenser"))
		cvarValue = cvar_noblock_p;
	if (StrEqual(classname, "obj_teleporter"))
		cvarValue = cvar_noblock_p;
	if (cvarValue == 0 || remove)
		SetEntProp(i, Prop_Send, "m_CollisionGroup", 5);
	if (cvarValue == 1 && !remove)
		SetEntProp(i, Prop_Send, "m_CollisionGroup", 2);
	if (cvarValue == 2 && !remove)
		SetEntProp(i, Prop_Send, "m_CollisionGroup", 10);
	if (cvarValue == 3 && !remove)
		SetEntProp(i, Prop_Send, "m_CollisionGroup", 1);
}

SetOverlay(client, bool:apply) {
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	if (apply) {
		ClientCommand(client, "r_screenoverlay \"%s\"", cvar_overlay);
	} else {
		ClientCommand(client, "r_screenoverlay \"\"");
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
}

SetNotarget(ent, bool:apply) {
	if (apply) {
		new flags = GetEntityFlags(ent)|FL_NOTARGET;
		SetEntityFlags(ent, flags);
	} else {
		new flags = GetEntityFlags(ent)&~FL_NOTARGET;
		SetEntityFlags(ent, flags);
	}
}

public Action:Player_AFKCheck(Handle:htimer) {
	if (cvar_afklimit > 0) {
		for (new client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && !IsFakeClient(client)) {
				if (p_lastbtnstate[client] != (p_lastbtnstate[client] = GetClientButtons(client))) {
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
					ForcePlayerSuicide(client);
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
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && !IsFakeClient(client)) {
			AfkTime[client] = 0.0;
		}
	}
	h_timer_afkcheck = CreateTimer(cvar_afkinterval, Player_AFKCheck, INVALID_HANDLE, TIMER_REPEAT);
}

public OnPluginEnd() {
	for (new i=1; i <= MaxClients; i++) {
		UnhookClient(i);
		if (IsFriendly[i]) {
			MakeClientHostile(i);
			IsAdmin[i] = false;
			new action;
			if (IsInSpawn[i]) {
				action = cvar_action_h_spawn;
			} else {
				action = cvar_action_h;
			}
			if (action < 0) {
				ForcePlayerSuicide(i);
			} if (action > 0) {
				SlapPlayer(i, action);
			}
			CPrintToChat(i, "%s Plugin has been unloaded or restarted.", CHAT_PREFIX);
		}
	}
}

public Airblast(Handle:event, const String:name[], bool:dontBroadcast) {
	new pyro = GetClientOfUserId(GetEventInt(event, "userid"));
	new pitcher = GetClientOfUserId(GetEventInt(event, "ownerid"));
	//new weaponid = GetEventInt(event, "weaponid");
	new object = GetEventInt(event, "object_entindex");
	if (IsValidEntity(object)) {
		new String:classname[64];
		GetEntityClassname(object, classname, sizeof(classname));
		if (!(StrEqual(classname, "tf_projectile_pipe_remote") || StrEqual(classname, "player"))) {
			if (IsFriendly[pitcher] && !IsFriendly[pyro] && cvar_airblastkill) {
				AcceptEntityInput(object, "Kill");
			}
		}
	}
}

HookClient(const client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

UnhookClient(const client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public OnEntityCreated(entity, const String:classname[]) {
	if (cvar_ammopack) {
		if(StrContains(classname, "item_ammopack_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
		}
		if(StrEqual(classname, "tf_ammo_pack", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
		}
		if(StrEqual(classname, "tf_projectile_stun_ball", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
			SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
		}
	}
	if (cvar_healthpack) {
		if(StrContains(classname, "item_healthkit_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnHealthPackTouch);
			SDKHook(entity, SDKHook_Touch, OnHealthPackTouch);
		}
	}
	if (cvar_money) {
		if(StrContains(classname, "item_currencypack_", false) != -1) {
			SDKHook(entity, SDKHook_StartTouch, OnMoneyTouch);
			SDKHook(entity, SDKHook_Touch, OnMoneyTouch);
		}
	}
	if (cvar_stopcap) {
		if(StrEqual(classname, "trigger_capture_area", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnCPTouch );
			SDKHook(entity, SDKHook_Touch, OnCPTouch );
		}
	}
	if (cvar_stopintel) {
		if(StrEqual(classname, "item_teamflag", false)) {
			SDKHook(entity, SDKHook_StartTouch, OnFlagTouch );
			SDKHook(entity, SDKHook_Touch, OnFlagTouch );
		}
	}
	if (cvar_pumpkin) {
		if(StrEqual(classname, "tf_pumpkin_bomb", false)) {
			SDKHook(entity, SDKHook_OnTakeDamage, PumpkinTakeDamage);
		}
	}
	if(StrEqual(classname, "tf_projectile_pipe_remote", false)) {
		SDKHook(entity, SDKHook_OnTakeDamage, StickyTakeDamage);
	}
	if (cvar_funcbutton) {
		if(StrEqual(classname, "func_button", false)) {
			SDKHook(entity, SDKHook_OnTakeDamage, ButtonTakeDamage);
			SDKHook(entity, SDKHook_Use, ButtonUsed);
		}
	}
	if(StrEqual(classname, "func_respawnroom", false)) {
		SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
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
		SDKHook(ent, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(ent, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public Action:OnCPTouch(point, client) {
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	} else {
		if (IsFriendly[client] && cvar_stopcap && !IsAdmin[client]) {
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	}
}

public Action:OnFlagTouch(point, client) {
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	} else {
		if (IsFriendly[client] && cvar_stopintel && !IsAdmin[client]) {
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	}
}

public Action:OnHealthPackTouch(point, client) {
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	} else {
		if (IsFriendly[client] && cvar_healthpack && !IsAdmin[client]) {
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	}
}

public Action:OnAmmoPackTouch(point, client) {
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	} else {
		if (IsFriendly[client] && cvar_ammopack && !IsAdmin[client]) {
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	}
}

public Action:OnMoneyTouch(point, client) {
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	} else {
		if (IsFriendly[client] && cvar_money && !IsAdmin[client]) {
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	}
}

public Action:PumpkinTakeDamage(pumpkin, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (attacker < 1 || attacker > MaxClients) {
		return Plugin_Continue;
	}
	if (IsFriendly[attacker] && cvar_pumpkin && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:ButtonTakeDamage(button, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (attacker < 1 || attacker > MaxClients) {
		return Plugin_Continue;
	}
	if (IsFriendly[attacker] && cvar_funcbutton && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:ButtonUsed(entity, activator, caller, UseType:type, Float:value) {
	if (activator < 1 || activator > MaxClients) {
		return Plugin_Continue;
	}
	if (IsFriendly[activator] && cvar_funcbutton && !IsAdmin[activator]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:StickyTakeDamage(sticky, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (attacker < 1 || attacker > MaxClients) {
		return Plugin_Continue;
	} else {
		if (IsFriendly[attacker] && !IsAdmin[attacker]) {
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public SpawnStartTouch(spawn, client) {
	if (client > MaxClients || client < 1)
		return;
	if (IsClientConnected(client) && IsClientInGame(client))
		IsInSpawn[client] = true;
}

public SpawnEndTouch(spawn, client) {
	if (client > MaxClients || client < 1)
		return;
	if (IsClientConnected(client) && IsClientInGame(client))
		IsInSpawn[client] = false;
}


/* ///////////////////////////////////////////////////////////////////////////////////////
Engie Building shit. Code modified from the following plugins:
forums.alliedmods.net/showthread.php?t=171518
forums.alliedmods.net/showthread.php?p=1553549
*/

public Action:Object_Built(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new building = GetEventInt(event, "index");
	decl String:b_classname[64];
	GetEntityClassname(building, b_classname, sizeof(b_classname));
	SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
	if (IsFriendly[client]) {
		if (StrEqual(b_classname, "obj_sentrygun")) {
			if (cvar_nobuild_s && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build sentries while Friendly!", CHAT_PREFIX);
			} else {
				if (cvar_invuln_s == 2) {	
					SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
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
		if (StrEqual(b_classname, "obj_dispenser")) {
			if (cvar_nobuild_d && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build dispensers while Friendly!", CHAT_PREFIX);
			} else {
				if (cvar_invuln_d == 2) {	
					SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
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
		if (StrEqual(b_classname, "obj_teleporter")) {
			if (cvar_nobuild_t && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build teleporters while Friendly!", CHAT_PREFIX);
			} else {
				if (cvar_invuln_t == 2) {	
					SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
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
	return Plugin_Handled;
}

MakeBuildingsFriendly(const client) {
	new sentrygun = -1;
	new dispenser = -1;
	new teleporter = -1;
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(sentrygun) && (GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)) {
			if (cvar_killbuild_f_s && !IsAdmin[client]) {
				AcceptEntityInput(sentrygun, "Kill");
			} else {
				if (cvar_invuln_s > 0) {
					if (cvar_invuln_s == 1) {
						RemoveActiveSapper(sentrygun, false);
					}
					if (cvar_invuln_s == 2) {
						SetEntProp(sentrygun, Prop_Data, "m_takedamage", 0, 1);
						RemoveActiveSapper(sentrygun, true);
					}
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
			} else {
				if (cvar_invuln_d > 0) {
					if (cvar_invuln_d == 1) {
						RemoveActiveSapper(dispenser, false);
					}
					if (cvar_invuln_d == 2) {
						SetEntProp(dispenser, Prop_Data, "m_takedamage", 0, 1);
						RemoveActiveSapper(dispenser, true);
					}
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
			} else {
				if (cvar_invuln_t > 0) {
					if (cvar_invuln_t == 1) {
						RemoveActiveSapper(teleporter, false);
					}
					if (cvar_invuln_t == 2) {
						SetEntProp(teleporter, Prop_Data, "m_takedamage", 0, 1);
						RemoveActiveSapper(teleporter, true);
					}
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
			} else {
				if (cvar_invuln_s == 2) {	
					SetEntProp(sentrygun, Prop_Data, "m_takedamage", 2, 1);
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
			} else {
				if (cvar_invuln_d == 2) {	
					SetEntProp(dispenser, Prop_Data, "m_takedamage", 2, 1);
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
			} else {
				if (cvar_invuln_t == 2) {	
					SetEntProp(teleporter, Prop_Data, "m_takedamage", 2, 1);
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
	new String:classname[64];
	GetEntityClassname(building, classname, sizeof(classname));
	if (attacker < 1 || attacker > MaxClients) {
		return Plugin_Continue;
	}
	if (!IsAdmin[attacker]) {
		if (StrEqual(classname, "obj_sentrygun", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_s > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		if (StrEqual(classname, "obj_dispenser", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_d > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		if (StrEqual(classname, "obj_teleporter", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && cvar_invuln_t > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Object_Sapped(Handle:event, const String:name[], bool:dontBroadcast) {
	new engie = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new sapper = GetEventInt(event, "sapperid");
	new spy = GetClientOfUserId(GetEventInt(event, "userid"));
	new building = GetEventInt(event, "object"); //dispenser 0, tele 1, sentry 2
	if (IsFriendly[spy] && !IsAdmin[spy]) {
		AcceptEntityInput(sapper, "Kill");
	} else {
		if (IsFriendly[engie]) {
			if (building == 0) {
				if (cvar_invuln_d == 2) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (cvar_invuln_d == 1 && !IsAdmin[spy]) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (cvar_invuln_d == 1 && IsAdmin[spy]) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
				if (cvar_invuln_d == 0) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
			}
			if (building == 1) {
				if (cvar_invuln_t == 2) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (cvar_invuln_t == 1 && !IsAdmin[spy]) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (cvar_invuln_t == 1 && IsAdmin[spy]) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
				if (cvar_invuln_t == 0) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
			}
			if (building == 2) {
				if (cvar_invuln_s == 2) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (cvar_invuln_s == 1 && !IsAdmin[spy]) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (cvar_invuln_s == 1 && IsAdmin[spy]) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
				if (cvar_invuln_s == 0) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
			}
		} else {
			SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
		}
	}
	return Plugin_Continue;
}

public Action:SapperTakeDamage(sapper, &attacker, &inflictor, &Float:damage, &damagetype) {
	new homewrecker = attacker;
	new building = GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity");
	new engie = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	if (attacker < 1 || attacker > MaxClients) {
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

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrEqual(sample, "weapons/sapper_timer.wav", false)
	|| (StrContains(sample, "spy_tape_01.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_02.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_03.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_04.wav", false) != -1)
	|| (StrContains(sample, "spy_tape_05.wav", false) != -1)) {
		if (!IsValidEntity(GetEntPropEnt(entity, Prop_Send, "m_hBuiltOnEntity"))) return Plugin_Stop;
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
The following code was borrowed from FlaminSarge's Ghost Mode plugin: forums.alliedmods.net/showthread.php?t=183266
This code makes wearables change alpha if sm_friendly_alpha_w is higher than -1 */

stock SetWearableInvis(client, bool:set = true)
{
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
	} else {
		new String:prefix[] = "[Friendly]";
		new String:part1[] = "Please consider installing Updater!";
		new String:part2[] = "It will help you automatically keep your plugins up to date!";
		new String:part3[] = "Please go to:";
		new String:url[] = "https://forums.alliedmods.net/showthread.php?t=169095";
		PrintToServer("%s %s %s %s %s", prefix, part1, part2, part3, url);
	}
}

public Action:Updater_OnPluginDownloading() {
	if (cvar_update > 0) {
		return Plugin_Continue;
	} else {
		PrintToServer("%s An update to Friendly Mode is available! Please see the forum thread for more info.");
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
	} else {
		PrintToServer("%s An update has been downloaded, and will be installed on the next map change.");
	}
}

public Action:Restart_Plugin(client, args) {
	CReplyToCommand(client, "%s Attempting plugin reload...", CHAT_PREFIX);
	ReloadPlugin();
	return Plugin_Handled;
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
		SeenAdvert[client] = (SeenAdvert[client] + 1);
	}
	if (SeenAdvert[client] == 4) {
		SeenAdvert[client] = (SeenAdvert[client] + 1);
		if (cvar_enabled && CheckCommandAccess(client, "sm_friendly", 0, false)) {
			CPrintToChat(client, "%s This server is currently running %s v.{lightgreen}%s{default}. Type {olive}/friendly{default} to use.", CHAT_PREFIX, CHAT_NAME, PLUGIN_VERSION);
		}
	}
}

public Action:smFriendlyVer(client, args) {
	if (client != 0) {
		DisableAdvert(client);
	}
	if (CheckCommandAccess(client, "sm_friendly", 0, false) && cvar_enabled) {
		CReplyToCommand(client, "%s This server is currently running %s v.{lightgreen}%s{default}. Type {olive}/friendly{default} to use. There are currently {lightgreen}%i{default} players in Friendly mode.", CHAT_PREFIX, CHAT_NAME, PLUGIN_VERSION, FriendlyPlayerCount);
	} else {
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
	if (IsFriendly[client] && !IsAdmin[client] && IsValidEdict(weapon)) {
		new String:weaponClass[32];
		GetEdictClassname(weapon, weaponClass, sizeof(weaponClass));
		new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		new wepCount;
		new wepClassCount;
		for (new i = 0; i < sizeof(cvar_blockweps_classes) && wepClassCount < 1 && !StrEqual(cvar_blockweps_classes[i], "-1"); i++) {
			if (StrEqual(cvar_blockweps_classes[i], weaponClass)) {
				wepClassCount++;
			}
		}
		if (wepClassCount > 0) {
			for (new i = 0; i < sizeof(cvar_blockweps_white) && wepCount < 1 && !StrEqual(cvar_blockweps_white[i], "-1"); i++) {
				if (StringToInt(cvar_blockweps_white[i]) == weaponIndex) {
					wepCount++;
				}
			}
			if (wepCount > 0) {
				return Plugin_Continue;
			} else {
				return Plugin_Handled;
			}
		} else {
			for (new i = 0; i < sizeof(cvar_blockweps_black) && wepCount < 1 && !StrEqual(cvar_blockweps_black[i], "-1"); i++) {
				if (StringToInt(cvar_blockweps_black[i]) == weaponIndex) {
					wepCount++;
				}
			}
			if (wepCount > 0) {
				return Plugin_Handled;
			} else {
				return Plugin_Continue;
			}
		}
	} else {
		return Plugin_Continue;
	}
}

public Action:TauntCmd(client, const String:strCommand[], iArgs) {
	if (IsFriendly[client] && !IsAdmin[client]) {
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(weapon)) {
			new wepCount;
			new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			for (new i = 0; i < sizeof(cvar_blocktaunt) && wepCount < 1 && !StrEqual(cvar_blocktaunt[i], "-1"); i++) {
				if (StringToInt(cvar_blocktaunt[i]) == weaponIndex) {
					wepCount++;
				}
			}
			if (wepCount > 0) {
				return Plugin_Handled;
			} 
		}
	}
	return Plugin_Continue;
}


ForceWeaponSwitches(const client) {
	CreateTimer(0.2, ForceWeaponSwitches0, client);
	CreateTimer(0.4, ForceWeaponSwitches1, client);
	CreateTimer(0.6, ForceWeaponSwitches2, client);
}
public Action:ForceWeaponSwitches0(Handle:timer, any:client) {
	new weapon0 = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(weapon0)) {
		new String:weapon0Class[32];
		GetEdictClassname(weapon0, weapon0Class, sizeof(weapon0Class));
		FakeClientCommand(client, "use %s", weapon0Class);
	}
}
public Action:ForceWeaponSwitches1(Handle:timer, any:client) {
	new weapon1 = GetPlayerWeaponSlot(client, 1);
	if (IsValidEdict(weapon1)) {
		new String:weapon1Class[32];
		GetEdictClassname(weapon1, weapon1Class, sizeof(weapon1Class));
		FakeClientCommand(client, "use %s", weapon1Class);
	}
}
public Action:ForceWeaponSwitches2(Handle:timer, any:client) {
	new weapon2 = GetPlayerWeaponSlot(client, 2);
	if (IsValidEdict(weapon2)) {
		new String:weapon2Class[32];	
		GetEdictClassname(weapon2, weapon2Class, sizeof(weapon2Class));
		FakeClientCommand(client, "use %s", weapon2Class);
	}
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Begin code relevant to hooking other convar changes */

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	if (hHandle == hcvar_version || FirstCaching) {
		SetConVarString(hcvar_version, PLUGIN_VERSION);
	}
	if (hHandle == hcvar_enabled || FirstCaching) {
		cvar_enabled = GetConVarBool(hcvar_enabled);
		if (!FirstCaching) {
			if (cvar_enabled) {
				if (cvar_logging > 0) {
					LogAction(-1, -1, "Friendly mode plugin was enabled.");
				}
				CPrintToChatAll("%s An admin has re-enabled Friendly Mode. Type {olive}/friendly{default} to use.", CHAT_PREFIX);
			} else {
				if (cvar_logging > 0) {
					LogAction(-1, -1, "Friendly mode plugin was disabled. All players forced out of Friendly mode.");
				}
				CPrintToChatAll("%s An admin has disabled Friendly Mode.", CHAT_PREFIX);
				for (new i=1; i <= MaxClients; i++) {
					if (IsFriendly[i]) {
						MakeClientHostile(i);
						if (!IsAdmin[i]) {
							new action;
							if (IsInSpawn[i]) {
								action = cvar_action_h_spawn;
							} else {
								action = cvar_action_h;
							}
							if (action < 0) {
								ForcePlayerSuicide(i);
							} if (action > 0) {
								SlapPlayer(i, action);
							}
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_logging || FirstCaching) {
		cvar_logging = GetConVarInt(hcvar_logging);
	}
	if (hHandle == hcvar_advert || FirstCaching) {
		cvar_advert = GetConVarBool(hcvar_advert);
	}
	if (hHandle == hcvar_update || FirstCaching) {
		cvar_update = GetConVarInt(hcvar_update);
	}
	if (hHandle == hcvar_maxfriendlies || FirstCaching) {
		cvar_maxfriendlies = GetConVarInt(hcvar_maxfriendlies);
	}
	if (hHandle == hcvar_delay || FirstCaching) {
		cvar_delay = GetConVarFloat(hcvar_delay);
	}
	if (hHandle == hcvar_afklimit || FirstCaching) {
		cvar_afklimit = GetConVarInt(hcvar_afklimit);
		if (!FirstCaching) {
			RestartAFKTimer();
		}
	}
	if (hHandle == hcvar_afkinterval || FirstCaching) {
		cvar_afkinterval = GetConVarFloat(hcvar_afkinterval);
		if (!FirstCaching) {
			RestartAFKTimer();
		}
	}
	if (hHandle == hcvar_action_h || FirstCaching) {
		cvar_action_h = GetConVarInt(hcvar_action_h);
	}
	if (hHandle == hcvar_action_f || FirstCaching) {
		cvar_action_f = GetConVarInt(hcvar_action_f);
	}
	if (hHandle == hcvar_action_h_spawn || FirstCaching) {
		cvar_action_h_spawn = GetConVarInt(hcvar_action_h_spawn);
	}
	if (hHandle == hcvar_action_f_spawn || FirstCaching) {
		cvar_action_f_spawn = GetConVarInt(hcvar_action_f_spawn);
	}
	if (hHandle == hcvar_remember || FirstCaching) {
		cvar_remember = GetConVarBool(hcvar_remember);
	}
	if (hHandle == hcvar_goomba || FirstCaching) {
		cvar_goomba = GetConVarBool(hcvar_goomba);
	}
	if (hHandle == hcvar_blockrtd || FirstCaching) {
		cvar_blockrtd = GetConVarBool(hcvar_blockrtd);
	}
	if (hHandle == hcvar_stopcap || FirstCaching) {
		cvar_stopcap = GetConVarBool(hcvar_stopcap);
		if (!FirstCaching) {
			new ent = -1;
			if (cvar_stopcap) {
				while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_StartTouch, OnCPTouch );
					SDKHook(ent, SDKHook_Touch, OnCPTouch );
				}
			} else {
				while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_StartTouch, OnCPTouch );
					SDKUnhook(ent, SDKHook_Touch, OnCPTouch );
				}
			}
		}
	}
	if (hHandle == hcvar_stopintel || FirstCaching) {
		cvar_stopintel = GetConVarBool(hcvar_stopintel);
		if (!FirstCaching) {
			new ent = -1;
			if (cvar_stopintel) {
				while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
					SDKHook(ent, SDKHook_Touch, OnFlagTouch );
				}
			} else {
				while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_StartTouch, OnFlagTouch );
					SDKUnhook(ent, SDKHook_Touch, OnFlagTouch );
				}
			}
		}
	}
	if (hHandle == hcvar_ammopack || FirstCaching) {
		cvar_ammopack = GetConVarBool(hcvar_ammopack);
		if (!FirstCaching) {
			new ent = -1;
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
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_stun_ball")) != -1) {
					SDKHook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
			} else {
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKUnhook(ent, SDKHook_Touch, OnAmmoPackTouch);
				}
				ent = -1;
				while ((ent = FindEntityByClassname(ent, "item_ammopack_medium")) != -1) {
					SDKUnhook(ent, SDKHook_StartTouch, OnAmmoPackTouch);
					SDKHook(ent, SDKHook_Touch, OnAmmoPackTouch);
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
	if (hHandle == hcvar_healthpack || FirstCaching) {
		cvar_healthpack = GetConVarBool(hcvar_healthpack);
		if (!FirstCaching) {
			new ent = -1;
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
			} else {
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
	if (hHandle == hcvar_money || FirstCaching) {
		cvar_money = GetConVarBool(hcvar_money);
		if (!FirstCaching) {
			new ent = -1;
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
			} else {
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
	if (hHandle == hcvar_pumpkin || FirstCaching) {
		cvar_pumpkin = GetConVarBool(hcvar_pumpkin);
		if (!FirstCaching) {
			new ent = -1;
			if (cvar_pumpkin) {
				while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
				}
			} else {
				while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
				}
			}
		}
	}
	if (hHandle == hcvar_airblastkill || FirstCaching) {
		cvar_airblastkill = GetConVarBool(hcvar_airblastkill);
	}
	if (hHandle == hcvar_funcbutton || FirstCaching) {
		cvar_funcbutton = GetConVarBool(hcvar_funcbutton);
		if (!FirstCaching) {
			new ent = -1;
			if (cvar_funcbutton) {
				while ((ent = FindEntityByClassname(ent, "func_button"))!=INVALID_ENT_REFERENCE) {
					SDKHook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
					SDKHook(ent, SDKHook_Use, ButtonUsed);
				}
			} else {
				while ((ent = FindEntityByClassname(ent, "func_button"))!=INVALID_ENT_REFERENCE) {
					SDKUnhook(ent, SDKHook_OnTakeDamage, ButtonTakeDamage);
					SDKUnhook(ent, SDKHook_Use, ButtonUsed);
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_p || FirstCaching) {
		cvar_invuln_p = GetConVarInt(hcvar_invuln_p);
		if (!FirstCaching) {
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					if (cvar_invuln_p == 0) {
						SetEntProp(i, Prop_Data, "m_takedamage", 0, 1); //godmode
					} else if (cvar_invuln_p == 1){
						SetEntProp(i, Prop_Data, "m_takedamage", 1, 1); //buddha
					} else {
						SetEntProp(i, Prop_Data, "m_takedamage", 2, 1); //mortal
					}
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_s || FirstCaching) {
		cvar_invuln_s = GetConVarInt(hcvar_invuln_s);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_invuln_s < 2) {
							SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
							RemoveActiveSapper(i, false);
						} else if (cvar_invuln_s == 2){
							SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
							RemoveActiveSapper(i, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_d || FirstCaching) {
		cvar_invuln_d = GetConVarInt(hcvar_invuln_d);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_invuln_d < 2) {
							SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
							RemoveActiveSapper(i, false);
						} else if (cvar_invuln_d == 2){
							SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
							RemoveActiveSapper(i, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_invuln_t || FirstCaching) {
		cvar_invuln_t = GetConVarInt(hcvar_invuln_t);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_invuln_t < 2) {
							SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
							RemoveActiveSapper(i, false);
						} else if (cvar_invuln_t == 2){
							SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
							RemoveActiveSapper(i, true);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_notarget_p || FirstCaching) {
		cvar_notarget_p = GetConVarBool(hcvar_notarget_p);
		if (!FirstCaching) {
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					if (cvar_notarget_p) {
						SetNotarget(i, true);
					} else {
						SetNotarget(i, false);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_notarget_s || FirstCaching) {
		cvar_notarget_s = GetConVarBool(hcvar_notarget_s);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_notarget_s) {
							SetNotarget(i, true);
						} else {
							SetNotarget(i, false);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_notarget_d || FirstCaching) {
		cvar_notarget_d = GetConVarBool(hcvar_notarget_d);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_notarget_d) {
							SetNotarget(i, true);
						} else {
							SetNotarget(i, false);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_notarget_t || FirstCaching) {
		cvar_notarget_t = GetConVarBool(hcvar_notarget_t);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_notarget_t) {
							SetNotarget(i, true);
						} else {
							SetNotarget(i, false);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_p || FirstCaching) {
		cvar_noblock_p = GetConVarInt(hcvar_noblock_p);
		if (!FirstCaching) {
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					ApplyNoblock(i, false);
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_s || FirstCaching) {
		cvar_noblock_s = GetConVarInt(hcvar_noblock_s);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						ApplyNoblock(i, false);				
					}
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_d || FirstCaching) {
		cvar_noblock_d = GetConVarInt(hcvar_noblock_d);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						ApplyNoblock(i, false);				
					}
				}
			}
		}
	}
	if (hHandle == hcvar_noblock_t || FirstCaching) {
		cvar_noblock_t = GetConVarInt(hcvar_noblock_t);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						ApplyNoblock(i, false);				
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_p || FirstCaching) {
		cvar_alpha_p = GetConVarInt(hcvar_alpha_p);
		if (!FirstCaching) {
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					if (cvar_alpha_p >= 0 && cvar_alpha_p <= 255) {
						SetEntityRenderMode(i, RENDER_TRANSALPHA);
						SetEntityRenderColor(i, _, _, _, cvar_alpha_p);
					} else {
						SetEntityRenderMode(i, RENDER_NORMAL);
						SetEntityRenderColor(i, _, _, _, _);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_w || FirstCaching) {
		cvar_alpha_w = GetConVarInt(hcvar_alpha_w);
		if (!FirstCaching) {
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					if (cvar_alpha_w >= 0 && cvar_alpha_w <= 255) {
						SetWearableInvis(i);
					} else {
						SetWearableInvis(i, false);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_wep || FirstCaching) {
		cvar_alpha_wep = GetConVarInt(hcvar_alpha_wep);
		if (!FirstCaching) {
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					if (cvar_alpha_wep >= 0 && cvar_alpha_wep <= 255) {
						SetWeaponInvis(i);
					} else {
						SetWeaponInvis(i, false);
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_s || FirstCaching) {
		cvar_alpha_s = GetConVarInt(hcvar_alpha_s);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_alpha_s >= 0) {
							SetEntityRenderMode(i, RENDER_TRANSALPHA);
							SetEntityRenderColor(i, _, _, _, cvar_alpha_s);
						} else {
							SetEntityRenderMode(i, RENDER_NORMAL);
							SetEntityRenderColor(i, _, _, _, _);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_d || FirstCaching) {
		cvar_alpha_d = GetConVarInt(hcvar_alpha_d);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_alpha_d >= 0) {
							SetEntityRenderMode(i, RENDER_TRANSALPHA);
							SetEntityRenderColor(i, _, _, _, cvar_alpha_d);
						} else {
							SetEntityRenderMode(i, RENDER_NORMAL);
							SetEntityRenderColor(i, _, _, _, _);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_alpha_t || FirstCaching) {
		cvar_alpha_t = GetConVarInt(hcvar_alpha_t);
		if (!FirstCaching) {
			new i = -1;
			while ((i = FindEntityByClassname(i, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
				if (IsValidEntity(i)) {
					new engie = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
					if (IsFriendly[engie]) {
						if (cvar_alpha_t >= 0) {
							SetEntityRenderMode(i, RENDER_TRANSALPHA);
							SetEntityRenderColor(i, _, _, _, cvar_alpha_t);
						} else {
							SetEntityRenderMode(i, RENDER_NORMAL);
							SetEntityRenderColor(i, _, _, _, _);
						}
					}
				}
			}
		}
	}
	if (hHandle == hcvar_nobuild_s || FirstCaching) {
		cvar_nobuild_s = GetConVarBool(hcvar_nobuild_s);
	}
	if (hHandle == hcvar_nobuild_d || FirstCaching) {
		cvar_nobuild_d = GetConVarBool(hcvar_nobuild_d);
	}
	if (hHandle == hcvar_nobuild_t || FirstCaching) {
		cvar_nobuild_t = GetConVarBool(hcvar_nobuild_t);
	}
	if (hHandle == hcvar_killbuild_h_s || FirstCaching) {
		cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_h_s);
	}
	if (hHandle == hcvar_killbuild_h_d || FirstCaching) {
		cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_h_d);
	}
	if (hHandle == hcvar_killbuild_h_t || FirstCaching) {
		cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_h_t);
	}
	if (hHandle == hcvar_killbuild_f_s || FirstCaching) {
		cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_f_s);
	}
	if (hHandle == hcvar_killbuild_f_d || FirstCaching) {
		cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_f_d);
	}
	if (hHandle == hcvar_killbuild_f_t || FirstCaching) {
		cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_f_t);
	}
	if (hHandle == hcvar_blockweps_black || FirstCaching) {
		new String:strWeaponsBlack[256];
		GetConVarString(hcvar_blockweps_black, strWeaponsBlack, sizeof(strWeaponsBlack));
		if (StrEqual(strWeaponsBlack, "0")) {
			strWeaponsBlack = "";
		} else if (StrEqual(strWeaponsBlack, "1")) {
			strWeaponsBlack = DEFAULT_BLOCKED_WEAPONS;
		}
		for (new i=1; i < sizeof(cvar_blockweps_black) && !StrEqual(cvar_blockweps_black[i], "-1"); i++) {
			cvar_blockweps_black[i] = "-1";
		}
		ExplodeString(strWeaponsBlack, ",", cvar_blockweps_black, sizeof(cvar_blockweps_black), sizeof(cvar_blockweps_black[]));
	}
	if (hHandle == hcvar_blockweps_white || FirstCaching) {
		new String:strWeaponsWhite[256];
		GetConVarString(hcvar_blockweps_white, strWeaponsWhite, sizeof(strWeaponsWhite));
		if (StrEqual(strWeaponsWhite, "0")) {
			strWeaponsWhite = "";
		} else if (StrEqual(strWeaponsWhite, "1")) {
			strWeaponsWhite = DEFAULT_WHITELISTED_WEAPONS;
		}
		for (new i=1; i < sizeof(cvar_blockweps_white) && !StrEqual(cvar_blockweps_white[i], "-1"); i++) {
			cvar_blockweps_white[i] = "-1";
		}
		ExplodeString(strWeaponsWhite, ",", cvar_blockweps_white, sizeof(cvar_blockweps_white), sizeof(cvar_blockweps_white[]));
	}
	if (hHandle == hcvar_blockweps_classes || FirstCaching) {
		new String:strWeaponsClass[256];
		GetConVarString(hcvar_blockweps_classes, strWeaponsClass, sizeof(strWeaponsClass));
		if (StrEqual(strWeaponsClass, "0")) {
			strWeaponsClass = "";
		} else if (StrEqual(strWeaponsClass, "1")) {
			strWeaponsClass = DEFAULT_BLOCKED_WEAPONCLASSES;
		}
		for (new i=1; i < sizeof(cvar_blockweps_classes) && !StrEqual(cvar_blockweps_classes[i], "-1"); i++) {
			cvar_blockweps_classes[i] = "-1";
		}
		ExplodeString(strWeaponsClass, ",", cvar_blockweps_classes, sizeof(cvar_blockweps_classes), sizeof(cvar_blockweps_classes[]));
	}
	if (hHandle == hcvar_blocktaunt || FirstCaching) {
		new String:strWeaponsTaunt[256];
		GetConVarString(hcvar_blocktaunt, strWeaponsTaunt, sizeof(strWeaponsTaunt));
		if (StrEqual(strWeaponsTaunt, "0")) {
			strWeaponsTaunt = "";
		} else if (StrEqual(strWeaponsTaunt, "1")) {
			strWeaponsTaunt = DEFAULT_BLOCKED_TAUNTS;
		}
		for (new i=1; i < sizeof(cvar_blocktaunt) && !StrEqual(cvar_blocktaunt[i], "-1"); i++) {
			cvar_blocktaunt[i] = "-1";
		}
		ExplodeString(strWeaponsTaunt, ",", cvar_blocktaunt, sizeof(cvar_blocktaunt), sizeof(cvar_blocktaunt[]));
	}
	if (hHandle == hcvar_overlay || FirstCaching) {
		new String:strOverlay[256];
		GetConVarString(hcvar_overlay, strOverlay, sizeof(strOverlay));
		if (StrEqual(strOverlay, "0"))
			strOverlay = "0";
		if (StrEqual(strOverlay, ""))
			strOverlay = "0";
		if (StrEqual(strOverlay, "1"))
			strOverlay = DEFAULT_OVERLAY_1;
		if (StrEqual(strOverlay, "2"))
			strOverlay = DEFAULT_OVERLAY_2;
		if (StrEqual(strOverlay, "3"))
			strOverlay = DEFAULT_OVERLAY_3;
		if (StrEqual(strOverlay, "4"))
			strOverlay = DEFAULT_OVERLAY_4;
		if (StrEqual(strOverlay, "5"))
			strOverlay = DEFAULT_OVERLAY_5;
		if (StrEqual(strOverlay, "6"))
			strOverlay = DEFAULT_OVERLAY_6;
		cvar_overlay = strOverlay;
		if (!FirstCaching) {
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					if (!StrEqual(cvar_overlay, "0")) {
						SetOverlay(i, true);
					} else {
						SetOverlay(i, false);
					}
				}
			}
		}
	}
	if (FirstCaching) {
		HookCvars();
		HookThings();
		FirstCaching = false;
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
	HookConVarChange(hcvar_stopcap, cvarChange);
	HookConVarChange(hcvar_stopintel, cvarChange);
	HookConVarChange(hcvar_ammopack, cvarChange);
	HookConVarChange(hcvar_healthpack, cvarChange);
	HookConVarChange(hcvar_money, cvarChange);
	HookConVarChange(hcvar_pumpkin, cvarChange);
	HookConVarChange(hcvar_airblastkill, cvarChange);
	HookConVarChange(hcvar_funcbutton, cvarChange);
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