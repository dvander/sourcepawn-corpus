#pragma semicolon 1
#pragma newdecls required

ConVar g_cPassword;
char g_sPassword[128];

public Plugin myinfo =
{
	name = "Password",
	author = "Yaser2007",
	description = "Sets or remove the server password with command.",
	version = "1.1",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	g_cPassword = FindConVar("sv_password");

	RegAdminCmd("pw", Cmd_SetPassword, ADMFLAG_PASSWORD);
	RegAdminCmd("rpw", Cmd_RemovePassword, ADMFLAG_PASSWORD);
}

public Action Cmd_SetPassword(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: pw <value>");
		return Plugin_Handled;
	}

	char sPw[128];
	GetCmdArg(1, sPw, sizeof(sPw));

	GetConVarString(g_cPassword, g_sPassword, sizeof(g_sPassword));

	if(StrEqual(sPw, "none", false) || StrEqual(sPw, NULL_STRING))
	{
		if(StrEqual(g_sPassword, "none", false) || StrEqual(g_sPassword, NULL_STRING))
		{
			ReplyToCommand(client, "\x04The server currently has no password!");
			return Plugin_Handled;
		}

		SetConVarString(g_cPassword, "none");
		PrintToChatAll("\x04The server password has been removed successfully.");
		return Plugin_Handled;
	}

	if(StrEqual(sPw, g_sPassword, false))
	{
		ReplyToCommand(client, "\x04Your password is the same as the server password!");
		return Plugin_Handled;
	}

	SetConVarString(g_cPassword, sPw);
	PrintToChatAll("\x04%N \x01Changed server password to: \x03'%s'", client, sPw);

	return Plugin_Handled;
}

public Action Cmd_RemovePassword(int client, int args)
{
	GetConVarString(g_cPassword, g_sPassword, sizeof(g_sPassword));

	if(StrEqual(g_sPassword, "none", false) || StrEqual(g_sPassword, NULL_STRING))
	{
		ReplyToCommand(client, "\x04The server currently has no password!");
		return Plugin_Handled;
	}

	SetConVarString(g_cPassword, "none");
	PrintToChatAll("\x04The server password has been removed successfully.");

	return Plugin_Handled;
}