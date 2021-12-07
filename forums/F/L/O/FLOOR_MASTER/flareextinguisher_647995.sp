/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Flare Extinguisher
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CVAR_VERSION	    0
#define CVAR_RATE	    1
#define CVAR_NUM_CVARS	    2

#define VERSION		    "1.2"

new Handle:g_cvars[CVAR_NUM_CVARS];
new Handle:g_timer = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Flare Extinguisher",
    author = "Ryan \"FLOOR_MASTER\" Mannion",
    description = "Periodically remove flares from the game",
    version = VERSION,
    url = "http://www.2fort2furious.com"
};

public OnPluginStart() {
    g_cvars[CVAR_VERSION] = CreateConVar(
	"sm_fe_version",
	VERSION,
	"Flare Extinguisher Version",
	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[CVAR_RATE] = CreateConVar(
	"sm_fe_rate",
	"180",
	"Interval, in seconds, to wait between extinguishing flares",
	FCVAR_PLUGIN,
	true, 0.0);

    RegAdminCmd("sm_fe", Command_ExtinguishFlares, ADMFLAG_ROOT);
    HookConVarChange(g_cvars[CVAR_RATE], OnRateChange);
}

public OnConfigsExecuted() {
    new Float:time = GetConVarFloat(g_cvars[CVAR_RATE]);
    if (g_timer == INVALID_HANDLE && time > 0.0) {
	g_timer = CreateTimer(time, Timer_ExtinguishFlares, _, TIMER_REPEAT);
    }
}

public OnPluginEnd() {
    if (g_timer != INVALID_HANDLE) {
	CloseHandle(g_timer);
	g_timer = INVALID_HANDLE;
    }
}

public OnRateChange(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    new Float:time = StringToFloat(newVal);

    if (g_timer != INVALID_HANDLE) {
	CloseHandle(g_timer);
	g_timer = INVALID_HANDLE;
    }

    if (time > 0.0) {
	ExtinguishFlares();
	g_timer = CreateTimer(time, Timer_ExtinguishFlares, _, TIMER_REPEAT);
    }
}

public Action:Command_ExtinguishFlares(client, args) {
    ExtinguishFlares();
    ReplyToCommand(client, "[FE] Extinguishing flares");
}

public Action:Timer_ExtinguishFlares(Handle:timer) {
    ExtinguishFlares();
}

stock ExtinguishFlares() {
    new ent = -1;

    new Handle:flares = CreateArray();
    while ((ent = FindEntityByClassname(ent, "tf_projectile_flare")) >= 0) {
	PushArrayCell(flares, ent);
    }
    CreateTimer(2.0, Timer_ExtinguishFlares2, flares);
}

public Action:Timer_ExtinguishFlares2(Handle:timer, Handle:flares) {
    new size = GetArraySize(flares);
    decl String:class[32];
    new edict = 0;
    new count = 0;

    for (new i = 0; i < size; i++) {
	edict = GetArrayCell(flares, i);

	if (IsValidEdict(edict)) {
	    GetEdictClassname(edict, class, sizeof(class));
	    if (StrEqual(class, "tf_projectile_flare")) {
		RemoveEdict(edict);
		count++;
	    }
	}
    }
    CloseHandle(flares);

    PrintToServer("[FE] Extinguished %d flare(s)", count);
}

