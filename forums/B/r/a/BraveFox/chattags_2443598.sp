#include <sourcemod>
#include <scp>


#pragma semicolon 1
#pragma tabsize 0

public Plugin myinfo = {
	name        = "Admins Tags",
	author      = "ItsNoy",
	description = "Admins Get Tags",
	version     = "1.0",
	url         = ""
};

public OnPluginStart()
{
}

public Action OnChatMessage(int &client, Handle hRecipients, char[] sName, char[] Message)
{
	if(CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		Format(Message, MAXLENGTH_MESSAGE, "[Admin]%s", Message);
		return Plugin_Handled;
	}
	if(CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		Format(Message, MAXLENGTH_MESSAGE, "[Moderator]%s", Message);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}