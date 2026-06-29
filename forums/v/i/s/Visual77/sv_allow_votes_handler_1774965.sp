#include <sourcemod>

new Handle:g_hVotesCvar = INVALID_HANDLE;

public OnPluginStart()
{
	g_hVotesCvar = FindConVar("sv_allow_votes");
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client)) return;

	if (isAdminsInGame())
	{
		if (GetConVarInt(g_hVotesCvar) != 0) SetConVarInt(g_hVotesCvar, 0);
	}
	else
	{
		if (GetConVarInt(g_hVotesCvar) != 1) SetConVarInt(g_hVotesCvar, 1);
	} 
}

public OnClientDisconnected(client)
{
	if (IsFakeClient(client)) return; 

	if (!isAdminsInGame())
	{
		if (GetConVarInt(g_hVotesCvar) != 1) SetConVarInt(g_hVotesCvar, 1);
	}
}

bool:isAdminsInGame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
		{                  
			return true;
		}
	}
	return false;
}