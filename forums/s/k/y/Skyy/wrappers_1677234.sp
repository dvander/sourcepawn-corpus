clearUserData(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientIndexOutOfRange(i) || !IsClientInGame(i) || IsFakeClient(i)) continue;
		damageReport[i][client] = 0;
	}
	if (GetConVarInt(Logging) == 1) LogToFile("tdr_log", "[TDR] Cleared All User Data for %N", client);
}

stock bool:IsClientIndexOutOfRange(client)
{
	if (client <= 0 || client > MaxClients) return true;
	else return false;
}

stock bool:IsTankIncapacitated(client)
{
	if (IsIncapacitated(client) || GetClientHealth(client) < 1) return true;
	return false;
}

stock bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

DisplayTankInformation(victim)
{
	if (GetConVarInt(Logging) == 1) LogToFile("tdr_log", "[TDR] Displaying Damage Report for Dead Tank: %N", victim);
	new String:pct[16];
	Format(pct, sizeof(pct), "%");

	if (GetConVarInt(displayType) == 1)
	{
		// Public Display
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 2) continue;
			PrintToChat(i, "\x05[\x04TDR\x05] \x01Tank player: \x04%N \x01has been killed.", victim);
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 2) continue;
			if (damageReport[i][victim] < 1) continue;
			new Float:damage = (damageReport[i][victim] * 1.0) / (startHealth[victim] * 1.0) * 100.0;
			for (new ii = 1; ii <= MaxClients; ii++)
			{
				if (!IsClientInGame(ii) || IsFakeClient(ii) || GetClientTeam(ii) != 2) continue;
				PrintToChat(ii, "\x03%N \x05(\x04%d - %3.2f%s\x05)", i, damageReport[i][victim], damage, pct);
			}
		}
	}
	else
	{
		// Display privately
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 2) continue;
			if (damageReport[i][victim] < 1) continue;
			new Float:damage = (damageReport[i][victim] * 1.0) / (startHealth[victim] * 1.0) * 100.0;
			PrintToChat(i, "\x05[\x04TDR\x05] \x01Tank player: \x04%N \x01has been killed.", victim);
			PrintToChat(i, "\x01Damage Done: \x04%d - %3.2f%s", damageReport[i][victim], damage, pct);
		}
	}
}