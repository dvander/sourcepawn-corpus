#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "[L4D] Client timeout override",
	author = "djromero (SkyDavid)",
	description = "Overrides client's timeout to prevent disconnect on long map changes",
	version = PLUGIN_VERSION,
	url = "www.theskyclan.com"
}


new Handle:h_timeout_value;
new TimeOut_Value;


public OnPluginStart()
{
	// We register the version cvar
	CreateConVar("l4d_client_timeout_override_version", PLUGIN_VERSION, "Version of L4D Client timeout override plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// cvar for timeout value
	h_timeout_value = CreateConVar("l4d_client_timeout_value", "120", "Value to override client's timeout", ADMFLAG_KICK, false, 0.0, false, 0.0);
	TimeOut_Value = GetConVarInt(h_timeout_value);
	HookConVarChange(h_timeout_value, ConVarTimeoutValue);
}

public ConVarTimeoutValue(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TimeOut_Value = GetConVarInt(h_timeout_value);
}

public OnClientPutInServer(client) 
{
	if(!IsFakeClient(client))
	{
		SetTimeOut(client);
	}
}

SetTimeOut(client)
{
	decl String:ipaddr[24];
	decl String:cmd[100];
	GetClientIP(client, ipaddr, sizeof(ipaddr));
	
	if (!StrEqual(ipaddr,"loopback",false))
	{
		// We change the timeout
		Format (cmd, sizeof(cmd), "cl_timeout %i", TimeOut_Value);
		ClientCommand(client, cmd);
	}
}


