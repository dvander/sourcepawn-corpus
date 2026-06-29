#include <sourcemod>

#define PLUGIN_VERSION "1.0-lite"
#define BLOCK_TIME 5

public Plugin:myinfo = 
{
	name = "Radio Spam Block",
	author = "exvel,tigerox",
	description = "Blocking players from radio spam.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=662933"
}

new last_radio_use[MAXPLAYERS+1];
new g_block_time = BLOCK_TIME;


public OnPluginStart()
{
	CreateConVar("sm_radio_spam_block_version", PLUGIN_VERSION, "Radio Spam Block Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	AddCommandListener(RestrictRadio, "compliment");
	AddCommandListener(RestrictRadio, "coverme");
	AddCommandListener(RestrictRadio, "cheer");
	AddCommandListener(RestrictRadio, "takepoint");
	AddCommandListener(RestrictRadio, "holdpos");
	AddCommandListener(RestrictRadio, "regroup");
	AddCommandListener(RestrictRadio, "followme");
	AddCommandListener(RestrictRadio, "takingfire");
	AddCommandListener(RestrictRadio, "thanks");
	AddCommandListener(RestrictRadio, "go");
	AddCommandListener(RestrictRadio, "fallback");
	AddCommandListener(RestrictRadio, "sticktog");
	AddCommandListener(RestrictRadio, "getinpos");
	AddCommandListener(RestrictRadio, "stormfront");
	AddCommandListener(RestrictRadio, "report");
	AddCommandListener(RestrictRadio, "roger");
	AddCommandListener(RestrictRadio, "enemyspot");
	AddCommandListener(RestrictRadio, "needbackup");
	AddCommandListener(RestrictRadio, "sectorclear");
	AddCommandListener(RestrictRadio, "inposition");
	AddCommandListener(RestrictRadio, "reportingin");
	AddCommandListener(RestrictRadio, "getout");
	AddCommandListener(RestrictRadio, "negative");
	AddCommandListener(RestrictRadio, "enemydown");
}

public OnClientConnected(client)
{
	last_radio_use[client] = 0;
}

public Action:RestrictRadio(client, const String:command[], argc)
{
	if(!IsFakeClient(client))
	{
		new time = GetTime() - last_radio_use[client];
		if ( time >= g_block_time )
		{
			last_radio_use[client] = GetTime();
		}
		else
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}