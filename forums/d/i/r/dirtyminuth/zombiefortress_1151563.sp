////////////////////////////////////////////////////////////////////////////////
//
//  Z O M B I E - F O R T R E S S - [TF2]
//
//  This is a rewrite of the original ZF mod.
//
//  Author: dirtyminuth
//
//  Credits: Sirot, original author of ZF. (http://www.zf.sovietgaming.net/)
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
#define PLUGIN_VERSION "4.0.4.0"
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
#define ZF_TEAMPREF_SURVIVOR 0
#define ZF_TEAMPREF_NONE 1
#define ZF_TEAMPREF_ZOMBIE 2

#define ZF_ROUNDSTATE_INIT 0
#define ZF_ROUNDSTATE_NONE 1
#define ZF_ROUNDSTATE_GRACE 2
#define ZF_ROUNDSTATE_ACTIVE 3

#define ZF_SPAWNSTATE_REST 0
#define ZF_SPAWNSTATE_HUNGER 1
#define ZF_SPAWNSTATE_FRENZY 2

#define PLAYERBUILTOBJECT_ID_DISPENSER 0
#define PLAYERBUILTOBJECT_ID_TELENT 1
#define PLAYERBUILTOBJECT_ID_TELEXIT 2
#define PLAYERBUILTOBJECT_ID_SENTRY 3

#define PLAYERCOND_KRITZ (1 << 11)

//
// Enumerations and Associated Structures
//
// ZF weapons
#define MAX_ZFWEAPON_COUNT 8
enum ZFWeaponType
{
  ZFWeapon_Bonk = 0,        // Weapon Slot 1, Item Index 46
  ZFWeapon_Sandman = 1,     // Weapon Slot 2, Item Index 44
  ZFWeapon_Sandvich = 2,    // Weapon Slot 1, Item Index 42
  ZFWeapon_DeadRinger = 3,  // Weapon Slot 4, Item Index 59
  ZFWeapon_SMG = 4,         // Weapon Slot 1, Item Index 16
  ZFWeapon_Rifle = 5,       // Weapon Slot 0, Item Index 14
  ZFWeapon_Huntsman = 6,    // Weapon Slot 0, Item Index 56  
  ZFWeapon_DalokohsBar = 7  // Weapon Slot 1, Item Index 159
};
new const zf_weaponSlot[MAX_ZFWEAPON_COUNT] = {1,2,1,4,1,0,0,1};
new const zf_weaponItemDefIndex[MAX_ZFWEAPON_COUNT] = {46,44,42,59,16,14,56,159};

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
new zf_bWasMiniRound;
new zf_roundState;
new zf_spawnState;
new zf_spawnRestCounter;
new zf_spawnSurvivorsKilledCounter;
new zf_spawnZombiesKilledCounter;

// Client State
new zf_teamPref[MAXPLAYERS+1];
new zf_critBonus[MAXPLAYERS+1];
new zf_hoardeBonus[MAXPLAYERS+1];

// Offsets
new zf_oClipAmmo;
new zf_oReserveAmmo;

// Global Timer Handles
new Handle:zf_tMain;
new Handle:zf_tSetup;
new Handle:zf_tHoarde;
new Handle:zf_tPluginReminder;

// Client Timer Handles
new Handle:zf_tForceRespawn[MAXPLAYERS+1];
new Handle:zf_tPostSpawn[MAXPLAYERS+1];
new Handle:zf_tRage[MAXPLAYERS+1];

// Cvar Handles
new Handle:zf_cvForceOn;
new Handle:zf_cvRatio;
new Handle:zf_cvAllowTeamPref;
new Handle:zf_cvSwapOnPayload;
new Handle:zf_cvSwapOnAttdef;

