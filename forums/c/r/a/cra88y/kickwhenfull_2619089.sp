#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
public Plugin myinfo = 
{
	name = "FullServerKick",
	author = "cra88y",
	version = "1.0"
};
public void OnClientPostAdminCheck(int client)
{
	if(GetClientCount(true) > GetMaxHumanPlayers()) //You might be able to use MaxClients here to be dynamic but idk tbh
	{
		if (!IsPlayerAdmin(client))
		{
			KickClient(client, "Server is full! Please try again later.");
		}
	}
}
stock bool IsPlayerAdmin(int client)
{
	if (IsClientInGame(client) && CheckCommandAccess(client, "", ADMFLAG_KICK))
		return true;
	
	return false;
}