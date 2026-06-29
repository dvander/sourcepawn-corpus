#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "List All Admin Commands",
	author = "3V0Lu710N",
	description = "Gets all admin commands from all loaded plugins",
	version = PLUGIN_VERSION,
	url = "http://www.hellsgamers.com"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_getcmds", Get_Cmds, ADMFLAG_ROOT, "[SM] sm_getcmds <number of plugins>");

	LoadTranslations("common.phrases");
}

public Action Get_Cmds(client, args)
{

	if(args < 1)
	{
		ReplyToCommand(client, "[SM] sm_getcmds <number of plugins>");

		return Plugin_Handled;
	}

	if(!client)
	{
		PrintToServer("Command is not usable through Server Console or Rcon");

		return Plugin_Handled;
	}

	char Arg1[256];
	char z_File[256];
	char cmdList[10000];

	GetCmdArg(1, Arg1, sizeof(Arg1));

	BuildPath(Path_SM, z_File, sizeof(z_File), "cmds.txt");

	if(FileExists(z_File) == true)
	{
		DeleteFile(z_File);
	}

	Handle h_File = OpenFile(z_File, "at");

	for(int i = 1; i < StringToInt(Arg1); i++)
	{
		ServerCommandEx(cmdList, sizeof(cmdList), "sm cmds %i", i);

		WriteFileLine(h_File, "%s", cmdList);
	}

	CloseHandle(h_File);

	return Plugin_Handled;
}