////////////////////////////////////////////////////////////
//
// Sourcemod Callbacks
//
////////////////////////////////////////////////////////////
public OnPluginStart()
{
  // Initialize state
  zf_bEnabled = false;
  zf_bWasMiniRound = false;
  zf_roundState = ZF_ROUNDSTATE_INIT;
  
  // Initialize offsets
  zf_oClipAmmo = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
  zf_oReserveAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
  
  // Initialize timer handles
  zf_tMain = INVALID_HANDLE;
  zf_tSetup = INVALID_HANDLE;
  zf_tHoarde = INVALID_HANDLE;
  zf_tPluginReminder = INVALID_HANDLE;

  // Register cvars
  CreateConVar("sm_zf_version", PLUGIN_VERSION, "Current Zombie Fortress Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
  zf_cvForceOn = CreateConVar("sm_zf_force_on", "1", "<0/1> Activate ZF for non-ZF maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  zf_cvRatio = CreateConVar("sm_zf_ratio", "0.65", "<0.01-1.00> Percentage of players that start as survivors.", FCVAR_PLUGIN, true, 0.01, true, 1.0);
  zf_cvAllowTeamPref = CreateConVar("sm_zf_allowteampref", "1", "<0/1> Allow use of team preference criteria.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  zf_cvSwapOnPayload = CreateConVar("sm_zf_swaponpayload", "1", "<0/1> Swap teams on payload maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  zf_cvSwapOnAttdef = CreateConVar("sm_zf_swaponattdef", "1", "<0/1> Swap teams on attack/defend maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  
  // Config
  AutoExecConfig(true, "plugin_zf");
      
  // Hook events
  HookEvent("teamplay_round_start", event_RoundStart);
  HookEvent("teamplay_round_win", event_RoundEnd);
  HookEvent("player_spawn", event_PlayerSpawn);  
  HookEvent("player_death", event_PlayerDeath);
  HookEvent("player_builtobject", event_PlayerBuiltObject);

  // Register Admin Commands
  RegAdminCmd("sm_zf_enable", command_zfEnable, ADMFLAG_GENERIC, "Activates the Zombie Fortress plugin.");
  RegAdminCmd("sm_zf_disable", command_zfDisable, ADMFLAG_GENERIC, "Deactivates the Zombie Fortress plugin.");
  RegAdminCmd("sm_zf_swapteams", command_zfSwapTeams, ADMFLAG_GENERIC, "Swaps current team roles.");
  
  // Hook Client Commands
  AddCommandListener(hook_JoinTeam, "jointeam");
  AddCommandListener(hook_JoinClass, "joinclass");
  AddCommandListener(hook_VoiceMenu, "voicemenu");  
  AddCommandListener(hook_zfMenu, "zf_menu");
  AddCommandListener(hook_zfTeamPref, "zf_teampref");  
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
    GetConVarBool(zf_cvForceOn) ? zfEnable() : zfDisable();
  } 
     
  // 2. Determine whether to swap teams on payload maps.
  //    For "pl_" prefixed maps, swap teams if sm_zf_swaponpayload is set.
  if(strncmp(mapname, "pl_", 3, false) == 0)
  {
    if(GetConVarBool(zf_cvSwapOnPayload)) 
    {
      zf_zombieTeam = _:TFTeam_Red;
      zf_survivorTeam = _:TFTeam_Blue;
    }
  }
  
  // 3. Determine whether to swap teams on attack / defend maps.
  //    For "cp_" prefixed maps, and maps with all RED control points, 
  //    swap teams if sm_zf_swaponattdef is set.
  if(strncmp(mapname, "cp_", 3, false) == 0)
  {
    new bool:isAttdef = true;
    new index = -1;
    while((index = FindEntityByClassname(index, "team_control_point")) != -1)
    {
      if(GetEntProp(index, Prop_Send, "m_iTeamNum") != 2) // 2 = Red Team
      {
        isAttdef = false;
        break;
      }
    }
    
    if(GetConVarBool(zf_cvSwapOnAttdef) && isAttdef)
    {
      zf_zombieTeam = _:TFTeam_Red;
      zf_survivorTeam = _:TFTeam_Blue;
    }
  }
    
  // 4. Set initial round state at the end of OnConfigsExecuted().
  zf_roundState = ZF_ROUNDSTATE_INIT;
}  
    
public OnClientConnected(client)
{ 
  if(!zf_bEnabled) return;
  resetClientPref(client);
  resetClientState(client);
}

public OnClientPutInServer(client)
{
  if(!zf_bEnabled) return;
  CreateTimer(10.0, timer_initialHelp, client);
}

public OnClientDisconnect(client)
{
  if(!zf_bEnabled) return;
  resetClientPref(client);
  resetClientState(client);
}

public OnGameFrame()
{
  if(!zf_bEnabled) return;  
  handle_gameFrameLogic();
}

////////////////////////////////////////////////////////////
//
// Admin Console Command Handlers
//
////////////////////////////////////////////////////////////
public Action:command_zfEnable (client, args)
{ 
  if(!zf_bEnabled)
  {
    zfEnable();
    ServerCommand("mp_restartgame 10");
  }
}

public Action:command_zfDisable (client, args)
{
  if(zf_bEnabled)
  {
    zfDisable();
    ServerCommand("mp_restartgame 10");  
  }  
}

public Action:command_zfSwapTeams (client, args)
{
  if(zf_bEnabled)
  {
    zfSwapTeams();
    zf_roundState = ZF_ROUNDSTATE_NONE;
    zf_bWasMiniRound = false;
    ServerCommand("mp_restartgame 10");
  }
}

////////////////////////////////////////////////////////////
//
// Client Console / Chat Command Handlers
//
////////////////////////////////////////////////////////////
public Action:hook_JoinTeam(client, const String:command[], argc)
{  
  decl String:cmd1[32];
  decl String:sSurTeam[16];  
  decl String:sZomTeam[16];
  decl String:sZomVgui[16];
  
  if(!zf_bEnabled) return Plugin_Continue;  
  if(argc < 1) return Plugin_Handled;
   
  GetCmdArg(1, cmd1, sizeof(cmd1));
  
  if(zf_roundState >= ZF_ROUNDSTATE_GRACE)
  {
    // Assign team-specific strings
    if(zf_zombieTeam == _:TFTeam_Blue)
    {
      sSurTeam = "red";
      sZomTeam = "blue";
      sZomVgui = "class_blue";
    }
    else
    {
      sSurTeam = "blue";
      sZomTeam = "red";
      sZomVgui = "class_red";      
    }
      
    // If client tries to join the survivor team or a random team
    // during grace period or active round, place them on the zombie
    // team and present them with the zombie class select screen.
    if(StrEqual(cmd1, sSurTeam, false) || 
       StrEqual(cmd1, "auto", false))
    {
      ChangeClientTeam(client, zf_zombieTeam);
      ShowVGUIPanel(client, sZomVgui);
      return Plugin_Handled;
    }
    // If client tries to join the zombie team or spectator
    // during grace period or active round, let them do so.
    else if(StrEqual(cmd1, sZomTeam, false) || 
            StrEqual(cmd1, "spectate", false))
    {
      return Plugin_Continue;
    }
    // Prevent joining any other team.
    else
    {
      return Plugin_Handled;
    }
  }

  return Plugin_Continue;
}

public Action:hook_JoinClass(client, const String:command[], argc)
{
  decl String:cmd1[32];
  
  if(!zf_bEnabled) return Plugin_Continue;
  if(argc < 1) return Plugin_Handled;

  GetCmdArg(1, cmd1, sizeof(cmd1));
  
  if(GetClientTeam(client) == zf_zombieTeam)   
  {
    // If an invalid zombie class is selected, print a message and
    // accept joinclass command. ZF spawn logic will correct this
    // issue when the player spawns.
    if(!(StrEqual(cmd1, "scout", false) ||
         StrEqual(cmd1, "spy", false)  || 
         StrEqual(cmd1, "heavyweapons", false)))
    {
      PrintToChat(client, "\x05[ZF]\x01 Valid zombies: Scout, Heavy, Spy.");
    }
  }

  else if(GetClientTeam(client) == zf_survivorTeam)
  {
    // Prevent survivors from switching classes during the round.
    if(zf_roundState == ZF_ROUNDSTATE_ACTIVE)
    {
      PrintToChat(client, "\x05[ZF]\x01 Survivors can't change classes during a round!");
      return Plugin_Handled;          
    }
    // If an invalid survivor class is selected, print a message
    // and accept the joincalss command. ZF spawn logic will
    // correct this issue when the player spawns.
    else if(!(StrEqual(cmd1, "soldier", false) || 
              StrEqual(cmd1, "pyro", false) || 
              StrEqual(cmd1, "demoman", false) || 
              StrEqual(cmd1, "engineer", false) || 
              StrEqual(cmd1, "medic", false) || 
              StrEqual(cmd1, "sniper", false)))
    {
      PrintToChat(client, "\x05[ZF]\x01 Valid survivors: Soldier, Pyro, Demo, Engineer, Medic, Sniper.");
    }       
  }
    
  return Plugin_Continue;
}

public Action:hook_VoiceMenu(client, const String:command[], argc)
{
  decl String:cmd1[32], String:cmd2[32];
  
  if(!zf_bEnabled) return Plugin_Continue;  
  if(argc < 2) return Plugin_Handled;
  
  GetCmdArg(1, cmd1, sizeof(cmd1));
  GetCmdArg(2, cmd2, sizeof(cmd2));
  
  // Capture call for medic commands (represented by "voicemenu 0 0").
  // Activate zombie Rage ability (150% health), if possible. Rage 
  // can't be activated below full health or if it's already active.
  // Rage recharges after 30 seconds.
  if(StrEqual(cmd1, "0") && StrEqual(cmd2, "0"))
  {
    if(IsPlayerAlive(client) && (GetClientTeam(client) == zf_zombieTeam))
    {    
      new clientHealth = GetClientHealth(client);
      new clientMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");       
  
      if((zf_tRage[client] == INVALID_HANDLE) && (clientHealth >= clientMaxHealth))
      {
        zf_tRage[client] = CreateTimer(30.0, timer_rageReady, client);
        
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
  
  return Plugin_Continue;
}

public Action:hook_zfTeamPref(client, const String:command[], argc)
{
  decl String:cmd1[32];
  
  if(!zf_bEnabled) return Plugin_Continue;
     
  // Get team preference
  if(argc == 0)
  {
    if(zf_teamPref[client] == ZF_TEAMPREF_SURVIVOR)
      ReplyToCommand(client, "Survivors");
    else if(zf_teamPref[client] == ZF_TEAMPREF_ZOMBIE)
      ReplyToCommand(client, "Zombies");
    else if(zf_teamPref[client] == ZF_TEAMPREF_NONE)
      ReplyToCommand(client, "None");
    return Plugin_Handled;
  }
  
  GetCmdArg(1, cmd1, sizeof(cmd1));
  
  // Set team preference
  if(StrEqual(cmd1, "sur", false))
  {
    zf_teamPref[client] = ZF_TEAMPREF_SURVIVOR;
    return Plugin_Handled;
  }  
  else if(StrEqual(cmd1, "zom", false))
  {
    zf_teamPref[client] = ZF_TEAMPREF_ZOMBIE;
    return Plugin_Handled;
  }
  else if(StrEqual(cmd1, "none", false))
  {
    zf_teamPref[client] = ZF_TEAMPREF_NONE;
    return Plugin_Handled;
  }

  // Error in command format, display usage
  ReplyToCommand(client, "Usage: zf_teampref [SUR|ZOM|NONE]");
  return Plugin_Handled;
}

public Action:hook_zfMenu(client, const String:command[], argc)
{
  if(!zf_bEnabled) return Plugin_Continue; 
  panel_PrintMain(client);
  
  return Plugin_Handled;  
}

////////////////////////////////////////////////////////////
//
// TF2 Gameplay Event Handlers
//
////////////////////////////////////////////////////////////
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{  
  new clientCond = GetEntProp(client, Prop_Send, "m_nPlayerCond");  
  
  // 1. Being kritzed overrides other crit calculations.
  if(clientCond & PLAYERCOND_KRITZ) return Plugin_Continue;
  
  // 2. Handle crit bonus
  result = (zf_critBonus[client] > GetRandomInt(0,99));
  return Plugin_Handled;  
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  decl players[MAXPLAYERS];
  decl playerCount;
  decl surCount;
 
  if(!zf_bEnabled) return Plugin_Continue;

#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: event_RoundStart()");
#endif   

  // Handle initial event_RoundStart "double" call on new map loads.
  if(zf_roundState == ZF_ROUNDSTATE_INIT) 
  {
    zf_roundState = ZF_ROUNDSTATE_NONE;
    return Plugin_Continue;
  }

  // 1. Assign players to zombie and survivor teams.
  //    Only assign teams if last round was a full round.
  if(!zf_bWasMiniRound)
  {
    // 1a. Find all active players.
    playerCount = 0;
    for(new i = 1; i <= MaxClients; i++)
    {
      if(IsClientInGame(i) && (GetClientTeam(i) > 1))
      {
          players[playerCount++] = i;     
      }
    }
  
    // 1b. Randomize, sort players 
    SortIntegers(players, playerCount, Sort_Random);
    // NOTE: As of SM 1.3.1, SortIntegers w/ Sort_Random doesn't 
    //       sort the first element of the array. Temp fix below.  
    new idx = GetRandomInt(0,playerCount-1);
    new temp = players[idx];
    players[idx] = players[0];
    players[0] = temp;    
    
    // 1c. Sort players using team preference criteria
    if(GetConVarBool(zf_cvAllowTeamPref)) 
    {
      SortCustom1D(players, playerCount, SortFunc1D:Sort_Preference);
    }
    
    // 1d. Calculate team counts. At least one survivor must exist.   
    surCount = RoundToFloor(playerCount*GetConVarFloat(zf_cvRatio));
    if((surCount == 0) && (playerCount > 0))
    {
      surCount = 1;
    }  
      
    // 1e. Assign active players to survivor and zombie teams.
    for(new i = 0; i < surCount; i++)
      spawnClient(players[i], zf_survivorTeam);   
    for(new i = surCount; i < playerCount; i++)
      spawnClient(players[i], zf_zombieTeam);   
  }
   
  // 2. Handle map entity adjustment.
  //    Disable all resupply cabinets.
  //    Remove ammopacks and ragdolls resulting from initial team balance.
  new index = -1;
  while((index = FindEntityByClassname(index, "func_regenerate")) != -1)
    AcceptEntityInput(index, "Disable");
       
  // 3. Handle initial game state.
  //    Handle round state.
  //    Handle zombie spawn state.
  zf_roundState = ZF_ROUNDSTATE_GRACE;  
  if(zf_tSetup != INVALID_HANDLE) KillTimer(zf_tSetup);
  zf_tSetup = CreateTimer(20.0, timer_setupEnd);
  PrintToChatAll("\x05[ZF]\x01 Grace period begun. Survivors can change classes.");
  
  zf_spawnState = ZF_SPAWNSTATE_HUNGER;
  zf_spawnSurvivorsKilledCounter = 1;
  setTeamRespawnTime(zf_zombieTeam, 10.0);

  // 4. Handle post round start cleanup.
  CreateTimer(1.0, timer_postRoundStart);
    
  return Plugin_Continue;
}

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;
  
#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: event_RoundEnd()");
#endif  

  zf_bWasMiniRound = !GetEventBool(event, "full_round");
  zf_roundState = ZF_ROUNDSTATE_NONE;        
  
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
    if(zf_roundState == ZF_ROUNDSTATE_ACTIVE)
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
  if(zf_tPostSpawn[client] != INVALID_HANDLE)
  {
    KillTimer(zf_tPostSpawn[client]);  
  }
  zf_tPostSpawn[client] = CreateTimer(0.1, timer_postSpawn, client); 
    
  return Plugin_Continue;  
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;

#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: event_PlayerDeath()");
#endif    
  
  if(zf_roundState != ZF_ROUNDSTATE_ACTIVE) return Plugin_Continue;    
  
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
    if((killers[0] > 0) && (GetClientTeam(killers[0]) == zf_zombieTeam))
    {
      zf_spawnSurvivorsKilledCounter--;
    }
    
    // Transfer player to zombie team.
    CreateTimer(6.0, timer_zombify, victim);
  }
  
  // 2. Handle zombie death rules.
  else if(GetClientTeam(victim) == zf_zombieTeam)
  {      
    // Note if zombie killed by survivor.
    if((killers[0] > 0) && (GetClientTeam(killers[0]) == zf_survivorTeam))
    {
      zf_spawnZombiesKilledCounter--;
    }
    
    if(killers[0] == killers[1]) killers[1] = 0; // Avoid rare self assist.    
    for(new i = 0; i < 2; i++)
    {      
      killer = killers[i];              
      if((killer > 0) && IsClientInGame(killer) && IsPlayerAlive(killer))
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
        
        // 2b. Handle morale bonuses
        //     Each kill grants a small health bonus and increases
        //     current crit bonus.
        killerHealth = GetClientHealth(killer);
        killerMaxHealth = GetEntProp(killer, Prop_Data, "m_iMaxHealth"); 
        
        killerHealth += zf_critBonus[killer] * 2;
        killerHealth = min(killerHealth, killerMaxHealth);        
        SetEntityHealth(killer, killerHealth);

        zf_critBonus[killer] = min(100, zf_critBonus[killer] + 5);            
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

public Action:event_PlayerBuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;

  new index = GetEventInt(event, "index");
  new object = GetEventInt(event, "object");

  // 1. Handle dispenser rules.
  //    Disable dispensers when they begin construction.
  //    Increase max health to 250 (default level 1 is 150).      
  if(object == PLAYERBUILTOBJECT_ID_DISPENSER)
  {
    SetEntProp(index, Prop_Send, "m_bDisabled", 1);
    SetEntProp(index, Prop_Send, "m_iMaxHealth", 250);
  }

  return Plugin_Continue;     
}

////////////////////////////////////////////////////////////
//
// Periodic Timer Callbacks
//
////////////////////////////////////////////////////////////
public Action:timer_main(Handle:timer) // 1Hz
{     
  if(!zf_bEnabled) return Plugin_Continue;
  handle_survivorAbilities();
  handle_zombieAbilities();      

  if(zf_roundState != ZF_ROUNDSTATE_ACTIVE) return Plugin_Continue;
  handle_winCondition();
  handle_spawnState();
          
  return Plugin_Continue;
}

public Action:timer_hoarde(Handle:timer) // 1/5th Hz
{  
  if(!zf_bEnabled) return Plugin_Continue;
  handle_hoardeBonus();
  
  return Plugin_Continue;  
}

public Action:timer_pluginReminder(Handle:timer) // 1/180th Hz
{ 
  if(!zf_bEnabled) return Plugin_Continue;  
  help_printZFInfoChat(0);
  
  return Plugin_Continue;
}

////////////////////////////////////////////////////////////
//
// Aperiodic Timer Callbacks
//
////////////////////////////////////////////////////////////
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
  if(IsClientInGame(client) && (nextClientTeam > 1))
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
 
    // Use of m_lifeState here prevents:
    // 1. "[Player] Suicided" messages.
    // 2. Adding a death to player stats.
    SetEntProp(client, Prop_Send, "m_lifeState", 2); 
    TF2_SetPlayerClass(client, nextClientClass, false, true);   
    ChangeClientTeam(client, nextClientTeam);
    SetEntProp(client, Prop_Send, "m_lifeState", 0);      
    TF2_RespawnPlayer(client);      
  }
  
  zf_tForceRespawn[client] = INVALID_HANDLE;
  
  return Plugin_Continue; 
}

public Action:timer_postSpawn(Handle:timer, any:client)
{      
  decl clientTeam;
  decl TFClassType:clientClass;
  
#if defined ZF_DEBUG_MESSAGES  
  LogMessage("[ZF DEBUG]: timer_postSpawn() %d", client); 
#endif   
 
  if(IsClientInGame(client) && IsPlayerAlive(client))
  {    
    clientTeam = GetClientTeam(client);
    clientClass = TF2_GetPlayerClass(client);
    
    // 1. Handle class weapon restrictions
    if(clientTeam == zf_zombieTeam)
    {
      switch(clientClass)
      {
        // 1a. Remove Scattergun(0), FAN(0), Pistol(1), Lugermorph(1).          
        //     Keep BONK! (1), Bat(2), Sandman(2).
        case TFClass_Scout:
        {
          TF2_RemoveWeaponSlot(client, 0);
          if(!isEquipped(client,ZFWeaponType:ZFWeapon_Bonk))             
            TF2_RemoveWeaponSlot(client, 1);           
        }
        // 1b. Remove Minigun(0), Natascha(0), Shotgun(1).
        //     Keep Sandwich(1), Dalokohs Bar(1), Fists(2), KGB(2).
        case TFClass_Heavy:
        {
          TF2_RemoveWeaponSlot(client, 0);
          if(!(isEquipped(client, ZFWeaponType:ZFWeapon_Sandvich) || 
               isEquipped(client, ZFWeaponType:ZFWeapon_DalokohsBar)))
            TF2_RemoveWeaponSlot(client, 1);         
        }
        // 1c. Remove Revolver(0), Ambassador(0), Big Kill(0), Sapper(1), Disguise Kit(3), Dead Ringer(4).
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

  zf_tPostSpawn[client] = INVALID_HANDLE;
    
  return Plugin_Continue; 
}

public Action:timer_rageReady(Handle:timer, any:client)
{  
  if(IsClientInGame(client) && IsPlayerAlive(client))
  {    
    PrintHintText(client, "Rage is ready!");
  }
  
  zf_tRage[client] = INVALID_HANDLE; 
    
  return Plugin_Continue; 
}

public Action:timer_initialHelp(Handle:timer, any:client)
{    
  // Wait until client is in game before printing initial help text.
  if(IsClientInGame(client))
  {
    help_printZFInfoChat(client);
  }
  else
  {
    CreateTimer(10.0, timer_initialHelp, client);  
  }  
  return Plugin_Continue; 
}

public Action:timer_setupEnd(Handle:timer)
{
  zf_roundState = ZF_ROUNDSTATE_ACTIVE;
  zf_tSetup = INVALID_HANDLE;
  
  PrintToChatAll("\x05[ZF]\x01 Grace period complete. Survivors can no longer change classes.");
  
  return Plugin_Continue;  
}

public Action:timer_postRoundStart(Handle:timer)
{ 
  // 1. Remove all dropped ammopacks.
  new index = -1;
  while ((index = FindEntityByClassname(index, "tf_ammo_pack")) != -1)
      AcceptEntityInput(index, "Kill");
  
  // 2. Remove all ragdolls.
  index = -1;
  while ((index = FindEntityByClassname(index, "tf_ragdoll")) != -1)
      AcceptEntityInput(index, "Kill");
      
  // 3. Disable all payload cart dispensers.
  index = -1;
  while((index = FindEntityByClassname(index, "mapobj_cart_dispenser")) != -1)
    SetEntProp(index, Prop_Send, "m_bDisabled", 1);  
  
  return Plugin_Continue; 
}

public Action:timer_zombify(Handle:timer, any:client)
{   
  if(IsClientInGame(client))
  {
    PrintToChat(client, "\x05[ZF]\x01 You have perished, zombifying....");
    spawnClient(client, zf_zombieTeam);
  }
  
  return Plugin_Continue; 
}

////////////////////////////////////////////////////////////
//
// Handling Functionality
//
////////////////////////////////////////////////////////////
handle_gameFrameLogic()
{
  // 1. Limit spy cloak to 80% of max.
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i) && IsPlayerAlive(i))
    {
      new Float:val = GetEntPropFloat(i, Prop_Send, "m_flCloakMeter");
      if(val > 80.0)
        SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 80.0);
    }
  }
}
  
handle_winCondition()
{
  decl bool:anySurvivorAlive;
  decl index;
  
  // 1. Check for any survivors that are still alive.
  anySurvivorAlive = false;
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == zf_survivorTeam))
    {
      anySurvivorAlive = true;
      break;
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
    
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == zf_survivorTeam))
    {
      // 1. Handle survivor weapon rules.
      //    SMG doesn't have to reload. 
      //    Syringe gun / blutsauger don't have to reload. 
      //    Flamethrower / backburner ammo limited to 100.
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
      } //switch
      
      // 2. Handle survivor crit bonus rules.
      //    Decrement morale bonus.
      zf_critBonus[i] = max(0, zf_critBonus[i] - 1);
      
    } //if
  } //for
  
  // 3. Handle sentry rules.
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
  decl bonus;
  
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == zf_zombieTeam))
    {   
      clientClass = TF2_GetPlayerClass(i);
      clientHealth = GetClientHealth(i);
      clientMaxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
              
      // 1. Handle zombie regeneration.
      //    Zombies regenerate health based on class and number of nearby
      //    zombies (hoarde bonus). Zombies decay health when overhealed.
      bonus = 0;
      if(clientHealth < clientMaxHealth)
      {
        switch(clientClass)
        {
          case TFClass_Scout: bonus = 2 + (1 * zf_hoardeBonus[i]);
          case TFClass_Heavy: bonus = 4 + (3 * zf_hoardeBonus[i]);
          case TFClass_Spy:   bonus = 2 + (1 * zf_hoardeBonus[i]);
        }        
        clientHealth += bonus;
        clientHealth = min(clientHealth, clientMaxHealth);
        SetEntityHealth(i, clientHealth);
      }
      else if(clientHealth > clientMaxHealth)
      {
        switch(clientClass)
        {
          case TFClass_Scout: bonus = -3;
          case TFClass_Heavy: bonus = -7;
          case TFClass_Spy:   bonus = -3;
        }          
        clientHealth += bonus;
        clientHealth = max(clientHealth, clientMaxHealth); 
        SetEntityHealth(i, clientHealth);
      }

      // 2. Handle zombie crit rate bonus.
      //    Zombies receive crit bonus based on number of nearby zombies
      //    (hoarde bonus). Zombies only receive this bonus at full health
      //    or greater.
      bonus = 0;
      if(clientHealth >= clientMaxHealth)
      {
        switch(clientClass)
        {
          case TFClass_Scout: bonus = 5 + (1 * zf_hoardeBonus[i]);
          case TFClass_Heavy: bonus = 10 + (5 * zf_hoardeBonus[i]);
          case TFClass_Spy:   bonus = 5 + (1 * zf_hoardeBonus[i]);
        }
      }   
      zf_critBonus[i] = bonus;
      
      // 3. Handle zombie rage speed adjustments.
      //    Zombie speed has three states: above, at, and below full health.
      clientSpeed = getZombieSpeed(clientClass, clientHealth, clientMaxHealth);
      SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", clientSpeed); 
      
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
    if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == zf_zombieTeam))
    {              
      player[playerCount] = i;
      playerHoardeId[playerCount] = -1;
      GetEntPropVector(i, Prop_Send, "m_vecOrigin", playerPos[playerCount]);       
      playerCount++; 
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

////////////////////////////////////////////////////////////
//
// ZF Logic Functionality
//
////////////////////////////////////////////////////////////
zfEnable()
{     
  zf_bEnabled = true;
  zf_bWasMiniRound = false;
  zf_roundState = ZF_ROUNDSTATE_NONE;  
  
  zf_zombieTeam = _:TFTeam_Blue;
  zf_survivorTeam = _:TFTeam_Red;
  
  resetClientStates();
    
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
  zf_bWasMiniRound = false;
  zf_roundState = ZF_ROUNDSTATE_NONE;  
  
  resetClientStates();
    
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
}

zfSwapTeams()
{
  if(zf_zombieTeam == _:TFTeam_Blue)
  {
    zf_zombieTeam = _:TFTeam_Red;
    zf_survivorTeam = _:TFTeam_Blue;
  }
  else
  {
    zf_zombieTeam = _:TFTeam_Blue;
    zf_survivorTeam = _:TFTeam_Red;
  }
}

spawnClient(client, clientTeam)
{
#if defined ZF_DEBUG_MESSAGES    
  LogMessage("[ZF DEBUG]: spawnClient() %d %d", client, clientTeam);
#endif
  
  new Handle:dataPack = CreateDataPack();
  WritePackCell(dataPack, client);
  WritePackCell(dataPack, clientTeam);
    
  if(zf_tForceRespawn[client] != INVALID_HANDLE)
  {
    KillTimer(zf_tForceRespawn[client]);
  }
  zf_tForceRespawn[client] = CreateTimer(0.1, timer_forceRespawn, dataPack);   
}

resetClientPref(client)
{
  zf_teamPref[client] = ZF_TEAMPREF_NONE;
}

resetClientStates()
{
  for(new i = 0; i <= MAXPLAYERS; i++) resetClientState(i);
}

resetClientState(client)
{ 
  zf_critBonus[client] = 0;
  zf_hoardeBonus[client] = 0;
  if(zf_tForceRespawn[client] != INVALID_HANDLE)
  {
    KillTimer(zf_tForceRespawn[client]);
    zf_tForceRespawn[client] = INVALID_HANDLE;
  }    
  if(zf_tPostSpawn[client] != INVALID_HANDLE)
  {
    KillTimer(zf_tPostSpawn[client]);
    zf_tPostSpawn[client] = INVALID_HANDLE;
  }
  if(zf_tRage[client] != INVALID_HANDLE)
  {
    KillTimer(zf_tRage[client]); 
    zf_tRage[client] = INVALID_HANDLE; 
  }
}

////////////////////////////////////////////////////////////
//
// Utility Functionality
//
////////////////////////////////////////////////////////////
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

public Sort_Preference(client1, client2, const array[], Handle:hndl)
{  
  // Used during round start to sort using client team preference.
  if(zf_teamPref[client1] < zf_teamPref[client2]) return -1;
  if(zf_teamPref[client1] > zf_teamPref[client2]) return 1;
  return 0;
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

Float:getZombieSpeed(TFClassType:class, health, maxHealth)
{
  switch (class)
  {
    case TFClass_Scout:
    { return (health > maxHealth) ? 400.0 : (health == maxHealth) ? 340.0 : 300.0; }
    case TFClass_Spy:
    { return (health > maxHealth) ? 340.0 : (health == maxHealth) ? 280.0 : 240.0; }
    case TFClass_Heavy:
    { return (health > maxHealth) ? 300.0 : (health == maxHealth) ? 240.0 : 200.0; }
  }
  return 0.0;
}

////////////////////////////////////////////////////////////
//
// Help Functionality
//
////////////////////////////////////////////////////////////
public help_printZFInfoChat(client)
{
  if(client == 0)
  {
    PrintToChatAll("\x05[ZF]\x01 This server is running the Zombie Fortress plugin, v%s", PLUGIN_VERSION);
    PrintToChatAll("\x05[ZF]\x01 Type \"zf_menu\" in console for help and preferences!");    
  }
  else
  {
    PrintToChat(client, "\x05[ZF]\x01 Welcome! This server is running the Zombie Fortress plugin, v%s", PLUGIN_VERSION);
    PrintToChat(client, "\x05[ZF]\x01 Type \"zf_menu\" in console for help and preferences!");
  }
}

////////////////////////////////////////////////////////////
//
// Main Menu Functionality
//
////////////////////////////////////////////////////////////
public panel_PrintMain(client)
{
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel, "ZF Main Menu");
  DrawPanelItem(panel, "Help");  
  DrawPanelItem(panel, "Preferences");
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandleMain, 10);
  CloseHandle(panel);
}

