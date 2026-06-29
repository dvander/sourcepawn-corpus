#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D] Join Team",
	author = "Jonny",
	description = "",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
}

public Action:Command_Say(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "!join", false) == 0 || strcmp(text[startidx], "!jointeam", false) == 0 || strcmp(text[startidx], "!jointeam 2", false) == 0 || strcmp(text[startidx], "!jointeam2", false) == 0)
	{
		FakeClientCommand(client, "jointeam 2");
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}