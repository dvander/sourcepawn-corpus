#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Noclip for players",
	author = "linux_lover",
	description = "Toggles noclip on players",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");
}

public Action:Listener_Say(client, const String:command[], argc)
{	
	if(client && argc && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:strArg1[50];
		GetCmdArg(1, strArg1, sizeof(strArg1));
		
		if(strcmp(strArg1, "noclip") == 0)
		{
			new MoveType:mt = GetEntityMoveType(client);
			
			if(mt == MOVETYPE_WALK)
			{
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
			}else{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
		}
	}
	
	return Plugin_Continue;
}
