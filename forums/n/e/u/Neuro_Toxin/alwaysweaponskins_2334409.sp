#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <dhooks>
#undef REQUIRE_PLUGIN
#include <lastrequest>
#define REQUIRE_PLUGIN

/***************************************************
 * PLUGIN STUFF
 **************************************************/

new bool:HostiesLoaded;

public Plugin:myinfo =
{
	name = "Always Weapon Skins",
	author = "Neuro Toxin",
	description = "Players always get their weapon skins!",
	version = "2.2.0",
	url = "https://forums.alliedmods.net/showthread.php?t=237114",
}

public OnPluginStart()
{
	CreateConvars();

	new Handle:hVersion = CreateConVar("aws_version", "2.2.0");
	new flags = GetConVarFlags(hVersion);
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(hVersion, flags);
	
	if (!HookOnGiveNamedItem())
	{
		SetFailState("Unable to hook GiveNamedItem using DHooks");
		return;
	}
	
	BuildItems();
}

/***************************************************
 * CONVAR STUFF
 **************************************************/
new Handle:hCvarEnable = INVALID_HANDLE;
new Handle:hCvarSkipNamedWeapons = INVALID_HANDLE;
new Handle:hCvarDebugMessages = INVALID_HANDLE;

new bool:CvarEnable = false;
new bool:CvarSkipNamedWeapons = true;
new bool:CvarDebugMessages = false;

Handle g_hMapWeapons = null;

stock CreateConvars()
{
	hCvarEnable = CreateConVar("aws_enable", "1", "Enables plugin");
	hCvarSkipNamedWeapons = CreateConVar("aws_skipnamedweapons", "1", "If a weapon is named it wont replace");
	hCvarDebugMessages = CreateConVar("aws_debugmessages", "0", "Display debug messages in client console");
	
	HookConVarChange(hCvarEnable, OnCvarChanged);
	HookConVarChange(hCvarSkipNamedWeapons, OnCvarChanged);
	HookConVarChange(hCvarDebugMessages, OnCvarChanged);
}

stock LoadConvars()
{
	CvarEnable = GetConVarBool(hCvarEnable);
	CvarSkipNamedWeapons = GetConVarBool(hCvarSkipNamedWeapons);
	CvarDebugMessages = GetConVarBool(hCvarDebugMessages);
}

public OnCvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hCvarEnable)
		CvarEnable = StringToInt(newVal) == 0 ? false : true;
	else if (cvar == hCvarSkipNamedWeapons)
		CvarSkipNamedWeapons = StringToInt(newVal) == 0 ? false : true;
	else if (cvar == hCvarDebugMessages)
		CvarDebugMessages = StringToInt(newVal) == 0 ? false : true;
}

/***************************************************
 * HOSTIES SUPPORT STUFF
 **************************************************/

public OnAllPluginsLoaded()
{
	HostiesLoaded = LibraryExists("lastrequest");
}

/***************************************************
 * EVENT STUFF
 **************************************************/

public OnConfigsExecuted()
{
	LoadConvars();
}

public OnMapStart()
{
	if (g_hMapWeapons != null)
		ClearArray(g_hMapWeapons);
	else
		g_hMapWeapons = CreateArray();
	
	for (new client = 1; client < MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
			
		if (!IsClientAuthorized(client))
			continue;
			
		OnClientPutInServer(client);
	}
}

