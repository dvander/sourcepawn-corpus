#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.01"

public Plugin:myinfo =
{
	name = "Banlist",
	author = "X@IDER",
	description = "Shows banlist",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_listid", ListID, ADMFLAG_BAN);
	RegAdminCmd("sm_listip", ListIP, ADMFLAG_BAN);
}

public Action:ListID(client, args)
{
	ReplyToCommand(client,"---------------------------------------------------------------------------------");
	new Handle:F = OpenFile("cfg/banned_user.cfg","r");
	if (F == INVALID_HANDLE)
	{
		ReplyToCommand(client,"File open error");
		ReplyToCommand(client,"---------------------------------------------------------------------------------");
		return Plugin_Handled;	
	}
	decl String:Line[512];
	decl String:Text[3][256];
	new String:Time[256];
	new i = 0;
	while (ReadFileLine(F,Line,512))
	{
		Line[strlen(Line)-1] = 0;
		ExplodeString(Line," ",Text,3,256);
		if (!strcmp(Text[1],"0")) Time = "permanent";
		else Time = Text[1];
		ReplyToCommand(client,"%02d  %20s: %s",i++,Text[2],Time);
	}
	CloseHandle(F);
	ReplyToCommand(client,"---------------------------------------------------------------------------------");
	return Plugin_Handled;	
}

public Action:ListIP(client, args)
{
	ReplyToCommand(client,"---------------------------------------------------------------------------------");
	new Handle:F = OpenFile("cfg/banned_ip.cfg","r");
	if (F == INVALID_HANDLE)
	{
		ReplyToCommand(client,"File open error");
		ReplyToCommand(client,"---------------------------------------------------------------------------------");
		return Plugin_Handled;	
	}
	decl String:Line[512];
	decl String:Text[3][256];
	new String:Time[256];
	new i = 0;
	while (ReadFileLine(F,Line,512))
	{
		Line[strlen(Line)-1] = 0;
		ExplodeString(Line," ",Text,3,256);
		if (!strcmp(Text[1],"0")) Time = "permanent";
		else Time = Text[1];
		ReplyToCommand(client,"%02d  %15s: %s",i++,Text[2],Time);
	}
	CloseHandle(F);
	ReplyToCommand(client,"---------------------------------------------------------------------------------");
	return Plugin_Handled;	
}