public panel_HandleMain(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintHelp(param1);       
      case 2: panel_PrintPrefs(param1);   
      default: return;   
    } 
  } 
}

//
// Main.Preferences Menus
//
public panel_PrintPrefs(client)
{
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel, "ZF Preferences");
  DrawPanelItem(panel, "Team Preference");
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandlePrefs, 10);
  CloseHandle(panel);
}

public panel_HandlePrefs(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintPrefs00(param1);
      default: return;   
    } 
  }
}

public panel_PrintPrefs00(client)
{
  new Handle:panel = CreatePanel();
  SetPanelTitle(panel, "ZF Team Preference");
  
  if(zf_teamPref[client] == ZF_TEAMPREF_NONE)
    DrawPanelItem(panel, "(Current) None", ITEMDRAW_DISABLED);
  else
    DrawPanelItem(panel, "None");

  if(zf_teamPref[client] == ZF_TEAMPREF_SURVIVOR)
    DrawPanelItem(panel, "(Current) Survivors", ITEMDRAW_DISABLED);
  else
    DrawPanelItem(panel, "Survivors");
        
  if(zf_teamPref[client] == ZF_TEAMPREF_ZOMBIE)
    DrawPanelItem(panel, "(Current) Zombies", ITEMDRAW_DISABLED);
  else
    DrawPanelItem(panel, "Zombies");
    
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandlePrefs00, 10);
  CloseHandle(panel);
}

