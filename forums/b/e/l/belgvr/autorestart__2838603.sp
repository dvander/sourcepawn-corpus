#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <multicolors>

ConVar g_hRestartTime;
ConVar g_hWriteToLog;
ConVar g_hPreTimer;
ConVar g_hRestartMessage;
ConVar g_hRestartNowMsg;
ConVar g_hSoundPath;

int g_iLastChecked = -1;

public Plugin myinfo = 
{
    name = "Autorestart++",
    author = "Ribas",
    description = "Restarts the server at an specific time or with commands",
    version = "1.3",
    url = "https://hl2dm.com.br"
};

public void OnPluginStart()
{
    g_hRestartTime = CreateConVar("sm_autorestart_time", "0500", "Restart time in HHMM format (24h)", _, true, 0.0, true, 2359.0);
    g_hWriteToLog = CreateConVar("sv_autorestart_writetolog", "1", "Enable or disable restart logging (1 = on, 0 = off)", _, true, 0.0, true, 1.0);
    g_hPreTimer = CreateConVar("sm_autorestart_pretimer", "10", "Countdown in seconds before restart", _, true, 1.0, true, 30.0);
    g_hRestartMessage = CreateConVar("sm_autorestart_message", "{red}>>> [SERVER WILL RESTART IN %d SECONDS]", "Message format with %%d for seconds left");
    g_hRestartNowMsg = CreateConVar("sm_autorestartnow_msg", "{red}>>> [SERVER WILL RESTART IN %d SECONDS]", "Message for manual restart via command");
    g_hSoundPath = CreateConVar("sm_autorestart_sound", "buttons/button15.wav", "Sound file to play on each countdown message (relative to sound folder). [PLEASE USE ONLY GAME SOUNDS, WON'T WORK WITH CUSTOM SOUNDS!!!!!']");

    CreateTimer(1.0, CheckTime, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    AutoExecConfig(true, "autorestart++");

    RegAdminCmd("sm_autorestartnow", Command_AutoRestartNow, ADMFLAG_ROOT, "sm_autorestartnow <seconds>");
}

void PlaySoundToAll()
{
    char sSound[PLATFORM_MAX_PATH];
    g_hSoundPath.GetString(sSound, sizeof(sSound));

    char sCommand[PLATFORM_MAX_PATH + 32];
    Format(sCommand, sizeof(sCommand), "play */%s", sSound);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            ClientCommand(i, sCommand);
        }
    }
}

public Action CheckTime(Handle timer)
{
    char sTime[8];
    FormatTime(sTime, sizeof(sTime), "%H%M", GetTime());
    int currentTime = StringToInt(sTime);

    int seconds;
    FormatTime(sTime, sizeof(sTime), "%S", GetTime());
    seconds = StringToInt(sTime);

    if (currentTime == g_hRestartTime.IntValue && seconds == 0 && g_iLastChecked != currentTime)
    {
        g_iLastChecked = currentTime;
        int preTimer = g_hPreTimer.IntValue;
        PreRestart(preTimer, false);
    }

    return Plugin_Continue;
}

void PreRestart(int seconds, bool isNow)
{
    for (int i = 0; i < seconds; i++)
    {
        CreateTimer(float(i), isNow ? ShowCountdownNow : ShowCountdownScheduled, seconds - i);
    }
    CreateTimer(float(seconds), PerformRestart);
}

public Action ShowCountdownScheduled(Handle timer, any secondsLeft)
{
    char formatMsg[192];
    g_hRestartMessage.GetString(formatMsg, sizeof(formatMsg));
    CPrintToChatAll(formatMsg, secondsLeft);
    PlaySoundToAll();
    return Plugin_Continue;
}

public Action ShowCountdownNow(Handle timer, any secondsLeft)
{
    char formatMsg[192];
    g_hRestartNowMsg.GetString(formatMsg, sizeof(formatMsg));
    CPrintToChatAll(formatMsg, secondsLeft);
    PlaySoundToAll();
    return Plugin_Continue;
}

public Action PerformRestart(Handle timer)
{
    if (g_hWriteToLog.BoolValue)
    {
        char logPath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, logPath, sizeof(logPath), "logs/autorestart2_restarts.log");

        Handle file = OpenFile(logPath, "a");
        if (file != INVALID_HANDLE)
        {
            char timestamp[64];
            FormatTime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", GetTime());
            WriteFileLine(file, "%s - Server restarted.", timestamp);
            CloseHandle(file);
        }
    }

    ServerCommand("_restart");
    return Plugin_Continue;
}

public Action Command_AutoRestartNow(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_autorestartnow <seconds>");
        return Plugin_Handled;
    }

    char arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    int delay = StringToInt(arg);

    if (delay < 1 || delay > 120)
    {
        ReplyToCommand(client, "Delay must be between 1 and 120 seconds.");
        return Plugin_Handled;
    }

    PreRestart(delay, true);
    ReplyToCommand(client, "Server will restart in %d seconds.", delay);
    return Plugin_Handled;
}
