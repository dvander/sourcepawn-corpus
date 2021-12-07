/*
 * Adaptive Respawn
 *
 * Written By Snow
 * Parts taken from "TF2 Fast Respawns" by WoZeR
 */

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#define CV_TAG_STRING "respawntimes"

// TF2 map modes
const MM_UNKNOWN = 0
const MM_DEFAULT = 1
const MM_PUSH = 2
const MM_AD = 3
const MM_FAST = 4
const MM_ARENA = 5
const MM_DM = 6

// TF2 Teams
const TM_SPEC = 0
const TM_RED = 2
const TM_BLU = 3

// CVARs
new Handle:cvEnabled
new Handle:cvArenaDm
new Handle:cvOverrideMode
new Handle:cvMinRespawn
new Handle:cvMaxRespawn

new Handle:cvMinRamp
new Handle:cvMaxRamp

new Handle:cvPushAddTimelimit
new Handle:cvPushAddMin

new Handle:cvPushTailRamp
new Handle:cvRoundTarget
new Handle:cvMinFastTime
new Handle:cvEventRamp
new Handle:cvPushCapCooldown

new Handle:cvTags
new Handle:cvArenaQueue
new Handle:cvStalemateMeleeOnly

new bool:tagsRecursing = false

// Active variables
new mapMode = MM_UNKNOWN
new Float:roundStartTime = 0.0
new Float:lastCapTime = 0.0
new bool:inSuddenDeath = false

#define PLUGIN_VERSION "0.2.5"

// Plugin definitions
public Plugin:myinfo = 
{
  name = "Adaptive Respawn",
  author = "Snow",
  description = "Adaptive Respawn for TF2",
  version = PLUGIN_VERSION,
  url = "http://www.sourcemod.com"
}

public OnPluginStart()
{
  CreateConVar("sm_adr_version", PLUGIN_VERSION, "Adaptive Respawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
  
  cvEnabled = CreateConVar("sm_adr_enabled", "1", "Enable adaptive respawn")
  
  cvArenaDm = CreateConVar("sm_adr_arena_dm", "0", "Play arena maps as deathmatch")
  cvOverrideMode = CreateConVar("sm_adr_mode_override", "0", "Override respawn mode. (0=AUTO, 1=DEFAULT, 2=PUSH, 3=A/D, 4=FAST)")
  cvMinRespawn = CreateConVar("sm_adr_min_respawn", "7", "Min respawn time")
  cvMaxRespawn = CreateConVar("sm_adr_max_respawn", "14", "Max respawn time")
  
  cvMinFastTime = CreateConVar("sm_adr_min_fast", "60", "Minimum amount of time at start of map to have fast respawn (secs)")
  
  cvMinRamp = CreateConVar("sm_adr_min_ramp", "240", "A/D maps: Minimum time to gradually increase respawns times over (secs)")
  cvMaxRamp = CreateConVar("sm_adr_max_ramp", "1200", "A/D maps: Maximum time to gradually increase respawns times over (secs)")  
  
  cvPushAddTimelimit = CreateConVar("sm_adr_push_add_timelimit", "15", "Push maps: After round has lasted this long stop adding to round timer (mins)")
  cvPushAddMin = CreateConVar("sm_adr_push_add_min", "10", "Push maps: Amount of time to add when timelimit is reached (secs)")
  
  cvRoundTarget = CreateConVar("sm_adr_round_target", "15", "Try to make rounds shorter than this by adapting respawn times (mins)")
  cvPushTailRamp = CreateConVar("sm_adr_tail_ramp", "300", "Push maps: Time to gradually increase respawn times over at end of round (secs)")
  cvEventRamp = CreateConVar("sm_adr_event_ramp", "180", "Time to increase respawns over after a cap (secs)")
  cvPushCapCooldown = CreateConVar("sm_adr_push_cap_cooldown", "0", "Push maps: After a cap ramp down the respawn times over period (secs)")
  
  cvTags = FindConVar("sv_tags");
  cvArenaQueue = FindConVar("tf_arena_use_queue")
  cvStalemateMeleeOnly = FindConVar("mp_stalemate_meleeonly")
  
  // To start respawn timer
  HookEvent("player_death", EventPlayerDeath)
  
  // Stalemate and humiliation
  HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy) // Disable spawning during suddendeath. Could be fun if enabled with melee only.
  HookEvent("teamplay_round_win", EventSuddenDeath, EventHookMode_PostNoCopy) // Disable spawning during beat the crap out of the losing team mode. Fun if on :)
  HookEvent("teamplay_game_over", EventSuddenDeath, EventHookMode_PostNoCopy) // Disable spawning
  HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy) // Enable fast spawning
  
  // For respawn time calculations
  HookEvent("teamplay_round_active", EventRoundPlaying, EventHookMode_PostNoCopy)
  HookEvent("teamplay_setup_finished", EventRoundPlaying, EventHookMode_PostNoCopy)
  HookEvent("arena_round_start", EventRoundPlaying, EventHookMode_PostNoCopy)
  HookEvent("teamplay_point_captured", EventPointCaptured, EventHookMode_PostNoCopy)
  HookEvent("ctf_flag_captured", EventPointCaptured, EventHookMode_PostNoCopy)
  
  HookEvent("player_team", EventChangeTeam)
    
  // For limiting push map time added.
  HookEvent("teamplay_timer_time_added", EventTimerUpdated)
  
  if (cvTags != INVALID_HANDLE)
  {
    HookConVarChange(cvTags, CallbackTags);
  }
}

