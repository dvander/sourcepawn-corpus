#pragma semicolon 1

#include <sourcemod>
#include <store>

#define MAX_FILTERS 128

enum Filter
{
	String:FilterMap[128],
	FilterPlayerCount,
	FilterFlags,
	Float:FilterMultiplier,
	Float:FilterMinimumMultiplier,
	Float:FilterMaximumMultiplier,
	FilterAddend,
	FilterMinimumAddend,
	FilterMaximumAddend,
	FilterTeam
}

new String:g_currencyName[64];

new Float:g_timeInSeconds;
new bool:g_enableMessagePerTick;

new g_baseMinimum;
new g_baseMaximum;

new g_filters[MAX_FILTERS][Filter];
new g_filterCount;

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
public OnAllPluginsLoaded()
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

	g_timeInSeconds = KvGetFloat(kv, "time_per_distribute", 180.0);
	g_enableMessagePerTick = bool:KvGetNum(kv, "enable_message_per_distribute", 0);

	if (KvJumpToKey(kv, "distribution"))
	{
		g_baseMinimum = KvGetNum(kv, "base_minimum", 1);
		g_baseMaximum = KvGetNum(kv, "base_maximum", 3);

		if (KvJumpToKey(kv, "filters"))
		{
			g_filterCount = 0;

			if (KvGotoFirstSubKey(kv))
			{
				do
				{
					g_filters[g_filterCount][FilterMultiplier] = KvGetFloat(kv, "multiplier", 1.0);
					g_filters[g_filterCount][FilterMinimumMultiplier] = KvGetFloat(kv, "min_multiplier", 1.0);
					g_filters[g_filterCount][FilterMaximumMultiplier] = KvGetFloat(kv, "max_multiplier", 1.0);

					g_filters[g_filterCount][FilterAddend] = KvGetNum(kv, "addend");
					g_filters[g_filterCount][FilterMinimumAddend] = KvGetNum(kv, "min_addend");
					g_filters[g_filterCount][FilterMaximumAddend] = KvGetNum(kv, "max_addend");

					g_filters[g_filterCount][FilterPlayerCount] = KvGetNum(kv, "player_count", 0);
					g_filters[g_filterCount][FilterTeam] = KvGetNum(kv, "team", -1);
                                       
					decl String:flags[32];
					KvGetString(kv, "flags", flags, sizeof(flags));

					if (!StrEqual(flags, ""))
						g_filters[g_filterCount][FilterFlags] = ReadFlagString(flags);

					KvGetString(kv, "map", g_filters[g_filterCount][FilterMap], 32);

					g_filterCount++;
				} while (KvGotoNextKey(kv));
			}
		}
	}

	CloseHandle(kv);
}


public Action:ForgivePoints(Handle:timer)
{
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));

	new clientCount = GetClientCount();

	new accountIds[MaxClients];
	new credits[MaxClients];

	new count = 0;
	
	for (new client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client))
		{
			accountIds[count] = GetSteamAccountID(client);
			credits[count] = Calculate(client, map, clientCount);

			if (g_enableMessagePerTick)
			{
				if (credits[count] >= 0) PrintToChat(client, "%s%t", STORE_PREFIX, "Received Credits", credits[count], g_currencyName);
				else PrintToChat(client, "%s%t", STORE_PREFIX, "Lost Credits", credits[count], g_currencyName);
			}

			count++;
		}
	}

	Store_GiveDifferentCreditsToUsers(accountIds, count, credits);
}

Calculate(client, const String:map[], clientCount)
{
	new min = g_baseMinimum;
	new max = g_baseMaximum;

	for (new filter = 0; filter < g_filterCount; filter++)
	{
		if ((g_filters[filter][FilterPlayerCount] == 0 || clientCount >= g_filters[filter][FilterPlayerCount]) && 
			(StrEqual(g_filters[filter][FilterMap], "") || StrEqual(g_filters[filter][FilterMap], map)) && 
			(g_filters[filter][FilterFlags] == 0 || HasPermission(client, g_filters[filter][FilterFlags])) &&
			(g_filters[filter][FilterTeam] == -1 || g_filters[filter][FilterTeam] == GetClientTeam(client)))
		{
			min = RoundToZero(min * g_filters[filter][FilterMultiplier] * g_filters[filter][FilterMinimumMultiplier]) 
					+ g_filters[filter][FilterAddend] + g_filters[filter][FilterMinimumAddend];

			max = RoundToZero(max * g_filters[filter][FilterMultiplier] * g_filters[filter][FilterMaximumMultiplier])
					+ g_filters[filter][FilterAddend] + g_filters[filter][FilterMaximumAddend];
		}
	}

	return GetRandomInt(min, max);
}

bool:HasPermission(client, flags)
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID)
		return false;

	new count = 0, found = 0;
	for (new i = 0; i <= 20; i++)
    {
		if (flags & (1<<i))
		{
			count++;

			if (GetAdminFlag(admin, AdminFlag:i))
				found++;
		}
	}

	if (count == found)
		return true;

	return false;
}
