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
 
/* 
 * Created for jump servers in response to Valve's November 20, 2014 patch that prevents building
 * inside trigger_hurt areas, which have been widely used in jump maps for health regen
 *
 * Note: Uses brush entity creation method from https://forums.alliedmods.net/showthread.php?t=129597
 *
 * Changelog 
 * 
 * 1.0.1  1/28/2015
 * - Tweaked regen interval
 *
 * 1.0.0  1/27/2015
 * - Initial release
 */
#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <smlib>

#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "1.0.1"
#define UPDATE_URL     "http://www.tf2jump.com/plugins/nobuildpatch/updatefile.txt"

#define DECOY_MODEL "models/props_2fort/cow001_reference.mdl"

public Plugin:myinfo = {
  name = "Nobuild Patch",
  author = "AI",
  description = "Allows engineers to build inside trigger_hurt brushes by replacing them with trigger_multiple",
  version = PLUGIN_VERSION,
  url = "http://tf2rj.com/forum/index.php?topic=959.0"
}

public OnPluginStart() {
  CreateConVar("nobuildpatch_version", PLUGIN_VERSION, "Nobuild Patch plugin version -- Do not modify", FCVAR_PLUGIN | FCVAR_DONTRECORD);

  if (LibraryExists("updater")) {
    Updater_AddPlugin(UPDATE_URL);
  }
  
  HookEventEx("game_start", OnRoundStart);
  HookEventEx("teamplay_round_start", OnRoundStart);
}

public OnLibraryAdded(const String:sName[]) {
  if (StrEqual(sName, "updater")) {
    Updater_AddPlugin(UPDATE_URL);
  }
}

public OnMapStart() {
  PrecacheModel(DECOY_MODEL, true);
}

public Action:OnRoundStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
  decl Float:iVecOrigin[3];
  decl Float:iVecMins[3];
  decl Float:iVecMaxs[3];

  new iEntity = INVALID_ENT_REFERENCE;
  while ((iEntity = FindEntityByClassname(iEntity, "trigger_hurt")) != INVALID_ENT_REFERENCE) {
    
    GetEntPropVector(iEntity, Prop_Data, "m_vecMins", iVecMins);
    GetEntPropVector(iEntity, Prop_Data, "m_vecMaxs", iVecMaxs);
    
    new Float:fDamage = GetEntPropFloat(iEntity, Prop_Data, "m_flDamage");
    if (fDamage < 0) {
      GetEntPropVector(iEntity, Prop_Data, "m_vecMins", iVecMins);
      GetEntPropVector(iEntity, Prop_Data, "m_vecMaxs", iVecMaxs);
      
      new iDamageModel = GetEntProp(iEntity, Prop_Data, "m_damageModel");
      new iEntityTrigger = CreateEntityByName("trigger_multiple");

      if (iDamageModel == 0 && iEntityTrigger != INVALID_ENT_REFERENCE) {
        
        DispatchSpawn(iEntityTrigger);
        ActivateEntity(iEntityTrigger);
        
        SetEntityModel(iEntityTrigger, DECOY_MODEL);        
        
        Entity_GetAbsOrigin(iEntity, iVecOrigin);
        Entity_SetAbsOrigin(iEntityTrigger, iVecOrigin);

        SetEntPropVector(iEntityTrigger, Prop_Send, "m_vecMins", iVecMins);
        SetEntPropVector(iEntityTrigger, Prop_Send, "m_vecMaxs", iVecMaxs);
        
        SetEntProp(iEntityTrigger, Prop_Send, "m_nSolidType", 2);
        
        new iEffects = GetEntProp(iEntityTrigger, Prop_Data, "m_fEffects") | 32;
        SetEntProp(iEntityTrigger, Prop_Send, "m_fEffects", iEffects);  
        
        SDKHookEx(iEntityTrigger, SDKHook_StartTouch, OnTouch); 
        SDKHookEx(iEntityTrigger, SDKHook_Touch, OnTouch); 
        SDKHookEx(iEntityTrigger, SDKHook_EndTouch, OnTouch); 
        
        RemoveEdict(iEntity);
        iEntity = INVALID_ENT_REFERENCE;
      }
    }
  }
  
  return Plugin_Handled;
}

public Action:OnTouch(iEntity, iOther) {
  new Float:fTime = FloatFraction(GetGameTime());
  if (Client_IsValid(iOther) && (FloatAbs(fTime-0.25) < 0.01 || FloatAbs(fTime-0.75) < 0.01)) {
    Entity_SetHealth(iOther, Entity_GetMaxHealth(iOther));
    
    return Plugin_Handled;
  }
  
  return Plugin_Continue;
}