public OnMapStart()
{
  // Detect the type of map
  new String:mapName[PLATFORM_MAX_PATH] 
  GetCurrentMap(mapName, PLATFORM_MAX_PATH - 1)
  
  mapMode = GetConVarInt(cvOverrideMode)
  
  if (mapMode != MM_UNKNOWN)
  {
    // Auto-detect was overridden.
  }
  else if (StrStartsWith(mapName, "plr_") ||
      StrStartsWith(mapName, "tc_") ||
      StrStartsWith(mapName, "es_"))
  {
    mapMode = MM_AD
  }
  else if (StrStartsWith(mapName, "ph_"))
  {
    mapMode = MM_ARENA
  }
  else if (StrStartsWith(mapName, "sd_"))
  {
    mapMode = MM_PUSH
  }
  else if (StrStartsWith(mapName, "ctf_"))
  {
    if (IsCtfAttackDefendMap())
    {
      mapMode = MM_AD
    }
    else
    {
      // mapMode = MM_FAST
      mapMode = MM_PUSH
    }
  }
  else if (StrStartsWith(mapName, "pl_") ||
      StrStartsWith(mapName, "cp_"))
  {
    if (IsAttackDefendMap())
    {
      mapMode = MM_AD
    }
    else
    {
      mapMode = MM_PUSH
    }
  }
  else
  {
    if (IsArenaMap())
    {
      if (GetConVarBool(cvArenaDm))
      {
        mapMode = MM_DM
      }
      else
      {
        mapMode = MM_ARENA
      }
    }
    else if (IsAttackDefendMap())
    {
      mapMode = MM_AD
    }
    else if (IsCtfAttackDefendMap())
    {
      mapMode = MM_AD
    }
    else
    {
      mapMode = MM_FAST
    }
  }
  
  inSuddenDeath = false
  roundStartTime = 0.0
  lastCapTime = 0.0
  
  LogMessage("Detected map mode: %d", mapMode)
}

public bool:IsArenaMap()
{
  new iEnt = FindEntityByClassname(-1, "tf_logic_arena")
  
  if (iEnt == -1)
  {
    return false
  }
  else
  {
    return true
  }
}

public bool:IsCtfAttackDefendMap()
{
  new iEnt = FindEntityByClassname(-1, "tf_logic_hybrid_ctf_cp")
  
  if (iEnt != -1)
  {
    return true
  }
  
  new iTeam
  new bluFlags = 0
  new redFlags = 0
  new neuFlags = 0
  while ((iEnt = FindEntityByClassname(iEnt, "item_teamflag")) != -1)
  {
    iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeamNum")
    if (iTeam == TM_BLU)
    {
      bluFlags++
    }
    else if (iTeam == TM_RED)
    {
      redFlags++
    }
    else
    {
      neuFlags++
    }
  }
  
  if (bluFlags != redFlags)
  {
    return true
  }
  else
  {
    return false
  }
}

public bool:IsAttackDefendMap()
{
  new iEnt = -1
  
  new iTeam
  new bluPoints = 0
  new redPoints = 0
  new neuPoints = 0
  while ((iEnt = FindEntityByClassname(iEnt, "team_control_point")) != -1)
  {
    iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeamNum")
    if (iTeam == TM_BLU)
    {
      bluPoints++
    }
    else if (iTeam == TM_RED)
    {
      redPoints++
    }
    else
    {
      neuPoints++
    }
  }
  
  if (bluPoints != redPoints)
  {
    return true
  }
  else
  {
    return false
  }
}

