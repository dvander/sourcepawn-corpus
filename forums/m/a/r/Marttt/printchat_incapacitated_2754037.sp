public void OnPluginStart()
{
    HookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

public void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (victim && IsClientInGame(victim) && attacker && IsClientInGame(attacker))
    {
        PrintToChatAll("%N incapacitated %N", attacker, victim);
    }
}