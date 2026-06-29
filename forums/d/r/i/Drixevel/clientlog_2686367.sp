#include <sourcemod>

#pragma newdecls required

ConVar g_cvCL_Enable;
ConVar g_cvCL_Folder;
ConVar g_cvCL_Active;

char g_sCmdLogPath[PLATFORM_MAX_PATH];

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "Client Log"
#define PLUGIN_AUTHOR           "Maxximou5, Drixevel"
#define PLUGIN_DESCRIPTION      "Logs a clients information when a client connects."
#define PLUGIN_URL              "https://maxximou5.com/"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	g_cvCL_Enable = CreateConVar("sm_client_log_enable", "1", "Enable logging for Client Log");
	g_cvCL_Folder = CreateConVar("sm_client_log_dir", "logs", "Path to where information for the file will be logged");
	g_cvCL_Active = CreateConVar("sm_client_log_active", "1", "Builds active list of clients when clientlog command is used");
	g_cvCL_Folder.AddChangeHook(onFolderChange);
	g_cvCL_Active.AddChangeHook(onActiveChange);
	AutoExecConfig();
	
	RegAdminCmd("sm_clientlog", Command_LoadClientLog, ADMFLAG_CHANGEMAP, "Toggles Client Log");
}

public void onFolderChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue))
		return;
	
	BuildDir();
}

public void onActiveChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue))
		return;
	
	if (StrEqual(newValue, "1", false))
		BuildActiveList();
}

public void OnConfigsExecuted()
{
	if (!g_cvCL_Enable.BoolValue)
		return;
	
	BuildDir();
	
	if (g_cvCL_Active.BoolValue)
		BuildActiveList();
}

void BuildDir()
{
	char sMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sMap, sizeof(sMap));
	
	char sFolder[PLATFORM_MAX_PATH];
	g_cvCL_Folder.GetString(sFolder, sizeof(sFolder));
	
	char sDate[32];
	FormatTime(sDate, sizeof(sDate), "%Y-%m-%d_%H_%M_%S");
	
	char sPath[PLATFORM_MAX_PATH];
	if (StrContains(sMap, "workshop", false) != -1)
	{
		char sWorkshop[PLATFORM_MAX_PATH]; char sWorkshopID[PLATFORM_MAX_PATH];
		GetCurrentWorkshopMap(sWorkshop, sizeof(sWorkshop), sWorkshopID, sizeof(sWorkshopID) - 1);
		Format(sPath, sizeof(sPath), "%s/CL_%s_%s.log", sFolder, sWorkshop, sDate);
	}
	else
		Format(sPath, sizeof(sPath), "%s/CL_%s_%s.log", sFolder, sMap, sDate);

	BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), sPath);
	PrintToServer("Saving SteamIDs to path: %s", g_sCmdLogPath);
		
	if (!DirExists(sFolder) && !CreateDirectory(sFolder, 511))
		SetFailState("[CL] Failed to create directory %s", sFolder);
}

public void OnClientPutInServer(int client)
{
	if (!g_cvCL_Enable.BoolValue || IsFakeClient(client))
		return;
	
	char sAuthid[64];
	GetClientAuthId(client, AuthId_Steam2, sAuthid, sizeof(sAuthid), false);
	
	char sIPAddress[64];
	GetClientIP(client, sIPAddress, sizeof(sIPAddress));
	
	LogToFileEx(g_sCmdLogPath, "<%N> [%s] <%s>", client, sAuthid, sIPAddress);
}

public Action Command_LoadClientLog(int client, int args)
{
    if (g_cvCL_Enable.BoolValue)
    {
        g_cvCL_Enable.IntValue = 0;
        ReplyToCommand(client, "[CL] Client Log has been disabled.");
    }
    else
    {
        if (g_cvCL_Active.BoolValue)
            BuildActiveList();

        g_cvCL_Enable.IntValue = 1;
        ReplyToCommand(client, "[CL] Client Log has been enabled.");
    }

    return Plugin_Handled;
}

void GetCurrentWorkshopMap(char[] map, int mapbuffer, char[] workshopID, int workshopbuffer)
{
    char currentmap[128];
    char currentmapbuffer[2][64];

    GetCurrentMap(currentmap, 127)
    ReplaceString(currentmap, sizeof(currentmap), "workshop/", "", false);
    ExplodeString(currentmap, "/", currentmapbuffer, 2, 63);

    strcopy(map, mapbuffer, currentmapbuffer[1]);
    strcopy(workshopID, workshopbuffer, currentmapbuffer[0]);
}

void BuildActiveList()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            OnClientPutInServer(i);
}