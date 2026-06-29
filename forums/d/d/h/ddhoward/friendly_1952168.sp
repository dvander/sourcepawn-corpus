/*
Changes since 13.0509
	sm_friendly_alpha_w now applies to Powerup Canteens
	Fixed a bug involving players using the command while dead, while sm_friendly_remember = 0
	cached cvars, should slightly improve performance
	allow admins to target other players
		sm_friendly_targetothers
	Each command (other than sm_friendly itself) now has two valid names
To-do
	anti-AFK
	find a way to retrieve the owner of a sticky, so friendly stickies can be given invuln/alpha
	particle effect
	cvars to clear domination status, or take status into account when determining if damage nullification applies
	figure out how to make Friendly players invisible to bosses/bots
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>
#include <colors>

#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#tryinclude <updater> //If updater.inc cannot be found, you will get errors on compilation. You should be able to safely ignore them.

#define PLUGIN_VERSION "13.0514"
#define UPDATE_URL "http://ddhbitbucket.crabdance.com/sm-friendly-mode/raw/default/friendlymodeupdate.txt"

#define CHAT_PREFIX "{olive}[Friendly]{default}"
#define CHAT_PREFIX_NOCOLOR "[Friendly]"
#define CHAT_PREFIX_NOCOLOR_SPACE "[Friendly] "
#define CHAT_NAME "{olive}Friendly Mode{default}"
#define CHAT_NAME_NOCOLOR "Friendly Mode"

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
new _:SeenAdvert[MAXPLAYERS+1] = {0, ...};
new _:FriendlyPlayerCount = 0;

new Handle:hcvar_version = INVALID_HANDLE;
//new String:cvar_version = PLUGIN_VERSION;

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

new Handle:hcvar_action_h = INVALID_HANDLE;
new _:cvar_action_h = -2;
new Handle:hcvar_action_f = INVALID_HANDLE;
new _:cvar_action_f = -2;
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
		SeenAdvert[i] = 5;
		if (IsClientInGame(i)) {
			HookClient(i);
		}
	}
	
	hcvar_version = CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Friendly Mode Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(hcvar_version, PLUGIN_VERSION);

	hcvar_enabled = CreateConVar("sm_friendly_enabled", "1", "(0/1) Enables/Disables Friendly Mode", FCVAR_PLUGIN|FCVAR_DONTRECORD);

	
	hcvar_update = CreateConVar("sm_friendly_update", "1", "(0/1/2) Updater compatibility. 0 = disabled, 1 = auto-download, 2 = auto-download and auto-install", FCVAR_PLUGIN);
	hcvar_logging = CreateConVar("sm_friendly_logging", "2", "(0/1/2) 0 = No logging, 1 = Will log use of sm_friendly_admin, 2 = Will log use of sm_friendly_admin and sm_friendly.", FCVAR_PLUGIN);
	hcvar_advert = CreateConVar("sm_friendly_advert", "1", "(0/1) If enabled, players will see a message informing them about the plugin when they join the server.", FCVAR_PLUGIN);
	hcvar_maxfriendlies = CreateConVar("sm_friendly_maxfriendlies", "32", "(Any positive integer) This sets a limit how many players can simultaneously be Friendly.", FCVAR_PLUGIN);

	hcvar_action_h = CreateConVar("sm_friendly_action_h", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Hostile? See this plugin's thread for details.", FCVAR_PLUGIN);
	hcvar_action_f = CreateConVar("sm_friendly_action_f", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Friendly? See this plugin's thread for details.", FCVAR_PLUGIN);
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
	
	HookConVarChange(hcvar_version, cvarChange);
	HookConVarChange(hcvar_enabled, cvarChange);
	HookConVarChange(hcvar_update, cvarChange);
	HookConVarChange(hcvar_logging, cvarChange);
	HookConVarChange(hcvar_advert, cvarChange);
	HookConVarChange(hcvar_maxfriendlies, cvarChange);
	HookConVarChange(hcvar_action_h, cvarChange);
	HookConVarChange(hcvar_action_f, cvarChange);
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

	RegAdminCmd("sm_friendly", UseFriendlyCmd, 0, "Toggles Friendly Mode");
	RegAdminCmd("sm_friendly_admin", OnToggleAdmin, ADMFLAG_BAN, "Players who toggle this command will be able to damage friendly players while not friendly themselves.");
	RegAdminCmd("sm_friendly_v", smFriendlyVer, 0, "Outputs the current version to the chat.");
	RegAdminCmd("sm_friendly_r", Restart_Plugin, ADMFLAG_RCON, "Unloads and reloads plugin smx, relies on updater.inc");

	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("player_builtobject", Object_Built);
	HookEvent("player_sapped_object", Object_Sapped);
	HookEvent("post_inventory_application", Inventory_App);
	HookEvent("teamplay_round_active", Round_Start);
	HookEvent("object_deflected", Airblast);

	AutoExecConfig(false, "friendly");

	AddNormalSoundHook(Hook_NormalSound);

	HookThings();

	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(TauntCmd, "+taunt");

}

public OnConfigsExecuted() {
	CacheCvars();
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	HookThings();
}

OnUseCmdOnSelf(client) {
	if (client != 0) {
		if (cvar_enabled) {
			if (IsPlayerAlive(client)) {
				UsedCommandAlive(client);
			} else {
				UsedCommandDead(client);
			}
		} else {
			CPrintToChat(client, "%s Friendly Mode is currently disabled on this server.", CHAT_PREFIX);
		}
		DisableAdvert(client);
	} else {
	ReplyToCommand(client, "%s Not a valid client. You must be in the game to use sm_friendly.", CHAT_PREFIX_NOCOLOR);
	}
}

UsedCommandAlive(const client) {
	if (RequestedChange[client]) {
		RequestedChange[client] = false;
		CPrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
	} else {
		if (IsFriendly[client]) {
			if (IsAdmin[client]) {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
			} else if (cvar_action_h == -2) {
				CPrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
			} else if (cvar_action_h == -1) {
				CPrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				ForcePlayerSuicide(client);
			} else if (cvar_action_h == 0) {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
			} else if (cvar_action_h > 0) {
				MakeClientHostile(client);
				SlapPlayer(client, cvar_action_h);
				CPrintToChat(client, "%s You are no longer Friendly, but took damage because of the switch!", CHAT_PREFIX);
			}
		} else {
			if (IsAdmin[client]) {
				MakeClientFriendly(client);
				CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
			} else if (cvar_action_f == -2) {
				CPrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
			} else if (cvar_action_f == -1) {
				CPrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				ForcePlayerSuicide(client);
			} else if (cvar_action_f == 0) {
				if (FriendlyPlayerCount < cvar_maxfriendlies) {
					MakeClientFriendly(client);
					CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
					FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
				} else {
					CPrintToChat(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
				}
			} else if (cvar_action_f > 0) {
				if (FriendlyPlayerCount < cvar_maxfriendlies) {
					MakeClientFriendly(client);
					SlapPlayer(client, cvar_action_f);
					CPrintToChat(client, "%s You were made Friendly, but took damage because of the switch!", CHAT_PREFIX);
				} else {
					CPrintToChat(client, "%s There are too many Friendly players already!", CHAT_PREFIX);
				}
			}
		}
	}
}

UsedCommandDead(const client) {
	if (RequestedChange[client]) {
		RequestedChange[client] = false;
		CPrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
		if (IsFriendly[client] && !cvar_remember) {
			RFETRIZ[client] = true;
		}
	} else {
		RequestedChange[client] = true;
		CPrintToChat(client, "%s You will toggle Friendly mode upon respawning.", CHAT_PREFIX);
		RFETRIZ[client] = false;
	}
}

public Action:OnToggleAdmin(client, args) {
	if (client != 0) {
		DisableAdvert(client);
		if (IsAdmin[client]) {
			IsAdmin[client] = false;
			CPrintToChat(client, "%s You are no longer bypassing Friendly Mode.", CHAT_PREFIX);
			if (cvar_logging > 0) {
				LogAction(client, -1, "\"%L\" turned off Friendly Admin Bypass mode.", client);
			}
		} else {
			if (cvar_enabled) {
				IsAdmin[client] = true;
				CPrintToChat(client, "%s You are now bypassing Friendly Mode.", CHAT_PREFIX);
				if (cvar_logging > 0) {
					LogAction(client, -1, "\"%L\" activated Friendly Admin Bypass mode.", client);
				}
			} else {
				CPrintToChat(client, "%s Friendly Mode is currently disabled on this server.", CHAT_PREFIX);
			}
		}
	} else {
		ReplyToCommand(client, "%s Not a valid client. You must be in the game to use sm_friendly_admin.", CHAT_PREFIX_NOCOLOR);
	}
	return Plugin_Handled;
}

public Action:UseFriendlyCmd(client, args) {
	new numargs = GetCmdArgs();
	new String:arg1[64];
	new String:arg2[2];
	new String:arg3[2];
	new target[MAXPLAYERS];
	new String:target_name[MAX_TARGET_LENGTH];
	new method = 0;
	new bool:tn_is_ml;
	new numtargets;
	if (numargs == 0 || !CheckCommandAccess(client, "sm_friendly_targetothers", ADMFLAG_BAN, true)) {
		OnUseCmdOnSelf(client);
		return Plugin_Handled;
	}
	if (numargs > 3) {
		ReplyToCommand(client, "%s Usage: \"sm_friendly_force [target] [0/1] [0/1]\"", CHAT_PREFIX_NOCOLOR);
		return Plugin_Handled;
	}
	if (numargs >= 1) {
		GetCmdArg(1, arg1, sizeof(arg1));
		if ((numtargets = ProcessTargetString(arg1, client, target, sizeof(target), 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, numtargets);
			return Plugin_Handled;
		}
	}
	if (numargs >= 2) {
		GetCmdArg(2, arg2, sizeof(arg2));
		if (!(StrEqual(arg2, "1") || StrEqual(arg2, "0"))) {
			ReplyToCommand(client, "%s Second argument must be either 0 or 1. 0 to disable Friendly, or 1 to enable.", CHAT_PREFIX_NOCOLOR);
			return Plugin_Handled;
		}
	}
	if (numargs == 3) {
		GetCmdArg(3, arg3, sizeof(arg3));
		if (!(StrEqual(arg3, "1") || StrEqual(arg3, "0"))) {
			ReplyToCommand(client, "%s Third argument must be either 0 or 1. 0 to toggle Friendly instantly, or 1 to slay the player.", CHAT_PREFIX_NOCOLOR);
			return Plugin_Handled;
		}
		method = StringToInt(arg3);
	}
	if (numtargets == 1) {
		new singletarget = target[0];
		if (IsFriendly[singletarget] && StrEqual(arg2, "1")) {
			ReplyToCommand(client, "%s That player is already Friendly!", CHAT_PREFIX_NOCOLOR);
			return Plugin_Handled;
		}
		if (!IsFriendly[singletarget] && StrEqual(arg2, "0")) {
			ReplyToCommand(client, "%s That player is already non-Friendly.", CHAT_PREFIX_NOCOLOR);
			return Plugin_Handled;
		}
	}
	if (numargs == 1) {
		if (cvar_logging > 0) {
			LogAction(client, -1, "\"%L\" toggled Friendly mode on %s.", client, target_name);
		}
		ShowActivity2(client, CHAT_PREFIX_NOCOLOR_SPACE, "Toggled Friendly on %s.", target_name);
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (IsFriendly[currenttarget]) {
				MakeClientHostile(currenttarget);
				if (currenttarget != client) {
					CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
				}
				if (method == 1 && !IsAdmin[currenttarget]) {
					ForcePlayerSuicide(currenttarget);
				}
			} else {
				MakeClientFriendly(currenttarget);
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
			}
		}
	} else if (numargs > 1) {
		if (StrEqual(arg2, "1")) {
			ShowActivity2(client, CHAT_PREFIX_NOCOLOR_SPACE, "Enabled Friendly on %s.", target_name);
			if (cvar_logging > 0) {
				LogAction(client, -1, "\"%L\" enabled Friendly mode on %s.", client, target_name);
			}
		} else if (StrEqual(arg2, "0")) {
			ShowActivity2(client, CHAT_PREFIX_NOCOLOR_SPACE, "Disabled Friendly on %s.", target_name);
			if (cvar_logging > 0) {
				LogAction(client, -1, "\"%L\" disabled Friendly mode on %s.", client, target_name);
			}
		}
		for (new i = 0; i < numtargets; i++) {
			new currenttarget = target[i];
			if (StrEqual(arg2, "0")) {
				if (IsFriendly[currenttarget]) {
					MakeClientHostile(currenttarget);
					if (currenttarget != client) {
						CPrintToChat(currenttarget, "%s An admin has forced you out of Friendly Mode.", CHAT_PREFIX);
					}
					if (method == 1 && !IsAdmin[currenttarget]) {
						ForcePlayerSuicide(currenttarget);
					}
				}
			}
			if (StrEqual(arg2, "1")) {
				if (!IsFriendly[currenttarget]) {
					MakeClientFriendly(currenttarget);
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
				}
			}
		}
	}
	return Plugin_Handled;
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (cvar_advert) {
		DoAdvert(client);
	}
	if (RFETRIZ[client]) {
		CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
		RequestedChange[client] = false;
		RFETRIZ[client] = false;
		// Inventory_App should take care of things from here
	} else if (RequestedChange[client]) {
		if (IsFriendly[client]) {
			MakeClientHostile(client);
			CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
		} else {
			if (FriendlyPlayerCount < cvar_maxfriendlies) {
				MakeClientFriendly(client);
				CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
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
			}
		}
	}
}

public OnClientPutInServer(client) {
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	IsAdmin[client] = false;
	RFETRIZ[client] = false;
	HookClient(client);
	SeenAdvert[client] = 0;
}

public OnClientDisconnect(client) {
	if (IsFriendly[client]) {
		FriendlyPlayerCount = FriendlyPlayerCount - 1;
	}
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	IsAdmin[client] = false;
	RFETRIZ[client] = false;

	UnhookClient(client);
}

MakeClientHostile(const client) {
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
	if (cvar_logging == 2) {
		LogAction(client, -1, "\"%L\" turned off Friendly mode.", client);
	}
}

MakeClientFriendly(const client) {
	FriendlyPlayerCount = FriendlyPlayerCount + 1;
	MakeBuildingsFriendly(client);
	ReapplyFriendly(client);
	RemoveMySappers(client);
	if (cvar_stopintel) {
		FakeClientCommand(client, "dropitem");
	}
	if (cvar_logging == 2) {
		LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
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

public OnPluginEnd() {
	for (new i=1; i <= MaxClients; i++) {
		UnhookClient(i);
		if (IsFriendly[i]) {
			MakeClientHostile(i);
			IsAdmin[i] = false;
			if (cvar_action_h < 0) {
				ForcePlayerSuicide(i);
			} if (cvar_action_h > 0) {
				SlapPlayer(i, cvar_action_h);
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
	if(StrContains(classname, "item_ammopack_", false) != -1) {
		SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
		SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
	}
	if(StrContains(classname, "tf_ammo_pack", false) != -1) {
		SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
		SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
	}
	if(StrContains(classname, "tf_projectile_stun_ball", false) != -1) {
		SDKHook(entity, SDKHook_StartTouch, OnAmmoPackTouch);
		SDKHook(entity, SDKHook_Touch, OnAmmoPackTouch);
	}
	if(StrContains(classname, "item_healthkit_", false) != -1) {
		SDKHook(entity, SDKHook_StartTouch, OnHealthPackTouch);
		SDKHook(entity, SDKHook_Touch, OnHealthPackTouch);
	}
	if(StrContains(classname, "item_currencypack_", false) != -1) {
		SDKHook(entity, SDKHook_StartTouch, OnMoneyTouch);
		SDKHook(entity, SDKHook_Touch, OnMoneyTouch);
	}
	if(StrContains(classname, "trigger_capture_area", false) != -1) {
		SDKHook(entity, SDKHook_StartTouch, OnCPTouch );
		SDKHook(entity, SDKHook_Touch, OnCPTouch );
	}
	if(StrContains(classname, "item_teamflag", false) != -1) {
		SDKHook(entity, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(entity, SDKHook_Touch, OnFlagTouch );
	}
	if(StrContains(classname, "tf_pumpkin_bomb", false) != -1) {
		SDKHook(entity, SDKHook_OnTakeDamage, PumpkinTakeDamage);
	}
	if(StrContains(classname, "tf_projectile_pipe_remote", false) != -1) {
		SDKHook(entity, SDKHook_OnTakeDamage, StickyTakeDamage);
	}
}

HookThings() {
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
		SDKHook(ent, SDKHook_StartTouch, OnCPTouch );
		SDKHook(ent, SDKHook_Touch, OnCPTouch );
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_pumpkin_bomb"))!=INVALID_ENT_REFERENCE) {
		SDKHook(ent, SDKHook_OnTakeDamage, PumpkinTakeDamage);
	}
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
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
	i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
	while ((i = FindEntityByClassname(i, "tf_powerup_bottle")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) {
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
}


stock SetWeaponInvis(client, bool:set = true) {
	new alpha = cvar_alpha_wep;
	for(new i=0; i < 5; i++) {
		new entity = GetPlayerWeaponSlot(client, i);
		if(entity != -1) {
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
}

public Action:Updater_OnPluginChecking() {
	if (cvar_update > 0) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
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
}

public Action:Restart_Plugin(client, args) {
	if (client != 0) {
		CPrintToChat(client, "%s Attempting plugin reload...", CHAT_PREFIX);
	} else {
		ReplyToCommand(client, "%s Attempting plugin reload...", CHAT_PREFIX_NOCOLOR);
	}
	ReloadPlugin();
	return Plugin_Handled;
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Goomba Stomp Integration */

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower) {
	if ((IsFriendly[attacker] 
		|| IsFriendly[victim]) 
	&& (!IsAdmin[attacker]) 
	&& (cvar_goomba)) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
RTD Integration */

public Action:RTD_CanRollDice(client) {
	if (IsFriendly[client] 
	&& !IsAdmin[client] 
	&& cvar_blockrtd) {
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
		ShowFriendlyVer(client);
	}
}

public Action:smFriendlyVer(client, args) {
	ShowFriendlyVer(client);
	return Plugin_Handled;
}

DisableAdvert(const client) {
	SeenAdvert[client] = 5;
}

ShowFriendlyVer(const client) {
	if (client != 0) {
		CPrintToChat(client, "%s This server is currently running %s v.{lightgreen}%s{default}. Type {olive}/friendly{default} to use.", CHAT_PREFIX, CHAT_NAME, PLUGIN_VERSION);
		DisableAdvert(client);
	} else {
		ReplyToCommand(client, "%s Your server is currently running %s v.%s.", CHAT_PREFIX_NOCOLOR, CHAT_NAME_NOCOLOR, PLUGIN_VERSION);
	}
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

CacheCvars() {
//	cvar_version = GetConVarString(hcvar_version);
	cvar_enabled = GetConVarBool(hcvar_enabled);
	cvar_logging = GetConVarInt(hcvar_logging);
	cvar_advert = GetConVarBool(hcvar_advert);
	cvar_update = GetConVarInt(hcvar_update);
	cvar_maxfriendlies = GetConVarInt(hcvar_maxfriendlies);
	cvar_action_h = GetConVarInt(hcvar_action_h);
	cvar_action_f = GetConVarInt(hcvar_action_f);
	cvar_remember = GetConVarBool(hcvar_remember);
	cvar_goomba = GetConVarBool(hcvar_goomba);
	cvar_blockrtd = GetConVarBool(hcvar_blockrtd);
	cvar_stopcap = GetConVarBool(hcvar_stopcap);
	cvar_stopintel = GetConVarBool(hcvar_stopintel);
	cvar_ammopack = GetConVarBool(hcvar_ammopack);
	cvar_healthpack = GetConVarBool(hcvar_healthpack);
	cvar_money = GetConVarBool(hcvar_money);
	cvar_pumpkin = GetConVarBool(hcvar_pumpkin);
	cvar_airblastkill = GetConVarBool(hcvar_airblastkill);
	cvar_invuln_p = GetConVarInt(hcvar_invuln_p);
	cvar_invuln_s = GetConVarInt(hcvar_invuln_s);
	cvar_invuln_d = GetConVarInt(hcvar_invuln_d);
	cvar_invuln_t = GetConVarInt(hcvar_invuln_t);
	cvar_notarget_p = GetConVarBool(hcvar_notarget_p);
	cvar_notarget_s = GetConVarBool(hcvar_notarget_s);
	cvar_notarget_d = GetConVarBool(hcvar_notarget_d);
	cvar_notarget_t = GetConVarBool(hcvar_notarget_t);
	cvar_noblock_p = GetConVarInt(hcvar_noblock_p);
	cvar_noblock_s = GetConVarInt(hcvar_noblock_s);
	cvar_noblock_d = GetConVarInt(hcvar_noblock_d);
	cvar_noblock_t = GetConVarInt(hcvar_noblock_t);
	cvar_alpha_p = GetConVarInt(hcvar_alpha_p);
	cvar_alpha_w = GetConVarInt(hcvar_alpha_w);
	cvar_alpha_wep = GetConVarInt(hcvar_alpha_wep);
	cvar_alpha_s = GetConVarInt(hcvar_alpha_s);
	cvar_alpha_d = GetConVarInt(hcvar_alpha_d);
	cvar_alpha_t = GetConVarInt(hcvar_alpha_t);
	cvar_nobuild_s = GetConVarBool(hcvar_nobuild_s);
	cvar_nobuild_d = GetConVarBool(hcvar_nobuild_d);
	cvar_nobuild_t = GetConVarBool(hcvar_nobuild_t);
	cvar_killbuild_h_s = GetConVarBool(hcvar_killbuild_h_s);
	cvar_killbuild_h_d = GetConVarBool(hcvar_killbuild_h_d);
	cvar_killbuild_h_t = GetConVarBool(hcvar_killbuild_h_t);
	cvar_killbuild_f_s = GetConVarBool(hcvar_killbuild_f_s);
	cvar_killbuild_f_d = GetConVarBool(hcvar_killbuild_f_d);
	cvar_killbuild_f_t = GetConVarBool(hcvar_killbuild_f_t);

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
}

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	CacheCvars();
	if (hHandle == hcvar_invuln_p) {
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
	if (hHandle == hcvar_invuln_s) {
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
	if (hHandle == hcvar_invuln_d) {
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
	if (hHandle == hcvar_invuln_t) {
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
	if (hHandle == hcvar_notarget_p) {
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
	if (hHandle == hcvar_notarget_s) {
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
	if (hHandle == hcvar_notarget_d) {
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
	if (hHandle == hcvar_notarget_t) {
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
	if (hHandle == hcvar_alpha_p) {
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
	if (hHandle == hcvar_alpha_w) {
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
	if (hHandle == hcvar_alpha_wep) {
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
	if (hHandle == hcvar_alpha_s) {
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
	if (hHandle == hcvar_alpha_d) {
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
	if (hHandle == hcvar_alpha_t) {
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
	if (hHandle == hcvar_noblock_p) {
		for (new i=1; i <= MaxClients; i++) {
			if (IsFriendly[i]) {
				ApplyNoblock(i, false);
			}
		}
	}
	if (hHandle == hcvar_noblock_s) {
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
	if (hHandle == hcvar_noblock_d) {
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
	if (hHandle == hcvar_noblock_t) {
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
	if (hHandle == hcvar_overlay) {
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
	if (hHandle == hcvar_version) {
		SetConVarString(hHandle, PLUGIN_VERSION);
	}
	if (hHandle == hcvar_enabled) {
		if (cvar_enabled) {
			CPrintToChatAll("%s An admin has re-enabled Friendly Mode. Type {olive}/friendly{default} to use.", CHAT_PREFIX);
		} else {
			CPrintToChatAll("%s An admin has disabled Friendly Mode.", CHAT_PREFIX);
			for (new i=1; i <= MaxClients; i++) {
				if (IsFriendly[i]) {
					MakeClientHostile(i);
					IsAdmin[i] = false;
					if (cvar_action_h < 0) {
						ForcePlayerSuicide(i);
					} if (cvar_action_h > 0) {
						SlapPlayer(i, cvar_action_h);
					}
				}
			}
		}
	}
}