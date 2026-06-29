#include <sourcemod>

public Plugin:myinfo = 

{
	name = "Slash Me",
	author = "Fire",
	description = "/me",
	version = "3",
	url = "www.snigsclan.com"
}

new Handle:szType;
new Handle:szStart;
new Handle:szEnd;
new String:szTypo[7];
new String:szStar[MAXPLAYERS];
new String:szEn[MAXPLAYERS];

public OnPluginStart()
{
	CreateConVar("sm_me_version", "3", "SlashMe Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	szType = CreateConVar("sm_me_type", "tab", "Announce Type | custom, tab, star, dblstar, chev, norm, tabstar, tabdbl, tabchev", FCVAR_PLUGIN);
	szStart = CreateConVar("sm_me_start", "* ", "Starting Characters, INCLUDING SPACES", FCVAR_PLUGIN);
	szEnd = CreateConVar("sm_me_end", " *", "Ending Characters, INCLUDING SPACES", FCVAR_PLUGIN);
	
	GetConVarString(szType, szTypo, sizeof(szTypo));
	GetConVarString(szStart, szStar, sizeof(szStar));
	GetConVarString(szEnd, szEn, sizeof(szEn));
	RegConsoleCmd("sm_me", Command_Me);
}

public OnConfigsExecuted()
{
	GetConVarString(szStart, szStar, sizeof(szStar));
	GetConVarString(szEnd, szEn, sizeof(szEn));
	GetConVarString(szType, szTypo, sizeof(szTypo));
}

public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	GetConVarString(szStart, szStar, sizeof(szStar));
	GetConVarString(szEnd, szEn, sizeof(szEn));
	GetConVarString(szType, szTypo, sizeof(szTypo));
} 

public Action:Command_Me(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "\x04Usage:\x01 /me <message>");
		return Plugin_Handled;
	}
	
	new String:act[128];
	GetCmdArgString(act, sizeof(act));
	
	slashme(client, act);
	
	return Plugin_Handled;
}

stock slashme(client, String:act[128])
{
	new String:message[200];
	if (StrEqual(szTypo, "norm"))
	{
		Format(message, sizeof(message), "\x03%N %s", client, act);
	}
	else if (StrEqual(szTypo, "tab"))
	{
		Format(message, sizeof(message), "\x03    %N %s", client, act);
	}
	else if (StrEqual(szTypo, "tabstar"))
	{
		Format(message, sizeof(message), "\x03    * %N %s", client, act);
	}
	else if (StrEqual(szTypo, "tabdbl"))
	{
		Format(message, sizeof(message), "\x03    * %N %s *", client, act);
	}
	else if (StrEqual(szTypo, "tabchev"))
	{
		Format(message, sizeof(message), "\x03    <%N %s>", client, act);
	}
	else if (StrEqual(szTypo, "star"))
	{
		Format(message, sizeof(message), "\x03* %N %s", client, act);
	}
	else if (StrEqual(szTypo, "dblstar"))
	{
		Format(message, sizeof(message), "\x03* %N %s *", client, act);
	}
	else if (StrEqual(szTypo, "chev"))
	{
		Format(message, sizeof(message), "\x03<%N %s>", client, act);
	}
	else if (StrEqual(szTypo, "custom"))
	{
		Format(message, sizeof(message), "\x03%s%N %s%s>", szStar, client, act, szEn);
	}
	else
	{
		LogError("Invalid /me Type, Defaulting");
		Format(message, sizeof(message), "\x03    %N %s", client, act);
	}
	
	SayText2(client, message);
	
	return;
}

stock SayText2(author_index , const String:message[] ) {
	new Handle:buffer = StartMessageAll("SayText2");
	if (buffer != INVALID_HANDLE) {
		BfWriteByte(buffer, author_index);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}