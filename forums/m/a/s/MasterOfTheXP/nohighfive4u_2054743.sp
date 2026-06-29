public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		SetEntProp(i, Prop_Send, "m_bIsReadyToHighFive", 0);
	}
}