#include <sourcemod>
#include <regex>

public Plugin:myinfo = 
{
	name = "IP Chat Block",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Blocks players from posting ips in chat.",
	version = "1.0",
	url = "http://www.wcfan.de/"
}

new Handle:g_IpRegex = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_ipchatblock_version", "1.0", "IP Chat Block version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("say", ChatHook);
	RegConsoleCmd("say_team", ChatHook);
	g_IpRegex = CompileRegex("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:?\\d*");
}

public Action:ChatHook(client, args)
{
	new String:text[256], String:pName[64];
	decl Handle:sb_Convar;
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);

	if(MatchRegex(g_IpRegex, text) > 0)
	{
		GetClientName(client, pName, 64);
		PrintToChatAll("\x04[IP CHAT BLOCK] %s has been banned for posting an IP in chat.", pName);
		PrintToConsole(client, "You have been banned for posting an IP in chat.");
		sb_Convar = FindConVar("sb_version");
		if (sb_Convar != INVALID_HANDLE)
		{
			ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(client), 0, "Don't post unknown IPs");
			CloseHandle(sb_Convar);
			return Plugin_Handled;
		}
		BanClient(client, 0, BANFLAG_AUTO, "Don't post unknown IPs", "Don't post unknown IPs", "IPCHAT", 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}