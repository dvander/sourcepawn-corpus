/*
 * Double Jump
 *
 * Description:
 *  Allows players to double-jump
 *  Original idea: NcB_Sav
 *
 * Convars:
 *  sm_doublejump_enabled [bool] : Enables or disable double-jumping. Default: 1
 *  sm_doublejump_boost [amount] : Amount to boost the player. Default: 250
 *  sm_doublejump_max [jumps]    : Maximum number of re-jumps while airborne. Default: 1
 *
 * Changelog:
 *  v1.1.0 - Update by StrikerTheHedgefox
 *   Overhaul. Doesn't use OnGameFrame anymore, and ditches an unnecessary variable.
 *  v1.0.1
 *   Minor code optimization.
 *  v1.0.0
 *   Initial release.
 *
 * Known issues:
 *  Doesn't register all mouse-wheel triggered +jumps
 *
 * Todo:
 *  Employ upcoming OnClientCommand function to remove excess OnGameFrame-age.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net
 *  Hidden:Source: http://www.hidden-source.com
 *  NcB_Sav: http://forums.alliedmods.net/showthread.php?t=99228
 */
#define PLUGIN_VERSION		"1.1.0"

#include <sdktools>
#include <sourcemod>

#define ZOMBIECLASS_HUNTER 3

public Plugin:myinfo = {
	name		= "Double Jump",
	author		= "Paegus & StrikerTheHedgefox",
	description	= "Allows double-jumping.",
	version		= PLUGIN_VERSION,
	url			= ""
}

new
	Handle:g_cvJumpBoost	= INVALID_HANDLE,
	Handle:g_cvJumpEnable	= INVALID_HANDLE,
	Handle:g_cvJumpMax		= INVALID_HANDLE,
	Float:g_flBoost			= 250.0,
	bool:g_bDoubleJump		= true,
	g_fLastButtons[MAXPLAYERS+1],
	g_iJumps[MAXPLAYERS+1],
	g_iJumpMax
	
public OnPluginStart() {
	CreateConVar(
		"l4d2_multijump_version", PLUGIN_VERSION,
		"Double Jump Version",
		FCVAR_NOTIFY
	)
	
	g_cvJumpEnable = CreateConVar(
		"l4d2_multijump_enabled", "1",
		"Enables double-jumping.",
		FCVAR_NOTIFY
	)
	
	g_cvJumpBoost = CreateConVar(
		"l4d2_multijump_boost", "250.0",
		"The amount of vertical boost to apply to double jumps.",
		FCVAR_NOTIFY
	)
	
	g_cvJumpMax = CreateConVar(
		"l4d2_multijump_max", "1",
		"The maximum number of re-jumps allowed while already jumping.",
		FCVAR_NOTIFY
	)
	
	HookConVarChange(g_cvJumpBoost,		convar_ChangeBoost)
	HookConVarChange(g_cvJumpEnable,	convar_ChangeEnable)
	HookConVarChange(g_cvJumpMax,		convar_ChangeMax)
	
	g_bDoubleJump	= GetConVarBool(g_cvJumpEnable)
	g_flBoost		= GetConVarFloat(g_cvJumpBoost)
	g_iJumpMax		= GetConVarInt(g_cvJumpMax)
	
	AutoExecConfig(true, "l4d2_hunter_multi_jump");
}

public convar_ChangeBoost(Handle:convar, const String:oldVal[], const String:newVal[]) {
	g_flBoost = StringToFloat(newVal)
}

public convar_ChangeEnable(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (StringToInt(newVal) >= 1) {
		g_bDoubleJump = true
	} else {
		g_bDoubleJump = false
	}
}

public convar_ChangeMax(Handle:convar, const String:oldVal[], const String:newVal[]) {
	g_iJumpMax = StringToInt(newVal)
}

stock Landed(const any:client) {
	g_iJumps[client] = 0	// reset jumps count
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bDoubleJump)
	{
		new fCurFlags = GetEntityFlags(client);
		if(fCurFlags & FL_ONGROUND)
		{
			Landed(client);
		}
		else if(!(g_fLastButtons[client] & IN_JUMP) && (buttons & IN_JUMP) && !(fCurFlags & FL_ONGROUND) && IsValidHunter(client))
		{
			ReJump(client);
		}
		
		g_fLastButtons[client] = buttons;
	}
}

stock ReJump(const any:client)
{
	if (g_iJumps[client] < g_iJumpMax) // has jumped at least once but hasn't exceeded max re-jumps
	{						
		g_iJumps[client]++											// increment jump count
		decl Float:vVel[3]
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel)	// get current speeds
		
		vVel[2] = g_flBoost
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel)		// boost player
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}
	
	return true;
}

stock bool:IsValidHunter(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_HUNTER)
		{
			return true;
		}
	}
	
	return false;
}