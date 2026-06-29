#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

static int g_iLaserMaterial, g_iHaloMaterial;

bool g_bLaserEnabled[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[TF2] Laser Beam",
	author = "Pelipoika",
	description = "",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_laserbeam", Command_ToggleLaser, ADMFLAG_ROOT, "Fire a deadly laser");
}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
}

public void OnClientPutInServer(int client)
{
	g_bLaserEnabled[client] = false;
}

public Action Command_ToggleLaser(int client, int args)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if(g_bLaserEnabled[client])
		{
			g_bLaserEnabled[client] = false;
			PrintToChat(client, "[LASER] Disabled");
		}
		else
		{
			g_bLaserEnabled[client] = true;
			PrintToChat(client, "[LASER] Enabled, hold R to fire the laser");
		}
	}
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon)
{
	if (IsPlayerAlive(client) && g_bLaserEnabled[client] && iButtons & IN_RELOAD)
	{
		float flPos[3], flAng[3];
		GetClientEyePosition(client, flPos);
		GetClientEyeAngles(client, flAng);
		
		flPos[2] -= 5.0;
		
		Handle TraceRay = TR_TraceRayFilterEx(flPos, flAng, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceFilterEnt, client);
		
		if(TR_DidHit(TraceRay))
		{
			float flEndPos[3];
			TR_GetEndPosition(flEndPos, TraceRay);
			int iHit = TR_GetEntityIndex(TraceRay);
			
			float flDamageForce[3];
			MakeVectorFromPoints(flPos, flEndPos, flDamageForce);
			NormalizeVector(flDamageForce, flDamageForce);
			ScaleVector(flDamageForce, 500.0);

			if(iHit > 0 && iHit <= MaxClients && IsClientInGame(iHit))
			{
				SDKHooks_TakeDamage(iHit, client, client, 2.0, DMG_ENERGYBEAM|DMG_PLASMA|DMG_DISSOLVE, _, flDamageForce);
				TeleportEntity(iHit, NULL_VECTOR, NULL_VECTOR, flDamageForce);
			}
			
			TE_SetupBeamPoints(flPos, flEndPos, g_iLaserMaterial, g_iHaloMaterial, 0, 0, 0.06, 1.0, 1.0, 1, 0.0, {255, 0, 0, 255}, 0);
			TE_SendToAll();
		}
		
		delete TraceRay;
	}
}

public bool TraceFilterEnt(int entityhit, int mask, any entity)
{
	if (entityhit != entity)
	{
		return true;
	}
	
	return false;
}