#define PLUGIN_VERSION		"1.0"

#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MAX_COMMANDS        64
#define MAX_COMMAND_NAME    64

char g_sCommands[MAX_COMMANDS][MAX_COMMAND_NAME];
int g_iCommandsCount;

public Plugin myinfo =
{
	name = "[TEST] Block commands for players not alive.",
	author = "Mart",
	description = "Block commands for players not alive.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases"); 

	// Load commands
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/alive_commands.txt");

	if( FileExists(sPath) )
	{
		File hFile = OpenFile(sPath, "r");
		if( hFile != null )
		{
			while( g_iCommandsCount < MAX_COMMANDS && !hFile.EndOfFile() && hFile.ReadLine(g_sCommands[g_iCommandsCount], MAX_COMMAND_NAME))
			{
				TrimString(g_sCommands[g_iCommandsCount]);
				if( strlen(g_sCommands[g_iCommandsCount]) > 0 )
					g_iCommandsCount++;
			}
		}
		delete hFile;
	}
	
	for (int i = 0; i < MAX_COMMANDS; i++)
	{
		if (!StrEqual(g_sCommands[i], ""))
			AddCommandListener(GenericCmdBlock ,g_sCommands[i]);
	}	

}

public Action GenericCmdBlock(int client, const String:command[], int argc)
{
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] %t", "Target must be alive"); 
		return Plugin_Stop;
	}
	return Plugin_Handled;
}