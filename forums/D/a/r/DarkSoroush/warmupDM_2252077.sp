#pragma semicolon 1
#pragma dynamic 645221
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new String:ConfigFile[PLATFORM_MAX_PATH];

new String:activeWeapons[64][64];
new activeChances[64];
new activeWeapons_Size = 0;

new String:clipWeapons[64][64];
new clipSizes[64];
new clipWeapons_Size = 0;

new bool:inWarmUp = false;

new m_hOwnerEntity, m_hActiveWeapon, m_iClip1, m_iPrimaryAmmoType;

new Handle:cvar_enable;
new Handle:cvar_fillOnReload;
new Handle:cvar_fillOnKill;
new Handle:cvar_hpOnKill;
new Handle:cvar_fillMagazine;
new Handle:cvar_noMatch;
new Handle:cvar_noWeapons;
new Handle:cvar_noKnife;
new Handle:cvar_noDrop;

public Plugin:myinfo = 
{
	name = "WarmupDM",
	author = "Soroush Falahati",
	description = "A DeathMatch like modification of the gameplay based on the build-in warmup functionality of CSGO",
	version = PLUGIN_VERSION,
	url = "http://www.falahati.net/"
}

public OnPluginStart()
{
	CreateConVar("sm_warmupdm_version", PLUGIN_VERSION, "Warmup Only Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_enable = 			CreateConVar("sm_warmupdm_enable", 					"1", 
								"Is WarmupDM plugin enable?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_fillOnReload = 	CreateConVar("sm_warmupdm_fillonreload", 			"0", 
								"Filling the client ammo on reload.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_fillOnKill = 		CreateConVar("sm_warmupdm_fillonkill", 				"1", 
								"Filling the client ammo after getting a kill?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_hpOnKill = 		CreateConVar("sm_warmupdm_hponkill", 				"5", 
								"Increasing the client's health points after getting a kill?", FCVAR_PLUGIN, true, 0.0, true, 999.0);
	cvar_fillMagazine = 	CreateConVar("sm_warmupdm_fillmagazine", 			"0", 
								"Filling the active magazine of the client weapon?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_noMatch = 			CreateConVar("sm_warmupdm_nomatch", 				"1", 
								"Make the game a warmup only game?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_noWeapons = 		CreateConVar("sm_warmupdm_noweapons", 				"1", 
								"Remove the weapons from the map and the players?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_noKnife = 			CreateConVar("sm_warmupdm_noknife", 				"0", 
								"Do not remove the knife?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_noDrop = 			CreateConVar("sm_warmupdm_nodrop", 					"1", 
								"Disable the ability to drop the guns?", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "warmupdm");
	
	m_hActiveWeapon			= FindSendPropOffs("CBasePlayer",       "m_hActiveWeapon");
	m_iClip1				= FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	m_iPrimaryAmmoType		= FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	m_hOwnerEntity			= FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	
	if (m_hActiveWeapon < 0 || m_iClip1 < 0 || m_iPrimaryAmmoType < 0 || m_hOwnerEntity < 0)
	{
		return;
	}
	
	BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), "configs/warmupdm_config.txt");
	
	HookEvent("player_spawn",	Event_PlayerSpawn);
	HookEvent("round_start",	Event_Round_Start);
	HookEvent("player_death",	Event_Player_Death);
	HookEvent("weapon_reload",	Event_Weapon_Reload);
	
	AddCommandListener(OnWeaponDrop, "drop");
}

public OnMapStart()
{
	inWarmUp = false;
}

public Action:Event_Round_Start(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvar_enable))
	{
		inWarmUp = false;
		return Plugin_Continue;
	}
	if (GameRules_GetProp("m_bWarmupPeriod") != 1 && inWarmUp)
	{
		inWarmUp = false;
		if (GetConVarBool(cvar_noMatch))
		{
			TerminateGame();
		}
		return Plugin_Continue;
	}
	else if (GameRules_GetProp("m_bWarmupPeriod") == 1 && !inWarmUp)
	{
		inWarmUp = true;
		ServerCommand("mp_warmup_start");
		activeWeapons_Size = 0;
		if (!LoadMapSettings())
		{
			if (!DetectMapWeapons())
			{
				return Plugin_Continue;
			}
		}
		PrintToServer("WarmupDM: %d Active Weapons", activeWeapons_Size);
		for (new i = 0; i < activeWeapons_Size; i++)
		{
			PrintToServer("WarmupDM: Active Weapon #%d = %s [%d]", i, activeWeapons[i], activeChances[i]);
		}
	}
	if (inWarmUp && GetConVarBool(cvar_noWeapons) && activeWeapons_Size > 0)
	{
		RemoveMapWeapons();
	}
	return Plugin_Continue;
}

