#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION  "0.0.9"

public Plugin:myinfo = 
{
	name = "Ruxpin Get Zombie Kills",
	author = "TeddyRuxpin - pRed",
	description = "Utilities for L4D Zombie Kill Tracking",
	version = PLUGIN_VERSION,
	url = "http://blacktusklabs.com/btlforums"
}

public OnPluginStart()
{
	CreateConVar("sm_zkills_version", PLUGIN_VERSION, "Get L4D Current Zombie Kills", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_zkills", cmdGetKills, "Get your zombie kill count");
}
public Action:cmdGetKills(client, args)
{
				new kills_check = GetEntProp(client, Prop_Send, "m_checkpointZombieKills");
				new kills_mission = GetEntProp(client, Prop_Send, "m_missionZombieKills");
				PrintToChat(client, "\x04[SM]\x01 Zombies killed This Stage: %d ", kills_check);
				PrintToChat(client, "\x04[SM]\x01 Zombies killed This Campaign: %d ", kills_mission);
				return Plugin_Handled;
}