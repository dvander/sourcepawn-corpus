#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "L4D2 Saferoom Door Opener",
	author = "DarkNoghri",
	description = "Prints the name of the saferoom door opener.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

new bool:door_opened;
new Handle:h_pluginEnabled=INVALID_HANDLE;
new bool:plugin_enabled;

public OnPluginStart()
{
	CreateConVar("l4d2_saferoom_opener_version", PLUGIN_VERSION, "Version of L4D2 Saferoom Door Opener", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	h_pluginEnabled = CreateConVar("l4d2_saferoom_opener_enable", "1", "0 turns plugin off, 1 turns it on.", FCVAR_PLUGIN, true, 0, true, 1.0);

	HookEvent("door_open", EventDoorOpened);
	HookEvent("round_start", EventRoundStart);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("player_left_start_area", EventLeftStart);
	
	HookConVarChange(h_pluginEnabled, ChangePluginEnabled);
	
	door_opened = false;
	plugin_enabled = GetConVarBool(h_pluginEnabled);
}

public EventDoorOpened(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!plugin_enabled) return Plugin_Continue;
	
	//saferoom door check
	new bool:checkpoint = GetEventBool(event, "checkpoint");
	if(checkpoint == false) return Plugin_Continue;
	
	//was it closed?
	new bool:closed = GetEventBool(event, "closed");
	if(closed == false) return Plugin_Continue;
	
	//was it already opened this round?
	if(door_opened == true) return Plugin_Continue;
	
	//who was it?
	new opener = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:openerName[64];
	GetClientName(opener, openerName, sizeof(openerName));
	
	//if(IsFakeClient(opener)) return Plugin_Continue;
	
	//print and set variable
	PrintToChatAll("%s opened the saferoom door.", openerName);
	door_opened = true;
	return Plugin_Continue;
}

public EventLeftStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!plugin_enabled) return Plugin_Continue;

	door_opened = true;
	
	return Plugin_Continue;
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	door_opened = false;
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	door_opened = false;
}

public ChangePluginEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	plugin_enabled = GetConVarBool(cvar);
	
	if(plugin_enabled == false) door_opened = false;
}

