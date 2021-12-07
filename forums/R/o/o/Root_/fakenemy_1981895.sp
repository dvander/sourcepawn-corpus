#include <sendproxy>

enum
{
	Team_Unassigned,
	Team_Spectator,
	Team_2,
	Team_3,
	Team_Custom
};

new bool:g_bLateLoad;

public OnPluginStart()
{
	if (g_bLateLoad)
	{
		// Apply the hooks on all players
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SendProxy_Hook(i, "m_iTeamNum", Prop_Int, Hook_TeamNum);
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	SendProxy_Hook(client, "m_iTeamNum", Prop_Int, Hook_TeamNum);
}

public Action:Hook_TeamNum(client, const String:propName[], &value, element)
{
	value = Team_Custom;

	return Plugin_Changed;
}