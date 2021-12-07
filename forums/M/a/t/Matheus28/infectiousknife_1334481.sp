#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"
#define PLUGIN_PREFIX "\x04[Infectious Knife]\x01"

#define CFG_INFECTION_KILL 9.0
#define CFG_INFECTION_SHOW 5.0

#define CFG_CLOAK_BONUS 35.0

public Plugin:myinfo = 
{
	name = "Infectious Knife",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

new bool:disguise[MAXPLAYERS+1];
new Float:lifetime[MAXPLAYERS+1];
new bool:hasInfection[MAXPLAYERS+1];
new infector[MAXPLAYERS+1];

new m_nDisguiseClass[MAXPLAYERS+1];
new m_nDisguiseTeam[MAXPLAYERS+1];
new m_iDisguiseTargetIndex[MAXPLAYERS+1];
new m_iDisguiseHealth[MAXPLAYERS+1];
new m_hDisguiseWeapon[MAXPLAYERS+1];
new bool:infectiousKnife[MAXPLAYERS+1];
new bool:changeInfectiousKnife[MAXPLAYERS+1];
new bool:suicide[MAXPLAYERS+1];
new bool:inRespawn[MAXPLAYERS+1]={false};
new Float:maxCloakLevel[MAXPLAYERS+1]={100.0};

new Float:tickRate;

new Handle:cv_admin;
new Handle:cv_print;


public OnPluginStart(){
	CreateConVar("sm_infectiousknife_version",
	PLUGIN_VERSION, "infectious Knife Version",
	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD,
	true, StringToFloat(PLUGIN_VERSION), true, StringToFloat(PLUGIN_VERSION));
	
	cv_admin=CreateConVar("sm_infectiousknife_admin", "0", "Only admins with reservation flag can use this knife.", FCVAR_NOTIFY, true, _, true);
	cv_print=CreateConVar("sm_infectiousknife_print", "1", "Informs the players how to use the knife (if sm_infectiousknife_admin = 1, this will only inform admins)", FCVAR_NOTIFY, true, _, true);
	
	tickRate=GetTickInterval();
	
	RegConsoleCmd("sm_infectiousknife", Cmd_Infectious, "Toggles your infectious knife");
	//RegConsoleCmd("sm_infectiousdebug", Cmd_Debug, "");
	
	
	HookEvent("player_spawn", player_spawn);
	
	HookEntityOutput("func_respawnroom","OnStartTouch", EH_StartTouchRespawn);
	HookEntityOutput("func_respawnroom","OnEndTouch", EH_EndTouchRespawn);
	
	CreateTimer(120.0, Timer_Print, _, TIMER_REPEAT);
	
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i)){
			ResetClientVars(i);
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_PostThink, OnPostThink);
		}
	}
}

public Action:Timer_Print(Handle:timer){
	if(!GetConVarBool(cv_print)) return;
	for(new i=1;i<=MaxClients;++i){
		if(IsValid(i)){
			if(GetConVarBool(cv_admin) && !GetAdminFlag(GetUserAdmin(i), Admin_Reservation)){
				continue;
			}
			
			PrintToChat(i, "%s To use the new Infectious Knife as a Spy, type /infectiousknife", PLUGIN_PREFIX);
		}
	}
}

public OnClientPutInServer(client){
	ResetClientVars(client);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}

public OnClientDisconnect_Post(client){
	ResetClientVars(client);
}

public ResetClientVars(i){
	disguise[i]=false;
	changeInfectiousKnife[i]=false;
	infectiousKnife[i]=false;
	hasInfection[i]=false;
	infector[i]=0;
	suicide[i]=false;
	maxCloakLevel[i]=1.0;
	inRespawn[i]=false;
}

public Action:Cmd_Debug(client, args){
	if(hasInfection[client]) return Plugin_Handled;
	if(!IsPlayerAlive(client)) return Plugin_Handled;
	PrintCenterText(client, "Debug Infection ON, you are now infected.\n(But you shouldn't know yet, pretend you don't :D)");
	hasInfection[client]=true;
	infector[client]=client;
	lifetime[client]=CFG_INFECTION_KILL;
	
	return Plugin_Handled;
}

