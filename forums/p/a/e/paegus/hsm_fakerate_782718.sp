/*
 * Hidden:SourceMod - Fake Rate
 *
 * Description:
 *  Adjusts the Hidden's stamina regeneration and cling-drain rates to match desired tickrate.
 *
 * Convars:
 *  hsm_fr_tick [rate]        : The effective tickrate the Hidden's stamina flows at. Defaults to server's tickrate.
 *  hdn_staminadrain [factor] : The rate at which to drain stamin while clinging to the wall. Default: -0.095.
 *
 * Changelog:
 *  v1.0.1
 *   Added drain state for +aura. -Thx Darkhand.
 *  v1.0.0
 *   Initial release.
 *
 * Known issues:
 *  Regeneration & drain rates are approximate as I don't know the hard-coded rates. They seem to be:
 *   0.3 regeneration per tick on-ground.
 *   0.1 drain per tick in aura.
 *   hdn_staminadrain drain per tick while clinging.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */
#define PLUGIN_VERSION		"1.0.1"

#pragma semicolon			1

#define DEV					0

#define HDN_MOVETYPE_CLING	12
#define HDN_TEAM_HIDDEN		3

public Plugin:myinfo =
{
	name		= "H:SM - Fake Rate.",
	author		= "Paegus",
	description	= "Adjust Hidden's stamina regeneration & drain rates.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=782718"
}

static const
	Float:g_flBaseSRPT = 0.31275,	// Base stamina regeneration per game-tick while standing still.
	Float:g_flBaseADPT = -0.095		// Base stamina drain per-tick while in aura. Hardcoded / independant of hdn_staminadrain?
;

new
	Handle:cvarFakeTick			= INVALID_HANDLE,	// Tickrate to emulate.
	Handle:cvarDrainRate		= INVALID_HANDLE,	// hdn_staminadrain.
	Float:g_flActualTickrate,						// Server's actual tickrate.
	Float:g_flRegen				= 0.0,				// Per-frame standing stamina regeneration adjustment.
	Float:g_flClingDrain		= 0.0,				// Per-frame clinging stamina drain adjustment.
	Float:g_flAuraDrain			= 0.0				// Per-frame in-aura stamina drain adjustment.
;

public OnPluginStart()
{
	CreateConVar (
		"hsm_fr_version",
		PLUGIN_VERSION,
		"H:SM - Fake-rate version.",
		FCVAR_PLUGIN|FCVAR_NOTIFY
	);
	
	g_flActualTickrate = 1.0/GetTickInterval();	// Get server's actual tickrate.
	decl String:szRate[32];
	Format(szRate, 32, "%.0f", g_flActualTickrate);
	
	cvarFakeTick = CreateConVar (
		"hsm_fr_tick",
		szRate,
		"The effective tickrate the Hidden's stamina flows at.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 30.0,
		true, 100.0
	);
	
	cvarDrainRate = FindConVar("hdn_staminadrain");
	
	g_flRegen = GetRegenRateBoost(GetConVarFloat(cvarFakeTick));
	g_flClingDrain = GetClingDrainRate(GetConVarFloat(cvarDrainRate));
	g_flAuraDrain = GetAuraDrainRate();
	
	#if DEV
	PrintToServer(
		"* [Fake-Rate]\r\n\tActual tick:    %f\r\n\tEffective tick: %f\r\n\tRegen boost:    %f\r\n\tCling drain:    %f\r\n\tAura drain::    %f",
		g_flActualTickrate,
		GetConVarFloat(cvarFakeTick),
		g_flRegen,
		g_flClingDrain,
		g_flAuraDrain
	);
	#endif
	
	HookConVarChange(cvarFakeTick, convar_Change);
	HookConVarChange(cvarDrainRate, convar_Change);
}

public convar_Change(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (convar == cvarFakeTick) {
		g_flRegen = GetRegenRateBoost(StringToFloat(newVal));
		g_flClingDrain = GetClingDrainRate(GetConVarFloat(cvarDrainRate));
		g_flAuraDrain = GetAuraDrainRate();
		
		#if DEV
		PrintToServer(
			"* [Fake-Rate]\r\n\tActual tick:    %f\r\n\tEffective tick: %f\r\n\tRegen boost:    %f\r\n\tCling drain:    %f\r\n\tAura drain::    %f",
			g_flActualTickrate,
			StringToFloat(newVal),
			g_flRegen,
			g_flClingDrain,
			g_flAuraDrain
		);
		#endif
	}
	
	else if (convar == cvarDrainRate) {
		g_flClingDrain = GetClingDrainRate(StringToFloat(newVal));
	}
}

