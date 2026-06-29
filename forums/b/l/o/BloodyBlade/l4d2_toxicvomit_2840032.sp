#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D2] Toxic Vomit",
	author = "Drixevel(Edit. by BloodyBlade)",
	description = "Damages players when vomited on.",
	version = PLUGIN_VERSION,
	url = "https://drixevel.dev/"
};

ConVar convar_Enabled, convar_Damage;
bool bHooked = false;
float fToxicDamage = 0.0;

public void OnPluginStart()
{
    CreateConVar("l4d2_toxicvomit_version", PLUGIN_VERSION, "[L4D2] Toxic Vomit plugin version", CVAR_FLAGS);
    convar_Enabled = CreateConVar("l4d2_toxicvomit_enabled", "1", "Should the plugin be enabled or not?", CVAR_FLAGS, true, 0.0, true, 1.0);
    convar_Damage = CreateConVar("l4d2_toxicvomit_damage", "1.0", "Damage to do per tick to players who have been vomited on.", CVAR_FLAGS, true, 0.0, true, 100.0);
    AutoExecConfig(true, "l4d2_toxicvomit");
    convar_Enabled.AddChangeHook(OnConVarEnableChanged);
    convar_Damage.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    fToxicDamage = convar_Damage.FloatValue;
}

void IsAllowed()
{
	bool bPluginOn = convar_Enabled.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		OnConVarsChanged(null, "", "");
		HookEvent("player_now_it", Event_OnPlayerIt);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_now_it", Event_OnPlayerIt);
	}
}

void Event_OnPlayerIt(Event event, const char[] name, bool dontBroadcast)
{
	//Is the plugin enabled?
	if (!convar_Enabled.BoolValue)
		return;
	
	//Client being vomited on.
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	//Validate the client just in case.
	if (!IsValidAliveClient(client) || !IsValidClient(attacker))
		return;
	
	//Must come from a boomer.
	if (event.GetBool("by_boomer") || event.GetBool("exploded"))
	{
		DataPack hPack;
		CreateDataTimer(1.0, OnVomitedTimer, hPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		hPack.WriteCell(client);
		hPack.WriteCell(attacker);
	}
}

Action OnVomitedTimer(Handle timer, DataPack pack)
{
	int iVictim = pack.ReadCell();
	int iAttacker = pack.ReadCell();
	//Validate the clients.
	if (!IsValidClient(iAttacker) || !IsValidAliveClient(iVictim) || !IsBoomed(iVictim))
	{
		return Plugin_Stop;
	}

	SDKHooks_TakeDamage(iVictim, 0, iAttacker, fToxicDamage, DMG_ACID);
	return Plugin_Continue;
}

//Found Here: https://github.com/gkistler/SourcemodStuff/blob/master/l4dcompstats.sp#L46
stock bool IsBoomed(int client)
{
	return (GetEntPropFloat(client, Prop_Send, "m_vomitStart") + 20.1) > GetGameTime();
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

stock bool IsValidAliveClient(int client)
{
	return IsValidClient(client) && IsPlayerAlive(client);
}
