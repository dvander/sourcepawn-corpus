
// CONSOLE COMMAND BLOCKER

// THIS PLUGIN BLOCKS CERTAIN CONSOLE COMMANDS
// FROM BEING EXECUTED BY ADDING THE CHEAT
// FLAG TO THEM SO THEY WILL NOT WORK.

#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Console Command Blocker",
	author = "Cooltad, pRED*",
	description = "Blocks usage of certain console commands",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
// add new console commands to block by copy-pasting:
//
// new flags = GetCommandFlags("INSERT_COMMAND_TO_BLOCK_HERE");
// SetCommandFlags("INSERT_COMMAND_TO_BLOCK_HERE", flags|FCVAR_CHEAT);
//
// Then you must chang both instances of 'flags' to a number greater than
// the previous. For example, if on the latter copy-paste, it is
// 'flags2', then for your new copy-pasta, it would be 'flags3', in
// both instances. Then you can use comments "//" to leave your reason
// for organization reasons.

	new flags = GetCommandFlags("sv_benchmark_force_start");		// crashes server
	SetCommandFlags("sv_benchmark_force_start", flags|FCVAR_CHEAT);
	
	new flags1 = GetCommandFlags("sv_soundscape_printdebuginfo");	// crashes server
	SetCommandFlags("sv_soundscape_printdebuginfo", flags1|FCVAR_CHEAT);
	
	new flags2 = GetCommandFlags("ai_test_los");					// crashes server
	SetCommandFlags("ai_test_los", flags2|FCVAR_CHEAT);
//
// INSERT YOUR NEW COPY-PASTA BELOW


//
//
	CreateConVar("sm_con_com_block_version", PLUGIN_VERSION, "Console Command Blocker version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}