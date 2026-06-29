#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Plugin Command Info",
	author = "Sheepdude",
	description = "Reports the plugins to which a SourceMod command is registered.",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new Handle:h_PluginIterator;
new String:g_CommandList[128][48][64];
new g_PluginCount;

public OnPluginStart()
{
	CreateConVar("sm_cmdinfo_version", PLUGIN_VERSION, "[SM] CommandInfo plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	RegConsoleCmd("sm_cmdinfo", CmdCommandInfo);
}

public OnAllPluginsLoaded()
{
	PrintToServer("----------------|       [CommandInfo] Searching      |---------------");
	IteratePlugins();
	PopulateCommands();
	PrintToServer("----------------|       [CommandInfo] Finished       |---------------");
}

IteratePlugins()
{
	g_PluginCount = 0;
	h_PluginIterator = GetPluginIterator();
	while(MorePlugins(h_PluginIterator))
	{
		new Handle:h_CurrentPlugin = ReadPlugin(h_PluginIterator);
		if(h_CurrentPlugin != INVALID_HANDLE)
		{
			GetPluginFilename(h_CurrentPlugin, g_CommandList[g_PluginCount][0], sizeof(g_CommandList[][]));
			g_PluginCount++;
			CloseHandle(h_CurrentPlugin);
		}
	}
	CloseHandle(h_PluginIterator);
}

PopulateCommands()
{
	decl String:buffer[3072];
	decl String:tempcommands[48][64];
	for(new i = 0; i < g_PluginCount; i++)
	{
		ServerCommandEx(buffer, sizeof(buffer), "sm cmds %s", g_CommandList[i][0]);
		new stringcount = ExplodeString(buffer, "\n  ", tempcommands, sizeof(tempcommands), sizeof(tempcommands[]));
		new k = 1;
		while(k <= stringcount)
		{
			SplitString(tempcommands[k], " ", g_CommandList[i][k], sizeof(g_CommandList[][]));
			k++;
		}
	}
}

public Action:CmdCommandInfo(client, args)
{
	new bool:found = false;
	new String:argstring[64];
	GetCmdArg(1, argstring, sizeof(argstring));
	ReplyToCommand(client, "\n[SM] %s is registered to:", argstring);
	for(new i = 0; i < sizeof(g_CommandList); i++)
	{
		for(new j = 1; j < sizeof(g_CommandList[]); j++)
		{
			if(StrEqual(g_CommandList[i][j], argstring))
			{
				ReplyToCommand(client, "  %s", g_CommandList[i][0]);
				found = true;
				break;
			}
		}
	}
	if(!found)
		ReplyToCommand(client, "  %s not found", argstring);
}