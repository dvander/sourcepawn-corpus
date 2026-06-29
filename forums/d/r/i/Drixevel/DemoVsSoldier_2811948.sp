#include <sourcemod>

public Plugin myinfo =
{
	name = "TF2 Class Restriction",
	author = "Rogue Spy",
	description = "Forces Blue Team to be Soldiers and Red Team to be Demomen.",
	version = "1.0",
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_forceteam", ForceTeamCmd, "Force teams to specific classes");
}

public Action ForceTeamCmd(int client, int args)
{
	if (args < 3)
	{
		PrintToChat(client, "Usage: sm_forceteam <team> <class>");
		PrintToChat(client, "Available teams: 2 (Blue), 3 (Red)");
		PrintToChat(client, "Available classes: 3 (Soldier), 4 (Demoman)");
		return Plugin_Handled;
	}

	int team = GetClientTeam2(client);
	int class = GetCmdArgInt(2);

	if ((team == 2 && class == 3) || (team == 3 && class == 4))
	{
		PrintToChat(client, "Forcing your team to the desired class...");
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
	}
	else
	{
		PrintToChat(client, "Invalid team or class specified.");
	}

	return Plugin_Handled;
}

public int GetClientTeam2(int client)
{
	int team = GetClientTeam(client);
	return team;
}
