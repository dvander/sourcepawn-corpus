#include <sourcemod>

#define PLUGIN_VERSION "0.4.8"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hTeam = INVALID_HANDLE;
new Handle:g_hCvar = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Tidy Chat Light for CSS",
	author = "linux_lover",
	description = "Cleans up the chat area from team and cvar change messages",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_tidychat_version", PLUGIN_VERSION, "Tidy Chat Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hEnabled = CreateConVar("sm_tidychat_on", "1", "0/1 On/off");
	g_hTeam = CreateConVar("sm_tidychat_team", "1", "0/1 Tidy team join messages");
	g_hCvar = CreateConVar("sm_tidychat_cvar", "1", "0/1 Tidy cvar messages");

	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);

	}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hTeam))
	{
		if(!GetEventBool(event, "silent"))
		{
			SetEventBroadcast(event, true);
		}
	}

	return Plugin_Continue;
}

public Action:Event_Cvar(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnabled) && GetConVarInt(g_hCvar))
	{
		SetEventBroadcast(event, true);
	}

	return Plugin_Continue;
}