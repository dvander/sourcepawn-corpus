#if 0
---------------------------------------------------------------------------------------------
-File:

elimination.sp

---------------------------------------------------------------------------------------------
-License:

Elimination Counter Strike: Source (CSS) SourceMod Plugin
Copyright (C) 2011 B.D.A.K. Koch

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 3.0, as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

As a special exception, AlliedModders LLC gives you permission to link the
code of this program (as well as its derivative works) to "Half-Life 2," the
"Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
by the Valve Corporation.  You must obey the GNU General Public License in
all respects for all other code used.  Additionally, AlliedModders LLC grants
this exception to all derivative works.  AlliedModders LLC defines further
exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
or <http://www.sourcemod.net/license.php>.

---------------------------------------------------------------------------------------------
#endif // 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <cstrike>

new String:g_Tag[32] = "\x04[Elimination]\x01";

new g_RespawnTarget[MAXPLAYERS+1],
	g_nRespawnQueue[MAXPLAYERS+1];

new Handle:g_cvarSpawnProtectionTime,
	Handle:g_cvarSuicideRespawn,
	Handle:g_cvarKillCountWarning,
	Handle:g_cvarGunMenu;

new Float:g_CvSpawnProtectionTime = 3.0,
	bool:g_CvSuicideRespawn = false,
	g_CvKillCountWarning = 3,
	bool:g_CvGunMenu = true;

new Handle:g_SpawnProtectionTimer[MAXPLAYERS+1];

new String:g_LastWeapons[MAXPLAYERS+1][2][32],
	bool:g_AutoLastWeapon[MAXPLAYERS+1] = false;

