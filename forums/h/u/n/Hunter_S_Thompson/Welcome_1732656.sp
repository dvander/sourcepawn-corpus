#include <sourcemod>

new Handle:sm_Join_Message = INVALID_HANDLE;
public Plugin:myinfo =
{
	name = "Welcome",
	author = "Hunter S. Thompson",
	description = "My First Plugin - Displays a welcome message when the user joins.",
	version = "1.0.0.0",
	url = "http://forums.alliedmods.net/showthread.php?t=187975"
};

public OnPluginStart()
{
	sm_Join_Message = CreateConVar("sm_join_message", "Welcome %N, to Conflagration Deathrun!", "Default Join Message", FCVAR_NOTIFY)
	AutoExecConfig(true, "onJoin")
}

public OnClientPostAdminCheck(client)
{
	new String:name[MAX_NAME_LENGTH]
	new String:Message[128]
	GetConVarString(sm_Join_Message, Message, sizeof(Message))
	GetClientName(client, name, sizeof(name))
	PrintToChat(client, Message, client); 
}