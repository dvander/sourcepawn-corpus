// Includes
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

// Plugin Info
#define PLUGIN_NAME "consolechatfilter"
#define PLUGIN_AUTHOR "Jason Bourne"
#define PLUGIN_DESC "Blocks annoying console chat from maps"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_SITE "www.immersion-networks.com"
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_SITE
}

// Handles Define
new Handle:sm_ccf_enable = INVALID_HANDLE;

// Executed on plugin start
public OnPluginStart()
{
	// Which commands to listen for

	HookEvent("player_chat", Event_Chat, EventHookMode_Pre);
	
	// Create some ConVars
	CreateConVar("sm_ccf_version", PLUGIN_VERSION, "Console Chat Filter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_ccf_enable = CreateConVar("sm_ccf_enable", "1", "Enable Console Chat Filter. [0 = FALSE, 1 = TRUE]");
	
}

// What todo when someone talks
public Event_Chat( Handle:Event_Chat, const String:Chat_Name[], bool:Death_Broadcast )
{
	
	if(GetConVarBool(sm_ccf_enable)) // if plugin is enabled 
	{
		new clientint = GetEventInt(Event_Chat,"userid");
		new client= GetClientOfUserId(clientint);
		if (client==0) // is console talking ?
		{
			return Plugin_Stop; // STOP THE SPAM
		} 
	}
	
	return Plugin_Continue;
	
}