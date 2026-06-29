#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

char g_sMapName[64];

public Plugin myinfo = {
    name = "Server Browser - Mapname Stripper",
    author = "Techno",
    description = "Strips the workshop string from map names",
    version = "1.0.0",
    url = "https://tech-no.me"
};

public void OnMapStart()
{
    GetCurrentMap(g_sMapName, sizeof(g_sMapName));
    GetMapDisplayName(g_sMapName, g_sMapName, sizeof(g_sMapName));
}

public void OnGameFrame()
{
    SteamWorks_SetMapName(g_sMapName);
}
