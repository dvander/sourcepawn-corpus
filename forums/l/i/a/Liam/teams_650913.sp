/**
 * vim: set ts=4 :
 * =============================================================================
 * Get Teams
 * Looks the server tickrate up.
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
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
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
    name = "Get Team Num",
    author = "Liam",
    description = "Looks up the clients team number.",
    version = "1.0",
    url = "http://www.wcugaming.org"
};

public OnPluginStart( )
{
    RegConsoleCmd("sm_getteams", Command_Teams);
}

public Action:Command_Teams(client, args)
{
    new f_Max = GetMaxClients( ), f_Team;
    decl String:f_Name[MAX_NAME_LENGTH];

    for(new i = 1; i < f_Max; i++)
    {
        if(!IsClientConnected(i) || !IsClientInGame(i))
            continue;

        GetClientName(i, f_Name, sizeof(f_Name));
        f_Team = GetClientTeam(i);
        ReplyToCommand(client, "Client %s on Team %d", f_Name, f_Team);
    }
}