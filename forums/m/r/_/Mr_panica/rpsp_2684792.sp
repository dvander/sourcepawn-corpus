#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>

public OnPluginStart()
{
    HookEvent("rps_taunt_event", Event_RpsTaunt);
}

public Plugin myinfo = 
{
	name = "[PGZ] Rock Paper Scissors Printer",
	author = "Mr_panica",
	version = "1.00",
};

public void Event_RpsTaunt(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	int loser = event.GetInt("loser");

	if(!IsClientInGame(winner) || !IsClientInGame(loser))
		return;
	
	CPrintToChatAll("{orange}[RPSP] {%s}%N {default}defeated {%s}%N {default}in the RPS game.",
		(TF2_GetClientTeam(winner) == TFTeam_Red) ? "red" : "blue", winner,
		(TF2_GetClientTeam(loser) == TFTeam_Red) ? "red" : "blue", loser);

}
