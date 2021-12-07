/*
 *physics attacker check plugin
 */

new const String:PluginVersion[60] = "1.0.0.1";

public Plugin:myinfo = {
	
	name = "Physics Attacker Check",
	author = "javalia",
	description = "Check Physics Attacker",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
	
};

#include <sourcemod>
#include <sdktools>
#include "sdkhooks"
#include "stocklib"

new Handle:cvar_checkfriendlyfire = INVALID_HANDLE;
new Handle:cvar_friendlyfire = INVALID_HANDLE;

public OnPluginStart(){
	
	cvar_friendlyfire = FindConVar("mp_friendlyfire");
	
	CreateConVar("physicsattackercheck_version", PluginVersion, "plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	cvar_checkfriendlyfire = CreateConVar("physicsattackercheck_checkfriendlyfire", "1", "will this plugin prevent friendly fire inflicted by props?");
	
	AutoExecConfig();
	
}

public OnMapStart(){

	AutoExecConfig();
	
}

public OnClientPutInServer(client){
	
	SDKHook(client, SDKHook_OnTakeDamage, ClientOnTakeDamageHook);
	
}

public Action:ClientOnTakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype){

	//attacker is a client! and he is not client himself
	if(IsClientConnectedIngame(attacker) && (client != attacker)){
	
		if((GetClientTeam(attacker) == GetClientTeam(client))){
		
			if(!GetConVarBool(cvar_friendlyfire) && GetConVarBool(cvar_checkfriendlyfire)){
		
				decl String:classname[32];
				
				GetEdictClassname(inflictor, classname, 64);
		
				if(isphysicspropclassname(classname)){
				
					return Plugin_Handled;
				
				}
				
			}
		
		}
	
	}
	
	return Plugin_Continue;

}

public OnEntityCreated(entity, const String:classname[]){
	
	if(isphysicspropclassname(classname)){
		
		SDKHook(entity, SDKHook_OnTakeDamage, PropOnTakeDamageHook);
		
	}
	
}

public Action:PropOnTakeDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	
	//attacker is a client!
	if(IsClientConnectedIngame(attacker)){
		
		//PrintToChatAll("원래공격자 %d", attacker);
		
		//만약 클라이언트가 물체에 데미지를 입혔다면, 그 클라이언트를 마지막 공격자로 해야 한다
		
		if(inflictor == attacker){
		
			//PrintToChatAll("공격자가 직접 공격했음");
			
			if(damagetype & DMG_CRUSH){
			
				new lastphysicsattacker = GetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker")
				
				if(lastphysicsattacker != -1){
				
					//PrintToChatAll("바꿀 공격자 : %d", lastphysicsattacker);
					attacker = GetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker");
					return Plugin_Changed;
				
				}else{
				
					//PrintToChatAll("이전 공격자가 없는 물체임. 어태커 %d가 피직스 어태커가 됨", attacker);
					SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", attacker);
					SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
				
				}
				
				SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime() + 0.01);
				
			}else{
				
				//PrintToChatAll("피직스 어태커를 바꿈");
				
				SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", attacker);
				SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
			
			}
		
		}else{
			
			//PrintToChatAll("공격자가 간접 공격했음");
			
			if(damagetype & DMG_CRUSH){
				
				new lastphysicsattacker = GetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker")
				
				if(lastphysicsattacker != -1){
				
					//PrintToChatAll("바꿀 공격자 : %d", GetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker"));
					attacker = GetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker");
					SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime() + 0.01);
					return Plugin_Changed;
					
				}else{
				
					//PrintToChatAll("이전 공격자가 없는 물체임. 어태커 %d가 피직스 어태커가 됨", attacker);
					SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", attacker);
					SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
				
				}
			
			}else{
			
				//PrintToChatAll("피직스 어태커를 바꿈");
				
				SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", attacker);
				SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
			
			}
		
		}
		
	}
	
		
	return Plugin_Continue;

}

bool:isphysicspropclassname(const String:classname[]){

	
	if((StrContains(classname, "prop_physics", false)  != -1) || (StrContains(classname, "prop_physics_override", false)  != -1)
		|| (StrContains(classname, "func_physbox") != -1) || (StrContains(classname, "func_physbox_multiplayer") != -1)){
	
		return true;
	
	}else{
	
		return false;
	
	}

}