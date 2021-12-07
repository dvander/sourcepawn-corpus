#pragma semicolon 1

#include <sourcemod>

new Handle:sv_password;

public Plugin:myinfo = 
{
	name = "Random Server Password",
	author = "Xsinthis`",
	description = "Randomly generates a server password",
	version = "1.0",
	url = "http://skulshockcommunity.com"
}

public OnPluginStart()
{
	RegAdminCmd("generate_password", GeneratePassword, ADMFLAG_ROOT, "Randomly generates a password for the server");
	sv_password = FindConVar("sv_password");
}

public Action:GeneratePassword(client, args)
{
	new String:password[4];
	new pw_int = GetRandomInt(100, 999);
	IntToString(pw_int, password, 4);
	SetConVarString(sv_password, password);
    
	PrintToChatAll("Server password changed to:\x04 %s", password);
	LogMessage("Server password changed to: %s", password);
}