#define PLUGIN_VERSION		"1.1.0"

#include <sdktools>
#include <sourcemod>

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
	
	bool enabled[MAXPLAYERS + 1];
	
public OnPluginStart() {
	
	RegConsoleCmd("sm_dj", toggleDJ);
	
	CreateConVar(
		"sm_doublejump_version", PLUGIN_VERSION,
		"Double Jump Version",
		FCVAR_NOTIFY
	)
	
	g_cvJumpEnable = CreateConVar(
		"sm_doublejump_enabled", "1",
		"Enables double-jumping.",
		FCVAR_NOTIFY
	)
	
	g_cvJumpBoost = CreateConVar(
		"sm_doublejump_boost", "250.0",
		"The amount of vertical boost to apply to double jumps.",
		FCVAR_NOTIFY
	)
	
	g_cvJumpMax = CreateConVar(
		"sm_doublejump_max", "1",
		"The maximum number of re-jumps allowed while already jumping.",
		FCVAR_NOTIFY
	)
	
	HookConVarChange(g_cvJumpBoost,		convar_ChangeBoost)
	HookConVarChange(g_cvJumpEnable,	convar_ChangeEnable)
	HookConVarChange(g_cvJumpMax,		convar_ChangeMax)
	
	g_bDoubleJump	= GetConVarBool(g_cvJumpEnable)
	g_flBoost		= GetConVarFloat(g_cvJumpBoost)
	g_iJumpMax		= GetConVarInt(g_cvJumpMax)
}

public void OnClientPutInServer(int client)
{
	enabled[client] = true;
}

public Action toggleDJ(int client, int args)
{
	enabled[client] = !enabled[client];
	
	PrintToChat(client, "[\x04Double Jump\x01] is now %s", (enabled[client] ? "Enabled" : "Disabled"));
	
	return Plugin_Handled;
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
	int flags = GetUserFlagBits(client);
	if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
	{
	if(g_bDoubleJump && enabled[client])
	{
		new fCurFlags = GetEntityFlags(client);
		if(fCurFlags & FL_ONGROUND)
		{
			Landed(client);
		}
		else if(!(g_fLastButtons[client] & IN_JUMP) && (buttons & IN_JUMP) && !(fCurFlags & FL_ONGROUND))
		{
			ReJump(client);
		}
		
		g_fLastButtons[client] = buttons;
	}
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