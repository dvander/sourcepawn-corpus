#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "Show Killer",
    author = "Programmiert von FeritGang",
    description = "Zeigt den Spieler, der dich getötet hat",
    version = "1.0",
    url = "http://5.189.131.115/cstrike"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (IsClientInGame(victim) && IsClientInGame(attacker))
    {
        char attackerName[MAX_NAME_LENGTH];
        GetClientName(attacker, attackerName, sizeof(attackerName));

        float x = 0.4; // Verschiebe die Meldung leicht nach links
        float y = 0.1;
        float holdTime = 5.0;
        int red = 64, green = 224, blue = 208, alpha = 255; // Türkis

        SetHudTextParams(x, y, holdTime, red, green, blue, alpha, 0, 0);
        ShowHudText(victim, 0, "Du wurdest von %s getötet!", attackerName);
    }
}
