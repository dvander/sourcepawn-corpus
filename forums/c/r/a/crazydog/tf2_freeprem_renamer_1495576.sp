#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = {
	name        = "Free or Premium Renamer",
	author      = "Crazydog",
	description = "Add a [F] or [P] to a player's name based on their TF2 ownership status",
	version     = PLUGIN_VERSION,
	url         = "http://theelders.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_fpr_version", PLUGIN_VERSION, "FreePremiumRenamer Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_fpr_ftag", "[F]", "Tag for Free users");
	CreateConVar("sm_fpr_ptag", "[P]", "Tag for Premium users");
}

public OnClientPostAdminCheck(client)
{
	new String:name[256], String:newName[256], String:ftag[32], String:ptag[32];
	GetClientName(client, name, sizeof(name));
	GetConVarString(FindConVar("sm_fpr_ftag"), ftag, sizeof(ftag));
	GetConVarString(FindConVar("sm_fpr_ptag"), ptag, sizeof(ptag));
	
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		Format(newName, sizeof(newName), "%s %s", name, ftag);
	}else{
		Format(newName, sizeof(newName), "%s %s", name, ptag);
	}
	SetClientInfo(client, "name", newName);
	
	return;
}