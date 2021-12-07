#define TEAM_SURVIVORS			2

#define PLUGIN_VERSION			"1.0"

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "Temporary Mitigation Friendly Fire",
	author = "Sky",
	description = "Temporarily mitigates the friendly fire for new players in a server.",
	version = PLUGIN_VERSION,
	url = "mikel.toth@gmail.com"
}

new Handle:g_FriendlyFire_MitigationTime;
new bool:bHasMitigation[MAXPLAYERS + 1];

public OnPluginStart()
{
	g_FriendlyFire_MitigationTime			= CreateConVar("tmff_mitigation_time","60","The amount of time, in seconds, after a new player joins, that they can't cause friendly-fire to teammates.");

	AutoExecConfig(true, "tmff");
}

public OnConfigsExecuted()
{
	AutoExecConfig(true, "tmff");
	CreateConVar("tmff_version", PLUGIN_VERSION);
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	bHasMitigation[client] = true;
	if (GetConVarInt(g_FriendlyFire_MitigationTime) > 0) CreateTimer(GetConVarInt(g_FriendlyFire_MitigationTime) * 1.0, Timer_AllowFriendlyFire, client, TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		bHasMitigation[client] = true;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:Timer_AllowFriendlyFire(Handle:timer, any:client)
{
	if (IsClientInGame(client)) bHasMitigation[client] = false;
	return Plugin_Stop;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVORS && bHasMitigation[attacker] && IsClientInGame(victim) && GetClientTeam(attacker) == GetClientTeam(victim))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}