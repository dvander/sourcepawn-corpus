#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Block team changes",
	author = "ecca",
	description = "",
	version = "1.0"
};

public OnPluginStart()
{
	AddCommandListener(Command_CheckJoin, "jointeam");
}

public Action:Command_CheckJoin(client, const String:command[], args)
{
	new String:teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new Target_Team = StringToInt(teamString);
	new Current_Team = GetClientTeam(client);
		
	if (Current_Team == 2 && Target_Team == 3)
	{
		PrintToChat(client, "\x03[SM] \x01Team changes to Counter-Terrorists is not allowed!");
		return Plugin_Handled;		
	}
	return Plugin_Continue;
}	