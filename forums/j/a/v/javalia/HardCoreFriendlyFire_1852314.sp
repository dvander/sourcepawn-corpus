#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new const String:PluginVersion[60] = "1.0.0.0";

public Plugin:myinfo = {
	
	name = "HardCoreFriendlyFire",
	author = "javalia",
	description = "deal same amount of damage to teammates like damaging enemy",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
	
};

new oldTeamNum[MAXPLAYERS + 1] = {-1, ...};

new Handle:mp_friendlyfire = INVALID_HANDLE;
new Handle:cvar_freeforall = INVALID_HANDLE;

public OnPluginStart(){

	CreateConVar("HardCoreFriendlyFire_version", PluginVersion, "plugin info cvar", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	
	cvar_freeforall = CreateConVar("HardCoreFriendlyFire_freeforall", "0", "enables FFA mode");
	
	HookEvent("player_hurt", EventHurtHook, EventHookMode_Pre);
	HookEvent("player_death", EventDeathHook, EventHookMode_Pre);

}

public OnMapStart(){
	
	AutoExecConfig();

}

public OnClientPutInServer(client){
	
	oldTeamNum[client] = -1;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);

}

public Action:EventHurtHook(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(GetConVarBool(mp_friendlyfire) && !GetConVarBool(cvar_freeforall)){
	
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(isClientConnectedIngame(client)){
			
			if(oldTeamNum[client] != -1){
			
				SetEntProp(client, Prop_Data, "m_iTeamNum", oldTeamNum[client]);
				oldTeamNum[client] = -1;
			
			}
		
		}
		
	}
	
	return Plugin_Continue;

}

public Action:EventDeathHook(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(GetConVarBool(mp_friendlyfire) && !GetConVarBool(cvar_freeforall)){
	
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(isClientConnectedIngame(client)){
			
			if(oldTeamNum[client] != -1){
			
				SetEntProp(client, Prop_Data, "m_iTeamNum", oldTeamNum[client]);
				oldTeamNum[client] = -1;
			
			}
		
		}
		
	}
	
	return Plugin_Continue;

}

public Action:OnTakeDamageHook(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]){

	if(GetConVarBool(mp_friendlyfire)){
	
		if(isClientConnectedIngameAlive(victim) && isClientConnectedIngame(attacker)){
			
			new victimteam = GetClientTeam(victim);
			
			if(victimteam == GetClientTeam(attacker)){
				
				if(!GetConVarBool(cvar_freeforall)){
				
					SDKHooks_TakeDamage(victim, inflictor, attacker, 0.0, DMG_GENERIC, weapon, NULL_VECTOR, damagePosition);
					
				}
				
				oldTeamNum[victim] = victimteam;
				SetEntProp(victim, Prop_Data, "m_iTeamNum", 0);
				
			}
		
		}
		
	}
	
	return Plugin_Changed;

}

public OnTakeDamagePostHook(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3]){
	
	if(GetConVarBool(mp_friendlyfire)){
	
		if(isClientConnectedIngame(victim)){
			
			if(oldTeamNum[victim] != -1){
				
				SetEntProp(victim, Prop_Data, "m_iTeamNum", oldTeamNum[victim]);
				oldTeamNum[victim] = -1;
			
			}
		
		}
		
	}
	
}

stock bool:isClientConnectedIngameAlive(client){
	
	if(isClientConnectedIngame(client)){
		
		if(IsPlayerAlive(client) == true && IsClientObserver(client) == false){
			
			return true;
			
		}else{
			
			return false;
			
		}
		
	}else{
		
		return false;
		
	}
	
}

stock bool:isClientConnectedIngame(client){
	
	if(client > 0 && client <= MaxClients){
		
		if(IsClientInGame(client) == true){
			
			return true;
			
		}else{
			
			return false;
			
		}
		
	}else{
		
		return false;
		
	}
	
}