/* This is my first script so dont hate! */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>


public Plugin:myinfo = 
{
	name = "sm_rsptc",
	author = "gameguysz",
	description = "Respawns The Player or Changes the players team",
	version = "0.3",
	url = "http://www.michaelcamesao.site40.net/"
}

public OnPluginStart()
{
	RegAdminCmd("respawn", Spawn, ADMFLAG_ROOT, "Usage: respawn [target]");
	RegAdminCmd("move", CT, ADMFLAG_ROOT, "Usage: move [target] <team> (1 = Spec / 2 = Red / 3 = Blue)");
}

public Action:Spawn(client, args)
{
	if (args == 1)
	{
		new String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		new target = FindTarget(client, arg);
		if (IsClientConnected(target))
		{
			TF2_RespawnPlayer(target);
			ReplyToCommand(client,"\x03[SM]\x01%N , has been respawned", target);
		}
		else
		{
			ReplyToCommand(client,"\x03[SM]\x01No player by that name is connected");
		}
	}
	return Plugin_Handled;
}


public Action:CT(client, args)
{
	if (args != 1)
	{
		new String:arg[MAX_NAME_LENGTH], String:arg2[32]
		GetCmdArg(1, arg, sizeof(arg));
		new target2 = FindTarget(client, arg);
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
			else
			{
				PrintToChat(client, "\x03[SM]\x01Please choose a team");
			}
			ChangeClientTeam(target2, Team);
			PrintToChatAll("\x03[SM]\x06%N \x01Has moved \x06%N \x01To a new team ", client, target2);
		}
	}
	else
	{
		PrintToChat(client, "\x03[SM]\x01Usage: move [name] <team#1/2/3>");
	}
	return Plugin_Handled;
}