public OnGameFrame() {
	if (g_flRegen != 0) {	// The effective tickrate is not the the same as the actual.
		decl Float:flStamina;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsHidden(i)) {
				flStamina = GetStamina(i);											// Get current stamina.
				if (IsInAura(i)) {													// Attempting to view Aura.
					if (flStamina < 0.1) {											// Too low to regenerate
						SetAura(i, false);											// Set aura off.
					} else if (IsClinging(i)) {										// Clinging while using aura.
						SetStamina(i, flStamina + g_flAuraDrain + g_flClingDrain);	// Apply both aura and cling drain augmentations.
					} else {														// Only using aura
						SetStamina(i, flStamina + g_flAuraDrain);					// Apply aura drain augmentaion.
					}
				} else if (IsOnGround(i)) {											// Regeneration possible.
					if (flStamina < 99.9) {											// Regenerating.
						SetStamina(i, flStamina + g_flRegen);						// Apply normal regen augmentation.
					}
				} else if (IsClinging(i)) {											// Clinging.
					SetStamina(i, flStamina + g_flClingDrain);						// Apply cling drain augmentation.
				}
			}
		}
	}
}

/* Stocks */

/* Returns applied regeneration rate based on effective vs actual tickrate */
stock Float:GetRegenRateBoost(const Float:rate) {
	return ((rate - g_flActualTickrate) * g_flBaseSRPT) / g_flActualTickrate;
}

/* Returns applied cling drain rate based on effective vs actual tickrate and hdn_staminadrain */
stock Float:GetClingDrainRate(const Float:drain) {
	return ((GetConVarFloat(cvarFakeTick) - g_flActualTickrate) * drain) / g_flActualTickrate;
}

/* Returns applied aura drain rate based on effective vs actual tickrate */
stock Float:GetAuraDrainRate() {
	return ((GetConVarFloat(cvarFakeTick) - g_flActualTickrate) * g_flBaseADPT) / g_flActualTickrate;
}

/* Returns aura state. on: true, off: false */
stock bool:IsInAura(const any:client) {
	return (GetEntProp(client, Prop_Send, "m_bAura") == 1);
}

/* Sets aura on or off and returns state */
stock bool:SetAura(const any:client, const bool:aurastate=true) {
	if (aurastate) {
		SetEntProp(client, Prop_Send, "m_bAura", 1);
	} else {
		SetEntProp(client, Prop_Send, "m_bAura", 0);
	}
	return aurastate;
}

/* Toggles aura and returns current state */
stock bool:AuraToggle(const any:client) {
	return AuraSet(client, !IsInAura(client));
}

/* Returns player's ground state. On the ground: true. */
stock bool:IsOnGround(const any:client) {
	if (GetEntityFlags(client) & FL_ONGROUND) {
		return true;
	}
	
	return false;
}

/* Returns player's cling state. Clinging: true. Not clinging: false */
stock bool:IsClinging(const any:client) {
	return (GetEntityMoveType(client) == MoveType:HDN_MOVETYPE_CLING);
}

/* Returns whether player is a viable Hidden. */
stock bool:IsHidden(const any:client) {
	return (
		IsClientInGame(client) &&
		IsPlayerAlive(client) &&
		GetClientTeam(client) == HDN_TEAM_HIDDEN
	);
}

/* Returns player's current stamina */
stock Float:GetStamina(const any:client) {
	return GetEntPropFloat(client, Prop_Send, "m_flStamina");
}

/* Sets player's stamina. Returns current amount */
stock Float:SetStamina(const any:client, const Float:amount) {
	if (amount > 100.000000) {	// Too high. cap at 100.
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 100.0);
		return 100.0;
	} else {
		SetEntPropFloat(client, Prop_Send, "m_flStamina", amount);
		return amount;
	}
}

/* Adds an amount to player's current stamina. Returns current stamina */
stock Float:AddStamina(const any:client, const Float:amount) {
	return SetStamina(client, GetStamina(client) + amount);
}
