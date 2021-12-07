#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required;

#define PLUGIN_AUTHOR 	"Arkarr"
#define PLUGIN_VERSION 	"1.00"

#define MAX_BUTTONS 	25

int LastButtons[MAXPLAYERS + 1];

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "[CSS/CSGO] Kick the Nade !", 
	author = PLUGIN_AUTHOR, 
	description = "Allow the players to kick the incoming grenades", 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO && g_Game != Engine_CSS)
		SetFailState("This plugin is for CSGO/CSS only.");
}

public void OnClientDisconnect_Post(int client)
{
	LastButtons[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);
		
		if ((buttons & button))
		{
			if (!(LastButtons[client] & button))
			{
				OnButtonPress(client, button);
			}
		}
		else if ((LastButtons[client] & button))
		{
			OnButtonRelease(client, button);
		}
	}
	
	LastButtons[client] = buttons;
	
	return Plugin_Continue;
}

public void OnButtonPress(int client, int button)
{
	if (!(button & IN_USE))
		return;
	
	for (int nadeIndex = MaxClients; nadeIndex < GetMaxEntities(); nadeIndex++)
	{
		if (!IsValidEntity(nadeIndex) || !IsValidEdict(nadeIndex))
			continue;
		
		char strClassName[50];
		GetEdictClassname(nadeIndex, strClassName, 32);
		
		if (StrContains(strClassName, "projectile") != -1)
		{
			if (StrContains(strClassName, "hegrenade") == -1 && 
				StrContains(strClassName, "flashbang") == -1 && 
				StrContains(strClassName, "smoke") == -1 && 
				StrContains(strClassName, "decoy") == -1 && 
				StrContains(strClassName, "molotov") == -1 && 
				StrContains(strClassName, "incgrenade") == -1)
			continue;
			
			if (!IsEntityInSightRange(client, nadeIndex, 120.0, 300.0, false))
				continue;
						
			float start[3], angle[3], end[3]; 
			GetClientEyePosition(client, start); 
			GetClientEyeAngles(client, angle); 
			TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client); 
			if (!TR_DidHit(INVALID_HANDLE))
				continue;
				
			TR_GetEndPosition(end, INVALID_HANDLE); 
			
			float nadePos[3];
			GetEntPropVector(nadeIndex, Prop_Send, "m_vecOrigin", nadePos);
			MakeVectorFromPoints(nadePos, end, end);
			
			GetVectorAngles(end, angle);
			NormalizeVector(end, end);
			ScaleVector(end, 500.0);
			
			
			TeleportEntity(nadeIndex, NULL_VECTOR, angle, end);
			
			break;
		}
	}
}

public void OnButtonRelease(int client, int button)
{
	//Nothing to do here.
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data)  
{ 
	return entity > MaxClients; 
}  

stock bool IsEntityInSightRange(int client, int target, float angle = 90.0, float distance = 0.0, bool heightcheck = true, bool negativeangle = false)
{
	if (angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	if (!IsClientInGame(client) || !IsClientConnected(client))
		ThrowError("Client is not alive.");
	
	float clientpos[3], targetpos[3], anglevector[3], targetvector[3], resultangle, resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if (negativeangle)
		NegateVector(anglevector);
	
	GetClientAbsOrigin(client, clientpos);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetpos);
	
	if (heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if (resultangle <= angle / 2)
	{
		if (distance > 0)
		{
			if (!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if (distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}
