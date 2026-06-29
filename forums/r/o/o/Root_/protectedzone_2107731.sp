#include <sdkhooks>
new	bool:InAZone[MAXPLAYERS + 1] = {false, ...},
	bool:InBZone[MAXPLAYERS + 1] = {false, ...};
public Plugin:myinfo =
{
	name        = "SM Custom Zones",
	author      = "Root",
	description = NULL_STRING,
	version     = "1.0",
	url         = "http://www.dodsplugins.com/"
}
public OnClientDisconnect(client) InAZone[client] = InBZone[client] = false;
public Action:OnEnteredProtectedZone(zone, client, const String:prefix[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		decl String:m_iName[MAX_NAME_LENGTH*2];
		GetEntPropString(zone, Prop_Data, "m_iName", m_iName, sizeof(m_iName));

		if (StrEqual(m_iName[8], "ZoneA", false))
		{
			InAZone[client] = true;
			SDKHook(client, SDKHook_TraceAttack,  TraceAttack);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		else if (StrEqual(m_iName[8], "ZoneB", false))
		{
			InBZone[client] = true;
			SDKHook(client, SDKHook_TraceAttack,  TraceAttack);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}

		if (GetConVarBool(ShowZones))
		{
			PrintToChat(client, "%sYou have entered %s!", prefix, m_iName[8]);
		}
	}
}
public Action:OnLeftProtectedZone(zone, client, const String:prefix[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		decl String:m_iName[MAX_NAME_LENGTH*2];
		GetEntPropString(zone, Prop_Data, "m_iName", m_iName, sizeof(m_iName));

		if (StrEqual(m_iName[8], "ZoneA", false))
		{
			InAZone[client] = false;
			SDKUnhook(client, SDKHook_TraceAttack,  TraceAttack);
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		else if (StrEqual(m_iName[8], "ZoneB", false))
		{
			InBZone[client] = false;
			SDKUnhook(client, SDKHook_TraceAttack,  TraceAttack);
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}

		if (GetConVarBool(ShowZones) && IsPlayerAlive(client))
		{
			PrintToChat(client, "%sYou have left %s!", prefix, m_iName[8]);
		}
	}
}
public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	return (InAZone[attacker] && InBZone[victim]) ? Plugin_Handled : Plugin_Continue;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	return (InAZone[attacker] && InBZone[victim]) ? Plugin_Handled : Plugin_Continue;
}