public void OnClientPutInServer(client)
{
	HookPlayer(client);
	SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public void OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

Handle g_hGiveNamedItem = null;
Handle g_hGiveNamedItemPost = null;

public bool HookOnGiveNamedItem()
{
	Handle config = LoadGameConfigFile("sdktools.games");
	if(config == null)
	{
		LogError("Unable to load game config file: sdktools.games");
		return false;
	}
	
	int offset = GameConfGetOffset(config, "GiveNamedItem");
	if (offset == -1)
	{
		CloseHandle(config);
		LogError("Unable to find offset 'GiveNamedItem' in game data 'sdktools.games'");
		return false;
	}
	
	/* POST HOOK */
	g_hGiveNamedItemPost = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, OnGiveNamedItemPost);
	if (g_hGiveNamedItemPost == INVALID_HANDLE)
	{
		CloseHandle(config);
		LogError("Unable to post hook 'int CCSPlayer::GiveNamedItem(char const*, int, CEconItemView*, bool)'");
		return false;
	}
	
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_CharPtr, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_Bool, -1, DHookPass_ByVal);
	
	/* PRE HOOK */
	g_hGiveNamedItem = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, OnGiveNamedItemPre);
	if (g_hGiveNamedItem == INVALID_HANDLE)
	{
		CloseHandle(config);
		LogError("Unable to hook 'int CCSPlayer::GiveNamedItem(char const*, int, CEconItemView*, bool)'");
		return false;
	}
	
	DHookAddParam(g_hGiveNamedItem, HookParamType_CharPtr, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItem, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItem, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItem, HookParamType_Bool, -1, DHookPass_ByVal);
	return true;
}

stock void HookPlayer(int client)
{
	DHookEntity(g_hGiveNamedItem, false, client);
	DHookEntity(g_hGiveNamedItemPost, true, client);
}

static bool s_TeamWasSwitched = false;
static int s_OriginalClientTeam;
static bool s_HookInUse = false;

public MRESReturn OnGiveNamedItemPre(int client, Handle hReturn, Handle hParams)
{
	// Skip if plugin is disabled
	if (!CvarEnable)
	{
		if (CvarDebugMessages)
			PrintToConsole(client, "[AWS] -> Plugin is disabled");
		return MRES_Ignored;
	}
	
	s_HookInUse = true;
	
	// Get the classname parameter
	char classname[64];
	DHookGetParamString(hParams, 1, classname, sizeof(classname));
	
	if (CvarDebugMessages)
		PrintToConsole(client, "[AWS] OnGiveNamedItemPre(int client, char[] classname='%s')", classname);
	
	// Get item definition by classname
	int itemdefinition = GetItemDefinitionByClassname(classname);
	
	// Skip unknown weapons
	if (itemdefinition == -1)
		return MRES_Ignored;
	
	// Skip knives
	if (IsItemDefinitionKnife(itemdefinition))
		return MRES_Ignored;
		
	// Get weapons team
	int weaponteam = GetWeaponTeamByItemDefinition(itemdefinition);
	
	if (CvarDebugMessages)
		PrintToConsole(client, "[AWS] -> Item definition team: %d", weaponteam);
	
	// Skip weapons for any team
	if (weaponteam == CS_TEAM_NONE)
		return MRES_Ignored;
		
	// Remeber players current team
	s_OriginalClientTeam = GetEntProp(client, Prop_Data, "m_iTeamNum")
	
	// Switch player to correct team for weapon
	SetEntProp(client, Prop_Data, "m_iTeamNum", weaponteam);
	s_TeamWasSwitched = true;
	
	if (CvarDebugMessages)
		PrintToConsole(client, "[AWS] -> Player.m_iTeamNum set to %d", weaponteam);
	return MRES_Ignored;
}

public MRESReturn OnGiveNamedItemPost(int client, Handle hReturn, Handle hParams)
{
	if (CvarDebugMessages)
		PrintToConsole(client, "-> OnGiveNamedItemPost(int client, char[] classname)");
	
	// Skip if plugin is disabled
	if (!CvarEnable)
	{
		if (CvarDebugMessages)
			PrintToConsole(client, "[AWS] -> Plugin is disabled");
		return MRES_Ignored;
	}
	
	// Skip if players team wasn't switched
	if (!s_TeamWasSwitched)
	{
		s_HookInUse = false;
		return MRES_Ignored;
	}
	
	// Switch players team back
	s_TeamWasSwitched = false;
	SetEntProp(client, Prop_Data, "m_iTeamNum", s_OriginalClientTeam);
	
	if (CvarDebugMessages)
		PrintToConsole(client, "[AWS] -> Player.m_iTeamNum set to %d", s_OriginalClientTeam);
	s_HookInUse = false;
	return MRES_Ignored;
}

