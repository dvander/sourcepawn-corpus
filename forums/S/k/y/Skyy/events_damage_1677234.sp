public Action:Event_TankKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientIndexOutOfRange(victim)) return;
	if (!IsFakeClient(victim)) return;
	if (GetClientTeam(victim) != 3)
	{
		class[victim] = 0;
		return;
	}
	DisplayTankInformation(victim);
}

public Action:Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != 3)
	{
		class[client] = 0;
		return;
	}

	class[client] = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (class[client] == ZOMBIECLASS_TANK)
	{
		clearUserData(client);
		startHealth[client] = GetClientHealth(client);
	}
}

public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim	 = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage	 = GetEventInt(event, "dmg_health");

	if (IsClientIndexOutOfRange(victim)) return;
	if (IsClientIndexOutOfRange(attacker) || !IsClientInGame(attacker) || IsFakeClient(attacker) || GetClientTeam(attacker) != 2) return;
	if (!IsClientInGame(victim) || GetClientTeam(victim) != 3) return;

	class[victim] = GetEntProp(victim, Prop_Send, "m_zombieClass");
	if (class[victim] != ZOMBIECLASS_TANK) return;

	if (!IsTankIncapacitated(victim)) damageReport[attacker][victim] += damage;
	if (damageReport[attacker][victim] > startHealth[victim]) damageReport[attacker][victim] = startHealth[victim];
}

public Action:Event_PlayerIncapacitated(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim					= GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientIndexOutOfRange(victim)) return;
	if (IsFakeClient(victim)) return;
	if (GetClientTeam(victim) != 3)
	{
		class[victim] = 0;
		return;
	}
	DisplayTankInformation(victim);
}