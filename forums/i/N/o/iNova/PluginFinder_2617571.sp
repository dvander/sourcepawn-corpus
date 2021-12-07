#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_NAME		"Plugin Finder"
#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Nova",
	description	= "Find plugin(s) by command",
	version		= PLUGIN_VERSION,
	url			= "http://vk.com/spv34"
};

public OnPluginStart()
{
	RegAdminCmd("sm_find",		Command_FIND,	2, "Find plugin(s) by command");
	RegAdminCmd("sm_findex",	Command_FINDEX,	2, "Find plugin(s) by command (only plugin filename)");
	LogMessage("%s %s has been loaded successfully", PLUGIN_NAME, PLUGIN_VERSION);
}

public Action:Command_FIND(client, args)
{
	new Handle:hPluginIter = GetPluginIterator();
	decl String:sPluginFilename[256];
	decl String:sBuffer[10240];
	decl String:sCmdArg[128];
	GetCmdArg(1, sCmdArg, sizeof(sCmdArg));
	
	if (args)
	{
		if (CommandExists(sCmdArg))
		{
			while (MorePlugins(hPluginIter))
			{
				GetPluginFilename(ReadPlugin(hPluginIter), sPluginFilename, sizeof(sPluginFilename));
				ServerCommandEx(sBuffer, sizeof(sBuffer), "sm cmds %s", sPluginFilename);
				
				if (StrContains(sBuffer, sCmdArg, true) != -1)
				{
					Format(sPluginFilename, sizeof(sPluginFilename), "%s", sPluginFilename);
					break;
				}
				else
				{
					sBuffer[0] = '\0';
				}
			}
		}
		else
		{
			sBuffer[0] = '\0';
			ReplyToCommand(client, "[SM] Command \"%s\" not found.", sCmdArg);
		}
	}
	else if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_find <command>");
		return Plugin_Handled;
	}
	
	if (sBuffer[0] != '\0')
	{
		new Handle:hPluginFlename = FindPluginByFile(sPluginFilename);
		decl String:sPluginName[256];
		GetPluginInfo(hPluginFlename, PlInfo_Name, sPluginName, sizeof(sPluginName));
		ReplyToCommand(client, "[SM] Command by plugin %s (%s).", sPluginName, sPluginFilename);
	}
	
	CloseHandle(hPluginIter);
	return Plugin_Handled;
}

public Action:Command_FINDEX(client, args)
{
	new Handle:hPluginIter = GetPluginIterator();
	decl String:sPluginFilename[256];
	decl String:sBuffer[10240];
	decl String:sPlugin[256];
	decl String:sCmdArg[128];
	GetCmdArg(1, sCmdArg, sizeof(sCmdArg));
	
	if (args)
	{
		if (CommandExists(sCmdArg))
		{
			while (MorePlugins(hPluginIter))
			{
				GetPluginFilename(ReadPlugin(hPluginIter), sPluginFilename, sizeof(sPluginFilename));
				ServerCommandEx(sBuffer, sizeof(sBuffer), "sm cmds %s", sPluginFilename);
				
				if (StrContains(sBuffer, sCmdArg, true) != -1)
				{
					Format(sPlugin, sizeof(sPlugin), "%s", sPluginFilename);
					break;
				}
				else
				{
					sBuffer[0] = '\0';
				}
			}
		}
		else
		{
			sBuffer[0] = '\0';
		}
	}
	else if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findex <command>");
		return Plugin_Handled;
	}
	
	if (sBuffer[0] != '\0')
		ReplyToCommand(client, "%s", sPlugin);
	
	CloseHandle(hPluginIter);
	return Plugin_Handled;
}