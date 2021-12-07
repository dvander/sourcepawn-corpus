/*
WHOLE BUNCH OF CRAZY SHIT FOR ENGIE BUILDINGS
improved plugin performance on hooking buildings
AutoExecCfg
Friendly spys can wear sappers
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>
#include <colors>
#include <goomba>

#undef REQUIRE_PLUGIN
#tryinclude <updater>

#define PLUGIN_VERSION "13.0422"
#define UPDATE_URL "http://ddhbitbucket.crabdance.com/sm-friendly-mode/raw/default/friendlymodeupdate.txt"

#define CHAT_PREFIX "{olive}[Friendly]{default}"
#define CHAT_PREFIX_NOCOLOR "[Friendly]"
#define CHAT_NAME "{olive}Friendly Mode{default}"
#define CHAT_NAME_NOCOLOR "Friendly Mode"


new bool:ClientIsFriendly[MAXPLAYERS+1] = {false, ...};
new bool:ClientRequestedChange[MAXPLAYERS+1] = {false, ...};
new bool:ClientIsAdmin[MAXPLAYERS+1] = {false, ...};
new bool:ClientRFETRIZ[MAXPLAYERS+1] = {false, ...};
new bool:ClientIsHooked[MAXPLAYERS+1] = {false, ...};
new _:ClientSeenAdvert[MAXPLAYERS+1] = {0, ...};

new Handle:sm_friendly_action_h = INVALID_HANDLE;
new Handle:sm_friendly_action_f = INVALID_HANDLE;
new Handle:sm_friendly_remember = INVALID_HANDLE;
new Handle:sm_friendly_blockweps = INVALID_HANDLE;
new Handle:sm_friendly_update = INVALID_HANDLE;
new Handle:sm_friendly_advert = INVALID_HANDLE;
new Handle:sm_friendly_goomba = INVALID_HANDLE;
new Handle:sm_friendly_enabled = INVALID_HANDLE;
new Handle:sm_friendly_version = INVALID_HANDLE;

new Handle:sm_friendly_invuln = INVALID_HANDLE;
new Handle:sm_friendly_invuln_s = INVALID_HANDLE;
new Handle:sm_friendly_invuln_d = INVALID_HANDLE;
new Handle:sm_friendly_invuln_t = INVALID_HANDLE;

new Handle:sm_friendly_notarget = INVALID_HANDLE;
new Handle:sm_friendly_notarget_s = INVALID_HANDLE;
new Handle:sm_friendly_notarget_d = INVALID_HANDLE;
new Handle:sm_friendly_notarget_t = INVALID_HANDLE;

new Handle:sm_friendly_noblock = INVALID_HANDLE;
new Handle:sm_friendly_noblock_s = INVALID_HANDLE;
new Handle:sm_friendly_noblock_d = INVALID_HANDLE;
new Handle:sm_friendly_noblock_t = INVALID_HANDLE;

new Handle:sm_friendly_alpha = INVALID_HANDLE;
new Handle:sm_friendly_alpha_s = INVALID_HANDLE;
new Handle:sm_friendly_alpha_d = INVALID_HANDLE;
new Handle:sm_friendly_alpha_t = INVALID_HANDLE;

new Handle:sm_friendly_killsentry = INVALID_HANDLE;
new Handle:sm_friendly_killdispenser = INVALID_HANDLE;
new Handle:sm_friendly_killtele = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Friendly Mode",
	author = "Derek D. Howard",
	description = "Allows players to become invulnerable to damage from other players, while also being unable to attack other players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=213205"
};

public OnPluginStart() {

	for(new i=1; i<MAXPLAYERS+1; i++) {
		ClientIsFriendly[i] = false;
		ClientRequestedChange[i] = false;
		ClientIsAdmin[i] = false;
		ClientRFETRIZ[i] = false;
		ClientIsHooked[i] = false;
		ClientSeenAdvert[i] = 5;
	}
	
	sm_friendly_version = CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Friendly Mode Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(sm_friendly_version, PLUGIN_VERSION);
	HookConVarChange(sm_friendly_version, attemptVersionChange);

	sm_friendly_enabled = CreateConVar("sm_friendly_enabled", "1", "(0/1) Enables/Disables Friendly Mode", FCVAR_PLUGIN);
	HookConVarChange(sm_friendly_enabled, smEnableChange);
	
	sm_friendly_action_h = CreateConVar("sm_friendly_action_h", "-1", "(Any integer, -2 or greater) What action to take on living players who want to become Hostile? See this plugin's thread for details.", FCVAR_PLUGIN);
	sm_friendly_action_f = CreateConVar("sm_friendly_action_f", "-1", "(Any integer, -2 or greater) What action to take on living players who want to become Friendly? See this plugin's thread for details.", FCVAR_PLUGIN);
	sm_friendly_remember = CreateConVar("sm_friendly_remember", "0", "(0/1) If enabled, a player who somehow dies while Friendly be Friendly upon respawn.", FCVAR_PLUGIN);
	sm_friendly_blockweps = CreateConVar("sm_friendly_blockweps", "0", "(0/1) If enabled, a Friendly player will be unable to take out certain weapons.", FCVAR_PLUGIN);
	sm_friendly_update = CreateConVar("sm_friendly_update", "1", "(0/1/2) Updater compatibility. 0 = disabled, 1 = auto-download, 2 = auto-download and auto-install", FCVAR_PLUGIN);
	sm_friendly_advert = CreateConVar("sm_friendly_advert", "1", "(0/1) If enabled, players will see a message informing them about the plugin when they join the server.", FCVAR_PLUGIN);
	sm_friendly_goomba = CreateConVar("sm_friendly_goomba", "1", "(0/1) If enabled, Goomba Stomp will follow the same damage rules of Friendly mode as regular attacks.", FCVAR_PLUGIN);

	sm_friendly_invuln = CreateConVar("sm_friendly_invuln", "2", "(0/1/2/3) 0 = Friendly players have full godmode. 1 = Buddha. 2 = Only invulnerable to other players. 3 = Invuln to other players AND himself.", FCVAR_PLUGIN);
	sm_friendly_invuln_s = CreateConVar("sm_friendly_invuln_s", "0", "(0/1) If enabled, Friendly players' sentries will have godmode.", FCVAR_PLUGIN);
	sm_friendly_invuln_d = CreateConVar("sm_friendly_invuln_d", "0", "(0/1) If enabled, Friendly players' dispensers will have godmode.", FCVAR_PLUGIN);
	sm_friendly_invuln_t = CreateConVar("sm_friendly_invuln_t", "0", "(0/1) If enabled, Friendly players' teleporters will have godmode.", FCVAR_PLUGIN);
	
	sm_friendly_notarget = CreateConVar("sm_friendly_notarget", "1", "(0/1) If enabled, a Friendly player will be invisible to sentries, immune to airblasts, etc.", FCVAR_PLUGIN);
	sm_friendly_notarget_s = CreateConVar("sm_friendly_notarget_s", "1", "(0/1) If enabled, a Friendly player's sentry will be invisible to enemy sentries.", FCVAR_PLUGIN);
	sm_friendly_notarget_d = CreateConVar("sm_friendly_notarget_d", "1", "(0/1) If enabled, a Friendly player's dispenser will be invisible to enemy sentries.", FCVAR_PLUGIN);
	sm_friendly_notarget_t = CreateConVar("sm_friendly_notarget_t", "1", "(0/1) If enabled, a Friendly player's teleporters will be invisible to enemy sentries.", FCVAR_PLUGIN);
	
	sm_friendly_alpha = CreateConVar("sm_friendly_alpha", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly players. -1 disables this feature.", FCVAR_PLUGIN);
	sm_friendly_alpha_s = CreateConVar("sm_friendly_alpha_s", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly sentries. -1 disables this feature.", FCVAR_PLUGIN);
	sm_friendly_alpha_d = CreateConVar("sm_friendly_alpha_d", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly dispensers. -1 disables this feature.", FCVAR_PLUGIN);
	sm_friendly_alpha_t = CreateConVar("sm_friendly_alpha_t", "128", "(Any integer, -1 thru 255) Sets the transparency of Friendly teleporters. -1 disables this feature.", FCVAR_PLUGIN);

	sm_friendly_noblock = CreateConVar("sm_friendly_noblock", "1", "(0/1) If enabled, a Friendly player will not be able to block the paths of other players.", FCVAR_PLUGIN);
	sm_friendly_noblock_s = CreateConVar("sm_friendly_noblock_s", "1", "(0/1) If enabled, a Friendly sentry will not be able to block the paths of other players.", FCVAR_PLUGIN);
	sm_friendly_noblock_d = CreateConVar("sm_friendly_noblock_d", "1", "(0/1) If enabled, a Friendly dispenser will not be able to block the paths of other players.", FCVAR_PLUGIN);
	sm_friendly_noblock_t = CreateConVar("sm_friendly_noblock_t", "1", "(0/1) If enabled, a Friendly teleporter will not be able to block the paths of other players. If enabled, only the Engineer who built the tele will be able to use it.", FCVAR_PLUGIN);

	sm_friendly_killsentry = CreateConVar("sm_friendly_killsentry", "1", "(0/1) When enabled, a Friendly Engineer's sentry will vanish upon becoming hostile.", FCVAR_PLUGIN);
	sm_friendly_killdispenser = CreateConVar("sm_friendly_killdispenser", "1", "(0/1) When enabled, a Friendly Engineer's dispenser will vanish upon becoming hostile.", FCVAR_PLUGIN);
	sm_friendly_killtele = CreateConVar("sm_friendly_killtele", "1", "(0/1) When enabled, a Friendly Engineer's teleporters will vanish upon becoming hostile.", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_friendly", OnToggleFriendly, 0, "Toggles Friendly Mode");
	RegAdminCmd("sm_friendly_admin", OnToggleAdmin, ADMFLAG_BAN, "Players who toggle this command will be able to damage friendly players while not friendly themselves.");
	RegAdminCmd("sm_friendly_v", smFriendlyVer, 0, "Outputs the current version to the chat.");
	RegAdminCmd("sm_friendly_r", Restart_Plugin, ADMFLAG_RCON, "Unloads and reloads friendly.smx, relies on updater.inc");
//	RegAdminCmd("sm_friendly_d", DebugFriendly, ADMFLAG_ROOT, "Outputs various things to the console. Useful for those who are editing the source code of the plugin.");

	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("player_builtobject", Object_Built);
	HookEvent("player_sapped_object", Object_Sapped);

	PrintToServer("%s ALL FRIENDLY MODE CVARS HAVE BEEN MOVED TO THEIR OWN CFG FILE, LOCATED AT: tf/cfg/sourcemod/friendly.cfg", CHAT_PREFIX_NOCOLOR);
	AutoExecConfig(true, "friendly");
	
	CPrintToChatAll("%s Plugin has been installed/restarted/updated. Friendly may not work correctly until you respawn.", CHAT_PREFIX);

}

public Action:OnToggleFriendly(client, args) {
	if(client != 0) {
		if (GetConVarBool(sm_friendly_enabled)) {
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
	if (ClientRequestedChange[client]) {
		ClientRequestedChange[client] = false;
		CPrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
	} else {
		if (ClientIsFriendly[client]) {
			if (GetConVarInt(sm_friendly_action_h) == -2) {
				CPrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
			} if (GetConVarInt(sm_friendly_action_h) == -1) {
				CPrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				ForcePlayerSuicide(client);
			} if (GetConVarInt(sm_friendly_action_h) == 0) {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
			} if (GetConVarInt(sm_friendly_action_h) > 0) {
				MakeClientHostile(client);
				SlapPlayer(client, GetConVarInt(sm_friendly_action_h));
				CPrintToChat(client, "%s You are no longer Friendly, but took damage because of the switch!", CHAT_PREFIX);
			}
		} else {
			if (GetConVarInt(sm_friendly_action_f) == -2) {
				CPrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
			} if (GetConVarInt(sm_friendly_action_f) == -1) {
				CPrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				ForcePlayerSuicide(client);
			} if (GetConVarInt(sm_friendly_action_f) == 0) {
				MakeClientFriendly(client);
				CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
			} if (GetConVarInt(sm_friendly_action_f) > 0) {
				MakeClientFriendly(client);
				SlapPlayer(client, GetConVarInt(sm_friendly_action_f));
				CPrintToChat(client, "%s You were made Friendly, but took damage because of the switch!", CHAT_PREFIX);
			}
		}
	}
}

UsedCommandDead(const client) {
	if (ClientRequestedChange[client]) {
		ClientRequestedChange[client] = false;
		CPrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
		if (ClientIsFriendly[client] && (GetConVarBool(sm_friendly_remember) == false)) {
			ClientRFETRIZ[client] = true;
		}
	} else {
		ClientRequestedChange[client] = true;
		CPrintToChat(client, "%s You will toggle Friendly mode upon respawning.", CHAT_PREFIX);
		ClientRFETRIZ[client] = false;
	}
}

public Action:OnToggleAdmin(client, args) {
	if(client != 0) {
		DisableAdvert(client);
		if (ClientIsAdmin[client]) {
			ClientIsAdmin[client] = false;
			CPrintToChat(client, "%s You are no longer bypassing Friendly Mode.", CHAT_PREFIX);
		} else {
			if (GetConVarBool(sm_friendly_enabled)) {
				if (GetConVarInt(sm_friendly_invuln) < 2) {
					CPrintToChat(client, "%s You cannot bypass Friendly Mode while cvar {lightgreen}sm_friendly_invuln{default} = 0 or 1", CHAT_PREFIX);
				} else {
					ClientIsAdmin[client] = true;
					CPrintToChat(client, "%s You are now bypassing Friendly Mode.", CHAT_PREFIX);
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

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarBool(sm_friendly_advert)) {
		DoAdvert(client);
	}
	if (ClientRFETRIZ[client]) {
		ReapplyFriendly(client);
		CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
	} else if (ClientRequestedChange[client]) {
		if (ClientIsFriendly[client]) {
			MakeClientHostile(client);
			CPrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
		} else {
			MakeClientFriendly(client);
			CPrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
		}
	} else if (ClientRequestedChange[client] == false) {
		if (ClientIsFriendly[client]) {
			if (GetConVarBool(sm_friendly_remember)) {
				ReapplyFriendly(client);
				CPrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
			} else {
				MakeClientHostile(client);
				CPrintToChat(client, "%s You have been taken out of Friendly mode because you respawned.", CHAT_PREFIX);
			}
		}
	}
	if (ClientIsHooked[client] == false) {
		HookClient(client);
	}
}

public OnClientPutInServer(client) {
	HookClient(client);
}

public OnClientDisconnect(client) {
	ClientIsFriendly[client] = false;
	ClientRequestedChange[client] = false;
	ClientIsAdmin[client] = false;
	ClientRFETRIZ[client] = false;

	UnhookClient(client);
}

MakeClientHostile(const client) {
	ClientIsFriendly[client] = false;
	ClientRequestedChange[client] = false;
	ClientRFETRIZ[client] = false;
	MakeBuildingsHostile(client);
	if (GetConVarInt(sm_friendly_invuln) < 2) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		new flags = GetEntityFlags(client)&~FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
	if (GetConVarBool(sm_friendly_noblock)) {
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
	}
	if (GetConVarInt(sm_friendly_alpha) > -1) {
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, _);
		SetWearableInvis(client, false);
	}
}


MakeClientFriendly(const client) {
	ClientIsFriendly[client] = true;
	ClientRequestedChange[client] = false;
	ClientRFETRIZ[client] = false;
	MakeBuildingsFriendly(client);
	if (GetConVarInt(sm_friendly_invuln) < 2) {
		if (GetConVarInt(sm_friendly_invuln) == 0) {
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //godmode
		}
		if (GetConVarInt(sm_friendly_invuln) == 1) {
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1); //buddha
		}
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
	if (GetConVarBool(sm_friendly_blockweps)) {
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	if (GetConVarBool(sm_friendly_noblock)) {
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
	}
	if (GetConVarInt(sm_friendly_alpha) > -1) {
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, _, _, _, GetConVarInt(sm_friendly_alpha));
		SetWearableInvis(client);
	}
}



ReapplyFriendly(const client) {
	ClientIsFriendly[client] = true;
	ClientRequestedChange[client] = false;
	ClientRFETRIZ[client] = false;
	if (GetConVarInt(sm_friendly_invuln) < 2) {
		if (GetConVarInt(sm_friendly_invuln) == 0) {
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //godmode
		}
		if (GetConVarInt(sm_friendly_invuln) == 1) {
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1); //buddha
		}
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
	if (GetConVarBool(sm_friendly_noblock)) {
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
	}
	if (GetConVarInt(sm_friendly_alpha) > -1) {
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, _, _, _, GetConVarInt(sm_friendly_alpha));
		SetWearableInvis(client);
	}
}

public smEnableChange(Handle:hHandle, const String:oldValue[], const String:newValue[]) {
	if (GetConVarBool(hHandle)) {
		CPrintToChatAll("%s An admin has re-enabled Friendly Mode. Type {olive}/friendly{default} to use.", CHAT_PREFIX);
	} else {
		CPrintToChatAll("%s An admin has disabled Friendly Mode.", CHAT_PREFIX);
		for(new i=1; i<MAXPLAYERS+1; i++) {
			if (ClientIsFriendly[i] == true) {
				MakeClientHostile(i);
				ClientIsAdmin[i] = false;
				if (GetConVarInt(sm_friendly_action_h) < 0) {
					ForcePlayerSuicide(i);
				} if (GetConVarInt(sm_friendly_action_h) > 0) {
					SlapPlayer(i, GetConVarInt(sm_friendly_action_h));
				}
			}
		}
	}
}

public OnPluginEnd() {
	for(new i=1; i<MAXPLAYERS+1; i++) {
		if (ClientIsFriendly[i] == true) {
			MakeClientHostile(i);
			ClientIsAdmin[i] = false;
			if (GetConVarInt(sm_friendly_action_h) < 0) {
				ForcePlayerSuicide(i);
			} if (GetConVarInt(sm_friendly_action_h) > 0) {
				SlapPlayer(i, GetConVarInt(sm_friendly_action_h));
			}
		}
		if (ClientIsHooked[i] == true) {
			UnhookClient(i);
		}
	}
	PrintToServer("%s ALL FRIENDLY MODE CVARS HAVE BEEN MOVED TO THEIR OWN CFG FILE, LOCATED AT: tf/cfg/sourcemod/friendly.cfg", CHAT_PREFIX_NOCOLOR);
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
	if (ClientIsFriendly[client]) {
		if (StrEqual(b_classname, "obj_sentrygun")) {
			if (GetConVarBool(sm_friendly_invuln_s)) {	
				SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
			}
			if (GetConVarBool(sm_friendly_noblock_s)) {
				SetEntProp(building, Prop_Send, "m_CollisionGroup", 2);
			}
			if (GetConVarBool(sm_friendly_notarget_s)) {
				new flags = GetEntityFlags(building)|FL_NOTARGET;
				SetEntityFlags(building, flags);
			}
			if (GetConVarInt(sm_friendly_alpha_s) > -1) {	
				SetEntityRenderMode(building, RENDER_TRANSALPHA);
				SetEntityRenderColor(building, _, _, _, GetConVarInt(sm_friendly_alpha_s));
			}
		}
		if (StrEqual(b_classname, "obj_dispenser")) {
			if (GetConVarBool(sm_friendly_invuln_d)) {	
				SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
			}
			if (GetConVarBool(sm_friendly_noblock_d)) {
				SetEntProp(building, Prop_Send, "m_CollisionGroup", 2);
			}
			if (GetConVarBool(sm_friendly_notarget_d)) {
				new flags = GetEntityFlags(building)|FL_NOTARGET;
				SetEntityFlags(building, flags);
			}
			if (GetConVarInt(sm_friendly_alpha_d) > -1) {	
				SetEntityRenderMode(building, RENDER_TRANSALPHA);
				SetEntityRenderColor(building, _, _, _, GetConVarInt(sm_friendly_alpha_d));
			}
		}
		if (StrEqual(b_classname, "obj_teleporter")) {
			if (GetConVarBool(sm_friendly_invuln_t)) {	
				SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
			}
			if (GetConVarBool(sm_friendly_noblock_t)) {
				SetEntProp(building, Prop_Send, "m_CollisionGroup", 2);
			}
			if (GetConVarBool(sm_friendly_notarget_t)) {
				new flags = GetEntityFlags(building)|FL_NOTARGET;
				SetEntityFlags(building, flags);
			}
			if (GetConVarInt(sm_friendly_alpha_t) > -1) {	
				SetEntityRenderMode(building, RENDER_TRANSALPHA);
				SetEntityRenderColor(building, _, _, _, GetConVarInt(sm_friendly_alpha_t));
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
		if ((IsValidEntity(sentrygun)) && (GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(sm_friendly_invuln_s)) {	
				SetEntProp(sentrygun, Prop_Data, "m_takedamage", 0, 1);
				RemoveActiveSapper(sentrygun);
			}
			if (GetConVarBool(sm_friendly_noblock_s)) {
				SetEntProp(sentrygun, Prop_Send, "m_CollisionGroup", 2);
			}
			if (GetConVarBool(sm_friendly_notarget_s)) {
				new flags = GetEntityFlags(sentrygun)|FL_NOTARGET;
				SetEntityFlags(sentrygun, flags);
			}
			if (GetConVarInt(sm_friendly_alpha_s) > -1) {	
				SetEntityRenderMode(sentrygun, RENDER_TRANSALPHA);
				SetEntityRenderColor(sentrygun, _, _, _, GetConVarInt(sm_friendly_alpha_s));
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if ((IsValidEntity(dispenser)) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(sm_friendly_invuln_d)) {	
				SetEntProp(dispenser, Prop_Data, "m_takedamage", 0, 1);
				RemoveActiveSapper(dispenser);
			}
			if (GetConVarBool(sm_friendly_noblock_d)) {
				SetEntProp(dispenser, Prop_Send, "m_CollisionGroup", 2);
			}
			if (GetConVarBool(sm_friendly_notarget_d)) {
				new flags = GetEntityFlags(dispenser)|FL_NOTARGET;
				SetEntityFlags(dispenser, flags);
			}
			if (GetConVarInt(sm_friendly_alpha_d) > -1) {	
				SetEntityRenderMode(dispenser, RENDER_TRANSALPHA);
				SetEntityRenderColor(dispenser, _, _, _, GetConVarInt(sm_friendly_alpha_d));
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if ((IsValidEntity(teleporter)) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(sm_friendly_invuln_t)) {	
				SetEntProp(teleporter, Prop_Data, "m_takedamage", 0, 1);
				RemoveActiveSapper(teleporter);
			}
			if (GetConVarBool(sm_friendly_noblock_t)) {
				SetEntProp(teleporter, Prop_Send, "m_CollisionGroup", 2);
			}
			if (GetConVarBool(sm_friendly_notarget_t)) {
				new flags = GetEntityFlags(teleporter)|FL_NOTARGET;
				SetEntityFlags(teleporter, flags);
			}
			if (GetConVarInt(sm_friendly_alpha_t) > -1) {	
				SetEntityRenderMode(teleporter, RENDER_TRANSALPHA);
				SetEntityRenderColor(teleporter, _, _, _, GetConVarInt(sm_friendly_alpha_t));
			}
		}
	}
}


MakeBuildingsHostile(const client) {
	new sentrygun = -1;
	new dispenser = -1;
	new teleporter = -1;
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE) {
		if ((IsValidEntity(sentrygun)) && (GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(sm_friendly_killsentry)) {
				AcceptEntityInput(sentrygun, "Kill");
			} else {
				if (GetConVarBool(sm_friendly_invuln_s)) {	
					SetEntProp(sentrygun, Prop_Data, "m_takedamage", 2, 1);
				}
				if (GetConVarBool(sm_friendly_noblock_s)) {
					SetEntProp(sentrygun, Prop_Send, "m_CollisionGroup", 5);
				}
				if (GetConVarBool(sm_friendly_notarget_s)) {
					new flags = GetEntityFlags(sentrygun)&~FL_NOTARGET;
					SetEntityFlags(sentrygun, flags);
				}
				if (GetConVarInt(sm_friendly_alpha_s) != -1) {	
					SetEntityRenderMode(sentrygun, RENDER_NORMAL);
					SetEntityRenderColor(sentrygun, _, _, _, _);
				}
			}
		}
	}
	while ((dispenser = FindEntityByClassname(dispenser, "obj_dispenser"))!=INVALID_ENT_REFERENCE) {
		if ((IsValidEntity(dispenser)) && (GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(sm_friendly_killdispenser)) {
				AcceptEntityInput(dispenser, "Kill");
			} else {
				if (GetConVarBool(sm_friendly_invuln_d)) {	
					SetEntProp(dispenser, Prop_Data, "m_takedamage", 2, 1);
				}
				if (GetConVarBool(sm_friendly_noblock_d)) {
					SetEntProp(dispenser, Prop_Send, "m_CollisionGroup", 5);
				}
				if (GetConVarBool(sm_friendly_notarget_d)) {
					new flags = GetEntityFlags(dispenser)&~FL_NOTARGET;
					SetEntityFlags(dispenser, flags);
				}
				if (GetConVarInt(sm_friendly_alpha_d) != -1) {	
					SetEntityRenderMode(dispenser, RENDER_NORMAL);
					SetEntityRenderColor(dispenser, _, _, _, _);
				}
			}
		}
	}
	while ((teleporter = FindEntityByClassname(teleporter, "obj_teleporter"))!=INVALID_ENT_REFERENCE) {
		if ((IsValidEntity(teleporter)) && (GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder") == client)) {
			if (GetConVarBool(sm_friendly_killtele)) {
				AcceptEntityInput(teleporter, "Kill");
			} else {
				if (GetConVarBool(sm_friendly_invuln_t)) {	
					SetEntProp(teleporter, Prop_Data, "m_takedamage", 2, 1);
				}
				if (GetConVarBool(sm_friendly_noblock_t)) {
					SetEntProp(teleporter, Prop_Send, "m_CollisionGroup", 5);
				}
				if (GetConVarBool(sm_friendly_notarget_t)) {
					new flags = GetEntityFlags(teleporter)&~FL_NOTARGET;
					SetEntityFlags(teleporter, flags);
				}
				if (GetConVarInt(sm_friendly_alpha_t) != -1) {	
					SetEntityRenderMode(teleporter, RENDER_NORMAL);
					SetEntityRenderColor(teleporter, _, _, _, _);
				}
			}
		}
	}
}

public Action:Object_Sapped(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new sapper = GetEventInt(event, "sapperid");
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new building = GetEventInt(event, "object"); //dispenser 0, tele 1, sentry 2

	if(ClientIsFriendly[attacker] || (ClientIsFriendly[client] && ((building == 0 && GetConVarBool(sm_friendly_invuln_d)) || (building == 1 && GetConVarBool(sm_friendly_invuln_t)) || (building == 2 && GetConVarBool(sm_friendly_invuln_s))))) {
		AcceptEntityInput(sapper, "Kill");
	}
	return Plugin_Stop;
}

public RemoveActiveSapper(building) {
	new sapper = -1; 
	while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper"))!=INVALID_ENT_REFERENCE) {
		if(IsValidEntity(sapper) && GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity") == building) {
			AcceptEntityInput(sapper, "Kill");
		}
	}	
}


///////////////////////////////////////////////////////////////////////////

HookClient(const client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	ClientIsHooked[client] = true;
}

UnhookClient(const client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	ClientIsHooked[client] = false;
}


public Action:OnWeaponSwitch(client, weapon)
{
	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

	if(ClientIsFriendly[client] && GetConVarBool(sm_friendly_blockweps))
	{
		if(StrEqual(sWeapon, "tf_weapon_flamethrower") || StrEqual(sWeapon, "tf_weapon_medigun") || StrEqual(sWeapon, "tf_weapon_bonesaw") || StrEqual(sWeapon, "tf_weapon_compound_bow") || StrEqual(sWeapon, "tf_weapon_bat_wood") || StrEqual(sWeapon, "tf_weapon_jar") || StrEqual(sWeapon, "tf_weapon_jar_milk") || StrEqual(sWeapon, "tf_weapon_fireaxe") || StrEqual(sWeapon, "tf_weapon_lunchbox") || StrEqual(sWeapon, "tf_weapon_crossbow"))
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:BuildingTakeDamage(building, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (attacker < 1 || attacker > MaxClients) {
		return Plugin_Continue;
	}
	new String:classname[64];
	GetEntityClassname(building, classname, sizeof(classname));
	if (StrEqual(classname, "obj_sentrygun", false) || StrEqual(classname, "obj_dispenser", false) || StrEqual(classname, "obj_teleporter", false))	{
		if (ClientIsAdmin[attacker] == false) {
			if (ClientIsFriendly[attacker]) {
				damage = 0.0;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker < 1 || attacker > MaxClients || ((client == attacker) && (GetConVarInt(sm_friendly_invuln) != 3)))
	{
		return Plugin_Continue;
	}

	if ((ClientIsFriendly[attacker] || ClientIsFriendly[client]) && (ClientIsAdmin[attacker] == false))
	{
		damage = 0.0;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
The following code was borrowed from FlaminSarge's Ghost Mode plugin: forums.alliedmods.net/showthread.php?t=183266
This code makes wearables change alpha if sm_friendly_alpha is higher than -1 */

