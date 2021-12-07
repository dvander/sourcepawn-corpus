#pragma semicolon 1
#include <sdkhooks>

bool bInSpawn[MAXPLAYERS+1] = {false, ...};

public Plugin myinfo =
{
    name        = "NoSpawnChange",
    author      = "Noodl",
    description = "Disables changing class in the spawn room",
    version     = "1.0",
    url         = "http://flux.tf"
}

public void OnPluginStart()
{
	AddCommandListener(BlockSwap, "joinclass");
}

public Action BlockSwap(int iClient, const char[] sCommand, int iArgc)
{
	if (bInSpawn[iClient])
	{
		return Plugin_Handled;
	}
	else return Plugin_Continue;
}

public OnEntityCreated(iEntity, const char[] sClassname)
{
	if (StrEqual(sClassname, "func_respawnroom", false))	// This is the earliest we can catch this
	{
		SDKHook(iEntity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(iEntity, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public SpawnStartTouch(iSpawn, iClient)
{
	// Make sure it is a iClient and not something random
	if (!(0 < iClient < MaxClients))
		return;	// Not a client

	if (IsValidClient(iClient))
		bInSpawn[iClient] = true;
}

public SpawnEndTouch(iSpawn, iClient)
{
	if (!(0 < iClient < MaxClients))
		return;

	if (IsValidClient(iClient))
		bInSpawn[iClient] = false;
}

stock bool IsValidClient(int iClient, bool bNoBots = true)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || (bNoBots && IsFakeClient(iClient)))
	{
		return false;
	}
	return IsClientInGame(iClient);
}