
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"

new botMin, botAdd, botSubtract, reserved;

new Handle:ControlBotQuota = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Bot Control",
	author = "TnTSCS aka ClarkKent",
	description = "Requested Plugin to control bot_quota>",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{	
	CreateConVar("sm_botcontrol_version", PLUGIN_VERSION, "Version of this requested plugin", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	
	new Handle:hRandom; // KyleS HATES Handles
	
	hRandom = CreateConVar("sm_botcontrol_min", "10", "Minimum number of bots to start with");
	botMin = GetConVarInt(hRandom);
	HookConVarChange(hRandom, MinChanged);
	
	hRandom = CreateConVar("sm_botcontrol_add", "2", "Number of bots to add for when a human joins");
	botAdd = GetConVarInt(hRandom);
	HookConVarChange(hRandom, AddChanged);
	
	hRandom = CreateConVar("sm_botcontrol_rem", "2", "Number of bots to remove for when a human leaves");
	botSubtract = GetConVarInt(hRandom);
	HookConVarChange(hRandom, RemChanged);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	ControlBotQuota = FindConVar("bot_quota");
	
	AutoExecConfig(true, "plugin.botcontrol");
}

public OnConfigsExecuted()
{
	SetConVarInt(ControlBotQuota, botMin);
	
	new Handle:hRandom;
	
	hRandom = FindConVar("sm_reserved_slots");
	reserved = GetConVarInt(hRandom);
	HookConVarChange(hRandom, RSChanged);
	
	CloseHandle(hRandom);
}

public OnClientPutInServer(client)
{
	if(IsFakeClient(client))
		return;
	
	new value = GetConVarInt(ControlBotQuota);
	value += botAdd;
	
	new maximum = MaxClients - reserved;
	
	if(value >= maximum - 1)
		return;
	
	SetConVarInt(ControlBotQuota, value);
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client) && IsFakeClient(client))
		return;
	
	new value = GetConVarInt(ControlBotQuota);
	value -= botSubtract;
	
	if(value < botMin)
		value = botMin;
	
	SetConVarInt(ControlBotQuota, value);
}

public MinChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	botMin = GetConVarInt(cvar);
}

public AddChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	botAdd = GetConVarInt(cvar);
}

public RemChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	botSubtract = GetConVarInt(cvar);
}

public RSChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	reserved = GetConVarInt(cvar);
}
