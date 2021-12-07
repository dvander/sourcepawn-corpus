#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name        = "Free2BeKicked",
	author      = "Asher \"asherkin\" Baker",
	description = "Automatically kicks non-premium players.",
	version     = PLUGIN_VERSION,
	url         = "http://limetech.org/"
};

public OnPluginStart()
{
	CreateConVar("anti_f2p_version", PLUGIN_VERSION, "Free2BeKicked", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnClientPostAdminCheck(client)
{
	if (CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_ROOT, true))
	{
		return;
	}
	
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		KickClient(client, "You need a Premium TF2 account to play on this server");
		return;
	}
	
	return;
}