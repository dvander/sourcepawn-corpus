#include <sourcemod>
#include <scp>

public Plugin:myinfo = 
{
	name = "Greentext",
	author = "Pelipoika",
	description = "Changes messages prefixed with > to green.",
	version = "1.0",
	url = "forums.alliedmodders.com"
}

public Action:OnChatMessage(&author, Handle:recepients, String:name[], String:message[]) 
{
	if (author > 0 && IsClientInGame(author))
	{
		ReplaceString(message, MAXLENGTH_INPUT, ">", "\x05>");
		return Plugin_Changed;
	}
	
	return Plugin_Handled;
}