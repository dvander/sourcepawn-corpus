/**
 * -----------------------------------------------------
 * File        nearest_player.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2013 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */



// Includes
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <updater>


// Use semicolon
#pragma semicolon 1



// Handles for the config
new Handle:unit_c;
new Handle:directionFlags_c;
new Handle:distanceFlags_c;
new Handle:nameFlags_c;
new Handle:autoupdate_c;



// unit to use
new unit;

// Flags
new directionFlagBits;
new distanceFlagBits;
new nameFlagBits;



// Saves what the player get
new bool:playerItems[MAXPLAYERS + 1][3];



// Plugin information
public Plugin:myinfo =
{
	name = "Nearest Player",
	author = "Popoklopsi",
	version = "1.0.0",
	description = "Players can see the distance and direction to the nearest player",
	url = "http://popoklopsi.de"
};



// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("nearest_player", "sourcemod");

	// Global versions cvar
	AutoExecConfig_CreateConVar("nearest_player_version", "1.0.0", "Nearest Player Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	unit_c = AutoExecConfig_CreateConVar("nearest_player_unit", "1", "1 = Use feet as unit, 0 = Use meters as unit");

	directionFlags_c = AutoExecConfig_CreateConVar("nearest_player_direction", "", "Here you can define which flags a player need to see the direction to the nearest player. You can use just one flag or more (like \"abg\" or just \"s\"). Empty to activate for all");
	distanceFlags_c = AutoExecConfig_CreateConVar("nearest_player_distance", "", "Here you can define which flags a player need to see the distance to the nearest player. You can use just one flag or more (like \"abg\" or just \"s\"). Empty to activate for all");
	nameFlags_c = AutoExecConfig_CreateConVar("nearest_player_name", "", "Here you can define which flags a player need to see the name of the nearest player. You can use just one flag or more (like \"abg\" or just \"s\"). Empty to activate for all");

	autoupdate_c = AutoExecConfig_CreateConVar("nearest_player_update", "1", "1 = Auto. update the plugin (needs Autoupdater: http://forums.alliedmods.net/showthread.php?t=169095), 0 = Off");


	// Create the config
	AutoExecConfig(true, "nearest_player", "sourcemod");
	AutoExecConfig_CleanFile();


	// Load translation
	LoadTranslations("nearest_player.phrases.txt");


	// Create the timer to check nearest player
	CreateTimer(0.2, checkPlayers, _, TIMER_REPEAT);


	// Hook player spawn
	HookEvent("player_spawn", eventPlayerSpawn);
}



// Configs are executed
public OnConfigsExecuted()
{
	// Strings to store
	decl String:directionFlags[36];
	decl String:distanceFlags[36];
	decl String:nameFlags[36];


	// Disable Hud Hint Sound
	if (FindConVar("sv_hudhint_sound") != INVALID_HANDLE)
	{
		SetConVarInt(FindConVar("sv_hudhint_sound"), 0);
	}


	// Get unit to take
	unit = GetConVarInt(unit_c);



	// Add auto update
	if (GetConVarInt(autoupdate_c) == 1 && LibraryExists("updater"))
	{
		Updater_AddPlugin("http://popoklopsi.de/nearest_player/update.txt");
	}



	// Now get the flag cvars
	GetConVarString(directionFlags_c, directionFlags, sizeof(directionFlags));
	GetConVarString(distanceFlags_c, distanceFlags, sizeof(distanceFlags));
	GetConVarString(nameFlags_c, nameFlags, sizeof(nameFlags));


	// And save them
	directionFlagBits = ReadFlagString(directionFlags);
	distanceFlagBits = ReadFlagString(distanceFlags);
	nameFlagBits = ReadFlagString(nameFlags);
}



// A player spawned, get his items
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);


	// Reset the player
	playerItems[client][0] = false;
	playerItems[client][1] = false;
	playerItems[client][2] = false;



	// Is client Valid?
	if (isClientValid(client))
	{
		// Check flags
		if ((GetUserFlagBits(client) & directionFlagBits) == directionFlagBits)
		{
			playerItems[client][2] = true;
		}

		if ((GetUserFlagBits(client) & distanceFlagBits) == distanceFlagBits)
		{
			playerItems[client][1] = true;
		}

		if ((GetUserFlagBits(client) & nameFlagBits) == nameFlagBits)
		{
			playerItems[client][0] = true;
		}
	}
}



