#include <sourcemod>
#include <sdktools>
#define VERSION "1.0"
public Plugin:myinfo =
{
	name = "LAZERRRRSSSS!",
	author = "MitchDizzle_",
	description = "Mitch's lazer print on wall stuff plugin cheese!",
	version = VERSION,
	url = "nefarious.mitch@yahoo.com"
}
new const g_DefaultColors_c[7][4] = { {255,255,255,255}, {255,0,0,255}, {0,255,0,255}, {0,0,255,255}, {255,255,0,255}, {0,255,255,255}, {255,0,255,255} };
new Float:LastLaser[MAXPLAYERS+1][3];
new bool:LaserE[MAXPLAYERS+1] = {false, ...};
new g_sprite;

public OnPluginStart()
{
	CreateConVar("sm_lazer_version", VERSION, "LAZERRRRSSSS! plugin. derp.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("+sm_laser", CMD_laser_p, ADMFLAG_BAN);
	RegAdminCmd("-sm_laser", CMD_laser_m, ADMFLAG_BAN);
	g_sprite = PrecacheModel("materials/sprites/xbeam2.vmt");
	CreateTimer(0.1, Timer_Pay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public OnClientPutInServer(client)
{
	LaserE[client] = false;
	LastLaser[client][0] = 0.0;
	LastLaser[client][1] = 0.0;
	LastLaser[client][2] = 0.0;
}
public Action:Timer_Pay(Handle:timer)
{
	new Float:pos[3];
	new Color = GetRandomInt(0,6);
	new my_color;
	for(new Y = 0; Y < MAXPLAYERS+1; Y++) 
	{
		if(IsValidClient(Y))
		{
			if(LaserE[Y])
			{ 
				GetPlayerEye(Y, pos);
				if(GetVectorDistance(pos, LastLaser[Y]) > 0.0)
				{
					my_color |=    ( (g_DefaultColors_c[Color][0] & 0xFF) << 16);
					my_color |=    ( (g_DefaultColors_c[Color][1] & 0xFF) << 8 );
					my_color |=    ( (g_DefaultColors_c[Color][2] & 0xFF) << 0 );
					LaserP(LastLaser[Y], pos, g_DefaultColors_c[Color], (60.0)*(5.0));
				}
				LastLaser[Y][0] = pos[0];
				LastLaser[Y][1] = pos[1];
				LastLaser[Y][2] = pos[2];
			}
		} 
	}
}
public Action:CMD_laser_p(client, args)
{
	GetPlayerEye(client, LastLaser[client]);
	LaserE[client] = true;
	return Plugin_Handled;
}

public Action:CMD_laser_m(client, args)
{
	LastLaser[client][0] = 0.0;
	LastLaser[client][1] = 0.0;
	LastLaser[client][2] = 0.0;
	LaserE[client] = false;
	return Plugin_Handled;
}
stock LaserP(Float:start[3], Float:end[3], color[4], Float:time)
{
	TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, time, 2.0, 2.0, RoundToZero(time), 0.0, color, 0);
	TE_SendToAll();
}

stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return (true);
	}

	CloseHandle(trace);
	return (false);
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}
stock bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}