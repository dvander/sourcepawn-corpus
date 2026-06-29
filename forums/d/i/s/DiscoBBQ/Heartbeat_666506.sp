//Heartbeat v1.0 by Joe 'Pinkfairie' Maley
//Made by request

//Termination:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>

//Definitions:
#define MAX_HEARTBEAT_HP 25

//Variables:
static Float:BufferTime[33];

//Prethink:
public OnGameFrame()
{

	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new Client = 1; Client <= MaxPlayers; Client++)
	{

		//Timing:
		if(BufferTime[Client] <= (GetGameTime() - 10))
		{

			//Update:
			BufferTime[Client] = GetGameTime();

			//Connected:
			if(IsClientConnected(Client) && IsClientInGame(Client))
			{

				//Alive:
				if(IsPlayerAlive(Client))
				{

					//Declare:
					decl Health;

					//Initialize:
					Health = GetClientHealth(Client);

					//Check:
					if(Health <= MAX_HEARTBEAT_HP)
					{

						//Emit:
						EmitSoundToClient(Client, "heartbeat.wav");
					}
				}
			}
		}
	}
}

//Information:
public Plugin:myinfo =
{

	//Initialize:
	name = "Heartbeat",
	author = "Pinkfairie",
	description = "Heartbeat sound when low HP",
	version = "1.0",
	url = "hiimjoemaley@hotmail.com"
}

//Map Start:
public OnMapStart()
{
 
	//Precache:
	PrecacheSound("heartbeat.wav", true);
 
	//Force download:
	AddFileToDownloadsTable("sound/heartbeat.wav");
}

//Initation:
public OnPluginStart()
{

	//Register:
	PrintToConsole(0, "[SM] Heartbeat v1.0 by Joe 'Pinkfairie' Maley loaded successfully!");
}