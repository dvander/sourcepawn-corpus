#include <sourcemod>
#include <colors>

public Plugin:myinfo = 
{
	name = "Admin Chat Colors",
	author = "EGood",
	description = "Admin Chat Colors",
	version = "1.0.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("say", SayHook);
	RegConsoleCmd("say_team", SayHook);
}

public Action:SayHook(client, args)
{
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	StripQuotes(text);
	
	if(strlen(text) <= 1)
		return Plugin_Continue;
	
	if(text[0] == '!' && text[1] == ' ')
	{
		if(!IsClientConnected(client) && !IsClientInGame(client))
			return Plugin_Continue;
		
		if(GetUserAdmin(client) == INVALID_ADMIN_ID)
			return Plugin_Continue;
		
		new String:name[64];
			GetClientName(client, name, sizeof(name));
		
		decl String:message[192];
		strcopy(message, 192, text[2]);

		CPrintToChatAllEx(client, "{olive}A{green}dmin{default} | {teamcolor}%s {olive}: {green}%s", name, message);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}