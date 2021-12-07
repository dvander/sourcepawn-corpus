#pragma semicolon 1
#define PLUGIN_VERSION "14.0228.0"

//#include <tf2_stocks>
//#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>
//#include <sourcebans>

#define UPDATE_URL "http://ddhoward.bitbucket.org/InfiniteHealExploitFix.txt"
new Handle:hcvar_version;

/*
new g_clNumSpawns[MAXPLAYERS + 1];
new g_clLastSpawn[MAXPLAYERS + 1];
new bool:g_clBanning[MAXPLAYERS + 1];

new Handle:g_hWeaponReset;

new Handle:g_cvarBanLength;
new Handle:g_cvarNumDetections;
new Handle:g_cvarSpamTime;
*/

public Plugin:myinfo = {
	name = "[TF2] Infinite Healing Exploit Fix",
	author = "Derek D. Howard w/ lots of code by Dr. McKay",
	description = "Prevented an exploit that has since been patched by Valve.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=235240"
};

public OnPluginStart() {
	hcvar_version = CreateConVar("sm_infinitehealingexploitfix", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	
	decl String:message[] = "This plugin is no longer needed, feel free to uninstall it. You can also keep it; if the exploit resurfaces, this plugin will be updated.";
	PrintToServer("%s %s", "[infinitehealinghotfix.smx]", message);
	LogError(message);
	
	/*
	g_cvarBanLength = CreateConVar("sm_infinitehealfix_banlength", "-2", "Time in minutes to ban people who abuse the exploit (0 for permanent, -1 for kick, -2 to let them stay)");
	g_cvarNumDetections = CreateConVar("sm_infinitehealfix_numdetections", "30", "Number of times a player has to spam the respawn/loadout preset command before triggering");
	g_cvarSpamTime = CreateConVar("sm_infinitehealfix_spamtime", "2", "Time in seconds between commands to consider it \"spam\" (lower is less sensitive)");

	decl String:file[PLATFORM_MAX_PATH]; file[0] = '\0';
	BuildPath(Path_SM, file, sizeof(file), "gamedata/infhealhotfix.txt");
	if (FileExists(file)) {
		new Handle:hConf = LoadGameConfigFile("infhealhotfix");
		if (hConf != INVALID_HANDLE) {
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "WeaponReset");
			g_hWeaponReset = EndPrepSDKCall();
		}
		CloseHandle(hConf);
	}
	if (g_hWeaponReset == INVALID_HANDLE) {
		LogError("infhealhotfix.txt not found, or another error occurred. Plugin will still kick/ban exploiters.");
	}
	HookEvent("player_spawn", Event_PlayerSpawn);
	*/
}

/*
public OnClientConnected(client) {
	g_clBanning[client] = false;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetClientTeam(client) <= 1) { return; } // Not sure if this is needed, this method is only called on spawn?

	if (TF2_GetPlayerClass(client) != TFClass_Medic) { return; } // They're not a medic
	
	if (g_hWeaponReset != INVALID_HANDLE) { // the gamedata was loaded
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(weapon)) {
			decl String:weaponClass[64]; weaponClass[0] = '\0';
			if (GetEntityClassname(weapon, weaponClass, sizeof(weaponClass)) && (StrEqual("tf_weapon_medigun", weaponClass))) {
				SDKCall(g_hWeaponReset, weapon);
			}
		}
	}
	
	if (g_clBanning[client]) {
		TF2_SetPlayerClass(client, TFClass_Scout);
		ForcePlayerSuicide(client);
		if (IsPlayerAlive(client)) {
			SDKHooks_TakeDamage(client, client, client, 99999.0);
		}
		return;
	}

	new length = GetConVarInt(g_cvarBanLength);
	if (length == -2 && g_hWeaponReset != INVALID_HANDLE) {
		// the cvar says to let them stay, AND the gamedata is loaded
		return;
	}
	
	if (GetTime() - g_clLastSpawn[client] > GetConVarInt(g_cvarSpamTime)) {
		// the client's previous spawn was more than sm_infinitehealfix_spamtime seconds ago
		g_clNumSpawns[client] = 0;
	}
	
	g_clNumSpawns[client]++;
	g_clLastSpawn[client] = GetTime();
	
	if (g_clNumSpawns[client] >= GetConVarInt(g_cvarNumDetections)) {
		// You dun fucked up
		g_clBanning[client] = true;
		ForcePlayerSuicide(client);
		if (IsPlayerAlive(client)) {
			SDKHooks_TakeDamage(client, client, client, 99999.0);
		}
		LogMessage("%L has been detected as exploiting the infinite healing glitch!", client); //just in case they leave before the ban
		CreateTimer(3.0, Timer_KickOrBan, GetClientUserId(client));
	}
}

public Action:Timer_KickOrBan(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client)) { return; }
	
	new length = GetConVarInt(g_cvarBanLength);
	decl String:message[256] = "Healing exploit detected";
	if (length < 0) {
		KickClient(client, "%s", message);
	} else {
		if(LibraryExists("sourcebans")) {
			SBBanPlayer(0, client, length, message);
		} else {
			BanClient(client, length, BANFLAG_AUTO, message, message, "infinite_uber_fix", 0);
		}
	}
}
*/

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	SetConVarString(hcvar_version, PLUGIN_VERSION);
}

public OnAllPluginsLoaded() {
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}
public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}
public Updater_OnPluginUpdated() {
	ReloadPlugin();
}