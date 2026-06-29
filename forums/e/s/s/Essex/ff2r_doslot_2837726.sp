/*
  "passive_doslot"
  {
    "max"		      "3"			// Max slot count of this ability

    "delay1"		  "3.0"		// Delay before using slot ability
    "doslot1"		  "20"		// Trigger Slot

    "delay2"		  "3.0"		// Delay before using slot ability
    "doslot2"		  "20"		// Trigger Slot

    "delay3"		  "3.0"		// Delay before using slot ability
    "doslot3"		  "20"		// Trigger Slot

    "plugin_name"	"ff2r_doslot"
  }

  "rage_doslot"	// Ability name can use suffixes
  {
    "slot"		    "0"			// Ability Slot
    "delay"		    "3.0"		// Delay before first use
    "doslot"		  "20"		// Trigger Slot

    "plugin_name"	"ff2r_doslot"
  }

  "kill_class_doslot"
  {
    "scout"    "20"
    "soldier"  "21"
    "pyro"     "22"
    "demoman"  "23"
    "heavy"    "24"
    "medic"    "25"
    "sniper"   "26"
    "engineer" "27"
    "spy"      "28"
    "cooldown" "3.0"

    "plugin_name"	"ff2r_doslot"
  }

  "rage_charge_doslot"      // Ability name can use suffixes
  {
    "slot"		            "0"			  // Ability Slot

    "doslot"		          "20"		  // Trigger Slot (example: 20 is ion cannon)
    "amount"		          "3"	      // Amount of charge to use
    "ragecost"            "0.0"     // Mininum rage cost for using ability (0 = no rage cost)
    "cooldown"		        "3.0"		  // Cooldown time before using ability again
    "buttonmode"	        "1"		    // ActivationKey  (1 = RightClick. 2 = ReloadButton. 3 = Special)

    "hud_message"	        "%d Ion Cannon Left Press Reload to use"		// Show HUD message when ability is used
    "hud_message_color"	  "0 ; 255 ; 0"	// HUD message color (RGB format)
    "hud_cooldown_color"	"255 ; 0 ; 0"	// HUD cooldown color (RGB format)

    "plugin_name"         "ff2r_doslot"
  }
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <tf2>
#include <tf2_stocks>
#include <ff2r>

#pragma semicolon 1
#pragma newdecls required

enum struct SlotData
{
  int   slotNumber;
  float timer;
}

enum struct onKillClassSlotData
{
  TFClassType classType;
  int         slotNumber;
}

enum struct ChargeSlotData
{
  int   charges;
  float nextUse;
  int   slotNumber;
  float ragecost;
  int   buttonMode;
  char  hudMessage[128];
  int   hudColor[3];
  int   cooldownColor[3];
  float cooldown;
}

// store slot data
ArrayList passiveSlots[MAXPLAYERS + 1];
ArrayList rageSlots[MAXPLAYERS + 1];
ArrayList onKillClassSlot[MAXPLAYERS + 1];
ArrayList chargeSlots[MAXPLAYERS + 1];

// interval
bool      bHasChargeAbility[MAXPLAYERS + 1];
float     flOnKillCooldown[MAXPLAYERS + 1];

// HUD
Handle    hChargeHud[MAXPLAYERS + 1][3];  // Support up to 3 charge slots per player
float     flNextHud[MAXPLAYERS + 1];

public Plugin myinfo =
{
  name        = "[FF2R] Do Slot",
  author      = "Zell",
  description = "triggers a slot ability after a delay or on kill for a specific class",
  version     = "1.0.1",
  url         = ""
};

public void OnPluginStart()
{
  HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
  HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
  HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);

  for (int client = 0; client <= MaxClients; client++)
  {
    passiveSlots[client]     = new ArrayList(sizeof(SlotData));
    rageSlots[client]        = new ArrayList(sizeof(SlotData));
    chargeSlots[client]      = new ArrayList(sizeof(ChargeSlotData));
    onKillClassSlot[client]  = new ArrayList(sizeof(onKillClassSlotData));
    flOnKillCooldown[client] = 0.0;

    for (int slot = 0; slot < 3; slot++)
    {
      hChargeHud[client][slot] = CreateHudSynchronizer();
    }

    flNextHud[client] = 0.0;
  }
}

public void OnPluginEnd()
{
  // unhook events
  UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
  UnhookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
  UnhookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);

  // clean up arrays
  for (int client = 0; client <= MaxClients; client++)
  {
    delete passiveSlots[client];
    delete rageSlots[client];
    delete chargeSlots[client];
    delete onKillClassSlot[client];
    flOnKillCooldown[client] = 0.0;

    // close HUD
    for (int slot = 0; slot < 3; slot++)
    {
      CloseHandle(hChargeHud[client][slot]);
    }

    flNextHud[client] = 0.0;
  }
}

public void FF2R_OnBossCreated(int client, BossData cfg, bool setup)
{
  if (!setup || FF2R_GetGamemodeType() != 2)
  {
    passiveSlots[client].Clear();
    rageSlots[client].Clear();
    onKillClassSlot[client].Clear();
    flOnKillCooldown[client] = 0.0;
    chargeSlots[client].Clear();
    bHasChargeAbility[client] = false;

    AbilityData ability       = cfg.GetAbility("passive_doslot");
    if (ability.IsMyPlugin())
    {
      int max = ability.GetInt("max", 0);

      for (int i = 1; i <= max; i++)
      {
        char ability_name[64];

        Format(ability_name, sizeof(ability_name), "doslot%i", i);
        int slotNum = ability.GetInt(ability_name, -2);

        if (slotNum != -2)
        {
          Format(ability_name, sizeof(ability_name), "delay%i", i);
          float    delay = ability.GetFloat(ability_name);

          SlotData data;
          data.slotNumber = slotNum;
          data.timer      = GetEngineTime() + delay;

          passiveSlots[client].PushArray(data);
        }
      }
    }

    // handle on-kill class slots
    ability = cfg.GetAbility("kill_class_doslot");
    if (ability.IsMyPlugin())
    {
      for (int i = 1; i <= 9; i++)  // 1-9 because 0 is unknown class
      {
        char class[32];
        GetClassStringByIndex(i, class, sizeof(class));

        int slotNum = ability.GetInt(class, -2);
        if (slotNum != -2)
        {
          onKillClassSlotData data;
          data.classType  = view_as<TFClassType>(i);
          data.slotNumber = slotNum;

          onKillClassSlot[client].PushArray(data);
        }
      }
    }
    SDKHook(client, SDKHook_PreThink, DoSlot_Prethink);
  }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
  for (int client = 1; client <= MaxClients; client++)
  {
    if (FF2R_GetBossData(client))
    {
      passiveSlots[client].Clear();
      rageSlots[client].Clear();
      onKillClassSlot[client].Clear();
      flOnKillCooldown[client] = 0.0;
      chargeSlots[client].Clear();
      bHasChargeAbility[client] = false;

      SDKUnhook(client, SDKHook_PreThink, DoSlot_Prethink);
      break;
    }
  }
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
  if (!cfg.IsMyPlugin())
    return;

  if (!StrContains(ability, "rage_doslot", false))
  {
    SlotData data;
    data.slotNumber = cfg.GetInt("doslot", 0);
    data.timer      = GetEngineTime() + cfg.GetFloat("delay", 0.0);

    rageSlots[client].PushArray(data);
  }

  else if (!StrContains(ability, "rage_charge_doslot", false))
  {
    // prevent adding more than 5 charge slots
    if (chargeSlots[client].Length >= 3)
      return;

    ChargeSlotData data;
    data.charges    = cfg.GetInt("amount", 3);
    data.slotNumber = cfg.GetInt("doslot", 20);
    data.ragecost   = cfg.GetFloat("ragecost", 0.0);
    data.buttonMode = cfg.GetInt("buttonmode", 2);
    data.cooldown   = cfg.GetFloat("cooldown", 3.0);
    data.nextUse    = 0.0;

    cfg.GetString("hud_message", data.hudMessage, sizeof(data.hudMessage), "");

    char colorStr[32];
    cfg.GetString("hud_message_color", colorStr, sizeof(colorStr), "0 255 0");
    ParseColorString(colorStr, data.hudColor);

    cfg.GetString("hud_cooldown_color", colorStr, sizeof(colorStr), "255 0 0");
    ParseColorString(colorStr, data.cooldownColor);

    chargeSlots[client].PushArray(data);
    bHasChargeAbility[client] = true;
  }
}

public void DoSlot_Prethink(int client)
{
  DoSlot(client, GetEngineTime());
}

public void DoSlot(int client, float gameTime)
{
  // this is for passive
  int passiveCount = passiveSlots[client].Length;
  for (int i = passiveCount - 1; i >= 0; i--)
  {
    SlotData data;
    passiveSlots[client].GetArray(i, data);

    if (data.timer <= gameTime)
    {
      FF2R_DoBossSlot(client, data.slotNumber, data.slotNumber);
      passiveSlots[client].Erase(i);
    }
  }

  // this is for rage
  int rageCount = rageSlots[client].Length;
  for (int i = rageCount - 1; i >= 0; i--)
  {
    SlotData data;
    rageSlots[client].GetArray(i, data);

    if (data.timer <= gameTime)
    {
      FF2R_DoBossSlot(client, data.slotNumber, data.slotNumber);
      rageSlots[client].Erase(i);
    }
  }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
  if (!bHasChargeAbility[client] || !IsValidClient(client) || !IsPlayerAlive(client))
    return Plugin_Continue;

  BossData boss = FF2R_GetBossData(client);
  if (!boss)
    return Plugin_Continue;

  // this is for checking charge ability
  if (chargeSlots[client].Length == 0)
  {
    bHasChargeAbility[client] = false;
    return Plugin_Continue;
  }

  // get current rage
  float          currentRage = GetBossCharge(boss, "0");

  ChargeSlotData data;
  for (int i = chargeSlots[client].Length - 1; i >= 0; i--)
  {
    chargeSlots[client].GetArray(i, data);

    // if charge is all used
    if (data.charges <= 0)
    {
      chargeSlots[client].Erase(i);
      continue;
    }

    // get the current time
    float currentTime = GetEngineTime();

    // update the HUD (this was moved from OnGameFrame() to here)
    if (currentTime >= flNextHud[client])
    {
      flNextHud[client] = currentTime + 0.1;
    }
    bool isOnCooldown = data.nextUse > currentTime;
    bool isNoRage     = data.ragecost > currentRage;

    if (data.hudMessage[0] != '\0')
    {
      float yPos = 0.21 + (0.03 * i);

      // set color based on whether ability is on cooldown
      SetHudTextParams(
        -1.0, yPos, 0.2,
        isOnCooldown || isNoRage ? data.cooldownColor[0] : data.hudColor[0],
        isOnCooldown || isNoRage ? data.cooldownColor[1] : data.hudColor[1],
        isOnCooldown || isNoRage ? data.cooldownColor[2] : data.hudColor[2],
        255, 0, 0.0, 0.0, 0.0);

      // show cooldown timer if ability is on cooldown
      if (isOnCooldown)
      {
        char format[128];
        Format(format, sizeof(format), data.hudMessage, data.charges);
        ShowSyncHudText(client, hChargeHud[client][i], "%s (%.1fs)", format, data.nextUse - currentTime);
      }
      // show rage cost if doesnt have enough rage
      else if (isNoRage)
      {
        char format[128];
        Format(format, sizeof(format), data.hudMessage, data.charges);
        ShowSyncHudText(client, hChargeHud[client][i], "%s (Required %d RAGE)", format, RoundToNearest(data.ragecost));
      }
      else
      {
        ShowSyncHudText(client, hChargeHud[client][i], data.hudMessage, data.charges);
      }
    }

    // this is for checking button mode
    if (isOnCooldown)
      continue;  // skip if ability is on cooldown

    // check button press based on button mode
    bool button;
    switch (data.buttonMode)
    {
      case 1: button = (buttons & IN_ATTACK2) != 0;  // Right click
      case 2: button = (buttons & IN_RELOAD) != 0;   // Reload
      case 3: button = (buttons & IN_ATTACK3) != 0;  // Special attack
    }

    if (button && data.charges > 0 && !isNoRage)
    {
      // use the ability
      FF2R_DoBossSlot(client, data.slotNumber);

      currentRage -= data.ragecost;

      // update charges cooldown and rage
      SetBossCharge(boss, "0", currentRage);
      data.charges--;
      data.nextUse = currentTime + data.cooldown;
      chargeSlots[client].SetArray(i, data);
    }
  }

  return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
  int victim   = GetClientOfUserId(GetEventInt(event, "userid"));
  int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

  if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
    return Plugin_Continue;

  if (attacker == victim)
    return Plugin_Continue;

  if (!IsValidClient(victim) || !IsValidClient(attacker))
    return Plugin_Continue;

  BossData boss = FF2R_GetBossData(attacker);
  if (!boss)
    return Plugin_Continue;

  AbilityData ability = boss.GetAbility("kill_class_doslot");
  if (!ability.IsMyPlugin())
    return Plugin_Continue;

  // check if the kill class equal to the one in the on kill class data
  int length = onKillClassSlot[attacker].Length;
  for (int i = length - 1; i >= 0; i--)
  {
    onKillClassSlotData data;
    onKillClassSlot[attacker].GetArray(i, data);
    if (data.classType == TF2_GetPlayerClass(victim))
    {
      // cooldown to the current time + the cooldown value
      if (GetEngineTime() > flOnKillCooldown[attacker])
      {
        flOnKillCooldown[attacker] = GetEngineTime() + boss.GetAbility("kill_class_doslot").GetFloat("cooldown", 0.0);
        // then trigger the slot
        FF2R_DoBossSlot(attacker, data.slotNumber);
      }
    }
  }

  return Plugin_Continue;
}

public float GetBossCharge(ConfigData cfg, const char[] slot)
{
  int length    = strlen(slot) + 7;
  char[] buffer = new char[length];
  Format(buffer, length, "charge%s", slot);
  return cfg.GetFloat(buffer);
}

public void SetBossCharge(ConfigData cfg, const char[] slot, float amount)
{
  int length    = strlen(slot) + 7;
  char[] buffer = new char[length];
  Format(buffer, length, "charge%s", slot);
  cfg.SetFloat(buffer, amount);
}

stock void ParseColorString(const char[] colorStr, int color[3])
{
  char splits[3][8];
  ExplodeString(colorStr, " ; ", splits, sizeof(splits), sizeof(splits[]));

  for (int i = 0; i < 3; i++)
  {
    color[i] = StringToInt(splits[i]);
  }
}

stock void GetClassStringByIndex(int index, char[] buffer, int maxlen)
{
  switch (index)
  {
    case 1:
      strcopy(buffer, maxlen, "scout");
    case 2:
      strcopy(buffer, maxlen, "sniper");
    case 3:
      strcopy(buffer, maxlen, "soldier");
    case 4:
      strcopy(buffer, maxlen, "demoman");
    case 5:
      strcopy(buffer, maxlen, "medic");
    case 6:
      strcopy(buffer, maxlen, "heavy");
    case 7:
      strcopy(buffer, maxlen, "pyro");
    case 8:
      strcopy(buffer, maxlen, "spy");
    case 9:
      strcopy(buffer, maxlen, "engineer");
    default:
      strcopy(buffer, maxlen, "unknown");
  }
}

stock bool IsValidClient(int clientIdx, bool replaycheck = true)
{
  if (clientIdx <= 0 || clientIdx > MaxClients)
    return false;

  if (!IsClientInGame(clientIdx) || !IsClientConnected(clientIdx))
    return false;

  if (GetEntProp(clientIdx, Prop_Send, "m_bIsCoaching"))
    return false;

  if (replaycheck && (IsClientSourceTV(clientIdx) || IsClientReplay(clientIdx)))
    return false;

  return true;
}