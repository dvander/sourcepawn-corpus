#pragma semicolon 1
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig
#include <sdktools>
#include <morecolors>

new Handle:g_hConsoleTag = INVALID_HANDLE;
new String:g_sConsoleTag[50];
new Handle:g_hConsoleTagColor = INVALID_HANDLE;
new String:g_sConsoleTagColor[7];
new Handle:g_hConsoleName = INVALID_HANDLE;
new String:g_sConsoleName[50];
new Handle:g_hConsoleNameColor = INVALID_HANDLE;
new String:g_sConsoleNameColor[7];
new Handle:g_hConsoleChatColor = INVALID_HANDLE;
new String:g_sConsoleChatColor[7];

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
	AutoExecConfig_SetFile("togcc");
	AutoExecConfig_CreateConVar("togcc_version", PLUGIN_VERSION, "TOGs Console Colors: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hConsoleTag = AutoExecConfig_CreateConVar("togcc_consoletag", "", "Tag to use for console.", FCVAR_NONE);
	GetConVarString(g_hConsoleTag, g_sConsoleTag, sizeof(g_sConsoleTag));
	HookConVarChange(g_hConsoleTag, OnCVarChange);
	
	g_hConsoleTagColor = AutoExecConfig_CreateConVar("togcc_tagcolor", "000000", "Hexadecimal value to use for console tag color (do not include #)", FCVAR_NONE);
	GetConVarString(g_hConsoleTagColor, g_sConsoleTagColor, sizeof(g_sConsoleTagColor));
	HookConVarChange(g_hConsoleTagColor, OnCVarChange);
	
	g_hConsoleName = AutoExecConfig_CreateConVar("togcc_consolename", "CONSOLE", "Name to use for console.", FCVAR_NONE);
	GetConVarString(g_hConsoleName, g_sConsoleName, sizeof(g_sConsoleName));
	HookConVarChange(g_hConsoleName, OnCVarChange);
	
	g_hConsoleNameColor = AutoExecConfig_CreateConVar("togcc_namecolor", "FF0000", "Hexadecimal value to use for console name color (do not include #)", FCVAR_NONE);
	GetConVarString(g_hConsoleNameColor, g_sConsoleNameColor, sizeof(g_sConsoleNameColor));
	HookConVarChange(g_hConsoleNameColor, OnCVarChange);
	
	g_hConsoleChatColor = AutoExecConfig_CreateConVar("togcc_chatcolor", "FF0000", "Hexadecimal value to use for console chat color (do not include #)", FCVAR_NONE);
	GetConVarString(g_hConsoleChatColor, g_sConsoleChatColor, sizeof(g_sConsoleChatColor));
	HookConVarChange(g_hConsoleChatColor, OnCVarChange);

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
	
	decl String:sMessage[512];
	GetCmdArgString(sMessage, 512);
	StripQuotes(sMessage);
	TrimString(sMessage);
	CPrintToChatAll("\x07%s%s\x07%s%s: \x07%s%s", g_sConsoleTagColor, g_sConsoleTag, g_sConsoleNameColor, g_sConsoleName, g_sConsoleChatColor, sMessage);
	PrintToServer("%s%s: %s", g_sConsoleTag, g_sConsoleName, sMessage);
	return Plugin_Handled;
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hConsoleTag)
	{
		GetConVarString(g_hConsoleTag, g_sConsoleTag, sizeof(g_sConsoleTag));
	}
	if(cvar == g_hConsoleTagColor)
	{
		GetConVarString(g_hConsoleTagColor, g_sConsoleTagColor, sizeof(g_sConsoleTagColor));
	}
	if(cvar == g_hConsoleName)
	{
		GetConVarString(g_hConsoleName, g_sConsoleName, sizeof(g_sConsoleName));
	}
	if(cvar == g_hConsoleNameColor)
	{
		GetConVarString(g_hConsoleNameColor, g_sConsoleNameColor, sizeof(g_sConsoleNameColor));
	}
	if(cvar == g_hConsoleChatColor)
	{
		GetConVarString(g_hConsoleChatColor, g_sConsoleChatColor, sizeof(g_sConsoleChatColor));
	}
}