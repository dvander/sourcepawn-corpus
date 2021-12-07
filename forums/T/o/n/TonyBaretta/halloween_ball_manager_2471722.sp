#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#pragma newdecls required

#define PLUGIN_VERSION "1.2"

ConVar g_hBallSoundEnabled;
ConVar g_hBallSpawned;
int g_hballcount = 0;

public Plugin myinfo = {
    name = "Halloween Ball Manager",
    author = "TonyBaretta",
    description = "Halloween Ball Manager",
    version = PLUGIN_VERSION,
    url = "http://www.wantedgov.it"
};

public void OnMapStart()
{
	PrecacheModel("models/props_halloween/hwn_kart_ball01.mdl", true);
	CreateTimer(0.5, CheckForEntPos, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}
public void OnPluginStart()
{
	RegAdminCmd("sm_hball", Command_HBallSpawn, ADMFLAG_SLAY, "spawn halloween ball");
	RegAdminCmd("sm_kball", Command_HBallKill, ADMFLAG_SLAY, "kill halloween ball/balls");
	AddNormalSoundHook(view_as<NormalSHook>(MySoundHook));
	g_hBallSoundEnabled = CreateConVar("hball_sound", "0", "Enables/disables ball sound", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hBallSpawned = CreateConVar("hball_max", "5.0", "max number of balls", FCVAR_NONE);
	CreateConVar("halloween_ball_manager_version", PLUGIN_VERSION, "Current Halloween Ball Manager version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public Action Command_HBallSpawn(int client,int args)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) >=2)  {
		int iMaxBall = GetConVarInt(g_hBallSpawned);
		if (g_hballcount >= iMaxBall){
			PrintToChat(client, "\x04 Halloween Ball Spawned %d of %d you can't spawn more.", g_hballcount, iMaxBall);
		}
		if (g_hballcount < iMaxBall){
			float origin[3], angles[3], pos[3];
			GetClientEyePosition(client, origin);
			GetClientEyeAngles(client, angles);
			Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceFilterSelf, client);
			
			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(pos, trace);
				pos[2] += 25.0;
				int iBall = CreateEntityByName("prop_soccer_ball");
				if(IsValidEntity(iBall))
				{
					DispatchKeyValue(iBall, "model", "models/props_halloween/hwn_kart_ball01.mdl");
					DispatchSpawn(iBall);
					TeleportEntity(iBall, pos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			delete trace;
			g_hballcount++;
			PrintToChat(client, "\x04 Halloween Ball Spawned %d of %d .", g_hballcount, iMaxBall);
		}
	}
	return Plugin_Handled; 
}
public Action Command_HBallKill(int client,int args)
{
	int index = -1; 
	while ((index = FindEntityByClassname(index, "prop_soccer_ball")) > 0) 
	{ 
		AcceptEntityInput(index, "Kill");
		PrintToChat(client, "\x04 Halloween Ball Deleted.");
		g_hballcount = 0;
	} 
	return Plugin_Handled; 
}
public Action MySoundHook(int clients[64], int numClients, char Pathname[PLATFORM_MAX_PATH], int entity, int channel, float volume, int level, int pitch, int flags) 
{
	if(!g_hBallSoundEnabled.IntValue){
		if(StrContains(Pathname, "bumper_car_hit_ball.wav", false) != -1)return Plugin_Stop;
		else
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public Action CheckForEntPos(Handle timer)
{
	int iProjectile = -1;
	while ((iProjectile = FindEntityByClassname(iProjectile, "tf_projectile_*")) != -1)
	{
		float projloc[3];
		GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", projloc);

		int iHBall = -1;
		while ((iHBall = FindEntityByClassname(iHBall, "prop_soccer_ball")) != -1)
		{
			float spawnloc[3];
			GetEntPropVector(iHBall, Prop_Send, "m_vecOrigin", spawnloc);
			if (GetVectorDistance(projloc, spawnloc) < 190.00)
			{
				AcceptEntityInput(iProjectile, "Kill");
				break;
			}
		}
	}
	return Plugin_Continue;
}
public bool TraceFilterSelf(int entity, int contentsMask, any iPumpking)
{
	if(entity == iPumpking || entity > MaxClients || (entity >= 1 && entity <= MaxClients))
		return false;
	
	return true;
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}