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
	g_FriendlyFire_MitigationTime = CreateConVar("tmff_mitigation_time", "60.0", "The amount of time, in seconds, after a new player joins, that they can't cause friendly-fire to teammates. 0 to disable plugin.");

	AutoExecConfig(true, "tmff");
}

public OnAllPluginsLoaded()
{
    /* Account for late loading */
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client))
        {
            SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public OnConfigsExecuted()
{
	AutoExecConfig(true, "tmff");
	CreateConVar("tmff_version", PLUGIN_VERSION);
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    /* Suggested change; if time convar is zero then act as if the plugin was disabled. */
	if (GetConVarInt(g_FriendlyFire_MitigationTime) > 0)
    {
        bHasMitigation[client] = true;
        CreateTimer(GetConVarFloat(g_FriendlyFire_MitigationTime), Timer_AllowFriendlyFire, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public OnClientDisconnect(client)
{
	bHasMitigation[client] = false;
    // No need to unhook clients upon disconnecting (== entity destoryed), SDKHooks does that for you
}

public Action:Timer_AllowFriendlyFire(Handle:timer, any:userid)
{
    // We should use an userid instead since the client index may change hands in 60 seconds
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        bHasMitigation[client] = false;
    }

	return Plugin_Stop;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    /* Gotta make sure the attacker is within the client index range, 
     * otherwise you could end up with erorrs about variable going out of
     * range on damage entities that is larger than 32. 
     * bHasMitigation doubles as an IsClientInGame for the attacker since its
     * only set upon the client entering the server. */
    if (attacker > 0 || attacker <= MaxClients && bHasMitigation[attacker] && victim > 0 && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(attacker) == GetClientTeam(victim))
    {
        damage = 0.0;
		return Plugin_Changed;
    }

	return Plugin_Continue;
}