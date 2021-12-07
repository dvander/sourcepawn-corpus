#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

public Plugin:myinfo = {
	name = "Burn Damage Fix",
	author = "[GFL] Roy, That One Guy, KyleS, and [Lickaroo Johnson McPhaley]",
	description = "Slows you down if you're being burned",
	version = "1.0",
	url = "GFLClan.com"
};

// ConVars
new Handle:g_amount = INVALID_HANDLE;
new Handle:g_amountend = INVALID_HANDLE;
new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_time = INVALID_HANDLE;
new Handle:g_prop = INVALID_HANDLE;
new Handle:g_movetype = INVALID_HANDLE;

// ConVar Values
new Float:f_amount;
new Float:f_amountend;
new bool:b_enabled;
new Float:f_time;
new String:s_prop[MAX_NAME_LENGTH];
new bool:b_movetype;

// Settings
new bool:isburning[MAXPLAYERS+1];

// Developer Mode
new bool:b_debug = false;

public OnPluginStart() {
	// ConVars
	g_amount = CreateConVar("sm_bsd_amount", "25.0", "The amount to slow the player down?");
	g_amountend = CreateConVar("sm_bsd_amount_end", "0.0", "What to assign to the prop when the player is done burning.");
	g_enabled = CreateConVar("sm_bsd_enabled", "1", "Enable this plugin?");
	g_time = CreateConVar("sm_bsd_time", "5.0", "The time the burn damage lasts for?");
	g_prop = CreateConVar("sm_bsd_prop", "m_flStamina", "Prop to use to slow down players (don't mess with this unless you know what you're doing).");
	g_movetype = CreateConVar("sm_bsd_set_movetype", "1", "Set the player's \"movetype\" to 2 while being burned and back to 1 after being burned (only with sm_bsd_prop set to \"m_flStamina\".");
	
	// Change these convars!
	HookConVarChange(g_amount, AmountChange);
	HookConVarChange(g_amountend, AmountEndChange);
	HookConVarChange(g_time, TimeChange);
	HookConVarChange(g_enabled, EnabledChange);
	HookConVarChange(g_prop, PropChange);
	HookConVarChange(g_movetype, MoveTypeChange);
	
	// Set the values!
	f_amount = GetConVarFloat(g_amount);
	f_amountend = GetConVarFloat(g_amountend);
	b_enabled = GetConVarBool(g_enabled);
	f_time = GetConVarFloat(g_time);
	GetConVarString(g_prop, s_prop, sizeof(s_prop));
	b_movetype = GetConVarBool(g_movetype);
	
	// Auto Execute the config
	AutoExecConfig(true, "sm_BSD");
	
	// Late loading (pointed out by KyleS)
	for (new i=1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public AmountChange(Handle:convar, const String:oldv[], const String:newv[]) {
	f_amount = StringToFloat(newv);
}

public AmountEndChange(Handle:convar, const String:oldv[], const String:newv[]) {
	f_amountend = StringToFloat(newv);
}

public TimeChange(Handle:convar, const String:oldv[], const String:newv[]) {
	f_time = StringToFloat(newv);
}

public EnabledChange(Handle:convar, const String:oldv[], const String:newv[]) {
	b_enabled = GetConVarBool(g_enabled);
}

public PropChange(Handle:convar, const String:oldv[], const String:newv[]) {
	strcopy(s_prop, sizeof(s_prop), newv);
}

public MoveTypeChange(Handle:convar, const String:oldv[], const String:newv[]) {
	b_movetype = GetConVarBool(g_movetype);
}


public OnConfigsExecuted() {
	// Set the values!
	f_amount = GetConVarFloat(g_amount);
	b_enabled = GetConVarBool(g_enabled);
	f_time = GetConVarFloat(g_time);
	GetConVarString(g_prop, s_prop, sizeof(s_prop));
	b_movetype = GetConVarBool(g_movetype);
}

public OnClientPutInServer(client) {
	// Hook the SDKHook!
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PostThink, OnThink);
}

public OnClientDisconnect(client) {
	// Set "isburning" to false for the client.
	isburning[client] = false;
}

// SDK Hooks
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (victim > MaxClients || victim <= 0 || !IsClientInGame(victim) || !IsPlayerAlive(victim) || !b_enabled || ZR_IsClientHuman(victim) || IsClientInAir(victim) || !(damagetype & DMG_BURN) || isburning[victim]) {
		return Plugin_Continue;
	}
	
	// Now set the stamina value!
	SetEntPropFloat(victim, Prop_Send, s_prop, f_amount);
	// Set the move type to 2 if enabled.
	if (b_movetype && StrEqual(s_prop, "m_flStamina")) {
		SetEntProp(victim, Prop_Send, "movetype", 2);	// Two is CS:GO's default, but some servers may set this to "1" due to the increase in knock back (only for the "m_flStamina" prop)
	}
	
	isburning[victim] = true;
	
	// Debug
	if (b_debug) {
		PrintToChat(victim, "Burning started (Prop: \"%s\" and Amount: %f)...", s_prop, f_amount);
	}
	
	// Now Create the timer to disable it.
	CreateTimer(f_time, DisableSlowDown, victim, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public OnThink (client) {
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && isburning[client] && StrEqual(s_prop, "m_flStamina") && !ZR_IsClientHuman(client)) {
		new Float:i = GetEntPropFloat(client, Prop_Send, "m_flStamina");
		
		if (i <= 0.0) {
			// Reset the stamina when a player jumps.
			SetEntPropFloat(client, Prop_Send, s_prop, f_amount);
			
			// Debug
			if (b_debug) {
				PrintToChat(client, "You were in the air! Stamina reset (Amount: %f)", f_amount);
			}
		}
	}
}

public Action:DisableSlowDown(Handle:timer, any:victim) {
	// Just a saftey check.
	if (IsClientInGame(victim)) {
		SetEntPropFloat(victim, Prop_Send, s_prop, f_amountend);
		// Set move type back to 1
		if (b_movetype && StrEqual(s_prop, "m_flStamina")) {
			SetEntProp(victim, Prop_Send, "movetype", 1);
		}
		
		// Debug
		if (b_debug) {
			PrintToChat(victim, "Burning Ended (Amount End: %f)...", f_amountend);
		}
	}
	isburning[victim] = false;
}

bool:IsClientInAir(client) {
	// Shortened code (thanks KyleS)
	return (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1);
}