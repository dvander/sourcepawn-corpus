/*
 * finalefix.sp
 * Copyright (c) 2021 Ed <ed@groovyexpress.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sourcemod>

bool ffTriggered = false;
bool ffTheSacrifice = false;

// 
// Toggle instant death for The Sacrifice finale once the player sacrifices himself.
// Be aware that the reset value is set to the default (2) and is static (unchangeable at runtime).
// 
#define ED_SACRIFICE_DEATH 0

public Plugin:myinfo =
{
	name = "Escape Vehicle Finale Fix (For 4+ Players)",
	author = "EDSHOT",
	description = "Only four survivors will be teleported once the escape vehicle is used, the rest usually fall down and die.",
	version = "0.1-rev1"
};

public void OnPluginStart()
{
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving, EventHookMode_Pre);
	HookEvent("mission_lost", Event_MissionLost, EventHookMode_Pre);
}

public void OnPluginEnd()
{
	UnhookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving, EventHookMode_Pre);
	UnhookEvent("mission_lost", Event_MissionLost, EventHookMode_Pre);
}

public void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	char mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));

	if (StrEqual(mapname, "l4d_river03_port", false) || StrEqual(mapname, "c7m3_port", false))
	{
		// 
		// Has a problem where the convar isn't stripped and still prints it out anyways.
		// 
		#if ED_SACRIFICE_DEATH
			Handle hcvIncapCount = FindConVar("survivor_max_incapacitated_count");
			SetConVarFlags(hcvIncapCount, (GetConVarFlags(hcvIncapCount) ^ FCVAR_NOTIFY));
			SetConVarInt(hcvIncapCount, 0);
		#endif
		ffTheSacrifice = true;
	}
	else
	{
		Handle hcvGodMode = FindConVar("god");
		SetConVarFlags(hcvGodMode, (GetConVarFlags(hcvGodMode) ^ FCVAR_NOTIFY));
		SetConVarInt(hcvGodMode, 1);
		ffTriggered = true;
	}
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	// 
	// Prevent a bug where a person kills themselves at the last minute so the level restarts again, except
	// people now have god mode.
	// 
	if (ffTriggered)
	{
		Handle hcvGodMode = FindConVar("god");
		SetConVarInt(hcvGodMode, 0);
		SetConVarFlags(hcvGodMode, (GetConVarFlags(hcvGodMode) | FCVAR_NOTIFY));
		ffTriggered = false;
	}
}

public void OnMapStart()
{
	if (ffTheSacrifice)
	{
		#if ED_SACRIFICE_DEATH
			Handle hcvIncapCount = FindConVar("survivor_max_incapacitated_count");
			SetConVarInt(hcvIncapCount, 2);
			SetConVarFlags(hcvIncapCount, (GetConVarFlags(hcvIncapCount) | FCVAR_NOTIFY));
		#endif
		ffTheSacrifice = false;
	}
	if (ffTriggered)
	{
		Handle hcvGodMode = FindConVar("god");
		SetConVarInt(hcvGodMode, 0);
		SetConVarFlags(hcvGodMode, (GetConVarFlags(hcvGodMode) | FCVAR_NOTIFY));
		ffTriggered = false;
	}
}
