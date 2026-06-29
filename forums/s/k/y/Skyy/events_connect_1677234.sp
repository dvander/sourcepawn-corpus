EC_OnClientPostAdminCheck(client)
{
	// Make sure this client id damage variable is cleared
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		damageReport[client][i] = 0;
		damageReport[i][client] = 0;
	}
	if (GetConVarInt(Logging) == 1) LogToFile("tdr_log", "[TDR] Cleared Data for user %N", client);
}