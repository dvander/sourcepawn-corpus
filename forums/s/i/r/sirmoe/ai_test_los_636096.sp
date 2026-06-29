#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.2"

// Functions
public Plugin:myinfo =
{
	name = "ai_test_los blocker",
	author = "pRED*",
	description = "Blocks usage of the ai_test_los",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	new flags = GetCommandFlags("ai_test_los");
	SetCommandFlags("ai_test_los", flags|FCVAR_CHEAT);
	
	
	CreateConVar("sm_ai_test_los_version", PLUGIN_VERSION, "ai_test_los blocker version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}