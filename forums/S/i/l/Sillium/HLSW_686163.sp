#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "1.1"

public Plugin:myinfo = {
   name        = "HLSW Nextmap & Timeleft",
   author      = "Author: Tsunami, Bugfix: Sillium",
   description = "Shows nextmap and timeleft in HLSW.",
   version     = PL_VERSION,
   url         = "http://www.tsunami-productions.nl"
}

new Handle:g_hNextMap;
new Handle:g_hTimeLeft;
new Handle:g_hsm_Nextmap;

public OnPluginStart() {
   CreateConVar("sm_hlswinfo_version", PL_VERSION, "Shows nextmap and timeleft in HLSW.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
   g_hNextMap  = CreateConVar("cm_nextmap",  "", "Nextmap in HLSW",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
   g_hTimeLeft = CreateConVar("cm_timeleft", "", "Timeleft in HLSW", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
   g_hsm_Nextmap = FindConVar("sm_nextmap");
   
   HookConVarChange(g_hsm_Nextmap, NextMap);
   CreateTimer(15.0, Timeleft, _, TIMER_REPEAT);
}

public OnMapStart() {
   decl String:sTimeLeft[8];
   Format(sTimeLeft, sizeof(sTimeLeft), "%d:00", GetConVarInt(FindConVar("mp_timelimit")));
   SetConVarString(g_hTimeLeft, sTimeLeft);
}

public NextMap(Handle:convar, const String:oldValue[], const String:newValue[]) {
   SetCommandFlags("cm_nextmap", FCVAR_PLUGIN|FCVAR_SPONLY);
   SetConVarString(g_hNextMap, newValue);
   SetCommandFlags("cm_nextmap", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
}

public Action:Timeleft(Handle:timer) {
   decl String:sTimeLeft[8];
   new iMins, iSecs, iTimeLeft;
   
   if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) {
      iMins    = iTimeLeft / 60;
      if (iTimeLeft % 60   > 30) {
         iMins += 1;
         iSecs  = 0;
      } else {
         iSecs  = 30;
      }
   }
   
   Format(sTimeLeft, sizeof(sTimeLeft), "%d:%02d", iMins, iSecs);
   SetCommandFlags("cm_timeleft", FCVAR_PLUGIN|FCVAR_SPONLY);
   SetConVarString(g_hTimeLeft, sTimeLeft);
   SetCommandFlags("cm_timeleft", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
}