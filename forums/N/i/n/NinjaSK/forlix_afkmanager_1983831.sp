// Forlix AFKManager
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2011 Dominik Friedrichs

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION            "1.23"
#define PLUGIN_VERSION_CVAR       "forlix_afkmanager_version"

#define MAX_NAME_LEN              32
#define TEAM_SPECTATOR            1

#define AFK_CHECK_INTERVAL        0.2

// convar defaults

#define PLAYER_TIME               "60"
#define SPECTATOR_TIME            "300"
#define SPECTATOR_KICK_THRESHOLD  "16"

public Plugin:myinfo =
{
  name = "Forlix AFKManager",
  author = "Forlix (Dominik Friedrichs)",
  description = "AFK to Spectator and AFK Spectator kicking",
  version = PLUGIN_VERSION,
  url = "http://forlix.org/"
};

new Handle:h_player_time = INVALID_HANDLE;
new Handle:h_spectator_time = INVALID_HANDLE;
new Handle:h_spectator_kick_threshold = INVALID_HANDLE;

new player_time = 0;
new spectator_time = 0;
new spectator_kick_threshold = 0;

new Handle:h_timer_afkcheck = INVALID_HANDLE;

new Float:p_afk_time[MAXPLAYERS+1] = {0.0, ...};


public OnPluginStart()
{
  new Handle:version_cvar = CreateConVar(PLUGIN_VERSION_CVAR,
  PLUGIN_VERSION,
  "Forlix AFKManager plugin version",
  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);

  SetConVarString(version_cvar, PLUGIN_VERSION, false, false);

  h_player_time = CreateConVar("forlix_afkmanager_player_time",
  PLAYER_TIME,
  "Time in full seconds players can be AFK before being moved to Spectator (0 to disable)",
  0, true, 0.0, true, 300.0);

  h_spectator_time = CreateConVar("forlix_afkmanager_spectator_time",
  SPECTATOR_TIME,
  "Time in full seconds Spectators can be AFK before being kicked (0 to disable)",
  0, true, 0.0, true, 1200.0);

  h_spectator_kick_threshold = CreateConVar("forlix_afkmanager_spectator_kick_threshold",
  SPECTATOR_KICK_THRESHOLD,
  "Amount of total players connected above which AFK Spectators will be kicked",
  0, true, 0.0, true, 64.0);

  HookConVarChange(h_player_time, MyConVarChanged);
  HookConVarChange(h_spectator_time, MyConVarChanged);
  HookConVarChange(h_spectator_kick_threshold, MyConVarChanged);

  // manually trigger convar readout
  MyConVarChanged(INVALID_HANDLE, "0", "0");

  return;
}


public OnClientConnected(client)
{
  p_afk_time[client] = 0.0;
  return;
}


public Action:OnClientCommand(client,
                              args)
{
  p_afk_time[client] = 0.0;
  return(Plugin_Continue);
}


public Action:Player_AFKCheck(Handle:htimer)
{
  static p_lastbtnstate[MAXPLAYERS+1] = {0, ...};
  new numplayers = GetRealPlayerCount();

  for(new client = 1; client <= MaxClients; client++)
  if(IsClientInGame(client)
  && !IsFakeClient(client))
  {
    if(p_lastbtnstate[client]
    != (p_lastbtnstate[client] = GetClientButtons(client)))
    // players buttons changed
    {
      p_afk_time[client] = 0.0;
      continue;
    }

    if(GetClientTeam(client) <= TEAM_SPECTATOR)
    // spectator or unassigned
    {
      if(numplayers > spectator_kick_threshold
      && spectator_time
      && (p_afk_time[client] += AFK_CHECK_INTERVAL) > spectator_time)
      // AFK as spectator for too long
      {
        AFKKickMessage(client);
        ServerCommand("kickid %u", GetClientUserId(client));

        numplayers--;
      }

      continue;
    }

    if(!IsPlayerAlive(client))
    // ignore dead players in a team other than spec
      continue;

    if(player_time
    && (p_afk_time[client] += AFK_CHECK_INTERVAL) > player_time)
    // AFK as alive player for too long
    {
      p_afk_time[client] = 0.0;
      ChangeClientTeam(client, TEAM_SPECTATOR);
    }
  }

  return(Plugin_Continue);
}


RestartAFKTimer()
{
  if(h_timer_afkcheck != INVALID_HANDLE)
  {
    KillTimer(h_timer_afkcheck);
    h_timer_afkcheck = INVALID_HANDLE;
  }

  for(new client = 1; client <= MaxClients; client++)
  if(IsClientInGame(client))
    p_afk_time[client] = 0.0;

  h_timer_afkcheck = CreateTimer(AFK_CHECK_INTERVAL,
                                 Player_AFKCheck,
                                 INVALID_HANDLE,
                                 TIMER_REPEAT);

  return;
}


AFKKickMessage(client)
{
  decl String:name[MAX_NAME_LEN];

  if(!GetClientName(client, name, sizeof(name)))
    return;

  new Handle:h_textmsg = StartMessageAll("TextMsg");

  if(h_textmsg != INVALID_HANDLE)
  {
    BfWriteByte(h_textmsg, 3);
    BfWriteString(h_textmsg, "#Game_idle_kick");
    BfWriteString(h_textmsg, name);
    EndMessage();
  }

  return;
}


GetRealPlayerCount()
{
  new players = 0;

  for(new client = 1; client <= MaxClients; client++)
  if(IsClientInGame(client)
  && !IsFakeClient(client))
    players++;

  return(players);
}


public MyConVarChanged(Handle:convar,
                       const String:oldValue[],
                       const String:newValue[])
{
  player_time = GetConVarInt(h_player_time);
  spectator_time = GetConVarInt(h_spectator_time);
  spectator_kick_threshold = GetConVarInt(h_spectator_kick_threshold);

  RestartAFKTimer();
  return;
}
