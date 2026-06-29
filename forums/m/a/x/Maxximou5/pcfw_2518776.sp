#include <cstrike> 
#include <sdktools>

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "[CS:GO] Pricecheck For Warmup"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Allows for clients to be able to buy weapons for no amount during warmup."
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

public Action CS_OnGetWeaponPrice(int client, const char[] weapon, int &price)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		price = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}