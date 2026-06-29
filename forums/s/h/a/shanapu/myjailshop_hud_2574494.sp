/*
 * MyJailShop - Credits HUD Plugin.
 * by: shanapu
 * https://github.com/shanapu/MyJailShop/
 * 
 * Copyright (C) 2016-2018 Thomas Schmidt (shanapu)
 *
 * This file is part of the MyJailShop SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <autoexecconfig>
#include <mystocks>
#include <myjailshop>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Console Variables
ConVar gc_bPlugin;
ConVar gc_bAlive;
ConVar gc_iRed;
ConVar gc_iBlue;
ConVar gc_iGreen;
ConVar gc_iAlpha;
ConVar gc_fX;
ConVar gc_fY;

// Handle
Handle g_hHUD;

// Info
public Plugin myinfo =
{
	name = "MyJailShop - Credits HUD",
	description = "A player HUD to display credits",
	author = "shanapu",
	version = "1.0",
	url = "https://github.com/shanapu/MyJailShop"
}

// Start
public void OnPluginStart()
{
	// AutoExecConfig
	AutoExecConfig_SetFile("Settings", "MyJailShop");
	AutoExecConfig_SetCreateFile(true);

	gc_bPlugin = AutoExecConfig_CreateConVar("sm_jailshop_hud_enable", "1", "0 - disabled, 1 - enable this MyJailShop Module", _, true, 0.0, true, 1.0);
	gc_bAlive = AutoExecConfig_CreateConVar("sm_jailshop_hud_alive", "1", "0 - show hud only to alive player, 1 - show hud to dead & alive player", _, true, 0.0, true, 1.0);
	gc_fX = AutoExecConfig_CreateConVar("sm_jailshop_hud_x", "0.05", "x coordinate, from 0 to 1. -1.0 is the center", _, true, -1.0, true, 1.0);
	gc_fY = AutoExecConfig_CreateConVar("sm_jailshop_hud_y", "0.65", "y coordinate, from 0 to 1. -1.0 is the center", _, true, -1.0, true, 1.0);
	gc_iRed = AutoExecConfig_CreateConVar("sm_jailshop_hud_red", "200", "Color of sm_hud_type '1' (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iGreen = AutoExecConfig_CreateConVar("sm_jailshop_hud_green", "200", "Color of sm_hud_type '1' (set R, G and B values to 255 to disable) (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iBlue = AutoExecConfig_CreateConVar("sm_jailshop_hud_blue", "0", "Color of sm_hud_type '1' (set R, G and B values to 255 to disable) (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_iAlpha = AutoExecConfig_CreateConVar("sm_jailshop_hud_alpha", "200", "Alpha value of sm_hud_type '1' (set value to 255 to disable for transparency)", _, true, 0.0, true, 255.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	g_hHUD = CreateHudSynchronizer();
}

// Prepare Plugin & modules
public void OnMapStart()
{
	if (gc_bPlugin.BoolValue)
	{
		CreateTimer(1.0, Timer_ShowHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

}

/******************************************************************************
                   TIMER
******************************************************************************/

public Action Timer_ShowHUD(Handle timer, Handle pack)
{
	if (!gc_bPlugin.BoolValue)
		return Plugin_Handled;

	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!IsValidClient(i, false, gc_bAlive.BoolValue))
			continue;

		ClearSyncHud(i, g_hHUD);
		SetHudTextParams(gc_fX.FloatValue, gc_fY.FloatValue, 5.0, gc_iRed.IntValue, gc_iGreen.IntValue, gc_iBlue.IntValue, gc_iAlpha.IntValue, 1, 1.0, 0.0, 0.0);

		ShowSyncHudText(i, g_hHUD, "Credits: %i¢", MyJailShop_GetCredits(i));
	}

	return Plugin_Continue;
}