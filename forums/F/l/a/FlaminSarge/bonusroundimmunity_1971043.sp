/* Bonus Round Immunity
 *  By Antithasys
 *  http://www.mytf2.com	//DEFUNCT WEBSITE
 *
 * Description:
 *			Gives admins immunity during the bonus round
 *
 * 1.1.0
 * Added spawn hook for cross plugin support
 *
 * 1.0.0
 * Initial Release
 *
 * Future Updates:
 *			None
 * Modifications by:
 *  FlaminSarge
 */
 
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.1.1"

new Handle:bri_enabled = INVALID_HANDLE;
new Handle:bri_mode = INVALID_HANDLE;
new bool:IsPlayerImmune[MAXPLAYERS + 1];
new bool:IsEnabled = true;
new bool:RoundEnd = false;

#define DEF_FLAG ADMFLAG_RESERVATION

public Plugin:myinfo =
{
	name = "Bonus Round Immunity",
	author = "Antithasys",
	description = "Gives admins immunity during bonus round",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=79363"
}

public OnPluginStart()
{
	CreateConVar("brimmunity_version", PLUGIN_VERSION, "Bonus Round Immunity", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	bri_enabled = CreateConVar("bri_enabled", "1", "Enable/Disable Admin immunity during bonus round", FCVAR_PLUGIN);
	bri_mode = CreateConVar("bri_mode", "1", "TakeDamage mode to set for immunity (0- GodMode, 1- Buddha, other values may work)", FCVAR_PLUGIN);
	HookConVarChange(bri_mode, ModeChanged);
	HookConVarChange(bri_enabled, EnabledChanged);
	HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
	AutoExecConfig(true, "plugin.bonusroundimmunity");
}

public OnConfigsExecuted()
{
	IsEnabled = GetConVarBool(bri_enabled);
	RoundEnd = false;
}

public OnClientDisconnect(client)
{
	CleanUp(client);
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = false;
	if (!IsEnabled) return;
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) continue;
		if (CheckCommandAccess(i, "bonusroundimmunity", DEF_FLAG, true) && IsPlayerImmune[i]) {
			if (GetEntProp(i, Prop_Data, "m_takedamage") == GetConVarInt(bri_mode)) SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			IsPlayerImmune[i] = false;
		}
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = true;
	if (!IsEnabled) return;
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) continue;
		if (CheckCommandAccess(i, "bonusroundimmunity", DEF_FLAG, true)) {
			if (GetEntProp(i, Prop_Data, "m_takedamage") == 2) SetEntProp(i, Prop_Data, "m_takedamage", GetConVarInt(bri_mode), 1);
			IsPlayerImmune[i] = true;
		}
	}
}

public HookPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsEnabled && CheckCommandAccess(client, "bonusroundimmunity", DEF_FLAG, true) && RoundEnd) {
		if (GetEntProp(client, Prop_Data, "m_takedamage") == 2) SetEntProp(client, Prop_Data, "m_takedamage", GetConVarInt(bri_mode), 1);
		IsPlayerImmune[client] = true;
	}
}

stock CleanUp(client)
{
	if (IsPlayerImmune[client]) {
		if (IsClientInGame(client)) SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);	
		IsPlayerImmune[client] = false;
	}
}

public ModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!IsEnabled) return;
	new oVal = StringToInt(oldValue);
	new nVal = StringToInt(newValue);
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) continue;
		if (GetEntProp(i, Prop_Data, "m_takedamage") == oVal) SetEntProp(i, Prop_Data, "m_takedamage", nVal, 1);
	}
}

public EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (IsEnabled) {
		UnhookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
		UnhookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
		UnhookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
		for (new i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i)) continue;
			if (CheckCommandAccess(i, "bonusroundimmunity", DEF_FLAG, true) && IsPlayerImmune[i]) {
				if (GetEntProp(i, Prop_Data, "m_takedamage") == GetConVarInt(bri_mode)) SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				IsPlayerImmune[i] = false;
			}
		}
		IsEnabled = false;
	} else {
		HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
		HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
		HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
		IsEnabled = true;
	}
}