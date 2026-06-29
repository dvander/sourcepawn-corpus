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

	new String:arg[120], String:Entry[3][64];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", Entry, 3, 64);

	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"%s\" \"%s\"", Entry[0], Entry[1], Entry[2]); // target, flags, password

	CloseHandle(hFile);

	return Plugin_Handled;
}