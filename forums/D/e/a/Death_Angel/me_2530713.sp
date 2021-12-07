#pragma semicolon 1

#define PLUGIN_AUTHOR "TheDarkSid3r"
#define PLUGIN_VERSION "1.40"
#define UPDATE_URL	"https://github.com/Endernation/-TF2-me-Plugin/updates.txt"

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <updater>

Handle g_CUsername;
Handle g_CText;
Handle g_ServerName;

public Plugin myinfo = 
{
	name = "/me Plugin",
	author = PLUGIN_AUTHOR,
	description = "Allows clients to use /me",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	LogMessage("---Initializing me.smx(v%s)---", PLUGIN_VERSION);
	
	LogMessage("---Initializing Commands(me.smx)---");
	RegAdminCmd("sm_me", Command_ME, ADMFLAG_CHAT, "Use /me");
	RegAdminCmd("sm_me_action",Command_MEAction, ADMFLAG_CHAT, "Use /me_action");
	
	LogMessage("---Initializing ConVars(me.smx)---");
	CreateConVar("me_version", PLUGIN_VERSION, "Version for the /me plugin!Do not change!");
	CreateConVar("me_color_username", "darkgreen", "Color of the username printed!");
	CreateConVar("me_color_texts", "aqua", "Color of the text printed!");
	CreateConVar("me_server_name", "me Server", "Name of the server!");
	
	g_CUsername = FindConVar("me_color_username");
	g_CText = FindConVar("me_color_texts");
	g_ServerName = FindConVar("me_server_name");
	
	LogMessage("---Initializing Libraries(me.smx)---");
	/**if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}*/
	
	LogMessage("---Initialization Complete!---");
}

public OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnPluginEnd()
{
	LogMessage("---Disabling me.smx(v%s)---", PLUGIN_VERSION);
}

public OnClientConnected(int client)
{
	char clientName[256];
	char sString[256];
	char colorUsername[255];
	char colorText[255];
	char serverName[255];
	
	GetConVarString(g_CUsername, colorUsername, sizeof(colorUsername));
	GetConVarString(g_CText, colorText, sizeof(colorText));
	GetConVarString(g_ServerName, serverName, sizeof(serverName));
	GetClientName(client, clientName, sizeof(clientName));
	
	Format(sString, sizeof(sString), "{%s}%s{default} {%s}has connected to %s!{default}", colorUsername, clientName, colorText, serverName);
	CPrintToChatAll(sString);
}

public OnClientDisconnect(int client)
{
	char clientName[256];
	char sString[256];
	char colorUsername[255];
	char colorText[255];
	char serverName[255];
	
	GetConVarString(g_CUsername, colorUsername, sizeof(colorUsername));
	GetConVarString(g_CText, colorText, sizeof(colorText));
	GetConVarString(g_ServerName, serverName, sizeof(serverName));
	GetClientName(client, clientName, sizeof(clientName));
	
	Format(sString, sizeof(sString), "{%s}%s{default} {%s}has disconnected from %s!{default}", colorUsername, clientName, colorText, serverName);
	CPrintToChatAll(sString);
}

public Action Command_MEAction(int client, int args)
{
	char g_colorUsername[255];
	char g_colorText[255];
	char coloredText[255];
	char coloredName[255];
	
	GetConVarString(g_CUsername, g_colorUsername, sizeof(g_colorUsername));
	GetConVarString(g_CText, g_colorText, sizeof(g_colorText));
	
	if (args <= 0) 
	{
		CPrintToChat(client, "{gold}[{cyan}me.smx{gold}]{red}You need to specify at least 1 argument!{default}");
	} 
	else
	{
		char inString[256];
		char outString[256];
		char clientName[256];

		GetCmdArgString(inString, sizeof(inString));
		GetClientName(client, clientName, sizeof(clientName));
	
		Format(coloredText, sizeof(coloredText), "{%s}", g_colorText);
		Format(coloredName, sizeof(coloredName), "{%s}", g_colorUsername);
		Format(outString, sizeof(outString), "%s%s %s%s{default}", coloredName, clientName, coloredText, inString);
	
		CPrintToChatAll(outString);
	}
	return Plugin_Handled;
}

public Action Command_ME(int client, int args)
{
	char g_colorUsername[255];
	char g_colorText[255];
	char coloredText[255];
	char coloredName[255];
	
	GetConVarString(g_CUsername, g_colorUsername, sizeof(g_colorUsername));
	GetConVarString(g_CText, g_colorText, sizeof(g_colorText));
	
	if (args <= 0) 
	{
		CPrintToChat(client, "{gold}[{cyan}me.smx{gold}]{red}You need to specify at least 1 argument!{default}");
	} 
	else
	{
		char inString[256];
		char outString[256];
		char clientName[256];

		GetCmdArgString(inString, sizeof(inString));
		GetClientName(client, clientName, sizeof(clientName));
	
		Format(coloredText, sizeof(coloredText), "{%s}", g_colorText);
		Format(coloredName, sizeof(coloredName), "{%s}", g_colorUsername);
		Format(outString, sizeof(outString), "%s%s{default}:%s%s{default}", coloredName, clientName, coloredText, inString);
	
		CPrintToChatAll(outString);
	}
	return Plugin_Handled;
}