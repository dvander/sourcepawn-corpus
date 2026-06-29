#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[L4D2] Leveled Announce",
	author = "CanadaRox",
	description = "Print a chat message when someone levels a charger",
	version = "1.0",
	url = "..."
};

new Handle:g_hEnabled;
new bool:g_bEnabled;

public OnPluginStart()
{
	g_hEnabled = CreateConVar("l4d2_levelannounce_enable", "1", "Enable announces when a charger is leveled");
	
	HookConVarChange(g_hEnabled, ConVarChanged_Enable);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	HookEvent("charger_killed", ChargerKilled_Event);
}

public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = GetConVarBool(g_hEnabled);
}

public ChargerKilled_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled) return;
	
	new bool:IsCharging = GetEventBool(event, "charging");
	new bool:IsMelee = GetEventBool(event, "melee");
	if (!IsMelee || !IsCharging) return;
	
	new survivor = GetClientOfUserId(GetEventInt(event, "attacker"));
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	
	PrintToChatAll("%N leveled %N!!", survivor, charger);
}