Handle g_hWeaponClassname = null;
Handle g_hWeaponItemDefinition = null;
Handle g_hWeaponIsKnife = null;
Handle g_hWeaponTeam = null;

public int GetItemDefinitionByClassname(const char[] classname)
{
	if (StrEqual(classname, "weapon_knife"))
		return 42;
	if (StrEqual(classname, "weapon_knife_t"))
		return 59;
	
	int count = GetArraySize(g_hWeaponItemDefinition);
	char buffer[64];
	for (int i = 0; i < count; i++)
	{
		GetArrayString(g_hWeaponClassname, i, buffer, sizeof(buffer));
		if (StrEqual(classname, buffer))
		{
			return GetArrayCell(g_hWeaponItemDefinition, i);
		}
	}
	return -1;
}

static int GetWeaponTeamByItemDefinition(int itemdefinition)
{
	// weapon_knife
	if (itemdefinition == 42)
		return CS_TEAM_CT;
	
	// weapon_knife_t
	if (itemdefinition == 59)
		return CS_TEAM_T;
	
	int count = GetArraySize(g_hWeaponTeam);
	for (int i = 0; i < count; i++)
	{
		if (GetArrayCell(g_hWeaponItemDefinition, i) == itemdefinition)
			return GetArrayCell(g_hWeaponTeam, i);
	}
	return CS_TEAM_NONE;
}

static bool IsItemDefinitionKnife(int itemdefinition)
{
	if (itemdefinition == 42 || itemdefinition == 59)
		return true;

	int count = GetArraySize(g_hWeaponItemDefinition);
	for (int i = 0; i < count; i++)
	{
		if (GetArrayCell(g_hWeaponItemDefinition, i) == itemdefinition)
		{
			if (GetArrayCell(g_hWeaponIsKnife, i))
				return true;
			else
				return false;
		}
	}
	return false;
}

