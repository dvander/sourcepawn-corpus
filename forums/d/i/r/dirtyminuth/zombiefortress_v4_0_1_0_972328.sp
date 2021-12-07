////////////////////////////////////////////////////////////////////////////////
//
//  Z O M B I E - F O R T R E S S - [TF2]
//
//  This is a rewrite of the original ZF mod.
//
//  Changelog:
//    v4.0.0.0 : Initial Re-release
//    v4.0.1.0 : Moved ZF enable check to OnConfigsExecuted()
//               Decreased default survivor percentage to 65%.
//               Decreased Rage cooldown from 20s to 10s.
//               Sentry ammo now slowly decays.
//               Minor cloak improvements.
//
//  Credits:
//    Sirot, original author of ZF. (http://www.zf.sovietgaming.net/)
//
////////////////////////////////////////////////////////////////////////////////

//#define ZF_DEBUG_MESSAGES

#pragma semicolon 1

//
// Includes
//
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

//
// Plugin Information
//
#define PLUGIN_VERSION "4.0.1.0"
public Plugin:myinfo = 
{
  name          = "Zombie Fortress",
  author        = "dirtyminuth (Recode), Sirot (Original)",
  description   = "Pits a team of survivors aganist an endless onslaught of zombies.",
  version       = PLUGIN_VERSION,
  url           = "http://forums.alliedmods.net/showthread.php?t=77762"
}

//
// Defines
//
#define ZF_SPAWNSTATE_REST 0
#define ZF_SPAWNSTATE_HUNGER 1
#define ZF_SPAWNSTATE_FRENZY 2

#define ZF_RAGESTATE_INACTIVE 0
#define ZF_RAGESTATE_ACTIVE_ANGRY 1
#define ZF_RAGESTATE_ACTIVE_TIRED 2

#define ZF_EVENT_PLAYERBUILTOBJECT_ID_DISPENSER 0
#define ZF_EVENT_PLAYERBUILTOBJECT_ID_TELEENT 1
#define ZF_EVENT_PLAYERBUILTOBJECT_ID_TELEXIT 2
#define ZF_EVENT_PLAYERBUILTOBJECT_ID_SENTRY 3

#define ZF_PLAYERCOND_KRITZ (1 << 11)

//
// Enumerations and Associated Structures
//
// ZF weapons
enum ZFWeaponType
{
  ZFWeapon_Bonk = 0,        // Weapon Slot 1, Item Index 46
  ZFWeapon_Sandman = 1,     // Weapon Slot 2, Item Index 44
  ZFWeapon_Sandvich = 2,    // Weapon Slot 1, Item Index 42
  ZFWeapon_DeadRinger = 3,  // Weapon Slot 4, Item Index 59
  ZFWeapon_SMG = 4,         // Weapon Slot 1, Item Index 16
  ZFWeapon_Rifle = 5,       // Weapon Slot 0, Item Index 14
  ZFWeapon_Huntsman = 6     // Weapon Slot 0, Item Index 56
};
new const zf_weaponSlot[7] = {1,2,1,4,1,0,0};
new const zf_weaponItemDefIndex[7] = {46,44,42,59,16,14,56};

// ZF classes
// Uses TFClassType enumeration values.
new const TFClassType:ZF_SURVIVORS[6] = {
  TFClass_Sniper, TFClass_Soldier, TFClass_DemoMan, 
  TFClass_Medic,  TFClass_Pyro,    TFClass_Engineer};
new const TFClassType:ZF_ZOMBIES[3] = {
  TFClass_Scout,  TFClass_Heavy,   TFClass_Spy};
new const ZF_VALIDSURVIVOR[10] = {0,0,1,1,1,1,0,1,0,1};
new const ZF_VALIDZOMBIE[10]   = {0,1,0,0,0,0,1,0,1,0};
    
// ZF teams
new zf_zombieTeam = _:TFTeam_Blue;
new zf_survivorTeam = _:TFTeam_Red;

// Global State
new zf_bEnabled;
new zf_bSetupStarted;
new zf_bRoundStarted;
new zf_spawnState;
new zf_spawnRestCounter;
new zf_spawnSurvivorsKilledCounter;
new zf_spawnZombiesKilledCounter;

// Client State
new zf_rageState[MAXPLAYERS+1];
new zf_critBonus[MAXPLAYERS+1];
new zf_hoardeBonus[MAXPLAYERS+1];
new zf_moraleBonus[MAXPLAYERS+1];

// Offsets
new zf_oClipAmmo;
new zf_oReserveAmmo;

// Global Timer Handles
new Handle:zf_tMain;
new Handle:zf_tHoarde;
new Handle:zf_tPluginReminder;

// Client Timer Handles
new Handle:zf_tForceRespawn[MAXPLAYERS+1];
new Handle:zf_tStripWeapons[MAXPLAYERS+1];
new Handle:zf_tRageCooldown[MAXPLAYERS+1];
new Handle:zf_tRageReady[MAXPLAYERS+1];
new Handle:zf_tMoraleBoost[MAXPLAYERS+1];

// Cvar Handles
new Handle:zf_cvForceOn;
new Handle:zf_cvRatio;

//
// Callbacks
//

public OnPluginStart()
{
  // Initialize state
  zf_bEnabled = false;
  zf_bSetupStarted = false;
  zf_bRoundStarted = false;
  
  // Initialize offsets
  zf_oClipAmmo = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
  zf_oReserveAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
  
  // Initialize handles
  zf_tMain = INVALID_HANDLE;
  zf_tHoarde = INVALID_HANDLE;
  zf_tPluginReminder = INVALID_HANDLE;
  zf_cvForceOn = INVALID_HANDLE;
  zf_cvRatio = INVALID_HANDLE; 

  // Register cvars
  CreateConVar("sm_zf_version", PLUGIN_VERSION, "Current Zombie Fortress Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
  zf_cvForceOn = CreateConVar("sm_zf_force_on", "1", "<0/1> Activate ZF for non-ZF maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  zf_cvRatio = CreateConVar("sm_zf_ratio", "0.65", "<0.01-1.00> Percentage of players that start as survivors.", FCVAR_PLUGIN, true, 0.01, true, 1.0); 
  
  // Config
  AutoExecConfig(true, "plugin_zf");
      
  // Hook events
  HookEvent("teamplay_round_start", event_RoundStart);
  HookEvent("teamplay_setup_finished", event_RoundSetupEnd);
  HookEvent("teamplay_round_win", event_RoundEnd);
  HookEvent("player_spawn", event_PlayerSpawn);  
  HookEvent("player_death", event_PlayerDeath);
  HookEvent("player_say", event_PlayerChat);
  HookEvent("player_builtobject", event_PlayerBuiltObject);
    
  // Register SM admin commands
  RegAdminCmd("sm_zf_enable", command_zfEnable, ADMFLAG_GENERIC, "Activates the Zombie Fortress plugin");
  RegAdminCmd("sm_zf_disable", command_zfDisable, ADMFLAG_GENERIC, "Deactivates the Zombie Fortress plugin");
}

public OnMapStart()
{
#if defined ZF_DEBUG_MESSAGES        
  LogMessage("[ZF DEBUG] OnMapStart()");
#endif
}

public OnMapEnd()
{
#if defined ZF_DEBUG_MESSAGES        
  LogMessage("[ZF DEBUG] OnMapEnd()");
#endif
} 

public OnConfigsExecuted()
{
#if defined ZF_DEBUG_MESSAGES        
  LogMessage("[ZF DEBUG] OnConfigsExecuted()");
#endif

  // 1. Determine whether to enable ZF.
  //    For "zf_" prefixed maps, enable ZF.
  //    For non-"zf_" prefixed maps, disable ZF unless sm_zf_force_on is set.
  decl String:mapname[4];
  GetCurrentMap(mapname, sizeof(mapname));
  if(strncmp(mapname, "zf_", 3, false) == 0)
  {
    zfEnable();
  }
  else
  {
    if(GetConVarBool(zf_cvForceOn))
    {
      zfEnable();
    }
    else
    {
      zfDisable();
    }
  }
  
}  

public OnClientConnected(client)
{ 
  if(zf_bEnabled)
  { 
    resetClientState(client);
  }
}

public OnClientPutInServer(client)
{
  if(zf_bEnabled)
  {
    CreateTimer(10.0, timer_initialHelp, client);
  }
}

public OnClientDisconnect(client)
{
  if(zf_bEnabled)
  { 
    resetClientState(client);
  }
}

public OnGameFrame()
{
  // 1. Limit spy cloak.
  for(new i = 1; i < MaxClients; i++)
  {
    if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      new Float:val = GetEntPropFloat(i, Prop_Send, "m_flCloakMeter");
      if(val > 80.0)
        SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 80.0);
    }
  }
}

