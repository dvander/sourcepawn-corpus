#pragma semicolon 1

/*
 *	Admin Add Plugin
 *	by Master Xykon
 */

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Admin Add",
	author = "Master Xykon",
	description = "Add admins in-game with sm_admins_add",
	version = VERSION,
	url = "http://tf2tms.x10.mx/"
};

public OnPluginStart()
{
	CreateConVar("smaddadmin_version", VERSION, "SM Addadmin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_admins_add", Command_AddAdmin, ADMFLAG_RCON, "Adds an admin to admins.cfg");
}

public Action:Command_AddAdmin(client, args)
{
	if(args < 4)
	{
		ReplyToCommand(client, "[SM] Usage: sm_admins_add <name> <#steamid> <flags> <immunity>");
		return Plugin_Handled;
	}

	new String:szName[32], szTarget[64], String:szFlags[22], String:szImmunity[3];
	GetCmdArg(1, szName, sizeof(szName));
	GetCmdArg(2, szTarget, sizeof(szTarget));
	GetCmdArg(3, szFlags, sizeof(szFlags));
	GetCmdArg(4, szImmunity, sizeof(szImmunity));

	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins.cfg");
	
	new Handle:hFile = OpenFile(szFile, "at");
	WriteFileLine(hFile, "\"%s\"", szName);
	WriteFileLine(hFile, "{");
	WriteFileLine(hFile, "\"auth\"	\"steam\"");
	WriteFileLine(hFile, "\"identity\"	\"%s\"", szTarget);
	WriteFileLine(hFile, "\"flags\"	\"%s\"", szFlags);
	WriteFileLine(hFile, "\"immunity\"	\"%s\"", szImmunity);
	WriteFileLine(hFile, "}");
	
	CloseHandle(hFile);

	return Plugin_Handled;
}