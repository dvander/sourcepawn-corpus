#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name        = "[L4D2] Game Start Message",
    author      = "Drixevel",
    description = "Prints a message in chat when the game starts.",
    version     = "1.0.0",
    url         = "https://drixevel.dev/"
};

public void OnPluginStart()
{
    HookEvent("player_left_start_area", Event_OnPlayerLeftStartArea);
}

public void Event_OnPlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast) {
    PrintToChatAll("\x04[Oyun Mod-Kontrolü] \x01Oyun başladı. Oyun Mod'u hazır! Bol şanslar! İyi oyunlar...");
}