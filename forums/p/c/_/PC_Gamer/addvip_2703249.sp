#pragma semicolon 1

/*
*	Note: Based on the original SM Addadmin plugin
*	by MaTTe (mateo10)
*  Modded by Revolutzia, edited by PC Gamer
*/

#define VERSION "1.2"

public Plugin:myinfo = 
{
	name = "SM Add VIP",
	author = "Code from MaTTe and Revolutzia, edited by PC Gamer",
	description = "Add a VIP during the game with sm_addvip",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_addvip", Command_Addvip, ADMFLAG_SLAY, "Adds an admin to admins_simple.ini");
}

public Action:Command_Addvip(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addvip <name or #userid>");
		return Plugin_Handled;
	}
	decl String:buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client, buffer, true, false);
	decl String:steamid[64];
	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
	
	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"5:a\"", steamid);

	CloseHandle(hFile);

	return Plugin_Handled;
}