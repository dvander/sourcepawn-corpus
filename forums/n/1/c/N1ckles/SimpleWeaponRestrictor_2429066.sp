#include <sourcemod>
#include <cstrike> 
#include <sdkhooks>
#include <sdktools>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define WR_VERSION	"1.0.0"
#define NAME_LENGTH 64
#define ACCESS_FLAG ADMFLAG_CONFIG

// The list containing weapon aliaes (e.g. awp, p90...)
// An alias in this list will always be in lower case and without the "weapon_"-part
ArrayList g_alRestrictedWeapons = null;

// Internal value for late load procedures
bool g_bLateLoaded = false;

// ConVar + Internal value
ConVar g_cvDebug = null;
bool g_bDebug = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
	g_bLateLoaded = late;
}

public Plugin myinfo = 
{
	name = "Simple Weapon Restrictor",
	author = "N1ckles",
	description = "Restricts weapons",
	version = WR_VERSION,
	url = "http://gflclan.com"
};

public void OnPluginStart() {
	// Initialize list
	g_alRestrictedWeapons = new ArrayList(ByteCountToCells(NAME_LENGTH));
	
	// Register commands
	RegAdminCmd("wr_restrict", Command_Restrict, ACCESS_FLAG, "Restricts a weapon.");
	RegAdminCmd("wr_unrestrict", Command_Unrestrict, ACCESS_FLAG, "Unestricts a weapon.");
	RegAdminCmd("wr_reload", Command_Reload, ACCESS_FLAG, "Unestricts a weapon.");
	
	// Register ConVars
	CreateConVar("wr_version", WR_VERSION, "Simple Weapon Restrictor's version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED);
	g_cvDebug = CreateConVar("wr_debug", "0", "Enable debug logging");
	
	AutoExecConfig(true, "SimpleWeaponRestrictor");
	
	// Late loading
	if(g_bLateLoaded){
		for(int client = 1; client < MaxClients; ++client){
			if(IsClientInGame(client)){
				OnClientPutInServer(client);
			}
		}
	}
}

public void OnConfigsExecuted(){
	// Fetch the initial CVars and hook changes
	GetCVars();
	HookConVarChange(g_cvDebug, CVarChanged);
	
	// Clean the list and load the config file
	g_alRestrictedWeapons.Clear();
	LoadConfigFile(g_bLateLoaded);
}

void GetCVars(){
	// Feed internal values
	g_bDebug = g_cvDebug.BoolValue;
}

public void CVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	// Fetch changes
	GetCVars();
}

void LoadConfigFile(bool late){
	if(g_bDebug)
		PrintToServer("[WR] Loading config file");
	
	char path[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, path, sizeof(path), "configs/restricted_weapons.txt");
	
	if(!FileExists(path)){
		if(g_bDebug)
			PrintToServer("[WR] Failed to locate config file. Skipping..");
		return;
	}
	
	File config = OpenFile(path, "r");
	
	if(config == null){
		PrintToServer("[WR] Failed to open config file. Skipping..");
		return;
	}
	
	char weapon[NAME_LENGTH];
	
	int line = 0;
	int restrictions = 0;
	
	while(config.ReadLine(weapon, sizeof(weapon))){
		++line;
		
		TrimString(weapon);
		
		if(g_bDebug)
			PrintToServer("[WR] Config file: Processing line %d : '%s'", line, weapon);
		
		// If the string is empty: skip.
		if(strlen(weapon) < 1){
			if(g_bDebug)
				PrintToServer("[WR] Config file: Line %d is empty! Skipping..", line);
			continue;
		}
		
		LowerCaseString(weapon);
		
		// Remove "weapon_"
		StripWeaponPrefix(weapon, sizeof(weapon));
		
		if(!IsWeaponAliasValid(weapon)){
			PrintToServer("[WR] Config file: WARNING - Invalid entry: %s! (Line: %d)", weapon, line);
			continue;
		}
		
		// Check if already restricted
		if(g_alRestrictedWeapons.FindString(weapon) != -1){
			PrintToServer("[WR] Config file: WARNING - Duplicate entry: %s! (Line: %d)", weapon, line);
			continue;
		}
		
		// Do the restriction
		g_alRestrictedWeapons.PushString(weapon);
		++restrictions;
		
		if(g_bDebug)
			PrintToServer("[WR] Config file: Restricted %s!", weapon);
		
		// If this load was done late, check all clients for the given weapon.
		if(late){
			if(g_bDebug)
				PrintToServer("[WR] Config file: Removing %s from all players. (Late loaded)", weapon);
			RemoveWeaponFromAllPlayer(weapon);
		}
	}
	
	delete config;
	PrintToServer("[WR] Config file: Loaded %d restriction(s).", restrictions);
	if(g_bDebug)
		PrintToServer("[WR] Config file loaded");
}

// Events

public void OnClientPutInServer(int client){
	// Hook equip.
	SDKHook(client, SDKHook_WeaponEquip, Event_WeaponEquip);
}

