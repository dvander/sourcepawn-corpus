/*
 * forceset.sp
 * Copyright (c) 2022 Ed <ed@groovyexpress.com>
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
#include <left4dhooks>

public Plugin:myinfo =
{
	name = "Survivor Set Enforcer Extended",
	author = "EDSHOT",
	description = "Choose survivor sets dynamically. Thanks to DeathChaos25 for the original idea (and plugin that now needs to be extended).",
	version = "0.1"
};

public int GetSurvivorSet()
{
	char mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));

	// 
	// 0: L4D1 and L4D2
	// 1: L4D1 Only
	// 2: L4D2 Only
	// 

	// 
	// This section should be a configuration, but I am still doing it this way anyways.
	// 

	// The Passing
	if (StrEqual(mapname, "c6m1_riverbank", false) || StrEqual(mapname, "c6m3_port", false)) return 2;

	// L4D1 Campaigns (First Levels Only For Cutscenes)
	else if (StrEqual(mapname, "c7m1_docks", false) || StrEqual(mapname, "c8m1_apartment", false) ||
		 StrEqual(mapname, "c9m1_alleys", false) || StrEqual(mapname, "c10m1_caves", false) ||
		 StrEqual(mapname, "c11m1_greenhouse", false) || StrEqual(mapname, "c12m1_hilltop", false)) return 1;

	// Glubtastic 2
	else if (StrEqual(mapname, "glubtastic2_6", false)) return 2;

	// Resident Evil 2 - Side A
	else if (StrEqual(mapname, "re2a1", false) || StrEqual(mapname, "re2a2", false) ||
		 StrEqual(mapname, "re2a3", false) || StrEqual(mapname, "re2a4", false)) return 2;

	// Resident Evil 2 - Side B
	else if (StrEqual(mapname, "re2b1", false) || StrEqual(mapname, "re2b2", false) ||
		 StrEqual(mapname, "re2b3", false) || StrEqual(mapname, "re2b4", false)) return 2;

	// Resident Evil 3
	else if (StrEqual(mapname, "re3m5", false)) return 2;

	// Everything Else
	else return 0;
}

public Action L4D_OnGetSurvivorSet(&retVal)
{
	int set = GetSurvivorSet();

	if (set == 0 || set == 1 || set == 2)
	{
		retVal = set;
		SetConVarInt(FindConVar("l4d_csm_forceset"), set);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_OnFastGetSurvivorSet(&retVal)
{
	int set = GetSurvivorSet();

	if (set == 0 || set == 1 || set == 2)
	{
		retVal = set;
		SetConVarInt(FindConVar("l4d_csm_forceset"), set);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
