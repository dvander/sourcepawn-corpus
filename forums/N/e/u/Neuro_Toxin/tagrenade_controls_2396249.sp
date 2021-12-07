#include <sdkhooks>
#include <sdktools_engine>
#include <sdktools_trace>
#include <cstrike>

ConVar cvar_tagrenade_range;
ConVar cvar_tagrenade_time;
ConVar cvar_tagrenade_usetrace;
bool g_bPlayerIsTagged[MAXPLAYERS+1];
int g_offCollisionGroup = -1;

public Plugin myinfo =
{
	name = "Advanced Tactical Grenades",
	author = "Neuro Toxin",
	description = "Gives Tatical Grenades a few more settings",
	version = "0.0.3",
	url = "https://forums.alliedmods.net/showthread.php?p=2396249#post2396249"
}

public void OnPluginStart()
{
	HookEvent("tagrenade_detonate", OnTagrenadeDetonate);
	cvar_tagrenade_range = CreateConVar("tagrenade_range", "700.0", "Sets the proximity in which the tactical grenade will tag an opponent.");
	cvar_tagrenade_time = CreateConVar("tagrenade_time", "5.0", "How long a player is tagged for in seconds.");
	cvar_tagrenade_usetrace = CreateConVar("tagrenade_usetrace", "1", "Players must be directly tagged by grenade for effect.");
}

public void OnClientConnected(int client)
{
	g_bPlayerIsTagged[client] = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "tagrenade_projectile"))
		return;
		
	SDKHook(entity, SDKHook_Spawn, OnTagrenadeProjectileSpawned);
}

public Action OnTagrenadeProjectileSpawned(int entity)
{
	if (g_offCollisionGroup == -1)
	{
		g_offCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
		if (g_offCollisionGroup == -1)
			return Plugin_Continue;
	}
	SetEntData(entity, g_offCollisionGroup, 2, 4, true);
	return Plugin_Continue;
}

public void OnTagrenadeDetonate(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	DataPack pack = new DataPack();
	pack.WriteCell(userid);
	pack.WriteCell(GetEventInt(event, "entityid"));
	pack.WriteFloat(GetEventFloat(event, "x"));
	pack.WriteFloat(GetEventFloat(event, "y"));
	pack.WriteFloat(GetEventFloat(event, "z"));
	CreateTimer(0.0, OnGetTagrenadeTimes, pack);
}

public Action OnGetTagrenadeTimes(Handle timer, any data)
{
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
	{
		CloseHandle(pack);
		return Plugin_Continue;
	}
	
	int entity = pack.ReadCell();
	
	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
	{
		CloseHandle(pack);
		return Plugin_Continue;
	}
	
	float position[3];
	float targetposition[3];
	float distance;
	
	position[0] = pack.ReadFloat();
	position[1] = pack.ReadFloat();
	position[2] = pack.ReadFloat();
	CloseHandle(pack);
	
	for (int target = 1; target <= MaxClients; target++)
	{
		if (!IsClientInGame(target))
			continue;
		
		if (!IsPlayerAlive(target))
			continue;
			
		GetClientEyePosition(target, targetposition);
		distance = GetVectorDistance(position, targetposition);
		if (distance > cvar_tagrenade_range.FloatValue)
			continue;
			
		if (team == GetClientTeam(target))
			continue;
		
		if (!cvar_tagrenade_usetrace.BoolValue)
		{
			TagPlayerWithTagrenade(target);
			continue;
		}
		
		Handle trace = TR_TraceRayFilterEx(position, targetposition, MASK_SOLID, RayType_EndPoint, OnTraceForTagrenade, entity);
		if (TR_DidHit(trace) && TR_GetEntityIndex(trace) == target)
			TagPlayerWithTagrenade(target);
		
		CloseHandle(trace);
	}
	return Plugin_Continue;
}

public void TagPlayerWithTagrenade(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", GetGameTime() + cvar_tagrenade_time.FloatValue);
	CreateTimer(cvar_tagrenade_time.FloatValue, CleanPlayerTagrenade, GetClientUserId(client));
	g_bPlayerIsTagged[client] = true;
}

public Action CleanPlayerTagrenade(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return Plugin_Continue;
		
	SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
	g_bPlayerIsTagged[client] = false;
	return Plugin_Continue;
}

public bool OnTraceForTagrenade(int entity, int contentsMask, any weapon)
{
	if (entity == weapon)
		return false;
	return true;
}