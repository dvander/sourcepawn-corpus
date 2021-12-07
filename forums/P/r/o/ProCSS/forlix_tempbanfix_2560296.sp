// Forlix TempBanFix
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2016 Dominik Friedrichs

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION            "1.14"
#define PLUGIN_VERSION_CVAR       "forlix_tempbanfix_version"

#define MAX_STEAMID_LEN           32
#define TEMPBANFIX_FILE           "data/forlix_tempbanfix.txt"

#define TEMPBAN_MSG               "Temporary ban for another %s"

public Plugin:myinfo =
{
  name = "Forlix TempBanFix",
  author = "Forlix (Dominik Friedrichs)",
  description = "Handles all temporary bans, making sure they are removed on expiration",
  version = PLUGIN_VERSION,
  url = "http://forlix.org/"
};

new Handle:tempid_filterlist = INVALID_HANDLE;


public OnPluginStart()
{
  RegServerCmd("listidt", Command_ListIdTemp);
  RegServerCmd("removeid", Command_RemoveId);

  HookEvent("server_addban", Event_AddBan);
  HookEvent("server_removeban", Event_RemoveBan, EventHookMode_Pre);

  new Handle:version_cvar = CreateConVar(PLUGIN_VERSION_CVAR,
  PLUGIN_VERSION,
  "Forlix TempBanFix plugin version",
  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);

  SetConVarString(version_cvar, PLUGIN_VERSION, false, false);

  tempid_filterlist = CreateKeyValues("tempid_filterlist");
  ReadFromFile();

  return;
}


public OnMapStart()
{
  RemoveExpired();
  WriteToFile();

  return;
}


public OnPluginEnd()
{
  RemoveExpired();
  WriteToFile();
  CloseHandle(tempid_filterlist);

  return;
}


public OnClientAuthorized(client,
                          const String:auth[])
{
  decl String:str_authid[MAX_STEAMID_LEN];

  if(!IsClientConnected(client)
  || !GetClientAuthId(client, AuthId_Engine, str_authid, sizeof(str_authid)))
    return;

  KvRewind(tempid_filterlist);

  if(!KvJumpToKey(tempid_filterlist, str_authid))
    return;

  new time_r = KvGetNum(tempid_filterlist, "te")-GetTime();

  if(time_r > 0)
  // client is banned, force disconnect & tell remaining time
  {
    decl String:str_time_r[32];
    FriendlyTime(time_r, str_time_r, sizeof(str_time_r), false);

    KickClientEx(client, TEMPBAN_MSG, str_time_r);
  }
  else
  // temp ban has expired, remove it from the list
    KvDeleteThis(tempid_filterlist);

  return;
}


public Event_AddBan(Handle:event,
                    const String:Event_type[],
                    bool:dontBroadcast)
{
  decl String:str_authid[MAX_STEAMID_LEN];
  decl String:str_duration[64];

  GetEventString(event, "networkid", str_authid, sizeof(str_authid));
  GetEventString(event, "duration", str_duration, sizeof(str_duration));

  if(!str_authid[0])
  // only handle bans by steamid
    return;

  if(!strcmp(str_duration, "permanently"))
  {
    KvRewind(tempid_filterlist);

    if(KvJumpToKey(tempid_filterlist, str_authid))
    // temporary ban is turned into permanent ban
      KvDeleteThis(tempid_filterlist);

    return;
  }

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

  // find or create the authid key
  KvRewind(tempid_filterlist);
  KvJumpToKey(tempid_filterlist, str_authid, true);

  // store expiration timestamp, ban flags and duration
  KvSetNum(tempid_filterlist, "te", GetTime()+duration);

  KvSetNum(tempid_filterlist, "fl", 0);
  KvSetNum(tempid_filterlist, "du", duration);

  // we handle this ban, so remove it from the servers filterlist silently
  ServerCommand("removeid %s", str_authid);
  return;
}


public Action:Event_RemoveBan(Handle:event,
                              const String:Event_type[],
                              bool:dontBroadcast)
{
  decl String:str_authid[MAX_STEAMID_LEN];
  GetEventString(event, "networkid", str_authid, sizeof(str_authid));

  KvRewind(tempid_filterlist);

  if(KvJumpToKey(tempid_filterlist, str_authid))
  // block the removeban event, as we continue to handle this ban
  {
    PrintToServer("TempBanFix handles this ban");
    KvSetNum(tempid_filterlist, "fl", 1);

    WriteToFile();
    return(Plugin_Handled);
  }

  return(Plugin_Continue);
}


