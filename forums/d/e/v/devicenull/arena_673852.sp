#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Full Arena Teams",
	author = "devicenull",
	description = "What do you think?",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("fullarena_version",PLUGIN_VERSION,"Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("teamplay_round_start",round_start);
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:map[64];
	GetCurrentMap(map,64);
	if (StrContains(map,"arena_",false) != -1)
	{	
		for (new i=1;i<GetMaxClients();i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == _:TFTeam_Spectator)
				{
					AssignPlayer(i);
				}
			}
		}	
	}
}

public AssignPlayer(client)
{
	new count_red = GetTeamClientCount(_:TFTeam_Red);
	new count_blue = GetTeamClientCount(_:TFTeam_Blue);
	new count_spec = GetTeamClientCount(_:TFTeam_Spectator);
	
	if (count_red == count_blue && count_spec >= 2)
	{
		ChangeClientTeam(client,GetRandomInt(2,3));		
	}
	else if  (count_red < count_blue)
	{
		ChangeClientTeam(client,_:TFTeam_Red);
	}
	else if (count_blue < count_red)
	{
		ChangeClientTeam(client,_:TFTeam_Blue);
	}
	else
	{
		PrintToChat(client,"Sorry, but you have to sit out this round to keep the teams balanced");
	}	
}
