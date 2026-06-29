/*
 *	"weapon_smg", "weapon_smg_mp5", "weapon_smg_silenced", "weapon_rifle", 
 *	"weapon_rifle_ak47", "weapon_rifle_sg552", "weapon_rifle_desert", "weapon_hunting_rifle", 
 *	"weapon_sniper_military", "weapon_sniper_awp", "weapon_sniper_scout", "weapon_pumpshotgun", 
 *	"weapon_autoshotgun", "weapon_shotgun_chrome", "weapon_shotgun_spas", "weapon_pistol_magnum"
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DEBUG 0

#define PLUGIN_VERSION "0.8.1"
#define WEAPON_WAIT_TIME 1.0
#define MAX_WEAPONS 32
#define ITEM_PICKUP "items/itempickup.wav"
#define SOUND_EVENT "ui/helpful_event_1.wav"
#define SOUND_BELL "buttons/bell1.wav"

WeaponData g_WeaponData[MAXPLAYERS + 1];
bool g_bWeaponTaken[MAX_WEAPONS] = { false };
char g_sWeaponNames[MAX_WEAPONS][32];
int g_iWeaponCount = 0;

enum struct WeaponData
{
	bool taken[MAX_WEAPONS];
	float availableTime[MAX_WEAPONS];
	int count;
}

bool g_bLateLoad, g_bLeft4Dead2, g_bHookedEvents, g_bPluginEnable, g_bChatMessages;
ConVar g_hPluginEnable, g_hWeaponLimit, g_hChatMessages, g_hWeaponList;
int g_iWeaponLimit;

public Plugin myinfo =
{
	name = "[L4D/2] Each With Gun",
	author = "Dosergen",
	description = "Players can choose only one weapon type.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Dosergen/Stuff"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead) g_bLeft4Dead2 = false;
	else if (test == Engine_Left4Dead2) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_each_with_gun_version", PLUGIN_VERSION, "[L4D/2] Each With Gun plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hPluginEnable = CreateConVar("l4d_each_with_gun_enable", "1", "Enable or disable the plugin functionality.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hWeaponLimit = CreateConVar("l4d_each_with_gun_per_round", "1", "Maximum number of weapons a player can take per round. 0: Disable", FCVAR_NOTIFY, true, 0.0, true, 4.0);
	g_hChatMessages = CreateConVar("l4d_each_with_gun_chat_messages", "1", "Enable or disable chat messages for player.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hWeaponList = CreateConVar("l4d_each_with_gun_list", "weapon_hunting_rifle,weapon_sniper_military,weapon_sniper_awp,weapon_sniper_scout", "Comma-separated list of weapons.", FCVAR_NOTIFY);

	g_hPluginEnable.AddChangeHook(ConVarChanged);
	g_hWeaponLimit.AddChangeHook(ConVarChanged);
	g_hChatMessages.AddChangeHook(ConVarChanged);
	g_hWeaponList.AddChangeHook(ConVarChanged);

	if (g_bLateLoad) 
	{
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}

	RegAdminCmd("sm_ws", Command_WeaponStatus, ADMFLAG_ROOT, "Shows the current weapon status");

	AutoExecConfig(true, "l4d_each_with_gun");
}

public void OnPluginEnd()
{
	ResetAll();
}

public void OnConfigsExecuted()
{
	IsAllowed();
	ParseWeaponList();
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bPluginEnable = g_hPluginEnable.BoolValue;
	g_iWeaponLimit = g_hWeaponLimit.IntValue;
	g_bChatMessages = g_hChatMessages.BoolValue;
}

void IsAllowed()
{   
	GetCvars();
	if (g_bPluginEnable && !g_bHookedEvents)
	{
		HookEvent("round_start", evtRoundStart);
		HookEvent("round_end", evtRoundEnd);
		HookEvent("player_spawn", evtPlayerSpawn);
		HookEvent("player_death", evtPlayerDeath);
		if (g_bLeft4Dead2)
			HookEvent("weapon_drop", evtWeaponDrop);
		g_bHookedEvents = true;
	}
	else if (!g_bPluginEnable && g_bHookedEvents)
	{
		UnhookEvent("round_start", evtRoundStart);
		UnhookEvent("round_end", evtRoundEnd);
		UnhookEvent("player_spawn", evtPlayerSpawn);
		UnhookEvent("player_death", evtPlayerDeath);
		if (g_bLeft4Dead2)
			UnhookEvent("weapon_drop", evtWeaponDrop);
		g_bHookedEvents = false;
	}
}

Action Command_WeaponStatus(int client, int args)
{
	if (client == 0 || !IsValidClient(client))
		return Plugin_Handled;
	char clientName[64];
	GetClientName(client, clientName, sizeof(clientName));
	for (int i = 0; i < g_iWeaponCount; i++)
		WeaponStatus(client, i);
	return Plugin_Handled;
}

void WeaponStatus(int client, int weaponIndex)
{
	if (g_bWeaponTaken[weaponIndex])
	{
		bool found = false;
		for (int j = 1; j <= MaxClients; j++)
		{
			if (IsValidClient(j) && g_WeaponData[j].taken[weaponIndex])
			{
				char playerName[64];
				GetClientName(j, playerName, sizeof(playerName));
				PrintToChat(client, "\x04[INFO]\x01 Weapon %s is taken by \x04%s\x01.", g_sWeaponNames[weaponIndex], playerName);
				found = true;
			}
		}
		if (!found)
			PrintToChat(client, "\x04[INFO]\x01 Weapon %s is taken but unknown.", g_sWeaponNames[weaponIndex]);
	}
	else
		PrintToChat(client, "\x02[INFO]\x01 Weapon %s is available.", g_sWeaponNames[weaponIndex]);
}

void ParseWeaponList()
{
	char weaponList[512];
	g_hWeaponList.GetString(weaponList, sizeof(weaponList));
	g_iWeaponCount = 0;
	char weaponArray[MAX_WEAPONS][32];
	int count = ExplodeString(weaponList, ",", weaponArray, sizeof(weaponArray), sizeof(weaponArray[]));
	for (int i = 0; i < count; i++)
	{
		TrimString(weaponArray[i]);
		if (strlen(weaponArray[i]) == 0)
			continue;			
		strcopy(g_sWeaponNames[g_iWeaponCount], 32, weaponArray[i]);
		g_iWeaponCount++;
	}
	#if DEBUG
	LogMessage("Parsed weapon list: %d weapons loaded.", g_iWeaponCount);
	for (int j = 0; j < g_iWeaponCount; j++)
		LogMessage("Weapon %d: %s", j + 1, g_sWeaponNames[j]);
	#endif
}

void evtRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

void evtRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

void ResetAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
		ResetWeaponState(i);
	}
	// Reset global weapon availability
	for (int i = 0; i < g_iWeaponCount; i++)
		g_bWeaponTaken[i] = false;
	#if DEBUG
	PrintToChatAll("[DEBUG] All weapon states have been reset.");
	#endif
}

public void OnMapStart()
{
	PrecacheSound(ITEM_PICKUP);
//	PrecacheSound(SOUND_EVENT);
//	PrecacheSound(SOUND_BELL);
}

void evtPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return;
	ResetWeaponState(client);
	CheckWeaponState(client);
	#if DEBUG
	char clientName[64];
	GetClientName(client, clientName, sizeof(clientName));
	PrintToChatAll("[DEBUG] Weapon state checked for player: %s.", clientName);
	#endif
}

void evtPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return;
	ResetWeaponState(client);
	#if DEBUG
	char clientName[64];
	GetClientName(client, clientName, sizeof(clientName));
	PrintToChatAll("[DEBUG] Weapon state reset for player: %s.", clientName);
	#endif
}

void CheckWeaponState(int client)
{
	for (int slot = 0; slot < 5; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (!IsValidEntity(weapon)) 
			continue;
		char weaponName[64];
		GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		int weaponIndex = GetWeaponIndex(weaponName);
		if (weaponIndex == -1) 
			continue;
		g_WeaponData[client].taken[weaponIndex] = true;
		g_WeaponData[client].count++;
		g_bWeaponTaken[weaponIndex] = true;
		g_WeaponData[client].availableTime[weaponIndex] = GetEngineTime() + WEAPON_WAIT_TIME;
		#if DEBUG
		PrintToChatAll("[DEBUG] Weapon found in slot %d: %s. Total weapons: %d", slot, weaponName, g_WeaponData[client].count);
		#endif
	}
}

void ResetWeaponState(int client)
{
	for (int i = 0; i < g_iWeaponCount; i++)
	{
		if (g_WeaponData[client].taken[i])
		{
			g_WeaponData[client].taken[i] = false;
			g_WeaponData[client].count = 0;
			if (g_bWeaponTaken[i] && IsWeaponUsedByOthers(i))
				continue;
			g_bWeaponTaken[i] = false;
			g_WeaponData[client].availableTime[i] = 0.0;
		}
	}
}

bool IsWeaponUsedByOthers(int weaponIndex)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
		if (g_WeaponData[i].taken[weaponIndex])
			return true;
	}
	return false;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	if (!g_bLeft4Dead2)
		SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	if (!g_bLeft4Dead2)
		SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
}

Action OnWeaponEquip(int client, int weapon)
{
	int weaponIndex;
	char weaponName[64];
	if (!WeaponEvent(client, weapon, weaponName, sizeof(weaponName), weaponIndex))
		return Plugin_Continue;
	float currentTime = GetEngineTime();
	g_WeaponData[client].taken[weaponIndex] = true;
	g_WeaponData[client].count++;
	g_bWeaponTaken[weaponIndex] = true;
	g_WeaponData[client].availableTime[weaponIndex] = currentTime + WEAPON_WAIT_TIME;
	#if DEBUG
	char clientName[64];
	GetClientName(client, clientName, sizeof(clientName));
	PrintToChatAll("[DEBUG] Player %s picked up %s.", clientName, weaponName);
	#endif
	return Plugin_Continue;
}

Action OnWeaponCanUse(int client, int weapon)
{
	int weaponIndex;
	char weaponName[64];
	if (!WeaponEvent(client, weapon, weaponName, sizeof(weaponName), weaponIndex))
		return Plugin_Continue;
	float currentTime = GetEngineTime();
	if (!IsCanPickUpWeapon(client, weaponIndex, currentTime))
		return Plugin_Handled;
	return Plugin_Continue;
}

bool WeaponEvent(int client, int weapon, char[] weaponName, int weaponNameSize, int& weaponIndex)
{
	if (!IsCheckConditions(client, weapon))
		return false;
	GetEntityClassname(weapon, weaponName, weaponNameSize);
	weaponIndex = GetWeaponIndex(weaponName);
	if (weaponIndex == -1)
		return false;
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (active == weapon)
		return false;
	return true;
}

bool IsCanPickUpWeapon(int client, int weaponIndex, float currentTime)
{
	if (g_WeaponData[client].availableTime[weaponIndex] > currentTime)
	{
		float remainingTime = g_WeaponData[client].availableTime[weaponIndex] - currentTime;
		if (g_bChatMessages)
			PrintToChat(client, "\x04[INFO]\x01 You must wait \x04%.2f\x01 seconds before picking up this weapon.", remainingTime);
		return false;
	}
	if (g_WeaponData[client].taken[weaponIndex])
	{
		if (g_bChatMessages)
			PrintToChat(client, "\x04[INFO]\x01 You already have this weapon equipped.");
		GiveAmmo(client);
		return false;
	}
	if (g_bWeaponTaken[weaponIndex])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && g_WeaponData[i].taken[weaponIndex])
			{
				char weaponOwner[64];
				GetClientName(i, weaponOwner, sizeof(weaponOwner));
				if (g_bChatMessages)
					PrintToChat(client, "\x04[INFO]\x01 This weapon is still in use by \x04%s\x01!", weaponOwner);
//				EmitSoundToClient(client, SOUND_EVENT);
				return false;
			}
		}
	}
	if (g_iWeaponLimit > 0 && g_WeaponData[client].count >= g_iWeaponLimit)
	{
		if (g_bChatMessages)
			PrintToChat(client, "\x04[INFO]\x01 You are limited to \x04%d\x01 weapon(s) per round.", g_iWeaponLimit);
//		EmitSoundToClient(client, SOUND_BELL);
		return false;
	}
	return true;
}

void GiveAmmo(int client)
{
	int weaponSlot = GetPlayerWeaponSlot(client, 0);
	if (weaponSlot == -1)
		return;
	int ammoType = GetEntProp(weaponSlot, Prop_Send, "m_iPrimaryAmmoType");
	if (ammoType == -1)
		return;
	int currentAmmo = GetEntProp(client, Prop_Data, "m_iAmmo", _, ammoType);
	int addAmmo = 100;
	if (currentAmmo + addAmmo > 100)
		addAmmo = 100 - currentAmmo;
	if (addAmmo > 0)
	{
		EmitSoundToClient(client, ITEM_PICKUP);
		SetEntProp(client, Prop_Data, "m_iAmmo", currentAmmo + addAmmo, _, ammoType);
	}
		
}

void evtWeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bLeft4Dead2)
		return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weapon = event.GetInt("propid");
	if (!IsCheckConditions(client, weapon))
		return;
	WeaponDrop(client, weapon);
}

void OnWeaponDrop(int client, int weapon)
{
	if (!IsCheckConditions(client, weapon))
		return;
	WeaponDrop(client, weapon);
}

void WeaponDrop(int client, int weapon)
{
	char weaponName[64];
	GetEntityClassname(weapon, weaponName, sizeof(weaponName));
	int weaponIndex = GetWeaponIndex(weaponName);
	if (weaponIndex == -1)
		return;
	if (g_WeaponData[client].taken[weaponIndex])
	{
		g_WeaponData[client].taken[weaponIndex] = false;
		g_WeaponData[client].count--;
		g_bWeaponTaken[weaponIndex] = false;
		#if DEBUG
		char clientName[64];
		GetClientName(client, clientName, sizeof(clientName));
		PrintToChatAll("[DEBUG] Player %s dropped %s.", clientName, weaponName);
		#endif
	}
}

int GetWeaponIndex(const char[] weaponName)
{
	for (int i = 0; i < g_iWeaponCount; i++)
	{
		if (strcmp(weaponName, g_sWeaponNames[i], true) == 0)
			return i;
	}
	return -1;
}

bool IsCheckConditions(int client, int weapon)
{
	return g_bPluginEnable && IsValidClient(client) && IsPlayerAlive(client) && IsValidEntity(weapon);
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}