//
// SM Commands
//
public Action:command_zfEnable (client, args)
{ 
  if(!zf_bEnabled)
  {
    zfEnable();
    ServerCommand("mp_restartround 5");  
  }
}

public Action:command_zfDisable (client, args)
{
  if(zf_bEnabled)
  {
    zfDisable();
    ServerCommand("mp_restartround 5");  
  }  
}

zfEnable()
{     
  zf_bEnabled = true;
  zf_bSetupStarted = false;
  zf_bRoundStarted = false;
  
  for(new i = 0; i <= MAXPLAYERS; i++)
  {
    resetClientState(i);
  }
    
  // Adjust gameplay CVars.
  ServerCommand("mp_autoteambalance 0");
  ServerCommand("mp_teams_unbalance_limit 0");
  // Engineer
  ServerCommand("sm_cvar tf_obj_upgrade_per_hit 0"); // Locked
  ServerCommand("sm_cvar tf_sentrygun_metal_per_shell 201"); // Locked
  // Medic
  ServerCommand("sm_cvar weapon_medigun_charge_rate 30"); // Locked
  ServerCommand("sm_cvar weapon_medigun_chargerelease_rate 6"); // Locked
  ServerCommand("sm_cvar tf_max_health_boost 1.25"); // Locked
  ServerCommand("sm_cvar tf_boost_drain_time 300"); // Locked
  // Spy
  ServerCommand("sm_cvar tf_spy_invis_time 0.5"); // Locked 
  ServerCommand("sm_cvar tf_spy_invis_unstealth_time 0.75"); // Locked 
  ServerCommand("sm_cvar tf_spy_cloak_no_attack_time 1.0"); // Locked 
    
  // [Re]Enable periodic timers.
  if(zf_tMain != INVALID_HANDLE)
  {      
    KillTimer(zf_tMain);
  }
  if(zf_tHoarde != INVALID_HANDLE)
  {
    KillTimer(zf_tHoarde);
  }
  if(zf_tPluginReminder != INVALID_HANDLE)
  {
    KillTimer(zf_tPluginReminder);
  }
    
  zf_tMain = CreateTimer(1.0, timer_main, _, TIMER_REPEAT);  
  zf_tHoarde = CreateTimer(5.0, timer_hoarde, _, TIMER_REPEAT);   
  zf_tPluginReminder = CreateTimer(180.0, timer_pluginReminder, _, TIMER_REPEAT); 
}

zfDisable()
{  
  zf_bEnabled = false;
  zf_bSetupStarted = false;
  zf_bRoundStarted = false;  
    
  // Adjust gameplay CVars.
  ServerCommand("mp_autoteambalance 1");
  ServerCommand("mp_teams_unbalance_limit 1");
  // Engineer
  ServerCommand("sm_cvar tf_obj_upgrade_per_hit 25"); // Locked
  ServerCommand("sm_cvar tf_sentrygun_metal_per_shell 1"); // Locked
  // Medic
  ServerCommand("sm_cvar weapon_medigun_charge_rate 40"); // Locked
  ServerCommand("sm_cvar weapon_medigun_chargerelease_rate 8"); // Locked
  ServerCommand("sm_cvar tf_max_health_boost 1.5"); // Locked
  ServerCommand("sm_cvar tf_boost_drain_time 15"); // Locked 
  // Spy
  ServerCommand("sm_cvar tf_spy_invis_time 1.0"); // Locked 
  ServerCommand("sm_cvar tf_spy_invis_unstealth_time 2.0"); // Locked 
  ServerCommand("sm_cvar tf_spy_cloak_no_attack_time 2.0"); // Locked 
      
  // Disable periodic timers.
  if(zf_tMain != INVALID_HANDLE)
  {      
    KillTimer(zf_tMain);
    zf_tMain = INVALID_HANDLE;
  }
  if(zf_tHoarde != INVALID_HANDLE)
  {
    KillTimer(zf_tHoarde);
    zf_tHoarde = INVALID_HANDLE;
  }
  if(zf_tPluginReminder != INVALID_HANDLE)
  {
    KillTimer(zf_tPluginReminder);
    zf_tPluginReminder = INVALID_HANDLE;
  }

  // Enable resupply lockers.
  new index = -1;
  while((index = FindEntityByClassname(index, "func_regenerate")) != -1)
    AcceptEntityInput(index, "Enable");
  
  // Set medpacks to both teams.
  index = -1;
  while((index = FindEntityByClassname(index, "item_healthkit_full")) != -1)
    SetEntProp(index, Prop_Send, "m_iTeamNum", 0);
  index = -1;
  while((index = FindEntityByClassname(index, "item_healthkit_medium")) != -1)
    SetEntProp(index, Prop_Send, "m_iTeamNum", 0);
  index = -1;
  while((index = FindEntityByClassname(index, "item_healthkit_small")) != -1)
    SetEntProp(index, Prop_Send, "m_iTeamNum", 0);    
}

//
// Commands
//

