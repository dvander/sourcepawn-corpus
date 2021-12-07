#pragma semicolon 1

#include <sourcemod>

new Handle:sv_password;
new String:listOfChar[] = "aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ0123456789";

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
	decl String:password[26];
    
	for(new i = 1; i <= 26; i++)
	{
        new randomInt = GetRandomInt(0, 62);
        StrCat(password, sizeof(password), listOfChar[randomInt]);
	}
    
	SetConVarString(sv_password, password);
    
	PrintToChatAll("Server password changed to: %s", password);
	LogMessage("Server password changed to: %s", password);
}