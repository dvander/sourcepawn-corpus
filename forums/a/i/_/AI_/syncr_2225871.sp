/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.8.8"

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://www.tf2jump.com/plugins/syncr/updatefile.txt"

#define MAX_ROCKETS 20 // Why would you ever want to sync with anywhere near this?

#define OBSMODE_FP 4
#define OBSMODE_TP 5

#define MAX_FLOAT_ARBITRARY 100000.0
#define TR_VERIFY_SECTIONS 10
#define DIST_BAR_MAX 30
#define DIST_BAR_RES 10
#define DIST_BAR_WIDTH 35

#define PI 3.14159265358979

enum _:Rocketeer {
  bool:bActivated,
  iRockets[MAX_ROCKETS]
};

enum ConVarType {
  BOOL = 0,
  FLOAT = 1
};

new Handle:g_hRefreshTimer;

// ConVars
new Handle:g_hPluginEnabled;
new Handle:g_hLaser;
new Handle:g_hLaserAll;
new Handle:g_hLaserHide;
new Handle:g_hChart;
new Handle:g_hRing;
new Handle:g_hCrit;
new Handle:g_hSound;
new Handle:g_hRave;
new Handle:g_hWarnDist;
new Handle:g_hThreshold;

// Cached ConVar values
new bool:g_bPluginEnabled;
new bool:g_bLaser;
new bool:g_bLaserAll;
new bool:g_bLaserHide;
new bool:g_bChart;
new bool:g_bRing;
new bool:g_bCrit;
new bool:g_bSound;
new bool:g_bRave;
new Float:g_fWarnDist;
new Float:g_fThreshold;

// Models
new g_mLaser;
new g_mHalo;

// Player and rocket data
new g_rPlayers[MAXPLAYERS+1][Rocketeer];

public Plugin:myinfo = {
  name = "SyncR",
  author = "AI",
  description = "Rocket Jump Sync Reflex Trainer",
  version = PLUGIN_VERSION,
  url = "http://tf2rj.com/forum/index.php?topic=825.0"
}

public OnPluginStart() {
  CreateConVar("syncr_version", PLUGIN_VERSION, "SyncR plugin version -- Do not modify", FCVAR_PLUGIN | FCVAR_DONTRECORD);
  g_hPluginEnabled = CreateConVar("syncr_enabled", "1", "Enables SyncR", FCVAR_PLUGIN);
  
  // Feature toggles
  g_hLaser = CreateConVar("syncr_laser", "1", "Show colored laser pointer", FCVAR_PLUGIN);
  g_hLaserAll = CreateConVar("syncr_laser_all", "0", "Show colored laser pointer of all players using SyncR", FCVAR_PLUGIN);
  g_hLaserHide = CreateConVar("syncr_laser_hide", "1", "Hide colored laser pointer when looking up", FCVAR_PLUGIN);
  g_hChart = CreateConVar("syncr_chart", "1", "Show distance to impact chart", FCVAR_PLUGIN);
  g_hRing = CreateConVar("syncr_ring", "1", "Show landing prediction ring", FCVAR_PLUGIN);
  g_hCrit = CreateConVar("syncr_crit", "1", "Show sync crit particle", FCVAR_PLUGIN);
  g_hSound = CreateConVar("syncr_sound", "1", "Play sync crit sound", FCVAR_PLUGIN);
  g_hRave = CreateConVar("syncr_rave", "0", "Switch on some disco/rave fun", FCVAR_PLUGIN); // For the bored admins ;)
  
  // Default adjustments
  g_hWarnDist = CreateConVar("syncr_warn_distance", "440.0", "Imminent rocket impact distance to warn with red", FCVAR_PLUGIN, true, 0.0, false);
  g_hThreshold = CreateConVar("syncr_threshold", "30.0", "Distance required between rockets for blue laser and crit feedback -- Set to 0 to disable", FCVAR_PLUGIN, true, 0.0, false);

  // Commands
  RegConsoleCmd("sm_syncr", cmdSyncr, "Toggles visual and audio feedback for rocket syncs");
  RegAdminCmd("sm_setsyncr", cmdSetSyncr, ADMFLAG_SLAY, "Enable/disable SyncR for the specified player");
  
  HookConVarChange(g_hPluginEnabled, Hook_OnConVarChanged);
  HookConVarChange(g_hLaser, Hook_OnConVarChanged);
  HookConVarChange(g_hLaserAll, Hook_OnConVarChanged);
  HookConVarChange(g_hLaserHide, Hook_OnConVarChanged);
  HookConVarChange(g_hChart, Hook_OnConVarChanged);
  HookConVarChange(g_hRing, Hook_OnConVarChanged);
  HookConVarChange(g_hCrit, Hook_OnConVarChanged);
  HookConVarChange(g_hSound, Hook_OnConVarChanged);
  HookConVarChange(g_hRave, Hook_OnConVarChanged);
  
  HookConVarChange(g_hWarnDist, Hook_OnConVarChanged);
  HookConVarChange(g_hThreshold, Hook_OnConVarChanged);
  
  AutoExecConfig(true, "syncr");
  
  LoadTranslations("common.phrases");
  
  if (LibraryExists("updater")) {
    Updater_AddPlugin(UPDATE_URL);
  }
}