public Action:Cmd_Infectious(client, args){
	if(client==0) return Plugin_Continue;
	if(GetConVarBool(cv_admin) && !GetAdminFlag(GetUserAdmin(client), Admin_Reservation)){
		ReplyToCommand(client, "%s You do not have access to this command", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	changeInfectiousKnife[client]=!changeInfectiousKnife[client];
	
	if(!inRespawn[client]){
		// That's why you need to use condoms...
		new bool:willHasAids = infectiousKnife[client];
		
		if(changeInfectiousKnife[client]){
			willHasAids=!willHasAids;
		}
		if(willHasAids){
			ReplyToCommand(client, "%s Your Infectious Knife will be enabled next time you respawn.", PLUGIN_PREFIX);
		}else{
			ReplyToCommand(client, "%s Your Infectious Knife will be disabled next time you respawn.", PLUGIN_PREFIX);
		}
	}else{
		ChangeKnife(client);
	}
	return Plugin_Handled;
}

public EH_StartTouchRespawn(const String:output[], caller, activator, Float:delay){
	inRespawn[activator]=true;
}
public EH_EndTouchRespawn(const String:output[], caller, activator, Float:delay){
	inRespawn[activator]=false;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype){
	decl String:weapon[64];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(HasKnife(attacker)
	&& victim!=attacker
	&& attacker==inflictor
	&& IsValid(attacker)
	&& TF2_GetPlayerClass(attacker)==TFClass_Spy
	&& StrEqual(weapon, "tf_weapon_knife")
	){
		new Float:attacker_pos[3];
		new Float:victim_pos[3]; 
		new Float:victim_fwd[3];
		new Float:victim_eyes[3];
		new Float:angle_diff;
		new Float:angle_vec[3];
		GetClientAbsOrigin(attacker, attacker_pos);
		GetClientAbsOrigin(victim, victim_pos);
		attacker_pos[2] = victim_pos[2];

		GetClientEyeAngles(victim, victim_eyes);
		GetAngleVectors(victim_eyes, victim_fwd, NULL_VECTOR, NULL_VECTOR);
		MakeVectorFromPoints(victim_pos, attacker_pos, angle_vec);
		NormalizeVector(angle_vec, angle_vec);
		angle_diff = GetVectorDotProduct(victim_fwd, angle_vec);
		if (angle_diff >= 0.1){
			return Plugin_Continue;
		}
		
		damage=0.0;
		if(m_nDisguiseClass[attacker] != 0){
			disguise[attacker]=true;
		}
		
		if(!hasInfection[victim]){
			PrintCenterText(attacker, "You infected him!");
			TF2_SetCloak(attacker, TF2_GetCloak(attacker)+CFG_CLOAK_BONUS);
			hasInfection[victim]=true;
			lifetime[victim]=CFG_INFECTION_KILL;
			infector[victim]=attacker;
		}else{
			PrintCenterText(attacker, "He is already infected!");
		}
		
		return Plugin_Stop;
	}
	return Plugin_Continue;
}



public bool:HasKnife(i){
	if(!IsPlayerAlive(i)){
		return false;
	}
	return infectiousKnife[i] && GetEntProp(GetPlayerWeaponSlot(i, 2), Prop_Send, "m_iItemDefinitionIndex")==4;
}

public OnPostThink(i){
	if(suicide[i]){
		suicide[i]=false;
		if(IsPlayerAlive(i)){
			ForcePlayerSuicide(i);
		}
	}
	
	if(hasInfection[i]){
		if(inRespawn[i]){
			PrintCenterText(i, "You entered in your respawn, you are now cured.");
			hasInfection[i]=false;
		}else if(IsValid(infector[i])){
			new medics=GetEntProp(i,Prop_Send,"m_nNumHealers");
			if(medics>0 && IsPlayerAlive(i)){
				lifetime[i] += 1.0*tickRate*2*medics;
				if(lifetime[i]>CFG_INFECTION_KILL){
					hasInfection[i]=false;
					PrintCenterText(i, "The medic cured you");
				}else{
					if(!(TF2_GetPlayerConditionFlags(i)&_:TFCond_Bonked)){
						TF2_StunPlayer(i, 1.0, 0.2, TF_STUNFLAG_SLOWDOWN | TF_STUNFLAG_THIRDPERSON | TF_STUNFLAG_NOSOUNDOREFFECT , infector[i]);
					}
					new rlifetime=RoundToCeil((CFG_INFECTION_KILL-lifetime[i])/2);
					if(rlifetime>0){
						PrintCenterText(i, "The medic is curing you\nYour infection will be cured in %d seconds", rlifetime);
					}
				}
			}else if(lifetime[i]>0.0 && IsPlayerAlive(i)){
				lifetime[i] -= 1.0*tickRate;
				if(lifetime[i]<CFG_INFECTION_SHOW){
					if(!(TF2_GetPlayerConditionFlags(i)&_:TFCond_Bonked)){
						TF2_StunPlayer(i, 1.0, 0.2, TF_STUNFLAG_SLOWDOWN | TF_STUNFLAG_THIRDPERSON | TF_STUNFLAG_NOSOUNDOREFFECT , infector[i]);
					}
					new rlifetime=RoundToCeil(lifetime[i]);
					if(rlifetime>0){
						PrintCenterText(i, "You are infected! Find a medic to survive!\nExpected lifetime: %d seconds", rlifetime);
					}
				}
			}else{
				hasInfection[i]=false;
				if(IsPlayerAlive(i)){
					suicide[i]=true;
					DealDamage(i, 1, infector[i]);
					PrintCenterText(i, "You died from the infection");
				}
			}
		}else{
			hasInfection[i]=false;
		}
	}
	if(disguise[i]){
		disguise[i]=false;
		if(IsPlayerAlive(i)){
			TF2_AddCondition(i, TFCond_Disguised, 999.0);
			SetEntProp(i, Prop_Send, "m_nDisguiseClass", m_nDisguiseClass[i]);
			SetEntProp(i, Prop_Send, "m_nDisguiseTeam", m_nDisguiseTeam[i]);
			SetEntProp(i, Prop_Send, "m_iDisguiseTargetIndex", m_iDisguiseTargetIndex[i]);
			SetEntProp(i, Prop_Send, "m_iDisguiseHealth", m_iDisguiseHealth[i]);
			SetEntProp(i, Prop_Send, "m_hDisguiseWeapon", m_hDisguiseWeapon[i]);
			
		}
	}
	if(HasKnife(i) && TF2_GetPlayerClass(i)==TFClass_Spy && IsPlayerAlive(i)){
		m_nDisguiseClass[i] = GetEntProp(i, Prop_Send, "m_nDisguiseClass");
		m_nDisguiseTeam[i] = GetEntProp(i, Prop_Send, "m_nDisguiseTeam");
		m_iDisguiseTargetIndex[i] = GetEntProp(i, Prop_Send, "m_iDisguiseTargetIndex");
		m_iDisguiseHealth[i] = GetEntProp(i, Prop_Send, "m_iDisguiseHealth");
		m_hDisguiseWeapon[i] = GetEntProp(i, Prop_Send, "m_hDisguiseWeapon");
		
		new Float:cloaklevel = TF2_GetCloak(i);
		if(cloaklevel>maxCloakLevel[i]){
			TF2_SetCloak(i, maxCloakLevel[i], false);
		}else if(cloaklevel<maxCloakLevel[i]){
			maxCloakLevel[i]=cloaklevel;
		}
	}
}

stock TF2_SetCloak(client, Float:amount, bool:save=true){
	if(amount>100.0){
		amount=100.0;
	}else if(amount<0.0){
		amount=0.0;
	}
	if(save && maxCloakLevel[client]<amount){
		maxCloakLevel[client]=amount;
	}
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", amount);
}

stock Float:TF2_GetCloak(client){
	return GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	maxCloakLevel[client]=100.0;
	ChangeKnife(client);
}


public ChangeKnife(client){
	if(!changeInfectiousKnife[client]) return;
	changeInfectiousKnife[client]=false;
	infectiousKnife[client] = !infectiousKnife[client];
	if(infectiousKnife[client]){
		PrintToChat(client, "%s Your Infectious Knife is enabled.", PLUGIN_PREFIX);
	}else{
		PrintToChat(client, "%s Your Infectious Knife is disabled.", PLUGIN_PREFIX);
	}
}

stock DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]=""){
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0){
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt>0){
			DispatchKeyValue(victim,"targetname","infectious_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","infectious_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,"")){
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt", attacker);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","infectious_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}
stock IsValid(client){
	if(client<=0){
		return false;
	}
	if(client>MaxClients){
		return false;
	}
	if(!IsClientConnected(client)){
		return false;
	}
	if(!IsClientInGame(client)){
		return false;
	}
	return true;
}