// Client disconnected
public OnClientDisconnect(client)
{
	playerItems[client][0] = false;
	playerItems[client][1] = false;
	playerItems[client][2] = false;
}




// Check for nearest player
public Action:checkPlayers(Handle:timer, any:data)
{
	// Variables to store
	new Float:clientOrigin[3];
	new Float:searchOrigin[3];
	new Float:near;
	new Float:distance;

	new Float:dist;
	new Float:vecPoints[3];
	new Float:vecAngles[3];
	new Float:clientAngles[3];

	decl String:directionString[64];
	decl String:unitString[32];

	new String:textToPrint[64];

	// nearest client
	new nearest;



	// Client loop
	for (new client = 1; client <= MaxClients; client++)
	{
		// Valid client?
		if ((playerItems[client][0] || playerItems[client][1] || playerItems[client][2]) && IsPlayerAlive(client) && isClientValid(client))
		{
			// Reset variables
			nearest = 0;
			near = 0.0;


			// Get origin
			GetClientAbsOrigin(client, clientOrigin);


			// Next client loop
			for (new search = 1; search <= MaxClients; search++)
			{
				// Check if valid
				if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
				{
					// Get distance to first client
					GetClientAbsOrigin(search, searchOrigin);

					distance = GetVectorDistance(clientOrigin, searchOrigin);


					// Is he more near to the player as the player before?
					if (near == 0.0)
					{
						near = distance;
						nearest = search;
					}

					if (distance < near)
					{
						// Set new distance and new nearest player
						near = distance;
						nearest = search;
					}
				}
			}


			// Found a player?
			if (nearest != 0)
			{
				// Client get Direction?
				if (playerItems[client][2])
				{
					// Get the origin of the nearest player
					GetClientAbsOrigin(nearest, searchOrigin);

					// and the Angles
					GetClientAbsAngles(client, clientAngles);

					// Angles from origin
					MakeVectorFromPoints(clientOrigin, searchOrigin, vecPoints);
					GetVectorAngles(vecPoints, vecAngles);


					// Differenz
					new Float:diff = clientAngles[1] - vecAngles[1];


					// Correct it
					if (diff < -180)
					{
						diff = 360 + diff;
					}

					if (diff > 180)
					{
						diff = 360 - diff;
					}


					// Now geht the direction
					// Up
					if (diff >= -22.5 && diff < 22.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x91");
					}

					// right up
					else if (diff >= 22.5 && diff < 67.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x97");
					}

					// right
					else if (diff >= 67.5 && diff < 112.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x92");
					}

					// right down
					else if (diff >= 112.5 && diff < 157.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x98");
					}

					// down
					else if (diff >= 157.5 || diff < -157.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x93");
					}

					// down left
					else if (diff >= -157.5 && diff < -112.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x99");
					}

					// left
					else if (diff >= -112.5 && diff < -67.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x90");
					}

					// left up
					else if (diff >= -67.5 && diff < -22.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x96");
					}



					// Add to text
					if (playerItems[client][1] || playerItems[client][0])
					{
						Format(textToPrint, sizeof(textToPrint), "%s\n", directionString);
					}
					else
					{
						Format(textToPrint, sizeof(textToPrint), directionString);
					}
				}



				// Client get Distance?
				if (playerItems[client][1])
				{
					// Distance to meters
					dist = near * 0.01905;

					// Distance to feet?
					if (unit == 1)
					{
						dist = dist * 3.2808399;

						// Feet
						Format(unitString, sizeof(unitString), "%T", "feet", client);
					}
					else
					{
						// Meter
						Format(unitString, sizeof(unitString), "%T", "meter", client);
					}


					// Add to text
					if (playerItems[client][0])
					{
						Format(textToPrint, sizeof(textToPrint), "%s(%.0f %s)\n", textToPrint, dist, unitString);
					}
					else
					{
						Format(textToPrint, sizeof(textToPrint), "%s(%.0f %s)", textToPrint, dist, unitString);
					}
				}


				// Add name
				if (playerItems[client][0])
				{
					Format(textToPrint, sizeof(textToPrint), "%s%N", textToPrint, nearest);
				}

				// Print text
				PrintHintText(client, textToPrint);
			}
		}
	}

	return Plugin_Continue;
}




// Stock to check if client is valid
stock bool:isClientValid(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (!IsFakeClient(client) && !IsClientSourceTV(client))
			{
				// Yeah, the client is valid
				return true;
			}
		}
	}

	// No he isn't valid
	return false;
}