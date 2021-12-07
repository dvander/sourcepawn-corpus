/*
 * Mandatory Taunt Mode for TF2
 * Written by chundo (chundo@mefightclub.com)
 *
 * Licensed under the GPLv3
 */

#include <sourcemod>

#pragma semicolon 1

#define TAUNT_PLUGIN_VERSION "0.3"

new Handle:g_cvarTauntEnable = INVALID_HANDLE;
new Handle:g_cvarTauntChance = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Mandatory Taunt",
	author = "chundo",
	description = "Force taunting after a player makes a kill",
	version = TAUNT_PLUGIN_VERSION,
	url = "http://www.mefightclub.com/"
};

public OnPluginStart() {
	LoadTranslations("taunt.phrases");
	CreateConVar("sm_taunt_version", TAUNT_PLUGIN_VERSION, "Mandatory Taunt Mode version.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvarTauntEnable = CreateConVar("sm_taunt_enable", "0", "Force players to taunt after a kill", FCVAR_PLUGIN);
	g_cvarTauntChance = CreateConVar("sm_taunt_chance", "1.0", "Probability that a player will be forced to taunt (0.5 = 50%, 1.0 = 100%, etc.)", FCVAR_PLUGIN);
	RegAdminCmd("sm_taunt", Command_Taunt, ADMFLAG_SLAY, "Force a player to taunt", "taunt", FCVAR_PLUGIN);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookConVarChange(g_cvarTauntEnable, TauntEnableChanged);
	AutoExecConfig(false);
}

public TauntEnableChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "1") == 0) {
			PrintToChatAll("%c[SM] %c%t %c%t!", 0x01, 0x04, "Mandatory taunt mode", 0x01, "enabled");
		} else {
			PrintToChatAll("%c[SM] %c%t %c%t!", 0x01, 0x04, "Mandatory taunt mode", 0x01, "disabled");
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new Float:rand = GetRandomFloat(0.0, 1.0);
	if (GetConVarBool(g_cvarTauntEnable)
			&& GetConVarFloat(g_cvarTauntChance) >= rand) {
		new attacker_id = GetEventInt(event, "attacker");
		new attacker = GetClientOfUserId(attacker_id);
		PerformTaunt(0, attacker);
	}

}

public Action:Command_Taunt(client, args) {
	if (args < 1) {   
		ReplyToCommand(client, "[SM] Usage: sm_taunt <#userid|name>");
		return Plugin_Handled;
	}   

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0) {   
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}   

	for (new i = 0; i < target_count; i++)
		PerformTaunt(client, target_list[i]);

	ShowActivity2(client, "[SM] ", "%t %s", "Forced taunt on target", target_name);

	return Plugin_Handled;
}

public PerformTaunt(client, target) {
	LogAction(client, target, "\"%L\" forced \"%L\" to taunt", client, target);
	FakeClientCommand(target, "taunt");
}
