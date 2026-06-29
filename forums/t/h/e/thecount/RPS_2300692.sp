#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new winHealth = 30;

public OnPluginStart(){
	HookEvent("rps_taunt_event", Evt_RPS);
	HookConVarChange(CreateConVar("sm_rps_health", "30", "Health for RPS winner."), HealthChange);
}

public HealthChange(Handle:convar, const String:oldVal[], const String:newVal[]){
	winHealth = StringToInt(newVal);
}

public Evt_RPS(Handle:event, const String:name[], bool:dontB){
	new winner = GetEventInt(event, "winner"), loser = GetEventInt(event, "loser");
   if(loser < 1 || loser > MaxClients){ return; }
   SDKHooks_TakeDamage(loser, winner, winner, (float(GetClientHealth(loser)) * 2.0), DMG_BURN);
   SetEntityHealth(winner, (GetClientHealth(winner) + winHealth));
}