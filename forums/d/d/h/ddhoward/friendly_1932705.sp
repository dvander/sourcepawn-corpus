#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>

#define PLUGIN_VERSION "13.0414 (1406)"

new bool:ClientIsFriendly[MAXPLAYERS+1] = {false, ...};
new bool:ClientLeavingFriendly[MAXPLAYERS+1] = {false, ...};
new bool:ClientEnteringFriendly[MAXPLAYERS+1] = {false, ...};
new bool:ClientIsSpawning[MAXPLAYERS+1] = {false, ...};
new bool:ClientKilledOnSwitch[MAXPLAYERS+1] = {false, ...};
new Handle:sm_friendly_blockweps = INVALID_HANDLE;
new Handle:sm_friendly_remember = INVALID_HANDLE;
new Handle:sm_friendly_punish_hostile = INVALID_HANDLE;
new Handle:sm_friendly_punish_friendly = INVALID_HANDLE;
new Handle:sm_friendly_killsentry = INVALID_HANDLE;
new Handle:sm_friendly_wait_hostile = INVALID_HANDLE;
new Handle:sm_friendly_wait_friendly = INVALID_HANDLE;
new Handle:sm_friendly_version = INVALID_HANDLE;
new Handle:sm_friendly_buddha = INVALID_HANDLE;
new Handle:sm_friendly_notarget = INVALID_HANDLE;

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
	sm_friendly_version = CreateConVar("sm_friendly_version", PLUGIN_VERSION, "Plugin Version, DO NOT MODIFY.",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	SetConVarString(sm_friendly_version, PLUGIN_VERSION);
	
	for(new i=1; i<MAXPLAYERS+1; i++) ClientIsFriendly[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++) ClientLeavingFriendly[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++) ClientEnteringFriendly[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++) ClientIsSpawning[i] = false;
	for(new i=1; i<MAXPLAYERS+1; i++) ClientKilledOnSwitch[i] = false;
	sm_friendly_wait_hostile = CreateConVar("sm_friendly_wait_hostile", "0", "(0/1) Should a player disabling friendly mode be immediately made hostile, or remain friendly until respawning? 0 = immediate, 1 = wait until respawn", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_wait_friendly = CreateConVar("sm_friendly_wait_friendly", "0", "(0/1) Should a player enabling friendly mode be immediately made friendly, or remain hostile until respawning? 0 = immediate, 1 = wait until respawn", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_punish_hostile = CreateConVar("sm_friendly_punish_hostile", "-1", "If sm_friendly_wait_hostile = 0, how much damage to slap a player exiting friendly mode? Negative values cause the player to suicide.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_punish_friendly = CreateConVar("sm_friendly_punish_friendly", "-1", "If sm_friendly_wait_friendly = 0, how much damage to slap a player entering friendly mode? Negative values cause the player to suicide.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_killsentry = CreateConVar("sm_friendly_killsentry", "1", "(0/1) When enabled, a friendly Engineer will run the command DESTROY 2 upon becoming hostile. This should destroy his sentry.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_remember = CreateConVar("sm_friendly_remember", "0", "(0/1) If enabled, a player who somehow dies while friendly be friendly upon respawn.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_blockweps = CreateConVar("sm_friendly_blockweps", "0", "(0/1) If enabled, a friendly player will be unable to take out certain weapons.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_buddha = CreateConVar("sm_friendly_buddha", "1", "(0/1) If enabled, a friendly player will have full buddha mode. If disabled, he will only be immune to other players' basic attacks.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_friendly_notarget = CreateConVar("sm_friendly_notarget", "1", "(0/1) If enabled, a friendly player will be invisible to sentries, immune to airblasts, etc.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_friendly", OnToggleFriendly, ADMFLAG_BAN, "Toggles friendly on/off");
//	RegAdminCmd("sm_debugfriendly", DebugFriendlyCheck, ADMFLAG_ROOT, "debugger");
	HookEvent("player_spawn", OnPlayerSpawned);
}

ClientIsAlive(const client) {
	if (ClientIsFriendly[client]) {
		if (ClientLeavingFriendly[client]) {
			FriendlyWantsToStayFriendly(client);
		}
		else {
			FriendlyWantsToBeHostile(client);
		}
	}
	else {
		if (ClientEnteringFriendly[client]) {
			HostileWantsToStayHostile(client);
		}
		else {
			HostileWantsToBeFriendly(client);
		}
	}
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClientIsSpawning[client] = true;
	if (GetConVarBool(sm_friendly_remember) && (ClientIsFriendly[client]) && ((ClientLeavingFriendly[client]) == false)) {
		if (GetConVarBool(sm_friendly_notarget)) {
			RemoveTarget(client);
		}
		if (GetConVarBool(sm_friendly_buddha)) {
			MakeBuddha(client);
		}
	}
	else {
		if (ClientKilledOnSwitch[client]) {
			if (ClientLeavingFriendly[client]) {
				MakeClientHostile(client);
				ClientKilledOnSwitch[client] = false;
			}
			if (ClientEnteringFriendly[client]) {
				MakeClientFriendly(client);
				ClientKilledOnSwitch[client] = false;
			}
		}
		else {
			if (ClientIsFriendly[client]) {
				if (GetConVarBool(sm_friendly_remember)) {
					if (ClientLeavingFriendly[client]) {
						MakeClientHostile(client);
						PrintToChat(client, "Friendly mode disabled.");
					}
				}
				else {
					PrintToChat(client, "Friendly mode is disabled upon respawn.");
					MakeClientHostile(client);
				}
			}
			else {
				if (ClientEnteringFriendly[client]) {
					MakeClientFriendly(client);
					PrintToChat(client, "Friendly mode enabled.");
				}
			}
		}
	}
	ClientIsSpawning[client] = false;
}

MakeClientHostile(const client) {
	ClientIsFriendly[client] = false;
	ClientLeavingFriendly[client] = false;
	ClientEnteringFriendly[client] = false;
	if (GetConVarBool(sm_friendly_buddha)) {
		RemoveBuddha(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		MakeTarget(client);
	}
	KillSentry(client);
	if (ClientIsSpawning[client] == false) {
		HostileSlap(client);
	}
}

MakeClientFriendly(const client) {
	ClientIsFriendly[client] = true;
	ClientLeavingFriendly[client] = false;
	ClientEnteringFriendly[client] = false;
	if (GetConVarBool(sm_friendly_buddha)) {
		MakeBuddha(client);
	}
	if (GetConVarBool(sm_friendly_notarget)) {
		RemoveTarget(client);
	}
	if (ClientIsSpawning[client] == false) {
		FriendlySlap(client);
	}
	if (GetConVarBool(sm_friendly_blockweps)) {
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

HostileWantsToBeFriendly(const client) {
	if (GetConVarBool(sm_friendly_wait_friendly)) {
		ClientEnteringFriendly[client] = true;
		ReplyToCommand(client, "Friendly mode will be enabled when you respawn.");
	}
	else {
		MakeClientFriendly(client);
		if (GetConVarInt(sm_friendly_punish_friendly) < 0) {
			ReplyToCommand(client, "Friendly mode will be enabled when you respawn.");
		}
		else {
			ReplyToCommand(client, "Friendly mode enabled.");
		}
	}
}

HostileWantsToStayHostile(const client) {
	ClientEnteringFriendly[client] = false;
	ReplyToCommand(client, "Friendly mode will be not be enabled when you respawn.");
}

FriendlyWantsToBeHostile(const client) {
	if (GetConVarBool(sm_friendly_wait_hostile)) {
		ClientLeavingFriendly[client] = true;
		ReplyToCommand(client, "You must respawn to disable friendly mode.");
	}
	else {
		MakeClientHostile(client);
		if (GetConVarInt(sm_friendly_punish_hostile) < 0) {
			ReplyToCommand(client, "Friendly mode will be disabled when you respawn.");
		}
		else {
			ReplyToCommand(client, "Friendly mode disabled.");
		}
	}
}

FriendlyWantsToStayFriendly(const client) {
	ClientLeavingFriendly[client] = false;
	if (GetConVarBool(sm_friendly_remember)) {
		ReplyToCommand(client, "Friendly mode will be not be disabled when you respawn.");
	}
	else {
		ReplyToCommand(client, "Friendly mode is always disabled upon respawn.");
	}
}

HostileSlap(const client) {
	if (GetConVarInt(sm_friendly_punish_hostile) > 0) {
		FakeClientCommand(client, "voicemenu 2 5;");
		SlapPlayer(client, GetConVarInt(sm_friendly_punish_hostile));
	}
	if (GetConVarInt(sm_friendly_punish_hostile) == 0) {
		FakeClientCommand(client, "voicemenu 2 1;");
	}
	if (GetConVarInt(sm_friendly_punish_hostile) < 0) {
		FakeClientCommand(client, "voicemenu 0 7;");
		FakeClientCommand(client, "kill");
		ClientLeavingFriendly[client] = true;
		ClientKilledOnSwitch[client] = true;
	}
}

FriendlySlap(const client) {
	if (GetConVarInt(sm_friendly_punish_friendly) > 0) {
		FakeClientCommand(client, "voicemenu 2 4;");
		SlapPlayer(client, GetConVarInt(sm_friendly_punish_friendly));
	}
	if (GetConVarInt(sm_friendly_punish_friendly) == 0) {
		FakeClientCommand(client, "voicemenu 2 4;");
	}
	if (GetConVarInt(sm_friendly_punish_friendly) < 0) {
		FakeClientCommand(client, "voicemenu 0 7;");
		FakeClientCommand(client, "kill");
		ClientEnteringFriendly[client] = true;
		ClientKilledOnSwitch[client] = true;
	}
}

KillSentry(const client) {
	if (GetConVarBool(sm_friendly_killsentry)) {
		FakeClientCommand(client, "destroy 2");
	}
}

MakeBuddha(const client) {
	SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
}

RemoveBuddha(const client) {
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


public Action:OnToggleFriendly(client, args) {
	if(client != 0) {
		if(IsPlayerAlive(client)) {
			ClientIsAlive(client);
		}
		else {
			ReplyToCommand(client, "You cannot change !friendly status when dead.");
		}
		return Plugin_Handled;
	}
	else {
	ReplyToCommand(client, "Not a valid client. You must be in the game to use sm_friendly.");
	return Plugin_Handled;
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
	ClientIsFriendly[client] = false;
	ClientLeavingFriendly[client] = false;
	ClientEnteringFriendly[client] = false;
	ClientIsSpawning[client] = false;
	ClientKilledOnSwitch[client] = false;
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

/*
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
} */