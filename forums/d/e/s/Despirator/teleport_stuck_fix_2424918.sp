#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define PLUGIN_VERSION	"1.0.1"

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
	for (new i = 1;i <= MaxClients; i++)
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
		//SDKUnhook(i, SDKHook_ShouldCollide, OnShouldCollide);
	}
}

public MRESReturn:DHooks_OnTeleport(client, Handle:hParams)
{
	if (DHookIsNullParam(hParams, 1))
	{
		return MRES_Ignored;
	}
	
	new Float:origin[3];
	DHookGetParamVector(hParams, 1, origin);
	
	CheckStuck(client, origin);
	
	return MRES_Ignored;
}

CheckStuck(client, const Float:vecOrigin[3] = {0.0, 0.0, 0.0})
{
	if (vecOrigin[0] == 0.0 && vecOrigin[1] == 0.0 && vecOrigin[2] == 0.0)
	{
		return;
	}
	
	ZKillTimerEx(g_hTimer_EndNoblock[client]);
	//SDKUnhook(client, SDKHook_ShouldCollide, OnShouldCollide);
	
	decl Float:vecMins[3], Float:vecMaxs[3];
	GetClientMins(client, vecMins);
	GetClientMaxs(client, vecMaxs);
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_ALL, TraceRayHitFilter, client);
}

public bool:TraceRayHitFilter(entity, mask, any:data)
{
	if (data != entity && 0 < entity <= MaxClients)
	{
		if (g_hTimer_EndNoblock[data] == INVALID_HANDLE)
		{
			SetEntProp(data, Prop_Send, "m_CollisionGroup", 2);
			//SDKHook(data, SDKHook_ShouldCollide, OnShouldCollide);
			g_hTimer_EndNoblock[data] = CreateTimer(1.0, Timer_EndNoblock, data, TIMER_REPEAT);
		}
		if (g_hTimer_EndNoblock[entity] == INVALID_HANDLE)
		{
			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
			//SDKHook(entity, SDKHook_ShouldCollide, OnShouldCollide);
			g_hTimer_EndNoblock[entity] = CreateTimer(1.0, Timer_EndNoblock, entity, TIMER_REPEAT);
		}
	}
	return false;
}

public Action:Timer_EndNoblock(Handle:timer, any:client)
{
	decl Float:vecOrigin[3];
	decl Float:vecMins[3], Float:vecMaxs[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientMins(client, vecMins);
	GetClientMaxs(client, vecMaxs);
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_ALL, TraceRayHitFilterPlayer, client);
	
	if (TR_DidHit())
	{
		return Plugin_Continue;
	}
	
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
	//SDKUnhook(client, SDKHook_ShouldCollide, OnShouldCollide);
	g_hTimer_EndNoblock[client] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

/*public bool:OnShouldCollide(entity, collisiongroup, contentsmask, bool:originalResult)
{
	if (collisiongroup == 5)
	{
		return false;
	}
	
	return originalResult;
}*/

public bool:TraceRayHitFilterPlayer(entity, mask, any:data)
{
	return bool:(data != entity && 0 < entity <= MaxClients);
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
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available && GetEngineVersion() == Engine_CSGO)
	{
		return true; 
	} 
	if (GetFeatureStatus(FeatureType_Native, "GuessSDKVersion") == FeatureStatus_Available && GuessSDKVersion() == SOURCE_SDK_CSGO)
	{ 
		return true;
	}
	return false;
}