#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_DESCRIPTION "Blocks frequent use molotov, vomitjar and pipe bomb."

new Handle:admintimeout;
new Handle:timeout_type;
new Handle:molotov_timeout;
new Handle:vomitjar_timeout;
new Handle:pipe_bomb_timeout;
new UsedMolotov[MAXPLAYERS+1] = 1;
new UsedVomitjar[MAXPLAYERS+1] = 1;
new UsedPipeBomb[MAXPLAYERS+1] = 1;

public Plugin:myinfo = {
	name = "[L4D2] Throwing AntiSpam",
	author = "emsit",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://www.emsit.sk/"
}

public OnPluginStart() {
	CreateConVar("ThrowingAntiSpam_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_REPLICATED | FCVAR_NOTIFY);
	admintimeout = CreateConVar("ThrowingAntiSpam_admintimeout", "1", "0 -> Enable timeout for admins, 1 -> Disable timeout for admins", FCVAR_PLUGIN);
	timeout_type = CreateConVar("ThrowingAntiSpam_timeout_type", "1", "0 -> Fix timeout, 1 -> Penalty timeout", FCVAR_PLUGIN);
	molotov_timeout = CreateConVar("ThrowingAntiSpam_molotov_timeout", "15.0", "Molotov timeout", FCVAR_PLUGIN);
	vomitjar_timeout = CreateConVar("ThrowingAntiSpam_vomitjar_timeout", "10.0", "Vomitjar timeout", FCVAR_PLUGIN);
	pipe_bomb_timeout = CreateConVar("ThrowingAntiSpam_pipe_bomb_timeout", "5.0", "Pipe bomb timeout", FCVAR_PLUGIN);
	AutoExecConfig(true, "ThrowingAntiSpam");   

	HookEvent("weapon_fire", Event_weapon_fire);
	HookEvent("player_disconnect", Event_player_disconnect);
	HookEvent("round_start", Event_restart_plugin);
	HookEvent("round_end", Event_restart_plugin);
	HookEvent("finale_win", Event_restart_plugin);
	HookEvent("mission_lost", Event_restart_plugin);
	HookEvent("map_transition", Event_restart_plugin);	
}

// weapon_fire event
public Action:Event_weapon_fire(Handle:h_event, const String:Name[], bool:DontBroadcast) {
	decl String:weapon[32], client, Float:timeout;
	client = GetClientOfUserId(GetEventInt(h_event, "userid"));

	if (client <= 0 && !IsClientInGame(client) && !IsPlayerAlive(client)) {
		return Plugin_Handled;
	}

	if (GetAdminFlag(GetUserAdmin(client), Admin_Cheats, Access_Effective) && GetConVarInt(admintimeout) == 1) {
		return Plugin_Continue;
	}

	GetEventString(h_event, "weapon", weapon, sizeof(weapon));
	if (StrEqual(weapon, "molotov")) {
		if (GetConVarInt(molotov_timeout) > 0) {
			if (GetConVarInt(timeout_type) == 1) {
				timeout = GetConVarFloat(molotov_timeout) * UsedMolotov[client];
			} else {
				timeout = GetConVarFloat(molotov_timeout);
			}
			SDKHook(client, SDKHook_WeaponSwitch, OnMolotovSwitch);
			PrintToChat(client, "\x01[SM] \x04Molotov \x01blocked for \x03%is.", RoundFloat(timeout));
			CreateTimer(timeout, UnblockSwitchMolotov, client);
			UsedMolotov[client]++;
		}
	} else if (StrEqual(weapon, "vomitjar")) {
		if (GetConVarInt(vomitjar_timeout) > 0) {
			if (GetConVarInt(timeout_type) == 1) {
				timeout = GetConVarFloat(vomitjar_timeout) * UsedVomitjar[client];
			} else {
				timeout = GetConVarFloat(vomitjar_timeout);
			}
			SDKHook(client, SDKHook_WeaponSwitch, OnVomitjarSwitch);
			PrintToChat(client, "\x01[SM] \x04Vomitjar \x01blocked for \x03%is.", RoundFloat(timeout));
			CreateTimer(timeout, UnblockSwitchVomitjar, client);
			UsedVomitjar[client]++;
		}
	} else if (StrEqual(weapon, "pipe_bomb")) {
		if (GetConVarInt(pipe_bomb_timeout) > 0) {
			if (GetConVarInt(timeout_type) == 1) {
				timeout = GetConVarFloat(pipe_bomb_timeout) * UsedPipeBomb[client];
			} else {
				timeout = GetConVarFloat(pipe_bomb_timeout);
			}
			SDKHook(client, SDKHook_WeaponSwitch, OnPipebombSwitch);
			PrintToChat(client, "\x01[SM] \x04Pipe bomb \x01blocked for \x03%is.", RoundFloat(timeout));
			CreateTimer(timeout, UnblockSwitchPipebomb, client);
			UsedPipeBomb[client]++;
		}
	}
	return Plugin_Continue;
}

// block Molotov
public Action:UnblockSwitchMolotov(Handle:h_Timer, any:client) {
	SDKUnhook(client, SDKHook_WeaponSwitch, OnMolotovSwitch);
}

public Action:OnMolotovSwitch(client, weapon) {
	decl String:s_Weapon[32];
	GetEdictClassname(weapon, s_Weapon, sizeof(s_Weapon));

	if(StrEqual(s_Weapon, "weapon_molotov")) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// block Vomitjar
public Action:UnblockSwitchVomitjar(Handle:h_Timer, any:client) {
	SDKUnhook(client, SDKHook_WeaponSwitch, OnVomitjarSwitch);
}

public Action:OnVomitjarSwitch(client, weapon) {
	decl String:s_Weapon[32];
	GetEdictClassname(weapon, s_Weapon, sizeof(s_Weapon));

	if(StrEqual(s_Weapon, "weapon_vomitjar")) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// block Pipe bomb
public Action:UnblockSwitchPipebomb(Handle:h_Timer, any:client) {
	SDKUnhook(client, SDKHook_WeaponSwitch, OnPipebombSwitch);
}

public Action:OnPipebombSwitch(client, weapon) {
	decl String:s_Weapon[32];
	GetEdictClassname(weapon, s_Weapon, sizeof(s_Weapon));

	if(StrEqual(s_Weapon, "weapon_pipe_bomb")) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// reset variables
public Action:Event_restart_plugin(Handle:h_event, const String:Name[], bool:DontBroadcast) {
	for(new i = 1; i <= MAXPLAYERS; i++) {
		UsedMolotov[i] = 1;
		UsedVomitjar[i] = 1;
		UsedPipeBomb[i] = 1;
	}
	return Plugin_Continue;
}

public Action:Event_player_disconnect(Handle:h_event, const String:Name[], bool:DontBroadcast) {
	decl client;
	client = GetClientOfUserId(GetEventInt(h_event, "userid"));
	UsedMolotov[client] = 1;
	UsedVomitjar[client] = 1;
	UsedPipeBomb[client] = 1;
}