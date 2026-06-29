#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_mg", command_mg);
}
public Action command_mg(int client, int args)
{
	PrintToChatAll("%N \x0Fis a standart player");
	return Plugin_Handled;
}