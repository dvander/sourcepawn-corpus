// Plugin: Keep Doors Open in Counter-Strike: Source
// Author: [Dein Name]
// Description: Ein Plugin, das offene Türen offen lässt, sodass sie nicht mehr geschlossen werden können.
// A plugin that leaves open doors so that they can no longer be closed

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Keep Doors Open",
    author = "[XL] Oldie - Dellmuth",
    description = "Offene Türen bleiben offen",
    version = "1.0",
    url = "https://www.xloldies.de"
};

// Event, das aufgerufen wird, wenn eine Tür geöffnet oder geschlossen wird
public void OnPluginStart() {
    HookEntityOutput("prop_door_rotating", "OnClose", DoorPreventClose);
    HookEntityOutput("func_door", "OnClose", DoorPreventClose);
    PrintToServer("Plugin 'Keep Doors Open' wurde geladen.");
}

// Funktion, die das Schließen einer Tür verhindert
public void DoorPreventClose(const char[] output, int caller, int activator, float delay) {
    PrintToServer("Schließen der Tür %d verhindert.", caller);
    // Simuliere, dass die Tür nicht schließt, indem wir den Output manipulieren
    AcceptEntityInput(caller, "Unlock");
    AcceptEntityInput(caller, "Open");
}
