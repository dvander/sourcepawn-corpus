#pragma semicolon 1
#pragma newdecls required

static const char
	PL_NAME[]	= "Commands list",
	PL_VER[]	= "1.1.0",

	SEPARATOR[]	= "----+-------+------------------------------------------------------------------",
	FLAGS[][]	=
{
	"Reservation",
	"Generic",
	"Kick",
	"Ban",
	"Unban",
	"Slay",
	"Changemap",
	"Convars",
	"Config",
	"Chat",
	"Vote",
	"Password",
	"RCON",
	"Cheats",
	"Root",
	"Custom1",
	"Custom2",
	"Custom3",
	"Custom4",
	"Custom5",
	"Custom6"
};

public Plugin myinfo = 
{
	name		= PL_NAME,
	author		= "Grey83",
	description	= "Saves list of commands and descriptions to a file or displays available commands and descriptions in console",
	version		= PL_VER,
	url			= "https://forums.alliedmods.net/showthread.php?p=2401335"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_cmds_list_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_storecmds", Cmd_Store, ADMFLAG_ROOT, "Saves list of commands and descriptions to a file");
	RegConsoleCmd("sm_cmds", Cmd_Show, "Displays available commands and descriptions in console");
}

public Action Cmd_Store(int client, int args)
{
	int flags;
	char path[256], name[64], desc[256];
	Handle iterator = GetCommandIterator();

	BuildPath(Path_SM, path, sizeof(path), "CMDs_List.txt");

	if(FileExists(path)) DeleteFile(path);

	Handle file = OpenFile(path, "at");

	WriteFileLine(file, "Num	| Flags	| Name & Description");
	int i = 1;
	while(ReadCommandIterator(iterator, name, sizeof(name), flags, desc, sizeof(desc)))
	{
		if(CheckCommandAccess(client, name, flags))
		{
			if(!desc[0]) WriteFileLine(file, "%03d) %s	%s", i++, GetFlagName(flags), name);
			else WriteFileLine(file, "%03d) %s	%s		-- %s", i++, GetFlagName(flags), name, desc);
		}
	}

	if(i == 1) PrintToConsole(client, "Results not found");
	else PrintToConsole(client, "Saved %i commands.", i-1);

	delete file;
	delete iterator;

	return Plugin_Handled;
}

public Action Cmd_Show(int client, int args)
{
	int flags;
	char name[64], desc[256];
	Handle iterator = GetCommandIterator();

	if(GetCmdReplySource() == SM_REPLY_TO_CHAT) ReplyToCommand(client, "[SM] %t", "See console for output");

	PrintToConsole(client, SEPARATOR);
	PrintToConsole(client, "Num | Flags | Name & Description");
	PrintToConsole(client, SEPARATOR);
	int i = 1;
	while(ReadCommandIterator(iterator, name, sizeof(name), flags, desc, sizeof(desc)))
	{
		if(CheckCommandAccess(client, name, flags))
		{
			if(!desc[0]) PrintToConsole(client, "[%03d] %s %s", i++, GetFlagName(flags), name);
			else PrintToConsole(client, "[%03d] %s %s --> %s", i++, GetFlagName(flags), name, desc);
		}
	}
	PrintToConsole(client, SEPARATOR);

	if(i == 1) PrintToConsole(client, "Results not found");

	return Plugin_Handled;
}

stock char GetFlagName(int flags)
{
	static char buffer[PLATFORM_MAX_PATH];
	if(!flags)
	{
		buffer = "		";
		return buffer;
	}

	buffer[0] = 0;

	int i;
	for(; i < AdminFlags_TOTAL; i++) if(flags & (1<<i)) Format(buffer, sizeof(buffer), "%s%s|", buffer, FLAGS[i]);

	if((i = strlen(buffer) - 1) < 7)
	{
		buffer[i] = '	';
		i++;
	}
	buffer[i] = 0;

	return buffer;
}