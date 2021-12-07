stock Action:ProcessMessage(client, bool:teamchat, String:message[], maxlength)
{
	decl String:sChatMsg[1280];
	StripQuotes(message);
	TrimString(message);

	ReplaceString(message, maxlength, CHAR_PERCENT, CHAR_NULL);

	if (IsStringBlank(message))
	{
		return Plugin_Stop;
	}
	
	if (message[0] == CHAT_SYMBOL)
	{
		return Plugin_Continue;
	}
	
	if ((message[0] == TRIGGER_SYMBOL2 || message[0] == '.') && IsStringAlpha(message[1]))
	{
		return Plugin_Continue;
	}

	FormatMessage(client, GetClientTeam(client), IsPlayerAlive(client), teamchat, message, sChatMsg, sizeof(sChatMsg));
	
	new bool:bTeamColorUsed = StrContains(sChatMsg, "{teamcolor}") != -1 ? true : false;
	new iCurrentTeam = GetClientTeam(client);
	if (teamchat)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == iCurrentTeam)
			{
				if (bTeamColorUsed)
				{
					CPrintToChatEx(i, client, "%s", sChatMsg);
				}
				else
				{
					CPrintToChat(i, "%s", sChatMsg);
				}
			}
		}
	}
	else
	{
		if (bTeamColorUsed)
		{
			CPrintToChatAllEx(client, "%s", sChatMsg);
		}
		else
		{
			CPrintToChatAll("%s", sChatMsg);
		}
	}
	return Plugin_Stop;
}