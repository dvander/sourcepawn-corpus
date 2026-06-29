/* Includes */
#include <sourcemod>
 
/* Defines */
#define PLUGIN_VERSION "1.0.0.1"

new Handle:g_hEnabled;
new Handle:g_hAllowVotes;
 
public Plugin:myinfo =
{
	name = "Limited Voting",
	author = "Farzad",
	description = "Disables in-game voting when admins are present",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/plugins.php?author=Farzad&search=1"
}

public OnPluginStart()
{
	CreateConVar("limitedvoting_version", PLUGIN_VERSION, "Disables in-game voting when admins are present", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_limitedvoting", "1", "Sets whether limited voting is enabled");

	g_hAllowVotes = FindConVar("sv_allow_votes");
}

public OnMapStart()
{
	if (GetConVarBool(g_hEnabled))
	{
		SetConVarBool(g_hAllowVotes, true);
	}
}
 
public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(g_hEnabled) && GetConVarBool(g_hAllowVotes))
	{
		if (IsFakeClient(client))
		{
			return;
		}

		if (GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			/* Admin has joined, disable voting */
			PrintToChatAll("[Limited Voting]: Voting disabled!");
			SetConVarBool(g_hAllowVotes, false);
		}
	}
}
 
public OnClientDisconnect(client)
{
	if (GetConVarBool(g_hEnabled) && !GetConVarBool(g_hAllowVotes))
	{
		if (IsFakeClient(client)) return;

		if (GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			/* Check for other admins */
			for (new i = 1; i <= MaxClients; i ++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (GetUserAdmin(i) != INVALID_ADMIN_ID)
					{
						/* Admin found, return */
						return;
					}
				}
			}

			/* No admins on the server, re-enable voting */
			PrintToChatAll("[Limited Voting]: Voting has been enabled!");
			SetConVarBool(g_hAllowVotes, true);
		}
	}
} 