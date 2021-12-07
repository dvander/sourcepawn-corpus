#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.00"
#define PREFIX "\x03[AntiStuck]\x01"

public Plugin:myinfo =
{
	name = "Anti Stuck",
	author = "muso.sk",
	description = "Allows players to push them away from stucked player",
	version = PLUGIN_VERSION,
	url = ""
};

new TimerActive;

#define COLLISION_GROUP_PUSHAWAY            17
#define COLLISION_GROUP_PLAYER              5

public OnPluginStart()
{
	RegConsoleCmd("sm_stuck", Command_Stuck);
}

public Action:Command_Stuck(client, args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && TimerActive == 0)
	{
		PrintToChatAll("%s Unstucked all players", PREFIX);	
		TimerActive = 1;
		CreateTimer(1.0, Timer_UnBlockPlayer, client);
		
		for (new i = 1; i <= MaxClients; i++)
		{	
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				EnableAntiStuck(i);
			}
		}
	}
	else if (TimerActive == 1)
	{
		PrintToChat(client, "%s Command is already in use", PREFIX);
	}
	else
	{
		PrintToChat(client, "%s You must be alive to use this command", PREFIX);
	}
	
	return Plugin_Handled;
	
}

public Action:Timer_UnBlockPlayer(Handle:timer, any:client)
{
	TimerActive = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			DisableAntiStuck(i);
		}
	}
	
	return Plugin_Continue;
	
}

DisableAntiStuck(client)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
}

EnableAntiStuck(client)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
}