#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Simple Teams Ballancer for Insurgency",
	author = "Tomasz 'anacron' Motyliñski",
	description = "Simple Teams Ballancer for Insurgency",
	version = "0.0.1",
	url = "http://infmaous-clan.eu/"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_player_death);
}
public Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new counter_team_1 = 0;
	new counter_team_2 = 0;
	new victim = GetClientOfUserId( GetEventInt(event,"userid"));
	new VictimTeam = GetClientTeam(victim);
	if (VictimTeam != GetClientTeam(GetClientOfUserId(GetEventInt(event,"attacker"))))
	{
		for(new i=1;i<MAXPLAYERS;i++)
		{
			new ClientTeam = GetClientTeam(i);
			if (ClientTeam == 1) {counter_team_1++;}
			else if (ClientTeam == 2) {counter_team_2++;}
		}
		if ((VictimTeam == 1) && (counter_team_1 > counter_team_2 + 1) && !IsPlayerAlive(victim)) {ChangeClientTeam(victim,2);}
		else if ((VictimTeam == 2) && (counter_team_2 > counter_team_1 + 1) && !IsPlayerAlive(victim)) {ChangeClientTeam(victim,1);}
	}
}
