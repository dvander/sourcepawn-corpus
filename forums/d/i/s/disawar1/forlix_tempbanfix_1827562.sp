// Forlix TempBanFix
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2009 Dominik Friedrichs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <sourcemod>

#define SB_EDITION	1 // L4D SourceBans version

#pragma semicolon 1

#define PLUGIN_VERSION            "1.05"
#define PLUGIN_VERSION_CVAR       "forlix_tempbanfix_version"

#if SB_EDITION
	#define TEMPBAN_MSG               "You have been banned after voting off for %s"
#else
	#define TEMPBAN_MSG               "Temporary ban for another %s"
#endif

public Plugin:myinfo =
{
  name = "[L4D & L4D2] Forlix TempBanFix",
  author = "Forlix (Dominik Friedrichs), raziEiL [disawar1]",
  description = "Handles all temporary bans, making sure they are removed on expiration",
  version = PLUGIN_VERSION,
  url = "http://forlix.org/"
};

new Handle:tempid_filterlist = INVALID_HANDLE;

#if SB_EDITION
	static Handle:g_hVoteBan;
#endif

public OnPluginStart()
{
  RegServerCmd("listid", Command_Listid);
  RegServerCmd("removeid", Command_Removeid);

  HookEvent("server_addban", Event_AddBan);
  HookEvent("server_removeban", Event_RemoveBan, EventHookMode_Pre);

  new Handle:version_cvar = CreateConVar(PLUGIN_VERSION_CVAR,
  PLUGIN_VERSION,
  "Forlix TempBanFix plugin version",
  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);

  SetConVarString(version_cvar, PLUGIN_VERSION, false, false);

	#if SB_EDITION
		g_hVoteBan = FindConVar("sv_vote_kick_ban_duration");
		SetConVarInt(g_hVoteBan, 14);
	#endif

  tempid_filterlist = CreateKeyValues("tempid_filterlist");
}


public OnPluginEnd()
{
  // forget all temporary bans on unload
  CloseHandle(tempid_filterlist);
}


public OnClientAuthorized(client,
                          const String:str_networkid[])
{
  KvRewind(tempid_filterlist);

  if(!KvJumpToKey(tempid_filterlist, str_networkid))
    return;

  new time_r = KvGetNum(tempid_filterlist, "time_exp")-GetTime();

  if(time_r > 0)
  // client is banned, force disconnect + tell remaining time
  {
    decl String:str_time_r[32];
    FriendlyTime(time_r, str_time_r, sizeof(str_time_r), false);

    KickClientEx(client, TEMPBAN_MSG, str_time_r);
  }
  else
  // temp ban has expired, remove it from the list
    KvDeleteThis(tempid_filterlist);
}

public Event_AddBan(Handle:event,
                    const String:Event_type[],
                    bool:dontBroadcast)
{
  decl String:str_networkid[32];
  decl String:str_duration[64];

  GetEventString(event, "networkid", str_networkid, sizeof(str_networkid));
  GetEventString(event, "duration", str_duration, sizeof(str_duration));

  if(!str_networkid[0])
  // only handle bans by network id
    return;

	#if !SB_EDITION
	  if(StrEqual(str_duration, "permanently"))
	  {
		KvRewind(tempid_filterlist);

		if(KvJumpToKey(tempid_filterlist, str_networkid))
		// temporary ban is turned into permanent ban
		  KvDeleteThis(tempid_filterlist);

		return;
	  }
	#endif

  // extract the duration value and convert it to seconds
  decl fl_start;
  decl fl_len;
  decl duration;

  if((fl_start = FindCharInString(str_duration, '\x20')) <= 0
  || (fl_len = FindCharInString(str_duration[++fl_start], '\x20')) <= 0)
    return;
  else
    str_duration[fl_start+fl_len] = '\0';

  if((duration = StringToInt(str_duration[fl_start])*60) <= 0)
    return;

	#if SB_EDITION
		if (duration != (GetConVarInt(g_hVoteBan) * 60))
			return;
	#endif

  // find or create the networkid key
  KvRewind(tempid_filterlist);
  KvJumpToKey(tempid_filterlist, str_networkid, true);

  // store ban state, duration and expiration timestamp
  KvSetNum(tempid_filterlist, "state", 0);

  KvSetNum(tempid_filterlist, "duration", duration);
  KvSetNum(tempid_filterlist, "time_exp", duration+GetTime());

  // we handle this ban, so remove it from the servers filterlist silently
  ServerCommand("removeid %s", str_networkid);
}