public Action:OnClientCommand(client, args)
{ 
  decl String:cmd0[32], String:cmd1[32], String:cmd2[32];
    
  if(!zf_bEnabled) return Plugin_Continue;

  // Get command arguments.
  GetCmdArg(0, cmd0, sizeof(cmd0));
  GetCmdArg(1, cmd1, sizeof(cmd1));
  GetCmdArg(2, cmd2, sizeof(cmd2));

#if defined ZF_DEBUG_MESSAGES        
  LogMessage("[ZF DEBUG] OnClientCommand(): %d [%s] [%s] [%s]", client, cmd0, cmd1, cmd2);
#endif
    
  // 1. Capture "jointeam" commands.
  //    Prevent player from joining RED / invalid team after setup starts.
  if(StrEqual(cmd0, "jointeam", false))
  {
    if(zf_bSetupStarted)
    {
      if(StrEqual(cmd1, "red", false) || 
         StrEqual(cmd1, "auto", false))
      {
        ChangeClientTeam(client, zf_zombieTeam);
        ShowVGUIPanel(client, "class_blue");
        return Plugin_Handled;
      }
      else if(StrEqual(cmd1, "blue", false) || 
              StrEqual(cmd1, "spectate", false))
      {
        return Plugin_Continue;
      }
      else
      {
        return Plugin_Handled;
      }
    }
  }

  // 2. Capture "joinclass" commands.
  //    Notify player upon selecting an invalid class.
  else if(StrEqual(cmd0, "joinclass", false))
  {
    if(GetClientTeam(client) == zf_zombieTeam)   
    {
      if(!(StrEqual(cmd1, "scout", false) ||
           StrEqual(cmd1, "spy", false)  || 
           StrEqual(cmd1, "heavyweapons", false)))
      {
        PrintToChat(client, "\x05[ZF]\x01 Valid zombies: Scout, Heavy, Spy.");
      }
      return Plugin_Continue;
    }
    else if(GetClientTeam(client) == zf_survivorTeam)
    {
      if(zf_bRoundStarted)
      {
        PrintToChat(client, "\x05[ZF]\x01 Survivors can't change classes during a round!");
        return Plugin_Handled;          
      }
      else
      {
        if(!(StrEqual(cmd1, "soldier", false) || 
             StrEqual(cmd1, "pyro", false) || 
             StrEqual(cmd1, "demoman", false) || 
             StrEqual(cmd1, "engineer", false) || 
             StrEqual(cmd1, "medic", false) || 
             StrEqual(cmd1, "sniper", false)))
        {
          PrintToChat(client, "\x05[ZF]\x01 Valid survivors: Soldier, Pyro, Demo, Engineer, Medic, Sniper.");   
        }        
        return Plugin_Continue;    
      }
    }
  }
      
  // 3. Capture "voicemenu 0 0" (Call for Medic) commands.
  //    Activate zombie rage ability (150% health, increased speed). Can't
  //    be activated below full health or if ability is currently active.
  //    Cooldown effect goes active after 20 seconds, and ability recharges
  //    after 30 seconds.
  else if(StrEqual(cmd0, "voicemenu") && StrEqual(cmd1, "0") && StrEqual(cmd2, "0"))
  {
    if(IsPlayerAlive(client))
    {  
      if(GetClientTeam(client) == zf_zombieTeam)
      {     
        new clientHealth = GetClientHealth(client);
        new clientMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");       

        if((zf_rageState[client] == ZF_RAGESTATE_INACTIVE) && (clientHealth >= clientMaxHealth))
        {
          zf_rageState[client] = ZF_RAGESTATE_ACTIVE_ANGRY;
          zf_tRageCooldown[client] = CreateTimer(20.0, timer_rageCooldown, client);
          zf_tRageReady[client] = CreateTimer(30.0, timer_rageReady, client);
          
          SetEntityHealth(client, RoundToCeil(clientMaxHealth * 1.5));
                    
          ClientCommand(client, "voicemenu 2 1");
          PrintHintText(client, "Rage Activated!");  
        }
        else
        {
          ClientCommand(client, "voicemenu 2 5");
          PrintHintText(client, "Can't Activate Rage!"); 
        }
            
        return Plugin_Handled;
      }
    }
  }
  
  return Plugin_Continue;
}

//
// TF2 Gameplay Events
//

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
  new clientTeam = GetClientTeam(client);
  new clientCond = GetEntProp(client, Prop_Send, "m_nPlayerCond");  
  
  // 1. Being kritzed overrides other crit calculations.
  if(clientCond & ZF_PLAYERCOND_KRITZ) return Plugin_Continue;
  
  // 2a. Handle zombie crit bonus.
  if(clientTeam == zf_zombieTeam)
  {
    result = (zf_critBonus[client] > GetRandomInt(0, 99));
    return Plugin_Handled;  
  }  
  // 2b. Handle survivor morale bonus.
  else if(clientTeam == zf_survivorTeam)
  {
    if(zf_moraleBonus[client] >= 3)
    {
      result = true;
      return Plugin_Handled;
    }    
  }
  
  return Plugin_Continue;
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  decl players[MAXPLAYERS];
  decl playerCount;
  decl playerTeam;
  decl surCount;
 
  if(!zf_bEnabled) return Plugin_Continue;

#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: event_RoundStart()");
#endif   
    
  zf_bSetupStarted = true;
  zf_bRoundStarted = false;
  
  // 1a. Find all active players.
  playerCount = 0;
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsValidEntity(i) && IsClientInGame(i))
    {
      playerTeam = GetClientTeam(i);
      if((playerTeam == zf_survivorTeam) || (playerTeam == zf_zombieTeam))
      {
        players[playerCount++] = i;
      }
    }
  }
    
  // 1b. Calculate team sizes. 
  //     Note: at least one survivor must exist. 
  surCount = RoundToFloor(playerCount*GetConVarFloat(zf_cvRatio));
  if((surCount == 0) && (playerCount > 0))
  {
    surCount = 1;
  }  
  
  // 1c. Randomize active player array.
  for(new i = 1; i < playerCount; i++)
  {
    new j = GetRandomInt(0, i);
    new temp = players[i];
    players[i] = players[j];
    players[j] = temp;
  }

  // 1d. Assign active players to survivor and zombie teams.
  for(new i = 0; i < surCount; i++)
  {    
    spawnClient(players[i], zf_survivorTeam);   
  }
  for(new i = surCount; i < playerCount; i++)
  {
    spawnClient(players[i], zf_zombieTeam);   
  }
  
  // 2. Disable all resupply cabinets.
  new index = -1;
  while((index = FindEntityByClassname(index, "func_regenerate")) != -1)
    AcceptEntityInput(index, "Disable");

  // 3. Set medpacks to survivors only.
  index = -1;
  while((index = FindEntityByClassname(index, "item_healthkit_full")) != -1)
    SetEntProp(index, Prop_Send, "m_iTeamNum", zf_survivorTeam);
  index = -1;
  while((index = FindEntityByClassname(index, "item_healthkit_medium")) != -1)
    SetEntProp(index, Prop_Send, "m_iTeamNum", zf_survivorTeam);
  index = -1;
  while((index = FindEntityByClassname(index, "item_healthkit_small")) != -1)
    SetEntProp(index, Prop_Send, "m_iTeamNum", zf_survivorTeam);   
        
  // 4. Initialize zombie spawn state.
  zf_spawnState = ZF_SPAWNSTATE_HUNGER;
  zf_spawnSurvivorsKilledCounter = 1;
  setTeamRespawnTime(zf_zombieTeam, 10.0);

  // 5. Remove ammopacks and ragdolls resulting from initial team balance.
  CreateTimer(1.0, timer_removeDeathEnts);
  
  return Plugin_Continue;
}

public Action:event_RoundSetupEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;
  
#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: event_RoundSetupEnd()");
#endif  
    
  zf_bSetupStarted = true;
  zf_bRoundStarted = true;
                
  return Plugin_Continue;
}

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;
 
#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: event_RoundEnd()");
#endif  
   
  zf_bSetupStarted = false;
  zf_bRoundStarted = false;
            
  return Plugin_Continue;
}
 
