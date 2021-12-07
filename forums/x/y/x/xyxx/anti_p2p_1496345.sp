#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name        = "Prem2BeKicked",
	author      = "TT",
	description = "Automatically kicks non-freemium players.",
	version     = PLUGIN_VERSION,
	url         = "http://google.com/"
};

public OnPluginStart()
{
	CreateConVar("anti_p2p_version", PLUGIN_VERSION, "Prem2BeKicked", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnClientPostAdminCheck(client)
{
	if (CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_ROOT, true))
	{
		KickClient(client, "You need a Freemium TF2 account to play on this server");
		return;
	}
	
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		return;
	}
	
	return;
}
