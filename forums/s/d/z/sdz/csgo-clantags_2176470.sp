#include <sourcemod>
#include <clientprefs>
#include <colors>

static String:clanTagString[MAXPLAYERS + 1][16];
new Handle:clanTagCookie = INVALID_HANDLE;

//Plugin Information:
public Plugin:myinfo =
{
	name = "CS:GO Clan Tags",
	author = "EasSidezZ/Saudii",
	description = "",
	version = "1.0", //1st = Official Release, 2nd = Beta, 3rd = Alpha/Pre-Alpha
	url = "sourcemod.net"
}

public OnPluginStart()
{
	AddCommandListener(Listen_Chat, "say");
	AddCommandListener(Listen_ChatTeam, "say2");
	RegConsoleCmd("sm_clantag", Command_setClanTag, "Set a Clantag");
	clanTagCookie = RegClientCookie("clantag", "", CookieAccess_Public);

}

public OnClientCookiesCached(Client)
{
	GetClientCookie(Client, clanTagCookie, clanTagString[Client], 16);
	if(strlen(clanTagString[Client]) < 2)
	{
		clanTagString[Client] = "\0";
	}
}

public Action:Command_setClanTag(Client, Args)
{
	decl String:sArgs[16];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	if(strlen(sArgs) > 6 || strlen(sArgs) < 2)
	{
		CPrintToChat(Client, "[SM] Clan Tag must be 2 to 6 characters long");
		return Plugin_Handled;
	}

	clanTagString[Client] = sArgs;
	CPrintToChat(Client, "[SM] Clan Tag has been set to: \x04%s", sArgs);
	return Plugin_Handled;
}

public Action:Listen_Chat(Client, const String:command[], argc)
{
	decl String:chatMessage[255];
	GetCmdArg(1, chatMessage, sizeof(chatMessage));
	if(StrEqual(clanTagString[Client], "\0", false))
	{
		return Plugin_Continue;
	}

	switch(GetClientTeam(Client))
	{
		case 1:
		{
			Format(chatMessage, sizeof(chatMessage), " \x04%s \x08%N : \x01%s", clanTagString, Client, chatMessage);
		}

		case 2:
		{
			Format(chatMessage, sizeof(chatMessage), " \x04%s \x09%N : \x01%s", clanTagString, Client, chatMessage);
		}

		case 3:
		{
			Format(chatMessage, sizeof(chatMessage), " \x04%s \x0B%N : \x01%s", clanTagString, Client, chatMessage);
		}
	}

	CPrintToChatAll(chatMessage);
	return Plugin_Handled;
}

public Action:Listen_ChatTeam(Client, const String:command[], argc)
{
	decl String:chatMessage[255];
	GetCmdArg(1, chatMessage, sizeof(chatMessage));
	if(StrEqual(clanTagString[Client], "\0", false))
	{
		return Plugin_Continue;
	}

	switch(GetClientTeam(Client))
	{
		case 1:
		{
			Format(chatMessage, sizeof(chatMessage), " (Spectator) \x08%s \x09%N : \x01%s", clanTagString, Client, chatMessage);
		}

		case 2:
		{
			Format(chatMessage, sizeof(chatMessage), " (Terrorist) \x04%s \x09%N : \x01%s", clanTagString, Client, chatMessage);
		}

		case 3:
		{
			Format(chatMessage, sizeof(chatMessage), " (Counter-Terrorist) \x0B%s \x09%N : \x01%s", clanTagString, Client, chatMessage);
		}
	}

	CPrintToChatAll(chatMessage);
	return Plugin_Handled;
}