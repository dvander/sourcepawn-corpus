#include <sourcemod>
#include <sdktools>
#include <cstrike>

new rounds;

public Plugin:myinfo =
{
	name = "SM Rounds Counter Fixer",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://www.zeuszombie.com/"
};

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(GameRules_GetProp("m_totalRoundsPlayed") == rounds) GameRules_SetProp("m_totalRoundsPlayed",++rounds);
}

public Action:CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	rounds = GameRules_GetProp("m_totalRoundsPlayed");
}

