#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Nomad"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

ConVar g_cvarRestoreAmmount;

public Plugin myinfo = 
{
	name = "Fall Damage Heal",
	author = PLUGIN_AUTHOR,
	description = "Allows players to be healed some on taking falldamage",
	version = PLUGIN_VERSION,
	url = "www.publiclir.se"
};

public void OnPluginStart()
{
	g_cvarRestoreAmmount = CreateConVar("sm_falldamage_restore", "15", "The ammount of damage to restore when someone takes falldamage", 0, true, 0.0, true, 100.0);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnFallDamage);
}

public void OnFallDamage(int victim, int attacker, int inflictor, float damage, int damagetype) {
	if (damagetype == DMG_FALL) {
		int health = GetConVarInt(g_cvarRestoreAmmount);
		SetEntityHealth(victim, health);
	}
}