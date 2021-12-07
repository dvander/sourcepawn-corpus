#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <restrict>

#define PLUGIN_VERSION "2.2"
#define MAX_WEAPONS 55
#define NOTIFY_TIME 5

new bool:g_bEnabled,
	g_iWarmup,
	String:g_strConfigPath[PLATFORM_MAX_PATH],
	Handle:g_hClientTrie[MAXPLAYERS + 1] = {INVALID_HANDLE, ...},
	Handle:g_hWeaponTrie = INVALID_HANDLE,
	g_iMapStartTime = 0,
	bool:g_bLate,
	bool:g_bWeaponRestrictExists = false,
	g_iCanPrintToClient[MAXPLAYERS + 1] = {false, ...};

public Plugin:myinfo =
{
	name = "Weapon Limitation By SteamID",
	author = "Mini, Original Idea By: .:€S C 90 ZAP Killer.be:.",
	description = "Per Steam ID weapon restriction",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Restrict_IsWarmupRound");
	g_bLate = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("zk_wlbsid_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD);

	new Handle:conVar;
	conVar = CreateConVar("zk_wlbsid_enabled", "1", "Plugin enabled?");
	g_bEnabled = GetConVarBool(conVar);
	HookConVarChange(conVar, OnEnableChanged);

	conVar = CreateConVar("zk_wlbsid_warmup", "-1", "Warmup Mode:\n-1 - Detect warmup time through the Weapon Restriction plugin\n0 - Disable warmup timer\n 1 or more - Number of seconds that warmup is enabled.");
	g_iWarmup = GetConVarInt(conVar);
	HookConVarChange(conVar, OnWarmupChanged);

	conVar = CreateConVar("zk_wlbsid_config", "configs/zk_wlbsid.txt", "The config path");
	GetConVarString(conVar, g_strConfigPath, sizeof(g_strConfigPath));
	BuildPath(Path_SM, g_strConfigPath, sizeof(g_strConfigPath), g_strConfigPath);
	HookConVarChange(conVar, OnPathChanged);

	AutoExecConfig();

	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		g_hClientTrie[i] = INVALID_HANDLE;
	}

	RegAdminCmd("sm_listwepblock", Command_ListWeaponBlocked, ADMFLAG_GENERIC);
	RegAdminCmd("zk_addplayer", Command_AddPlayer, ADMFLAG_RCON);
	RegAdminCmd("zk_addsteamid", Command_AddSteamID, ADMFLAG_RCON);
	RegAdminCmd("zk_removeplayer", Command_RemovePlayer, ADMFLAG_RCON);
	RegAdminCmd("zk_removesteamid", Command_RemoveSteamId, ADMFLAG_RCON);
	RegAdminCmd("zk_removeplayerall", Command_RemovePlayerAll, ADMFLAG_RCON);
	RegAdminCmd("zk_removesteamidall", Command_RemoveSteamIDAll, ADMFLAG_RCON);
	RegAdminCmd("zk_reload", Command_Reload, ADMFLAG_RCON);

	g_iMapStartTime = GetTime();

	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	HookEvent("weapon_fire_on_empty", Event_WeaponFire, EventHookMode_Pre);

	if (g_bLate)
	{
		ParseConfiguration();
		ReloadPlayers();
	}

	g_bWeaponRestrictExists = LibraryExists("weaponrestrict");

	LoadTranslations("common.phrases");
}

public OnMapStart()
{
	g_iMapStartTime = GetTime();
}

public OnConfigsExecuted()
{
	ParseConfiguration();
}

