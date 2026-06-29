/*
 * Parachutes for Zephyrus store
 * by: shanapu
 * https://github.com/shanapu/StoreParachute/
 * 
 * used code by zipcore
 * https://gitlab.com/Zipcore/HungerGames/blob/master/addons/sourcemod/scripting/hungergames/tools/parachute.sp
 * 
 * Copyright (C) 2018 Thomas Schmidt (shanapu)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <sdktools>
#include <store>
#include <smartdm>

#pragma semicolon 1
#pragma newdecls required

bool g_bParachute[MAXPLAYERS+1];
bool g_bItem[MAXPLAYERS+1] = false;

char g_sModels[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];

float g_fSpeed[STORE_MAX_ITEMS];

int g_iModelCount = 0;
int g_iVelocity = -1;
int g_iParaEntRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
int g_iClientModel[MAXPLAYERS+1];


public Plugin myinfo = {
	name = "Parachute for Zephyrus Store",
	author = "shanapu",
	description = "Adds support for parachutes to Zephyrus Store plugin",
	version = "1.2",
	url = "https://github.com/shanapu/StoreParachute"
};

public void OnPluginStart()
{
	Store_RegisterHandler("parachute", "", ParaChute_OnMapStart, ParaChute_Reset, ParaChute_Config, ParaChute_Equip, ParaChute_Remove, true);

	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

public void ParaChute_OnMapStart()
{
	for(int i = 0; i < g_iModelCount; ++i)
	{
		Downloader_AddFileToDownloadsTable(g_sModels[i]);

		if (IsModelPrecached(g_sModels[i]))
			continue;

		PrecacheModel(g_sModels[i]);
	}
}

public void ParaChute_Reset()
{
	g_iModelCount = 0;
}

public bool ParaChute_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iModelCount);

	KvGetString(kv, "model", g_sModels[g_iModelCount], PLATFORM_MAX_PATH);
	g_fSpeed[g_iModelCount] = KvGetFloat(kv, "fallspeed", 100.0);

	if (!FileExists(g_sModels[g_iModelCount], true))
		return false;

	g_iModelCount++;

	return true;
}

public int ParaChute_Equip(int client, int id)
{
	g_iClientModel[client] = Store_GetDataIndex(id);
	g_bItem[client] = true;

	return -1;
}

public int ParaChute_Remove(int client)
{
	DisableParachute(client);
	g_bItem[client] = false;

	return 0;
}

public void OnClientDisconnect(int client)
{
	g_bItem[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!g_bItem[client])
		return Plugin_Continue;

	// https://gitlab.com/Zipcore/HungerGames/blob/master/addons/sourcemod/scripting/hungergames/tools/parachute.sp
	// Check abort reasons
	if(g_bParachute[client])
	{
		// Abort by released button
		if(!(buttons & IN_USE) || !IsPlayerAlive(client))
		{
			DisableParachute(client);
			return Plugin_Continue;
		}

		// Abort by up speed
		float fVel[3];
		GetEntDataVector(client, g_iVelocity, fVel);

		if(fVel[2] >= 0.0)
		{
			DisableParachute(client);
			return Plugin_Continue;
		}

		// Abort by on ground flag
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			DisableParachute(client);
			return Plugin_Continue;
		}

		// decrease fallspeed
		float fOldSpeed = fVel[2];

		// Player is falling to fast, lets slow him to max gc_fSpeed
		if(fVel[2] < g_fSpeed[g_iClientModel[client]] * (-1.0))
		{
			fVel[2] = g_fSpeed[g_iClientModel[client]] * (-1.0);
		}

		// fallspeed changed
		if(fOldSpeed != fVel[2])
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
	}
	// Should we start the parashute?
	else if(g_bItem[client])
	{
		// Reject by released button
		if(!(buttons & IN_USE) || !IsPlayerAlive(client))
			return Plugin_Continue;

		// Reject by on ground flag
		if(GetEntityFlags(client) & FL_ONGROUND)
			return Plugin_Continue;

		// Reject by up speed
		float fVel[3];
		GetEntDataVector(client, g_iVelocity, fVel);

		if(fVel[2] >= 0.0)
			return Plugin_Continue;

		// Open parachute
		int iEntity = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(iEntity, "model", g_sModels[g_iClientModel[client]]);
		DispatchSpawn(iEntity);

		SetEntityMoveType(iEntity, MOVETYPE_NOCLIP);

		// Teleport to player
		float fPos[3];
		float fAng[3];
		GetClientAbsOrigin(client, fPos);
		GetClientAbsAngles(client, fAng);
		fAng[0] = 0.0;
		TeleportEntity(iEntity, fPos, fAng, NULL_VECTOR);

		// Parent to player
		char sClient[16];
		Format(sClient, 16, "client%d", client);
		DispatchKeyValue(client, "targetname", sClient);
		SetVariantString(sClient);
		AcceptEntityInput(iEntity, "SetParent", iEntity, iEntity, 0);

		g_iParaEntRef[client] = EntIndexToEntRef(iEntity);
		g_bParachute[client] = true;
	}

	return Plugin_Continue;
}

void DisableParachute(int client)
{
	int iEntity = EntRefToEntIndex(g_iParaEntRef[client]);
	if(iEntity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iEntity, "ClearParent");
		AcceptEntityInput(iEntity, "kill");
	}

	g_bParachute[client] = false;
	g_iParaEntRef[client] = INVALID_ENT_REFERENCE;
}