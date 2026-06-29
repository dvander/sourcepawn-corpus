#pragma semicolon 1
#pragma newdecls required

/*
*	Note: Based on the original SM Addadmin plugin
*	by MaTTe (mateo10)
*  Modded by Revolutzia, edited by PC Gamer
*/

#define VERSION "1.6"

public Plugin myinfo = 
{
	name = "SM Make VIP",
	author = "Code from MaTTe and Revolutzia, edited by PC Gamer",
	description = "Add a VIP during the game with sm_makevip",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_makevip", Command_Addvip, ADMFLAG_SLAY, "Adds an admin to admins_simple.ini");	
}

public Action Command_Addvip(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_makevip <name or #userid>");
		return Plugin_Handled;
	}
	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	int target = FindTarget(client, buffer, true, false);
	char steamid[64];
	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
	
	char szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	Handle hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"5:a\"  //%N", steamid, target);

	CloseHandle(hFile);

	return Plugin_Handled;
}