/*
 *    Bomb Restart Timer for MvM Missions
 *    Copyright (C) 2013-2015, Yuri Sakhno (George1)
 *    Copyright (C) 2015, avi9526
 *
 *    This plugin is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This plugin is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

#define TF_FLAGEVENT_PICKUP 1
#define TF_FLAGEVENT_CAPTURE 2
#define TF_FLAGEVENT_DEFEND 3
#define TF_FLAGEVENT_DROPPED 4


public Plugin:myinfo =
{
    name = "Bomb Restart Timer",
    author = "George1 of Componentix.com + multi bomb fix by avi9526 <Dromaretsky@gmail.com>",
    description = "Adds restart timer to the bomb when it is dropped by robots",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=207224"
};

new Handle:cvarBombRestartTime;

public OnPluginStart()
{
    CreateConVar("sm_bombrestart_version", PLUGIN_VERSION, "BombRestartTimer version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvarBombRestartTime = CreateConVar("sm_bombrestart_time", "20", "The time before the bomb will be reset to start when dropped, in seconds", FCVAR_PLUGIN|FCVAR_NOTIFY, true, -1.0);
    HookEvent("teamplay_flag_event", Event_TeamplayFlag, EventHookMode_Post);
}

public Action:Event_TeamplayFlag(Handle:event, const String:name[], bool:dontBroadcast)
{
    new eventType = GetEventInt(event, "eventtype");
    
    if (eventType != TF_FLAGEVENT_DROPPED || GetConVarFloat(cvarBombRestartTime) < 0.0)
    {
        return Plugin_Continue;
    }
    
    new bomb = -1;

    while ((bomb = FindEntityByClassname(bomb, "item_teamflag")) != -1)
    {
        if (bomb == INVALID_ENT_REFERENCE)
        {
            LogAction(-1, -1, "[BombRestartTimer] INVALID_ENT_REFERENCE");
            break;
        } else
        {
            SetVariantInt(GetConVarInt(cvarBombRestartTime));
            AcceptEntityInput(bomb, "SetReturnTime");
        }
    }
    
    return Plugin_Continue;
}
