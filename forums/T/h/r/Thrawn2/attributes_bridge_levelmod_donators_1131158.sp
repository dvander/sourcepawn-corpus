#include <sourcemod>
#include <attributes>
#include <levelmod>
#include <donator>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"

public Plugin:myinfo =
{
	name = "tAttributes, use Leveling Mod, Double Attributes for Donators",
	author = "Thrawn, toazron1",
	description = "A plugin for tAttributes, giving double attribute points for donators via Leveling Mod.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public lm_OnClientLevelUp(client, level, amount, bool:isLevelDown)
{
	if(!isLevelDown && IsClientDonator(client))
		att_AddClientAvailablePoints(client, amount);
}