public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{   
  if(!zf_bEnabled) return Plugin_Continue;  
      
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new clientTeam = GetClientTeam(client);  
  new TFClassType:clientClass = TF2_GetPlayerClass(client);
    
#if defined ZF_DEBUG_MESSAGES      
  LogMessage("[ZF DEBUG]: event_PlayerSpawn() %d %d %d", client, clientTeam, clientClass);
#endif  

  // 1. Reset client state.
  resetClientState(client);

   // 2. Prevent players spawning on survivors if round has started.
   //    Prevent players spawning on survivors as an invalid class.
   //    Prevent players spawning on zombies as an invalid class.
  if(clientTeam == zf_survivorTeam)
  {
    if(zf_bRoundStarted)
    {
      spawnClient(client, zf_zombieTeam);
      return Plugin_Continue;
    }
    if(!validSurvivor(clientClass))
    {
      spawnClient(client, zf_survivorTeam); 
      return Plugin_Continue;
    }      
  }
  else if(clientTeam == zf_zombieTeam)
  {
    if(!validZombie(clientClass))
    {
      spawnClient(client, zf_zombieTeam); 
      return Plugin_Continue;
    }
  }   

  // 3. Handle class weapon and speed restrictions. 
  if(zf_tStripWeapons[client])
  {
    KillTimer(zf_tStripWeapons[client]);
  }  
  zf_tStripWeapons[client] = CreateTimer(0.1, timer_stripWeapons, client); 
    
  return Plugin_Continue;  
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;

#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: event_PlayerDeath()");
#endif    
    
  if(!zf_bRoundStarted) return Plugin_Continue;
  
  decl victim;       
  decl killers[2];
  decl killer;  
  decl TFClassType:killerClass;
  decl killerHealth;
  decl killerMaxHealth;
  decl ammo;
  
  // 1. Handle survivor death rules.
  victim = GetClientOfUserId(GetEventInt(event, "userid"));
  killers[0] = GetClientOfUserId(GetEventInt(event, "attacker")); 
  killers[1] = GetClientOfUserId(GetEventInt(event, "assister"));       
  if(GetClientTeam(victim) == zf_survivorTeam)
  {
    // Note if survivor killed by zombie.
    killer = killers[0];
    if((killer > 0) && IsValidEntity(killer))
    {
      if(GetClientTeam(killer) == zf_zombieTeam)
      {
        zf_spawnSurvivorsKilledCounter--;
      }
    }
    
    // Transfer player to zombie team.
    CreateTimer(6.0, timer_Zombify, victim);
  }
  
  // 2. Handle zombie death rules.
  else if(GetClientTeam(victim) == zf_zombieTeam)
  {      
    // Note if zombie killed by survivor.
    killer = killers[0];
    if((killer > 0) && IsValidEntity(killer))
    {
      if(GetClientTeam(killer) == zf_survivorTeam)
      {
        zf_spawnZombiesKilledCounter--;
      }
    }
    
    if(killers[0] == killers[1]) killers[1] = 0; // Avoid rare self assist.    
    for(new i = 0; i < 2; i++)
    {
      killer = killers[i];      
      if(killer <= 0) continue;        
              
      if(IsValidEntity(killer) && IsClientInGame(killer) && IsPlayerAlive(killer))
      {                  
        // 2a. Handle ammo kill bonuses.
        //     Soldiers receive 2 rockets per kill.
        //     Demomen receive 2 pipes per kill.
        //     Snipers receive 5 rifle / 2 arrows per kill.
        killerClass = TF2_GetPlayerClass(killer);        
        switch(killerClass)
        {
          case TFClass_Soldier:
          {
            ammo = GetEntData(killer, (zf_oReserveAmmo + 4));
            ammo = min((ammo + 2), 20);
            SetEntData(killer, (zf_oReserveAmmo + 4), ammo);
          }
          case TFClass_DemoMan:
          {
            ammo = GetEntData(killer, (zf_oReserveAmmo + 4));
            ammo = min((ammo + 2), 16);
            SetEntData(killer, (zf_oReserveAmmo + 4), ammo);            
          }
          case TFClass_Sniper:
          {     
            if(isEquipped(killer, ZFWeapon_Rifle))
            {
              ammo = GetEntData(killer, (zf_oReserveAmmo + 4)); 
              ammo = min((ammo + 5), 25);
              SetEntData(killer, (zf_oReserveAmmo + 4), ammo);
            }
            else if(isEquipped(killer, ZFWeapon_Huntsman))
            {
              ammo = GetEntData(killer, (zf_oReserveAmmo + 4)); 
              ammo = min((ammo + 2), 12);
              SetEntData(killer, (zf_oReserveAmmo + 4), ammo);
            }
          }
        } // switch
        
        // 2b. Handle morale bonuses.
        //     Survivors can go on kill streaks, where subsequent kills are
        //     less than 6 seconds apart. Upon reaching 3 kills in a row or
        //     greater, activate morale bonus (100% crits and 25 health per
        //     kill).      
        if(zf_tMoraleBoost[killer])
        {
          KillTimer(zf_tMoraleBoost[killer]);
        }
        zf_tMoraleBoost[killer] = CreateTimer(6.0, timer_moraleBoost, killer);
          
        zf_moraleBonus[killer]++;
        if(zf_moraleBonus[killer] == 3)
        {
          PrintHintText(killer, "Morale increased!");
        }
        if(zf_moraleBonus[killer] > 3)
        {
          killerHealth = GetClientHealth(killer);
          killerMaxHealth = GetEntProp(killer, Prop_Data, "m_iMaxHealth");
          if(killerHealth < killerMaxHealth)
          {
            killerHealth = min(killerHealth + 25, killerMaxHealth);
            SetEntityHealth(killer, killerHealth);
          }
        }
                  
      } // if         
    } // for 
    
    // 2c. Remove dropped ammopacks from zombies.
    new index = -1; 
    while ((index = FindEntityByClassname(index, "tf_ammo_pack")) != -1)
    {
      if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == victim)
        AcceptEntityInput(index, "Kill");
    }
  
  } // if    
  
  // 3. Reset client state.
  resetClientState(victim);
    
  return Plugin_Continue;
}

public Action:event_PlayerChat(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;
  
  decl String:chatText[256];
  decl client;
  
  GetEventString(event, "text", chatText, sizeof(chatText));
  client = GetClientOfUserId(GetEventInt(event, "userid"));
  
  if(StrEqual(chatText, "zf_help", false))
  {
    help_printZFInfoPanel(client);
    return Plugin_Handled;
  }
  else if(StrEqual(chatText, "zf_team", false))
  {
    help_printTeamInfoPanel(client,GetClientTeam(client));
    return Plugin_Handled;
  }
  else if(StrEqual(chatText, "zf_class", false))
  {
    help_printClassInfoPanel(client,TF2_GetPlayerClass(client));
    return Plugin_Handled;
  }

  return Plugin_Continue; 
}

public Action:event_PlayerBuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;

  new index = GetEventInt(event, "index");
  new object = GetEventInt(event, "object");

  // 1. Handle dispenser rules.
  //    Disable dispensers when they begin construction.
  //    Increase max health to 250 (default level 1 is 150).      
  if(object == ZF_EVENT_PLAYERBUILTOBJECT_ID_DISPENSER)
  {
    SetEntProp(index, Prop_Send, "m_bDisabled", 1);
    SetEntProp(index, Prop_Send, "m_iMaxHealth", 250);
  }

  return Plugin_Continue;     
}