public Action:EventTimerUpdated(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Skip if plugin disabled or in stalemate
  if (!GetConVarBool(cvEnabled) || inSuddenDeath) 
  {
    return Plugin_Continue
  }

  if (mapMode == MM_PUSH)
  {
    new Float:roundTimePlayed = GetGameTime() - roundStartTime
    
    new Float:timeAdded = 1.0 * GetEventInt(event, "seconds_added")
    
    // Prevent recusion, and ignore small values that might cause rounding problems.
    if (timeAdded <= 3.0)
    {
      return Plugin_Continue
    }  
    
    new Float:pushTimelimit = GetConVarInt(cvPushAddTimelimit) * 60.0
    new Float:minTimeAdded = GetConVarFloat(cvPushAddMin) 
    
    if (minTimeAdded < 1.0)
    {
      minTimeAdded = 1.0
    } 
    
    // 0 means disabled.
    if (pushTimelimit > 0.0)
    {
      new Float:timeRemaining = pushTimelimit - roundTimePlayed
      
      // Work out addLimit, the maximum amount of time we allow to be added.
      // Note: might be negative here
      new Float:addLimit = timeRemaining / 2
      
      // Note: Always positive here
      if (addLimit < minTimeAdded)
      {
        addLimit = minTimeAdded
      }
      
      if (timeAdded > addLimit)
      {
        new Float:excess = timeAdded - addLimit     
        
        if (excess > 1.0)
        {
          new iExcess = 0 - RoundToFloor(excess)    
          
          // LogMessage("Timer update reduced from %f by %d (limit %f)", timeAdded, iExcess, addLimit)  
        
          new iTimer = GetEventInt(event, "timer")
        
          // Add a negative time to remove the excess.
          SetVariantInt(iExcess)
        
          // Remove the time from the clock.
          AcceptEntityInput(iTimer, "AddTime")
        }
      }
    }
  }
  
  return Plugin_Continue
}

