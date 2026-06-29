/*
  "rage_chain_conditions"
  {
    "slot"               "0"
    "rage_duration"      "20.0"

    "conditions"
    {
      "0"  // First condition set
      {
        "trigger"    "24"     // trigger condition
        "keep"       "1"      // whether to keep trigger condition after applying 1 = keep, 0 = remove
        "apply"      "-4"     // apply condition -4 = explode, -3 = bonk stun, -2 = bleed, -1 = ignite or any condition id
        "duration"   "3.0"    // duration of apply condition
      }
      "1"  // Second condition set
      {
        "trigger"    "27"     // trigger condition
        "keep"       "1"      // whether to keep trigger condition after applying 1 = keep, 0 = remove
        "apply"      "-3"     // apply condition -4 = explode, -3 = bonk stun, -2 = bleed, -1 = ignite or any condition id
        "duration"   "3.0"    // duration of apply condition
      }
      // Add more as needed...
    }

    "plugin_name"     "ff2r_chain_conditions"
  }
*/

#include <sourcemod>
#include <cfgmap>
#include <ff2r>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
  name    = "Freak Fortress 2: Chain Conditions",
  author  = "Zell",
  version = "1.1.1",
};

enum struct ConditionSet
{
  int   trigger;
  int   keep;
  int   apply;
  float duration;
  float lastApplied;
}

float     flRageDuration[MAXPLAYERS + 1];
ArrayList conditionSets[MAXPLAYERS + 1];

public void OnPluginStart()
{
  for (int i = 1; i <= MaxClients; i++)
    conditionSets[i] = new ArrayList(sizeof(ConditionSet));
}

public void OnPluginEnd()
{
  for (int i = 1; i <= MaxClients; i++)
    delete conditionSets[i];
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
  if (!StrContains(ability, "rage_chain_conditions", false) && cfg.IsMyPlugin())
  {
    float     rageDuration = cfg.GetFloat("rage_duration", 10.0);
    ConfigMap conditions   = cfg.GetSection("conditions");

    if (conditions == null)
      return;

    for (int i = 1; i <= MaxClients; i++)
    {
      // clear previous rage duration and conditions
      flRageDuration[i] = 0.0;
      conditionSets[i].Clear();

      // skip if client is not valid or is on the same team
      if (!IsValidLivingClient(i) || TF2_GetClientTeam(i) == TF2_GetClientTeam(client))
        continue;

      // set rage duration and initialize condition sets
      flRageDuration[i] = GetEngineTime() + rageDuration;

      char index[8];
      int  conditionIndex = 0;
      do
      {
        IntToString(conditionIndex, index, sizeof(index));
        ConfigMap conditionConfig = conditions.GetSection(index);

        if (conditionConfig == null)
          break;

        ConditionSet condition;
        int          value;
        float        duration;

        conditionConfig.GetInt("trigger", value);
        condition.trigger = value;

        conditionConfig.GetInt("keep", value);
        condition.keep = value;

        conditionConfig.GetInt("apply", value);
        condition.apply = value;

        conditionConfig.GetFloat("duration", duration);
        condition.duration    = duration;
        condition.lastApplied = 0.0;

        if (condition.trigger >= 0 && condition.apply >= -4)
          conditionSets[i].PushArray(condition);

        conditionIndex++;
      }
      while (conditionIndex);

      if (conditionSets[i].Length > 0)
        SDKHook(i, SDKHook_PreThink, ChainPreThink);
    }
  }
}

public void FF2R_OnBossRemoved(int client)
{
  // clear rage duration and conditions when the boss is removed
  for (int i = 1; i <= MaxClients; i++)
  {
    if (flRageDuration[i] > 0.0)
    {
      flRageDuration[i] = 0.0;
      conditionSets[i].Clear();
      SDKUnhook(i, SDKHook_PreThink, ChainPreThink);
    }
  }
}

public void ChainPreThink(int client)
{
  if (GetEngineTime() > flRageDuration[client])
  {
    flRageDuration[client] = 0.0;
    conditionSets[client].Clear();
    SDKUnhook(client, SDKHook_PreThink, ChainPreThink);
    return;
  }

  if (!IsValidLivingClient(client))
    return;

  int size = conditionSets[client].Length;
  for (int i = 0; i < size; i++)
  {
    ConditionSet condition;
    conditionSets[client].GetArray(i, condition);

    if (TF2_IsPlayerInCondition(client, view_as<TFCond>(condition.trigger)) && GetEngineTime() >= condition.lastApplied)
    {
      switch (condition.apply)
      {
        case -1: TF2_IgnitePlayer(client, client, condition.duration);
        case -2: TF2_MakeBleed(client, client, condition.duration);
        case -3: TF2_StunPlayer(client, condition.duration, 0.0, TF_STUNFLAGS_NORMALBONK);
        case -4: SDKHooks_TakeDamage(client, client, client, GetClientHealth(client) * 10.0, (DMG_ALWAYSGIB | DMG_CRIT | DMG_BLAST));
        default: TF2_AddCondition(client, view_as<TFCond>(condition.apply), condition.duration);
      }

      condition.lastApplied = GetEngineTime() + condition.duration;
      conditionSets[client].SetArray(i, condition);
    }

    if (TF2_IsPlayerInCondition(client, view_as<TFCond>(condition.trigger)) && condition.keep == 0)
      TF2_RemoveCondition(client, view_as<TFCond>(condition.trigger));
  }
}

stock bool IsValidLivingClient(int client, bool replaycheck = true)
{
  if (client <= 0 || client > MaxClients) return false;
  if (!IsClientInGame(client) || !IsClientConnected(client)) return false;
  if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
  if (replaycheck && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
  if (!IsPlayerAlive(client)) return false;
  return true;
}