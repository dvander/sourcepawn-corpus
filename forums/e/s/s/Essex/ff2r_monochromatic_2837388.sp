/*
  "monochrome"
  {
    "target"	"0" // 0 = Everyone, 1 = Only Boss, 2: Enemy Team
    "plugin_name"	"ff2r_monochromatic"
  }
*/

#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sourcemod>
#include <cfgmap>
#include <ff2r>
#include <vscript>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
  name        = "Freak Fortress 2 Rewrite x VScript: Monochromatic",
  description = "The following has been brought to you in black and white",
  author      = "Koishi, Zell",
  version     = "1.1.0",
};

Handle g_SDKCallOverlay;
bool   enable = false;
int    bossId;
int    targetType = 0;  // 0 = Everyone, 1 = Only Boss, 2: Enemy Team

// clear vscript variables
public void OnAllPluginsLoaded()
{
  if (VScript_IsScriptVMInitialized())
    VScript_ResetScriptVM();
}

public void VScript_OnScriptVMInitialized()
{
  VScriptFunction pFunction;

  pFunction = VScript_GetClassFunction("CBasePlayer", "SetScriptOverlayMaterial");
  g_SDKCallOverlay = pFunction.CreateSDKCall();
  if (g_SDKCallOverlay == null)
    ThrowError("Failed to create SDK call for CBasePlayer::SetScriptOverlayMaterial");
}

public void OnPluginStart()
{
  HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
  HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
  if (g_SDKCallOverlay != null)
  {
    g_SDKCallOverlay.Close();
    g_SDKCallOverlay = null;
  }
  // clear vscript variables
  if (VScript_IsScriptVMInitialized())
    VScript_ResetScriptVM();

  // unhook events
  bossId = 0;
  enable = false;
  UnhookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
  UnhookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void FF2R_OnBossCreated(int client, BossData cfg, bool setup)
{
  if (!(!setup || FF2R_GetGamemodeType() != 2))
  {
    AbilityData ability = cfg.GetAbility("monochrome");
    if (ability.IsMyPlugin())
    {
      enable     = true;
      bossId     = client;
      targetType = ability.GetInt("target", 0);
      for (int i = 1; i <= MaxClients; i++)
      {
        if (!IsValidClient(i))
          continue;

        if (TargetType(client, i, targetType))
        {
          SetMonochrome(i);
        }
      }
    }
  }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
  if (enable)
  {
    enable = false;
    bossId = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
      if (!IsValidClient(i))
        continue;

      ClearMonochrome(i);
    }
  }
}

public void OnClientPutInServer(int client)
{
  if (!IsValidClient(client))
    return;
  if (enable && TargetType(bossId, client, targetType))
  {
    SetMonochrome(client);
  }
}

public void SetMonochrome(int client)
{
  if (g_SDKCallOverlay == null)
    return;
  // call vscript function to set overlay material be "debug/yuv"
  SDKCall(g_SDKCallOverlay, client, "debug/yuv");
}

public void ClearMonochrome(int client)
{
  if (g_SDKCallOverlay == null)
    return;

  // clear VScript overlay material
  SDKCall(g_SDKCallOverlay, client, "");
}

stock bool TargetType(int client, int target, int type)
{
  switch (type)
  {
    case 1:  // if target is boss
    {
      return (client == target);
    }
    case 2:  // if target's team is not same team as boss's team
    {
      return (GetClientTeam(client) != GetClientTeam(target));
    }
    default:  // if target is everyone
    {
      return true;
    }
  }
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
  if (client <= 0 || client > MaxClients)
    return false;

  if (!IsClientInGame(client) || !IsClientConnected(client))
    return false;

  if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))
    return false;

  if (replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
    return false;

  return true;
}