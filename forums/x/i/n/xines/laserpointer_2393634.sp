#include <sourcemod>
#include <sdktools>

new bool:LaserUse[MAXPLAYERS+1];
new const g_lpontcolor[4] = {255,255,255,255};
new g_lbeam;
new g_lpont;

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Laser pointer",
	author = "Xines",
	description = "Laser pointer",
	version = VERSION,
	url = ""
}

public OnMapStart() {
	g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_lpont = PrecacheModel("materials/sprites/redglow1.vmt");
}

public OnClientPutInServer(client)
{
	LaserUse[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if((buttons & IN_USE))
	{
		LaserUse[client] = true;
		if(IsClientInGame(client) && LaserUse[client])
		{
			decl Float:m_fOrigin[3], Float:m_fImpact[3];
			GetClientEyePosition(client, m_fOrigin);
			GetClientSightEnd(client, m_fImpact);
			TE_SetupBeamPoints(m_fOrigin, m_fImpact, g_lbeam, 0, 0, 0, 0.1, 0.12, 0.0, 1, 0.0, {0,255,0,255}, 0);
			TE_SendToAll();
			TE_SetupGlowSprite(m_fImpact, g_lpont, 0.1, 0.25, g_lpontcolor[3]);
			TE_SendToAll();
		}
	}
	else if(!(buttons & IN_USE))
	{
		LaserUse[client] = false;
	}
	return Plugin_Continue;
}

stock GetClientSightEnd(client, Float:out[3])
{
	decl Float:m_fEyes[3];
	decl Float:m_fAngles[3];
	GetClientEyePosition(client, m_fEyes);
	GetClientEyeAngles(client, m_fAngles);
	TR_TraceRayFilter(m_fEyes, m_fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
	if(TR_DidHit())
		TR_GetEndPosition(out);
}

public bool:TraceRayDontHitPlayers(entity, mask, any:data)
{
	if(0 < entity <= MaxClients)
		return false;
	return true;
}