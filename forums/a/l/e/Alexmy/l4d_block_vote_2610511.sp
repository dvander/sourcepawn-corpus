#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

public Plugin MyInfo = 
{
	name = "[L4D] Block Vote", 
	author = "AlexMy", 
	description = "", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	AddCommandListener(LockCommand, "callvote"); 
}
public Action LockCommand(int client, char [] command, int args) 
{
	char name[32];
	GetClientName(client, name, sizeof(name));
	if(client && IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	else if (client && !IsPlayerAlive(client))
	{
		if(GetUserFlagBits(client) > 0)  //
		{                                //
			return Plugin_Continue;      ///Мертвый Админ может запускать голосование!!!
		}                                //                           
		PrintToChatAll("\x03Мертвый \x04%s \x03пытался запустить голосование\x01!!!", name);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}