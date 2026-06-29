#include <sourcemod>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NEV	"Simple plugin"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314456"
#define PLUGIN_AUTHOR	"Nexd, Cruze"
#define PLUGIN_VERSION	"1.1"
#define PLUGIN_URL	"steelclouds.clans.hu"

int AdminCount = 0;

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
	AddCommandListener(Command_BlockRtv, "say rtv");
	AddCommandListener(Command_BlockRtv, "say rockthevote");
	AddCommandListener(Command_BlockRtv, "say_team rtv");
	AddCommandListener(Command_BlockRtv, "say_team rockthevote");
	AddCommandListener(Command_BlockRtv, "sm_rtv");
	AddCommandListener(Command_BlockRtv, "sm_rockthevote");
}

public void OnMapStart()
{
	AdminCount = 0;
}

public void OnClientDisconnect(int client)
{
	if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		AdminCount--;
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		AdminCount++;
	}
}

public Action Command_BlockRtv(int client, char[] command, int args)
{
	if (AdminCount >= 1)
	{
		CPrintToChat(client, "\x01[\x0BSystem\x01] You can't use RTV if there is atleast one \x03admin");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}