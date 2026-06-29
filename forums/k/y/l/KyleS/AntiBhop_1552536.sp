#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

/* Plugin Information */
public Plugin:myinfo =
{
    name 		=		"Anti Bunny Hopping",			// http://www.youtube.com/watch?v=Xk-Bc96KI-g
    author		=		"Kyle Sanderson",
    description	=		"Stops Bunny Hopping to the finest degree",
    version		=		"1.1",
    url			=		"http://SourceMod.net"
};

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) // Vel is shit.
{
	if (!(buttons & IN_JUMP) || !(GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONGROUND))
	{
		return Plugin_Continue;
	}
	
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	
	if (GetVectorLength(fVelocity) >= (GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") * 1.2))
	{
		ScaleVector(fVelocity, GetRandomFloat(0.45, 0.72));
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	
	return Plugin_Continue;
}