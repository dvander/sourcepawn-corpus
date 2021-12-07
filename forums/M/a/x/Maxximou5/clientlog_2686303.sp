#include <sourcemod>

#pragma newdecls required

ConVar g_cvCL_Enable;
ConVar g_cvCL_Folder;
ConVar g_cvCL_Active;

char g_sCmdLogPath[PLATFORM_MAX_PATH];

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "Client Log"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Logs a clients information when a client connects."
#define PLUGIN_URL              "https://maxximou5.com/"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

public void OnPluginStart()
{
    g_cvCL_Enable = CreateConVar("sm_client_log_enable", "1", "Enable logging for Client Log");
    g_cvCL_Folder = CreateConVar("sm_client_log_dir", "logs", "Path to where information for the file will be logged");
    g_cvCL_Active = CreateConVar("sm_client_log_active", "1", "Builds active list of clients when clientlog command is used");

    RegAdminCmd("sm_clientlog", Command_LoadClientLog, ADMFLAG_CHANGEMAP, "Toggles Client Log");

    AutoExecConfig();

    BuildFiles();
    BuildActiveList();
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
        LogReport(client);
}

public Action Command_LoadClientLog(int client, int args)
{
    if (g_cvCL_Enable.BoolValue)
    {
        g_cvCL_Enable.SetInt(0);
        ReplyToCommand(client, "[CL] Client Log has been disabled.");
    }
    else
    {
        if (g_cvCL_Active.BoolValue)
            BuildActiveList();

        g_cvCL_Enable.SetInt(1);
        ReplyToCommand(client, "[CL] Client Log has been enabled.");
    }

    return Plugin_Handled;
}

bool BuildFiles()
{
    if (g_cvCL_Enable.BoolValue)
    {
        char sDate[32];
        char sPath[PLATFORM_MAX_PATH];
        char sFolder[PLATFORM_MAX_PATH];
        char sWorkshopID[PLATFORM_MAX_PATH];
        char sMap[PLATFORM_MAX_PATH];
        char sWorkshop[PLATFORM_MAX_PATH];

        GetCurrentMap(sMap, PLATFORM_MAX_PATH);

        g_cvCL_Folder.GetString(sFolder, sizeof(sFolder));
        FormatTime(sDate, sizeof(sDate), "%Y-%m-%d_%H:%M:%S", GetTime());

        if (StrContains(sMap, "workshop", false) != -1)
        {
            GetCurrentWorkshopMap(sWorkshop, PLATFORM_MAX_PATH, sWorkshopID, sizeof(sWorkshopID) - 1);
            Format(sPath, sizeof(sPath), "%s/CL_%s_%s.log", sFolder, sWorkshop,sDate);
        }
        else
            Format(sPath, sizeof(sPath), "%s/CL_%s_%s.log", sFolder, sMap,sDate);

        BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), sPath);
        CheckDirectory(sFolder);
    }
}

void LogReport(int client)
{
    char sAuthid[64];
    char sIPAddress[64];

    GetClientIP(client, sIPAddress, sizeof(sIPAddress));
    GetClientAuthId(client, AuthId_Steam2, sAuthid, sizeof(sAuthid), false)

    LogToFileEx(g_sCmdLogPath, "<%N> [%s] <%s>", client, sAuthid, sIPAddress);
}

void CheckDirectory(char path[PLATFORM_MAX_PATH])
{
    if (!DirExists(path))
    {
        if (!CreateDirectory(path, 511))
        {
            LogError("[CL] Failed to create directory %s", path);
            SetFailState("[CL] Failed to create directory %s", path);
        }
    }
}

void GetCurrentWorkshopMap(char[] map, int mapbuffer, char[] workshopID, int workshopbuffer)
{
    char currentmap[128]
    char currentmapbuffer[2][64]

    GetCurrentMap(currentmap, 127)
    ReplaceString(currentmap, sizeof(currentmap), "workshop/", "", false)
    ExplodeString(currentmap, "/", currentmapbuffer, 2, 63)

    strcopy(map, mapbuffer, currentmapbuffer[1])
    strcopy(workshopID, workshopbuffer, currentmapbuffer[0])
}

void BuildActiveList()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            OnClientPutInServer(i);
    }
}