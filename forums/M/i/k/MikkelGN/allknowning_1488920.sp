/* Plugin Template generated by Pawn Studio */

#define PLUGIN_VERSION "1.0"
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "All knowning",
	author = "MikkelGN",
	description = "See deathchat",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	SetConVarString(CreateConVar("sm_allknowning_version", PLUGIN_VERSION, "Show Deathchat to admins", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT), PLUGIN_VERSION);
	
	HookEvent("player_say", EventPlayerSay);
}

public EventPlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:msg[192];
	new String:client[32];
	
	GetEventString(event, "text", msg, sizeof(msg));
	
	new person = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientName(person, client, sizeof(client));
	
	for (new i=1; i<=MaxClients; i++)
	{
		if(CheckCommandAccess(i, "sm_psay", ADMFLAG_CHAT) && !IsPlayerAlive(i))
		{
			PrintToChat(i, "\x04[AK] \x01%s : %s", client, msg);
		}
	}
}