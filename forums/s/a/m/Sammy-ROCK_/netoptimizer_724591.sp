#include <sourcemod>
#define Version "1.0"

public Plugin:myinfo = 
{
	name = "Net Optimizer",
	author = "NBK - Sammy-ROCK!",
	description = "Boost up server net by allowing compating even small packets.",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_net_optimizer_version", Version, "Version of Net Optimizer plugin.", FCVAR_NOTIFY);
}

public OnMapStart()
{
	new Handle:ConVar = FindConVar("net_compresspackets_minsize");
	if(ConVar != INVALID_HANDLE) {
		SetConVarInt(ConVar, 0, true, false);
		CloseHandle(ConVar);
	}
	else
		LogError("Unable to find convar \"net_compresspackets_minsize\".");
}