#pragma semicolon 1
#define DEBUG

#define PLUGIN_AUTHOR "AI"
#define PLUGIN_VERSION "0.1.0"

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "Hyper Scout",
	author = PLUGIN_AUTHOR,
	description = "Full hype for Soda Poppers",
	version = PLUGIN_VERSION,
	url = "http://jumpacademy.tf"
};

public void OnPluginStart()
{
	CreateConVar("hyperscout_version", PLUGIN_VERSION, "Hyper Scout plugin version", FCVAR_PLUGIN | FCVAR_NOTIFY);
	
	HookEvent("player_spawn", Event_EquipWeapon);
	HookEvent("player_changeclass", Event_EquipWeapon);
	HookEvent("post_inventory_application", Event_EquipWeapon);
}

public Action Event_EquipWeapon(Event hEvent, const char[] sName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (TF2_GetPlayerClass(iClient) == TFClass_Scout && CheckCommandAccess(iClient, "hyperscout_access", 0)) {
		int iWeapon = GetPlayerWeaponSlot(iClient, 0);
		if (iWeapon != -1) {
			char sClassName[32];
			GetEdictClassname(iWeapon, sClassName, sizeof(sClassName));

			if (StrEqual(sClassName, "tf_weapon_soda_popper")) {
				SetEntPropFloat(iClient, Prop_Send, "m_flHypeMeter", view_as<float>(0x7F800000)); // +Infinity hype
			} else {
				SetEntPropFloat(iClient, Prop_Send, "m_flHypeMeter", 0.0); // No hype
			}
		}
	}
	
	return Plugin_Continue;
}
