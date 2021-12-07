#include <sourcemod>
#include <geoip>
#include <cstrike>
#include <multi1v1>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
  name = "Arena Country TAG",
  version = "1.0",
  author = "ESK0",
  description = "",
  url = "www.github.com/ESK0"
};
public void OnPluginStart()
{
  LoadTranslations("multi1v1.phrases");
}
public void Multi1v1_AfterPlayerSetup(int client)
{
  int iArena = Multi1v1_GetArenaNumber(client);
  char szClanTag[32];
  char sIP[26];
  char szBuffer[3];
  GetClientIP(client, sIP, sizeof(sIP));
  GeoipCode2(sIP, szBuffer);
  Format(szClanTag, sizeof(szClanTag), "%T | %s", "ArenaClanTag",LANG_SERVER, iArena, szBuffer);
  CS_SetClientClanTag(client, szClanTag);
}
