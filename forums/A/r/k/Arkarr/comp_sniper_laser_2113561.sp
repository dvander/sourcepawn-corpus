#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

#define TF_TEAM_RED 2
#define TF_TEAM_BLU 3

new g_modelLaser, g_modelHalo; 
new bool:scopping[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name		=	"[TF2] Sniper Laser (How Do I Quickscope Edition V2)",
    author		=	"Arkarr & Oshizu (Made It All Time)",
    description	=	"Draw a simple laser from the sniper of player and where he is looking at [DOn'T MIND MY GOD DAMN ENGLISH!]",
    version		=	"1.02 (QuickscopeV2 Edition)",
    url			=	"http://www.sourcemod.net"
};

public OnMapStart()
{
	g_modelLaser = PrecacheModel("sprites/laser.vmt");
	g_modelHalo = PrecacheModel("materials/sprites/halo01.vmt");
}

public OnGameFrame()
{
	for (new i = MaxClients; i > 0; --i)
    {
		if(IsValidClient(i) && TF2_GetPlayerClass(i) == TFClass_Sniper && scopping[i])
		{
			decl Float:origin[3],Float:angles[3],Float:fwd[3],Float:rt[3],Float:up[3];

			GetClientEyePosition(i, origin);
			GetClientEyeAngles(i, angles);

			angles[0] += angles[0];
			angles[1] += angles[1];
			angles[2] += angles[2];    // angles are now transitioned relative to that, make sure you don't go over 360 or -360, best to use + or - 180 here

			GetAngleVectors(angles, fwd, rt, up);  //(not that you don't REALLLY need to do up like this, since players won't be tilted sideways and crap, but for other entities you do)
	
			if(GetClientTeam(i) == TF_TEAM_RED)
				TE_SetupBeamPoints(origin, GetEndPosition(i), g_modelLaser, g_modelHalo, 0, 1, 0.1, 2.0, 2.0, 1, 1.0, {255, 0, 0, 200}, 1)
			else
				TE_SetupBeamPoints(origin, GetEndPosition(i), g_modelLaser, g_modelHalo, 0, 1, 0.1, 2.0, 2.0, 1, 1.0, {0, 0, 255, 200}, 1)
			TE_SendToAll();
		}
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(condition == TFCond_Zoomed)
	{
		scopping[client] = true;
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(condition == TFCond_Zoomed)
	{
		scopping[client] = false;
	}
}

stock Float:GetEndPosition(client) 
{ 
	decl Float:start[3], Float:angle[3], Float:end[3]; 
	GetClientEyePosition(client, start); 
	GetClientEyeAngles(client, angle); 
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client); 
	if (TR_DidHit(INVALID_HANDLE)) 
	{ 
		TR_GetEndPosition(end, INVALID_HANDLE); 
	} 
	return end;
} 

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)  
{ 
	return entity > MaxClients; 
} 

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}