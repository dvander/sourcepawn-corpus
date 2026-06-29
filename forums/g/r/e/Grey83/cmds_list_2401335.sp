#include <sourcemod>

#define PLUGIN_VERSION		"1.0"
#define PLUGIN_NAME		"Commands list"

public Plugin myinfo = 
{
	name				= PLUGIN_NAME,
	author				= "Grey83",
	description				= "Saves list of commands and descriptions to a file or displays available commands and descriptions in console",
	version				= PLUGIN_VERSION,
	url					= "https://forums.alliedmods.net/showthread.php?p=2401335"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_cmds_list_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_storecmds", Cmd_Store, ADMFLAG_ROOT, "Saves list of commands and descriptions to a file");
	RegConsoleCmd("sm_cmds", Cmd_Show, "Displays available commands and descriptions in console");
}

public Action Cmd_Store(client, args)
{
	char z_File[256];
	char Name[64];
	char Desc[256];
	char Acces[7];
	int Flags;
	Handle CmdIter = GetCommandIterator();

	BuildPath(Path_SM, z_File, sizeof(z_File), "CMDs_List.txt");

	if(FileExists(z_File) == true) DeleteFile(z_File);

	Handle h_File = OpenFile(z_File, "at");

	WriteFileLine(h_File, "Num	| Acces	| Name & Description");
	int i = 1;
	while (ReadCommandIterator(CmdIter, Name, sizeof(Name), Flags, Desc, sizeof(Desc)))
	{
		if (CheckCommandAccess(client, Name, Flags)) 
		{
			Acces = (!Flags) ? "	" : "Admin";
			if (Desc[0] == '\0') WriteFileLine(h_File, "%03d)	%s	%s", i++, Acces, Name);
			else WriteFileLine(h_File, "%03d)	%s	%s		-- %s", i++, Acces, Name, Desc);
		}
	}

	if (i == 1) PrintToConsole(client, "Results not found");
	else  PrintToConsole(client, "Saved %i commands.", i-1);

	delete h_File;
	delete CmdIter;

	return Plugin_Handled;
}

public Action Cmd_Show(client, args)
{
	char Name[64];
	char Desc[256];
	char Acces[8];
	int Flags;
	Handle CmdIter = GetCommandIterator();

	if (GetCmdReplySource() == SM_REPLY_TO_CHAT) ReplyToCommand(client, "[SM] %t", "See console for output");

	PrintToConsole(client, "----+-------+------------------------------------------------------------------");
	PrintToConsole(client, "Num | Acces | Name & Description");
	PrintToConsole(client, "----+-------+------------------------------------------------------------------");
	int i = 1;
	while (ReadCommandIterator(CmdIter, Name, sizeof(Name), Flags, Desc, sizeof(Desc)))
	{
		if (CheckCommandAccess(client, Name, Flags)) 
		{
			Acces = (!Flags) ? "" : "[Admin]";
			if (Desc[0] == '\0') PrintToConsole(client, "[%03d] %-7.7s %s", i++, Acces, Name);
			else PrintToConsole(client, "[%03d] %-7.7s %s --> %s", i++, Acces, Name, Desc);
		}
	}
	PrintToConsole(client, "----+-------+------------------------------------------------------------------");

	if (i == 1) PrintToConsole(client, "Results not found");

	return Plugin_Handled;
}