public Action:Event_RemoveBan(Handle:event,
                              const String:Event_type[],
                              bool:dontBroadcast)
{
  decl String:str_networkid[32];
  GetEventString(event, "networkid", str_networkid, sizeof(str_networkid));

  KvRewind(tempid_filterlist);

  if(KvJumpToKey(tempid_filterlist, str_networkid))
  // block the removeban event, as we continue to handle this ban
  {
    PrintToServer("TempBanFix handles this ban");

    KvSetNum(tempid_filterlist, "state", 1);
  }
}


public Action:Command_Listid(args)
{
  PrintToServer("");
  KvRewind(tempid_filterlist);

  if(!KvGotoFirstSubKey(tempid_filterlist))
  {
    PrintToServer("ID temporary filter list (TempBanFix): empty");
    return(Plugin_Stop);
  }
  else
    PrintToServer("ID temporary filter list (TempBanFix):");

  new filter_num = 0;
  new time_c = GetTime();

  do
  {
    filter_num++;

    decl String:str_networkid[32];

    decl String:str_time_dur[32];
    decl String:str_time_r[32];

    KvGetSectionName(tempid_filterlist, str_networkid, sizeof(str_networkid));

    FriendlyTime(KvGetNum(tempid_filterlist, "duration"),
                 str_time_dur, sizeof(str_time_dur), true);

    new time_r = KvGetNum(tempid_filterlist, "time_exp")-time_c;

    if(time_r > 0)
    {
      FriendlyTime(time_r, str_time_r, sizeof(str_time_r), true);
      StrCat(str_time_r, sizeof(str_time_r), " left");
    }
    else
      str_time_r = "expired";

    PrintToServer("%d %s : %s (%s)",
                  filter_num, str_networkid, str_time_dur, str_time_r);
  }
  while(KvGotoNextKey(tempid_filterlist));

  return(Plugin_Stop);
}


public Action:Command_Removeid(args)
{
  decl String:str_networkid[32];
  str_networkid[0] = '\0';

  GetCmdArgString(str_networkid, sizeof(str_networkid));

  new split = FindCharInString(str_networkid, '\x20');

  if(split >= 0)
    str_networkid[split] = '\0';

  KvRewind(tempid_filterlist);

  if(!str_networkid[0]
  || !KvJumpToKey(tempid_filterlist, str_networkid)
  || !KvGetNum(tempid_filterlist, "state"))
    return(Plugin_Continue);

  KvDeleteThis(tempid_filterlist);
  PrintToServer("removeid (TempBanFix):  filter removed for %s", str_networkid);

  return(Plugin_Handled);
}


bool:FriendlyTime(time_s,
                  String:str_ftime[],
                  str_ftime_len,
                  bool:compact=false)
{
  if(time_s < 0)
  {
    str_ftime[0] = '\0';
    return(false);
  }

  new String:days_postfix[] = " days";
  new String:hrs_postfix[] = " hours";
  new String:mins_postfix[] = " minutes";

  if(compact)
  {
    days_postfix = "d";
    hrs_postfix = "h";
    mins_postfix = "m";
  }

  new days = time_s/86400;
  new hrs = (time_s/3600)%24;
  new mins = (time_s/60)%60;

  if(time_s < 60)
    Format(str_ftime, str_ftime_len,
           "< 1%s",
           mins_postfix);
  else
  if(time_s < 3600)
    Format(str_ftime, str_ftime_len,
           "%d%s",
           mins, mins_postfix);
  else
  if(time_s < 86400)
  {
    if(mins)
      Format(str_ftime, str_ftime_len,
             "%d%s %d%s",
             hrs, hrs_postfix, mins, mins_postfix);
    else
      Format(str_ftime, str_ftime_len,
             "%d%s",
             hrs, hrs_postfix);
  }
  else
  {
    if(hrs)
      Format(str_ftime, str_ftime_len,
             "%d%s %d%s",
             days, days_postfix, hrs, hrs_postfix);
    else
      Format(str_ftime, str_ftime_len,
             "%d%s",
             days, days_postfix);
  }

  return(true);
}
