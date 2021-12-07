///////////////////////////////////////////////////////////////////////////////////////
//
//  File:   FireLoopFix.sp
//  Author: Daedilus
//  Date:   2009-10-18
//
//  License:
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
///////////////////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

// Include SourceMod

#include <sourcemod.inc>
#include <sdktools_sound.inc>

// Include Psionics

#define FIRE_SMALL_LOOP2  "ambient/fire/fire_small_loop2.wav"

///////////////////////////////////////////////////////////////////////////////////////
// Plugin Info

public Plugin:myinfo =
{
  name = "FireLoopFix",
  author = "Daedilus",
  description = "Fixes the fire sound that loops for IgniteEntity by turning it off",
  version = "1.0.0",
  url = "http://www.budznetwork.com"
};


///////////////////////////////////////////////////////////////////////////////////////
// OnPluginStart

public OnPluginStart()
{
  // Hook the sounds being emitted to the client

  AddNormalSoundHook(NormalSoundHook);
}


///////////////////////////////////////////////////////////////////////////////////////
// OnPluginEnd

public OnPluginEnd()
{
  //RemoveNormalSoundHook(NormalSoundHook);
}


///////////////////////////////////////////////////////////////////////////////////////
// NormalSoundHook

public Action:NormalSoundHook(clients[64], &client_count, String:sample[PLATFORM_MAX_PATH],
                              &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
  if(strcmp(FIRE_SMALL_LOOP2, sample, false) == 0)
  {
    return Plugin_Stop;
  }

  return Plugin_Continue;
}
