#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>

#define PLUGIN_VERSION "13.0416 (1048)"

new bool:ClientIsFriendly[MAXPLAYERS+1] = {false, ...};
new bool:ClientRequestedChange[MAXPLAYERS+1] = {false, ...};
new Handle:sm_friendly_blockweps = INVALID_HANDLE;
new Handle:sm_friendly_remember = INVALID_HANDLE;
new Handle:sm_friendly_action_h = INVALID_HANDLE;
new Handle:sm_friendly_action_f = INVALID_HANDLE;
new Handle:sm_friendly_killsentry = INVALID_HANDLE;
new Handle:sm_friendly_version = INVALID_HANDLE;
new Handle:sm_friendly_invuln = INVALID_HANDLE;
new Handle:sm_friendly_notarget = INVALID_HANDLE;

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
	sm_friendly_version = CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Plugin Version, DO NOT MODIFY.",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	SetConVarString(sm_friendly_version, PLUGIN_VERSION);
	
	for(new i=1; i<MAXPLAYERS+1; i++) ClientIsFriendly[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++) ClientRequestedChange[i] = false;
	sm_friendly_action_h = CreateConVar("sm_friendly_action_h", "-1", "(Any integer, -2 or greater) What action to take on living players who want to become Hostile? See this plugin's thread for details.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_action_f = CreateConVar("sm_friendly_action_f", "-1", "(Any integer, -2 or greater) What action to take on living players who want to become Friendly? See this plugin's thread for details.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_killsentry = CreateConVar("sm_friendly_killsentry", "1", "(0/1) When enabled, a Friendly Engineer will run the command DESTROY 2 upon becoming non-Friendly. This should destroy his sentry.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_remember = CreateConVar("sm_friendly_remember", "0", "(0/1) If enabled, a player who somehow dies while Friendly be Friendly upon respawn.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_blockweps = CreateConVar("sm_friendly_blockweps", "0", "(0/1) If enabled, a Friendly player will be unable to take out certain weapons.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_invuln = CreateConVar("sm_friendly_invuln", "2", "(0/1/2) If 0, Friendly players will have full godmode. If 1, they will have full buddha mode. If 2, they will only be invulnerable to the basic attacks of other players.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_notarget = CreateConVar("sm_friendly_notarget", "1", "(0/1) If enabled, a Friendly player will be invisible to sentries, immune to airblasts, etc.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_friendly", OnToggleFriendly, 0, "Toggles Friendly Mode");
	RegAdminCmd("sm_debugfriendly", DebugFriendly, ADMFLAG_ROOT, "Outputs various things to the console. Useful for those who are editing the Friendly Mode plugin.");
	HookEvent("player_spawn", OnPlayerSpawned);
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
	PrintToChat(client, "Not a valid client. You must be in the game to use sm_friendly.");
	return Plugin_Handled;
	}
}

UsedCommandAlive(const client) {
	if (ClientRequestedChange[client]) {
		ClientRequestedChange[client] = false;
		PrintToChat(client, "You will not toggle Friendly mode upon respawning.");
	} else {
		if (ClientIsFriendly[client]) {
			if (GetConVarInt(sm_friendly_action_h) == -2) {
				PrintToChat(client, "You will not be Friendly upon respawning.");
				ClientRequestedChange[client] = true;
			} if (GetConVarInt(sm_friendly_action_h) == -1) {
				PrintToChat(client, "You will not be Friendly upon respawning.");
				ClientRequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				FakeClientCommand(client, "kill");
			} if (GetConVarInt(sm_friendly_action_h) == 0) {
				MakeClientHostile(client);
				PrintToChat(client, "You are no longer Friendly.");
				FakeClientCommand(client, "voicemenu 2 1"); //"Battle Cry"
			} if (GetConVarInt(sm_friendly_action_h) > 0) {
				MakeClientHostile(client);
				SlapPlayer(client, GetConVarInt(sm_friendly_action_h));
				PrintToChat(client, "You are no longer Friendly, but took damage because of the switch!");
			}
		} else {
			if (GetConVarInt(sm_friendly_action_f) == -2) {
				PrintToChat(client, "You will be Friendly upon respawning.");
				ClientRequestedChange[client] = true;
			} if (GetConVarInt(sm_friendly_action_f) == -1) {
				PrintToChat(client, "You will be Friendly upon respawning.");
				ClientRequestedChange[client] = true;
				FakeClientCommand(client, "voicemenu 0 7"); //"No"
				FakeClientCommand(client, "kill");
			} if (GetConVarInt(sm_friendly_action_f) == 0) {
				MakeClientFriendly(client);
				PrintToChat(client, "You are now Friendly.");
				FakeClientCommand(client, "voicemenu 2 4"); //"Positive"
			} if (GetConVarInt(sm_friendly_action_f) > 0) {
				MakeClientFriendly(client);
				SlapPlayer(client, GetConVarInt(sm_friendly_action_f));
				PrintToChat(client, "You were made Friendly, but took damage because of the switch!");
			}
		}
	}
}

