#define PLUGIN_VERSION 		"1.1"

/**************************************************

Command Block (l4d_command_block) by Mystik Spiral

Left4Dead2 SourceMod plugin blocks client commands.
Blocks commands as specified in the ConVar "cb_list".

By default, the blocked commands are:

    pause/setpause/unpause: Could be spammed to crash connected clients.
    jointeam: Could be used to spawn additional bots and other exploits.
    go_away_from_keyboard: Blocks many different idle exploits, most notably redirecting witch on startle.
        It is suggested to lower the parameter "director_afk_timeout" since players can no longer manually go idle.
        In the server.cfg file, set "sm_cvar director_afk_timeout 20", the default is 45.

The list of commands to block must be comma separated with no spaces.

Want to contribute code enhancements?
Create a pull request using this GitHub repository: https://github.com/Mystik-Spiral/l4d_command_block

Plugin discussion: https://forums.alliedmods.net/showthread.php?t=332223

**************************************************/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar g_cList;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Command Block",
	author = "Mystik Spiral",
	description = "Blocks specified client commands.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332223"
}

public void OnConfigsExecuted()
{
	CreateConVar("cb_version", PLUGIN_VERSION, "Command Block version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cList = CreateConVar("cb_list", "pause,setpause,unpause,jointeam,go_away_from_keyboard", "Commands to block", FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d_command_block");
	
	char sCommand[16][64], sList[512];
				
	g_cList.GetString(sList, sizeof sList);
	ExplodeString(sList, ",", sCommand, sizeof sCommand, sizeof sCommand[]);
				
	for( int iCommand = 0; iCommand < sizeof sCommand; iCommand++ )
	{
		if ( sCommand[iCommand][0] != '\0' )
		{
			AddCommandListener(CommandBlock, sCommand[iCommand]);
			//PrintToServer("[CmdBlk] Blocking: %s", sCommand[iCommand]);
		}
	}
}

public Action CommandBlock(int client, const char[] command, int argc) 
{
	//PrintToServer("[CmdBlk] Blocked \"%s\" attempted by %N", command, client);
	return Plugin_Handled;
}