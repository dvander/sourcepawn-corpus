#pragma semicolon 1
#pragma newdecls required

static const char
	PL_NAME[]	= "Commands list",
	PL_VER[]	= "1.1.1_artyk",
	SEPARATOR[] = "------|--------------|----------------------------------|----------------------------------|--------------------",
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
	int i = 1;
	
	int flags;
	char name[64], desc[256];
	
	char plugname[PLATFORM_MAX_PATH] = {};
	char flagText[PLATFORM_MAX_PATH] = {};
	
	CommandIterator  iterator = GetCommandIterator();
	char path[256];
	BuildPath(Path_SM, path, sizeof(path), "CMDs_List.txt");

	if(FileExists(path)) DeleteFile(path);

	Handle file = OpenFile(path, "at");
	
	WriteFileLine(file, "%s", SEPARATOR);
	WriteFileLine(file, " %3d  | %-12s | %-32s | %-32s | %s", "Num", "Plugin Name", "Admin Flags", "Name & Description");
	WriteFileLine(file, "%s", SEPARATOR);
	
	while (iterator.Next())
    {
		iterator.GetName(name, sizeof(name));
		iterator.GetDescription(desc, sizeof(desc));
		GetFlagName(iterator.Flags, flagText, sizeof(flagText));
		GetPluginFilename(iterator.Plugin, plugname, sizeof(plugname));
		
		//Print!
		if(!desc[0]) WriteFileLine(file, "[%3d] | %-12s | %-32s | %-32s | (NOARGS)", i, flagText, plugname, name);
		else 		 WriteFileLine(file, "[%3d] | %-12s | %-32s | %-32s | %s", i, flagText, plugname, name, desc);
		i++;
    }
	WriteFileLine(file, "%s", SEPARATOR);
	
	if(i == 1) PrintToConsole(client, "Results not found");
	else PrintToConsole(client, "Saved %i commands.", i-1);

	delete file;
	delete iterator;

	return Plugin_Handled;
}

public Action Cmd_Show(int client, int args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT) ReplyToCommand(client, "[SM] %t", "See console for output");
	
	PrintToConsole(client, "%s", SEPARATOR);
	PrintToConsole(client, " %3s  | %-12s | %-32s | %-32s | %s", "Num", "Admin Flags", "Plugin Name", "Command Name", "Command Description");
	PrintToConsole(client, "%s", SEPARATOR);
	
	int i = 1;
	
	int flags;
	char name[64], desc[256];
	
	char plugname[PLATFORM_MAX_PATH] = {};
	char flagText[PLATFORM_MAX_PATH] = {};
	
	CommandIterator  iterator =  new CommandIterator();
	
	while (iterator.Next())
    {
		iterator.GetName(name, sizeof(name));
		iterator.GetDescription(desc, sizeof(desc));
		if(CheckCommandAccess(client, name, iterator.Flags)){
			
			GetFlagName(iterator.Flags, flagText, sizeof(flagText));
			GetPluginFilename(iterator.Plugin, plugname, sizeof(plugname));
			
			//Print!
			if(!desc[0]){
				PrintToConsole(client, "[%3d] | %-12s | %-32s | %-32s | (NO DESCRIPTION!)", i, flagText, plugname, name);
			}
			else{
				PrintToConsole(client, "[%3d] | %-12s | %-32s | %-32s | %s", i, flagText, plugname, name, desc);
			}
			i++;
		}
    }
	
	if(i == 1) PrintToConsole(client, "Results not found");
	PrintToConsole(client, "%s", SEPARATOR);
	
	return Plugin_Handled;
}

stock void GetFlagName(int flags, char[] buffer, int maxlen)
{
	//static char buffer[PLATFORM_MAX_PATH];
	Format(buffer, maxlen, "%s", "(No flags)");
	
	for(int i = 0; i < AdminFlags_TOTAL; i++) {
		if(flags & (1<<i)){
			Format(buffer, maxlen, "%s", FLAGS[i]);
		}
	}
}