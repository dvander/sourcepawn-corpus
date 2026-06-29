#include <sourcemod>
#include <sdktools>

#include <tf2_stocks>
#include <tf2>


public Plugin:myinfo = 
{
	name = "MovePlayer",
	author = "piggiz",
	description = "Changes the players team.",
	version = "0.4",
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	RegAdminCmd("move", CT, ADMFLAG_CUSTOM6, "Usage: sm_move <team> (1 = Spec / 2 = Red / 3 = Blue)");
}

public Action:CT(client, args)
{
	if (args != 1)
	{
		new String:arg[MAX_NAME_LENGTH], String:arg2[32]
		GetCmdArg(1, arg, sizeof(arg));
		new target2 = client;
		new Team;
		if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)) && !IsClientReplay(target2))
		{
			if (StringToInt(arg2) == 1)
			{
				Team = 1;
			} 
			else if (StringToInt(arg2) == 2)
			{
				Team = 2;
			}
			else if (StringToInt(arg2) == 3)
			{
				Team = 3;
			}
			ChangeClientTeam(target2, Team);
		}
	}
	return Plugin_Handled;
}