#include <sourcemod>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#pragma newdecls required

int g_iClientCount;
ConVar g_cDifficulty;

public Plugin myinfo =
{
    name = "[L4D2] Difficulty Adjuster",
    author = "Tak (Chaosxk)",
    description = "Adjusts difficulty based on number of clients in server.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=297009"
}

public void OnPluginStart()
{
	if ((g_cDifficulty = FindConVar("z_difficulty")) == null)
	{
		LogError("[SM] Can not find convar z_difficulty");
		SetFailState("Can not find convar z_difficulty");
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		UpdateClientCount(++g_iClientCount);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;
		
	UpdateClientCount(++g_iClientCount);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
		return;
		
	UpdateClientCount(--g_iClientCount);
}

public void UpdateClientCount(int count)
{
	switch (count)
	{
		case 4:
			g_cDifficulty.SetString("easy");
		case 8:
			g_cDifficulty.SetString("normal");
		case 12:
			g_cDifficulty.SetString("hard");
		case 16:
			g_cDifficulty.SetString("impossible");
	}
}