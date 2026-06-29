#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0"

char g_strSupportedEntities[][] = {
	"tf_wearable",
	"wearable_item",
	"tf_wearable_demoshield",
	"tf_wearable_robot_arm",
	"tf_powerup_bottle",
	"tf_weapon_base",
	"tf_weapon_bat",
	"tf_weapon_bat_fish",
	"tf_weapon_bat_giftwrap",
	"tf_weapon_bat_wood",
	"tf_weapon_bonesaw",
	"tf_weapon_bottle",
};

public Plugin myinfo = {
	name = "[TF2] Serverside Player Attachment Fixer",
	author = "TF2CutContent",
	description = "Fixes the engine rendering entities attached to players invisible",
	version = PLUGIN_VERSION
};

public void OnPluginStart() {
	CreateConVar("sm_spafix_version", PLUGIN_VERSION, "[TF2] Serverside Player Attachment Fixer plugin version.", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

/**
 * Apparently, according to some, this method is "inefficient".
 * So I'm going to rewrite it and probably for-loop through the string array of supported entities.
 */
public void OnEntityCreated(int iEntity, const char[] strClassname) {
	if (IsValidEntity(iEntity) && HasEntProp(iEntity, Prop_Send, "m_bValidatedAttachedEntity")) {
		if (GetEntProp(iEntity, Prop_Send, "m_bValidatedAttachedEntity") != 0) return;
		SetEntProp(iEntity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
}