UsedCommandDead(const client) {
	if (ClientRequestedChange[client]) {
		ClientRequestedChange[client] = false;
		PrintToChat(client, "You will not toggle Friendly mode upon respawning.");
	} else {
		ClientRequestedChange[client] = true;
		PrintToChat(client, "You will toggle Friendly mode upon respawning.");
	}
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ClientRequestedChange[client]) {
		if (ClientIsFriendly[client]) {
			MakeClientHostile(client);
			PrintToChat(client, "You are no longer Friendly.");
		} else {
			MakeClientFriendly(client);
			PrintToChat(client, "You are now Friendly.");
		}
	} else {
		if (ClientIsFriendly[client]) {
			if (GetConVarBool(sm_friendly_remember)) {
				ReapplyFriendly(client);
				PrintToChat(client, "You are still Friendly.");
			} else {
				MakeClientHostile(client);
				PrintToChat(client, "You have been taken out of Friendly mode because you respawned.");
			}
		}
	}
}



MakeClientHostile(const client) {
	ClientIsFriendly[client] = false;
	ClientRequestedChange[client] = false;
	if (GetConVarInt(sm_friendly_invuln) != 2) {
		RemoveInvuln(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		MakeTarget(client);
	}
	if (GetConVarBool(sm_friendly_killsentry)) {
		FakeClientCommand(client, "destroy 2");
	}
}


MakeClientFriendly(const client) {
	ClientIsFriendly[client] = true;
	ClientRequestedChange[client] = false;
	if (GetConVarInt(sm_friendly_invuln) != 2) {
		GiveInvuln(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		RemoveTarget(client);
	}
	if (GetConVarBool(sm_friendly_blockweps)) {
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
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

ReapplyFriendly(const client) {
	if (GetConVarInt(sm_friendly_invuln) != 2) {
		GiveInvuln(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		RemoveTarget(client);
	}
}

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
		if(StrEqual(sWeapon, "tf_weapon_flamethrower") || StrEqual(sWeapon, "tf_weapon_medigun") || StrEqual(sWeapon, "tf_weapon_builder") || StrEqual(sWeapon, "tf_weapon_bonesaw") || StrEqual(sWeapon, "tf_weapon_compound_bow") || StrEqual(sWeapon, "tf_weapon_bat_wood") || StrEqual(sWeapon, "tf_weapon_jar") || StrEqual(sWeapon, "tf_weapon_jar_milk") || StrEqual(sWeapon, "tf_weapon_fireaxe") || StrEqual(sWeapon, "tf_weapon_lunchbox") || StrEqual(sWeapon, "tf_weapon_crossbow") || StrEqual(sWeapon, "tf_weapon_sapper"))
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

	if (attacker < 1 || attacker > MaxClients || client == attacker)
	{
		return Plugin_Continue;
	}

	if (ClientIsFriendly[attacker] || ClientIsFriendly[client])
	{
		damage = 0.0;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:DebugFriendly(client, args) {
	PrintToConsole(client, "Friendly: %i, Changing: %i, Alive: %i, Remember: %i, BlockWeps: %i, ActionH: %i, ActionF: %i, Invuln: %i, NoTarget: %i", (ClientIsFriendly[client]), (ClientRequestedChange[client]), (IsPlayerAlive(client)), (GetConVarInt(sm_friendly_remember)), (GetConVarInt(sm_friendly_blockweps)), (GetConVarInt(sm_friendly_action_h)), (GetConVarInt(sm_friendly_action_f)), (GetConVarInt(sm_friendly_invuln)), (GetConVarInt(sm_friendly_notarget)));
	return Plugin_Handled;
}