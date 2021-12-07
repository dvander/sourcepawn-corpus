#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

new Handle:hCvarEnable = INVALID_HANDLE, bool:bCvarEnable,
	bool:bLateLoad = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	bLateLoad = late;
	return APLRes_Success;
}
public OnPluginStart(){
	hCvarEnable = CreateConVar("sm_somecvar_enable", "1", "0 = Plugin disabled, 1 = enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	bCvarEnable = GetConVarBool(hCvarEnable);
	HookConVarChange(hCvarEnable, OnConVarChange);
	if (bLateLoad) LookupClients();
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[]){
	if (hCvar == hCvarEnable){
		bCvarEnable = bool:StringToInt(newValue);
		if (bCvarEnable) LookupClients();
		else LookupClients2();
	}
}

LookupClients(){
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

LookupClients2(){
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i)) SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnClientPutInServer(client){
	if (bCvarEnable) SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client){
	if (bCvarEnable) SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype){
	if(bCvarEnable){
		if(victim <= 0 && victim > MaxClients){ return Plugin_Continue; }
		if(attacker <= 0 || attacker > MaxClients){ return Plugin_Continue; }
		if(damage > 44.0){
			new String:wep[64];GetClientWeapon(attacker, wep, sizeof(wep));
			if(StrEqual(wep, "weapon_knife", false)){
				damage = 0.0;
				CS_RespawnPlayer(attacker);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}