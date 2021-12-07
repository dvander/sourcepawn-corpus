
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define Version "1.1"

public Plugin:myinfo = 
{
	name = "Add Admin",
	author = "amber.sourcepedia",
	description = "add admin in-game",
	version = Version,
	url = "http://cafe.naver.com/sourcemulti"
};

public OnPluginStart()
{
	CreateConVar("sm_admin_add_version", Version, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_add_admin", Command_AddAdmin, ADMFLAG_RCON);
}

public Action:Command_AddAdmin(client, args)
{
	if(args < 2){
		ReplyToCommand(client, "[SM] Usage: sm_add_admin <Steamid> <Flags>");
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
	ReplyToCommand(client, "[SM] %t", "Admin cache refreshed");
}