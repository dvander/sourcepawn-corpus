#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.3"
#define PLUGIN_PREFIX "\x04[Spy Improvements]\x01"

public Plugin:myinfo = 
{
	name = "Spy Improvements",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

new speedOffset;

new Float:spySpeed;

new Handle:cv_admin;
new Handle:cv_cloakedSpeed;

public OnPluginStart(){
	CreateConVar("sm_spyi_version", PLUGIN_VERSION, "Spy Improvements Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cv_admin = CreateConVar("sm_spyi_admin", "0",
	"If 1, only admins with with access to sm_spyi will be able to use the improvements",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	cv_cloakedSpeed = CreateConVar("sm_spyi_cloaked_speed", "350.0",
	"Spy speed when he is cloaked, 300 = Disabled",
	FCVAR_PLUGIN|FCVAR_NOTIFY, true, 220.0, true, 400.0);
	
	
	spySpeed = TF2_GetClassBaseSpeed(TFClass_Spy);
	speedOffset = FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
}

public OnGameFrame(){
	new bool:adminOnly = GetConVarBool(cv_admin);
	new Float:cloakedSpeed = GetConVarFloat(cv_cloakedSpeed);
	
	for(new i=1;i<=MaxClients;++i){
		if(!IsClientInGame(i)) continue;
		if(TF2_GetPlayerClass(i)!=TFClass_Spy) continue;
		if(!IsPlayerAlive(i)) continue;
		if(adminOnly
		&& !CheckCommandAccess(i, "sm_spyi", ADMFLAG_RESERVATION)){
			continue;
		}
		
		new buttons=GetClientButtons(i);
		new flags=TF2_GetPlayerConditionFlags(i);
		
		if(cloakedSpeed!=spySpeed){
			if(flags & TF_CONDFLAG_CLOAKED){
				if(GetEntDataFloat(i, speedOffset)!=cloakedSpeed){
					SetEntDataFloat(i, speedOffset, cloakedSpeed, true);
				}
			}else{
				if(GetEntDataFloat(i, speedOffset)==cloakedSpeed){
					SetEntDataFloat(i, speedOffset, spySpeed, true);
				}
				if(buttons & IN_RELOAD){
					SetEntDataFloat(i, speedOffset, spySpeed, true);
				}else{
					SetSpyDisguiseSpeed(i);
				}
			}
		}
	}
}

stock SetSpyDisguiseSpeed(i){
	new TFClassType:class = TFClassType:GetEntProp(i, Prop_Send, "m_nDisguiseClass");
	new Float:speed;
	if(!(TF2_GetPlayerConditionFlags(i) & TF_CONDFLAG_DISGUISED)){
		speed=spySpeed;
	}else{
		speed=TF2_GetClassBaseSpeed(class);
		if(speed>spySpeed){
			speed=spySpeed;
		}
	}
	SetEntDataFloat(i, speedOffset, speed, true);
}



stock Float:TF2_GetClassBaseSpeed(TFClassType:class){
	switch (class){
		case TFClass_Scout:     return 400.0;
		case TFClass_Soldier:   return 240.0;
		case TFClass_DemoMan:   return 280.0;
		case TFClass_Medic:     return 320.0;
		case TFClass_Heavy:     return 230.0;
	}
	return 300.0;
}

stock IsValid(i){
	if(i>MaxClients) return false;
	if(i<=0) return false;
	return IsClientInGame(i);
}