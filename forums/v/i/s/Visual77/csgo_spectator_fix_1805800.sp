#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "CSGO Spectator FIX",
	author = "V1sual",
	description = "Fix to allow more than two people on the spectator team.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_away", CmdSpectate);
	RegConsoleCmd("sm_afk", CmdSpectate);
	RegConsoleCmd("sm_spectate", CmdSpectate);

	AddCommandListener(SpecFromM_Fix, "jointeam");
	AddCommandListener(Spectate_Fix, "spectate");
}

public Action:CmdSpectate(client, args)
{
	if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;

	if (GetClientTeam(client) == 1)
	{
		PrintToChat(client, "[SM] You are already on the spectator team.");
		return Plugin_Handled;  
	}

	ClientCommand(client, "spectate");
	return Plugin_Handled;  
}

public Action:SpecFromM_Fix(client, const String:command[], argc)
{
	if (client > 0 && !IsFakeClient(client) && GetClientTeam(client) != 1)
	{
		decl String:team[12];
		GetCmdArgString(team, sizeof(team));

		new teamnumber = StringToInt(team);
		if (teamnumber == 1 || StrEqual(team, "spectate", false))
		{
			if (IsPlayerAlive(client)) ForcePlayerSuicide(client); // The game kills the player when going spec so we need to kill him here
			ChangeClientTeam(client, 1); 
			return Plugin_Handled;
		} 
	}  
	return Plugin_Continue;
}

public Action:Spectate_Fix(client, const String:command[], argc)
{
	if (client > 0 && !IsFakeClient(client) && GetClientTeam(client) != 1)
	{
		if (IsPlayerAlive(client)) ForcePlayerSuicide(client); // The game kills the player when going spec so we need to kill him here
		ChangeClientTeam(client, 1); 
		return Plugin_Handled;
	}  
	return Plugin_Continue;
}
