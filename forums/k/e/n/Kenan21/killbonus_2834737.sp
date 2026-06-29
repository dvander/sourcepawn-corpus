public Plugin myinfo =
{
    name = "Kill Bonus HP",
    author = "Created by FeritGang",
    description = "Gibt jeden Spieler Bonus-HP für Kills",
    version = "1.0",
    url = "http://5.189.131.115/cstrike"
}

public OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int max_health = 100;
    if (IsValidClient(attacker))
    {
        int current_health = GetClientHealth(attacker);
        int bonus_health = 30;

        int new_health = current_health + bonus_health;

        if (new_health > max_health)
        {
            new_health = max_health;
        }

        SetEntityHealth(attacker, new_health);
        PrintToChat(attacker, "Du hast %d HP Bonus erhalten!", bonus_health);
    }
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}
