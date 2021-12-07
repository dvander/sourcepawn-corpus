#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.1"

new Handle:Enable;
new bool:Allow[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "[L4D & L4D2] Survivor Crawl Pounce Fixes",
	author = "McFlurry",
	description = "Disallows crawling of survivor while being pounced and while being revived",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{
		SetFailState("Plugin supports Left 4 Dead series only.");
	}
	CreateConVar("l4d_crawl_fix_version", PLUGIN_VERSION, "Version of survivor crawl fix", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	Enable = CreateConVar("l4d_crawl_fix_enable", "1", "Enables Crawl Fixes", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d2_crawl_fix");
	HookEvent("lunge_pounce", PounceStart);
	HookEvent("pounce_end", PounceEnd);
	HookEvent("revive_begin", BRevive);
	HookEvent("revive_end", ERevive);
	HookEvent("revive_success", SRevive);
}

public OnMapStart()
{
	for(new i=1;i<=MaxClients;i++)
	{
		Allow[i] = false;
	}
}	

public Action:PounceStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	Allow[client] = true;
}	

public Action:PounceEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	Allow[client] = false;
}

public Action:BRevive(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Allow[client] = true;
}

public Action:ERevive(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Allow[client] = false;
}

public Action:SRevive(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Allow[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(Allow[client] && GetEntProp(client, Prop_Send, "m_isIncapacitated") && buttons & IN_FORWARD && GetConVarInt(Enable) == 1) return Plugin_Handled;
	return Plugin_Continue;
}	