#define PLUGIN_NAME "[CSS] Elimination"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION "Elimination Game Mode"
#define PLUGIN_VERSION "1.0.0 (GNU/GPLv3)"
#define PLUGIN_URL ""
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	new Handle:cvar = CreateConVar("sm_elim_version", PLUGIN_VERSION, "[ND] Elimination - Version Number", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	SetConVarString(cvar, PLUGIN_VERSION);

	RegConsoleCmd("sm_guns", ConCmd_Guns, "Re-enables gun menu");

	AddCommandListener(CmdListener_JoinClass, "joinclass");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	g_CvSpawnProtectionTime = InitCvar(g_cvarSpawnProtectionTime, OnConVarChanged, "sm_elim_spawn_protection", "0", "Enables spawn protection for x seconds.", FCVAR_DONTRECORD, true, 0.0);
	g_CvSuicideRespawn = InitCvar(g_cvarSuicideRespawn, OnConVarChanged, "sm_elim_suicide_respawn", "0", "Automatically respawns when one commits suicide.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_CvKillCountWarning = InitCvar(g_cvarKillCountWarning, OnConVarChanged, "sm_elim_killcount_warning", "3", "Issues a warning at x kills.", FCVAR_DONTRECORD, true, 0.0);
	g_CvGunMenu = InitCvar(g_cvarGunMenu, OnConVarChanged, "sm_elim_gunmenu", "0", "Enables gun menu", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
}

public OnMapEnd() {
	for (new i = 0; i <= MAXPLAYERS; i++) {
		g_SpawnProtectionTimer[i] = INVALID_HANDLE;
	}
}

public OnClientDisconnect(client) {
	OnPlayerDeath(client, -1);
	g_LastWeapons[client][0][0] = '\0';
	g_LastWeapons[client][1][0] = '\0';
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	damage = 0.0;

	return Plugin_Changed;
}

public Action:ConCmd_Guns(client, argc) {
	if (g_CvGunMenu) {
		if (g_AutoLastWeapon[client]) {
			PrintToChat(client, "%s You re-enabled the gun selection menu.", g_Tag);
			g_AutoLastWeapon[client] = false;
		}
		else {
			PrintToChat(client, "%s The gun selection menu is already enabled.", g_Tag);
		}
	}
	return Plugin_Handled;
}

public Action:CmdListener_JoinClass(client, String:command[], argc) {
	new team = GetClientTeam(client);

	if (team < 2 || team > 3) {
		return;
	}

	CreateTimer(0.0, Timer_JoinClass, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_JoinClass(Handle:timer, any:data) {
	new client = GetClientOfUserId(data);

	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) < 2) {
		return;
	}

	if (!IsPlayerAlive(client)) {
		new team = GetClientTeam(client);

		if (team < 2 || team > 3) {
			return;
		}

		new target = GetTopRespawnQueue(team==2?3:2);

		if (target <= 0) {
			return;
		}

		AddPlayerToRespawnQueue(client, target);
		PrintToChat(client, "%s You joined late, you will respawn when \x03%N\x01 dies.", g_Tag, target);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			g_RespawnTarget[i] = 0;
			g_nRespawnQueue[i] = 0;
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			if (g_SpawnProtectionTimer[i] != INVALID_HANDLE) {
				CloseHandle(g_SpawnProtectionTimer[i]);
				g_SpawnProtectionTimer[i] = INVALID_HANDLE;
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	}

	if (g_SpawnProtectionTimer[client] != INVALID_HANDLE) {
		CloseHandle(g_SpawnProtectionTimer[client]);
	}
	if (g_CvSpawnProtectionTime > 0.0) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		g_SpawnProtectionTimer[client] = CreateTimer(g_CvSpawnProtectionTime, Timer_SpawnProtection, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		PrintHintText(client, "%s You're now protected for %.1f seconds.", g_Tag, g_CvSpawnProtectionTime);
	}

	if (g_CvGunMenu) {
		if (g_AutoLastWeapon[client]) {
			for (new i = 0; i < 2; i++) {
				if (g_LastWeapons[client][0][0] != '\0') {
					GivePlayerItem2(client, g_LastWeapons[client][i], i);
				}
			}
		}
		else {
			CreateTimer(0.1, Timer_GunMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_GunMenu(Handle:menu, any:data) {
	new client = GetClientOfUserId(data);

	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	}

	ShowGunMenu(client);
}

public Action:Timer_SpawnProtection(Handle:timer, any:data) {
	new client = GetClientOfUserId(data);

	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) {
		return;
	}

	g_SpawnProtectionTimer[client] = INVALID_HANDLE;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	PrintHintText(client, "%s You're no longer protected.", g_Tag);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid")),
		attacker = GetEventInt(event, "attacker");

	if (victim <= 0) {
		return;
	}

	if (attacker && !(attacker = GetClientOfUserId(attacker))) {
		attacker = -1;
	}

	OnPlayerDeath(victim, attacker);
}

OnPlayerDeath(victim, attacker) {
	if (g_SpawnProtectionTimer[victim] != INVALID_HANDLE) {
		SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
		CloseHandle(g_SpawnProtectionTimer[victim]);
		g_SpawnProtectionTimer[victim] = INVALID_HANDLE;
	}

	RespawnPlayersInQueue(victim);

	if (attacker < 0) {
		return;
	}

	if (!attacker || victim == attacker) {
		if (g_CvSuicideRespawn) {
			DelayedRespawn(victim);
		}
		else {
			attacker = GetTopRespawnQueue(GetClientTeam(victim)==2?3:2)
			if (attacker <= 0) {
				DelayedRespawn(victim);
			}
			else {
				PrintToChat(victim, "%s You killed yourself, you will respawn when \x03%N\x01 dies.", g_Tag, attacker);
				AddPlayerToRespawnQueue(victim, attacker);
			}
		}
	}
	else {
		PrintToChat(victim, "%s You will respawn when \x03%N\x01 dies.", g_Tag, attacker);
		AddPlayerToRespawnQueue(victim, attacker);

		if (g_nRespawnQueue[attacker] == g_CvKillCountWarning) {
			new team = GetClientTeam(attacker) == 2 ? 3 : 2;
			for (new i = 1; i <= MaxClients; i++) {
				if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team) {
					PrintHintText(i, "%s \x03%N\x01 has scored %i kills.", g_Tag, attacker, g_CvKillCountWarning);
				}
			}
		}
	}
}

ShowGunMenu(client) {
	static Handle:menu = INVALID_HANDLE;

	if (menu == INVALID_HANDLE) {
		menu = CreateMenu(GunMenuHandler);
		SetMenuTitle(menu, "Choose Weapons:");
		AddMenuItem(menu, "0", "Pistols");
		AddMenuItem(menu, "1", "Rifles");
		AddMenuItem(menu, "2", "Sniper Rifles");
		AddMenuItem(menu, "3", "Machine Guns");
		AddMenuItem(menu, "4", "Shotguns");
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
		AddMenuItem(menu, "alwaysprev", "Always Previous Weapons");
		// AddMenuItem(menu, "random", "Random Weapons");
		AddMenuItem(menu, "prev", "Previous Weapons");
		SetMenuExitButton(menu, true);
	}

	if (menu == INVALID_HANDLE) {
		return false;
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return true;
}

public GunMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		if (param1 > 0 && param1 <= MaxClients && IsClientConnected(param1) && IsClientInGame(param1)) {
			decl String:item[32];
			GetMenuItem(menu, param2, item, sizeof(item));

			g_AutoLastWeapon[param1] = false;
			
			if (StrEqual(item, "prev")) {
				for (new i = 0; i < 2; i++) {
					if (g_LastWeapons[param1][0][0] != '\0') {
						GivePlayerItem2(param1, g_LastWeapons[param1][i], i);
					}
				}
			}
			else if (StrEqual(item, "alwaysprev")) {
				for (new i = 0; i < 2; i++) {
					if (g_LastWeapons[param1][0][0] != '\0') {
						GivePlayerItem2(param1, g_LastWeapons[param1][i], i);
					}
				}

				g_AutoLastWeapon[param1] = true;
			}
			// else if (StrEqual(item, "random")) {
			// }
			else {
				ShowGunSubmenu(param1, StringToInt(item));
			}
		}
	}
	// else if (action == MenuAction_End) {
	// 	CloseHandle(menu);
	// }
}

ShowGunSubmenu(client, index) {
	static Handle:menu[5];

	if (menu[index] == INVALID_HANDLE) {
		menu[index] = CreateMenu(GunSubmenuHandler);
		switch (index) {
			case 0:
			{
				SetMenuTitle(menu[index], "Pistols:");
				AddMenuItem(menu[index], "weapon_deagle", "IMI Desert Eagle");
				AddMenuItem(menu[index], "weapon_glock", "Glock");
				AddMenuItem(menu[index], "weapon_usp", "USP");
				AddMenuItem(menu[index], "weapon_p228", "P-228");
				AddMenuItem(menu[index], "weapon_elite", "Dual Elites");
				AddMenuItem(menu[index], "weapon_fiveseven", "Five-Seven");
			}
			case 1:
			{
				SetMenuTitle(menu[index], "Rifles:");
				AddMenuItem(menu[index], "weapon_ak47", "AK-47");
				AddMenuItem(menu[index], "weapon_m4a1", "M4A1");
				AddMenuItem(menu[index], "weapon_galil", "Galil");
				AddMenuItem(menu[index], "weapon_famas", "Famas");
				AddMenuItem(menu[index], "weapon_aug", "AUG");
				AddMenuItem(menu[index], "weapon_sg552", "SG552");
				AddMenuItem(menu[index], "weapon_m249", "Para");
			}
			case 2:
			{
				SetMenuTitle(menu[index], "Sniper Rifles:");
				AddMenuItem(menu[index], "weapon_awp", "AWP");
				AddMenuItem(menu[index], "weapon_scout", "Scout");
				AddMenuItem(menu[index], "weapon_g3sg1", "G3SG1");
				AddMenuItem(menu[index], "weapon_sg550", "SG550");
			}
			case 3:
			{
				SetMenuTitle(menu[index], "Machine Guns:");
				AddMenuItem(menu[index], "weapon_mac10", "MAC-10");
				AddMenuItem(menu[index], "weapon_tmp", "TMP");
				AddMenuItem(menu[index], "weapon_mp5navy", "MP5");
				AddMenuItem(menu[index], "weapon_ump45", "UMP-45");
				AddMenuItem(menu[index], "weapon_p90", "P-90");
			}
			case 4:
			{
				SetMenuTitle(menu[index], "Shotguns:");
				AddMenuItem(menu[index], "weapon_m3", "M3");
				AddMenuItem(menu[index], "weapon_xm1014", "XM1014");
			}
		}
		SetMenuExitButton(menu[index], true);
	}

	if (menu[index] == INVALID_HANDLE) {
		return false;
	}

	DisplayMenu(menu[index], client, MENU_TIME_FOREVER);

	return true;
}

public GunSubmenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		if (param1 > 0 && param1 <= MaxClients && IsClientConnected(param1) && IsClientInGame(param1)) {
			decl String:item[32];
			GetMenuTitle(menu, item, sizeof(item));

			new slot = !!StrEqual(item, "Pistols:");

			GetMenuItem(menu, param2, item, sizeof(item));
			strcopy(g_LastWeapons[param1][slot], sizeof(g_LastWeapons[][]), item);

			if (IsPlayerAlive(param1)) {
				GivePlayerItem2(param1, item, slot);
			}

			ShowGunMenu(param1);
		}
	}
	// else if (action == MenuAction_End) {
	// 	CloseHandle(menu);
	// }
}

GivePlayerItem2(client, const String:item[], slot) {
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (weapon != INVALID_ENT_REFERENCE && RemovePlayerItem(client, weapon)) {
		AcceptEntityInput(weapon, "kill");
	}

	GivePlayerItem(client, item);
}

GetTopRespawnQueue(team = -1) {
	new top = -1,
		offset = GetRandomInt(0, MaxClients-1);
	for (new i = 1; i <= MaxClients; i++) {
		new client = (i + offset) % MaxClients + 1;
		if (
			(team == -1 || (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == team && IsPlayerAlive(client))) &&
			(g_nRespawnQueue[client] > top || g_nRespawnQueue[client] == top)
		) {
			top = client;
		}
	}

	return top;
}

RespawnPlayersInQueue(queue) {
	new team = -1;
	if (IsClientConnected(queue) && IsClientInGame(queue)) {
		team = 5 - GetClientTeam(queue);
		if (team != 2 && team != 3) {
			team = -1;
		}
	}

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			if (g_RespawnTarget[i] == queue) {
				DelayedRespawn(i);
				g_RespawnTarget[i] = -1;
			}
			else if (g_nRespawnQueue[queue] && team != -1 && GetClientTeam(i) == team) {
				PrintToChat(i, "%s \x04%i\x01 enemies have respawned.", g_Tag, g_nRespawnQueue[queue]);
			}
		}
	}

	g_nRespawnQueue[queue] = 0;
}

