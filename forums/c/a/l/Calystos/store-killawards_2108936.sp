#pragma semicolon 1

#include <sourcemod>
#include <store>

#define MAX_FILTERS 128
#define MAX_FILTER_KVLEN 255

enum Filter
{
	String:FilterKey[MAX_FILTER_KVLEN],
	String:FilterValue[MAX_FILTER_KVLEN],
	String:FilterType[10],
	FilterAddend,
	Float:FilterMultiplier
}

new String:g_currencyName[64];

new g_filters[MAX_FILTERS][Filter];
new g_filterCount;

new g_points_kill;
new g_suicide;
new g_points_teamkill;
new bool:g_enable_message_per_kill;

public Plugin:myinfo =
{
	name        = "[Store] Kill Awards",
	author      = "eXemplar",
	description = "Award kills component for [Store]",
	version     = STORE_VERSION,
	url         = "https://github.com/eggsampler/store-killawards"
};

/**
 * Plugin is loading.
 */
public OnPluginStart() 
{
	LoadConfig();
	LoadTranslations("store.killawards");

	HookEvent("player_death", Event_PlayerDeath);
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
	BuildPath(Path_SM, path, sizeof(path), "configs/store/killawards.cfg");
	
	if (!FileToKeyValues(kv, path)) 
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}

	g_points_kill = KvGetNum(kv, "points_kill", 2);
	g_suicide = KvGetNum(kv, "points_suicide", -1);
	g_points_teamkill = KvGetNum(kv, "points_teamkill", -1);
	g_enable_message_per_kill = bool:KvGetNum(kv, "enable_message_per_kill", 0);

	if (KvJumpToKey(kv, "filters"))
	{
		g_filterCount = 0;

		if (KvGotoFirstSubKey(kv))
		{
			do
			{
				decl String:key_name[MAX_FILTER_KVLEN];
				KvGetSectionName(kv, key_name, sizeof(key_name));

				decl String:type[10];
				KvGetString(kv, "type", type, 10);

				if (KvGotoFirstSubKey(kv))
				{
					do
					{
						strcopy(g_filters[g_filterCount][FilterKey], MAX_FILTER_KVLEN, key_name);
						KvGetSectionName(kv, g_filters[g_filterCount][FilterValue], MAX_FILTER_KVLEN);
						strcopy(g_filters[g_filterCount][FilterType], 10, type);
						g_filters[g_filterCount][FilterAddend] = KvGetNum(kv, "addend", 0);
						g_filters[g_filterCount][FilterMultiplier] = KvGetFloat(kv, "multiplier", 1.0);

						//LogMessage("Adding filter %i, k=%s v=%s t=%s, a=%i, m=%f", g_filterCount, g_filters[g_filterCount][FilterKey], g_filters[g_filterCount][FilterValue], g_filters[g_filterCount][FilterType], g_filters[g_filterCount][FilterAddend], g_filters[g_filterCount][FilterMultiplier]);

						g_filterCount++;
					} while (KvGotoNextKey(kv));

					KvGoBack(kv);
				}

			} while (KvGotoNextKey(kv));
		}
	}

	CloseHandle(kv);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_died = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	// ignore invalid clients or fake clients (bots)
	if (client_killer <= 0 || IsFakeClient(client_killer))
	{
		return Plugin_Continue;
	}

	// suicides
	if (client_killer == client_died) 
	{
		new points = Calculate(event, g_suicide);
		if (points != 0)
		{
			GiveCreditsToClient(client_killer, points);
			if (g_enable_message_per_kill)
			{
				if (points >= 0) PrintToChat(client_killer, "%s%t", STORE_PREFIX, "Received Credits Suicide", points, g_currencyName);
				else PrintToChat(client_killer, "%s%t", STORE_PREFIX, "Lost Credits Suicide", points, g_currencyName);
			}
		}
		return Plugin_Continue;
	}

	if (GetClientTeam(client_killer) == GetClientTeam(client_died))
	{
		new points = Calculate(event, g_points_teamkill);
		if (points != 0)
		{
			GiveCreditsToClient(client_killer, points);
			if (g_enable_message_per_kill)
			{
				if (points >= 0) PrintToChat(client_killer, "%s%t", STORE_PREFIX, "Received Credits TeamKill", points, g_currencyName, client_died);
				else PrintToChat(client_killer, "%s%t", STORE_PREFIX, "Lost Credits TeamKill", points, g_currencyName, client_died);
			}
		}
		return Plugin_Continue;
	}

	new points = Calculate(event, g_points_kill);
	if (points != 0)
	{
		GiveCreditsToClient(client_killer, points);
		if (g_enable_message_per_kill)
		{
			if (points >= 0) PrintToChat(client_killer, "%s%t", STORE_PREFIX, "Received Credits Kill", points, g_currencyName, client_died);
			else PrintToChat(client_killer, "%s%t", STORE_PREFIX, "Lost Credits Kill", points, g_currencyName, client_died);
		}
	}

	return Plugin_Continue;
}

Calculate(Handle:event, basepoints)
{
	new points = basepoints;

	for (new filter = 0; filter < g_filterCount; filter++)
	{
		new bool:matches = false;
		if (StrEqual(g_filters[filter][FilterType], "string"))
		{
			decl String:value[MAX_FILTER_KVLEN];
			GetEventString(event, g_filters[filter][FilterKey], value, sizeof(value));
			if(StrEqual(value, g_filters[filter][FilterValue]))
			{
				matches = true;
			}
			//LogMessage("testing %s %s = %s %i", g_filters[filter][FilterKey], g_filters[filter][FilterValue], value, matches);
		}
		else if (StrEqual(g_filters[filter][FilterType], "int"))
		{
			new value = GetEventInt(event, g_filters[filter][FilterKey]);
			if (value == StringToInt(g_filters[filter][FilterValue]))
			{
				matches = true;
			}
			//LogMessage("testing %s %s = %i %i", g_filters[filter][FilterKey], g_filters[filter][FilterValue], value, matches);
		}
		else if (StrEqual(g_filters[filter][FilterType], "bool"))
		{
			new bool:value = bool:GetEventInt(event, g_filters[filter][FilterKey]);
			if (value == bool:StringToInt(g_filters[filter][FilterValue]))
			{
				matches = true;
			}
			//LogMessage("testing %s %s = %i %i", g_filters[filter][FilterKey], g_filters[filter][FilterValue], value, matches);
		}
		else if (StrEqual(g_filters[filter][FilterType], "float"))
		{
			new Float:value = GetEventFloat(event, g_filters[filter][FilterKey]);
			if (value == StringToFloat(g_filters[filter][FilterValue]))
			{
				matches = true;
			}
			//LogMessage("testing %s %s = %f %i", g_filters[filter][FilterKey], g_filters[filter][FilterValue], value, matches);
		}

		if(matches == true)
		{
			points = RoundToZero(points * g_filters[filter][FilterMultiplier]);
			if (points >= 0)
			{
				points += g_filters[filter][FilterAddend];
			}
			else
			{
				points -= g_filters[filter][FilterAddend];
			}
		}
	}

	return points;
}

GiveCreditsToClient(client, credits)
{
	new id[1];
	id[0] = GetSteamAccountID(client);
	Store_GiveCreditsToUsers(id, 1, credits);
}
