#include <sourcemod>

#pragma semicolon 1

#define VERSION			"1.0"
#define	AUTHOR			"MMYTH"

#define fm_get_user_team(%1)	GetClientTeam(%1)

new Handle:g_on, Handle:g_teamkill;

public Plugin:myinfo =
{
	name = "Simple One die, all dies",
	author = AUTHOR,
	description = "When a player die (if isn't suicide), all his teammates die too",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	g_on = CreateConVar("simple_onedie_alldies", "1");
	g_teamkill = CreateConVar("simple_onedie_alldies_tk", "1");
	
	HookEvent("player_death", event_playerdeath, EventHookMode_Post);
}

public event_playerdeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killerid = GetEventInt(event, "attacker");
	new victimid = GetEventInt(event, "userid");
	
	if(!GetConVarInt(g_on) || (!GetConVarInt(g_teamkill) && (fm_get_user_team(killerid) == fm_get_user_team(victimid))) || killerid == victimid)
		return;
	
	new playersCount, i;
	playersCount = GetClientCount();
	
	for(i = 0; i < playersCount; i++)
	{
		if(fm_get_user_team(victimid) == fm_get_user_team(i))
		{
			ClientCommand(i, "kill");
			PrintToChat(i, "One die, all dies");
		}
	}
}