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

public Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
	if (CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_ROOT, true))
		return;
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		if ((groupAccountID==103582791431384943) && groupMember)
			return;
		KickClient(client, "Free TF2 Account must be in VS Saxton Hale Mode group to play.");
		return;
	}
}

public OnClientPostAdminCheck(client)
{
	Steam_RequestGroupStatus(client, 103582791431384943);	
	return;
}

public Action:Timer_Da(Handle:hTimer,any:client)
{
	PrintToChat(client,"Yes %i",Steam_RequestGroupStatus(client,103582791431384943));
	return Plugin_Continue;
}

public Action:Timer_Net(Handle:hTimer,any:client)
{
	PrintToChat(client,"No");
	return Plugin_Continue;
}