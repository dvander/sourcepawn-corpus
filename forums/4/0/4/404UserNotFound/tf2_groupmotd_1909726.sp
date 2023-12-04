#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION		"1.0"

new Handle:ConVarGroupName = INVALID_HANDLE;
new String:g_strGroupName[255];

public Plugin:myinfo = {
	name		= "[TF2] Group MOTD",
	author	  = "abrandnewday",
	description = "Adds in a !group command to bring up your Steam Group in the MOTD window!",
	version	 = PLUGIN_VERSION,
	url		 = "https://forums.alliedmods.net/member.php?u=165383"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "[SM] This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_groupmotd_version", PLUGIN_VERSION, "Group MOTD Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	ConVarGroupName = CreateConVar("sm_groupmotd_groupname", "sourcemod", "Insert your group name here. Default is alliedmodders-community, but please change this to your own group name.", FCVAR_PLUGIN);
	GetConVarString(ConVarGroupName, g_strGroupName, sizeof(g_strGroupName));
	HookConVarChange(ConVarGroupName, ConVarChanged);
	
	RegConsoleCmd("sm_group", Command_Group, "Usage: sm_group");
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    GetConVarString(cvar, g_strGroupName, sizeof(g_strGroupName));
}  

public Action:Command_Group(client, args)
{
	decl String:url[256];
	Format(url, sizeof(url), "http://www.steamcommunity.com/groups/%s", g_strGroupName);
	new Handle:Kv = CreateKeyValues("data");
	KvSetString(Kv, "title", "");
	KvSetString(Kv, "type", "2");
	KvSetString(Kv, "msg", url);
	KvSetNum(Kv, "customsvr", 1);
	ShowVGUIPanel(client, "info", Kv);
	CloseHandle(Kv);
	return Plugin_Handled;
}