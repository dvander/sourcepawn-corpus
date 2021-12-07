/**
 * WillItCraft by Moiph
 * Very simple plugin to allow use of "willitcraft" as a command
 * to display a user's TF2 crafting possibilities from willitcraft.com.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ---------
 * Changelog
 * ---------
 *
 * 8/21/2011 - v1.1
 * - Added version cvar
 * - Added client check
 *
 * 8/20/2011 - v1.0
 * - Initial checkin
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Constants
#define PLUGIN_VERSION "1.1"

// Plugin info
public Plugin:myinfo =
{
    name = "WillItCraft",
    author = "Moiph",
    description = "Shows WillItCraft results for a player.",
    version = PLUGIN_VERSION,
    url = "willitcraft.com"
}

/**
 * Register willitcraft command.
 */
public OnPluginStart()
{
    CreateConVar("sm_willitcraft_version", PLUGIN_VERSION, "WillItCraft version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    RegConsoleCmd("sm_willitcraft", Command_WillItCraft);
}

/**
 * Launch the willitcraft results in the MOTD panel for the requesting user.
 */
public Action:Command_WillItCraft(client, args)
{
    new String:steamId[255];
    new String:craftUrl[255];
    
    if (IsValidClient(client) && GetClientAuthString(client, steamId, sizeof(steamId)))
    {
        Format(craftUrl, sizeof(craftUrl), "http://willitcraft.com/profiles/%s", steamId);

        ShowMOTDPanel(client, "Your craft results:", craftUrl, 2);
    }

    return Plugin_Handled;
}

/**
 * Validates we have a valid client.
 */
public bool:IsValidClient(client)
{
    if (client <= 0 || client > MaxClients)
    {
        return false;
    }
    
    return IsClientInGame(client);
}