//
// Timer Callbacks
//

// Periodic @ 1Hz.
public Action:timer_main(Handle:timer)
{    
  if(!zf_bEnabled) return Plugin_Continue;
  
  handle_survivorAbilities();
  handle_zombieAbilities();      

  if(!zf_bRoundStarted) return Plugin_Continue;  
  
  handle_winCondition();
  handle_spawnState();
          
  return Plugin_Continue;
}

// Periodic @ 1/5th Hz.
public Action:timer_hoarde(Handle:timer)
{
  if(!zf_bEnabled) return Plugin_Continue;
  
  handle_hoardeBonus();
    
  return Plugin_Continue;  
}

// Periodic @ 1/150th Hz.
public Action:timer_pluginReminder(Handle:timer)
{
  if(!zf_bEnabled) return Plugin_Continue;  
  
  help_printZFInfoChat(0);
  
  return Plugin_Continue;
}

public Action:timer_forceRespawn(Handle:timer, Handle:dataPack)
{    
  decl TFClassType:nextClientClass;
       
  ResetPack(dataPack);
  new client = ReadPackCell(dataPack);
  new nextClientTeam = ReadPackCell(dataPack);
  CloseHandle(dataPack);   
   
#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: timer_forceRespawn() %d %d", client, nextClientTeam); 
#endif    

  // 1. Prevent players from spawning if they're on an invalid team.
  //    Prevent players from spawning as an invalid class.
  if(IsValidEntity(client) && IsClientInGame(client))
  {    
    if((nextClientTeam == zf_zombieTeam) || (nextClientTeam == zf_survivorTeam))
    {
      nextClientClass = TF2_GetPlayerClass(client);
      if((nextClientTeam == zf_zombieTeam) && !validZombie(nextClientClass))
      {
        nextClientClass = randomZombie();
      }
      if((nextClientTeam == zf_survivorTeam) && !validSurvivor(nextClientClass))
      {
        nextClientClass = randomSurvivor();    
      }
   
      TF2_SetPlayerClass(client, nextClientClass, false, true);   
      ChangeClientTeam(client, nextClientTeam);      
      TF2_RespawnPlayer(client);      
    }
  }
  
  zf_tForceRespawn[client] = INVALID_HANDLE;
  
  return Plugin_Continue; 
}

public Action:timer_stripWeapons(Handle:timer, any:client)
{      
  decl clientTeam;
  decl TFClassType:clientClass;
  
#if defined ZF_DEBUG_MESSAGES  
  LogMessage("[ZF DEBUG]: timer_stripWeapons() %d", client); 
#endif   
 
  if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
  {    
    clientTeam = GetClientTeam(client);
    clientClass = TF2_GetPlayerClass(client);
    
    // 1. Handle class weapon restrictions
    if(clientTeam == zf_zombieTeam)
    {
      switch(clientClass)
      {
        // 1a. Remove Scattergun(0), FAN(0), Pistol(1), BONK!(1).          
        //     Keep Bat(2), Sandman(2).
        case TFClass_Scout:
        {
          TF2_RemoveWeaponSlot(client, 0);  
          TF2_RemoveWeaponSlot(client, 1);           
        }
        // 1b. Remove Minigun(0), Natascha(0), Shotgun(1), Sandwich(1).
        //     Keep Fists(2), KGB(2).
        case TFClass_Heavy:
        {
          TF2_RemoveWeaponSlot(client, 0);         
          TF2_RemoveWeaponSlot(client, 1);         
        }
        // 1c. Remove Revolver(0), Ambassador(0), Sapper(1), Disguise Kit(3), Dead Ringer(4).
        //     Keep Knife(2), Invis Watch(4), C&D(4).
        case TFClass_Spy:
        {
          TF2_RemoveWeaponSlot(client, 0);                
          TF2_RemoveWeaponSlot(client, 1);       
          TF2_RemoveWeaponSlot(client, 3);
          if(isEquipped(client,ZFWeaponType:ZFWeapon_DeadRinger))
            TF2_RemoveWeaponSlot(client, 4);
        }
      }
  
      // 2. Switch to melee slot.
      new weapon = GetPlayerWeaponSlot(client, 2);
      SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon); 
    }
    
    // 3. Handle class speed restrictions.  
    SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", getClassBaseSpeed(clientClass));    
  }

  zf_tStripWeapons[client] = INVALID_HANDLE;
  
  return Plugin_Continue; 
}

public Action:timer_rageCooldown(Handle:timer, any:client)
{
  if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
  {    
    zf_rageState[client] = ZF_RAGESTATE_ACTIVE_TIRED;
    PrintHintText(client, "Rage has made you tired!");
  }
  
  zf_tRageCooldown[client] = INVALID_HANDLE;
  
  return Plugin_Continue; 
}

public Action:timer_rageReady(Handle:timer, any:client)
{
  if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
  {    
    zf_rageState[client] = ZF_RAGESTATE_INACTIVE;
    PrintHintText(client, "Rage is ready!");
  }
  
  zf_tRageReady[client] = INVALID_HANDLE;
  
  return Plugin_Continue; 
}

public Action:timer_moraleBoost(Handle:timer, any:client)
{
  if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
  {   
    if(zf_moraleBonus[client] >= 3)
    {
      PrintHintText(client, "Morale reset!");
    }
    zf_moraleBonus[client] = 0;
  }
  
  zf_tMoraleBoost[client] = INVALID_HANDLE;
  
  return Plugin_Continue;   
}

public Action:timer_initialHelp(Handle:timer, any:client)
{  
  // Wait until client is in game before printing initial help text.
  if(IsValidEntity(client))
  {
    if(IsClientInGame(client))
    {
      help_printZFInfoChat(client);
    }
    else
    {
      CreateTimer(10.0, timer_initialHelp, client);  
    }
  }
  
  return Plugin_Continue; 
}

public Action:timer_removeDeathEnts(Handle:timer)
{
  // 1. Remove all dropped ammopacks.
  new index = -1;
  while ((index = FindEntityByClassname(index, "tf_ammo_pack")) != -1)
      AcceptEntityInput(index, "Kill");
  
  // 2. Remove all ragdolls.
  index = -1;
  while ((index = FindEntityByClassname(index, "tf_ragdoll")) != -1)
      AcceptEntityInput(index, "Kill");
      
  return Plugin_Continue; 
}

public Action:timer_Zombify(Handle:timer, any:client)
{
  
#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: timer_Zombify() %d", client); 
#endif
    
  if(IsValidEntity(client) && IsClientInGame(client))
  {
    PrintToChat(client, "\x05[ZF]\x01 You have perished, zombifying....");
    spawnClient(client, zf_zombieTeam);
  }
}