public panel_HandlePrefs00(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: zf_teamPref[param1] = ZF_TEAMPREF_NONE;
      case 2: zf_teamPref[param1] = ZF_TEAMPREF_SURVIVOR;
      case 3: zf_teamPref[param1] = ZF_TEAMPREF_ZOMBIE;
      default: return;   
    } 
  }
}

//
// Main.Help Menu
//
public panel_PrintHelp(client)
{
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel, "ZF Help");
  DrawPanelItem(panel, "ZF Overview");
  DrawPanelItem(panel, "Team: Survivors");
  DrawPanelItem(panel, "Team: Zombies");
  DrawPanelItem(panel, "Classes: Survivors");
  DrawPanelItem(panel, "Classes: Zombies");
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandleHelp, 10);
  CloseHandle(panel);
}

public panel_HandleHelp(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintOverview(param1);
      case 2: panel_PrintTeam(param1, zf_survivorTeam);
      case 3: panel_PrintTeam(param1, zf_zombieTeam);
      case 4: panel_PrintSurClass(param1);
      case 5: panel_PrintZomClass(param1);
      default: return;   
    } 
  } 
}
 
//
// Main.Help.Overview Menus
//
public panel_PrintOverview(client)
{
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel, "ZF Overview");
  DrawPanelText(panel, "----------------------------------------");
  DrawPanelText(panel, "Humans must survive the endless hoarde.");
  DrawPanelText(panel, "When a human dies, they become a zombie.");
  DrawPanelText(panel, "----------------------------------------");
  DrawPanelItem(panel, "Return to Help Menu");  
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandleOverview, 10);
  CloseHandle(panel);
}

