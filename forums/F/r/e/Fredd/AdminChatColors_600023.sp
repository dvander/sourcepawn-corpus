#include <sourcemod>

#pragma semicolon 1
#define VERSION "0.1"

public Plugin:myinfo = 
{
	name = "Admin Chat Colors",
	author = "Fredd",
	description = "Every time admins use chat all text is changed to green..",
	version = VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("acc_version", VERSION, "");
	RegConsoleCmd("say", SayHook);
}public Action:SayHook(client, Args)
{
	new AdminId:AdminID = GetUserAdmin(client);
	if(AdminID == INVALID_ADMIN_ID)
		return Plugin_Continue;
	
	decl String:Name[MAX_NAME_LENGTH];
	decl String:Msg[256];
		
	GetClientName(client, Name, sizeof(Name));
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-1] = '\0';
	PrintToChatAll("\x04%s: %s", Name, Msg[1]);
	
	return Plugin_Handled;
}