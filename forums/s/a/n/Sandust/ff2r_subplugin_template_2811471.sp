/*
	"rage_hinttext"	// Ability name can use suffixes
	{
		"slot"			"0"							// Ability Slot
		"message"		"Go Get Them Maggot!"		// Hinttext Message
		"delay"			"15.0"						// Delay before first use
		"cooldown"		"20.0"						// Cooldown
		"plugin_name"	"ff2r_subplugin_templete"	// Plugin Name
	}
*/

#include <sourcemod>
#include <cfgmap>
#include <ff2r>

#pragma semicolon 1
#pragma newdecls required

/**
 * If you want to use formula to your ability, uncomment this.
 * This file provides ParseFormula functions.
 */
//#include "freak_fortress_2/formula_parser.sp"

/**
 * After 2023-07-25 Update, we don't need to set 36.
 */
//#define MAXTF2PLAYERS MAXPLAYERS + 1

/**
 * Original author is J0BL3SS. But he is retired and privatize all his plugins.
 * 
 * Your plugin's info. Fill it.
 */
public Plugin myinfo = {
	name = "[FF2R] ",
	author = "",
	description = "",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart() {
	/**
	 * Most subplugins are late-loaded by ff2r main plugin.
	 * So we need to make late-load support for ability.
	 * 
	 * If you don't need late-load support, remove this.
	 */
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			OnClientPutInServer(client);
			
			BossData cfg = FF2R_GetBossData(client);
			if (cfg) {
				FF2R_OnBossCreated(client, cfg, false);
				FF2R_OnBossEquipped(client, true);
			}
		}
	}
}

public void OnPluginEnd() {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && FF2R_GetBossData(client)) {
			FF2R_OnBossRemoved(client);
		}
	}
}

/**
 * Usually, SDKHook on OnTakeDamage here. But you can use nosoop's SM-TFOnTakeDamage instead.
 */
public void OnClientPutInServer(int client) {
	
}

/**
 * When boss created, hook the abilities here.
 * 
 * We no longer use RoundStart Event to hook abilities because bosses can be created trough 
 * manually by command in other gamemodes other than Arena or create bosses mid-round.
 * 
 * Actually, this forward is called twice. OnBossSpawn and OnRoundStart.
 * 
 * Add the following conditions to make it work only at the start of the round.
 * if (!setup || FF2R_GetGamemodeType() != 2) {
 * 
 * }
 */
public void FF2R_OnBossCreated(int client, BossData cfg, bool setup) {
	if (!setup || FF2R_GetGamemodeType() != 2) {
		AbilityData ability = cfg.GetAbility("rage_hinttext");
		if (ability.IsMyPlugin()) {
			/**
			 * FF2R_OnAbility makes it easy to confuse BossData and AbilityData.
			 * So be careful to using.
			 */
			ability.SetFloat("delay", GetGameTime() + ability.GetFloat("delay"));
		}
	}
}

/**
 * This is literally just "post_inventory_application" for boss.
 */
public void FF2R_OnBossEquipped(int client, bool weapons) {
	
}

/**
 * When boss removed (Died?/Left the Game/New Round Started)
 * 
 * You can use this to unhook and clear abilities from the player(s).
 */
public void FF2R_OnBossRemoved(int clientIdx) {
	
}

/**
 * When before using ability
 * 
 * You can block using ability here.
 */
public Action FF2R_OnAbilityPre(int client, const char[] ability, AbilityData cfg, bool &result) {	
	/**
	 * Cooldown check.
	 */
	if (!StrContains(ability, "rage_hinttext", false) && cfg.IsMyPlugin()) {
		if (cfg.GetFloat("delay") > GetGameTime()) {
			result = false;
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

/**
 * When using ability
 */
public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg) {
	/**
	 * Use !StrContains to suffix.
	 * 
	 * Call IsMyPlugin to avoid wrong plugin name.
	 * 
	 * NOTE: AbilityData's method "IsMyPlugin()" includes null check.
	 */
	if (!StrContains(ability, "rage_hinttext", false) && cfg.IsMyPlugin()) {
		char message[128];
		cfg.GetString("message", message, sizeof(message));
		
		if (message[0]) {
			PrintHintText(client, message);
		} else {
			PrintHintText(client, "fill up your \"message\" argument lol");
		}
		
		/**
		 * Add cooldown. Use cfgmap instead of declaring global cooldown variables.
		 */
		cfg.SetFloat("delay", GetGameTime() + cfg.GetFloat("cooldown"));
	}
}