stock bool BuildItems()
{
	Handle kv = CreateKeyValues("items_game");
	if (!FileToKeyValues(kv, "scripts/items/items_game.txt"))
	{
		LogError("Unable to open/read file at 'scripts/items/items_game.txt'.");
		return false;
	}
	
	if (!KvJumpToKey(kv, "prefabs"))
		return false;
	
	if (!KvGotoFirstSubKey(kv, false))
		return false;
	
	g_hWeaponClassname = CreateArray(128);
	g_hWeaponItemDefinition = CreateArray();
	g_hWeaponIsKnife = CreateArray();
	g_hWeaponTeam = CreateArray();
	
	// Loop through all prefabs
	char buffer[128];
	char classname[128];
	int len;
	do
	{
		// Get prefab value and check for weapon_base
		KvGetString(kv, "prefab", buffer, sizeof(buffer));
		if (StrEqual(buffer, "weapon_base") || StrEqual(buffer, "primary") || StrEqual(buffer, "melee"))
		{
		
		}
		else
		{
			// Get the section name and check if its a weapon
			KvGetSectionName(kv, buffer, sizeof(buffer));
			if (StrContains(buffer, "weapon_") == 0)
			{
				// Remove _prefab to get the classname
				len = StrContains(buffer, "_prefab");
				if (len == -1) continue;
				strcopy(classname, len+1, buffer);
				
				// Store data
				PushArrayString(g_hWeaponClassname, classname);
				PushArrayCell(g_hWeaponItemDefinition, -1);
				PushArrayCell(g_hWeaponIsKnife, 0);
				
				if (!KvJumpToKey(kv, "used_by_classes"))
				{
					PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
					continue;
				}
				
				int team_ct = KvGetNum(kv, "counter-terrorists");
				int team_t = KvGetNum(kv, "terrorists");
				
				if (team_ct)
				{
					if (team_t)
						PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
					else
						PushArrayCell(g_hWeaponTeam, CS_TEAM_CT);
				}
				else if (team_t)
					PushArrayCell(g_hWeaponTeam, CS_TEAM_T);
				else
					PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
					
				KvGoBack(kv);
			}
		}
	} while (KvGotoNextKey(kv));
	
	KvGoBack(kv);
	KvGoBack(kv);
	
	if (!KvJumpToKey(kv, "items"))
		return false;
	
	if (!KvGotoFirstSubKey(kv, false))
		return false;

	char weapondefinition[12]; char weaponclassname[128]; char weaponprefab[128];
	do
	{
		KvGetString(kv, "name", weaponclassname, sizeof(weaponclassname));
		int index = GetWeaponIndexOfClassname(weaponclassname);
		
		// This item was not listed in the prefabs
		if (index == -1)
		{
			KvGetString(kv, "prefab", weaponprefab, sizeof(weaponprefab));
			
			if (!StrEqual(weaponprefab, "melee") && !StrEqual(weaponprefab, "melee_unusual"))
				continue;
			
			// Get weapon data
			KvGetSectionName(kv, weapondefinition, sizeof(weapondefinition));
			/*KvGetString(kv, "item_name", weapondescription, sizeof(weapondescription));
			GetCsgoPhrase(weapondescription, weapondescription, sizeof(weapondescription));*/
			
			// Store weapon data
			PushArrayString(g_hWeaponClassname, weaponclassname);
			PushArrayCell(g_hWeaponItemDefinition, StringToInt(weapondefinition));
			PushArrayCell(g_hWeaponIsKnife, 1);
			PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
		}
		
		// This item was found in prefabs. We just need to store the weapon index
		else
		{
			// Get weapon data
			KvGetSectionName(kv, weapondefinition, sizeof(weapondefinition));
			
			// Set weapon data
			SetArrayCell(g_hWeaponItemDefinition, index, StringToInt(weapondefinition));
		}
	
	} while (KvGotoNextKey(kv));

	return true;
}

// Returns the array index for position in g_hWeaponClassnames
stock int GetWeaponIndexOfClassname(const char[] classname)
{
	int count = GetArraySize(g_hWeaponClassname);
	char buffer[128];
	for (int i = 0; i < count; i++)
	{
		GetArrayString(g_hWeaponClassname, i, buffer, sizeof(buffer));
		if (StrEqual(buffer, classname))
			return i;
	}
	return -1;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Skip if plugin is disabled
	if (!CvarEnable)
		return;
	
	// Skip if hook is in use!
	if (s_HookInUse)
		return;
		
	// Skip if map weapons array is null
	if (g_hMapWeapons == null)
		return;
		
	// Skip if GNI doesn't know the item definition
	int itemdefinition = GetItemDefinitionByClassname(classname);
	if (itemdefinition == -1) return;
	
	// Skip knives
	if (IsItemDefinitionKnife(itemdefinition))
		return;
	
	// Store the entity index as this is a map weapon
	PushArrayCell(g_hMapWeapons, entity);
	
	if (CvarDebugMessages)
		PrintToServer("[AWS] OnEntityCreated(entity=%d, classname=%s, itemdefinition=%d, mapweaponarraysize=%d)", entity, classname, itemdefinition, GetArraySize(g_hMapWeapons));
}

public void OnEntityDestroyed(int entity)
{
	if (IsMapWeapon(entity, true) && CvarDebugMessages)
		PrintToServer("[AWS] OnEntityDestroyed(entity=%d, mapweaponarraysize=%d)", entity, GetArraySize(g_hMapWeapons));
}

