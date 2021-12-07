#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <IsTargetInSightRange>
#define PLUGIN_VERSION "1.0.0"

new Handle:g_isEnabled = INVALID_HANDLE;

#define IS_VALID_CLIENT(%1) 	(%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) 		(GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) 		(GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1) 	(IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))
#define IS_VALID_SURVIVOR(%1) 	(IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) 	(IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define GET_ZOMBIE_CLASS(%1) 	GetEntProp(%1, Prop_Send, "m_zombieClass")

#define FFADE_IN            0x0001
#define FFADE_OUT           0x0002
#define FFADE_MODULATE      0x0004
#define FFADE_STAYOUT       0x0008
#define FFADE_PURGE         0x0010
 
public Plugin:myinfo = 
{
	name = "Flashbang Boomer",
	author = "Dr_Newbie",
	description = "Boomer will give a big flash when it explode.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	g_isEnabled = CreateConVar("sm_flashbangboomer", "1", "(1 = ON ; 0 = OFF)", FCVAR_NOTIFY);
	HookEvent("player_death", Event_PlayerKillBoomer);
}

public Action:Event_PlayerKillBoomer(Handle:hEvent, const String:sEvName[], bool:bSilent)
{
	if(!GetConVarBool(g_isEnabled))
		return Plugin_Continue;
	new iuserid = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new Float:BoomerpOs[3];
	new Float:PlayerpOs[3];
	if(IS_VALID_INFECTED(iuserid) && GET_ZOMBIE_CLASS(iuserid) == 2) {
		GetClientAbsOrigin(iuserid, BoomerpOs);
		for(new iClient = 0; iClient <= MaxClients; iClient++) {
			if(IS_VALID_SURVIVOR(iClient) && IsClientInGame(iClient)) {
				if(!IsFakeClient(iClient)) {
					GetClientEyePosition(iClient, PlayerpOs);
					new Float:result = GetVectorDistance(BoomerpOs, PlayerpOs);
					new during;
					new bool:iInSight, iInBlock;
					TR_TraceRayFilter(PlayerpOs, BoomerpOs, MASK_VISIBLE_AND_NPCS, RayType_EndPoint, TraceRayFilterClients, iClient);
					iInSight = IsTargetInSightRange(iClient, iuserid, 180.0, result, true, false);
					iInBlock = TR_GetEntityIndex(INVALID_HANDLE);
					if(iInSight == false || iInBlock) {
						during = 200;
					} else {
						if(result > 2000.0) during = 500;
						else if( 1500.0 < result && result <= 2000.0) during = 1500;
						else if( 1000.0 < result && result <= 1500.0) during = 2000;
						else during = 4000;
					}
					PerformFade(iClient, during, {127, 235, 212}, 255);
				}
			}
		}		
	}
	return Plugin_Continue;
}

PerformFade(iClient, iDuration, const iColor[3], iAlpha) 
{
	new iFullBlindDuration = iDuration / 4;
	new Handle:hFadeClient = StartMessageOne("Fade", iClient);
	BfWriteShort(hFadeClient, iDuration = 03850|iFullBlindDuration);
	BfWriteShort(hFadeClient, iFullBlindDuration);
	BfWriteShort(hFadeClient, (FFADE_PURGE|FFADE_IN));
	BfWriteByte(hFadeClient, iColor[0]);
	BfWriteByte(hFadeClient, iColor[1]);
	BfWriteByte(hFadeClient, iColor[2]);
	BfWriteByte(hFadeClient, iAlpha);
	EndMessage();
}

public bool:TraceRayFilterClients(entity, mask, any:data)
{
	if(entity > 0 && entity <=MaxClients)
	{
		if(IS_SURVIVOR(entity)) {
			if(entity == data)
				return false;
			else
				return true;
			}
	}
	return true;
}