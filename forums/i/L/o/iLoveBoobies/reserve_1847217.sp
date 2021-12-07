#include <sourcemod>

new Handle:g_Module_ReserveSettings_TotalSlots;
new Handle:g_Module_ReserveSettings_ReserveSlots;
new Handle:g_Module_ReserveSettings_HideReserveSlots;
new Handle:g_Module_ReserveSettings_AutomatedSlots;
new Handle:g_Module_ReserveSettings_SurvivorLimit;
new Handle:g_Module_ReserveSettings_InfectedLimit;

new Spectators;

public OnPluginStart()
{
	g_Module_ReserveSettings_TotalSlots				= CreateConVar("reservesettings_totalslots","8","The total amount of slots on the server.");
	g_Module_ReserveSettings_ReserveSlots			= CreateConVar("reservesettings_reserveslots","0","The total amount of reserve slots on the server.");
	g_Module_ReserveSettings_HideReserveSlots		= CreateConVar("reservesettings_hidereserveslots","1","If enabled, total slots - reserve slots is the value of total slots displayed.");
	g_Module_ReserveSettings_AutomatedSlots			= CreateConVar("reservesettings_automatedslots","1","If enabled, slots are automated. If disabled, slot settings must be defined in this config.");
	g_Module_ReserveSettings_SurvivorLimit			= CreateConVar("reservesettings_survivorlimit","4","If automated slots is disabled, the number of survivor slots.");
	g_Module_ReserveSettings_InfectedLimit			= CreateConVar("reservesettings_infectedlimit","4","If automated slots is disabled, the number of infected slots.");
	
	SetAndMaintainSlots();
}	

public SetAndMaintainSlots()
{
	SetConVarInt(FindConVar("sv_maxplayers"), GetConVarInt(g_Module_ReserveSettings_TotalSlots) + Spectators);
	if (GetConVarInt(g_Module_ReserveSettings_HideReserveSlots) == 1)
	{
		SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(g_Module_ReserveSettings_TotalSlots) - GetConVarInt(g_Module_ReserveSettings_ReserveSlots) + Spectators);
	}
	else
	{
		SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(g_Module_ReserveSettings_TotalSlots) + Spectators);
	}

	// Set the team limits

	if (GetConVarInt(g_Module_ReserveSettings_AutomatedSlots) == 1)
	{
		SetConVarInt(FindConVar("l4d_survivor_limit"), (GetConVarInt(g_Module_ReserveSettings_TotalSlots) - GetConVarInt(g_Module_ReserveSettings_ReserveSlots)) / 2);
		SetConVarInt(FindConVar("l4d_infected_limit"), (GetConVarInt(g_Module_ReserveSettings_TotalSlots) - GetConVarInt(g_Module_ReserveSettings_ReserveSlots)) / 2);
		SetConVarInt(FindConVar("survivor_limit"), (GetConVarInt(g_Module_ReserveSettings_TotalSlots) - GetConVarInt(g_Module_ReserveSettings_ReserveSlots)) / 2);
		SetConVarInt(FindConVar("z_max_player_zombies"), (GetConVarInt(g_Module_ReserveSettings_TotalSlots) - GetConVarInt(g_Module_ReserveSettings_ReserveSlots)) / 2);
	}
	else
	{
		SetConVarInt(FindConVar("l4d_survivor_limit"), GetConVarInt(g_Module_ReserveSettings_SurvivorLimit));
		SetConVarInt(FindConVar("l4d_infected_limit"), GetConVarInt(g_Module_ReserveSettings_InfectedLimit));
		SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(g_Module_ReserveSettings_SurvivorLimit));
		SetConVarInt(FindConVar("z_max_player_zombies"), GetConVarInt(g_Module_ReserveSettings_InfectedLimit));
	}
}