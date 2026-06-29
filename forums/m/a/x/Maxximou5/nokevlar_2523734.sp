#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "[CS:GO] No Armor"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Dissallows clients from buying armor."
#define PLUGIN_URL              "http://maxximou5.com/"

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
    if (GetEngineVersion() != Engine_CSGO)
    {
        SetFailState("ERROR: This plugin is designed only for CS:GO.");
    }
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
    if (IsValidClient(client) && (StrContains(weapon, "kevlar") || StrContains(weapon, "assaultsuit") || StrContains(weapon, "vesthlm")))
    {
    	PrintToChat(client, "[\x04SHOP\x01] Buying kevlar is not allowed!")
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    if (!(0 < client <= MaxClients)) return false;
    if (!IsClientInGame(client)) return false;
    if (IsFakeClient(client)) return false;
    return true;
}
