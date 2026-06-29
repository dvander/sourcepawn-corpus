#pragma semicolon 1

#include <sourcemod>
#include <store>

new Float:g_timeInSeconds;
new g_creditsPerTick;
new bool:g_enableMessagePerTick;

new String:g_currencyName[64];

public Plugin:myinfo =
{
	name        = "[Store] Distributor",
	author      = "alongub",
	description = "Distributor component for [Store]",
	version     = STORE_VERSION,
	url         = "https://github.com/alongubkin/store"
};

/**
 * Plugin is loading.
 */
public OnPluginStart() 
{
	LoadConfig();
	LoadTranslations("store.phrases");

	CreateTimer(g_timeInSeconds, ForgivePoints, _, TIMER_REPEAT);
}

/**
 * Configs just finished getting executed.
 */
public OnConfigsExecuted()
{
	Store_GetCurrencyName(g_currencyName, sizeof(g_currencyName));
}

/**
 * Load plugin config.
 */
LoadConfig() 
{
	new Handle:kv = CreateKeyValues("root");
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/store/distributor.cfg");
	
	if (!FileToKeyValues(kv, path)) 
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}

	g_timeInSeconds = KvGetFloat(kv, "time_in_seconds", 180.0);
	g_creditsPerTick = KvGetNum(kv, "credits_per_tick", 3);
	g_enableMessagePerTick = bool:KvGetNum(kv, "enable_message_per_tick", 0);

	CloseHandle(kv);
}


public Action:ForgivePoints(Handle:timer)
{
	new accountIds[MaxClients];
	new count = 0;
	
	for (new client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client))
		{
			accountIds[count] = Store_GetClientAccountID(client);
			count++;

			if (g_enableMessagePerTick)
			{
				PrintToChat(client, "%t", "Received Credits", g_creditsPerTick, g_currencyName);
			}
		}
	}

	Store_GiveCreditsToUsers(accountIds, count, g_creditsPerTick);
}