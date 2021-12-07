/**
 * ==============================================================================
 * [TF2] Merasmus Stun Enabler!
 * Copyright (C) 2016 Benoist3012
 * ==============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

public const Plugin myinfo =
{
	name = "[TF2]Merasmus Stun Enabler",
	author = "Benoist3012",
	description = "Fix merasmus not being stunned by bomb heads on maps other than ghost fort.",
	version = "0.1",
	url	= "http://steamcommunity.com/id/Benoist3012/"
}

Handle g_hSDKStunMerasmus;

public void OnMapStart()
{
	CreateConVar("merasmus_stun_enabler", "0.1", "[TF2] Merasmus Stun Enabler!", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SDK_Init();
}

void SDK_Init()
{
	Handle hGamedata = LoadGameConfigFile("merasmus_stun");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CMerasmus::AddStun");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKStunMerasmus = EndPrepSDKCall();
	if(g_hSDKStunMerasmus == INVALID_HANDLE)
		PrintToServer("[Benoist Gamedata] Could not find CMerasmus::AddStun!");
	CloseHandle(hGamedata);
}
void SDK_StunMerasmus(int iMerasmus, int iPlayer)
{
	if(g_hSDKStunMerasmus != INVALID_HANDLE)
	{
		SDKCall(g_hSDKStunMerasmus, iMerasmus, iPlayer);
	}
}

public void OnEntityCreated(int iEntity,const char[] classname)
{
	if(StrEqual(classname,"merasmus"))
		CreateTimer(0.1, MerasmusThink, iEntity, TIMER_REPEAT);
}

public Action MerasmusThink(Handle hTimer, int iMerasmus)
{
	if(!IsValidEntity(iMerasmus))
		return Plugin_Stop;
	char sClass[64];
	GetEntityNetClass(iMerasmus,sClass,sizeof(sClass));
	if(!StrEqual(sClass,"CMerasmus"))
		return Plugin_Stop;
	float pos1[3];
	GetEntPropVector(iMerasmus, Prop_Data,"m_vecAbsOrigin",pos1);
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || !TF2_IsPlayerInCondition(i, TFCond_HalloweenBombHead)) continue;
					
		float pos2[3];
		GetClientEyePosition(i, pos2);
					
		float distance = GetVectorDistance(pos1, pos2);
					
		float dist = 120.0;
					
							
		if(distance < dist)
		{
			SDK_StunMerasmus(iMerasmus, i);
		}
	}
	return Plugin_Continue;
}