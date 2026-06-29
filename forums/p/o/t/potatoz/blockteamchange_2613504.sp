#include <sourcemod>
#pragma semicolon 1

#define VERSION "1.0"

public Plugin:myinfo =
{
    name = "block team change",
    author = "potatoz",
    description = "blocks team changes whilst client is alive",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
	AddCommandListener(Command_JoinTeam, "jointeam");	
}

public Action Command_JoinTeam(int client, char[] command, int args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
		
	if(IsPlayerAlive(client))
	{
		ReplyToCommand(client, " \x07You may not switch team whilst alive");
		return Plugin_Handled;  
	}
	
	return Plugin_Continue;
}