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

#pragma semicolon 1

//
// Includes
//
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>

#include "zf_utils.inc"

//
// Plugin Information
//
#define PLUGIN_VERSION "4.0.5.0"
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
#define ZF_TEAMPREF_SURVIVOR  0
#define ZF_TEAMPREF_NONE      1
#define ZF_TEAMPREF_ZOMBIE    2

#define ZF_ROUNDSTATE_INIT    0
#define ZF_ROUNDSTATE_NONE    1
#define ZF_ROUNDSTATE_GRACE   2
#define ZF_ROUNDSTATE_ACTIVE  3

#define ZF_SPAWNSTATE_REST    0
#define ZF_SPAWNSTATE_HUNGER  1
#define ZF_SPAWNSTATE_FRENZY  2

#define PLAYERBUILTOBJECT_ID_DISPENSER  0

//
// State
//

// Global State
new zf_bEnabled;
new zf_bWasMiniRound;
new zf_roundState;
new zf_spawnState;
new zf_spawnRestCounter;
new zf_spawnSurvivorsKilledCounter;
new zf_spawnZombiesKilledCounter;
// Client Preferences
new zf_teamPref[MAXPLAYERS+1];
// Client State
new zf_critBonus[MAXPLAYERS+1];
new zf_hoardeBonus[MAXPLAYERS+1];
new zf_rageTimer[MAXPLAYERS+1];

