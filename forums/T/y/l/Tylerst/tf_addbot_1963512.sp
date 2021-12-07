#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "TF2 AddBot",
	author = "Tylerst",
	description = "Spawn a Bot",
	version = PLUGIN_VERSION,
	url = "None"
};


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new Handle:cvar_cheats = INVALID_HANDLE;

public OnPluginStart()
{	
	RegAdminCmd("sm_addbot", Command_Botspawn, ADMFLAG_ROOT, "Add a bot Usage: sm_addbot <name> <team> <class>");
	cvar_cheats = FindConVar("sv_cheats");
}

public Action:Command_Botspawn(client, args)
{
	if(args != 3) ReplyToCommand(client, "[SM] Usage: sm_addbot <name> <team> <class>");
	decl String:name[32], String:team[32], String:class[32];
	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, team, sizeof(team));
	GetCmdArg(3, class, sizeof(class));
	SetConVarFlags(cvar_cheats, FCVAR_NONE);
	SetConVarInt(cvar_cheats, 1);
	ServerCommand("bot -name %s -team %s -class %s", name, team, class);
	CreateTimer(0.1, ResetCheats);
	return Plugin_Handled;
}

public Action:ResetCheats(Handle:timer)
{
	SetConVarInt(cvar_cheats, 0);
	SetConVarFlags(cvar_cheats, FCVAR_NOTIFY|FCVAR_REPLICATED);
}

