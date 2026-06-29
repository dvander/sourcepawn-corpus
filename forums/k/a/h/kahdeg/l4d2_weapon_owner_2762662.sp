#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.00"

//#define DEBUG

#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_VALID_HUMAN(%1)		(IS_VALID_CLIENT(%1) && IsClientConnected(%1) && !IsFakeClient(%1))
#define IS_SPECTATOR(%1)        (GetClientTeam(%1) == TEAM_SPECTATOR)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == TEAM_SURVIVOR)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == TEAM_INFECTED)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_SPECTATOR(%1)  (IS_VALID_INGAME(%1) && IS_SPECTATOR(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))
#define IS_HUMAN_SURVIVOR(%1)   (IS_VALID_HUMAN(%1) && IS_SURVIVOR(%1))
#define IS_HUMAN_INFECTED(%1)   (IS_VALID_HUMAN(%1) && IS_INFECTED(%1))

#define MAX_CLIENTS MaxClients

#define CONFIG_FILE "weapon_owner.cfg"

public Plugin myinfo = 
{
	name = "Weaponer owner", 
	author = "kahdeg", 
	description = "Locking dropped weapon.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/member.php?u=316295"
};

ConVar g_bCvarAllow, g_bCvarLockPrimary, g_bCvarLockSecondary, g_bCvarWeaponOwnershipTimeout, g_iCvarWeaponOwnershipTimeout;
Handle g_hWeaponLockToggleCookie;

char g_ConfigPath[PLATFORM_MAX_PATH];
ArrayList g_WeaponOwnerRef; //each client can lock 1 primary and 1 offhand for themself

public void OnPluginStart()
{
	//Make sure we are on left 4 dead 2!
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("This plugin only supports left 4 dead 2!");
		return;
	}
	
	g_WeaponOwnerRef = new ArrayList(5);
	
	BuildPath(Path_SM, g_ConfigPath, sizeof(g_ConfigPath), "configs/%s", CONFIG_FILE);
	
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	CreateConVar("sm_wpowner_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_bCvarAllow = CreateConVar("weapon_owner_on", "1", "Enable plugin. 1=Plugin On. 0=Plugin Off", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCvarLockPrimary = CreateConVar("weapon_owner_lock_primary_on", "1", "1=lock Primary weapon On. 0=ignore Primary weapon", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCvarLockSecondary = CreateConVar("weapon_owner_lock_secondary_on", "1", "1=lock Secondary weapon On. 0=ignore Secondary weapon", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCvarWeaponOwnershipTimeout = CreateConVar("weapon_owner_lock_timeout", "0", "1=enable Weapon Ownership timeout. 0=disable Weapon Ownership timeout", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_iCvarWeaponOwnershipTimeout = CreateConVar("weapon_owner_lock_timeout_duration", "30", "Duration for weapon claim.", FCVAR_NOTIFY, true, 5.0, true, 9999.0);
	
	g_hWeaponLockToggleCookie = RegClientCookie("weaponowner_toggle_cookie", "Weapon owner Toggle", CookieAccess_Protected);
	
	RegConsoleCmd("sm_wp_toggle_lock", Command_ToggleLock, "Toggle on using weapon owner or not.");
	RegConsoleCmd("sm_wp_unlock", Command_Unlock, "Unlock currently claimed weapon.");
	RegConsoleCmd("sm_wp_unlock_primary", Command_UnlockPrimary, "Unlock currently claimed primary weapon.");
	RegConsoleCmd("sm_wp_unlock_secondary", Command_UnlockSecondary, "Unlock currently claimed secondary weapon.");
	
	AutoExecConfig(true, "l4d2_weaponowner");
	
	HookEvent("weapon_drop", Event_WeaponDrop, EventHookMode_Post);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		}
	}
	
	CreateTimer(2.0, Timer_CheckOwnerTimeout, _, TIMER_REPEAT);
}

