#include <sourcemod>
#include <sdktools>

// ---- Plugin Handles ----
new	Handle:g_cvJumpBoost	= INVALID_HANDLE;
new	Handle:g_cvJumpEnable	= INVALID_HANDLE;
new	Handle:g_cvJumpMax		= INVALID_HANDLE;

// ---- Plugin Floats ----
new	Float:g_flBoost			= 250.0

// ---- Plugin Bools ----
new	bool:g_bDoubleJump		= true;
new bool:DoubleJumpEnabled[MAXPLAYERS+1] = {true,...};

new	g_fLastButtons[MAXPLAYERS+1];
new	g_fLastFlags[MAXPLAYERS+1];
new	g_iJumps[MAXPLAYERS+1];
new g_iJumpMax;



public Plugin:myinfo =
{
	name		= "Togglable Double Jump",
	author		= "Paegus - Edited by Marcus",
	description	= "Allows the toggling of double-jumping.",
	version		= "1.1.0",
	url			= ""
}
	
public OnPluginStart()
{
	RegAdminCmd("sm_doublejump",	Command_Jump,	0,	"Toggles the Double Jump Feature");

	g_cvJumpEnable = CreateConVar("sm_doublejump_enabled",	"1","Enables double-jumping.",	FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvJumpBoost = CreateConVar("sm_doublejump_boost",	"250.0",	"The amount of vertical boost to apply to double jumps.",	FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvJumpMax = CreateConVar("sm_doublejump_max",	"1","The maximum number of re-jumps allowed while already jumping.",	FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookConVarChange(g_cvJumpBoost,		convar_ChangeBoost)
	HookConVarChange(g_cvJumpEnable,	convar_ChangeEnable)
	HookConVarChange(g_cvJumpMax,		convar_ChangeMax)
	
	g_bDoubleJump	= GetConVarBool(g_cvJumpEnable)
	g_flBoost		= GetConVarFloat(g_cvJumpBoost)
	g_iJumpMax		= GetConVarInt(g_cvJumpMax)
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

public OnGameFrame()
{
	if (g_bDoubleJump) {
		for (new i = 1; i <= MaxClients; i++) {		// cycle through players
			if (IsClientInGame(i) && IsPlayerAlive(i) && DoubleJumpEnabled[i]) { // Checks if player is in game, alive, and whether or not double jump is enabled
				DoubleJump(i)						// checking for double jump
			}
		}
	}
}
stock DoubleJump(const any:client) {
	new
		fCurFlags	= GetEntityFlags(client),		// current flags
		fCurButtons	= GetClientButtons(client)		// current buttons
	
	if (g_fLastFlags[client] & FL_ONGROUND) {		// was grounded last frame
		if (
			!(fCurFlags & FL_ONGROUND) &&			// becomes airbirne this frame
			!(g_fLastButtons[client] & IN_JUMP) &&	// was not jumping last frame
			fCurButtons & IN_JUMP					// started jumping this frame
		) {
			OriginalJump(client)					// process jump from the ground
		}
	} else if (										// was airborne last frame
		fCurFlags & FL_ONGROUND						// becomes grounded this frame
	) {
		Landed(client)								// process landing on the ground
	} else if (										// remains airborne this frame
		!(g_fLastButtons[client] & IN_JUMP) &&		// was not jumping last frame
		fCurButtons & IN_JUMP						// started jumping this frame
	) {
		ReJump(client)								// process attempt to double-jump
	}
	
	g_fLastFlags[client]	= fCurFlags				// update flag state for next frame
	g_fLastButtons[client]	= fCurButtons			// update button state for next frame
}

stock OriginalJump(const any:client) {
	g_iJumps[client]++	// increment jump count
}

stock Landed(const any:client) {
	g_iJumps[client] = 0	// reset jumps count
}

stock ReJump(const any:client) {
	if ( 1 <= g_iJumps[client] <= g_iJumpMax) {						// has jumped at least once but hasn't exceeded max re-jumps
		g_iJumps[client]++											// increment jump count
		decl Float:vVel[3]
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel)	// get current speeds
		
		vVel[2] = g_flBoost
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel)		// boost player
	}
}
public Action:Command_Jump(client, args) {
	if ( IsClientInGame(client) && !DoubleJumpEnabled[client] ) {
		DoubleJumpEnabled[client] = true;
		PrintToChat(client, "\x04[Notice]:\x01 You have enabled your double-jump feature.");
	} else if ( IsClientInGame(client) && DoubleJumpEnabled[client] ) {
		DoubleJumpEnabled[client] = false;
		PrintToChat(client, "\x04[Notice]:\x01 You have disabled your double-jump feature.");
	}
	return Plugin_Handled;
}

