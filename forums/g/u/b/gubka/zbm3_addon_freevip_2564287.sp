/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin FreeVIP =
{
	name        	= "[ZP] Addon: FreeVIP",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon give vip access to all players at night",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Initialize convars
ConVar gConVarTimeStart, gConVarTimeEnd;

// Global id
AdminId iD[MAXPLAYERS+1] = INVALID_ADMIN_ID;

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Create cvars
	gConVarTimeStart = CreateConVar("zp_freevip_time_start", "00:00", "The beggining time when normal player get the free vip");
	gConVarTimeEnd	 = CreateConVar("zp_freevip_time_end", 	 "09:00", "The ending time when normal player don't the free vip");
	
	// Create config
	AutoExecConfig(true, "sm_freevip");
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex		The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
	#pragma unused clientIndex
	
	// Verify that the client is non-bot
	if (IsFakeClient(clientIndex))
	{
		return;
	}
	
	// Verify that the client is user
	if(GetUserAdmin(clientIndex) != INVALID_ADMIN_ID)
	{
		iD[clientIndex] = INVALID_ADMIN_ID; //!????
		return;
	}
	
	//######################################################################
	
	// Initialize array to store the 64bit timestamp in
	char sTime[512];
	
	// Format hours
	FormatTime(sTime, sizeof(sTime), "%H", GetTime());
	int H = StringToInt(sTime);

	//######################################################################
	
	// Initialize begining time
	char sBegin[3][8];
	GetConVarString(gConVarTimeStart, sTime, sizeof(sTime));
	ExplodeString(sTime, ":", sBegin, sizeof(sBegin), sizeof(sBegin[]));
	
	// Initialize ending time
	char sEnd[3][8];
	GetConVarString(gConVarTimeEnd, sTime, sizeof(sTime));
	ExplodeString(sTime, ":", sEnd, sizeof(sEnd), sizeof(sEnd[]));

	//######################################################################
	
	// Validate hours
	if(StringToInt(sBegin[0]) <= H && StringToInt(sEnd[0]) > H)
	{
		// Give the vip to the client
		iD[clientIndex] = CreateAdmin("FreeVIP");
		SetAdminFlag(iD[clientIndex], Admin_Custom1, true);
		SetUserAdmin(clientIndex, iD[clientIndex]);
		
		// Log it
		FormatTime(sTime, sizeof(sTime), "%H:%M:%S", GetTime());
		LogMessage("[FreeVip] Player [%N] get a free VIP at [%s]", clientIndex, sTime);
	}
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
	// Remove vip
	if(RemoveAdmin(iD[clientIndex]))
	{
		// Log it
		LogMessage("[FreeVip] Player [%N] have lost his VIP on the disconnection");
	}
	
	// Reset global id
	iD[clientIndex] = INVALID_ADMIN_ID;
}