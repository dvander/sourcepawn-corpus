#pragma semicolon 1
#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define CS_PLAYER_SPEED_RUN 260.0

new Handle:g_hGetSpeed;
new Handle:g_hTeleport;

new Float:g_fHighSpeed[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "CS:GO Knockback Fix",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Enables knockback in CS:GO by allowing higher walking speeds when necassary",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		Format(error, err_max, "This fix applies only on CS:GO.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:hGameConf = LoadGameConfigFile("knockbackfix.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Gamedata file smrpg_speed.games.txt is missing.");
	
	new iOffset = GameConfGetOffset(hGameConf, "GetPlayerMaxSpeed");
	CloseHandle(hGameConf);
	
	if(iOffset == -1)
		SetFailState("Gamedata is missing the \"GetPlayerMaxSpeed\" offset.");
	
	g_hGetSpeed = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, Hook_GetPlayerMaxSpeedPost);
	if(g_hGetSpeed == INVALID_HANDLE)
		SetFailState("Failed to create hook on \"GetPlayerMaxSpeed\".");
	
	hGameConf = LoadGameConfigFile("sdktools.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Gamedata file sdktools.games.txt is missing.");
	iOffset = GameConfGetOffset(hGameConf, "Teleport");
	CloseHandle(hGameConf);
	if(iOffset == -1)
		SetFailState("Gamedata is missing the \"Teleport\" offset.");
	
	g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, Hook_OnTeleport);
	if(g_hTeleport == INVALID_HANDLE)
		return;
	DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
	DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
	DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
	DHookAddParam(g_hTeleport, HookParamType_Bool);
	
	// Account for late loading
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	DHookEntity(g_hGetSpeed, true, client);
	DHookEntity(g_hTeleport, false, client);
}

public OnClientDisconnect(client)
{
	g_fHighSpeed[client] = 0.0;
}

public MRESReturn:Hook_GetPlayerMaxSpeedPost(client, Handle:hReturn)
{
	if(g_fHighSpeed[client] <= 0.0)
		return MRES_Ignored;
	
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
	if(GetVectorLength(fVelocity) <= CS_PLAYER_SPEED_RUN || !IsPlayerAlive(client))
	{
		g_fHighSpeed[client] = 0.0;
		return MRES_Ignored;
	}
	
	// Set new high limit temporarily.
	DHookSetReturn(hReturn, g_fHighSpeed[client]);
	
	return MRES_Override;
}

public MRESReturn:Hook_OnTeleport(client, Handle:hParams)
{
	if(DHookIsNullParam(hParams, 3))
		return MRES_Ignored;

	new Float:velocity[3];
	DHookGetParamVector(hParams, 3, velocity);

	// Something wants the player to get faster than he is usually allowed to walk.
	// Set the maxspeed to that value until he slowed down enough again
	new Float:fSpeed = GetVectorLength(velocity);
	if(fSpeed > CS_PLAYER_SPEED_RUN)
		g_fHighSpeed[client] = fSpeed;
	
	return MRES_Ignored;
}