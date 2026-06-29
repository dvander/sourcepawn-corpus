/*
 * Respawn All
 * by: shanapu
 * https://github.com/shanapu/
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
#include <cstrike>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Console Variables
ConVar gc_iPlugin;

// Info
public Plugin myinfo = {
	name = "Respawn all",
	author = "shanapu",
	description = "A single admin commadnt o respawn all player",
	version = "1.0",
	url = "https://github.com/shanapu/"
};

// Start
public void OnPluginStart()
{
	gc_iPlugin = CreateConVar("sm_respawnall_enable", "1", "1 on / 0 off", _, true, 0.0, true, 1.0);

	RegAdminCmd("sm_ok", Command_Respawn, ADMFLAG_BAN, "Respawn all player");
	RegAdminCmd("sm_respawnall", Command_Respawn, ADMFLAG_BAN, "Respawn all player");
}

public Action Command_Respawn(int client, int args)
{
	if (!gc_iPlugin.BoolValue)
		return Plugin_Handled;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			CS_RespawnPlayer(i);
		}
	}

	return Plugin_Handled;
}