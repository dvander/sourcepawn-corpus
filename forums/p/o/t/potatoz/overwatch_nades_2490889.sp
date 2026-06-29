/*                                                        
 * 		    Copyright (C) 2018 Adam "Potatoz" Ericsson
 * 
 * 	This program is free software: you can redistribute it and/or modify it
 * 	under the terms of the GNU General Public License as published by the Free
 * 	Software Foundation, either version 3 of the License, or (at your option) 
 * 	any later version.
 *
 * 	This program is distributed in the hope that it will be useful, but WITHOUT 
 * 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * 	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * 	See http://www.gnu.org/licenses/. for more information
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "OVERWATCH:Nades",
	author = "Potatoz",
	description = "Logs all grenade throws to admins in console",
	version = "1.0",
	url = ""
};

public OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "_projectile", false) != -1) 
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public OnEntitySpawned(int entity)
{
    if(IsValidEntity(entity) && IsValidEdict(entity))
	{
		char classname[45], team[32]; 
		GetEdictClassname(entity, classname, sizeof(classname)); 
		
		if(StrContains(classname, "_projectile", false) != -1) 
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == -1)
				return;

			if(GetClientTeam(owner) == 2)
				Format(team, sizeof(team), "(T)");
			else if(GetClientTeam(owner) == 3)
				Format(team, sizeof(team), "(CT)");
			else if(GetClientTeam(owner) < 2)
				Format(team, sizeof(team), "(SPEC)");	
						
			char current_time[30];
			FormatTime(current_time, sizeof(current_time), "%H:%M:%S", GetTime());
						
			for (int x = 1; x <= MaxClients; x++) 
				if (CheckCommandAccess(x, "generic_admin", ADMFLAG_GENERIC, false)) 
					PrintToConsole(x, " OVERWATCH-NADES | %s - \"%N\" %s threw a %s", current_time, owner, team, classname); 
		}
	}
}