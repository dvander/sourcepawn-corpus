#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new String:gS_DisallowedString[][] = {"\n", "\t", "\r", "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08"};

public Plugin:myinfo = 
{
	name = "Connect/Disconnect Exploit Fixer",
	author = "shavit",
	description = "That plugin is fixing is fixing an exploit that allows a cheater to get an IP of players and use a custom disconnect reason.",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_dis_connect_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	HookEvent("player_connect", Player_Connect, EventHookMode_Pre);
	HookEvent("player_disconnect", Player_Disconnect, EventHookMode_Pre);
}

public Action:Player_Connect(Handle:Event, const String:Name[], bool:dB)
{
	SetEventString(Event, "address", "nope:png");
	
	return Plugin_Changed;
}

public Action:Player_Disconnect(Handle:Event, const String:Name[], bool:dB)
{
	new String:reason[64];
	GetEventString(Event, "reason", reason, 64);
	
	new bool:Changed;
	
	for(new i; i < sizeof(gS_DisallowedString); i++)
	{
		if(ReplaceString(reason, 64, gS_DisallowedString[i], ""))
		{
			Changed = true;
		}
	}
	
	if(Changed)
	{
		SetEventString(Event, "reason", reason);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
