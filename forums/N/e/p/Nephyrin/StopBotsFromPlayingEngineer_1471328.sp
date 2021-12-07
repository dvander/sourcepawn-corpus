/* 
 * StopBotsFromPlayingEngineer.sp
 * 
 * Copyright 2011 Nephyrin@DoubleZen.net
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define TEAM_RED 2
#define TEAM_BLUE 3
#define TEAM_SPEC 1

new Handle:sm_sbfpe_class;

public Plugin:myinfo = 
{
	name = "StopBotsFromPlayingEngineer",
	author = "Nephyrin",
	description = "Stops bots from being able to play as an engineer.",
	version = "1.0",
	url = "http://www.doublezen.net/"
};

public OnPluginStart()
{
    sm_sbfpe_class = CreateConVar("sm_sbfpe_class", "medic", "Class bots who try to switch to engineer should wind up as");
    CreateConVar("sm_sbfpe_version", "1.0", "StopBotsFromPlayingEngineer version", FCVAR_NOTIFY);
    HookEvent("player_changeclass", OnPlayerChangeClass);
}

public Action:OnPlayerChangeClass(Handle:event, const String:ename[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsFakeClient(client))
    {
        new TFClassType:class = GetEventInt(event, "class");
        decl String:name[64];
        GetClientName(client, name, sizeof(name));
        if (class == TFClass_Engineer)
        {
            decl String:alternateclass[64];
            GetConVarString(sm_sbfpe_class, alternateclass, sizeof(alternateclass));
            FakeClientCommandEx(client, "joinclass %s", alternateclass);
            PrintToServer("[StopBotsFromPlayingEngineer] %s tried to go engineer, forcing %s instead", name, alternateclass);
        }
    }
    return Plugin_Continue;
}

