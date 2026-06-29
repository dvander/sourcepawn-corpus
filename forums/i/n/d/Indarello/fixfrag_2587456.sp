public OnPluginStart() 
{
	HookEventEx("player_death", DR_Action_Death, EventHookMode_Pre);
}

public Action:DR_Action_Death(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new victim	= GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsClientInGame(victim) && (attacker == 0 || attacker == victim))
		SetEntProp(victim, Prop_Data, "m_iFrags", GetClientFrags(victim) + 1);
}