#pragma semicolon 1
#include <sourcemod>

public Plugin myinfo = {
	name        = "[ANY] Give Admin Flag",
	author      = "Sgt. Gremulock",
	description = "Gives players that join an admin flag.",
	version     = "1.0",
	url         = "sourcemod.net"
};

public void OnPluginStart()
{
	CreateConVar("sm_giveadminflag_version", "1.0", "Plugin's version.", FCVAR_NOTIFY);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!CheckCommandAccess(client, "sm_admin", ADMFLAG_CUSTOM5, false))
	{
		AdminId Client_Admin = GetUserAdmin(client);
		Client_Admin.SetFlag(Admin_Custom5, true);
	}
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	
	return IsClientInGame(client);
}