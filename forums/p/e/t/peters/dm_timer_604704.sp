/*
 * =============================================================================
 * DM Timer
 * forces maps to end their Round, even when they do not normally listen
 * to RoundEnd, as for example dm_store and dm_duel_v2.
 * DM Timer will search for the next map in the mapcycle file and in
 * cvar sm_nextmap (votes) and start it as soon as the round ends.
 *
 * DM Timer is started with 'dmt_start', best to include this command in the
 * map config:  <tf>/cfg/dm_duel_v2.cfg
 * 
 * (c)2008 Peter Slootweg  All rights reserved.
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
 * $Id$
 *
 * Remarks:
 * - Copied FindAndSetNextMap from sourcemod's nextmap.sp
 *
 * v0.1 - first hacked together script. It worked, but not suitable for release
 * v0.2 - first public release. Has some things that need fixing
 * v0.3 - fixed the command replies and logging
 *
 * TODO:
 *  - don't start when noone is playing
 *
 */

#pragma semicolon 1

#include <sourcemod>

new Handle:dmt_CVar_Interval = INVALID_HANDLE;

new Handle:dmt_CVar_Nextmap;
new Handle:dmt_MapList = INVALID_HANDLE;
new dmt_MapListSerial = -1;
new dmt_MapPos = -1;

new String:dmt_nextmap[32];

new Handle:dmt_MapTimer = INVALID_HANDLE;
new Float:dmt_Interval = 2.0;

public Plugin:myinfo = 
  {
    name = "DeathMatch Map timer",
    author = "PeterS",
    description = "Timer for maps that don't listen to round_end",
    version = "0.3",
    url = ""
  };
   
public OnPluginStart()
{
  RegAdminCmd("dmt_start", Command_DtStart, ADMFLAG_CHANGEMAP);
  RegAdminCmd("dmt_stop",  Command_DtStop,  ADMFLAG_CHANGEMAP);
  RegAdminCmd("dmt_status",  Command_DtStatus,  ADMFLAG_CHANGEMAP);
  RegAdminCmd("dmt_timeleft",  Command_DtTimeLeft,  ADMFLAG_CHANGEMAP);
  
  dmt_CVar_Interval = CreateConVar("dmtimer_interval", "2", "DM Timer check interval (sec)", FCVAR_NOTIFY);
  dmt_MapList = CreateArray(32);

  AutoExecConfig(true, "plugin_dueltimer");
  
  HookConVarChange(dmt_CVar_Interval, CVar_Change_Interval);
}

public OnConfigsExecuted()
{
  dmt_Interval = GetConVarFloat(dmt_CVar_Interval);
  dmt_CVar_Nextmap = FindConVar("sm_nextmap");

}

public CVar_Change_Interval(Handle:convar, const String:oldValue[], const String:newValue[])
{
  dmt_Interval = GetConVarFloat(dmt_CVar_Interval);
  LogMessage("interval is now %01.0f", dmt_Interval);
}

public Action:Command_DtStart(client, args)
{
  if (dmt_MapTimer != INVALID_HANDLE)
    KillTimer(dmt_MapTimer);

  dmt_MapTimer = INVALID_HANDLE;
  dmt_MapTimer = CreateTimer(dmt_Interval, TimerEnd);
  ReplyToCommand(client, "[DM Timer] timer started (check interval %01.0f seconds)", dmt_Interval);

  return Plugin_Handled;
}

public Action:Command_DtStop(client, args)
{
  if (dmt_MapTimer == INVALID_HANDLE)
    {
      ReplyToCommand(client, "[DM Timer] No running DM Timer found");
      return Plugin_Handled;
    }
  
  dmt_MapTimer = INVALID_HANDLE;
  ReplyToCommand(client, "[DM Timer] timer stopped");

  return Plugin_Handled;
}

public Action:Command_DtStatus(client, args)
{
  if ( dmt_MapTimer == INVALID_HANDLE )
    ReplyToCommand(client, "[DM Timer] No running DM Timer found");
  else
    ReplyToCommand(client, "[DM Timer] DM Timer is running");
}

public Action:Command_DtTimeLeft(client, args)
{
  new timeleft;
  if (GetMapTimeLeft(timeleft))
    {
      if ( timeleft == -1 )
	{
	  ReplyToCommand(client, "[DM Timer] Map hasn't started yet");
	}
      else
	{
	  new mins, secs;
	  if (timeleft + 15 > 0)
	    {
	      mins = timeleft / 60;
	      secs = timeleft % 60;
	    }
	  
	  ReplyToCommand(client, "[DM Timer] Time left: %d:%02d", mins, secs);
	}
    }
  return Plugin_Handled;
}

public Action:TimerEnd(Handle:timer)
{
  /* Timer is done */
  if (dmt_MapTimer != INVALID_HANDLE)
    KillTimer(dmt_MapTimer);

  dmt_MapTimer = INVALID_HANDLE;

  new timeleft;
  if (GetMapTimeLeft(timeleft))
    {
      if (timeleft + 15 <= 0)
	{
	  FindAndSetNextMap();
	  LogMessage("Time is up, starting %s", dmt_nextmap);
	  ServerCommand("changelevel \"%s\"", dmt_nextmap);

	  return Plugin_Stop;
	}
    }

  dmt_MapTimer = CreateTimer(dmt_Interval, TimerEnd);
  return Plugin_Handled;
}

/*
   Copied from sourcemod's nextmap.sp,
   but renamed the variables to match the rest. And changed some
   other bits to make it fit better
*/

FindAndSetNextMap()
{

  decl String:currentMap[64];
  GetConVarString(dmt_CVar_Nextmap, dmt_nextmap, 64);
  GetCurrentMap(currentMap, 64);
  
  if (strcmp(dmt_nextmap, currentMap) == 0)
    {
      if (ReadMapList(dmt_MapList,
		      dmt_MapListSerial,
		      "mapcyclefile")
		  
	  == INVALID_HANDLE)
	{
	  if (dmt_MapListSerial == -1)
	    {
	      LogError("FATAL: Cannot load map cycle. Nextmap not loaded.");
	      SetFailState("Mapcycle Not Found");
	    }
	}
  
      new mapCount = GetArraySize(dmt_MapList);

      if (dmt_MapPos == -1)
	{
	  decl String:current[64];
	  GetCurrentMap(current, 64);

	  for (new i = 0; i < mapCount; i++)
	    {
	      GetArrayString(dmt_MapList, i, dmt_nextmap, sizeof(dmt_nextmap));
	      if (strcmp(current, dmt_nextmap, false) == 0)
		{
		  dmt_MapPos = i;
		  break;
		}
	    }

	  if (dmt_MapPos == -1)
	    dmt_MapPos = 0;
	}

      dmt_MapPos++;
      if (dmt_MapPos >= mapCount)
	dmt_MapPos = 0;

      GetArrayString(dmt_MapList, dmt_MapPos, dmt_nextmap, sizeof(dmt_nextmap));
    }
  SetConVarString(dmt_CVar_Nextmap, dmt_nextmap);
}
