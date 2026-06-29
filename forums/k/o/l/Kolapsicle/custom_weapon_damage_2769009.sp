#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo =  {
	name = "Custom Weapon Damage", 
	author = "Kolapsicle", 
	description = "Controls weapon damage per client.", 
	version = "1.0.0", 
	url = ""
};

enum struct WeaponConfig {
	char auth[32];
	char classname[32];
	float modifier;
}

enum struct Player {
	bool enabled;
	float wildcardModifier;
	ArrayList weaponConfig;
	
	float GetDamageModifier(int weapon, int inflictor) {
		char classname[32];
		if (IsValidEntity(weapon)) {
			GetEntityClassname(weapon, classname, sizeof(classname));
		}
		else if (IsValidEntity(inflictor)) {
			GetEntityClassname(inflictor, classname, sizeof(classname));
		}
		else {
			return this.wildcardModifier;
		}
		
		if (this.weaponConfig == null) {
			return this.wildcardModifier;
		}
		
		WeaponConfig config;
		for (int i = 0; i < this.weaponConfig.Length; i++) {
			this.weaponConfig.GetArray(i, config);
			if (StrEqual(classname, config.classname, false)) {
				return config.modifier;
			}
		}
		
		return this.wildcardModifier;
	}
}

ConVar g_cvEnabled = null;
ArrayList g_alWeaponsConfig = null;
Player player[MAXPLAYERS + 1];

// This list is used to find keys in our keyvalues structure
char g_cWeaponList[][32] =  {
	"*", 
	"weapon_axe", "weapon_fists", "weapon_hammer", "weapon_knife", "weapon_spanner", 
	"weapon_cz75a", "weapon_deagle", "weapon_elite", "weapon_fiveseven", "weapon_glock", "weapon_hkp2000", "weapon_p250", "weapon_revolver", "weapon_tec9", "weapon_usp_silencer", 
	"weapon_mag7", "weapon_nova", "weapon_sawedoff", "weapon_xm1014", 
	"weapon_m249", "weapon_negev", 
	"weapon_mac10", "weapon_mp5sd", "weapon_mp7", "weapon_mp9", "weapon_p90", "weapon_bizon", "weapon_ump45", 
	"weapon_ak47", "weapon_aug", "weapon_famas", "weapon_galilar", "weapon_m4a1_silencer", "weapon_m4a1", "weapon_sg556", 
	"weapon_awp", "weapon_g3sg1", "weapon_scar20", "weapon_ssg08", 
	"hegrenade_projectile", "flashbang_projectile", "smokegrenade_projectile", "decoy_projectile", "inferno", 
	"weapon_taser" };

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("sm_cwd_enabled", "1", "Enables custom weapon damage.", FCVAR_NOTIFY);
	LoadWeaponConfig();
	LateLoad();
}

public void OnClientPostAdminCheck(int client)
{
	SetupClient(client);
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

// Handles loading this plugin after players have already joined the server
void LateLoad()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}
		
		SetupClient(i);
		SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

// Divides the global keyvalue ArrayList into smaller per client ArrayLists for per client referencing
void SetupClient(int client)
{
	char auth[32];
	if (GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth))) {
		player[client].enabled = true;
		player[client].wildcardModifier = 1.0;
		
		WeaponConfig config;
		ArrayList tempConfig = new ArrayList(sizeof(WeaponConfig));
		for (int i = 0; i < g_alWeaponsConfig.Length; i++) {
			g_alWeaponsConfig.GetArray(i, config);
			if (StrEqual(auth, config.auth, false)) {
				if (StrEqual("*", config.classname, false)) {
					player[client].wildcardModifier = config.modifier;
					continue;
				}
				
				tempConfig.PushArray(config);
			}
		}
		
		if (tempConfig.Length > 0) {
			player[client].weaponConfig = tempConfig.Clone();
		}
		
		delete tempConfig;
	}
}

// Loads and imports custom_weapon_damage.cfg into a keyvalues structure, which in turn is loaded into a global ArrayList for later processing
void LoadWeaponConfig()
{
	if (g_alWeaponsConfig == null) {
		g_alWeaponsConfig = new ArrayList(sizeof(WeaponConfig));
	}
	
	g_alWeaponsConfig.Clear();
	
	KeyValues kv = new KeyValues("Custom Weapon Damage");
	
	char buffer[256];
	BuildPath(Path_SM, buffer, sizeof(buffer), "/configs/custom_weapon_damage.cfg");
	kv.ImportFromFile(buffer);
	
	WeaponConfig config;
	if (kv.GotoFirstSubKey(true)) {
		do {
			kv.GetSectionName(config.auth, sizeof(config.auth));
			for (int i = 0; i < sizeof(g_cWeaponList); i++) {
				config.classname = g_cWeaponList[i];
				config.modifier = kv.GetFloat(g_cWeaponList[i], 1.0);
				
				if (config.modifier != 1.0) {  // Unchanged weapons don't need to be tracked
					g_alWeaponsConfig.PushArray(config);
				}
			}
		} while (kv.GotoNextKey(true));
	}
	
	delete kv;
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_cvEnabled.BoolValue) {
		return Plugin_Continue;
	}
	
	if (!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	
	if (player[attacker].enabled) {
		damage *= player[attacker].GetDamageModifier(weapon, inflictor);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
} 