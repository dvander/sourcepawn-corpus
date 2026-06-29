/*
 * Random Warden
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


#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <warden>


#pragma semicolon 1
#pragma newdecls required


public Plugin myinfo = {
	name = "Random warden",
	author = "shanapu",
	description = "Choose a random player as warden on roundstart",
	version = "1.0",
	url = "https://github.com/shanapu"
};


public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}


public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	if (warden_exist())
		return;

	int client = GetRandomPlayer(CS_TEAM_CT);

	if (client < 1)
		return;

	warden_set(client);
}


int GetRandomPlayer(int team)
{
	int[] clients = new int[MaxClients];
	int clientCount;

	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
	{
		if ((GetClientTeam(i) == team) && IsPlayerAlive(i))
		{
			clients[clientCount++] = i;
		}
	}

	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}