#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
 name = "Add crit sound for spy backstab",
 author = "Ratty",
 description = "For servers with crits off",
 version = "1.0",
 url = "http://www.nom-nom.nom.us"
}

public OnPluginStart() {
 HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
 decl String:weapon[64];
 GetEventString(event, "weapon", weapon, sizeof(weapon));
 new client = GetClientOfUserId(GetEventInt(event, "attacker"));
 new customkill = GetEventInt(event, "customkill");

 if(StrEqual(weapon, "knife")) {
  if(customkill==2) EmitSoundToClient(client,"player/crit_hit.wav");
 }
 return Plugin_Continue;	
}