AddPlayerToRespawnQueue(client, queue) {
	g_RespawnTarget[client] = queue;
	g_nRespawnQueue[queue]++;
}

DelayedRespawn(client, Float:delay = 0.0) {
	CreateTimer(delay, Timer_Respawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (cvar == g_cvarSpawnProtectionTime) {
		g_CvSpawnProtectionTime = StringToFloat(newVal);
	}
	else if (cvar == g_cvarSuicideRespawn) {
		g_CvSuicideRespawn = bool:StringToInt(newVal);
	}
	else if (cvar == g_cvarKillCountWarning) {
		g_CvKillCountWarning = StringToInt(newVal);
	}
	else if (cvar == g_cvarGunMenu) {
		g_CvGunMenu = bool:StringToInt(newVal);
	}
}

public Action:Timer_Respawn(Handle:timer, any:data) {
	new client = GetClientOfUserId(data);

	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) {
		return;
	}

	RespawnPlayer(client);
}

stock RespawnPlayer(client) {
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client)) {
		CS_RespawnPlayer(client);
	}
}

stock any:InitCvar(&Handle:cvar, ConVarChanged:callback, const String:name[], const String:defaultValue[], const String:description[] = "", flags = 0, bool:hasMin = false, Float:min = 0.0, bool:hasMax = false, Float:max = 0.0) {
	cvar = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	if (cvar != INVALID_HANDLE) {
		HookConVarChange(cvar, callback);
	}
	else {
		LogMessage("Couldn't create console variable \"%s\", using default value \"%s\"", name, defaultValue);
	}

	new type = 1;
	new len = strlen(defaultValue);
	for (new i = 0; i < len; i++) {
		if (defaultValue[i] == '.') {
			type = 2;
		}
		else if (IsCharNumeric(defaultValue[i])) {
			continue
		}
		else {
			type = 0;
			break;
		}
	}

	if (type == 1) {
		return cvar != INVALID_HANDLE ? GetConVarInt(cvar) : StringToInt(defaultValue);
	}
	else if (type == 2) {
		return cvar != INVALID_HANDLE ? GetConVarFloat(cvar) : StringToFloat(defaultValue);
	}

	return 0;
}
