#include <sourcemod>
#include <sdktools>

ConVar g_Duration;
int g_Countdown;
bool g_IsFake;

public Plugin myinfo = {
    name = "serverselfdestruct",
    author = "TheR",
    description = "finally 2fort can rest now",
    version = "1"
};

public void OnPluginStart() {
    RegAdminCmd("serverselfdestruct", Command_Destruct, ADMFLAG_ROOT);
    RegAdminCmd("serverselfdestruct_fake", Command_FakeDestruct, ADMFLAG_ROOT);

    g_Duration = CreateConVar("serverselfdestruct_duration", "4", "Duration", FCVAR_NOTIFY, true, 1.0, true, 30.0);
}

public void OnMapStart() {
    PrecacheSound("ambient/alarms/klaxon1.wav", true);
    PrecacheSound("ambient/explosions/explode_8.wav", true);
    PrecacheSound("vo/scout_laughlong01.mp3", true);
}

public Action Command_Destruct(int client, int args) {
    g_IsFake = false;
    StartSequence();
    return Plugin_Handled;
}

public Action Command_FakeDestruct(int client, int args) {
    g_IsFake = true;
    StartSequence();
    return Plugin_Handled;
}

void StartSequence() {
    g_Countdown = g_Duration.IntValue;
    CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    DoFlash();
}

public Action Timer_Countdown(Handle timer) {
    g_Countdown--;

    if (g_Countdown > 0) {
        DoFlash();
        return Plugin_Continue;
    }

    FinalExplosion();
    return Plugin_Stop;
}

void DoFlash() {
    SetHudTextParams(-1.0, 0.5, 0.8, 255, 255, 255, 255, 0, 0.0, 0.1, 0.1);

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) continue;

        ClientCommand(i, "play ambient/alarms/klaxon1.wav");
        SendFade(i, 500, 0, 0x0001, 255, 0, 0, 150);
        ShowHudText(i, -1, "SERVER EXPLOSION IMMINENT");
    }
}

void FinalExplosion() {
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) continue;

        if (g_IsFake) {
            SetHudTextParams(-1.0, 0.5, 3.0, 255, 255, 255, 255, 2, 0.1, 0.1, 0.1);
            ShowHudText(i, -1, "GET SCAMMED");
            ClientCommand(i, "play vo/scout_laughlong01.mp3");
        } else {
            SendFade(i, 300, 0, 0x0008 | 0x0010, 255, 255, 255, 255);
            ScreenShake(i, 60.0, 150.0, 0.5);
            ClientCommand(i, "play ambient/explosions/explode_8.wav");
        }
    }

    if (g_IsFake) return;

    CreateTimer(0.3, Timer_KickAll);
}

void SendFade(int client, int duration, int holdtime, int flags, int r, int g, int b, int a) {
    Handle msg = StartMessageOne("Fade", client);
    if (msg == null) return;

    if (GetUserMessageType() == UM_Protobuf) {
        PbSetInt(msg, "duration", duration);
        PbSetInt(msg, "hold_time", holdtime);
        PbSetInt(msg, "flags", flags);

        int clr[4];
        clr[0] = r;
        clr[1] = g;
        clr[2] = b;
        clr[3] = a;

        PbSetColor(msg, "clr", clr);
    } else {
        BfWriteShort(msg, duration);
        BfWriteShort(msg, holdtime);
        BfWriteShort(msg, flags);
        BfWriteByte(msg, r);
        BfWriteByte(msg, g);
        BfWriteByte(msg, b);
        BfWriteByte(msg, a);
    }

    EndMessage();
}

void ScreenShake(int client, float amplitude, float frequency, float duration) {
    Handle msg = StartMessageOne("Shake", client);
    if (msg == null) return;

    if (GetUserMessageType() == UM_Protobuf) {
        PbSetInt(msg, "command", 0);
        PbSetFloat(msg, "local_amplitude", amplitude);
        PbSetFloat(msg, "frequency", frequency);
        PbSetFloat(msg, "duration", duration);
    } else {
        BfWriteByte(msg, 0);
        BfWriteFloat(msg, amplitude);
        BfWriteFloat(msg, frequency);
        BfWriteFloat(msg, duration);
    }

    EndMessage();
}

public Action Timer_KickAll(Handle timer) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            KickClient(i, "SERVER EXPLODED");
        }
    }

    CreateTimer(0.5, Timer_Shutdown);
    return Plugin_Stop;
}

public Action Timer_Shutdown(Handle timer) {
    ServerCommand("quit");
    return Plugin_Stop;
}