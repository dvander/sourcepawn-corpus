/*
	"rage_custom_arms"
	{
		"arm_model"	"models/weapons/c_models/c_scout_arms.mdl"

		"plugin_name"	"ff2r_arm"
	}
*/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cfgmap>
#include <ff2r>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[FF2R] Arm",
	author = "Sandy",
	description = "The FF2R sub-plugin allow bosses to give custom arms",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public Action OnWeaponEquip(int client, int weapon) {
	if (IsValidEntity(weapon)) {
		BossData boss = FF2R_GetBossData(client);
		if (boss) {
			AbilityData ability = boss.GetAbility("rage_custom_arms");
			if (!ability.IsMyPlugin()) {
				return Plugin_Continue;
			}
			
			char model[PLATFORM_MAX_PATH];
			if (ability.GetString("arm_model", model, sizeof(model)) && FileExists(model, true)) {
				PrecacheModel(model);
				
				SetEntityModel(weapon, model);
				SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
				SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
			}
		}
	}
	
	return Plugin_Continue;
}