public Action Command_ToggleLock(int clientId, int args) {
	if (IsPluginDisabled()) {
		ReplyToCommand(clientId, "Cannot execute command. Weapon owner is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!IS_VALID_HUMAN(clientId)) {
		ReplyToCommand(clientId, "Client '%d' is not valid.", clientId);
		return Plugin_Handled;
	}
	
	char sCookieValue[4];
	if (GetClientWeaponOwnerToggleState(clientId)) {
		//toggle off
		IntToString(0, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(clientId, g_hWeaponLockToggleCookie, sCookieValue);
		Claim(clientId, -1, true);
		Claim(clientId, -1, false);
		//PrintHintText(clientId, "Weapon lock off.");
		PrintToChat(clientId, "Weapon Lock Off");
	} else {
		//toggle on
		IntToString(1, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(clientId, g_hWeaponLockToggleCookie, sCookieValue);
		//PrintHintText(clientId, "Weapon lock on.");
		PrintToChat(clientId, "Weapon Lock On");
	}
	
	return Plugin_Handled;
}

public Action Command_Unlock(int clientId, int args) {
	if (IsPluginDisabled()) {
		ReplyToCommand(clientId, "Cannot execute command. Weapon owner is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!IS_VALID_HUMAN(clientId)) {
		ReplyToCommand(clientId, "Client '%d' is not valid.", clientId);
		return Plugin_Handled;
	}
	
	Claim(clientId, -1, true);
	Claim(clientId, -1, false);
	//PrintHintText(clientId, "Unlocked all.");
	PrintToChat(clientId, "Unlocked All.");
	
	return Plugin_Handled;
}

public Action Command_UnlockPrimary(int clientId, int args) {
	if (IsPluginDisabled()) {
		ReplyToCommand(clientId, "Cannot execute command. Weapon owner is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!IS_VALID_HUMAN(clientId)) {
		ReplyToCommand(clientId, "Client '%d' is not valid.", clientId);
		return Plugin_Handled;
	}
	
	Claim(clientId, -1, true);
	//PrintHintText(clientId, "Unlocked primary.");
	PrintToChat(clientId, "Unlocked primary.");
	
	return Plugin_Handled;
}

public Action Command_UnlockSecondary(int clientId, int args) {
	if (IsPluginDisabled()) {
		ReplyToCommand(clientId, "Cannot execute command. Weapon owner is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!IS_VALID_HUMAN(clientId)) {
		ReplyToCommand(clientId, "Client '%d' is not valid.", clientId);
		return Plugin_Handled;
	}
	
	Claim(clientId, -1, false);
	//PrintHintText(clientId, "Unlocked secondary.");
	PrintToChat(clientId, "Unlocked secondary.");
	
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void OnMapStart()
{
	/**
	 * @note Precache your models, sounds, etc. here!
	 * Not in OnConfigsExecuted! Doing so leads to issues.
	 */
}

/**
* Callback for timer to expire weapon ownership.
*/
public Action Timer_CheckOwnerTimeout(Handle timer) {
	if (IsPluginDisabled()) {
		return Plugin_Continue;
	}
	if (IsWeaponOwnershipTimeoutDisabled()) {
		return Plugin_Continue;
	}
	int n = g_WeaponOwnerRef.Length;
	int currentTimestamp = GetTime();
	for (int i = 0; i < n; i++) {
		int clientId = g_WeaponOwnerRef.Get(i, 0);
		int primaryWeaponEntId = g_WeaponOwnerRef.Get(i, 1);
		int primaryWeaponTimestamp = g_WeaponOwnerRef.Get(i, 2);
		int secondaryWeaponEntId = g_WeaponOwnerRef.Get(i, 3);
		int secondaryWeaponTimestamp = g_WeaponOwnerRef.Get(i, 4);
		
		if (primaryWeaponEntId != -1 && (currentTimestamp - primaryWeaponTimestamp > GetWeaponOwnershipTimeout())) {
			PrintToChat(clientId, "primary weapon unclaimed");
			g_WeaponOwnerRef.Set(i, -1, 1);
		}
		
		if (secondaryWeaponEntId != -1 && (currentTimestamp - secondaryWeaponTimestamp > GetWeaponOwnershipTimeout())) {
			PrintToChat(clientId, "secondary weapon unclaimed");
			g_WeaponOwnerRef.Set(i, -1, 3);
		}
	}
	return Plugin_Continue;
}

/**
* Callback for WeaponCanUse hook.
*/
public Action OnWeaponCanUse(int clientId, int weaponEntId)
{
	if (IsPluginDisabled()) {
		return Plugin_Continue;
	}
	
	if (IS_VALID_CLIENT(clientId)) {
		
		//survivor pickup weapon
		if (IS_VALID_HUMAN(clientId) && IS_VALID_SURVIVOR(clientId)) {
			
			char weaponName[64];
			GetEntityClassname(weaponEntId, weaponName, sizeof(weaponName));
			if (!IsWeapon(weaponName)) {
				return Plugin_Continue;
			}
			
			bool isClaim = IsClaimed(weaponEntId);
			bool isOwner = IsOwner(clientId, weaponEntId);
			int ownerClientId = GetOwner(weaponEntId);
			char ownerClientName[255];
			if (ownerClientId != -1) {
				GetClientName(ownerClientId, ownerClientName, sizeof(ownerClientName));
			}
			
			DebugPrint("picked up: %s | %d | %s | %s | %s", weaponName, weaponEntId, isClaim ? "c":"nc", isOwner ? "o" : "no", ownerClientId == -1 ? "None" : ownerClientName);
			
			if (isClaim && !isOwner)
			{
				PrintHintText(clientId, "This weapon is claimed by %s!", ownerClientName);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

/**
* Callback for weapon_drop event.
*/
public Action Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast) {
	
	if (IsPluginDisabled()) {
		return Plugin_Continue;
	}
	
	int usid = event.GetInt("userid");
	int clientId = GetClientOfUserId(usid);
	int weaponEntId = event.GetInt("propid");
	
	if (IS_VALID_CLIENT(clientId)) {
		
		//check for weapon owner toggle
		if (!GetClientWeaponOwnerToggleState(clientId)) {
			return Plugin_Continue;
		}
		
		//survivor drop weapon
		if (IS_VALID_SURVIVOR(clientId)) {
			char item[255];
			event.GetString("item", item, 255);
			char weaponName[255];
			FormatEx(weaponName, 255, "weapon_%s", item);
			if (!IsWeapon(weaponName)) {
				return Plugin_Continue;
			}
			Claim(clientId, weaponEntId, IsPrimaryWeapon(weaponName));
			char ownerClientName[255];
			GetClientName(clientId, ownerClientName, sizeof(ownerClientName));
			DebugPrint("dropped: %s | %d | c | o | %s", weaponName, weaponEntId, ownerClientName);
		}
	}
	return Plugin_Continue;
}

/**
* Check if a client own a weapon
*/
public bool IsOwner(int clientId, int weaponEntId) {
	if (clientId < MAX_CLIENTS) {
		int claimId = g_WeaponOwnerRef.FindValue(clientId, 0);
		if (claimId == -1) {
			return false;
		}
		return (g_WeaponOwnerRef.Get(claimId, 1) == weaponEntId || g_WeaponOwnerRef.Get(claimId, 3) == weaponEntId);
	}
	return false;
}

/**
* Check if a weapon is claimed
*/
public bool IsClaimed(int weaponEntId) {
	int claimId = g_WeaponOwnerRef.FindValue(weaponEntId, 1);
	if (claimId == -1) {
		claimId = g_WeaponOwnerRef.FindValue(weaponEntId, 3);
	}
	return claimId != -1;
}

/**
* Get a weapon's owner's clientid
*/
public int GetOwner(int weaponEntId) {
	int claimId = g_WeaponOwnerRef.FindValue(weaponEntId, 1);
	if (claimId == -1) {
		claimId = g_WeaponOwnerRef.FindValue(weaponEntId, 3);
	}
	if (claimId != -1) {
		return g_WeaponOwnerRef.Get(claimId, 0);
	}
	return -1;
}

/**
* Claim a weapon for a client
*/
public int Claim(int clientId, int weaponEntId, bool isPrimary) {
	int claim[5];
	if (clientId < MAX_CLIENTS) {
		
		if (isPrimary && !CanLockPrimary()) {
			DebugPrint("primary lock disabled");
			return -1;
		}
		
		if (!isPrimary && !CanLockSecondary()) {
			DebugPrint("secondary lock disabled");
			return -1;
		}
		
		int claimId = g_WeaponOwnerRef.FindValue(clientId, 0);
		int currentTime = GetTime();
		if (claimId == -1) {
			claim[0] = clientId;
			if (isPrimary) {
				claim[1] = weaponEntId;
				claim[2] = currentTime;
				claim[3] = -1;
				claim[4] = -1;
			} else {
				claim[1] = -1;
				claim[2] = -1;
				claim[3] = weaponEntId;
				claim[4] = currentTime;
			}
			claimId = g_WeaponOwnerRef.PushArray(claim, 5);
			DebugPrint("new claim");
		} else {
			int oldwp = g_WeaponOwnerRef.Get(claimId, isPrimary ? 1 : 3);
			g_WeaponOwnerRef.Set(claimId, weaponEntId, isPrimary ? 1 : 3);
			g_WeaponOwnerRef.Set(claimId, currentTime, isPrimary ? 2 : 4);
			DebugPrint("overwrite claim %d -> %d", oldwp, weaponEntId);
		}
		return claimId;
	}
	return -1;
}

/**
* Check if a weapon is in primary slot
*/
public bool IsPrimaryWeapon(const char[] weaponName) {
	
	//melee
	if (StrEqual(weaponName, "weapon_chainsaw") || StrEqual(weaponName, "weapon_melee")) {
		return false;
	}
	
	//pistol
	if (StrEqual(weaponName, "weapon_pistol_magnum") || StrEqual(weaponName, "weapon_pistol")) {
		return false;
	}
	
	return true;
}

/**
* Check if an item is a weapon
*/
public bool IsWeapon(const char[] weaponName) {
	//special
	if (StrEqual(weaponName, "weapon_grenade_launcher") || StrEqual(weaponName, "weapon_rifle_m60")) {
		return true;
	}
	
	//melee
	if (StrEqual(weaponName, "weapon_chainsaw") || StrEqual(weaponName, "weapon_melee")) {
		return true;
	}
	
	//deagle
	if (StrEqual(weaponName, "weapon_pistol_magnum")) {
		return true;
	}
	
	//rifle
	if (StrEqual(weaponName, "weapon_rifle") || StrEqual(weaponName, "weapon_rifle_ak47") || StrEqual(weaponName, "weapon_rifle_desert") || StrEqual(weaponName, "weapon_rifle_sg552")) {
		return true;
	}
	
	//shotgun
	if (StrEqual(weaponName, "weapon_pumpshotgun") || StrEqual(weaponName, "weapon_shotgun_chrome") || StrEqual(weaponName, "weapon_autoshotgun") || StrEqual(weaponName, "weapon_shotgun_spas")) {
		return true;
	}
	
	//smg
	if (StrEqual(weaponName, "weapon_smg") || StrEqual(weaponName, "weapon_smg_mp5") || StrEqual(weaponName, "weapon_smg_silenced")) {
		return true;
	}
	
	//sniper
	if (StrEqual(weaponName, "weapon_sniper_awp") || StrEqual(weaponName, "weapon_sniper_military") || StrEqual(weaponName, "weapon_sniper_scout") || StrEqual(weaponName, "weapon_hunting_rifle")) {
		return true;
	}
	return false;
}

public void DebugPrint(const char[] format, any...) {
	#if defined DEBUG
	char buffer[254];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToChat(i, "%s", buffer);
		}
	}
	#endif
}

public bool GetClientWeaponOwnerToggleState(int clientId) {
	char sCookieValue[4];
	GetClientCookie(clientId, g_hWeaponLockToggleCookie, sCookieValue, sizeof(sCookieValue));
	int cookieValue = StringToInt(sCookieValue);
	return cookieValue == 1;
}

public bool CanLockPrimary() {
	return g_bCvarLockPrimary.BoolValue;
}

public bool CanLockSecondary() {
	return g_bCvarLockSecondary.BoolValue;
}

public bool IsPluginDisabled() {
	return !g_bCvarAllow.BoolValue;
}

public int GetWeaponOwnershipTimeout() {
	return g_iCvarWeaponOwnershipTimeout.IntValue;
}

public bool IsWeaponOwnershipTimeoutDisabled() {
	return !g_bCvarWeaponOwnershipTimeout.BoolValue;
}
