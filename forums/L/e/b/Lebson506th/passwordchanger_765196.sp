#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "0.0.1"

new Handle:sv_password = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Password Changer",
	author = "Lebson506th",
	description = "Change server password without sm_cvar",
	version = PLUGIN_VERSION,
	url = "http://www.506th-pir.org"
};

public OnPluginStart() {
	CreateConVar("sm_password_version", PLUGIN_VERSION, "Password Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_password", Command_Password, ADMFLAG_SLAY, "sm_password <password>");
	
	sv_password = FindConVar("sv_password");
	
	if(sv_password == INVALID_HANDLE)
		SetFailState("[SM sv_password not found. Plugin failed to load.");
}

public Action:Command_Password(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_password <password>");
		return Plugin_Handled;
	}

	new String:password[64];
	GetCmdArg(1, password, sizeof(password));

	SetConVarString(sv_password, password); 

	return Plugin_Handled;
}