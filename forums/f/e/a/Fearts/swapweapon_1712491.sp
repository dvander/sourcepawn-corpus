#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_NAME "Swap Weapon"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0 (GNU/GPLv3)"
#define PLUGIN_URL ""
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

#define MAX_WEAPONS 5
new const String:g_Weapons[2][MAX_WEAPONS][16] = {
	{
		"sg552",
		"g3sg1",
		"ak47",
		"mac10",
		"elite"
	}, {
		"aug",
		"sg550",
		"m4a1",
		"tmp",
		"fiveseven"
	}
};

new Handle:g_hCvEnabled,
	Handle:g_hCvSwapTime,
	Handle:g_hCvMaxSwaps;

new Float:g_RoundStartTime;
new g_nSwaps[MAXPLAYERS+1];

public OnPluginStart() {
	RegAdminCmd("sm_swap", ConCmd_Swap, 0, "Swaps your weapon with the corresponding one of the opposing team. (Currently held weapon takes precedence.)");

	new const String:cvar_name[] = "sm_swapweapon_version";

	new Handle:cvar = FindConVar(cvar_name),
		flags = FCVAR_NOTIFY | FCVAR_DONTRECORD;

	if (cvar != INVALID_HANDLE) {
		SetConVarString(cvar, PLUGIN_VERSION);
		SetConVarFlags(cvar, flags);
	}
	else {
		cvar = CreateConVar(cvar_name, PLUGIN_VERSION, "Swap Weapon's version string", flags);
	}

	if (cvar != INVALID_HANDLE) {
		CloseHandle(cvar);
	}

	g_hCvEnabled = CreateConVar("sm_swapweapon_enabled", "1", "Whether this plugin should be enabled.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_hCvSwapTime = CreateConVar("sm_swapweapon_swap_time", "15.0", "Time period in seconds after the round's start during which sm_swap can be used. (<0 disables)", FCVAR_DONTRECORD, true, -1.0);
	g_hCvMaxSwaps = CreateConVar("sm_swapweapon_max_swaps", "2", "Maximum number of times sm_swap can be used per round (<0 disables)", FCVAR_DONTRECORD, true, -1.0);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnClientConnected(client) {
	g_nSwaps[client] = 0;
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast) {
	for (new i = 1; i < MaxClients; i++) {
		g_nSwaps[i] = 0;
	}

	g_RoundStartTime = GetGameTime();
}

public Action:ConCmd_Swap(client, argc) {
	if (!GetConVarInt(g_hCvEnabled)) {
		return Plugin_Continue;
	}

	new team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT) {
		PrintToChat(client, "[SM] Please join a team first.");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "[SM] You need to be alive to do that.");
		return Plugin_Handled;
	}

	new Float:time = GetConVarFloat(g_hCvSwapTime);
	if (time >= 0.0 && GetGameTime() > g_RoundStartTime + time) {
		PrintToChat(client, "[SM] %.1f seconds have already passed: you're not allowed to use sm_swap anymore.", time);
		return Plugin_Handled;
	}

	new max_swaps = GetConVarInt(g_hCvMaxSwaps);
	if (max_swaps >= 0 && g_nSwaps[client] > max_swaps) {
		PrintToChat(client, "[SM] You're only allowed to use sm_swap %i times.", max_swaps);
		return Plugin_Handled;
	}

	team -= 2;

	new slot = 1,
		bool:not_valid_weapon = true,
		bool:first_iteration = true;
	for (new i = 0; i < 2; i++) {
		LogMessage("1");
		new weapon = GetPlayerWeaponSlot(client, slot);

		if (weapon == INVALID_ENT_REFERENCE ||
			!IsValidEdict(weapon) ||
			!IsValidEntity(weapon)
		) {
			slot = !slot;
			continue;
		}

		if (i == 0 && first_iteration && GetEntProp(weapon, Prop_Data, "m_iState") != 2) {
			LogMessage("4");
			slot = 0;
			i = -1;
			first_iteration = false;
			continue;
		}

		first_iteration = false;
		not_valid_weapon = false;

		decl String:weapon_name[64],
			String:class[64];
		GetEntityClassname(weapon, class, sizeof(class));

		for (new i = 0; i < MAX_WEAPONS; i++) {
			Format(weapon_name, sizeof(weapon_name), "weapon_%s", g_Weapons[team][i]);
			if (StrEqual(class, weapon_name)) {
				Format(weapon_name, sizeof(weapon_name), "weapon_%s", g_Weapons[!team][i]);
				if (GivePlayerItem(client, weapon_name) != INVALID_ENT_REFERENCE) {
					CS_DropWeapon(client, weapon, false, false);
					AcceptEntityInput(weapon, "kill");

					new Handle:data = CreateDataPack();
					WritePackCell(data, GetClientUserId(client));
					WritePackString(data, weapon_name);
					CreateTimer(0.03, Timer_SwitchToWeapon, data, TIMER_FLAG_NO_MAPCHANGE); // Should approximately take 2 frames.

					PrintToChat(client, "[SM] Swapped weapon.");
				}
				else {
					PrintToChat(client, "[SM] Couldn't create new weapon.");
				}

				g_nSwaps[client]++;
				return Plugin_Handled;
			}
		}

		slot = !slot;
	}

	if (not_valid_weapon) {
		PrintToChat(client, "[SM] You need to have a gun to do that.");
	}
	else {
		PrintToChat(client, "[SM] Your weapons aren't swappable.");
	}

	return Plugin_Handled;
}

public Action:Timer_SwitchToWeapon(Handle:timer, any:data) {
	ResetPack(data);

	new client = GetClientOfUserId(ReadPackCell(data));

	if (!client) {
		return;
	}

	decl String:weapon[64];
	ReadPackString(data, weapon, sizeof(weapon));
	CloseHandle(data);

	FakeClientCommand(client, "use %s", weapon);
}