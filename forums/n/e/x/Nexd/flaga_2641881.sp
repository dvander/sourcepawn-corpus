#include <sourcemod>

#define PLUGIN_NEV	"Kick players without flag A"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314716"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_URL	"steelclouds.clans.hu"

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
}

public OnClientConnectFull(client)
{
	if (!CheckCommandAccess(client, "sm_reservation", ADMFLAG_RESERVATION))
	{
		KickClient(client, "Sorry, but you are not allowed to connect.");
	}
}