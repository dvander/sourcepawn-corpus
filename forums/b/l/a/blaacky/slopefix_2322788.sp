#include <sourcemod>
#include <sdktools>

#define VERSION "1.2"

public Plugin myinfo = 
{
	name = "Slope Landing Fix",
	author = "Mev & Blacky",
	description = "Makes it so landing on a slope will gaurantee a boost.",
	version = VERSION,
	url = "http://steamcommunity.com/id/blaackyy/ & http://steamcommunity.com/id/mevv/"
}

float g_vCurrent[MAXPLAYERS + 1][3];
float g_vLast[MAXPLAYERS + 1][3];

bool g_bOnGround[MAXPLAYERS + 1];
bool g_bLastOnGround[MAXPLAYERS + 1];

ConVar g_hSlopeFixEnable;
bool   g_bSlopeFixEnable;

public void OnPluginStart()
{
	CreateConVar("slopefix_version", VERSION, "Slope fix version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	g_hSlopeFixEnable = CreateConVar("slopefix_enable", "1", "Enables slope fix.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hSlopeFixEnable, OnEnableSlopeFixChanged);
}

public void OnConfigsExecuted()
{
	g_bSlopeFixEnable = GetConVarBool(g_hSlopeFixEnable);
}

public OnEnableSlopeFixChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bSlopeFixEnable = bool:StringToInt(newValue);
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data && !(0 < entity <= MaxClients);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(g_bSlopeFixEnable == true)
	{
		g_bLastOnGround[client] = g_bOnGround[client];
		
		if (GetEntityFlags(client) & FL_ONGROUND)
			g_bOnGround[client] = true;
		else
			g_bOnGround[client] = false;
		
		g_vLast[client][0]    = g_vCurrent[client][0];
		g_vLast[client][1]    = g_vCurrent[client][1];
		g_vLast[client][2]    = g_vCurrent[client][2];
		g_vCurrent[client][0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		g_vCurrent[client][1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		g_vCurrent[client][2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
		
		// Check if player landed on the ground
		if (g_bOnGround[client] == true && g_bLastOnGround[client] == false)
		{
			// Set up and do tracehull to find out if the player landed on a slope
			float vPos[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);

			float vMins[3];
			GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);

			float vMaxs[3];
			GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);

			float vEndPos[3];
			vEndPos[0] = vPos[0];
			vEndPos[1] = vPos[1];
			vEndPos[2] = vPos[2] - FindConVar("sv_maxvelocity").FloatValue;
			
			TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);

			if(TR_DidHit())
			{
				// Gets the normal vector of the surface under the player
				float vPlane[3], vLast[3];
				TR_GetPlaneNormal(INVALID_HANDLE, vPlane);
				
				// Make sure it's not flat ground and not a surf ramp (1.0 = flat ground, < 0.7 = surf ramp)
				if(0.7 <= vPlane[2] < 1.0)
				{
					/*
					Copy the ClipVelocity function from sdk2013 
					(https://mxr.alliedmods.net/hl2sdk-sdk2013/source/game/shared/gamemovement.cpp#3145)
					With some minor changes to make it actually work
					*/
					vLast[0]  = g_vLast[client][0];
					vLast[1]  = g_vLast[client][1];
					vLast[2]  = g_vLast[client][2];
					vLast[2] -= (FindConVar("sv_gravity").FloatValue * GetTickInterval() * 0.5);
					
					float fBackOff = GetVectorDotProduct(vLast, vPlane);
						
					float change, vVel[3];
					for(int i; i < 2; i++)
					{
						change  = vPlane[i] * fBackOff;
						vVel[i] = vLast[i] - change;
					}
					
					float fAdjust = GetVectorDotProduct(vVel, vPlane);
					if(fAdjust < 0.0)
					{
						for(int i; i < 2; i++)
						{
							vVel[i] -= (vPlane[i] * fAdjust);
						}
					}
					
					vVel[2] = 0.0;
					vLast[2] = 0.0;
					
					// Make sure the player is going down a ramp by checking if they actually will gain speed from the boost
					if(GetVectorLength(vVel) > GetVectorLength(vLast))
					{
						// Teleport the player, also adds basevelocity
						if(GetEntityFlags(client) & FL_BASEVELOCITY)
						{
							float vBase[3];
							GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", vBase);
							
							AddVectors(vVel, vBase, vVel);
						}
						
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);		
					}
				}
			}	
		}
	}
}