public panel_HandleOverview(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintHelp(param1);
      default: return;   
    } 
  } 
}
 
//
// Main.Help.Team Menus
//
public panel_PrintTeam(client, team)
{
  new Handle:panel = CreatePanel();
  if(team == zf_survivorTeam)
  {
    SetPanelTitle(panel, "ZF Survivor Team");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelText(panel, "Survivors consist of soldiers, demomen,");
    DrawPanelText(panel, "pyros, engineers, medics, and snipers.");
    DrawPanelText(panel, "They receive morale boosts for multiple");
    DrawPanelText(panel, "kills in a row. Morale boosts grant crit");
    DrawPanelText(panel, "and health bonuses.");
    DrawPanelText(panel, "----------------------------------------");
  }
  else if(team == zf_zombieTeam)
  {
    SetPanelTitle(panel, "ZF Zombie Team");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelText(panel, "Zombies consist of scouts, heavies, and");
    DrawPanelText(panel, "spies. They receive regeneration and crit");
    DrawPanelText(panel, "bonuses for sticking together as a hoarde.");
    DrawPanelText(panel, "They also possess the Rage ability, which");
    DrawPanelText(panel, "gives health and speed bonuses. Rage is");
    DrawPanelText(panel, "activated by calling for a medic, and");
    DrawPanelText(panel, "recharges after 30s.");
    DrawPanelText(panel, "----------------------------------------");
  }
  DrawPanelItem(panel, "Return to Help Menu");
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandleTeam, 10);
  CloseHandle(panel);
}

