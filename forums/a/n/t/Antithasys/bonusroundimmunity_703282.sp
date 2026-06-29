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

#define PLUGIN_VERSION "1.1.0"

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
	author = "Antithasys",
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
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				IsPlayerImmune[i] = false;
			}
		}
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = true;
	if (IsEnabled) {
		for (new i = 1; i <= maxclients; i++) {
			if (IsPlayerAdmin[i]) {
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				IsPlayerImmune[i] = true;
			}
		}
	}
}

public HookPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsEnabled && IsPlayerAdmin[client] && RoundEnd) {
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		IsPlayerImmune[client] = true;
	}
}

stock CleanUp(client)
{
	IsPlayerAdmin[client] = false;
	if (IsPlayerImmune[client]) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);	
		IsPlayerImmune[client] = false;
	}
}

stock bool:IsValidAdmin(client, const String:flags[])
{
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
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
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