/*
	file smac_ban_on_spinhack.sp

	Copyright (c) 2014  El Diablo <diablo@war3evo.info>

	Antihack is free software: you may copy, redistribute
	and/or modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This file is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	This file incorporates work covered by the following copyright and
	permission notice:

	SourceMod Anti-Cheat
	Copyright (C) 2011-2013 SMAC Development Team

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	This file incorporates work covered by the following copyright and
	permission notice:

	Kigen's Anti-Cheat Module
	Copyright (C) 2007-2011 CodingDirect LLC

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

/* SM Includes */
#include <sourcemod>
#include <smac>

/* Plugin Info */
public Plugin:myinfo =
{
	name = "Ban on SpinHack",
	author = SMAC_AUTHOR,
	description = "Bans players after X number of spinhacks",
	version = SMAC_VERSION,
	url = SMAC_URL
};

new Handle:g_hAutoBanSpinHack;
new AutoBanSpinHackAmount=6;
new SpinHackCount[MAXPLAYERS + 1];

public OnPluginStart()
{
	g_hAutoBanSpinHack = CreateConVar("smac_spinhack_ban", "6", "0 - Disabled.\nBans a player if detects spinhack this number of times.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hAutoBanSpinHack, OnConvarChanged);
}

public OnConvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar==g_hAutoBanSpinHack)
		AutoBanSpinHackAmount = StringToInt(newValue);
}

public OnClientDisconnect(client)
{
	SpinHackCount[client] = 0;
}

public Action:SMAC_OnCheatDetected(client, const String:module[], DetectionType:type, Handle:info)
{
	if(AutoBanSpinHackAmount<=0) return Plugin_Continue;

	if(type==Detection_Spinhack && ++SpinHackCount[client]>=AutoBanSpinHackAmount)
	{
		SMAC_LogAction(client, "is banned for using spinhack.");
		SMAC_Ban(client,"Spinhack Detected");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