public panel_HandleTeam(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintHelp(param1);
      default: return;   
    } 
  } 
}

//
// Main.Help.Class Menus
//
public panel_PrintSurClass(client)
{
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel, "ZF Survivor Classes");
  DrawPanelItem(panel, "Soldier");
  DrawPanelItem(panel, "Sniper");
  DrawPanelItem(panel, "Medic");
  DrawPanelItem(panel, "Demo");
  DrawPanelItem(panel, "Pyro");
  DrawPanelItem(panel, "Engineer");
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandleSurClass, 10);
  CloseHandle(panel);
}

public panel_HandleSurClass(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintClass(param1, TFClass_Soldier);
      case 2: panel_PrintClass(param1, TFClass_Sniper);
      case 3: panel_PrintClass(param1, TFClass_Medic);
      case 4: panel_PrintClass(param1, TFClass_DemoMan);
      case 5: panel_PrintClass(param1, TFClass_Pyro);
      case 6: panel_PrintClass(param1, TFClass_Engineer);
      default: return;   
    } 
  } 
}
      
public panel_PrintZomClass(client)
{
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel, "ZF Zombie Classes");
  DrawPanelItem(panel, "Scout");
  DrawPanelItem(panel, "Heavy");
  DrawPanelItem(panel, "Spy");
  DrawPanelItem(panel, "Close Menu");
  SendPanelToClient(panel, client, panel_HandleZomClass, 10);
  CloseHandle(panel);
}

