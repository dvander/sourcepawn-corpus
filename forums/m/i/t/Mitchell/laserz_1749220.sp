#include <sourcemod>
#include <sdktools>
#define VERSION "1.3.2"
public Plugin:myinfo =
{
	name = "LAZERRRRSSSS!",
	author = "MitchDizzle_",
	description = "Mitch's lazer print on wall stuff plugin cheese!",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=189956"
}
new const g_DefaultColors_c[7][4] = { {255,255,255,255}, {255,0,0,255}, {0,255,0,255}, {0,0,255,255}, {255,255,0,255}, {0,255,255,255}, {255,0,255,255} };
new Float:LastLaser[MAXPLAYERS+1][3];
new bool:LaserE[MAXPLAYERS+1] = {false, ...};
new g_sprite;
public OnPluginStart() {
	CreateConVar("sm_lazer_version", VERSION, "LAZERRRRSSSS! plugin. derp.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("+sm_laser", CMD_laser_p, ADMFLAG_BAN);
	RegAdminCmd("-sm_laser", CMD_laser_m, ADMFLAG_BAN);
	RegAdminCmd("+laser", CMD_laser_p, ADMFLAG_BAN);
	RegAdminCmd("-laser", CMD_laser_m, ADMFLAG_BAN);
}
public OnMapStart() {
	g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
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
	for(new Y = 1; Y <= MaxClients; Y++) 
	{
		if(IsClientInGame(Y) && LaserE[Y])
		{
			TraceEye(Y, pos);
			if(GetVectorDistance(pos, LastLaser[Y]) > 6.0) {
				LaserP(LastLaser[Y], pos, g_DefaultColors_c[Color]);
				LastLaser[Y][0] = pos[0];
				LastLaser[Y][1] = pos[1];
				LastLaser[Y][2] = pos[2];
			}
		} 
	}
}
public Action:CMD_laser_p(client, args) {
	TraceEye(client, LastLaser[client]);
	LaserE[client] = true;
	return Plugin_Handled;
}

public Action:CMD_laser_m(client, args) {
	LastLaser[client][0] = 0.0;
	LastLaser[client][1] = 0.0;
	LastLaser[client][2] = 0.0;
	LaserE[client] = false;
	return Plugin_Handled;
}
stock LaserP(Float:start[3], Float:end[3], color[4]) {
	TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, color, 0);
	TE_SendToAll();
}
TraceEye(client, Float:pos[3]) {
	decl Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(pos, INVALID_HANDLE);
	return;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask) {
	return (entity > GetMaxClients() || !entity);
}