stock bool IsMapWeapon(int entity, bool remove=false)
{
	if (g_hMapWeapons == null)
		return false;
		
	int count = GetArraySize(g_hMapWeapons);
	for (int i = 0; i < count; i++)
	{
		if (GetArrayCell(g_hMapWeapons, i) != entity)
			continue;
		
		if (remove)
			RemoveFromArray(g_hMapWeapons, i);
		return true;
	}
	return false;
}

public Action:OnPostWeaponEquip(client, weapon)
{
	// Skip if hook is in use!
	if (s_HookInUse)
		return Plugin_Continue;
		
	if (CvarDebugMessages)
		PrintToConsole(client, "[AWS] OnPostWeaponEquip(weapon=%d)", weapon);
	
	// Skip if plugin is disabled
	if (!CvarEnable)
	{
		if (CvarDebugMessages)
			PrintToConsole(client, "[AWS] -> Plugin is disabled");
		return Plugin_Continue;
	}
	
	// Skip bots
	if (IsFakeClient(client))
		return Plugin_Continue;

	// Check for map weapon
	if (!IsMapWeapon(weapon, true))
	{
		if (CvarDebugMessages)
			PrintToConsole(client, "[AWS] -> Skipped: IsMapWeapon(weapon=%d)==false", weapon);
		return Plugin_Continue;
	}
	
	// remake weapon string for m4a1_silencer, usp_silencer and cz75a
	new String:classname[64];
	new itemdefinition = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	switch (itemdefinition)
	{
		case 60:
		{
			if (CvarDebugMessages)
				PrintToConsole(client, "[SM] -> Index 60: Classname reset to: weapon_m4a1_silencer from: %s", classname);
			classname = "weapon_m4a1_silencer";
		}
		case 61:
		{
			if (CvarDebugMessages)
				PrintToConsole(client, "[SM] -> Index 61: Classname reset to: weapon_usp_silencer from: %s", classname);
			classname = "weapon_usp_silencer";
		}
		case 63:
		{
			if (CvarDebugMessages)
				PrintToConsole(client, "[SM] -> Index 63: Classname reset to: weapon_cz75a from: %s", classname);
			classname = "weapon_cz75a";
		}
		default:
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
		}
	}
	
	if (CvarDebugMessages)
		PrintToServer("[AWS] OnEntityClearedFromMapWeapons(entity=%d, classname=%s, mapweaponarraysize=%d)", weapon, classname, GetArraySize(g_hMapWeapons));
	
	// Skip if hosties is loaded and client is in last request
	if (HostiesLoaded)
		if (IsClientInLastRequest(client))
			return Plugin_Continue;
	
	// Skip if previously owned
	int m_hPrevOwner = GetEntProp(weapon, Prop_Send, "m_hPrevOwner");
	if (m_hPrevOwner > 0)
	{
		if (CvarDebugMessages)
			PrintToConsole(client, "[AWS] -> Skipped: m_hPrevOwner == %d", m_hPrevOwner);
		return Plugin_Continue;
	}
		
	// Skip if the weapon is named while CvarSkipNamedWeapons is enabled
	if (CvarSkipNamedWeapons)
	{
		char entname[64];
		GetEntPropString(weapon, Prop_Data, "m_iName", entname, sizeof(entname));
		if (!StrEqual(entname, ""))
		{
			if (CvarDebugMessages)
				PrintToConsole(client, "[AWS] -> Skipped: m_iName == %s", entname);
			return Plugin_Continue;
		}
	}
	
	// Debug logging
	if (CvarDebugMessages)
		PrintToConsole(client, "[AWS] Respawning %s (defindex=%d)", classname, itemdefinition);
	
	// Processing weapon switch
	// Remove current weapon from player
	AcceptEntityInput(weapon, "Kill");
	
	// Give player new weapon so the GNI hook can set the correct team inside the GiveNamedItemEx call
	GivePlayerItem(client, classname);
	return Plugin_Handled;
}