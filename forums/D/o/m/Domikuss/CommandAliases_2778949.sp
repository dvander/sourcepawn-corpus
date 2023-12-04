#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

#define PATH_TO_CONFIG "configs/CommandAliases.ini"

StringMap g_hCommands;
ArrayList g_hCmdAlreadyRegs;

public Plugin myinfo =
{
	name = "Command Aliases",
	author = "Domikuss",
	description = "Allows you to assign an alternative command name/s",
	version = "1.0.2",
	url = "https://github.com/Domikuss/Command-Aliases"
};

public void OnPluginStart()
{
	g_hCommands = new StringMap();
	g_hCmdAlreadyRegs = new ArrayList(ByteCountToCells(32));
	RegAdminCmd("sm_cmda_reload", CmdReload, ADMFLAG_ROOT, "Reload Config - Command Aliases");
}

public void OnMapStart()
{
	LoadConfig();
}

void LoadConfig()
{
	KeyValues hKvConfig;
	char sPath[PLATFORM_MAX_PATH], sBuf[1024], sKey[32];

	g_hCommands.Clear();

	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, PATH_TO_CONFIG);

	hKvConfig = new KeyValues("CommandAliases");

	if(!hKvConfig.ImportFromFile(sPath))
	{
		SetFailState("Command Aliases - config is not found (%s).", sPath);
	}

	hKvConfig.Rewind();
	hKvConfig.JumpToKey("commands");

	if (hKvConfig.GotoFirstSubKey(false))
	{
		do
		{
			hKvConfig.GetSectionName(sKey, sizeof sKey);
			hKvConfig.GetString(NULL_STRING, sBuf, sizeof(sBuf));
			int i = 0;
			do 
			{
				i = FindCharInString(sBuf, ';', true);
				if (i > -1)
				{
					sBuf[i] = 0;
				}

				i++;
				g_hCommands.SetString(sBuf[i], sKey);
				if(PushRegCommand(sBuf[i])) RegConsoleCmd(sBuf[i], CommandCB);
			} while (i != 0);
		}
		while(hKvConfig.GotoNextKey(false));
	}

	delete hKvConfig;
}

bool PushRegCommand(char[] sCommand)
{
	if(g_hCmdAlreadyRegs.FindString(sCommand) == -1)
	{
		g_hCmdAlreadyRegs.PushString(sCommand);

		return true;
	}
	else return false;
}

Action CommandCB(int iClient, int iArgs)
{
	char sCommand[32], sBuf[32], sArgs[512];

	GetCmdArg(0, sCommand, sizeof(sCommand));
	for(int i = 1; i <= iArgs; i++)
	{
		GetCmdArg(i, sBuf, sizeof(sBuf));
		Format(sArgs, sizeof(sArgs), "%s %s", sArgs, sBuf);
	}

	if(g_hCommands.GetString(sCommand, sBuf, sizeof(sBuf)))
	{
		if(iClient == 0)
		{
			ServerCommand("%s %s", sBuf, sArgs);
		}
		else ClientCommand(iClient, "%s %s", sBuf, sArgs);
	}

	return Plugin_Handled;
}

Action CmdReload(int iClient, int iArgs)
{
	LoadConfig();

	ReplyToCommand(iClient, "The plugin config was successfully reloaded");

	return Plugin_Handled;
}