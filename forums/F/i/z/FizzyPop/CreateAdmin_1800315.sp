#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo =
{
	name = "Add Admins SIMPLE",
	author = "FizzyPop",
	description = "MY First Plugin For Sourcemod",
	version = "1.01",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	RegAdminCmd("sm_createadmin", Command_Create, ADMFLAG_RCON);
}

public Action:Command_Create(client, args)
{
	if(args < 2){
		ReplyToCommand(client, "[SM] Usage: sm_createadmin <Steamid> <Flags>");
		return Plugin_Handled;
	}
	new String:szName[32], String:szFlags[22];
	GetCmdArg(1, szName, sizeof(szName));
	GetCmdArg(2, szFlags, sizeof(szFlags));
	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");
	new Handle:hFile = OpenFile(szFile, "a");
	WriteFileLine(hFile, "\n%s \"%s\"", szName, szFlags);
	CloseHandle(hFile);
	PerformReloadAdmins(client);
	return Plugin_Handled;
}

PerformReloadAdmins(client)
{
	DumpAdminCache(AdminCache_Groups, true);
	DumpAdminCache(AdminCache_Overrides, true);
	LogAction(client, -1, "\"%L\" refreshed the admin cache.", client);
	ReplyToCommand(client, "[SM] %t", "Admin Info Reloaded");
}