// Refilling the weapons
public Action:Event_Weapon_Reload(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_enable) && GetConVarBool(cvar_fillOnReload) && GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		new iClient 		= GetEventInt(hEvent, "userid");
		new client   		= GetClientOfUserId(iClient);
		if (client)
		{
			CreateTimer(0.1, Timer_RefillWeapons, iClient, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

// Refilling the weapons and adding to the health points
public Action:Event_Player_Death(Handle:hEvent, const String:name[], bool:dontBroadcast)
{	
	if (GetConVarBool(cvar_enable) && GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		new iAttacker 		= GetEventInt(hEvent, "attacker");
		new attacker   		= GetClientOfUserId(iAttacker);
		new iClient			= GetEventInt(hEvent, "userid");
		new client     		= GetClientOfUserId(iClient);
		if ((attacker && client) && GetClientTeam(attacker) != GetClientTeam(client))
		{
			if (GetConVarInt(cvar_hpOnKill) != 0)
			{
				new clientHealth = GetClientHealth(attacker);
				SetEntityHealth(attacker, (clientHealth + GetConVarInt(cvar_hpOnKill)));
			}
			if (GetConVarBool(cvar_fillOnKill))
			{
				CreateTimer(0.1, Timer_RefillWeapons, iAttacker, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

// Disable Dropping of Gun
public Action:OnWeaponDrop(client, const String:command[], argc)
{
	if (GetConVarBool(cvar_enable) && GetConVarBool(cvar_noDrop) && GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;	
}

// Hide Dropped Gun
public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	if (GetConVarBool(cvar_enable) && GetConVarBool(cvar_noDrop) && GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		if (IsValidEntity(weaponIndex))
		{
			AcceptEntityInput(weaponIndex, "KillHierarchy");
		}
	}
	return Plugin_Continue;	
}

// Give a Random Gun
public Action:Event_PlayerSpawn(Handle:hEvent, const String:name[], bool:dontBroadcast)
{	
	if (GetConVarBool(cvar_enable) && GameRules_GetProp("m_bWarmupPeriod") == 1 && activeWeapons_Size > 0)
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (GetConVarBool(cvar_noWeapons))
		{
			RemovePlayerWeapons(iClient, GetConVarBool(cvar_noKnife));
		}
		new totalChances = 0;
		for (new i = 0; i < activeWeapons_Size; i++)
		{
			totalChances += activeChances[i];
		}
		if (totalChances > 0)
		{
			new randomInt = GetRandomInt(0, totalChances - 1);
			new itemIndex = 0;
			for (new i = 0; i < activeWeapons_Size; i++)
			{
				itemIndex += activeChances[i];
				if (randomInt < itemIndex)
				{
					itemIndex = i;
					break;
				}
			}
			itemIndex = GivePlayerItem(iClient, activeWeapons[itemIndex]);
			if (itemIndex > 0)
			{
				StoreClipSize(itemIndex);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_RefillWeapons(Handle:timer, any:iClient)
{
	new client = GetClientOfUserId(iClient);
	if (client)
	{
		// Filling Primary and Secondery Weapons' Total Ammo & Magazine
		for (new slot = 0; slot < 2; slot++)
		{
			new weapon = GetPlayerWeaponSlot(client, slot);
			if (weapon > 0)
			{
				FillWeaponAmmo(client, weapon, GetConVarBool(cvar_fillMagazine));
			}
		}
	}
}

AddToWeaponArray(const String:weapon[], chance = 1)
{
	for (new i = 0; i < activeWeapons_Size; i++)
	{
		if (StrEqual(activeWeapons[i], weapon))
		{
			activeChances[i] += chance;
			return;
		}
	}
	strcopy(activeWeapons[activeWeapons_Size], strlen(weapon) + 1, weapon);
	activeChances[activeWeapons_Size] = chance;
	activeWeapons_Size++;
	return;
}

GetClipSize(entity_Index)
{
	if (IsValidEdict(entity_Index) && IsValidEntity(entity_Index))
	{
		decl String:weapon[64];
		GetEdictClassname(entity_Index, weapon, sizeof(weapon));
		if (StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1)
		{
			for (new i = 0; i < clipWeapons_Size; i++)
			{
				if (StrEqual(clipWeapons[i], weapon))
				{
					return clipSizes[i];
				}
			}
		}
	}
	return 0;
}

bool:StoreClipSize(entity_Index)
{
	if (IsValidEdict(entity_Index) && IsValidEntity(entity_Index))
	{
		decl String:weapon[64];
		GetEdictClassname(entity_Index, weapon, sizeof(weapon));
		if (StrContains(weapon, "weapon_") == -1 && StrContains(weapon, "item_") == -1)
		{
			return false;
		}
		for (new i = 0; i < clipWeapons_Size; i++)
		{
			if (StrEqual(clipWeapons[i], weapon))
			{
				return false;
			}
		}
		strcopy(clipWeapons[clipWeapons_Size], strlen(weapon) + 1, weapon);
		clipSizes[clipWeapons_Size] = GetEntData(entity_Index, m_iClip1);
		clipWeapons_Size++;
		return true;
	}
	return false;
}

bool:DetectMapWeapons()
{
	new maxent = GetMaxEntities();
	decl String:weapon[64];
	for (new i = GetMaxClients(); i < maxent;i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, m_hOwnerEntity) == -1)
			{
				AddToWeaponArray(weapon);
			}
		}
	}
	return activeWeapons_Size > 0;
}

bool:RemoveMapWeapons()
{
	new maxent = GetMaxEntities();
	decl String:weapon[64];
	for (new i = GetMaxClients(); i < maxent;i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, m_hOwnerEntity) == -1)
			{
				AcceptEntityInput(i, "KillHierarchy");
			}
		}
	}
}

bool:LoadMapSettings()
{
	decl String:MapName[128];
	new String:MapPreFix[16];
	GetCurrentMap(MapName, sizeof(MapName));
	new pos = FindCharInString(MapName, '/', true);
	if (pos == -1)
	{
		pos = FindCharInString(MapName, '\\', true);
	}
	if (pos != -1)
	{
		strcopy(MapName, strlen(MapName) - pos, MapName[pos + 1]);
	}
	pos = FindCharInString(MapName, '_');
	if (pos	!= -1)
	{
		strcopy(MapPreFix, pos + 2, MapName);
	}
	PrintToServer("WarmupDM: LOADING MAP SETTINGS: %s, %s", MapName, MapPreFix);
	new Handle:kv = CreateKeyValues("WarmupPerMapConfig");
	
	FileToKeyValues(kv, ConfigFile);
	if (!(KvJumpToKey(kv, MapName) || KvJumpToKey(kv, MapPreFix) || KvJumpToKey(kv, "default")) || !KvGotoFirstSubKey(kv, false))
	{
		CloseHandle(kv);
		return false;
	}
	
	decl String:key[64];
	new value = 0;
	do
	{
		if (KvGetSectionName(kv, key, sizeof key) && (value = KvGetNum(kv, NULL_STRING)))
		{
			AddToWeaponArray(key, value);
		}
	} while (KvGotoNextKey(kv, false));
	
	CloseHandle(kv);
	return true;
}

RemovePlayerWeapons(iClient, removeKnife = false)
{
	for (new slot = 0; slot < 6; slot++)
	{
		new weapon = -1;
		while ((weapon = GetPlayerWeaponSlot(iClient, slot)) > -1)
		{
			if (IsValidEntity(weapon) && !removeKnife)
			{
				decl String:entityName[64];
				if (GetEntityClassname(weapon, entityName, sizeof entityName))
				{
					if (StrEqual(entityName, "weapon_knife"))
					{
						break;
					}
				}
			}
			RemovePlayerItem(iClient, weapon);
		}
	}  
}

TerminateGame()
{
	ServerCommand("mp_timelimit 1");
	ServerCommand("mp_roundtime 1");
	ServerCommand("mp_maxrounds 1");
	for (new client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && !IsClientObserver(client) && IsPlayerAlive(client))
		{
			new deaths = GetEntProp(client, Prop_Data, "m_iDeaths");
			SetEntProp(client, Prop_Data, "m_iDeaths", deaths - 1);
			new kills = GetEntProp(client, Prop_Data, "m_iFrags");
			SetEntProp(client, Prop_Data, "m_iFrags", kills + 1);
			ForcePlayerSuicide(client);
		}
	}
}

FillWeaponAmmo(owner, weapon, fillMagazine = false)
{
	if (IsValidEdict(weapon))
	{
		new ammo_type = GetEntData(weapon, m_iPrimaryAmmoType);
		GivePlayerAmmo(owner, 255, ammo_type, true);
		new clipSize = GetClipSize(weapon);
		if (fillMagazine && clipSize > 0)
		{
			SetEntData(weapon, m_iClip1, clipSize);
		}
	}
}
