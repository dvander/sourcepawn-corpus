#pragma semicolon 1
#include <sourcemod>
#include <store>

#define PLUGIN_VERSION "1.0"

Handle gh_Creditsaward;
int g_Creditsaward;

public Plugin:myinfo =
{
	name        = "[Store] Team win award",
	author      = "wyd3x",
	description = "Award winner team every round",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/member.php?u=197680 || http://csgo.co.il"
};

public OnPluginStart() 
{
	CreateConVar("sm_winaward_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN);
	gh_Creditsaward = CreateConVar("store_winner_award", "4", "How much credits got winner team", FCVAR_PLUGIN);
	g_Creditsaward = GetConVarInt(gh_Creditsaward);
	HookEvent("round_end", Event_RoundEnd);
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	for(int i = 1; i < MaxClients; i++)
		if(IsValidClient(i))
			if(GetClientTeam(i) == GetEventInt(event, "winner"))
				GiveCreditsToClient(i);
				
	return Plugin_Continue;
}

GiveCreditsToClient(int client)
{
	int id = Store_GetClientAccountID(client);
	Store_GiveCredits(id, g_Creditsaward);
	PrintToChat(client, "%s Your team won, you got %i credits", STORE_PREFIX, g_Creditsaward);
}


stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}