#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.1"
public Plugin:myinfo = {
	name = "[TF2] Set Speed",
	author = "ChauffeR",
	version = PLUGIN_VERSION
}

public OnPluginStart() {
	RegAdminCmd("sm_setspeed", SetSpeed, ADMFLAG_CHEATS, "Sets speed on other players.");	
	CreateConVar( "sm_c_setspeed_version", PLUGIN_VERSION, "ChauffeR's Set Speed Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
}

public OnPluginEnd() {
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			RemoveAttribute(i, "major move speed bonus");
		}
	}
}

public OnClientDisconnect(client) {
	RemoveAttribute(client, "major move speed bonus");
}

public Action:SetSpeed(client, args)
{
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:value = StringToFloat(arg2);
	new Float:showvalue = value;
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_FILTER_CONNECTED,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(args < 2) {
		ReplyToCommand(client, "Format: sm_setspeed <player> <speed>");
		return Plugin_Handled;
	}
	
	if(args == 2) {
		for(new i = 0; i < target_count; i++) {
			new target = target_list[i];
			if(IsValidClient(target)) {
				if(value <= 0.001) value = 0.001;
				AddAttribute(target, "major move speed bonus", value);
			}
			LogAction(client, target, "\"%L\" changed speed of \"%L\" (value %f)", client, target, showvalue);
		}
		ShowActivity2(client, "[SM] ","Set speed of %s to %f", target_name, showvalue);
	}
	return Plugin_Handled;
}
stock AddAttribute(client, String:attribute[], Float:value) {
	if(IsValidClient(client)) {
		TF2Attrib_SetByName(client, attribute, value);
		TF2Attrib_ClearCache(client);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	}
}

stock RemoveAttribute(client, String:attribute[]) {
	if(IsValidClient(client)) {
		TF2Attrib_RemoveByName(client, attribute);
		TF2Attrib_ClearCache(client);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	}
}

stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}