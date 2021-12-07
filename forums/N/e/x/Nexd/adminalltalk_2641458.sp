#include <sourcemod>
#include <colors>

#define PLUGIN_NEV	"admin alltalk"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314650"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_URL	"steelclouds.clans.hu"

Handle gh_AdminAlltalk = INVALID_HANDLE;
bool g_ToggleAlltalk[MAXPLAYERS+1] = false;


public Plugin myinfo = 
{
	name = PLUGIN_NEV,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);
	RegConsoleCmd("sm_aat", CMD_AAT, "Admin alltalk.");
	gh_AdminAlltalk = FindConVar("sv_full_alltalk");
}

public Action CMD_AAT(int client, int args)
{
	if(!IsPlayerAlive(client) && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC) && !g_ToggleAlltalk[client])
	{
		SendConVarValue(client, gh_AdminAlltalk, "1");
		CPrintToChat(client, "\x01[\x0BSystem\x01] You have enabled the alltalk!");
		g_ToggleAlltalk[client] = true;
	}
	else if(!IsPlayerAlive(client) && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		SendConVarValue(client, gh_AdminAlltalk, "0");
		CPrintToChat(client, "\x01[\x0BSystem\x01] You have disabled the alltalk!");
		g_ToggleAlltalk[client] = false;
	}
	else if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC) && IsPlayerAlive(client))
	{
		CPrintToChat(client, "\x01[\x0BSystem\x01] You have to be dead to use this command");
	}
	else if (!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		CPrintToChat(client, "\x01[\x0BSystem\x01] You need to be ADMIN!");
	}
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	new i = GetClientOfUserId(GetEventInt(event, "userid"));
	if (CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
	{
		SendConVarValue(i, gh_AdminAlltalk, "0");
		g_ToggleAlltalk[i] = false;
	}
}