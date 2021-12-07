#include <sourcemod>

public Plugin:myinfo = 
{
	name = "!Kill Command",
	author = "",
	description = "Provides a command for players to kill themselves with",
	version = "1.0",
	url = "http://alliedmods.net/"
}

public OnPluginStart()
{
  //Register the commands you want players to kill themselves with
  RegConsoleCmd("sm_kill", Command_Kill);
}

public Action:Command_Kill(client, args)
{
  //Check to see if the player is in-game. If so, let them suicide.
  if (IsClientInGame(client))
		ClientCommand(client, "kill");
  
  //Return that the command has finished.
  return Plugin_Handled;
}