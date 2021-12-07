/**
 * I am keeping this weapon
 * L4D2 plugin to keep your weapons on map changes on a Versus game.
 * http://wolfbit.com
 * Copyright (C) 2010 Hilario Pérez Corona (Muy Matón)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"0.8"

public Plugin:myinfo = {
	name = "[L4D2] I am keeping this weapon",
	author = "Muy Matón",
	description = "L4D2 extension to keep your weapons/health on map changes on a Versus game.",
	version = PLUGIN_VERSION,
	url = "http://wolfbit.com"
};

#define MAX_SUPPORTED_PLAYERS	64
#define MAX_LINE_WIDTH			32

// Data structure
new String:playerIds[MAX_SUPPORTED_PLAYERS][MAX_LINE_WIDTH];
new clientIds[MAX_SUPPORTED_PLAYERS];
new bool:positionUsed[MAX_SUPPORTED_PLAYERS];
new String:slotPrimary[MAX_SUPPORTED_PLAYERS][MAX_LINE_WIDTH];
new priAmmo[MAX_SUPPORTED_PLAYERS];
new priClip[MAX_SUPPORTED_PLAYERS];
new priUpgrade[MAX_SUPPORTED_PLAYERS];
new priUpgrAmmo[MAX_SUPPORTED_PLAYERS];
new String:slotSecondary[MAX_SUPPORTED_PLAYERS][MAX_LINE_WIDTH];
new secClip[MAX_SUPPORTED_PLAYERS];
new String:slotThrowable[MAX_SUPPORTED_PLAYERS][MAX_LINE_WIDTH];
new String:slotMedkit[MAX_SUPPORTED_PLAYERS][MAX_LINE_WIDTH];
new String:slotPills[MAX_SUPPORTED_PLAYERS][MAX_LINE_WIDTH];
new slotHealth[MAX_SUPPORTED_PLAYERS];
new Handle:timers[MAX_SUPPORTED_PLAYERS] = {INVALID_HANDLE, ...};

// ConVars
new Handle:hkeep_primary;
new Handle:hkeep_secondary;
new Handle:hkeep_throwable;
new Handle:hkeep_medkit;
new Handle:hkeep_pills;
new Handle:hkeep_health;
new Handle:hkeep_min_health;
new Handle:hkeep_commands_enabled;

// Find out if a plugin is enabled
new bool:pluginEnabled = false;

// Initialize convars, hooks and commands
public OnPluginStart() {
	CreateConVar("keep_version", PLUGIN_VERSION, "I will keep this weapon version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	hkeep_primary = CreateConVar("keep_primary", "1", "Keep the primary weapon on map change");
	hkeep_secondary = CreateConVar("keep_secondary", "1", "Keep the secondary weapon on map change");
	hkeep_throwable = CreateConVar("keep_throwable", "1", "Keep the throwable weapon on map change");
	hkeep_medkit = CreateConVar("keep_medkit", "1", "Keep the medkit on map change");
	hkeep_pills = CreateConVar("keep_pills", "1", "Keep pills/adrenaline on map change");
	hkeep_health = CreateConVar("keep_health", "1", "Keep the same health on map change");
	hkeep_min_health = CreateConVar("keep_min_health", "25", "Minimum health to start with. If a survivor ends with less than this amount, then he will start with this amount.");
	hkeep_commands_enabled = CreateConVar("keep_commands_enabled", "1", "Enable the keep_save and keep_load commands");
	
	HookEvent("player_team", Event_player_change_team);
	
	RegConsoleCmd("keep_save", Command_Save);
	RegConsoleCmd("keep_load", Command_Load);
	
	LogToGame("[L4D2] I will keep this weapon plugin was initialized");
	
	AutoExecConfig(true, "iamkeepingthis");
}

// On map start check for the game type to enable/disable the plugin
// Only for versus and teamversus should be enabled
public OnMapStart() {
	new Handle:currGameMode = FindConVar("mp_gamemode");
	decl String:currGameModeName[15];
	GetConVarString(currGameMode, currGameModeName, 15);
	
	LogToGame("Currently playing '%s' game mode", currGameModeName);
	
	if (StrEqual(currGameModeName, "versus") == true || StrEqual(currGameModeName, "coop") == true) {
		pluginEnabled = true;
		
		LogToGame("Keep plugin is enabled");
	} else {
		pluginEnabled = false;
		
		LogToGame("Keep plugin is disabled");
	}
}

// Manual keep_save command
public Action:Command_Save(client, args) {
	if (pluginEnabled == false) {
		return Plugin_Handled;
	}
	
	if (GetConVarBool(hkeep_commands_enabled) == true) {
		for (new i = 1; i <= GetClientCount(false); i++) {
			SaveClientData(i);
		}
	}
	
	return Plugin_Handled;
}

// Manual keep_load command
public Action:Command_Load(client, args) {
	if (pluginEnabled == false) {
		return Plugin_Handled;
	}

	if (GetConVarBool(hkeep_commands_enabled) == true) {
		for (new i = 1; i <= GetClientCount(false); i++) {
			RestoreClientData(i);
		}
	}
	
	return Plugin_Handled;
}

// On player disconnection (map change) save the player's items
public OnClientDisconnect(client) {
	if (pluginEnabled == false) {
		return;
	}

	SaveClientData(client);
}

// Checks whenever a player changes team.
// We are interested in the changes:
//     From a Survivor team to ANY team... To save the player's information
//     From ANY team to the Survivor team... To restore the player's information
public Action:Event_player_change_team(Handle:event, const String:name[], bool:dontBroadcast) {
	if (pluginEnabled == false) {
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetEventInt(event, "oldteam") == 2) {
		// If the player was a survivor, save his data
		SaveClientData(client);
	} else if (GetEventInt(event, "team") == 2) {
		// If the player is changing to a survivor team, restore his data
		
		// Search for the SteamID
		decl String:SteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, SteamID, sizeof(SteamID));

		// Don't do anything if it's a bot
		if (StrEqual(SteamID, "BOT")) {
			return;
		}

		// Seek out the idx where the SteamID stores the data
		new idx = FindSteamID(SteamID);
		if (positionUsed[idx] == false) {
			return;		
		}
		
		// Create a timer because the player is not instantly changed to
		// the survivor team... Check every 3 seconds until he's actually
		// a survivor to do the restoration
		timers[idx] = CreateTimer(3.0, RetryRestore, client, TIMER_REPEAT);
	}
}

// When a player changes team (spectator->survivor or infected-survivor)
// it takes a moment to actually be a survivor... So this timer function
// checks constantly until a player is spawned as a survivor to restore all
// his items
public Action:RetryRestore(Handle:timer, any:client) {
	// Verify that the player is a survivor
	if (GetClientTeam(client) != 2) {
		return;
	}

	// If the player is a survivor, then restore his data...
	// The restore funcion will cancel the timer
	RestoreClientData(client);
}

// Restore the information for a player
// Only restore it once
RestoreClientData(client) {
	// Only affects survivors
	if (GetClientTeam(client) != 2) {
		return;
	}
	
	// Get the SteamID
	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	// Don't do anything it it's a bot
	if (StrEqual(SteamID, "BOT")) {
		return;
	}

	// Find the index where the SteamID stores the data
	new idx = FindSteamID(SteamID);
	
	// Clear out the timer if there's one
	if (timers[idx] != INVALID_HANDLE) {
		CloseHandle(timers[idx]);
		timers[idx] = INVALID_HANDLE;
	}
	
	// Don't restore the data if it's not used...
	// because it can have garbage
	if (positionUsed[idx] == false) {
		return;		
	}
	
	// Restore all the data
	RestorePrimary(client, idx);
	RestoreSecondary(client, idx);
	RestoreThrowable(client, idx);
	RestoreMedkit(client, idx);
	RestorePills(client, idx);
	RestoreHealth(client, idx);
	
	// Dont allow the data to be restored twice
	positionUsed[idx] = false;
}

// Save all the information of a player
SaveClientData(client) {
	// Don't store information for an infected
	if (GetClientTeam(client) != 2) {
		return;
	}
	
	// Seek the SteamID
	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	// Don't do anything if it's a bot
	if (StrEqual(SteamID, "BOT")) {
		return;
	}
	
	// Find out in wich position of the array is the SteamID
	new idx = FindSteamID(SteamID);
	if (positionUsed[idx] == false) {
		playerIds[idx] = SteamID;
		positionUsed[idx] = true;
		clientIds[idx] = client;
	}
	
	// Save all the information
	SavePrimary(client, idx);
	SaveSecondary(client, idx);
	SaveThrowable(client, idx);
	SaveMedkit(client, idx);
	SavePills(client, idx);
	SaveHealth(client, idx);
}

// Find a StreamID in the structure
FindSteamID(String:SteamID[]) {
	new idx = -1;
	
	for (new i = 0; i < MAX_SUPPORTED_PLAYERS; i++) {
		if (positionUsed[i] == true) {
			if (StrEqual(playerIds[i], SteamID)) {
				return i;
			}
		} else if (idx == -1 && positionUsed[i] == false) {
			idx = i;
		}
	}
	
	// We've found a free position...
	if (idx >= 0) {
		return idx;
	}
	
	// We haven't found a position, so let's free one up
	LogToGame("Data array is full, i'll need to free up a space");
	for (new i = 0; i < MAX_SUPPORTED_PLAYERS; i++) {
		if (positionUsed[i] == true) {
			new client = clientIds[i];
			if (!IsClientConnected(client) || !IsClientInGame(client) || !IsClientAuthorized(client)) {
				LogToGame("Found the index '%d' with steam id '%s' to be available, freeing up!", i, playerIds[i]);
				
				positionUsed[i] = false;
				return i;
			}
		}
	}
	
	// No one found? Cannot be possible, we've got 64 slots and only 20 available players
	// we'll free up the last one
	LogToGame("No players to free up... Weird... Giving up on the last position.");
	positionUsed[MAX_SUPPORTED_PLAYERS - 1] = false;
	return MAX_SUPPORTED_PLAYERS - 1;
}

// Save the primary weapon
SavePrimary(client, idx) {
	GetWeaponNameAtSlot(client, 0, slotPrimary[idx], MAX_LINE_WIDTH);
	
	if (slotPrimary[idx][0] != 0) {
		priAmmo[idx] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo");
		priClip[idx] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
		priUpgrade[idx] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec");
		priUpgrAmmo[idx] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");

		LogToGame("Saving '%s' for player '%N'", slotPrimary[idx], client);
		LogToGame("Saving clip with '%d' bullets and '%d' extra ammo with flags (%d,%d) for player '%N'", priClip[idx], priAmmo[idx], priUpgrade[idx], priUpgrAmmo[idx]);
	}
}

// Restore the weapon for a player
RestorePrimary(client, idx) {
	if (GetConVarBool(hkeep_primary) == false || slotPrimary[idx][0] == 0) return;
	GiveToPlayer(client, slotPrimary[idx], 0);

	SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo", priAmmo[idx]);
	SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", priClip[idx]);
	SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec", priUpgrade[idx]);
	SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", priUpgrAmmo[idx]);
	
	LogToGame("Restoring clip with '%d' bullets and '%d' extra ammo with flags (%d,%d) for player '%N'", priClip[idx], priAmmo[idx], priUpgrade[idx], priUpgrAmmo[idx]);
}

// Save the secondary weapon
SaveSecondary(client, idx) {
	GetWeaponNameAtSlot(client, 1, slotSecondary[idx], MAX_LINE_WIDTH);
	
	if (StrEqual(slotSecondary[idx], "weapon_melee")) {
		// Thanx to Jonny for this code snippet...
		decl String:modelname[128];
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, "models/weapons/melee/v_fireaxe.mdl", false)) {
			slotSecondary[idx] = "fireaxe";
		} else if (StrEqual(modelname, "models/weapons/melee/v_crowbar.mdl", false)) {
			slotSecondary[idx] = "crowbar";
		} else if (StrEqual(modelname, "models/weapons/melee/v_cricket_bat.mdl", false)) {
			slotSecondary[idx] = "cricket_bat";
		} else if (StrEqual(modelname, "models/weapons/melee/v_katana.mdl", false)) {
			slotSecondary[idx] = "katana";
		} else if (StrEqual(modelname, "models/weapons/melee/v_bat.mdl", false)) {
			slotSecondary[idx] = "baseball_bat";
		} else if (StrEqual(modelname, "models/v_models/v_knife_t.mdl", false)) {
			slotSecondary[idx] = "knife";
		} else if (StrEqual(modelname, "models/weapons/melee/v_electric_guitar.mdl", false)) {
			slotSecondary[idx] = "electric_guitar";
		} else if (StrEqual(modelname, "models/weapons/melee/v_frying_pan.mdl", false)) {
			slotSecondary[idx] = "frying_pan";
		} else if (StrEqual(modelname, "models/weapons/melee/v_machete.mdl", false)) {
			slotSecondary[idx] = "machete";
		} else if (StrEqual(modelname, "models/weapons/melee/v_golfclub.mdl", false)) {
			slotSecondary[idx] = "golfclub";
		} else if (StrEqual(modelname, "models/weapons/melee/v_tonfa.mdl", false)) {
			slotSecondary[idx] = "tonfa";
		} else if (StrEqual(modelname, "models/weapons/melee/v_riotshield.mdl", false)) {
			slotSecondary[idx] = "riotshield";
		}
		LogToGame("Saving '%s' for player '%N'", slotSecondary[idx], client);
	} else if (StrEqual(slotSecondary[idx], "weapon_chainsaw")) {
		LogToGame("Saving '%s' for player '%N'", slotSecondary[idx], client);

		secClip[idx] = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1");
		
		LogToGame("Current ammunition for chainsaw is '%d' for player '%N'", secClip[idx], client);
	} else {
		LogToGame("Saving '%s' for player '%N'", slotSecondary[idx], client);
	}
}

// Restore the secondary weapon (melee, pistol or chainsaw)
RestoreSecondary(client, idx) {
	if (GetConVarBool(hkeep_secondary) == false || slotSecondary[idx][0] == 0) return;
	GiveToPlayer(client, slotSecondary[idx], 1);

	if (StrEqual(slotSecondary[idx], "weapon_chainsaw")) {
		SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", secClip[idx]);
		LogToGame("Chainsaw ammunition is set to '%d' for '%N'", secClip[idx]);
	}
}

// Save the Throwable item
SaveThrowable(client, idx) {
	GetWeaponNameAtSlot(client, 2, slotThrowable[idx], MAX_LINE_WIDTH);
	
	if (slotThrowable[idx][0] != 0) {
		LogToGame("Saving '%s' for player '%N'", slotThrowable[idx], client);
	}
}

// Restore the Throwable item
RestoreThrowable(client, idx) {
	if (GetConVarBool(hkeep_throwable) == false || slotThrowable[idx][0] == 0) return;
	GiveToPlayer(client, slotThrowable[idx], 2);
}

// Save the Medkit
SaveMedkit(client, idx) {
	GetWeaponNameAtSlot(client, 3, slotMedkit[idx], MAX_LINE_WIDTH);
	
	if (slotMedkit[idx][0] != 0) {
		LogToGame("Saving '%s' for player '%N'", slotMedkit[idx], client);
	}
}

// Restore the Medkit
RestoreMedkit(client, idx) {
	if (GetConVarBool(hkeep_medkit) == false || slotMedkit[idx][0] == 0) return;
	GiveToPlayer(client, slotMedkit[idx], 3);
}

// Save the player's pills
SavePills(client, idx) {
	GetWeaponNameAtSlot(client, 4, slotPills[idx], MAX_LINE_WIDTH);
	
	if (slotPills[idx][0] != 0) {
		LogToGame("Saving '%s' for player '%N'", slotPills[idx], client);
	}
}

// Restore the pills
RestorePills(client, idx) {
	if (GetConVarBool(hkeep_pills) == false || slotPills[idx][0] == 0) return;
	GiveToPlayer(client, slotPills[idx], 4);
}

// Save the player's health
SaveHealth(client, idx) {
	slotHealth[idx] = GetClientHealth(client);
	
	LogToGame("Saving '%d' health for player '%N'", slotHealth[idx], client);
}

// Restore the health to a client. It will restore the maximum amount of health
// testing the last health of the player and the convar keep_min_health.
// For example, if the player ended with 1 health and keep_min_health is 25, then
// 25 will be restored.
RestoreHealth(client, idx) {
	if (GetConVarBool(hkeep_health) == false) return;
	
	new toRestore = GetConVarInt(hkeep_min_health);
	if (toRestore < slotHealth[idx]) {
		toRestore = slotHealth[idx];
	}
	
	SetEntProp(client, Prop_Send, "m_iHealth", toRestore, 1);
	
	LogToGame("Restoring '%d' health for the player '%N'", toRestore, client);
}

// Get the weapon name in a slot
GetWeaponNameAtSlot(client, slot, String:weaponName[], maxlen) {
	new wIdx = GetPlayerWeaponSlot(client, slot);
	if (wIdx < 0) {
		weaponName[0] = 0;
		return;
	}
	
	GetEdictClassname(wIdx, weaponName, maxlen);
}

// Give an item to a client, but prior to that, the item in the slot will
// be removed.
// If it's a melee weapon, it will seek for any melee weapon that is
// pre-cached
GiveToPlayer(client, String:item[], slot) {
	// Seek a pre-cached melee weapon
	new count = 12;
	while (CheckForMelee(item, MAX_LINE_WIDTH) == 0 && count > 0) {
		count -= 1;
	}
	
	// If no pre-cached melee weapon found after testing the 12 of them,
	// then don't do anything
	if (count == 0) {
		return;
	}

	// Disappear the current item in the slot specified...
	RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));
	
	// Temporarily change the 'give' command, so it isn't a cheat
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);

	//  Using a new variable so we can remove weapon_ if found
	decl String:itemName[MAX_LINE_WIDTH];
	strcopy(itemName, MAX_LINE_WIDTH, item);
	
	// Remove weapon_
	if (StrContains(itemName, "weapon_")) {
		new idx = 0;
		while (item[idx + 7] != 0) {
			itemName[idx] = item[idx + 7];
			idx++;
		}
		itemName[idx] = 0;
	}

	// Give the item to the player
	FakeClientCommand(client, "give %s", itemName);
	
	// Log it on the console
	LogToGame("Giving '%s' to '%N'", itemName, client);

	// Change back the 'give' command to wichever flags it had
	SetCommandFlags("give", flags);
}

// This function will return 1 if it's not a melee or if a melee weapon
// is pre-cached, or 0 if it's a melee and NOT precached. When returning 0 it will 
// also modify the weapon parameter with the next weapon, so you can call 
// it 12 times while it returns 0 to seek for a pre-cached melee weapon
CheckForMelee(String:weapon[], maxlen) {
	if (StrEqual(weapon, "fireaxe")) {
		if (IsModelPrecached("models/weapons/melee/v_fireaxe.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "crowbar");
		}
	} else if (StrEqual(weapon, "crowbar")) {
		if (IsModelPrecached("models/weapons/melee/v_crowbar.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "cricket_bat");
		}
	} else if (StrEqual(weapon, "cricket_bat")) {
		if (IsModelPrecached("models/weapons/melee/v_cricket_bat.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "katana");
		}
	} else if (StrEqual(weapon, "weapon")) {
		if (IsModelPrecached("models/weapons/melee/v_katana.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "baseball_bat");
		}
	} else if (StrEqual(weapon, "baseball_bat")) {
		if (IsModelPrecached("models/weapons/melee/v_bat.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "knife");
		}
	} else if (StrEqual(weapon, "knife")) {
		if (IsModelPrecached("models/v_models/v_knife_t.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "electric_guitar");
		}
	} else if (StrEqual(weapon, "electric_guitar")) {
		if (IsModelPrecached("models/weapons/melee/v_electric_guitar.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "frying_pan");
		}
	} else if (StrEqual(weapon, "frying_pan")) {
		if (IsModelPrecached("models/weapons/melee/v_frying_pan.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "machete");
		}
	} else if (StrEqual(weapon, "machete")) {
		if (IsModelPrecached("models/weapons/melee/v_machete.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "golfclub");
		}
	} else if (StrEqual(weapon, "golfclub")) {
		if (IsModelPrecached("models/weapons/melee/v_golfclub.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "tonfa");
		}
	} else if (StrEqual(weapon, "tonfa")) {
		if (IsModelPrecached("models/weapons/melee/v_tonfa.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "riotshield");
		}
	} else if (StrEqual(weapon, "riotshield")) {
		if (IsModelPrecached("models/weapons/melee/v_riotshield.mdl")) {
			return 1;
		} else {
			strcopy(weapon, maxlen, "fireaxe");
		}
	} else {
		// It's not a melee, load it out
		return 1;
	}
	
	// Not a pre-cached melee, check with the new one...
	return 0;
}
