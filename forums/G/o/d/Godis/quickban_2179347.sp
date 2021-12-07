#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME			"QuickBan"
#define PLUGIN_AUTHOR		"Godis"
#define PLUGIN_DESCRIPTION	"Ban cheaters/hackers quickly"
#define PLUGIN_VERSION		"1.2"
#define PLUGIN_URL			"www.sourcemod.net"

ConVar g_BanDuration = null;
ConVar g_BanReason = null;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author	 = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	CreateConVar("sm_quickban_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	g_BanDuration = CreateConVar("sm_quickban_duration", "0", "Ban duration");
	g_BanReason = CreateConVar("sm_quickban_reason", "General exploit", "Ban reason");
	
	RegAdminCmd("sm_quickban", Cmd_QuickBan, ADMFLAG_BAN, "sm_quickban <#userid|name>");
	RegAdminCmd("sm_qb", Cmd_QuickBan, ADMFLAG_BAN, "sm_qb <#userid|name>");
}

public Action Cmd_QuickBan(int client, int args)
{
	char cmd[32];
	GetCmdArg(0, cmd, sizeof(cmd));
	
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: %s <#userid|name>", cmd);
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	int target = FindTarget(client, arg);
	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	char buffer[64];
	g_BanReason.GetString(buffer, sizeof(buffer));
	
	FakeClientCommand(client, "sm_ban #%d %d \"%s\"", GetClientUserId(target), g_BanDuration.IntValue, buffer);
	return Plugin_Handled;
}
