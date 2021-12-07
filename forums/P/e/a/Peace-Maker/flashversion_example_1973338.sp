#pragma semicolon 1
#include <sourcemod>
#include <flashversion>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Flashversion Example",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Provides a command to display a client's flash player version",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_flashversion", Cmd_FlashVersion, "Shows a player's flash player version. Usage: sm_flashversion [name|steamid|#userid]");
}

public Action:Cmd_FlashVersion(client, args)
{
	if(!client && args == 0)
	{
		ReplyToCommand(client, "Usage: sm_flashversion <name|steamid|#userid>");
		return Plugin_Handled;
	}
	
	new iTarget = client;
	
	if(args > 0)
	{
		decl String:sBuffer[32];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		iTarget = FindTarget(client, sBuffer, true, false);
		if(iTarget == -1)
			return Plugin_Handled;
	}
	
	Flash_GetClientVersion(iTarget, false, Flash_OnGetClientVersion, GetClientUserId(client));
	
	return Plugin_Handled;
}

public Flash_OnGetClientVersion(client, flashversion[4], bool:bError, any:userid)
{
	new caller = GetClientOfUserId(userid);
	if(!caller)
	{
		PrintToServer("%s%N's flash player version: %d.%d.%d.%d", (bError?"Failed to get ":""), client, flashversion[0], flashversion[1], flashversion[2], flashversion[3]);
	}
	else if(IsClientInGame(caller))
	{
		PrintToChat(caller, "%s%N's flash player version: %d.%d.%d.%d", (bError?"Failed to get ":""), client, flashversion[0], flashversion[1], flashversion[2], flashversion[3]);
		PrintToConsole(caller, "%s%N's flash player version: %d.%d.%d.%d", (bError?"Failed to get ":""), client, flashversion[0], flashversion[1], flashversion[2], flashversion[3]);
	}
}