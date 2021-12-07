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
 *
 * Thanks to bl4nk on the SourceMod forums for helping me to remove the
 * dependency on sdktools and thus make this script work on Windows as well as
 * Linux! 
 */

#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1

// Defines
#if !defined DEBUG
#define DEBUG 0
#endif

#define PL_VERSION      "1.1"

// Enums
enum TFFlagEvent
{
  TFFlag_PickedUp = 1,
  TFFlag_Captured = 2,
  TFFlag_Defended = 3,
  TFFlag_Dropped  = 4
};

static const TFClass_MaxAmmo[TFClassType][3] =
{
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {20, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};

static const TFClass_MaxClip[TFClassType][2] = 
{
  {-1, -1}, {6, 12}, {25, 0}, {4, 6}, {4, 8}, 
  {40, -1}, {-1, 6}, {-1, 6}, {6, -1}, {6, 12}
};

// Globals
new Handle:g_hTogglePlugin = INVALID_HANDLE;
new bool:g_bIsEnabled = true;

// Public
public Plugin:myinfo =
{
  name = "TF2 Capper Regeneration",
  author = "deltron",
  description = "Regenerates a player when they capture the intelligence",
  version = PL_VERSION,
  url = "http://sourcemod.net"
};

public OnPluginStart()
{
  SetupConVars();

  HookEvent("teamplay_flag_event", Event_teamplay_flag_event);
}

public Action:Event_teamplay_flag_event(Handle:event, const String:name[], 
    bool:dontBroadcast)
{
  if (!g_bIsEnabled)
    return;

  switch (TFFlagEvent:GetEventInt(event, "eventtype"))
  {
    case TFFlag_Captured:
    {
      RegenerateClient(GetEventInt(event, "player"));
    }
  }
}

public ConVarChange_TogglePlugin(Handle:cvar, const String:oldValue[], const String:newValue[])
{
  if (StringToInt(newValue) > 0)
    g_bIsEnabled = true;
  else
    g_bIsEnabled = false;
}

// Stocks
stock SetupConVars()
{
  CreateConVar("sm_tf2_capregen", PL_VERSION, 
      "TF2 capper regeneration plugin.", 
      FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

  g_hTogglePlugin = CreateConVar("sm_tf2_capregen_enable", "1", 
      "Enable/disable Q3F/ETF style player regeneration upon \
      flag capture.",
      FCVAR_PLUGIN|FCVAR_NOTIFY);

  HookConVarChange(g_hTogglePlugin, ConVarChange_TogglePlugin);
} 

stock RegenerateClient(client)
{
  if (!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
    return;

  new TFClassType:class = TF2_GetPlayerClass(client);

  SetEntityHealth(client, 
      TF2_GetPlayerResourceData(client, TFResource_MaxHealth));
  FillClientAmmo(client, class);
  FillClientClip(client, class);
}

stock FillClientAmmo(client, TFClassType:class)
{
  for (new i=0 ; i<sizeof(TFClass_MaxAmmo[]) ; i++)
  {
    if (TFClass_MaxAmmo[class][i] == -1) continue;

    SetEntData(
        client,
        FindSendPropInfo("CTFPlayer", "m_iAmmo") + ((i+1)*4),
        TFClass_MaxAmmo[class][i]);
  }
}

stock FillClientClip(client, TFClassType:class)
{
  for (new i=0 ; i<sizeof(TFClass_MaxClip[]) ; i++)
  {

    if (class == TFClass_Scout && GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iEntityLevel") > 1) {
      if (i == 0) TFClass_MaxClip[class][i] = 2;
      if (i == 1) TFClass_MaxClip[class][i] = -1;
    } else {
      if (i == 0) TFClass_MaxClip[class][i] = 6;
      if (i == 1) TFClass_MaxClip[class][i] = 12;
    }

    if (TFClass_MaxClip[class][i] == -1) continue;

    SetEntData(
      GetPlayerWeaponSlot(client, i),
      FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 
      TFClass_MaxClip[class][i]);
  }
}
