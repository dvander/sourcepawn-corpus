#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "ManiCompat",
	author = "red!",
	description = "Execute supermenu on ma_admin and admin",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
};

public OnPluginStart(){
  
  CreateConVar("manicompat_version", PLUGIN_VERSION, "Version of ManiCompat", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
  RegConsoleCmd("ma_admin", ma_admin);
  RegConsoleCmd("admin", ma_admin);

}

public OnPluginEnd(){
}


 
public Action:ma_admin(client, args)
{
	FakeClientCommand(client, "sm_super");
	//ClientCommand(client, "sm_super");
	return Plugin_Handled;
}


