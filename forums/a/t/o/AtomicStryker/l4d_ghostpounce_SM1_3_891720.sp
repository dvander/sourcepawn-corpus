#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.4"

new bool:jumpdelay[MAXPLAYERS+1];
new bool:denynotified[MAXPLAYERS+1];
new Handle:MidFlightSpawn = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D_Ghostpounce",
	author = " AtomicStryker",
	description = "Left 4 Dead Ghost Leap",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=99519"
}

public OnPluginStart()
{
	CreateConVar("l4d_ghostpounce_version", PLUGIN_VERSION, " Ghost Leap Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	MidFlightSpawn = CreateConVar("l4d_ghostpounce_flightspawnallowed", "1", "Allow or Disallow Infected to Spawn during Ghost Pounce", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_ghostpounce");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_ATTACK2 && !jumpdelay[client])
	{
		if (GetClientTeam(client)!=3) return Plugin_Continue;
		if (!IsPlayerSpawnGhost(client)) return Plugin_Continue;
		
		jumpdelay[client] = true;
		CreateTimer(3.0, ResetJumpDelay, client);
		DoPounce(client);
	}

	if (buttons & IN_ATTACK && jumpdelay[client] && !(GetEntProp(client, Prop_Send, "m_ghostSpawnState", 4)) &&!GetConVarBool(MidFlightSpawn))
	{
		PrintToChat(client, "\x04This server disallows spawning during Ghost Pounce");
		SetEntProp(client, Prop_Send, "m_ghostSpawnState", 128, 4);
		if (!denynotified[client]) denynotified[client] = true;
	}
	return Plugin_Continue;
}

DoPounce(any:client)
{
	decl Float:vec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	
	if (vec[2] != 0)
	{
		PrintCenterText(client, "You must be on even ground to ghost pounce");
		return;
	}
	if (vec[0] == 0 && vec[1] == 0)
	{
		PrintCenterText(client, "You must be on the move to ghost pounce");
		return;
	}
	
	vec[0] *= 3;
	vec[1] *= 3;
	vec[2] = 750.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
}

public Action:ResetJumpDelay(Handle:timer, any:client)
{
	jumpdelay[client] = false;
	denynotified[client] = false;
}

stock bool:IsPlayerSpawnGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	else return false;
}