//
// Routines
//
handle_winCondition()
{
  decl bool:anySurvivorAlive;
  decl index;
  
  // 1. Check for any survivors that are still alive.
  anySurvivorAlive = false;
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      if(GetClientTeam(i) == zf_survivorTeam)
      {
        anySurvivorAlive = true;
        break;
      }
    }
  }
  
  // 2. If no survivors are alive and at least 1 zombie is playing,
  //    end round with zombie win.
  if(!anySurvivorAlive && (GetTeamClientCount(zf_zombieTeam) > 0))
  {
    index = FindEntityByClassname(-1, "game_round_win");
    if (index == -1)
    {
      index = CreateEntityByName("game_round_win");
      DispatchSpawn(index);    
    }
    SetVariantInt(zf_zombieTeam);
    AcceptEntityInput(index, "SetTeam");
    AcceptEntityInput(index, "RoundWin");    
  }
}

handle_spawnState()
{
  // 1. Handle zombie spawn times. Zombie spawn times can have one of three
  //    states: Rest (long spawn times), Hunger (medium spawn times), and
  //    Frenzy (short spawn times).
  switch(zf_spawnState)
  {
    // 1a. Rest state (long spawn times). Transition to Hunger
    //     state after rest timer reaches zero.
    case ZF_SPAWNSTATE_REST:    
    {
      zf_spawnRestCounter--;
      if(zf_spawnRestCounter <= 0)
      {
        zf_spawnState = ZF_SPAWNSTATE_HUNGER;
        zf_spawnSurvivorsKilledCounter = 1;        
        PrintToChatAll("\x05[ZF SPAWN]\x01 Zombies Hunger..."); 
        setTeamRespawnTime(zf_zombieTeam, 10.0);                
      }
    }
    
    // 1b. Hunger state (medium spawn times). Transition to Frenzy
    //     state after one survivor is killed.
    case ZF_SPAWNSTATE_HUNGER:
    {
      if(zf_spawnSurvivorsKilledCounter <= 0)
      {
        zf_spawnState = ZF_SPAWNSTATE_FRENZY;
        zf_spawnZombiesKilledCounter = (2 * GetTeamClientCount(zf_zombieTeam));
        PrintToChatAll("\x05[ZF SPAWN]\x01 Zombies are Frenzied!"); 
        setTeamRespawnTime(zf_zombieTeam, 1.0);        
      }
    }
    
    // 1c. Frenzy state (short spawn times). Transition to Rest
    //     state after a given number of zombies are killed.
    case ZF_SPAWNSTATE_FRENZY:
    {
      if(zf_spawnZombiesKilledCounter <= 0)
      {
        zf_spawnState = ZF_SPAWNSTATE_REST;
        zf_spawnRestCounter = min(45, (3 * GetTeamClientCount(zf_zombieTeam)));
        PrintToChatAll("\x05[ZF SPAWN]\x01 Zombies are Resting..."); 
        setTeamRespawnTime(zf_zombieTeam, 20.0);        
      }
    }
  } 
}
  
handle_survivorAbilities()
{
  decl clientWeapon;
  decl reserveAmmo;
  decl clipAmmo;
  decl ammoAdj;
  
  decl index;
  decl sentryAmmo;
  decl sentryMaxHealth;
    
  // 1. Handle survivor weapon rules.
  //    SMG doesn't have to reload. 
  //    Syringe gun / blutsauger don't have to reload. 
  //    Flamethrower / backburner ammo limited to 100.
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      if(GetClientTeam(i) == zf_survivorTeam)
      {
        switch(TF2_GetPlayerClass(i))
        {
          case TFClass_Sniper:
          {
            clientWeapon = GetPlayerWeaponSlot(i, 1);            
            if((clientWeapon > 0) && isEquipped(i, ZFWeapon_SMG))
            {      
              reserveAmmo = GetEntData(i, (zf_oReserveAmmo + 8));              
              clipAmmo = GetEntData(clientWeapon, zf_oClipAmmo);
              ammoAdj = min((25 - clipAmmo), reserveAmmo);            
            
              if(ammoAdj > 0)
              {
                SetEntData(i, (zf_oReserveAmmo + 8), (reserveAmmo - ammoAdj));
                SetEntData(clientWeapon, zf_oClipAmmo, (clipAmmo + ammoAdj));              
              }
            }
          }
          
          case TFClass_Medic: 
          {
            clientWeapon = GetPlayerWeaponSlot(i, 0);
            if(clientWeapon > 0)
            { 
              reserveAmmo = GetEntData(i, (zf_oReserveAmmo + 4));              
              clipAmmo = GetEntData(clientWeapon, zf_oClipAmmo);
              ammoAdj = min((40 - clipAmmo), reserveAmmo);            
                
              if(ammoAdj > 0)
              {
                SetEntData(i, (zf_oReserveAmmo + 4), (reserveAmmo - ammoAdj));
                SetEntData(clientWeapon, zf_oClipAmmo, (clipAmmo + ammoAdj));              
              }
            }            
          }
          
          case TFClass_Pyro:
          {
            reserveAmmo = GetEntData(i, (zf_oReserveAmmo + 4));                         

            if(reserveAmmo > 100)
            {
              ammoAdj = max((reserveAmmo - 10),100);
              SetEntData(i, (zf_oReserveAmmo + 4), ammoAdj);            
            }    
          }          
        } 
      }
    }
  }

  // 2. Handle sentry rules.
  //    Sentry ammo limited to 60, and slowly decays.
  //    Sentries self destruct when they run out of ammo.
  index = -1;
  while ((index = FindEntityByClassname(index, "obj_sentrygun")) != -1)
  {            
    if(GetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed") == 1.0)
    {  
      sentryAmmo = GetEntProp(index, Prop_Send, "m_iAmmoShells");
      sentryMaxHealth = GetEntProp(index, Prop_Send, "m_iMaxHealth");
      if(sentryAmmo > 0)
      {
        sentryAmmo = min(60, (sentryAmmo - 1));
        SetEntProp(index, Prop_Send, "m_iAmmoShells", sentryAmmo);
      }
      else
      {
        SetVariantInt(sentryMaxHealth);
        AcceptEntityInput(index, "RemoveHealth");
      }
    }
  }    
}

handle_zombieAbilities()
{
  decl TFClassType:clientClass;
  decl clientHealth;
  decl clientMaxHealth;
  decl Float:clientSpeed;  
  decl critBonus;
  decl regenBonus;
  
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      if(GetClientTeam(i) == zf_zombieTeam)
      {      
        clientClass = TF2_GetPlayerClass(i);
        clientHealth = GetClientHealth(i);
        clientMaxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
                
        // 1. Handle zombie regeneration.
        //    Zombies regenerate health based on class and number of nearby
        //    zombies (hoarde bonus). Zombies decay health when overhealed.
        regenBonus = 0;
        if(clientHealth < clientMaxHealth)
        {
          switch(clientClass)
          {
            case TFClass_Scout: regenBonus = 2 + (1 * zf_hoardeBonus[i]);
            case TFClass_Heavy: regenBonus = 4 + (3 * zf_hoardeBonus[i]);
            case TFClass_Spy:   regenBonus = 2 + (1 * zf_hoardeBonus[i]);
          }        
          clientHealth += regenBonus;
          clientHealth = min(clientHealth, clientMaxHealth);
          SetEntityHealth(i, clientHealth);
        }
        else if(clientHealth > clientMaxHealth)
        {
          regenBonus = -2;
          clientHealth += regenBonus;
          clientHealth = max(clientHealth, clientMaxHealth); 
          SetEntityHealth(i, clientHealth);
        }
 
        // 2. Handle zombie crit rate bonus.
        //    Zombies receive crit bonus based on number of nearby zombies
        //    (hoarde bonus). Zombies only receive this bonus at full health
        //    or greater.
        critBonus = 0;
        if(clientHealth >= clientMaxHealth)
        {
          switch(clientClass)
          {
            case TFClass_Scout: critBonus = 5 + (1 * zf_hoardeBonus[i]);
            case TFClass_Heavy: critBonus = 5 + (2 * zf_hoardeBonus[i]);
            case TFClass_Spy:   critBonus = 5 + (1 * zf_hoardeBonus[i]);
          }
        }   
        zf_critBonus[i] = critBonus;
        
        // 3. Handle zombie rage speed adjustments.
        //    When rage is not active, zombie speed is based on whether they
        //    have full health. When rage is active, zombie speed is based on
        //    whether cooldown period is in effect.
        clientSpeed = getZombieSpeed(clientClass, (clientHealth >= clientMaxHealth), zf_rageState[i]);
        SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", clientSpeed); 
        
      } //if
    } //if
  } //for
}

