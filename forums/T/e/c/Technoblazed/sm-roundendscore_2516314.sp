#include <cstrike>
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <pugsetup>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = {
    name = "[SM] PUG Round End Score",
    author = "Techno",
    description = "Prints the current match score at the end of a round.",
    version = PLUGIN_VERSION,
    url = "https://tech-no.me"
}

public void OnPluginStart() {
    HookEvent("round_end", Event_RoundEnd);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    if (PugSetup_GetGameState() != GameState_Live) {
        return Plugin_Continue;
    }

    int ctScore = CS_GetTeamScore(CS_TEAM_CT);
    int tScore = CS_GetTeamScore(CS_TEAM_T);

    char ctName[64];
    char tName[64];

    GetTeamName(CS_TEAM_CT, ctName, sizeof(ctName));
    GetTeamName(CS_TEAM_T, tName, sizeof(tName));

    if ((tScore + ctScore) > 0) {
        if (tScore > ctScore) {
            PugSetup_MessageToAll("\x0B%s \x04%i\x01 - \x07%i\x01 \x09%s", ctName, tName, ctScore, tScore);
        } else if (ctScore == tScore) {
            PugSetup_MessageToAll("\x0B%s \x10%i\x01 - \x10%i\x01 \x09%s", ctName, tName, ctScore, tScore);
        } else {
            PugSetup_MessageToAll("\x0B%s \x07%i\x01 - \x04%i\x01 \x09%s", ctName, tName, ctScore, tScore);
        }
    }

    return Plugin_Continue;
}
