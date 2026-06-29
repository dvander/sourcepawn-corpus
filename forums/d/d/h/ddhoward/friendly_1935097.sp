/*
CHANGES MADE SINCE 13.0418
fixed a stupid fucking error on line 258
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#tryinclude <updater>


#define PLUGIN_VERSION "13.0418.1"
#define UPDATE_URL "http://ddhbitbucket.crabdance.com/sm-friendly-mode/raw/default/friendlymodeupdate.txt"
#define CHAT_PREFIX "[Friendly Mode]"


new bool:ClientIsFriendly[MAXPLAYERS+1] = {false, ...};
new bool:ClientRequestedChange[MAXPLAYERS+1] = {false, ...};
new bool:ClientIsAdmin[MAXPLAYERS+1] = {false, ...};
new Handle:sm_friendly_blockweps = INVALID_HANDLE;
new Handle:sm_friendly_remember = INVALID_HANDLE;
new Handle:sm_friendly_action_h = INVALID_HANDLE;
new Handle:sm_friendly_action_f = INVALID_HANDLE;
new Handle:sm_friendly_killsentry = INVALID_HANDLE;
new Handle:sm_friendly_invuln = INVALID_HANDLE;
new Handle:sm_friendly_notarget = INVALID_HANDLE;
new Handle:sm_friendly_noblock = INVALID_HANDLE;
new Handle:sm_friendly_alpha = INVALID_HANDLE;
new Handle:sm_friendly_update = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Friendly Mode",
	author = "Derek D. Howard",
	description = "Allows players to become invulnerable to damage from other players, while also being unable to attack other players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=213205"
};

public OnPluginStart()
{
	for(new i=1; i<MAXPLAYERS+1; i++) ClientIsFriendly[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++) ClientRequestedChange[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++) ClientIsAdmin[i] = false;
	new Handle:sm_friendly_version;
	sm_friendly_version = CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Friendly Mode Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(sm_friendly_version, PLUGIN_VERSION);
	sm_friendly_action_h = CreateConVar("sm_friendly_action_h", "-1", "(Any integer, -2 or greater) What action to take on living players who want to become Hostile? See this plugin's thread for details.", FCVAR_PLUGIN);
	sm_friendly_action_f = CreateConVar("sm_friendly_action_f", "-1", "(Any integer, -2 or greater) What action to take on living players who want to become Friendly? See this plugin's thread for details.", FCVAR_PLUGIN);
	sm_friendly_killsentry = CreateConVar("sm_friendly_killsentry", "1", "(0/1) When enabled, a Friendly Engineer will run the command DESTROY 2 upon becoming non-Friendly. This should destroy his sentry.", FCVAR_PLUGIN);
	sm_friendly_remember = CreateConVar("sm_friendly_remember", "0", "(0/1) If enabled, a player who somehow dies while Friendly be Friendly upon respawn.", FCVAR_PLUGIN);
	sm_friendly_blockweps = CreateConVar("sm_friendly_blockweps", "0", "(0/1) If enabled, a Friendly player will be unable to take out certain weapons.", FCVAR_PLUGIN);
	sm_friendly_invuln = CreateConVar("sm_friendly_invuln", "2", "(0/1/2/3) 0 = Friendly players have full godmode. 1 = Buddha. 2 = Only invulnerable to other players. 3 = Invuln to other players AND himself.", FCVAR_PLUGIN);
	sm_friendly_notarget = CreateConVar("sm_friendly_notarget", "1", "(0/1) If enabled, a Friendly player will be invisible to sentries, immune to airblasts, etc.", FCVAR_PLUGIN);
	sm_friendly_noblock = CreateConVar("sm_friendly_noblock", "1", "(0/1) If enabled, a Friendly player will not be able to block the paths of other players.", FCVAR_PLUGIN);
	sm_friendly_alpha = CreateConVar("sm_friendly_alpha", "128", "(Any integer, -1 thru +255) Sets the alpha visibility of friendly players. -1 disables this feature.", FCVAR_PLUGIN);
	sm_friendly_update = CreateConVar("sm_friendly_update", "1", "(0/1/2) Updater compatibility. 0 = disabled, 1 = auto-download, 2 = auto-download and auto-install", FCVAR_PLUGIN);
	RegAdminCmd("sm_friendly", OnToggleFriendly, 0, "Toggles Friendly Mode");
	RegAdminCmd("sm_friendly_admin", OnToggleAdmin, ADMFLAG_BAN, "Players who toggle this command will be able to damage friendly players while not friendly themselves.");
	RegAdminCmd("sm_friendly_debug", DebugFriendly, ADMFLAG_ROOT, "Outputs various things to the console. Useful for those who are editing the Friendly Mode plugin.");
	HookEvent("player_spawn", OnPlayerSpawned);
	
	HookConVarChange(sm_friendly_version, Callback_VersionConVarChanged);

}

public Action:OnToggleFriendly(client, args) {
	if(client != 0) {
		if(IsPlayerAlive(client)) {
			UsedCommandAlive(client);
		} else {
			UsedCommandDead(client);
		}
		return Plugin_Handled;
	} else {
	PrintToChat(client, "%s Not a valid client. You must be in the game to use sm_friendly.", CHAT_PREFIX);
	return Plugin_Handled;
	}
}

UsedCommandAlive(const client) {
	if (ClientRequestedChange[client]) {
		ClientRequestedChange[client] = false;
		PrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
	} else {
		if (ClientIsFriendly[client]) {
			if (GetConVarInt(sm_friendly_action_h) == -2) {
				PrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
			} if (GetConVarInt(sm_friendly_action_h) == -1) {
				PrintToChat(client, "%s You will not be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				FakeClientCommand(client, "kill");
			} if (GetConVarInt(sm_friendly_action_h) == 0) {
				MakeClientHostile(client);
				PrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
			} if (GetConVarInt(sm_friendly_action_h) > 0) {
				MakeClientHostile(client);
				SlapPlayer(client, GetConVarInt(sm_friendly_action_h));
				PrintToChat(client, "%s You are no longer Friendly, but took damage because of the switch!", CHAT_PREFIX);
			}
		} else {
			if (GetConVarInt(sm_friendly_action_f) == -2) {
				PrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
			} if (GetConVarInt(sm_friendly_action_f) == -1) {
				PrintToChat(client, "%s You will be Friendly upon respawning.", CHAT_PREFIX);
				ClientRequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				FakeClientCommand(client, "kill");
			} if (GetConVarInt(sm_friendly_action_f) == 0) {
				MakeClientFriendly(client);
				PrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
				FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
			} if (GetConVarInt(sm_friendly_action_f) > 0) {
				MakeClientFriendly(client);
				SlapPlayer(client, GetConVarInt(sm_friendly_action_f));
				PrintToChat(client, "%s You were made Friendly, but took damage because of the switch!", CHAT_PREFIX);
			}
		}
	}
}

UsedCommandDead(const client) {
	if (ClientRequestedChange[client]) {
		ClientRequestedChange[client] = false;
		PrintToChat(client, "%s You will not toggle Friendly mode upon respawning.", CHAT_PREFIX);
	} else {
		ClientRequestedChange[client] = true;
		PrintToChat(client, "%s You will toggle Friendly mode upon respawning.", CHAT_PREFIX);
	}
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ClientRequestedChange[client]) {
		if (ClientIsFriendly[client]) {
			MakeClientHostile(client);
			PrintToChat(client, "%s You are no longer Friendly.", CHAT_PREFIX);
		} else {
			MakeClientFriendly(client);
			PrintToChat(client, "%s You are now Friendly.", CHAT_PREFIX);
		}
	} else {
		if (ClientIsFriendly[client]) {
			if (GetConVarBool(sm_friendly_remember)) {
				ReapplyFriendly(client);
				PrintToChat(client, "%s You are still Friendly.", CHAT_PREFIX);
			} else {
				MakeClientHostile(client);
				PrintToChat(client, "%s You have been taken out of Friendly mode because you respawned.", CHAT_PREFIX);
			}
		}
	}
}



MakeClientHostile(const client) {
	ClientIsFriendly[client] = false;
	ClientRequestedChange[client] = false;
	if (GetConVarInt(sm_friendly_invuln) < 2) {
		RemoveInvuln(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		MakeTarget(client);
	}
	if (GetConVarBool(sm_friendly_killsentry)) {
		FakeClientCommand(client, "destroy 2");
	}
	if (GetConVarBool(sm_friendly_noblock)) {
		GiveCollision(client);
	}
	if (GetConVarInt(sm_friendly_alpha) > -1) {
		RemoveAlpha(client);
	}
}


MakeClientFriendly(const client) {
	ClientIsFriendly[client] = true;
	ClientRequestedChange[client] = false;
	if (GetConVarInt(sm_friendly_invuln) < 2) {
		GiveInvuln(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		RemoveTarget(client);
	}
	if (GetConVarBool(sm_friendly_blockweps)) {
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	if (GetConVarBool(sm_friendly_noblock)) {
		RemoveCollision(client);
	}
	if (GetConVarInt(sm_friendly_alpha) > -1) {
		SetAlpha(client);
	}
}

GiveInvuln(const client) {
	if (GetConVarInt(sm_friendly_invuln) == 0) {
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //godmode
	}
	if (GetConVarInt(sm_friendly_invuln) == 1) {
		SetEntProp(client, Prop_Data, "m_takedamage", 1, 1); //buddha
	}
}

RemoveInvuln(const client) {
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

MakeTarget(const client) {
	new flags = GetEntityFlags(client)&~FL_NOTARGET;
	SetEntityFlags(client, flags);
}

RemoveTarget(const client) {
	new flags = GetEntityFlags(client)|FL_NOTARGET;
	SetEntityFlags(client, flags);
}

GiveCollision(const client) {
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
}

RemoveCollision(const client) {
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
}

SetAlpha(const client) {
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, _, _, _, GetConVarInt(sm_friendly_alpha));
	SetWearableInvis(client);
}

RemoveAlpha(const client) {
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, _, _, _, _);
	SetWearableInvis(client, false);
}

ReapplyFriendly(const client) {
	if (GetConVarInt(sm_friendly_invuln) < 2) {
		GiveInvuln(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		RemoveTarget(client);
	}
	if (GetConVarBool(sm_friendly_noblock)) {
		RemoveCollision(client);
	}
	if (GetConVarInt(sm_friendly_alpha) > -1) {
		SetAlpha(client);
	}
}

public Action:OnToggleAdmin(client, args) {
	if (ClientIsAdmin[client]) {
		ClientIsAdmin[client] = false;
		PrintToChat(client, "%s You will not be able to damage friendly players.", CHAT_PREFIX);
		return Plugin_Handled;
	} else {
		if (GetConVarInt(sm_friendly_invuln) < 2) {
			PrintToChat(client, "%s You cannot bypass Friendly Mode while sm_friendly_invuln = 0 or 1", CHAT_PREFIX);
			return Plugin_Handled;
		} else {
			ClientIsAdmin[client] = true;
			PrintToChat(client, "%s You are now bypassing Friendly Mode.", CHAT_PREFIX);
			return Plugin_Handled;
		}
	}
}

//The following code was borrowed from FlaminSarge's Ghost Mode plugin: forums.alliedmods.net/showthread.php?t=183266
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
//The previous code was borrowed from FlaminSarge's Ghost Mode plugin: forums.alliedmods.net/showthread.php?t=183266


public OnEntityCreated(building, const String:classname[]) {
	if(building > 0) {
		SDKHook(building, SDKHook_Spawn, OnEntitySpawned);
	}
}

public OnEntitySpawned(building) {
	SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
}

public OnClientPutInServer(client)
{
	HookNewClient(client);
}

HookNewClient(const client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponSwitch(client, weapon)
{
	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

	if(ClientIsFriendly[client] && GetConVarBool(sm_friendly_blockweps))
	{
		if(StrEqual(sWeapon, "tf_weapon_flamethrower") || StrEqual(sWeapon, "tf_weapon_medigun") || StrEqual(sWeapon, "tf_weapon_bonesaw") || StrEqual(sWeapon, "tf_weapon_compound_bow") || StrEqual(sWeapon, "tf_weapon_bat_wood") || StrEqual(sWeapon, "tf_weapon_jar") || StrEqual(sWeapon, "tf_weapon_jar_milk") || StrEqual(sWeapon, "tf_weapon_fireaxe") || StrEqual(sWeapon, "tf_weapon_lunchbox") || StrEqual(sWeapon, "tf_weapon_crossbow") || StrEqual(sWeapon, "tf_weapon_sapper"))
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:BuildingTakeDamage(building, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (attacker < 1 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	new String:classname[64];
	GetEntityClassname(building, classname, sizeof(classname));
	if (StrEqual(classname, "obj_sentrygun", false) || StrEqual(classname, "obj_dispenser", false) || StrEqual(classname, "obj_teleporter", false))	// make sure it is a building
	{
		if(ClientIsFriendly[attacker])
		{
		damage = 0.0;
		return Plugin_Handled;
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

public Action:DebugFriendly(client, args) {
	PrintToConsole(client, "%s Friendly: %i, Admin: %i, Changing: %i, Alive: %i, Remember: %i, BlockWeps: %i, ActionH: %i, ActionF: %i, Invuln: %i, NoTarget: %i, NoBlock: %i, Alpha: %i, Update: %i", CHAT_PREFIX, (ClientIsFriendly[client]), (ClientIsAdmin[client]), (ClientRequestedChange[client]), (IsPlayerAlive(client)), (GetConVarInt(sm_friendly_remember)), (GetConVarInt(sm_friendly_blockweps)), (GetConVarInt(sm_friendly_action_h)), (GetConVarInt(sm_friendly_action_f)), (GetConVarInt(sm_friendly_invuln)), (GetConVarInt(sm_friendly_notarget)), (GetConVarInt(sm_friendly_noblock)), (GetConVarInt(sm_friendly_alpha)), (GetConVarInt(sm_friendly_update)));
	return Plugin_Handled;
}


//Updater code begins here, code shamelessly borrowed and modified from Dr. McKay's "Automatic Steam Update" plugin.

public OnAllPluginsLoaded() {
	if(LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}
public Callback_VersionConVarChanged(Handle:sm_friendly_version, const String:oldValue[], const String:newValue[]) {
	SetConVarString(sm_friendly_version, PLUGIN_VERSION);
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
		PrintToChatAll("%s An update has been installed, a map change is needed.", CHAT_PREFIX);
	}
	if (GetConVarInt(sm_friendly_update) == 1) {
		PrintToChatAll("%s An update has been downloaded, will be installed upon map change.", CHAT_PREFIX);
	}
}
//////////////////////////////////////////////Updater Code Ends Here