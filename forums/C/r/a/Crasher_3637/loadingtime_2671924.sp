#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

float g_flTimeConnected[MAXPLAYERS + 1];

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!IsFakeClient(client))
	{
		g_flTimeConnected[client] = GetEngineTime();
	}

	return true;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		float flFinalTime = GetEngineTime() - g_flTimeConnected[client];
		PrintToChatAll("[SM] It took %N around %.2f seconds to connect.", client, flFinalTime);
	}
}

public void OnClientDisconnect(int client)
{
	g_flTimeConnected[client] = 0.0;
}