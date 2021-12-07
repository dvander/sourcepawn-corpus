#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:timey = 2.0, bool:enabled[MAXPLAYERS + 1];
new Handle:conv = INVALID_HANDLE;
public OnPluginStart(){
HookEvent("player_death", Evt_PlayerDeath);
conv = CreateConVar("sm_godtime", "2.0", "Amount of time for godmode");
HookConVarChange(conv, TimeChange);
}

public Evt_PlayerDeath(Handle:event, const String:name[], bool:dontB){
new client = GetClientOfUserId(GetEventInt(event, "userid"));
new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
if(client > 0 && client <= MaxClients && attacker > 0 && attacker <= MaxClients){
enabled[attacker] = true;
CreateTimer(timey, Timer_End, attacker);
}
}

public Action:Timer_End(Handle:timer, any:client){
enabled[client] = false;
return Plugin_Handled;
}

public OnClientPutInServer(client){
SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client){
SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype){
if(enabled[victim]){
damage = 0.0;
return Plugin_Changed;
}
return Plugin_Continue;
}

public TimeChange (Handle:convar, String:oldVal[], String:newVal[]){
timey = StringToFloat(newVal);
}

