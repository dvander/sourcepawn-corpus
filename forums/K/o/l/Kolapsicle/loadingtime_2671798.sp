#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

ArrayList g_clients;

public void OnMapStart()
{
	g_clients = new ArrayList(2);
}

public void OnMapEnd()
{
	delete g_clients;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (IsFakeClient(client))
	{
		return true;
	}
	
	if (g_clients == null)
	{
		return true;
	}
	
	any buffer[2];
	buffer[0] = GetClientUserId(client);
	buffer[1] = GetEngineTime();
	g_clients.PushArray(buffer);
	return true;
}

public void OnClientPutInServer(int client)
{
	if (g_clients == null)
	{
		return;
	}
	
	int userid = GetClientUserId(client);
	any buffer[2];
	
	for (int i = g_clients.Length - 1; i >= 0; i--)
	{
		g_clients.GetArray(i, buffer);
		
		if (userid == buffer[0])
		{
			PrintToChatAll("[SM] %N connected in %.2f seconds.", client, GetEngineTime() - view_as<float>(buffer[1]));
			delete g_clients;
			return;
		}
	}
} 