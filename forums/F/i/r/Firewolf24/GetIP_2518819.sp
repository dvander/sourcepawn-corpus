#include <sourcemod>

public Plugin myinfo = 
{
	name = "Get IP",
	author = "Firewolf",
	description = "Simple Plugin for viewing IP's of players",
	version = "0.1",
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_getip", Command_GetIp, ADMFLAG_GENERIC, "sm_getip <#userid|name> (Gets the IP of the selected target)");
}

public Action:Command_GetIp(client, args)
{
	if(args < 1)
	{
	ReplyToCommand(client, "[SM] Missing Parameters. Usage: sm_getip <target>");
	}

	char arg1[32];	 
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);
	new String:ClientIP[32];
	new String:TargetName[32];
	
	GetClientName(target, TargetName, sizeof(TargetName));
	GetClientIP(target, ClientIP, sizeof(ClientIP));
	
	PrintToChat(client, "[SM] IP of client %s: %s", TargetName, ClientIP);
	return Plugin_Handled;
}