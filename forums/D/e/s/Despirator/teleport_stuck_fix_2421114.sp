#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define PLUGIN_VERSION	"1.0.0"

new Handle:g_hTeleport;

new Handle:g_hTimer_EndNoblock[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Teleport Stuck Fix", 
	author = "FrozDark", 
	description = "Auto noblock for players if they stuck by teleport", 
	version = PLUGIN_VERSION, 
	url = "www.hlmod.ru"
}

public OnPluginStart()
{
	CreateConVar("sm_teleport_stuck_fix_version", PLUGIN_VERSION, "Zombie:Unlimited teleport stuck fix plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	new Handle:hGameData = LoadGameConfigFile("sdktools.games");
	
	if (hGameData == INVALID_HANDLE)
	{
		return;
	}
	
	new iOffset = GameConfGetOffset(hGameData, "Teleport");
	CloseHandle(hGameData);
	
	if (iOffset == -1)
	{
		SetFailState("[DHooks] Offset for Teleport function is not found!");
		return;
	}
	
	g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
	if (g_hTeleport == INVALID_HANDLE)
	{
		SetFailState("[DHooks] Could not create Teleport hook function!");
		return;
	}
	
	DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
	DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
	DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
	
	if (IsCSGO())
	{
		DHookAddParam(g_hTeleport, HookParamType_Bool);
	}
	for(new i = 1;i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
	DHookEntity(g_hTeleport, true, client);
}

public OnClientDisconnect_Post(client)
{
	ZKillTimerEx(g_hTimer_EndNoblock[client]);
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		ZKillTimerEx(g_hTimer_EndNoblock[i]);
	}
}

public MRESReturn:DHooks_OnTeleport(client, Handle:hParams)
{
	new bool:bOriginNull = DHookIsNullParam(hParams, 1);
	
	if (bOriginNull)
	{
		return MRES_Ignored;
	}
	
	decl Float:origin[3];
	DHookGetParamVector(hParams, 1, origin);
	
	CheckStuck(client, origin);
	
	return MRES_Ignored;
}

CheckStuck(client, Float:origin[3] = {0.0, 0.0, 0.0})
{
	decl Float:vecOrigin[3];
	decl Float:vecMins[3], Float:vecMaxs[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientMins(i, vecMins);
			GetClientMaxs(i, vecMaxs);
			if (origin[0] == 0.0 && origin[1] == 0.0 && origin[2] == 0.0)
			{
				GetClientAbsOrigin(i, vecOrigin);
			}
			else
			{
				vecOrigin[0] = origin[0];
				vecOrigin[1] = origin[1];
				vecOrigin[2] = origin[2];
			}
			TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_ALL, TraceRayHitFilter, client);
			
			new bool:bDidHit = TR_DidHit();
			
			if (!bDidHit)
			{
				GetClientMins(client, vecMins);
				GetClientMaxs(client, vecMaxs);
				GetClientAbsOrigin(client, vecOrigin);
				
				TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_ALL, TraceRayHitFilter, i);
				bDidHit = TR_DidHit();
			}
			
			if (bDidHit)
			{
				ZKillTimerEx(g_hTimer_EndNoblock[i]);
				SetEntProp(i, Prop_Send, "m_CollisionGroup", 2);
				g_hTimer_EndNoblock[i] = CreateTimer(1.0, Timer_EndNoblock, i);
				
				if (g_hTimer_EndNoblock[client] == INVALID_HANDLE)
				{
					SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
					g_hTimer_EndNoblock[client] = CreateTimer(1.0, Timer_EndNoblock, client);
				}
			}
		}
	}
	
}

public Action:Timer_EndNoblock(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
	g_hTimer_EndNoblock[client] = INVALID_HANDLE;
	
	CheckStuck(client);
}

public bool:TraceRayHitFilter(entity, mask, any:data)
{
	return entity == data;
}

stock ZKillTimerEx(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock bool:IsCSGO()
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available) 
	{
		switch (GetEngineVersion()) 
		{ 
			case Engine_CSGO: return true; 
		} 
	} 
	else if (GetFeatureStatus(FeatureType_Native, "GuessSDKVersion") == FeatureStatus_Available) 
	{ 
		switch (GuessSDKVersion())
		{ 
			case SOURCE_SDK_CSGO: return true;
		}
	}
	return false;
}