handle_hoardeBonus()
{ 
  decl playerCount;
  decl player[MAXPLAYERS];
  decl playerHoardeId[MAXPLAYERS];
  decl Float:playerPos[MAXPLAYERS][3];
  
  decl hoardeSize[MAXPLAYERS];

  decl curPlayer;
  decl curHoarde;
  decl Handle:hStack;
  
  // 1. Find all active zombie players.
  playerCount = 0;
  for(new i = 1; i <= MaxClients; i++)
  {  
    if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      if(GetClientTeam(i) == zf_zombieTeam)
      {              
        player[playerCount] = i;
        playerHoardeId[playerCount] = -1;
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", playerPos[playerCount]);       
        playerCount++; 
      }
    }
  }
  
  // 2. Calculate hoarde groups.
  //    A hoarde is defined as a single, contiguous group of valid zombie
  //    players. Distance calculation between zombie players serves as
  //    primary decision criteria.
  curHoarde = 0;
  hStack = CreateStack();  
  for(new i = 0; i < playerCount; i++)
  {
    // 2a. Create new hoarde group.
    if(playerHoardeId[i] == -1)
    {
      PushStackCell(hStack, i);   
      playerHoardeId[i] = curHoarde;
      hoardeSize[curHoarde] = 1;
    }
    
    // 2b. Build current hoarde created in step 2a.
    //     Use a depth-first adjacency search.
    while(PopStackCell(hStack, curPlayer))
    {            
      for(new j = i+1; j < playerCount; j++)
      {
        if(playerHoardeId[j] == -1)
        {
          if(GetVectorDistance(playerPos[j], playerPos[curPlayer], true) <= 200000)
          {
            PushStackCell(hStack, j);
            playerHoardeId[j] = curHoarde;
            hoardeSize[curHoarde]++;
          }
        }
      } 
    }
    curHoarde++;
  }
  
  // 3. Set hoarde bonuses.
  for(new i = 1; i <= MaxClients; i++)
    zf_hoardeBonus[i] = 0;    
  for(new i = 0; i < playerCount; i++)
    zf_hoardeBonus[player[i]] = hoardeSize[playerHoardeId[i]] - 1;    
}

//
// Help Routines
//
public help_printZFInfoChat(client)
{
  if(client == 0)
  {
    PrintToChatAll("\x05[ZF]\x01 This server is running the Zombie Fortress plugin, v%s", PLUGIN_VERSION);
    PrintToChatAll("\x05[ZF]\x01 Type \"zf_help\" in chat for more information.");    
  }
  else
  {
    PrintToChat(client, "\x05[ZF]\x01 This server is running the Zombie Fortress plugin, v%s", PLUGIN_VERSION);
    PrintToChat(client, "\x05[ZF]\x01 Type \"zf_help\" in chat for more information.");
  }
}

public help_printZFInfoPanel(client)
{
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel, "ZF Plugin Info");
  DrawPanelText(panel, "----------------------------------------");
  DrawPanelText(panel, "Humans must survive the endless hoarde.");
  DrawPanelText(panel, "When a human dies, they become a zombie.");
  DrawPanelText(panel, "* Type \"zf_team\" to see your team info.");
  DrawPanelText(panel, "* Type \"zf_class\" to see your class info.");
  DrawPanelText(panel, "----------------------------------------");
  DrawPanelItem(panel, "Hide this message.");
  SendPanelToClient(panel, client, dummy_PanelHandler, 10);
  CloseHandle(panel);
}

public help_printTeamInfoPanel(client, team)
{
  new Handle:panel = CreatePanel();
  if(team == zf_survivorTeam)
  {
    SetPanelTitle(panel, "Survivor Team");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelText(panel, "Survivors consist of soldiers, demomen,");
    DrawPanelText(panel, "pyros, engineers, medics, and snipers.");
    DrawPanelText(panel, "They receive morale boosts for multiple");
    DrawPanelText(panel, "kills in a row. Morale boosts grant crit");
    DrawPanelText(panel, "and health bonuses.");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelItem(panel, "Hide this message.");
    SendPanelToClient(panel, client, dummy_PanelHandler, 10);
  }
  else if(team == zf_zombieTeam)
  {
    SetPanelTitle(panel, "Zombie Team");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelText(panel, "Zombies consist of scouts, heavies, and");
    DrawPanelText(panel, "spies. They receive regeneration and crit");
    DrawPanelText(panel, "bonuses for sticking together as a hoarde.");
    DrawPanelText(panel, "They also possess the Rage ability, which");
    DrawPanelText(panel, "gives health and speed bonuses. Rage cooldown");
    DrawPanelText(panel, "occurs after 20s and recharges after 30s.");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelItem(panel, "Hide this message.");
    SendPanelToClient(panel, client, dummy_PanelHandler, 10);
  }
  else
  {
    SetPanelTitle(panel, "Spectator Team");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelText(panel, "Here you are, secretly watching other");
    DrawPanelText(panel, "players. Creep.");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelItem(panel, "Hide this message.");
    SendPanelToClient(panel, client, dummy_PanelHandler, 10);
  }

  CloseHandle(panel);
}

