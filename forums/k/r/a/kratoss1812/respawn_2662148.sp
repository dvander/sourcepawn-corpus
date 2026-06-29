#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma newdecls required

int iUseTime[MAXPLAYERS + 1] = 0;

public void OnPluginStart()
{
	RegConsoleCmd("sm_respawn", Respawn);
}

public Action Respawn(int Client, int Args)
{
	if ((GetTime() - iUseTime[Client]) < 30.0)
		return;
	
	iUseTime[Client] = GetTime();
	CS_RespawnPlayer(Client)
}

public void OnClientPostAdminCheck(int Client)
{
	iUseTime[Client] = GetTime();
}