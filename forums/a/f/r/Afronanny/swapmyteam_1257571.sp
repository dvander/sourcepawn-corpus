#include <sourcemod>

public Plugin:myinfo = 
{
	name = "TeamSwap",
	author = "Afronanny",
	description = "Allow donors to swap teams immediately",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_swapmyteam", Command_SwapMyTeam, ADMFLAG_CUSTOM5);
}

public Action:Command_SwapMyTeam(client, args)
{
	new team = GetClientTeam(client);
	switch (team)
	{
		case 2: ChangeClientTeam(client, 3);
		case 3: ChangeClientTeam(client, 2);
		default: ReplyToCommand(client, "\x01\x04[SM]\x01 Join a team first");
	}
	return Plugin_Handled;
}