#pragma semicolon 1

#include <rtd2>
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

new Handle:hTrace;

new Handle:cvarRPBounce;

new Float:RPBounce;

new bool:JustLaunched[MAXPLAYERS+1];
new Float:LastAirVel[MAXPLAYERS+1][3];
new bool:HasBouncyPerk[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "RTD2 Bouncy",
	author = "kking117",
	description = "Adds the negative perk bouncy to rtd2."
};

public void OnPluginStart()
{
	if(RTD2_IsRegOpen())
	{
		RegisterPerks();
	}
	
	cvarRPBounce=CreateConVar("rtd_bouncy_rebound", "1.1", "The amount of velocity that is rebounded when under the effects of bouncy.", _, false, -1000.0, false, 1000.0);
	HookConVarChange(cvarRPBounce, CvarChange);
}

public void OnMapStart()
{
	RPBounce = GetConVarFloat(cvarRPBounce);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==cvarRPBounce)
	{
	    RPBounce =StringToFloat(newValue);
	}
}

public int RTD2_OnRegOpen()
{
	RegisterPerks();
}

void RegisterPerks()
{
	new iId = RTD2_RegisterPerk("bouncy", "Bouncy", 0, "vo/scout_sf12_badmagic04.mp3", 0, "0", "0", "bounce|rebound|bouncy", RTD2Manager_Perk);
}

public int RTD2Manager_Perk(int client, int iPerkId, bool bEnable)
{
	if(bEnable)
	{
		HasBouncyPerk[client]=true;
	}
	else
	{
		HasBouncyPerk[client]=false;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(HasBouncyPerk[client])
	{
		new Float:vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);	// get current speeds
		new Float:clientPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPosition);
		if((GetEntityFlags(client) & FL_ONGROUND))
		{
			if(!JustLaunched[client] && LastAirVel[client][2]<-2.0)
			{
				LastAirVel[client][0]*=RPBounce;
				LastAirVel[client][1]*=RPBounce;
				LastAirVel[client][2]*=RPBounce*-1.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, LastAirVel[client]);
				JustLaunched[client]=true;
			}
		}
		else
		{
			new Float:NextPosition[3];
			NextPosition[0]=clientPosition[0]+(vVel[0]*0.1);
			NextPosition[1]=clientPosition[1]+(vVel[1]*0.1);
			if(vVel[2]>1.0)
			{
				NextPosition[2]=clientPosition[2]+(vVel[2]*0.1);
			}
			else
			{
				NextPosition[2]=clientPosition[2];
			}
			if(TraceHullCollide(clientPosition, NextPosition, client))
			{
				new Float:vBuffer[3];
				new Float:ReboundAngle[3];
				new Float:VelocityAngle[3];
				SubtractVectors(clientPosition, NextPosition, vBuffer); 
				NormalizeVector(vBuffer, vBuffer); 
				GetVectorAngles(vBuffer, ReboundAngle);  
				SubtractVectors(NextPosition, clientPosition, vBuffer); 
				NormalizeVector(vBuffer, vBuffer); 
				GetVectorAngles(vBuffer, VelocityAngle);			
				
				new Handle:trace = TR_TraceRayFilterEx(clientPosition, VelocityAngle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);
				//handles velocity when colliding with walls and ceilings
				//code was taken from the rocket bounce plugin
				if(TR_DidHit(trace))
				{
					new Float:vNormal[3];
					TR_GetPlaneNormal(trace, vNormal);
					CloseHandle(trace);
					new Float:dotProduct = GetVectorDotProduct(vNormal, vVel);
		
					ScaleVector(vNormal, dotProduct);
					ScaleVector(vNormal, 2.0);
					
					SubtractVectors(vVel, vNormal, LastAirVel[client]);
					LastAirVel[client][0]*=RPBounce;
					LastAirVel[client][1]*=RPBounce;
					LastAirVel[client][2]*=RPBounce;

					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, LastAirVel[client]);
				}
				else
				{
					CloseHandle(trace);
				}
			}
			LastAirVel[client][0]=vVel[0];
			LastAirVel[client][1]=vVel[1];
			LastAirVel[client][2]=vVel[2];
			JustLaunched[client]=false;
		}
	}
	else
	{
	    JustLaunched[client]=true;
	}
}

stock bool:TraceHullCollide(Float:pos2[3], Float:pos[3], entity)
{
    //hTrace = TR_TraceRayFilterEx(pos2, pos, MASK_SOLID, RayType_EndPoint, TraceFilter_NoNPCPLAYERPROJ, entity);
	new Float:vecmaxs[3];
	new Float:vecmins[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecmaxs);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vecmins);
	hTrace = TR_TraceHullFilterEx(pos2, pos, vecmins, vecmaxs, MASK_SOLID, TraceFilter_NoNPCPLAYERPROJ, entity);
	if(hTrace != INVALID_HANDLE)
	{
        if(TR_DidHit(hTrace))//we hit something
		{
		    CloseHandle(hTrace);
		    return true;
		}
		else//we hit nothing man
		{
			CloseHandle(hTrace);
			return false;
		}
	}
	return false;
}

stock bool:TraceFilter_NoNPCPLAYERPROJ(entity, contentsMask, any:ent)
{
	if(entity == ent)
	{
		return false;
	}
	else if(IsValidClient(entity))
	{
	    return false;
	}
	else if(IsValidEntity(entity))
	{
	    new String:ClassName[255];
		GetEntityClassname(entity, ClassName, sizeof(ClassName)); //we really don't care about projectiles
		if(!StrContains(ClassName, "tf_projectile", false))
		{
		    return false;
		}
		else if(!StrContains(ClassName, "obj_", false)) //buildings and sapper attatchments
		{
		    return false;
		}
		else if(!StrContains(ClassName, "_boss", false)) //monoculous and tank_boss
		{
		    return false;
		}
		else if(!StrContains(ClassName, "mera", false)) //MERASMUS
		{
		    return false;
		}
		else if(!StrContains(ClassName, "tf_zomb", false)) //tf2 skeletons
		{
		    return false;
		}
		else if(!StrContains(ClassName, "headless_hat", false)) //pumpkin boy
		{
		    return false;
		}
	}
	return true;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}

stock bool:IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}