/*  ZR Glowing
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CustomPlayerSkins>
#include <zombiereloaded>

#define DATA "1.1"

bool first;

public Plugin myinfo =
{
	name = "ZR Glowing",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
}

public void OnPluginStart()
{
	CreateConVar("zr_glowing_version", DATA, "plugin info", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart);
	first = true;
	for( int i = 1; i <= MaxClients; i++ )
	{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
			{
				SetupGlowSkin(i);
				SetEntityRenderColor(i, 255, 255, 255, 255);//visivel
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);//ativador
			}
	}
}

public OnMapStart()
{
	first = true;
	for( int i = 1; i <= MaxClients; i++ )
	{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
			{
				SetupGlowSkin(i);
				SetEntityRenderColor(i, 255, 255, 255, 255);//visivel
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);//ativador
			}
	}
}

public void Event_RoundStart(Handle:event, char[] name, bool dontBroadcast)
{
	first = true;
	for( int i = 1; i <= MaxClients; i++ )
	{
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
			{
				SetupGlowSkin(i);
				SetEntityRenderColor(i, 255, 255, 255, 255);//visivel
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);//ativador
			}
	}
}

public ZR_OnClientInfected(int client,int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(first)
	{
		// create glow models in first infection for prevent crash on round start (optimization)
		first = false;
		for( int i = 1; i <= MaxClients; i++ )
			if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))SetupGlowSkin(i);
	}
		
	// zombies dont need to have a glow model
	UnhookGlow(client);
}

public ZR_OnClientHumanPost(int client, bool respawn, bool protect)
{
	// remove and re create all glow models for prevent this bug https://forums.alliedmods.net/showthread.php?t=280484
	for( int i = 1; i <= MaxClients; i++ )
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
		{
			//CPS_RemoveSkin(client);
			SetupGlowSkin(i);
		}
}

//Perpare client for glow
void SetupGlowSkin(int client)
{
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));
	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	
	if (iSkin == -1)
		return;
		
	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin))
		SetupGlow(iSkin);
}

//set client glow
void SetupGlow(int iSkin)
{
	int iOffset;
	
	if (!iOffset && (iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
		return;
	
	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	int iRed = 155;
	int iGreen = 0;
	int iBlue = 10;

	SetEntData(iSkin, iOffset, iRed, _, true);
	SetEntData(iSkin, iOffset + 1, iGreen, _, true);
	SetEntData(iSkin, iOffset + 2, iBlue, _, true);
	SetEntData(iSkin, iOffset + 3, 255, _, true);
}


//Who can see the glow if vaild
public Action OnSetTransmit_GlowSkin(int iSkin, int client)
{
/*	if(CPS_HasSkin(client) && EntRefToEntIndex(CPS_GetSkin(client)) == iSkin)
	{
		return Plugin_Handled;
	}*/
	
	if (!IsPlayerAlive(client))
		return Plugin_Handled;
		
		
		
	if (ZR_IsClientZombie(client))
		return Plugin_Continue;
			
	
	return Plugin_Handled;
}


//remove glow
void UnhookGlow(int client)
{
	if (!CPS_HasSkin(client))
		return;
		
	int iSkin = EntRefToEntIndex(CPS_GetSkin(client));
	
	SDKUnhook(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin);
	
	CPS_RemoveSkin(client);
}