public help_printClassInfoPanel(client, TFClassType:class)
{
  new Handle:panel = CreatePanel();
  switch(class)
  {
    case TFClass_Soldier:
    {
      SetPanelTitle(panel, "Soldier [Survivor/Assault]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Gains 2 rockets per kill.");
      DrawPanelText(panel, "Speed increased to 280 (from 240).");
    }
    case TFClass_Pyro:
    {
      SetPanelTitle(panel, "Pyro [Survivor/Assault]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Flamethrower/Backburner limited to 100.");
      DrawPanelText(panel, "Speed decreased to 240 (from 300).");      
    }
    case TFClass_DemoMan:
    {
      SetPanelTitle(panel, "Demoman [Survivor/Assault]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Gains 2 pipes per kill.");    
    }
    case TFClass_Engineer:
    {
      SetPanelTitle(panel, "Engineer [Survivor/Support]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Buildables can't be upgraded, but can be");
      DrawPanelText(panel, "repaired.");
      DrawPanelText(panel, "Sentry ammo limited to 60, slowly decays,");
      DrawPanelText(panel, "and more ammo can't be added. Sentry self");
      DrawPanelText(panel, "destructs when ammo is depleted.");
      DrawPanelText(panel, "Dispenser health increased to 250 (from 150).");    
    }
    case TFClass_Medic:
    {
      SetPanelTitle(panel, "Medic [Survivor/Support]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Syringe Gun/Blutsauger doesn't have to");
      DrawPanelText(panel, "reload.");
      DrawPanelText(panel, "Ueber/Kritzkrieg charge faster, but don't");
      DrawPanelText(panel, "last as long."); 
      DrawPanelText(panel, "Overheal limited to 125% of max health.");
      DrawPanelText(panel, "Overheal decays more slowly.");
    }
    case TFClass_Sniper:
    {
      SetPanelTitle(panel, "Sniper [Survivor/Support]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Gains 5 Rifle/2 Huntman ammo per kill.");
      DrawPanelText(panel, "SMG doesn't have to reload.");   
    }    
    case TFClass_Scout:
    {
      SetPanelTitle(panel, "Scout [Zombie]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Bat/Sandman only.");
      DrawPanelText(panel, "Rage ability: Increase speed and health");
      DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
      DrawPanelText(panel, "Speed (full health) reduced to 340 (from 400).");
      DrawPanelText(panel, "Speed (weakened) reduced to 300 (from 400).");      
    }
    case TFClass_Heavy:
    {
      SetPanelTitle(panel, "Heavy [Zombie]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Fists/KGB only.");
      DrawPanelText(panel, "Rage ability: Increase speed and health");
      DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
      DrawPanelText(panel, "Speed (full health) increased to 240 (from 230).");
      DrawPanelText(panel, "Speed (weakened) reduced to 200 (from 230).");   
    }
    case TFClass_Spy:
    {
      SetPanelTitle(panel, "Spy [Zombie]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Knife/Invis Watch/Cloak and Dagger only.");
      DrawPanelText(panel, "Rage ability: Increase speed and health");
      DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
      DrawPanelText(panel, "Speed (full health) reduced to 280 (from 300).");
      DrawPanelText(panel, "Speed (weakened) reduced to 240 (from 300)."); 
    }    
    default:
    {
      SetPanelTitle(panel, "Unassigned [Spectator]");
      DrawPanelText(panel, "----------------------------------------");      
      DrawPanelText(panel, "Honestly, what were you expecting here?");   
    }
  }
  DrawPanelText(panel, "----------------------------------------");
  DrawPanelItem(panel, "Hide this message.");
  SendPanelToClient(panel, client, dummy_PanelHandler, 8);
  
  CloseHandle(panel);
}

public dummy_PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{ return; }

//
// Utility Routines
//
max(a,b) { return (a > b) ? a : b; }
min(a,b) { return (a < b) ? a : b; }

bool:validZombie(TFClassType:class)   { return (ZF_VALIDZOMBIE[class] == 1); }
bool:validSurvivor(TFClassType:class) { return (ZF_VALIDSURVIVOR[class] == 1); }
TFClassType:randomZombie()   { return ZF_ZOMBIES[GetRandomInt(0,2)]; }
TFClassType:randomSurvivor() { return ZF_SURVIVORS[GetRandomInt(0,5)]; }

bool:isEquipped(client, ZFWeaponType:zfWeapon)
{
  new weapon = GetPlayerWeaponSlot(client, zf_weaponSlot[zfWeapon]);
  new itemDef = (weapon > 0) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
  return (itemDef == zf_weaponItemDefIndex[zfWeapon]);
}

spawnClient(client, clientTeam)
{
#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: spawnClient() %d %d", client, clientTeam);
#endif
  
  new Handle:dataPack = CreateDataPack();
  WritePackCell(dataPack, client);
  WritePackCell(dataPack, clientTeam);
    
  if(zf_tForceRespawn[client])
  {
    KillTimer(zf_tForceRespawn[client]);
  }
  zf_tForceRespawn[client] = CreateTimer(0.1, timer_forceRespawn, dataPack); 
}

setTeamRespawnTime(team, Float:time)
{
  new index = FindEntityByClassname(-1, "tf_gamerules");
  if(index != -1)
  {
    SetVariantFloat(time/2.0);
    if(team == _:TFTeam_Blue)
      AcceptEntityInput(index, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
    if(team == _:TFTeam_Red)
      AcceptEntityInput(index, "SetRedTeamRespawnWaveTime", -1, -1, 0);
  }       
}

Float:getClassBaseSpeed(TFClassType:class)
{
  switch (class)
  { 
    case TFClass_Soldier:  return 280.0;
    case TFClass_DemoMan:  return 280.0;
    case TFClass_Medic:    return 320.0;
    case TFClass_Pyro:     return 240.0;
    case TFClass_Engineer: return 300.0;
    case TFClass_Sniper:   return 300.0;
    case TFClass_Scout:    return 340.0;
    case TFClass_Spy:      return 280.0;
    case TFClass_Heavy:    return 240.0;
  }
  return 0.0;
}

Float:getZombieSpeed(TFClassType:class, bool:fullHealth, rageState)
{
  switch (class)
  {
    case TFClass_Scout:
    {
      if(rageState == ZF_RAGESTATE_INACTIVE)          return (fullHealth ? 340.0 : 300.0);
      else if(rageState == ZF_RAGESTATE_ACTIVE_ANGRY) return 400.0;
      else if(rageState == ZF_RAGESTATE_ACTIVE_TIRED) return 200.0;
    }
    case TFClass_Spy:
    {
      if(rageState == ZF_RAGESTATE_INACTIVE)          return (fullHealth ? 280.0 : 240.0);
      else if(rageState == ZF_RAGESTATE_ACTIVE_ANGRY) return 340.0;
      else if(rageState == ZF_RAGESTATE_ACTIVE_TIRED) return 170.0;
    }
    case TFClass_Heavy:
    {
      if(rageState == ZF_RAGESTATE_INACTIVE)          return (fullHealth ? 240.0 : 200.0);
      else if(rageState == ZF_RAGESTATE_ACTIVE_ANGRY) return 300.0;
      else if(rageState == ZF_RAGESTATE_ACTIVE_TIRED) return 150.0;  
    }
  }
  return 0.0;
}

resetClientState(client)
{ 
  zf_rageState[client] = ZF_RAGESTATE_INACTIVE;
  zf_critBonus[client] = 0;
  zf_hoardeBonus[client] = 0;
  zf_moraleBonus[client] = 0;
  if(zf_tForceRespawn[client])
  {
    KillTimer(zf_tForceRespawn[client]);
    zf_tForceRespawn[client] = INVALID_HANDLE;
  }    
  if(zf_tStripWeapons[client])
  {
    KillTimer(zf_tStripWeapons[client]);
    zf_tStripWeapons[client] = INVALID_HANDLE;
  }
  if(zf_tRageCooldown[client])
  {
    KillTimer(zf_tRageCooldown[client]); 
    zf_tRageCooldown[client] = INVALID_HANDLE; 
  } 
  if(zf_tRageReady[client])
  { 
    KillTimer(zf_tRageReady[client]); 
    zf_tRageReady[client] = INVALID_HANDLE; 
  }
  if(zf_tMoraleBoost[client])
  {
    KillTimer(zf_tMoraleBoost[client]);
    zf_tMoraleBoost[client] = INVALID_HANDLE;
  }
}

