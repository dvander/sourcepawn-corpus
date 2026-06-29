static const int iAdmFlags[21] = {
ADMFLAG_RESERVATION,
ADMFLAG_GENERIC,
ADMFLAG_KICK,
ADMFLAG_BAN,
ADMFLAG_UNBAN,
ADMFLAG_SLAY,
ADMFLAG_CHANGEMAP,
ADMFLAG_CONVARS,
ADMFLAG_CONFIG,
ADMFLAG_CHAT,
ADMFLAG_VOTE,
ADMFLAG_PASSWORD,
ADMFLAG_RCON,
ADMFLAG_CHEATS,
ADMFLAG_CUSTOM1,
ADMFLAG_CUSTOM2,
ADMFLAG_CUSTOM3,
ADMFLAG_CUSTOM4,
ADMFLAG_CUSTOM5,
ADMFLAG_CUSTOM6,
ADMFLAG_ROOT
};
static const char sAdmFlagLetters[21][2] = {
"a",
"b",
"c",
"d",
"e",
"f",
"g",
"h",
"i",
"j",
"k",
"l",
"m",
"n",
"o",
"p",
"q",
"r",
"s",
"t",
"z"
};
static const char sAdmFlagsNames[21][12] = {
"reservation",
"generic",
"kick",
"ban",
"unban",
"slay",
"changemap",
"cvars",
"config",
"chat",
"vote",
"password",
"rcon",
"cheats",
"custom1",
"custom2",
"custom3",
"custom4",
"custom5",
"custom6",
"root"
};
//bool bToAll;

public Plugin myinfo = 
{
	name		= "Check command flags",
	author		= "Grey83",
	description	= "Shows commands available for the flag",
	version		= "1.0.1",
	url			= ""
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
/*	ConVar CVar;
	HookConVarChange((CVar = CreateConVar("sm_cf_access", "1","1 - shows all commands, 0 - shows only available to",FCVAR_NONE,true, 0.0, true, 1.0)), CVarChange);
	bToAll = CVar.BoolValue;
*/
	RegConsoleCmd("listflags", Cmd_ShowFlags, "Shows available flags (letter and name)");
	RegConsoleCmd("cmdflags", Cmd_ShowCmds, "cmdflags <flag> - shows commands available for the flag\ncmdflags - shows commands available to You");
}
/*
public void CVarChange(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bToAll = CVar.BoolValue;
}
*/
public Action Cmd_ShowFlags(int client, int args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT) ReplyToCommand(client, "[SM] %t", "See console for output");

	PrintToConsole(client, "---+----+-----------+------");
	PrintToConsole(client, "Num Char    Name     Access");
	PrintToConsole(client, "---+----+-----------+------");
	for(int i; i < 21; i++)
	{
		PrintToConsole(client, "%2d) '%s': %-11s %s", i+1, sAdmFlagLetters[i], sAdmFlagsNames[i], isHaveAccess(client, iAdmFlags[i]) ? "V" : "-");
	}
	PrintToConsole(client, "---+----+---------------");

	return Plugin_Handled;
}

public Action Cmd_ShowCmds(int client, int args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT) ReplyToCommand(client, "[SM] %t", "See console for output");

	int order = -1;

	if(args)
	{
		char letter[2];
		GetCmdArg(1, letter, sizeof(letter));
		for(int i; i < 21; i++)
		{
			if(StrContains(letter, sAdmFlagLetters[i], false) != -1)
			{
				order = i;
				break;
			}
		}

		if(order < 0) PrintToConsole(client, "Flag '%s' does not exist\nTo see available flags print 'listflags'", letter);
	}

	ListAvailableCommands(client, order);

	return Plugin_Handled;
}

bool isHaveAccess(int client, int flag)
{
	if(!client) return true;

	AdminId admin = GetUserAdmin(client);
	if(admin != INVALID_ADMIN_ID)
		return (GetAdminFlags(admin, Access_Real) & flag || GetAdminFlags(admin, Access_Effective) & flag);

	return false;
}

void ListAvailableCommands(int client, const int order)
{
	Handle CmdIter = GetCommandIterator();
	char sName[64], sDesc[256];
	if(order < 0 ) PrintToConsole(client, "Commands available to You:");
	else PrintToConsole(client, "Admin flag '%s': %s", sAdmFlagLetters[order], sAdmFlagsNames[order]);
	int j = 1, iFlags;
	while (ReadCommandIterator(CmdIter, sName, sizeof(sName), iFlags, sDesc, sizeof(sDesc)))
	{
		if((order < 0 && CheckCommandAccess(client, sName, iFlags)) || (0 < order < 20 && iFlags & iAdmFlags[order]) || (order > 19 && iFlags))
		{
			if(sDesc[0]) Format(sDesc, sizeof(sDesc), "\n	%s", sDesc);
			PrintToConsole(client, "%3d) %s%s", j++, sName, sDesc);
		}
	}
	if (j == 1) PrintToConsole(client, "%t", "No commands available");

	delete CmdIter;
}