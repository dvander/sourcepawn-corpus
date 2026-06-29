//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>

public Plugin myinfo = 
{
	name = "Chosen Player", 
	author = "Keith Warren (Sky Guardian)", 
	description = "Retrieves a random chosen player.", 
	version = "1.0.0", 
	url = "https://github.com/SkyGuardian"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_getplayer", Command_GetPlayer, ADMFLAG_SLAY, "Random gets a chosen player and announces them.");
}

public Action Command_GetPlayer(int client, int args)
{
	int chosen = GetRandomClient();
	
	if (chosen == 0)
	{
		ReplyToCommand(client, "Error finding player.");
		return Plugin_Handled;
	}
	
	PrintCenterTextAll("%N is the chosen player", chosen);
	PrintToChatAll("%N is the chosen player", chosen);
	
	return Plugin_Handled;
}

stock int GetRandomClient(bool ingame = true, bool alive = false, bool nofake = false, int team = 0)
{
	int[] clients = new int[MaxClients];
	int amount;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (ingame && !IsClientInGame(i) || alive && !IsPlayerAlive(i) || nofake && IsFakeClient(i) || team > 0 && team != GetClientTeam(i))
		{
			continue;
		}

		clients[amount++] = i;
	}

	return clients[GetRandomInt(0, amount)];
}