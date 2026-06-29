#pragma semicolon 1

/*
 *	SM Addadmin
 *	by MaTTe (mateo10)
 */

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "SM Addadmin",
	author = "MaTTe",
	description = "Add an admin during the game with sm_addadmin",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("smaddadmin_version", VERSION, "SM Addadmin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_addadmin", Command_AddAdmin, ADMFLAG_RCON, "Adds an admin to admins_simple.ini");
}

public Action:Command_AddAdmin(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addadmin <name or #userid> <flags> <password>");
		return Plugin_Handled;
	}

	new String:szTarget[64], String:szFlags[20], String:szPassword[32];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	GetCmdArg(2, szFlags, sizeof(szFlags));
	GetCmdArg(3, szPassword, sizeof(szPassword));

	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"%s\" \"%s\"", szTarget, szFlags, szPassword);

	CloseHandle(hFile);

	return Plugin_Handled;
}