stock SetWearableInvis(client, bool:set = true)
{
	new i = -1;
	new alpha = GetConVarInt(sm_friendly_alpha);
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable"))
		{
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
	i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable"))
		{
			SetEntityRenderMode(i, set ? RENDER_TRANSCOLOR : RENDER_NORMAL);
			SetEntityRenderColor(i, _, _, _, set ? alpha : 255);
		}
	}
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Updater code begins here, code shamelessly borrowed and modified from Dr. McKay's "Automatic Steam Update" plugin. */

public OnAllPluginsLoaded() {
	if(LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public attemptVersionChange(Handle:hHandle, const String:oldValue[], const String:newValue[]) {
	SetConVarString(hHandle, PLUGIN_VERSION);
}

public Action:Updater_OnPluginChecking() {
	if(GetConVarInt(sm_friendly_update) > 0) {
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
	if (GetConVarInt(sm_friendly_update) == 2) {
		ReloadPlugin();
	}
}

public Action:Restart_Plugin(client, args) {
	ReloadPlugin();
	return Plugin_Handled;
}


/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Goomba Stomp Integration */

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower) {
	if ((ClientIsFriendly[attacker] || ClientIsFriendly[victim]) && (ClientIsAdmin[attacker] == false) && (GetConVarBool(sm_friendly_goomba))) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Advert/sm_friendly_v Code */

DoAdvert(const client) {
	if (ClientSeenAdvert[client] < 4) {
		ClientSeenAdvert[client] = (ClientSeenAdvert[client] + 1);
	}
	if (ClientSeenAdvert[client] == 4) {
		ClientSeenAdvert[client] = (ClientSeenAdvert[client] + 1);
		ShowFriendlyVer(client);
	}
}

public Action:smFriendlyVer(client, args) {
	ShowFriendlyVer(client);
	return Plugin_Handled;
}

DisableAdvert(const client) {
	ClientSeenAdvert[client] = 5;
}

ShowFriendlyVer(const client) {
	if (client != 0) {
		CPrintToChat(client, "%s Hello! This server is currently running %s v.{lightgreen}%s{default}. Type {olive}/friendly{default} to use.", CHAT_PREFIX, CHAT_NAME, PLUGIN_VERSION);
		DisableAdvert(client);
	} else {
		ReplyToCommand(client, "%s Hello! Your server is currently running %s v.%s.", CHAT_PREFIX_NOCOLOR, CHAT_NAME_NOCOLOR, PLUGIN_VERSION);
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
	PrintToConsole(client, "%s Friendly: %i, Admin: %i, Changing: %i, Alive: %i, RFETRIZ: %i, SeenAdvert: %i", CHAT_PREFIX_NOCOLOR, (ClientIsFriendly[client]), (ClientIsAdmin[client]), (ClientRequestedChange[client]), (IsPlayerAlive(client)), (ClientRFETRIZ[client]), (ClientSeenAdvert[client]));
}

PrintConVars(const client) {
	PrintToConsole(client, "%s Remember: %i, BlockWeps: %i, ActionH: %i, ActionF: %i, Invuln: %i, NoTarget: %i, NoBlock: %i, Alpha: %i, Update: %i, AdvertEnabled: %i", CHAT_PREFIX_NOCOLOR, (GetConVarInt(sm_friendly_remember)), (GetConVarInt(sm_friendly_blockweps)), (GetConVarInt(sm_friendly_action_h)), (GetConVarInt(sm_friendly_action_f)), (GetConVarInt(sm_friendly_invuln)), (GetConVarInt(sm_friendly_notarget)), (GetConVarInt(sm_friendly_noblock)), (GetConVarInt(sm_friendly_alpha)), (GetConVarInt(sm_friendly_update)), (GetConVarInt(sm_friendly_advert)));

}
*/