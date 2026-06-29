#include <sourcemod>

public Plugin myinfo = {
    name = "Force Nextmap",
    author = "Razera",
    version = "1.0"
};

int g_StartTime;

public void OnMapStart() {
    g_StartTime = GetTime();
    CreateTimer(10.0, CheckTime, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckTime(Handle timer) {
    int timeLimit = GetConVarInt(FindConVar("mp_timelimit")) * 60;
    if (timeLimit <= 0)
        return Plugin_Continue;

    if (GetTime() - g_StartTime >= timeLimit) {
        char nextmap[PLATFORM_MAX_PATH];
        GetNextMap(nextmap, sizeof(nextmap));
        ServerCommand("changelevel %s", nextmap);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}
