#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "2.0"

new Handle:cvarEnabled;
new Handle:cvarAdminsOnly;
new Handle:cvarScout;
new Handle:cvarSoldier;
new Handle:cvarPyro;
new Handle:cvarDemoman;
new Handle:cvarHeavy;
new Handle:cvarEngineer;
new Handle:cvarMedic;
new Handle:cvarSniper;
new Handle:cvarSpy;

new bool:Enabled;
new Float:ScoutSpeed;
new Float:SoldierSpeed;
new Float:PyroSpeed;
new Float:DemoSpeed;
new Float:HeavySpeed;
new Float:EngineerSpeed;
new Float:MedicSpeed;
new Float:SniperSpeed;
new Float:SpySpeed;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = {
	name = "[TF2] Change Class Speed",
	author = "Tak (Chaosxk)",
	description = "A working class speed changer for TF2",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart() {
	CreateConVar("ccs_version", PLUGIN_VERSION, "Change Class Speed Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cvarEnabled = CreateConVar("ccs_enabled", "1", "Enable/Disable Class Speeds.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAdminsOnly = CreateConVar("ccs_admin", "0", "Set speeds for Admins only?\n0 = Public\n1 = Admins", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvarScout 		= 		CreateConVar("ccs_scout_speed", "520.0", "Sets speed for Scout.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarSoldier 	= 		CreateConVar("ccs_soldier_speed", "520.0", "Sets speed for Soldier.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarPyro 		= 		CreateConVar("ccs_pyro_speed", "520.0", "Sets speed for Pyro.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarDemoman 	= 		CreateConVar("ccs_demoman_speed", "520.0", "Sets speed for Demoman.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarHeavy 		= 		CreateConVar("ccs_heavy_speed", "520.0", "Sets speed for Heavy.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarEngineer 	=	 	CreateConVar("ccs_engineer_speed", "520.0", "Sets speed for Engineer.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarMedic 		= 		CreateConVar("ccs_medic_speed", "520.0", "Sets speed for Medic.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarSniper		= 		CreateConVar("ccs_sniper_speed", "520.0", "Sets speed for Sniper.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	cvarSpy 		=		CreateConVar("ccs_spy_speed", "520.0", "Sets speed for Spy.", FCVAR_PLUGIN, true, 0.0, true, 520.0);
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath);
	
	HookConVarChange(cvarEnabled, cvarChange);
	HookConVarChange(cvarScout, cvarChange);
	HookConVarChange(cvarSoldier, cvarChange);
	HookConVarChange(cvarPyro, cvarChange);
	HookConVarChange(cvarDemoman, cvarChange);
	HookConVarChange(cvarHeavy, cvarChange);
	HookConVarChange(cvarEngineer, cvarChange);
	HookConVarChange(cvarMedic, cvarChange);
	HookConVarChange(cvarSniper, cvarChange);
	HookConVarChange(cvarSpy, cvarChange);
	
	AutoExecConfig(true, "ccspeed_config");
	LoadTranslations("common.phrases");
}

public OnPluginEnd() {
	UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookConVarChange(cvarEnabled, cvarChange);
	UnhookConVarChange(cvarScout, cvarChange);
	UnhookConVarChange(cvarSoldier, cvarChange);
	UnhookConVarChange(cvarPyro, cvarChange);
	UnhookConVarChange(cvarDemoman, cvarChange);
	UnhookConVarChange(cvarHeavy, cvarChange);
	UnhookConVarChange(cvarEngineer, cvarChange);
	UnhookConVarChange(cvarMedic, cvarChange);
	UnhookConVarChange(cvarSniper, cvarChange);
	UnhookConVarChange(cvarSpy, cvarChange);
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		RemoveAttribute(i, "move speed bonus");
		ChangePlayerWeaponSlot(i);
		TF2_RegeneratePlayer(i);
	}
}

public OnConfigsExecuted() {
	Enabled = GetConVarBool(cvarEnabled);
	ScoutSpeed = GetConVarFloat(cvarScout);
	SoldierSpeed = GetConVarFloat(cvarSoldier);
	PyroSpeed = GetConVarFloat(cvarPyro);
	DemoSpeed = GetConVarFloat(cvarDemoman);
	HeavySpeed = GetConVarFloat(cvarHeavy);
	EngineerSpeed = GetConVarFloat(cvarEngineer);
	MedicSpeed = GetConVarFloat(cvarMedic);
	SniperSpeed = GetConVarFloat(cvarSniper);
	SpySpeed = GetConVarFloat(cvarSpy);
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		new bool:AdminsOnly = GetConVarBool(cvarAdminsOnly);
		if(AdminsOnly && CheckCommandAccess(i, "ccs_adminflag", ADMFLAG_GENERIC) || !AdminsOnly) {
			SetClientSpeed(i);
		}
	}
}

public cvarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(convar == cvarEnabled) Enabled = GetConVarBool(cvarEnabled); 
	else if(convar == cvarScout) ScoutSpeed = GetConVarFloat(cvarScout);
	else if(convar == cvarSoldier) SoldierSpeed = GetConVarFloat(cvarSoldier);
	else if(convar == cvarPyro) PyroSpeed = GetConVarFloat(cvarPyro);
	else if(convar == cvarDemoman) DemoSpeed = GetConVarFloat(cvarDemoman);
	else if(convar == cvarHeavy) HeavySpeed = GetConVarFloat(cvarHeavy);
	else if(convar == cvarEngineer) EngineerSpeed = GetConVarFloat(cvarEngineer);
	else if(convar == cvarMedic) MedicSpeed = GetConVarFloat(cvarMedic);
	else if(convar == cvarSniper) SniperSpeed = GetConVarFloat(cvarSniper);
	else if(convar == cvarSpy) SpySpeed = GetConVarFloat(cvarSpy);
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		new bool:AdminsOnly = GetConVarBool(cvarAdminsOnly);
		if(AdminsOnly && CheckCommandAccess(i, "ccs_adminflag", ADMFLAG_GENERIC) || !AdminsOnly) {
			SetClientSpeed(i);
		}
	}
}

public OnClientDisconnect(client) {
	RemoveAttribute(client, "move speed bonus");
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	if(!Enabled) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return Plugin_Continue;
	if(!IsPlayerAlive(client)) return Plugin_Continue;
	new bool:AdminsOnly = GetConVarBool(cvarAdminsOnly);
	if(AdminsOnly && CheckCommandAccess(client, "ccs_adminflag", ADMFLAG_GENERIC) || !AdminsOnly) {
		SetClientSpeed(client);
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return Plugin_Continue;
	RemoveAttribute(client, "move speed bonus");
	return Plugin_Continue;
}

SetClientSpeed(client) {
	new TFClassType:Class = TF2_GetPlayerClass(client);
	new Float:ClientSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
	switch(Class) {
		case TFClass_Scout: AddAttribute(client, "move speed bonus", ScoutSpeed/ClientSpeed);
		case TFClass_Soldier: AddAttribute(client, "move speed bonus", SoldierSpeed/ClientSpeed);
		case TFClass_Pyro: AddAttribute(client, "move speed bonus", PyroSpeed/ClientSpeed);
		case TFClass_DemoMan: AddAttribute(client, "move speed bonus", DemoSpeed/ClientSpeed);
		case TFClass_Heavy: AddAttribute(client, "move speed bonus", HeavySpeed/ClientSpeed);
		case TFClass_Engineer: AddAttribute(client, "move speed bonus", EngineerSpeed/ClientSpeed);
		case TFClass_Medic: AddAttribute(client, "move speed bonus", MedicSpeed/ClientSpeed);
		case TFClass_Sniper: AddAttribute(client, "move speed bonus", SniperSpeed/ClientSpeed);
		case TFClass_Spy: AddAttribute(client, "move speed bonus", SpySpeed/ClientSpeed);
	}
	TF2_RegeneratePlayer(client);
}

stock AddAttribute(client, String:attribute[], Float:value) {
	if(IsValidClient(client)) {
		TF2Attrib_SetByName(client, attribute, value);
	}
}

stock RemoveAttribute(client, String:attribute[]) {
	if(IsValidClient(client)) {
		TF2Attrib_RemoveByName(client, attribute);
	}
}

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}