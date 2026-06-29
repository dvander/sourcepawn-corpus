#pragma semicolon 1
#include <sourcemod>
#include <dukehacks>

#define PLUGIN_VERSION "0.0.1.3"

public Plugin:myinfo = 
{
	name = "traceattack",
	author = "L. Duke",
	description = "reduce damage of weapons",
	version = PLUGIN_VERSION,
	url = "www.LDuke.com"
}

new Handle:cvDmgMult = INVALID_HANDLE;

public OnPluginStart()
{
	// setup convars
	CreateConVar("sm_dmg_version", PLUGIN_VERSION, "damage mod version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvDmgMult = CreateConVar("sm_dmg_mult", "0.5", "damage multiplier to apply to all attacks");
	
	// register the TraceAttackHook function to be notified of attack trace
	dhAddClientHook(HK_TraceAttack, TraceAttackHook);
}

// Note that damage is BEFORE modifiers are applied by the game for
// things like crits, hitboxes, etc.  The damage shown here will NOT
// match the damage shown in player_hurt (which is after crits, hitboxes,
// etc. are applied).
public Action:TraceAttackHook(client, attacker, inflictor, Float:damage, &Float:multiplier)
{
	// change the multiplier
	// (always use *= rather than = so that other plugins modifications are not lost)
	multiplier *= GetConVarFloat(cvDmgMult);
	
	// multipler was changed
	// (use Plugin_Continue if no changes)
	// (use Plugin_Handled to block the game's TraceAttack routine completely)
	return Plugin_Changed;
}
