/*
Changes since 12.0426
Massive Changes and improvements to weapon blocker
added check to see if the game running is TF2. Plugin will refuse to load on other games.
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

#define PLUGIN_VERSION "13.0503"
#define UPDATE_URL "http://ddhbitbucket.crabdance.com/sm-friendly-mode/raw/default/friendlymodeupdate.txt"

#define CHAT_PREFIX "{olive}[Friendly]{default}"
#define CHAT_PREFIX_NOCOLOR "[Friendly]"
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

new bool:IsFriendly[MAXPLAYERS+1] = {false, ...};
new bool:RequestedChange[MAXPLAYERS+1] = {false, ...};
new bool:IsAdmin[MAXPLAYERS+1] = {false, ...};
new bool:RFETRIZ[MAXPLAYERS+1] = {false, ...};
new _:SeenAdvert[MAXPLAYERS+1] = {0, ...};

new String:g_classStrBuffer[255][32];
new String:g_indexStrBufferBlack[255][8];
new String:g_indexStrBufferWhite[255][8];
new String:g_tauntStrBuffer[255][32];

new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_version = INVALID_HANDLE;
new Handle:cvar_logging = INVALID_HANDLE;
new Handle:cvar_advert = INVALID_HANDLE;

new Handle:cvar_action_h = INVALID_HANDLE;
new Handle:cvar_action_f = INVALID_HANDLE;
new Handle:cvar_remember = INVALID_HANDLE;
new Handle:cvar_update = INVALID_HANDLE;
new Handle:cvar_goomba = INVALID_HANDLE;
new Handle:cvar_blockrtd = INVALID_HANDLE;
new Handle:cvar_stopcap = INVALID_HANDLE;
new Handle:cvar_stopintel = INVALID_HANDLE;
new Handle:cvar_overlay = INVALID_HANDLE;

new Handle:cvar_blockweps_black = INVALID_HANDLE;
new Handle:cvar_blockweps_classes = INVALID_HANDLE;
new Handle:cvar_blockweps_white = INVALID_HANDLE;
new Handle:cvar_blocktaunt = INVALID_HANDLE;

new Handle:cvar_invuln_p = INVALID_HANDLE;
new Handle:cvar_invuln_s = INVALID_HANDLE;
new Handle:cvar_invuln_d = INVALID_HANDLE;
new Handle:cvar_invuln_t = INVALID_HANDLE;

new Handle:cvar_notarget_p = INVALID_HANDLE;
new Handle:cvar_notarget_s = INVALID_HANDLE;
new Handle:cvar_notarget_d = INVALID_HANDLE;
new Handle:cvar_notarget_t = INVALID_HANDLE;

new Handle:cvar_noblock_p = INVALID_HANDLE;
new Handle:cvar_noblock_s = INVALID_HANDLE;
new Handle:cvar_noblock_d = INVALID_HANDLE;
new Handle:cvar_noblock_t = INVALID_HANDLE;

new Handle:cvar_alpha_p = INVALID_HANDLE;
new Handle:cvar_alpha_w = INVALID_HANDLE;
new Handle:cvar_alpha_wep = INVALID_HANDLE;
new Handle:cvar_alpha_s = INVALID_HANDLE;
new Handle:cvar_alpha_d = INVALID_HANDLE;
new Handle:cvar_alpha_t = INVALID_HANDLE;

new Handle:cvar_nobuild_s = INVALID_HANDLE;
new Handle:cvar_nobuild_d = INVALID_HANDLE;
new Handle:cvar_nobuild_t = INVALID_HANDLE;
new Handle:cvar_killbuild_h_s = INVALID_HANDLE;
new Handle:cvar_killbuild_h_d = INVALID_HANDLE;
new Handle:cvar_killbuild_h_t = INVALID_HANDLE;
new Handle:cvar_killbuild_f_s = INVALID_HANDLE;
new Handle:cvar_killbuild_f_d = INVALID_HANDLE;
new Handle:cvar_killbuild_f_t = INVALID_HANDLE;


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
	
	cvar_version = CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Friendly Mode Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(cvar_version, PLUGIN_VERSION);
	HookConVarChange(cvar_version, attemptVersionChange);

	cvar_enabled = CreateConVar("sm_friendly_enabled", "1", "(0/1) Enables/Disables Friendly Mode", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	HookConVarChange(cvar_enabled, smEnableChange);
	
	cvar_update = CreateConVar("sm_friendly_update", "1", "(0/1/2) Updater compatibility. 0 = disabled, 1 = auto-download, 2 = auto-download and auto-install", FCVAR_PLUGIN);
	cvar_logging = CreateConVar("sm_friendly_logging", "2", "(0/1/2) 0 = No logging, 1 = Will log use of sm_friendly_admin, 2 = Will log use of sm_friendly_admin and sm_friendly.", FCVAR_PLUGIN);
	cvar_advert = CreateConVar("sm_friendly_advert", "1", "(0/1) If enabled, players will see a message informing them about the plugin when they join the server.", FCVAR_PLUGIN);

	cvar_action_h = CreateConVar("sm_friendly_action_h", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Hostile? See this plugin's thread for details.", FCVAR_PLUGIN);
	cvar_action_f = CreateConVar("sm_friendly_action_f", "-2", "(Any integer, -2 or greater) What action to take on living players who want to become Friendly? See this plugin's thread for details.", FCVAR_PLUGIN);
	cvar_remember = CreateConVar("sm_friendly_remember", "0", "(0/1) If enabled, a player who somehow dies while Friendly be Friendly upon respawn.", FCVAR_PLUGIN);
	cvar_goomba = CreateConVar("sm_friendly_goomba", "1", "(0/1) If enabled, Goomba Stomp will follow the same damage rules of Friendly mode as regular attacks.", FCVAR_PLUGIN);
	cvar_blockrtd = CreateConVar("sm_friendly_blockrtd", "1", "(0/1) If enabled, Friendly players will be unable to activate Roll The Dice.", FCVAR_PLUGIN);
	cvar_stopcap = CreateConVar("sm_friendly_stopcap", "1", "(0/1) If enabled, Friendly players will be unable to cap points or push carts.", FCVAR_PLUGIN);
	cvar_stopintel = CreateConVar("sm_friendly_stopintel", "1", "(0/1) If enabled, Friendly players will be unable to grab the intel.", FCVAR_PLUGIN);
	cvar_overlay = CreateConVar("sm_friendly_overlay", "0", "You can set a path to an overlay to display to Friendly players. Set to 0 to disable.", FCVAR_PLUGIN);

	cvar_blockweps_classes = CreateConVar("sm_friendly_blockwep_classes", "1", "What weapon classes to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	cvar_blockweps_black = CreateConVar("sm_friendly_blockweps", "1", "What weapon index definiteion numbers to block? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	cvar_blockweps_white = CreateConVar("sm_friendly_blockweps_whitelist", "1", "What weapon index definiteion numbers to whitelist? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	cvar_blocktaunt = CreateConVar("sm_friendly_blocktaunt", "1", "What weapon index definition numbers to block taunting with? Set to 0 to disable, 1 to use defaults, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	
	cvar_invuln_p = CreateConVar("sm_friendly_invuln", "2", "(0/1/2/3) 0 = Friendly players have full godmode. 1 = Buddha. 2 = Only invulnerable to other players. 3 = Invuln to other players AND himself.", FCVAR_PLUGIN);
	cvar_invuln_s = CreateConVar("sm_friendly_invuln_s", "0", "(0/1/2) 0 = Disabled, 1 = Friendly sentries will be invulnerable to other players, 2 = Friendly sentries have full Godmode.", FCVAR_PLUGIN);
	cvar_invuln_d = CreateConVar("sm_friendly_invuln_d", "0", "(0/1/2) 0 = Disabled, 1 = Friendly dispensers will be invulnerable to other players, 2 = Friendly dispensers have full Godmode.", FCVAR_PLUGIN);
	cvar_invuln_t = CreateConVar("sm_friendly_invuln_t", "0", "(0/1/2) 0 = Disabled, 1 = Friendly teleporters will be invulnerable to other players, 2 = Friendly teleporters have full Godmode.", FCVAR_PLUGIN);

	cvar_notarget_p = CreateConVar("sm_friendly_notarget", "1", "(0/1) If enabled, a Friendly player will be invisible to sentries, immune to airblasts, etc.", FCVAR_PLUGIN);
	cvar_notarget_s = CreateConVar("sm_friendly_notarget_s", "1", "(0/1) If enabled, a Friendly player's sentry will be invisible to enemy sentries.", FCVAR_PLUGIN);
	cvar_notarget_d = CreateConVar("sm_friendly_notarget_d", "1", "(0/1) If enabled, a Friendly player's dispenser will be invisible to enemy sentries. Friendly dispensers will have their healing act buggy.", FCVAR_PLUGIN);
	cvar_notarget_t = CreateConVar("sm_friendly_notarget_t", "1", "(0/1) If enabled, a Friendly player's teleporters will be invisible to enemy sentries.", FCVAR_PLUGIN);

	cvar_alpha_p = CreateConVar("sm_friendly_alpha", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly players. -1 disables this feature.", FCVAR_PLUGIN);
	cvar_alpha_w = CreateConVar("sm_friendly_alpha_w", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' cosmetics. -1 disables this feature.", FCVAR_PLUGIN);
	cvar_alpha_wep = CreateConVar("sm_friendly_alpha_wep", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly players' weapons. -1 disables this feature.", FCVAR_PLUGIN);
	cvar_alpha_s = CreateConVar("sm_friendly_alpha_s", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly sentries. -1 disables this feature.", FCVAR_PLUGIN);
	cvar_alpha_d = CreateConVar("sm_friendly_alpha_d", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly dispensers. -1 disables this feature.", FCVAR_PLUGIN);
	cvar_alpha_t = CreateConVar("sm_friendly_alpha_t", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly teleporters. -1 disables this feature.", FCVAR_PLUGIN);

	cvar_noblock_p = CreateConVar("sm_friendly_noblock", "1", "(0/1) If enabled, a Friendly player will not be able to block the paths of other players.", FCVAR_PLUGIN);
	cvar_noblock_s = CreateConVar("sm_friendly_noblock_s", "1", "(0/1) If enabled, a Friendly sentry will not be able to block the paths of other players.", FCVAR_PLUGIN);
	cvar_noblock_d = CreateConVar("sm_friendly_noblock_d", "1", "(0/1) If enabled, a Friendly dispenser will not be able to block the paths of other players.", FCVAR_PLUGIN);
	cvar_noblock_t = CreateConVar("sm_friendly_noblock_t", "1", "(0/1) If enabled, a Friendly teleporter will not be able to block the paths of other players. If enabled, only the Engineer who built the tele will be able to use it.", FCVAR_PLUGIN);

	cvar_killbuild_h_s = CreateConVar("sm_friendly_killsentry", "1", "(0/1) When enabled, a Friendly Engineer's sentry will vanish upon becoming hostile.", FCVAR_PLUGIN);
	cvar_killbuild_h_d = CreateConVar("sm_friendly_killdispenser", "1", "(0/1) When enabled, a Friendly Engineer's dispenser will vanish upon becoming hostile.", FCVAR_PLUGIN);
	cvar_killbuild_h_t = CreateConVar("sm_friendly_killtele", "1", "(0/1) When enabled, a Friendly Engineer's teleporters will vanish upon becoming hostile.", FCVAR_PLUGIN);
	cvar_killbuild_f_s = CreateConVar("sm_friendly_killsentry_f", "1", "(0/1) When enabled, an Engineer's sentry will vanish upon becoming Friendly.", FCVAR_PLUGIN);
	cvar_killbuild_f_d = CreateConVar("sm_friendly_killdispenser_f", "1", "(0/1) When enabled, an Engineer's dispenser will vanish upon becoming Friendly.", FCVAR_PLUGIN);
	cvar_killbuild_f_t = CreateConVar("sm_friendly_killtele_f", "1", "(0/1) When enabled, an Engineer's teleporters will vanish upon becoming Friendly.", FCVAR_PLUGIN);
	cvar_nobuild_s = CreateConVar("sm_friendly_nobuild_s", "0", "(0/1) When enabled, a Friendly engineer will not be able to build sentries.", FCVAR_PLUGIN);
	cvar_nobuild_d = CreateConVar("sm_friendly_nobuild_d", "1", "(0/1) When enabled, a Friendly engineer will not be able to build dispensers.", FCVAR_PLUGIN);
	cvar_nobuild_t = CreateConVar("sm_friendly_nobuild_t", "0", "(0/1) a Friendly engineer will not be able to build teleporters.", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_friendly", OnToggleFriendly, 0, "Toggles Friendly Mode");
	RegAdminCmd("sm_friendly_admin", OnToggleAdmin, ADMFLAG_BAN, "Players who toggle this command will be able to damage friendly players while not friendly themselves.");
	RegAdminCmd("sm_friendly_v", smFriendlyVer, 0, "Outputs the current version to the chat.");
	RegAdminCmd("sm_friendly_r", Restart_Plugin, ADMFLAG_RCON, "Unloads and reloads friendly.smx, relies on updater.inc");
//	RegAdminCmd("sm_friendly_d", DebugFriendly, 0, "Outputs various things to the console. Useful for those who are editing the source code of the plugin.");

	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("player_builtobject", Object_Built);
	HookEvent("player_sapped_object", Object_Sapped);
	HookEvent("post_inventory_application", Inventory_App);
	HookEvent("teamplay_round_active", Round_Start);

	AutoExecConfig(false, "friendly");

	AddNormalSoundHook(Hook_NormalSound);

	HookObjectives();

	HookConVarChange(cvar_blockweps_classes, blockedweps_cvarchange);
	HookConVarChange(cvar_blockweps_black, blockedweps_cvarchange);
	HookConVarChange(cvar_blockweps_white, blockedweps_cvarchange);
	HookConVarChange(cvar_blocktaunt, blockedweps_cvarchange);
	
	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(TauntCmd, "+taunt");

}

public OnConfigsExecuted() {
	GetWeaponBlockerStrings();
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	HookObjectives();
}

public Action:OnToggleFriendly(client, args) {
	if (client != 0) {
		if (GetConVarBool(cvar_enabled)) {
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
	return Plugin_Handled;
}

UsedCommandAlive(const client) {
	if (RequestedChange[client]) {
		RequestedChange[client] = false;
		CPrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
	} else {
		if (IsFriendly[client]) {
			if (GetConVarInt(cvar_action_h) == 0 || IsAdmin[client]) {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
			} else if (GetConVarInt(cvar_action_h) == -2) {
				CPrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
			} else if (GetConVarInt(cvar_action_h) == -1) {
				CPrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				ForcePlayerSuicide(client);
			} else if (GetConVarInt(cvar_action_h) > 0) {
				MakeClientHostile(client);
				SlapPlayer(client, GetConVarInt(cvar_action_h));
				CPrintToChat(client, "%s You are no longer Friendly, but took damage because of the switch!", CHAT_PREFIX);
			}
		} else {
			if (GetConVarInt(cvar_action_f) == 0 || IsAdmin[client]) {
				MakeClientFriendly(client);
				CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
			} else if (GetConVarInt(cvar_action_f) == -2) {
				CPrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
			} else if (GetConVarInt(cvar_action_f) == -1) {
				CPrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				RequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				ForcePlayerSuicide(client);
			} else if (GetConVarInt(cvar_action_f) > 0) {
				MakeClientFriendly(client);
				SlapPlayer(client, GetConVarInt(cvar_action_f));
				CPrintToChat(client, "%s You were made Friendly, but took damage because of the switch!", CHAT_PREFIX);
			}
		}
	}
}

UsedCommandDead(const client) {
	if (RequestedChange[client]) {
		RequestedChange[client] = false;
		CPrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
		if (IsFriendly[client] && !GetConVarBool(cvar_remember)) {
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
			if (GetConVarInt(cvar_logging) > 0) {
				LogAction(client, -1, "\"%L\" turned off Friendly Admin Bypass mode.", client);
			}
		} else {
			if (GetConVarBool(cvar_enabled)) {
				IsAdmin[client] = true;
				CPrintToChat(client, "%s You are now bypassing Friendly Mode.", CHAT_PREFIX);
				if (GetConVarInt(cvar_logging) > 0) {
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

public Inventory_App(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFriendly[client] && GetConVarInt(cvar_alpha_w) > -1) {
		SetWearableInvis(client);
	}
	if (IsFriendly[client] && GetConVarInt(cvar_alpha_wep) > -1) {
		SetWeaponInvis(client);
	}
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarBool(cvar_advert)) {
		DoAdvert(client);
	}
	if (RFETRIZ[client]) {
		ReapplyFriendly(client);
		CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
	} else if (RequestedChange[client]) {
		if (IsFriendly[client]) {
			MakeClientHostile(client);
			CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
		} else {
			MakeClientFriendly(client);
			CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
		}
	} else if (!RequestedChange[client]) {
		if (IsFriendly[client]) {
			if (GetConVarBool(cvar_remember)) {
				ReapplyFriendly(client);
				CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
			} else {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You have been taken out of Friendly mode because you respawned.", CHAT_PREFIX);
			}
		}
	}
}

public OnClientPutInServer(client) {
	HookClient(client);
	SeenAdvert[client] = 0;
}

public OnClientDisconnect(client) {
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	IsAdmin[client] = false;
	RFETRIZ[client] = false;

	UnhookClient(client);
}

MakeClientHostile(const client) {
	IsFriendly[client] = false;
	RequestedChange[client] = false;
	RFETRIZ[client] = false;
	MakeBuildingsHostile(client);
	RemoveOverlay(client);
	if (GetConVarInt(cvar_invuln_p) < 2) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	if (GetConVarBool(cvar_notarget_p)) {
		new flags = GetEntityFlags(client)&~FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
	if (GetConVarBool(cvar_noblock_p)) {
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
	}
	if (GetConVarInt(cvar_alpha_p) > -1) {
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, _);
	}
	if (GetConVarInt(cvar_alpha_w) > -1) {
		SetWearableInvis(client, false);
	}
	if (GetConVarInt(cvar_alpha_wep) > -1) {
		SetWeaponInvis(client, false);
	}
	if (GetConVarInt(cvar_logging) == 2) {
		LogAction(client, -1, "\"%L\" turned off Friendly mode.", client);
	}
}

MakeClientFriendly(const client) {
	MakeBuildingsFriendly(client);
	ReapplyFriendly(client);
	RemoveMySappers(client);
	if (GetConVarBool(cvar_stopintel)) {
		FakeClientCommand(client, "dropitem");
	}
	if (GetConVarInt(cvar_logging) == 2) {
		LogAction(client, -1, "\"%L\" activated Friendly mode.", client);
	}
	if (!IsAdmin[client]) {
		ForceWeaponSwitches(client);
	}
}

ReapplyFriendly(const client) {
	IsFriendly[client] = true;
	RequestedChange[client] = false;
	RFETRIZ[client] = false;
	SetOverlay(client);
	if (GetConVarInt(cvar_invuln_p) < 2) {
		if (GetConVarInt(cvar_invuln_p) == 0) {
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //godmode
		}
		if (GetConVarInt(cvar_invuln_p) == 1) {
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1); //buddha
		}
	}
	if (GetConVarBool(cvar_notarget_p)) {
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
	if (GetConVarBool(cvar_noblock_p)) {
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
	}
	if (GetConVarInt(cvar_alpha_p) > -1) {
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, _, _, _, GetConVarInt(cvar_alpha_p));
	}
	if (GetConVarInt(cvar_alpha_w) > -1) {
		SetWearableInvis(client);
	}
	if (GetConVarInt(cvar_alpha_wep) > -1) {
		SetWeaponInvis(client);
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (attacker < 1 || attacker > MaxClients || (client == attacker && GetConVarInt(cvar_invuln_p) != 3)) {
		return Plugin_Continue;
	}
	if ((IsFriendly[attacker] || IsFriendly[client]) && !IsAdmin[attacker]) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public smEnableChange(Handle:hHandle, const String:oldValue[], const String:newValue[]) {
	if (GetConVarBool(hHandle)) {
		CPrintToChatAll("%s An admin has re-enabled Friendly Mode. Type {olive}/friendly{default} to use.", CHAT_PREFIX);
	} else {
		CPrintToChatAll("%s An admin has disabled Friendly Mode.", CHAT_PREFIX);
		for (new i=1; i <= MaxClients; i++) {
			if (IsFriendly[i]) {
				MakeClientHostile(i);
				IsAdmin[i] = false;
				if (GetConVarInt(cvar_action_h) < 0) {
					ForcePlayerSuicide(i);
				} if (GetConVarInt(cvar_action_h) > 0) {
					SlapPlayer(i, GetConVarInt(cvar_action_h));
				}
			}
		}
	}
}

public OnPluginEnd() {
	for (new i=1; i <= MaxClients; i++) {
		UnhookClient(i);
		if (IsFriendly[i]) {
			MakeClientHostile(i);
			IsAdmin[i] = false;
			if (GetConVarInt(cvar_action_h) < 0) {
				ForcePlayerSuicide(i);
			} if (GetConVarInt(cvar_action_h) > 0) {
				SlapPlayer(i, GetConVarInt(cvar_action_h));
			}
			CPrintToChat(i, "%s Plugin has been unloaded or restarted.", CHAT_PREFIX);
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

HookObjectives() {
	new capturePoint = -1;
	while ((capturePoint = FindEntityByClassname(capturePoint, "trigger_capture_area"))!=INVALID_ENT_REFERENCE) {
		SDKHook(capturePoint, SDKHook_StartTouch, OnCPTouch );
		SDKHook(capturePoint, SDKHook_Touch, OnCPTouch );
	}
	new teamIntel = -1;
	while ((teamIntel = FindEntityByClassname(teamIntel, "item_teamflag"))!=INVALID_ENT_REFERENCE) {
		SDKHook(teamIntel, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(teamIntel, SDKHook_Touch, OnFlagTouch );
	}
}

public Action:OnCPTouch(point, client) {
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	} else {
		if (IsFriendly[client] && GetConVarBool(cvar_stopcap) && !IsAdmin[client]) {
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	}
}

public Action:OnFlagTouch(point, client) {
	if (IsFriendly[client] && GetConVarBool(cvar_stopintel) && !IsAdmin[client]) {
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
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
			if (GetConVarBool(cvar_nobuild_s) && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build sentries while Friendly!", CHAT_PREFIX);
			} else {
				if (GetConVarInt(cvar_invuln_s) == 2) {	
					SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
				}
				if (GetConVarBool(cvar_noblock_s)) {
					SetEntProp(building, Prop_Send, "m_CollisionGroup", 2);
				}
				if (GetConVarBool(cvar_notarget_s)) {
					new flags = GetEntityFlags(building)|FL_NOTARGET;
					SetEntityFlags(building, flags);
				}
				if (GetConVarInt(cvar_alpha_s) > -1) {	
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, GetConVarInt(cvar_alpha_s));
				}
			}
		}
		if (StrEqual(b_classname, "obj_dispenser")) {
			if (GetConVarBool(cvar_nobuild_d) && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build dispensers while Friendly!", CHAT_PREFIX);
			} else {
				if (GetConVarInt(cvar_invuln_d) == 2) {	
					SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
				}
				if (GetConVarBool(cvar_noblock_d)) {
					SetEntProp(building, Prop_Send, "m_CollisionGroup", 2);
				}
				if (GetConVarBool(cvar_notarget_d)) {
					new flags = GetEntityFlags(building)|FL_NOTARGET;
					SetEntityFlags(building, flags);
				}
				if (GetConVarInt(cvar_alpha_d) > -1) {	
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, GetConVarInt(cvar_alpha_d));
				}
			}
		}
		if (StrEqual(b_classname, "obj_teleporter")) {
			if (GetConVarBool(cvar_nobuild_t) && !IsAdmin[client]) {
				AcceptEntityInput(building, "Kill");
				CPrintToChat(client, "%s You cannot build teleporters while Friendly!", CHAT_PREFIX);
			} else {
				if (GetConVarInt(cvar_invuln_t) == 2) {	
					SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
				}
				if (GetConVarBool(cvar_noblock_t)) {
					SetEntProp(building, Prop_Send, "m_CollisionGroup", 2);
				}
				if (GetConVarBool(cvar_notarget_t)) {
					new flags = GetEntityFlags(building)|FL_NOTARGET;
					SetEntityFlags(building, flags);
				}
				if (GetConVarInt(cvar_alpha_t) > -1) {	
					SetEntityRenderMode(building, RENDER_TRANSALPHA);
					SetEntityRenderColor(building, _, _, _, GetConVarInt(cvar_alpha_t));
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
			if (GetConVarBool(cvar_killbuild_f_s) && !IsAdmin[client]) {
				AcceptEntityInput(sentrygun, "Kill");
			} else {
				if (GetConVarInt(cvar_invuln_s) > 0) {
					if (GetConVarInt(cvar_invuln_s) == 1) {
						RemoveActiveSapper(sentrygun, false);
					}
					if (GetConVarInt(cvar_invuln_s) == 2) {
						SetEntProp(sentrygun, Prop_Data, "m_takedamage", 0, 1);
						RemoveActiveSapper(sentrygun, true);
					}
				}
				if (GetConVarBool(cvar_noblock_s)) {
					SetEntProp(sentrygun, Prop_Send, "m_CollisionGroup", 2);
				}
				if (GetConVarBool(cvar_notarget_s)) {
					new flags = GetEntityFlags(sentrygun)|FL_NOTARGET;
					SetEntityFlags(sentrygun, flags);
				}
				if (GetConVarInt(cvar_alpha_s) > -1) {	
					SetEntityRenderMode(sentrygun, RENDER_TRANSALPHA);
					SetEntityRenderColor(sentrygun, _, _, _, GetConVarInt(cvar_alpha_s));
				}
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(dispenser) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(cvar_killbuild_f_d) && !IsAdmin[client]) {
				AcceptEntityInput(dispenser, "Kill");
			} else {
				if (GetConVarInt(cvar_invuln_d) > 0) {
					if (GetConVarInt(cvar_invuln_d) == 1) {
						RemoveActiveSapper(dispenser, false);
					}
					if (GetConVarInt(cvar_invuln_d) == 2) {
						SetEntProp(dispenser, Prop_Data, "m_takedamage", 0, 1);
						RemoveActiveSapper(dispenser, true);
					}
				}
				if (GetConVarBool(cvar_noblock_d)) {
					SetEntProp(dispenser, Prop_Send, "m_CollisionGroup", 2);
				}
				if (GetConVarBool(cvar_notarget_d)) {
					new flags = GetEntityFlags(dispenser)|FL_NOTARGET;
					SetEntityFlags(dispenser, flags);
				}
				if (GetConVarInt(cvar_alpha_d) > -1) {	
					SetEntityRenderMode(dispenser, RENDER_TRANSALPHA);
					SetEntityRenderColor(dispenser, _, _, _, GetConVarInt(cvar_alpha_d));
				}
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(teleporter) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(cvar_killbuild_f_t) && !IsAdmin[client]) {
				AcceptEntityInput(teleporter, "Kill");
			} else {
				if (GetConVarInt(cvar_invuln_t) > 0) {
					if (GetConVarInt(cvar_invuln_t) == 1) {
						RemoveActiveSapper(teleporter, false);
					}
					if (GetConVarInt(cvar_invuln_t) == 2) {
						SetEntProp(teleporter, Prop_Data, "m_takedamage", 0, 1);
						RemoveActiveSapper(teleporter, true);
					}
				}
				if (GetConVarBool(cvar_noblock_t)) {
					SetEntProp(teleporter, Prop_Send, "m_CollisionGroup", 2);
				}
				if (GetConVarBool(cvar_notarget_t)) {
					new flags = GetEntityFlags(teleporter)|FL_NOTARGET;
					SetEntityFlags(teleporter, flags);
				}
				if (GetConVarInt(cvar_alpha_t) > -1) {	
					SetEntityRenderMode(teleporter, RENDER_TRANSALPHA);
					SetEntityRenderColor(teleporter, _, _, _, GetConVarInt(cvar_alpha_t));
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
			if (GetConVarBool(cvar_killbuild_h_s) && !IsAdmin[client]) {
				AcceptEntityInput(sentrygun, "Kill");
			} else {
				if (GetConVarInt(cvar_invuln_s) == 2) {	
					SetEntProp(sentrygun, Prop_Data, "m_takedamage", 2, 1);
				}
				if (GetConVarBool(cvar_noblock_s)) {
					SetEntProp(sentrygun, Prop_Send, "m_CollisionGroup", 5);
				}
				if (GetConVarBool(cvar_notarget_s)) {
					new flags = GetEntityFlags(sentrygun)&~FL_NOTARGET;
					SetEntityFlags(sentrygun, flags);
				}
				if (GetConVarInt(cvar_alpha_s) != -1) {	
					SetEntityRenderMode(sentrygun, RENDER_NORMAL);
					SetEntityRenderColor(sentrygun, _, _, _, _);
				}
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(dispenser) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(cvar_killbuild_h_d) && !IsAdmin[client]) {
				AcceptEntityInput(dispenser, "Kill");
			} else {
				if (GetConVarInt(cvar_invuln_d) == 2) {	
					SetEntProp(dispenser, Prop_Data, "m_takedamage", 2, 1);
				}
				if (GetConVarBool(cvar_noblock_d)) {
					SetEntProp(dispenser, Prop_Send, "m_CollisionGroup", 5);
				}
				if (GetConVarBool(cvar_notarget_d)) {
					new flags = GetEntityFlags(dispenser)&~FL_NOTARGET;
					SetEntityFlags(dispenser, flags);
				}
				if (GetConVarInt(cvar_alpha_d) != -1) {	
					SetEntityRenderMode(dispenser, RENDER_NORMAL);
					SetEntityRenderColor(dispenser, _, _, _, _);
				}
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if (IsValidEntity(teleporter) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(cvar_killbuild_h_t) && !IsAdmin[client]) {
				AcceptEntityInput(teleporter, "Kill");
			} else {
				if (GetConVarInt(cvar_invuln_t) == 2) {	
					SetEntProp(teleporter, Prop_Data, "m_takedamage", 2, 1);
				}
				if (GetConVarBool(cvar_noblock_t)) {
					SetEntProp(teleporter, Prop_Send, "m_CollisionGroup", 5);
				}
				if (GetConVarBool(cvar_notarget_t)) {
					new flags = GetEntityFlags(teleporter)&~FL_NOTARGET;
					SetEntityFlags(teleporter, flags);
				}
				if (GetConVarInt(cvar_alpha_t) != -1) {	
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
			if (IsFriendly[attacker] || (IsFriendly[engie] && GetConVarInt(cvar_invuln_s) > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		if (StrEqual(classname, "obj_dispenser", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && GetConVarInt(cvar_invuln_d) > 0)) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		if (StrEqual(classname, "obj_teleporter", false)) {
			if (IsFriendly[attacker] || (IsFriendly[engie] && GetConVarInt(cvar_invuln_t) > 0)) {
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
				if (GetConVarInt(cvar_invuln_d) == 2) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (GetConVarInt(cvar_invuln_d) == 1 && !IsAdmin[spy]) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (GetConVarInt(cvar_invuln_d) == 1 && IsAdmin[spy]) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
				if (GetConVarInt(cvar_invuln_d) == 0) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
			}
			if (building == 1) {
				if (GetConVarInt(cvar_invuln_t) == 2) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (GetConVarInt(cvar_invuln_t) == 1 && !IsAdmin[spy]) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (GetConVarInt(cvar_invuln_t) == 1 && IsAdmin[spy]) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
				if (GetConVarInt(cvar_invuln_t) == 0) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
			}
			if (building == 2) {
				if (GetConVarInt(cvar_invuln_s) == 2) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (GetConVarInt(cvar_invuln_s) == 1 && !IsAdmin[spy]) {
					AcceptEntityInput(sapper, "Kill");
				}
				if (GetConVarInt(cvar_invuln_s) == 1 && IsAdmin[spy]) {
					SDKHook(sapper, SDKHook_OnTakeDamage, SapperTakeDamage);
				}
				if (GetConVarInt(cvar_invuln_s) == 0) {
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
	new alpha = GetConVarInt(cvar_alpha_w);
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
}


stock SetWeaponInvis(client, bool:set = true) {
	new alpha = GetConVarInt(cvar_alpha_wep);
	for(new i=0; i < 4; i++) {
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

public attemptVersionChange(Handle:hHandle, const String:oldValue[], const String:newValue[]) {
	SetConVarString(hHandle, PLUGIN_VERSION);
}

public Action:Updater_OnPluginChecking() {
	if (GetConVarInt(cvar_update) > 0) {
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
	if (GetConVarInt(cvar_update) == 2) {
		ReloadPlugin();
	}
}

public Action:Restart_Plugin(client, args) {
	CPrintToChat(client, "%s Attempting plugin reload...", CHAT_PREFIX);
	ReloadPlugin();
	return Plugin_Handled;
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Goomba Stomp Integration */

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower) {
	if ((IsFriendly[attacker] 
		|| IsFriendly[victim]) 
	&& (!IsAdmin[attacker]) 
	&& (GetConVarBool(cvar_goomba))) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
RTD Integration */

public Action:RTD_CanRollDice(client) {
	if (IsFriendly[client] 
	&& !IsAdmin[client] 
	&& GetConVarBool(cvar_blockrtd)) {
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
		for (new i = 0; i < sizeof(g_classStrBuffer) && wepClassCount < 1; i++) {
			if (StrEqual(g_classStrBuffer[i], weaponClass)) {
				wepClassCount++;
			}
		}
		if (wepClassCount > 0) {
			for (new i = 0; i < sizeof(g_indexStrBufferWhite) && wepCount < 1; i++) {
				if (StringToInt(g_indexStrBufferWhite[i]) == weaponIndex) {
					wepCount++;
				}
			}
			if (wepCount > 0) {
				return Plugin_Continue;
			} else {
				return Plugin_Handled;
			}
		} else {
			for (new i = 0; i < sizeof(g_indexStrBufferBlack) && wepCount < 1; i++) {
				if (StringToInt(g_indexStrBufferBlack[i]) == weaponIndex) {
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
			for (new i = 0; i < sizeof(g_tauntStrBuffer) && wepCount < 1; i++) {
				if (StringToInt(g_tauntStrBuffer[i]) == weaponIndex) {
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

GetWeaponBlockerStrings() {

	new String:strWeaponsBlack[256];
	GetConVarString(cvar_blockweps_black, strWeaponsBlack, sizeof(strWeaponsBlack));
	if (StrEqual(strWeaponsBlack, "0")) {
		strWeaponsBlack = "";
	} else if (StrEqual(strWeaponsBlack, "1")) {
		strWeaponsBlack = DEFAULT_BLOCKED_WEAPONS;
	}
	ExplodeString(strWeaponsBlack, ",", g_indexStrBufferBlack, sizeof(g_indexStrBufferBlack), sizeof(g_indexStrBufferBlack[]));

	new String:strWeaponsWhite[256];
	GetConVarString(cvar_blockweps_white, strWeaponsWhite, sizeof(strWeaponsWhite));
	if (StrEqual(strWeaponsWhite, "0")) {
		strWeaponsWhite = "";
	} else if (StrEqual(strWeaponsWhite, "1")) {
		strWeaponsWhite = DEFAULT_WHITELISTED_WEAPONS;
	}
	ExplodeString(strWeaponsWhite, ",", g_indexStrBufferWhite, sizeof(g_indexStrBufferWhite), sizeof(g_indexStrBufferWhite[]));

	new String:strWeaponsClass[256];
	GetConVarString(cvar_blockweps_classes, strWeaponsClass, sizeof(strWeaponsClass));
	if (StrEqual(strWeaponsClass, "0")) {
		strWeaponsClass = "";
	} else if (StrEqual(strWeaponsClass, "1")) {
		strWeaponsClass = DEFAULT_BLOCKED_WEAPONCLASSES;
	}
	ExplodeString(strWeaponsClass, ",", g_classStrBuffer, sizeof(g_classStrBuffer), sizeof(g_classStrBuffer[]));

	new String:strWeaponsTaunt[256];
	GetConVarString(cvar_blocktaunt, strWeaponsTaunt, sizeof(strWeaponsTaunt));
	if (StrEqual(strWeaponsTaunt, "0")) {
		strWeaponsTaunt = "";
	} else if (StrEqual(strWeaponsTaunt, "1")) {
		strWeaponsTaunt = DEFAULT_BLOCKED_TAUNTS;
	}
	ExplodeString(strWeaponsTaunt, ",", g_tauntStrBuffer, sizeof(g_tauntStrBuffer), sizeof(g_tauntStrBuffer[]));

}

public blockedweps_cvarchange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	GetWeaponBlockerStrings();
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
Begin code relevant to overlay */

SetOverlay(client) {
	new String:material[129];
	GetConVarString(cvar_overlay, material, sizeof(material));
	if (!StrEqual(material, "0")) {
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		ClientCommand(client, "r_screenoverlay \"%s\"", material);
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
	}
}

RemoveOverlay(client) {
	new String:material[129];
	GetConVarString(cvar_overlay, material, sizeof(material));
	if (!StrEqual(material, "0")) {
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		ClientCommand(client, "r_screenoverlay \"\"");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
	}
}



/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Begin code relevant to sm_friendly_d 

public Action:DebugFriendly(client, args) {
	if (client != 0) {
		PrintClientVars(client);
		PrintConVars(client);
	} else {
		PrintConVars(client);
	}
	return Plugin_Handled;
}

PrintClientVars(const client) {
	PrintToConsole(client, "%s Friendly: %i, Admin: %i, Changing: %i, Alive: %i, RFETRIZ: %i, SeenAdvert: %i", CHAT_PREFIX_NOCOLOR, (IsFriendly[client]), (IsAdmin[client]), (RequestedChange[client]), (IsPlayerAlive(client)), (RFETRIZ[client]), (SeenAdvert[client]));
}

PrintConVars(const client) {
	PrintToConsole(client, "%s Remember: %i, BlockWeps: %i, ActionH: %i, ActionF: %i, Invuln: %i, NoTarget: %i, NoBlock: %i, Alpha: %i, Update: %i, AdvertEnabled: %i", CHAT_PREFIX_NOCOLOR, (GetConVarInt(cvar_remember)), (GetConVarInt(cvar_action_h)), (GetConVarInt(cvar_action_f)), (GetConVarInt(cvar_invuln_p)), (GetConVarInt(cvar_notarget_p)), (GetConVarInt(cvar_noblock_p)), (GetConVarInt(cvar_alpha_p)), (GetConVarInt(cvar_update)), (GetConVarInt(cvar_advert)));

}
*/