#pragma semicolon 1
#include <sourcemod>
#include <regex>

public Plugin myinfo =
{
    name = "Anti-Ad Logger",
    author = "D₳ⱮPƑL✪Ҡ",
    description = "Logs IPs and domains in chat messages",
    version = "1.2",
    url = "https://steamcommunity.com/profiles/76561199509359636/ /// https://mad-cats.com/"
};

Handle g_hRegex;

public void OnPluginStart()
{
    g_hRegex = CompileRegex("\\b(?:[0-9]{1,3}[.,][0-9]{1,3}[.,][0-9]{1,3}[.,][0-9]{1,3}(:[0-9]{2,5})?|[a-zA-Z0-9,-]+[.,][a-zA-Z]{2,})\\b");
    HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
    
    char logPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, logPath, sizeof(logPath), "logs/antiadlogs.txt");
    File file = OpenFile(logPath, "a");
    if (file)
    {
        CloseHandle(file);
    }
}

public void OnPluginEnd()
{
    if (g_hRegex != INVALID_HANDLE)
    {
        CloseHandle(g_hRegex);
    }
}

public Action Event_PlayerSay(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    char message[256];
    GetEventString(event, "text", message, sizeof(message));
    
    if (MatchRegex(g_hRegex, message))
    {
        char logPath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, logPath, sizeof(logPath), "logs/antiadlogs.txt");
        
        char steamID[32];
        GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
        
        char timeStr[64];
        FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S");
        
        File file = OpenFile(logPath, "a");
        if (file)
        {
            WriteFileLine(file, "%s | %s | %N: %s", timeStr, steamID, client, message);
            CloseHandle(file);
        }
    }
    return Plugin_Continue;
}