#include <sourcemod>


#pragma newdecls required
#pragma semicolon 1

int iRoundCount;
int iOldClient;
bool bGiveFlag[MAXPLAYERS + 1];


public Plugin myinfo = 
{
	name = "RandomVIP", 
	author = "Hexer10", 
	description = "Gives a & o flags randomly every 5 rounds", 
	version = "1.0", 
	url = "https://forums.alliedmods.net/showthread.php?t=298530"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
}

public void OnRoundStart(Event event, const char[] name, bool dontbrocast)
{
	if (iRoundCount == 5) //If 5 rounds are gone reset the flags
	{
		RemoveUserFlags(iOldClient, Admin_Reservation);
		RemoveUserFlags(iOldClient, Admin_Custom1);
		iRoundCount = 0;
		bGiveFlag[iOldClient] = false;
	}
	
	if (iRoundCount == 0)
	{
		int client = GetRandomPlayer();
		while (client == iOldClient)
		{
			client = GetRandomPlayer();
		}
		iOldClient = client;
		bGiveFlag[iOldClient] = true;
		AddUserFlags(client, Admin_Reservation);
		AddUserFlags(client, Admin_Custom1);
	}
	
	iRoundCount++;
	
}

public void OnRebuildAdminCache(AdminCachePart part) //Prevent disabling after VIP after permissions reloads
{
	if (bGiveFlag[iOldClient]) 
	{
		AdminId admin = GetUserAdmin(iOldClient);
		if (!GetAdminFlag(admin, Admin_Reservation))
			AddUserFlags(iOldClient, Admin_Reservation);
		if (!GetAdminFlag(admin, Admin_Custom1))
			AddUserFlags(iOldClient, Admin_Custom1);
	}
}


//Get a random client
stock int GetRandomPlayer()
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, false, true))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
	
}

//Check for a valid client
stock bool IsValidClient(int client, bool AllowBots = false, bool AllowDead = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
} 