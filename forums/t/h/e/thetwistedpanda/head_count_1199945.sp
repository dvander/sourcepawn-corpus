#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

new g_headCount[MAXPLAYERS + 1];
new Handle:g_isEnabled = INVALID_HANDLE;
new Handle:g_minHeadshots = INVALID_HANDLE;
new Handle:g_resetOnMiss = INVALID_HANDLE;
new Handle:g_resetOnDeath = INVALID_HANDLE;
new Handle:g_announceMode = INVALID_HANDLE;

public Plugin:myinfo =
{
   name = "Head Count",
   author = "Twisted|Panda",
   description = "Announces a headshot killing spree.",
   version = PLUGIN_VERSION,
   url = "http://alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_headcount_version", PLUGIN_VERSION, "Head Count Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_isEnabled    = CreateConVar("sm_headcount_enable", "1", "Enables or disables all features of this plugin.");
	g_minHeadshots    = CreateConVar("sm_headcount_minimum", "4", "The minimum number of headshots before the plugin starts to announce.");
	g_resetOnMiss    = CreateConVar("sm_headcount_reset_non", "1", "If enabled, a player's spree will be reset upon a non-headshot kill.");
	g_resetOnDeath    = CreateConVar("sm_headcount_reset_death", "1", "If enabled, player's spree will be reset upon their death.");
	g_announceMode    = CreateConVar("sm_headcount_announce", "1", "If enabled, chat messages will be displayed to everyone. If disabled, chat messages displayed only to affected user.");

	HookEvent("player_death", OnPlayerDeath);
}

public OnClientPostAdminCheck(client)
{
	if(client && IsClientInGame(client))
		g_headCount[client] = 0;
}

public OnPlayerDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	if(GetConVarInt(g_isEnabled))
	{
		new String:clientName[32];
		new bool:isHeadshot = GetEventBool(Event, "headshot");
		new victim = GetClientOfUserId(GetEventInt(Event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
		
		if(isHeadshot)
		{
			g_headCount[attacker]++;
			new curCount = g_headCount[attacker];
			if(curCount >= GetConVarInt(g_minHeadshots))
			{
				if(GetConVarInt(g_announceMode))
				{
					GetClientName(attacker, clientName, sizeof(clientName));
					PrintHintTextToAll("%s: %d HSs in a row!", clientName, curCount);
				}
				else
					PrintHintText(attacker, "%d HSs in a row!", curCount);
			}
		}
		else
			if(g_headCount[attacker] && GetConVarInt(g_resetOnMiss))
				g_headCount[attacker] = 0;

		if(g_headCount[victim] && GetConVarInt(g_resetOnDeath))
			g_headCount[victim] = 0;
	}
}