public Action Event_WeaponEquip(int client, int weapon){

	// Get class name of the weapon
	char weaponClass[NAME_LENGTH];
	GetEdictClassname(weapon, weaponClass, sizeof(weaponClass));
	
	// Remove "weapon_"-part
	StripWeaponPrefix(weaponClass, sizeof(weaponClass));
	
	// Check if restricted
	if(g_alRestrictedWeapons.FindString(weaponClass) != -1){
		// Notify the client
		CPrintToChat(client, "{green}[WR] {darkred}%s {default} is restricted and cannot be picked up.", weaponClass);
		// Kill the bugger
		AcceptEntityInput(weapon, "kill");
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] weapon){
	if(g_alRestrictedWeapons.FindString(weapon) != -1){
		CPrintToChat(client, "{green}[WR] {default}You cannot buy a {darkred}%s{default}, because it's restricted.", weapon);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// Commands

public Action Command_Reload(int client, int args){
	if(g_bDebug)
		PrintToServer("[WR] Reloading config file");
	g_alRestrictedWeapons.Clear();
	LoadConfigFile(true);
	CReplyToCommand(client, "{green}[WR] {default}Config reloaded!");
}

public Action Command_Restrict(int client, int args){
	if(args < 1){
		CReplyToCommand(client, "{green}[WR] {default}Usage: sm_restrict <weapon name (e.g. awp)>");
		return Plugin_Handled;
	}
	
	// Fetch the arg
	char weaponAlias[NAME_LENGTH];
	GetCmdArg(1, weaponAlias, sizeof(weaponAlias));
	
	// Remove "weapon_" if it's there
	StripWeaponPrefix(weaponAlias, sizeof(weaponAlias));
	
	// Lower case it
	LowerCaseString(weaponAlias);
	
	// Check if valid
	if(!IsWeaponAliasValid(weaponAlias)){
		CReplyToCommand(client, "{green}[WR] {darkred}%s {default} is an invalid weapon!", weaponAlias);
		return Plugin_Handled;
	}
	
	// Check if already restricted
	if(g_alRestrictedWeapons.FindString(weaponAlias) != -1){
		CReplyToCommand(client, "{green}[WR] {darkred}%s {default}is already restricted!", weaponAlias);
		return Plugin_Handled;
	}
	
	g_alRestrictedWeapons.PushString(weaponAlias);
	
	ShowActivity2(client, "[WR] ", "Restricted weapon: %s.", weaponAlias);
	
	CReplyToCommand(client, "{green}[WR] {default}Removing {darkred}%s {default}from all clients!", weaponAlias);
	
	// Check all clients for the weapon
	RemoveWeaponFromAllPlayer(weaponAlias);
	
	return Plugin_Handled;
}

public Action Command_Unrestrict(int client, int args){
	if(args < 1){
		CReplyToCommand(client, "{green}[WR] {default}Usage: sm_unrestrict <weapon name (e.g. awp)>");
		return Plugin_Handled;
	}
	
	// Fetch the arg
	char weaponAlias[NAME_LENGTH];
	GetCmdArg(1, weaponAlias, sizeof(weaponAlias));
	
	// Remove "weapon_" if it's there
	StripWeaponPrefix(weaponAlias, sizeof(weaponAlias));
	
	// Lower case it
	LowerCaseString(weaponAlias);
	
	// Check if restricted
	int index = g_alRestrictedWeapons.FindString(weaponAlias);
	if(index == -1){
		CReplyToCommand(client, "{green}[WR] {darkred}%s {default}is invalid or not restricted!", weaponAlias);
		return Plugin_Handled;
	}
	
	g_alRestrictedWeapons.Erase(index);
	
	ShowActivity2(client, "[WR] ", "Unrestricted weapon: %s.", weaponAlias);
	
	return Plugin_Handled;
}

// Helpers

// Remove given alias from all clients and notify them
void RemoveWeaponFromAllPlayer(const char[] weaponAlias){
	// Prepare the class name by appending "weapon_"
	char weaponClass[NAME_LENGTH];
	Format(weaponClass, sizeof(weaponClass), "weapon_%s", weaponAlias);
	
	// Loop through all clients
	for(int client = 1; client < MaxClients; ++client){
		if(!IsClientInGame(client))
			continue;
		
		// Loop through all slots. TODO: Optimize this.
		for(int slot = CS_SLOT_PRIMARY; slot <= CS_SLOT_C4; ++slot){
			// Get the weapon
			int weapon = GetPlayerWeaponSlot(client, slot);
			
			// If empty slot: skip.
			if(weapon == -1)
				continue;
			
			// Get class
			char entityClass[NAME_LENGTH];
			GetEdictClassname(weapon, entityClass, sizeof(entityClass));
			
			if(StrEqual(weaponClass, entityClass, true)){
				if(RemovePlayerItem(client, weapon)){
					// Kill the bugger
					AcceptEntityInput(weapon, "kill");
					// Notify the client of the missing weapon
					CPrintToChat(client, "{green}[WR] {darkred}%s {default} has been restricted and removed from you.", weaponAlias);
				}
				break;
			}
		}
	}
}

// Remove "weapon_" from a string
void StripWeaponPrefix(char[] weapon, int size){
	ReplaceString(weapon, size, "weapon_", "", false);
}

// Lower case a string
void LowerCaseString(char[] s){
	for(int i = 0;; ++i){
		// Break early at zero-termination
		if(s[i] == '\0'){
			break;
		}
		
		if(IsCharUpper(s[i])){
			s[i] = CharToLower(s[i]);
		}
	}
}

// Check if alias is valid
bool IsWeaponAliasValid(const char[] alias){
	return CS_AliasToWeaponID(alias) != CSWeapon_NONE;
}