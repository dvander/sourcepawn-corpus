public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
 	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(IsClientInGame(victim) && GetClientTeam(victim) == 3)
	{		 
 		if (attacker != 0)
		{
 			if(IsClientInGame(attacker) && GetClientTeam(attacker) == 2) 
			{
				PrintToChatAll("\x04%N \x03killed\x01 %N", attacker, victim);
			}
		}
	}
}
