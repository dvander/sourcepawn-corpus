/*
	SM Lord of the chickens

	Copyright (C) 2018 Francisco 'Franc1sco' García

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "SM Lord of the chickens",
	author = "Franc1sco franug",
	description = "",
	version = "0.1",
	url = "http://steamcommunity.com/id/franug"
}

public void OnPluginStart()
{
	CreateTimer(1.0, Timer_Check, _, TIMER_REPEAT);
}

public Action Timer_Check(Handle timer)
{
	int ent = -1;
	float origin[3], origin_chicken[3];
	
	float closer_distance=99999.9;
	int closer;
	
	float distance;
	while((ent = FindEntityByClassname(ent, "chicken")) != -1)
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin_chicken);
		
		for (int i = 1; i < MaxClients;i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, origin);
				distance = GetVectorDistance(origin, origin_chicken);
			
				if(distance <= 500.0)
				{
					if(distance < closer_distance)
					{
						closer_distance = distance;
						closer = i;
					}
				}
			}
	}
	
	if(closer > 0)
		SetEntPropEnt(ent, Prop_Send, "m_leader", closer);
}