public panel_HandleZomClass(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintClass(param1, TFClass_Scout);
      case 2: panel_PrintClass(param1, TFClass_Heavy);
      case 3: panel_PrintClass(param1, TFClass_Spy);
      default: return;   
    } 
  } 
}

public panel_PrintClass(client, TFClassType:class)
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
      DrawPanelText(panel, "----------------------------------------");
    }
    case TFClass_Pyro:
    {
      SetPanelTitle(panel, "Pyro [Survivor/Assault]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Flamethrower/Backburner limited to 100.");
      DrawPanelText(panel, "Speed decreased to 240 (from 300).");      
      DrawPanelText(panel, "----------------------------------------");
    }
    case TFClass_DemoMan:
    {
      SetPanelTitle(panel, "Demoman [Survivor/Assault]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Gains 2 pipes per kill.");    
      DrawPanelText(panel, "----------------------------------------");
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
      DrawPanelText(panel, "----------------------------------------");
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
      DrawPanelText(panel, "----------------------------------------");
    }
    case TFClass_Sniper:
    {
      SetPanelTitle(panel, "Sniper [Survivor/Support]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Gains 5 Rifle/2 Huntman ammo per kill.");
      DrawPanelText(panel, "SMG doesn't have to reload.");   
      DrawPanelText(panel, "----------------------------------------");
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
      DrawPanelText(panel, "----------------------------------------");
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
      DrawPanelText(panel, "----------------------------------------");
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
      DrawPanelText(panel, "----------------------------------------");
    }    
    default:
    {
      SetPanelTitle(panel, "Unassigned / Spectator");
      DrawPanelText(panel, "----------------------------------------");      
      DrawPanelText(panel, "Honestly, what were you expecting here?");
      DrawPanelText(panel, "----------------------------------------");
    }
  }
  DrawPanelItem(panel, "Return to Help Menu");
  DrawPanelItem(panel, "Close Menu");  
  SendPanelToClient(panel, client, panel_HandleClass, 8);
  CloseHandle(panel);
}

public panel_HandleClass(Handle:menu, MenuAction:action, param1, param2)
{
  if(action == MenuAction_Select)
  {
    switch(param2)
    {
      case 1: panel_PrintHelp(param1);
      default: return;   
    } 
  } 
}

public dummy_PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{ return; }