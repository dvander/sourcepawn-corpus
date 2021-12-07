#pragma semicolon 1

new m_iAccount;
new Handle:extra_cash_amount;
new Handle:extra_cash_amount_admins;

public OnPluginStart()
{
	m_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

	extra_cash_amount = CreateConVar("extra_cash_amount", "500", "For player");
	extra_cash_amount_admins = CreateConVar("extra_cash_amount_admins", "1000", "For admins");

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && !IsFakeClient(client))
	{
		SetEntData(client, m_iAccount, GetConVarInt(CheckCommandAccess(client, "", ADMFLAG_GENERIC, true) ? extra_cash_amount_admins : extra_cash_amount));
	}
}
