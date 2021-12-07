#include <sourcemod>

#define PLUGIN_VERSION "1.0"

static 	const 	Float:	BLOCKTIME 							= 0.3;
static 	const	String:	PISTOLNETCLASS[]					= "CPistol";
		new 	bool:	g_bProhibitClientUse[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Block Pistol Spam",
	author = "Mr. Zero",
	description = "Prevents people from mass spawning pistols by using an exploit",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=121483"
}

public OnPluginStart()
{
	CreateConVar("l4d2_blockpistolspam_version",PLUGIN_VERSION,"Block Pistol Spam Version",FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("player_use",PlayerUse_Event);
}

public PlayerUse_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sBuffer[32];
	GetEntityNetClass(GetEventInt(event,"targetid"),sBuffer,sizeof(sBuffer));
	
	if (!StrEqual(PISTOLNETCLASS,sBuffer)){return;}
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	g_bProhibitClientUse[client] = true;
	CreateTimer(BLOCKTIME,BlockUse_Timer,client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!g_bProhibitClientUse[client]) return Plugin_Continue;
	if (!(buttons & IN_USE)) return Plugin_Continue;
	
	buttons = buttons^IN_USE;
	
	return Plugin_Continue;
}

public Action:BlockUse_Timer(Handle:timer,any:client)
{
	g_bProhibitClientUse[client] = false;
}