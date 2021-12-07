#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

ArrayList g_clients;

public void OnPluginStart()
{
	g_clients = new ArrayList(2);
}

public void OnPluginEnd()
{
	delete g_clients;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	any buffer[2];
	buffer[0] = GetClientUserId(client);
	buffer[1] = GetEngineTime();
	g_clients.PushArray(buffer);
	return true;
}

public void OnClientPutInServer(int client)
{
	int userid = GetClientUserId(client);
	any buffer[2];
	
	for (int i = 0; i < g_clients.Length; i++)
	{
		g_clients.GetArray(i, buffer);
		
		if (userid == buffer[0])
		{
			g_clients.Erase(i);
			PrintToChatAll("[SM] %N connected in %.2f seconds.", client, GetEngineTime() - view_as<float>(buffer[1]));
			return;
		}
	}
} 