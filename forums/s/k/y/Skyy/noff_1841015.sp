#define PLUGIN_VERSION			"1.0"

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "No Friendly-Fire",
	author = "Sky",
	description = "Players cannot hurt teammates.",
	version = PLUGIN_VERSION,
	url = "mikel.toth@gmail.com"
}

new Handle:g_FriendlyFireDisabled;

public OnPluginStart()
{
	g_FriendlyFireDisabled			= CreateConVar("friendlyfire_disabled","1","If friendly-fire is disabled.");

	AutoExecConfig(true, "noff");
}

public OnConfigsExecuted()
{
	AutoExecConfig(true, "noff");
	CreateConVar("friendlyfire_version", PLUGIN_VERSION);
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsClientInGame(attacker) && IsClientInGame(victim) && GetClientTeam(attacker) == GetClientTeam(victim) && GetConVarInt(g_FriendlyFireDisabled) == 1)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}