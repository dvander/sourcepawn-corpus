/**
 * vim: et filetype=cpp sts=2 sw=2 ts=2 tw=80
 * ============================================================================
 * Copyright (c) 2008, Adam James <atj@pulsewidth.org.uk>. All rights reserved.
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
 * ============================================================================
 */

#include <sourcemod>

#pragma semicolon 1

#if !defined DEBUG
#define DEBUG 0
#endif

#define PL_VERSION        "1.2"
#define sDEFAULT_GRAVITY  "0.1"
#define fDEFAULT_GRAVITY   0.1
#define fMIN_GRAVITY       0.01
#define fMAX_GRAVITY       2.0

new bool:g_bIsEnabled = true;
new Handle:g_hIsEnabled = INVALID_HANDLE;

new bool:g_bInBonusRound = false;
new g_iMaxClients;

new Handle:g_hGravityLevelWinners = INVALID_HANDLE;
new Float:g_fGravityLevelWinners  = fDEFAULT_GRAVITY;
new Handle:g_hGravityLevelLosers  = INVALID_HANDLE;
new Float:g_fGravityLevelLosers   = fDEFAULT_GRAVITY;

public Plugin:myinfo =
{
  name = "TF2 Bonus Round Gravity",
  author = "deltron",
  description = "Allows the gravity of players on the winning and losing \
                 teams to be set independently during the bonus round.",
  version = PL_VERSION,
  url = "http://sourcemod.net"
};

public OnPluginStart()
{
  SetupConVars();

  g_iMaxClients = GetMaxClients();

  HookEvent("teamplay_round_start", Event_teamplay_round_start);
  HookEvent("teamplay_round_win", Event_teamplay_round_win);
  HookEvent("teamplay_restart_round", Event_teamplay_round_start);
}

public ConVarChange_IsEnabled(Handle:cvar, const String:oldValue[], const String:newValue[])
{
  if (StringToInt(newValue) > 0)
    g_bIsEnabled = true;
  else
    g_bIsEnabled = false;
}

public ConVarChange_GravityLevel(Handle:cvar, const String:oldValue[], const String:newValue[])
{
  new Float:level = StringToFloat(newValue);

  if (cvar == g_hGravityLevelLosers)
  {
    g_fGravityLevelLosers = level;
  }
  else if (cvar == g_hGravityLevelWinners)
  {
    g_fGravityLevelWinners = level;
  }
}

public Action:Event_teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast)
{
  OnBonusRoundStart(GetEventInt(event, "team"));
}

public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
  OnBonusRoundEnd();
}

stock SetupConVars()
{
  CreateConVar("sm_tf2_bonus_grav_version", PL_VERSION, 
      "TF2 Bonus Round Gravity SourceMod plugin", 
      FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

  g_hIsEnabled = CreateConVar("sm_tf2_bonus_grav_enabled", "1", 
      "Enable/disable the modification of client gravity during the bonus round",
      FCVAR_PLUGIN|FCVAR_NOTIFY);

  HookConVarChange(g_hIsEnabled, ConVarChange_IsEnabled);

  g_hGravityLevelLosers = CreateConVar("sm_tf2_bonus_grav_losers", 
      sDEFAULT_GRAVITY, "Sets the gravity level for the losing team during the \
      bonus round.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, fMIN_GRAVITY, true, fMAX_GRAVITY);

  g_hGravityLevelWinners = CreateConVar("sm_tf2_bonus_grav_winners", 
      sDEFAULT_GRAVITY, "Sets the gravity level for the winning team during the \
      bonus round.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, fMIN_GRAVITY, true, fMAX_GRAVITY);

  HookConVarChange(g_hGravityLevelLosers, ConVarChange_GravityLevel);
  HookConVarChange(g_hGravityLevelWinners, ConVarChange_GravityLevel);
}

stock OnBonusRoundStart(winners)
{
  if (g_bIsEnabled)
  {
    g_bInBonusRound = true;
    SetGravityTeam(winners, g_fGravityLevelWinners);
    SetGravityTeam(GetOpposingTFTeam(winners), g_fGravityLevelLosers);
  }
}

stock OnBonusRoundEnd()
{
  if (g_bInBonusRound)
  {
    g_bInBonusRound = false;
    SetGravityAll();
  }

}

stock GetOpposingTFTeam(team)
{
  return (team == 2 ? 3 : (team == 3 ? 2 : -1));
}

stock SetGravityAll(Float:gravity=1.0)
{
  for (new i = 1; i <= g_iMaxClients; i++)
  {
    if (IsClientInGame(i) && !IsFakeClient(i))
      SetEntityGravity(i, gravity);
  }
}

stock SetGravityTeam(team, Float:gravity)
{
  if (team == -1) return;

  for (new i = 1; i <= g_iMaxClients; i++)
  {
    if (IsClientInGame(i) && !IsFakeClient(i) 
        && GetClientTeam(i) == team)
      SetEntityGravity(i, gravity);
  }
}
