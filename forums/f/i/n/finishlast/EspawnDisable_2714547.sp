#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define  TEAM_SURVIVORS 2
#define  TEAM_INFECTED 3

public Plugin:myinfo =
{
	name = "ESpawn Preventor",
	author = "Patrick Evans",
	description = "Plugin to instantly kill an infected that trys to espawn",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	
    	HookEvent("player_spawn", _PlayerSpawned);
}

public _PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:clientVec[3];
	new Float:clientsVec[24][3];
	decl String:clientName[256];
	decl String:output[512];
	
	GetClientName(client,clientName,sizeof(clientName));
	
	// Check for correct team
	if (GetClientTeam(client) == TEAM_INFECTED)
	{
		GetClientAbsOrigin(client, clientVec);
		//Format(output,sizeof(output),"I Am At: %f, %f, %f",clientVec[0],clientVec[1],clientVec[2]);
		//PrintToChat(client,output);
		
		for( new i = 1; i<= GetClientCount(); i++ )
		{
			if( IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS) )
			{
				if( i == client )
				{
					continue;
				}
				GetClientAbsOrigin(i, clientsVec[i]);
				//Format(output,sizeof(output),"Client: %d, is at: %f, %f, %f",i,clientsVec[i][0],clientsVec[i][1],clientsVec[i][2]);
				//PrintToChat(client,output);
				if( (clientsVec[i][0] <= clientVec[0]+50 && clientsVec[i][0] >= clientVec[0]-50) && (clientsVec[i][1] <= clientVec[1]+50 && clientsVec[i][1] >= clientVec[1]-50) && (clientsVec[i][2] <= clientVec[2]+50 && clientsVec[i][2] >= clientVec[2]-50) )
				{
					ForcePlayerSuicide(client);
					Format(output,sizeof(output),"[SM] %s tried to espawn and was killed for it.",clientName);
					PrintToChatAll(output);
					return;
				}
			}
		}
	}
}