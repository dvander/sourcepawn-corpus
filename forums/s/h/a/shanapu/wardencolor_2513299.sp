/*
 * MyJailbreak - Warden - Colorize Warden Module.
 * by: shanapu
 * https://github.com/shanapu/MyJailbreak/
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
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
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <warden>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Console Variables
ConVar gc_bColor;
ConVar gc_iWardenColorRed;
ConVar gc_iWardenColorGreen;
ConVar gc_iWardenColorBlue;
ConVar gc_bWardenColorRandom;

// Integers
int g_iColors[8][4] = 
{
	{255, 255, 255, 255}, // white
	{255, 0, 0, 255}, // red
	{20, 255, 20, 255}, // green
	{0, 65, 255, 255}, // blue
	{255, 255, 0, 255}, // yellow
	{0, 255, 255, 255}, // cyan
	{255, 0, 255, 255}, // magenta
	{255, 80, 0, 255}  // orange
};


public Plugin myinfo =  {
	name = "Warden color", 
	author = "shanapu", 
	description = "Change the color of the warden", 
	version = "1.0", 
	url = "https://github.com/shanapu/"
};

// Info
public void Color_OnPluginStart()
{
	// AutoExecConfig
	gc_bColor = CreateConVar("sm_warden_color_enable", "1", "0 - disabled, 1 - enable warden colored", _, true, 0.0, true, 1.0);
	gc_bWardenColorRandom = CreateConVar("sm_warden_color_random", "1", "0 - disabled, 1 - enable warden rainbow colored", _, true, 0.0, true, 1.0);
	gc_iWardenColorRed = CreateConVar("sm_warden_color_red", "0", "What color to turn the warden into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iWardenColorGreen = CreateConVar("sm_warden_color_green", "0", "What color to turn the warden into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iWardenColorBlue = CreateConVar("sm_warden_color_blue", "255", "What color to turn the warden into (rgB): x - blue value", _, true, 0.0, true, 255.0);
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

public void warden_OnWardenCreated(int client)
{
	CreateTimer(1.0, Timer_WardenFixColor, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void warden_OnWardenRemoved(int client)
{
	CreateTimer(0.1, Timer_RemoveColor, client);
}


/******************************************************************************
                   TIMER
******************************************************************************/

public Action Timer_WardenFixColor(Handle timer, any client)
{
	if (IsValidClient(client, false, false))
	{
		if (warden_iswarden(client))
		{
			if (gc_bColor.BoolValue)
			{
				if (gc_bWardenColorRandom.BoolValue)
				{
					int i = GetRandomInt(1, 7);
					SetEntityRenderColor(client, g_iColors[i][0], g_iColors[i][1], g_iColors[i][2], g_iColors[i][3]);
				}
				else SetEntityRenderColor(client, gc_iWardenColorRed.IntValue, gc_iWardenColorGreen.IntValue, gc_iWardenColorBlue.IntValue, 255);
			}
		}
		else
		{
			SetEntityRenderColor(client);

			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

public Action Timer_RemoveColor(Handle timer, any client) 
{
	if (IsValidClient(client, true, true))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}