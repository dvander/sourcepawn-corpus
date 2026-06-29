#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static bWatcher[MAXPLAYERS+1] = { false,... };

static Color[4] = {255,255,255,255};
static LaserModel;
static HaloModel;

public Plugin:myinfo =
{
	name = "Bird Watcher",
	author = "Jaro 'Monkeys' Vanderheijden",
	description = "Shows the locations of birds",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_birdwatcher", Command_BirdWatch, "Toggles Birdwatching");
	CreateTimer(2.0, timerBeam, _, TIMER_REPEAT);
}

public OnClientConnected(Client)
{
	bWatcher[Client] = false;
}

public OnMapStart()
{
	LaserModel = PrecacheModel("materials/sprites/light_glow03.vmt");
	HaloModel = PrecacheModel("materials/sprites/healbeam.vmt");
}

public Action:Command_BirdWatch(Client, Args)
{
	bWatcher[Client] = !bWatcher[Client];
	PrintToChat(Client, "You %s watching for birds.", bWatcher[Client]?"started":"stopped");
	return Plugin_Handled;
}

public Action:timerBeam(Handle:timers)
{
	new index = FindEntityByClassname(0, "entity_bird");

	if(index == 0)
		PrintToChatAll("No Bird found");
	while(index > 0)
	{
		for(new X = 1; X <= MaxClients; X++)
		{
			if(IsClientInGame(X) && bWatcher[X])
			{
				TE_SetupBeamLaser(index, X, LaserModel, HaloModel, 0, 66, 1.0, 1.0, 1.0, 0, 1.0, Color, 1);
				TE_SendToClient(X);
			}
		}
		index = FindEntityByClassname(index, "entity_bird");
	}
	return Plugin_Handled;
}