//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines

//Sourcemod Includes
#include <sourcemod>

//Globals

public Plugin myinfo =
{
	name = "Random Client",
	author = "Keith Warren (Shaders Allen)",
	description = "Picks a random client and places their name in chat.",
	version = "1.0.0",
	url = "https://github.com/ShadersAllen"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_randomplayer", Command_RandomPlayer, ADMFLAG_SLAY, "Picks a random player and places their name in chat.");
}

public Action Command_RandomPlayer(int client, int args)
{
	int random = GetRandomClient(true, true, true, 0);
	
	if (random == 0)
	{
		PrintToChat(client, "No valid clients found.");
		return Plugin_Handled;
	}
	
	RequestFrame(Frame_PrintName, GetClientUserId(random));
	
	return Plugin_Handled;
}

public void Frame_PrintName(any userid)
{
	int random;
	if ((random = GetClientOfUserId(userid)) > 0)
		PrintToChatAll("Chosen player: %N", random);
}

int GetRandomClient(bool ingame = true, bool alive = false, bool fake = false, int team = 0)
{
	int[] clients = new int[MaxClients];
	int amount;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (ingame && !IsClientInGame(i) || alive && !IsPlayerAlive(i) || !fake && IsFakeClient(i) || team > 0 && team != GetClientTeam(i))
			continue;

		clients[amount++] = i;
	}

	return clients[GetRandomInt(0, amount)];
}