//Player died, create a timer to respawn the player
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Skip if plugin disabled or in stalemate
  if (!GetConVarBool(cvEnabled) || inSuddenDeath) 
  {
    return Plugin_Continue
  }
  
  if (roundStartTime <= 0.0)
  {
    return Plugin_Continue
  }
  
  new Float:currentTime = GetGameTime()  
  new Float:roundTimePlayed = currentTime - roundStartTime
  if (roundStartTime <= 0.0)
  {
    roundTimePlayed = 0.0
  }
  
  new Float:minRespawn = GetConVarFloat(cvMinRespawn)
  new Float:maxRespawn = GetConVarFloat(cvMaxRespawn)
  
  if (minRespawn < 2.0)
  {
    minRespawn = 2.0
  }
  if (minRespawn > 30.0)
  {
    minRespawn = 30.0
  }
  if (maxRespawn > 30.0)
  {
    maxRespawn = 30.0
  }
  if (minRespawn > maxRespawn)
  {
    maxRespawn = minRespawn
  }
  
  // The ratio of minRespawn (0.0) to maxRespawn (1.0)
  new Float:rampRatio = 0.0

  if (mapMode == MM_PUSH)
  { 
    new Float:minFastTime = GetConVarFloat(cvMinFastTime)    
    new Float:minRampStart = roundStartTime + minFastTime
      
    new Float:pushEventRamp = GetConVarFloat(cvEventRamp)
    if (pushEventRamp > 0)
    {
      new Float:eventRampStart = lastCapTime
      if (eventRampStart < minRampStart)
      {
        eventRampStart = minRampStart
      }
      
      new Float:eventRampEnd = eventRampStart + pushEventRamp
      
      rampRatio = CalcRampRatio(eventRampEnd, pushEventRamp, currentTime, false, rampRatio)
    }
    
    new Float:pushTailLength = GetConVarFloat(cvPushTailRamp)  
    if (pushTailLength > 0.0)
    {
      new Float:roundTarget = GetConVarInt(cvRoundTarget) * 60.0
      if (roundTarget < 1)
      {
        roundTarget = 15 * 60.0
      } 
      new Float:roundEndTime = roundStartTime + roundTarget
      
      new Float:rampStart = roundEndTime - pushTailLength
      
      if (rampStart < minRampStart)
      {
        rampStart = minRampStart
      }
      
      rampRatio = CalcRampRatio(rampStart + pushTailLength, pushTailLength, currentTime, false, rampRatio)
    }
    
    if (roundTimePlayed >= minFastTime)
    {
      new Float:capCooldown = GetConVarFloat(cvPushCapCooldown)      
      if (capCooldown > 0 && lastCapTime > 0)
      {
        rampRatio = CalcRampRatio(lastCapTime + capCooldown, capCooldown, currentTime, true, rampRatio)
      }   
    }
  }
  else if (mapMode == MM_AD)
  { 
    new Float:roundEndTime = GetRoundEndTime()
    new Float:roundLength = roundEndTime - roundStartTime
    if (roundLength < 90 || roundLength > 2000)
    {
      new Float:roundTarget = GetConVarInt(cvRoundTarget) * 60.0
      if (roundTarget < 1)
      {
        roundTarget = 15 * 60.0
      }
      roundEndTime = roundStartTime + roundTarget
    }
    
    // LogMessage("AD respawn: %f %f %f %f", roundStartTime, roundEndTime, roundTimePlayed, currentTime)     

    new Float:minFastTime = GetConVarFloat(cvMinFastTime)
    new Float:minRampLength = GetConVarFloat(cvMinRamp)
    new Float:maxRampLength = GetConVarFloat(cvMaxRamp)
    
    new Float:rampStartTime = roundStartTime + minFastTime
    if (lastCapTime > rampStartTime)
    {
      rampStartTime = lastCapTime
    }
    
    new Float:roundRampLength = roundEndTime - rampStartTime
    
    if (roundRampLength < minRampLength)
    {
      roundRampLength = minRampLength
    }
    else if (roundRampLength > maxRampLength)
    {
      roundRampLength = maxRampLength
    }
    
    rampRatio = CalcRampRatio(rampStartTime + roundRampLength, roundRampLength, currentTime, false, rampRatio)
  }
  else if (mapMode == MM_FAST)
  {    
    rampRatio = 0.0
  }
  else if (mapMode == MM_DM)
  {
    new timeleft = 0
    GetMapTimeLeft(timeleft)    
    
    if (timeleft > 0)
    {
      rampRatio = 0.0
    }
    else
    {
      inSuddenDeath = true;
      // Stop spawning once the timelimit has been reached.
      return Plugin_Continue
    }    
  }
  else if (mapMode == MM_ARENA)
  {
    return Plugin_Continue
  }
  else
  {
    return Plugin_Continue
  }
  
  // Correct any errors we made.
  if (rampRatio < 0.0)
  {
    rampRatio = 0.0
  }
  else if (rampRatio > 1.0)
  {
    rampRatio = 1.0
  }
  
  new Float:respawnTime = (maxRespawn - minRespawn) * rampRatio + minRespawn  
  
  // LogMessage("Respawn limit: %f %f", rampRatio, respawnTime)  

  new userId = GetEventInt(event, "userid")
  
  // Respawn the player at the specified time
  CreateTimer(respawnTime, SpawnPlayerTimer, userId, TIMER_FLAG_NO_MAPCHANGE) 
  
  return Plugin_Continue
}

public Action:SpawnPlayerTimer(Handle:timer, any:userId)
{
  new client = GetClientOfUserId(userId)
  if (client > 0)
  {
    // Respawn the player if he is in game and is dead.
    if(!inSuddenDeath && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
    {
      new team = GetClientTeam(client)
      if(team == TM_RED || team == TM_BLU)
      {
        TF2_RespawnPlayer(client)
      }
    }
  }
  return Plugin_Continue
} 

// Calculate how far through the respawn time ramp-up we are.
// endTime: Time to use full respawn times
// rampLen: How long to gradually increase from min times to max times
// currentTime: The current time (OK if before the ramp or after the ramp)
// cooldown: Ramp goes down instead of up (from max to min)
// currentRatio: Return this if it higher than the calculated value
//
// return value between 0.0 and 1.0
Float:CalcRampRatio(Float:endTime, Float:rampLen, Float:currentTime, bool:cooldown, Float:currentRatio)
{
  new Float:ourRatio = 0.0
  new Float:startTime = endTime - rampLen
  
  if (currentTime >= endTime)
  {
    ourRatio = 1.0
  }
  else if (currentTime <= startTime)
  {
    ourRatio = 0.0
  }
  else
  {
    ourRatio = (currentTime - startTime) / rampLen
  }
  
  if (cooldown)
  {
    ourRatio = 1 - ourRatio
  }
  
  if (ourRatio > currentRatio)
  {
    return ourRatio
  }
  else
  {
    return currentRatio
  }
}

Float:GetRoundEndTime()
{
  new iTimer = -1
  new Float:endTime = -1.0
  
  while ((iTimer = FindEntityByClassname(iTimer, "team_round_timer")) != -1)
  {
    // Some maps have multiple timers (eg tc_meridian)
    new inHud = GetEntPropEnt(iTimer, Prop_Send, "m_bShowInHUD")
    if (inHud)
    {
      endTime = GetEntPropFloat(iTimer, Prop_Send, "m_flTimerEndTime")
    }
  }
  return endTime
}

public Action:EventSuddenDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Don't respawn players during sudden death mode
  inSuddenDeath = true
  
  return Plugin_Continue
}

