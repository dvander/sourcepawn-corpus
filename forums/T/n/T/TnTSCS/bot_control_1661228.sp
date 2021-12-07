
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new botMin, botAdd, botSubtract;

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
	// Create this plugins CVars
	new Handle:hRandom; // KyleS HATES handles
	
	CreateConVar("sm_botcontrol_version", PLUGIN_VERSION, "Version of this requested plugin");
	
	hRandom = CreateConVar("sm_botcontrol_min", "10", "Minimum number of bots to start with");
	botMin = GetConVarInt(hRandom);
	
	hRandom = CreateConVar("sm_botcontrol_add", "2", "Number of bots to add for when a human joins");
	botAdd = GetConVarInt(hRandom);
	
	hRandom = CreateConVar("sm_botcontrol_rem", "2", "Number of bots to remove for when a human leaves");
	botSubtract = GetConVarInt(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	ControlBotQuota = FindConVar("bot_quota");
}

public OnConfigsExecuted()
{
	SetConVarInt(ControlBotQuota, botMin);
}

public OnClientPutInServer(client)
{
	if(IsFakeClient(client))
		return;
	
	new value = GetConVarInt(ControlBotQuota);
	value += botAdd;
	
	SetConVarInt(ControlBotQuota, value, _, true);
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client) && IsFakeClient(client))
		return;
	
	new value = GetConVarInt(ControlBotQuota);
	value -= botSubtract;
	
	SetConVarInt(ControlBotQuota, value, _, true);
}
