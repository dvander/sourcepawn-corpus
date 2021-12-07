/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[CSGO] Damage Logger"
#define PLUGIN_DESCRIPTION "Displays damage done between players to all players in console."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>

/*****************************/
//ConVars
ConVar convar_Status;
ConVar convar_Admins;
ConVar convar_FakeClients;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	LoadTranslations("damage-logger.phrases");
	
	convar_Status = CreateConVar("sm_damagelogger_status", "1", "Should the plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Admins = CreateConVar("sm_damagelogger_admins", "0", "Should damage logs be shown to admins only?\n(override = 'damage-logger')", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_FakeClients = CreateConVar("sm_damagelogger_fakeclients", "1", "Should damage logs be shown to or from bots?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig();
	
	HookEvent("player_hurt", Event_OnPlayerHurt);
}

public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!convar_Status.BoolValue)
		return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!convar_FakeClients.BoolValue && (IsFakeClient(victim) || IsFakeClient(attacker)))
		return;
	
	if (attacker < 0 || attacker > MaxClients)
		return;
	
	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));
	
	int hp = event.GetInt("dmg_health");
	
	float origin[3];
	GetClientAbsOrigin(victim, origin);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		if (convar_Admins.BoolValue && !CheckCommandAccess(i, "damage-logger", ADMFLAG_GENERIC, true))
			continue;
		
		PrintToConsoleAll("%T", "damage log", i, attacker, victim, weapon, hp, origin[0], origin[1], origin[2]);
	}
}