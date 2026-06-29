#include <sourcemod>

new Handle:MK_Enabled = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Matchkick",
	author = "Impact",
	description = "Bans a player whi is disconnection on a live match",
	version = "0.0",
	url = "non"
}

public OnPluginStart()
{
	MK_Enabled = CreateConVar("sm_matchkick_enable", "0", "Enable this Plugin")
	HookEvent( "player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre)
}


public Action:PlayerDisconnect_Event(Handle:event, String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(MK_Enabled))
	{
		decl String:reason[64]
		decl String:username[64]
		decl String:userId[32]
		GetEventString(event, "name", username, sizeof(username))
		GetEventString(event, "userid", userId, sizeof(userId))
		GetEventString(event, "reason", reason, sizeof(reason))
		
		if(StrContains(reason, "Disconnect by user.") != -1)
		{
			ServerCommand("sm_ban %s 0 \"You have been banned for leaving while match is live\"", userId)
			LogMessage("User %s has been banned for leaving while math is live: %s", username, reason)
		}
	}
	return Plugin_Handled
	
}