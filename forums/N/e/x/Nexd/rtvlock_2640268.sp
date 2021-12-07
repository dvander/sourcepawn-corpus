#include <sourcemod>
#include <colors>

#define PLUGIN_NEV	"Simple plugin"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314456"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"
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
	AddCommandListener(Command_BlockRtv, "rtv");
	AddCommandListener(Command_BlockRtv, "rockthevote");
	AddCommandListener(Command_BlockRtv, "sm_rtv");
}

public void OnMapStart()
{
	AdminCount=0;
}

public OnClientDisconnect(client)
{
	if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		AdminCount--;
	}
}

public OnClientPostAdminCheck(client){
    
	if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		AdminCount++;
	}
}

Action Command_BlockRtv(int client, const String:command[], args)
{
	if (AdminCount >= 1) {
		return Plugin_Stop;
		CPrintToChat(client, "\x01[\x0BSystem\x01] You can't use RTV if there is atleast one \x03admin");
	} else {
		return Plugin_Continue;
	}
}