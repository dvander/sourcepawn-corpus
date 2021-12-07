#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>

#define PLUGIN_VERSION "13.0412 T1249"

new bool:ClientIsFriendly[MAXPLAYERS+1] = {false, ...};
new bool:ClientLeavingFriendly[MAXPLAYERS+1] = {false, ...};
new Handle:sm_friendly_blockweps = INVALID_HANDLE;
new Handle:sm_friendly_remember = INVALID_HANDLE;
new Handle:sm_friendly_slap = INVALID_HANDLE;
new Handle:sm_friendly_killsentry = INVALID_HANDLE;
new Handle:sm_friendly_nowait = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Friendly Mode",
	author = "Derek D. Howard",
	description = "Allows players to enter buddha mode, while being unable to attack other players. Original code by Dyl0n.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=213205"
};

public OnPluginStart()
{
	for(new i=1; i<MAXPLAYERS+1; i++)
		ClientIsFriendly[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++)
		ClientLeavingFriendly[i] = false;
	CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Plugin Version",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_nowait = CreateConVar("sm_friendly_nowait", "1", "Should a player leaving friendly be immediately made unfriendly, or remain friendly until respawning? 1 = immediate, 0 = wait until respawn", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_remember = CreateConVar("sm_friendly_remember", "0", "(1/0) If enabled, a player who dies while friendly be friendly upon respawn.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_slap = CreateConVar("sm_friendly_slap", "99999", "How much damage to slap a player exiting friendly mode? 0 = disabled", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_killsentry = CreateConVar("sm_friendly_killsentry", "1", "(1/0) If enabled, a friendly Engineer's sentry will be destroyed upon becoming hostile.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_blockweps = CreateConVar("sm_friendly_blockweps", "0", "Enable/Disable(1/0) Block Weapons", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_friendly", OnToggleFriendly, ADMFLAG_BAN, "Toggles friendly on/off");
	RegAdminCmd("sm_debugfriendly", DebugFriendlyCheck, ADMFLAG_ROOT, "Checks if you are friendly or not, used by Derek to debug the plugin.");
	HookEvent("player_spawn", OnPlayerSpawned);
}

public Action:OnToggleFriendly(client, args) {
	if(IsPlayerAlive(client)) {
		if (ClientLeavingFriendly[client] == false) {
			if (ClientIsFriendly[client] == true) {
				if (GetConVarBool(sm_friendly_nowait)) {
					ClientIsFriendly[client] = false;
					SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
					new flags = GetEntityFlags(client)&~FL_NOTARGET;
					SetEntityFlags(client, flags);
					ReplyToCommand(client, "Friendly mode disabled.");
					if (GetConVarBool(sm_friendly_killsentry) == true) {
						FakeClientCommand(client, "destroy 2");
					}
					if (GetConVarInt(sm_friendly_slap) > 0) {
						FakeClientCommand(client, "voicemenu 0 7;");
						SlapPlayer(client, GetConVarInt(sm_friendly_slap));
					}
				}
				else {
					if (GetConVarBool(sm_friendly_remember)) {
						ReplyToCommand(client, "Friendly mode will be disabled upon respawn.");
						ClientLeavingFriendly[client] = true;
					}
					else {
						ReplyToCommand(client, "Friendly mode is disabled upon respawn.");
					}
				}
			}
			else {
				ClientIsFriendly[client] = true;
				new flags = GetEntityFlags(client)|FL_NOTARGET;
				SetEntityFlags(client, flags);
				SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
				ReplyToCommand(client, "Friendly mode enabled.");
			}
		}
		else {
			ClientLeavingFriendly[client] = false;
			if (GetConVarBool(sm_friendly_remember)) {
				ReplyToCommand(client, "You will remain Friendly upon respawning.");
			}
			else {
				ReplyToCommand(client, "Friendly mode is always disabled upon respawn.");
			}
		}
	}
	else {
		ReplyToCommand(client, "You cannot apply !friendly when dead.");
	}
	return Plugin_Handled;
}  

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ClientIsFriendly[client]) {
		if (GetConVarBool(sm_friendly_remember)) {
			if (ClientLeavingFriendly[client]) {
				ClientIsFriendly[client] = false;
				ClientLeavingFriendly[client] = false;
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
				new flags = GetEntityFlags(client)&~FL_NOTARGET;
				SetEntityFlags(client, flags);
				ReplyToCommand(client, "Friendly mode disabled due to respawn.");
				if (GetConVarBool(sm_friendly_killsentry)) {
					FakeClientCommand(client, "destroy 2");
				}
			}
		}
		else {
			ClientIsFriendly[client] = false;
			ClientLeavingFriendly[client] = false;
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			new flags = GetEntityFlags(client)&~FL_NOTARGET;
			SetEntityFlags(client, flags);
			ReplyToCommand(client, "Friendly mode disabled due to respawn.");
			if (GetConVarBool(sm_friendly_killsentry)) {
				FakeClientCommand(client, "destroy 2");
			}
		}
	}
}

public OnEntityCreated(building, const String:classname[])
{
	SDKHook(building, SDKHook_Spawn, OnEntitySpawned);
}

public OnEntitySpawned(building)
{
	SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
}

public OnClientPutInServer(client)
{
	ClientIsFriendly[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponSwitch(client, weapon)
{
	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

	if(ClientIsFriendly[client] && GetConVarBool(sm_friendly_blockweps))
	{
		if(StrEqual(sWeapon, "tf_weapon_flamethrower") || StrEqual(sWeapon, "tf_weapon_medigun") || StrEqual(sWeapon, "tf_weapon_builder") || StrEqual(sWeapon, "tf_weapon_bonesaw") || StrEqual(sWeapon, "tf_weapon_compound_bow") || StrEqual(sWeapon, "tf_weapon_bat_wood") || StrEqual(sWeapon, "tf_weapon_jar") || StrEqual(sWeapon, "tf_weapon_jar_milk") || StrEqual(sWeapon, "tf_weapon_fireaxe") || StrEqual(sWeapon, "tf_weapon_lunchbox") || StrEqual(sWeapon, "tf_weapon_crossbow"))
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
	decl String:weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));

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

public Action:DebugFriendlyCheck(client, args) {
	if ((ClientLeavingFriendly[client] == true) && (GetConVarBool(sm_friendly_nowait) == true)) {
		ReplyToCommand(client, "Nowait is on, and ClientLeavingFriendly is also on. Something is very wrong.");
	}
	else {
		if ((ClientIsFriendly[client] == true) && (ClientLeavingFriendly[client] == true)) {
			ReplyToCommand(client, "Friendly on, ClientLeavingFriendly on.");
		}
		if ((ClientIsFriendly[client] == true) && (ClientLeavingFriendly[client] == false)) {
			ReplyToCommand(client, "Friendly on, ClientLeavingFriendly off.");
		}
		if ((ClientIsFriendly[client] == false) && (ClientLeavingFriendly[client] == true)) {
			ReplyToCommand(client, "Friendly off, ClientLeavingFriendly on. Something is wrong.");
		}
		if ((ClientIsFriendly[client] == false) && (ClientLeavingFriendly[client] == false)) {
			ReplyToCommand(client, "Friendly off, ClientLeavingFriendly off.");
		}
	}
}