#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required 1

#define PREFIX "Team Limits"
#define SPECTATOR_TEAM 1

Handle g_h_max_players = INVALID_HANDLE;
int max_players;

public Plugin myinfo = {
	name = "Team Limit",
	author = "Vertigo & Kushal",
	description = "Restrict Team Join By Number of Players",
	version = "1.0",
	url = "Thanks Vertigo & SM9()"
};

public void OnPluginStart()
{	
	g_h_max_players = CreateConVar("wm_max_players", "0", "Sets the maximum players allowed on both teams combined, others will be forced to spectator (0 = unlimited)", FCVAR_NOTIFY, true, 0.0);

	HookConVarChange(g_h_max_players, OnMaxPlayersChange);
	
	RegConsoleCmd("jointeam", ChooseTeam);
	RegConsoleCmd("spectate", ChooseTeam);
	RegAdminCmd("sm_wl", Command_LimitTeam, ADMFLAG_GENERIC, "Limit players.");
}

public void OnMaxPlayersChange(Handle cvar, const char[] oldVal, const char[] newVal)
{
	max_players = StringToInt(newVal);
}

public Action ChooseTeam(int client, int args)
{
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	max_players = GetConVarInt(g_h_max_players);
	
	if ((g_h_max_players) && max_players != 0 && GetClientTeam(client) <= 1 && CS_GetPlayingCount() >= max_players)
	{
		PrintToChat(client, "\x03[%s]\x02 Maximum Players Reached. Team is now Full.",PREFIX);
		ChangeClientTeam(client, SPECTATOR_TEAM);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Command_LimitTeam(int client, int args)
{
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	char maxValue[10];
	GetCmdArg(1, maxValue, sizeof(maxValue));
	max_players = StringToInt(maxValue);
	
	return Plugin_Continue;
}

stock int CS_GetPlayingCount() {
	int count;
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1) {
			count++;
		}
	}
	
	return count;
}