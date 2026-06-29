

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1"
public Plugin:myinfo =
{
	name = "SpeedCap",
	author = "Cow",
	description = "Limits players velocity",
	version = PLUGIN_VERSION,
	url = ""
};


new Handle:g_ConVar_Limit;
new Float:g_VelocityLimit = 350.0;

public OnPluginStart()
{
	g_ConVar_Limit = CreateConVar("sm_slowhop_limit", "350.0", "Maximum velocity a play is allowed when jumping. 0 Disables limiting.", FCVAR_PLUGIN|FCVAR_SPONLY);
	AutoExecConfig(true, "slowhop");
	
	HookConVarChange(g_ConVar_Limit, Event_CvarChange);
	HookEvent("player_jump", Event_PlayerJump);
}

public OnConfigsExecuted()
{
	RefreshCvarCache();
}


public Event_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RefreshCvarCache();
}

stock RefreshCvarCache()
{
	g_VelocityLimit = GetConVarFloat(g_ConVar_Limit);
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_VelocityLimit)
		CreateTimer(0.1, Event_PostJump, GetClientOfUserId(GetEventInt(event, "userid")));
}


public Action:Event_PostJump(Handle:timer, any:client_index)
{
	// Get present velocity vectors
	decl Float:vVel[3];
	GetEntPropVector(client_index, Prop_Data, "m_vecVelocity", vVel);

	// Determine how much each vector must be scaled for the magnitude to equal the limit
	// scale = limit / (vx^2 + vy^2)^0.5)
	// Derived from Pythagorean theorem, where the hypotenuse represents the magnitude of velocity,
	// and the two legs represent the x and y velocity components.
	// As a side effect, velocity component signs are also handled.
	new Float:scale = FloatDiv(g_VelocityLimit, SquareRoot( FloatAdd( Pow(vVel[0], 2.0), Pow(vVel[1], 2.0) ) ) );

	// A scale < 1 indicates a magnitude > limit
	if (scale < 1.0)
	{
		// Reduce each vector by the appropriate amount
		vVel[0] = FloatMul(vVel[0], scale);
		vVel[1] = FloatMul(vVel[1], scale);

		// Impart new velocity onto player
		TeleportEntity(client_index, NULL_VECTOR, NULL_VECTOR, vVel);
	}
}
