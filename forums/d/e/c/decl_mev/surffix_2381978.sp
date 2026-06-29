#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

public Plugin myinfo = 
{
	name = "Surf bug fix",
	author = "mev",
	description = "Eliminates random surfing bugs that slow you down",
	version = VERSION,
	url = "http://steamcommunity.com/id/mevv/"
}

ConVar g_hSurfFixEnable;
bool   g_bSurfFixEnable;

float g_fMaxVelocity;

public void OnPluginStart()
{
	CreateConVar("surffix_version", VERSION, "Surf fix version", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED);
	
	g_hSurfFixEnable = CreateConVar("surffix_enable", "1", "Enables surf fix.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(g_hSurfFixEnable, OnEnableSurfFixChanged);
	HookConVarChange(FindConVar("sv_maxvelocity"), OnEnableMaxVelocityChanged);
}

public void OnConfigsExecuted()
{
	g_bSurfFixEnable = GetConVarBool(g_hSurfFixEnable);
}

public OnEnableSurfFixChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSurfFixEnable = StringToInt(newValue) == 1 ? true : false;
}

public OnEnableMaxVelocityChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fMaxVelocity = StringToFloat(newValue);
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data && !(0 < entity <= MaxClients);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(g_bSurfFixEnable)
	{
		// Set up and do tracehull to find out if the player landed on a surf
		float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);

		float vMins[3];
		GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);

		float vMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
		
		// Fix weird shit that made people go through the roof
		vPos[2] += 1.0;
		vMaxs[2] -= 1.0;
		
		float vEndPos[3];
		
		// Take account for the client already being stuck
		vEndPos[0] = vPos[0];
		vEndPos[1] = vPos[1];
		vEndPos[2] = vPos[2] - g_fMaxVelocity;
		
		TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);
		
		if(TR_DidHit())
		{
			// Gets the normal vector of the surface under the player
			float vPlane[3], vRealEndPos[3];
			
			TR_GetPlaneNormal(INVALID_HANDLE, vPlane);
			TR_GetEndPosition(vRealEndPos);
			
			// Check if client is on a surf ramp, and if he is stuck
			if(0.7 > vPlane[2] && vPos[2] - vRealEndPos[2] < 0.975)
			{
				// Player was stuck, lets put him back on the ramp
				TeleportEntity(client, vRealEndPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}
