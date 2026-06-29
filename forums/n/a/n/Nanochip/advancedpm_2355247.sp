#pragma semicolon 1
#include <sourcemod>
#include <morecolors>
#include <clientprefs>

#define PLUGIN_VERSION	"1.2.1"

public Plugin myinfo = {
	name		= "[ANY] Advanced Private Messages",
	author		= "Nanochip",
	description = "Better private messaging than silly ol' Basechat!",
	version		= PLUGIN_VERSION,
	url			= "http://thecubeserver.org/"
};

int replyTo[MAXPLAYERS+1] = {0, ...};
bool pmspy[MAXPLAYERS+1];
bool csgo = false;
Handle cPmspy;


public void OnPluginStart()
{
	if (GetEngineVersion() == Engine_CSGO) csgo = true;
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_advancedpm_version", PLUGIN_VERSION, "Advanced Private Messages Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_p", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_pm", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_privatemessage", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_msg", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_tell", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_message", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_w", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_whisper", Cmd_PM, "Private Message a player!");
	RegConsoleCmd("sm_qr", Cmd_Reply, "Reply to a private message!");
	RegConsoleCmd("sm_reply", Cmd_Reply, "Reply to a private message!");
	
	RegAdminCmd("sm_pmspy", Cmd_PmSpy, ADMFLAG_KICK, "Enable/Disable Private Message Spy.");
	
	cPmspy = RegClientCookie("sm_advancedpm_pmspy", "", CookieAccess_Private);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		pmspy[i] = true;
		if (IsClientInGame(i) && AreClientCookiesCached(i)) OnClientCookiesCached(i);
	}
}

public void OnMapStart()
{
	for (int i = 0; i < MAXPLAYERS+1; i++)
	{
		replyTo[i] = 0;
	}
}

public Action Cmd_PmSpy(int client, int args)
{
	if (pmspy[client])
	{
		pmspy[client] = false;
		SetClientCookie(client, cPmspy, "false");
		if (csgo) ReplyToCommand(client, "[PM SPY] Disabled.");
		else CReplyToCommand(client, "{green}[PM SPY] Disabled.");
	}
	else
	{
		pmspy[client] = true;
		SetClientCookie(client, cPmspy, "true");
		if (csgo) ReplyToCommand(client, "[PM SPY] Enabled.");
		else CReplyToCommand(client, "{green}[PM SPY] Enabled.");
	}
	return Plugin_Handled;
}

public Action Cmd_PM(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: !p <name or #userid> <message>");
		return Plugin_Handled;
	}
	
	char pName[MAX_NAME_LENGTH];
	GetCmdArg(1, pName, sizeof(pName));
	
	char arg[32] = "";
	char message[132] = "";
	for (int i = 2; i <= args; i++)
	{
		GetCmdArg(i, arg, sizeof(arg));
		Format(message, sizeof(message), "%s %s", message, arg);
	}
	
	int target = FindTarget(client, pName, true, false);
	if (target == -1) return Plugin_Handled;	
	
	SendPrivateChat(client, target, message);
	replyTo[client] = target;
	replyTo[target] = client;
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	int temp = replyTo[client];
	replyTo[client] = -1;
	if (temp <= MAXPLAYERS) replyTo[temp] = -1;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	replyTo[client] = 0;
}

public OnClientCookiesCached(int client)
{
	char info[6];
	GetClientCookie(client, cPmspy, info, sizeof(info));
	if (StrEqual(info, "true")) pmspy[client] = true;
	if (StrEqual(info, "false")) pmspy[client] = false;
}

public Action Cmd_Reply(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !qr <message>");
		return Plugin_Handled;
	}
	
	if (replyTo[client] == 0)
	{
		ReplyToCommand(client, "[SM] You have not sent/received a private message, therefore you cannot reply to nothing.");
		return Plugin_Handled;
	}
	
	if (replyTo[client] == -1)
	{
		ReplyToCommand(client, "[SM] You cannot send a private message to a disconnected player.");
		return Plugin_Handled;
	}
	
	char arg[32] = "";
	char message[132] = "";
	for (int i = 1; i <= args; i++)
	{
		GetCmdArg(i, arg, sizeof(arg));
		Format(message, sizeof(message), "%s %s", message, arg);
	}
	
	int target = replyTo[client];
	if (target == -1) return Plugin_Handled;
	
	SendPrivateChat(client, target, message);
	return Plugin_Handled;
}

void SendPrivateChat(client, target, const char[] message)
{
	if (client == 0)
	{
		if (csgo)
			PrintToChat(target, "(Console to You) Console :  %s", message);
		else
			CPrintToChat(target, "{black}({darkmagenta}Console {azure}to {fuchsia}You{black}) {default}Console :  {azure}%s", message);
	}
	
	if (target != client)
	{
		if (csgo)
			PrintToChat(client, "(You to %N) %N :  %s", target, client, message);
		else
			CPrintToChatEx(client, client, "{black}({fuchsia}You {azure}to {darkmagenta}%N{black}) {teamcolor}%N {default}:  {azure}%s", target, client, message);
	}
	
	if (csgo)
		PrintToChat(target, "(%N to You) %N :  %s", client, client, message);
	else
		CPrintToChatEx(target, client, "{black}({darkmagenta}%N {azure}to {fuchsia}You{black}) {teamcolor}%N {default}:  {azure}%s", client, client, message);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (CheckCommandAccess(i, "sm_pmspy", ADMFLAG_KICK, false) && pmspy[i] && i != client && i != target && CanUserTarget(i, client))
		{
			if (csgo)
				PrintToChat(i, "[PM SPY] (%N to %N) %N :  %s", client, target, client, message);
			else
				CPrintToChatEx(i, client, "{green}[PM SPY] {black}({darkmagenta}%N {azure}to {darkmagenta}%N{black}) {teamcolor}%N {default}:  {azure}%s", client, target, client, message);
		}
	}
	LogAction(client, -1, "\"%L\" sent a private message to \"%L\" (message: %s)", client, target, message);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (StrStarts(sArgs, "!w ") || StrStarts(sArgs, "!whisper ") || StrStarts(sArgs, "!privatemessage ") || StrStarts(sArgs, "!p ") || StrStarts(sArgs, "!pm ") || StrStarts(sArgs, "!tell ") || StrStarts(sArgs, "!msg ") || StrStarts(sArgs, "!message ") || StrStarts(sArgs, "!qr ") || StrStarts(sArgs, "!reply ")) return Plugin_Handled;
	return Plugin_Continue;
}

stock bool StrStarts(const char[] szStr, const char[] szSubStr, bool bCaseSensitive = true) 
{
	return !StrContains(szStr, szSubStr, bCaseSensitive);
}