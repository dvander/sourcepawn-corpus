#include <sourcemod>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "1.0.0"
new g_iFreePlayersTotal = 0;
new g_iPaidPlayersTotal = 0;

public Plugin:myinfo = {
	name        = "Paid vs Free - Counter",
	author      = "DarthNinja",
	description = "Counts and totals free and non-free players.",
	version     = PLUGIN_VERSION,
	url         = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_pvf_version", PLUGIN_VERSION, "Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("pvf", PrintTotals, ADMFLAG_KICK);
	g_iFreePlayersTotal = 0;
	g_iPaidPlayersTotal = 0;
}

public OnClientPostAdminCheck(client)
{	
	if (IsFakeClient(client))
		return;
	
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		g_iFreePlayersTotal++
	}
	else
	{
		g_iPaidPlayersTotal++
	}
	return;
}

public Action:PrintTotals(client, args)
{
	ReplyToCommand(client, "\x04[\x03PvF\x04]\x01: Total premium players this session: \x05%i\x01.  Total free players this session: \x05%i\x01", g_iPaidPlayersTotal, g_iFreePlayersTotal);
}