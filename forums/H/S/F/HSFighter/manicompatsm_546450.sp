#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "ManiCompatSM",
	author = "red! / HSFighter",
	description = "Execute SM-Menu on ma_admin and admin",
	version = PLUGIN_VERSION,
	url = "http://www.forum.sourceserver.info"
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
	FakeClientCommand(client, "sm_admin");
	//ClientCommand(client, "sm_admin");
	return Plugin_Handled;
}


