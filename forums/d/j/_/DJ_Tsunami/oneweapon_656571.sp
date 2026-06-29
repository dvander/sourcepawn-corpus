#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION    "0.5.5"
#define CVAR_DISABLED "none"

public Plugin:myinfo = {
	name        = "One Weapon",
	author      = "Tsunami",
	description = "Gives a single weapon with unlimited ammo to everyone.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
};

new g_iAmount;
new g_iClip;
new g_iHealth = 0;
new g_iMaxClients;
new g_iMaxEntities;
new g_iOwner;
new g_iWeapon;
new bool:g_bEnabled = false;
new Handle:g_hHealth;
new Handle:g_hWeapon;
new String:g_sWeapon[64] = CVAR_DISABLED;

public OnPluginStart() {
	CreateConVar("sm_oneweapon_version", PL_VERSION, "Gives a single weapon with unlimited ammo to everyone.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hHealth   = CreateConVar("sm_oneweapon_health",   "0",           "Amount of health to give to everyone.",          FCVAR_PLUGIN);
	g_hWeapon   = CreateConVar("sm_oneweapon_weapon",   CVAR_DISABLED, "Class name of the weapon to give to everyone.",  FCVAR_PLUGIN);
	g_iClip     = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iOwner    = FindSendPropInfo("CBaseCombatWeapon", "m_hOwner");
	g_iWeapon   = FindSendPropInfo("CBasePlayer",       "m_hActiveWeapon");
	
	HookConVarChange(g_hHealth, ConVarChange_Health);
	HookConVarChange(g_hWeapon, ConVarChange_Weapon);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	RegConsoleCmd("drop", Command_Drop, "Disable dropping the single weapon given to everyone.");
}

public OnMapStart() {
	g_iMaxClients  = GetMaxClients();
	g_iMaxEntities = GetMaxEntities();
}

public OnGameFrame() {
	if (g_bEnabled) {
		for (new i = 1, iWeapon; i <= g_iMaxClients; i++) {
			if (IsClientInGame(i) && IsPlayerAlive(i)) {
				if (IsValidEntity((iWeapon   = GetEntDataEnt2(i, g_iWeapon)))) {
					if (g_iAmount != -1) {
						SetEntData(iWeapon, g_iClip, g_iAmount, _, true);
					}
				} else {
					GivePlayerItem(i, g_sWeapon);
					
					if (IsValidEntity((iWeapon = GetEntDataEnt2(i, g_iWeapon)))) {
						g_iAmount = GetEntData(iWeapon, g_iClip);
					}
				}
			}
		}
	}
}

public ConVarChange_Health(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iHealth   = StringToInt(newValue);
}

public ConVarChange_Weapon(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled  = !StrEqual(newValue, CVAR_DISABLED);
	strcopy(g_sWeapon, sizeof(g_sWeapon), newValue);
	
	for (new i  = 1, iClients = GetClientCount(); i <= iClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			ForcePlayerSuicide(i);
		}
	}
}

public Action:Command_Drop(client, args) {
	return g_bEnabled ? Plugin_Handled : Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_bEnabled) {
		for (new i = g_iMaxClients + 1, String:sClassName[64]; i <= g_iMaxEntities; i++) {
			if (IsValidEntity(i)) {
				GetEntityNetClass(i, sClassName, sizeof(sClassName));
				
				if (StrContains(sClassName, "CWeapon") != -1 &&
						GetEntDataEnt2(i, g_iOwner)        == -1) {
					RemoveEdict(i);
				}
			}
		}
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_bEnabled) {
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (GetClientTeam(iClient) > 1) {
			CreateTimer(0.1, Timer_Strip, iClient);
		}
	}
}

public Action:Timer_Strip(Handle:timer, any:client) {
	for (new i = 0, s; i < 5; i++) {
		if ((s = GetPlayerWeaponSlot(client, i)) != -1) {
			RemovePlayerItem(client, s);
			RemoveEdict(s);
		}
	}
	
	if (g_iHealth > 0) {
		SetEntityHealth(client, g_iHealth);
	}
}