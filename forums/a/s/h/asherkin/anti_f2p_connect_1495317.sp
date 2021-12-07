#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>
#include <connect>

#define PLUGIN_VERSION "2.1.0"

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

public bool:OnClientPreConnectEx(const String:name[], String:password[255], const String:ip[], const String:steamID[], String:rejectReason[255])
{
	if (!Steam_SetCustomSteamID(steamID))
	{
		//ThrowError("Couldn't set %s as CustomSteamID", steamID);
		return true;
	}
	
	if (Steam_CheckClientSubscription(USE_CUSTOM_STEAMID, 0) && !Steam_CheckClientDLC(USE_CUSTOM_STEAMID, 459))
	{
		strcopy(rejectReason, 255, "You need a Premium TF2 account to play on this server.");
		return false;
	}
	
	return true;
}