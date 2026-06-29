#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Block Auto Assign",
	author = "Shad0w93",
	description = "Blocks users attempted to auto assign",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=190586"
}

public OnPluginStart()
{
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action:Command_JoinTeam(client, const String:command[], argc)
{
	decl String:sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	if (sArg[0] == '0')
	{
		if (IsClientInGame(client))
			ShowVGUIPanel(client, "team");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}