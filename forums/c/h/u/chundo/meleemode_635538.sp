/*
 * Melee Mode
 * Written by chundo (chundo@mefightclub.com)
 * Portions adapted from Sudden Death Melee Redux by bl4nk
 *
 * Licensed under the GPL version 2 or above
 */

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.4"

new bool:isMeleeEnabled = false;

new Handle:cvarEnable = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Melee Mode",
	author = "chundo",
	description = "Force everyone to use melee weapons",
	version = PLUGIN_VERSION,
	url = "http://www.mefightclub.com"
};

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("ForceMeleeMode", __NativeForceMelee);
	RegPluginLibrary("meleemode");
	return true;
}

public OnPluginStart()
{
	CreateConVar("sm_meleemode_version", PLUGIN_VERSION, "Melee Mode Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_meleemode_enable", "0", "Enable melee mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegConsoleCmd("equip", Command_Equip);
	__ForceMelee(GetConVarBool(cvarEnable));
	HookConVarChange(cvarEnable, EnableChange);
	AutoExecConfig();
}

public EnableChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (strcmp(newValue, "1") == 0) {
		__ForceMelee(true);
	} else {
		__ForceMelee(false);
	}
}

public __NativeForceMelee(Handle:plugin, numParams) {
	new bool:active = bool:GetNativeCell(1);
	return _:__ForceMelee(active);
}

public __ForceMelee(bool:active) {
	if (active && !isMeleeEnabled) {
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("teamplay_round_active", Event_RoundStart);
		HookEvent("teamplay_round_win", Event_RoundEnd);
		HookEvent("teamplay_round_start", Event_RoundEnd);

		StripAllToMelee();
		DisableResupply();

		isMeleeEnabled = true;

		PrintToChatAll("\x01[SM] \x04Melee only mode \x01enabled!");
	} else if (!active && isMeleeEnabled) {
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("teamplay_round_active", Event_RoundStart);
		UnhookEvent("teamplay_round_win", Event_RoundEnd);
		UnhookEvent("teamplay_round_start", Event_RoundEnd);

		EnableResupply();

		isMeleeEnabled = false;

		new maxc = GetMaxClients();
		for (new i = 1; i <= maxc; ++i) {
			if (IsClientInGame(i) && IsPlayerAlive(i)) {
				// HOLY HACK, BATMAN!
				// TF2_EquipPlayerClassWeapons() is broken, so respawn and teleport.
				new Float:origin[3];
				GetClientAbsOrigin(i, origin);
				new Float:angles[3];
				GetClientAbsAngles(i, angles);
				TF2_RespawnPlayer(i);
				TeleportEntity(i, origin, angles, NULL_VECTOR);
			}
		}

		PrintToChatAll("\x01[SM] \x04Melee only mode \x01disabled!");
	}
	return 1;
}

public Action:Command_Equip(client, args) {
	if (GetConVarBool(cvarEnable)) {
		CreateTimer(0.1, Timer_StripToMelee, client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_StripToMelee, client);
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	DisableResupply();
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	EnableResupply();
}

public Action:Timer_StripToMelee(Handle:timer, any:client) {
	StripToMelee(client);
}

StripAllToMelee() {
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
		StripToMelee(i);
}

StripToMelee(client) {
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		for (new i = 0; i <= 5; i++)
			if (i != 2)
				TF2_RemoveWeaponSlot(client, i);
		ClientCommand(client, "slot3");
	}
}

EnableResupply() {
	new iRegenerate = -1;
	while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1)
		AcceptEntityInput(iRegenerate, "Enable");
}

DisableResupply() {
	new iRegenerate = -1;
	while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1)
		AcceptEntityInput(iRegenerate, "Disable");
}