public OnLibraryAdded(const String:sName[]) {
  if (StrEqual(sName, "updater")) {
    Updater_AddPlugin(UPDATE_URL);
  }
}

public OnConfigsExecuted() {
  g_bPluginEnabled = GetConVarBool(g_hPluginEnabled);
  g_bLaser = GetConVarBool(g_hLaser);
  g_bLaserAll = GetConVarBool(g_hLaserAll);
  g_bLaserHide = GetConVarBool(g_hLaserHide);
  g_bChart = GetConVarBool(g_hChart);
  g_bRing = GetConVarBool(g_hRing);
  g_bCrit = GetConVarBool(g_hCrit);
  g_bSound = GetConVarBool(g_hSound);
  g_bRave = GetConVarBool(g_hRave);
  
  g_fWarnDist = GetConVarFloat(g_hWarnDist);
  g_fThreshold = GetConVarFloat(g_hThreshold);
}

public OnMapStart() {
  g_mLaser = PrecacheModel("sprites/laser.vmt");
  g_mHalo = PrecacheModel("materials/sprites/halo01.vmt");
  
  PrecacheSound("weapons/rocket_shoot_crit.wav");
  
  clearAllData();

  g_hRefreshTimer = CreateTimer(0.0, Timer_refresh, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd() {

  if (g_hRefreshTimer != INVALID_HANDLE) {
    CloseHandle(g_hRefreshTimer);
    g_hRefreshTimer = INVALID_HANDLE;
  }
}

public OnClientDisconnect(iClient) {
	if(g_bPluginEnabled) {
		clearData(iClient);
	}
}

public Hook_OnConVarChanged(Handle:hConVar, const String:sOldValue[], const String:sNewValue[]) {
  // Caches convar to global variables to prevent repeated querying
  if (hConVar == g_hPluginEnabled) {
    g_bPluginEnabled = bool:StringToInt(sNewValue);
    
    // Don't risk inconsistency -- clear everything
    clearAllData();
  }
  
  updateConVar(sNewValue, hConVar==g_hPluginEnabled, g_bPluginEnabled, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hLaser, g_bLaser, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hLaserAll, g_bLaserAll, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hLaserHide, g_bLaserHide, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hChart, g_bChart, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hRing, g_bRing, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hCrit, g_bCrit, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hSound, g_bSound, iType:BOOL);
  updateConVar(sNewValue, hConVar==g_hRave, g_bRave, iType:BOOL);
  
  updateConVar(sNewValue, hConVar==g_hWarnDist, g_fWarnDist, iType:FLOAT);
  updateConVar(sNewValue, hConVar==g_hThreshold, g_fThreshold, iType:FLOAT);
}

public updateConVar(const String:sValue[], bool:bUpdate, &any:aVar, const iType) {
  if (bUpdate) {
    switch (iType) {
      case BOOL: {
        aVar = bool:StringToInt(sValue);
      }
      case FLOAT: {
        aVar = StringToFloat(sValue);
      }
    }
  }
}

public OnEntityCreated(iEntity, const String:sClassName[]) {
  if(g_bPluginEnabled) {
    if (StrEqual(sClassName,"tf_projectile_rocket")) {
      SDKHook(iEntity, SDKHook_Spawn, Hook_OnRocketSpawn);
    } else if (g_bRave && StrContains(sClassName,"tf_projectile") == 0) {
      // sClassName starts with "tf_projectile", i.e. rockets, pipes, stickies, arrows, syringe, bolts
      SDKHook(iEntity, SDKHook_Spawn, Hook_OnRocketSpawn);
    }
  }
}

public Hook_OnRocketSpawn(iEntity) {
  new iEntityRef = EntIndexToEntRef(iEntity);
  
  static prevEntityRef = -1;

  if (g_bPluginEnabled && prevEntityRef != iEntityRef) {
    
    // Workaround for SourceMod bug calling hook twice on the same rocket entity
    prevEntityRef = iEntityRef;
  
    new iOwner = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
    if (Client_IsIngameAuthorized(iOwner) && g_rPlayers[iOwner][bActivated]) {
      decl Float:fOrigin[3];
      decl Float:fOtherOrigin[3];

      Entity_GetAbsOrigin(iEntity, fOrigin);
      
      if (g_fThreshold > 0.0 && (g_bSound || g_bCrit)) {
        new bool:bNearRocket = false;
        new iEntIdx = -1;
        
        for (new j=0; j<MAX_ROCKETS && !bNearRocket; j++) {
          iEntIdx = EntRefToEntIndex(g_rPlayers[iOwner][iRockets][j]);
          
          if (iEntIdx == -1) {
            // Rocket no longer exists -- clean up
            g_rPlayers[iOwner][iRockets][j] = -1;
          } else {
            Entity_GetAbsOrigin(iEntIdx, fOtherOrigin);
            
            new Float:fVerticalDisparity = 0.7*(fOtherOrigin[2]-fOrigin[2])*(fOtherOrigin[2]-fOrigin[2]);
            new Float:fHorizontalDisparity = 0.3*(fOtherOrigin[0]-fOrigin[0])*(fOtherOrigin[0]-fOrigin[0]) + (fOtherOrigin[1]-fOrigin[1])*(fOtherOrigin[1]-fOrigin[1]);
            
            bNearRocket = !GetConVarBool(g_hRave) && SquareRoot(fHorizontalDisparity + fVerticalDisparity) < g_fThreshold;
          }
        }
        
        if (bNearRocket) {
          if (g_bSound) {
            decl iClients[MaxClients];
            new iClientCount=Client_Get(iClients, CLIENTFILTER_INGAMEAUTH);

            Entity_GetAbsOrigin(iOwner, fOtherOrigin);
            EmitSoundToClient(iOwner, "weapons/rocket_shoot_crit.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
            EmitSound(iClients, iClientCount, "weapons/rocket_shoot_crit.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.75, SNDPITCH_NORMAL, -1, fOtherOrigin);
          }
          
          if (g_bCrit) {
            critify(iOwner, iEntity);
            critify(iOwner, iEntIdx); // Nearby rocket
          }
        }
      }
      
      for (new i=0; i<MAX_ROCKETS; i++) {
        new iRef = g_rPlayers[iOwner][iRockets][i];
        if (iRef == -1 || EntRefToEntIndex(iRef) == -1) {
          g_rPlayers[iOwner][iRockets][i] = iEntityRef;
          return;
        }
      }
    }
  }
}

public Action:Timer_refresh(Handle:timer) {
  if (!g_bPluginEnabled || !g_bLaser) {
    return;
  }
  
  decl Float:fOrigin[3];
  decl Float:fAngles[3];
  decl iColor[4];
  decl Float:fClientOrigin[3];
  decl Float:fClientVelocity[3];
  decl Float:fClientEyeAngles[3];
  decl Float:fDistanceImpact;
  decl Float:fDistanceBody;
  decl Float:fTargetPoint[3];
  decl Float:fGroundPoint[3];
  decl Handle:hTr;
  new Float:fBeamWidth = 2.0;
  
  decl String:sDistBar[DIST_BAR_WIDTH];
  decl iClientObs[MAXPLAYERS];
  decl iClientObsCount;
  
  for (new i=1; i<=MaxClients; i++) {
    if (g_rPlayers[i][bActivated] && Client_IsIngameAuthorized(i) && TFTeam:GetClientTeam(i) > TFTeam_Spectator) {
      
      // Find all observers
      iClientObs[0] = i; // Include self
      iClientObsCount = 1; // Include self
      for (new j=1; j<=MaxClients; j++) {
        if (Client_IsIngameAuthorized(j) && i != j) {
          new iObsMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
          
          if ((iObsMode == OBSMODE_FP || iObsMode == OBSMODE_TP)) {
            new iObsTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
            if (i == iObsTarget) {
              iClientObs[iClientObsCount++] = j;
            }
          }
        }
      }
      
      new iRingColor[4] = {255, 255, 255, 255}; // White
      new Float:fClosetDistance = MAX_FLOAT_ARBITRARY;
      
      decl String:sRocketInfo[254] = "\0";
      decl Float:fVel[3];
      
      GetClientEyeAngles(i, fClientEyeAngles);
      
      // Draw beams for each of the client's rockets
      for (new j=0; j<MAX_ROCKETS; j++) {
      
        new iEntIdx = EntRefToEntIndex(g_rPlayers[i][iRockets][j]);
        
        if (iEntIdx == -1) {
          // Rocket no longer exists -- clean up
          g_rPlayers[i][iRockets][j] = -1;
        } else {
          Entity_GetAbsOrigin(iEntIdx, fOrigin);
          Entity_GetAbsAngles(iEntIdx, fAngles);
          
          if (g_bRave) {
            fAngles[0] = GetRandomFloat()*360;
            fAngles[1] = GetRandomFloat()*360;
            fAngles[2] = GetRandomFloat()*360;
          }
          
          hTr = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT_HULL, RayType_Infinite, traceHitEnvironment, iEntIdx);
          if(TR_DidHit(hTr) && IsValidEntity(TR_GetEntityIndex(hTr))) {
            TR_GetEndPosition(fTargetPoint, hTr);
            CloseHandle(hTr);
          } else {
            // Abnormal condition
            LogToGame("SYNCR: Failed to trace ray for rocket %d from client %i", i, j);
            CloseHandle(hTr);
            return;
          }
          
          fDistanceImpact = GetVectorDistance(fOrigin, fTargetPoint);
          
          Entity_GetAbsVelocity(iEntIdx, fVel);
          
          new iSegments = RoundToFloor(fDistanceImpact/GetVectorLength(fVel)*DIST_BAR_RES);
          sDistBar[0] = 0;
          for (new k=0; k<DIST_BAR_MAX && k<iSegments; k++) {
            sDistBar[k] = '|';
          }
          if (iSegments > DIST_BAR_MAX-3) {
            sDistBar[DIST_BAR_MAX-4] = '.';
            sDistBar[DIST_BAR_MAX-3] = '.';
            sDistBar[DIST_BAR_MAX-2] = '.';
            sDistBar[DIST_BAR_MAX-1] = 0;
          } else {
            sDistBar[iSegments] = 0;
          }
          
          Format(sRocketInfo, sizeof(sRocketInfo), "%s\nR%d: %s", sRocketInfo, j+1, sDistBar);
          
          // Disable beams when the client looks up
          if (g_bLaserHide && FloatAbs(fClientEyeAngles[0]+89.0) < 20.0) {
            continue;
          }
          
          if (fDistanceImpact < g_fWarnDist) {
            iColor = {255, 0, 0, 255}; // Red
          } else if (fDistanceImpact < 1.5*g_fWarnDist) {
            iColor = {255, 0, 127, 255}; // Rose
          } else {
            fDistanceBody = GetVectorDistance(fOrigin, fClientOrigin);
          
            if (0.0 < g_fThreshold && fDistanceBody < g_fThreshold) {
              iColor = {0, 0, 255, 255}; // Blue
            } else if (0.0 < g_fThreshold && fDistanceBody < 1.5*g_fThreshold) {
              iColor = {0, 255, 255, 255}; // Cyan
            } else if (fDistanceImpact < 2*g_fWarnDist) {
              iColor = {255, 255, 0, 255}; // Yellow
            } else {
              iColor = {0, 255, 0, 255}; // Green
            }
          }
          
          
          if (g_bRave) {
            iColor[0] = GetRandomInt(0,255);
            iColor[1] = GetRandomInt(0,255);
            iColor[2] = GetRandomInt(0,255);
            iColor[3] = 255;
          }
          
          if (fDistanceImpact < fClosetDistance) {
            fClosetDistance = fDistanceImpact;
            iRingColor = iColor; // Reference
          }
          
          if (g_bRave) {
            fBeamWidth = 10.0;
          }

          TE_SetupBeamPoints(fOrigin, fTargetPoint, g_mLaser, g_mHalo, 0, 30, 0.2, fBeamWidth, fBeamWidth, 10, 1.0, iColor, 0);
          
          if (g_bLaserAll || g_bRave) {
            TE_SendToAll();
          } else {
            TE_Send(iClientObs, iClientObsCount);
          }
        }
      }
      
      Entity_GetAbsOrigin(i, fClientOrigin);
      Entity_GetAbsVelocity(i, fClientVelocity);

      fAngles[0] = 90.0;
      fAngles[1] = 0.0;
      fAngles[2] = 0.0;
      
      decl Float:fprobePoint[3];
      fprobePoint[0] = fClientOrigin[0];
      fprobePoint[1] = fClientOrigin[1];
      fprobePoint[2] = fClientOrigin[2];
      
      decl Float:fprobeVelocity[3];
      fprobeVelocity[0] = fClientVelocity[0] * GetTickInterval();
      fprobeVelocity[1] = fClientVelocity[1] * GetTickInterval();
      fprobeVelocity[2] = fClientVelocity[2] * GetTickInterval();
      
      new Float:fPlayerGravityRatio = GetEntityGravity(i);
      if (fPlayerGravityRatio == 0) {
        fPlayerGravityRatio = 1.0;
      }
      
      new Float:fGravity = -GetConVarFloat(FindConVar("sv_gravity")) * fPlayerGravityRatio * GetTickInterval() * GetTickInterval();
      
      decl Float:fTracePointPrev[3];
      decl Float:fTracePoint[3];
      fTracePointPrev[0] = fprobePoint[0];
      fTracePointPrev[1] = fprobePoint[1];
      fTracePointPrev[2] = fprobePoint[2];
      
      decl Float:fNormal[3];
      decl Float:fNormalAngles[3];
      
      for (new k=0; k<5; k++) {
        hTr = TR_TraceRayFilterEx(fprobePoint, fAngles, MASK_SHOT_HULL, RayType_Infinite, traceHitEnvironment, i);
        if(TR_DidHit(hTr) && IsValidEntity(TR_GetEntityIndex(hTr))) {
          TR_GetEndPosition(fGroundPoint, hTr);
          CloseHandle(hTr);
        } else {
          CloseHandle(hTr);
          return;
        }

        new Float:fDist = fGroundPoint[2]-fprobePoint[2];
        if (FloatAbs(fDist) < 10) {
          break;
        }
        
        new Float:fVelDirectional = fGravity*fDist;

        // v_f^2 = v_0^2 + 2*g*d
        new Float:fVelFinal = SquareRoot(FloatAbs(fprobeVelocity[2]*fprobeVelocity[2] + 2*fVelDirectional));
        if (fVelDirectional > 0) {
          fVelFinal *= -1.0;
        }
        
        new Float:fTime = (fVelFinal-fprobeVelocity[2])/fGravity;
        
        // Final value
        fGroundPoint[0] += fprobeVelocity[0]*fTime;
        fGroundPoint[1] += fprobeVelocity[1]*fTime;
        
        new Float:fTemp[3];
        
        // RT verification
        for (new l=1; l<=TR_VERIFY_SECTIONS; l++) {
          new Float:fTimeSlice = (l*fTime)/TR_VERIFY_SECTIONS;
          fTracePoint[0] = fprobePoint[0] + fprobeVelocity[0]*fTimeSlice;
          fTracePoint[1] = fprobePoint[1] + fprobeVelocity[1]*fTimeSlice;
          
          // dz = v_0*t+0.5*at*^2 = (v_0 + 0.5*a*t)*t
          fTracePoint[2] = fprobePoint[2] + (fprobeVelocity[2] + 0.5*fGravity*fTimeSlice)*fTimeSlice;
          
          new Float:fTraceDist = GetVectorDistance(fTracePoint, fTracePointPrev);
          
          SubtractVectors(fTracePoint, fTracePointPrev, fTemp); // Store temp vector in fTemp
          GetVectorAngles(fTemp, fTemp);
          
          hTr = TR_TraceRayFilterEx(fTracePointPrev, fTemp, MASK_ALL, RayType_Infinite, traceHitEnvironment, i);
          if(TR_DidHit(hTr) && IsValidEntity(TR_GetEntityIndex(hTr))) {
            TR_GetEndPosition(fTemp, hTr);
            
            if (GetVectorDistance(fTracePointPrev, fTemp) <= fTraceDist) {
              fGroundPoint[0] = fTemp[0];
              fGroundPoint[1] = fTemp[1];
              fGroundPoint[2] = fTemp[2];
              
              TR_GetPlaneNormal(hTr, fNormal);
              GetVectorAngles(fNormal, fNormalAngles);
              
              fTemp[0] += fNormal[0]*50;
              fTemp[1] += fNormal[1]*50;
              fTemp[2] += fNormal[2]*50;
              
              GetVectorAngles(fNormal, fNormalAngles);
             
              CloseHandle(hTr);
              break;
            }
          } else {
            CloseHandle(hTr);
            break;
          }
          
          CloseHandle(hTr);
          
          fTracePointPrev[0] = fTracePoint[0];
          fTracePointPrev[1] = fTracePoint[1];
          fTracePointPrev[2] = fTracePoint[2];
        }
        
        // Furthest probe points
        fprobePoint[0] = fGroundPoint[0];
        fprobePoint[1] = fGroundPoint[1];
        fprobePoint[2] = fGroundPoint[2];
        
        fprobeVelocity[2] = fVelFinal;
      }
      
      if (g_bChart) {
        new Handle:hBuffer = StartMessage("KeyHintText", iClientObs, iClientObsCount); 
        BfWriteByte(hBuffer, 1); // Channel
        fDistanceImpact = GetVectorDistance(fClientOrigin, fGroundPoint);
        new iSegments = RoundToFloor(fDistanceImpact/1100.0*DIST_BAR_RES);
        sDistBar[0] = '-';
        sDistBar[1] = 0;
        for (new k=0; k<DIST_BAR_MAX && k<iSegments; k++) {
          sDistBar[k] = '|';
        }
        if (iSegments > DIST_BAR_MAX-3) {
          sDistBar[DIST_BAR_MAX-4] = '.';
          sDistBar[DIST_BAR_MAX-3] = '.';
          sDistBar[DIST_BAR_MAX-2] = '.';
          sDistBar[DIST_BAR_MAX-1] = 0;
        } else if (iSegments > 0) {
          sDistBar[iSegments] = 0;
        }
          
        new iHu = RoundFloat(1100.0/DIST_BAR_RES);
        if (sRocketInfo[0]) {
          Format(sRocketInfo, sizeof(sRocketInfo), "Distance to Impact (per %d hu)\n                                                    \nPC: %s%s", iHu, sDistBar, sRocketInfo);
          BfWriteString(hBuffer, sRocketInfo);
        } else {
          Format(sRocketInfo, sizeof(sRocketInfo), "Distance to Impact (per %d hu)\n                                                    \nPC: %s", iHu, sDistBar);
          BfWriteString(hBuffer, sRocketInfo);
        }
        EndMessage();
      }
      
      // Ignore vertical
      if (FloatAbs(270.0-fNormalAngles[0]) > 10) {
        continue;
      }
      
      if (g_bRing) {
        // Distance from client to currently predicted landing point
        new Float:fDistImpactPoint = GetVectorDistance(fClientOrigin, fGroundPoint);
        //if (FloatAbs(fClientVelocity[2] + 550) < g_fThreshold) {
        if (fDistImpactPoint < g_fThreshold) {
          iRingColor = {0, 0, 255, 255}; // Blue
        }
        
        if (fClientEyeAngles[0] > 45.0 && fClosetDistance != MAX_FLOAT_ARBITRARY || fDistImpactPoint > 30) {
          fGroundPoint[2] += 10.0;
          
          new Float:fMultiplier = Math_Min(1.0, FloatAbs(fDistImpactPoint)/1000.0);
          new Float:fDeg0 = PI/3;
          
          decl Float:ringPoint[3];
          decl Float:ringPointPrev[3];
          
          ringPointPrev[0] = fGroundPoint[0] + Cosine(0.0)*g_fThreshold*fMultiplier;
          ringPointPrev[1] = fGroundPoint[1] + Sine(0.0)*g_fThreshold*fMultiplier;
          ringPointPrev[2] = fGroundPoint[2];
          
          decl Float:vfExpand[3];
          decl Float:vfPointA[3];
          decl Float:vfPointB[3];
          for (new Float:fDeg=fDeg0; fDeg<2*PI; fDeg+=fDeg0) {
            ringPoint[0] = fGroundPoint[0] + Cosine(fDeg)*g_fThreshold*fMultiplier;
            ringPoint[1] = fGroundPoint[1] + Sine(fDeg)*g_fThreshold*fMultiplier;
            ringPoint[2] = fGroundPoint[2];
            
            SubtractVectors(ringPoint, ringPointPrev, vfExpand);
            ScaleVector(vfExpand, 0.5*1.08);

            vfPointA[0] = 0.5*(ringPointPrev[0]+ringPoint[0]);
            vfPointA[1] = 0.5*(ringPointPrev[1]+ringPoint[1]);
            vfPointA[2] = 0.5*(ringPointPrev[2]+ringPoint[2]);
            
            AddVectors(vfPointA, vfExpand, vfPointA);
            ScaleVector(vfExpand, -2.0);
            AddVectors(vfPointA, vfExpand, vfPointB);

            TE_SetupBeamPoints(vfPointA, vfPointB, g_mLaser, g_mHalo, 0, 30, 0.2, fMultiplier*5.0, fMultiplier*5.0, 10, 1.0, iRingColor, 0);
            
            ringPointPrev[0] = ringPoint[0];
            ringPointPrev[1] = ringPoint[1];
            ringPointPrev[2] = ringPoint[2];
            
            if (g_bLaserAll) {
              TE_SendToAll();
            } else {
              TE_Send(iClientObs, iClientObsCount);
            }
          }
        }
      }
    }
  }
}

public Action:cmdSetSyncr(iClient, iArgC) {
  if (iArgC != 2) {
    ReplyToCommand(iClient, "Usage: sm_setsyncr <player> [0/1]");
    return Plugin_Handled;
  }
  
  new String:sArg1[32];
  GetCmdArg(1, sArg1, sizeof(sArg1));
  new iTarget = FindTarget(iClient, sArg1);
  if (iTarget == -1) {
    return Plugin_Handled;
  }
  
  new String:sArg2[32];
  GetCmdArg(2, sArg2, sizeof(sArg2));
  new bool:iEnable = bool:StringToInt(sArg2);
  
  new String:sTargetName[32];
  GetClientName(iTarget, sTargetName, sizeof(sTargetName));
  
  g_rPlayers[iTarget][bActivated] = iEnable;
  if (iEnable) {
    ReplyToCommand(iClient, "SyncR enabled for %s", sTargetName);
    PrintToChat(iTarget, "SyncR enabled");
  } else {
    ReplyToCommand(iClient, "SyncR disabled for %s", sTargetName);
    PrintToChat(iTarget, "SyncR disabled");
    clearData(iTarget);
  }
  
  return Plugin_Handled;
}

public Action:cmdSyncr(iClient, iArgC) {
  g_rPlayers[iClient][bActivated] = !g_rPlayers[iClient][bActivated];
  
  if (g_rPlayers[iClient][bActivated]) {
    ReplyToCommand(iClient, "SyncR enabled");
  } else {
    ReplyToCommand(iClient, "SyncR disabled");
    clearData(iClient);
  }
  
  return Plugin_Handled;
}


clearData(iClient) {
  g_rPlayers[iClient][bActivated] = false;
  for (new i=0; i<MAX_ROCKETS; i++) {
    g_rPlayers[iClient][iRockets][i] = -1;
  }
}

clearAllData() {
  for (new i=1; i<=MaxClients; i++) {
    clearData(i);
    Array_Fill(g_rPlayers[i][iRockets], MAX_ROCKETS, -1);
  }
}

critify(iClient, iEntity) {
  new iParticle = CreateEntityByName("info_particle_system");
  if (IsValidEdict(iParticle)) {
    new Float:fOrigin[3];
    Entity_GetAbsOrigin(iEntity, fOrigin);
    Entity_SetAbsOrigin(iParticle, fOrigin);
    
    
    if (GetClientTeam(iClient) == 2) {
      DispatchKeyValue(iParticle, "effect_name", "critical_rocket_red");
    } else {
      DispatchKeyValue(iParticle, "effect_name", "critical_rocket_blue");
    }
    
    SetVariantString("!activator");
    AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);			
    DispatchSpawn(iParticle);
    ActivateEntity(iParticle);
    AcceptEntityInput(iParticle, "Start");
  }
}

public bool:traceHitEnvironment(iEntity, iMask, any:iEntityStart) {
  // Ignore players
	return iEntity != iEntityStart && !Client_IsIngameAuthorized(iEntity);
}
