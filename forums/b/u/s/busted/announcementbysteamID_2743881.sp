#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <colorvariables>


#define CONFIG_PATH "configs/announcementsteamID.txt"

public Plugin myinfo =
{
    name = "Announcement by SteamID",
    author = "Busted",
    description = "Print a message and play a sound when a player connect by steam ID",
    version = "1.1",
    url = "https://attawaybaby.com/"
};

char sz_Path [PLATFORM_MAX_PATH];
char soundBuffer [PLATFORM_MAX_PATH];
char szBuffer [256];
char s1Buffer [256];
char s2Buffer [256];
char g_SteamID[MAXPLAYERS + 1][32];


public void OnConfigsExecuted()
{
    BuildPath(Path_SM, sz_Path, sizeof(sz_Path), "%s", CONFIG_PATH);
    
    if (FileExists(sz_Path))
    {
        Handle kv = CreateKeyValues("Custom Announcements");
        if (FileToKeyValues(kv, sz_Path) && KvGotoFirstSubKey(kv))
        {
            do
            {
                KvGetString(kv, "sound", szBuffer, sizeof(szBuffer));
                Format(soundBuffer, sizeof(soundBuffer), "sound/%s", szBuffer);

                PrecacheSoundAny(szBuffer);
                AddFileToDownloadsTable(soundBuffer);

            } while (KvGotoNextKey(kv));
        }
        delete kv;
    }
    else
    {
        LogError("[AnnouncementbySteamID] % File not found", CONFIG_PATH);
        PrintToServer("[AnnouncementbySteamID] % File not found", CONFIG_PATH);
    }
}

public void OnPluginStart()
{

}

public void OnClientPutInServer(int client)
{
    if (!IsValidClient(client))
    return;


    GetClientAuthId(client, AuthId_Steam2, g_SteamID[client], MAX_NAME_LENGTH, true);
}

public void OnClientPostAdminCheck(int client)
{
    LoadConfigFile(client);
}

public void LoadConfigFile(int client)
{
	BuildPath(Path_SM, sz_Path, sizeof(sz_Path), "%s", CONFIG_PATH);

	if (FileExists(sz_Path))
    {
        Handle kv = CreateKeyValues("Custom Announcements");
        if (FileToKeyValues(kv, sz_Path) && KvGotoFirstSubKey(kv))
        {
            do
            {
                KvGetString(kv, "steamid", szBuffer, sizeof(szBuffer), "none");
                // Check if this keyvalue has a steamid
                if (!StrEqual(szBuffer, "none"))
                {
                    if(StrEqual(g_SteamID[client], szBuffer))
                    {
                        KvGetString(kv, "sound", s1Buffer, sizeof(szBuffer));
                        CreateTimer(2.0, send_Sound);
                        //EmitSoundToAllAny(szBuffer);

                        KvGetString(kv, "connectmsg", s2Buffer, sizeof(szBuffer));
                        CreateTimer(2.0, send_Message);
                        //PrintToChatAll("%s", szBuffer);
                        break;
                    }

                }

            } while (KvGotoNextKey(kv));
        }
        delete kv;
    }
	else
    {
        LogError("[AnnouncementbySteamID] % File not found", CONFIG_PATH);
        PrintToServer("[AnnouncementbySteamID] % File not found", CONFIG_PATH); 
    }
}

public Action send_Sound(Handle timer)
{
    EmitSoundToAllAny(s1Buffer);
    return Plugin_Continue;
}

public Action send_Message(Handle timer)
{
    CPrintToChatAll("%s", s2Buffer);
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if (client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
		return true;
	return false;
}