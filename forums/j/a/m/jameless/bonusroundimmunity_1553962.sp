/* Bonus Round Immunity
 *  By Antithasys
 *  http://www.mytf2.com
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
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1.0b"

new Handle:bri_charadminflag = INVALID_HANDLE;
new Handle:bri_enabled = INVALID_HANDLE;
new bool:IsPlayerAdmin[MAXPLAYERS + 1];
new bool:IsPlayerImmune[MAXPLAYERS + 1];
new bool:IsEnabled = true;
new bool:RoundEnd = false;
new String:CharAdminFlag[32];
new maxclients;

public Plugin:myinfo =
{
	name = "Bonus Round Immunity",
	author = "Antithasys; modified by NuclearWatermelon soundfix by jameless",
	description = "Gives admins immunity during bonus round",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("brimmunity_version", PLUGIN_VERSION, "Bonus Round Immunity", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	bri_enabled = CreateConVar("bri_enabled", "1", "Enable/Disable Admin immunity during bonus round");
	bri_charadminflag = CreateConVar("bri_charadminflag", "a", "Admin flag to use for immunity (only one).  Must be a in char format.");
	HookConVarChange(bri_enabled, EnabledChanged);
	HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
	AutoExecConfig(true, "plugin.bonusroundimmunity");
}

public OnConfigsExecuted()
{
	GetConVarString(bri_charadminflag, CharAdminFlag, sizeof(CharAdminFlag));
	IsEnabled = GetConVarBool(bri_enabled);
	maxclients = GetMaxClients();
	RoundEnd = false;
}

public OnClientPostAdminCheck(client)
{
	if (IsValidAdmin(client, CharAdminFlag))
		IsPlayerAdmin[client] = true;
	else
		IsPlayerAdmin[client] = false;
}

public OnClientDisconnect(client)
{
	CleanUp(client);
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = false;
	if (IsEnabled) {
		for (new i = 1; i <= maxclients; i++) {
			if (IsPlayerAdmin[i] && IsPlayerImmune[i]) {
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				TF2_SetPlayerPowerPlay(i, false);
				IsPlayerImmune[i] = false;
			}
		}
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = true;
	CreateTimer((GetConVarFloat(FindConVar("mp_bonusroundtime"))-1.0),turnoffpp);
	if (IsEnabled) {
		for (new i = 1; i <= maxclients; i++) {
			if (IsPlayerAdmin[i]) {
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				TF2_SetPlayerPowerPlay(i, true);
				IsPlayerImmune[i] = true;
			}
		}
	}
}

public HookPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsEnabled && IsPlayerAdmin[client] && RoundEnd) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		TF2_SetPlayerPowerPlay(client, true);
		IsPlayerImmune[client] = true;
	}
}

stock CleanUp(client)
{
	IsPlayerAdmin[client] = false;
	if (IsPlayerImmune[client]) {
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		TF2_SetPlayerPowerPlay(client, false);	
		IsPlayerImmune[client] = false;
	}
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if (client == 0) return false;
	if (!IsClientConnected(client))
		return false;
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags) {
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) {
		return true;
	}
	return false;
}

public EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (IsEnabled) {
		UnhookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
		UnhookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
		UnhookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
		for (new i = 1; i <= maxclients; i++) {
			if (IsPlayerAdmin[i] && IsPlayerImmune[i]) {
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				TF2_SetPlayerPowerPlay(i, false);
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

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	new bool:victimadmin = IsValidAdmin(victim, CharAdminFlag);
	new bool:attackadmin = IsValidAdmin(attacker, CharAdminFlag);
	if (victimadmin) {
		if (attackadmin) {
			return Plugin_Continue;
		}
		else {
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	else {
		return Plugin_Continue;
	}
}

public Action:turnoffpp(Handle:timer) {
	RoundEnd = false;
	if (IsEnabled) {
		for (new i = 1; i <= maxclients; i++) {
			if (IsPlayerAdmin[i] && IsPlayerImmune[i]) {
				TF2_SetPlayerPowerPlay(i, false);
			}
		}
	}
}