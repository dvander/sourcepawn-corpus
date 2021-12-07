/*
 * Froggy Jump for Hunter Zombie:Reloaded Plugin.
 * by: shanapu
 * https://github.com/shanapu/
 * 
 * Copyright (C) 2017 Thomas Schmidt (shanapu)
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
#include <classzr>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

int g_iFroggyJumped[MAXPLAYERS + 1];

// Info
public Plugin myinfo = {
	name = "Froggy Jump for Hunter",
	author = "shanapu",
	description = "Add Froggy Jump for Hunter class in Zombie:Reloaded",
	version = "1.0",
	url = "https://github.com/shanapu/"
};

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	int classIndex = ZR_GetClassByName("Hunter");
	int clientClass = ZR_GetActiveClass(client); 
	
	int water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	
	// Last button
	static bool bPressed[MAXPLAYERS+1] = false;
	
	if (IsPlayerAlive(client) && clientClass == classIndex)
	{
		// Reset when on Ground
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			g_iFroggyJumped[client] = 0;
			bPressed[client] = false;
		}
		else
		{
			// Player pressed jump button?
			if (buttons & IN_JUMP)
			{
				if (water <= 1)
				{
					if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
					{
						SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
						if (!(GetEntityFlags(client) & FL_ONGROUND)) buttons &= ~IN_JUMP;
					}
				}
								
				// For second time?
				if (!bPressed[client] && g_iFroggyJumped[client]++ == 1)
				{
					float velocity[3];
					float velocity0;
					float velocity1;
					float velocity2;
					float velocity2_new;
					
					// Get player velocity
					velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
					velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
					velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
					
					velocity2_new = 200.0;
					
					// calculate new velocity^^
					if (velocity2 < 150.0) velocity2_new = velocity2_new + 20.0;
					
					if (velocity2 < 100.0) velocity2_new = velocity2_new + 30.0;
					
					if (velocity2 < 50.0) velocity2_new = velocity2_new + 40.0;
					
					if (velocity2 < 0.0) velocity2_new = velocity2_new + 50.0;
					
					if (velocity2 < -50.0) velocity2_new = velocity2_new + 60.0;
					
					if (velocity2 < -100.0) velocity2_new = velocity2_new + 70.0;
					
					if (velocity2 < -150.0) velocity2_new = velocity2_new + 80.0;
					
					if (velocity2 < -200.0) velocity2_new = velocity2_new + 90.0;
					
					// Set new velocity
					velocity[0] = velocity0 * 0.1;
					velocity[1] = velocity1 * 0.1;
					velocity[2] = velocity2_new;
					
					// Double Jump
					SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
				}
				
				bPressed[client] = true;
			}
			else bPressed[client] = false;
		}
	}
	return Plugin_Continue;
}