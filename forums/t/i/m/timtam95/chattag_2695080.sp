#pragma newdecls required
#pragma semicolon 1

char chattags[256][32];

stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	return IsClientInGame(client);
}

stock void SayText2(int client, int author, char[] message)
{
	Handle hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, message);
	EndMessage();
}

public void OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	RegConsoleCmd("sm_tag", Command_Tag);
	RegConsoleCmd("sm_deltag", Command_DelTag);
}

public Action Command_Say(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Continue;

	if (chattags[client][0] != '\0')
	{
		char msg[256], nick[256], buffer[256];
		GetCmdArgString(msg, sizeof(msg));
		ReplaceString(msg, sizeof(msg), "\"", "");
		GetClientName(client, nick, sizeof(nick));

		int ClientTeam = GetClientTeam(client);
		if (ClientTeam == 1) 
		{
			Format(buffer, sizeof(buffer), "\x01*SPEC* \x03%s", chattags[client]);
		}
		else
		{
			if (!IsPlayerAlive(client))
			{
				Format(buffer, sizeof(buffer), "\x01*DEAD* \x03%s", chattags[client]);
			}
			else
			{
				Format(buffer, sizeof(buffer), "\x03%s", chattags[client]);
			}
		}

		Format(msg, sizeof(msg), "%s%s\x01 : %s", buffer, nick, msg);

		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				SayText2(i, client, msg);
			}
		}

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}


public Action Command_SayTeam(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Continue;

	if (chattags[client][0] != '\0')
	{
		char msg[256], nick[256], buffer[256];
		GetCmdArgString(msg, sizeof(msg));
		ReplaceString(msg, sizeof(msg), "\"", "");
		GetClientName(client, nick, sizeof(nick));

		int ClientTeam = GetClientTeam(client);
		if (ClientTeam == 1) 
		{
			Format(buffer, sizeof(buffer), "\x01(Spectator) \x03%s", chattags[client]);
		}
		else
		{
			if (!IsPlayerAlive(client))
			{
				Format(buffer, sizeof(buffer), "\x01*DEAD*(TEAM) \x03%s", chattags[client]);
			}
			else
			{
				Format(buffer, sizeof(buffer), "\x01(TEAM) \x03%s", chattags[client]);
			}
			
		}

		Format(msg, sizeof(msg), "%s%s\x01 : %s", buffer, nick, msg);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				if (GetClientTeam(client) == ClientTeam)
				{
					SayText2(i, client, msg);
				}
			}
		}

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Command_Tag(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Continue;

	GetCmdArgString(chattags[client], 32);
	ReplyToCommand(client, "Chat tag set to: %s", chattags[client]);

	return Plugin_Continue;
}

public Action Command_DelTag(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Continue;

	chattags[client][0] = '\0';
	ReplyToCommand(client, "Chat tag removed");

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	chattags[client][0] = '\0';
}