public Action:EventRoundReset(Handle:event, const String:name[], bool:dontBroadcast)
{
  // LogMessage("Round reset: %f", GetGameTime())
  
  // Skip if plugin disabled.
  if (mapMode == MM_DM && GetConVarBool(cvEnabled)) 
  {
    SetConVarBool(cvArenaQueue, false, true, true)
    SetConVarInt(cvStalemateMeleeOnly, 0, true, true);
  }
  
  // Time to respawn players again, wahoo!
  inSuddenDeath = false
  roundStartTime = 0.0
  lastCapTime = 0.0
  
  return Plugin_Continue
}

public Action:EventRoundPlaying(Handle:event, const String:name[], bool:dontBroadcast)
{
  // LogMessage("Round playing: %f", GetGameTime())

  roundStartTime = GetGameTime()
  lastCapTime = 0.0
  
  return Plugin_Continue
}

public Action:EventPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
  lastCapTime = GetGameTime()
  
  // LogMessage("Point/flag captured.")
  
  return Plugin_Continue
}

public Action:EventChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Skip if plugin disabled.
  if (!GetConVarBool(cvEnabled)) 
  {
    return Plugin_Continue
  }

  if (mapMode == MM_DM && !inSuddenDeath && roundStartTime > 0)
  {
    new userId = GetEventInt(event, "userid")
    new client = GetClientOfUserId(userId)    
    new oldTeam = GetEventInt(event, "oldteam")
    new newTeam = GetEventInt(event, "team")
    
    // If the player changes team, and changes to RED or BLU start a timer to
    // spawn them.
    if (client > 0 && newTeam >= 2 && oldTeam != newTeam)
    {
      CreateTimer(GetConVarFloat(cvMinRespawn), TrySpawningDm, userId, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT) 
    }
  }
  
  return Plugin_Continue
}

// In arena DM mode, if the player has chosen a class spawn them. If they haven't let the 
// timer repeat again. If they have gone spec, or left the server stop the timer.
public Action:TrySpawningDm(Handle:timer, any:userId)
{
  new client = GetClientOfUserId(userId)
  if (client > 0 &&
      mapMode == MM_DM && 
      !inSuddenDeath && 
      roundStartTime > 0 &&
      IsClientConnected(client) && 
      IsClientInGame(client) &&
      !IsPlayerAlive(client))
  {
    new clientTeam = GetClientTeam(client)
    
    if (clientTeam == TM_RED ||
        clientTeam == TM_BLU)
    {      
      new desiredClass = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass")
      if (desiredClass > 0)
      {
        // LogMessage("Spawning player %i class=%i team=%i desired=%i", client, clientClass, clientTeam, desiredClass)
      
        // Spawn the player then stop the timer.
        TF2_RespawnPlayer(client)
        return Plugin_Stop
      }
      else
      {
        // No class chosen yet. Let the timer continue.
        return Plugin_Continue
      }
    }
  }
  
  // Something has changed, so we don't want to spawn the player any more.
  return Plugin_Stop
}

// Add "respawntimes" tag.  
public CallbackTags(Handle:convar, const String:oldValue[], const String:newValue[])
{
  if (!GetConVarBool(cvEnabled) || tagsRecursing) 
  {
    return
  }
  
  tagsRecursing = true

  if (strlen(newValue) == 0)
  {
    SetConVarString(cvTags, CV_TAG_STRING)
  }
  else if (StrContains(newValue, CV_TAG_STRING) == -1)
  {
    decl String:tags[128];  
    Format(tags, sizeof(tags), "%s,%s", newValue, CV_TAG_STRING)
    SetConVarString(cvTags, tags)
  }
  
  tagsRecursing = false
}

bool:StrStartsWith(String:str[], String:searchStr[])
{
  new len = strlen(str);
  new searchLen = strlen(searchStr);
  
  if (len < searchLen)
  {
    return false;
  }
  
  return (strncmp(str, searchStr, searchLen, false) == 0);
}