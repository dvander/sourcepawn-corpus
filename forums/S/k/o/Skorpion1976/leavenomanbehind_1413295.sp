/**
 * @file	leavenomanbehind.sp
 * @author	1Swat2KillThemAll
 *
 * @brief	L4D2 SourceMod Plugin
 * @version	1.000.000
 *
 * Leave No Man Behind L4D2 SourceMod Plugin
 * Copyright (C)/© 2010 B.D.A.K. Koch
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new bool:g_IsInSafehouse[MAXPLAYERS+1] = { false, ... },
	g_cInSafehouse = 0,
	g_iDoor = -1,
	g_IsDoorOpen = true;

enum eTeams
{
	eTeams_Unassigned = 1,
	eTeams_Survivor,
	eTeams_Infected,
	eTeams_Spectator,
	eTeams_Max
};

enum eEvents
{
	eEvents_Player_Death = 0,
	eEvents_Player_Entered_Checkpoint,
	eEvents_Player_Left_Checkpoint,
	eEvents_Player_Use,
	eEvents_Max
};
new stock const String:g_Events[][] =
{
	"player_death",
	"player_entered_checkpoint",
	"player_left_checkpoint",
	"player_use"
};

#define PLUGIN_NAME "Leave No Man Behind"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCR "The safehouse's door can only be closed when all players are inside."
#define PLUGIN_VERSION "1.000.000"
#define PLUGIN_URL ""
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	CreateConVar("sm_lnmb_version", PLUGIN_VERSION, "Version Console Variable", FCVAR_CHEAT | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	for (new i = 0; i < _:eEvents_Max; i++)
	{
		HookEvent(g_Events[i], Event_Handler);
	}
	HookEvent("round_start", Event_RoundStart);
}

public Event_Handler(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == _:eTeams_Survivor)
	{
		switch (name[7])
		{
			case 'd':
			{
				if (g_IsInSafehouse[client])
				{
					g_IsInSafehouse[client] = false;
					g_cInSafehouse--;
					if (g_cInSafehouse < 0)
					{
						g_cInSafehouse = 0;
					}
				}
			}
			case 'e':
			{
				if (!g_IsInSafehouse[client])
				{
					g_IsInSafehouse[client] = true;
					g_cInSafehouse++;
				}
			}
			case 'l':
			{
				if (g_IsInSafehouse[client])
				{
					g_IsInSafehouse[client] = false;
					g_cInSafehouse--;
					if (g_cInSafehouse < 0)
					{
						g_cInSafehouse = 0;
					}
				}
			}
			case 'u':
			{
				if (GetEventInt(event, "targetid") == g_iDoor)
				{
					new cLivingPlayers = 0;

					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) &&
							GetClientTeam(i) == _:eTeams_Survivor && IsPlayerAlive(i))
						{
							cLivingPlayers++;
						}
					}

					if (g_cInSafehouse < cLivingPlayers)
					{
						if (g_iDoor != -1 && g_IsDoorOpen)
						{
							CreateTimer(0.1 , Timer_OpenDoor, g_iDoor, TIMER_FLAG_NO_MAPCHANGE);

							g_IsDoorOpen = true;

							PrintToChat(client, "[SM] Please wait untill all players have entered the safehouse!");
						}
					}
					else
					{
						SetEntProp(g_iDoor, Prop_Data, "m_hasUnlockSequence", 0);
						AcceptEntityInput(g_iDoor, "Unlock");
						g_IsDoorOpen = !g_IsDoorOpen;
					}
				}
			}
		}
	}
}
public Action:Timer_OpenDoor(Handle:timer, any:iDoor)
{
	SetEntProp(iDoor, Prop_Data, "m_hasUnlockSequence", 0);
	AcceptEntityInput(iDoor, "Unlock");
	AcceptEntityInput(iDoor, "Open");
	AcceptEntityInput(iDoor, "Lock");
	SetEntProp(iDoor, Prop_Data, "m_hasUnlockSequence", 1);

	return Plugin_Stop;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		g_IsInSafehouse[i] = false;
	}
	g_cInSafehouse = 0;
	g_iDoor = -1;

	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
	{
		if (!GetEntProp(ent, Prop_Data, "m_hasUnlockSequence"))
		{
			g_iDoor = ent;
		}
	}
}