public OnLibraryAdded(const String:name[])
{
	if (!strcmp(name, "weaponrestrict"))
	{
		g_bWeaponRestrictExists = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (!strcmp(name, "weaponrestrict"))
	{
		g_bWeaponRestrictExists = false;
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bEnabled && WarmupPasses() && (g_hClientTrie[client] != INVALID_HANDLE))
	{
		decl String:weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		new bool:block;
		if (GetTrieValue(g_hClientTrie[client], weapon, block))
		{
			if (block)
			{
				new time = GetTime();
				if ((time - g_iCanPrintToClient[client]) >= NOTIFY_TIME)
				{
					PrintToChat(client, "[SM] This weapon has been restricted for you.");
					g_iCanPrintToClient[client] = time;
				}
				new weaponIndex = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				CS_DropWeapon(client, weaponIndex, false, true);
				return Plugin_Handled;
			}
		}

	}
	return Plugin_Continue;
}

public Action:Command_RemoveSteamIDAll(client, args)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	if (args >= 1)
	{
		new Handle:kv = CreateKeyValues("Steam ID Restrictions");
		if (!FileToKeyValues(kv, g_strConfigPath))
		{
			CloseHandle(kv);
			ReplyToCommand(client, "[SM] Could not find config file.");
			SetFailState("Config file \"%s\" doesn't exist.", g_strConfigPath);
			return Plugin_Handled;
		}
		KvSavePosition(kv);
		decl String:steamId[32];
		GetCmdArg(1, steamId, sizeof(steamId));
		if (!KvJumpToKey(kv, steamId))
		{
			ReplyToCommand(client, "[SM] No weapons restricted for %s", steamId);
			return Plugin_Handled;
		}
		
		if (KvDeleteThis(kv) == 0)
		{
			ReplyToCommand(client, "[SM] Could not unrestrict all weapons for %s", steamId);
			return Plugin_Handled;
		}

		KvRewind(kv);
		if (!KeyValuesToFile(kv, g_strConfigPath))
		{
			ReplyToCommand(client, "[SM] Could not unrestrict all weapons for %s", steamId);
		}
		else
		{
			ReplyToCommand(client, "[SM] Unrestricted all weapons for %s", steamId);
			ParseConfiguration();
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: zk_removesteamidall <Steam ID>");
	}
	return Plugin_Handled;
}

public Action:Command_RemovePlayerAll(client, args)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	if (args >= 1)
	{
		decl String:strClient[256];
		GetCmdArg(1, strClient, sizeof(strClient));
		new target = FindTarget(client, strClient);
		if ((target > 0 && target <= MaxClients) && IsClientAuthorized(target) && IsClientInGame(target))
		{
			new Handle:kv = CreateKeyValues("Steam ID Restrictions");
			if (!FileToKeyValues(kv, g_strConfigPath))
			{
				CloseHandle(kv);
				ReplyToCommand(client, "[SM] Could not find config file.");
				SetFailState("Config file \"%s\" doesn't exist.", g_strConfigPath);
				return Plugin_Handled;
			}
			KvSavePosition(kv);
			decl String:steamId[32];
			GetClientAuthString(target, steamId, sizeof(steamId));
			if (!KvJumpToKey(kv, steamId))
			{
				ReplyToCommand(client, "[SM] No weapons restricted for %N", target);
				return Plugin_Handled;
			}
			
			if (KvDeleteThis(kv) == 0)
			{
				ReplyToCommand(client, "[SM] Could not unrestrict all weapons for %N", target);
				return Plugin_Handled;
			}

			KvRewind(kv);
			if (!KeyValuesToFile(kv, g_strConfigPath))
			{
				ReplyToCommand(client, "[SM] Could not unrestrict all weapons for %N", target);
			}
			else
			{
				ReplyToCommand(client, "[SM] Unrestricted all weapons for %N", target);
				ParseConfiguration();
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: zk_removeplayerall <name | #userid>");
	}
	return Plugin_Handled;
}

public Action:Command_RemoveSteamId(client, args)
{
	if (!g_bEnabled || g_hClientTrie[client] == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}
	if (args >= 2)
	{
		new Handle:kv = CreateKeyValues("Steam ID Restrictions");
		if (!FileToKeyValues(kv, g_strConfigPath))
		{
			CloseHandle(kv);
			ReplyToCommand(client, "[SM] Could not find config file.");
			SetFailState("Config file \"%s\" doesn't exist.", g_strConfigPath);
			return Plugin_Handled;
		}
		KvSavePosition(kv);
		decl String:steamId[64];
		GetCmdArg(1, steamId, sizeof(steamId));
		decl String:weapon[32];
		GetCmdArg(2, weapon, sizeof(weapon));
		if (!KvJumpToKey(kv, steamId))
		{
			ReplyToCommand(client, "[SM] Weapon %s is not restricted for %s.", weapon, steamId);
			return Plugin_Handled;
		}
		
		if (!KvJumpToKey(kv, weapon))
		{
			ReplyToCommand(client, "[SM] Weapon %s is not restricted for %s.", weapon, steamId);
			return Plugin_Handled;
		}

		if (KvDeleteThis(kv) == 0)
		{
			ReplyToCommand(client, "[SM] Could not unrestrict weapon for %s", steamId);
		}

		KvRewind(kv);
		if (!KeyValuesToFile(kv, g_strConfigPath))
		{
			ReplyToCommand(client, "[SM] Could not unrestrict weapon for %s", steamId);
		}
		else
		{
			ReplyToCommand(client, "[SM] Unrestricted weapon \"%s\" for %s", weapon, steamId);
			ParseConfiguration();
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: zk_addsteamid <name | #userid> <weapon>");
	}
	return Plugin_Handled;	
}

public Action:Command_RemovePlayer(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	if (args >= 2)
	{
		decl String:strClient[256];
		GetCmdArg(1, strClient, sizeof(strClient));
		new target = FindTarget(client, strClient);
		if ((target > 0 && target <= MaxClients) && IsClientAuthorized(target) && IsClientInGame(target))
		{	
			new Handle:kv = CreateKeyValues("Steam ID Restrictions");
			if (!FileToKeyValues(kv, g_strConfigPath))
			{
				CloseHandle(kv);
				ReplyToCommand(client, "[SM] Could not find config file.");
				SetFailState("Config file \"%s\" doesn't exist.", g_strConfigPath);
				return Plugin_Handled;
			}
			KvSavePosition(kv);
			decl String:weapon[32];
			GetCmdArg(2, weapon, sizeof(weapon));
			decl String:steamId[32];
			GetClientAuthString(target, steamId, sizeof(steamId));
			if (!KvJumpToKey(kv, steamId))
			{
				ReplyToCommand(client, "[SM] Weapon %s is not restricted for %N.", weapon, target);
				return Plugin_Handled;
			}
			
			if (!KvJumpToKey(kv, weapon))
			{
				ReplyToCommand(client, "[SM] Weapon %s is not restricted for %N.", weapon, target);
				return Plugin_Handled;
			}

			if (KvDeleteThis(kv) == 0)
			{
				ReplyToCommand(client, "[SM] Could not unrestrict weapon for %N", target);
			}

			KvRewind(kv);
			if (!KeyValuesToFile(kv, g_strConfigPath))
			{
				ReplyToCommand(client, "[SM] Could not unrestrict weapon for %N", target);
			}
			else
			{
				ReplyToCommand(client, "[SM] Unrestricted weapon \"%s\" for %N", weapon, target);
				ParseConfiguration();
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: zk_addsteamid <Steam ID> <weapon>");
	}
	return Plugin_Handled;
}

public Action:Command_AddSteamID(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	if (args >= 2)
	{
		new Handle:kv = CreateKeyValues("Steam ID Restrictions");
		if (!FileToKeyValues(kv, g_strConfigPath))
		{
			CloseHandle(kv);
			ReplyToCommand(client, "[SM] Could not find config file.");
			SetFailState("Config file \"%s\" doesn't exist.", g_strConfigPath);
			return Plugin_Handled;
		}
		KvSavePosition(kv);
		decl String:steamId[32];
		GetCmdArg(1, steamId, sizeof(steamId));
		decl String:weapon[32];
		GetCmdArg(2, weapon, sizeof(weapon));
		if (!KvJumpToKey(kv, steamId, true))
		{
			ReplyToCommand(client, "[SM] Could not restrict weapon for %s.", steamId);
			return Plugin_Handled;
		}
		KvSetString(kv, weapon, "restrict");
		KvRewind(kv);
		if (!KeyValuesToFile(kv, g_strConfigPath))
		{
			ReplyToCommand(client, "[SM] Could not restrict weapon for %s", steamId);
		}
		else
		{
			ReplyToCommand(client, "[SM] Restricted weapon \"%s\" for %s", weapon, steamId);
			ParseConfiguration();
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: zk_addsteamid <Steam ID> <weapon>");
	}
	return Plugin_Handled;
}

public Action:Command_AddPlayer(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	if (args >= 2)
	{
		decl String:strClient[256];
		GetCmdArg(1, strClient, sizeof(strClient));
		new target = FindTarget(client, strClient);
		if ((target > 0 && target <= MaxClients) && IsClientAuthorized(target) && IsClientInGame(target))
		{
			new Handle:kv = CreateKeyValues("Steam ID Restrictions");
			if (!FileToKeyValues(kv, g_strConfigPath))
			{
				CloseHandle(kv);
				ReplyToCommand(client, "[SM] Could not find config file.");
				SetFailState("Config file \"%s\" doesn't exist.", g_strConfigPath);
				return Plugin_Handled;
			}
			KvSavePosition(kv);
			decl String:weapon[32];
			GetCmdArg(2, weapon, sizeof(weapon));
			decl String:steamId[32];
			GetClientAuthString(client, steamId, sizeof(steamId));
			if (!KvJumpToKey(kv, steamId, true))
			{
				ReplyToCommand(client, "[SM] Could not restrict weapon for %N.", target);
				return Plugin_Handled;
			}
			KvSetString(kv, weapon, "restrict");
			KvRewind(kv);
			if (!KeyValuesToFile(kv, g_strConfigPath))
			{
				ReplyToCommand(client, "[SM] Could not restrict weapon for %N", target);
			}
			else
			{
				ReplyToCommand(client, "[SM] Restricted weapon \"%s\" for %N", weapon, target);
				ParseConfiguration();
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: zk_addplayer <name | #userid> <weapon>");
	}
	return Plugin_Handled;
}

public Action:Command_Reload(client, args)
{
	ParseConfiguration();
	ReplyToCommand(client, "[SM] Reloaded the Steam ID Weapon Restrict config.");
	return Plugin_Handled;
}

public Action:Command_ListWeaponBlocked(client, args)
{
	if (!g_bEnabled || g_hWeaponTrie == INVALID_HANDLE)
		return Plugin_Continue;

	decl String:auth[32], String:weapons[1024], String:weaponList[MAX_WEAPONS][32];
	if (args > 0)
	{
		decl String:arg[256];
		GetCmdArgString(arg, sizeof(arg));
		new target = FindTarget(client, arg);
		if (target > 0 && target <= MaxClients)
		{
			if (!IsClientAuthorized(target) || !IsClientInGame(target))
			{
				ReplyToCommand(client, "[SM] Target is not completely in-game.");
				return Plugin_Handled;
			}

			GetClientAuthString(client, auth, sizeof(auth));

			GetTrieString(g_hWeaponTrie, auth, weapons, sizeof(weapons));
			new list ;
			if ((list = ExplodeString(weapons, ";", weaponList, sizeof(weaponList), sizeof(weaponList[]))) > 0)
			{
				ReplyToCommand(client, "[SM] %N's blocked weapons:");
				for (new i = 0; i < list; i++)
				{
					SetTrieValue(g_hClientTrie[client], weaponList[i], true);

					ReplyToCommand(client, "%s", weaponList[i]);
				}
			}
		}
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientAuthorized(i) || !IsClientInGame(i))
				continue;
			GetClientAuthString(i, auth, sizeof(auth));

			GetTrieString(g_hWeaponTrie, auth, weapons, sizeof(weapons));
			new list ;
			if ((list = ExplodeString(weapons, ";", weaponList, sizeof(weaponList), sizeof(weaponList[]))) > 0)
			{
				ReplyToCommand(client, "[SM] %N's blocked weapons:");
				for (new x = 0; x < list; x++)
				{
					SetTrieValue(g_hClientTrie[client], weaponList[x], true);

					ReplyToCommand(client, "%s", weaponList[x]);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public OnClientAuthorized(client, const String:auth[])
{
	if (g_bEnabled && g_hWeaponTrie != INVALID_HANDLE)
	{
		if (g_hClientTrie[client] != INVALID_HANDLE)
			ClearTrie(g_hClientTrie[client]);
		g_hClientTrie[client] = INVALID_HANDLE;
		decl String:weapons[1024], String:weaponList[MAX_WEAPONS][32];
		if (GetTrieString(g_hWeaponTrie, auth, weapons, sizeof(weapons)))
		{
			new list;
			if ((list = ExplodeString(weapons, ";", weaponList, sizeof(weaponList), sizeof(weaponList[]))) > 0)
			{
				g_hClientTrie[client] = CreateTrie();
				for (new i = 0; i < list; i++)
				{
					SetTrieValue(g_hClientTrie[client], weaponList[i], true);
				}
			}
			else
			{
				LogError("Could not find any weapons for \"%s\" but it was listed...", auth);
			}
		}
	}
	
}

public OnClientPutInServer(client)
{
	if (g_bEnabled && g_hWeaponTrie != INVALID_HANDLE)
	{
		SDKHook(client, SDKHook_WeaponCanUse, CanUseWeapon);
		SDKHook(client, SDKHook_WeaponCanSwitchTo, CanSwitch);
		SDKHook(client, SDKHook_WeaponEquip, CanUseWeapon);
		SDKHook(client, SDKHook_WeaponSwitch, CanSwitch);
	}
}

public OnClientDisconnect(client)
{
	if (g_bEnabled && g_hWeaponTrie != INVALID_HANDLE)
	{
		SDKUnhook(client, SDKHook_WeaponCanUse, CanUseWeapon);
		SDKUnhook(client, SDKHook_WeaponCanSwitchTo, CanSwitch);
		SDKUnhook(client, SDKHook_WeaponEquip, CanUseWeapon);
		SDKUnhook(client, SDKHook_WeaponSwitch, CanSwitch);
	}

	if (g_hClientTrie[client] != INVALID_HANDLE)
	{		
		ClearTrie(g_hClientTrie[client]);
		g_hClientTrie[client] = INVALID_HANDLE;
	}
}

public Action:CanSwitch(client, weapon)
{
	if (g_bEnabled && WarmupPasses() && (g_hClientTrie[client] != INVALID_HANDLE))
	{
		decl String:name[32];
		GetEntityClassname(weapon, name, sizeof(name));
		if ((ReplaceString(name, sizeof(name), "weapon_", "", false)) < 1)
			ReplaceString(name, sizeof(name), "item_", "", false);

		new bool:block;
		
		if (GetTrieValue(g_hClientTrie[client], name, block))
		{
			if (block)
			{
				new time = GetTime();
				if ((time - g_iCanPrintToClient[client]) >= NOTIFY_TIME)
				{
					PrintToChat(client, "[SM] This weapon has been restricted for you.");
					g_iCanPrintToClient[client] = time;
				}
				CS_DropWeapon(client, weapon, false, true);
				AcceptEntityInput(weapon, "Kill");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:CanUseWeapon(client, weapon)
{
	if (g_bEnabled && WarmupPasses() && (g_hClientTrie[client] != INVALID_HANDLE))
	{
		decl String:name[32];
		GetEntityClassname(weapon, name, sizeof(name));
		ReplaceString(name, sizeof(name), "weapon_", "", false);
		ReplaceString(name, sizeof(name), "item_", "", false);

		new bool:block;
		
		if (GetTrieValue(g_hClientTrie[client], name, block))
		{
			if (block)
			{
				new time = GetTime();
				if ((time - g_iCanPrintToClient[client]) >= NOTIFY_TIME)
				{
					PrintToChat(client, "[SM] This weapon has been restricted for you.");
					g_iCanPrintToClient[client] = time;
				}
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	new bool:block;
	if (g_bEnabled && WarmupPasses() && (g_hClientTrie[client] != INVALID_HANDLE) && GetTrieValue(g_hClientTrie[client], weapon, block))
	{
		if (block)
		{
			PrintToChat(client, "[SM] This weapon has been restricted for you.");
			g_iCanPrintToClient[client] = GetTime();
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public OnEnableChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = bool:StringToInt(newVal);
	ReloadPlayers();
}

public OnWarmupChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	g_iWarmup = StringToInt(newVal);
}

public OnPathChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	BuildPath(Path_SM, g_strConfigPath, sizeof(g_strConfigPath), newVal);
	ParseConfiguration();
}

stock bool:WarmupPasses()
{
	if (g_iWarmup == 0)
	{
		return false;
	}
	if (g_iWarmup == -1 && g_bWeaponRestrictExists && Restrict_IsWarmupRound())
	{
		return false;
	}
	else if (!g_bLate && ((GetTime() - g_iMapStartTime) <= g_iWarmup))
	{
		return false;
	}
	return true;
}

stock ReloadPlayers()
{
	decl String:auth[32];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_hClientTrie[i] != INVALID_HANDLE)
			ClearTrie(g_hClientTrie[i]);
		g_hClientTrie[i] = INVALID_HANDLE;
		g_iCanPrintToClient[i] = (GetTime() - (NOTIFY_TIME + 1));
		if (IsClientInGame(i))
			OnClientPutInServer(i);
		if (IsClientAuthorized(i) && GetClientAuthString(i, auth, sizeof(auth)))
		{
			OnClientAuthorized(i, auth);
		}
	}
}

stock ParseConfiguration()
{
	if (g_hWeaponTrie != INVALID_HANDLE)
		ClearTrie(g_hWeaponTrie);
	g_hWeaponTrie = CreateTrie();

	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_hClientTrie[i] != INVALID_HANDLE)
			ClearTrie(g_hClientTrie[i]);
		g_hClientTrie[i] = INVALID_HANDLE;
	}

	new Handle:kv = CreateKeyValues("Steam ID Restrictions");
	if (!FileToKeyValues(kv, g_strConfigPath))
	{
		CloseHandle(kv);
		SetFailState("Config file \"%s\" doesn't exist.", g_strConfigPath);
		return;
	}
	if (!KvGotoFirstSubKey(kv))
	{
		LogError("No subkeys found...");
		return;
	}
	decl String:steamId[64], String:weapon[32], String:weaponAllow[32], String:weaponString[1024];
	do
	{
		weaponString[0] = '\0';
		KvGetSectionName(kv, steamId, sizeof(steamId));
		if (!KvGotoFirstSubKey(kv, false))
		{
			LogError("No weapons assigned to \"%s\"", steamId);
			continue;
		}
		do
		{
			KvGetSectionName(kv, weapon, sizeof(weapon));
			KvGetString(kv, NULL_STRING, weaponAllow, sizeof(weaponAllow));
			if (!StrEqual(weaponAllow, "restrict", false))
				continue;
			if (weaponString[0] == '\0')
				strcopy(weaponString, sizeof(weapon), weapon);
			else
				Format(weaponString, sizeof(weaponString), "%s;%s", weaponString, weapon);
		}
		while (KvGotoNextKey(kv, false));

		if (weaponString[0] == '\0')
		{
			LogError("No weapons assigned to \"%s\"", steamId);
			continue;
		}
		else
		{
			SetTrieString(g_hWeaponTrie, steamId, weaponString);
		}
	}
	while (KvGotoNextKey(kv));
	CloseHandle(kv);

	ReloadPlayers();
}

public OnPluginEnd()
{
	if (g_hWeaponTrie != INVALID_HANDLE)
	{
		ClearTrie(g_hWeaponTrie);
		g_hWeaponTrie = INVALID_HANDLE;
	}
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		if (g_hClientTrie[i] != INVALID_HANDLE)
		{
			ClearTrie(g_hClientTrie[i]);
			g_hClientTrie[i] = INVALID_HANDLE;
		}
	}
}