// Global Timer Handles
new Handle:zf_tMain;            // Periodic
new Handle:zf_tMainSlow;        // Periodic
new Handle:zf_tHoarde;          // Periodic
new Handle:zf_tGraceStartPost;  // Aperiodic
new Handle:zf_tGraceEnd;        // Aperiodic

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
  // Check for necessary extensions
  if(GetExtensionFileStatus("sdkhooks.ext") < 1)
    SetFailState("SDK Hooks is not loaded.");
      
  // Initialize global state
  zf_bEnabled = false;
  zf_bWasMiniRound = false;
  zf_roundState = ZF_ROUNDSTATE_INIT;
  
  // Initialize client state  
  for(new i = 0; i <= MAXPLAYERS; i++)
    resetClientState(i);
    
  // Initialize timer handles
  zf_tMain = INVALID_HANDLE;
  zf_tMainSlow = INVALID_HANDLE;
  zf_tGraceStartPost = INVALID_HANDLE;
  zf_tGraceEnd = INVALID_HANDLE;
  zf_tHoarde = INVALID_HANDLE;
  
  // Register cvars
  CreateConVar("sm_zf_version", PLUGIN_VERSION, "Current Zombie Fortress Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
  zf_cvForceOn = CreateConVar("sm_zf_force_on", "1", "<0/1> Activate ZF for non-ZF maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  zf_cvRatio = CreateConVar("sm_zf_ratio", "0.65", "<0.01-1.00> Percentage of players that start as survivors.", FCVAR_PLUGIN, true, 0.01, true, 1.0);
  zf_cvAllowTeamPref = CreateConVar("sm_zf_allowteampref", "1", "<0/1> Allow use of team preference criteria.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  zf_cvSwapOnPayload = CreateConVar("sm_zf_swaponpayload", "1", "<0/1> Swap teams on payload maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  zf_cvSwapOnAttdef = CreateConVar("sm_zf_swaponattdef", "1", "<0/1> Swap teams on attack/defend maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

  // Initialize Utilities
  utilInit();
    
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
  // Hook Client Console Commands  
  AddCommandListener(hook_zfTeamPref, "zf_teampref");
  // Hook Client Chat / Console Commands
  RegConsoleCmd("zf_menu", cmd_zfMenu); 
}

public OnConfigsExecuted()
{
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
      setZomTeam(_:TFTeam_Red);
      setSurTeam(_:TFTeam_Blue);
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
      setZomTeam(_:TFTeam_Red);
      setSurTeam(_:TFTeam_Blue);
    }
  }
    
  // 4. Set initial round state at the end of OnConfigsExecuted().
  zf_roundState = ZF_ROUNDSTATE_INIT;
}  

public OnMapEnd()
{
  // Close timer handles
  if(zf_tMain != INVALID_HANDLE)
  {      
    CloseHandle(zf_tMain);
    zf_tMain = INVALID_HANDLE;
  }
  if(zf_tMainSlow != INVALID_HANDLE)
  {
    CloseHandle(zf_tMainSlow);
    zf_tMainSlow = INVALID_HANDLE;
  }
  if(zf_tGraceStartPost != INVALID_HANDLE)
  {      
    CloseHandle(zf_tGraceStartPost);
    zf_tGraceStartPost = INVALID_HANDLE;
  }
  if(zf_tGraceEnd != INVALID_HANDLE)
  {
    CloseHandle(zf_tGraceEnd);
    zf_tGraceEnd = INVALID_HANDLE;
  } 
  if(zf_tHoarde != INVALID_HANDLE)
  {
    CloseHandle(zf_tHoarde);
    zf_tHoarde = INVALID_HANDLE;    
  }
}
    
public OnClientConnected(client)
{ 
  if(!zf_bEnabled) return;
  resetClientPref(client);
  resetClientState(client);
}

public OnClientPostAdminCheck(client)
{
  if(!zf_bEnabled) return;
  SDKHook(client, SDKHook_PreThink, OnPreThink);
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
// SDKHooks Callbacks
//
////////////////////////////////////////////////////////////
public Action:OnGetGameDescription(String:gameDesc[64])
{
  if(!zf_bEnabled) return Plugin_Continue;    
  Format(gameDesc, sizeof(gameDesc), "Zombie Fortress (%s)", PLUGIN_VERSION);
  return Plugin_Changed;
}

public OnPreThink(client)
{  
  // Handle speed bonuses.
  if(IsPlayerAlive(client) && !isHindered(client) && !isCharging(client))
  { 
    new Float:speed = clientBaseSpeed(client) + clientBonusSpeed(client);
    SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", speed);
  }
}

////////////////////////////////////////////////////////////
//
// Admin Console Command Handlers
//
////////////////////////////////////////////////////////////
public Action:command_zfEnable(client, args)
{ 
  if(!zf_bEnabled)
  {
    zfEnable();
    ServerCommand("mp_restartgame 10");
  }
}

public Action:command_zfDisable(client, args)
{
  if(zf_bEnabled)
  {
    zfDisable();
    ServerCommand("mp_restartgame 10");  
  }  
}

public Action:command_zfSwapTeams(client, args)
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
    if(zomTeam() == _:TFTeam_Blue)
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
      ChangeClientTeam(client, zomTeam());
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
  
  if(isZom(client))   
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

  else if(isSur(client))
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
    if(IsPlayerAlive(client) && isZom(client))
    {    
      new curH = GetClientHealth(client);
      new maxH = GetEntProp(client, Prop_Data, "m_iMaxHealth");       
  
      if((zf_rageTimer[client] == 0) && (curH >= maxH))
      {
        zf_rageTimer[client] = 30;
        
        SetEntityHealth(client, RoundToCeil(maxH * 1.5));
                  
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

public Action:cmd_zfMenu(client, args)
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
  // 1. Being kritzed / charging override other crit calculations.
  if(isKritzed(client) || isCharging(client))
    return Plugin_Continue;
  
  // 2. Handle crit bonus
  result = (zf_critBonus[client] > GetRandomInt(0,99));
  return Plugin_Changed;  
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  decl players[MAXPLAYERS];
  decl playerCount;
  decl surCount;
 
  if(!zf_bEnabled) return Plugin_Continue; 

  //
  // Handle round state.
  // + event_RoundStart() is called twice on new map loads.
  //
  if(zf_roundState == ZF_ROUNDSTATE_INIT) 
  {
    zf_roundState = ZF_ROUNDSTATE_NONE;
    return Plugin_Continue;
  }
  else
  {
    zf_roundState = ZF_ROUNDSTATE_GRACE;
    PrintToChatAll("\x05[ZF]\x01 Grace period begun. Survivors can change classes.");  
  }
  
  // 1. Assign players to zombie and survivor teams.
  //    + Only assign teams if last round was a full round.
  //
  if(!zf_bWasMiniRound)
  {
    // 1a. Find all active players.
    playerCount = 0;
    for(new i = 1; i <= MaxClients; i++)
    {
      if(IsClientInGame(i) && (GetClientTeam(i) > 1))
      {
        players[playerCount++] = i;  
        if(IsFakeClient(i))
          zf_teamPref[i] = ZF_TEAMPREF_NONE;
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
      spawnClient(players[i], surTeam());   
    for(new i = surCount; i < playerCount; i++)
      spawnClient(players[i], zomTeam());   
  }
     
  // 2. Handle map entity adjustment.
  //    + Disable all resupply cabinets.
  new index = -1;
  while((index = FindEntityByClassname(index, "func_regenerate")) != -1)
    AcceptEntityInput(index, "Disable");

  // 3. Handle zombie spawn state.  
  zf_spawnState = ZF_SPAWNSTATE_HUNGER;
  zf_spawnSurvivorsKilledCounter = 1;
  setTeamRespawnTime(zomTeam(), 10.0);
         
  // 4. Handle grace period timers.
  if(zf_tGraceStartPost != INVALID_HANDLE)
    CloseHandle(zf_tGraceStartPost);
  zf_tGraceStartPost = CreateTimer(1.0, timer_graceStartPost); 
  
  if(zf_tGraceEnd != INVALID_HANDLE)
    CloseHandle(zf_tGraceEnd);      
  zf_tGraceEnd = CreateTimer(20.0, timer_graceEnd);  
    
  return Plugin_Continue;
}

//
// Round End Event
//
public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;
  
  zf_bWasMiniRound = !GetEventBool(event, "full_round");
  zf_roundState = ZF_ROUNDSTATE_NONE;        
  
  return Plugin_Continue;
}

//
// Player Spawn Event
//
public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{   
  if(!zf_bEnabled) return Plugin_Continue;  
      
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new TFClassType:clientClass = TF2_GetPlayerClass(client);

  resetClientState(client);
        
  // 2. Prevent players spawning on survivors if round has started.
  //    Prevent players spawning on survivors as an invalid class.
  //    Prevent players spawning on zombies as an invalid class.
  if(isSur(client))
  {
    if(zf_roundState == ZF_ROUNDSTATE_ACTIVE)
    {
      spawnClient(client, zomTeam());
      return Plugin_Continue;
    }
    if(!validSurvivor(clientClass))
    {
      spawnClient(client, surTeam()); 
      return Plugin_Continue;
    }      
  }
  else if(isZom(client))
  {
    if(!validZombie(clientClass))
    {
      spawnClient(client, zomTeam()); 
      return Plugin_Continue;
    }
  }   

  // 3. Handle valid, post spawn logic
  CreateTimer(0.1, timer_postSpawn, client); 
      
  return Plugin_Continue; 
}

//
// Player Death Event
//
public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!zf_bEnabled) return Plugin_Continue;   
  
  if(zf_roundState != ZF_ROUNDSTATE_ACTIVE) return Plugin_Continue;    
  
  decl victim;       
  decl killers[2]; 
  decl TFClassType:killerClass;
  decl curH;
  decl maxH;
  decl ammo;
  
  // 1. Handle survivor death rules.
  victim = GetClientOfUserId(GetEventInt(event, "userid"));
  killers[0] = GetClientOfUserId(GetEventInt(event, "attacker")); 
  killers[1] = GetClientOfUserId(GetEventInt(event, "assister"));       
  if(isSur(victim))
  {
    // Note if survivor killed by zombie.    
    if((killers[0] > 0) && isZom(killers[0]))
    {
      zf_spawnSurvivorsKilledCounter--;
    }
    
    // Transfer player to zombie team.
    CreateTimer(6.0, timer_zombify, victim);
  }
  
  // 2. Handle zombie death rules.
  else if(isZom(victim))
  {      
    // Note if zombie killed by survivor.
    if((killers[0] > 0) && isSur(killers[0]))
    {
      zf_spawnZombiesKilledCounter--;
    }
    
    if(killers[0] == killers[1]) killers[1] = 0; // Avoid rare self assist.    
    for(new i = 0; i < 2; i++)
    {                 
      if((killers[i] > 0) && IsClientInGame(killers[i]) && IsPlayerAlive(killers[i]))
      {                  
        // 2a. Handle ammo kill bonuses.
        //     Soldiers receive 2 rockets per kill.
        //     Demomen receive 2 pipes per kill.
        //     Snipers receive 5 rifle / 2 arrows per kill.
        killerClass = TF2_GetPlayerClass(killers[i]);        
        switch(killerClass)
        {
          case TFClass_Soldier:
          {
            ammo = GetEntData(killers[i], (zf_oReserveAmmo + 4));
            ammo = min((ammo + 2), 20);
            SetEntData(killers[i], (zf_oReserveAmmo + 4), ammo);
          }
          case TFClass_DemoMan:
          {
            ammo = GetEntData(killers[i], (zf_oReserveAmmo + 4));
            ammo = min((ammo + 2), 16);
            SetEntData(killers[i], (zf_oReserveAmmo + 4), ammo);            
          }
          case TFClass_Sniper:
          {     
            if(isEquipped(killers[i], Rifle))
            {
              ammo = GetEntData(killers[i], (zf_oReserveAmmo + 4)); 
              ammo = min((ammo + 5), 25);
              SetEntData(killers[i], (zf_oReserveAmmo + 4), ammo);
            }
            else if(isEquipped(killers[i], Huntsman))
            {
              ammo = GetEntData(killers[i], (zf_oReserveAmmo + 4)); 
              ammo = min((ammo + 2), 12);
              SetEntData(killers[i], (zf_oReserveAmmo + 4), ammo);
            }
          }
        } // switch
               
        // 2b. Handle morale bonuses
        //     Each kill grants a small health bonus and increases
        //     current crit bonus.
        curH = GetClientHealth(killers[i]);
        maxH = GetEntProp(killers[i], Prop_Data, "m_iMaxHealth"); 
        if(curH < maxH)
        {
          curH += zf_critBonus[killers[i]] * 2;
          curH = min(curH, maxH);        
          SetEntityHealth(killers[i], curH);
        }
        zf_critBonus[killers[i]] = min(100, zf_critBonus[killers[i]] + 5); 
                   
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

//
// Object Built Event
//
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

public Action:timer_mainSlow(Handle:timer) // 4 min
{ 
  if(!zf_bEnabled) return Plugin_Continue;  
  help_printZFInfoChat(0);
  
  return Plugin_Continue;
}

public Action:timer_hoarde(Handle:timer) // 1/5th Hz
{  
  if(!zf_bEnabled) return Plugin_Continue;
  handle_hoardeBonus();
  
  return Plugin_Continue;  
}

////////////////////////////////////////////////////////////
//
// Aperiodic Timer Callbacks
//
////////////////////////////////////////////////////////////
public Action:timer_postSpawn(Handle:timer, any:client)
{         
  if(IsClientInGame(client) && IsPlayerAlive(client))
  {      
    // 1. Handle class weapon restrictions
    if(isZom(client))
    {
      stripToMelee(client);  
    }
  }
    
  return Plugin_Continue; 
}

public Action:timer_graceStartPost(Handle:timer)
{ 
  zf_tGraceStartPost = INVALID_HANDLE;
  
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

public Action:timer_graceEnd(Handle:timer)
{
  zf_tGraceEnd = INVALID_HANDLE;
  
  zf_roundState = ZF_ROUNDSTATE_ACTIVE;  
  PrintToChatAll("\x05[ZF]\x01 Grace period complete. Survivors can no longer change classes.");
  
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

public Action:timer_zombify(Handle:timer, any:client)
{   
  if(IsClientInGame(client))
  {
    PrintToChat(client, "\x05[ZF]\x01 You have perished, zombifying....");
    spawnClient(client, zomTeam());
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
    if(IsClientInGame(i) && IsPlayerAlive(i) && isZom(i))
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
    if(IsClientInGame(i) && IsPlayerAlive(i) && isSur(i))
    {
      anySurvivorAlive = true;
      break;
    }
  }
   
  // 2. If no survivors are alive and at least 1 zombie is playing,
  //    end round with zombie win.
  if(!anySurvivorAlive && (GetTeamClientCount(zomTeam()) > 0))
  {
    index = FindEntityByClassname(-1, "team_control_point_master");
    if(index == -1)
    {
      index = CreateEntityByName("team_control_point_master");
      DispatchSpawn(index);
    }
    
    if(index == -1)
    {
      LogMessage("[ZF] Can't create 'team_control_point_master,' can't end round!");
    }
    else
    {
      AcceptEntityInput(index, "Enable");
      SetVariantInt(zomTeam());
      AcceptEntityInput(index, "SetWinner"); 
    }
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
        setTeamRespawnTime(zomTeam(), 8.0);                
      }
    }
    
    // 1b. Hunger state (medium spawn times). Transition to Frenzy
    //     state after one survivor is killed.
    case ZF_SPAWNSTATE_HUNGER:
    {
      if(zf_spawnSurvivorsKilledCounter <= 0)
      {
        zf_spawnState = ZF_SPAWNSTATE_FRENZY;
        zf_spawnZombiesKilledCounter = (2 * GetTeamClientCount(zomTeam()));
        PrintToChatAll("\x05[ZF SPAWN]\x01 Zombies are Frenzied!"); 
        setTeamRespawnTime(zomTeam(), 0.0);
      }
    }
    
    // 1c. Frenzy state (short spawn times). Transition to Rest
    //     state after a given number of zombies are killed.
    case ZF_SPAWNSTATE_FRENZY:
    {
      if(zf_spawnZombiesKilledCounter <= 0)
      {
        zf_spawnState = ZF_SPAWNSTATE_REST;
        zf_spawnRestCounter = min(45, (3 * GetTeamClientCount(zomTeam())));
        PrintToChatAll("\x05[ZF SPAWN]\x01 Zombies are Resting..."); 
        setTeamRespawnTime(zomTeam(), 16.0);        
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
    if(IsClientInGame(i) && IsPlayerAlive(i) && isSur(i))
    {
      // 1. Handle survivor weapon rules.
      //    SMG doesn't have to reload. 
      //    Syringe gun / blutsauger don't have to reload. 
      //    Flamethrower / backburner ammo limited to 125.
      switch(TF2_GetPlayerClass(i))
      {
        case TFClass_Sniper:
        {
          clientWeapon = GetPlayerWeaponSlot(i, 1);            
          if((clientWeapon > 0) && isEquipped(i, SMG))
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
          if(reserveAmmo > 125)
          {
            ammoAdj = max((reserveAmmo - 10), 125);
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
  decl curH;
  decl maxH; 
  decl bonus;
  
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i) && IsPlayerAlive(i) && isZom(i))
    {   
      clientClass = TF2_GetPlayerClass(i);
      curH = GetClientHealth(i);
      maxH = GetEntProp(i, Prop_Data, "m_iMaxHealth");
              
      // 1. Handle zombie regeneration.
      //    Zombies regenerate health based on class and number of nearby
      //    zombies (hoarde bonus). Zombies decay health when overhealed.
      bonus = 0;
      if(curH < maxH)
      {
        switch(clientClass)
        {
          case TFClass_Scout: bonus = 2 + (1 * zf_hoardeBonus[i]);
          case TFClass_Heavy: bonus = 4 + (3 * zf_hoardeBonus[i]);
          case TFClass_Spy:   bonus = 2 + (1 * zf_hoardeBonus[i]);
        }        
        curH += bonus;
        curH = min(curH, maxH);
        SetEntityHealth(i, curH);
      }
      else if(curH > maxH)
      {
        switch(clientClass)
        {
          case TFClass_Scout: bonus = -3;
          case TFClass_Heavy: bonus = -7;
          case TFClass_Spy:   bonus = -3;
        }          
        curH += bonus;
        curH = max(curH, maxH); 
        SetEntityHealth(i, curH);
      }

      // 2. Handle zombie crit rate bonus.
      //    Zombies receive crit bonus based on number of nearby zombies
      //    (hoarde bonus). Zombies only receive this bonus at full health
      //    or greater.
      bonus = 0;
      if(curH >= maxH)
      {
        switch(clientClass)
        {
          case TFClass_Scout: bonus = 5 + (1 * zf_hoardeBonus[i]);
          case TFClass_Heavy: bonus = 10 + (5 * zf_hoardeBonus[i]);
          case TFClass_Spy:   bonus = 5 + (1 * zf_hoardeBonus[i]);
        }
      }   
      zf_critBonus[i] = bonus;
      
      // 3. Handle zombie rage timer
      //    Rage recharges every 30s.
      if(zf_rageTimer[i] > 0)
      {
        if(zf_rageTimer[i] == 1)
        {
          PrintHintText(i, "Rage is ready!");
        }
        zf_rageTimer[i]--;
      }      
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
    if(IsClientInGame(i) && IsPlayerAlive(i) && isZom(i))
    {              
      player[playerCount] = i;
      playerHoardeId[playerCount] = -1;
      getClientPos(i, playerPos[playerCount]);
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
    
  CloseHandle(hStack);    
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
  
  setSurTeam(_:TFTeam_Red);
  setZomTeam(_:TFTeam_Blue);
    
  for(new i = 0; i <= MAXPLAYERS; i++)
    resetClientState(i);
    
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
  ServerCommand("sm_cvar tf_boost_drain_time 3600"); // Locked
  // Spy
  ServerCommand("sm_cvar tf_spy_invis_time 0.5"); // Locked 
  ServerCommand("sm_cvar tf_spy_invis_unstealth_time 0.75"); // Locked 
  ServerCommand("sm_cvar tf_spy_cloak_no_attack_time 1.0"); // Locked 
    
  // [Re]Enable periodic timers.
  if(zf_tMain != INVALID_HANDLE)    
    CloseHandle(zf_tMain);
  zf_tMain = CreateTimer(1.0, timer_main, _, TIMER_REPEAT); 
  
  if(zf_tMainSlow != INVALID_HANDLE)
    CloseHandle(zf_tMainSlow);    
  zf_tMainSlow = CreateTimer(240.0, timer_mainSlow, _, TIMER_REPEAT);
  
  if(zf_tHoarde != INVALID_HANDLE)
    CloseHandle(zf_tHoarde);
  zf_tHoarde = CreateTimer(5.0, timer_hoarde, _, TIMER_REPEAT); 
}

zfDisable()
{  
  zf_bEnabled = false;
  zf_bWasMiniRound = false;
  zf_roundState = ZF_ROUNDSTATE_NONE;  
  
  for(new i = 0; i <= MAXPLAYERS; i++)
    resetClientState(i);
    
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
    CloseHandle(zf_tMain);
    zf_tMain = INVALID_HANDLE;
  }
  if(zf_tMainSlow != INVALID_HANDLE)
  {
    CloseHandle(zf_tMainSlow);
    zf_tMainSlow = INVALID_HANDLE;
  }
  if(zf_tHoarde != INVALID_HANDLE)
  {
    CloseHandle(zf_tHoarde);
    zf_tHoarde = INVALID_HANDLE;
  }

  // Enable resupply lockers.
  new index = -1;
  while((index = FindEntityByClassname(index, "func_regenerate")) != -1)
    AcceptEntityInput(index, "Enable");
}

////////////////////////////////////////////////////////////
//
// Utility Functionality
//
////////////////////////////////////////////////////////////
public Sort_Preference(client1, client2, const array[], Handle:hndl)
{  
  // Used during round start to sort using client team preference.
  if(zf_teamPref[client1] < zf_teamPref[client2]) return -1;
  if(zf_teamPref[client1] > zf_teamPref[client2]) return 1;
  return 0;
}

zfSwapTeams()
{
  if(zomTeam() == _:TFTeam_Blue)
  {
    setSurTeam(_:TFTeam_Blue);
    setZomTeam(_:TFTeam_Red);    
  }
  else
  {
    setSurTeam(_:TFTeam_Red);
    setZomTeam(_:TFTeam_Blue);    
  }
}

resetClientPref(client)
{
  zf_teamPref[client] = ZF_TEAMPREF_NONE;
}

resetClientState(client)
{ 
  zf_critBonus[client] = 0;
  zf_hoardeBonus[client] = 0;
  zf_rageTimer[client] = 0;
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
    PrintToChat(client, "\x05[ZF]\x01 This server is running the Zombie Fortress plugin, v%s", PLUGIN_VERSION);
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
      case 2: panel_PrintTeam(param1, surTeam());
      case 3: panel_PrintTeam(param1, zomTeam());
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
  if(team == surTeam())
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
  else if(team == zomTeam())
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
      DrawPanelText(panel, "Bat/Sandman/Bonk!/Crit-a-Cola only.");
      DrawPanelText(panel, "Rage ability: Increase speed and health");
      DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
      DrawPanelText(panel, "Speed reduced to 340 (from 400).");    
      DrawPanelText(panel, "----------------------------------------");
    }
    case TFClass_Heavy:
    {
      SetPanelTitle(panel, "Heavy [Zombie]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Fists/KGB/Sandvich/Dalokohs Bar only.");
      DrawPanelText(panel, "Rage ability: Increase speed and health");
      DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
      DrawPanelText(panel, "Speed increased to 240 (from 230).");  
      DrawPanelText(panel, "----------------------------------------");
    }
    case TFClass_Spy:
    {
      SetPanelTitle(panel, "Spy [Zombie]");
      DrawPanelText(panel, "----------------------------------------");
      DrawPanelText(panel, "Knife/Invis Watch/Cloak and Dagger only.");
      DrawPanelText(panel, "Rage ability: Increase speed and health");
      DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
      DrawPanelText(panel, "Speed reduced to 280 (from 300).");
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