public Action:Command_ListIdTemp(args)
{
  RemoveExpired();
  KvRewind(tempid_filterlist);

  if(!KvGotoFirstSubKey(tempid_filterlist))
  {
    PrintToServer("ID temporary filter list (TempBanFix): empty");
    return(Plugin_Handled);
  }
  else
    PrintToServer("ID temporary filter list (TempBanFix):");

  new filter_num = 0;
  new time_c = GetTime();

  do
  {
    filter_num++;

    decl String:str_authid[MAX_STEAMID_LEN];

    decl String:str_time_dur[32];
    decl String:str_time_r[32];

    KvGetSectionName(tempid_filterlist, str_authid, sizeof(str_authid));

    FriendlyTime(KvGetNum(tempid_filterlist, "du"),
                 str_time_dur, sizeof(str_time_dur));

    new time_r = KvGetNum(tempid_filterlist, "te")-time_c;

    if(time_r > 0)
    {
      FriendlyTime(time_r, str_time_r, sizeof(str_time_r), true);
      StrCat(str_time_r, sizeof(str_time_r), " left");
    }
    else
      str_time_r = "expired";

    PrintToServer("%u %s : %s (%s)",
                  filter_num, str_authid, str_time_dur, str_time_r);
  }
  while(KvGotoNextKey(tempid_filterlist));

  return(Plugin_Handled);
}


public Action:Command_RemoveId(args)
{
  decl String:str_authid[MAX_STEAMID_LEN];
  str_authid[0] = '\0';

  GetCmdArgString(str_authid, sizeof(str_authid));

  new split = FindCharInString(str_authid, '\x20');

  if(split >= 0)
    str_authid[split] = '\0';

  KvRewind(tempid_filterlist);

  if(!str_authid[0]
  || !KvJumpToKey(tempid_filterlist, str_authid)
  || !KvGetNum(tempid_filterlist, "fl"))
    return(Plugin_Continue);

  KvDeleteThis(tempid_filterlist);
  PrintToServer("removeid (TempBanFix):  filter removed for %s", str_authid);

  WriteToFile();
  return(Plugin_Handled);
}


void RemoveExpired()
{
  KvRewind(tempid_filterlist);

  if(!KvGotoFirstSubKey(tempid_filterlist))
    return;

  new time_c = GetTime();

  for(;;)
  if(KvGetNum(tempid_filterlist, "te")-time_c > 0)
  {
    if(!KvGotoNextKey(tempid_filterlist))
      break;
  }
  else
  {
    if(KvDeleteThis(tempid_filterlist) < 1)
      break;
  }

  return;
}


void ReadFromFile()
{
  decl String:path[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, path, sizeof(path), TEMPBANFIX_FILE);

  FileToKeyValues(tempid_filterlist, path);
  return;
}


void WriteToFile()
{
  decl String:path[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, path, sizeof(path), TEMPBANFIX_FILE);

  KvRewind(tempid_filterlist);
  KeyValuesToFile(tempid_filterlist, path);
  return;
}


bool:FriendlyTime(time_s,
                  String:str_ftime[],
                  str_ftime_len,
                  bool:compact=true)
{
  decl String:days_pf[16];
  decl String:hrs_pf[16];
  decl String:mins_pf[16];
  decl String:secs_pf[16];

  if(compact)
  {
    days_pf = "d";
    hrs_pf = "h";
    mins_pf = "m";
    secs_pf = "s";
  }
  else
  {
    days_pf = " days";
    hrs_pf = " hours";
    mins_pf = " minutes";
    secs_pf = " seconds";
  }

  if(time_s < 0)
  {
    str_ftime[0] = '\0';
    return(false);
  }

  new days = time_s/86400;
  new hrs = (time_s/3600)%24;
  new mins = (time_s/60)%60;
  new secs = time_s%60;

  if(time_s < 60)
    Format(str_ftime, str_ftime_len,
           "%u%s",
           secs, secs_pf);
  else
  if(time_s < 3600)
    Format(str_ftime, str_ftime_len,
           "%u%s %u%s",
           mins, mins_pf, secs, secs_pf);
  else
  if(time_s < 86400)
    Format(str_ftime, str_ftime_len,
           "%u%s %u%s",
           hrs, hrs_pf, mins, mins_pf);
  else
    Format(str_ftime, str_ftime_len,
           "%u%s %u%s",
           days, days_pf, hrs, hrs_pf);

  return(true);
}
