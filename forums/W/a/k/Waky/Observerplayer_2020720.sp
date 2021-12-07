#include <sourcemod>
#include <colors>
#include <smlib>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "www.area-community.net"
#define MAX_FILE_LEN 256

new g_client = 0;
new g_target = 0;

public Plugin:myinfo = 
{
	name = "[AoG-Admin]Oberserver Player",
	author = "Waky www.area-community.net",
	description = "<- Description ->",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	RegAdminCmd("sm_observe",ADMIN_Oberserve,ADMFLAG_KICK);
	RegAdminCmd("sm_unobserve", ADMIN_UNOBSERVE, ADMFLAG_KICK);
	LoadTranslations("observe.phrases");
}
public Action:ADMIN_Oberserve(client ,args)
{
	g_client = client;
	decl String:buffer[100];
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client, buffer, true);
	g_target = target;
	CPrintToChat(client,"%T","OBSERVING",LANG_SERVER, target);
	Client_SetObserverTarget(client, target, true);
}
public Action:ADMIN_UNOBSERVE(client, args)
{
	CPrintToChat(g_client,"%T","UNOBSERVE",LANG_SERVER,g_target);
	g_client = 0;
	g_target = INVALID_STRING_INDEX;
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == g_target)
	{
		Client_SetObserverTarget(g_client, client, true);
		return Plugin_Continue;
	}
	else return Plugin_Handled;
}
public OnClientDisconnect(client)
{
	if(client == g_target)
	{
		ADMIN_UNOBSERVE(g_client, g_target);
	}
}
