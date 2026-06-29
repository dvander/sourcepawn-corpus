#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <steamtools>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#define PLUGIN_VERSION "1.0"


new bool:IsPremium[MAXPLAYERS+1] = false;
new bool:IsInGame[MAXPLAYERS+1] = false;
new bool:SteamToolsAvailable = false;

// Plugin Info
public Plugin:myinfo =
{
	name = "[DEV|TF2] IsClientPremium native",
	author = "KK",
	description = "This plugin provide IsClientPremium native, for plugin developers.",
	version = PLUGIN_VERSION,
	url = "http://www.attack2.co.cc/"
};


// Plugin Start
public OnPluginStart()
{
	CreateConVar("sm_dev_tf2_premium", PLUGIN_VERSION, "IsClientPremium native version", FCVAR_CHEAT|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SteamToolsAvailable = LibraryExists("SteamTools");
}


// AskPluginLoad2
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("plugin.tf2.premium");
	CreateNative("IsClientPremium", Native_IsPremium);
	return APLRes_Success;
}


// OnLibraryRemoved
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools"))
	{
		SteamToolsAvailable = false;
	}
}


// OnLibraryAdded
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools"))
	{
		SteamToolsAvailable = true;
	}
}


// OnClientPostAdminCheck
public OnClientPostAdminCheck(client)
{
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		IsPremium[client] = true;
	}
	IsInGame[client] = true;
}


// OnClientDisconnect
public OnClientDisconnect(client)
{
	IsInGame[client] = false;
	IsPremium[client] = false;
}


// Native_IsPremium
public Native_IsPremium(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return IsClientPremium(client);
}


// IsClientPremium
public IsClientPremium(client)
{
	if (SteamToolsAvailable)
	{
		if (0 < client <= MaxClients && IsInGame[client])
		{
			if (IsPremium[client])
			{
				return 1;
			}
			return -1;
		}
		return -2;
	}
	return -3;
}
