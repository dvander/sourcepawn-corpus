#include <sourcemod>

new Handle:cvarAutoRestartEnabled = INVALID_HANDLE;    // Auto restartgame Enabled?;
new Handle:cvarAutoRestartTime = INVALID_HANDLE;    // Time in seconds before Auto restartgame (round).
new Handle:AutoRestartGameTimer = INVALID_HANDLE;
new Counter;

public Plugin:myinfo =
{
    name = "[TF2] Autorestartgame",
    author = "MON@H Rasta",
    description = "Automaticly restarting game (round)",
    version = "1.0.0.0",
    url = ""
};

public OnPluginStart()
{
    cvarAutoRestartEnabled = CreateConVar("sm_autorestartgame", "0", "Enable/Disable Auto restartgame", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvarAutoRestartTime = CreateConVar("sm_autorestartgame_time", "60.0", "Time in minutes before Auto restartgame.", FCVAR_PLUGIN, true, 1.0);
    RegAdminCmd ("sm_restartgame", RestartGame, ADMFLAG_GENERIC, "Restarts the round and resets the round time");
}

public Action:RestartGame(client, args)
{
    PrintToChatAll ("[SM] Restarting game in 1 second");
    ServerCommand ("mp_restartgame 1");
    Counter = 0;
}

public OnMapStart()
{
    Counter = 0;

    if(GetConVarInt(cvarAutoRestartEnabled) == 1)
    {
        AutoRestartGameTimer = CreateTimer(1.0, Timer_Count, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

public OnMapEnd()
{
    KillTimer(AutoRestartGameTimer);
    Counter = 0;
}

stock ForceRestartGame()
{
    PrintToChatAll ("[SM] Autorestarting game in 1 second");
    ServerCommand ("mp_restartgame 1");
    Counter = 0;
}

public Action:Timer_Count(Handle:timer, any:client)
{
    if (Counter < GetConVarInt(cvarAutoRestartTime))
    {
        Counter++;
        return Plugin_Continue;
    }
    else
    {
        ForceRestartGame();
        return Plugin_Stop;
    }
} 