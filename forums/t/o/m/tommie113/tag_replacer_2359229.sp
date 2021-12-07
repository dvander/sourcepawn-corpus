#include <sourcemod>

public Plugin:myinfo =
{
	name = "Map info tag replacer.",
	author = "tommie113",
	description = "Changes (ALL) Console: into MAP INFO:",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);
}


public Action:Hook_TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:message[256]; 
	BfReadString(bf, message, sizeof(message), true);
     
	if(StrContains(message, "(ALL) Console:") != -1)
    {
		ReplaceString(message, sizeof(message), "(ALL) Console:", "MAP INFO:", false);
		return Plugin_Changed;
	} else {
		return Plugin_Continue;
	}
}