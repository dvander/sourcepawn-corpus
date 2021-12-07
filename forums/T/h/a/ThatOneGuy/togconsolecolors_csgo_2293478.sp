#pragma semicolon 1
#define PLUGIN_VERSION "1.2_csgo"

#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig
#include <sdktools>

new Handle:g_hConsoleName = INVALID_HANDLE;
new String:g_sConsoleName[50];

public Plugin:myinfo =
{
	name = "TOGs Console Colors",
	author = "That One Guy",
	description = "Colors chat output from CONSOLE",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togconsolecolors");
	AutoExecConfig_CreateConVar("togcc_csgo_version", PLUGIN_VERSION, "TOGs Console Colors (CS:GO): Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hConsoleName = AutoExecConfig_CreateConVar("togcc_csgo_consolename", "CONSOLE", "Name to use for console.", FCVAR_NONE);
	GetConVarString(g_hConsoleName, g_sConsoleName, sizeof(g_sConsoleName));
	HookConVarChange(g_hConsoleName, OnCVarChange);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public Action:Command_Say(client, String:Command[], ArgC)
{
	if(client)
	{
		return Plugin_Continue;
	}
	
	decl String:sMessage[256];
	GetCmdArgString(sMessage, sizeof(sMessage));
	StripQuotes(sMessage);
	TrimString(sMessage);
	PrintToChatAll(" \x0E%s: %s", g_sConsoleName, sMessage);
	PrintToServer("%s: %s", g_sConsoleName, sMessage);
	return Plugin_Handled;
}

public OnCVarChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if(hCVar == g_hConsoleName)
	{
		GetConVarString(g_hConsoleName, g_sConsoleName, sizeof(g_sConsoleName));
	}
}