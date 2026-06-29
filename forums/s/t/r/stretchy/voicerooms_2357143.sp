/**
 * Voice Rooms: A sourcemod plugin for making voicerooms.
 * Copyright (C) 2015 Earl Cochran (stretch)
 * 
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

#include <sourcemod>
#include <adt.inc>
#include <sdktools_voice.inc>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "[ANY] Voice Rooms",
	author      = "stretch",
	description = "A sourcemod plugin that allows players to join different voice chat rooms.",
	version     = "0.3",
	url         = "https://forums.alliedmods.net/showthread.php?p=2357143"
};


/**
 * GLOBALS
 */
ArrayList g_RoomList;
int g_clientsCurrentRoom[MAXPLAYERS + 1];

public void OnPluginStart()
{
	GetRoomsFromConfig();
	RegConsoleCmd("sm_voicerooms", Command_VoiceRoomsMenu);
}

public void OnClientConnected(int client)
{
	g_clientsCurrentRoom[client] = 0;
	for (int thisClient = 1; thisClient < MaxClients + 1; thisClient++)
	{
		if (IsClientInGame(thisClient) && !IsFakeClient(thisClient) && thisClient != client)
		{
			if (g_clientsCurrentRoom[thisClient] != g_clientsCurrentRoom[client])
			{
				/**
				 * Set the connecting client to only hear, and communitcate with,
				 * the people in the default room.
				 */
				 SetListenOverride(thisClient, client, Listen_No);
				 SetListenOverride(client, thisClient, Listen_No);
			}
		}
	}

}

public void OnClientDisconnect(int client)
{
	g_clientsCurrentRoom[client] = 0;
}

public void GetRoomsFromConfig()
{
	char configPath[PLATFORM_MAX_PATH];
	if(BuildPath(Path_SM, configPath, sizeof(configPath), "configs/voicerooms.cfg") <= 0)
	{
		SetFailState("Could not load config file voicerooms.cfg. Please verify its existence and try again.");
	}

	KeyValues voiceRoomsConfig = new KeyValues("");
	if(voiceRoomsConfig.ImportFromFile(configPath))
	{
		g_RoomList = new ArrayList(32, 0);
		voiceRoomsConfig.GotoFirstSubKey(false);
			
		// Do/While loop for getting the list of rooms from the config.
		do
		{
			char currentKey[32];
			voiceRoomsConfig.GetString(NULL_STRING, currentKey, sizeof(currentKey), "ERROR");

			// Push to global room list array
			g_RoomList.PushString(currentKey);

		} while (voiceRoomsConfig.GotoNextKey(false));

		delete voiceRoomsConfig;
	}
	else
	{
		SetFailState("Could not read the KeyValues from the config file.");
	}

}

public Action Command_VoiceRoomsMenu(int client, int args)
{
	Menu voiceRoomsMenu = new Menu(VoiceRoomsMenuHandler);
	voiceRoomsMenu.SetTitle("Voice Rooms:");
	for (int i = 0; i < g_RoomList.Length; i++)
	{
		char roomName[32];
		int roomCount;
		char roomWithCount[36];
		g_RoomList.GetString(i, roomName, sizeof(roomName));
		for (int p = 1; p < MaxClients; p++)
		{
			if (i == g_clientsCurrentRoom[p] && IsClientInGame(p))
			{
				roomCount++;
			}
		}
		Format(roomWithCount, sizeof(roomWithCount), "%s [%i]", roomName, roomCount);
		if (g_clientsCurrentRoom[client] == i)
		{
			voiceRoomsMenu.AddItem(roomName, roomWithCount, ITEMDRAW_DISABLED);
		}
		else
		{
			voiceRoomsMenu.AddItem(roomName, roomWithCount);
		}
	}
	voiceRoomsMenu.Display(client, 45);
}

public int VoiceRoomsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			int clientChangingRooms = param1;
			int clientConnectingRoom = param2;

			for (int thisClient = 1; thisClient < MaxClients + 1; thisClient++)
			{
				if (IsClientInGame(thisClient) && !IsFakeClient(thisClient) && thisClient != clientChangingRooms)
				{
					if (g_clientsCurrentRoom[thisClient] != clientConnectingRoom)
					{
						/**
						 * Stop the clients not in the room being switched to 
						 * from hearing the departing client.
						 */
						 SetListenOverride(thisClient, clientChangingRooms, Listen_No);
						 SetListenOverride(clientChangingRooms, thisClient, Listen_No);
					}
					if (g_clientsCurrentRoom[thisClient] == clientConnectingRoom)
					{
						/**
						 * Allow the client changing rooms to receive communication from 
						 * those already in the room, and allow the client to send
						 * communication to those already in the room.
						 */
						 SetListenOverride(clientChangingRooms, thisClient, Listen_Yes);
						 SetListenOverride(thisClient, clientChangingRooms, Listen_Yes);
					}
				}
			}

			g_clientsCurrentRoom[clientChangingRooms] = clientConnectingRoom;

			char clientConnectingRoomName[32];
			g_RoomList.GetString(clientConnectingRoom, clientConnectingRoomName, sizeof(clientConnectingRoomName));
			PrintToChat(clientChangingRooms, "[Voice Rooms]: You have now joined %s", clientConnectingRoomName);
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}

}
