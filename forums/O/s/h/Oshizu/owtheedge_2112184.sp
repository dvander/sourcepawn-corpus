#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

#define TF_TEAM_RED 2
#define TF_TEAM_BLU 3

new g_modelLaser, g_modelHalo; 
new String:plugin_tag[60] = "{green}[SniperLaser]{default}";
new bool:scopping[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name		=	"[TF2] Sniper Laser (How Do I Quickscope Edition)",
    author		=	"Arkarr & Oshizu (Made It All Time",
    description	=	"Draw a simple laser from the sniper of player and where he is looking at [DOn'T MIND MY GOD DAMN ENGLISH!]",
    version		=	"1.01 (Quickscope Edition)",
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
			new Float:position_p[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", position_p);
			position_p[2]+= 73.0;
			position_p[1]+= 5.0;
			position_p[0]-= 20.0;
			if(GetClientTeam(i) == TF_TEAM_RED)
				TE_SetupBeamPoints(position_p, GetEndPosition(i), g_modelLaser, g_modelHalo, 0, 1, 0.1, 2.0, 2.0, 1, 1.0, {255, 0, 0, 200}, 1)
			else
				TE_SetupBeamPoints(position_p, GetEndPosition(i), g_modelLaser, g_modelHalo, 0, 1, 0.1, 2.0, 2.0, 1, 1.0, {0, 0, 255, 200}, 1)
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