#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
    name = "Rebellion Plugin",
    author = "Mad-Cats|dAmpFLoK /// https://steamcommunity.com/profiles/76561199509359636/ /// www.Mad-Cats.com",
    description = "Markiert Terroristen, die CTs angreifen, und zeigt eine Nachricht im Chat an.",
    version = "1.0"
};

public void OnPluginStart()
{
    // Hook für das "player_hurt" Event setzen
    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
    
    // Hook für den Start einer neuen Runde setzen
    HookEvent("round_start", OnRoundStart, EventHookMode_Post);
    
    PrintToServer("[Rebellion Plugin] Plugin erfolgreich geladen.");
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    // Holen der Attacker- und Opfer-IDs
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    // Validieren der Spieler
    if (!IsClientInGame(victim) || !IsClientInGame(attacker))
        return Plugin_Continue;

    // Team der Spieler holen
    int victimTeam = GetClientTeam(victim);
    int attackerTeam = GetClientTeam(attacker);

    // Nur reagieren, wenn ein Terrorist (T) einen CT angreift
    if (victimTeam == 3 && attackerTeam == 2)
    {
        // Namen der Spieler holen
        char victimName[64];
        char attackerName[64];
        GetClientName(victim, victimName, sizeof(victimName));
        GetClientName(attacker, attackerName, sizeof(attackerName));

        // Nachricht in den Chat senden (mit Farbformatierung)
        PrintToChatAll("\x01[ALARM] \x05Player \x04%s \x01is rebelling against\x03%s!", attackerName, victimName);

        // Modell des Angreifers rot färben
        SetEntityRenderColor(attacker, 255, 0, 0, 255); // RGB = Rot
    }

    return Plugin_Continue;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // Alle Terroristen (T) zurücksetzen
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2)  // Team 2 = Terroristen
        {
            // Setze die Renderfarbe zurück (weiß = Standard)
            SetEntityRenderColor(i, 255, 255, 255, 255); // RGB = Weiß
        }
    }

    return Plugin_Continue;
}
