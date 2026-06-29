#include <sourcemod>
#include <clientprefs>
#include <chat-processor>

#define PLUGIN_VERSION "1.0"

Handle hCookie;
ArrayList recipients;

public Plugin myinfo =
{
	name = "Hide Chat",
	author = "Sgt. Gremulock,",
	description = "Hide the chat of other players.",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

public void OnPluginStart()
{
	CreateConVar("sm_hidechat_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	hCookie = RegClientCookie("sm_hidechat_client", "Does a client have hide chat enabled?", CookieAccess_Protected);
	
	RegConsoleCmd("sm_hidechat", Command_Hidechat);
}

public void OnClientPostAdminCheck(int client)
{
	char cookie[32];
	GetClientCookie(client, hCookie, cookie, sizeof(cookie));
	int cookievalue = StringToInt(cookie);
	
	if (cookievalue == 1)
	{
		return;
	}
	else if (cookievalue == 0)
	{
		recipients.Push(client);
	}
}

public void OnClientDisconnect(int client)
{
	if (recipients.FindValue(client) != -1)
	{
		recipients.Erase(client);
	}
}

public Action Command_Hidechat(int client, int args)
{
	char cookie[32];
	GetClientCookie(client, hCookie, cookie, sizeof(cookie));
	int cookievalue = StringToInt(cookie);
	
	if (cookievalue == 1)
	{
		SetClientCookie(client, hCookie, "0");
		ReplyToCommand(client, "[SM] Disabled hide chat.");
		recipients.Push(client);
		
		return Plugin_Handled;
	}
	else if (cookievalue == 0)
	{
		SetClientCookie(client, hCookie, "1");
		ReplyToCommand(client, "[SM] Enabled hide chat.");
		recipients.Erase(client);
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action CP_OnChatMessage(int& author, ArrayList aRecipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	aRecipients.Clear();
	aRecipients = recipients.Clone();
}