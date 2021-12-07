#pragma semicolon 1

/*
 *	SM Addadmin
 *	by MaTTe (mateo10)
 *  Modded by Revolutzia
 */

#define VERSION "1.1"

public Plugin:myinfo = 
{
	name = "SM Add Admin & Add Group",
	author = "MaTTe modded by Revolutzia",
	description = "Add an admin during the game with sm_addadmin or add an admin to a group with sm_admintogroup",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_addadmin", Command_AddAdmin, ADMFLAG_RCON, "Adds an admin to admins_simple.ini");
	RegAdminCmd("sm_admintogroup", Command_AddAdminToGroup, ADMFLAG_RCON, "Adds an admin to a group in admins_simple.ini");
}

public Action:Command_AddAdmin(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addadmin <name or #userid> <flags> <password>");
		return Plugin_Handled;
	}
	decl String:buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client, buffer, true, false);
	decl String:steamid[64];
	GetClientAuthString(target, steamid, sizeof(steamid));
	new String:szFlags[20], String:szPassword[32];
	GetCmdArg(2, szFlags, sizeof(szFlags));
	GetCmdArg(3, szPassword, sizeof(szPassword));

	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"%s\" \"%s\"", steamid, szFlags, szPassword);

	CloseHandle(hFile);

	return Plugin_Handled;
}

public Action:Command_AddAdminToGroup(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_admintogroup <name or #userid> <group> <password>");
		return Plugin_Handled;
	}
	
	decl String:buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client, buffer, true, false);
	decl String:steamid[64];
	GetClientAuthString(target, steamid, sizeof(steamid));
	new String:szFlags[20], String:szPassword[32];
	GetCmdArg(2, szFlags, sizeof(szFlags));
	GetCmdArg(3, szPassword, sizeof(szPassword));
	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" @%s \"%s\"", steamid, szFlags, szPassword);

	CloseHandle(hFile);

	return Plugin_Handled;
}