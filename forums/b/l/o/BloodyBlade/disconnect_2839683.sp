/**
 * disconnect.sp - atom0s (c) 2010 [atom0s@live.com]
 * =================================================================
 * 
 * Disconnect message removal.
 * 
 * Removes a users disconnection message.
 * 
 * =================================================================
 * 
 */
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar g_DisconnectMessageEnable, g_DisconnectMessage;
bool bHooked = false;
char cMessage[64];

public Plugin myinfo = 
{
	name 		= "Disconnect Message Removal",
	author 		= "atom0s(Edit. by BloodyBlade)",
	description = "Blocks disconnection messages.",
	version 	= PLUGIN_VERSION,
	url 		= "N/A"
};

public void OnPluginStart()
{
	CreateConVar("disconnectmsg_version", PLUGIN_VERSION, "Disconnect Message Removal Version (by atom0s)", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_DisconnectMessageEnable = CreateConVar("disconnect_message_enable", "1", "Enable/Disable plugin", CVAR_FLAGS);
	g_DisconnectMessage = CreateConVar("disconnect_message", "", "Disconnection message shown when a user is disconnected.", CVAR_FLAGS);

	AutoExecConfig(true, "disconnectmsg");

	g_DisconnectMessageEnable.AddChangeHook(OnConVarPluginOnChange);
	g_DisconnectMessage.AddChangeHook(ConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_DisconnectMessage.GetString(cMessage, 64);
}

void IsAllowed()
{
	bool bPluginOn = g_DisconnectMessageEnable.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	}
}

Action PlayerDisconnect_Event(Event event, const char[] name, bool dontBroadcast)
{
	char cReason[64];
	event.GetString("reason", cReason, sizeof(cReason));
	if (StrContains(cReason, "kicked", false) != -1 
	|| StrContains(cReason, "banned", false) != -1 
	|| StrContains(cReason, "timed out", false) != -1 
	|| StrContains(cReason, "No Steam Logon", false) != -1 
	|| StrContains(cReason, "Server shutting down", false) != -1
	)
	{
		return Plugin_Continue;
	}
	else
	{
		event.SetString("reason", cMessage);
	}
	return Plugin_Continue;
}
