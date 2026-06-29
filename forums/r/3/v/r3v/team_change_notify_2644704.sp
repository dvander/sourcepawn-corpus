#include <csgo_colors>
static const String:msg[][] = 
{
	"joined {PURPLE}spectators",
	"joined {RED}terrorists",
	"joined {BLUE}counter-terrorists"
};

public OnPluginStart()
{
	HookEvent("player_team", Event_Team, EventHookMode_Pre);
}

public Action:Event_Team(Handle:event, String:name[], bool:dontBroadcast)
{
	static client, team;
	if(dontBroadcast || GetEventBool(event,"disconnect") || GetEventBool(event,"silent")
	|| !(client = GetClientOfUserId(GetEventInt(event,"userid"))) || (team = GetEventInt(event,"team") - 1) < 0)
		return Plugin_Continue;

	CGOPrintToChatAll("Player {GREEN}%N %s", client, msg[team]);
	SetEventBroadcast(event, true);

	return Plugin_Changed;
}