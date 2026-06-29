#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Pause protect - testing",
	author = "Anhil",
	description = "Debugging",
	version = "1.0",
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_gametime", GameTime, ADMFLAG_GENERIC, "Returns GetGameTime()'s value");
}
public Action:GameTime(client,args)
{
	ReplyToCommand(client, "[SM] GetGameTime(): %d", GetGameTime());
	return Plugin_Handled;
}