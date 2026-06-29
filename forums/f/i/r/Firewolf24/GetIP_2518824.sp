#include <sourcemod>
#include <geoip>

#pragma semicolon 1
//#pragma newdcls required

#define TAG_MESSAGE "[\x04IP\x01]"

public Plugin myinfo = 
{
	name = "Get IP",
	author = "Firewolf",
	description = "Simple Plugin for viewing the IP and location of players",
	version = "0.4",
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_getip", Command_GetIp, ADMFLAG_CHEATS, "sm_getip <#userid|name> (Gets the IP and location of the selected target)");
}

public Action:Command_GetIp(client, args)
{
	if(args < 1)
	{
	ReplyToCommand(client, "%s Missing Parameters. Usage: sm_getip <target>", TAG_MESSAGE);
	return Plugin_Handled;
	}

	char arg1[32];	 
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);
	new String:ClientIP[32];
	new String:TargetName[32];
	new String:ClientLocation[32];
	
	GetClientName(target, TargetName, sizeof(TargetName));
	GetClientIP(target, ClientIP, sizeof(ClientIP));
	GeoipCountry(ClientIP, ClientLocation, sizeof(ClientLocation));
	
	ReplyToCommand(client, "%s IP: %s", TAG_MESSAGE, ClientIP);
	ReplyToCommand(client, "%s Location: %s", TAG_MESSAGE, ClientLocation);
	return Plugin_Handled;
}