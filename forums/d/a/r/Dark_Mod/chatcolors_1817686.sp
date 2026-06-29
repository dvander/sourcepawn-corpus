#include <sourcemod>
#include <colors>

#pragma semicolon 1
#define VERSION "1.0.2"

public Plugin:myinfo = 
{
	name = "Admin Chat Colors",
	author = "Dark Mod",
	description = "Chat colors for admin players!",
	version = VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("acc_version", VERSION, "");
	RegConsoleCmd("say", SayHook);
}

public Action:SayHook(client, Args)
{
	new AdminId:AdminID = GetUserAdmin(client);
	if(AdminID == INVALID_ADMIN_ID)
		return Plugin_Continue;
	
	decl String:Name[MAX_NAME_LENGTH];
	decl String:Msg[256];
		
	GetClientName(client, Name, sizeof(Name));
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-1] = '\0';
	CPrintToChatAll("{green}%s: {default}%s", Name, Msg[1]);
	
	return Plugin_Handled;
}